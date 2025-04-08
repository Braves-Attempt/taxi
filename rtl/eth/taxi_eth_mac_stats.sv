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

if (STAT_TX_LEVEL == 0) begin

    taxi_stats_collect #(
        .CNT(8),
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
        .stat_inc('{
            stat_tx_byte,                   // 0:  TX_BYTES
            INC_W'(tx_start_packet),        // 1:  TX_PKTS
            INC_W'(stat_tx_err_user),       // 2:  TX_ERR
            INC_W'(stat_tx_err_underflow),  // 3:  TX_UNDR
            INC_W'(stat_tx_err_oversize),   // 4:  TX_OVRSZ
            INC_W'(stat_tx_mcf),            // 5:  TX_CTRL
            INC_W'(0),                      // 6:  TX_COL
            INC_W'(0)                       // 7:
        }),
        .stat_valid('{8{1'b1}}),

        /*
         * Statistics increment output
         */
        .m_axis_stat(axis_stat_tx),

        /*
         * Control inputs
         */
        .update(1'b0)
    );

end else if (STAT_TX_LEVEL == 1) begin

    taxi_stats_collect #(
        .CNT(16),
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
        .stat_inc('{
            stat_tx_byte,                   // 0:  TX_BYTES
            INC_W'(tx_start_packet),        // 1:  TX_PKTS
            INC_W'(stat_tx_err_user),       // 2:  TX_ERR
            INC_W'(stat_tx_err_underflow),  // 3:  TX_UNDR
            INC_W'(stat_tx_err_oversize),   // 4:  TX_OVRSZ
            INC_W'(stat_tx_mcf),            // 5:  TX_CTRL
            INC_W'(0),                      // 6:  TX_COL
            INC_W'(0),                      // 7:
            INC_W'(hist_tx_pkt_small),      // 8:  TX_PSM
            INC_W'(hist_tx_pkt_64),         // 9:  TX_P64
            INC_W'(hist_tx_pkt_65_127),     // 10: TX_P65
            INC_W'(hist_tx_pkt_128_255),    // 11: TX_P128
            INC_W'(hist_tx_pkt_256_511),    // 12: TX_P256
            INC_W'(hist_tx_pkt_512_1023),   // 13: TX_P512
            INC_W'(hist_tx_pkt_1024_1518),  // 14: TX_P1024
            INC_W'(hist_tx_pkt_large_1)     // 15: TX_PLG
        }),
        .stat_valid('{16{1'b1}}),

        /*
         * Statistics increment output
         */
        .m_axis_stat(axis_stat_tx),

        /*
         * Control inputs
         */
        .update(1'b0)
    );

end else begin

    taxi_stats_collect #(
        .CNT(32),
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
        .stat_inc('{
            stat_tx_byte,                   // 0:  TX_BYTES
            INC_W'(tx_start_packet),        // 1:  TX_PKTS
            INC_W'(stat_tx_err_user),       // 2:  TX_ERR
            INC_W'(stat_tx_err_underflow),  // 3:  TX_UNDR
            INC_W'(stat_tx_err_oversize),   // 4:  TX_OVRSZ
            INC_W'(stat_tx_mcf),            // 5:  TX_CTRL
            INC_W'(0),                      // 6:  TX_COL
            INC_W'(0),                      // 7:
            INC_W'(hist_tx_pkt_small),      // 8:  TX_PSM
            INC_W'(hist_tx_pkt_64),         // 9:  TX_P64
            INC_W'(hist_tx_pkt_65_127),     // 10: TX_P65
            INC_W'(hist_tx_pkt_128_255),    // 11: TX_P128
            INC_W'(hist_tx_pkt_256_511),    // 12: TX_P256
            INC_W'(hist_tx_pkt_512_1023),   // 13: TX_P512
            INC_W'(hist_tx_pkt_1024_1518),  // 14: TX_P1024
            INC_W'(hist_tx_pkt_large_2),    // 15: TX_PLG
            INC_W'(hist_tx_pkt_1519_2047),  // 16: TX_P1519
            INC_W'(hist_tx_pkt_2048_4095),  // 17: TX_P2048
            INC_W'(hist_tx_pkt_4096_8192),  // 18: TX_P4096
            INC_W'(hist_tx_pkt_8192_9215),  // 19: TX_P8192
            INC_W'(stat_tx_pkt_ucast),      // 20: TX_UCAST
            INC_W'(stat_tx_pkt_mcast),      // 21: TX_MCAST
            INC_W'(stat_tx_pkt_bcast),      // 22: TX_BCAST
            INC_W'(stat_tx_pkt_vlan),       // 23: TX_VLAN
            INC_W'(stat_tx_lfc_pkt),        // 24: TX_LFC
            INC_W'(stat_tx_pfc_pkt),        // 25: TX_PFC
            INC_W'(0),                      // 26: TX_MCOL
            INC_W'(0),                      // 27: TX_DEFER
            INC_W'(0),                      // 28: TX_LCOL
            INC_W'(0),                      // 29: TX_ECOL
            INC_W'(0),                      // 30: TX_EDEF
            INC_W'(0)                       // 31:
        }),
        .stat_valid('{32{1'b1}}),

        /*
         * Statistics increment output
         */
        .m_axis_stat(axis_stat_tx),

        /*
         * Control inputs
         */
        .update(1'b0)
    );

end

if (STAT_RX_LEVEL == 0) begin

    taxi_stats_collect #(
        .CNT(8),
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
        .stat_inc('{
            stat_rx_byte,                   // 0:  RX_BYTES
            INC_W'(rx_start_packet),        // 1:  RX_PKTS
            INC_W'(stat_rx_err_bad_fcs),    // 2:  RX_FCSER
            INC_W'(stat_rx_fifo_drop),      // 3:  RX_FDRP
            INC_W'(stat_rx_err_oversize),   // 4:  RX_OVRSZ
            INC_W'(stat_rx_err_bad_block),  // 5:  RX_ERBLK
            INC_W'(stat_rx_err_framing),    // 6:  RX_ERFRM
            INC_W'(0)                       // 7:
        }),
        .stat_valid('{8{1'b1}}),

        /*
         * Statistics increment output
         */
        .m_axis_stat(axis_stat_rx),

        /*
         * Control inputs
         */
        .update(1'b0)
    );

end else if (STAT_RX_LEVEL == 1) begin

    taxi_stats_collect #(
        .CNT(16),
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
        .stat_inc('{
            stat_rx_byte,                   // 0:  RX_BYTES
            INC_W'(rx_start_packet),        // 1:  RX_PKTS
            INC_W'(stat_rx_err_bad_fcs),    // 2:  RX_FCSER
            INC_W'(stat_rx_fifo_drop),      // 3:  RX_FDRP
            INC_W'(stat_rx_err_oversize),   // 4:  RX_OVRSZ
            INC_W'(stat_rx_err_bad_block),  // 5:  RX_ERBLK
            INC_W'(stat_rx_err_framing),    // 6:  RX_ERFRM
            INC_W'(0),                      // 7:
            INC_W'(hist_rx_pkt_small),      // 8:  RX_PSM
            INC_W'(hist_rx_pkt_64),         // 9:  RX_P64
            INC_W'(hist_rx_pkt_65_127),     // 10: RX_P65
            INC_W'(hist_rx_pkt_128_255),    // 11: RX_P128
            INC_W'(hist_rx_pkt_256_511),    // 12: RX_P256
            INC_W'(hist_rx_pkt_512_1023),   // 13: RX_P512
            INC_W'(hist_rx_pkt_1024_1518),  // 14: RX_P1024
            INC_W'(hist_rx_pkt_large_1)     // 15: RX_PLG
        }),
        .stat_valid('{16{1'b1}}),

        /*
         * Statistics increment output
         */
        .m_axis_stat(axis_stat_rx),

        /*
         * Control inputs
         */
        .update(1'b0)
    );

end else begin

    taxi_stats_collect #(
        .CNT(32),
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
        .stat_inc('{
            stat_rx_byte,                   // 0:  RX_BYTES
            INC_W'(rx_start_packet),        // 1:  RX_PKTS
            INC_W'(stat_rx_err_bad_fcs),    // 2:  RX_FCSER
            INC_W'(stat_rx_fifo_drop),      // 3:  RX_FDRP
            INC_W'(stat_rx_err_oversize),   // 4:  RX_OVRSZ
            INC_W'(stat_rx_err_bad_block),  // 5:  RX_ERBLK
            INC_W'(stat_rx_err_framing),    // 6:  RX_ERFRM
            INC_W'(0),                      // 7:
            INC_W'(hist_rx_pkt_small),      // 8:  RX_PSM
            INC_W'(hist_rx_pkt_64),         // 9:  RX_P64
            INC_W'(hist_rx_pkt_65_127),     // 10: RX_P65
            INC_W'(hist_rx_pkt_128_255),    // 11: RX_P128
            INC_W'(hist_rx_pkt_256_511),    // 12: RX_P256
            INC_W'(hist_rx_pkt_512_1023),   // 13: RX_P512
            INC_W'(hist_rx_pkt_1024_1518),  // 14: RX_P1024
            INC_W'(hist_rx_pkt_large_2),    // 15: RX_PLG
            INC_W'(hist_rx_pkt_1519_2047),  // 16: RX_P1519
            INC_W'(hist_rx_pkt_2048_4095),  // 17: RX_P2048
            INC_W'(hist_rx_pkt_4096_8192),  // 18: RX_P4096
            INC_W'(hist_rx_pkt_8192_9215),  // 19: RX_P8192
            INC_W'(stat_rx_pkt_ucast),      // 20: RX_UCAST
            INC_W'(stat_rx_pkt_mcast),      // 21: RX_MCAST
            INC_W'(stat_rx_pkt_bcast),      // 22: RX_BCAST
            INC_W'(stat_rx_pkt_vlan),       // 23: RX_VLAN
            INC_W'(stat_rx_lfc_pkt),        // 24: RX_LFC
            INC_W'(stat_rx_pfc_pkt),        // 25: RX_PFC
            INC_W'(stat_rx_err_preamble),   // 26: RX_ERPRE
            INC_W'(stat_rx_pkt_fragment),   // 27: RX_FRG
            INC_W'(stat_rx_pkt_jabber),     // 28: RX_JBR
            INC_W'(0),                      // 29:
            INC_W'(0),                      // 30:
            INC_W'(0)                       // 31:
        }),
        .stat_valid('{32{1'b1}}),

        /*
         * Statistics increment output
         */
        .m_axis_stat(axis_stat_rx),

        /*
         * Control inputs
         */
        .update(1'b0)
    );

end

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
    .S_COUNT(2),
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
