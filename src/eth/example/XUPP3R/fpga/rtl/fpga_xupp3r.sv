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
    parameter string FAMILY = "virtexuplus"
)
(
    /*
     * Clock: 48MHz
     */
    input  wire logic         clk_48mhz,
    input  wire logic         sys_rst_l,

    /*
     * GPIO
     */
    output wire logic [3:0]   led,

    /*
     * UART: 3000000 bps, 8N1
     */
    input  wire logic         uart_rxd,
    output wire logic         uart_txd,

    /*
     * I2C and related signals
     */
    inout  wire logic         eeprom_i2c_scl,
    inout  wire logic         eeprom_i2c_sda,
    output wire logic         fpga_i2c_master_l,
    output wire logic         qsfp_ctl_en,

    /*
     * Ethernet: QSFP28
     */
    output wire logic [3:0]   qsfp0_tx_p,
    output wire logic [3:0]   qsfp0_tx_n,
    input  wire logic [3:0]   qsfp0_rx_p,
    input  wire logic [3:0]   qsfp0_rx_n,
    input  wire logic         qsfp0_mgt_refclk_b0_p,
    input  wire logic         qsfp0_mgt_refclk_b0_n,
    // input  wire logic         qsfp0_mgt_refclk_b1_p,
    // input  wire logic         qsfp0_mgt_refclk_b1_n,
    // input  wire logic         qsfp0_mgt_refclk_c0_p,
    // input  wire logic         qsfp0_mgt_refclk_c0_n,
    // input  wire logic         qsfp0_mgt_refclk_c1_p,
    // input  wire logic         qsfp0_mgt_refclk_c1_n,
    output wire logic         qsfp0_resetl,
    input  wire logic         qsfp0_modprsl,
    input  wire logic         qsfp0_intl,
    output wire logic         qsfp0_lpmode,
    inout  wire logic         qsfp0_i2c_scl,
    inout  wire logic         qsfp0_i2c_sda,

    output wire logic [3:0]   qsfp1_tx_p,
    output wire logic [3:0]   qsfp1_tx_n,
    input  wire logic [3:0]   qsfp1_rx_p,
    input  wire logic [3:0]   qsfp1_rx_n,
    input  wire logic         qsfp1_mgt_refclk_b0_p,
    input  wire logic         qsfp1_mgt_refclk_b0_n,
    // input  wire logic         qsfp1_mgt_refclk_b1_p,
    // input  wire logic         qsfp1_mgt_refclk_b1_n,
    // input  wire logic         qsfp1_mgt_refclk_c2_p,
    // input  wire logic         qsfp1_mgt_refclk_c2_n,
    // input  wire logic         qsfp1_mgt_refclk_c3_p,
    // input  wire logic         qsfp1_mgt_refclk_c3_n,
    output wire logic         qsfp1_resetl,
    input  wire logic         qsfp1_modprsl,
    input  wire logic         qsfp1_intl,
    output wire logic         qsfp1_lpmode,
    inout  wire logic         qsfp1_i2c_scl,
    inout  wire logic         qsfp1_i2c_sda,

    output wire logic [3:0]   qsfp2_tx_p,
    output wire logic [3:0]   qsfp2_tx_n,
    input  wire logic [3:0]   qsfp2_rx_p,
    input  wire logic [3:0]   qsfp2_rx_n,
    input  wire logic         qsfp2_mgt_refclk_b0_p,
    input  wire logic         qsfp2_mgt_refclk_b0_n,
    // input  wire logic         qsfp2_mgt_refclk_b2_p,
    // input  wire logic         qsfp2_mgt_refclk_b2_n,
    // input  wire logic         qsfp2_mgt_refclk_d0_p,
    // input  wire logic         qsfp2_mgt_refclk_d0_n,
    // input  wire logic         qsfp2_mgt_refclk_d1_p,
    // input  wire logic         qsfp2_mgt_refclk_d1_n,
    output wire logic         qsfp2_resetl,
    input  wire logic         qsfp2_modprsl,
    input  wire logic         qsfp2_intl,
    output wire logic         qsfp2_lpmode,
    inout  wire logic         qsfp2_i2c_scl,
    inout  wire logic         qsfp2_i2c_sda,

    output wire logic [3:0]   qsfp3_tx_p,
    output wire logic [3:0]   qsfp3_tx_n,
    input  wire logic [3:0]   qsfp3_rx_p,
    input  wire logic [3:0]   qsfp3_rx_n,
    input  wire logic         qsfp3_mgt_refclk_b0_p,
    input  wire logic         qsfp3_mgt_refclk_b0_n,
    // input  wire logic         qsfp3_mgt_refclk_b3_p,
    // input  wire logic         qsfp3_mgt_refclk_b3_n,
    // input  wire logic         qsfp3_mgt_refclk_d2_p,
    // input  wire logic         qsfp3_mgt_refclk_d2_n,
    // input  wire logic         qsfp3_mgt_refclk_d3_p,
    // input  wire logic         qsfp3_mgt_refclk_d3_n,
    output wire logic         qsfp3_resetl,
    input  wire logic         qsfp3_modprsl,
    input  wire logic         qsfp3_intl,
    output wire logic         qsfp3_lpmode,
    inout  wire logic         qsfp3_i2c_scl,
    inout  wire logic         qsfp3_i2c_sda
);

// Clock and reset

wire clk_125mhz_mmcm_out;

// Internal 125 MHz clock
wire clk_125mhz_int;
wire rst_125mhz_int;

wire mmcm_rst = !sys_rst_l;
wire mmcm_locked;
wire mmcm_clkfb;

// MMCM instance
MMCME4_BASE #(
    // 48 MHz input
    .CLKIN1_PERIOD(20.833),
    .REF_JITTER1(0.010),
    // 48 MHz input / 4 = 12 MHz PFD (range 10 MHz to 500 MHz)
    .DIVCLK_DIVIDE(4),
    // 12 MHz PFD * 125 = 1500 MHz VCO (range 800 MHz to 1600 MHz)
    .CLKFBOUT_MULT_F(125),
    .CLKFBOUT_PHASE(0),
    // 1500 MHz / 12 = 125 MHz, 0 degrees
    .CLKOUT0_DIVIDE_F(12),
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
    // 48 MHz input
    .CLKIN1(clk_48mhz),
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
assign qsfp_ctl_en = 1'b1;
assign fpga_i2c_master_l = 1'b0;

wire uart_rxd_int;

wire eeprom_i2c_scl_i;
wire eeprom_i2c_scl_o;
wire eeprom_i2c_sda_i;
wire eeprom_i2c_sda_o;

wire qsfp0_modprsl_int;
wire qsfp0_intl_int;
wire qsfp0_i2c_scl_i;
wire qsfp0_i2c_scl_o;
wire qsfp0_i2c_sda_i;
wire qsfp0_i2c_sda_o;

wire qsfp1_modprsl_int;
wire qsfp1_intl_int;
wire qsfp1_i2c_scl_i;
wire qsfp1_i2c_scl_o;
wire qsfp1_i2c_sda_i;
wire qsfp1_i2c_sda_o;

wire qsfp2_modprsl_int;
wire qsfp2_intl_int;
wire qsfp2_i2c_scl_i;
wire qsfp2_i2c_scl_o;
wire qsfp2_i2c_sda_i;
wire qsfp2_i2c_sda_o;

wire qsfp3_modprsl_int;
wire qsfp3_intl_int;
wire qsfp3_i2c_scl_i;
wire qsfp3_i2c_scl_o;
wire qsfp3_i2c_sda_i;
wire qsfp3_i2c_sda_o;

logic eeprom_i2c_scl_o_reg;
logic eeprom_i2c_sda_o_reg;

logic qsfp0_i2c_scl_o_reg;
logic qsfp0_i2c_sda_o_reg;

logic qsfp1_i2c_scl_o_reg;
logic qsfp1_i2c_sda_o_reg;

logic qsfp2_i2c_scl_o_reg;
logic qsfp2_i2c_sda_o_reg;

logic qsfp3_i2c_scl_o_reg;
logic qsfp3_i2c_sda_o_reg;

always_ff @(posedge clk_125mhz_int) begin
    eeprom_i2c_scl_o_reg <= eeprom_i2c_scl_o;
    eeprom_i2c_sda_o_reg <= eeprom_i2c_sda_o;

    qsfp0_i2c_scl_o_reg <= qsfp0_i2c_scl_o;
    qsfp0_i2c_sda_o_reg <= qsfp0_i2c_sda_o;

    qsfp1_i2c_scl_o_reg <= qsfp1_i2c_scl_o;
    qsfp1_i2c_sda_o_reg <= qsfp1_i2c_sda_o;

    qsfp2_i2c_scl_o_reg <= qsfp2_i2c_scl_o;
    qsfp2_i2c_sda_o_reg <= qsfp2_i2c_sda_o;

    qsfp3_i2c_scl_o_reg <= qsfp3_i2c_scl_o;
    qsfp3_i2c_sda_o_reg <= qsfp3_i2c_sda_o;
end

taxi_sync_signal #(
    .WIDTH(19),
    .N(2)
)
sync_signal_inst (
    .clk(clk_125mhz_int),
    .in({uart_rxd, eeprom_i2c_scl, eeprom_i2c_sda,
        qsfp0_modprsl, qsfp0_intl, qsfp0_i2c_scl, qsfp0_i2c_sda,
        qsfp1_modprsl, qsfp1_intl, qsfp1_i2c_scl, qsfp1_i2c_sda,
        qsfp2_modprsl, qsfp2_intl, qsfp2_i2c_scl, qsfp2_i2c_sda,
        qsfp3_modprsl, qsfp3_intl, qsfp3_i2c_scl, qsfp3_i2c_sda}),
    .out({uart_rxd_int, eeprom_i2c_scl_i, eeprom_i2c_sda_i,
        qsfp0_modprsl_int, qsfp0_intl_int, qsfp0_i2c_scl_i, qsfp0_i2c_sda_i,
        qsfp1_modprsl_int, qsfp1_intl_int, qsfp1_i2c_scl_i, qsfp1_i2c_sda_i,
        qsfp2_modprsl_int, qsfp2_intl_int, qsfp2_i2c_scl_i, qsfp2_i2c_sda_i,
        qsfp3_modprsl_int, qsfp3_intl_int, qsfp3_i2c_scl_i, qsfp3_i2c_sda_i})
);

assign eeprom_i2c_scl = eeprom_i2c_scl_o_reg ? 1'bz : 1'b0;
assign eeprom_i2c_sda = eeprom_i2c_sda_o_reg ? 1'bz : 1'b0;

assign qsfp0_i2c_scl = qsfp0_i2c_scl_o_reg ? 1'bz : 1'b0;
assign qsfp0_i2c_sda = qsfp0_i2c_sda_o_reg ? 1'bz : 1'b0;

assign qsfp1_i2c_scl = qsfp1_i2c_scl_o_reg ? 1'bz : 1'b0;
assign qsfp1_i2c_sda = qsfp1_i2c_sda_o_reg ? 1'bz : 1'b0;

assign qsfp2_i2c_scl = qsfp2_i2c_scl_o_reg ? 1'bz : 1'b0;
assign qsfp2_i2c_sda = qsfp2_i2c_sda_o_reg ? 1'bz : 1'b0;

assign qsfp3_i2c_scl = qsfp3_i2c_scl_o_reg ? 1'bz : 1'b0;
assign qsfp3_i2c_sda = qsfp3_i2c_sda_o_reg ? 1'bz : 1'b0;

fpga_core #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY)
)
core_inst (
    /*
     * Clock: 125 MHz
     * Synchronous reset
     */
    .clk_125mhz(clk_125mhz_int),
    .rst_125mhz(rst_125mhz_int),

    /*
     * GPIO
     */
    .led(led),

    /*
     * UART: 3000000 bps, 8N1
     */
    .uart_rxd(uart_rxd_int),
    .uart_txd(uart_txd),

    /*
     * I2C
     */
    .eeprom_i2c_scl_i(eeprom_i2c_scl_i),
    .eeprom_i2c_scl_o(eeprom_i2c_scl_o),
    .eeprom_i2c_sda_i(eeprom_i2c_sda_i),
    .eeprom_i2c_sda_o(eeprom_i2c_sda_o),

    /*
     * Ethernet: QSFP28
     */
    .qsfp0_tx_p(qsfp0_tx_p),
    .qsfp0_tx_n(qsfp0_tx_n),
    .qsfp0_rx_p(qsfp0_rx_p),
    .qsfp0_rx_n(qsfp0_rx_n),
    .qsfp0_mgt_refclk_b0_p(qsfp0_mgt_refclk_b0_p),
    .qsfp0_mgt_refclk_b0_n(qsfp0_mgt_refclk_b0_n),

    .qsfp0_modprsl(qsfp0_modprsl_int),
    .qsfp0_resetl(qsfp0_resetl),
    .qsfp0_intl(qsfp0_intl_int),
    .qsfp0_lpmode(qsfp0_lpmode),

    .qsfp0_i2c_scl_i(qsfp0_i2c_scl_i),
    .qsfp0_i2c_scl_o(qsfp0_i2c_scl_o),
    .qsfp0_i2c_sda_i(qsfp0_i2c_sda_i),
    .qsfp0_i2c_sda_o(qsfp0_i2c_sda_o),

    .qsfp1_tx_p(qsfp1_tx_p),
    .qsfp1_tx_n(qsfp1_tx_n),
    .qsfp1_rx_p(qsfp1_rx_p),
    .qsfp1_rx_n(qsfp1_rx_n),
    .qsfp1_mgt_refclk_b0_p(qsfp1_mgt_refclk_b0_p),
    .qsfp1_mgt_refclk_b0_n(qsfp1_mgt_refclk_b0_n),

    .qsfp1_modprsl(qsfp1_modprsl_int),
    .qsfp1_resetl(qsfp1_resetl),
    .qsfp1_intl(qsfp1_intl_int),
    .qsfp1_lpmode(qsfp1_lpmode),

    .qsfp1_i2c_scl_i(qsfp1_i2c_scl_i),
    .qsfp1_i2c_scl_o(qsfp1_i2c_scl_o),
    .qsfp1_i2c_sda_i(qsfp1_i2c_sda_i),
    .qsfp1_i2c_sda_o(qsfp1_i2c_sda_o),

    .qsfp2_tx_p(qsfp2_tx_p),
    .qsfp2_tx_n(qsfp2_tx_n),
    .qsfp2_rx_p(qsfp2_rx_p),
    .qsfp2_rx_n(qsfp2_rx_n),
    .qsfp2_mgt_refclk_b0_p(qsfp2_mgt_refclk_b0_p),
    .qsfp2_mgt_refclk_b0_n(qsfp2_mgt_refclk_b0_n),

    .qsfp2_modprsl(qsfp2_modprsl_int),
    .qsfp2_resetl(qsfp2_resetl),
    .qsfp2_intl(qsfp2_intl_int),
    .qsfp2_lpmode(qsfp2_lpmode),

    .qsfp2_i2c_scl_i(qsfp2_i2c_scl_i),
    .qsfp2_i2c_scl_o(qsfp2_i2c_scl_o),
    .qsfp2_i2c_sda_i(qsfp2_i2c_sda_i),
    .qsfp2_i2c_sda_o(qsfp2_i2c_sda_o),

    .qsfp3_tx_p(qsfp3_tx_p),
    .qsfp3_tx_n(qsfp3_tx_n),
    .qsfp3_rx_p(qsfp3_rx_p),
    .qsfp3_rx_n(qsfp3_rx_n),
    .qsfp3_mgt_refclk_b0_p(qsfp3_mgt_refclk_b0_p),
    .qsfp3_mgt_refclk_b0_n(qsfp3_mgt_refclk_b0_n),

    .qsfp3_modprsl(qsfp3_modprsl_int),
    .qsfp3_resetl(qsfp3_resetl),
    .qsfp3_intl(qsfp3_intl_int),
    .qsfp3_lpmode(qsfp3_lpmode),

    .qsfp3_i2c_scl_i(qsfp3_i2c_scl_i),
    .qsfp3_i2c_scl_o(qsfp3_i2c_scl_o),
    .qsfp3_i2c_sda_i(qsfp3_i2c_sda_i),
    .qsfp3_i2c_sda_o(qsfp3_i2c_sda_o)
);

endmodule

`resetall
