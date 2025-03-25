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
 * Statistics collector testbench
 */
module test_taxi_stats_collect #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter CNT = 8,
    parameter INC_W = 8,
    parameter ID_BASE = 0,
    parameter UPDATE_PERIOD = 128,
    parameter STAT_INC_W = 16,
    parameter STAT_ID_W = $clog2(CNT)
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

logic [INC_W-1:0] stat_inc[CNT];
logic [0:0] stat_valid[CNT];

taxi_axis_if #(
    .DATA_W(STAT_INC_W),
    .KEEP_EN(0),
    .KEEP_W(1),
    .ID_EN(1),
    .ID_W(STAT_ID_W)
) m_axis_stat();

logic update;

taxi_stats_collect #(
    .CNT(CNT),
    .INC_W(INC_W),
    .ID_BASE(ID_BASE),
    .UPDATE_PERIOD(UPDATE_PERIOD)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * Increment inputs
     */
    .stat_inc(stat_inc),
    .stat_valid(stat_valid),

    /*
     * Statistics increment output
     */
    .m_axis_stat(m_axis_stat),

    /*
     * Control inputs
     */
    .update(update)
);

endmodule

`resetall
