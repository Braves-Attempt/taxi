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
 * AXI4-Stream XGMII frame receiver (XGMII in, AXI out)
 */
module taxi_axis_xgmii_rx_64 #
(
    parameter DATA_W = 64,
    parameter CTRL_W = (DATA_W/8),
    parameter logic PTP_TS_EN = 1'b0,
    parameter logic PTP_TS_FMT_TOD = 1'b1,
    parameter PTP_TS_W = PTP_TS_FMT_TOD ? 96 : 64
)
(
    input  wire logic                 clk,
    input  wire logic                 rst,

    /*
     * XGMII input
     */
    input  wire logic [DATA_W-1:0]    xgmii_rxd,
    input  wire logic [CTRL_W-1:0]    xgmii_rxc,

    /*
     * Receive interface (AXI stream)
     */
    taxi_axis_if.src                  m_axis_rx,

    /*
     * PTP
     */
    input  wire logic [PTP_TS_W-1:0]  ptp_ts,

    /*
     * Configuration
     */
    input  wire logic                 cfg_rx_enable,

    /*
     * Status
     */
    output wire logic [1:0]           start_packet,
    output wire logic                 error_bad_frame,
    output wire logic                 error_bad_fcs
);

// extract parameters
localparam KEEP_W = DATA_W/8;
localparam USER_W = (PTP_TS_EN ? PTP_TS_W : 0) + 1;

// check configuration
if (DATA_W != 64)
    $fatal(0, "Error: Interface width must be 64 (instance %m)");

if (KEEP_W*8 != DATA_W || CTRL_W*8 != DATA_W)
    $fatal(0, "Error: Interface requires byte (8-bit) granularity (instance %m)");

if (m_axis_rx.DATA_W != DATA_W)
    $fatal(0, "Error: Interface DATA_W parameter mismatch (instance %m)");

if (m_axis_rx.USER_W != USER_W)
    $fatal(0, "Error: Interface USER_W parameter mismatch (instance %m)");

localparam [7:0]
    ETH_PRE = 8'h55,
    ETH_SFD = 8'hD5;

localparam [7:0]
    XGMII_IDLE = 8'h07,
    XGMII_START = 8'hfb,
    XGMII_TERM = 8'hfd,
    XGMII_ERROR = 8'hfe;

localparam [1:0]
    STATE_IDLE = 2'd0,
    STATE_PAYLOAD = 2'd1,
    STATE_LAST = 2'd2;

logic [1:0] state_reg = STATE_IDLE, state_next;

// datapath control signals
logic reset_crc;

logic lanes_swapped = 1'b0;
logic [31:0] swap_rxd = 32'd0;
logic [3:0] swap_rxc = 4'd0;
logic [3:0] swap_rxc_term = 4'd0;

logic [2:0] term_lane_reg = 0, term_lane_d0_reg = 0;
logic term_present_reg = 1'b0;
logic framing_error_reg = 1'b0, framing_error_d0_reg = 1'b0;

logic [DATA_W-1:0] xgmii_rxd_d0 = '0;
logic [DATA_W-1:0] xgmii_rxd_d1 = '0;

logic [CTRL_W-1:0] xgmii_rxc_d0 = '0;

logic xgmii_start_swap = 1'b0;
logic xgmii_start_d0 = 1'b0;
logic xgmii_start_d1 = 1'b0;

logic [DATA_W-1:0] m_axis_rx_tdata_reg = '0, m_axis_rx_tdata_next;
logic [KEEP_W-1:0] m_axis_rx_tkeep_reg = '0, m_axis_rx_tkeep_next;
logic m_axis_rx_tvalid_reg = 1'b0, m_axis_rx_tvalid_next;
logic m_axis_rx_tlast_reg = 1'b0, m_axis_rx_tlast_next;
logic m_axis_rx_tuser_reg = 1'b0, m_axis_rx_tuser_next;

logic [1:0] start_packet_reg = 2'b00;
logic error_bad_frame_reg = 1'b0, error_bad_frame_next;
logic error_bad_fcs_reg = 1'b0, error_bad_fcs_next;

logic [PTP_TS_W-1:0] ptp_ts_reg = '0;
logic [PTP_TS_W-1:0] ptp_ts_out_reg = '0, ptp_ts_out_next;
logic [PTP_TS_W-1:0] ptp_ts_adj_reg = '0;
logic ptp_ts_borrow_reg = '0;

logic [31:0] crc_state = '1;

wire [31:0] crc_next;

wire [7:0] crc_valid;
logic [7:0] crc_valid_save;

assign crc_valid[7] = crc_next == ~32'h2144df1c;
assign crc_valid[6] = crc_next == ~32'hc622f71d;
assign crc_valid[5] = crc_next == ~32'hb1c2a1a3;
assign crc_valid[4] = crc_next == ~32'h9d6cdf7e;
assign crc_valid[3] = crc_next == ~32'h6522df69;
assign crc_valid[2] = crc_next == ~32'he60914ae;
assign crc_valid[1] = crc_next == ~32'he38a6876;
assign crc_valid[0] = crc_next == ~32'h6b87b1ec;

logic [4+16-1:0] last_ts_reg = '0;
logic [4+16-1:0] ts_inc_reg = '0;

assign m_axis_rx.tdata = m_axis_rx_tdata_reg;
assign m_axis_rx.tkeep = m_axis_rx_tkeep_reg;
assign m_axis_rx.tstrb = m_axis_rx.tkeep;
assign m_axis_rx.tvalid = m_axis_rx_tvalid_reg;
assign m_axis_rx.tlast = m_axis_rx_tlast_reg;
assign m_axis_rx.tid = '0;
assign m_axis_rx.tdest = '0;
assign m_axis_rx.tuser[0] = m_axis_rx_tuser_reg;
if (PTP_TS_EN) begin
    assign m_axis_rx.tuser[1 +: PTP_TS_W] = ptp_ts_out_reg;
end

assign start_packet = start_packet_reg;
assign error_bad_frame = error_bad_frame_reg;
assign error_bad_fcs = error_bad_fcs_reg;

taxi_lfsr #(
    .LFSR_W(32),
    .LFSR_POLY(32'h4c11db7),
    .LFSR_GALOIS(1),
    .LFSR_FEED_FORWARD(0),
    .REVERSE(1),
    .DATA_W(64)
)
eth_crc (
    .data_in(xgmii_rxd_d0),
    .state_in(crc_state),
    .data_out(),
    .state_out(crc_next)
);

// Mask input data
wire [DATA_W-1:0] xgmii_rxd_masked;
wire [CTRL_W-1:0] xgmii_term;

for (genvar n = 0; n < CTRL_W; n = n + 1) begin
    assign xgmii_rxd_masked[n*8 +: 8] = xgmii_rxc[n] ? 8'd0 : xgmii_rxd[n*8 +: 8];
    assign xgmii_term[n] = xgmii_rxc[n] && (xgmii_rxd[n*8 +: 8] == XGMII_TERM);
end

always_comb begin
    state_next = STATE_IDLE;

    reset_crc = 1'b0;

    m_axis_rx_tdata_next = xgmii_rxd_d1;
    m_axis_rx_tkeep_next = {KEEP_W{1'b1}};
    m_axis_rx_tvalid_next = 1'b0;
    m_axis_rx_tlast_next = 1'b0;
    m_axis_rx_tuser_next = 1'b0;

    ptp_ts_out_next = ptp_ts_out_reg;

    error_bad_frame_next = 1'b0;
    error_bad_fcs_next = 1'b0;

    case (state_reg)
        STATE_IDLE: begin
            // idle state - wait for packet
            reset_crc = 1'b1;

            if (xgmii_start_d1 && cfg_rx_enable) begin
                // start condition

                reset_crc = 1'b0;
                state_next = STATE_PAYLOAD;
            end else begin
                state_next = STATE_IDLE;
            end
        end
        STATE_PAYLOAD: begin
            // read payload
            m_axis_rx_tdata_next = xgmii_rxd_d1;
            m_axis_rx_tkeep_next = {KEEP_W{1'b1}};
            m_axis_rx_tvalid_next = 1'b1;
            m_axis_rx_tlast_next = 1'b0;
            m_axis_rx_tuser_next = 1'b0;

            if (PTP_TS_EN) begin
                ptp_ts_out_next = (!PTP_TS_FMT_TOD || ptp_ts_borrow_reg) ? ptp_ts_reg : ptp_ts_adj_reg;
            end

            if (framing_error_reg || framing_error_d0_reg) begin
                // control or error characters in packet
                m_axis_rx_tlast_next = 1'b1;
                m_axis_rx_tuser_next = 1'b1;
                error_bad_frame_next = 1'b1;
                reset_crc = 1'b1;
                state_next = STATE_IDLE;
            end else if (term_present_reg) begin
                reset_crc = 1'b1;
                if (term_lane_reg <= 4) begin
                    // end this cycle
                    m_axis_rx_tkeep_next = {KEEP_W{1'b1}} >> 3'(CTRL_W-4-term_lane_reg);
                    m_axis_rx_tlast_next = 1'b1;
                    if ((term_lane_reg == 0 && crc_valid_save[7]) ||
                        (term_lane_reg == 1 && crc_valid[0]) ||
                        (term_lane_reg == 2 && crc_valid[1]) ||
                        (term_lane_reg == 3 && crc_valid[2]) ||
                        (term_lane_reg == 4 && crc_valid[3])) begin
                        // CRC valid
                    end else begin
                        m_axis_rx_tuser_next = 1'b1;
                        error_bad_frame_next = 1'b1;
                        error_bad_fcs_next = 1'b1;
                    end
                    state_next = STATE_IDLE;
                end else begin
                    // need extra cycle
                    state_next = STATE_LAST;
                end
            end else begin
                state_next = STATE_PAYLOAD;
            end
        end
        STATE_LAST: begin
            // last cycle of packet
            m_axis_rx_tdata_next = xgmii_rxd_d1;
            m_axis_rx_tkeep_next = {KEEP_W{1'b1}} >> 3'(CTRL_W+4-term_lane_d0_reg);
            m_axis_rx_tvalid_next = 1'b1;
            m_axis_rx_tlast_next = 1'b1;
            m_axis_rx_tuser_next = 1'b0;

            reset_crc = 1'b1;

            if ((term_lane_d0_reg == 5 && crc_valid_save[4]) ||
                (term_lane_d0_reg == 6 && crc_valid_save[5]) ||
                (term_lane_d0_reg == 7 && crc_valid_save[6])) begin
                // CRC valid
            end else begin
                m_axis_rx_tuser_next = 1'b1;
                error_bad_frame_next = 1'b1;
                error_bad_fcs_next = 1'b1;
            end

            if (xgmii_start_d1 && cfg_rx_enable) begin
                // start condition

                reset_crc = 1'b0;
                state_next = STATE_PAYLOAD;
            end else begin
                state_next = STATE_IDLE;
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

    m_axis_rx_tdata_reg <= m_axis_rx_tdata_next;
    m_axis_rx_tkeep_reg <= m_axis_rx_tkeep_next;
    m_axis_rx_tvalid_reg <= m_axis_rx_tvalid_next;
    m_axis_rx_tlast_reg <= m_axis_rx_tlast_next;
    m_axis_rx_tuser_reg <= m_axis_rx_tuser_next;

    ptp_ts_out_reg <= ptp_ts_out_next;

    start_packet_reg <= 2'b00;
    error_bad_frame_reg <= error_bad_frame_next;
    error_bad_fcs_reg <= error_bad_fcs_next;

    swap_rxd <= xgmii_rxd_masked[63:32];
    swap_rxc <= xgmii_rxc[7:4];
    swap_rxc_term <= xgmii_term[7:4];

    xgmii_start_swap <= 1'b0;
    xgmii_start_d0 <= xgmii_start_swap;

    if (PTP_TS_EN && PTP_TS_FMT_TOD) begin
        // ns field rollover
        ptp_ts_adj_reg[15:0] <= ptp_ts_reg[15:0];
        {ptp_ts_borrow_reg, ptp_ts_adj_reg[45:16]} <= $signed({1'b0, ptp_ts_reg[45:16]}) - $signed(31'd1000000000);
        ptp_ts_adj_reg[47:46] <= 0;
        ptp_ts_adj_reg[95:48] <= ptp_ts_reg[95:48] + 1;
    end

    // lane swapping and termination character detection
    if (lanes_swapped) begin
        xgmii_rxd_d0 <= {xgmii_rxd_masked[31:0], swap_rxd};
        xgmii_rxc_d0 <= {xgmii_rxc[3:0], swap_rxc};

        term_lane_reg <= 0;
        term_present_reg <= 1'b0;
        framing_error_reg <= {xgmii_rxc[3:0], swap_rxc} != 0;

        for (integer i = CTRL_W-1; i >= 0; i = i - 1) begin
            if ({xgmii_term[3:0], swap_rxc_term}[i]) begin
                term_lane_reg <= 3'(i);
                term_present_reg <= 1'b1;
                framing_error_reg <= ({xgmii_rxc[3:0], swap_rxc} & ({CTRL_W{1'b1}} >> (CTRL_W-i))) != 0;
                lanes_swapped <= 1'b0;
            end
        end
    end else begin
        xgmii_rxd_d0 <= xgmii_rxd_masked;
        xgmii_rxc_d0 <= xgmii_rxc;

        term_lane_reg <= 0;
        term_present_reg <= 1'b0;
        framing_error_reg <= xgmii_rxc != 0;

        for (integer i = CTRL_W-1; i >= 0; i = i - 1) begin
            if (xgmii_rxc[i] && (xgmii_rxd[i*8 +: 8] == XGMII_TERM)) begin
                term_lane_reg <= 3'(i);
                term_present_reg <= 1'b1;
                framing_error_reg <= (xgmii_rxc & ({CTRL_W{1'b1}} >> (CTRL_W-i))) != 0;
                lanes_swapped <= 1'b0;
            end
        end
    end

    // start control character detection
    if (xgmii_rxc[0] && xgmii_rxd[7:0] == XGMII_START) begin
        lanes_swapped <= 1'b0;

        xgmii_start_d0 <= 1'b1;

        term_lane_reg <= 0;
        term_present_reg <= 1'b0;
        framing_error_reg <= xgmii_rxc[7:1] != 0;
    end else if (xgmii_rxc[4] && xgmii_rxd[39:32] == XGMII_START) begin
        lanes_swapped <= 1'b1;

        xgmii_start_swap <= 1'b1;

        term_lane_reg <= 0;
        term_present_reg <= 1'b0;
        framing_error_reg <= xgmii_rxc[7:5] != 0;
    end

    // capture timestamps
    if (xgmii_start_swap) begin
        start_packet_reg <= 2'b10;
        if (PTP_TS_FMT_TOD) begin
            ptp_ts_reg[45:0] <= ptp_ts[45:0] + 46'(ts_inc_reg >> 1);
            ptp_ts_reg[95:48] <= ptp_ts[95:48];
        end else begin
            ptp_ts_reg <= ptp_ts + PTP_TS_W'(ts_inc_reg >> 1);
        end
    end

    if (xgmii_start_d0) begin
        if (!lanes_swapped) begin
            start_packet_reg <= 2'b01;
            ptp_ts_reg <= ptp_ts;
        end
    end

    term_lane_d0_reg <= term_lane_reg;
    framing_error_d0_reg <= framing_error_reg;

    if (reset_crc) begin
        crc_state <= '1;
    end else begin
        crc_state <= crc_next;
    end

    crc_valid_save <= crc_valid;

    xgmii_rxd_d1 <= xgmii_rxd_d0;
    xgmii_start_d1 <= xgmii_start_d0;

    last_ts_reg <= (4+16)'(ptp_ts);
    ts_inc_reg <= (4+16)'(ptp_ts) - last_ts_reg;

    if (rst) begin
        state_reg <= STATE_IDLE;

        m_axis_rx_tvalid_reg <= 1'b0;

        start_packet_reg <= 2'b00;
        error_bad_frame_reg <= 1'b0;
        error_bad_fcs_reg <= 1'b0;

        xgmii_rxc_d0 <= '0;

        xgmii_start_swap <= 1'b0;
        xgmii_start_d0 <= 1'b0;
        xgmii_start_d1 <= 1'b0;

        lanes_swapped <= 1'b0;
    end
end

endmodule

`resetall
