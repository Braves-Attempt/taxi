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
 * AXI4-Stream XGMII frame transmitter (AXI in, XGMII out)
 */
module taxi_axis_xgmii_tx_32 #
(
    parameter DATA_W = 32,
    parameter CTRL_W = (DATA_W/8),
    parameter logic PADDING_EN = 1'b1,
    parameter logic DIC_EN = 1'b1,
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
     * XGMII output
     */
    output wire logic [DATA_W-1:0]    xgmii_txd,
    output wire logic [CTRL_W-1:0]    xgmii_txc,

    /*
     * PTP
     */
    input  wire logic [PTP_TS_W-1:0]  ptp_ts,

    /*
     * Configuration
     */
    input  wire logic [7:0]           cfg_ifg = 8'd12,
    input  wire logic                 cfg_tx_enable,

    /*
     * Status
     */
    output wire logic                 start_packet,
    output wire logic                 error_underflow
);

// extract parameters
localparam KEEP_W = DATA_W/8;
localparam USER_W = TX_CPL_CTRL_IN_TUSER ? 2 : 1;
localparam TX_TAG_W = s_axis_tx.ID_W;

localparam EMPTY_W = $clog2(KEEP_W);
localparam MIN_LEN_W = $clog2(MIN_FRAME_LEN-4-CTRL_W+1);

// check configuration
if (DATA_W != 32)
    $fatal(0, "Error: Interface width must be 32 (instance %m)");

if (KEEP_W*8 != DATA_W || CTRL_W*8 != DATA_W)
    $fatal(0, "Error: Interface requires byte (8-bit) granularity (instance %m)");

if (s_axis_tx.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (s_axis_tx.USER_W != USER_W)
    $fatal(0, "Error: Interface USER_W parameter mismatch (instance %m)");

localparam [7:0]
    ETH_PRE = 8'h55,
    ETH_SFD = 8'hD5;

localparam [7:0]
    XGMII_IDLE = 8'h07,
    XGMII_START = 8'hfb,
    XGMII_TERM = 8'hfd,
    XGMII_ERROR = 8'hfe;

localparam [3:0]
    STATE_IDLE = 4'd0,
    STATE_PREAMBLE = 4'd1,
    STATE_PAYLOAD = 4'd2,
    STATE_PAD = 4'd3,
    STATE_FCS_1 = 4'd4,
    STATE_FCS_2 = 4'd5,
    STATE_FCS_3 = 4'd6,
    STATE_ERR = 4'd7,
    STATE_IFG = 4'd8;

logic [3:0] state_reg = STATE_IDLE, state_next;

// datapath control signals
logic reset_crc;
logic update_crc;

logic [DATA_W-1:0] s_tdata_reg = '0, s_tdata_next;
logic [EMPTY_W-1:0] s_empty_reg = '0, s_empty_next;

logic [DATA_W-1:0] fcs_output_txd_0;
logic [DATA_W-1:0] fcs_output_txd_1;
logic [CTRL_W-1:0] fcs_output_txc_0;
logic [CTRL_W-1:0] fcs_output_txc_1;

logic [7:0] ifg_offset;

logic extra_cycle;

logic frame_reg = 1'b0, frame_next;
logic frame_error_reg = 1'b0, frame_error_next;
logic [MIN_LEN_W-1:0] frame_min_count_reg = '0, frame_min_count_next;

logic [7:0] ifg_count_reg = 8'd0, ifg_count_next;
logic [1:0] deficit_idle_count_reg = 2'd0, deficit_idle_count_next;

logic s_axis_tx_tready_reg = 1'b0, s_axis_tx_tready_next;

logic [PTP_TS_W-1:0] m_axis_tx_cpl_ts_reg = '0, m_axis_tx_cpl_ts_next;
logic [TX_TAG_W-1:0] m_axis_tx_cpl_tag_reg = '0, m_axis_tx_cpl_tag_next;
logic m_axis_tx_cpl_valid_reg = 1'b0, m_axis_tx_cpl_valid_next;

logic [31:0] crc_state_reg[3:0];
wire [31:0] crc_state_next[3:0];

logic [DATA_W-1:0] xgmii_txd_reg = {CTRL_W{XGMII_IDLE}}, xgmii_txd_next;
logic [CTRL_W-1:0] xgmii_txc_reg = {CTRL_W{1'b1}}, xgmii_txc_next;

logic start_packet_reg = 1'b0, start_packet_next;
logic error_underflow_reg = 1'b0, error_underflow_next;

assign s_axis_tx.tready = s_axis_tx_tready_reg;

assign xgmii_txd = xgmii_txd_reg;
assign xgmii_txc = xgmii_txc_reg;

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

for (genvar n = 0; n < 4; n = n + 1) begin : crc

    taxi_lfsr #(
        .LFSR_W(32),
        .LFSR_POLY(32'h4c11db7),
        .LFSR_GALOIS(1),
        .LFSR_FEED_FORWARD(0),
        .REVERSE(1),
        .DATA_W(8*(n+1))
    )
    eth_crc (
        .data_in(s_tdata_reg[0 +: 8*(n+1)]),
        .state_in(crc_state_reg[3]),
        .data_out(),
        .state_out(crc_state_next[n])
    );

end

function [1:0] keep2empty(input [3:0] k);
    casez (k)
        4'bzzz0: keep2empty = 2'd3;
        4'bzz01: keep2empty = 2'd3;
        4'bz011: keep2empty = 2'd2;
        4'b0111: keep2empty = 2'd1;
        4'b1111: keep2empty = 2'd0;
    endcase
endfunction

// Mask input data
wire [DATA_W-1:0] s_axis_tx_tdata_masked;

for (genvar n = 0; n < CTRL_W; n = n + 1) begin
    assign s_axis_tx_tdata_masked[n*8 +: 8] = s_axis_tx.tkeep[n] ? s_axis_tx.tdata[n*8 +: 8] : 8'd0;
end

// FCS cycle calculation
always_comb begin
    casez (s_empty_reg)
        2'd3: begin
            fcs_output_txd_0 = {~crc_state_next[0][23:0], s_tdata_reg[7:0]};
            fcs_output_txd_1 = {{2{XGMII_IDLE}}, XGMII_TERM, ~crc_state_reg[0][31:24]};
            fcs_output_txc_0 = 4'b0000;
            fcs_output_txc_1 = 4'b1110;
            ifg_offset = 8'd3;
            extra_cycle = 1'b0;
        end
        2'd2: begin
            fcs_output_txd_0 = {~crc_state_next[1][15:0], s_tdata_reg[15:0]};
            fcs_output_txd_1 = {XGMII_IDLE, XGMII_TERM, ~crc_state_reg[1][31:16]};
            fcs_output_txc_0 = 4'b0000;
            fcs_output_txc_1 = 4'b1100;
            ifg_offset = 8'd2;
            extra_cycle = 1'b0;
        end
        2'd1: begin
            fcs_output_txd_0 = {~crc_state_next[2][7:0], s_tdata_reg[23:0]};
            fcs_output_txd_1 = {XGMII_TERM, ~crc_state_reg[2][31:8]};
            fcs_output_txc_0 = 4'b0000;
            fcs_output_txc_1 = 4'b1000;
            ifg_offset = 8'd1;
            extra_cycle = 1'b0;
        end
        2'd0: begin
            fcs_output_txd_0 = s_tdata_reg;
            fcs_output_txd_1 = ~crc_state_reg[3];
            fcs_output_txc_0 = 4'b0000;
            fcs_output_txc_1 = 4'b0000;
            ifg_offset = 8'd4;
            extra_cycle = 1'b1;
        end
    endcase
end

always_comb begin
    state_next = STATE_IDLE;

    reset_crc = 1'b0;
    update_crc = 1'b0;

    frame_next = frame_reg;
    frame_error_next = frame_error_reg;
    frame_min_count_next = frame_min_count_reg;

    ifg_count_next = ifg_count_reg;
    deficit_idle_count_next = deficit_idle_count_reg;

    s_axis_tx_tready_next = 1'b0;

    s_tdata_next = s_tdata_reg;
    s_empty_next = s_empty_reg;

    m_axis_tx_cpl_ts_next = m_axis_tx_cpl_ts_reg;
    m_axis_tx_cpl_tag_next = m_axis_tx_cpl_tag_reg;
    m_axis_tx_cpl_valid_next = 1'b0;

    if (start_packet_reg) begin
        if (PTP_TS_EN) begin
            m_axis_tx_cpl_ts_next = ptp_ts;
        end
        m_axis_tx_cpl_tag_next = s_axis_tx.tid;
        if (TX_CPL_CTRL_IN_TUSER) begin
            m_axis_tx_cpl_valid_next = (s_axis_tx.tuser >> 1) == 0;
        end else begin
            m_axis_tx_cpl_valid_next = 1'b1;
        end
    end

    // XGMII idle
    xgmii_txd_next = {CTRL_W{XGMII_IDLE}};
    xgmii_txc_next = {CTRL_W{1'b1}};

    start_packet_next = 1'b0;
    error_underflow_next = 1'b0;

    if (s_axis_tx.tvalid && s_axis_tx.tready) begin
        frame_next = !s_axis_tx.tlast;
    end

    case (state_reg)
        STATE_IDLE: begin
            // idle state - wait for data
            frame_error_next = 1'b0;
            frame_min_count_next = MIN_LEN_W'(MIN_FRAME_LEN-4-CTRL_W);
            reset_crc = 1'b1;

            // XGMII idle
            xgmii_txd_next = {CTRL_W{XGMII_IDLE}};
            xgmii_txc_next = {CTRL_W{1'b1}};

            s_tdata_next = s_axis_tx_tdata_masked;
            s_empty_next = keep2empty(s_axis_tx.tkeep);

            if (s_axis_tx.tvalid && cfg_tx_enable) begin
                // XGMII start and preamble
                xgmii_txd_next = {{3{ETH_PRE}}, XGMII_START};
                xgmii_txc_next = 4'b0001;
                s_axis_tx_tready_next = 1'b1;
                state_next = STATE_PREAMBLE;
            end else begin
                ifg_count_next = 8'd0;
                deficit_idle_count_next = 2'd0;
                state_next = STATE_IDLE;
            end
        end
        STATE_PREAMBLE: begin
            // send preamble
            reset_crc = 1'b1;

            s_tdata_next = s_axis_tx_tdata_masked;
            s_empty_next = keep2empty(s_axis_tx.tkeep);

            xgmii_txd_next = {ETH_SFD, {3{ETH_PRE}}};
            xgmii_txc_next = {CTRL_W{1'b0}};

            s_axis_tx_tready_next = 1'b1;
            start_packet_next = 1'b1;
            state_next = STATE_PAYLOAD;
        end
        STATE_PAYLOAD: begin
            // transfer payload
            update_crc = 1'b1;
            s_axis_tx_tready_next = 1'b1;

            if (frame_min_count_reg > MIN_LEN_W'(CTRL_W)) begin
                frame_min_count_next = MIN_LEN_W'(frame_min_count_reg - CTRL_W);
            end else begin
                frame_min_count_next = 0;
            end

            xgmii_txd_next = s_tdata_reg;
            xgmii_txc_next = {CTRL_W{1'b0}};

            s_tdata_next = s_axis_tx_tdata_masked;
            s_empty_next = keep2empty(s_axis_tx.tkeep);

            if (!s_axis_tx.tvalid || s_axis_tx.tlast) begin
                s_axis_tx_tready_next = frame_next; // drop frame
                frame_error_next = !s_axis_tx.tvalid || s_axis_tx.tuser[0];
                error_underflow_next = !s_axis_tx.tvalid;

                if (PADDING_EN && frame_min_count_reg != 0) begin
                    if (frame_min_count_reg > MIN_LEN_W'(CTRL_W)) begin
                        s_empty_next = 0;
                        state_next = STATE_PAD;
                    end else begin
                        if (keep2empty(s_axis_tx.tkeep) > 2'(CTRL_W-frame_min_count_reg)) begin
                            s_empty_next = 2'(CTRL_W-frame_min_count_reg);
                        end
                        state_next = STATE_FCS_1;
                    end
                end else begin
                    state_next = STATE_FCS_1;
                end
            end else begin
                state_next = STATE_PAYLOAD;
            end
        end
        STATE_PAD: begin
            // pad frame to MIN_FRAME_LEN
            s_axis_tx_tready_next = frame_next; // drop frame

            xgmii_txd_next = s_tdata_reg;
            xgmii_txc_next = {CTRL_W{1'b0}};

            s_tdata_next = 32'd0;
            s_empty_next = 0;

            update_crc = 1'b1;

            if (frame_min_count_reg > MIN_LEN_W'(CTRL_W)) begin
                frame_min_count_next = MIN_LEN_W'(frame_min_count_reg - CTRL_W);
                state_next = STATE_PAD;
            end else begin
                frame_min_count_next = 0;
                s_empty_next = 2'(CTRL_W-frame_min_count_reg);
                state_next = STATE_FCS_1;
            end
        end
        STATE_FCS_1: begin
            // last cycle
            s_axis_tx_tready_next = frame_next; // drop frame

            xgmii_txd_next = fcs_output_txd_0;
            xgmii_txc_next = fcs_output_txc_0;

            update_crc = 1'b1;

            ifg_count_next = (cfg_ifg > 8'd12 ? cfg_ifg : 8'd12) - ifg_offset + 8'(deficit_idle_count_reg);
            if (frame_error_reg) begin
                state_next = STATE_ERR;
            end else begin
                state_next = STATE_FCS_2;
            end
        end
        STATE_FCS_2: begin
            // last cycle
            s_axis_tx_tready_next = frame_next; // drop frame

            xgmii_txd_next = fcs_output_txd_1;
            xgmii_txc_next = fcs_output_txc_1;

            if (extra_cycle) begin
                state_next = STATE_FCS_3;
            end else begin
                state_next = STATE_IFG;
            end
        end
        STATE_FCS_3: begin
            // last cycle
            s_axis_tx_tready_next = frame_next; // drop frame

            xgmii_txd_next = {{3{XGMII_IDLE}}, XGMII_TERM};
            xgmii_txc_next = {CTRL_W{1'b1}};

            if (DIC_EN) begin
                if (ifg_count_next > 8'd3) begin
                    state_next = STATE_IFG;
                end else begin
                    deficit_idle_count_next = 2'(ifg_count_next);
                    ifg_count_next = 8'd0;
                    s_axis_tx_tready_next = 1'b1;
                    state_next = STATE_IDLE;
                end
            end else begin
                if (ifg_count_next > 8'd0) begin
                    state_next = STATE_IFG;
                end else begin
                    state_next = STATE_IDLE;
                end
            end
        end
        STATE_ERR: begin
            // terminate packet with error
            s_axis_tx_tready_next = frame_next; // drop frame

            // XGMII error
            xgmii_txd_next = {XGMII_TERM, {3{XGMII_ERROR}}};
            xgmii_txc_next = {CTRL_W{1'b1}};

            ifg_count_next = cfg_ifg > 8'd12 ? cfg_ifg : 8'd12;

            state_next = STATE_IFG;
        end
        STATE_IFG: begin
            // send IFG
            s_axis_tx_tready_next = frame_next; // drop frame

            // XGMII idle
            xgmii_txd_next = {CTRL_W{XGMII_IDLE}};
            xgmii_txc_next = {CTRL_W{1'b1}};

            if (ifg_count_reg > 8'd4) begin
                ifg_count_next = ifg_count_reg - 8'd4;
            end else begin
                ifg_count_next = 8'd0;
            end

            if (DIC_EN) begin
                if (ifg_count_next > 8'd3 || frame_reg) begin
                    state_next = STATE_IFG;
                end else begin
                    deficit_idle_count_next = 2'(ifg_count_next);
                    ifg_count_next = 8'd0;
                    state_next = STATE_IDLE;
                end
            end else begin
                if (ifg_count_next > 8'd0 || frame_reg) begin
                    state_next = STATE_IFG;
                end else begin
                    state_next = STATE_IDLE;
                end
            end
        end
        default: begin
            // invalid state, return to idle
            state_next = STATE_IDLE;
        end
    endcase
end

always_ff @(posedge clk) begin
    state_reg <= state_next;

    frame_reg <= frame_next;
    frame_error_reg <= frame_error_next;
    frame_min_count_reg <= frame_min_count_next;

    ifg_count_reg <= ifg_count_next;
    deficit_idle_count_reg <= deficit_idle_count_next;

    s_tdata_reg <= s_tdata_next;
    s_empty_reg <= s_empty_next;

    s_axis_tx_tready_reg <= s_axis_tx_tready_next;

    m_axis_tx_cpl_ts_reg <= m_axis_tx_cpl_ts_next;
    m_axis_tx_cpl_tag_reg <= m_axis_tx_cpl_tag_next;
    m_axis_tx_cpl_valid_reg <= m_axis_tx_cpl_valid_next;

    for (integer i = 0; i < 3; i = i + 1) begin
        crc_state_reg[i] <= crc_state_next[i];
    end

    if (update_crc) begin
        crc_state_reg[3] <= crc_state_next[3];
    end

    if (reset_crc) begin
        crc_state_reg[3] <= '1;
    end

    xgmii_txd_reg <= xgmii_txd_next;
    xgmii_txc_reg <= xgmii_txc_next;

    start_packet_reg <= start_packet_next;
    error_underflow_reg <= error_underflow_next;

    if (rst) begin
        state_reg <= STATE_IDLE;

        frame_reg <= 1'b0;

        ifg_count_reg <= 8'd0;
        deficit_idle_count_reg <= 2'd0;

        s_axis_tx_tready_reg <= 1'b0;

        m_axis_tx_cpl_valid_reg <= 1'b0;

        xgmii_txd_reg <= {CTRL_W{XGMII_IDLE}};
        xgmii_txc_reg <= {CTRL_W{1'b1}};

        start_packet_reg <= 1'b0;
        error_underflow_reg <= 1'b0;
    end
end

endmodule

`resetall
