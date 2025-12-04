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
    parameter RLATENCY = 2, // ren latency, default 2
    parameter RADDR_WIDTH = 13,
    parameter WADDR_WIDTH = 13,
    parameter CACHE_DATA_WIDTH = 16*64
)
(
    // Global Signals definition
    input core_clk, // top spu process clock
    input core_clk_sm, // softmax module clock
    input core_clk_ln, // layernorm module clock
    input rst_n, // reset input, active-low
    // CFG 
    input  wire [1:0] cfg_spubuf_ptsel,
    input  wire [1:0] cfg_spubuf_wtsel,
    input  wire [1:0] cfg_spubuf_rtsel,

    // Control Interface definition
    input spu_start, // spu process start (a pulse)
    output spu_end, // spu process ending (a pulse)
    input [255:0] spu_instr, // instruction for the layer of spu, validated by spu_start pulse

    // fmbuf Interface definition
    output lbuf_ren, // lbuf read enable
    output [RADDR_WIDTH-1:0] lbuf_raddr, // lbuf read address, validated by lbuf_ren
    input [16*64-1:0] lbuf_rdata, // lbuf read data, 2cycle delay from lbuf_ren
    output lbuf_wen, // lbuf write enable
    output [WADDR_WIDTH-1:0] lbuf_waddr, // lbuf write address, validated by lbuf_wen
    output [16*64-1:0] lbuf_wdata // lbuf write data, validated by lbuf_wen
);
// global 
localparam LN_MAX_CHANNEL_DEPTH = 11; //  2^11 = 2048
localparam SM_MAX_CHANNEL_DEPTH = 12; //  2^12 = 4096, but considering other ops after read, should be 8192-1, therefore no need to -1 for bitwidth in cnts
localparam CACHE_DATA_DEPTH = SM_MAX_CHANNEL_DEPTH - 3;
localparam CACHE_RLATENCY = 2;


// instr structure definition, w.r.t instr excel
localparam OP_START_BIT = 3;
localparam OP_END_BIT = 0;
localparam SPU_OP_START_BIT = 4;
localparam SPU_OP_END_BIT = 4;
localparam SPU_SM_OP_START_BIT = 6;
localparam SPU_SM_OP_END_BIT = 6;
localparam SPU_LN_OP_START_BIT = 7;
localparam SPU_LN_OP_END_BIT = 7;
localparam MATRIX_Y_START_BIT = 23;
localparam MATRIX_Y_END_BIT = 8;
localparam MATRIX_X_H_START_BIT = 34; // new
localparam MATRIX_X_H_END_BIT = 24; // new
localparam MATRIX_X_W_START_BIT = 46; // new
localparam MATRIX_X_W_END_BIT = 35; // new
localparam SHIFT_0_START_BIT = 50;
localparam SHIFT_0_END_BIT = 47;
localparam SHIFT_1_START_BIT = 54;
localparam SHIFT_1_END_BIT = 51;
localparam SHIFT_2_START_BIT = 59;
localparam SHIFT_2_END_BIT = 55;
localparam LN_DIV_M_START_BIT = 66; // new
localparam LN_DIV_M_END_BIT = 60; // new
localparam LN_DIV_E_START_BIT = 71; // new
localparam LN_DIV_E_END_BIT = 67; // new
localparam IFM_BASE_ADDR_START_BIT = 87;
localparam IFM_BASE_ADDR_END_BIT = 72;
localparam OFM_BASE_ADDR_START_BIT = 103;
localparam OFM_BASE_ADDR_END_BIT = 88;
localparam IFM_BLOCK_ALIGN_START_BIT = 115;
localparam IFM_BLOCK_ALIGN_END_BIT = 104;
localparam OFM_BLOCK_ALIGN_START_BIT = 127;
localparam OFM_BLOCK_ALIGN_END_BIT = 116;

localparam SM_LUT_CONFIG_START_BIT = 255;
localparam SM_LUT_CONFIG_END_BIT = 128;

reg [255:0] spu_instr_reg;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) spu_instr_reg <= 'd0;
    else if (spu_start) spu_instr_reg <= spu_instr;
end

reg [6:0] ln_div_m_multireg [3:0];
reg [4:0] ln_div_e_multireg [3:0];
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        ln_div_m_multireg[0] <= 'd0;
        ln_div_m_multireg[1] <= 'd0;
        ln_div_m_multireg[2] <= 'd0;
        ln_div_m_multireg[3] <= 'd0;

        ln_div_e_multireg[0] <= 'd0;
        ln_div_e_multireg[1] <= 'd0;
        ln_div_e_multireg[2] <= 'd0;
        ln_div_e_multireg[3] <= 'd0;
    end
    else if (spu_start) begin
        ln_div_m_multireg[0] <= spu_instr[LN_DIV_M_START_BIT: LN_DIV_M_END_BIT];
        ln_div_m_multireg[1] <= spu_instr[LN_DIV_M_START_BIT: LN_DIV_M_END_BIT];
        ln_div_m_multireg[2] <= spu_instr[LN_DIV_M_START_BIT: LN_DIV_M_END_BIT];
        ln_div_m_multireg[3] <= spu_instr[LN_DIV_M_START_BIT: LN_DIV_M_END_BIT];

        ln_div_e_multireg[0] <= spu_instr[LN_DIV_E_START_BIT: LN_DIV_E_END_BIT];
        ln_div_e_multireg[1] <= spu_instr[LN_DIV_E_START_BIT: LN_DIV_E_END_BIT];
        ln_div_e_multireg[2] <= spu_instr[LN_DIV_E_START_BIT: LN_DIV_E_END_BIT];
        ln_div_e_multireg[3] <= spu_instr[LN_DIV_E_START_BIT: LN_DIV_E_END_BIT];
    end
end

// decompose spu instr
wire [3:0] spu_op = spu_instr_reg[OP_START_BIT: OP_END_BIT];
wire [0:0] spu_spu_op = spu_instr[SPU_OP_START_BIT: SPU_OP_END_BIT];
wire [0:0] spu_spu_op_reg = spu_instr_reg[SPU_OP_START_BIT: SPU_OP_END_BIT];
wire [0:0] spu_sm_op = spu_instr[SPU_SM_OP_START_BIT: SPU_SM_OP_END_BIT];
wire [0:0] spu_ln_op = spu_instr[SPU_LN_OP_START_BIT: SPU_LN_OP_END_BIT];
wire [15:0] spu_matrix_y = spu_instr_reg[MATRIX_Y_START_BIT: MATRIX_Y_END_BIT] + 1;
wire [10:0] spu_matrix_x_h = spu_instr_reg[MATRIX_X_H_START_BIT: MATRIX_X_H_END_BIT] + 1;
wire [11:0] spu_matrix_x_w = spu_instr_reg[MATRIX_X_W_START_BIT: MATRIX_X_W_END_BIT] + 1;
wire [3:0] shift0 = spu_instr_reg[SHIFT_0_START_BIT: SHIFT_0_END_BIT];
wire [3:0] shift1 = spu_instr_reg[SHIFT_1_START_BIT: SHIFT_1_END_BIT];
wire [4:0] shift2 = spu_instr_reg[SHIFT_2_START_BIT: SHIFT_2_END_BIT];
// wire [6:0] ln_div_m = spu_instr_reg[LN_DIV_M_START_BIT: LN_DIV_M_END_BIT];
// wire [4:0] ln_div_e = spu_instr_reg[LN_DIV_E_START_BIT: LN_DIV_E_END_BIT];
wire [15:0] im_base_addr = spu_instr[IFM_BASE_ADDR_START_BIT: IFM_BASE_ADDR_END_BIT];
wire [15:0] om_base_addr = spu_instr[OFM_BASE_ADDR_START_BIT: OFM_BASE_ADDR_END_BIT];
wire [11:0] im_block_align = spu_instr_reg[IFM_BLOCK_ALIGN_START_BIT: IFM_BLOCK_ALIGN_END_BIT];
wire [11:0] om_block_align = spu_instr_reg[OFM_BLOCK_ALIGN_START_BIT: OFM_BLOCK_ALIGN_END_BIT];

wire [127:0] sm_lut_config = spu_instr_reg[SM_LUT_CONFIG_START_BIT: SM_LUT_CONFIG_END_BIT];

reg [1:0] h_pad; // 如果最后两位是0, 4-0=4但是表示不了，无所谓，不会导致pad=4
reg [1:0] w_pad;
reg [15:0] spu_matrix_x;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        h_pad <= 'd0;
        w_pad <= 'd0;
        spu_matrix_x <= 'd0;
    end
    else begin
        h_pad <= 4 - spu_matrix_x_h[1:0];
        w_pad <= 4 - spu_matrix_x_w[1:0];
        spu_matrix_x <= (spu_matrix_x_h + h_pad) * (spu_matrix_x_w + w_pad);
    end
end

wire [11:0] token_per_block = spu_matrix_y >> 4; // Parallelism degree is 16 for matrix_y, so each block should process matrix_y / 16 in total

wire [RADDR_WIDTH-1:0] ln_lbuf_raddr, sm_lbuf_raddr; // submodule buf rd addr
wire [WADDR_WIDTH-1:0] ln_lbuf_waddr, sm_lbuf_waddr; // submodule buf wr addr
wire ln_lbuf_ren, sm_lbuf_ren; // submodule buf rd en
wire ln_lbuf_wen, sm_lbuf_wen; // submodule buf wr en
wire [16*64-1:0] ln_lbuf_wdata; // submodule buf rd data
wire [16*64-1:0] sm_lbuf_wdata; // submodule buf wr data
reg [16*64-1:0] lbuf_rdata_pulse_reg; // pulse 1 cycle to reduce timing issue
reg ln_start, sm_start; // submodule process start
wire ln_end, sm_end; // submodule process end

// arbitration
assign lbuf_raddr = spu_spu_op_reg ? ln_lbuf_raddr : sm_lbuf_raddr;
assign lbuf_waddr = spu_spu_op_reg ? ln_lbuf_waddr : sm_lbuf_waddr;
assign lbuf_ren = spu_spu_op_reg ? ln_lbuf_ren : sm_lbuf_ren;
assign lbuf_wen = spu_spu_op_reg ? ln_lbuf_wen : sm_lbuf_wen;
assign lbuf_wdata = spu_spu_op_reg ? ln_lbuf_wdata : sm_lbuf_wdata;
assign spu_end = spu_spu_op_reg ? ln_end : sm_end;

// pulse 1 cycle for lbuf_rdata
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) lbuf_rdata_pulse_reg <= 'd0;
    else lbuf_rdata_pulse_reg <= lbuf_rdata;
end

// submodule start signals, remain the same process as spu_start
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) ln_start <= 1'b0;
    else if (spu_start && spu_spu_op) ln_start <= 1'b1;
    else if (ln_start) ln_start <= 1'b0;
end
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) sm_start <= 1'b0;
    else if (spu_start && !spu_spu_op) sm_start <= 1'b1;
    else if (sm_start) sm_start <= 1'b0;
end

reg sm_op;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) sm_op <= 1'b0;
    else if (spu_start && !spu_spu_op) sm_op <= spu_sm_op;
end

reg ln_op;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) ln_op <= 1'b0;
    else if (spu_start && spu_spu_op) ln_op <= spu_ln_op;
end

// spu cache control
wire spu_cache_ren, spu_cache_wen, sm_cache_ren, sm_cache_wen, ln_cache_ren, ln_cache_wen;
wire [CACHE_DATA_DEPTH-1:0] spu_cache_raddr, spu_cache_waddr, sm_cache_raddr, sm_cache_waddr, ln_cache_addr;
wire [CACHE_DATA_WIDTH-1:0] spu_cache_wdata, spu_cache_rdata, sm_cache_wdata, ln_cache_wdata;

assign spu_cache_raddr = spu_spu_op_reg ? ln_cache_addr : sm_cache_raddr;
assign spu_cache_waddr = spu_spu_op_reg ? ln_cache_addr : sm_cache_waddr;
assign spu_cache_ren = spu_spu_op_reg ? ln_cache_ren : sm_cache_ren;
assign spu_cache_wen = spu_spu_op_reg ? ln_cache_wen : sm_cache_wen;
assign spu_cache_wdata = spu_spu_op_reg ? ln_cache_wdata : sm_cache_wdata;

reg spu_cache_ren_reg;
wire [127:0] spu_cache_sub_rdata_pre [7:0];
reg [127:0] spu_cache_sub_rdata [7:0];
wire [127:0] spu_cache_sub_wdata [7:0];
assign spu_cache_sub_wdata[0] = spu_cache_wdata[127:0];
assign spu_cache_sub_wdata[1] = spu_cache_wdata[255:128];
assign spu_cache_sub_wdata[2] = spu_cache_wdata[383:256];
assign spu_cache_sub_wdata[3] = spu_cache_wdata[511:384];
assign spu_cache_sub_wdata[4] = spu_cache_wdata[639:512];
assign spu_cache_sub_wdata[5] = spu_cache_wdata[767:640];
assign spu_cache_sub_wdata[6] = spu_cache_wdata[895:768];
assign spu_cache_sub_wdata[7] = spu_cache_wdata[1023:896];

always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) spu_cache_ren_reg <= 1'b0;
    else spu_cache_ren_reg <= spu_cache_ren;
end

always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        spu_cache_sub_rdata[0] <= 'd0;
        spu_cache_sub_rdata[1] <= 'd0;
        spu_cache_sub_rdata[2] <= 'd0;
        spu_cache_sub_rdata[3] <= 'd0;
        spu_cache_sub_rdata[4] <= 'd0;
        spu_cache_sub_rdata[5] <= 'd0;
        spu_cache_sub_rdata[6] <= 'd0;
        spu_cache_sub_rdata[7] <= 'd0;   
    end
    else if (spu_cache_ren_reg) begin
        spu_cache_sub_rdata[0] <= spu_cache_sub_rdata_pre[0];
        spu_cache_sub_rdata[1] <= spu_cache_sub_rdata_pre[1];
        spu_cache_sub_rdata[2] <= spu_cache_sub_rdata_pre[2];
        spu_cache_sub_rdata[3] <= spu_cache_sub_rdata_pre[3];
        spu_cache_sub_rdata[4] <= spu_cache_sub_rdata_pre[4];
        spu_cache_sub_rdata[5] <= spu_cache_sub_rdata_pre[5];
        spu_cache_sub_rdata[6] <= spu_cache_sub_rdata_pre[6];
        spu_cache_sub_rdata[7] <= spu_cache_sub_rdata_pre[7];
    end
end


assign spu_cache_rdata = {spu_cache_sub_rdata[7],spu_cache_sub_rdata[6],spu_cache_sub_rdata[5],spu_cache_sub_rdata[4],
                        spu_cache_sub_rdata[3],spu_cache_sub_rdata[2],spu_cache_sub_rdata[1],spu_cache_sub_rdata[0]};


// submodule LayerNorm (LN / ln) instance
spu_ln_top #(RLATENCY+1, RADDR_WIDTH, WADDR_WIDTH, LN_MAX_CHANNEL_DEPTH, CACHE_RLATENCY, CACHE_DATA_WIDTH, CACHE_DATA_DEPTH) u_spu_ln_top (
    .core_clk(core_clk_ln),
    .rst_n(rst_n),
    .ln_start(ln_start),
    .ln_op(ln_op),
    .ln_end(ln_end),

    .spu_matrix_x_h(spu_matrix_x_h),
    .spu_matrix_x_w(spu_matrix_x_w),
    .h_pad(h_pad),
    .w_pad(w_pad),
    .ln_channel_number(spu_matrix_x[LN_MAX_CHANNEL_DEPTH:0]),
    .im_base_addr(im_base_addr),
    .om_base_addr(om_base_addr),
    .ifm_addr_align(im_block_align),
    .ofm_addr_align(om_block_align),
    .token_per_block(token_per_block),
    .ln_shift_output(shift0),
    .ln_div_m_0(ln_div_m_multireg[0]),
    .ln_div_m_1(ln_div_m_multireg[1]),
    .ln_div_m_2(ln_div_m_multireg[2]),
    .ln_div_m_3(ln_div_m_multireg[3]),
    .ln_div_e_0(ln_div_e_multireg[0]),
    .ln_div_e_1(ln_div_e_multireg[1]),
    .ln_div_e_2(ln_div_e_multireg[2]),
    .ln_div_e_3(ln_div_e_multireg[3]),
    
    .ln_lbuf_ren(ln_lbuf_ren),
    .ln_lbuf_raddr(ln_lbuf_raddr),
    .ln_lbuf_rdata(lbuf_rdata_pulse_reg),
    .ln_lbuf_wen(ln_lbuf_wen),
    .ln_lbuf_waddr(ln_lbuf_waddr),
    .ln_lbuf_wdata(ln_lbuf_wdata),

    .ln_cache_ren(ln_cache_ren),
    .ln_cache_addr(ln_cache_addr),
    .ln_cache_rdata(spu_cache_rdata),
    .ln_cache_wen(ln_cache_wen),
    .ln_cache_wdata(ln_cache_wdata)
);

// submodule SoftMax (SM / sm) instance
spu_sm_top #(RLATENCY+1, RADDR_WIDTH, WADDR_WIDTH, SM_MAX_CHANNEL_DEPTH, CACHE_RLATENCY, CACHE_DATA_WIDTH, CACHE_DATA_DEPTH) u_spu_sm_top (
    .core_clk(core_clk_sm),
    .rst_n(rst_n),
    .sm_start(sm_start),
    .sm_op(sm_op),
    .sm_end(sm_end),

    .spu_matrix_x_h(spu_matrix_x_h),
    .spu_matrix_x_w(spu_matrix_x_w),
    .h_pad(h_pad),
    .w_pad(w_pad),
    .sm_channel_number(spu_matrix_x[SM_MAX_CHANNEL_DEPTH:0]), // maximum channel number supported by ln is 4096
    .sm_lut_config(sm_lut_config),
    .im_base_addr(im_base_addr),
    .om_base_addr(om_base_addr),
    .ifm_addr_align(im_block_align),
    .ofm_addr_align(om_block_align),
    .token_per_block(token_per_block),
    .sm_shift_input(shift1),
    .sm_exp_shift_output(shift2),
    .sm_shift_output(shift0),

    .sm_lbuf_ren(sm_lbuf_ren),
    .sm_lbuf_raddr(sm_lbuf_raddr),
    .sm_lbuf_rdata(lbuf_rdata_pulse_reg),
    .sm_lbuf_wen(sm_lbuf_wen),
    .sm_lbuf_waddr(sm_lbuf_waddr),
    .sm_lbuf_wdata(sm_lbuf_wdata),

    .sm_cache_ren(sm_cache_ren),
    .sm_cache_raddr(sm_cache_raddr),
    .sm_cache_waddr(sm_cache_waddr),
    .sm_cache_rdata(spu_cache_rdata),
    .sm_cache_wen(sm_cache_wen),
    .sm_cache_wdata(sm_cache_wdata)
);

`ifdef ASIC
genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : cache_gen
        // TS1N28HPCPSVTB512X128M4S u_spu_cache(
        //     .CLK(core_clk),
        //     .CEB(~(spu_cache_wen || spu_cache_ren)),
        //     .WEB(~spu_cache_wen),
        //     .A(spu_cache_addr),
        //     .D(spu_cache_sub_wdata[i]),
        //     .Q(spu_cache_sub_rdata[i])
        // );
        TSDN28HPCPUHDB512X128M4M u_spu_cache(
            .RTSEL(cfg_spubuf_rtsel),
            .WTSEL(cfg_spubuf_wtsel),
            .PTSEL(cfg_spubuf_ptsel),
            .AA(spu_cache_waddr),
            .DA(spu_cache_sub_wdata[i]),
            .WEBA(~spu_cache_wen),
            .CEBA(~spu_cache_wen),
            .CLK(core_clk),
            .AB(spu_cache_raddr),
            .DB(128'b0),
            .WEBB(1'b1),
            .CEBB(~spu_cache_ren),
            .QA(),
            .QB(spu_cache_sub_rdata_pre[i])
        );
    end
endgenerate
`else
genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : cache_gen
        // spu_cache #(CACHE_DATA_WIDTH / 8, CACHE_DATA_DEPTH) u_spu_cache(
        //     .clka(core_clk),
        //     .clkb(core_clk),
        //     // .ena(spu_cache_ren),
        //     .wea(1'b0),
        //     .web(spu_cache_wen),
        //     .addra(spu_cache_raddr),
        //     .addrb(spu_cache_waddr),
        //     .dina(),
        //     .dinb(spu_cache_sub_wdata[i]),
        //     .douta(spu_cache_sub_rdata[i]),
        //     .doutb()
        // );
        fpga_sdp_ram #(
          .RAM_WIDTH(CACHE_DATA_WIDTH/8),      // Specify RAM data width
          .RAM_DEPTH(2**CACHE_DATA_DEPTH),     // Specify RAM depth (number of entries)
          .RAM_PERFORMANCE("LOW_LATENCY"),     // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
          .INIT_FILE("") // Specify name/location of RAM initialization file 
        ) u_spu_cache(
                  // port A: Write
                  .clka(core_clk),
                  .addra(spu_cache_waddr),
                  .dina(spu_cache_sub_wdata[i]),
                  .wea(spu_cache_wen),
                  // port B: Read
                  .clkb(core_clk),
                  .rstb(!rst_n), // core_rst_n
                  .regceb(1'b0), // Output register enable
                  .addrb(spu_cache_raddr),
                  .enb(spu_cache_ren),
                  .doutb(spu_cache_sub_rdata_pre[i]) // RAM output data
        );
    end
endgenerate
`endif
endmodule
