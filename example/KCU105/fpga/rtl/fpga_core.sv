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
module fpga_core
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input  wire logic        clk,
    input  wire logic        rst,

    /*
     * GPIO
     */
    input  wire logic        btnu,
    input  wire logic        btnl,
    input  wire logic        btnd,
    input  wire logic        btnr,
    input  wire logic        btnc,
    input  wire logic [7:0]  sw,
    output wire logic [7:0]  led,

    /*
     * UART: 115200 bps, 8N1
     */
    input  wire logic        uart_rxd,
    output wire logic        uart_txd,
    output wire logic        uart_rts,
    input  wire logic        uart_cts,

    /*
     * Ethernet: 1000BASE-T
     */
    input  wire logic        phy_gmii_clk,
    input  wire logic        phy_gmii_rst,
    input  wire logic        phy_gmii_clk_en,
    input  wire logic [7:0]  phy_gmii_rxd,
    input  wire logic        phy_gmii_rx_dv,
    input  wire logic        phy_gmii_rx_er,
    output wire logic [7:0]  phy_gmii_txd,
    output wire logic        phy_gmii_tx_en,
    output wire logic        phy_gmii_tx_er,
    output wire logic        phy_reset_n,
    input  wire logic        phy_int_n,

    /*
     * Ethernet: 1000BASE-X SFP
     */
    input  wire logic        sfp0_gmii_clk,
    input  wire logic        sfp0_gmii_rst,
    input  wire logic        sfp0_gmii_clk_en,
    input  wire logic [7:0]  sfp0_gmii_rxd,
    input  wire logic        sfp0_gmii_rx_dv,
    input  wire logic        sfp0_gmii_rx_er,
    output wire logic [7:0]  sfp0_gmii_txd,
    output wire logic        sfp0_gmii_tx_en,
    output wire logic        sfp0_gmii_tx_er,
    output wire logic        sfp0_tx_disable_b,

    input  wire logic        sfp1_gmii_clk,
    input  wire logic        sfp1_gmii_rst,
    input  wire logic        sfp1_gmii_clk_en,
    input  wire logic [7:0]  sfp1_gmii_rxd,
    input  wire logic        sfp1_gmii_rx_dv,
    input  wire logic        sfp1_gmii_rx_er,
    output wire logic [7:0]  sfp1_gmii_txd,
    output wire logic        sfp1_gmii_tx_en,
    output wire logic        sfp1_gmii_tx_er,
    output wire logic        sfp1_tx_disable_b
);

assign led = sw;

// UART
assign uart_rts = 0;

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

// BASE-T PHY
assign phy_reset_n = !rst;

taxi_axis_if #(.DATA_W(8), .ID_W(8)) axis_eth();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_W(8)) axis_tx_cpl();

taxi_eth_mac_1g_fifo #(
    .PADDING_EN(1),
    .MIN_FRAME_LEN(64),
    .TX_FIFO_DEPTH(16384),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(16384),
    .RX_FRAME_FIFO(1)
)
eth_mac_inst (
    .rx_clk(phy_gmii_clk),
    .rx_rst(phy_gmii_rst),
    .tx_clk(phy_gmii_clk),
    .tx_rst(phy_gmii_rst),
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
     * GMII interface
     */
    .gmii_rxd(phy_gmii_rxd),
    .gmii_rx_dv(phy_gmii_rx_dv),
    .gmii_rx_er(phy_gmii_rx_er),
    .gmii_txd(phy_gmii_txd),
    .gmii_tx_en(phy_gmii_tx_en),
    .gmii_tx_er(phy_gmii_tx_er),

    /*
     * Control
     */
    .rx_clk_enable(phy_gmii_clk_en),
    .tx_clk_enable(phy_gmii_clk_en),
    .rx_mii_select(1'b0),
    .tx_mii_select(1'b0),

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

// SFP+
assign sfp0_tx_disable_b = 1'b1;
assign sfp1_tx_disable_b = 1'b1;

taxi_axis_if #(.DATA_W(8), .ID_W(8)) axis_sfp0_eth();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_W(8)) axis_sfp0_tx_cpl();

taxi_axis_if #(.DATA_W(8), .ID_W(8)) axis_sfp1_eth();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_W(8)) axis_sfp1_tx_cpl();

taxi_eth_mac_1g_fifo #(
    .PADDING_EN(1),
    .MIN_FRAME_LEN(64),
    .TX_FIFO_DEPTH(16384),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(16384),
    .RX_FRAME_FIFO(1)
)
sfp0_eth_mac_inst (
    .rx_clk(sfp0_gmii_clk),
    .rx_rst(sfp0_gmii_rst),
    .tx_clk(sfp0_gmii_clk),
    .tx_rst(sfp0_gmii_rst),
    .logic_clk(clk),
    .logic_rst(rst),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(axis_sfp0_eth),
    .m_axis_tx_cpl(axis_sfp0_tx_cpl),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(axis_sfp0_eth),

    /*
     * GMII interface
     */
    .gmii_rxd(sfp0_gmii_rxd),
    .gmii_rx_dv(sfp0_gmii_rx_dv),
    .gmii_rx_er(sfp0_gmii_rx_er),
    .gmii_txd(sfp0_gmii_txd),
    .gmii_tx_en(sfp0_gmii_tx_en),
    .gmii_tx_er(sfp0_gmii_tx_er),

    /*
     * Control
     */
    .rx_clk_enable(sfp0_gmii_clk_en),
    .tx_clk_enable(sfp0_gmii_clk_en),
    .rx_mii_select(1'b0),
    .tx_mii_select(1'b0),

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

taxi_eth_mac_1g_fifo #(
    .PADDING_EN(1),
    .MIN_FRAME_LEN(64),
    .TX_FIFO_DEPTH(16384),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(16384),
    .RX_FRAME_FIFO(1)
)
sfp1_eth_mac_inst (
    .rx_clk(sfp1_gmii_clk),
    .rx_rst(sfp1_gmii_rst),
    .tx_clk(sfp1_gmii_clk),
    .tx_rst(sfp1_gmii_rst),
    .logic_clk(clk),
    .logic_rst(rst),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(axis_sfp1_eth),
    .m_axis_tx_cpl(axis_sfp1_tx_cpl),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(axis_sfp1_eth),

    /*
     * GMII interface
     */
    .gmii_rxd(sfp1_gmii_rxd),
    .gmii_rx_dv(sfp1_gmii_rx_dv),
    .gmii_rx_er(sfp1_gmii_rx_er),
    .gmii_txd(sfp1_gmii_txd),
    .gmii_tx_en(sfp1_gmii_tx_en),
    .gmii_tx_er(sfp1_gmii_tx_er),

    /*
     * Control
     */
    .rx_clk_enable(sfp1_gmii_clk_en),
    .tx_clk_enable(sfp1_gmii_clk_en),
    .rx_mii_select(1'b0),
    .tx_mii_select(1'b0),

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
