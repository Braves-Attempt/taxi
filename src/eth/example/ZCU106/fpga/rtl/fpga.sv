// SPDX-License-Identifier: MIT
/*

Copyright (c) 2020-2025 FPGA Ninja, LLC

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
    // simulation (set to avoid vendor primitives)
    parameter logic SIM = 1'b0,
    // vendor ("GENERIC", "XILINX", "ALTERA")
    parameter string VENDOR = "XILINX",
    // device family
    parameter string FAMILY = "zynquplus",
    // SFP rate selection (0 for 1G, 1 for 10G)
    parameter logic SFP_RATE = 1'b1,
    // 10G MAC configuration
    parameter logic CFG_LOW_LATENCY = 1'b1,
    parameter logic COMBINED_MAC_PCS = 1'b1,
    parameter MAC_DATA_W = 32
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
    input  wire logic [7:0]  sw,
    output wire logic [7:0]  led,

    /*
     * UART: 115200 bps, 8N1
     */
    input  wire logic        uart_rxd,
    output wire logic        uart_txd,
    input  wire logic        uart_rts,
    output wire logic        uart_cts,

    /*
     * Ethernet: SFP+
     */
    input  wire logic [1:0]  sfp_rx_p,
    input  wire logic [1:0]  sfp_rx_n,
    output wire logic [1:0]  sfp_tx_p,
    output wire logic [1:0]  sfp_tx_n,
    input  wire logic        sfp_mgt_refclk_0_p,
    input  wire logic        sfp_mgt_refclk_0_n,
    output wire logic [1:0]  sfp_tx_disable_b
);

wire clk_125mhz_ibufg;

// Internal 125 MHz clock
wire clk_125mhz_mmcm_out;
wire clk_125mhz_int;
wire rst_125mhz_int;

// Internal 62.5 MHz clock
wire clk_62mhz_mmcm_out;
wire clk_62mhz_int;

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
MMCME4_BASE #(
    // 125 MHz input
    .CLKIN1_PERIOD(8.0),
    .REF_JITTER1(0.010),
    // 125 MHz input / 1 = 125 MHz PFD (range 10 MHz to 500 MHz)
    .DIVCLK_DIVIDE(1),
    // 125 MHz PFD * 10 = 1250 MHz VCO (range 800 MHz to 1600 MHz)
    .CLKFBOUT_MULT_F(10),
    .CLKFBOUT_PHASE(0),
    // 1250 MHz / 10 = 125 MHz, 0 degrees
    .CLKOUT0_DIVIDE_F(10),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0),
    // 1250 MHz / 20 = 62.5 MHz, 0 degrees
    .CLKOUT1_DIVIDE(20),
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
    // 62.5 MHz, 0 degrees
    .CLKOUT1(clk_62mhz_mmcm_out),
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

BUFG
clk_62mhz_bufg_inst (
    .I(clk_62mhz_mmcm_out),
    .O(clk_62mhz_int)
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
wire [7:0] sw_int;

taxi_debounce_switch #(
    .WIDTH(5+8),
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

wire [7:0] led_int;

// SFP+
wire [1:0] sfp_tx_p_int;
wire [1:0] sfp_tx_n_int;

wire sfp0_gmii_clk_int;
wire sfp0_gmii_rst_int;
wire sfp0_gmii_clk_en_int = 1'b1;
wire [7:0] sfp0_gmii_txd_int;
wire sfp0_gmii_tx_en_int;
wire sfp0_gmii_tx_er_int;
wire [7:0] sfp0_gmii_rxd_int;
wire sfp0_gmii_rx_dv_int;
wire sfp0_gmii_rx_er_int;

wire [15:0] sfp0_status_vect;

wire sfp1_gmii_clk_int;
wire sfp1_gmii_rst_int;
wire sfp1_gmii_clk_en_int = 1'b1;
wire [7:0] sfp1_gmii_txd_int;
wire sfp1_gmii_tx_en_int;
wire sfp1_gmii_tx_er_int;
wire [7:0] sfp1_gmii_rxd_int;
wire sfp1_gmii_rx_dv_int;
wire sfp1_gmii_rx_er_int;

wire [15:0] sfp1_status_vect;

if (SFP_RATE == 0) begin : sfp_phy
    // 1000BASE-X

    wire sfp0_gmii_gtrefclk;
    wire sfp0_gmii_txuserclk;
    wire sfp0_gmii_txuserclk2;
    wire sfp0_gmii_resetdone;
    wire sfp0_gmii_pmareset;
    wire sfp0_gmii_mmcm_locked;

    assign sfp0_gmii_clk_int = sfp0_gmii_txuserclk2;

    taxi_sync_reset #(
        .N(4)
    )
    sync_reset_sfp0_inst (
        .clk(sfp0_gmii_clk_int),
        .rst(rst_125mhz_int || !sfp0_gmii_resetdone),
        .out(sfp0_gmii_rst_int)
    );

    wire sfp0_status_link_status              = sfp0_status_vect[0];
    wire sfp0_status_link_synchronization     = sfp0_status_vect[1];
    wire sfp0_status_rudi_c                   = sfp0_status_vect[2];
    wire sfp0_status_rudi_i                   = sfp0_status_vect[3];
    wire sfp0_status_rudi_invalid             = sfp0_status_vect[4];
    wire sfp0_status_rxdisperr                = sfp0_status_vect[5];
    wire sfp0_status_rxnotintable             = sfp0_status_vect[6];
    wire sfp0_status_phy_link_status          = sfp0_status_vect[7];
    wire [1:0] sfp0_status_remote_fault_encdg = sfp0_status_vect[9:8];
    wire [1:0] sfp0_status_speed              = sfp0_status_vect[11:10];
    wire sfp0_status_duplex                   = sfp0_status_vect[12];
    wire sfp0_status_remote_fault             = sfp0_status_vect[13];
    wire [1:0] sfp0_status_pause              = sfp0_status_vect[15:14];

    wire [4:0] sfp0_config_vect;

    assign sfp0_config_vect[4] = 1'b0; // autonegotiation enable
    assign sfp0_config_vect[3] = 1'b0; // isolate
    assign sfp0_config_vect[2] = 1'b0; // power down
    assign sfp0_config_vect[1] = 1'b0; // loopback enable
    assign sfp0_config_vect[0] = 1'b0; // unidirectional enable

    basex_pcs_pma_0
    sfp0_pcspma (
        .gtrefclk_p(sfp_mgt_refclk_0_p),
        .gtrefclk_n(sfp_mgt_refclk_0_n),
        .gtrefclk_out(sfp0_gmii_gtrefclk),
        .txn(sfp_tx_n[0]),
        .txp(sfp_tx_p[0]),
        .rxn(sfp_rx_n[0]),
        .rxp(sfp_rx_p[0]),
        .independent_clock_bufg(clk_62mhz_int),
        .userclk_out(sfp0_gmii_txuserclk),
        .userclk2_out(sfp0_gmii_txuserclk2),
        .rxuserclk_out(),
        .rxuserclk2_out(),
        .gtpowergood(),
        .resetdone(sfp0_gmii_resetdone),
        .pma_reset_out(sfp0_gmii_pmareset),
        .mmcm_locked_out(sfp0_gmii_mmcm_locked),
        .gmii_txd(sfp0_gmii_txd_int),
        .gmii_tx_en(sfp0_gmii_tx_en_int),
        .gmii_tx_er(sfp0_gmii_tx_er_int),
        .gmii_rxd(sfp0_gmii_rxd_int),
        .gmii_rx_dv(sfp0_gmii_rx_dv_int),
        .gmii_rx_er(sfp0_gmii_rx_er_int),
        .gmii_isolate(),
        .configuration_vector(sfp0_config_vect),
        .status_vector(sfp0_status_vect),
        .reset(rst_125mhz_int),
        .signal_detect(1'b1)
    );

    wire sfp1_gmii_txuserclk2 = sfp0_gmii_txuserclk2;
    wire sfp1_gmii_resetdone;

    assign sfp1_gmii_clk_int = sfp1_gmii_txuserclk2;

    taxi_sync_reset #(
        .N(4)
    )
    sync_reset_sfp1_inst (
        .clk(sfp1_gmii_clk_int),
        .rst(rst_125mhz_int || !sfp1_gmii_resetdone),
        .out(sfp1_gmii_rst_int)
    );

    wire sfp1_status_link_status              = sfp1_status_vect[0];
    wire sfp1_status_link_synchronization     = sfp1_status_vect[1];
    wire sfp1_status_rudi_c                   = sfp1_status_vect[2];
    wire sfp1_status_rudi_i                   = sfp1_status_vect[3];
    wire sfp1_status_rudi_invalid             = sfp1_status_vect[4];
    wire sfp1_status_rxdisperr                = sfp1_status_vect[5];
    wire sfp1_status_rxnotintable             = sfp1_status_vect[6];
    wire sfp1_status_phy_link_status          = sfp1_status_vect[7];
    wire [1:0] sfp1_status_remote_fault_encdg = sfp1_status_vect[9:8];
    wire [1:0] sfp1_status_speed              = sfp1_status_vect[11:10];
    wire sfp1_status_duplex                   = sfp1_status_vect[12];
    wire sfp1_status_remote_fault             = sfp1_status_vect[13];
    wire [1:0] sfp1_status_pause              = sfp1_status_vect[15:14];

    wire [4:0] sfp1_config_vect;

    assign sfp1_config_vect[4] = 1'b0; // autonegotiation enable
    assign sfp1_config_vect[3] = 1'b0; // isolate
    assign sfp1_config_vect[2] = 1'b0; // power down
    assign sfp1_config_vect[1] = 1'b0; // loopback enable
    assign sfp1_config_vect[0] = 1'b0; // unidirectional enable

    basex_pcs_pma_1
    sfp1_pcspma (
        .gtrefclk(sfp0_gmii_gtrefclk),
        .txn(sfp_tx_n[1]),
        .txp(sfp_tx_p[1]),
        .rxn(sfp_rx_n[1]),
        .rxp(sfp_rx_p[1]),
        .independent_clock_bufg(clk_62mhz_int),
        .txoutclk(),
        .gtpowergood(),
        .rxoutclk(),
        .resetdone(sfp1_gmii_resetdone),
        .cplllock(),
        .mmcm_reset(),
        .userclk(sfp0_gmii_txuserclk),
        .userclk2(sfp0_gmii_txuserclk2),
        .pma_reset(sfp0_gmii_pmareset),
        .mmcm_locked(sfp0_gmii_mmcm_locked),
        .rxuserclk(1'b0),
        .rxuserclk2(1'b0),
        .gmii_txd(sfp1_gmii_txd_int),
        .gmii_tx_en(sfp1_gmii_tx_en_int),
        .gmii_tx_er(sfp1_gmii_tx_er_int),
        .gmii_rxd(sfp1_gmii_rxd_int),
        .gmii_rx_dv(sfp1_gmii_rx_dv_int),
        .gmii_rx_er(sfp1_gmii_rx_er_int),
        .gmii_isolate(),
        .configuration_vector(sfp1_config_vect),
        .status_vector(sfp1_status_vect),
        .reset(rst_125mhz_int),
        .signal_detect(1'b1)
    );

end else begin
    // 10GBASE-R

    assign sfp_tx_p = sfp_tx_p_int;
    assign sfp_tx_n = sfp_tx_n_int;

end

// SGMII interface debug:
// SW12:1 (sw[3]) off for payload byte, on for status vector
// SW12:2 (sw[2]) off for SFP0, on for SFP1
// SW12:4 (sw[0]) off for LSB of status vector, on for MSB
wire [15:0] sel_sv = sw[2] ? sfp1_status_vect : sfp0_status_vect;
assign led = sw[3] ? (sw[0] ? sel_sv[15:8] : sel_sv[7:0]) : led_int;

fpga_core #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .SFP_RATE(SFP_RATE),
    .CFG_LOW_LATENCY(CFG_LOW_LATENCY),
    .COMBINED_MAC_PCS(COMBINED_MAC_PCS),
    .MAC_DATA_W(MAC_DATA_W)
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
     * Ethernet: SFP+
     */
    .sfp_rx_p(sfp_rx_p),
    .sfp_rx_n(sfp_rx_n),
    .sfp_tx_p(sfp_tx_p_int),
    .sfp_tx_n(sfp_tx_n_int),
    .sfp_mgt_refclk_0_p(sfp_mgt_refclk_0_p),
    .sfp_mgt_refclk_0_n(sfp_mgt_refclk_0_n),

    .sfp0_gmii_clk(sfp0_gmii_clk_int),
    .sfp0_gmii_rst(sfp0_gmii_rst_int),
    .sfp0_gmii_clk_en(sfp0_gmii_clk_en_int),
    .sfp0_gmii_rxd(sfp0_gmii_rxd_int),
    .sfp0_gmii_rx_dv(sfp0_gmii_rx_dv_int),
    .sfp0_gmii_rx_er(sfp0_gmii_rx_er_int),
    .sfp0_gmii_txd(sfp0_gmii_txd_int),
    .sfp0_gmii_tx_en(sfp0_gmii_tx_en_int),
    .sfp0_gmii_tx_er(sfp0_gmii_tx_er_int),

    .sfp1_gmii_clk(sfp1_gmii_clk_int),
    .sfp1_gmii_rst(sfp1_gmii_rst_int),
    .sfp1_gmii_clk_en(sfp1_gmii_clk_en_int),
    .sfp1_gmii_rxd(sfp1_gmii_rxd_int),
    .sfp1_gmii_rx_dv(sfp1_gmii_rx_dv_int),
    .sfp1_gmii_rx_er(sfp1_gmii_rx_er_int),
    .sfp1_gmii_txd(sfp1_gmii_txd_int),
    .sfp1_gmii_tx_en(sfp1_gmii_tx_en_int),
    .sfp1_gmii_tx_er(sfp1_gmii_tx_er_int),

    .sfp_tx_disable_b(sfp_tx_disable_b)
);

endmodule

`resetall
