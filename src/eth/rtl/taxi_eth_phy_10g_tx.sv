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
 * 10G Ethernet PHY TX
 */
module taxi_eth_phy_10g_tx #
(
    parameter DATA_W = 64,
    parameter CTRL_W = (DATA_W/8),
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
     * XGMII interface
     */
    input  wire logic [DATA_W-1:0]  xgmii_txd,
    input  wire logic [CTRL_W-1:0]  xgmii_txc,

    /*
     * SERDES interface
     */
    output wire logic [DATA_W-1:0]  serdes_tx_data,
    output wire logic [HDR_W-1:0]   serdes_tx_hdr,

    /*
     * Status
     */
    output wire logic               tx_bad_block,

    /*
     * Configuration
     */
    input  wire logic               cfg_tx_prbs31_enable
);

// check configuration
if (DATA_W != 64)
    $fatal(0, "Error: Interface width must be 64");

if (CTRL_W * 8 != DATA_W)
    $fatal(0, "Error: Interface requires byte (8-bit) granularity");

if (HDR_W != 2)
    $fatal(0, "Error: HDR_W must be 2");

wire [DATA_W-1:0] encoded_tx_data;
wire [HDR_W-1:0]  encoded_tx_hdr;

taxi_xgmii_baser_enc_64 #(
    .DATA_W(DATA_W),
    .CTRL_W(CTRL_W),
    .HDR_W(HDR_W)
)
xgmii_baser_enc_inst (
    .clk(clk),
    .rst(rst),

    /*
     * XGMII interface
     */
    .xgmii_txd(xgmii_txd),
    .xgmii_txc(xgmii_txc),

    /*
     * 10GBASE-R encoded interface
     */
    .encoded_tx_data(encoded_tx_data),
    .encoded_tx_hdr(encoded_tx_hdr),

    /*
     * Status
     */
    .tx_bad_block(tx_bad_block)
);

taxi_eth_phy_10g_tx_if #(
    .DATA_W(DATA_W),
    .HDR_W(HDR_W),
    .BIT_REVERSE(BIT_REVERSE),
    .SCRAMBLER_DISABLE(SCRAMBLER_DISABLE),
    .PRBS31_EN(PRBS31_EN),
    .SERDES_PIPELINE(SERDES_PIPELINE)
)
eth_phy_10g_tx_if_inst (
    .clk(clk),
    .rst(rst),

    /*
     * 10GBASE-R encoded interface
     */
    .encoded_tx_data(encoded_tx_data),
    .encoded_tx_hdr(encoded_tx_hdr),

    /*
     * SERDES interface
     */
    .serdes_tx_data(serdes_tx_data),
    .serdes_tx_hdr(serdes_tx_hdr),

    /*
     * Configuration
     */
    .cfg_tx_prbs31_enable(cfg_tx_prbs31_enable)
);

endmodule

`resetall
