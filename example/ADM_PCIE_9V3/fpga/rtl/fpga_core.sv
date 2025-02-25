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
    parameter string FAMILY = "virtexuplus"
)
(
    /*
     * Clock: 125 MHz
     * Synchronous reset
     */
    input  wire       clk_125mhz,
    input  wire       rst_125mhz,

    /*
     * GPIO
     */
    output wire [1:0] user_led_g,
    output wire       user_led_r,
    output wire [1:0] front_led,
    input  wire [1:0] user_sw,

    /*
     * Ethernet: QSFP28
     */
    output wire logic [3:0]  qsfp_0_tx_p,
    output wire logic [3:0]  qsfp_0_tx_n,
    input  wire logic [3:0]  qsfp_0_rx_p,
    input  wire logic [3:0]  qsfp_0_rx_n,
    input  wire logic        qsfp_0_mgt_refclk_p,
    input  wire logic        qsfp_0_mgt_refclk_n,
    input  wire logic        qsfp_0_modprs_l,
    output wire logic        qsfp_0_sel_l,

    output wire logic [3:0]  qsfp_1_tx_p,
    output wire logic [3:0]  qsfp_1_tx_n,
    input  wire logic [3:0]  qsfp_1_rx_p,
    input  wire logic [3:0]  qsfp_1_rx_n,
    // input  wire logic        qsfp_1_mgt_refclk_p,
    // input  wire logic        qsfp_1_mgt_refclk_n,
    input  wire logic        qsfp_1_modprs_l,
    output wire logic        qsfp_1_sel_l,

    output wire logic        qsfp_reset_l,
    input  wire logic        qsfp_int_l
);


// QSFP28
assign qsfp_0_sel_l = 1'b1;
assign qsfp_1_sel_l = 1'b1;
assign qsfp_reset_l = 1'b1;

wire [7:0] qsfp_tx_clk;
wire [7:0] qsfp_tx_rst;
wire [7:0] qsfp_rx_clk;
wire [7:0] qsfp_rx_rst;

wire [7:0] qsfp_rx_status;

wire [1:0] qsfp_gtpowergood;

wire qsfp_0_mgt_refclk;
wire qsfp_0_mgt_refclk_int;
wire qsfp_0_mgt_refclk_bufg;

wire qsfp_rst;

taxi_axis_if #(.DATA_W(64), .ID_W(8)) axis_qsfp_tx[7:0]();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_W(8)) axis_qsfp_tx_cpl[7:0]();
taxi_axis_if #(.DATA_W(64), .ID_W(8)) axis_qsfp_rx[7:0]();

if (SIM) begin

    assign qsfp_0_mgt_refclk = qsfp_0_mgt_refclk_p;
    assign qsfp_0_mgt_refclk_int = qsfp_0_mgt_refclk_p;
    assign qsfp_0_mgt_refclk_bufg = qsfp_0_mgt_refclk_int;

end else begin

    IBUFDS_GTE4 ibufds_gte4_qsfp_0_mgt_refclk_inst (
        .I     (qsfp_0_mgt_refclk_p),
        .IB    (qsfp_0_mgt_refclk_n),
        .CEB   (1'b0),
        .O     (qsfp_0_mgt_refclk),
        .ODIV2 (qsfp_0_mgt_refclk_int)
    );

    BUFG_GT bufg_gt_qsfp_0_mgt_refclk_inst (
        .CE      (&qsfp_gtpowergood),
        .CEMASK  (1'b1),
        .CLR     (1'b0),
        .CLRMASK (1'b1),
        .DIV     (3'd0),
        .I       (qsfp_0_mgt_refclk_int),
        .O       (qsfp_0_mgt_refclk_bufg)
    );

end

taxi_sync_reset #(
    .N(4)
)
qsfp_sync_reset_inst (
    .clk(qsfp_0_mgt_refclk_bufg),
    .rst(rst_125mhz),
    .out(qsfp_rst)
);

taxi_eth_mac_25g_us #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),

    .CNT(4),

    // GT type
    .GT_TYPE("GTY"),

    // PHY parameters
    .PADDING_EN(1'b1),
    .DIC_EN(1'b1),
    .MIN_FRAME_LEN(64),
    .PTP_TS_EN(1'b0),
    .PTP_TS_FMT_TOD(1'b1),
    .PTP_TS_W(96),
    .PRBS31_EN(1'b0),
    .TX_SERDES_PIPELINE(1),
    .RX_SERDES_PIPELINE(1),
    .COUNT_125US(125000/6.4)
)
qsfp_0_mac_inst (
    .xcvr_ctrl_clk(clk_125mhz),
    .xcvr_ctrl_rst(qsfp_rst),

    /*
     * Common
     */
    .xcvr_gtpowergood_out(qsfp_gtpowergood[0]),
    .xcvr_gtrefclk00_in(qsfp_0_mgt_refclk),
    .xcvr_qpll0lock_out(),
    .xcvr_qpll0clk_out(),
    .xcvr_qpll0refclk_out(),

    /*
     * Serial data
     */
    .xcvr_txp(qsfp_0_tx_p),
    .xcvr_txn(qsfp_0_tx_n),
    .xcvr_rxp(qsfp_0_rx_p),
    .xcvr_rxn(qsfp_0_rx_n),

    /*
     * MAC clocks
     */
    .rx_clk(qsfp_rx_clk[3:0]),
    .rx_rst_in('0),
    .rx_rst_out(qsfp_rx_rst[3:0]),
    .tx_clk(qsfp_tx_clk[3:0]),
    .tx_rst_in('0),
    .tx_rst_out(qsfp_tx_rst[3:0]),
    .ptp_sample_clk('0),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(axis_qsfp_tx[3:0]),
    .m_axis_tx_cpl(axis_qsfp_tx_cpl[3:0]),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(axis_qsfp_rx[3:0]),

    /*
     * PTP clock
     */
    .tx_ptp_ts('0),
    .tx_ptp_ts_step('0),
    .rx_ptp_ts('0),
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
    .tx_pfc_req('0),
    .tx_pfc_resend('0),
    .rx_pfc_en('0),
    .rx_pfc_req(),
    .rx_pfc_ack('0),

    /*
     * Pause interface
     */
    .tx_lfc_pause_en('0),
    .tx_pause_req('0),
    .tx_pause_ack(),

    /*
     * Status
     */
    .tx_start_packet(),
    .tx_error_underflow(),
    .rx_start_packet(),
    .rx_error_count(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_bad_block(),
    .rx_sequence_error(),
    .rx_block_lock(),
    .rx_high_ber(),
    .rx_status(qsfp_rx_status[3:0]),
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
    .cfg_ifg('{4{8'd12}}),
    .cfg_tx_enable('1),
    .cfg_rx_enable('1),
    .cfg_tx_prbs31_enable('0),
    .cfg_rx_prbs31_enable('0),
    .cfg_mcf_rx_eth_dst_mcast('{4{48'h01_80_C2_00_00_01}}),
    .cfg_mcf_rx_check_eth_dst_mcast('1),
    .cfg_mcf_rx_eth_dst_ucast('{4{48'd0}}),
    .cfg_mcf_rx_check_eth_dst_ucast('0),
    .cfg_mcf_rx_eth_src('{4{48'd0}}),
    .cfg_mcf_rx_check_eth_src('0),
    .cfg_mcf_rx_eth_type('{4{16'h8808}}),
    .cfg_mcf_rx_opcode_lfc('{4{16'h0001}}),
    .cfg_mcf_rx_check_opcode_lfc('1),
    .cfg_mcf_rx_opcode_pfc('{4{16'h0101}}),
    .cfg_mcf_rx_check_opcode_pfc('1),
    .cfg_mcf_rx_forward('0),
    .cfg_mcf_rx_enable('0),
    .cfg_tx_lfc_eth_dst('{4{48'h01_80_C2_00_00_01}}),
    .cfg_tx_lfc_eth_src('{4{48'h80_23_31_43_54_4C}}),
    .cfg_tx_lfc_eth_type('{4{16'h8808}}),
    .cfg_tx_lfc_opcode('{4{16'h0001}}),
    .cfg_tx_lfc_en('0),
    .cfg_tx_lfc_quanta('{4{16'hffff}}),
    .cfg_tx_lfc_refresh('{4{16'h7fff}}),
    .cfg_tx_pfc_eth_dst('{4{48'h01_80_C2_00_00_01}}),
    .cfg_tx_pfc_eth_src('{4{48'h80_23_31_43_54_4C}}),
    .cfg_tx_pfc_eth_type('{4{16'h8808}}),
    .cfg_tx_pfc_opcode('{4{16'h0101}}),
    .cfg_tx_pfc_en('0),
    .cfg_tx_pfc_quanta('{4{'{8{16'hffff}}}}),
    .cfg_tx_pfc_refresh('{4{'{8{16'h7fff}}}}),
    .cfg_rx_lfc_opcode('{4{16'h0001}}),
    .cfg_rx_lfc_en('0),
    .cfg_rx_pfc_opcode('{4{16'h0101}}),
    .cfg_rx_pfc_en('0)
);

taxi_eth_mac_25g_us #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),

    .CNT(4),

    // GT type
    .GT_TYPE("GTY"),

    // PHY parameters
    .PADDING_EN(1'b1),
    .DIC_EN(1'b1),
    .MIN_FRAME_LEN(64),
    .PTP_TS_EN(1'b0),
    .PTP_TS_FMT_TOD(1'b1),
    .PTP_TS_W(96),
    .PRBS31_EN(1'b0),
    .TX_SERDES_PIPELINE(1),
    .RX_SERDES_PIPELINE(1),
    .COUNT_125US(125000/6.4)
)
qsfp_1_mac_inst (
    .xcvr_ctrl_clk(clk_125mhz),
    .xcvr_ctrl_rst(qsfp_rst),

    /*
     * Common
     */
    .xcvr_gtpowergood_out(qsfp_gtpowergood[1]),
    .xcvr_gtrefclk00_in(qsfp_0_mgt_refclk),
    .xcvr_qpll0lock_out(),
    .xcvr_qpll0clk_out(),
    .xcvr_qpll0refclk_out(),

    /*
     * Serial data
     */
    .xcvr_txp(qsfp_1_tx_p),
    .xcvr_txn(qsfp_1_tx_n),
    .xcvr_rxp(qsfp_1_rx_p),
    .xcvr_rxn(qsfp_1_rx_n),

    /*
     * MAC clocks
     */
    .rx_clk(qsfp_rx_clk[7:4]),
    .rx_rst_in('0),
    .rx_rst_out(qsfp_rx_rst[7:4]),
    .tx_clk(qsfp_tx_clk[7:4]),
    .tx_rst_in('0),
    .tx_rst_out(qsfp_tx_rst[7:4]),
    .ptp_sample_clk('0),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(axis_qsfp_tx[7:4]),
    .m_axis_tx_cpl(axis_qsfp_tx_cpl[7:4]),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(axis_qsfp_rx[7:4]),

    /*
     * PTP clock
     */
    .tx_ptp_ts('0),
    .tx_ptp_ts_step('0),
    .rx_ptp_ts('0),
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
    .tx_pfc_req('0),
    .tx_pfc_resend('0),
    .rx_pfc_en('0),
    .rx_pfc_req(),
    .rx_pfc_ack('0),

    /*
     * Pause interface
     */
    .tx_lfc_pause_en('0),
    .tx_pause_req('0),
    .tx_pause_ack(),

    /*
     * Status
     */
    .tx_start_packet(),
    .tx_error_underflow(),
    .rx_start_packet(),
    .rx_error_count(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_bad_block(),
    .rx_sequence_error(),
    .rx_block_lock(),
    .rx_high_ber(),
    .rx_status(qsfp_rx_status[7:4]),
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
    .cfg_ifg('{4{8'd12}}),
    .cfg_tx_enable('1),
    .cfg_rx_enable('1),
    .cfg_tx_prbs31_enable('0),
    .cfg_rx_prbs31_enable('0),
    .cfg_mcf_rx_eth_dst_mcast('{4{48'h01_80_C2_00_00_01}}),
    .cfg_mcf_rx_check_eth_dst_mcast('1),
    .cfg_mcf_rx_eth_dst_ucast('{4{48'd0}}),
    .cfg_mcf_rx_check_eth_dst_ucast('0),
    .cfg_mcf_rx_eth_src('{4{48'd0}}),
    .cfg_mcf_rx_check_eth_src('0),
    .cfg_mcf_rx_eth_type('{4{16'h8808}}),
    .cfg_mcf_rx_opcode_lfc('{4{16'h0001}}),
    .cfg_mcf_rx_check_opcode_lfc('1),
    .cfg_mcf_rx_opcode_pfc('{4{16'h0101}}),
    .cfg_mcf_rx_check_opcode_pfc('1),
    .cfg_mcf_rx_forward('0),
    .cfg_mcf_rx_enable('0),
    .cfg_tx_lfc_eth_dst('{4{48'h01_80_C2_00_00_01}}),
    .cfg_tx_lfc_eth_src('{4{48'h80_23_31_43_54_4C}}),
    .cfg_tx_lfc_eth_type('{4{16'h8808}}),
    .cfg_tx_lfc_opcode('{4{16'h0001}}),
    .cfg_tx_lfc_en('0),
    .cfg_tx_lfc_quanta('{4{16'hffff}}),
    .cfg_tx_lfc_refresh('{4{16'h7fff}}),
    .cfg_tx_pfc_eth_dst('{4{48'h01_80_C2_00_00_01}}),
    .cfg_tx_pfc_eth_src('{4{48'h80_23_31_43_54_4C}}),
    .cfg_tx_pfc_eth_type('{4{16'h8808}}),
    .cfg_tx_pfc_opcode('{4{16'h0101}}),
    .cfg_tx_pfc_en('0),
    .cfg_tx_pfc_quanta('{4{'{8{16'hffff}}}}),
    .cfg_tx_pfc_refresh('{4{'{8{16'h7fff}}}}),
    .cfg_rx_lfc_opcode('{4{16'h0001}}),
    .cfg_rx_lfc_en('0),
    .cfg_rx_pfc_opcode('{4{16'h0101}}),
    .cfg_rx_pfc_en('0)
);

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
