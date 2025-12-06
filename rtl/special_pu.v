`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ACCESS
// Engineer: 
// 
// Create Date: 2023/08/29 21:49:21
// Design Name: 
// Module Name: Special_PU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Parallelism y | x = 16 | 8
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: ACCESS confidential
// 
//////////////////////////////////////////////////////////////////////////////////


//`define FPGA

// should remove, write in xdc
module special_pu #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32
)
(
    // Global Signals definition
    input core_clk, // top spu process clock
    input rst_n, // reset input, active-low

    // Control Interface definition
    input spu_config_en,
    input spu_start, // spu process start (a pulse)
    output spu_end, // spu process ending (a pulse)
    
    // input [255:0] spu_instr, // instruction for the layer of spu, validated by spu_start pulse
    // New inputs
    input spu_op_in,
    input [ADDR_WIDTH-1:0] spu_matrix_y_in,
    input [ADDR_WIDTH-1:0] spu_matrix_x_in,
    input [3:0] shift0_in,
    input [3:0] shift1_in,
    input [4:0] shift2_in,
    input [ADDR_WIDTH-1:0] im_base_addr_in,
    input [ADDR_WIDTH-1:0] om_base_addr_in,
    input [ADDR_WIDTH-1:0] im_block_align_in,
    input [ADDR_WIDTH-1:0] om_block_align_in,
    input [6:0] ln_div_m_in,
    input [4:0] ln_div_e_in,

    // // buffer Interface definition
    // output gbuf_cen,
    // output gbuf_wen,
    // output [ADDR_WIDTH-1:0] gbuf_addr,
    // output [DATA_WIDTH-1:0] gbuf_din,
    // input [DATA_WIDTH-1:0] gbuf_dout
    output gbuf_cen,
    output gbuf_wen,
    output [ADDR_WIDTH-1:0] gbuf_waddr,
    output [ADDR_WIDTH-1:0] gbuf_raddr,
    output [DATA_WIDTH-1:0] gbuf_din,
    input [DATA_WIDTH-1:0] gbuf_dout
);

reg spu_op;
reg [ADDR_WIDTH-1:0] spu_matrix_y;
reg [ADDR_WIDTH-1:0] spu_matrix_x;
reg [3:0] shift0;
reg [3:0] shift1;
reg [4:0] shift2;
reg [ADDR_WIDTH-1:0] im_block_align;
reg [ADDR_WIDTH-1:0] om_block_align;
reg [6:0] ln_div_m;
reg [4:0] ln_div_e;
reg [ADDR_WIDTH-1:0] im_base_addr;
reg [ADDR_WIDTH-1:0] om_base_addr;

always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        spu_op <= 'd0;
        spu_matrix_y <= 'd0;
        spu_matrix_x <= 'd0;
        shift0 <= 'd0;
        shift1 <= 'd0;
        shift2 <= 'd0;
        im_block_align <= 'd0;
        om_block_align <= 'd0;
        ln_div_m <= 'd0;
        ln_div_e <= 'd0;
        im_base_addr <= 'd0;
        om_base_addr <= 'd0;
    end
    else if (spu_config_en) begin
        spu_op <= spu_op_in;
        spu_matrix_y <= spu_matrix_y_in; 
        spu_matrix_x <= spu_matrix_x_in;
        shift0 <= shift0_in;
        shift1 <= shift1_in;
        shift2 <= shift2_in;
        im_block_align <= im_block_align_in;
        om_block_align <= om_block_align_in;
        ln_div_m <= ln_div_m_in;
        ln_div_e <= ln_div_e_in;
        im_base_addr <= im_base_addr_in;
        om_base_addr <= om_base_addr_in;
    end
end

wire [11:0] token_per_block = spu_matrix_y;

wire [ADDR_WIDTH-1:0] ln_gbuf_raddr, sm_gbuf_raddr; // submodule buf rd addr
wire [ADDR_WIDTH-1:0] ln_gbuf_waddr, sm_gbuf_waddr; // submodule buf wr addr
wire ln_gbuf_ren, sm_gbuf_ren; // submodule buf rd en
wire ln_gbuf_wen, sm_gbuf_wen; // submodule buf wr en
wire [DATA_WIDTH-1:0] ln_gbuf_wdata; // submodule buf rd data
wire [DATA_WIDTH-1:0] sm_gbuf_wdata; // submodule buf wr data
reg ln_start, sm_start; // submodule process start
wire ln_end, sm_end; // submodule process end

// submodule start signals, remain the same process as spu_start
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) ln_start <= 1'b0;
    else if (spu_start && spu_op) ln_start <= 1'b1;
    else if (ln_start) ln_start <= 1'b0;
end
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) sm_start <= 1'b0;
    else if (spu_start && !spu_op) sm_start <= 1'b1;
    else if (sm_start) sm_start <= 1'b0;
end

// submodule LayerNorm (LN / ln) instance
spu_ln_top #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
)
u_spu_ln_top (
    .core_clk(core_clk),
    .rst_n(rst_n),
    .ln_start(ln_start),
    .ln_end(ln_end),

    .spu_matrix_y(spu_matrix_y),
    .spu_matrix_x(spu_matrix_x),
    .im_base_addr(im_base_addr),
    .om_base_addr(om_base_addr),
    .ifm_addr_align(im_block_align),
    .ofm_addr_align(om_block_align),
    .ln_shift_output(shift0),
    .ln_div_m(ln_div_m),
    .ln_div_e(ln_div_e),
    
    .ln_gbuf_ren(ln_gbuf_ren),
    .ln_gbuf_raddr(ln_gbuf_raddr),
    .ln_gbuf_rdata(gbuf_dout),
    .ln_gbuf_wen(ln_gbuf_wen),
    .ln_gbuf_waddr(ln_gbuf_waddr),
    .ln_gbuf_wdata(ln_gbuf_wdata)
);

// submodule SoftMax (SM / sm) instance
spu_sm_top #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) u_spu_sm_top (
    .core_clk(core_clk),
    .rst_n(rst_n),
    .sm_start(sm_start),
    .sm_end(sm_end),

    .spu_matrix_y(spu_matrix_y),
    .spu_matrix_x(spu_matrix_x),
    .im_base_addr(im_base_addr),
    .om_base_addr(om_base_addr),
    .ifm_addr_align(im_block_align),
    .ofm_addr_align(om_block_align),
    .sm_shift_input(shift1),
    .sm_exp_shift_output(shift2),
    .sm_shift_output(shift0),

    .sm_gbuf_ren(sm_gbuf_ren),
    .sm_gbuf_raddr(sm_gbuf_raddr),
    .sm_gbuf_rdata(gbuf_dout),
    .sm_gbuf_wen(sm_gbuf_wen),
    .sm_gbuf_waddr(sm_gbuf_waddr),
    .sm_gbuf_wdata(sm_gbuf_wdata)
);



// arbitration

wire gbuf_ren_tmp = spu_op ? ln_gbuf_ren : sm_gbuf_ren;
wire gbuf_wen_tmp = spu_op ? ln_gbuf_wen : sm_gbuf_wen;
wire [ADDR_WIDTH-1:0] gbuf_raddr_tmp = spu_op ? ln_gbuf_raddr : sm_gbuf_raddr;
wire [ADDR_WIDTH-1:0] gbuf_waddr_tmp = spu_op ? ln_gbuf_waddr : sm_gbuf_waddr;
wire [DATA_WIDTH-1:0] gbuf_wdata_tmp = spu_op ? ln_gbuf_wdata : sm_gbuf_wdata;

assign gbuf_cen = ~(gbuf_ren_tmp || gbuf_wen_tmp);
assign gbuf_wen = ~gbuf_wen_tmp;
// assign gbuf_addr = gbuf_ren_tmp ? gbuf_raddr_tmp : gbuf_waddr_tmp;
assign gbuf_raddr = gbuf_raddr_tmp;
assign gbuf_waddr = gbuf_waddr_tmp;
assign gbuf_din = gbuf_wdata_tmp;

assign spu_end = spu_op ? ln_end : sm_end;
endmodule
