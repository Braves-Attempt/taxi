// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2015-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * GMII PHY interface
 */
module taxi_gmii_phy_if #
(
    // simulation (set to avoid vendor primitives)
    parameter logic SIM = 1'b0,
    // vendor ("GENERIC", "XILINX", "ALTERA")
    parameter VENDOR = "XILINX",
    // device family
    parameter FAMILY = "virtex7"
)
(
    input  wire logic        gtx_clk,
    input  wire logic        gtx_rst,

    /*
     * GMII interface to MAC
     */
    output wire logic        mac_gmii_rx_clk,
    output wire logic        mac_gmii_rx_rst,
    output wire logic [7:0]  mac_gmii_rxd,
    output wire logic        mac_gmii_rx_dv,
    output wire logic        mac_gmii_rx_er,
    output wire logic        mac_gmii_tx_clk,
    output wire logic        mac_gmii_tx_rst,
    input  wire logic [7:0]  mac_gmii_txd,
    input  wire logic        mac_gmii_tx_en,
    input  wire logic        mac_gmii_tx_er,

    /*
     * GMII interface to PHY
     */
    input  wire logic        phy_gmii_rx_clk,
    input  wire logic [7:0]  phy_gmii_rxd,
    input  wire logic        phy_gmii_rx_dv,
    input  wire logic        phy_gmii_rx_er,
    input  wire logic        phy_mii_tx_clk,
    output wire logic        phy_gmii_tx_clk,
    output wire logic [7:0]  phy_gmii_txd,
    output wire logic        phy_gmii_tx_en,
    output wire logic        phy_gmii_tx_er,

    /*
     * Control
     */
    input  wire logic        mii_select
);

taxi_ssio_sdr_in #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .WIDTH(10)
)
rx_ssio_sdr_inst (
    .input_clk(phy_gmii_rx_clk),
    .input_d({phy_gmii_rxd, phy_gmii_rx_dv, phy_gmii_rx_er}),
    .output_clk(mac_gmii_rx_clk),
    .output_q({mac_gmii_rxd, mac_gmii_rx_dv, mac_gmii_rx_er})
);

taxi_ssio_sdr_out #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .WIDTH(10)
)
tx_ssio_sdr_inst (
    .clk(mac_gmii_tx_clk),
    .input_d({mac_gmii_txd, mac_gmii_tx_en, mac_gmii_tx_er}),
    .output_clk(phy_gmii_tx_clk),
    .output_q({phy_gmii_txd, phy_gmii_tx_en, phy_gmii_tx_er})
);

if (!SIM && VENDOR == "XILINX") begin
    // Xilinx/AMD device support

    BUFGMUX
    gmii_bufgmux_inst (
        .I0(gtx_clk),
        .I1(phy_mii_tx_clk),
        .S(mii_select),
        .O(mac_gmii_tx_clk)
    );

end else begin
    // generic/simulation implementation (no vendor primitives)

    assign mac_gmii_tx_clk = mii_select ? phy_mii_tx_clk : gtx_clk;

end

// reset sync
taxi_sync_reset #(
    .N(4)
)
tx_reset_sync_inst (
    .clk(mac_gmii_tx_clk),
    .rst(gtx_rst),
    .out(mac_gmii_tx_rst)
);

taxi_sync_reset #(
    .N(4)
)
rx_reset_sync_inst (
    .clk(mac_gmii_rx_clk),
    .rst(gtx_rst),
    .out(mac_gmii_rx_rst)
);

endmodule

`resetall
