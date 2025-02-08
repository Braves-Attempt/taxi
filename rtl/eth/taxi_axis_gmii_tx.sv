// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2015-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream GMII frame transmitter (AXI in, GMII out)
 */
module taxi_axis_gmii_tx #
(
    parameter DATA_W = 8,
    parameter logic PADDING_EN = 1'b1,
    parameter MIN_FRAME_LEN = 64,
    parameter logic PTP_TS_EN = 1'b0,
    parameter PTP_TS_W = 96,
    parameter logic TX_CPL_CTRL_IN_TUSER = 1'b1
)
(
    input  wire logic                 clk,
    input  wire logic                 rst,

    /*
     * Transmit interface (AXI stream)
     */
    taxi_axis_if.snk                  s_axis_tx,
    taxi_axis_if.src                  m_axis_tx_cpl,

    /*
     * GMII output
     */
    output wire logic [DATA_W-1:0]    gmii_txd,
    output wire logic                 gmii_tx_en,
    output wire logic                 gmii_tx_er,

    /*
     * PTP
     */
    input  wire logic [PTP_TS_W-1:0]  ptp_ts,

    /*
     * Control
     */
    input  wire logic                 clk_enable,
    input  wire logic                 mii_select,

    /*
     * Configuration
     */
    input  wire logic [7:0]           cfg_ifg,
    input  wire logic                 cfg_tx_enable,

    /*
     * Status
     */
    output wire logic                 start_packet,
    output wire logic                 error_underflow
);

localparam USER_W = TX_CPL_CTRL_IN_TUSER ? 2 : 1;
localparam TX_TAG_W = s_axis_tx.ID_W;

localparam MIN_LEN_W = $clog2(MIN_FRAME_LEN-4-1+1);

// check configuration
if (DATA_W != 8)
    $fatal(0, "Error: Interface width must be 8 (instance %m)");

if (s_axis_tx.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (s_axis_tx.USER_W != USER_W)
    $fatal(0, "Error: Interface USER_W parameter mismatch (instance %m)");

localparam [7:0]
    ETH_PRE = 8'h55,
    ETH_SFD = 8'hD5;

localparam [2:0]
    STATE_IDLE = 3'd0,
    STATE_PREAMBLE = 3'd1,
    STATE_PAYLOAD = 3'd2,
    STATE_LAST = 3'd3,
    STATE_PAD = 3'd4,
    STATE_FCS = 3'd5,
    STATE_IFG = 3'd6;

logic [2:0] state_reg = STATE_IDLE, state_next;

// datapath control signals
logic reset_crc;
logic update_crc;

logic [7:0] s_tdata_reg = 8'd0, s_tdata_next;

logic mii_odd_reg = 1'b0, mii_odd_next;
logic [3:0] mii_msn_reg = 4'b0, mii_msn_next;

logic frame_reg = 1'b0, frame_next;
logic frame_error_reg = 1'b0, frame_error_next;
logic [7:0] frame_ptr_reg = '0, frame_ptr_next;
logic [MIN_LEN_W-1:0] frame_min_count_reg = '0, frame_min_count_next;

logic [7:0] gmii_txd_reg = 8'd0, gmii_txd_next;
logic gmii_tx_en_reg = 1'b0, gmii_tx_en_next;
logic gmii_tx_er_reg = 1'b0, gmii_tx_er_next;

logic s_axis_tx_tready_reg = 1'b0, s_axis_tx_tready_next;

logic [PTP_TS_W-1:0] m_axis_tx_cpl_ts_reg = '0, m_axis_tx_cpl_ts_next;
logic [TX_TAG_W-1:0] m_axis_tx_cpl_tag_reg = '0, m_axis_tx_cpl_tag_next;
logic m_axis_tx_cpl_valid_reg = 1'b0, m_axis_tx_cpl_valid_next;

logic start_packet_int_reg = 1'b0, start_packet_int_next;
logic start_packet_reg = 1'b0, start_packet_next;
logic error_underflow_reg = 1'b0, error_underflow_next;

logic [31:0] crc_state = '1;
wire [31:0] crc_next;

assign s_axis_tx.tready = s_axis_tx_tready_reg;

assign gmii_txd = gmii_txd_reg;
assign gmii_tx_en = gmii_tx_en_reg;
assign gmii_tx_er = gmii_tx_er_reg;

assign m_axis_tx_cpl.tdata = PTP_TS_EN ? m_axis_tx_cpl_ts_reg : '0;
assign m_axis_tx_cpl.tkeep = 1'b1;
assign m_axis_tx_cpl.tstrb = m_axis_tx_cpl.tkeep;
assign m_axis_tx_cpl.tvalid = m_axis_tx_cpl_valid_reg;
assign m_axis_tx_cpl.tlast = 1'b1;
assign m_axis_tx_cpl.tid = m_axis_tx_cpl_tag_reg;
assign m_axis_tx_cpl.tdest = '0;
assign m_axis_tx_cpl.tuser = '0;

assign start_packet = start_packet_reg;
assign error_underflow = error_underflow_reg;

taxi_lfsr #(
    .LFSR_W(32),
    .LFSR_POLY(32'h4c11db7),
    .LFSR_GALOIS(1),
    .LFSR_FEED_FORWARD(0),
    .REVERSE(1),
    .DATA_W(8)
)
eth_crc_8 (
    .data_in(s_tdata_reg),
    .state_in(crc_state),
    .data_out(),
    .state_out(crc_next)
);

always_comb begin
    state_next = STATE_IDLE;

    reset_crc = 1'b0;
    update_crc = 1'b0;

    mii_odd_next = mii_odd_reg;
    mii_msn_next = mii_msn_reg;

    frame_next = frame_reg;
    frame_error_next = frame_error_reg;
    frame_ptr_next = frame_ptr_reg;
    frame_min_count_next = frame_min_count_reg;

    s_axis_tx_tready_next = 1'b0;

    s_tdata_next = s_tdata_reg;

    m_axis_tx_cpl_ts_next = m_axis_tx_cpl_ts_reg;
    m_axis_tx_cpl_tag_next = m_axis_tx_cpl_tag_reg;
    m_axis_tx_cpl_valid_next = 1'b0;

    if (start_packet_reg) begin
        m_axis_tx_cpl_ts_next = ptp_ts;
        m_axis_tx_cpl_tag_next = s_axis_tx.tid;
        if (TX_CPL_CTRL_IN_TUSER) begin
            m_axis_tx_cpl_valid_next = (s_axis_tx.tuser >> 1) == 0;
        end else begin
            m_axis_tx_cpl_valid_next = 1'b1;
        end
    end

    gmii_txd_next = '0;
    gmii_tx_en_next = 1'b0;
    gmii_tx_er_next = 1'b0;

    start_packet_int_next = start_packet_int_reg;
    start_packet_next = 1'b0;
    error_underflow_next = 1'b0;

    if (s_axis_tx.tvalid && s_axis_tx.tready) begin
        frame_next = !s_axis_tx.tlast;
    end

    if (!clk_enable) begin
        // clock disabled - hold state and outputs
        gmii_txd_next = gmii_txd_reg;
        gmii_tx_en_next = gmii_tx_en_reg;
        gmii_tx_er_next = gmii_tx_er_reg;
        state_next = state_reg;
    end else if (mii_select && mii_odd_reg) begin
        // MII odd cycle - hold state, output MSN
        mii_odd_next = 1'b0;
        gmii_txd_next = {4'd0, mii_msn_reg};
        gmii_tx_en_next = gmii_tx_en_reg;
        gmii_tx_er_next = gmii_tx_er_reg;
        state_next = state_reg;
        if (start_packet_int_reg) begin
            start_packet_int_next = 1'b0;
            start_packet_next = 1'b1;
        end
    end else begin
        case (state_reg)
            STATE_IDLE: begin
                // idle state - wait for packet
                reset_crc = 1'b1;

                mii_odd_next = 1'b0;
                frame_ptr_next = 1;

                frame_error_next = 1'b0;
                frame_min_count_next = MIN_LEN_W'(MIN_FRAME_LEN-4-1);

                if (s_axis_tx.tvalid && cfg_tx_enable) begin
                    mii_odd_next = 1'b1;
                    gmii_txd_next = ETH_PRE;
                    gmii_tx_en_next = 1'b1;
                    state_next = STATE_PREAMBLE;
                end else begin
                    state_next = STATE_IDLE;
                end
            end
            STATE_PREAMBLE: begin
                // send preamble
                reset_crc = 1'b1;

                mii_odd_next = 1'b1;
                frame_ptr_next = frame_ptr_reg + 1;

                gmii_txd_next = ETH_PRE;
                gmii_tx_en_next = 1'b1;

                if (frame_ptr_reg == 6) begin
                    s_axis_tx_tready_next = 1'b1;
                    s_tdata_next = s_axis_tx.tdata;
                    state_next = STATE_PREAMBLE;
                end else if (frame_ptr_reg == 7) begin
                    // end of preamble; start payload
                    frame_ptr_next = '0;
                    if (s_axis_tx_tready_reg) begin
                        s_axis_tx_tready_next = 1'b1;
                        s_tdata_next = s_axis_tx.tdata;
                    end
                    gmii_txd_next = ETH_SFD;
                    if (mii_select) begin
                        start_packet_int_next = 1'b1;
                    end else begin
                        start_packet_next = 1'b1;
                    end
                    state_next = STATE_PAYLOAD;
                end else begin
                    state_next = STATE_PREAMBLE;
                end
            end
            STATE_PAYLOAD: begin
                // send payload

                update_crc = 1'b1;
                s_axis_tx_tready_next = 1'b1;

                mii_odd_next = 1'b1;

                if (frame_min_count_reg != 0) begin
                    frame_min_count_next = frame_min_count_reg - 1;
                end

                gmii_txd_next = s_tdata_reg;
                gmii_tx_en_next = 1'b1;

                s_tdata_next = s_axis_tx.tdata;

                if (!s_axis_tx.tvalid || s_axis_tx.tlast) begin
                    s_axis_tx_tready_next = frame_next; // drop frame
                    frame_error_next = !s_axis_tx.tvalid || s_axis_tx.tuser[0];
                    error_underflow_next = !s_axis_tx.tvalid;

                    state_next = STATE_LAST;
                end else begin
                    state_next = STATE_PAYLOAD;
                end
            end
            STATE_LAST: begin
                // last payload word

                update_crc = 1'b1;
                s_axis_tx_tready_next = frame_next; // drop frame

                mii_odd_next = 1'b1;

                gmii_txd_next = s_tdata_reg;
                gmii_tx_en_next = 1'b1;

                if (PADDING_EN && frame_min_count_reg != 0) begin
                    frame_min_count_next = frame_min_count_reg - 1;
                    s_tdata_next = 8'd0;
                    state_next = STATE_PAD;
                end else begin
                    frame_ptr_next = '0;
                    state_next = STATE_FCS;
                end
            end
            STATE_PAD: begin
                // send padding
                s_axis_tx_tready_next = frame_next; // drop frame

                update_crc = 1'b1;
                mii_odd_next = 1'b1;

                gmii_txd_next = 8'd0;
                gmii_tx_en_next = 1'b1;

                s_tdata_next = 8'd0;

                if (frame_min_count_reg != 0) begin
                    frame_min_count_next = frame_min_count_reg - 1;
                    state_next = STATE_PAD;
                end else begin
                    frame_ptr_next = '0;
                    state_next = STATE_FCS;
                end
            end
            STATE_FCS: begin
                // send FCS
                s_axis_tx_tready_next = frame_next; // drop frame

                mii_odd_next = 1'b1;
                frame_ptr_next = frame_ptr_reg + 1;

                case (frame_ptr_reg[1:0])
                    2'd0: gmii_txd_next = ~crc_state[7:0];
                    2'd1: gmii_txd_next = ~crc_state[15:8];
                    2'd2: gmii_txd_next = ~crc_state[23:16];
                    2'd3: gmii_txd_next = ~crc_state[31:24];
                endcase
                gmii_tx_en_next = 1'b1;
                gmii_tx_er_next = frame_error_reg;

                if (frame_ptr_reg < 3) begin
                    state_next = STATE_FCS;
                end else begin
                    frame_ptr_next = '0;
                    state_next = STATE_IFG;
                end
            end
            STATE_IFG: begin
                // send IFG
                s_axis_tx_tready_next = frame_next; // drop frame

                mii_odd_next = 1'b1;
                frame_ptr_next = frame_ptr_reg + 1;

                if (frame_ptr_reg < cfg_ifg-1 || frame_reg) begin
                    state_next = STATE_IFG;
                end else begin
                    state_next = STATE_IDLE;
                end
            end
            default: begin
                // invalid state, return to idle
                state_next = STATE_IDLE;
            end
        endcase

        if (mii_select) begin
            mii_msn_next = gmii_txd_next[7:4];
            gmii_txd_next[7:4] = 4'd0;
        end
    end
end

always_ff @(posedge clk) begin
    state_reg <= state_next;

    frame_reg <= frame_next;
    frame_error_reg <= frame_error_next;
    frame_ptr_reg <= frame_ptr_next;
    frame_min_count_reg <= frame_min_count_next;

    m_axis_tx_cpl_ts_reg <= m_axis_tx_cpl_ts_next;
    m_axis_tx_cpl_tag_reg <= m_axis_tx_cpl_tag_next;
    m_axis_tx_cpl_valid_reg <= m_axis_tx_cpl_valid_next;

    mii_odd_reg <= mii_odd_next;
    mii_msn_reg <= mii_msn_next;

    s_tdata_reg <= s_tdata_next;

    s_axis_tx_tready_reg <= s_axis_tx_tready_next;

    gmii_txd_reg <= gmii_txd_next;
    gmii_tx_en_reg <= gmii_tx_en_next;
    gmii_tx_er_reg <= gmii_tx_er_next;

    if (reset_crc) begin
        crc_state <= '1;
    end else if (update_crc) begin
        crc_state <= crc_next;
    end

    start_packet_int_reg <= start_packet_int_next;
    start_packet_reg <= start_packet_next;
    error_underflow_reg <= error_underflow_next;

    if (rst) begin
        state_reg <= STATE_IDLE;

        frame_reg <= 1'b0;

        s_axis_tx_tready_reg <= 1'b0;

        m_axis_tx_cpl_valid_reg <= 1'b0;

        gmii_tx_en_reg <= 1'b0;
        gmii_tx_er_reg <= 1'b0;

        start_packet_int_reg <= 1'b0;
        start_packet_reg <= 1'b0;
        error_underflow_reg <= 1'b0;
    end
end

endmodule

`resetall
