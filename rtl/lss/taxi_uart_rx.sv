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
 * AXI4-Stream UART (RX)
 */
module taxi_uart_rx #
(
    parameter DATA_W = 8
)
(
    input  wire logic         clk,
    input  wire logic         rst,

    /*
     * AXI4-Stream output (source)
     */
    taxi_axis_if.src          m_axis_rx,

    /*
     * UART interface
     */
    input  wire logic         rxd,

    /*
     * Status
     */
    output wire logic         busy,
    output wire logic         overrun_error,
    output wire logic         frame_error,

    /*
     * Configuration
     */
    input  wire logic [15:0]  prescale

);

// check configuration
if (m_axis_rx.DATA_W != DATA_W)
    $fatal(0, "Error: Interface parameter DATA_W mismatch (instance %m)");

logic [DATA_W-1:0] m_axis_tdata_reg = 0;
logic m_axis_tvalid_reg = 0;

logic rxd_reg = 1;

logic busy_reg = 0;
logic overrun_error_reg = 0;
logic frame_error_reg = 0;

logic [DATA_W-1:0] data_reg = 0;
logic [18:0] prescale_reg = 0;
logic [3:0] bit_cnt_reg = 0;

assign m_axis_rx.tdata = m_axis_tdata_reg;
assign m_axis_rx.tkeep = 1'b1;
assign m_axis_rx.tstrb = m_axis_rx.tkeep;
assign m_axis_rx.tvalid = m_axis_tvalid_reg;
assign m_axis_rx.tlast = 1'b1;

assign busy = busy_reg;
assign overrun_error = overrun_error_reg;
assign frame_error = frame_error_reg;

always_ff @(posedge clk) begin
    rxd_reg <= rxd;
    overrun_error_reg <= 0;
    frame_error_reg <= 0;

    if (m_axis_rx.tvalid && m_axis_rx.tready) begin
        m_axis_tvalid_reg <= 0;
    end

    if (prescale_reg > 0) begin
        prescale_reg <= prescale_reg - 1;
    end else if (bit_cnt_reg > 0) begin
        if (bit_cnt_reg > DATA_W+1) begin
            if (!rxd_reg) begin
                bit_cnt_reg <= bit_cnt_reg - 1;
                prescale_reg <= {prescale, 3'd0}-1;
            end else begin
                bit_cnt_reg <= 0;
                prescale_reg <= 0;
            end
        end else if (bit_cnt_reg > 1) begin
            bit_cnt_reg <= bit_cnt_reg - 1;
            prescale_reg <= {prescale, 3'd0}-1;
            data_reg <= {rxd_reg, data_reg[DATA_W-1:1]};
        end else if (bit_cnt_reg == 1) begin
            bit_cnt_reg <= bit_cnt_reg - 1;
            if (rxd_reg) begin
                m_axis_tdata_reg <= data_reg;
                m_axis_tvalid_reg <= 1;
                overrun_error_reg <= m_axis_tvalid_reg;
            end else begin
                frame_error_reg <= 1;
            end
        end
    end else begin
        busy_reg <= 0;
        if (!rxd_reg) begin
            prescale_reg <= {prescale, 2'd0}-2;
            bit_cnt_reg <= DATA_W+2;
            data_reg <= 0;
            busy_reg <= 1;
        end
    end

    if (rst) begin
        m_axis_tdata_reg <= 0;
        m_axis_tvalid_reg <= 0;
        rxd_reg <= 1;
        prescale_reg <= 0;
        bit_cnt_reg <= 0;
        busy_reg <= 0;
        overrun_error_reg <= 0;
        frame_error_reg <= 0;
    end
end

endmodule

`resetall
