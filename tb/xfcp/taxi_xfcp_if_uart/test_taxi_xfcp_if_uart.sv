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
 * XFCP Interface (UART) testbench
 */
module test_taxi_xfcp_if_uart #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter TX_FIFO_DEPTH = 512,
    parameter RX_FIFO_DEPTH = 512
    /* verilator lint_on WIDTHTRUNC */
)
();

logic clk;
logic rst;

logic uart_rxd;
logic uart_txd;

taxi_axis_if #(.DATA_W(8), .LAST_EN(1), .USER_EN(1), .USER_W(1)) dn_xfcp_in(), dn_xfcp_out();

logic [15:0] prescale;

taxi_xfcp_if_uart #(
    .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
    .RX_FIFO_DEPTH(RX_FIFO_DEPTH)
)
uut (
    .clk(clk),
    .rst(rst),

    /*
     * UART interface
     */
    .uart_rxd(uart_rxd),
    .uart_txd(uart_txd),

    /*
     * XFCP downstream port
     */
    .dn_xfcp_in(dn_xfcp_in),
    .dn_xfcp_out(dn_xfcp_out),

    /*
     * Configuration
     */
    .prescale(prescale)
);

endmodule

`resetall
