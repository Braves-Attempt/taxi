// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2018-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * 10G Ethernet PHY TX IF
 */
module taxi_eth_phy_10g_tx_if #
(
    parameter DATA_W = 64,
    parameter HDR_W = 2,
    parameter logic BIT_REVERSE = 1'b0,
    parameter logic SCRAMBLER_DISABLE = 1'b0,
    parameter logic PRBS31_EN = 1'b0,
    parameter SERDES_PIPELINE = 0
)
(
    input  wire logic               clk,
    input  wire logic               rst,

    /*
     * 10GBASE-R encoded interface
     */
    input  wire logic [DATA_W-1:0]  encoded_tx_data,
    input  wire logic [HDR_W-1:0]   encoded_tx_hdr,

    /*
     * SERDES interface
     */
    output wire logic [DATA_W-1:0]  serdes_tx_data,
    output wire logic [HDR_W-1:0]   serdes_tx_hdr,

    /*
     * Configuration
     */
    input  wire logic               cfg_tx_prbs31_enable
);

// check configuration
if (DATA_W != 64)
    $fatal(0, "Error: Interface width must be 64");

if (HDR_W != 2)
    $fatal(0, "Error: HDR_W must be 2");

logic [57:0] scrambler_state_reg = '1;
wire [57:0] scrambler_state;
wire [DATA_W-1:0] scrambled_data;

logic [30:0] prbs31_state_reg = 31'h7fffffff;
wire [30:0] prbs31_state;
wire [DATA_W+HDR_W-1:0] prbs31_data;

logic [DATA_W-1:0] serdes_tx_data_reg = '0;
logic [HDR_W-1:0] serdes_tx_hdr_reg = '0;

wire [DATA_W-1:0] serdes_tx_data_int;
wire [HDR_W-1:0]  serdes_tx_hdr_int;

if (BIT_REVERSE) begin
    for (genvar n = 0; n < DATA_W; n = n + 1) begin
        assign serdes_tx_data_int[n] = serdes_tx_data_reg[DATA_W-n-1];
    end

    for (genvar n = 0; n < HDR_W; n = n + 1) begin
        assign serdes_tx_hdr_int[n] = serdes_tx_hdr_reg[HDR_W-n-1];
    end
end else begin
    assign serdes_tx_data_int = serdes_tx_data_reg;
    assign serdes_tx_hdr_int = serdes_tx_hdr_reg;
end

if (SERDES_PIPELINE > 0) begin
    (* srl_style = "register" *)
    reg [DATA_W-1:0] serdes_tx_data_pipe_reg[SERDES_PIPELINE-1:0];
    (* srl_style = "register" *)
    reg [HDR_W-1:0]  serdes_tx_hdr_pipe_reg[SERDES_PIPELINE-1:0];

    for (genvar n = 0; n < SERDES_PIPELINE; n = n + 1) begin
        initial begin
            serdes_tx_data_pipe_reg[n] = '0;
            serdes_tx_hdr_pipe_reg[n] = '0;
        end

        always @(posedge clk) begin
            serdes_tx_data_pipe_reg[n] <= n == 0 ? serdes_tx_data_int : serdes_tx_data_pipe_reg[n-1];
            serdes_tx_hdr_pipe_reg[n] <= n == 0 ? serdes_tx_hdr_int : serdes_tx_hdr_pipe_reg[n-1];
        end
    end

    assign serdes_tx_data = serdes_tx_data_pipe_reg[SERDES_PIPELINE-1];
    assign serdes_tx_hdr = serdes_tx_hdr_pipe_reg[SERDES_PIPELINE-1];
end else begin
    assign serdes_tx_data = serdes_tx_data_int;
    assign serdes_tx_hdr = serdes_tx_hdr_int;
end

taxi_lfsr #(
    .LFSR_W(58),
    .LFSR_POLY(58'h8000000001),
    .LFSR_GALOIS(0),
    .LFSR_FEED_FORWARD(0),
    .REVERSE(1),
    .DATA_W(DATA_W)
)
scrambler_inst (
    .data_in(encoded_tx_data),
    .state_in(scrambler_state_reg),
    .data_out(scrambled_data),
    .state_out(scrambler_state)
);

taxi_lfsr #(
    .LFSR_W(31),
    .LFSR_POLY(31'h10000001),
    .LFSR_GALOIS(0),
    .LFSR_FEED_FORWARD(0),
    .REVERSE(1),
    .DATA_W(DATA_W+HDR_W)
)
prbs31_gen_inst (
    .data_in('0),
    .state_in(prbs31_state_reg),
    .data_out(prbs31_data),
    .state_out(prbs31_state)
);

always_ff @(posedge clk) begin
    scrambler_state_reg <= scrambler_state;

    if (PRBS31_EN && cfg_tx_prbs31_enable) begin
        prbs31_state_reg <= prbs31_state;

        serdes_tx_data_reg <= ~prbs31_data[DATA_W+HDR_W-1:HDR_W];
        serdes_tx_hdr_reg <= ~prbs31_data[HDR_W-1:0];
    end else begin
        serdes_tx_data_reg <= SCRAMBLER_DISABLE ? encoded_tx_data : scrambled_data;
        serdes_tx_hdr_reg <= encoded_tx_hdr;
    end
end

endmodule

`resetall
