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
 * 10M/100M Ethernet MAC with MII interface testbench
 */
module test_taxi_eth_mac_mii #
(
    /* verilator lint_off WIDTHTRUNC */
    parameter logic SIM = 1'b1,
    parameter string VENDOR = "XILINX",
    parameter string FAMILY = "virtex7",
    parameter logic PADDING_EN = 1'b1,
    parameter MIN_FRAME_LEN = 64,
    parameter logic PTP_TS_EN = 1'b0,
    parameter PTP_TS_W = 96,
    parameter TX_TAG_W = 16,
    parameter logic PFC_EN = 1'b0,
    parameter logic PAUSE_EN = PFC_EN
    /* verilator lint_on WIDTHTRUNC */
)
();

localparam DATA_W = 8;
localparam TX_USER_W = 1;
localparam RX_USER_W = (PTP_TS_EN ? PTP_TS_W : 0) + 1;

logic rst;
logic rx_clk;
logic rx_rst;
logic tx_clk;
logic tx_rst;

taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(TX_USER_W), .ID_EN(1), .ID_W(TX_TAG_W)) s_axis_tx();
taxi_axis_if #(.DATA_W(PTP_TS_W), .KEEP_W(1), .ID_EN(1), .ID_W(TX_TAG_W)) m_axis_tx_cpl();
taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(RX_USER_W)) m_axis_rx();

logic mii_rx_clk;
logic [3:0] mii_rxd;
logic mii_rx_dv;
logic mii_rx_er;
logic mii_tx_clk;
logic [3:0] mii_txd;
logic mii_tx_en;
logic mii_tx_er;

logic [PTP_TS_W-1:0] tx_ptp_ts;
logic [PTP_TS_W-1:0] rx_ptp_ts;

logic tx_lfc_req;
logic tx_lfc_resend;
logic rx_lfc_en;
logic rx_lfc_req;
logic rx_lfc_ack;

logic [7:0] tx_pfc_req;
logic tx_pfc_resend;
logic [7:0] rx_pfc_en;
logic [7:0] rx_pfc_req;
logic [7:0] rx_pfc_ack;

logic tx_lfc_pause_en;
logic tx_pause_req;
logic tx_pause_ack;

logic tx_start_packet;
logic tx_error_underflow;
logic rx_start_packet;
logic rx_error_bad_frame;
logic rx_error_bad_fcs;
logic stat_tx_mcf;
logic stat_rx_mcf;
logic stat_tx_lfc_pkt;
logic stat_tx_lfc_xon;
logic stat_tx_lfc_xoff;
logic stat_tx_lfc_paused;
logic stat_tx_pfc_pkt;
logic [7:0] stat_tx_pfc_xon;
logic [7:0] stat_tx_pfc_xoff;
logic [7:0] stat_tx_pfc_paused;
logic stat_rx_lfc_pkt;
logic stat_rx_lfc_xon;
logic stat_rx_lfc_xoff;
logic stat_rx_lfc_paused;
logic stat_rx_pfc_pkt;
logic [7:0] stat_rx_pfc_xon;
logic [7:0] stat_rx_pfc_xoff;
logic [7:0] stat_rx_pfc_paused;

logic [7:0] cfg_ifg;
logic cfg_tx_enable;
logic cfg_rx_enable;
logic [47:0] cfg_mcf_rx_eth_dst_mcast;
logic cfg_mcf_rx_check_eth_dst_mcast;
logic [47:0] cfg_mcf_rx_eth_dst_ucast;
logic cfg_mcf_rx_check_eth_dst_ucast;
logic [47:0] cfg_mcf_rx_eth_src;
logic cfg_mcf_rx_check_eth_src;
logic [15:0] cfg_mcf_rx_eth_type;
logic [15:0] cfg_mcf_rx_opcode_lfc;
logic cfg_mcf_rx_check_opcode_lfc;
logic [15:0] cfg_mcf_rx_opcode_pfc;
logic cfg_mcf_rx_check_opcode_pfc;
logic cfg_mcf_rx_forward;
logic cfg_mcf_rx_enable;
logic [47:0] cfg_tx_lfc_eth_dst;
logic [47:0] cfg_tx_lfc_eth_src;
logic [15:0] cfg_tx_lfc_eth_type;
logic [15:0] cfg_tx_lfc_opcode;
logic cfg_tx_lfc_en;
logic [15:0] cfg_tx_lfc_quanta;
logic [15:0] cfg_tx_lfc_refresh;
logic [47:0] cfg_tx_pfc_eth_dst;
logic [47:0] cfg_tx_pfc_eth_src;
logic [15:0] cfg_tx_pfc_eth_type;
logic [15:0] cfg_tx_pfc_opcode;
logic cfg_tx_pfc_en;
logic [15:0] cfg_tx_pfc_quanta[8];
logic [15:0] cfg_tx_pfc_refresh[8];
logic [15:0] cfg_rx_lfc_opcode;
logic cfg_rx_lfc_en;
logic [15:0] cfg_rx_pfc_opcode;
logic cfg_rx_pfc_en;

taxi_eth_mac_mii #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .PADDING_EN(PADDING_EN),
    .MIN_FRAME_LEN(MIN_FRAME_LEN),
    .PTP_TS_EN(PTP_TS_EN),
    .PTP_TS_W(PTP_TS_W),
    .PFC_EN(PFC_EN),
    .PAUSE_EN(PAUSE_EN)
)
uut (
    .rst(rst),
    .rx_clk(rx_clk),
    .rx_rst(rx_rst),
    .tx_clk(tx_clk),
    .tx_rst(tx_rst),

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
     * MII interface
     */
    .mii_rx_clk(mii_rx_clk),
    .mii_rxd(mii_rxd),
    .mii_rx_dv(mii_rx_dv),
    .mii_rx_er(mii_rx_er),
    .mii_tx_clk(mii_tx_clk),
    .mii_txd(mii_txd),
    .mii_tx_en(mii_tx_en),
    .mii_tx_er(mii_tx_er),

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
     * Status
     */
    .tx_start_packet(tx_start_packet),
    .tx_error_underflow(tx_error_underflow),
    .rx_start_packet(rx_start_packet),
    .rx_error_bad_frame(rx_error_bad_frame),
    .rx_error_bad_fcs(rx_error_bad_fcs),
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
    .cfg_ifg(cfg_ifg),
    .cfg_tx_enable(cfg_tx_enable),
    .cfg_rx_enable(cfg_rx_enable),
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
