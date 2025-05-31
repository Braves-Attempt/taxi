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
    parameter string FAMILY = "virtexu"
)
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input  wire logic        clk,
    input  wire logic        rst,

    /*
     * GPIO
     */
    input  wire logic        btnu,
    input  wire logic        btnl,
    input  wire logic        btnd,
    input  wire logic        btnr,
    input  wire logic        btnc,
    input  wire logic [3:0]  sw,
    output wire logic [7:0]  led,

    /*
     * UART: 115200 bps, 8N1
     */
    input  wire logic        uart_rxd,
    output wire logic        uart_txd,
    input  wire logic        uart_rts,
    output wire logic        uart_cts,

    /*
     * Ethernet: 1000BASE-T SGMII
     */
    input  wire logic        phy_gmii_clk,
    input  wire logic        phy_gmii_rst,
    input  wire logic        phy_gmii_clk_en,
    input  wire logic [7:0]  phy_gmii_rxd,
    input  wire logic        phy_gmii_rx_dv,
    input  wire logic        phy_gmii_rx_er,
    output wire logic [7:0]  phy_gmii_txd,
    output wire logic        phy_gmii_tx_en,
    output wire logic        phy_gmii_tx_er,
    output wire logic        phy_reset_n,
    input  wire logic        phy_int_n,

    /*
     * Ethernet: QSFP28
     */
    input  wire logic [3:0]  qsfp_rx_p,
    input  wire logic [3:0]  qsfp_rx_n,
    output wire logic [3:0]  qsfp_tx_p,
    output wire logic [3:0]  qsfp_tx_n,
    input  wire logic        qsfp_mgt_refclk_0_p,
    input  wire logic        qsfp_mgt_refclk_0_n,
    // input  wire logic        qsfp_mgt_refclk_1_p,
    // input  wire logic        qsfp_mgt_refclk_1_n,
    // output wire logic        qsfp_recclk_p,
    // output wire logic        qsfp_recclk_n,
    output wire logic        qsfp_modsell,
    output wire logic        qsfp_resetl,
    input  wire logic        qsfp_modprsl,
    input  wire logic        qsfp_intl,
    output wire logic        qsfp_lpmode
);

// assign led = 8'(sw);

// XFCP
assign uart_cts = 1'b0;

taxi_axis_if #(.DATA_W(8), .USER_EN(1), .USER_W(1)) xfcp_ds(), xfcp_us();

taxi_xfcp_if_uart #(
    .TX_FIFO_DEPTH(512),
    .RX_FIFO_DEPTH(512)
)
xfcp_if_uart_inst (
    .clk(clk),
    .rst(rst),

    /*
     * UART interface
     */
    .uart_rxd(uart_rxd),
    .uart_txd(uart_txd),

    /*
     * XFCP downstream interface
     */
    .xfcp_dsp_ds(xfcp_ds),
    .xfcp_dsp_us(xfcp_us),

    /*
     * Configuration
     */
    .prescale(16'(125000000/921600))
);

taxi_axis_if #(.DATA_W(8), .USER_EN(1), .USER_W(1)) xfcp_sw_ds[1](), xfcp_sw_us[1]();

taxi_xfcp_switch #(
    .XFCP_ID_STR("VCU108"),
    .XFCP_EXT_ID(0),
    .XFCP_EXT_ID_STR("Taxi example"),
    .PORTS($size(xfcp_sw_us))
)
xfcp_sw_inst (
    .clk(clk),
    .rst(rst),

    /*
     * XFCP upstream port
     */
    .xfcp_usp_ds(xfcp_ds),
    .xfcp_usp_us(xfcp_us),

    /*
     * XFCP downstream ports
     */
    .xfcp_dsp_ds(xfcp_sw_ds),
    .xfcp_dsp_us(xfcp_sw_us)
);

taxi_axis_if #(.DATA_W(16), .KEEP_W(1), .KEEP_EN(0), .LAST_EN(0), .USER_EN(1), .USER_W(1), .ID_EN(1), .ID_W(10)) axis_stat();

taxi_xfcp_mod_stats #(
    .XFCP_ID_STR("Statistics"),
    .XFCP_EXT_ID(0),
    .XFCP_EXT_ID_STR(""),
    .STAT_COUNT_W(64),
    .STAT_PIPELINE(2)
)
xfcp_stats_inst (
    .clk(clk),
    .rst(rst),

    /*
     * XFCP upstream port
     */
    .xfcp_usp_ds(xfcp_sw_ds[0]),
    .xfcp_usp_us(xfcp_sw_us[0]),

    /*
     * Statistics increment input
     */
    .s_axis_stat(axis_stat)
);

taxi_axis_if #(.DATA_W(16), .KEEP_W(1), .KEEP_EN(0), .LAST_EN(0), .USER_EN(1), .USER_W(1), .ID_EN(1), .ID_W(10)) axis_eth_stat[2]();

taxi_axis_arb_mux #(
    .S_COUNT($size(axis_eth_stat)),
    .UPDATE_TID(1'b0),
    .ARB_ROUND_ROBIN(1'b1),
    .ARB_LSB_HIGH_PRIO(1'b0)
)
stat_mux_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream inputs (sink)
     */
    .s_axis(axis_eth_stat),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(axis_stat)
);

// BASE-T PHY
assign phy_reset_n = !rst;

taxi_axis_if #(.DATA_W(8), .ID_W(8)) axis_eth();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_W(8)) axis_tx_cpl();

taxi_eth_mac_1g_fifo #(
    .PADDING_EN(1),
    .MIN_FRAME_LEN(64),
    .STAT_EN(1),
    .STAT_TX_LEVEL(1),
    .STAT_RX_LEVEL(1),
    .STAT_ID_BASE(0),
    .STAT_UPDATE_PERIOD(1024),
    .STAT_STR_EN(1),
    .STAT_PREFIX_STR("SGMII0"),
    .TX_FIFO_DEPTH(16384),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(16384),
    .RX_FRAME_FIFO(1)
)
eth_mac_inst (
    .rx_clk(phy_gmii_clk),
    .rx_rst(phy_gmii_rst),
    .tx_clk(phy_gmii_clk),
    .tx_rst(phy_gmii_rst),
    .logic_clk(clk),
    .logic_rst(rst),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(axis_eth),
    .m_axis_tx_cpl(axis_tx_cpl),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(axis_eth),

    /*
     * GMII interface
     */
    .gmii_rxd(phy_gmii_rxd),
    .gmii_rx_dv(phy_gmii_rx_dv),
    .gmii_rx_er(phy_gmii_rx_er),
    .gmii_txd(phy_gmii_txd),
    .gmii_tx_en(phy_gmii_tx_en),
    .gmii_tx_er(phy_gmii_tx_er),

    /*
     * Control
     */
    .rx_clk_enable(phy_gmii_clk_en),
    .tx_clk_enable(phy_gmii_clk_en),
    .rx_mii_select(1'b0),
    .tx_mii_select(1'b0),

    /*
     * Statistics
     */
    .stat_clk(clk),
    .stat_rst(rst),
    .m_axis_stat(axis_eth_stat[0]),

    /*
     * Status
     */
    .tx_error_underflow(),
    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),

    /*
     * Configuration
     */
    .cfg_tx_max_pkt_len(16'd9218),
    .cfg_tx_ifg(8'd12),
    .cfg_tx_enable(1'b1),
    .cfg_rx_max_pkt_len(16'd9218),
    .cfg_rx_enable(1'b1)
);

// QSFP28
assign qsfp_modsell = 1'b0;
assign qsfp_resetl = 1'b1;
assign qsfp_lpmode = 1'b0;

wire [3:0] qsfp_tx_clk;
wire [3:0] qsfp_tx_rst;
wire [3:0] qsfp_rx_clk;
wire [3:0] qsfp_rx_rst;

wire [3:0] qsfp_rx_status;

assign led = {qsfp_rx_status, qsfp_rx_rst};

wire qsfp_gtpowergood;

wire qsfp_mgt_refclk_0;
wire qsfp_mgt_refclk_0_int;
wire qsfp_mgt_refclk_0_bufg;

wire qsfp_rst;

taxi_axis_if #(.DATA_W(64), .ID_W(8)) axis_qsfp_tx[4]();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_W(8)) axis_qsfp_tx_cpl[4]();
taxi_axis_if #(.DATA_W(64), .ID_W(8)) axis_qsfp_rx[4]();
taxi_axis_if #(.DATA_W(16), .KEEP_W(1), .KEEP_EN(0), .LAST_EN(0), .USER_EN(1), .USER_W(1), .ID_EN(1), .ID_W(8)) axis_qsfp_stat();

if (SIM) begin

    assign qsfp_mgt_refclk_0 = qsfp_mgt_refclk_0_p;
    assign qsfp_mgt_refclk_0_int = qsfp_mgt_refclk_0_p;
    assign qsfp_mgt_refclk_0_bufg = qsfp_mgt_refclk_0_int;

end else begin

    IBUFDS_GTE3 ibufds_gte3_qsfp_mgt_refclk_0_inst (
        .I     (qsfp_mgt_refclk_0_p),
        .IB    (qsfp_mgt_refclk_0_n),
        .CEB   (1'b0),
        .O     (qsfp_mgt_refclk_0),
        .ODIV2 (qsfp_mgt_refclk_0_int)
    );

    BUFG_GT bufg_gt_qsfp_mgt_refclk_0_inst (
        .CE      (qsfp_gtpowergood),
        .CEMASK  (1'b1),
        .CLR     (1'b0),
        .CLRMASK (1'b1),
        .DIV     (3'd0),
        .I       (qsfp_mgt_refclk_0_int),
        .O       (qsfp_mgt_refclk_0_bufg)
    );

end

taxi_sync_reset #(
    .N(4)
)
qsfp_sync_reset_inst (
    .clk(qsfp_mgt_refclk_0_bufg),
    .rst(rst),
    .out(qsfp_rst)
);

taxi_eth_mac_25g_us #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),

    .CNT(4),

    // GT config
    .CFG_LOW_LATENCY(1),

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
    .COUNT_125US(125000/6.4),
    .STAT_EN(1),
    .STAT_TX_LEVEL(1),
    .STAT_RX_LEVEL(1),
    .STAT_ID_BASE(16+16),
    .STAT_UPDATE_PERIOD(1024),
    .STAT_STR_EN(1),
    .STAT_PREFIX_STR('{"QSFP.1", "QSFP.2", "QSFP.3", "QSFP.4"})
)
qsfp_mac_inst (
    .xcvr_ctrl_clk(clk),
    .xcvr_ctrl_rst(qsfp_rst),

    /*
     * Common
     */
    .xcvr_gtpowergood_out(qsfp_gtpowergood),
    .xcvr_gtrefclk00_in(qsfp_mgt_refclk_0),
    .xcvr_qpll0pd_in(1'b0),
    .xcvr_qpll0reset_in(1'b0),
    .xcvr_qpll0pcierate_in(3'd0),
    .xcvr_qpll0lock_out(),
    .xcvr_qpll0clk_out(),
    .xcvr_qpll0refclk_out(),
    .xcvr_gtrefclk01_in(qsfp_mgt_refclk_0),
    .xcvr_qpll1pd_in(1'b0),
    .xcvr_qpll1reset_in(1'b0),
    .xcvr_qpll1pcierate_in(3'd0),
    .xcvr_qpll1lock_out(),
    .xcvr_qpll1clk_out(),
    .xcvr_qpll1refclk_out(),

    /*
     * Serial data
     */
    .xcvr_txp(qsfp_tx_p),
    .xcvr_txn(qsfp_tx_n),
    .xcvr_rxp(qsfp_rx_p),
    .xcvr_rxn(qsfp_rx_n),

    /*
     * MAC clocks
     */
    .rx_clk(qsfp_rx_clk),
    .rx_rst_in('0),
    .rx_rst_out(qsfp_rx_rst),
    .tx_clk(qsfp_tx_clk),
    .tx_rst_in('0),
    .tx_rst_out(qsfp_tx_rst),
    .ptp_sample_clk('0),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(axis_qsfp_tx),
    .m_axis_tx_cpl(axis_qsfp_tx_cpl),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(axis_qsfp_rx),

    /*
     * PTP clock
     */
    .tx_ptp_ts('{4{'0}}),
    .tx_ptp_ts_step('0),
    .rx_ptp_ts('{4{'0}}),
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
    .tx_pfc_req('{4{'0}}),
    .tx_pfc_resend('0),
    .rx_pfc_en('{4{'0}}),
    .rx_pfc_req(),
    .rx_pfc_ack('{4{'0}}),

    /*
     * Pause interface
     */
    .tx_lfc_pause_en('0),
    .tx_pause_req('0),
    .tx_pause_ack(),

    /*
     * Statistics
     */
    .stat_clk(clk),
    .stat_rst(rst),
    .m_axis_stat(axis_eth_stat[1]),

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
    .rx_status(qsfp_rx_status),
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
    .cfg_tx_max_pkt_len('{4{16'd9218}}),
    .cfg_tx_ifg('{4{8'd12}}),
    .cfg_tx_enable('1),
    .cfg_rx_max_pkt_len('{4{16'd9218}}),
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

for (genvar n = 0; n < 4; n = n + 1) begin : qsfp_ch

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
