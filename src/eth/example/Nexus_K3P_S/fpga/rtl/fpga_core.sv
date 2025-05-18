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
    input  wire logic             clk_125mhz,
    input  wire logic             rst_125mhz,

    /*
     * GPIO
     */
    output wire logic [1:0][1:0]  sfp_led,
    output wire logic [1:0]       sma_led,

    /*
     * Ethernet: SFP+
     */
    input  wire logic [1:0]       sfp_rx_p,
    input  wire logic [1:0]       sfp_rx_n,
    output wire logic [1:0]       sfp_tx_p,
    output wire logic [1:0]       sfp_tx_n,
    input  wire logic             sfp_mgt_refclk_p,
    input  wire logic             sfp_mgt_refclk_n,
    output wire logic             sfp_mgt_refclk_out,
    output wire logic [1:0]       sfp_tx_disable,
    input  wire logic [1:0]       sfp_npres,
    input  wire logic [1:0]       sfp_los,
    output wire logic [1:0]       sfp_rs
);

// SFP+
wire [1:0] sfp_tx_clk;
wire [1:0] sfp_tx_rst;
wire [1:0] sfp_rx_clk;
wire [1:0] sfp_rx_rst;

wire [1:0] sfp_rx_status;

assign sfp_led[0][0] = sfp_rx_status[0];
assign sfp_led[0][1] = 1'b0;
assign sfp_led[1][0] = sfp_rx_status[1];
assign sfp_led[1][1] = 1'b0;
assign sma_led = '0;

assign sfp_tx_disable = '1;
assign sfp_rs = '1;

wire sfp_gtpowergood;

wire sfp_mgt_refclk;
wire sfp_mgt_refclk_int;
wire sfp_mgt_refclk_bufg;

assign sfp_mgt_refclk_out = sfp_mgt_refclk_bufg;

wire sfp_rst;

taxi_axis_if #(.DATA_W(64), .ID_W(8)) axis_sfp_tx[2]();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_W(8)) axis_sfp_tx_cpl[2]();
taxi_axis_if #(.DATA_W(64), .ID_W(8)) axis_sfp_rx[2]();
taxi_axis_if #(.DATA_W(16), .KEEP_W(1), .KEEP_EN(0), .LAST_EN(0), .USER_EN(1), .USER_W(1), .ID_EN(1), .ID_W(8)) axis_sfp_stat();

if (SIM) begin

    assign sfp_mgt_refclk = sfp_mgt_refclk_p;
    assign sfp_mgt_refclk_int = sfp_mgt_refclk_p;
    assign sfp_mgt_refclk_bufg = sfp_mgt_refclk_int;

end else begin

    if (FAMILY == "kintexu") begin

        IBUFDS_GTE3 ibufds_gte3_sfp_mgt_refclk_inst (
            .I     (sfp_mgt_refclk_p),
            .IB    (sfp_mgt_refclk_n),
            .CEB   (1'b0),
            .O     (sfp_mgt_refclk),
            .ODIV2 (sfp_mgt_refclk_int)
        );

    end else begin

        IBUFDS_GTE4 ibufds_gte4_sfp_mgt_refclk_inst (
            .I     (sfp_mgt_refclk_p),
            .IB    (sfp_mgt_refclk_n),
            .CEB   (1'b0),
            .O     (sfp_mgt_refclk),
            .ODIV2 (sfp_mgt_refclk_int)
        );

    end

    BUFG_GT bufg_gt_sfp_mgt_refclk_inst (
        .CE      (sfp_gtpowergood),
        .CEMASK  (1'b1),
        .CLR     (1'b0),
        .CLRMASK (1'b1),
        .DIV     (3'd0),
        .I       (sfp_mgt_refclk_int),
        .O       (sfp_mgt_refclk_bufg)
    );

end

taxi_sync_reset #(
    .N(4)
)
sfp_sync_reset_inst (
    .clk(sfp_mgt_refclk_bufg),
    .rst(rst_125mhz),
    .out(sfp_rst)
);

taxi_eth_mac_25g_us #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),

    .CNT(2),

    // GT type
    .GT_TYPE(FAMILY == "kintexu" ? "GTH" : "GTY"),

    // GT parameters
    .GT_TX_POLARITY('1),
    .GT_RX_POLARITY('0),

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
sfp_mac_inst (
    .xcvr_ctrl_clk(clk_125mhz),
    .xcvr_ctrl_rst(sfp_rst),

    /*
     * Common
     */
    .xcvr_gtpowergood_out(sfp_gtpowergood),
    .xcvr_gtrefclk00_in(sfp_mgt_refclk),
    .xcvr_qpll0lock_out(),
    .xcvr_qpll0clk_out(),
    .xcvr_qpll0refclk_out(),

    /*
     * Serial data
     */
    .xcvr_txp(sfp_tx_p),
    .xcvr_txn(sfp_tx_n),
    .xcvr_rxp(sfp_rx_p),
    .xcvr_rxn(sfp_rx_n),

    /*
     * MAC clocks
     */
    .rx_clk(sfp_rx_clk),
    .rx_rst_in('0),
    .rx_rst_out(sfp_rx_rst),
    .tx_clk(sfp_tx_clk),
    .tx_rst_in('0),
    .tx_rst_out(sfp_tx_rst),
    .ptp_sample_clk('0),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(axis_sfp_tx),
    .m_axis_tx_cpl(axis_sfp_tx_cpl),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(axis_sfp_rx),

    /*
     * PTP clock
     */
    .tx_ptp_ts('{2{'0}}),
    .tx_ptp_ts_step('0),
    .rx_ptp_ts('{2{'0}}),
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
    .tx_pfc_req('{2{'0}}),
    .tx_pfc_resend('0),
    .rx_pfc_en('{2{'0}}),
    .rx_pfc_req(),
    .rx_pfc_ack('{2{'0}}),

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
    .m_axis_stat(axis_sfp_stat),

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
    .rx_status(sfp_rx_status),
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
    .cfg_tx_max_pkt_len('{2{16'd9218}}),
    .cfg_tx_ifg('{2{8'd12}}),
    .cfg_tx_enable('1),
    .cfg_rx_max_pkt_len('{2{16'd9218}}),
    .cfg_rx_enable('1),
    .cfg_tx_prbs31_enable('0),
    .cfg_rx_prbs31_enable('0),
    .cfg_mcf_rx_eth_dst_mcast('{2{48'h01_80_C2_00_00_01}}),
    .cfg_mcf_rx_check_eth_dst_mcast('1),
    .cfg_mcf_rx_eth_dst_ucast('{2{48'd0}}),
    .cfg_mcf_rx_check_eth_dst_ucast('0),
    .cfg_mcf_rx_eth_src('{2{48'd0}}),
    .cfg_mcf_rx_check_eth_src('0),
    .cfg_mcf_rx_eth_type('{2{16'h8808}}),
    .cfg_mcf_rx_opcode_lfc('{2{16'h0001}}),
    .cfg_mcf_rx_check_opcode_lfc('1),
    .cfg_mcf_rx_opcode_pfc('{2{16'h0101}}),
    .cfg_mcf_rx_check_opcode_pfc('1),
    .cfg_mcf_rx_forward('0),
    .cfg_mcf_rx_enable('0),
    .cfg_tx_lfc_eth_dst('{2{48'h01_80_C2_00_00_01}}),
    .cfg_tx_lfc_eth_src('{2{48'h80_23_31_43_54_4C}}),
    .cfg_tx_lfc_eth_type('{2{16'h8808}}),
    .cfg_tx_lfc_opcode('{2{16'h0001}}),
    .cfg_tx_lfc_en('0),
    .cfg_tx_lfc_quanta('{2{16'hffff}}),
    .cfg_tx_lfc_refresh('{2{16'h7fff}}),
    .cfg_tx_pfc_eth_dst('{2{48'h01_80_C2_00_00_01}}),
    .cfg_tx_pfc_eth_src('{2{48'h80_23_31_43_54_4C}}),
    .cfg_tx_pfc_eth_type('{2{16'h8808}}),
    .cfg_tx_pfc_opcode('{2{16'h0101}}),
    .cfg_tx_pfc_en('0),
    .cfg_tx_pfc_quanta('{2{'{8{16'hffff}}}}),
    .cfg_tx_pfc_refresh('{2{'{8{16'h7fff}}}}),
    .cfg_rx_lfc_opcode('{2{16'h0001}}),
    .cfg_rx_lfc_en('0),
    .cfg_rx_pfc_opcode('{2{16'h0101}}),
    .cfg_rx_pfc_en('0)
);

for (genvar n = 0; n < 2; n = n + 1) begin : sfp_ch

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
        .s_clk(sfp_rx_clk[n]),
        .s_rst(sfp_rx_rst[n]),
        .s_axis(axis_sfp_rx[n]),

        /*
         * AXI4-Stream output (source)
         */
        .m_clk(sfp_tx_clk[n]),
        .m_rst(sfp_tx_rst[n]),
        .m_axis(axis_sfp_tx[n]),

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
