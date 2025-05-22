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
 * FPGA core logic
 */
module fpga_core #
(
    parameter logic SIM = 1'b0,
    parameter string VENDOR = "XILINX",
    parameter string FAMILY = "kintexuplus"
)
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input  wire logic         clk_125mhz,
    input  wire logic         rst_125mhz,

    /*
     * GPIO
     */
    output wire logic [1:0]   qsfp_led_green,
    output wire logic [1:0]   qsfp_led_orange,
    output wire logic         sma_led_green,
    output wire logic         sma_led_red,

    /*
     * Ethernet: SFP+
     */
    output wire logic [3:0]   qsfp_0_tx_p,
    output wire logic [3:0]   qsfp_0_tx_n,
    input  wire logic [3:0]   qsfp_0_rx_p,
    input  wire logic [3:0]   qsfp_0_rx_n,
    input  wire logic         qsfp_mgt_refclk_p,
    input  wire logic         qsfp_mgt_refclk_n,
    output wire logic         qsfp_mgt_refclk_out,
    output wire logic         qsfp_0_modsell,
    output wire logic         qsfp_0_resetl,
    input  wire logic         qsfp_0_modprsl,
    input  wire logic         qsfp_0_intl,
    output wire logic         qsfp_0_lpmode,

    output wire logic [3:0]   qsfp_1_tx_p,
    output wire logic [3:0]   qsfp_1_tx_n,
    input  wire logic [3:0]   qsfp_1_rx_p,
    input  wire logic [3:0]   qsfp_1_rx_n,
    output wire logic         qsfp_1_modsell,
    output wire logic         qsfp_1_resetl,
    input  wire logic         qsfp_1_modprsl,
    input  wire logic         qsfp_1_intl,
    output wire logic         qsfp_1_lpmode
);

// QSFP28
assign qsfp_0_modsell = 1'b0;
assign qsfp_0_resetl = 1'b1;
assign qsfp_0_lpmode = 1'b0;

assign qsfp_1_modsell = 1'b0;
assign qsfp_1_resetl = 1'b1;
assign qsfp_1_lpmode = 1'b0;

wire [7:0] qsfp_tx_clk;
wire [7:0] qsfp_tx_rst;
wire [7:0] qsfp_rx_clk;
wire [7:0] qsfp_rx_rst;

wire [7:0] qsfp_rx_status;

assign qsfp_led_green[0] = qsfp_rx_status[0];
assign qsfp_led_orange[0] = 1'b0;
assign qsfp_led_green[1] = qsfp_rx_status[4];
assign qsfp_led_orange[1] = 1'b0;
assign sma_led_green = 1'b0;
assign sma_led_red = 1'b0;

wire [1:0] qsfp_gtpowergood;

wire qsfp_mgt_refclk;
wire qsfp_mgt_refclk_int;
wire qsfp_mgt_refclk_bufg;

assign qsfp_mgt_refclk_out = qsfp_mgt_refclk_bufg;

wire qsfp_rst;

taxi_axis_if #(.DATA_W(64), .ID_W(8)) axis_qsfp_tx[8]();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_W(8)) axis_qsfp_tx_cpl[8]();
taxi_axis_if #(.DATA_W(64), .ID_W(8)) axis_qsfp_rx[8]();
taxi_axis_if #(.DATA_W(16), .KEEP_W(1), .KEEP_EN(0), .LAST_EN(0), .USER_EN(1), .USER_W(1), .ID_EN(1), .ID_W(8)) axis_qsfp_stat[2]();

if (SIM) begin

    assign qsfp_mgt_refclk = qsfp_mgt_refclk_p;
    assign qsfp_mgt_refclk_int = qsfp_mgt_refclk_p;
    assign qsfp_mgt_refclk_bufg = qsfp_mgt_refclk_int;

end else begin

    IBUFDS_GTE4 ibufds_gte4_qsfp_mgt_refclk_inst (
        .I     (qsfp_mgt_refclk_p),
        .IB    (qsfp_mgt_refclk_n),
        .CEB   (1'b0),
        .O     (qsfp_mgt_refclk),
        .ODIV2 (qsfp_mgt_refclk_int)
    );

    BUFG_GT bufg_gt_qsfp_mgt_refclk_inst (
        .CE      (&qsfp_gtpowergood),
        .CEMASK  (1'b1),
        .CLR     (1'b0),
        .CLRMASK (1'b1),
        .DIV     (3'd0),
        .I       (qsfp_mgt_refclk_int),
        .O       (qsfp_mgt_refclk_bufg)
    );

end

taxi_sync_reset #(
    .N(4)
)
qsfp_sync_reset_inst (
    .clk(qsfp_mgt_refclk_bufg),
    .rst(rst_125mhz),
    .out(qsfp_rst)
);

wire [7:0] qsfp_tx_p;
wire [7:0] qsfp_tx_n;
wire [7:0] qsfp_rx_p = {qsfp_1_rx_p, qsfp_0_rx_p};
wire [7:0] qsfp_rx_n = {qsfp_1_rx_n, qsfp_0_rx_n};

assign qsfp_0_tx_p = qsfp_tx_p[3:0];
assign qsfp_0_tx_n = qsfp_tx_n[3:0];
assign qsfp_1_tx_p = qsfp_tx_p[7:4];
assign qsfp_1_tx_n = qsfp_tx_n[7:4];

for (genvar n = 0; n < 2; n = n + 1) begin : gty_quad

    localparam CNT = 4;

    taxi_eth_mac_25g_us #(
        .SIM(SIM),
        .VENDOR(VENDOR),
        .FAMILY(FAMILY),

        .CNT(4),

        // GT type
        .GT_TYPE("GTY"),

        // GT parameters
        .GT_TX_POLARITY(n == 1 ? 4'b1001 : 4'b0000),
        .GT_RX_POLARITY(4'b0000),

        // MAC/PHY parameters
        .PADDING_EN(1'b1),
        .DIC_EN(1'b1),
        .MIN_FRAME_LEN(64),
        .PTP_TS_EN(1'b0),
        .PTP_TS_FMT_TOD(1'b1),
        .PTP_TS_W(96),
        .PRBS31_EN(1'b0),
        .TX_SERDES_PIPELINE(1),
        .RX_SERDES_PIPELINE(1),
        .COUNT_125US(125000/6.4),
        .STAT_EN(1'b0)
    )
    mac_inst (
        .xcvr_ctrl_clk(clk_125mhz),
        .xcvr_ctrl_rst(qsfp_rst),

        /*
         * Common
         */
        .xcvr_gtpowergood_out(qsfp_gtpowergood[n]),
        .xcvr_gtrefclk00_in(qsfp_mgt_refclk),
        .xcvr_qpll0pd_in(1'b0),
        .xcvr_qpll0reset_in(1'b0),
        .xcvr_qpll0pcierate_in(3'd0),
        .xcvr_qpll0lock_out(),
        .xcvr_qpll0clk_out(),
        .xcvr_qpll0refclk_out(),
        .xcvr_gtrefclk01_in(qsfp_mgt_refclk),
        .xcvr_qpll1pd_in(1'b0),
        .xcvr_qpll1reset_in(1'b0),
        .xcvr_qpll1pcierate_in(3'd0),
        .xcvr_qpll1lock_out(),
        .xcvr_qpll1clk_out(),
        .xcvr_qpll1refclk_out(),

        /*
         * Serial data
         */
        .xcvr_txp(qsfp_tx_p[n*CNT +: CNT]),
        .xcvr_txn(qsfp_tx_n[n*CNT +: CNT]),
        .xcvr_rxp(qsfp_rx_p[n*CNT +: CNT]),
        .xcvr_rxn(qsfp_rx_n[n*CNT +: CNT]),

        /*
         * MAC clocks
         */
        .rx_clk(qsfp_rx_clk[n*CNT +: CNT]),
        .rx_rst_in('0),
        .rx_rst_out(qsfp_rx_rst[n*CNT +: CNT]),
        .tx_clk(qsfp_tx_clk[n*CNT +: CNT]),
        .tx_rst_in('0),
        .tx_rst_out(qsfp_tx_rst[n*CNT +: CNT]),
        .ptp_sample_clk('0),

        /*
         * Transmit interface (AXI stream)
         */
        .s_axis_tx(axis_qsfp_tx[n*CNT +: CNT]),
        .m_axis_tx_cpl(axis_qsfp_tx_cpl[n*CNT +: CNT]),

        /*
         * Receive interface (AXI stream)
         */
        .m_axis_rx(axis_qsfp_rx[n*CNT +: CNT]),

        /*
         * PTP clock
         */
        .tx_ptp_ts('{CNT{'0}}),
        .tx_ptp_ts_step('0),
        .rx_ptp_ts('{CNT{'0}}),
        .rx_ptp_ts_step('0),

        /*
         * Link-level Flow Control (LFC) (IEEE 802.3 annex 31B PAUSE)
         */
        .tx_lfc_req('0),
        .tx_lfc_resend('0),
        .rx_lfc_en('0),
        .rx_lfc_req(),
        .rx_lfc_ack('0),

        /*
         * Priority Flow Control (PFC) (IEEE 802.3 annex 31D PFC)
         */
        .tx_pfc_req('{CNT{'0}}),
        .tx_pfc_resend('0),
        .rx_pfc_en('{CNT{'0}}),
        .rx_pfc_req(),
        .rx_pfc_ack('{CNT{'0}}),

        /*
         * Pause interface
         */
        .tx_lfc_pause_en('0),
        .tx_pause_req('0),
        .tx_pause_ack(),

        /*
         * Statistics
         */
        .stat_clk(clk_125mhz),
        .stat_rst(rst_125mhz),
        .m_axis_stat(axis_qsfp_stat[n]),

        /*
         * Status
         */
        .tx_start_packet(),
        .stat_tx_byte(),
        .stat_tx_pkt_len(),
        .stat_tx_pkt_ucast(),
        .stat_tx_pkt_mcast(),
        .stat_tx_pkt_bcast(),
        .stat_tx_pkt_vlan(),
        .stat_tx_pkt_good(),
        .stat_tx_pkt_bad(),
        .stat_tx_err_oversize(),
        .stat_tx_err_user(),
        .stat_tx_err_underflow(),
        .rx_start_packet(),
        .rx_error_count(),
        .rx_block_lock(),
        .rx_high_ber(),
        .rx_status(qsfp_rx_status[n*CNT +: CNT]),
        .stat_rx_byte(),
        .stat_rx_pkt_len(),
        .stat_rx_pkt_fragment(),
        .stat_rx_pkt_jabber(),
        .stat_rx_pkt_ucast(),
        .stat_rx_pkt_mcast(),
        .stat_rx_pkt_bcast(),
        .stat_rx_pkt_vlan(),
        .stat_rx_pkt_good(),
        .stat_rx_pkt_bad(),
        .stat_rx_err_oversize(),
        .stat_rx_err_bad_fcs(),
        .stat_rx_err_bad_block(),
        .stat_rx_err_framing(),
        .stat_rx_err_preamble(),
        .stat_rx_fifo_drop('0),
        .stat_tx_mcf(),
        .stat_rx_mcf(),
        .stat_tx_lfc_pkt(),
        .stat_tx_lfc_xon(),
        .stat_tx_lfc_xoff(),
        .stat_tx_lfc_paused(),
        .stat_tx_pfc_pkt(),
        .stat_tx_pfc_xon(),
        .stat_tx_pfc_xoff(),
        .stat_tx_pfc_paused(),
        .stat_rx_lfc_pkt(),
        .stat_rx_lfc_xon(),
        .stat_rx_lfc_xoff(),
        .stat_rx_lfc_paused(),
        .stat_rx_pfc_pkt(),
        .stat_rx_pfc_xon(),
        .stat_rx_pfc_xoff(),
        .stat_rx_pfc_paused(),

        /*
         * Configuration
         */
        .cfg_tx_max_pkt_len('{CNT{16'd9218}}),
        .cfg_tx_ifg('{CNT{8'd12}}),
        .cfg_tx_enable('1),
        .cfg_rx_max_pkt_len('{CNT{16'd9218}}),
        .cfg_rx_enable('1),
        .cfg_tx_prbs31_enable('0),
        .cfg_rx_prbs31_enable('0),
        .cfg_mcf_rx_eth_dst_mcast('{CNT{48'h01_80_C2_00_00_01}}),
        .cfg_mcf_rx_check_eth_dst_mcast('1),
        .cfg_mcf_rx_eth_dst_ucast('{CNT{48'd0}}),
        .cfg_mcf_rx_check_eth_dst_ucast('0),
        .cfg_mcf_rx_eth_src('{CNT{48'd0}}),
        .cfg_mcf_rx_check_eth_src('0),
        .cfg_mcf_rx_eth_type('{CNT{16'h8808}}),
        .cfg_mcf_rx_opcode_lfc('{CNT{16'h0001}}),
        .cfg_mcf_rx_check_opcode_lfc('1),
        .cfg_mcf_rx_opcode_pfc('{CNT{16'h0101}}),
        .cfg_mcf_rx_check_opcode_pfc('1),
        .cfg_mcf_rx_forward('0),
        .cfg_mcf_rx_enable('0),
        .cfg_tx_lfc_eth_dst('{CNT{48'h01_80_C2_00_00_01}}),
        .cfg_tx_lfc_eth_src('{CNT{48'h80_23_31_43_54_4C}}),
        .cfg_tx_lfc_eth_type('{CNT{16'h8808}}),
        .cfg_tx_lfc_opcode('{CNT{16'h0001}}),
        .cfg_tx_lfc_en('0),
        .cfg_tx_lfc_quanta('{CNT{16'hffff}}),
        .cfg_tx_lfc_refresh('{CNT{16'h7fff}}),
        .cfg_tx_pfc_eth_dst('{CNT{48'h01_80_C2_00_00_01}}),
        .cfg_tx_pfc_eth_src('{CNT{48'h80_23_31_43_54_4C}}),
        .cfg_tx_pfc_eth_type('{CNT{16'h8808}}),
        .cfg_tx_pfc_opcode('{CNT{16'h0101}}),
        .cfg_tx_pfc_en('0),
        .cfg_tx_pfc_quanta('{CNT{'{8{16'hffff}}}}),
        .cfg_tx_pfc_refresh('{CNT{'{8{16'h7fff}}}}),
        .cfg_rx_lfc_opcode('{CNT{16'h0001}}),
        .cfg_rx_lfc_en('0),
        .cfg_rx_pfc_opcode('{CNT{16'h0101}}),
        .cfg_rx_pfc_en('0)
    );

end

for (genvar n = 0; n < 8; n = n + 1) begin : qsfp_ch

    taxi_axis_async_fifo #(
        .DEPTH(16384),
        .RAM_PIPELINE(2),
        .FRAME_FIFO(1),
        .USER_BAD_FRAME_VALUE(1'b1),
        .USER_BAD_FRAME_MASK(1'b1),
        .DROP_OVERSIZE_FRAME(1),
        .DROP_BAD_FRAME(1),
        .DROP_WHEN_FULL(1)
    )
    ch_fifo (
        /*
         * AXI4-Stream input (sink)
         */
        .s_clk(qsfp_rx_clk[n]),
        .s_rst(qsfp_rx_rst[n]),
        .s_axis(axis_qsfp_rx[n]),

        /*
         * AXI4-Stream output (source)
         */
        .m_clk(qsfp_tx_clk[n]),
        .m_rst(qsfp_tx_rst[n]),
        .m_axis(axis_qsfp_tx[n]),

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

end

endmodule

`resetall
