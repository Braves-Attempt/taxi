// SPDX-License-Identifier: CERN-OHL-S-2.0
/*

Copyright (c) 2017-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

*/

`timescale 1ns / 1ps

/*
 * XFCP 1xN switch
 */
module taxi_xfcp_switch #
(
    parameter PORTS = 4,
    parameter logic [15:0] XFCP_ID_TYPE = 16'h0100,
    parameter XFCP_ID_STR = "XFCP Switch",
    parameter logic [8*16-1:0] XFCP_EXT_ID = 0,
    parameter XFCP_EXT_ID_STR = ""
)
(
    input  wire logic  clk,
    input  wire logic  rst,

    /*
     * XFCP upstream port
     */
    taxi_axis_if.snk   up_xfcp_in,
    taxi_axis_if.src   up_xfcp_out,

    /*
     * XFCP downstream ports
     */
    taxi_axis_if.snk   dn_xfcp_in[PORTS],
    taxi_axis_if.src   dn_xfcp_out[PORTS]
);

parameter CL_PORTS = PORTS > 1 ? $clog2(PORTS) : 1;
parameter CL_PORTS_P1 = $clog2(PORTS+1);

// check configuration
if (PORTS < 1 || PORTS > 256)
    $fatal(0, "Error: PORTS out of range; must be between 1 and 256");

localparam START_TAG = 8'hFF;
localparam RPATH_TAG = 8'hFE;
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
    {id_rom[1], id_rom[0]} = 16'h0100 | (XFCP_ID_TYPE & 16'h00FF); // module type (switch)
    id_rom[2] = 8'd1; // upstream port count
    id_rom[3] = 8'(PORTS); // downstream port count

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

localparam [2:0]
    DN_STATE_IDLE = 3'd0,
    DN_STATE_TRANSFER = 3'd1,
    DN_STATE_HEADER = 3'd2,
    DN_STATE_PKT = 3'd3,
    DN_STATE_ID = 3'd4;

reg [2:0] dn_state_reg = DN_STATE_IDLE, dn_state_next;

localparam [0:0]
    UP_STATE_IDLE = 1'd0,
    UP_STATE_TRANSFER = 1'd1;

reg [0:0] up_state_reg = UP_STATE_IDLE, up_state_next;

reg [CL_PORTS-1:0] dn_select_reg = '0, dn_select_next;
reg dn_frame_reg = 1'b0, dn_frame_next;
reg dn_enable_reg = 1'b0, dn_enable_next;

reg [CL_PORTS_P1-1:0] up_select_reg = '0, up_select_next;
reg up_frame_reg = 1'b0, up_frame_next;

reg up_xfcp_in_tready_reg = 1'b0, up_xfcp_in_tready_next;

reg [PORTS-1:0] dn_xfcp_in_tready_reg = '0, dn_xfcp_in_tready_next;

wire [PORTS-1:0] dn_xfcp_out_tready;
wire [PORTS-1:0] dn_xfcp_out_tvalid;

// internal datapath
reg [7:0] up_xfcp_out_tdata_int;
reg       up_xfcp_out_tvalid_int;
reg       up_xfcp_out_tready_int_reg = 1'b0;
reg       up_xfcp_out_tlast_int;
reg       up_xfcp_out_tuser_int;
wire      up_xfcp_out_tready_int_early;

reg [7:0]       dn_xfcp_out_tdata_int;
reg [PORTS-1:0] dn_xfcp_out_tvalid_int;
reg             dn_xfcp_out_tready_int_reg = 1'b0;
reg             dn_xfcp_out_tlast_int;
reg             dn_xfcp_out_tuser_int;
wire            dn_xfcp_out_tready_int_early;

reg [7:0] int_loop_tdata_reg = 8'd0, int_loop_tdata_next;
reg       int_loop_tvalid_reg = 1'b0, int_loop_tvalid_next;
reg       int_loop_tready;
reg       int_loop_tready_early;
reg       int_loop_tlast_reg = 1'b0, int_loop_tlast_next;
reg       int_loop_tuser_reg = 1'b0, int_loop_tuser_next;

assign up_xfcp_in.tready = up_xfcp_in_tready_reg;

// unpack interface array
wire [PORTS+1-1:0]  dn_xfcp_in_tready;
wire [7:0]          dn_xfcp_in_tdata[PORTS+1];
wire [PORTS+1-1:0]  dn_xfcp_in_tvalid;
wire [PORTS+1-1:0]  dn_xfcp_in_tlast;
wire                dn_xfcp_in_tuser[PORTS+1];

for (genvar n = 0; n < PORTS; n = n + 1) begin
    assign dn_xfcp_in_tdata[n] = dn_xfcp_in[n].tdata;
    assign dn_xfcp_in_tvalid[n] = dn_xfcp_in[n].tvalid;
    assign dn_xfcp_in[n].tready = dn_xfcp_in_tready_reg[n];
    assign dn_xfcp_in_tlast[n] = dn_xfcp_in[n].tlast;
    assign dn_xfcp_in_tuser[n] = dn_xfcp_in[n].tuser;

    assign dn_xfcp_in_tready[n] = dn_xfcp_in[n].tready;
end

assign dn_xfcp_in_tdata[PORTS] = int_loop_tdata_reg;
assign dn_xfcp_in_tvalid[PORTS] = int_loop_tvalid_reg;
assign dn_xfcp_in_tlast[PORTS] = int_loop_tlast_reg;
assign dn_xfcp_in_tuser[PORTS] = int_loop_tuser_reg;

assign dn_xfcp_in_tready[PORTS] = int_loop_tready;

// mux for downstream output control signals
wire current_output_tvalid = dn_xfcp_out_tvalid[dn_select_reg];
wire current_output_tready = dn_xfcp_out_tready[dn_select_reg];

// mux for incoming downstream packet
wire [7:0] current_input_tdata  = dn_xfcp_in_tdata[up_select_reg];
wire       current_input_tvalid = dn_xfcp_in_tvalid[up_select_reg];
wire       current_input_tready = dn_xfcp_in_tready[up_select_reg];
wire       current_input_tlast  = dn_xfcp_in_tlast[up_select_reg];
wire       current_input_tuser  = dn_xfcp_in_tuser[up_select_reg];

// downstream control logic
always_comb begin
    dn_state_next = DN_STATE_IDLE;

    dn_select_next = dn_select_reg;
    dn_frame_next = dn_frame_reg;
    dn_enable_next = dn_enable_reg;

    id_ptr_next = id_ptr_reg;

    up_xfcp_in_tready_next = 1'b0;

    dn_xfcp_out_tdata_int = up_xfcp_in.tdata;
    dn_xfcp_out_tvalid_int = PORTS'(up_xfcp_in.tvalid && up_xfcp_in.tready && dn_enable_reg) << dn_select_reg;
    dn_xfcp_out_tlast_int = up_xfcp_in.tlast;
    dn_xfcp_out_tuser_int = up_xfcp_in.tuser;

    int_loop_tdata_next = int_loop_tdata_reg;
    int_loop_tvalid_next = int_loop_tvalid_reg && !int_loop_tready;
    int_loop_tlast_next = int_loop_tlast_reg;
    int_loop_tuser_next = int_loop_tuser_reg;

    if (up_xfcp_in.tready & up_xfcp_in.tvalid) begin
        // end of frame detection
        if (up_xfcp_in.tlast) begin
            dn_frame_next = 1'b0;
            dn_enable_next = 1'b0;
        end
    end

    case (dn_state_reg)
        DN_STATE_IDLE: begin
            // wait for incoming upstream packet
            up_xfcp_in_tready_next = 1'b1;
            id_ptr_next = '0;

            if (!dn_frame_reg && up_xfcp_in.tready && up_xfcp_in.tvalid) begin
                // start of frame
                dn_frame_next = 1'b1;
                if (up_xfcp_in.tdata == RPATH_TAG || up_xfcp_in.tdata == START_TAG) begin
                    // packet for us

                    int_loop_tdata_next = up_xfcp_in.tdata;
                    int_loop_tvalid_next = up_xfcp_in.tvalid;
                    int_loop_tlast_next = up_xfcp_in.tlast;
                    int_loop_tuser_next = up_xfcp_in.tuser;

                    up_xfcp_in_tready_next = int_loop_tready_early;

                    if (up_xfcp_in.tdata == RPATH_TAG) begin
                        // has rpath
                        dn_state_next = DN_STATE_HEADER;
                    end else begin
                        // no rpath
                        dn_state_next = DN_STATE_PKT;
                    end
                end else begin
                    // route packet
                    dn_enable_next = 1'b1;
                    dn_select_next = CL_PORTS'(up_xfcp_in.tdata);
                    up_xfcp_in_tready_next = dn_xfcp_out_tready_int_early;
                    dn_state_next = DN_STATE_TRANSFER;
                    if (up_xfcp_in.tdata >= 8'(PORTS)) begin
                        // out of range
                        dn_enable_next = 1'b0;
                    end
                end
            end else begin
                dn_state_next = DN_STATE_IDLE;
            end
        end
        DN_STATE_TRANSFER: begin
            // transfer upstream packet through proper downstream port
            if (up_xfcp_in.tready && up_xfcp_in.tvalid) begin
                // end of frame detection
                if (up_xfcp_in.tlast) begin
                    dn_frame_next = 1'b0;
                    dn_enable_next = 1'b0;
                    dn_state_next = DN_STATE_IDLE;
                end else begin
                    dn_state_next = DN_STATE_TRANSFER;
                end
            end else begin
                dn_state_next = DN_STATE_TRANSFER;
            end
            up_xfcp_in_tready_next = dn_xfcp_out_tready_int_early && dn_frame_next;
        end
        DN_STATE_HEADER: begin
            // loop back header

            up_xfcp_in_tready_next = int_loop_tready_early;

            if (up_xfcp_in.tready && up_xfcp_in.tvalid) begin
                int_loop_tdata_next = up_xfcp_in.tdata;
                int_loop_tvalid_next = 1'b1;
                int_loop_tlast_next = up_xfcp_in.tlast;
                int_loop_tuser_next = up_xfcp_in.tuser;

                // end of header detection
                if (up_xfcp_in.tdata == START_TAG) begin
                    dn_state_next = DN_STATE_PKT;
                end else begin
                    dn_state_next = DN_STATE_HEADER;
                end
            end else begin
                dn_state_next = DN_STATE_HEADER;
            end
        end
        DN_STATE_PKT: begin
            // packet type

            up_xfcp_in_tready_next = int_loop_tready_early;

            if (up_xfcp_in.tready && up_xfcp_in.tvalid) begin
                int_loop_tdata_next = up_xfcp_in.tdata;
                int_loop_tvalid_next = 1'b1;
                int_loop_tlast_next = up_xfcp_in.tlast;
                int_loop_tuser_next = up_xfcp_in.tuser;

                if (up_xfcp_in.tdata == ID_REQ) begin
                    // ID packet
                    int_loop_tdata_next = ID_RESP;
                    int_loop_tlast_next = 1'b0;
                    dn_state_next = DN_STATE_ID;
                end else begin
                    // something else
                    int_loop_tlast_next = 1'b1;
                    int_loop_tuser_next = 1'b1;
                    dn_state_next = DN_STATE_IDLE;
                end
            end else begin
                dn_state_next = DN_STATE_PKT;
            end
        end
        DN_STATE_ID: begin
            // send ID

            up_xfcp_in_tready_next = dn_frame_next;

            if (int_loop_tready) begin
                int_loop_tdata_next = id_rom[id_ptr_reg];
                int_loop_tvalid_next = 1'b1;
                int_loop_tlast_next = 1'b0;
                int_loop_tuser_next = 1'b0;

                id_ptr_next = id_ptr_reg + 1;
                if (id_ptr_reg == ID_ROM_SIZE-1) begin
                    int_loop_tlast_next = 1'b1;
                    dn_state_next = DN_STATE_IDLE;
                end else begin
                    dn_state_next = DN_STATE_ID;
                end
            end else begin
                dn_state_next = DN_STATE_ID;
            end
        end
        default: begin
            dn_state_next = DN_STATE_IDLE;
        end
    endcase
end

// upstream control logic
wire [PORTS+1-1:0] req;
wire [PORTS+1-1:0] ack;
wire [PORTS+1-1:0] grant;
wire grant_valid;
wire [CL_PORTS_P1-1:0] grant_index;

// arbiter instance
taxi_arbiter #(
    .PORTS(PORTS+1),
    .ARB_ROUND_ROBIN(1),
    .ARB_BLOCK(1),
    .ARB_BLOCK_ACK(1),
    .LSB_HIGH_PRIO(1)
)
arb_inst (
    .clk(clk),
    .rst(rst),
    .req(req),
    .ack(ack),
    .grant(grant),
    .grant_valid(grant_valid),
    .grant_index(grant_index)
);

assign req = dn_xfcp_in_tvalid & ~grant;
assign ack = grant & dn_xfcp_in_tvalid & dn_xfcp_in_tready & dn_xfcp_in_tlast;

always_comb begin
    up_state_next = UP_STATE_IDLE;

    up_select_next = up_select_reg;
    up_frame_next = up_frame_reg;


    up_xfcp_out_tdata_int = current_input_tdata;
    up_xfcp_out_tvalid_int = current_input_tvalid && current_input_tready && up_frame_reg;
    up_xfcp_out_tlast_int = current_input_tlast;
    up_xfcp_out_tuser_int = current_input_tuser;

    if (current_input_tready && current_input_tvalid) begin
        if (current_input_tlast) begin
            // end of frame detection
            up_frame_next = 1'b0;
        end
    end

    case (up_state_reg)
        UP_STATE_IDLE: begin
            // wait for incoming downstream packet
            if (grant_valid && up_xfcp_out_tready_int_reg) begin
                up_frame_next = 1'b1;
                up_select_next = grant_index;
                up_state_next = UP_STATE_TRANSFER;

                if (up_select_next == CL_PORTS_P1'(PORTS)) begin
                    // internal loop; don't add port
                end else begin
                    // prepend port to packet
                    up_xfcp_out_tdata_int = 8'(grant_index);
                    up_xfcp_out_tvalid_int = 1'b1;
                    up_xfcp_out_tlast_int = 1'b0;
                    up_xfcp_out_tuser_int = 1'b0;
                end
            end else begin
                up_state_next = UP_STATE_IDLE;
            end
        end
        UP_STATE_TRANSFER: begin
            // transfer downstream packet out through upstream port
            if (current_input_tvalid && current_input_tready) begin
                if (current_input_tlast) begin
                    up_frame_next = 1'b0;
                    up_state_next = UP_STATE_IDLE;
                end else begin
                    up_state_next = UP_STATE_TRANSFER;
                end
            end else begin
                up_state_next = UP_STATE_TRANSFER;
            end
        end
    endcase
end

always_comb begin
    dn_xfcp_in_tready_next = '0;

    // int_loop_tready_early = 1'b0;

    // generate ready signal on selected port
    if (up_select_next == CL_PORTS_P1'(PORTS)) begin
        // int_loop_tready_early = up_xfcp_out_tready_int_early && up_frame_next;
    end else begin
        dn_xfcp_in_tready_next = PORTS'(up_xfcp_out_tready_int_early && up_frame_next) << up_select_next;
    end
end

always_comb begin
    int_loop_tready_early = up_xfcp_out_tready_int_early && up_frame_next;
end

always_comb begin
    int_loop_tready = up_xfcp_out_tready_int_reg && up_frame_reg;
end

always_ff @(posedge clk) begin
    dn_state_reg <= dn_state_next;
    up_state_reg <= up_state_next;

    id_ptr_reg <= id_ptr_next;

    dn_select_reg <= dn_select_next;
    dn_frame_reg <= dn_frame_next;
    dn_enable_reg <= dn_enable_next;

    up_select_reg <= up_select_next;
    up_frame_reg <= up_frame_next;

    up_xfcp_in_tready_reg <= up_xfcp_in_tready_next;
    dn_xfcp_in_tready_reg <= dn_xfcp_in_tready_next;

    int_loop_tdata_reg <= int_loop_tdata_next;
    int_loop_tvalid_reg <= int_loop_tvalid_next;
    int_loop_tlast_reg <= int_loop_tlast_next;
    int_loop_tuser_reg <= int_loop_tuser_next;

    if (rst) begin
        dn_state_reg <= DN_STATE_IDLE;
        up_state_reg <= UP_STATE_IDLE;
        dn_select_reg <= '0;
        dn_frame_reg <= 1'b0;
        dn_enable_reg <= 1'b0;
        up_select_reg <= '0;
        up_frame_reg <= 1'b0;
        up_xfcp_in_tready_reg <= 1'b0;
        dn_xfcp_in_tready_reg <= '0;
        int_loop_tvalid_reg <= 1'b0;
    end
end

// upstream output datapath logic
reg [7:0]  up_xfcp_out_tdata_reg = 8'd0;
reg        up_xfcp_out_tvalid_reg = 1'b0, up_xfcp_out_tvalid_next;
reg        up_xfcp_out_tlast_reg = 1'b0;
reg        up_xfcp_out_tuser_reg = 1'b0;

reg [7:0]  temp_up_xfcp_tdata_reg = 8'd0;
reg        temp_up_xfcp_tvalid_reg = 1'b0, temp_up_xfcp_tvalid_next;
reg        temp_up_xfcp_tlast_reg = 1'b0;
reg        temp_up_xfcp_tuser_reg = 1'b0;

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
    if (rst) begin
        up_xfcp_out_tvalid_reg <= 1'b0;
        up_xfcp_out_tready_int_reg <= 1'b0;
        temp_up_xfcp_tvalid_reg <= 1'b0;
    end else begin
        up_xfcp_out_tvalid_reg <= up_xfcp_out_tvalid_next;
        up_xfcp_out_tready_int_reg <= up_xfcp_out_tready_int_early;
        temp_up_xfcp_tvalid_reg <= temp_up_xfcp_tvalid_next;
    end

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
end

// downstream output datapath logic
reg [7:0]       dn_xfcp_out_tdata_reg = 8'd0;
reg [PORTS-1:0] dn_xfcp_out_tvalid_reg = '0, dn_xfcp_out_tvalid_next;
reg             dn_xfcp_out_tlast_reg = 1'b0;
reg             dn_xfcp_out_tuser_reg = 1'b0;

reg [7:0]       temp_dn_xfcp_out_tdata_reg = 8'd0;
reg [PORTS-1:0] temp_dn_xfcp_out_tvalid_reg = '0, temp_dn_xfcp_out_tvalid_next;
reg             temp_dn_xfcp_out_tlast_reg = 1'b0;
reg             temp_dn_xfcp_out_tuser_reg = 1'b0;

// datapath control
reg store_dn_xfcp_int_to_output;
reg store_dn_xfcp_int_to_temp;
reg store_dn_xfcp_temp_to_output;

assign dn_xfcp_out_tvalid = dn_xfcp_out_tvalid_reg;

for (genvar k = 0; k < PORTS; k = k + 1) begin
    assign dn_xfcp_out[k].tdata  = dn_xfcp_out_tdata_reg;
    assign dn_xfcp_out[k].tkeep  = '1;
    assign dn_xfcp_out[k].tstrb  = dn_xfcp_out[k].tkeep;
    assign dn_xfcp_out[k].tvalid = dn_xfcp_out_tvalid_reg[k];
    assign dn_xfcp_out[k].tlast  = dn_xfcp_out_tlast_reg;
    assign dn_xfcp_out[k].tid    = '0;
    assign dn_xfcp_out[k].tdest  = '0;
    assign dn_xfcp_out[k].tuser  = dn_xfcp_out_tuser_reg;

    assign dn_xfcp_out_tready[k] = dn_xfcp_out[k].tready;
end

// enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
assign dn_xfcp_out_tready_int_early = ((dn_xfcp_out_tready & dn_xfcp_out_tvalid) != 0) || ((temp_dn_xfcp_out_tvalid_reg == 0) && ((dn_xfcp_out_tvalid == 0) || (dn_xfcp_out_tvalid_int == 0)));

always_comb begin
    // transfer sink ready state to source
    dn_xfcp_out_tvalid_next = dn_xfcp_out_tvalid_reg;
    temp_dn_xfcp_out_tvalid_next = temp_dn_xfcp_out_tvalid_reg;

    store_dn_xfcp_int_to_output = 1'b0;
    store_dn_xfcp_int_to_temp = 1'b0;
    store_dn_xfcp_temp_to_output = 1'b0;

    if (dn_xfcp_out_tready_int_reg) begin
        // input is ready
        if (((dn_xfcp_out_tready & dn_xfcp_out_tvalid) != 0) || (dn_xfcp_out_tvalid == 0)) begin
            // output is ready or currently not valid, transfer data to output
            dn_xfcp_out_tvalid_next = dn_xfcp_out_tvalid_int;
            store_dn_xfcp_int_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_dn_xfcp_out_tvalid_next = dn_xfcp_out_tvalid_int;
            store_dn_xfcp_int_to_temp = 1'b1;
        end
    end else if ((dn_xfcp_out_tready & dn_xfcp_out_tvalid) != 0) begin
        // input is not ready, but output is ready
        dn_xfcp_out_tvalid_next = temp_dn_xfcp_out_tvalid_reg;
        temp_dn_xfcp_out_tvalid_next = '0;
        store_dn_xfcp_temp_to_output = 1'b1;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        dn_xfcp_out_tvalid_reg <= '0;
        dn_xfcp_out_tready_int_reg <= 1'b0;
        temp_dn_xfcp_out_tvalid_reg <= '0;
    end else begin
        dn_xfcp_out_tvalid_reg <= dn_xfcp_out_tvalid_next;
        dn_xfcp_out_tready_int_reg <= dn_xfcp_out_tready_int_early;
        temp_dn_xfcp_out_tvalid_reg <= temp_dn_xfcp_out_tvalid_next;
    end

    // datapath
    if (store_dn_xfcp_int_to_output) begin
        dn_xfcp_out_tdata_reg <= dn_xfcp_out_tdata_int;
        dn_xfcp_out_tlast_reg <= dn_xfcp_out_tlast_int;
        dn_xfcp_out_tuser_reg <= dn_xfcp_out_tuser_int;
    end else if (store_dn_xfcp_temp_to_output) begin
        dn_xfcp_out_tdata_reg <= temp_dn_xfcp_out_tdata_reg;
        dn_xfcp_out_tlast_reg <= temp_dn_xfcp_out_tlast_reg;
        dn_xfcp_out_tuser_reg <= temp_dn_xfcp_out_tuser_reg;
    end

    if (store_dn_xfcp_int_to_temp) begin
        temp_dn_xfcp_out_tdata_reg <= dn_xfcp_out_tdata_int;
        temp_dn_xfcp_out_tlast_reg <= dn_xfcp_out_tlast_int;
        temp_dn_xfcp_out_tuser_reg <= dn_xfcp_out_tuser_int;
    end
end

endmodule
