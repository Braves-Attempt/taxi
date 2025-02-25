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
    parameter string FAMILY = "kintexuplus"
)
(
    /*
     * GPIO
     */
    output wire logic [1:0][1:0]  sfp_led,
    output wire logic [1:0]       sma_led,

    /*
     * Ethernet: SFP+
     */
    input  wire logic [1:0]       sfp_rx_p,
    input  wire logic [1:0]       sfp_rx_n,
    output wire logic [1:0]       sfp_tx_p,
    output wire logic [1:0]       sfp_tx_n,
    input  wire logic             sfp_mgt_refclk_p,
    input  wire logic             sfp_mgt_refclk_n,
    output wire logic [1:0]       sfp_tx_disable,
    input  wire logic [1:0]       sfp_npres,
    input  wire logic [1:0]       sfp_los,
    output wire logic [1:0]       sfp_rs
);

// Clock and reset

wire sfp_mgt_refclk_out;

// Internal 125 MHz clock
wire clk_125mhz_mmcm_out;
wire clk_125mhz_int;
wire rst_125mhz_int;

wire mmcm_rst = 1'b0;
wire mmcm_locked;
wire mmcm_clkfb;

// MMCM instance
MMCME4_BASE #(
    // 161.13 MHz input
    .CLKIN1_PERIOD(6.206),
    .REF_JITTER1(0.010),
    // 161.13 MHz input / 11 = 14.65 MHz PFD (range 10 MHz to 500 MHz)
    .DIVCLK_DIVIDE(11),
    // 14.65 MHz PFD * 64 = 937.5 MHz VCO (range 800 MHz to 1600 MHz)
    .CLKFBOUT_MULT_F(64),
    .CLKFBOUT_PHASE(0),
    // 937.5 MHz / 7.5 = 125 MHz, 0 degrees
    .CLKOUT0_DIVIDE_F(7.5),
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
    // 161.13 MHz input
    .CLKIN1(sfp_mgt_refclk_out),
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
    .sfp_led(sfp_led),
    .sma_led(sma_led),

    /*
     * Ethernet: SFP+
     */
    .sfp_rx_p(sfp_rx_p),
    .sfp_rx_n(sfp_rx_n),
    .sfp_tx_p(sfp_tx_p),
    .sfp_tx_n(sfp_tx_n),
    .sfp_mgt_refclk_p(sfp_mgt_refclk_p),
    .sfp_mgt_refclk_n(sfp_mgt_refclk_n),
    .sfp_mgt_refclk_out(sfp_mgt_refclk_out),
    .sfp_tx_disable(sfp_tx_disable),
    .sfp_npres(sfp_npres),
    .sfp_los(sfp_los),
    .sfp_rs(sfp_rs)
);

endmodule

`resetall
