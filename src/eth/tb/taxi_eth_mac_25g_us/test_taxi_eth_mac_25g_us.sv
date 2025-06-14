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
 * Transceiver and MAC/PHY quad wrapper for UltraScale/UltraScale+ testbench
 */
module test_taxi_eth_mac_25g_us #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter logic SIM = 1'b1,
    parameter string VENDOR = "XILINX",
    parameter string FAMILY = "virtexuplus",
    parameter CNT = 4,
    parameter logic CFG_LOW_LATENCY = 1'b0,
    parameter string GT_TYPE = "GTY",
    parameter logic QPLL0_PD = 1'b0,
    parameter logic QPLL1_PD = 1'b1,
    parameter logic QPLL0_EXT_CTRL = 1'b0,
    parameter logic QPLL1_EXT_CTRL = 1'b0,
    parameter logic [CNT-1:0] GT_TX_PD = '0,
    parameter logic [CNT-1:0] GT_TX_QPLL_SEL = '0,
    parameter logic [CNT-1:0] GT_TX_POLARITY = '0,
    parameter logic [CNT-1:0] GT_TX_ELECIDLE = '0,
    parameter logic [CNT-1:0] GT_TX_INHIBIT = '0,
    parameter logic [CNT-1:0][4:0] GT_TX_DIFFCTRL = '{CNT{5'd16}},
    parameter logic [CNT-1:0][6:0] GT_TX_MAINCURSOR = '{CNT{7'd64}},
    parameter logic [CNT-1:0][4:0] GT_TX_POSTCURSOR = '{CNT{5'd0}},
    parameter logic [CNT-1:0][4:0] GT_TX_PRECURSOR = '{CNT{5'd0}},
    parameter logic [CNT-1:0] GT_RX_PD = '0,
    parameter logic [CNT-1:0] GT_RX_QPLL_SEL = '0,
    parameter logic [CNT-1:0] GT_RX_LPM_EN = '0,
    parameter logic [CNT-1:0] GT_RX_POLARITY = '0,
    parameter logic COMBINED_MAC_PCS = 1'b1,
    parameter DATA_W = 64,
    parameter logic PADDING_EN = 1'b1,
    parameter logic DIC_EN = 1'b1,
    parameter MIN_FRAME_LEN = 64,
    parameter logic PTP_TS_EN = 1'b0,
    parameter logic PTP_TS_FMT_TOD = 1'b1,
    parameter PTP_TS_W = PTP_TS_FMT_TOD ? 96 : 64,
    parameter TX_TAG_W = 16,
    parameter logic PRBS31_EN = 1'b0,
    parameter TX_SERDES_PIPELINE = 1,
    parameter RX_SERDES_PIPELINE = 1,
    parameter BITSLIP_HIGH_CYCLES = 0,
    parameter BITSLIP_LOW_CYCLES = 7,
    parameter COUNT_125US = 125000/6.4,
    parameter logic PFC_EN = 1'b0,
    parameter logic PAUSE_EN = PFC_EN,
    parameter logic STAT_EN = 1'b0,
    parameter STAT_TX_LEVEL = 1,
    parameter STAT_RX_LEVEL = 1,
    parameter STAT_ID_BASE = 0,
    parameter STAT_UPDATE_PERIOD = 1024,
    parameter logic STAT_STR_EN = 1'b0,
    parameter logic [8*8-1:0] STAT_PREFIX_STR[CNT] = '{CNT{"MAC"}}
    /* verilator lint_on WIDTHTRUNC */
)
();

localparam TX_USER_W = 1;
localparam RX_USER_W = (PTP_TS_EN ? PTP_TS_W : 0) + 1;

logic xcvr_ctrl_clk;
logic xcvr_ctrl_rst;

logic xcvr_gtpowergood_out;
logic xcvr_gtrefclk00_in;
logic xcvr_qpll0pd_in;
logic xcvr_qpll0reset_in;
logic [2:0] xcvr_qpll0pcierate_in;
logic xcvr_qpll0lock_out;
logic xcvr_qpll0clk_out;
logic xcvr_qpll0refclk_out;
logic xcvr_gtrefclk01_in;
logic xcvr_qpll1pd_in;
logic xcvr_qpll1reset_in;
logic [2:0] xcvr_qpll1pcierate_in;
logic xcvr_qpll1lock_out;
logic xcvr_qpll1clk_out;
logic xcvr_qpll1refclk_out;

logic [CNT-1:0] xcvr_txp;
logic [CNT-1:0] xcvr_txn;
logic [CNT-1:0] xcvr_rxp;
logic [CNT-1:0] xcvr_rxn;

logic [CNT-1:0] rx_clk;
logic [CNT-1:0] rx_rst_in;
logic [CNT-1:0] rx_rst_out;
logic [CNT-1:0] tx_clk;
logic [CNT-1:0] tx_rst_in;
logic [CNT-1:0] tx_rst_out;
logic [CNT-1:0] ptp_sample_clk;

taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(TX_USER_W), .ID_EN(1), .ID_W(TX_TAG_W)) s_axis_tx[CNT]();
taxi_axis_if #(.DATA_W(PTP_TS_W), .KEEP_W(1), .ID_EN(1), .ID_W(TX_TAG_W)) m_axis_tx_cpl[CNT]();
taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(RX_USER_W)) m_axis_rx[CNT]();

logic [PTP_TS_W-1:0] tx_ptp_ts[CNT];
logic [PTP_TS_W-1:0] rx_ptp_ts[CNT];

logic [CNT-1:0] tx_lfc_req;
logic [CNT-1:0] tx_lfc_resend;
logic [CNT-1:0] rx_lfc_en;
logic [CNT-1:0] rx_lfc_req;
logic [CNT-1:0] rx_lfc_ack;

logic [7:0] tx_pfc_req[CNT];
logic [CNT-1:0] tx_pfc_resend;
logic [7:0] rx_pfc_en[CNT];
logic [7:0] rx_pfc_req[CNT];
logic [7:0] rx_pfc_ack[CNT];

logic [CNT-1:0] tx_lfc_pause_en;
logic [CNT-1:0] tx_pause_req;
logic [CNT-1:0] tx_pause_ack;

logic stat_clk;
logic stat_rst;
taxi_axis_if #(.DATA_W(24), .KEEP_W(1), .LAST_EN(0), .USER_EN(1), .USER_W(1), .ID_EN(1), .ID_W(8)) m_axis_stat();

logic [1:0] tx_start_packet[CNT];
logic [3:0] stat_tx_byte[CNT];
logic [15:0] stat_tx_pkt_len[CNT];
logic [CNT-1:0] stat_tx_pkt_ucast;
logic [CNT-1:0] stat_tx_pkt_mcast;
logic [CNT-1:0] stat_tx_pkt_bcast;
logic [CNT-1:0] stat_tx_pkt_vlan;
logic [CNT-1:0] stat_tx_pkt_good;
logic [CNT-1:0] stat_tx_pkt_bad;
logic [CNT-1:0] stat_tx_err_oversize;
logic [CNT-1:0] stat_tx_err_user;
logic [CNT-1:0] stat_tx_err_underflow;
logic [1:0] rx_start_packet[CNT];
logic [6:0] rx_error_count[CNT];
logic [CNT-1:0] rx_block_lock;
logic [CNT-1:0] rx_high_ber;
logic [CNT-1:0] rx_status;
logic [3:0] stat_rx_byte[CNT];
logic [15:0] stat_rx_pkt_len[CNT];
logic [CNT-1:0] stat_rx_pkt_fragment;
logic [CNT-1:0] stat_rx_pkt_jabber;
logic [CNT-1:0] stat_rx_pkt_ucast;
logic [CNT-1:0] stat_rx_pkt_mcast;
logic [CNT-1:0] stat_rx_pkt_bcast;
logic [CNT-1:0] stat_rx_pkt_vlan;
logic [CNT-1:0] stat_rx_pkt_good;
logic [CNT-1:0] stat_rx_pkt_bad;
logic [CNT-1:0] stat_rx_err_oversize;
logic [CNT-1:0] stat_rx_err_bad_fcs;
logic [CNT-1:0] stat_rx_err_bad_block;
logic [CNT-1:0] stat_rx_err_framing;
logic [CNT-1:0] stat_rx_err_preamble;
logic [CNT-1:0] stat_rx_fifo_drop;
logic [CNT-1:0] stat_tx_mcf;
logic [CNT-1:0] stat_rx_mcf;
logic [CNT-1:0] stat_tx_lfc_pkt;
logic [CNT-1:0] stat_tx_lfc_xon;
logic [CNT-1:0] stat_tx_lfc_xoff;
logic [CNT-1:0] stat_tx_lfc_paused;
logic [CNT-1:0] stat_tx_pfc_pkt;
logic [7:0] stat_tx_pfc_xon[CNT];
logic [7:0] stat_tx_pfc_xoff[CNT];
logic [7:0] stat_tx_pfc_paused[CNT];
logic [CNT-1:0] stat_rx_lfc_pkt;
logic [CNT-1:0] stat_rx_lfc_xon;
logic [CNT-1:0] stat_rx_lfc_xoff;
logic [CNT-1:0] stat_rx_lfc_paused;
logic [CNT-1:0] stat_rx_pfc_pkt;
logic [7:0] stat_rx_pfc_xon[CNT];
logic [7:0] stat_rx_pfc_xoff[CNT];
logic [7:0] stat_rx_pfc_paused[CNT];

logic [15:0] cfg_tx_max_pkt_len[CNT];
logic [7:0] cfg_tx_ifg[CNT];
logic [CNT-1:0] cfg_tx_enable;
logic [15:0] cfg_rx_max_pkt_len[CNT];
logic [CNT-1:0] cfg_rx_enable;
logic [CNT-1:0] cfg_tx_prbs31_enable;
logic [CNT-1:0] cfg_rx_prbs31_enable;
logic [47:0] cfg_mcf_rx_eth_dst_mcast[CNT];
logic [CNT-1:0] cfg_mcf_rx_check_eth_dst_mcast;
logic [47:0] cfg_mcf_rx_eth_dst_ucast[CNT];
logic [CNT-1:0] cfg_mcf_rx_check_eth_dst_ucast;
logic [47:0] cfg_mcf_rx_eth_src[CNT];
logic [CNT-1:0] cfg_mcf_rx_check_eth_src;
logic [15:0] cfg_mcf_rx_eth_type[CNT];
logic [15:0] cfg_mcf_rx_opcode_lfc[CNT];
logic [CNT-1:0] cfg_mcf_rx_check_opcode_lfc;
logic [15:0] cfg_mcf_rx_opcode_pfc[CNT];
logic [CNT-1:0] cfg_mcf_rx_check_opcode_pfc;
logic [CNT-1:0] cfg_mcf_rx_forward;
logic [CNT-1:0] cfg_mcf_rx_enable;
logic [47:0] cfg_tx_lfc_eth_dst[CNT];
logic [47:0] cfg_tx_lfc_eth_src[CNT];
logic [15:0] cfg_tx_lfc_eth_type[CNT];
logic [15:0] cfg_tx_lfc_opcode[CNT];
logic [CNT-1:0] cfg_tx_lfc_en;
logic [15:0] cfg_tx_lfc_quanta[CNT];
logic [15:0] cfg_tx_lfc_refresh[CNT];
logic [47:0] cfg_tx_pfc_eth_dst[CNT];
logic [47:0] cfg_tx_pfc_eth_src[CNT];
logic [15:0] cfg_tx_pfc_eth_type[CNT];
logic [15:0] cfg_tx_pfc_opcode[CNT];
logic [CNT-1:0] cfg_tx_pfc_en;
logic [15:0] cfg_tx_pfc_quanta[CNT][8];
logic [15:0] cfg_tx_pfc_refresh[CNT][8];
logic [15:0] cfg_rx_lfc_opcode[CNT];
logic [CNT-1:0] cfg_rx_lfc_en;
logic [15:0] cfg_rx_pfc_opcode[CNT];
logic [CNT-1:0] cfg_rx_pfc_en;

taxi_eth_mac_25g_us #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .CNT(CNT),
    .CFG_LOW_LATENCY(CFG_LOW_LATENCY),
    .GT_TYPE(GT_TYPE),
    .QPLL0_PD(QPLL0_PD),
    .QPLL1_PD(QPLL1_PD),
    .QPLL0_EXT_CTRL(QPLL0_EXT_CTRL),
    .QPLL1_EXT_CTRL(QPLL1_EXT_CTRL),
    .GT_TX_PD(GT_TX_PD),
    .GT_TX_QPLL_SEL(GT_TX_QPLL_SEL),
    .GT_TX_POLARITY(GT_TX_POLARITY),
    .GT_TX_ELECIDLE(GT_TX_ELECIDLE),
    .GT_TX_INHIBIT(GT_TX_INHIBIT),
    .GT_TX_DIFFCTRL(GT_TX_DIFFCTRL),
    .GT_TX_MAINCURSOR(GT_TX_MAINCURSOR),
    .GT_TX_POSTCURSOR(GT_TX_POSTCURSOR),
    .GT_TX_PRECURSOR(GT_TX_PRECURSOR),
    .GT_RX_PD(GT_RX_PD),
    .GT_RX_QPLL_SEL(GT_RX_QPLL_SEL),
    .GT_RX_LPM_EN(GT_RX_LPM_EN),
    .GT_RX_POLARITY(GT_RX_POLARITY),
    .COMBINED_MAC_PCS(COMBINED_MAC_PCS),
    .DATA_W(DATA_W),
    .PADDING_EN(PADDING_EN),
    .DIC_EN(DIC_EN),
    .MIN_FRAME_LEN(MIN_FRAME_LEN),
    .PTP_TS_EN(PTP_TS_EN),
    .PTP_TS_FMT_TOD(PTP_TS_FMT_TOD),
    .PTP_TS_W(PTP_TS_W),
    .PRBS31_EN(PRBS31_EN),
    .TX_SERDES_PIPELINE(TX_SERDES_PIPELINE),
    .RX_SERDES_PIPELINE(RX_SERDES_PIPELINE),
    .BITSLIP_HIGH_CYCLES(BITSLIP_HIGH_CYCLES),
    .BITSLIP_LOW_CYCLES(BITSLIP_LOW_CYCLES),
    .COUNT_125US(COUNT_125US),
    .PFC_EN(PFC_EN),
    .PAUSE_EN(PAUSE_EN),
    .STAT_EN(STAT_EN),
    .STAT_TX_LEVEL(STAT_TX_LEVEL),
    .STAT_RX_LEVEL(STAT_RX_LEVEL),
    .STAT_ID_BASE(STAT_ID_BASE),
    .STAT_UPDATE_PERIOD(STAT_UPDATE_PERIOD),
    .STAT_STR_EN(STAT_STR_EN),
    .STAT_PREFIX_STR(STAT_PREFIX_STR)
)
uut (
    .xcvr_ctrl_clk(xcvr_ctrl_clk),
    .xcvr_ctrl_rst(xcvr_ctrl_rst),

    /*
     * Common
     */
    .xcvr_gtpowergood_out(xcvr_gtpowergood_out),
    .xcvr_gtrefclk00_in(xcvr_gtrefclk00_in),
    .xcvr_qpll0pd_in(xcvr_qpll0pd_in),
    .xcvr_qpll0reset_in(xcvr_qpll0reset_in),
    .xcvr_qpll0pcierate_in(xcvr_qpll0pcierate_in),
    .xcvr_qpll0lock_out(xcvr_qpll0lock_out),
    .xcvr_qpll0clk_out(xcvr_qpll0clk_out),
    .xcvr_qpll0refclk_out(xcvr_qpll0refclk_out),
    .xcvr_gtrefclk01_in(xcvr_gtrefclk01_in),
    .xcvr_qpll1pd_in(xcvr_qpll1pd_in),
    .xcvr_qpll1reset_in(xcvr_qpll1reset_in),
    .xcvr_qpll1pcierate_in(xcvr_qpll1pcierate_in),
    .xcvr_qpll1lock_out(xcvr_qpll1lock_out),
    .xcvr_qpll1clk_out(xcvr_qpll1clk_out),
    .xcvr_qpll1refclk_out(xcvr_qpll1refclk_out),

    /*
     * Serial data
     */
    .xcvr_txp(xcvr_txp),
    .xcvr_txn(xcvr_txn),
    .xcvr_rxp(xcvr_rxp),
    .xcvr_rxn(xcvr_rxn),

    /*
     * MAC clocks
     */
    .rx_clk(rx_clk),
    .rx_rst_in(rx_rst_in),
    .rx_rst_out(rx_rst_out),
    .tx_clk(tx_clk),
    .tx_rst_in(tx_rst_in),
    .tx_rst_out(tx_rst_out),
    .ptp_sample_clk(ptp_sample_clk),

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
     * PTP
     */
    .tx_ptp_ts(tx_ptp_ts),
    .tx_ptp_ts_step('0),
    .rx_ptp_ts(rx_ptp_ts),
    .rx_ptp_ts_step('0),

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
