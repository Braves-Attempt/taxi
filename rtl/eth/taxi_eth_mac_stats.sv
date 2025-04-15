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
 * MAC statistics
 */
module taxi_eth_mac_stats #
(
    parameter STAT_TX_LEVEL = 1,
    parameter STAT_RX_LEVEL = 1,
    parameter STAT_ID_BASE = 0,
    parameter STAT_UPDATE_PERIOD = 1024,
    parameter INC_W = 1
)
(
    input  wire logic              rx_clk,
    input  wire logic              rx_rst,
    input  wire logic              tx_clk,
    input  wire logic              tx_rst,

    /*
     * Statistics
     */
    input  wire logic              stat_clk,
    input  wire logic              stat_rst,
    taxi_axis_if.src               m_axis_stat,

    /*
     * Status
     */
    input  wire logic              tx_start_packet,
    input  wire logic [INC_W-1:0]  stat_tx_byte,
    input  wire logic [15:0]       stat_tx_pkt_len,
    input  wire logic              stat_tx_pkt_ucast,
    input  wire logic              stat_tx_pkt_mcast,
    input  wire logic              stat_tx_pkt_bcast,
    input  wire logic              stat_tx_pkt_vlan,
    input  wire logic              stat_tx_pkt_good,
    input  wire logic              stat_tx_pkt_bad,
    input  wire logic              stat_tx_err_oversize,
    input  wire logic              stat_tx_err_user,
    input  wire logic              stat_tx_err_underflow,
    input  wire logic              rx_start_packet,
    input  wire logic [INC_W-1:0]  stat_rx_byte,
    input  wire logic [15:0]       stat_rx_pkt_len,
    input  wire logic              stat_rx_pkt_fragment,
    input  wire logic              stat_rx_pkt_jabber,
    input  wire logic              stat_rx_pkt_ucast,
    input  wire logic              stat_rx_pkt_mcast,
    input  wire logic              stat_rx_pkt_bcast,
    input  wire logic              stat_rx_pkt_vlan,
    input  wire logic              stat_rx_pkt_good,
    input  wire logic              stat_rx_pkt_bad,
    input  wire logic              stat_rx_err_oversize,
    input  wire logic              stat_rx_err_bad_fcs,
    input  wire logic              stat_rx_err_bad_block,
    input  wire logic              stat_rx_err_framing,
    input  wire logic              stat_rx_err_preamble,
    input  wire logic              stat_rx_fifo_drop,
    input  wire logic              stat_tx_mcf,
    input  wire logic              stat_rx_mcf,
    input  wire logic              stat_tx_lfc_pkt,
    input  wire logic              stat_tx_lfc_xon,
    input  wire logic              stat_tx_lfc_xoff,
    input  wire logic              stat_tx_lfc_paused,
    input  wire logic              stat_tx_pfc_pkt,
    input  wire logic [7:0]        stat_tx_pfc_xon,
    input  wire logic [7:0]        stat_tx_pfc_xoff,
    input  wire logic [7:0]        stat_tx_pfc_paused,
    input  wire logic              stat_rx_lfc_pkt,
    input  wire logic              stat_rx_lfc_xon,
    input  wire logic              stat_rx_lfc_xoff,
    input  wire logic              stat_rx_lfc_paused,
    input  wire logic              stat_rx_pfc_pkt,
    input  wire logic [7:0]        stat_rx_pfc_xon,
    input  wire logic [7:0]        stat_rx_pfc_xoff,
    input  wire logic [7:0]        stat_rx_pfc_paused
);

localparam TX_CNT = STAT_TX_LEVEL == 0 ? 8 : (STAT_TX_LEVEL == 1 ? 16: 32);
localparam RX_CNT = STAT_RX_LEVEL == 0 ? 8 : (STAT_RX_LEVEL == 1 ? 16: 32);

taxi_axis_if #(
    .DATA_W(m_axis_stat.DATA_W),
    .KEEP_EN(1),
    .KEEP_W(1),
    .LAST_EN(0),
    .ID_EN(m_axis_stat.ID_EN),
    .ID_W(m_axis_stat.ID_W),
    .USER_EN(1),
    .USER_W(1)
)
axis_stat_tx(), axis_stat_rx(), axis_stat_int[2]();

wire [INC_W-1:0] tx_inc[TX_CNT];

wire hist_tx_pkt_small     = (stat_tx_pkt_len != 0) && stat_tx_pkt_len[15:6] == 0;
wire hist_tx_pkt_64        = stat_tx_pkt_len == 64;
wire hist_tx_pkt_65_127    = stat_tx_pkt_len[15:6] == 1 && stat_tx_pkt_len != 64;
wire hist_tx_pkt_128_255   = stat_tx_pkt_len[15:7] == 1;
wire hist_tx_pkt_256_511   = stat_tx_pkt_len[15:8] == 1;
wire hist_tx_pkt_512_1023  = stat_tx_pkt_len[15:9] == 1;
wire hist_tx_pkt_1024_1518 = stat_tx_pkt_len[15:10] == 1 && stat_tx_pkt_len <= 1518;
wire hist_tx_pkt_large_1   = stat_tx_pkt_len > 1518;
wire hist_tx_pkt_1519_2047 = stat_tx_pkt_len[15:11] == 0 && stat_tx_pkt_len > 1518;
wire hist_tx_pkt_2048_4095 = stat_tx_pkt_len[15:11] == 1;
wire hist_tx_pkt_4096_8192 = stat_tx_pkt_len[15:12] == 1;
wire hist_tx_pkt_8192_9215 = stat_tx_pkt_len[15:13] == 1 && stat_tx_pkt_len <= 9215;
wire hist_tx_pkt_large_2   = stat_tx_pkt_len > 9215;

// TX_BYTES
assign tx_inc[0]  = stat_tx_byte;
// TX_PKTS
assign tx_inc[1]  = INC_W'(tx_start_packet);
// TX_ERR
assign tx_inc[2]  = INC_W'(stat_tx_err_user);
// TX_UNDR
assign tx_inc[3]  = INC_W'(stat_tx_err_underflow);
// TX_OVRSZ
assign tx_inc[4]  = INC_W'(stat_tx_err_oversize);
// TX_CTRL
assign tx_inc[5]  = INC_W'(stat_tx_mcf);
// TX_COL
assign tx_inc[6]  = INC_W'(0);
// reserved
assign tx_inc[7]  = INC_W'(0);

if (STAT_TX_LEVEL > 0) begin
    // TX_PSM
    assign tx_inc[8]  = INC_W'(hist_tx_pkt_small);
    // TX_P64
    assign tx_inc[9]  = INC_W'(hist_tx_pkt_64);
    // TX_P65
    assign tx_inc[10] = INC_W'(hist_tx_pkt_65_127);
    // TX_P128
    assign tx_inc[11] = INC_W'(hist_tx_pkt_128_255);
    // TX_P256
    assign tx_inc[12] = INC_W'(hist_tx_pkt_256_511);
    // TX_P512
    assign tx_inc[13] = INC_W'(hist_tx_pkt_512_1023);
    // TX_P1024
    assign tx_inc[14] = INC_W'(hist_tx_pkt_1024_1518);
    // TX_PLG
    assign tx_inc[15] = INC_W'(STAT_TX_LEVEL > 1 ? hist_tx_pkt_large_2 : hist_tx_pkt_large_1);
end

if (STAT_TX_LEVEL > 1) begin
    // TX_P1519
    assign tx_inc[16] = INC_W'(hist_tx_pkt_1519_2047);
    // TX_P2048
    assign tx_inc[17] = INC_W'(hist_tx_pkt_2048_4095);
    // TX_P4096
    assign tx_inc[18] = INC_W'(hist_tx_pkt_4096_8192);
    // TX_P8192
    assign tx_inc[19] = INC_W'(hist_tx_pkt_8192_9215);
    // TX_UCAST
    assign tx_inc[20] = INC_W'(stat_tx_pkt_ucast);
    // TX_MCAST
    assign tx_inc[21] = INC_W'(stat_tx_pkt_mcast);
    // TX_BCAST
    assign tx_inc[22] = INC_W'(stat_tx_pkt_bcast);
    // TX_VLAN
    assign tx_inc[23] = INC_W'(stat_tx_pkt_vlan);
    // TX_LFC
    assign tx_inc[24] = INC_W'(stat_tx_lfc_pkt);
    // TX_PFC
    assign tx_inc[25] = INC_W'(stat_tx_pfc_pkt);
    // TX_MCOL
    assign tx_inc[26] = INC_W'(0);
    // TX_DEFER
    assign tx_inc[27] = INC_W'(0);
    // TX_LCOL
    assign tx_inc[28] = INC_W'(0);
    // TX_ECOL
    assign tx_inc[29] = INC_W'(0);
    // TX_EDEF
    assign tx_inc[30] = INC_W'(0);
    // reserved
    assign tx_inc[31] = INC_W'(0);
end

taxi_stats_collect #(
    .CNT(TX_CNT),
    .INC_W(INC_W),
    .ID_BASE(STAT_ID_BASE),
    .UPDATE_PERIOD(STAT_UPDATE_PERIOD)
)
tx_stats_inst (
    .clk(tx_clk),
    .rst(tx_rst),

    /*
     * Increment inputs
     */
    .stat_inc(tx_inc),
    .stat_valid('{TX_CNT{1'b1}}),

    /*
     * Statistics increment output
     */
    .m_axis_stat(axis_stat_tx),

    /*
     * Control inputs
     */
    .update(1'b0)
);

taxi_axis_async_fifo #(
    .DEPTH(32),
    .FRAME_FIFO(1'b0),
    .DROP_BAD_FRAME(1'b0),
    .DROP_WHEN_FULL(1'b0)
)
tx_stat_fifo (
    /*
     * AXI4-Stream input (sink)
     */
    .s_clk(tx_clk),
    .s_rst(tx_rst),
    .s_axis(axis_stat_tx),

    /*
     * AXI4-Stream output (source)
     */
    .m_clk(stat_clk),
    .m_rst(stat_rst),
    .m_axis(axis_stat_int[0]),

    /*
     * Pause
     */
    .s_pause_req(1'b0),
    .s_pause_ack(),
    .m_pause_req(1'b0),
    .m_pause_ack(),

    /*
     * Status
     */
    .s_status_depth(),
    .s_status_depth_commit(),
    .s_status_overflow(),
    .s_status_bad_frame(),
    .s_status_good_frame(),
    .m_status_depth(),
    .m_status_depth_commit(),
    .m_status_overflow(),
    .m_status_bad_frame(),
    .m_status_good_frame()
);

wire [INC_W-1:0] rx_inc[RX_CNT];

wire hist_rx_pkt_small     = (stat_rx_pkt_len != 0) && stat_rx_pkt_len[15:6] == 0;
wire hist_rx_pkt_64        = stat_rx_pkt_len == 64;
wire hist_rx_pkt_65_127    = stat_rx_pkt_len[15:6] == 1 && stat_rx_pkt_len != 64;
wire hist_rx_pkt_128_255   = stat_rx_pkt_len[15:7] == 1;
wire hist_rx_pkt_256_511   = stat_rx_pkt_len[15:8] == 1;
wire hist_rx_pkt_512_1023  = stat_rx_pkt_len[15:9] == 1;
wire hist_rx_pkt_1024_1518 = stat_rx_pkt_len[15:10] == 1 && stat_rx_pkt_len <= 1518;
wire hist_rx_pkt_large_1   = stat_rx_pkt_len > 1518;
wire hist_rx_pkt_1519_2047 = stat_rx_pkt_len[15:11] == 0 && stat_rx_pkt_len > 1518;
wire hist_rx_pkt_2048_4095 = stat_rx_pkt_len[15:11] == 1;
wire hist_rx_pkt_4096_8192 = stat_rx_pkt_len[15:12] == 1;
wire hist_rx_pkt_8192_9215 = stat_rx_pkt_len[15:13] == 1 && stat_rx_pkt_len <= 9215;
wire hist_rx_pkt_large_2   = stat_rx_pkt_len > 9215;

// RX_BYTES
assign rx_inc[0]  = stat_rx_byte;
// RX_PKTS
assign rx_inc[1]  = INC_W'(rx_start_packet);
// RX_FCSER
assign rx_inc[2]  = INC_W'(stat_rx_err_bad_fcs);
// RX_FDRP
assign rx_inc[3]  = INC_W'(stat_rx_fifo_drop);
// RX_OVRSZ
assign rx_inc[4]  = INC_W'(stat_rx_err_oversize);
// RX_ERBLK
assign rx_inc[5]  = INC_W'(stat_rx_err_bad_block);
// RX_ERFRM
assign rx_inc[6]  = INC_W'(stat_rx_err_framing);
// reserved
assign rx_inc[7]  = INC_W'(0);

if (STAT_RX_LEVEL > 0) begin
    // RX_PSM
    assign rx_inc[8]  = INC_W'(hist_rx_pkt_small);
    // RX_P64
    assign rx_inc[9]  = INC_W'(hist_rx_pkt_64);
    // RX_P65
    assign rx_inc[10] = INC_W'(hist_rx_pkt_65_127);
    // RX_P128
    assign rx_inc[11] = INC_W'(hist_rx_pkt_128_255);
    // RX_P256
    assign rx_inc[12] = INC_W'(hist_rx_pkt_256_511);
    // RX_P512
    assign rx_inc[13] = INC_W'(hist_rx_pkt_512_1023);
    // RX_P1024
    assign rx_inc[14] = INC_W'(hist_rx_pkt_1024_1518);
    // RX_PLG
    assign rx_inc[15] = INC_W'(STAT_RX_LEVEL > 1 ? hist_rx_pkt_large_2 : hist_rx_pkt_large_1);
end

if (STAT_RX_LEVEL > 1) begin
    // RX_P1519
    assign rx_inc[16] = INC_W'(hist_rx_pkt_1519_2047);
    // RX_P2048
    assign rx_inc[17] = INC_W'(hist_rx_pkt_2048_4095);
    // RX_P4096
    assign rx_inc[18] = INC_W'(hist_rx_pkt_4096_8192);
    // RX_P8192
    assign rx_inc[19] = INC_W'(hist_rx_pkt_8192_9215);
    // RX_UCAST
    assign rx_inc[20] = INC_W'(stat_rx_pkt_ucast);
    // RX_MCAST
    assign rx_inc[21] = INC_W'(stat_rx_pkt_mcast);
    // RX_BCAST
    assign rx_inc[22] = INC_W'(stat_rx_pkt_bcast);
    // RX_VLAN
    assign rx_inc[23] = INC_W'(stat_rx_pkt_vlan);
    // RX_LFC
    assign rx_inc[24] = INC_W'(stat_rx_lfc_pkt);
    // RX_PFC
    assign rx_inc[25] = INC_W'(stat_rx_pfc_pkt);
    // RX_ERPRE
    assign rx_inc[26] = INC_W'(stat_rx_err_preamble);
    // RX_FRG
    assign rx_inc[27] = INC_W'(stat_rx_pkt_fragment);
    // RX_JBR
    assign rx_inc[28] = INC_W'(stat_rx_pkt_jabber);
    // reserved
    assign rx_inc[29] = INC_W'(0);
    // reserved
    assign rx_inc[30] = INC_W'(0);
    // reserved
    assign rx_inc[31] = INC_W'(0);
end

taxi_stats_collect #(
    .CNT(RX_CNT),
    .INC_W(INC_W),
    .ID_BASE(STAT_ID_BASE+TX_CNT),
    .UPDATE_PERIOD(STAT_UPDATE_PERIOD)
)
rx_stats_inst (
    .clk(rx_clk),
    .rst(rx_rst),

    /*
     * Increment inputs
     */
    .stat_inc(rx_inc),
    .stat_valid('{RX_CNT{1'b1}}),

    /*
     * Statistics increment output
     */
    .m_axis_stat(axis_stat_rx),

    /*
     * Control inputs
     */
    .update(1'b0)
);

taxi_axis_async_fifo #(
    .DEPTH(32),
    .FRAME_FIFO(1'b0),
    .DROP_BAD_FRAME(1'b0),
    .DROP_WHEN_FULL(1'b0)
)
rx_stat_fifo (
    /*
     * AXI4-Stream input (sink)
     */
    .s_clk(rx_clk),
    .s_rst(rx_rst),
    .s_axis(axis_stat_rx),

    /*
     * AXI4-Stream output (source)
     */
    .m_clk(stat_clk),
    .m_rst(stat_rst),
    .m_axis(axis_stat_int[1]),

    /*
     * Pause
     */
    .s_pause_req(1'b0),
    .s_pause_ack(),
    .m_pause_req(1'b0),
    .m_pause_ack(),

    /*
     * Status
     */
    .s_status_depth(),
    .s_status_depth_commit(),
    .s_status_overflow(),
    .s_status_bad_frame(),
    .s_status_good_frame(),
    .m_status_depth(),
    .m_status_depth_commit(),
    .m_status_overflow(),
    .m_status_bad_frame(),
    .m_status_good_frame()
);

taxi_axis_arb_mux #(
    .S_COUNT($size(axis_stat_int)),
    .UPDATE_TID(1'b0),
    .ARB_ROUND_ROBIN(1'b1),
    .ARB_LSB_HIGH_PRIO(1'b0)
)
stat_mux_inst (
    .clk(stat_clk),
    .rst(stat_rst),

    /*
     * AXI4-Stream inputs (sink)
     */
    .s_axis(axis_stat_int),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(m_axis_stat)
);

endmodule

`resetall
