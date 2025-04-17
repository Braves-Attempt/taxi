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
 * Transceiver and MAC/PHY wrapper for UltraScale/UltraScale+
 */
module taxi_eth_mac_25g_us_ch #
(
    parameter logic SIM = 1'b0,
    parameter string VENDOR = "XILINX",
    parameter string FAMILY = "virtexuplus",

    parameter logic HAS_COMMON = 1'b1,

    // GT type
    parameter string GT_TYPE = "GTY",

    // GT parameters
    parameter logic GT_TX_POLARITY = 1'b0,
    parameter logic GT_RX_POLARITY = 1'b0,

    // MAC/PHY parameters
    parameter logic PADDING_EN = 1'b1,
    parameter logic DIC_EN = 1'b1,
    parameter MIN_FRAME_LEN = 64,
    parameter logic PTP_TS_EN = 1'b0,
    parameter logic PTP_TS_FMT_TOD = 1'b1,
    parameter PTP_TS_W = PTP_TS_FMT_TOD ? 96 : 64,
    parameter logic PRBS31_EN = 1'b0,
    parameter TX_SERDES_PIPELINE = 1,
    parameter RX_SERDES_PIPELINE = 1,
    parameter BITSLIP_HIGH_CYCLES = 0,
    parameter BITSLIP_LOW_CYCLES = 7,
    parameter COUNT_125US = 125000/6.4,
    parameter logic STAT_EN = 1'b0,
    parameter STAT_TX_LEVEL = 1,
    parameter STAT_RX_LEVEL = 1,
    parameter STAT_ID_BASE = 0,
    parameter STAT_UPDATE_PERIOD = 1024,
    parameter logic STAT_STR_EN = 1'b0,
    parameter logic [8*8-1:0] STAT_PREFIX_STR = "MAC"
)
(
    input  wire logic                 xcvr_ctrl_clk,
    input  wire logic                 xcvr_ctrl_rst,

    /*
     * Common
     */
    output wire logic                 xcvr_gtpowergood_out,

    /*
     * PLL out
     */
    input  wire logic                 xcvr_gtrefclk00_in,
    output wire logic                 xcvr_qpll0lock_out,
    output wire logic                 xcvr_qpll0clk_out,
    output wire logic                 xcvr_qpll0refclk_out,

    /*
     * PLL in
     */
    input  wire logic                 xcvr_qpll0lock_in,
    output wire logic                 xcvr_qpll0reset_out,
    input  wire logic                 xcvr_qpll0clk_in,
    input  wire logic                 xcvr_qpll0refclk_in,

    /*
     * Serial data
     */
    output wire logic                 xcvr_txp,
    output wire logic                 xcvr_txn,
    input  wire logic                 xcvr_rxp,
    input  wire logic                 xcvr_rxn,

    /*
     * MAC clocks
     */
    output wire logic                 rx_clk,
    input  wire logic                 rx_rst_in,
    output wire logic                 rx_rst_out,
    output wire logic                 tx_clk,
    input  wire logic                 tx_rst_in,
    output wire logic                 tx_rst_out,
    input  wire logic                 ptp_sample_clk,

    /*
     * Transmit interface (AXI stream)
     */
    taxi_axis_if.snk                  s_axis_tx,
    taxi_axis_if.src                  m_axis_tx_cpl,

    /*
     * Receive interface (AXI stream)
     */
    taxi_axis_if.src                  m_axis_rx,

    /*
     * PTP clock
     */
    input  wire logic [PTP_TS_W-1:0]  tx_ptp_ts = '0,
    input  wire logic                 tx_ptp_ts_step = 1'b0,
    input  wire logic [PTP_TS_W-1:0]  rx_ptp_ts = '0,
    input  wire logic                 rx_ptp_ts_step = 1'b0,

    /*
     * Link-level Flow Control (LFC) (IEEE 802.3 annex 31B PAUSE)
     */
    input  wire logic                 tx_lfc_req = 1'b0,
    input  wire logic                 tx_lfc_resend = 1'b0,
    input  wire logic                 rx_lfc_en = 1'b0,
    output wire logic                 rx_lfc_req,
    input  wire logic                 rx_lfc_ack = 1'b0,

    /*
     * Priority Flow Control (PFC) (IEEE 802.3 annex 31D PFC)
     */
    input  wire logic [7:0]           tx_pfc_req = '0,
    input  wire logic                 tx_pfc_resend = 1'b0,
    input  wire logic [7:0]           rx_pfc_en = '0,
    output wire logic [7:0]           rx_pfc_req,
    input  wire logic [7:0]           rx_pfc_ack = '0,

    /*
     * Pause interface
     */
    input  wire logic                 tx_lfc_pause_en = 1'b0,
    input  wire logic                 tx_pause_req = 1'b0,
    output wire logic                 tx_pause_ack,

    /*
     * Statistics
     */
    input  wire logic                 stat_clk,
    input  wire logic                 stat_rst,
    taxi_axis_if.src                  m_axis_stat,

    /*
     * Status
     */
    output wire logic [1:0]           tx_start_packet,
    output wire logic [3:0]           stat_tx_byte,
    output wire logic [15:0]          stat_tx_pkt_len,
    output wire logic                 stat_tx_pkt_ucast,
    output wire logic                 stat_tx_pkt_mcast,
    output wire logic                 stat_tx_pkt_bcast,
    output wire logic                 stat_tx_pkt_vlan,
    output wire logic                 stat_tx_pkt_good,
    output wire logic                 stat_tx_pkt_bad,
    output wire logic                 stat_tx_err_oversize,
    output wire logic                 stat_tx_err_user,
    output wire logic                 stat_tx_err_underflow,
    output wire logic [1:0]           rx_start_packet,
    output wire logic [6:0]           rx_error_count,
    output wire logic                 rx_block_lock,
    output wire logic                 rx_high_ber,
    output wire logic                 rx_status,
    output wire logic [3:0]           stat_rx_byte,
    output wire logic [15:0]          stat_rx_pkt_len,
    output wire logic                 stat_rx_pkt_fragment,
    output wire logic                 stat_rx_pkt_jabber,
    output wire logic                 stat_rx_pkt_ucast,
    output wire logic                 stat_rx_pkt_mcast,
    output wire logic                 stat_rx_pkt_bcast,
    output wire logic                 stat_rx_pkt_vlan,
    output wire logic                 stat_rx_pkt_good,
    output wire logic                 stat_rx_pkt_bad,
    output wire logic                 stat_rx_err_oversize,
    output wire logic                 stat_rx_err_bad_fcs,
    output wire logic                 stat_rx_err_bad_block,
    output wire logic                 stat_rx_err_framing,
    output wire logic                 stat_rx_err_preamble,
    input  wire logic                 stat_rx_fifo_drop = 1'b0,
    output wire logic                 stat_tx_mcf,
    output wire logic                 stat_rx_mcf,
    output wire logic                 stat_tx_lfc_pkt,
    output wire logic                 stat_tx_lfc_xon,
    output wire logic                 stat_tx_lfc_xoff,
    output wire logic                 stat_tx_lfc_paused,
    output wire logic                 stat_tx_pfc_pkt,
    output wire logic [7:0]           stat_tx_pfc_xon,
    output wire logic [7:0]           stat_tx_pfc_xoff,
    output wire logic [7:0]           stat_tx_pfc_paused,
    output wire logic                 stat_rx_lfc_pkt,
    output wire logic                 stat_rx_lfc_xon,
    output wire logic                 stat_rx_lfc_xoff,
    output wire logic                 stat_rx_lfc_paused,
    output wire logic                 stat_rx_pfc_pkt,
    output wire logic [7:0]           stat_rx_pfc_xon,
    output wire logic [7:0]           stat_rx_pfc_xoff,
    output wire logic [7:0]           stat_rx_pfc_paused,

    /*
     * Configuration
     */
    input  wire logic [15:0]          cfg_tx_max_pkt_len = 16'd1518,
    input  wire logic [7:0]           cfg_tx_ifg = 8'd12,
    input  wire logic                 cfg_tx_enable = 1'b1,
    input  wire logic [15:0]          cfg_rx_max_pkt_len = 16'd1518,
    input  wire logic                 cfg_rx_enable = 1'b1,
    input  wire logic                 cfg_tx_prbs31_enable = 1'b0,
    input  wire logic                 cfg_rx_prbs31_enable = 1'b0,
    input  wire logic [47:0]          cfg_mcf_rx_eth_dst_mcast = 48'h01_80_C2_00_00_01,
    input  wire logic                 cfg_mcf_rx_check_eth_dst_mcast = 1'b1,
    input  wire logic [47:0]          cfg_mcf_rx_eth_dst_ucast = 48'd0,
    input  wire logic                 cfg_mcf_rx_check_eth_dst_ucast = 1'b0,
    input  wire logic [47:0]          cfg_mcf_rx_eth_src = 48'd0,
    input  wire logic                 cfg_mcf_rx_check_eth_src = 1'b0,
    input  wire logic [15:0]          cfg_mcf_rx_eth_type = 16'h8808,
    input  wire logic [15:0]          cfg_mcf_rx_opcode_lfc = 16'h0001,
    input  wire logic                 cfg_mcf_rx_check_opcode_lfc = 1'b1,
    input  wire logic [15:0]          cfg_mcf_rx_opcode_pfc = 16'h0101,
    input  wire logic                 cfg_mcf_rx_check_opcode_pfc = 1'b1,
    input  wire logic                 cfg_mcf_rx_forward = 1'b0,
    input  wire logic                 cfg_mcf_rx_enable = 1'b0,
    input  wire logic [47:0]          cfg_tx_lfc_eth_dst = 48'h01_80_C2_00_00_01,
    input  wire logic [47:0]          cfg_tx_lfc_eth_src = 48'h80_23_31_43_54_4C,
    input  wire logic [15:0]          cfg_tx_lfc_eth_type = 16'h8808,
    input  wire logic [15:0]          cfg_tx_lfc_opcode = 16'h0001,
    input  wire logic                 cfg_tx_lfc_en = 1'b0,
    input  wire logic [15:0]          cfg_tx_lfc_quanta = 16'hffff,
    input  wire logic [15:0]          cfg_tx_lfc_refresh = 16'h7fff,
    input  wire logic [47:0]          cfg_tx_pfc_eth_dst = 48'h01_80_C2_00_00_01,
    input  wire logic [47:0]          cfg_tx_pfc_eth_src = 48'h80_23_31_43_54_4C,
    input  wire logic [15:0]          cfg_tx_pfc_eth_type = 16'h8808,
    input  wire logic [15:0]          cfg_tx_pfc_opcode = 16'h0101,
    input  wire logic                 cfg_tx_pfc_en = 1'b0,
    input  wire logic [15:0]          cfg_tx_pfc_quanta[8] = '{8{16'hffff}},
    input  wire logic [15:0]          cfg_tx_pfc_refresh[8] = '{8{16'h7fff}},
    input  wire logic [15:0]          cfg_rx_lfc_opcode = 16'h0001,
    input  wire logic                 cfg_rx_lfc_en = 1'b0,
    input  wire logic [15:0]          cfg_rx_pfc_opcode = 16'h0101,
    input  wire logic                 cfg_rx_pfc_en = 1'b0
);

localparam GT_USP = FAMILY == "kintexuplus" || FAMILY == "virtexuplus" || FAMILY == "virtexuplusHBM"
    || FAMILY == "virtexuplus58G" || FAMILY == "zynquplus" || FAMILY == "zynquplusRFSOC";

localparam DATA_W = 64;
localparam HDR_W = 2;

wire rx_reset_req;

wire gt_reset_tx_datapath = tx_rst_in;
wire gt_reset_rx_datapath = rx_rst_in || rx_reset_req;

wire gt_reset_tx_done;
wire gt_reset_rx_done;

wire [5:0] gt_txheader;
wire [63:0] gt_txdata;
wire gt_rxgearboxslip;
wire [5:0] gt_rxheader;
wire [1:0] gt_rxheadervalid;
wire [63:0] gt_rxdata;
wire [1:0] gt_rxdatavalid;

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

    taxi_eth_mac_25g_us_gty_full
    taxi_eth_mac_25g_us_gty_full_inst (
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

    taxi_eth_mac_25g_us_gth_full
    taxi_eth_mac_25g_us_gth_full_inst (
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

    taxi_eth_mac_25g_us_gty_full
    taxi_eth_mac_25g_us_gty_full_inst (
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

    taxi_eth_mac_25g_us_gth_full
    taxi_eth_mac_25g_us_gth_full_inst (
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

    taxi_eth_mac_25g_us_gty_channel
    taxi_eth_mac_25g_us_gty_channel_inst (
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

    taxi_eth_mac_25g_us_gth_channel
    taxi_eth_mac_25g_us_gth_channel_inst (
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

wire [DATA_W-1:0] serdes_tx_data;
wire [HDR_W-1:0]  serdes_tx_hdr;
wire [DATA_W-1:0] serdes_rx_data;
wire [HDR_W-1:0]  serdes_rx_hdr;
wire serdes_rx_bitslip;

assign gt_txdata = serdes_tx_data;
assign gt_txheader = {4'd0, serdes_tx_hdr};
assign gt_rxgearboxslip = serdes_rx_bitslip;

if (!SIM) begin
    assign serdes_rx_data = gt_rxdata;
    assign serdes_rx_hdr = gt_rxheader[1:0];
end

taxi_eth_mac_phy_10g #(
    .DATA_W(DATA_W),
    .HDR_W(HDR_W),
    .PADDING_EN(PADDING_EN),
    .DIC_EN(DIC_EN),
    .MIN_FRAME_LEN(MIN_FRAME_LEN),
    .PTP_TS_EN(PTP_TS_EN),
    .PTP_TS_FMT_TOD(PTP_TS_FMT_TOD),
    .PTP_TS_W(PTP_TS_W),
    .BIT_REVERSE(1'b1),
    .SCRAMBLER_DISABLE(1'b0),
    .PRBS31_EN(PRBS31_EN),
    .TX_SERDES_PIPELINE(TX_SERDES_PIPELINE),
    .RX_SERDES_PIPELINE(RX_SERDES_PIPELINE),
    .BITSLIP_HIGH_CYCLES(BITSLIP_HIGH_CYCLES),
    .BITSLIP_LOW_CYCLES(BITSLIP_LOW_CYCLES),
    .COUNT_125US(COUNT_125US),
    .STAT_EN(STAT_EN),
    .STAT_TX_LEVEL(STAT_TX_LEVEL),
    .STAT_RX_LEVEL(STAT_RX_LEVEL),
    .STAT_ID_BASE(STAT_ID_BASE),
    .STAT_UPDATE_PERIOD(STAT_UPDATE_PERIOD),
    .STAT_STR_EN(STAT_STR_EN),
    .STAT_PREFIX_STR(STAT_PREFIX_STR)
)
eth_mac_phy_10g_inst (
    .tx_clk(tx_clk),
    .tx_rst(tx_rst_out),
    .rx_clk(rx_clk),
    .rx_rst(rx_rst_out),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(s_axis_tx),
    .m_axis_tx_cpl(m_axis_tx_cpl),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(m_axis_rx),

    /*
     * Serdes interface
     */
    .serdes_tx_data(serdes_tx_data),
    .serdes_tx_hdr(serdes_tx_hdr),
    .serdes_rx_data(serdes_rx_data),
    .serdes_rx_hdr(serdes_rx_hdr),
    .serdes_rx_bitslip(serdes_rx_bitslip),
    .serdes_rx_reset_req(rx_reset_req),

    /*
     * PTP
     */
    .tx_ptp_ts(tx_ptp_ts),
    .rx_ptp_ts(rx_ptp_ts),

    /*
     * Link-level Flow Control (LFC) (IEEE 802.3 annex 31B PAUSE)
     */
    .tx_lfc_req(tx_lfc_req),
    .tx_lfc_resend(tx_lfc_resend),
    .rx_lfc_en(rx_lfc_en),
    .rx_lfc_req(rx_lfc_req),
    .rx_lfc_ack(rx_lfc_ack),

    /*
     * Priority Flow Control (PFC) (IEEE 802.3 annex 31D PFC)
     */
    .tx_pfc_req(tx_pfc_req),
    .tx_pfc_resend(tx_pfc_resend),
    .rx_pfc_en(rx_pfc_en),
    .rx_pfc_req(rx_pfc_req),
    .rx_pfc_ack(rx_pfc_ack),

    /*
     * Pause interface
     */
    .tx_lfc_pause_en(tx_lfc_pause_en),
    .tx_pause_req(tx_pause_req),
    .tx_pause_ack(tx_pause_ack),

    /*
     * Statistics
     */
    .stat_clk(stat_clk),
    .stat_rst(stat_rst),
    .m_axis_stat(m_axis_stat),

    /*
     * Status
     */
    .tx_start_packet(tx_start_packet),
    .stat_tx_byte(stat_tx_byte),
    .stat_tx_pkt_len(stat_tx_pkt_len),
    .stat_tx_pkt_ucast(stat_tx_pkt_ucast),
    .stat_tx_pkt_mcast(stat_tx_pkt_mcast),
    .stat_tx_pkt_bcast(stat_tx_pkt_bcast),
    .stat_tx_pkt_vlan(stat_tx_pkt_vlan),
    .stat_tx_pkt_good(stat_tx_pkt_good),
    .stat_tx_pkt_bad(stat_tx_pkt_bad),
    .stat_tx_err_oversize(stat_tx_err_oversize),
    .stat_tx_err_user(stat_tx_err_user),
    .stat_tx_err_underflow(stat_tx_err_underflow),
    .rx_start_packet(rx_start_packet),
    .rx_error_count(rx_error_count),
    .rx_block_lock(rx_block_lock),
    .rx_high_ber(rx_high_ber),
    .rx_status(rx_status),
    .stat_rx_byte(stat_rx_byte),
    .stat_rx_pkt_len(stat_rx_pkt_len),
    .stat_rx_pkt_fragment(stat_rx_pkt_fragment),
    .stat_rx_pkt_jabber(stat_rx_pkt_jabber),
    .stat_rx_pkt_ucast(stat_rx_pkt_ucast),
    .stat_rx_pkt_mcast(stat_rx_pkt_mcast),
    .stat_rx_pkt_bcast(stat_rx_pkt_bcast),
    .stat_rx_pkt_vlan(stat_rx_pkt_vlan),
    .stat_rx_pkt_good(stat_rx_pkt_good),
    .stat_rx_pkt_bad(stat_rx_pkt_bad),
    .stat_rx_err_oversize(stat_rx_err_oversize),
    .stat_rx_err_bad_fcs(stat_rx_err_bad_fcs),
    .stat_rx_err_bad_block(stat_rx_err_bad_block),
    .stat_rx_err_framing(stat_rx_err_framing),
    .stat_rx_err_preamble(stat_rx_err_preamble),
    .stat_rx_fifo_drop(stat_rx_fifo_drop),
    .stat_tx_mcf(stat_tx_mcf),
    .stat_rx_mcf(stat_rx_mcf),
    .stat_tx_lfc_pkt(stat_tx_lfc_pkt),
    .stat_tx_lfc_xon(stat_tx_lfc_xon),
    .stat_tx_lfc_xoff(stat_tx_lfc_xoff),
    .stat_tx_lfc_paused(stat_tx_lfc_paused),
    .stat_tx_pfc_pkt(stat_tx_pfc_pkt),
    .stat_tx_pfc_xon(stat_tx_pfc_xon),
    .stat_tx_pfc_xoff(stat_tx_pfc_xoff),
    .stat_tx_pfc_paused(stat_tx_pfc_paused),
    .stat_rx_lfc_pkt(stat_rx_lfc_pkt),
    .stat_rx_lfc_xon(stat_rx_lfc_xon),
    .stat_rx_lfc_xoff(stat_rx_lfc_xoff),
    .stat_rx_lfc_paused(stat_rx_lfc_paused),
    .stat_rx_pfc_pkt(stat_rx_pfc_pkt),
    .stat_rx_pfc_xon(stat_rx_pfc_xon),
    .stat_rx_pfc_xoff(stat_rx_pfc_xoff),
    .stat_rx_pfc_paused(stat_rx_pfc_paused),

    /*
     * Configuration
     */
    .cfg_tx_max_pkt_len(cfg_tx_max_pkt_len),
    .cfg_tx_ifg(cfg_tx_ifg),
    .cfg_tx_enable(cfg_tx_enable),
    .cfg_rx_max_pkt_len(cfg_rx_max_pkt_len),
    .cfg_rx_enable(cfg_rx_enable),
    .cfg_tx_prbs31_enable(cfg_tx_prbs31_enable),
    .cfg_rx_prbs31_enable(cfg_rx_prbs31_enable),
    .cfg_mcf_rx_eth_dst_mcast(cfg_mcf_rx_eth_dst_mcast),
    .cfg_mcf_rx_check_eth_dst_mcast(cfg_mcf_rx_check_eth_dst_mcast),
    .cfg_mcf_rx_eth_dst_ucast(cfg_mcf_rx_eth_dst_ucast),
    .cfg_mcf_rx_check_eth_dst_ucast(cfg_mcf_rx_check_eth_dst_ucast),
    .cfg_mcf_rx_eth_src(cfg_mcf_rx_eth_src),
    .cfg_mcf_rx_check_eth_src(cfg_mcf_rx_check_eth_src),
    .cfg_mcf_rx_eth_type(cfg_mcf_rx_eth_type),
    .cfg_mcf_rx_opcode_lfc(cfg_mcf_rx_opcode_lfc),
    .cfg_mcf_rx_check_opcode_lfc(cfg_mcf_rx_check_opcode_lfc),
    .cfg_mcf_rx_opcode_pfc(cfg_mcf_rx_opcode_pfc),
    .cfg_mcf_rx_check_opcode_pfc(cfg_mcf_rx_check_opcode_pfc),
    .cfg_mcf_rx_forward(cfg_mcf_rx_forward),
    .cfg_mcf_rx_enable(cfg_mcf_rx_enable),
    .cfg_tx_lfc_eth_dst(cfg_tx_lfc_eth_dst),
    .cfg_tx_lfc_eth_src(cfg_tx_lfc_eth_src),
    .cfg_tx_lfc_eth_type(cfg_tx_lfc_eth_type),
    .cfg_tx_lfc_opcode(cfg_tx_lfc_opcode),
    .cfg_tx_lfc_en(cfg_tx_lfc_en),
    .cfg_tx_lfc_quanta(cfg_tx_lfc_quanta),
    .cfg_tx_lfc_refresh(cfg_tx_lfc_refresh),
    .cfg_tx_pfc_eth_dst(cfg_tx_pfc_eth_dst),
    .cfg_tx_pfc_eth_src(cfg_tx_pfc_eth_src),
    .cfg_tx_pfc_eth_type(cfg_tx_pfc_eth_type),
    .cfg_tx_pfc_opcode(cfg_tx_pfc_opcode),
    .cfg_tx_pfc_en(cfg_tx_pfc_en),
    .cfg_tx_pfc_quanta(cfg_tx_pfc_quanta),
    .cfg_tx_pfc_refresh(cfg_tx_pfc_refresh),
    .cfg_rx_lfc_opcode(cfg_rx_lfc_opcode),
    .cfg_rx_lfc_en(cfg_rx_lfc_en),
    .cfg_rx_pfc_opcode(cfg_rx_pfc_opcode),
    .cfg_rx_pfc_en(cfg_rx_pfc_en)
);

endmodule

`resetall
