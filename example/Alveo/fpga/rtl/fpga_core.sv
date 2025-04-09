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
    parameter string FAMILY = "virtexuplus",
    parameter SW_CNT = 4,
    parameter LED_CNT = 3,
    parameter UART_CNT = 1,
    parameter PORT_CNT = 2,
    parameter PORT_LED_CNT = PORT_CNT,
    parameter GTY_QUAD_CNT = PORT_CNT,
    parameter GTY_CNT = GTY_QUAD_CNT*4,
    parameter GTY_CLK_CNT = GTY_QUAD_CNT
)
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input  wire                          clk_125mhz,
    input  wire                          rst_125mhz,

    /*
     * GPIO
     */
    input  wire [SW_CNT-1:0]             sw,
    output wire [LED_CNT-1:0]            led,
    output wire [PORT_LED_CNT-1:0]       port_led_act,
    output wire [PORT_LED_CNT-1:0]       port_led_stat_r,
    output wire [PORT_LED_CNT-1:0]       port_led_stat_g,
    output wire [PORT_LED_CNT-1:0]       port_led_stat_b,
    output wire [PORT_LED_CNT-1:0]       port_led_stat_y,

    /*
     * UART
     */
    output wire [UART_CNT-1:0]           uart_txd,
    input  wire [UART_CNT-1:0]           uart_rxd,

    /*
     * Ethernet
     */
    output wire logic [GTY_CNT-1:0]      eth_gty_tx_p,
    output wire logic [GTY_CNT-1:0]      eth_gty_tx_n,
    input  wire logic [GTY_CNT-1:0]      eth_gty_rx_p,
    input  wire logic [GTY_CNT-1:0]      eth_gty_rx_n,
    input  wire logic [GTY_CLK_CNT-1:0]  eth_gty_mgt_refclk_p,
    input  wire logic [GTY_CLK_CNT-1:0]  eth_gty_mgt_refclk_n,
    output wire logic [GTY_CLK_CNT-1:0]  eth_gty_mgt_refclk_out,

    output wire logic [PORT_CNT-1:0]     eth_port_modsell,
    output wire logic [PORT_CNT-1:0]     eth_port_resetl,
    input  wire logic [PORT_CNT-1:0]     eth_port_modprsl,
    input  wire logic [PORT_CNT-1:0]     eth_port_intl,
    output wire logic [PORT_CNT-1:0]     eth_port_lpmode
);

// UART
for (genvar n = 0; n < UART_CNT; n = n + 1) begin : uart_ch

    taxi_axis_if #(.DATA_W(8)) axis_uart();

    taxi_uart
    uart_inst (
        .clk(clk_125mhz),
        .rst(rst_125mhz),

        /*
         * AXI4-Stream input (sink)
         */
        .s_axis_tx(axis_uart),

        /*
         * AXI4-Stream output (source)
         */
        .m_axis_rx(axis_uart),

        /*
         * UART interface
         */
        .rxd(uart_rxd[n]),
        .txd(uart_txd[n]),

        /*
         * Status
         */
        .tx_busy(),
        .rx_busy(),
        .rx_overrun_error(),
        .rx_frame_error(),

        /*
         * Configuration
         */
        .prescale(16'(125000000/115200))
    );

end

// Ethernet
assign eth_port_modsell = '1;
assign eth_port_resetl = '1;
assign eth_port_lpmode = '0;

wire [GTY_CNT-1:0] eth_gty_tx_clk;
wire [GTY_CNT-1:0] eth_gty_tx_rst;
taxi_axis_if #(.DATA_W(64), .ID_W(8)) eth_gty_axis_tx[GTY_CNT]();
taxi_axis_if #(.DATA_W(96), .KEEP_W(1), .ID_W(8)) eth_gty_axis_tx_cpl[GTY_CNT]();

wire [GTY_CNT-1:0] eth_gty_rx_clk;
wire [GTY_CNT-1:0] eth_gty_rx_rst;
taxi_axis_if #(.DATA_W(64), .ID_W(8)) eth_gty_axis_rx[GTY_CNT]();

taxi_axis_if #(.DATA_W(16), .KEEP_W(1), .KEEP_EN(0), .LAST_EN(0), .USER_EN(1), .USER_W(1), .ID_EN(1), .ID_W(8)) eth_gty_axis_stat[GTY_QUAD_CNT]();

wire [GTY_CNT-1:0] eth_gty_rx_status;

wire [GTY_QUAD_CNT-1:0] eth_gty_gtpowergood;

wire [GTY_CLK_CNT-1:0] eth_gty_mgt_refclk;
wire [GTY_CLK_CNT-1:0] eth_gty_mgt_refclk_bufg;

wire [GTY_CLK_CNT-1:0] eth_gty_rst;

for (genvar n = 0; n < GTY_CLK_CNT; n = n + 1) begin : gty_clk

    wire eth_gty_mgt_refclk_int;

    if (SIM) begin

        assign eth_gty_mgt_refclk[n] = eth_gty_mgt_refclk_p[n];
        assign eth_gty_mgt_refclk_int = eth_gty_mgt_refclk_p[n];
        assign eth_gty_mgt_refclk_bufg[n] = eth_gty_mgt_refclk_int;

    end else begin

        IBUFDS_GTE4 ibufds_gte4_eth_gty_mgt_refclk_inst (
            .I     (eth_gty_mgt_refclk_p[n]),
            .IB    (eth_gty_mgt_refclk_n[n]),
            .CEB   (1'b0),
            .O     (eth_gty_mgt_refclk[n]),
            .ODIV2 (eth_gty_mgt_refclk_int)
        );

        BUFG_GT bufg_gt_eth_gty_mgt_refclk_inst (
            .CE      (&eth_gty_gtpowergood),
            .CEMASK  (1'b1),
            .CLR     (1'b0),
            .CLRMASK (1'b1),
            .DIV     (3'd0),
            .I       (eth_gty_mgt_refclk_int),
            .O       (eth_gty_mgt_refclk_bufg[n])
        );

    end

    assign eth_gty_mgt_refclk_out[n] = eth_gty_mgt_refclk_bufg[n];

    taxi_sync_reset #(
        .N(4)
    )
    qsfp_sync_reset_inst (
        .clk(eth_gty_mgt_refclk_bufg[n]),
        .rst(rst_125mhz),
        .out(eth_gty_rst[n])
    );

end

for (genvar n = 0; n < GTY_QUAD_CNT; n = n + 1) begin : gty_quad

    localparam CLK = n;
    localparam CNT = 4;

    taxi_eth_mac_25g_us #(
        .SIM(SIM),
        .VENDOR(VENDOR),
        .FAMILY(FAMILY),

        .CNT(CNT),

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
        .STAT_EN(1'b0)
    )
    mac_inst (
        .xcvr_ctrl_clk(clk_125mhz),
        .xcvr_ctrl_rst(eth_gty_rst[CLK]),

        /*
         * Common
         */
        .xcvr_gtpowergood_out(eth_gty_gtpowergood[n]),
        .xcvr_gtrefclk00_in(eth_gty_mgt_refclk[CLK]),
        .xcvr_qpll0lock_out(),
        .xcvr_qpll0clk_out(),
        .xcvr_qpll0refclk_out(),

        /*
         * Serial data
         */
        .xcvr_txp(eth_gty_tx_p[n*CNT +: CNT]),
        .xcvr_txn(eth_gty_tx_n[n*CNT +: CNT]),
        .xcvr_rxp(eth_gty_rx_p[n*CNT +: CNT]),
        .xcvr_rxn(eth_gty_rx_n[n*CNT +: CNT]),

        /*
         * MAC clocks
         */
        .rx_clk(eth_gty_rx_clk[n*CNT +: CNT]),
        .rx_rst_in('0),
        .rx_rst_out(eth_gty_rx_rst[n*CNT +: CNT]),
        .tx_clk(eth_gty_tx_clk[n*CNT +: CNT]),
        .tx_rst_in('0),
        .tx_rst_out(eth_gty_tx_rst[n*CNT +: CNT]),
        .ptp_sample_clk('0),

        /*
         * Transmit interface (AXI stream)
         */
        .s_axis_tx(eth_gty_axis_tx[n*CNT +: CNT]),
        .m_axis_tx_cpl(eth_gty_axis_tx_cpl[n*CNT +: CNT]),

        /*
         * Receive interface (AXI stream)
         */
        .m_axis_rx(eth_gty_axis_rx[n*CNT +: CNT]),

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
        .m_axis_stat(eth_gty_axis_stat[n]),

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
        .rx_status(eth_gty_rx_status[n*CNT +: CNT]),
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

for (genvar n = 0; n < GTY_CNT; n = n + 1) begin : gty_ch

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
        .s_clk(eth_gty_rx_clk[n]),
        .s_rst(eth_gty_rx_rst[n]),
        .s_axis(eth_gty_axis_rx[n]),

        /*
         * AXI4-Stream output (source)
         */
        .m_clk(eth_gty_tx_clk[n]),
        .m_rst(eth_gty_tx_rst[n]),
        .m_axis(eth_gty_axis_tx[n]),

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
