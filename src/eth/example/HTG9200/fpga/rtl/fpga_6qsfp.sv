// SPDX-License-Identifier: MIT
/*

Copyright (c) 2021-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA top-level module
 */
module fpga #
(
    parameter logic SIM = 1'b0,
    parameter string VENDOR = "XILINX",
    parameter string FAMILY = "virtexuplus"
)
(
    /*
     * Clock: 200 MHz LVDS
     */
    input  wire logic       ref_clk_p,
    input  wire logic       ref_clk_n,

    /*
     * GPIO
     */
    input  wire logic [1:0] btn,
    input  wire logic [7:0] sw,
    output wire logic [7:0] led,

    /*
     * I2C for board management
     */
    inout  wire logic       i2c_main_scl,
    inout  wire logic       i2c_main_sda,
    output wire logic       i2c_main_rst_n,

    /*
     * PLL
     */
    output wire logic       clk_gty2_fdec,
    output wire logic       clk_gty2_finc,
    input  wire logic       clk_gty2_intr_n,
    input  wire logic       clk_gty2_lol_n,
    output wire logic       clk_gty2_oe_n,
    output wire logic       clk_gty2_sync_n,
    output wire logic       clk_gty2_rst_n,

    /*
     * UART: 921600 bps, 8N1
     */
    output wire logic       uart_rxd,
    input  wire logic       uart_txd,
    input  wire logic       uart_rts,
    output wire logic       uart_cts,
    output wire logic       uart_rst_n,
    output wire logic       uart_suspend_n,

    /*
     * Ethernet: QSFP28
     */
    output wire logic [3:0] qsfp_1_tx_p,
    output wire logic [3:0] qsfp_1_tx_n,
    input  wire logic [3:0] qsfp_1_rx_p,
    input  wire logic [3:0] qsfp_1_rx_n,
    input  wire logic       qsfp_1_mgt_refclk_p,
    input  wire logic       qsfp_1_mgt_refclk_n,
    output wire logic       qsfp_1_resetl,
    input  wire logic       qsfp_1_modprsl,
    input  wire logic       qsfp_1_intl,

    output wire logic [3:0] qsfp_2_tx_p,
    output wire logic [3:0] qsfp_2_tx_n,
    input  wire logic [3:0] qsfp_2_rx_p,
    input  wire logic [3:0] qsfp_2_rx_n,
    input  wire logic       qsfp_2_mgt_refclk_p,
    input  wire logic       qsfp_2_mgt_refclk_n,
    output wire logic       qsfp_2_resetl,
    input  wire logic       qsfp_2_modprsl,
    input  wire logic       qsfp_2_intl,

    output wire logic [3:0] qsfp_3_tx_p,
    output wire logic [3:0] qsfp_3_tx_n,
    input  wire logic [3:0] qsfp_3_rx_p,
    input  wire logic [3:0] qsfp_3_rx_n,
    input  wire logic       qsfp_3_mgt_refclk_p,
    input  wire logic       qsfp_3_mgt_refclk_n,
    output wire logic       qsfp_3_resetl,
    input  wire logic       qsfp_3_modprsl,
    input  wire logic       qsfp_3_intl,

    output wire logic [3:0] qsfp_4_tx_p,
    output wire logic [3:0] qsfp_4_tx_n,
    input  wire logic [3:0] qsfp_4_rx_p,
    input  wire logic [3:0] qsfp_4_rx_n,
    input  wire logic       qsfp_4_mgt_refclk_p,
    input  wire logic       qsfp_4_mgt_refclk_n,
    output wire logic       qsfp_4_resetl,
    input  wire logic       qsfp_4_modprsl,
    input  wire logic       qsfp_4_intl,

    output wire logic [3:0] qsfp_5_tx_p,
    output wire logic [3:0] qsfp_5_tx_n,
    input  wire logic [3:0] qsfp_5_rx_p,
    input  wire logic [3:0] qsfp_5_rx_n,
    input  wire logic       qsfp_5_mgt_refclk_p,
    input  wire logic       qsfp_5_mgt_refclk_n,
    output wire logic       qsfp_5_resetl,
    input  wire logic       qsfp_5_modprsl,
    input  wire logic       qsfp_5_intl,

    output wire logic [3:0] qsfp_6_tx_p,
    output wire logic [3:0] qsfp_6_tx_n,
    input  wire logic [3:0] qsfp_6_rx_p,
    input  wire logic [3:0] qsfp_6_rx_n,
    input  wire logic       qsfp_6_mgt_refclk_p,
    input  wire logic       qsfp_6_mgt_refclk_n,
    output wire logic       qsfp_6_resetl,
    input  wire logic       qsfp_6_modprsl,
    input  wire logic       qsfp_6_intl,

    output wire logic [3:0] qsfp_7_tx_p,
    output wire logic [3:0] qsfp_7_tx_n,
    input  wire logic [3:0] qsfp_7_rx_p,
    input  wire logic [3:0] qsfp_7_rx_n,
    input  wire logic       qsfp_7_mgt_refclk_p,
    input  wire logic       qsfp_7_mgt_refclk_n,
    output wire logic       qsfp_7_resetl,
    input  wire logic       qsfp_7_modprsl,
    input  wire logic       qsfp_7_intl,

    output wire logic [3:0] qsfp_8_tx_p,
    output wire logic [3:0] qsfp_8_tx_n,
    input  wire logic [3:0] qsfp_8_rx_p,
    input  wire logic [3:0] qsfp_8_rx_n,
    input  wire logic       qsfp_8_mgt_refclk_p,
    input  wire logic       qsfp_8_mgt_refclk_n,
    output wire logic       qsfp_8_resetl,
    input  wire logic       qsfp_8_modprsl,
    input  wire logic       qsfp_8_intl,

    output wire logic [3:0] qsfp_9_tx_p,
    output wire logic [3:0] qsfp_9_tx_n,
    input  wire logic [3:0] qsfp_9_rx_p,
    input  wire logic [3:0] qsfp_9_rx_n,
    input  wire logic       qsfp_9_mgt_refclk_p,
    input  wire logic       qsfp_9_mgt_refclk_n,
    output wire logic       qsfp_9_resetl,
    input  wire logic       qsfp_9_modprsl,
    input  wire logic       qsfp_9_intl,

    /*
     * Ethernet: QSFP28 via HTG 6x QSFP28 FMC+ adapter
     */
    output wire logic [3:0] fmc_qsfp_1_tx_p,
    output wire logic [3:0] fmc_qsfp_1_tx_n,
    input  wire logic [3:0] fmc_qsfp_1_rx_p,
    input  wire logic [3:0] fmc_qsfp_1_rx_n,
    input  wire logic       fmc_qsfp_1_mgt_refclk_p,
    input  wire logic       fmc_qsfp_1_mgt_refclk_n,
    output wire logic       fmc_qsfp_1_modsell,
    output wire logic       fmc_qsfp_1_resetl,
    input  wire logic       fmc_qsfp_1_modprsl,
    input  wire logic       fmc_qsfp_1_intl,
    output wire logic       fmc_qsfp_1_lpmode,

    output wire logic [3:0] fmc_qsfp_2_tx_p,
    output wire logic [3:0] fmc_qsfp_2_tx_n,
    input  wire logic [3:0] fmc_qsfp_2_rx_p,
    input  wire logic [3:0] fmc_qsfp_2_rx_n,
    input  wire logic       fmc_qsfp_2_mgt_refclk_p,
    input  wire logic       fmc_qsfp_2_mgt_refclk_n,
    output wire logic       fmc_qsfp_2_modsell,
    output wire logic       fmc_qsfp_2_resetl,
    input  wire logic       fmc_qsfp_2_modprsl,
    input  wire logic       fmc_qsfp_2_intl,
    output wire logic       fmc_qsfp_2_lpmode,

    output wire logic [3:0] fmc_qsfp_3_tx_p,
    output wire logic [3:0] fmc_qsfp_3_tx_n,
    input  wire logic [3:0] fmc_qsfp_3_rx_p,
    input  wire logic [3:0] fmc_qsfp_3_rx_n,
    input  wire logic       fmc_qsfp_3_mgt_refclk_p,
    input  wire logic       fmc_qsfp_3_mgt_refclk_n,
    output wire logic       fmc_qsfp_3_modsell,
    output wire logic       fmc_qsfp_3_resetl,
    input  wire logic       fmc_qsfp_3_modprsl,
    input  wire logic       fmc_qsfp_3_intl,
    output wire logic       fmc_qsfp_3_lpmode,

    output wire logic [3:0] fmc_qsfp_4_tx_p,
    output wire logic [3:0] fmc_qsfp_4_tx_n,
    input  wire logic [3:0] fmc_qsfp_4_rx_p,
    input  wire logic [3:0] fmc_qsfp_4_rx_n,
    input  wire logic       fmc_qsfp_4_mgt_refclk_p,
    input  wire logic       fmc_qsfp_4_mgt_refclk_n,
    output wire logic       fmc_qsfp_4_modsell,
    output wire logic       fmc_qsfp_4_resetl,
    input  wire logic       fmc_qsfp_4_modprsl,
    input  wire logic       fmc_qsfp_4_intl,
    output wire logic       fmc_qsfp_4_lpmode,

    output wire logic [3:0] fmc_qsfp_5_tx_p,
    output wire logic [3:0] fmc_qsfp_5_tx_n,
    input  wire logic [3:0] fmc_qsfp_5_rx_p,
    input  wire logic [3:0] fmc_qsfp_5_rx_n,
    input  wire logic       fmc_qsfp_5_mgt_refclk_p,
    input  wire logic       fmc_qsfp_5_mgt_refclk_n,
    output wire logic       fmc_qsfp_5_modsell,
    output wire logic       fmc_qsfp_5_resetl,
    input  wire logic       fmc_qsfp_5_modprsl,
    input  wire logic       fmc_qsfp_5_intl,
    output wire logic       fmc_qsfp_5_lpmode,

    output wire logic [3:0] fmc_qsfp_6_tx_p,
    output wire logic [3:0] fmc_qsfp_6_tx_n,
    input  wire logic [3:0] fmc_qsfp_6_rx_p,
    input  wire logic [3:0] fmc_qsfp_6_rx_n,
    input  wire logic       fmc_qsfp_6_mgt_refclk_p,
    input  wire logic       fmc_qsfp_6_mgt_refclk_n,
    output wire logic       fmc_qsfp_6_modsell,
    output wire logic       fmc_qsfp_6_resetl,
    input  wire logic       fmc_qsfp_6_modprsl,
    input  wire logic       fmc_qsfp_6_intl,
    output wire logic       fmc_qsfp_6_lpmode,

    output wire logic       fmc_clk_finc,
    output wire logic       fmc_clk_fdec,
    output wire logic       fmc_clk_rst_n,
    input  wire logic       fmc_clk_lol_n,
    output wire logic       fmc_clk_sync_n,
    input  wire logic       fmc_clk_intr_n,

    output wire logic       fmc_sync_c2m_p,
    output wire logic       fmc_sync_c2m_n
);

// Clock and reset

wire ref_clk_ibufg;

// Internal 125 MHz clock
wire clk_125mhz_mmcm_out;
wire clk_125mhz_int;
wire rst_125mhz_int;

wire mmcm_rst = ~btn[0];
wire mmcm_locked;
wire mmcm_clkfb;

IBUFGDS #(
   .DIFF_TERM("FALSE"),
   .IBUF_LOW_PWR("FALSE")   
)
ref_clk_ibufg_inst (
   .O   (ref_clk_ibufg),
   .I   (ref_clk_p),
   .IB  (ref_clk_n) 
);

// MMCM instance
MMCME4_BASE #(
    // 200 MHz input
    .CLKIN1_PERIOD(5.0),
    .REF_JITTER1(0.010),
    // 200 MHz input / 1 = 200 MHz PFD (range 10 MHz to 500 MHz)
    .DIVCLK_DIVIDE(1),
    // 200 MHz PFD * 5 = 1000 MHz VCO (range 800 MHz to 1600 MHz)
    .CLKFBOUT_MULT_F(5),
    .CLKFBOUT_PHASE(0),
    // 1000 MHz / 8 = 125 MHz, 0 degrees
    .CLKOUT0_DIVIDE_F(8),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0),
    // Not used
    .CLKOUT1_DIVIDE(1),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(0),
    // Not used
    .CLKOUT2_DIVIDE(1),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT2_PHASE(0),
    // Not used
    .CLKOUT3_DIVIDE(1),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT3_PHASE(0),
    // Not used
    .CLKOUT4_DIVIDE(1),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT4_PHASE(0),
    .CLKOUT4_CASCADE("FALSE"),
    // Not used
    .CLKOUT5_DIVIDE(1),
    .CLKOUT5_DUTY_CYCLE(0.5),
    .CLKOUT5_PHASE(0),
    // Not used
    .CLKOUT6_DIVIDE(1),
    .CLKOUT6_DUTY_CYCLE(0.5),
    .CLKOUT6_PHASE(0),

    // optimized bandwidth
    .BANDWIDTH("OPTIMIZED"),
    // don't wait for lock during startup
    .STARTUP_WAIT("FALSE")
)
clk_mmcm_inst (
    // 200 MHz input
    .CLKIN1(ref_clk_ibufg),
    // direct clkfb feeback
    .CLKFBIN(mmcm_clkfb),
    .CLKFBOUT(mmcm_clkfb),
    .CLKFBOUTB(),
    // 125 MHz, 0 degrees
    .CLKOUT0(clk_125mhz_mmcm_out),
    .CLKOUT0B(),
    // Not used
    .CLKOUT1(),
    .CLKOUT1B(),
    // Not used
    .CLKOUT2(),
    .CLKOUT2B(),
    // Not used
    .CLKOUT3(),
    .CLKOUT3B(),
    // Not used
    .CLKOUT4(),
    // Not used
    .CLKOUT5(),
    // Not used
    .CLKOUT6(),
    // reset input
    .RST(mmcm_rst),
    // don't power down
    .PWRDWN(1'b0),
    // locked output
    .LOCKED(mmcm_locked)
);

BUFG
clk_125mhz_bufg_inst (
    .I(clk_125mhz_mmcm_out),
    .O(clk_125mhz_int)
);

taxi_sync_reset #(
    .N(4)
)
sync_reset_125mhz_inst (
    .clk(clk_125mhz_int),
    .rst(~mmcm_locked),
    .out(rst_125mhz_int)
);

// GPIO
wire btn_int;
wire [7:0] sw_int;

taxi_debounce_switch #(
    .WIDTH(9),
    .N(4),
    .RATE(125000)
)
debounce_switch_inst (
    .clk(clk_125mhz_int),
    .rst(rst_125mhz_int),
    .in({btn[1],
        sw}),
    .out({btn_int,
        sw_int})
);

wire uart_txd_int;
wire uart_rts_int;

taxi_sync_signal #(
    .WIDTH(2),
    .N(2)
)
sync_signal_inst (
    .clk(clk_125mhz_int),
    .in({uart_txd, uart_rts}),
    .out({uart_txd_int, uart_rts_int})
);

wire i2c_scl_i;
wire i2c_scl_o;
wire i2c_sda_i;
wire i2c_sda_o;

assign i2c_scl_i = i2c_main_scl;
assign i2c_main_scl = i2c_scl_o ? 1'bz : 1'b0;
assign i2c_sda_i = i2c_main_sda;
assign i2c_main_sda = i2c_sda_o ? 1'bz : 1'b0;
assign i2c_main_rst_n = 1'b1;

localparam PORT_CNT = 9+6;
localparam GTY_QUAD_CNT = PORT_CNT;
localparam GTY_CNT = GTY_QUAD_CNT*4;
localparam GTY_CLK_CNT = GTY_QUAD_CNT;

assign clk_gty2_fdec = 1'b0;
assign clk_gty2_finc = 1'b0;
assign clk_gty2_oe_n = 1'b0;
assign clk_gty2_sync_n = 1'b1;
assign clk_gty2_rst_n = !rst_125mhz_int;

wire [PORT_CNT-1:0] eth_gty_mgt_refclk_out;

// forward MGT ref clock to PLL on FMC+ board
OBUFDS obufds_fmc_refclk_inst (
    .I(eth_gty_mgt_refclk_out[0]),
    .O(fmc_sync_c2m_p),
    .OB(fmc_sync_c2m_n)
);

assign fmc_qsfp_1_lpmode = 1'b0;
assign fmc_qsfp_2_lpmode = 1'b0;
assign fmc_qsfp_3_lpmode = 1'b0;
assign fmc_qsfp_4_lpmode = 1'b0;
assign fmc_qsfp_5_lpmode = 1'b0;
assign fmc_qsfp_6_lpmode = 1'b0;

assign fmc_clk_finc = 1'b0;
assign fmc_clk_fdec = 1'b0;
assign fmc_clk_sync_n = 1'b1;
assign fmc_clk_rst_n = !rst_125mhz_int;

wire eth_pll_locked = clk_gty2_lol_n && fmc_clk_lol_n;

fpga_core #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .PORT_CNT(PORT_CNT),
    .GTY_QUAD_CNT(GTY_QUAD_CNT),
    .GTY_CNT(GTY_CNT),
    .GTY_CLK_CNT(GTY_CLK_CNT)
)
core_inst (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk_125mhz(clk_125mhz_int),
    .rst_125mhz(rst_125mhz_int),

    /*
     * GPIO
     */
    .btn(btn_int),
    .sw(sw_int),
    .led(led),

    /*
     * I2C for board management
     */
    .i2c_scl_i(i2c_scl_i),
    .i2c_scl_o(i2c_scl_o),
    .i2c_sda_i(i2c_sda_i),
    .i2c_sda_o(i2c_sda_o),

    /*
     * UART: 921600 bps, 8N1
     */
    .uart_rxd(uart_rxd),
    .uart_txd(uart_txd_int),
    .uart_rts(uart_rts_int),
    .uart_cts(uart_cts),
    .uart_rst_n(uart_rst_n),
    .uart_suspend_n(uart_suspend_n),

    /*
     * Ethernet: QSFP28
     */
    .eth_pll_locked(eth_pll_locked),

    .eth_gty_tx_p({fmc_qsfp_6_tx_p, fmc_qsfp_5_tx_p, fmc_qsfp_4_tx_p, fmc_qsfp_3_tx_p, fmc_qsfp_2_tx_p, fmc_qsfp_1_tx_p, qsfp_9_tx_p, qsfp_8_tx_p, qsfp_7_tx_p, qsfp_6_tx_p, qsfp_5_tx_p, qsfp_4_tx_p, qsfp_3_tx_p, qsfp_2_tx_p, qsfp_1_tx_p}),
    .eth_gty_tx_n({fmc_qsfp_6_tx_n, fmc_qsfp_5_tx_n, fmc_qsfp_4_tx_n, fmc_qsfp_3_tx_n, fmc_qsfp_2_tx_n, fmc_qsfp_1_tx_n, qsfp_9_tx_n, qsfp_8_tx_n, qsfp_7_tx_n, qsfp_6_tx_n, qsfp_5_tx_n, qsfp_4_tx_n, qsfp_3_tx_n, qsfp_2_tx_n, qsfp_1_tx_n}),
    .eth_gty_rx_p({fmc_qsfp_6_rx_p, fmc_qsfp_5_rx_p, fmc_qsfp_4_rx_p, fmc_qsfp_3_rx_p, fmc_qsfp_2_rx_p, fmc_qsfp_1_rx_p, qsfp_9_rx_p, qsfp_8_rx_p, qsfp_7_rx_p, qsfp_6_rx_p, qsfp_5_rx_p, qsfp_4_rx_p, qsfp_3_rx_p, qsfp_2_rx_p, qsfp_1_rx_p}),
    .eth_gty_rx_n({fmc_qsfp_6_rx_n, fmc_qsfp_5_rx_n, fmc_qsfp_4_rx_n, fmc_qsfp_3_rx_n, fmc_qsfp_2_rx_n, fmc_qsfp_1_rx_n, qsfp_9_rx_n, qsfp_8_rx_n, qsfp_7_rx_n, qsfp_6_rx_n, qsfp_5_rx_n, qsfp_4_rx_n, qsfp_3_rx_n, qsfp_2_rx_n, qsfp_1_rx_n}),
    .eth_gty_mgt_refclk_p({fmc_qsfp_6_mgt_refclk_p, fmc_qsfp_5_mgt_refclk_p, fmc_qsfp_4_mgt_refclk_p, fmc_qsfp_3_mgt_refclk_p, fmc_qsfp_2_mgt_refclk_p, fmc_qsfp_1_mgt_refclk_p, qsfp_9_mgt_refclk_p, qsfp_8_mgt_refclk_p, qsfp_7_mgt_refclk_p, qsfp_6_mgt_refclk_p, qsfp_5_mgt_refclk_p, qsfp_4_mgt_refclk_p, qsfp_3_mgt_refclk_p, qsfp_2_mgt_refclk_p, qsfp_1_mgt_refclk_p}),
    .eth_gty_mgt_refclk_n({fmc_qsfp_6_mgt_refclk_n, fmc_qsfp_5_mgt_refclk_n, fmc_qsfp_4_mgt_refclk_n, fmc_qsfp_3_mgt_refclk_n, fmc_qsfp_2_mgt_refclk_n, fmc_qsfp_1_mgt_refclk_n, qsfp_9_mgt_refclk_n, qsfp_8_mgt_refclk_n, qsfp_7_mgt_refclk_n, qsfp_6_mgt_refclk_n, qsfp_5_mgt_refclk_n, qsfp_4_mgt_refclk_n, qsfp_3_mgt_refclk_n, qsfp_2_mgt_refclk_n, qsfp_1_mgt_refclk_n}),
    .eth_gty_mgt_refclk_out(eth_gty_mgt_refclk_out),

    .eth_port_resetl({fmc_qsfp_6_resetl, fmc_qsfp_5_resetl, fmc_qsfp_4_resetl, fmc_qsfp_3_resetl, fmc_qsfp_2_resetl, fmc_qsfp_1_resetl, qsfp_9_resetl, qsfp_8_resetl, qsfp_7_resetl, qsfp_6_resetl, qsfp_5_resetl, qsfp_4_resetl, qsfp_3_resetl, qsfp_2_resetl, qsfp_1_resetl}),
    .eth_port_modprsl({fmc_qsfp_6_modprsl, fmc_qsfp_5_modprsl, fmc_qsfp_4_modprsl, fmc_qsfp_3_modprsl, fmc_qsfp_2_modprsl, fmc_qsfp_1_modprsl, qsfp_9_modprsl, qsfp_8_modprsl, qsfp_7_modprsl, qsfp_6_modprsl, qsfp_5_modprsl, qsfp_4_modprsl, qsfp_3_modprsl, qsfp_2_modprsl, qsfp_1_modprsl}),
    .eth_port_intl({fmc_qsfp_6_intl, fmc_qsfp_5_intl, fmc_qsfp_4_intl, fmc_qsfp_3_intl, fmc_qsfp_2_intl, fmc_qsfp_1_intl, qsfp_9_intl, qsfp_8_intl, qsfp_7_intl, qsfp_6_intl, qsfp_5_intl, qsfp_4_intl, qsfp_3_intl, qsfp_2_intl, qsfp_1_intl})
);

endmodule

`resetall
