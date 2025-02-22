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
    output wire logic [1:0]  led,
    output wire logic [1:0]  sfp_led,

    /*
     * Ethernet: 1000BASE-T
     */
    input  wire logic        phy2_rgmii_rx_clk,
    input  wire logic [3:0]  phy2_rgmii_rxd,
    input  wire logic        phy2_rgmii_rx_ctl,
    output wire logic        phy2_rgmii_tx_clk,
    output wire logic [3:0]  phy2_rgmii_txd,
    output wire logic        phy2_rgmii_tx_ctl,
    output wire logic        phy2_reset_n,

    input  wire logic        phy3_rgmii_rx_clk,
    input  wire logic [3:0]  phy3_rgmii_rxd,
    input  wire logic        phy3_rgmii_rx_ctl,
    output wire logic        phy3_rgmii_tx_clk,
    output wire logic [3:0]  phy3_rgmii_txd,
    output wire logic        phy3_rgmii_tx_ctl,
    output wire logic        phy3_reset_n,

    /*
     * Ethernet: 1000BASE-X SFP
     */
    input  wire logic        sfp_gmii_clk,
    input  wire logic        sfp_gmii_rst,
    input  wire logic        sfp_gmii_clk_en,
    input  wire logic [7:0]  sfp_gmii_rxd,
    input  wire logic        sfp_gmii_rx_dv,
    input  wire logic        sfp_gmii_rx_er,
    output wire logic [7:0]  sfp_gmii_txd,
    output wire logic        sfp_gmii_tx_en,
    output wire logic        sfp_gmii_tx_er,

    output wire logic        sfp_tx_disable,
    input  wire logic        sfp_tx_fault,
    input  wire logic        sfp_rx_los,
    input  wire logic        sfp_mod_abs,
    input  wire logic        sfp_i2c_scl_i,
    output wire logic        sfp_i2c_scl_o,
    output wire logic        sfp_i2c_scl_t,
    input  wire logic        sfp_i2c_sda_i,
    output wire logic        sfp_i2c_sda_o,
    output wire logic        sfp_i2c_sda_t
);

// BASE-T PHY
assign phy2_reset_n = !rst;
assign phy3_reset_n = !rst;

taxi_axis_if #(.DATA_W(8), .ID_W(8)) axis_phy2_eth();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_W(8)) axis_phy2_tx_cpl();

taxi_axis_if #(.DATA_W(8), .ID_W(8)) axis_phy3_eth();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_W(8)) axis_phy3_tx_cpl();

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
phy2_eth_mac_inst (
    .gtx_clk(clk),
    .gtx_clk90(clk90),
    .gtx_rst(rst),
    .logic_clk(clk),
    .logic_rst(rst),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(axis_phy2_eth),
    .m_axis_tx_cpl(axis_phy2_tx_cpl),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(axis_phy2_eth),

    /*
     * RGMII interface
     */
    .rgmii_rx_clk(phy2_rgmii_rx_clk),
    .rgmii_rxd(phy2_rgmii_rxd),
    .rgmii_rx_ctl(phy2_rgmii_rx_ctl),
    .rgmii_tx_clk(phy2_rgmii_tx_clk),
    .rgmii_txd(phy2_rgmii_txd),
    .rgmii_tx_ctl(phy2_rgmii_tx_ctl),

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
phy3_eth_mac_inst (
    .gtx_clk(clk),
    .gtx_clk90(clk90),
    .gtx_rst(rst),
    .logic_clk(clk),
    .logic_rst(rst),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(axis_phy3_eth),
    .m_axis_tx_cpl(axis_phy3_tx_cpl),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(axis_phy3_eth),

    /*
     * RGMII interface
     */
    .rgmii_rx_clk(phy3_rgmii_rx_clk),
    .rgmii_rxd(phy3_rgmii_rxd),
    .rgmii_rx_ctl(phy3_rgmii_rx_ctl),
    .rgmii_tx_clk(phy3_rgmii_tx_clk),
    .rgmii_txd(phy3_rgmii_txd),
    .rgmii_tx_ctl(phy3_rgmii_tx_ctl),

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

// SFP+
assign sfp_tx_disable = 1'b0;

taxi_axis_if #(.DATA_W(8), .ID_W(8)) axis_sfp_eth();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_W(8)) axis_sfp_tx_cpl();

taxi_eth_mac_1g_fifo #(
    .PADDING_EN(1),
    .MIN_FRAME_LEN(64),
    .TX_FIFO_DEPTH(16384),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(16384),
    .RX_FRAME_FIFO(1)
)
sfp_eth_mac_inst (
    .rx_clk(sfp_gmii_clk),
    .rx_rst(sfp_gmii_rst),
    .tx_clk(sfp_gmii_clk),
    .tx_rst(sfp_gmii_rst),
    .logic_clk(clk),
    .logic_rst(rst),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(axis_sfp_eth),
    .m_axis_tx_cpl(axis_sfp_tx_cpl),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(axis_sfp_eth),

    /*
     * GMII interface
     */
    .gmii_rxd(sfp_gmii_rxd),
    .gmii_rx_dv(sfp_gmii_rx_dv),
    .gmii_rx_er(sfp_gmii_rx_er),
    .gmii_txd(sfp_gmii_txd),
    .gmii_tx_en(sfp_gmii_tx_en),
    .gmii_tx_er(sfp_gmii_tx_er),

    /*
     * Control
     */
    .rx_clk_enable(sfp_gmii_clk_en),
    .tx_clk_enable(sfp_gmii_clk_en),
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
