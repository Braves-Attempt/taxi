// SPDX-License-Identifier: MIT
/*

Copyright (c) 2014-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA core logic
 */
module fpga_core #
(
    // simulation (set to avoid vendor primitives)
    parameter logic SIM = 1'b0,
    // vendor ("GENERIC", "XILINX", "ALTERA")
    parameter string VENDOR = "XILINX",
    // device family
    parameter string FAMILY = "artix7"
)
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input  wire logic       clk,
    input  wire logic       rst,

    /*
     * GPIO
     */
    input  wire logic [3:0]  btn,
    input  wire logic [3:0]  sw,
    output wire logic        led0_r,
    output wire logic        led0_g,
    output wire logic        led0_b,
    output wire logic        led1_r,
    output wire logic        led1_g,
    output wire logic        led1_b,
    output wire logic        led2_r,
    output wire logic        led2_g,
    output wire logic        led2_b,
    output wire logic        led3_r,
    output wire logic        led3_g,
    output wire logic        led3_b,
    output wire logic        led4,
    output wire logic        led5,
    output wire logic        led6,
    output wire logic        led7,

    /*
     * UART: 115200 bps, 8N1
     */
    input  wire logic        uart_rxd,
    output wire logic        uart_txd,

    /*
     * Ethernet: 100BASE-T MII
     */
    input  wire logic        phy_rx_clk,
    input  wire logic [3:0]  phy_rxd,
    input  wire logic        phy_rx_dv,
    input  wire logic        phy_rx_er,
    input  wire logic        phy_tx_clk,
    output wire logic [3:0]  phy_txd,
    output wire logic        phy_tx_en,
    input  wire logic        phy_col,
    input  wire logic        phy_crs,
    output wire logic        phy_reset_n
);

assign {led7, led6, led5, led4, led3_g, led2_g, led1_g, led0_g} = {sw, btn};
assign phy_reset_n = !rst;

taxi_axis_if #(.DATA_W(8)) axis_uart();

taxi_uart
uut (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis_tx(axis_uart),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis_rx(axis_uart),

    /*
     * UART interface
     */
    .rxd(uart_rxd),
    .txd(uart_txd),

    /*
     * Status
     */
    .tx_busy(),
    .rx_busy(),
    .rx_overrun_error(),
    .rx_frame_error(),

    /*
     * Configuration
     */
    .prescale(16'(125000000/115200/8))
);

taxi_axis_if #(.DATA_W(8), .ID_W(8)) axis_eth();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_W(8)) axis_tx_cpl();

taxi_eth_mac_mii_fifo #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .PADDING_EN(1),
    .MIN_FRAME_LEN(64),
    .TX_FIFO_DEPTH(16384),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(16384),
    .RX_FRAME_FIFO(1)
)
eth_mac_inst (
    .rst(rst),
    .logic_clk(clk),
    .logic_rst(rst),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(axis_eth),
    .m_axis_tx_cpl(axis_tx_cpl),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(axis_eth),

    /*
     * MII interface
     */
    .mii_rx_clk(phy_rx_clk),
    .mii_rxd(phy_rxd),
    .mii_rx_dv(phy_rx_dv),
    .mii_rx_er(phy_rx_er),
    .mii_tx_clk(phy_tx_clk),
    .mii_txd(phy_txd),
    .mii_tx_en(phy_tx_en),
    .mii_tx_er(),

    /*
     * Status
     */
    .tx_error_underflow(),
    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),

    /*
     * Configuration
     */
    .cfg_ifg(8'd12),
    .cfg_tx_enable(1'b1),
    .cfg_rx_enable(1'b1)
);

endmodule

`resetall
