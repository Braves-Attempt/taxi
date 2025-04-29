// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Transceiver wrapper for UltraScale/UltraScale+
 */
module taxi_eth_phy_25g_us_gt #
(
    parameter logic SIM = 1'b0,
    parameter string VENDOR = "XILINX",
    parameter string FAMILY = "virtexuplus",

    parameter logic HAS_COMMON = 1'b1,

    // GT type
    parameter string GT_TYPE = "GTY",

    // GT parameters
    parameter logic GT_TX_POLARITY = 1'b0,
    parameter logic GT_RX_POLARITY = 1'b0
)
(
    input  wire logic               xcvr_ctrl_clk,
    input  wire logic               xcvr_ctrl_rst,

    /*
     * Common
     */
    output wire logic               xcvr_gtpowergood_out,

    /*
     * PLL out
     */
    input  wire logic               xcvr_gtrefclk00_in,
    output wire logic               xcvr_qpll0lock_out,
    output wire logic               xcvr_qpll0clk_out,
    output wire logic               xcvr_qpll0refclk_out,

    /*
     * PLL in
     */
    input  wire logic               xcvr_qpll0lock_in,
    output wire logic               xcvr_qpll0reset_out,
    input  wire logic               xcvr_qpll0clk_in,
    input  wire logic               xcvr_qpll0refclk_in,

    /*
     * Serial data
     */
    output wire logic               xcvr_txp,
    output wire logic               xcvr_txn,
    input  wire logic               xcvr_rxp,
    input  wire logic               xcvr_rxn,

    /*
     * GT user clocks
     */
    output wire logic               rx_clk,
    input  wire logic               rx_rst_in,
    output wire logic               rx_rst_out,
    output wire logic               tx_clk,
    input  wire logic               tx_rst_in,
    output wire logic               tx_rst_out,

    /*
     * Serdes interface
     */
    input  wire logic [5:0]         gt_txheader,
    input  wire logic [63:0]        gt_txdata,
    input  wire logic               gt_rxgearboxslip,
    output wire logic [5:0]         gt_rxheader,
    output wire logic [1:0]         gt_rxheadervalid,
    output wire logic [63:0]        gt_rxdata,
    output wire logic [1:0]         gt_rxdatavalid
);

localparam GT_USP = FAMILY == "kintexuplus" || FAMILY == "virtexuplus" || FAMILY == "virtexuplusHBM"
    || FAMILY == "virtexuplus58G" || FAMILY == "zynquplus" || FAMILY == "zynquplusRFSOC";

wire gt_reset_tx_datapath = tx_rst_in;
wire gt_reset_rx_datapath = rx_rst_in;

wire gt_reset_tx_done;
wire gt_reset_rx_done;

taxi_sync_reset #(
    .N(4)
)
tx_reset_sync_inst (
    .clk(tx_clk),
    .rst(!gt_reset_tx_done || tx_rst_in),
    .out(tx_rst_out)
);

taxi_sync_reset #(
    .N(4)
)
rx_reset_sync_inst (
    .clk(rx_clk),
    .rst(!gt_reset_rx_done || rx_rst_in),
    .out(rx_rst_out)
);

if (SIM) begin : xcvr
    // simulation (no GT core)

    assign xcvr_gtpowergood_out = 1'b1;

    assign xcvr_qpll0lock_out = 1'b1;
    assign xcvr_qpll0clk_out = 1'b0;
    assign xcvr_qpll0refclk_out = 1'b0;

    assign gt_reset_tx_done = !xcvr_ctrl_rst;
    assign gt_reset_rx_done = !xcvr_ctrl_rst;

end else if (HAS_COMMON && GT_TYPE == "GTY" && GT_USP) begin : xcvr
    // UltraScale+ GTY (with common)

    taxi_eth_phy_25g_us_gty_full
    taxi_eth_phy_25g_us_gty_full_inst (
        // Common
        .gtwiz_reset_clk_freerun_in(xcvr_ctrl_clk),
        .gtwiz_reset_all_in(xcvr_ctrl_rst),
        .gtpowergood_out(xcvr_gtpowergood_out),

        // PLL
        .gtrefclk00_in(xcvr_gtrefclk00_in),
        .qpll0lock_out(xcvr_qpll0lock_out),
        .qpll0outclk_out(xcvr_qpll0clk_out),
        .qpll0outrefclk_out(xcvr_qpll0refclk_out),

        // Serial data
        .gtytxp_out(xcvr_txp),
        .gtytxn_out(xcvr_txn),
        .gtyrxp_in(xcvr_rxp),
        .gtyrxn_in(xcvr_rxn),

        // Transmit
        .gtwiz_userclk_tx_reset_in(1'b0),
        .gtwiz_userclk_tx_srcclk_out(),
        .gtwiz_userclk_tx_usrclk_out(),
        .gtwiz_userclk_tx_usrclk2_out(tx_clk),
        .gtwiz_userclk_tx_active_out(),
        .gtwiz_reset_tx_pll_and_datapath_in(1'b0),
        .gtwiz_reset_tx_datapath_in(gt_reset_tx_datapath),
        .gtwiz_reset_tx_done_out(gt_reset_tx_done),
        .txpmaresetdone_out(),
        .txprgdivresetdone_out(),

        .txpolarity_in(GT_TX_POLARITY),

        .gtwiz_userdata_tx_in(gt_txdata),
        .txheader_in(gt_txheader),
        .txsequence_in(7'b0),

        // Receive
        .gtwiz_userclk_rx_reset_in(1'b0),
        .gtwiz_userclk_rx_srcclk_out(),
        .gtwiz_userclk_rx_usrclk_out(),
        .gtwiz_userclk_rx_usrclk2_out(rx_clk),
        .gtwiz_userclk_rx_active_out(),
        .gtwiz_reset_rx_pll_and_datapath_in(1'b0),
        .gtwiz_reset_rx_datapath_in(gt_reset_rx_datapath),
        .gtwiz_reset_rx_cdr_stable_out(),
        .gtwiz_reset_rx_done_out(gt_reset_rx_done),
        .rxpmaresetdone_out(),
        .rxprgdivresetdone_out(),

        .rxpolarity_in(GT_RX_POLARITY),

        .rxgearboxslip_in(gt_rxgearboxslip),
        .gtwiz_userdata_rx_out(gt_rxdata),
        .rxdatavalid_out(gt_rxdatavalid),
        .rxheader_out(gt_rxheader),
        .rxheadervalid_out(gt_rxheadervalid),
        .rxstartofseq_out()
    );

    assign xcvr_qpll0reset_out = 1'b0;

end else if (HAS_COMMON && GT_TYPE == "GTH" && GT_USP) begin : xcvr
    // UltraScale+ GTH (with common)

    taxi_eth_phy_25g_us_gth_full
    taxi_eth_phy_25g_us_gth_full_inst (
        // Common
        .gtwiz_reset_clk_freerun_in(xcvr_ctrl_clk),
        .gtwiz_reset_all_in(xcvr_ctrl_rst),
        .gtpowergood_out(xcvr_gtpowergood_out),

        // PLL
        .gtrefclk00_in(xcvr_gtrefclk00_in),
        .qpll0lock_out(xcvr_qpll0lock_out),
        .qpll0outclk_out(xcvr_qpll0clk_out),
        .qpll0outrefclk_out(xcvr_qpll0refclk_out),

        // Serial data
        .gthtxp_out(xcvr_txp),
        .gthtxn_out(xcvr_txn),
        .gthrxp_in(xcvr_rxp),
        .gthrxn_in(xcvr_rxn),

        // Transmit
        .gtwiz_userclk_tx_reset_in(1'b0),
        .gtwiz_userclk_tx_srcclk_out(),
        .gtwiz_userclk_tx_usrclk_out(),
        .gtwiz_userclk_tx_usrclk2_out(tx_clk),
        .gtwiz_userclk_tx_active_out(),
        .gtwiz_reset_tx_pll_and_datapath_in(1'b0),
        .gtwiz_reset_tx_datapath_in(gt_reset_tx_datapath),
        .gtwiz_reset_tx_done_out(gt_reset_tx_done),
        .txpmaresetdone_out(),
        .txprgdivresetdone_out(),

        .txpolarity_in(GT_TX_POLARITY),

        .gtwiz_userdata_tx_in(gt_txdata),
        .txheader_in(gt_txheader),
        .txsequence_in(7'b0),

        // Receive
        .gtwiz_userclk_rx_reset_in(1'b0),
        .gtwiz_userclk_rx_srcclk_out(),
        .gtwiz_userclk_rx_usrclk_out(),
        .gtwiz_userclk_rx_usrclk2_out(rx_clk),
        .gtwiz_userclk_rx_active_out(),
        .gtwiz_reset_rx_pll_and_datapath_in(1'b0),
        .gtwiz_reset_rx_datapath_in(gt_reset_rx_datapath),
        .gtwiz_reset_rx_cdr_stable_out(),
        .gtwiz_reset_rx_done_out(gt_reset_rx_done),
        .rxpmaresetdone_out(),
        .rxprgdivresetdone_out(),

        .rxpolarity_in(GT_RX_POLARITY),

        .rxgearboxslip_in(gt_rxgearboxslip),
        .gtwiz_userdata_rx_out(gt_rxdata),
        .rxdatavalid_out(gt_rxdatavalid),
        .rxheader_out(gt_rxheader),
        .rxheadervalid_out(gt_rxheadervalid),
        .rxstartofseq_out()
    );

    assign xcvr_qpll0reset_out = 1'b0;

end else if (HAS_COMMON && GT_TYPE == "GTY" && !GT_USP) begin : xcvr
    // UltraScale GTY (with common)

    taxi_eth_phy_25g_us_gty_full
    taxi_eth_phy_25g_us_gty_full_inst (
        // Common
        .gtwiz_reset_clk_freerun_in(xcvr_ctrl_clk),
        .gtwiz_reset_all_in(xcvr_ctrl_rst),
        .gtpowergood_out(xcvr_gtpowergood_out),

        // PLL
        .gtrefclk00_in(xcvr_gtrefclk00_in),
        .qpll0lock_out(xcvr_qpll0lock_out),
        .qpll0outclk_out(xcvr_qpll0clk_out),
        .qpll0outrefclk_out(xcvr_qpll0refclk_out),

        // Serial data
        .gtytxp_out(xcvr_txp),
        .gtytxn_out(xcvr_txn),
        .gtyrxp_in(xcvr_rxp),
        .gtyrxn_in(xcvr_rxn),

        // Transmit
        .gtwiz_userclk_tx_reset_in(1'b0),
        .gtwiz_userclk_tx_srcclk_out(),
        .gtwiz_userclk_tx_usrclk_out(),
        .gtwiz_userclk_tx_usrclk2_out(tx_clk),
        .gtwiz_userclk_tx_active_out(),
        .gtwiz_reset_tx_pll_and_datapath_in(1'b0),
        .gtwiz_reset_tx_datapath_in(gt_reset_tx_datapath),
        .gtwiz_reset_tx_done_out(gt_reset_tx_done),
        .txpmaresetdone_out(),
        .txprgdivresetdone_out(),

        .txpolarity_in(GT_TX_POLARITY),

        .gtwiz_userdata_tx_in(gt_txdata),
        .txheader_in(gt_txheader),
        .txsequence_in(7'b0),

        // Receive
        .gtwiz_userclk_rx_reset_in(1'b0),
        .gtwiz_userclk_rx_srcclk_out(),
        .gtwiz_userclk_rx_usrclk_out(),
        .gtwiz_userclk_rx_usrclk2_out(rx_clk),
        .gtwiz_userclk_rx_active_out(),
        .gtwiz_reset_rx_pll_and_datapath_in(1'b0),
        .gtwiz_reset_rx_datapath_in(gt_reset_rx_datapath),
        .gtwiz_reset_rx_cdr_stable_out(),
        .gtwiz_reset_rx_done_out(gt_reset_rx_done),
        .rxpmaresetdone_out(),
        .rxprgdivresetdone_out(),

        .rxpolarity_in(GT_RX_POLARITY),

        .rxgearboxslip_in(gt_rxgearboxslip),
        .gtwiz_userdata_rx_out(gt_rxdata),
        .rxdatavalid_out(gt_rxdatavalid),
        .rxheader_out(gt_rxheader),
        .rxheadervalid_out(gt_rxheadervalid),
        .rxstartofseq_out()
    );

    assign xcvr_qpll0reset_out = 1'b0;

end else if (HAS_COMMON && GT_TYPE == "GTH" && !GT_USP) begin : xcvr
    // UltraScale GTH (with common)

    taxi_eth_phy_25g_us_gth_full
    taxi_eth_phy_25g_us_gth_full_inst (
        // Common
        .gtwiz_reset_clk_freerun_in(xcvr_ctrl_clk),
        .gtwiz_reset_all_in(xcvr_ctrl_rst),
        .gtpowergood_out(xcvr_gtpowergood_out),

        // PLL
        .gtrefclk00_in(xcvr_gtrefclk00_in),
        .qpll0lock_out(xcvr_qpll0lock_out),
        .qpll0outclk_out(xcvr_qpll0clk_out),
        .qpll0outrefclk_out(xcvr_qpll0refclk_out),

        // Serial data
        .gthtxp_out(xcvr_txp),
        .gthtxn_out(xcvr_txn),
        .gthrxp_in(xcvr_rxp),
        .gthrxn_in(xcvr_rxn),

        // Transmit
        .gtwiz_userclk_tx_reset_in(1'b0),
        .gtwiz_userclk_tx_srcclk_out(),
        .gtwiz_userclk_tx_usrclk_out(),
        .gtwiz_userclk_tx_usrclk2_out(tx_clk),
        .gtwiz_userclk_tx_active_out(),
        .gtwiz_reset_tx_pll_and_datapath_in(1'b0),
        .gtwiz_reset_tx_datapath_in(gt_reset_tx_datapath),
        .gtwiz_reset_tx_done_out(gt_reset_tx_done),
        .txpmaresetdone_out(),
        .txprgdivresetdone_out(),

        .txpolarity_in(GT_TX_POLARITY),

        .gtwiz_userdata_tx_in(gt_txdata),
        .txheader_in(gt_txheader),
        .txsequence_in(7'b0),

        // Receive
        .gtwiz_userclk_rx_reset_in(1'b0),
        .gtwiz_userclk_rx_srcclk_out(),
        .gtwiz_userclk_rx_usrclk_out(),
        .gtwiz_userclk_rx_usrclk2_out(rx_clk),
        .gtwiz_userclk_rx_active_out(),
        .gtwiz_reset_rx_pll_and_datapath_in(1'b0),
        .gtwiz_reset_rx_datapath_in(gt_reset_rx_datapath),
        .gtwiz_reset_rx_cdr_stable_out(),
        .gtwiz_reset_rx_done_out(gt_reset_rx_done),
        .rxpmaresetdone_out(),
        .rxprgdivresetdone_out(),

        .rxpolarity_in(GT_RX_POLARITY),

        .rxgearboxslip_in(gt_rxgearboxslip),
        .gtwiz_userdata_rx_out(gt_rxdata),
        .rxdatavalid_out(gt_rxdatavalid),
        .rxheader_out(gt_rxheader),
        .rxheadervalid_out(gt_rxheadervalid),
        .rxstartofseq_out()
    );

    assign xcvr_qpll0reset_out = 1'b0;

end else if (!HAS_COMMON && GT_TYPE == "GTY") begin : xcvr
    // UltraScale/UltraScale+ GTY (channel only)

    taxi_eth_phy_25g_us_gty_channel
    taxi_eth_phy_25g_us_gty_channel_inst (
        // Common
        .gtwiz_reset_clk_freerun_in(xcvr_ctrl_clk),
        .gtwiz_reset_all_in(xcvr_ctrl_rst),
        .gtpowergood_out(xcvr_gtpowergood_out),

        // PLL
        .gtwiz_reset_qpll0lock_in(xcvr_qpll0lock_in),
        .gtwiz_reset_qpll0reset_out(xcvr_qpll0reset_out),
        .qpll0clk_in(xcvr_qpll0clk_in),
        .qpll0refclk_in(xcvr_qpll0refclk_in),
        .qpll1clk_in(1'b0),
        .qpll1refclk_in(1'b0),

        // Serial data
        .gtytxp_out(xcvr_txp),
        .gtytxn_out(xcvr_txn),
        .gtyrxp_in(xcvr_rxp),
        .gtyrxn_in(xcvr_rxn),

        // Transmit
        .gtwiz_userclk_tx_reset_in(1'b0),
        .gtwiz_userclk_tx_srcclk_out(),
        .gtwiz_userclk_tx_usrclk_out(),
        .gtwiz_userclk_tx_usrclk2_out(tx_clk),
        .gtwiz_userclk_tx_active_out(),
        .gtwiz_reset_tx_pll_and_datapath_in(1'b0),
        .gtwiz_reset_tx_datapath_in(gt_reset_tx_datapath),
        .gtwiz_reset_tx_done_out(gt_reset_tx_done),
        .txpmaresetdone_out(),
        .txprgdivresetdone_out(),

        .txpolarity_in(GT_TX_POLARITY),

        .gtwiz_userdata_tx_in(gt_txdata),
        .txheader_in(gt_txheader),
        .txsequence_in(7'b0),

        // Receive
        .gtwiz_userclk_rx_reset_in(1'b0),
        .gtwiz_userclk_rx_srcclk_out(),
        .gtwiz_userclk_rx_usrclk_out(),
        .gtwiz_userclk_rx_usrclk2_out(rx_clk),
        .gtwiz_userclk_rx_active_out(),
        .gtwiz_reset_rx_pll_and_datapath_in(1'b0),
        .gtwiz_reset_rx_datapath_in(gt_reset_rx_datapath),
        .gtwiz_reset_rx_cdr_stable_out(),
        .gtwiz_reset_rx_done_out(gt_reset_rx_done),
        .rxpmaresetdone_out(),
        .rxprgdivresetdone_out(),

        .rxpolarity_in(GT_RX_POLARITY),

        .rxgearboxslip_in(gt_rxgearboxslip),
        .gtwiz_userdata_rx_out(gt_rxdata),
        .rxdatavalid_out(gt_rxdatavalid),
        .rxheader_out(gt_rxheader),
        .rxheadervalid_out(gt_rxheadervalid),
        .rxstartofseq_out()
    );

    assign xcvr_qpll0lock_out = 1'b0;
    assign xcvr_qpll0clk_out = 1'b0;
    assign xcvr_qpll0refclk_out = 1'b0;

end else if (!HAS_COMMON && GT_TYPE == "GTH") begin : xcvr
    // UltraScale/UltraScale+ GTY (channel only)

    taxi_eth_phy_25g_us_gth_channel
    taxi_eth_phy_25g_us_gth_channel_inst (
        // Common
        .gtwiz_reset_clk_freerun_in(xcvr_ctrl_clk),
        .gtwiz_reset_all_in(xcvr_ctrl_rst),
        .gtpowergood_out(xcvr_gtpowergood_out),

        // PLL
        .gtwiz_reset_qpll0lock_in(xcvr_qpll0lock_in),
        .gtwiz_reset_qpll0reset_out(xcvr_qpll0reset_out),
        .qpll0clk_in(xcvr_qpll0clk_in),
        .qpll0refclk_in(xcvr_qpll0refclk_in),
        .qpll1clk_in(1'b0),
        .qpll1refclk_in(1'b0),

        // Serial data
        .gthtxp_out(xcvr_txp),
        .gthtxn_out(xcvr_txn),
        .gthrxp_in(xcvr_rxp),
        .gthrxn_in(xcvr_rxn),

        // Transmit
        .gtwiz_userclk_tx_reset_in(1'b0),
        .gtwiz_userclk_tx_srcclk_out(),
        .gtwiz_userclk_tx_usrclk_out(),
        .gtwiz_userclk_tx_usrclk2_out(tx_clk),
        .gtwiz_userclk_tx_active_out(),
        .gtwiz_reset_tx_pll_and_datapath_in(1'b0),
        .gtwiz_reset_tx_datapath_in(gt_reset_tx_datapath),
        .gtwiz_reset_tx_done_out(gt_reset_tx_done),
        .txpmaresetdone_out(),
        .txprgdivresetdone_out(),

        .txpolarity_in(GT_TX_POLARITY),

        .gtwiz_userdata_tx_in(gt_txdata),
        .txheader_in(gt_txheader),
        .txsequence_in(7'b0),

        // Receive
        .gtwiz_userclk_rx_reset_in(1'b0),
        .gtwiz_userclk_rx_srcclk_out(),
        .gtwiz_userclk_rx_usrclk_out(),
        .gtwiz_userclk_rx_usrclk2_out(rx_clk),
        .gtwiz_userclk_rx_active_out(),
        .gtwiz_reset_rx_pll_and_datapath_in(1'b0),
        .gtwiz_reset_rx_datapath_in(gt_reset_rx_datapath),
        .gtwiz_reset_rx_cdr_stable_out(),
        .gtwiz_reset_rx_done_out(gt_reset_rx_done),
        .rxpmaresetdone_out(),
        .rxprgdivresetdone_out(),

        .rxpolarity_in(GT_RX_POLARITY),

        .rxgearboxslip_in(gt_rxgearboxslip),
        .gtwiz_userdata_rx_out(gt_rxdata),
        .rxdatavalid_out(gt_rxdatavalid),
        .rxheader_out(gt_rxheader),
        .rxheadervalid_out(gt_rxheadervalid),
        .rxstartofseq_out()
    );

    assign xcvr_qpll0lock_out = 1'b0;
    assign xcvr_qpll0clk_out = 1'b0;
    assign xcvr_qpll0refclk_out = 1'b0;

end else begin

    $fatal(0, "Error: invalid configuration (%m)");

end

endmodule

`resetall
