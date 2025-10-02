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
 * FPGA top-level module
 */
module fpga #
(
    parameter logic SIM = 1'b0,
    parameter string VENDOR = "XILINX",
    parameter string FAMILY = "virtexu"
)
(
    /*
     * Clock: 125MHz LVDS
     * Reset: Push button, active low
     */
    input  wire logic        clk_125mhz_p,
    input  wire logic        clk_125mhz_n,
    input  wire logic        reset,

    /*
     * GPIO
     */
    input  wire logic        btnu,
    input  wire logic        btnl,
    input  wire logic        btnd,
    input  wire logic        btnr,
    input  wire logic        btnc,
    input  wire logic [3:0]  sw,
    output wire logic [7:0]  led,

    /*
     * UART: 500000 bps, 8N1
     */
    input  wire logic        uart_rxd,
    output wire logic        uart_txd,
    input  wire logic        uart_rts,
    output wire logic        uart_cts,

    /*
     * Ethernet: 1000BASE-T SGMII
     */
    input  wire logic        phy_sgmii_rx_p,
    input  wire logic        phy_sgmii_rx_n,
    output wire logic        phy_sgmii_tx_p,
    output wire logic        phy_sgmii_tx_n,
    input  wire logic        phy_sgmii_clk_p,
    input  wire logic        phy_sgmii_clk_n,
    output wire logic        phy_reset_n,
    input  wire logic        phy_int_n,

    /*
     * Ethernet: QSFP28
     */
    input  wire logic        qsfp_rx_p[4],
    input  wire logic        qsfp_rx_n[4],
    output wire logic        qsfp_tx_p[4],
    output wire logic        qsfp_tx_n[4],
    input  wire logic        qsfp_mgt_refclk_0_p,
    input  wire logic        qsfp_mgt_refclk_0_n,
    // input  wire logic        qsfp_mgt_refclk_1_p,
    // input  wire logic        qsfp_mgt_refclk_1_n,
    // output wire logic        qsfp_recclk_p,
    // output wire logic        qsfp_recclk_n,
    output wire logic        qsfp_modsell,
    output wire logic        qsfp_resetl,
    input  wire logic        qsfp_modprsl,
    input  wire logic        qsfp_intl,
    output wire logic        qsfp_lpmode
);

// Clock and reset

wire clk_125mhz_ibufg;

// Internal 125 MHz clock
wire clk_125mhz_mmcm_out;
wire clk_125mhz_int;
wire rst_125mhz_int;

wire mmcm_rst = reset;
wire mmcm_locked;
wire mmcm_clkfb;

IBUFGDS #(
   .DIFF_TERM("FALSE"),
   .IBUF_LOW_PWR("FALSE")   
)
clk_125mhz_ibufg_inst (
   .O   (clk_125mhz_ibufg),
   .I   (clk_125mhz_p),
   .IB  (clk_125mhz_n) 
);

// MMCM instance
MMCME3_BASE #(
    // 125 MHz input
    .CLKIN1_PERIOD(8.0),
    .REF_JITTER1(0.010),
    // 125 MHz input / 1 = 125 MHz PFD (range 10 MHz to 500 MHz)
    .DIVCLK_DIVIDE(1),
    // 125 MHz PFD * 10 = 1250 MHz VCO (range 600 MHz to 1440 MHz)
    .CLKFBOUT_MULT_F(10),
    .CLKFBOUT_PHASE(0),
    // 1250 MHz / 10 = 125 MHz, 0 degrees
    .CLKOUT0_DIVIDE_F(10),
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
    // 125 MHz input
    .CLKIN1(clk_125mhz_ibufg),
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
wire btnu_int;
wire btnl_int;
wire btnd_int;
wire btnr_int;
wire btnc_int;
wire [3:0] sw_int;

taxi_debounce_switch #(
    .WIDTH(9),
    .N(4),
    .RATE(125000)
)
debounce_switch_inst (
    .clk(clk_125mhz_int),
    .rst(rst_125mhz_int),
    .in({btnu,
        btnl,
        btnd,
        btnr,
        btnc,
        sw}),
    .out({btnu_int,
        btnl_int,
        btnd_int,
        btnr_int,
        btnc_int,
        sw_int})
);

wire uart_rxd_int;
wire uart_rts_int;

taxi_sync_signal #(
    .WIDTH(2),
    .N(2)
)
sync_signal_inst (
    .clk(clk_125mhz_int),
    .in({uart_rxd, uart_rts}),
    .out({uart_rxd_int, uart_rts_int})
);

// SGMII interface to PHY
wire phy_gmii_clk_int;
wire phy_gmii_rst_int;
wire phy_gmii_clk_en_int;
wire [7:0] phy_gmii_txd_int;
wire phy_gmii_tx_en_int;
wire phy_gmii_tx_er_int;
wire [7:0] phy_gmii_rxd_int;
wire phy_gmii_rx_dv_int;
wire phy_gmii_rx_er_int;

wire [15:0] pcspma_status_vector;

wire pcspma_status_link_status              = pcspma_status_vector[0];
wire pcspma_status_link_synchronization     = pcspma_status_vector[1];
wire pcspma_status_rudi_c                   = pcspma_status_vector[2];
wire pcspma_status_rudi_i                   = pcspma_status_vector[3];
wire pcspma_status_rudi_invalid             = pcspma_status_vector[4];
wire pcspma_status_rxdisperr                = pcspma_status_vector[5];
wire pcspma_status_rxnotintable             = pcspma_status_vector[6];
wire pcspma_status_phy_link_status          = pcspma_status_vector[7];
wire [1:0] pcspma_status_remote_fault_encdg = pcspma_status_vector[9:8];
wire [1:0] pcspma_status_speed              = pcspma_status_vector[11:10];
wire pcspma_status_duplex                   = pcspma_status_vector[12];
wire pcspma_status_remote_fault             = pcspma_status_vector[13];
wire [1:0] pcspma_status_pause              = pcspma_status_vector[15:14];

wire [4:0] pcspma_config_vector;

assign pcspma_config_vector[4] = 1'b1; // autonegotiation enable
assign pcspma_config_vector[3] = 1'b0; // isolate
assign pcspma_config_vector[2] = 1'b0; // power down
assign pcspma_config_vector[1] = 1'b0; // loopback enable
assign pcspma_config_vector[0] = 1'b0; // unidirectional enable

wire [15:0] pcspma_an_config_vector;

assign pcspma_an_config_vector[15]    = 1'b1;    // SGMII link status
assign pcspma_an_config_vector[14]    = 1'b1;    // SGMII Acknowledge
assign pcspma_an_config_vector[13:12] = 2'b01;   // full duplex
assign pcspma_an_config_vector[11:10] = 2'b10;   // SGMII speed
assign pcspma_an_config_vector[9]     = 1'b0;    // reserved
assign pcspma_an_config_vector[8:7]   = 2'b00;   // pause frames - SGMII reserved
assign pcspma_an_config_vector[6]     = 1'b0;    // reserved
assign pcspma_an_config_vector[5]     = 1'b0;    // full duplex - SGMII reserved
assign pcspma_an_config_vector[4:1]   = 4'b0000; // reserved
assign pcspma_an_config_vector[0]     = 1'b1;    // SGMII

sgmii_pcs_pma_0
eth_pcspma (
    // SGMII
    .txp                  (phy_sgmii_tx_p),
    .txn                  (phy_sgmii_tx_n),
    .rxp                  (phy_sgmii_rx_p),
    .rxn                  (phy_sgmii_rx_n),

    // Ref clock from PHY
    .refclk625_p          (phy_sgmii_clk_p),
    .refclk625_n          (phy_sgmii_clk_n),

    // async reset
    .reset                (rst_125mhz_int),

    // clock and reset outputs
    .clk125_out           (phy_gmii_clk_int),
    .clk625_out           (),
    .clk312_out           (),
    .rst_125_out          (phy_gmii_rst_int),
    .idelay_rdy_out       (),
    .mmcm_locked_out      (),

    // MAC clocking
    .sgmii_clk_r          (),
    .sgmii_clk_f          (),
    .sgmii_clk_en         (phy_gmii_clk_en_int),

    // Speed control
    .speed_is_10_100      (pcspma_status_speed != 2'b10),
    .speed_is_100         (pcspma_status_speed == 2'b01),

    // Internal GMII
    .gmii_txd             (phy_gmii_txd_int),
    .gmii_tx_en           (phy_gmii_tx_en_int),
    .gmii_tx_er           (phy_gmii_tx_er_int),
    .gmii_rxd             (phy_gmii_rxd_int),
    .gmii_rx_dv           (phy_gmii_rx_dv_int),
    .gmii_rx_er           (phy_gmii_rx_er_int),
    .gmii_isolate         (),

    // Configuration
    .configuration_vector (pcspma_config_vector),

    .an_interrupt         (),
    .an_adv_config_vector (pcspma_an_config_vector),
    .an_restart_config    (1'b0),

    // Status
    .status_vector        (pcspma_status_vector),
    .signal_detect        (1'b1)
);

wire [7:0] led_int;

// SGMII interface debug:
// SW12:1 (sw[3]) off for payload byte, on for status vector
// SW12:4 (sw[0]) off for LSB of status vector, on for MSB
assign led = sw[3] ? (sw[0] ? pcspma_status_vector[15:8] : pcspma_status_vector[7:0]) : led_int;

fpga_core #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY)
)
core_inst (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk(clk_125mhz_int),
    .rst(rst_125mhz_int),

    /*
     * GPIO
     */
    .btnu(btnu_int),
    .btnl(btnl_int),
    .btnd(btnd_int),
    .btnr(btnr_int),
    .btnc(btnc_int),
    .sw(sw_int),
    .led(led_int),

    /*
     * UART: 115200 bps, 8N1
     */
    .uart_rxd(uart_rxd_int),
    .uart_txd(uart_txd),
    .uart_rts(uart_rts_int),
    .uart_cts(uart_cts),

    /*
     * Ethernet: 1000BASE-T SGMII
     */
    .phy_gmii_clk(phy_gmii_clk_int),
    .phy_gmii_rst(phy_gmii_rst_int),
    .phy_gmii_clk_en(phy_gmii_clk_en_int),
    .phy_gmii_rxd(phy_gmii_rxd_int),
    .phy_gmii_rx_dv(phy_gmii_rx_dv_int),
    .phy_gmii_rx_er(phy_gmii_rx_er_int),
    .phy_gmii_txd(phy_gmii_txd_int),
    .phy_gmii_tx_en(phy_gmii_tx_en_int),
    .phy_gmii_tx_er(phy_gmii_tx_er_int),
    .phy_reset_n(phy_reset_n),
    .phy_int_n(phy_int_n),

    /*
     * Ethernet: QSFP28
     */
    .qsfp_rx_p(qsfp_rx_p),
    .qsfp_rx_n(qsfp_rx_n),
    .qsfp_tx_p(qsfp_tx_p),
    .qsfp_tx_n(qsfp_tx_n),
    .qsfp_mgt_refclk_0_p(qsfp_mgt_refclk_0_p),
    .qsfp_mgt_refclk_0_n(qsfp_mgt_refclk_0_n),
    // .qsfp_mgt_refclk_1_p(qsfp_mgt_refclk_1_p),
    // .qsfp_mgt_refclk_1_n(qsfp_mgt_refclk_1_n),
    // .qsfp_recclk_p(qsfp_recclk_p),
    // .qsfp_recclk_n(qsfp_recclk_n),
    .qsfp_modsell(qsfp_modsell),
    .qsfp_resetl(qsfp_resetl),
    .qsfp_modprsl(qsfp_modprsl),
    .qsfp_intl(qsfp_intl),
    .qsfp_lpmode(qsfp_lpmode)
);

endmodule

`resetall
