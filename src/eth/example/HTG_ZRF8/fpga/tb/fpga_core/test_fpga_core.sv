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
 * FPGA core logic testbench
 */
module test_fpga_core #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter logic SIM = 1'b1,
    parameter string VENDOR = "XILINX",
    parameter string FAMILY = "zynquplusRFSOC",
    parameter PORT_CNT = 2,
    parameter GTY_QUAD_CNT = PORT_CNT,
    parameter GTY_CNT = GTY_QUAD_CNT*4,
    parameter GTY_CLK_CNT = GTY_QUAD_CNT,
    parameter ADC_CNT = 8,
    parameter ADC_SAMPLE_W = 16,
    parameter ADC_SAMPLE_CNT = 4,
    parameter DAC_CNT = ADC_CNT,
    parameter DAC_SAMPLE_W = ADC_SAMPLE_W,
    parameter DAC_SAMPLE_CNT = ADC_SAMPLE_CNT
    /* verilator lint_on WIDTHTRUNC */
)
();

localparam ADC_DATA_W = ADC_SAMPLE_W*ADC_SAMPLE_CNT;
localparam DAC_DATA_W = DAC_SAMPLE_W*DAC_SAMPLE_CNT;

logic clk_125mhz;
logic rst_125mhz;
logic fpga_refclk;
logic fpga_sysref;

logic [3:0] sw;
logic [3:0] led;
logic [7:0] gpio;

logic i2c_scl_i;
logic i2c_scl_o;
logic i2c_sda_i;
logic i2c_sda_o;

logic uart_rxd;
logic uart_txd;
logic uart_rts;
logic uart_cts;
logic uart_rst_n;
logic uart_suspend_n;

logic [GTY_CNT-1:0] eth_gty_tx_p;
logic [GTY_CNT-1:0] eth_gty_tx_n;
logic [GTY_CNT-1:0] eth_gty_rx_p;
logic [GTY_CNT-1:0] eth_gty_rx_n;
logic [GTY_CLK_CNT-1:0] eth_gty_mgt_refclk_p;
logic [GTY_CLK_CNT-1:0] eth_gty_mgt_refclk_n;
logic [GTY_CLK_CNT-1:0] eth_gty_mgt_refclk_out;

logic [PORT_CNT-1:0] eth_port_resetl;
logic [PORT_CNT-1:0] eth_port_modprsl;
logic [PORT_CNT-1:0] eth_port_intl;

logic axil_rfdc_clk;
logic axil_rfdc_rst;

taxi_axil_if #(
    .DATA_W(32),
    .ADDR_W(18)
) m_axil_rfdc();

logic axis_rfdc_clk;
logic axis_rfdc_rst;

taxi_axis_if #(
    .DATA_W(ADC_DATA_W),
    .KEEP_EN(1),
    .KEEP_W(ADC_SAMPLE_CNT),
    .LAST_EN(0),
    .USER_EN(0),
    .ID_EN(0),
    .DEST_EN(0)
) s_axis_adc[ADC_CNT]();

taxi_axis_if #(
    .DATA_W(DAC_DATA_W),
    .KEEP_EN(1),
    .KEEP_W(DAC_SAMPLE_CNT),
    .LAST_EN(0),
    .USER_EN(0),
    .ID_EN(0),
    .DEST_EN(0)
) m_axis_dac[DAC_CNT]();

fpga_core #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .PORT_CNT(PORT_CNT),
    .GTY_QUAD_CNT(GTY_QUAD_CNT),
    .GTY_CNT(GTY_CNT),
    .GTY_CLK_CNT(GTY_CLK_CNT),
    .ADC_CNT(ADC_CNT),
    .DAC_CNT(DAC_CNT)
)
uut (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk_125mhz(clk_125mhz),
    .rst_125mhz(rst_125mhz),
    .fpga_refclk(fpga_refclk),
    .fpga_sysref(fpga_sysref),

    /*
     * GPIO
     */
    .sw(sw),
    .led(led),
    .gpio(gpio),

    /*
     * I2C for board management
     */
    .i2c_scl_i(i2c_scl_i),
    .i2c_scl_o(i2c_scl_o),
    .i2c_sda_i(i2c_sda_i),
    .i2c_sda_o(i2c_sda_o),

    /*
     * UART: 115200 bps, 8N1
     */
    .uart_rxd(uart_rxd),
    .uart_txd(uart_txd),
    .uart_rts(uart_rts),
    .uart_cts(uart_cts),
    .uart_rst_n(uart_rst_n),
    .uart_suspend_n(uart_suspend_n),

    /*
     * Ethernet: FMC
     */
    .eth_gty_tx_p(eth_gty_tx_p),
    .eth_gty_tx_n(eth_gty_tx_n),
    .eth_gty_rx_p(eth_gty_rx_p),
    .eth_gty_rx_n(eth_gty_rx_n),
    .eth_gty_mgt_refclk_p(eth_gty_mgt_refclk_p),
    .eth_gty_mgt_refclk_n(eth_gty_mgt_refclk_n),
    .eth_gty_mgt_refclk_out(eth_gty_mgt_refclk_out),

    .eth_port_resetl(eth_port_resetl),
    .eth_port_modprsl(eth_port_modprsl),
    .eth_port_intl(eth_port_intl),

    /*
     * RFDC
     */
    .axil_rfdc_clk(axil_rfdc_clk),
    .axil_rfdc_rst(axil_rfdc_rst),
    .m_axil_rfdc_wr(m_axil_rfdc),
    .m_axil_rfdc_rd(m_axil_rfdc),

    .axis_rfdc_clk(axis_rfdc_clk),
    .axis_rfdc_rst(axis_rfdc_rst),
    .s_axis_adc(s_axis_adc),
    .m_axis_dac(m_axis_dac)
);

endmodule

`resetall
