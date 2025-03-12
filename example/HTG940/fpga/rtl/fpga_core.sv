// SPDX-License-Identifier: MIT
/*

Copyright (c) 2025 FPGA Ninja, LLC

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
    parameter string FAMILY = "zynquplus",
    // Use 90 degree clock for RGMII transmit
    parameter logic USE_CLK90 = 1'b1
)
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input  wire logic        clk,
    input  wire logic        clk90,
    input  wire logic        rst,

    /*
     * GPIO
     */
    input  wire logic        btn,
    input  wire logic [7:0]  sw,
    output wire logic [7:0]  led,

    /*
     * UART: 115200 bps, 8N1
     */
    output wire logic        uart_rxd,
    input  wire logic        uart_txd,
    input  wire logic        uart_rts,
    output wire logic        uart_cts,
    output wire logic        uart_rst_n,

    /*
     * Ethernet: 1000BASE-T RGMII
     */
    input  wire logic        phy_rgmii_rx_clk,
    input  wire logic [3:0]  phy_rgmii_rxd,
    input  wire logic        phy_rgmii_rx_ctl,
    output wire logic        phy_rgmii_tx_clk,
    output wire logic [3:0]  phy_rgmii_txd,
    output wire logic        phy_rgmii_tx_ctl
);

assign led = sw;

// UART
assign uart_cts = 1'b1;
assign uart_rst_n = 1'b1;

taxi_axis_if #(.DATA_W(8)) axis_uart();

taxi_uart
uart_inst (
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
    .rxd(uart_txd),
    .txd(uart_rxd),

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
    .prescale(16'(125000000/115200))
);

// BASE-T PHY
taxi_axis_if #(.DATA_W(8), .ID_W(8)) axis_eth();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_W(8)) axis_tx_cpl();

taxi_eth_mac_1g_rgmii_fifo #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .USE_CLK90(USE_CLK90),
    .PADDING_EN(1),
    .MIN_FRAME_LEN(64),
    .TX_FIFO_DEPTH(16384),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(16384),
    .RX_FRAME_FIFO(1)
)
eth_mac_inst (
    .gtx_clk(clk),
    .gtx_clk90(clk90),
    .gtx_rst(rst),
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
     * RGMII interface
     */
    .rgmii_rx_clk(phy_rgmii_rx_clk),
    .rgmii_rxd(phy_rgmii_rxd),
    .rgmii_rx_ctl(phy_rgmii_rx_ctl),
    .rgmii_tx_clk(phy_rgmii_tx_clk),
    .rgmii_txd(phy_rgmii_txd),
    .rgmii_tx_ctl(phy_rgmii_tx_ctl),

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
    .link_speed(),

    /*
     * Configuration
     */
    .cfg_ifg(8'd12),
    .cfg_tx_enable(1'b1),
    .cfg_rx_enable(1'b1)
);

endmodule

`resetall
