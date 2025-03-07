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
 * Transceiver and MAC/PHY quad wrapper for UltraScale/UltraScale+
 */
module taxi_eth_mac_25g_us #
(
    parameter logic SIM = 1'b0,
    parameter string VENDOR = "XILINX",
    parameter string FAMILY = "virtexuplus",

    parameter CNT = 4,

    // GT type
    parameter string GT_TYPE = "GTY",

    // GT parameters
    parameter logic [CNT-1:0] GT_TX_POLARITY = '0,
    parameter logic [CNT-1:0] GT_RX_POLARITY = '0,

    // MAC/PHY parameters
    parameter logic PADDING_EN = 1'b1,
    parameter logic DIC_EN = 1'b1,
    parameter MIN_FRAME_LEN = 64,
    parameter logic PTP_TS_EN = 1'b0,
    parameter logic PTP_TS_FMT_TOD = 1'b1,
    parameter PTP_TS_W = PTP_TS_FMT_TOD ? 96 : 64,
    parameter logic PRBS31_EN = 1'b0,
    parameter TX_SERDES_PIPELINE = 1,
    parameter RX_SERDES_PIPELINE = 1,
    parameter BITSLIP_HIGH_CYCLES = 0,
    parameter BITSLIP_LOW_CYCLES = 7,
    parameter COUNT_125US = 125000/6.4
)
(
    input  wire logic                 xcvr_ctrl_clk,
    input  wire logic                 xcvr_ctrl_rst,

    /*
     * Common
     */
    output wire logic                 xcvr_gtpowergood_out,
    input  wire logic                 xcvr_gtrefclk00_in,
    output wire logic                 xcvr_qpll0lock_out,
    output wire logic                 xcvr_qpll0clk_out,
    output wire logic                 xcvr_qpll0refclk_out,

    /*
     * Serial data
     */
    output wire logic [CNT-1:0]       xcvr_txp,
    output wire logic [CNT-1:0]       xcvr_txn,
    input  wire logic [CNT-1:0]       xcvr_rxp,
    input  wire logic [CNT-1:0]       xcvr_rxn,

    /*
     * MAC clocks
     */
    output wire logic [CNT-1:0]       rx_clk,
    input  wire logic [CNT-1:0]       rx_rst_in,
    output wire logic [CNT-1:0]       rx_rst_out,
    output wire logic [CNT-1:0]       tx_clk,
    input  wire logic [CNT-1:0]       tx_rst_in,
    output wire logic [CNT-1:0]       tx_rst_out,
    input  wire logic [CNT-1:0]       ptp_sample_clk,

    /*
     * Transmit interface (AXI stream)
     */
    taxi_axis_if.snk                  s_axis_tx[CNT],
    taxi_axis_if.src                  m_axis_tx_cpl[CNT],

    /*
     * Receive interface (AXI stream)
     */
    taxi_axis_if.src                  m_axis_rx[CNT],

    /*
     * PTP clock
     */
    input  wire logic [PTP_TS_W-1:0]  tx_ptp_ts[CNT] = '{CNT{'0}},
    input  wire logic [CNT-1:0]       tx_ptp_ts_step = '0,
    input  wire logic [PTP_TS_W-1:0]  rx_ptp_ts[CNT] = '{CNT{'0}},
    input  wire logic [CNT-1:0]       rx_ptp_ts_step = '0,

    /*
     * Link-level Flow Control (LFC) (IEEE 802.3 annex 31B PAUSE)
     */
    input  wire logic [CNT-1:0]       tx_lfc_req = '0,
    input  wire logic [CNT-1:0]       tx_lfc_resend = '0,
    input  wire logic [CNT-1:0]       rx_lfc_en = '0,
    output wire logic [CNT-1:0]       rx_lfc_req,
    input  wire logic [CNT-1:0]       rx_lfc_ack = '0,

    /*
     * Priority Flow Control (PFC) (IEEE 802.3 annex 31D PFC)
     */
    input  wire logic [7:0]           tx_pfc_req[CNT] = '{CNT{'0}},
    input  wire logic [CNT-1:0]       tx_pfc_resend = '0,
    input  wire logic [7:0]           rx_pfc_en[CNT] = '{CNT{'0}},
    output wire logic [7:0]           rx_pfc_req[CNT],
    input  wire logic [7:0]           rx_pfc_ack[CNT] = '{CNT{'0}},

    /*
     * Pause interface
     */
    input  wire logic [CNT-1:0]       tx_lfc_pause_en = '0,
    input  wire logic [CNT-1:0]       tx_pause_req = '0,
    output wire logic [CNT-1:0]       tx_pause_ack,

    /*
     * Status
     */
    output wire logic [1:0]           tx_start_packet[CNT],
    output wire logic [CNT-1:0]       tx_error_underflow,
    output wire logic [1:0]           rx_start_packet[CNT],
    output wire logic [6:0]           rx_error_count[CNT],
    output wire logic [CNT-1:0]       rx_error_bad_frame,
    output wire logic [CNT-1:0]       rx_error_bad_fcs,
    output wire logic [CNT-1:0]       rx_bad_block,
    output wire logic [CNT-1:0]       rx_sequence_error,
    output wire logic [CNT-1:0]       rx_block_lock,
    output wire logic [CNT-1:0]       rx_high_ber,
    output wire logic [CNT-1:0]       rx_status,
    output wire logic [CNT-1:0]       stat_tx_mcf,
    output wire logic [CNT-1:0]       stat_rx_mcf,
    output wire logic [CNT-1:0]       stat_tx_lfc_pkt,
    output wire logic [CNT-1:0]       stat_tx_lfc_xon,
    output wire logic [CNT-1:0]       stat_tx_lfc_xoff,
    output wire logic [CNT-1:0]       stat_tx_lfc_paused,
    output wire logic [CNT-1:0]       stat_tx_pfc_pkt,
    output wire logic [7:0]           stat_tx_pfc_xon[CNT],
    output wire logic [7:0]           stat_tx_pfc_xoff[CNT],
    output wire logic [7:0]           stat_tx_pfc_paused[CNT],
    output wire logic [CNT-1:0]       stat_rx_lfc_pkt,
    output wire logic [CNT-1:0]       stat_rx_lfc_xon,
    output wire logic [CNT-1:0]       stat_rx_lfc_xoff,
    output wire logic [CNT-1:0]       stat_rx_lfc_paused,
    output wire logic [CNT-1:0]       stat_rx_pfc_pkt,
    output wire logic [7:0]           stat_rx_pfc_xon[CNT],
    output wire logic [7:0]           stat_rx_pfc_xoff[CNT],
    output wire logic [7:0]           stat_rx_pfc_paused[CNT],

    /*
     * Configuration
     */
    input  wire logic [7:0]           cfg_ifg[CNT] = '{CNT{8'd12}},
    input  wire logic [CNT-1:0]       cfg_tx_enable = '1,
    input  wire logic [CNT-1:0]       cfg_rx_enable = '1,
    input  wire logic [CNT-1:0]       cfg_tx_prbs31_enable = '0,
    input  wire logic [CNT-1:0]       cfg_rx_prbs31_enable = '0,
    input  wire logic [47:0]          cfg_mcf_rx_eth_dst_mcast[CNT] = '{CNT{48'h01_80_C2_00_00_01}},
    input  wire logic [CNT-1:0]       cfg_mcf_rx_check_eth_dst_mcast = '1,
    input  wire logic [47:0]          cfg_mcf_rx_eth_dst_ucast[CNT] = '{CNT{48'd0}},
    input  wire logic [CNT-1:0]       cfg_mcf_rx_check_eth_dst_ucast = '0,
    input  wire logic [47:0]          cfg_mcf_rx_eth_src[CNT] = '{CNT{48'd0}},
    input  wire logic [CNT-1:0]       cfg_mcf_rx_check_eth_src = '0,
    input  wire logic [15:0]          cfg_mcf_rx_eth_type[CNT] = '{CNT{16'h8808}},
    input  wire logic [15:0]          cfg_mcf_rx_opcode_lfc[CNT] = '{CNT{16'h0001}},
    input  wire logic [CNT-1:0]       cfg_mcf_rx_check_opcode_lfc = '1,
    input  wire logic [15:0]          cfg_mcf_rx_opcode_pfc[CNT] = '{CNT{16'h0101}},
    input  wire logic [CNT-1:0]       cfg_mcf_rx_check_opcode_pfc = '1,
    input  wire logic [CNT-1:0]       cfg_mcf_rx_forward = '0,
    input  wire logic [CNT-1:0]       cfg_mcf_rx_enable = '0,
    input  wire logic [47:0]          cfg_tx_lfc_eth_dst[CNT] = '{CNT{48'h01_80_C2_00_00_01}},
    input  wire logic [47:0]          cfg_tx_lfc_eth_src[CNT] = '{CNT{48'h80_23_31_43_54_4C}},
    input  wire logic [15:0]          cfg_tx_lfc_eth_type[CNT] = '{CNT{16'h8808}},
    input  wire logic [15:0]          cfg_tx_lfc_opcode[CNT] = '{CNT{16'h0001}},
    input  wire logic [CNT-1:0]       cfg_tx_lfc_en = '0,
    input  wire logic [15:0]          cfg_tx_lfc_quanta[CNT] = '{CNT{16'hffff}},
    input  wire logic [15:0]          cfg_tx_lfc_refresh[CNT] = '{CNT{16'h7fff}},
    input  wire logic [47:0]          cfg_tx_pfc_eth_dst[CNT] = '{CNT{48'h01_80_C2_00_00_01}},
    input  wire logic [47:0]          cfg_tx_pfc_eth_src[CNT] = '{CNT{48'h80_23_31_43_54_4C}},
    input  wire logic [15:0]          cfg_tx_pfc_eth_type[CNT] = '{CNT{16'h8808}},
    input  wire logic [15:0]          cfg_tx_pfc_opcode[CNT] = '{CNT{16'h0101}},
    input  wire logic [CNT-1:0]       cfg_tx_pfc_en = '0,
    input  wire logic [15:0]          cfg_tx_pfc_quanta[CNT][8] = '{CNT{'{8{16'hffff}}}},
    input  wire logic [15:0]          cfg_tx_pfc_refresh[CNT][8] = '{CNT{'{8{16'h7fff}}}},
    input  wire logic [15:0]          cfg_rx_lfc_opcode[CNT] = '{CNT{16'h0001}},
    input  wire logic [CNT-1:0]       cfg_rx_lfc_en = '0,
    input  wire logic [15:0]          cfg_rx_pfc_opcode[CNT] = '{CNT{16'h0101}},
    input  wire logic [CNT-1:0]       cfg_rx_pfc_en = '0
);

for (genvar n = 0; n < CNT; n = n + 1) begin : ch

    localparam HAS_COMMON = n == 0;

    wire ch_gtpowergood_out;

    wire ch_qpll0lock_out;
    wire ch_qpll0clk_out;
    wire ch_qpll0refclk_out;

    if (HAS_COMMON) begin
        // drive outputs from common
        assign xcvr_gtpowergood_out = ch_gtpowergood_out;

        assign xcvr_qpll0lock_out = ch_qpll0lock_out;
        assign xcvr_qpll0clk_out = ch_qpll0clk_out;
        assign xcvr_qpll0refclk_out = ch_qpll0refclk_out;
    end

    taxi_eth_mac_25g_us_ch #(
        .SIM(SIM),
        .VENDOR(VENDOR),
        .FAMILY(FAMILY),

        .HAS_COMMON(HAS_COMMON),

        // GT type
        .GT_TYPE(GT_TYPE),

        // GT parameters
        .GT_TX_POLARITY(GT_TX_POLARITY[n]),
        .GT_RX_POLARITY(GT_RX_POLARITY[n]),

        // MAC/PHY parameters
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
        .COUNT_125US(COUNT_125US)
    )
    ch_inst (
        .xcvr_ctrl_clk(xcvr_ctrl_clk),
        .xcvr_ctrl_rst(xcvr_ctrl_rst),

        /*
         * Common
         */
        .xcvr_gtpowergood_out(ch_gtpowergood_out),

        /*
         * PLL out
         */
        .xcvr_gtrefclk00_in(xcvr_gtrefclk00_in),
        .xcvr_qpll0lock_out(ch_qpll0lock_out),
        .xcvr_qpll0clk_out(ch_qpll0clk_out),
        .xcvr_qpll0refclk_out(ch_qpll0refclk_out),

        /*
         * PLL in
         */
        .xcvr_qpll0lock_in(xcvr_qpll0lock_out),
        .xcvr_qpll0reset_out(),
        .xcvr_qpll0clk_in(xcvr_qpll0clk_out),
        .xcvr_qpll0refclk_in(xcvr_qpll0refclk_out),

        /*
         * Serial data
         */
        .xcvr_txp(xcvr_txp[n]),
        .xcvr_txn(xcvr_txn[n]),
        .xcvr_rxp(xcvr_rxp[n]),
        .xcvr_rxn(xcvr_rxn[n]),

        /*
         * MAC clocks
         */
        .rx_clk(rx_clk[n]),
        .rx_rst_in(rx_rst_in[n]),
        .rx_rst_out(rx_rst_out[n]),
        .tx_clk(tx_clk[n]),
        .tx_rst_in(tx_rst_in[n]),
        .tx_rst_out(tx_rst_out[n]),
        .ptp_sample_clk(ptp_sample_clk[n]),

        /*
         * Transmit interface (AXI stream)
         */
        .s_axis_tx(s_axis_tx[n]),
        .m_axis_tx_cpl(m_axis_tx_cpl[n]),

        /*
         * Receive interface (AXI stream)
         */
        .m_axis_rx(m_axis_rx[n]),

        /*
         * PTP clock
         */
        .tx_ptp_ts(tx_ptp_ts[n]),
        .tx_ptp_ts_step(tx_ptp_ts_step[n]),
        .rx_ptp_ts(rx_ptp_ts[n]),
        .rx_ptp_ts_step(rx_ptp_ts_step[n]),

        /*
         * Link-level Flow Control (LFC) (IEEE 802.3 annex 31B PAUSE)
         */
        .tx_lfc_req(tx_lfc_req[n]),
        .tx_lfc_resend(tx_lfc_resend[n]),
        .rx_lfc_en(rx_lfc_en[n]),
        .rx_lfc_req(rx_lfc_req[n]),
        .rx_lfc_ack(rx_lfc_ack[n]),

        /*
         * Priority Flow Control (PFC) (IEEE 802.3 annex 31D PFC)
         */
        .tx_pfc_req(tx_pfc_req[n]),
        .tx_pfc_resend(tx_pfc_resend[n]),
        .rx_pfc_en(rx_pfc_en[n]),
        .rx_pfc_req(rx_pfc_req[n]),
        .rx_pfc_ack(rx_pfc_ack[n]),

        /*
         * Pause interface
         */
        .tx_lfc_pause_en(tx_lfc_pause_en[n]),
        .tx_pause_req(tx_pause_req[n]),
        .tx_pause_ack(tx_pause_ack[n]),

        /*
         * Status
         */
        .tx_start_packet(tx_start_packet[n]),
        .tx_error_underflow(tx_error_underflow[n]),
        .rx_start_packet(rx_start_packet[n]),
        .rx_error_count(rx_error_count[n]),
        .rx_error_bad_frame(rx_error_bad_frame[n]),
        .rx_error_bad_fcs(rx_error_bad_fcs[n]),
        .rx_bad_block(rx_bad_block[n]),
        .rx_sequence_error(rx_sequence_error[n]),
        .rx_block_lock(rx_block_lock[n]),
        .rx_high_ber(rx_high_ber[n]),
        .rx_status(rx_status[n]),
        .stat_tx_mcf(stat_tx_mcf[n]),
        .stat_rx_mcf(stat_rx_mcf[n]),
        .stat_tx_lfc_pkt(stat_tx_lfc_pkt[n]),
        .stat_tx_lfc_xon(stat_tx_lfc_xon[n]),
        .stat_tx_lfc_xoff(stat_tx_lfc_xoff[n]),
        .stat_tx_lfc_paused(stat_tx_lfc_paused[n]),
        .stat_tx_pfc_pkt(stat_tx_pfc_pkt[n]),
        .stat_tx_pfc_xon(stat_tx_pfc_xon[n]),
        .stat_tx_pfc_xoff(stat_tx_pfc_xoff[n]),
        .stat_tx_pfc_paused(stat_tx_pfc_paused[n]),
        .stat_rx_lfc_pkt(stat_rx_lfc_pkt[n]),
        .stat_rx_lfc_xon(stat_rx_lfc_xon[n]),
        .stat_rx_lfc_xoff(stat_rx_lfc_xoff[n]),
        .stat_rx_lfc_paused(stat_rx_lfc_paused[n]),
        .stat_rx_pfc_pkt(stat_rx_pfc_pkt[n]),
        .stat_rx_pfc_xon(stat_rx_pfc_xon[n]),
        .stat_rx_pfc_xoff(stat_rx_pfc_xoff[n]),
        .stat_rx_pfc_paused(stat_rx_pfc_paused[n]),

        /*
         * Configuration
         */
        .cfg_ifg(cfg_ifg[n]),
        .cfg_tx_enable(cfg_tx_enable[n]),
        .cfg_rx_enable(cfg_rx_enable[n]),
        .cfg_tx_prbs31_enable(cfg_tx_prbs31_enable[n]),
        .cfg_rx_prbs31_enable(cfg_rx_prbs31_enable[n]),
        .cfg_mcf_rx_eth_dst_mcast(cfg_mcf_rx_eth_dst_mcast[n]),
        .cfg_mcf_rx_check_eth_dst_mcast(cfg_mcf_rx_check_eth_dst_mcast[n]),
        .cfg_mcf_rx_eth_dst_ucast(cfg_mcf_rx_eth_dst_ucast[n]),
        .cfg_mcf_rx_check_eth_dst_ucast(cfg_mcf_rx_check_eth_dst_ucast[n]),
        .cfg_mcf_rx_eth_src(cfg_mcf_rx_eth_src[n]),
        .cfg_mcf_rx_check_eth_src(cfg_mcf_rx_check_eth_src[n]),
        .cfg_mcf_rx_eth_type(cfg_mcf_rx_eth_type[n]),
        .cfg_mcf_rx_opcode_lfc(cfg_mcf_rx_opcode_lfc[n]),
        .cfg_mcf_rx_check_opcode_lfc(cfg_mcf_rx_check_opcode_lfc[n]),
        .cfg_mcf_rx_opcode_pfc(cfg_mcf_rx_opcode_pfc[n]),
        .cfg_mcf_rx_check_opcode_pfc(cfg_mcf_rx_check_opcode_pfc[n]),
        .cfg_mcf_rx_forward(cfg_mcf_rx_forward[n]),
        .cfg_mcf_rx_enable(cfg_mcf_rx_enable[n]),
        .cfg_tx_lfc_eth_dst(cfg_tx_lfc_eth_dst[n]),
        .cfg_tx_lfc_eth_src(cfg_tx_lfc_eth_src[n]),
        .cfg_tx_lfc_eth_type(cfg_tx_lfc_eth_type[n]),
        .cfg_tx_lfc_opcode(cfg_tx_lfc_opcode[n]),
        .cfg_tx_lfc_en(cfg_tx_lfc_en[n]),
        .cfg_tx_lfc_quanta(cfg_tx_lfc_quanta[n]),
        .cfg_tx_lfc_refresh(cfg_tx_lfc_refresh[n]),
        .cfg_tx_pfc_eth_dst(cfg_tx_pfc_eth_dst[n]),
        .cfg_tx_pfc_eth_src(cfg_tx_pfc_eth_src[n]),
        .cfg_tx_pfc_eth_type(cfg_tx_pfc_eth_type[n]),
        .cfg_tx_pfc_opcode(cfg_tx_pfc_opcode[n]),
        .cfg_tx_pfc_en(cfg_tx_pfc_en[n]),
        .cfg_tx_pfc_quanta(cfg_tx_pfc_quanta[n]),
        .cfg_tx_pfc_refresh(cfg_tx_pfc_refresh[n]),
        .cfg_rx_lfc_opcode(cfg_rx_lfc_opcode[n]),
        .cfg_rx_lfc_en(cfg_rx_lfc_en[n]),
        .cfg_rx_pfc_opcode(cfg_rx_pfc_opcode[n]),
        .cfg_rx_pfc_en(cfg_rx_pfc_en[n])
    );

end

endmodule

`resetall
