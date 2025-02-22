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
 * 10M/100M Ethernet MAC with MII interface and TX and RX FIFOs testbench
 */
module test_taxi_eth_mac_mii_fifo #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter logic SIM = 1'b1,
    parameter string VENDOR = "XILINX",
    parameter string FAMILY = "virtex7",
    parameter AXIS_DATA_W = 8,
    parameter logic PADDING_EN = 1'b1,
    parameter MIN_FRAME_LEN = 64,
    parameter TX_TAG_W = 16,
    parameter TX_FIFO_DEPTH = 4096,
    parameter TX_FIFO_RAM_PIPELINE = 1,
    parameter logic TX_FRAME_FIFO = 1'b1,
    parameter logic TX_DROP_OVERSIZE_FRAME = TX_FRAME_FIFO,
    parameter logic TX_DROP_BAD_FRAME = TX_DROP_OVERSIZE_FRAME,
    parameter logic TX_DROP_WHEN_FULL = 1'b0,
    parameter TX_CPL_FIFO_DEPTH = 64,
    parameter RX_FIFO_DEPTH = 4096,
    parameter RX_FIFO_RAM_PIPELINE = 1,
    parameter logic RX_FRAME_FIFO = 1'b1,
    parameter logic RX_DROP_OVERSIZE_FRAME = RX_FRAME_FIFO,
    parameter logic RX_DROP_BAD_FRAME = RX_DROP_OVERSIZE_FRAME,
    parameter logic RX_DROP_WHEN_FULL = RX_DROP_OVERSIZE_FRAME
    /* verilator lint_on WIDTHTRUNC */
)
();

localparam TX_USER_W = 1;
localparam RX_USER_W = 1;

logic rst;
logic logic_clk;
logic logic_rst;

taxi_axis_if #(.DATA_W(AXIS_DATA_W), .USER_EN(1), .USER_W(TX_USER_W), .ID_EN(1), .ID_W(TX_TAG_W)) s_axis_tx();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_EN(1), .ID_W(TX_TAG_W)) m_axis_tx_cpl();
taxi_axis_if #(.DATA_W(AXIS_DATA_W), .USER_EN(1), .USER_W(RX_USER_W)) m_axis_rx();

logic mii_rx_clk;
logic [3:0] mii_rxd;
logic mii_rx_dv;
logic mii_rx_er;
logic mii_tx_clk;
logic [3:0] mii_txd;
logic mii_tx_en;
logic mii_tx_er;

logic tx_error_underflow;
logic tx_fifo_overflow;
logic tx_fifo_bad_frame;
logic tx_fifo_good_frame;
logic rx_error_bad_frame;
logic rx_error_bad_fcs;
logic rx_fifo_overflow;
logic rx_fifo_bad_frame;
logic rx_fifo_good_frame;

logic [7:0] cfg_ifg;
logic cfg_tx_enable;
logic cfg_rx_enable;

taxi_eth_mac_mii_fifo #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .PADDING_EN(PADDING_EN),
    .MIN_FRAME_LEN(MIN_FRAME_LEN),
    .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
    .TX_FIFO_RAM_PIPELINE(TX_FIFO_RAM_PIPELINE),
    .TX_FRAME_FIFO(TX_FRAME_FIFO),
    .TX_DROP_OVERSIZE_FRAME(TX_DROP_OVERSIZE_FRAME),
    .TX_DROP_BAD_FRAME(TX_DROP_BAD_FRAME),
    .TX_DROP_WHEN_FULL(TX_DROP_WHEN_FULL),
    .TX_CPL_FIFO_DEPTH(TX_CPL_FIFO_DEPTH),
    .RX_FIFO_DEPTH(RX_FIFO_DEPTH),
    .RX_FIFO_RAM_PIPELINE(RX_FIFO_RAM_PIPELINE),
    .RX_FRAME_FIFO(RX_FRAME_FIFO),
    .RX_DROP_OVERSIZE_FRAME(RX_DROP_OVERSIZE_FRAME),
    .RX_DROP_BAD_FRAME(RX_DROP_BAD_FRAME),
    .RX_DROP_WHEN_FULL(RX_DROP_WHEN_FULL)
)
uut (
    .rst(rst),
    .logic_clk(logic_clk),
    .logic_rst(logic_rst),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(s_axis_tx),
    .m_axis_tx_cpl(m_axis_tx_cpl),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(m_axis_rx),

    /*
     * MII interface
     */
    .mii_rx_clk(mii_rx_clk),
    .mii_rxd(mii_rxd),
    .mii_rx_dv(mii_rx_dv),
    .mii_rx_er(mii_rx_er),
    .mii_tx_clk(mii_tx_clk),
    .mii_txd(mii_txd),
    .mii_tx_en(mii_tx_en),
    .mii_tx_er(mii_tx_er),

    /*
     * Status
     */
    .tx_error_underflow(tx_error_underflow),
    .tx_fifo_overflow(tx_fifo_overflow),
    .tx_fifo_bad_frame(tx_fifo_bad_frame),
    .tx_fifo_good_frame(tx_fifo_good_frame),
    .rx_error_bad_frame(rx_error_bad_frame),
    .rx_error_bad_fcs(rx_error_bad_fcs),
    .rx_fifo_overflow(rx_fifo_overflow),
    .rx_fifo_bad_frame(rx_fifo_bad_frame),
    .rx_fifo_good_frame(rx_fifo_good_frame),

    /*
     * Configuration
     */
    .cfg_ifg(cfg_ifg),
    .cfg_tx_enable(cfg_tx_enable),
    .cfg_rx_enable(cfg_rx_enable)
);

endmodule

`resetall
