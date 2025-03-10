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
 * XFCP switch testbench
 */
module test_taxi_xfcp_switch #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter PORTS = 4
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

taxi_axis_if #(.DATA_W(8), .LAST_EN(1), .USER_EN(1), .USER_W(1)) up_xfcp_in(), up_xfcp_out();
taxi_axis_if #(.DATA_W(8), .LAST_EN(1), .USER_EN(1), .USER_W(1)) dn_xfcp_in[PORTS](), dn_xfcp_out[PORTS]();

taxi_xfcp_switch #(
    .PORTS(PORTS)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * XFCP upstream port
     */
    .up_xfcp_in(up_xfcp_in),
    .up_xfcp_out(up_xfcp_out),

    /*
     * XFCP downstream ports
     */
    .dn_xfcp_in(dn_xfcp_in),
    .dn_xfcp_out(dn_xfcp_out)
);

endmodule

`resetall
