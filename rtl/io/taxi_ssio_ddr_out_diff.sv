// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2016-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Generic source synchronous DDR output
 */
module taxi_ssio_ddr_out_diff #
(
    // simulation (set to avoid vendor primitives)
    parameter logic SIM = 1'b0,
    // vendor ("GENERIC", "XILINX", "ALTERA")
    parameter VENDOR = "XILINX",
    // device family
    parameter FAMILY = "virtex7",
    // Use 90 degree clock for transmit
    parameter logic USE_CLK90 = 1'b1,
    // Width of register in bits
    parameter WIDTH = 1
)
(
    input  wire logic              clk,
    input  wire logic              clk90,

    input  wire logic [WIDTH-1:0]  input_d1,
    input  wire logic [WIDTH-1:0]  input_d2,

    output wire logic              output_clk_p,
    output wire logic              output_clk_n,
    output wire logic [WIDTH-1:0]  output_q_p,
    output wire logic [WIDTH-1:0]  output_q_n
);

wire output_clk;
wire [WIDTH-1:0] output_q;

taxi_ssio_ddr_out #(
    .SIM(SIM),
    .VENDOR(VENDOR),
    .FAMILY(FAMILY),
    .USE_CLK90(USE_CLK90),
    .WIDTH(WIDTH)
)
ssio_ddr_out_inst(
    .clk(clk),
    .clk90(clk90),
    .input_d1(input_d1),
    .input_d2(input_d2),
    .output_clk(output_clk),
    .output_q(output_q)
);

if (!SIM && VENDOR == "XILINX") begin
    // Xilinx/AMD device support

    OBUFDS
    clk_obufds_inst (
        .I(output_clk),
        .O(output_clk_p),
        .OB(output_clk_n)
    );

    for (genvar n = 0; n < WIDTH; n = n + 1) begin
        OBUFDS
        data_obufds_inst (
            .I(output_q[n]),
            .O(output_q_p[n]),
            .OB(output_q_n[n])
        );
    end

end else if (!SIM && VENDOR == "ALTERA") begin
    // Altera/Intel/Altera device support

    ALT_OUTBUF_DIFF
    clk_outbuf_diff_inst (
        .i(output_clk),
        .o(output_clk_p),
        .obar(output_clk_n)
    );

    for (genvar n = 0; n < WIDTH; n = n + 1) begin
        ALT_OUTBUF_DIFF
        data_outbuf_diff_inst (
            .i(output_q[n]),
            .o(output_q_p[n]),
            .obar(output_q_n[n])
        );
    end

end else begin
    // generic/simulation implementation (no vendor primitives)

    assign output_clk_p = output_clk;
    assign output_clk_n = ~output_clk;
    assign output_q_p = output_q;
    assign output_q_n = ~output_q;

end

endmodule

`resetall
