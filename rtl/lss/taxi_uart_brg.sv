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
 * AXI4-Stream UART baud rate generator
 */
module taxi_uart_brg
(
    input  wire logic         clk,
    input  wire logic         rst,

    /*
     * Baud rate pulse out
     */
    output wire logic         baud_clk,

    /*
     * Configuration
     */
    input  wire logic [15:0]  prescale
);

logic [15:0] prescale_reg = 0;
logic baud_clk_reg = 1'b0;

assign baud_clk = baud_clk_reg;

always_ff @(posedge clk) begin
    baud_clk_reg <= 1'b0;

    if (prescale_reg != 0) begin
        prescale_reg <= prescale_reg - 1;
    end else begin
        prescale_reg <= prescale - 1;
        baud_clk_reg <= 1'b1;
    end

    if (rst) begin
        prescale_reg <= 0;
        baud_clk_reg <= 0;
    end
end

endmodule

`resetall
