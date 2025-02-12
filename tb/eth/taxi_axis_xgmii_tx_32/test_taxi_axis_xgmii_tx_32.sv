// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream XGMII frame transmitter testbench
 */
module test_taxi_axis_xgmii_tx_32 #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter DATA_W = 32,
    parameter logic PADDING_EN = 1'b1,
    parameter logic DIC_EN = 1'b1,
    parameter MIN_FRAME_LEN = 64,
    parameter logic PTP_TS_EN = 1'b0,
    parameter PTP_TS_W = 96,
    parameter TX_TAG_W = 16,
    parameter logic TX_CPL_CTRL_IN_TUSER = 1'b0
    /* verilator lint_on WIDTHTRUNC */
)
();

localparam CTRL_W = DATA_W/8;
localparam USER_W = TX_CPL_CTRL_IN_TUSER ? 2 : 1;

logic clk;
logic rst;

taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(USER_W), .ID_EN(1), .ID_W(TX_TAG_W)) s_axis_tx();
taxi_axis_if #(.DATA_W(PTP_TS_W), .KEEP_W(1), .ID_EN(1), .ID_W(TX_TAG_W)) m_axis_tx_cpl();

logic [DATA_W-1:0] xgmii_txd;
logic [CTRL_W-1:0] xgmii_txc;

logic [PTP_TS_W-1:0] ptp_ts;

logic [7:0] cfg_ifg;
logic cfg_tx_enable;

logic start_packet;
logic error_underflow;

taxi_axis_xgmii_tx_32 #(
    .DATA_W(DATA_W),
    .CTRL_W(CTRL_W),
    .PADDING_EN(PADDING_EN),
    .DIC_EN(DIC_EN),
    .MIN_FRAME_LEN(MIN_FRAME_LEN),
    .PTP_TS_EN(PTP_TS_EN),
    .PTP_TS_W(PTP_TS_W),
    .TX_CPL_CTRL_IN_TUSER(TX_CPL_CTRL_IN_TUSER)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis_tx(s_axis_tx),
    .m_axis_tx_cpl(m_axis_tx_cpl),

    /*
     * XGMII output
     */
    .xgmii_txd(xgmii_txd),
    .xgmii_txc(xgmii_txc),

    /*
     * PTP
     */
    .ptp_ts(ptp_ts),

    /*
     * Configuration
     */
    .cfg_ifg(cfg_ifg),
    .cfg_tx_enable(cfg_tx_enable),

    /*
     * Status
     */
    .start_packet(start_packet),
    .error_underflow(error_underflow)
);

endmodule

`resetall
