// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2019-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * XFCP AXI lite module
 */
module taxi_xfcp_mod_axil #
(
    parameter logic [15:0] XFCP_ID_TYPE = 16'h8001,
    parameter XFCP_ID_STR = "AXIL Master",
    parameter logic [8*16-1:0] XFCP_EXT_ID = 0,
    parameter XFCP_EXT_ID_STR = "",
    parameter COUNT_SIZE = 16
)
(
    input  wire logic    clk,
    input  wire logic    rst,

    /*
     * XFCP upstream port
     */
    taxi_axis_if.snk     up_xfcp_in,
    taxi_axis_if.src     up_xfcp_out,

    /*
     * AXI lite master interface
     */
    taxi_axil_if.wr_mst  m_axil_wr,
    taxi_axil_if.rd_mst  m_axil_rd
);

// TODO various refactoring to fix width issues, among other things
// verilator lint_off WIDTH

localparam DATA_W = m_axil_wr.DATA_W;
localparam ADDR_W = m_axil_wr.ADDR_W;
localparam STRB_W = m_axil_wr.STRB_W;

// for interfaces that are more than one word wide, disable address lines
localparam VALID_ADDR_W = ADDR_W - $clog2(STRB_W);
// width of data port in words
localparam BYTE_LANES = STRB_W;
// size of words
localparam BYTE_W = DATA_W/BYTE_LANES;

localparam BYTE_AW = $clog2((BYTE_W+7)/8);
localparam WORD_AW = BYTE_AW + $clog2(STRB_W);

localparam BYTE_AM = {1'b0, {BYTE_AW{1'b1}}};
localparam WORD_AM = {1'b0, {WORD_AW{1'b1}}};

localparam ADDR_W_ADJ = ADDR_W+BYTE_AW;

localparam COUNT_BYTE_LANES = (COUNT_SIZE+8-1)/8;
localparam ADDR_BYTE_LANES = (ADDR_W_ADJ+8-1)/8;

// check configuration
if (BYTE_LANES * BYTE_W != DATA_W)
    $fatal(0, "Error: AXI data width not evenly divisible (instance %m)");

if (2**$clog2(BYTE_LANES) != BYTE_LANES)
    $fatal(0, "Error: AXI word width must be even power of two (instance %m)");

if (8*2**$clog2(BYTE_W/8) != BYTE_W)
    $fatal(0, "Error: AXI word size must be a power of two multiple of 8 (instance %m)");

localparam START_TAG = 8'hFF;
localparam RPATH_TAG = 8'hFE;
localparam READ_REQ = 8'h10;
localparam READ_RESP = 8'h11;
localparam WRITE_REQ = 8'h12;
localparam WRITE_RESP = 8'h13;
localparam ID_REQ = 8'hFE;
localparam ID_RESP = 8'hFF;

// ID ROM
localparam ID_PTR_W = (XFCP_EXT_ID != 0 || XFCP_EXT_ID_STR != 0) ? 6 : 5;
localparam ID_ROM_SIZE = 2**ID_PTR_W;
reg [7:0] id_rom[ID_ROM_SIZE];

reg [ID_PTR_W-1:0] id_ptr_reg = '0, id_ptr_next;

integer j;

initial begin
    // init ID ROM
    for (integer i = 0; i < ID_ROM_SIZE; i = i + 1) begin
        id_rom[i] = 0;
    end

    // binary part
    {id_rom[1], id_rom[0]} = 16'h8000 | XFCP_ID_TYPE; // module type
    {id_rom[3], id_rom[2]} = 16'(ADDR_W); // address bus width
    {id_rom[5], id_rom[4]} = 16'(DATA_W); // data bus width
    {id_rom[7], id_rom[6]} = 16'(BYTE_W); // word size
    {id_rom[9], id_rom[8]} = 16'(COUNT_SIZE); // count size

    // string part
    // find string length
    j = 0;
    for (integer i = 1; i <= 16; i = i + 1) begin
        if (j == i-1 && (XFCP_ID_STR >> (i*8)) > 0) begin
            j = i;
        end
    end

    // pack string
    for (integer i = 0; i <= j; i = i + 1) begin
        id_rom[i+16] = XFCP_ID_STR[8*(j-i) +: 8];
    end

    if (XFCP_EXT_ID != 0 || XFCP_EXT_ID_STR != 0) begin
        // extended ID

        // binary part
        for (integer i = 0; i < 16; i = i + 1) begin
            id_rom[i+32] = XFCP_EXT_ID[8*i +: 8];
        end

        // string part
        // find string length
        j = 0;
        for (integer i = 1; i <= 16; i = i + 1) begin
            if (j == i-1 && (XFCP_EXT_ID_STR >> (i*8)) > 0) begin
                j = i;
            end
        end

        // pack string
        for (integer i = 0; i <= j; i = i + 1) begin
            id_rom[i+48] = XFCP_EXT_ID_STR[8*(j-i) +: 8];
        end
    end
end

localparam [3:0]
    STATE_IDLE = 4'd0,
    STATE_HEADER_1 = 4'd1,
    STATE_HEADER_2 = 4'd2,
    STATE_HEADER_3 = 4'd3,
    STATE_READ_1 = 4'd4,
    STATE_READ_2 = 4'd5,
    STATE_WRITE_1 = 4'd6,
    STATE_WRITE_2 = 4'd7,
    STATE_WAIT_LAST = 4'd8,
    STATE_ID = 4'd9;

logic [3:0] state_reg = STATE_IDLE, state_next;

logic [COUNT_SIZE-1:0] ptr_reg = '0, ptr_next;
logic [7:0] count_reg = 8'd0, count_next;
logic last_cycle_reg = 1'b0;
logic write_reg = 1'b0, write_next;

logic [ADDR_W_ADJ-1:0] addr_reg = '0, addr_next;
logic [DATA_W-1:0] data_reg = '0, data_next;

logic up_xfcp_in_tready_reg = 1'b0, up_xfcp_in_tready_next;

logic m_axil_awvalid_reg = 1'b0, m_axil_awvalid_next;
logic [STRB_W-1:0] m_axil_wstrb_reg = '0, m_axil_wstrb_next;
logic m_axil_wvalid_reg = 1'b0, m_axil_wvalid_next;
logic m_axil_bready_reg = 1'b0, m_axil_bready_next;
logic m_axil_arvalid_reg = 1'b0, m_axil_arvalid_next;
logic m_axil_rready_reg = 1'b0, m_axil_rready_next;

// internal datapath
logic [7:0]  up_xfcp_out_tdata_int;
logic        up_xfcp_out_tvalid_int;
logic        up_xfcp_out_tready_int_reg = 1'b0;
logic        up_xfcp_out_tlast_int;
logic        up_xfcp_out_tuser_int;
wire         up_xfcp_out_tready_int_early;

assign up_xfcp_in.tready = up_xfcp_in_tready_reg;

assign m_axil_wr.awaddr = addr_reg;
assign m_axil_wr.awprot = 3'b010;
assign m_axil_wr.awuser = '0;
assign m_axil_wr.awvalid = m_axil_awvalid_reg;
assign m_axil_wr.wdata = data_reg;
assign m_axil_wr.wstrb = m_axil_wstrb_reg;
assign m_axil_wr.wuser = '0;
assign m_axil_wr.wvalid = m_axil_wvalid_reg;
assign m_axil_wr.bready = m_axil_bready_reg;

assign m_axil_rd.araddr = addr_reg;
assign m_axil_rd.arprot = 3'b010;
assign m_axil_rd.aruser = '0;
assign m_axil_rd.arvalid = m_axil_arvalid_reg;
assign m_axil_rd.rready = m_axil_rready_reg;

always_comb begin
    state_next = STATE_IDLE;

    ptr_next = ptr_reg;
    count_next = count_reg;
    write_next = write_reg;

    id_ptr_next = id_ptr_reg;

    up_xfcp_in_tready_next = 1'b0;

    up_xfcp_out_tdata_int = '0;
    up_xfcp_out_tvalid_int = 1'b0;
    up_xfcp_out_tlast_int = 1'b0;
    up_xfcp_out_tuser_int = 1'b0;

    addr_next = addr_reg;
    data_next = data_reg;

    m_axil_awvalid_next = m_axil_awvalid_reg && !m_axil_wr.awready;
    m_axil_wstrb_next = m_axil_wstrb_reg;
    m_axil_wvalid_next = m_axil_wvalid_reg && !m_axil_wr.wready;
    m_axil_bready_next = 1'b0;
    m_axil_arvalid_next = m_axil_arvalid_reg && !m_axil_rd.arready;
    m_axil_rready_next = 1'b0;

    case (state_reg)
        STATE_IDLE: begin
            // idle, wait for start of packet
            up_xfcp_in_tready_next = up_xfcp_out_tready_int_early;
            id_ptr_next = '0;

            if (up_xfcp_in.tready && up_xfcp_in.tvalid) begin
                if (up_xfcp_in.tlast) begin
                    // last asserted, ignore cycle
                    state_next = STATE_IDLE;
                end else if (up_xfcp_in.tdata == RPATH_TAG) begin
                    // need to pass through rpath
                    up_xfcp_out_tdata_int = up_xfcp_in.tdata;
                    up_xfcp_out_tvalid_int = 1'b1;
                    up_xfcp_out_tlast_int = 1'b0;
                    up_xfcp_out_tuser_int = 1'b0;
                    state_next = STATE_HEADER_1;
                end else if (up_xfcp_in.tdata == START_TAG) begin
                    // process header
                    up_xfcp_out_tdata_int = up_xfcp_in.tdata;
                    up_xfcp_out_tvalid_int = 1'b1;
                    up_xfcp_out_tlast_int = 1'b0;
                    up_xfcp_out_tuser_int = 1'b0;
                    state_next = STATE_HEADER_2;
                end else begin
                    // bad start byte, drop packet
                    state_next = STATE_WAIT_LAST;
                end
            end else begin
                state_next = STATE_IDLE;
            end
        end
        STATE_HEADER_1: begin
            // transfer through header
            up_xfcp_in_tready_next = up_xfcp_out_tready_int_early;

            if (up_xfcp_in.tready && up_xfcp_in.tvalid) begin
                // transfer through
                up_xfcp_out_tdata_int = up_xfcp_in.tdata;
                up_xfcp_out_tvalid_int = 1'b1;
                up_xfcp_out_tlast_int = 1'b0;
                up_xfcp_out_tuser_int = 1'b0;

                if (up_xfcp_in.tlast) begin
                    // last asserted in header, mark as such and drop
                    up_xfcp_out_tuser_int = 1'b1;
                    state_next = STATE_IDLE;
                end else if (up_xfcp_in.tdata == START_TAG) begin
                    // process header
                    state_next = STATE_HEADER_2;
                end else begin
                    state_next = STATE_HEADER_1;
                end
            end else begin
                state_next = STATE_HEADER_1;
            end
        end
        STATE_HEADER_2: begin
            // read packet type
            up_xfcp_in_tready_next = up_xfcp_out_tready_int_early;

            if (up_xfcp_in.tready && up_xfcp_in.tvalid) begin
                if (up_xfcp_in.tdata == READ_REQ && !up_xfcp_in.tlast) begin
                    // start of read
                    up_xfcp_out_tdata_int = READ_RESP;
                    up_xfcp_out_tvalid_int = 1'b1;
                    up_xfcp_out_tlast_int = 1'b0;
                    up_xfcp_out_tuser_int = 1'b0;
                    write_next = 1'b0;
                    count_next = 8'(COUNT_BYTE_LANES+ADDR_BYTE_LANES-1);
                    state_next = STATE_HEADER_3;
                end else if (up_xfcp_in.tdata == WRITE_REQ && !up_xfcp_in.tlast) begin
                    // start of write
                    up_xfcp_out_tdata_int = WRITE_RESP;
                    up_xfcp_out_tvalid_int = 1'b1;
                    up_xfcp_out_tlast_int = 1'b0;
                    up_xfcp_out_tuser_int = 1'b0;
                    write_next = 1'b1;
                    count_next = 8'(COUNT_BYTE_LANES+ADDR_BYTE_LANES-1);
                    state_next = STATE_HEADER_3;
                end else if (up_xfcp_in.tdata == ID_REQ) begin
                    // identify
                    up_xfcp_out_tdata_int = ID_RESP;
                    up_xfcp_out_tvalid_int = 1'b1;
                    up_xfcp_out_tlast_int = 1'b0;
                    up_xfcp_out_tuser_int = 1'b0;
                    state_next = STATE_ID;
                end else begin
                    // invalid start of packet
                    up_xfcp_out_tvalid_int = 1'b1;
                    up_xfcp_out_tlast_int = 1'b1;
                    up_xfcp_out_tuser_int = 1'b1;
                    if (up_xfcp_in.tlast) begin
                        state_next = STATE_IDLE;
                    end else begin
                        state_next = STATE_WAIT_LAST;
                    end
                end
            end else begin
                state_next = STATE_HEADER_2;
            end
        end
        STATE_HEADER_3: begin
            // store address and length
            up_xfcp_in_tready_next = up_xfcp_out_tready_int_early;

            if (up_xfcp_in.tready && up_xfcp_in.tvalid) begin
                // pass through
                up_xfcp_out_tdata_int = up_xfcp_in.tdata;
                up_xfcp_out_tvalid_int = 1'b1;
                up_xfcp_out_tlast_int = 1'b0;
                up_xfcp_out_tuser_int = 1'b0;
                // store pointers
                if (count_reg < COUNT_BYTE_LANES) begin
                    ptr_next[8*(COUNT_BYTE_LANES-count_reg-1) +: 8] = up_xfcp_in.tdata;
                end else begin
                    addr_next[8*(ADDR_BYTE_LANES-(count_reg-COUNT_BYTE_LANES)-1) +: 8] = up_xfcp_in.tdata;
                end
                count_next = count_reg - 1;
                if (count_reg == 0) begin
                    // end of header
                    // set initial word offset
                    count_next = addr_reg & WORD_AM;
                    m_axil_wstrb_next = '0;
                    data_next = '0;
                    if (write_reg) begin
                        // start writing
                        if (up_xfcp_in.tlast) begin
                            // end of frame in header
                            up_xfcp_out_tlast_int = 1'b1;
                            up_xfcp_out_tuser_int = 1'b1;
                            state_next = STATE_IDLE;
                        end else begin
                            up_xfcp_out_tlast_int = 1'b1;
                            state_next = STATE_WRITE_1;
                        end
                    end else begin
                        // start reading
                        up_xfcp_in_tready_next = !(last_cycle_reg || (up_xfcp_in.tvalid && up_xfcp_in.tlast));
                        m_axil_arvalid_next = 1'b1;
                        m_axil_rready_next = 1'b1;
                        state_next = STATE_READ_1;
                    end
                end else begin
                    if (up_xfcp_in.tlast) begin
                        // end of frame in header
                        up_xfcp_out_tlast_int = 1'b1;
                        up_xfcp_out_tuser_int = 1'b1;
                        state_next = STATE_IDLE;
                    end else begin
                        state_next = STATE_HEADER_3;
                    end
                end
            end else begin
                state_next = STATE_HEADER_3;
            end
        end
        STATE_READ_1: begin
            // wait for data
            m_axil_rready_next = 1'b1;

            // drop padding
            up_xfcp_in_tready_next = !(last_cycle_reg || (up_xfcp_in.tvalid && up_xfcp_in.tlast));

            if (m_axil_rd.rready && m_axil_rd.rvalid) begin
                // read cycle complete, store result
                m_axil_rready_next = 1'b0;
                data_next = m_axil_rd.rdata;
                addr_next = addr_reg + (1 << (ADDR_W-VALID_ADDR_W+BYTE_AW));
                state_next = STATE_READ_2;
            end else begin
                state_next = STATE_READ_1;
            end
        end
        STATE_READ_2: begin
            // send data

            // drop padding
            up_xfcp_in_tready_next = !(last_cycle_reg || (up_xfcp_in.tvalid && up_xfcp_in.tlast));

            if (up_xfcp_out_tready_int_reg) begin
                // transfer word and update pointers
                up_xfcp_out_tdata_int = data_reg[8*count_reg +: 8];
                up_xfcp_out_tvalid_int = 1'b1;
                up_xfcp_out_tlast_int = 1'b0;
                up_xfcp_out_tuser_int = 1'b0;
                count_next = count_reg + 1;
                ptr_next = ptr_reg - 1;
                if (ptr_reg == 1) begin
                    // last word of read
                    up_xfcp_out_tlast_int = 1'b1;
                    if (!(last_cycle_reg || (up_xfcp_in.tvalid && up_xfcp_in.tlast))) begin
                        state_next = STATE_WAIT_LAST;
                    end else begin
                        up_xfcp_in_tready_next = up_xfcp_out_tready_int_early;
                        state_next = STATE_IDLE;
                    end
                end else if (count_reg == (STRB_W*BYTE_W/8)-1) begin
                    // end of stored data word; read the next one
                    count_next = 0;
                    m_axil_arvalid_next = 1'b1;
                    m_axil_rready_next = 1'b1;
                    state_next = STATE_READ_1;
                end else begin
                    state_next = STATE_READ_2;
                end
            end else begin
                state_next = STATE_READ_2;
            end
        end
        STATE_WRITE_1: begin
            // write data
            up_xfcp_in_tready_next = 1'b1;

            if (up_xfcp_in.tready && up_xfcp_in.tvalid) begin
                // store word
                data_next[8*count_reg +: 8] = up_xfcp_in.tdata;
                count_next = count_reg + 1;
                ptr_next = ptr_reg - 1;
                m_axil_wstrb_next[count_reg >> ((BYTE_W/8)-1)] = 1'b1;
                if (count_reg == (STRB_W*BYTE_W/8)-1 || ptr_reg == 1) begin
                    // have full word or at end of block, start write operation
                    count_next = 0;
                    up_xfcp_in_tready_next = 1'b0;
                    m_axil_awvalid_next = 1'b1;
                    m_axil_wvalid_next = 1'b1;
                    m_axil_bready_next = 1'b1;
                    state_next = STATE_WRITE_2;
                    if (up_xfcp_in.tlast) begin
                        // last asserted, nothing further to write
                        ptr_next = 0;
                    end
                end else if (up_xfcp_in.tlast) begin
                    // last asserted, return to idle
                    state_next = STATE_IDLE;
                end else begin
                    state_next = STATE_WRITE_1;
                end
            end else begin
                state_next = STATE_WRITE_1;
            end
        end
        STATE_WRITE_2: begin
            // wait for write completion
            m_axil_bready_next = 1'b1;

            if (m_axil_wr.bready && m_axil_wr.bvalid) begin
                // end of write operation
                data_next = '0;
                addr_next = addr_reg + (1 << (ADDR_W-VALID_ADDR_W+BYTE_AW));
                m_axil_bready_next = 1'b0;
                m_axil_wstrb_next = '0;
                if (ptr_reg == 0) begin
                    // done writing
                    if (!last_cycle_reg) begin
                        up_xfcp_in_tready_next = 1'b1;
                        state_next = STATE_WAIT_LAST;
                    end else begin
                        up_xfcp_in_tready_next = up_xfcp_out_tready_int_early;
                        state_next = STATE_IDLE;
                    end
                end else begin
                    // more to write
                    state_next = STATE_WRITE_1;
                end
            end else begin
                state_next = STATE_WRITE_2;
            end
        end
        STATE_ID: begin
            // send ID

            // drop padding
            up_xfcp_in_tready_next = !(last_cycle_reg || (up_xfcp_in.tvalid && up_xfcp_in.tlast));

            up_xfcp_out_tdata_int = id_rom[id_ptr_reg];
            up_xfcp_out_tvalid_int = 1'b1;
            up_xfcp_out_tlast_int = 1'b0;
            up_xfcp_out_tuser_int = 1'b0;

            if (up_xfcp_out_tready_int_reg) begin
                // increment pointer
                id_ptr_next = id_ptr_reg + 1;
                if (id_ptr_reg == ID_PTR_W'(ID_ROM_SIZE-1)) begin
                    // read out whole ID
                    up_xfcp_out_tlast_int = 1'b1;
                    if (!(last_cycle_reg || (up_xfcp_in.tvalid && up_xfcp_in.tlast))) begin
                        state_next = STATE_WAIT_LAST;
                    end else begin
                        up_xfcp_in_tready_next = up_xfcp_out_tready_int_early;
                        state_next = STATE_IDLE;
                    end
                end else begin
                    state_next = STATE_ID;
                end
            end else begin
                state_next = STATE_ID;
            end
        end
        STATE_WAIT_LAST: begin
            // wait for end of frame
            up_xfcp_in_tready_next = 1'b1;

            if (up_xfcp_in.tready && up_xfcp_in.tvalid) begin
                // wait for tlast
                if (up_xfcp_in.tlast) begin
                    up_xfcp_in_tready_next = up_xfcp_out_tready_int_early;
                    state_next = STATE_IDLE;
                end else begin
                    state_next = STATE_WAIT_LAST;
                end
            end else begin
                state_next = STATE_WAIT_LAST;
            end
        end
        default: begin
            // return to idle
            state_next = STATE_IDLE;
        end
    endcase
end

always_ff @(posedge clk) begin
    state_reg <= state_next;

    id_ptr_reg <= id_ptr_next;

    ptr_reg <= ptr_next;
    count_reg <= count_next;
    write_reg <= write_next;

    if (up_xfcp_in.tready && up_xfcp_in.tvalid) begin
        last_cycle_reg <= up_xfcp_in.tlast;
    end

    addr_reg <= addr_next;
    data_reg <= data_next;

    up_xfcp_in_tready_reg <= up_xfcp_in_tready_next;

    m_axil_awvalid_reg <= m_axil_awvalid_next;
    m_axil_wstrb_reg <= m_axil_wstrb_next;
    m_axil_wvalid_reg <= m_axil_wvalid_next;
    m_axil_bready_reg <= m_axil_bready_next;
    m_axil_arvalid_reg <= m_axil_arvalid_next;
    m_axil_rready_reg <= m_axil_rready_next;

    if (rst) begin
        state_reg <= STATE_IDLE;
        up_xfcp_in_tready_reg <= 1'b0;
        m_axil_awvalid_reg <= 1'b0;
        m_axil_wvalid_reg <= 1'b0;
        m_axil_bready_reg <= 1'b0;
        m_axil_arvalid_reg <= 1'b0;
        m_axil_rready_reg <= 1'b0;
    end
end

// output datapath logic
logic [7:0]  up_xfcp_out_tdata_reg = '0;
logic        up_xfcp_out_tvalid_reg = 1'b0, up_xfcp_out_tvalid_next;
logic        up_xfcp_out_tlast_reg = 1'b0;
logic        up_xfcp_out_tuser_reg = 1'b0;

logic [7:0]  temp_up_xfcp_tdata_reg = '0;
logic        temp_up_xfcp_tvalid_reg = 1'b0, temp_up_xfcp_tvalid_next;
logic        temp_up_xfcp_tlast_reg = 1'b0;
logic        temp_up_xfcp_tuser_reg = 1'b0;

// datapath control
reg store_up_xfcp_int_to_output;
reg store_up_xfcp_int_to_temp;
reg store_up_xfcp_temp_to_output;

assign up_xfcp_out.tdata = up_xfcp_out_tdata_reg;
assign up_xfcp_out.tkeep = '1;
assign up_xfcp_out.tstrb = up_xfcp_out.tkeep;
assign up_xfcp_out.tvalid = up_xfcp_out_tvalid_reg;
assign up_xfcp_out.tlast = up_xfcp_out_tlast_reg;
assign up_xfcp_out.tid = '0;
assign up_xfcp_out.tdest = '0;
assign up_xfcp_out.tuser = up_xfcp_out_tuser_reg;

// enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
assign up_xfcp_out_tready_int_early = up_xfcp_out.tready || (!temp_up_xfcp_tvalid_reg && (!up_xfcp_out_tvalid_reg || !up_xfcp_out_tvalid_int));

always_comb begin
    // transfer sink ready state to source
    up_xfcp_out_tvalid_next = up_xfcp_out_tvalid_reg;
    temp_up_xfcp_tvalid_next = temp_up_xfcp_tvalid_reg;

    store_up_xfcp_int_to_output = 1'b0;
    store_up_xfcp_int_to_temp = 1'b0;
    store_up_xfcp_temp_to_output = 1'b0;
    
    if (up_xfcp_out_tready_int_reg) begin
        // input is ready
        if (up_xfcp_out.tready || !up_xfcp_out_tvalid_reg) begin
            // output is ready or currently not valid, transfer data to output
            up_xfcp_out_tvalid_next = up_xfcp_out_tvalid_int;
            store_up_xfcp_int_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_up_xfcp_tvalid_next = up_xfcp_out_tvalid_int;
            store_up_xfcp_int_to_temp = 1'b1;
        end
    end else if (up_xfcp_out.tready) begin
        // input is not ready, but output is ready
        up_xfcp_out_tvalid_next = temp_up_xfcp_tvalid_reg;
        temp_up_xfcp_tvalid_next = 1'b0;
        store_up_xfcp_temp_to_output = 1'b1;
    end
end

always_ff @(posedge clk) begin
    up_xfcp_out_tvalid_reg <= up_xfcp_out_tvalid_next;
    up_xfcp_out_tready_int_reg <= up_xfcp_out_tready_int_early;
    temp_up_xfcp_tvalid_reg <= temp_up_xfcp_tvalid_next;

    // datapath
    if (store_up_xfcp_int_to_output) begin
        up_xfcp_out_tdata_reg <= up_xfcp_out_tdata_int;
        up_xfcp_out_tlast_reg <= up_xfcp_out_tlast_int;
        up_xfcp_out_tuser_reg <= up_xfcp_out_tuser_int;
    end else if (store_up_xfcp_temp_to_output) begin
        up_xfcp_out_tdata_reg <= temp_up_xfcp_tdata_reg;
        up_xfcp_out_tlast_reg <= temp_up_xfcp_tlast_reg;
        up_xfcp_out_tuser_reg <= temp_up_xfcp_tuser_reg;
    end

    if (store_up_xfcp_int_to_temp) begin
        temp_up_xfcp_tdata_reg <= up_xfcp_out_tdata_int;
        temp_up_xfcp_tlast_reg <= up_xfcp_out_tlast_int;
        temp_up_xfcp_tuser_reg <= up_xfcp_out_tuser_int;
    end

    if (rst) begin
        up_xfcp_out_tvalid_reg <= 1'b0;
        up_xfcp_out_tready_int_reg <= 1'b0;
        temp_up_xfcp_tvalid_reg <= 1'b0;
    end 
end

endmodule

`resetall
