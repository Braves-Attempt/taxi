// SPDX-License-Identifier: MIT
/*

Copyright (c) 2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

interface taxi_apb_if #(
    // Width of data bus in bits
    parameter DATA_W = 32,
    // Width of address bus in bits
    parameter ADDR_W = 32,
    // Width of pstrb (width of data bus in words)
    parameter STRB_W = (DATA_W/8)
)
();
    logic [ADDR_W-1:0]  paddr;
    logic [2:0]         pprot;
    logic               psel;
    logic               penable;
    logic               pwrite;
    logic [DATA_W-1:0]  pwdata;
    logic [STRB_W-1:0]  pstrb;
    logic               pready;
    logic [DATA_W-1:0]  prdata;
    logic               pslverr;

    modport mst (
        output paddr,
        output pprot,
        output psel,
        output penable,
        output pwrite,
        output pwdata,
        output pstrb,
        input  pready,
        input  prdata,
        input  pslverr
    );

    modport slv (
        input  paddr,
        input  pprot,
        input  psel,
        input  penable,
        input  pwrite,
        input  pwdata,
        input  pstrb,
        output pready,
        output prdata,
        output pslverr
    );

endinterface
