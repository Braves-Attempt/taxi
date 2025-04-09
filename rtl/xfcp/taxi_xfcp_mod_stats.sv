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
 * XFCP statistics counter module
 */
module taxi_xfcp_mod_stats #
(
    parameter logic [15:0] XFCP_ID_TYPE = 16'h8080,
    parameter XFCP_ID_STR = "Statistics",
    parameter logic [8*16-1:0] XFCP_EXT_ID = 0,
    parameter XFCP_EXT_ID_STR = "",
    // Statistics counter (bits)
    parameter STAT_COUNT_W = 32,
    // Pipeline length
    parameter STAT_PIPELINE = 2
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * XFCP upstream port
     */
    taxi_axis_if.snk   xfcp_usp_ds,
    taxi_axis_if.src   xfcp_usp_us,

    /*
     * Statistics increment input
     */
    taxi_axis_if.snk   s_axis_stat
);

taxi_axil_if #(
    .DATA_W(32),
    .ADDR_W(s_axis_stat.ID_W+$clog2(STAT_COUNT_W))
) axil_if();

taxi_stats_counter #(
    .STAT_COUNT_W(STAT_COUNT_W),
    .PIPELINE(STAT_PIPELINE)
)
stats_counter_inst (
    .clk(clk),
    .rst(rst),

    /*
     * Statistics increment input
     */
    .s_axis_stat(s_axis_stat),

    /*
     * AXI Lite register interface
     */
    .s_axil_wr(axil_if),
    .s_axil_rd(axil_if)
);

taxi_xfcp_mod_axil #(
    .XFCP_ID_TYPE(XFCP_ID_TYPE),
    .XFCP_ID_STR(XFCP_ID_STR),
    .XFCP_EXT_ID(XFCP_EXT_ID),
    .XFCP_EXT_ID_STR(XFCP_EXT_ID_STR),
    .COUNT_SIZE(16)
)
xfcp_mod_axil_inst (
    .clk(clk),
    .rst(rst),

    /*
     * XFCP upstream port
     */
    .xfcp_usp_ds(xfcp_usp_ds),
    .xfcp_usp_us(xfcp_usp_us),

    /*
     * AXI lite master interface
     */
    .m_axil_wr(axil_if),
    .m_axil_rd(axil_if)
);

endmodule

`resetall
