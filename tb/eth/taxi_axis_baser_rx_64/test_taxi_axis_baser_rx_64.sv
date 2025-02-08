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
 * AXI4-Stream 10GBASE-R frame receiver testbench
 */
module test_taxi_axis_baser_rx_64 #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter DATA_W = 64,
    parameter HDR_W = 2,
    parameter logic PTP_TS_EN = 1'b0,
    parameter logic PTP_TS_FMT_TOD = 1'b1,
    parameter PTP_TS_W = PTP_TS_FMT_TOD ? 96 : 64
    /* verilator lint_on WIDTHTRUNC */
)
();

localparam USER_W = (PTP_TS_EN ? PTP_TS_W : 0) + 1;

logic clk;
logic rst;

logic [DATA_W-1:0] encoded_rx_data;
logic [HDR_W-1:0] encoded_rx_hdr;

taxi_axis_if #(.DATA_W(DATA_W), .USER_W(USER_W)) m_axis_rx();

logic [PTP_TS_W-1:0] ptp_ts;

logic cfg_rx_enable;

logic [1:0] start_packet;
logic error_bad_frame;
logic error_bad_fcs;
logic rx_bad_block;
logic rx_sequence_error;

taxi_axis_baser_rx_64 #(
    .DATA_W(DATA_W),
    .HDR_W(HDR_W),
    .PTP_TS_EN(PTP_TS_EN),
    .PTP_TS_FMT_TOD(PTP_TS_FMT_TOD),
    .PTP_TS_W(PTP_TS_W)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * 10GBASE-R encoded input
     */
    .encoded_rx_data(encoded_rx_data),
    .encoded_rx_hdr(encoded_rx_hdr),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis_rx(m_axis_rx),

    /*
     * PTP
     */
    .ptp_ts(ptp_ts),

    /*
     * Configuration
     */
    .cfg_rx_enable(cfg_rx_enable),

    /*
     * Status
     */
    .start_packet(start_packet),
    .error_bad_frame(error_bad_frame),
    .error_bad_fcs(error_bad_fcs),
    .rx_bad_block(rx_bad_block),
    .rx_sequence_error(rx_sequence_error)
);

endmodule

`resetall
