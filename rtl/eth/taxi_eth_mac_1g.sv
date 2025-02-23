// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2015-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * 1G Ethernet MAC
 */
module taxi_eth_mac_1g #
(
    parameter DATA_W = 8,
    parameter logic PADDING_EN = 1'b1,
    parameter MIN_FRAME_LEN = 64,
    parameter logic PTP_TS_EN = 1'b0,
    parameter PTP_TS_W = 96,
    parameter logic PFC_EN = 1'b0,
    parameter logic PAUSE_EN = PFC_EN
)
(
    input  wire logic                 rx_clk,
    input  wire logic                 rx_rst,
    input  wire logic                 tx_clk,
    input  wire logic                 tx_rst,

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
     * GMII interface
     */
    input  wire logic [DATA_W-1:0]    gmii_rxd,
    input  wire logic                 gmii_rx_dv,
    input  wire logic                 gmii_rx_er,
    output wire logic [DATA_W-1:0]    gmii_txd,
    output wire logic                 gmii_tx_en,
    output wire logic                 gmii_tx_er,

    /*
     * PTP
     */
    input  wire logic [PTP_TS_W-1:0]  tx_ptp_ts = '0,
    input  wire logic [PTP_TS_W-1:0]  rx_ptp_ts = '0,

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
     * Control
     */
    input  wire logic                 rx_clk_enable = 1'b1,
    input  wire logic                 tx_clk_enable = 1'b1,
    input  wire logic                 rx_mii_select = 1'b0,
    input  wire logic                 tx_mii_select = 1'b0,

    /*
     * Status
     */
    output wire logic                 tx_start_packet,
    output wire logic                 tx_error_underflow,
    output wire logic                 rx_start_packet,
    output wire logic                 rx_error_bad_frame,
    output wire logic                 rx_error_bad_fcs,
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
    input  wire logic [7:0]           cfg_ifg = 8'd12,
    input  wire logic                 cfg_tx_enable = 1'b1,
    input  wire logic                 cfg_rx_enable = 1'b1,
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
    input  wire logic [7:0][15:0]     cfg_tx_pfc_quanta = '{8{16'hffff}},
    input  wire logic [7:0][15:0]     cfg_tx_pfc_refresh = '{8{16'h7fff}},
    input  wire logic [15:0]          cfg_rx_lfc_opcode = 16'h0001,
    input  wire logic                 cfg_rx_lfc_en = 1'b0,
    input  wire logic [15:0]          cfg_rx_pfc_opcode = 16'h0101,
    input  wire logic                 cfg_rx_pfc_en = 1'b0
);

localparam TX_USER_W = 1;
localparam RX_USER_W = (PTP_TS_EN ? PTP_TS_W : 0) + 1;
localparam TX_TAG_W = s_axis_tx.ID_W;

localparam MAC_CTRL_EN = PAUSE_EN || PFC_EN;
localparam TX_USER_W_INT = (MAC_CTRL_EN ? 1 : 0) + TX_USER_W;

taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(TX_USER_W_INT), .ID_EN(1), .ID_W(TX_TAG_W)) axis_tx_int();
taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(RX_USER_W)) axis_rx_int();

taxi_axis_gmii_rx #(
    .DATA_W(DATA_W),
    .PTP_TS_EN(PTP_TS_EN),
    .PTP_TS_W(PTP_TS_W)
)
axis_gmii_rx_inst (
    .clk(rx_clk),
    .rst(rx_rst),

    /*
     * GMII input
     */
    .gmii_rxd(gmii_rxd),
    .gmii_rx_dv(gmii_rx_dv),
    .gmii_rx_er(gmii_rx_er),

    /*
     * Receive interface (AXI stream)
     */
    .m_axis_rx(axis_rx_int),

    /*
     * PTP
     */
    .ptp_ts(rx_ptp_ts),

    /*
     * Control
     */
    .clk_enable(rx_clk_enable),
    .mii_select(rx_mii_select),

    /*
     * Configuration
     */
    .cfg_rx_enable(cfg_rx_enable),

    /*
     * Status
     */
    .start_packet(rx_start_packet),
    .error_bad_frame(rx_error_bad_frame),
    .error_bad_fcs(rx_error_bad_fcs)
);

taxi_axis_gmii_tx #(
    .DATA_W(DATA_W),
    .PADDING_EN(PADDING_EN),
    .MIN_FRAME_LEN(MIN_FRAME_LEN),
    .PTP_TS_EN(PTP_TS_EN),
    .PTP_TS_W(PTP_TS_W),
    .TX_CPL_CTRL_IN_TUSER(MAC_CTRL_EN)
)
axis_gmii_tx_inst (
    .clk(tx_clk),
    .rst(tx_rst),

    /*
     * Transmit interface (AXI stream)
     */
    .s_axis_tx(axis_tx_int),
    .m_axis_tx_cpl(m_axis_tx_cpl),

    /*
     * GMII output
     */
    .gmii_txd(gmii_txd),
    .gmii_tx_en(gmii_tx_en),
    .gmii_tx_er(gmii_tx_er),

    /*
     * PTP
     */
    .ptp_ts(tx_ptp_ts),

    /*
     * Control
     */
    .clk_enable(tx_clk_enable),
    .mii_select(tx_mii_select),

    /*
     * Configuration
     */
    .cfg_ifg(cfg_ifg),
    .cfg_tx_enable(cfg_tx_enable),

    /*
     * Status
     */
    .start_packet(tx_start_packet),
    .error_underflow(tx_error_underflow)
);

generate

if (MAC_CTRL_EN) begin : mac_ctrl

    localparam MCF_PARAMS_SIZE = PFC_EN ? 18 : 2;

    wire                          tx_mcf_valid;
    wire                          tx_mcf_ready;
    wire [47:0]                   tx_mcf_eth_dst;
    wire [47:0]                   tx_mcf_eth_src;
    wire [15:0]                   tx_mcf_eth_type;
    wire [15:0]                   tx_mcf_opcode;
    wire [MCF_PARAMS_SIZE*8-1:0]  tx_mcf_params;

    wire                          rx_mcf_valid;
    wire [47:0]                   rx_mcf_eth_dst;
    wire [47:0]                   rx_mcf_eth_src;
    wire [15:0]                   rx_mcf_eth_type;
    wire [15:0]                   rx_mcf_opcode;
    wire [MCF_PARAMS_SIZE*8-1:0]  rx_mcf_params;

    // terminate LFC pause requests from RX internally on TX side
    wire                          tx_pause_req_int;
    wire                          rx_lfc_ack_int;

    reg tx_lfc_req_sync_reg_1 = 1'b0;
    reg tx_lfc_req_sync_reg_2 = 1'b0;
    reg tx_lfc_req_sync_reg_3 = 1'b0;

    always @(posedge rx_clk or posedge rx_rst) begin
        if (rx_rst) begin
            tx_lfc_req_sync_reg_1 <= 1'b0;
        end else begin
            tx_lfc_req_sync_reg_1 <= rx_lfc_req;
        end
    end

    always @(posedge tx_clk or posedge tx_rst) begin
        if (tx_rst) begin
            tx_lfc_req_sync_reg_2 <= 1'b0;
            tx_lfc_req_sync_reg_3 <= 1'b0;
        end else begin
            tx_lfc_req_sync_reg_2 <= tx_lfc_req_sync_reg_1;
            tx_lfc_req_sync_reg_3 <= tx_lfc_req_sync_reg_2;
        end
    end

    reg rx_lfc_ack_sync_reg_1 = 1'b0;
    reg rx_lfc_ack_sync_reg_2 = 1'b0;
    reg rx_lfc_ack_sync_reg_3 = 1'b0;

    always @(posedge tx_clk or posedge tx_rst) begin
        if (tx_rst) begin
            rx_lfc_ack_sync_reg_1 <= 1'b0;
        end else begin
            rx_lfc_ack_sync_reg_1 <= tx_lfc_pause_en ? tx_pause_ack : 0;
        end
    end

    always @(posedge rx_clk or posedge rx_rst) begin
        if (rx_rst) begin
            rx_lfc_ack_sync_reg_2 <= 1'b0;
            rx_lfc_ack_sync_reg_3 <= 1'b0;
        end else begin
            rx_lfc_ack_sync_reg_2 <= rx_lfc_ack_sync_reg_1;
            rx_lfc_ack_sync_reg_3 <= rx_lfc_ack_sync_reg_2;
        end
    end

    assign tx_pause_req_int = tx_pause_req || (tx_lfc_pause_en ? tx_lfc_req_sync_reg_3 : 0);

    assign rx_lfc_ack_int = rx_lfc_ack || rx_lfc_ack_sync_reg_3;

    taxi_mac_ctrl_tx #(
        .ID_W(s_axis_tx.ID_W),
        .DEST_W(s_axis_tx.DEST_W),
        .USER_W(TX_USER_W_INT),
        .MCF_PARAMS_SIZE(MCF_PARAMS_SIZE)
    )
    mac_ctrl_tx_inst (
        .clk(tx_clk),
        .rst(tx_rst),

        /*
         * AXI stream input
         */
        .s_axis(s_axis_tx),

        /*
         * AXI stream output
         */
        .m_axis(axis_tx_int),

        /*
         * MAC control frame interface
         */
        .mcf_valid(tx_mcf_valid),
        .mcf_ready(tx_mcf_ready),
        .mcf_eth_dst(tx_mcf_eth_dst),
        .mcf_eth_src(tx_mcf_eth_src),
        .mcf_eth_type(tx_mcf_eth_type),
        .mcf_opcode(tx_mcf_opcode),
        .mcf_params(tx_mcf_params),
        .mcf_id('0),
        .mcf_dest('0),
        .mcf_user(2'b10),

        /*
         * Pause interface
         */
        .tx_pause_req(tx_pause_req_int),
        .tx_pause_ack(tx_pause_ack),

        /*
         * Status
         */
        .stat_tx_mcf(stat_tx_mcf)
    );

    taxi_mac_ctrl_rx #(
        .USER_W(RX_USER_W),
        .USE_READY(0),
        .MCF_PARAMS_SIZE(MCF_PARAMS_SIZE)
    )
    mac_ctrl_rx_inst (
        .clk(rx_clk),
        .rst(rx_rst),

        /*
         * AXI stream input
         */
        .s_axis(axis_rx_int),

        /*
         * AXI stream output
         */
        .m_axis(m_axis_rx),

        /*
         * MAC control frame interface
         */
        .mcf_valid(rx_mcf_valid),
        .mcf_eth_dst(rx_mcf_eth_dst),
        .mcf_eth_src(rx_mcf_eth_src),
        .mcf_eth_type(rx_mcf_eth_type),
        .mcf_opcode(rx_mcf_opcode),
        .mcf_params(rx_mcf_params),
        .mcf_id(),
        .mcf_dest(),
        .mcf_user(),

        /*
         * Configuration
         */
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

        /*
         * Status
         */
        .stat_rx_mcf(stat_rx_mcf)
    );

    taxi_mac_pause_ctrl_tx #(
        .MCF_PARAMS_SIZE(MCF_PARAMS_SIZE),
        .PFC_EN(PFC_EN)
    )
    mac_pause_ctrl_tx_inst (
        .clk(tx_clk),
        .rst(tx_rst),

        /*
         * MAC control frame interface
         */
        .mcf_valid(tx_mcf_valid),
        .mcf_ready(tx_mcf_ready),
        .mcf_eth_dst(tx_mcf_eth_dst),
        .mcf_eth_src(tx_mcf_eth_src),
        .mcf_eth_type(tx_mcf_eth_type),
        .mcf_opcode(tx_mcf_opcode),
        .mcf_params(tx_mcf_params),

        /*
         * Pause (IEEE 802.3 annex 31B)
         */
        .tx_lfc_req(tx_lfc_req),
        .tx_lfc_resend(tx_lfc_resend),

        /*
         * Priority Flow Control (PFC) (IEEE 802.3 annex 31D)
         */
        .tx_pfc_req(tx_pfc_req),
        .tx_pfc_resend(tx_pfc_resend),

        /*
         * Configuration
         */
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
        .cfg_quanta_step(tx_mii_select ? 10'((4*256)/512) : 10'((8*256)/512)),
        .cfg_quanta_clk_en(tx_clk_enable),

        /*
         * Status
         */
        .stat_tx_lfc_pkt(stat_tx_lfc_pkt),
        .stat_tx_lfc_xon(stat_tx_lfc_xon),
        .stat_tx_lfc_xoff(stat_tx_lfc_xoff),
        .stat_tx_lfc_paused(stat_tx_lfc_paused),
        .stat_tx_pfc_pkt(stat_tx_pfc_pkt),
        .stat_tx_pfc_xon(stat_tx_pfc_xon),
        .stat_tx_pfc_xoff(stat_tx_pfc_xoff),
        .stat_tx_pfc_paused(stat_tx_pfc_paused)
    );

    taxi_mac_pause_ctrl_rx #(
        .MCF_PARAMS_SIZE(18),
        .PFC_EN(PFC_EN)
    )
    mac_pause_ctrl_rx_inst (
        .clk(rx_clk),
        .rst(rx_rst),

        /*
         * MAC control frame interface
         */
        .mcf_valid(rx_mcf_valid),
        .mcf_eth_dst(rx_mcf_eth_dst),
        .mcf_eth_src(rx_mcf_eth_src),
        .mcf_eth_type(rx_mcf_eth_type),
        .mcf_opcode(rx_mcf_opcode),
        .mcf_params(rx_mcf_params),

        /*
         * Pause (IEEE 802.3 annex 31B)
         */
        .rx_lfc_en(rx_lfc_en),
        .rx_lfc_req(rx_lfc_req),
        .rx_lfc_ack(rx_lfc_ack_int),

        /*
         * Priority Flow Control (PFC) (IEEE 802.3 annex 31D)
         */
        .rx_pfc_en(rx_pfc_en),
        .rx_pfc_req(rx_pfc_req),
        .rx_pfc_ack(rx_pfc_ack),

        /*
         * Configuration
         */
        .cfg_rx_lfc_opcode(cfg_rx_lfc_opcode),
        .cfg_rx_lfc_en(cfg_rx_lfc_en),
        .cfg_rx_pfc_opcode(cfg_rx_pfc_opcode),
        .cfg_rx_pfc_en(cfg_rx_pfc_en),
        .cfg_quanta_step(rx_mii_select ? 10'((4*256)/512) : 10'((8*256)/512)),
        .cfg_quanta_clk_en(rx_clk_enable),

        /*
         * Status
         */
        .stat_rx_lfc_pkt(stat_rx_lfc_pkt),
        .stat_rx_lfc_xon(stat_rx_lfc_xon),
        .stat_rx_lfc_xoff(stat_rx_lfc_xoff),
        .stat_rx_lfc_paused(stat_rx_lfc_paused),
        .stat_rx_pfc_pkt(stat_rx_pfc_pkt),
        .stat_rx_pfc_xon(stat_rx_pfc_xon),
        .stat_rx_pfc_xoff(stat_rx_pfc_xoff),
        .stat_rx_pfc_paused(stat_rx_pfc_paused)
    );

end else begin

    assign axis_tx_int.tdata = s_axis_tx.tdata;
    assign axis_tx_int.tkeep = s_axis_tx.tkeep;
    assign axis_tx_int.tvalid = s_axis_tx.tvalid;
    assign s_axis_tx.tready = axis_tx_int.tready;
    assign axis_tx_int.tlast = s_axis_tx.tlast;
    assign axis_tx_int.tid = s_axis_tx.tid;
    assign axis_tx_int.tdest = s_axis_tx.tdest;
    assign axis_tx_int.tuser = s_axis_tx.tuser;

    assign m_axis_rx.tdata = axis_rx_int.tdata;
    assign m_axis_rx.tkeep = axis_rx_int.tkeep;
    assign m_axis_rx.tvalid = axis_rx_int.tvalid;
    assign m_axis_rx.tlast = axis_rx_int.tlast;
    assign m_axis_rx.tid = axis_rx_int.tid;
    assign m_axis_rx.tdest = axis_rx_int.tdest;
    assign m_axis_rx.tuser = axis_rx_int.tuser;

    assign rx_lfc_req = '0;
    assign rx_pfc_req = '0;
    assign tx_pause_ack = '0;

    assign stat_tx_mcf = '0;
    assign stat_rx_mcf = '0;
    assign stat_tx_lfc_pkt = '0;
    assign stat_tx_lfc_xon = '0;
    assign stat_tx_lfc_xoff = '0;
    assign stat_tx_lfc_paused = '0;
    assign stat_tx_pfc_pkt = '0;
    assign stat_tx_pfc_xon = '0;
    assign stat_tx_pfc_xoff = '0;
    assign stat_tx_pfc_paused = '0;
    assign stat_rx_lfc_pkt = '0;
    assign stat_rx_lfc_xon = '0;
    assign stat_rx_lfc_xoff = '0;
    assign stat_rx_lfc_paused = '0;
    assign stat_rx_pfc_pkt = '0;
    assign stat_rx_pfc_xon = '0;
    assign stat_rx_pfc_xoff = '0;
    assign stat_rx_pfc_paused = '0;

end

endgenerate

endmodule

`resetall
