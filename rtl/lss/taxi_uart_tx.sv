// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2014-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream UART (TX)
 */
module taxi_uart_tx
(
    input  wire logic         clk,
    input  wire logic         rst,

    /*
     * AXI4-Stream input (sink)
     */
    taxi_axis_if.snk          s_axis_tx,

    /*
     * UART interface
     */
    output wire logic         txd,

    /*
     * Status
     */
    output wire logic         busy,

    /*
     * Configuration
     */
    input  wire logic [15:0]  prescale
);

localparam DATA_W = s_axis_tx.DATA_W;

logic s_axis_tready_reg = 0;

logic txd_reg = 1;

logic busy_reg = 0;

logic [DATA_W:0] data_reg = 0;
logic [18:0] prescale_reg = 0;
logic [3:0] bit_cnt_reg = 0;

assign s_axis_tx.tready = s_axis_tready_reg;

assign txd = txd_reg;

assign busy = busy_reg;

always_ff @(posedge clk) begin
    if (prescale_reg > 0) begin
        s_axis_tready_reg <= 0;
        prescale_reg <= prescale_reg - 1;
    end else if (bit_cnt_reg == 0) begin
        s_axis_tready_reg <= 1;
        busy_reg <= 0;

        if (s_axis_tx.tvalid) begin
            s_axis_tready_reg <= !s_axis_tready_reg;
            prescale_reg <= {prescale, 3'd0}-1;
            bit_cnt_reg <= DATA_W+1;
            data_reg <= {1'b1, s_axis_tx.tdata};
            txd_reg <= 0;
            busy_reg <= 1;
        end
    end else begin
        if (bit_cnt_reg > 1) begin
            bit_cnt_reg <= bit_cnt_reg - 1;
            prescale_reg <= {prescale, 3'd0}-1;
            {data_reg, txd_reg} <= {1'b0, data_reg};
        end else if (bit_cnt_reg == 1) begin
            bit_cnt_reg <= bit_cnt_reg - 1;
            prescale_reg <= {prescale, 3'd0}-1;
            txd_reg <= 1;
        end
    end

    if (rst) begin
        s_axis_tready_reg <= 0;
        txd_reg <= 1;
        prescale_reg <= 0;
        bit_cnt_reg <= 0;
        busy_reg <= 0;
    end
end

endmodule

`resetall
