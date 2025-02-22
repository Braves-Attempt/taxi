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
    parameter string FAMILY = "kintex7",
    // Use 90 degree clock for RGMII transmit
    parameter logic USE_CLK90 = 1'b1,
    // BASE-T PHY type (GMII, RGMII, SGMII)
    parameter BASET_PHY_TYPE = "GMII",
    // Invert SFP data pins
    parameter logic SFP_INVERT = 1'b1
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
    output wire logic        sfp_tx_disable_b,

    /*
     * Ethernet: 1000BASE-T
     */
    input  wire logic        phy_sgmii_clk,
    input  wire logic        phy_sgmii_rst,
    input  wire logic        phy_sgmii_clk_en,
    input  wire logic [7:0]  phy_sgmii_rxd,
    input  wire logic        phy_sgmii_rx_dv,
    input  wire logic        phy_sgmii_rx_er,
    output wire logic [7:0]  phy_sgmii_txd,
    output wire logic        phy_sgmii_tx_en,
    output wire logic        phy_sgmii_tx_er,
    input  wire logic        phy_rgmii_rx_clk,
    input  wire logic [3:0]  phy_rgmii_rxd,
    input  wire logic        phy_rgmii_rx_ctl,
    output wire logic        phy_rgmii_tx_clk,
    output wire logic [3:0]  phy_rgmii_txd,
    output wire logic        phy_rgmii_tx_ctl,
    input  wire logic        phy_gmii_rx_clk,
    input  wire logic [7:0]  phy_gmii_rxd,
    input  wire logic        phy_gmii_rx_dv,
    input  wire logic        phy_gmii_rx_er,
    output wire logic        phy_gmii_gtx_clk,
    input  wire logic        phy_gmii_tx_clk,
    output wire logic [7:0]  phy_gmii_txd,
    output wire logic        phy_gmii_tx_en,
    output wire logic        phy_gmii_tx_er,
    output wire logic        phy_reset_n,
    input  wire logic        phy_int_n
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

if (BASET_PHY_TYPE == "GMII") begin : baset_mac_gmii
    
    taxi_eth_mac_1g_gmii_fifo #(
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
        .gtx_clk(clk),
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
         * GMII interface
         */
        .gmii_rx_clk(phy_gmii_rx_clk),
        .gmii_rxd(phy_gmii_rxd),
        .gmii_rx_dv(phy_gmii_rx_dv),
        .gmii_rx_er(phy_gmii_rx_er),
        .gmii_tx_clk(phy_gmii_gtx_clk),
        .mii_tx_clk(phy_gmii_tx_clk),
        .gmii_txd(phy_gmii_txd),
        .gmii_tx_en(phy_gmii_tx_en),
        .gmii_tx_er(phy_gmii_tx_er),

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

    assign phy_sgmii_txd = '0;
    assign phy_sgmii_tx_en = 1'b0;
    assign phy_sgmii_tx_er = 1'b0;

    assign phy_rgmii_tx_clk = 1'b0;
    assign phy_rgmii_txd = '0;
    assign phy_rgmii_tx_ctl = 1'b0;

end else if (BASET_PHY_TYPE == "RGMII") begin : baset_mac_rgmii
    
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

    assign phy_gmii_gtx_clk = 1'b0;
    assign phy_gmii_txd = '0;
    assign phy_gmii_tx_en = 1'b0;
    assign phy_gmii_tx_er = 1'b0;

    assign phy_sgmii_txd = '0;
    assign phy_sgmii_tx_en = 1'b0;
    assign phy_sgmii_tx_er = 1'b0;
    
end else if (BASET_PHY_TYPE == "SGMII") begin : baset_mac_sgmii

    taxi_eth_mac_1g_fifo #(
        .PADDING_EN(1),
        .MIN_FRAME_LEN(64),
        .TX_FIFO_DEPTH(16384),
        .TX_FRAME_FIFO(1),
        .RX_FIFO_DEPTH(16384),
        .RX_FRAME_FIFO(1)
    )
    eth_mac_inst (
        .rx_clk(phy_sgmii_clk),
        .rx_rst(phy_sgmii_rst),
        .tx_clk(phy_sgmii_clk),
        .tx_rst(phy_sgmii_rst),
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
        .gmii_rxd(phy_sgmii_rxd),
        .gmii_rx_dv(phy_sgmii_rx_dv),
        .gmii_rx_er(phy_sgmii_rx_er),
        .gmii_txd(phy_sgmii_txd),
        .gmii_tx_en(phy_sgmii_tx_en),
        .gmii_tx_er(phy_sgmii_tx_er),

        /*
         * Control
         */
        .rx_clk_enable(phy_sgmii_clk_en),
        .tx_clk_enable(phy_sgmii_clk_en),
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

    assign phy_gmii_gtx_clk = 1'b0;
    assign phy_gmii_txd = '0;
    assign phy_gmii_tx_en = 1'b0;
    assign phy_gmii_tx_er = 1'b0;

    assign phy_rgmii_tx_clk = 1'b0;
    assign phy_rgmii_txd = '0;
    assign phy_rgmii_tx_ctl = 1'b0;

end

// SFP+
assign sfp_tx_disable_b = 1'b1;

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
eth_mac_inst (
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
