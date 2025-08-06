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
 * Zircon IP stack - TX egress module
 */
module zircon_ip_tx_egress #
(
    parameter logic IPV6_EN = 1'b1
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * Internal interfaces
     */
    taxi_axis_if.snk   s_axis_pkt,
    taxi_axis_if.snk   s_axis_meta,

    /*
     * MAC interfaces
     */
    input  wire logic  mac_tx_clk,
    input  wire logic  mac_tx_rst,
    taxi_axis_if.src   m_axis_mac_tx,
    taxi_axis_if.snk   s_axis_mac_tx_cpl
);

localparam MAC_DATA_W = m_axis_mac_tx.DATA_W;
localparam TX_USER_W = m_axis_mac_tx.USER_W;
localparam TX_TAG_W = m_axis_mac_tx.ID_W;
localparam DATA_W = s_axis_pkt.DATA_W;
localparam META_DATA_W = s_axis_meta.DATA_W;

taxi_axis_if #(.DATA_W(32), .USER_EN(1), .USER_W(TX_USER_W), .ID_EN(1), .ID_W(TX_TAG_W)) tx_pkt_hdr();
taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(TX_USER_W), .ID_EN(1), .ID_W(TX_TAG_W)) pkt_parts[2]();
taxi_axis_if #(.DATA_W(DATA_W), .USER_EN(1), .USER_W(TX_USER_W), .ID_EN(1), .ID_W(TX_TAG_W)) mac_tx_int();

// build header
zircon_ip_tx_deparse #(
    .IPV6_EN(IPV6_EN)
)
tx_deparse_inst (
    .clk(clk),
    .rst(rst),

    /*
     * Packet metadata input
     */
    .s_axis_meta(s_axis_meta),

    /*
     * Packet header output
     */
    .m_axis_pkt(tx_pkt_hdr)
);

taxi_axis_adapter
hdr_adapter_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI4-Stream input (sink)
     */
    .s_axis(tx_pkt_hdr),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(pkt_parts[0])
);

assign pkt_parts[1].tdata = s_axis_pkt.tdata;
assign pkt_parts[1].tkeep = s_axis_pkt.tkeep;
assign pkt_parts[1].tstrb = s_axis_pkt.tstrb;
assign pkt_parts[1].tvalid = s_axis_pkt.tvalid;
assign pkt_parts[1].tlast = s_axis_pkt.tlast;
assign pkt_parts[1].tid = s_axis_pkt.tid;
assign pkt_parts[1].tdest = s_axis_pkt.tdest;
assign pkt_parts[1].tuser = s_axis_pkt.tuser;

assign s_axis_pkt.tready = pkt_parts[1].tready;

// combine header and payload
taxi_axis_concat #(
    .S_COUNT(2)
)
tx_hdr_concat_inst (
    .clk(clk),
    .rst(rst),


    /*
     * AXI4-Stream inputs (sinks)
     */
    .s_axis(pkt_parts),

    /*
     * AXI4-Stream output (source)
     */
    .m_axis(mac_tx_int)
);

// TX FIFO
taxi_axis_async_fifo #(
    .DEPTH((MAC_DATA_W > DATA_W ? MAC_DATA_W : DATA_W)/8*32),
    .RAM_PIPELINE(1),
    .OUTPUT_FIFO_EN(1'b0),
    .FRAME_FIFO(1'b1),
    .USER_BAD_FRAME_VALUE(1'b1),
    .USER_BAD_FRAME_MASK(1'b1),
    .DROP_OVERSIZE_FRAME(1'b0),
    .DROP_BAD_FRAME(1'b0),
    .DROP_WHEN_FULL(1'b0),
    .MARK_WHEN_FULL(1'b0),
    .PAUSE_EN(1'b0)
)
tx_fifo_inst (
    /*
     * AXI4-Stream input (sink)
     */
    .s_clk(clk),
    .s_rst(rst),
    .s_axis(mac_tx_int),

    /*
     * AXI4-Stream output (source)
     */
    .m_clk(mac_tx_clk),
    .m_rst(mac_tx_rst),
    .m_axis(m_axis_mac_tx),

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

endmodule

`resetall
