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
 * AXI4-Stream GMII frame receiver testbench
 */
module test_taxi_axis_gmii_rx #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter DATA_W = 8,
    parameter logic PTP_TS_EN = 1'b0,
    parameter PTP_TS_W = 96
    /* verilator lint_on WIDTHTRUNC */
)
();

localparam USER_W = (PTP_TS_EN ? PTP_TS_W : 0) + 1;

logic clk;
logic rst;

logic [DATA_W-1:0] gmii_rxd;
logic gmii_rx_dv;
logic gmii_rx_er;

taxi_axis_if #(.DATA_W(DATA_W), .USER_W(USER_W)) m_axis_rx();

logic [PTP_TS_W-1:0] ptp_ts;

logic clk_enable;
logic mii_select;

logic cfg_rx_enable;

logic start_packet;
logic error_bad_frame;
logic error_bad_fcs;

taxi_axis_gmii_rx #(
    .DATA_W(DATA_W),
    .PTP_TS_EN(PTP_TS_EN),
    .PTP_TS_W(PTP_TS_W)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * GMII input
     */
    .gmii_rxd(gmii_rxd),
    .gmii_rx_dv(gmii_rx_dv),
    .gmii_rx_er(gmii_rx_er),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis_rx(m_axis_rx),

    /*
     * PTP
     */
    .ptp_ts(ptp_ts),

    /*
     * Control
     */
    .clk_enable(clk_enable),
    .mii_select(mii_select),

    /*
     * Configuration
     */
    .cfg_rx_enable(cfg_rx_enable),

    /*
     * Status
     */
    .start_packet(start_packet),
    .error_bad_frame(error_bad_frame),
    .error_bad_fcs(error_bad_fcs)
);

endmodule

`resetall
