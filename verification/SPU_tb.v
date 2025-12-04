`timescale 1ns / 1ps
`define core_clk_PERIOD 20
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/30 15:27:48
// Design Name: 
// Module Name: SPU_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SPU_tb();
localparam RLATENCY = 2;
// aabbccddee
reg core_clk, rst_n, spu_start, buffer_sel_wire, buffer_sel;
integer file1;
reg signed [7:0] data_0 [7:0];
reg signed [7:0] data_1 [7:0];
reg signed [7:0] data_2 [7:0];
reg signed [7:0] data_3 [7:0];
reg signed [7:0] data_4 [7:0];
reg signed [7:0] data_5 [7:0];
reg signed [7:0] data_6 [7:0];
reg signed [7:0] data_7 [7:0];
reg signed [7:0] data_8 [7:0];
reg signed [7:0] data_9 [7:0];
reg signed [7:0] data_10 [7:0];
reg signed [7:0] data_11 [7:0];
reg signed [7:0] data_12 [7:0];
reg signed [7:0] data_13 [7:0];
reg signed [7:0] data_14 [7:0];
reg signed [7:0] data_15 [7:0];
initial begin
    file1 = $fopen("../../../../../output_spu.txt", "w");
    core_clk = 1;
    rst_n = 0;
    spu_start = 0;
    buffer_sel_wire = 1;
    #20;
    rst_n = 1;
    #20;
    spu_start = 1;
    #20;
    spu_start = 0;
end
always #(`core_clk_PERIOD / 2) core_clk = ~core_clk;

wire [255:0] spu_instr;
wire [4-1:0] OP;  
wire [1-1:0] SPU_OP; 
wire [1-1:0] last_lyr_flag;
wire [1-1:0] spu_sm_op; // change here   
wire [1-1:0] spu_ln_op; // change here    
wire [16-1:0] matrix_y; 
wire [11-1:0] matrix_x_h; 
wire [12-1:0] matrix_x_w; 
wire [4-1:0] shift0;
wire [4-1:0] shift1;
wire [5-1:0] shift2;
wire [7-1:0] ln_div_m;
wire [5-1:0] ln_div_e;
wire [16-1:0] im_base_addr;   
wire [16-1:0] om_base_addr;   
wire [12-1:0] im_block_align; 
wire [12-1:0] om_block_align;

wire [128-1:0] sm_lut_config;

assign OP = 4'h4;
assign SPU_OP = 1'b0;
assign last_lyr_flag = 1'b0;
assign spu_sm_op = 1'b0;
assign spu_ln_op = 1'b0;
assign matrix_y = 16'd1023;
assign matrix_x_h = 16'd6;
assign matrix_x_w = 16'd7;
assign shift0 = 4'b1100;
assign shift1 = 4'b0011;
assign shift2 = 5'b00110;
assign ln_div_m = 7'd0;
assign ln_div_e = 5'd0;
assign im_base_addr = 16'd0;
assign om_base_addr = 16'd0;
assign im_block_align = 12'b000000001000;
assign om_block_align = 12'b000000001000;

assign sm_lut_config = 128'b11111111111111111110000111101011110001110101111110101111111100101001101101000110100010010000011101111000111011010110101010110111;

wire [1:0] h_pad;
wire [1:0] w_pad;
assign h_pad = 2'd1;
assign w_pad = 2'd0;
wire [15:0] matrix_x = (matrix_x_h + 1 + h_pad) * (matrix_x_w + 1 + w_pad);
wire [35:0] total_test_rd_addr = (matrix_y+1)*(matrix_x) / (16 * 8) + om_base_addr;

assign spu_instr = {sm_lut_config,om_block_align,im_block_align,om_base_addr,im_base_addr,ln_div_e,ln_div_m,shift2,shift1,shift0,matrix_x_w,matrix_x_h,matrix_y,spu_ln_op,spu_sm_op,last_lyr_flag,SPU_OP,OP};

wire [63:0] spu_bf_rd_data_0;
wire [63:0] spu_bf_rd_data_1;
wire [63:0] spu_bf_rd_data_2;
wire [63:0] spu_bf_rd_data_3;
wire [63:0] spu_bf_rd_data_4;
wire [63:0] spu_bf_rd_data_5;
wire [63:0] spu_bf_rd_data_6;
wire [63:0] spu_bf_rd_data_7;
wire [63:0] spu_bf_rd_data_8;
wire [63:0] spu_bf_rd_data_9;
wire [63:0] spu_bf_rd_data_10;
wire [63:0] spu_bf_rd_data_11;
wire [63:0] spu_bf_rd_data_12;
wire [63:0] spu_bf_rd_data_13;
wire [63:0] spu_bf_rd_data_14;
wire [63:0] spu_bf_rd_data_15;
wire [64*16-1:0] lbuf_rdata = {spu_bf_rd_data_15,spu_bf_rd_data_14,spu_bf_rd_data_13,spu_bf_rd_data_12,spu_bf_rd_data_11,spu_bf_rd_data_10,
spu_bf_rd_data_9,spu_bf_rd_data_8,spu_bf_rd_data_7,spu_bf_rd_data_6,spu_bf_rd_data_5,spu_bf_rd_data_4,spu_bf_rd_data_3,spu_bf_rd_data_2,spu_bf_rd_data_1,spu_bf_rd_data_0};
wire [64*16-1:0] lbuf_wdata;
wire [63:0] spu_bf_wr_data_0 = lbuf_wdata[64*1-1:64*0];
wire [63:0] spu_bf_wr_data_1 = lbuf_wdata[64*2-1:64*1];
wire [63:0] spu_bf_wr_data_2 = lbuf_wdata[64*3-1:64*2];
wire [63:0] spu_bf_wr_data_3 = lbuf_wdata[64*4-1:64*3];
wire [63:0] spu_bf_wr_data_4 = lbuf_wdata[64*5-1:64*4];
wire [63:0] spu_bf_wr_data_5 = lbuf_wdata[64*6-1:64*5];
wire [63:0] spu_bf_wr_data_6 = lbuf_wdata[64*7-1:64*6];
wire [63:0] spu_bf_wr_data_7 = lbuf_wdata[64*8-1:64*7];
wire [63:0] spu_bf_wr_data_8 = lbuf_wdata[64*9-1:64*8];
wire [63:0] spu_bf_wr_data_9 = lbuf_wdata[64*10-1:64*9];
wire [63:0] spu_bf_wr_data_10 = lbuf_wdata[64*11-1:64*10];
wire [63:0] spu_bf_wr_data_11 = lbuf_wdata[64*12-1:64*11];
wire [63:0] spu_bf_wr_data_12 = lbuf_wdata[64*13-1:64*12];
wire [63:0] spu_bf_wr_data_13 = lbuf_wdata[64*14-1:64*13];
wire [63:0] spu_bf_wr_data_14 = lbuf_wdata[64*15-1:64*14];
wire [63:0] spu_bf_wr_data_15 = lbuf_wdata[64*16-1:64*15];
wire [12:0] lbuf_raddr;
wire [12:0] lbuf_waddr;
wire lbuf_ren;
wire lbuf_wen;

wire [12:0] fmap_rd_addr = buffer_sel ? lbuf_raddr : tb_rd_cnt;
wire fmap_rd_en = buffer_sel ? lbuf_ren : tb_rd_en;

reg [16*64-1:0] lbuf_rdata_reg_0;
reg [16*64-1:0] lbuf_rdata_reg_1;
reg [16*64-1:0] lbuf_rdata_reg_2;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        lbuf_rdata_reg_0 <= 'd0;
        lbuf_rdata_reg_1 <= 'd0;
        lbuf_rdata_reg_2 <= 'd0;
    end
    else begin
        lbuf_rdata_reg_0 <= lbuf_rdata;
        lbuf_rdata_reg_1 <= lbuf_rdata_reg_0;
        lbuf_rdata_reg_2 <= lbuf_rdata_reg_1;
    end
end
wire [16*64-1:0] lbuf_rdata_in;
assign lbuf_rdata_in = RLATENCY == 2 ? lbuf_rdata : RLATENCY == 3 ? lbuf_rdata_reg_0 : RLATENCY == 4 ? lbuf_rdata_reg_1 : RLATENCY == 5 ? lbuf_rdata_reg_2 : lbuf_rdata;
special_pu #(RLATENCY) u_special_pu(
    .core_clk(core_clk),
    .core_clk_sm(core_clk),
    .core_clk_ln(core_clk),
    .rst_n(rst_n), // system reset for spu, active low
    .spu_start(spu_start), // enable for valid instruction, start process
    .spu_end(spu_end),
    .spu_instr(spu_instr), // instruction for spu, aligned to multiples of 64
    .lbuf_rdata(lbuf_rdata_in),
    .lbuf_wdata(lbuf_wdata),
    .lbuf_raddr(lbuf_raddr), // read addr for global buffer
    .lbuf_ren(lbuf_ren), // read enable for global buffer
    .lbuf_waddr(lbuf_waddr), // write addr for global buffer
    .lbuf_wen(lbuf_wen) // write enable for global buffer
);

reg [13:0] tb_rd_cnt; // not enough bits!!!

always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) tb_rd_cnt <= 13'd0 + om_base_addr;
    else if (~buffer_sel && total_test_rd_addr > 1 && tb_rd_cnt >= total_test_rd_addr - 1) tb_rd_cnt <= total_test_rd_addr;
    else if (~buffer_sel && total_test_rd_addr == 1 && tb_rd_cnt >= total_test_rd_addr) tb_rd_cnt <= total_test_rd_addr + 1;
    else if (~buffer_sel) tb_rd_cnt <= tb_rd_cnt + 13'd1;
end
wire tb_rd_en;
assign tb_rd_en = ~buffer_sel && tb_rd_cnt <= total_test_rd_addr - 1;
FeatureMap_Buffer u_FeatureMap_Buffer(
    .core_clk(core_clk),
    .fmap_rd_addr(fmap_rd_addr),
    .fmap_wr_addr(lbuf_waddr),
    .fmap_rd_en(fmap_rd_en),
    .fmap_wr_en(lbuf_wen),
    .fmap_wr_data_bank_0(spu_bf_wr_data_0),
    .fmap_wr_data_bank_1(spu_bf_wr_data_1),
    .fmap_wr_data_bank_2(spu_bf_wr_data_2),
    .fmap_wr_data_bank_3(spu_bf_wr_data_3),
    .fmap_wr_data_bank_4(spu_bf_wr_data_4),
    .fmap_wr_data_bank_5(spu_bf_wr_data_5),
    .fmap_wr_data_bank_6(spu_bf_wr_data_6),
    .fmap_wr_data_bank_7(spu_bf_wr_data_7),
    .fmap_wr_data_bank_8(spu_bf_wr_data_8),
    .fmap_wr_data_bank_9(spu_bf_wr_data_9),
    .fmap_wr_data_bank_10(spu_bf_wr_data_10),
    .fmap_wr_data_bank_11(spu_bf_wr_data_11),
    .fmap_wr_data_bank_12(spu_bf_wr_data_12),
    .fmap_wr_data_bank_13(spu_bf_wr_data_13),
    .fmap_wr_data_bank_14(spu_bf_wr_data_14),
    .fmap_wr_data_bank_15(spu_bf_wr_data_15),
    .fmap_rd_data_bank_0(spu_bf_rd_data_0),
    .fmap_rd_data_bank_1(spu_bf_rd_data_1),
    .fmap_rd_data_bank_2(spu_bf_rd_data_2),
    .fmap_rd_data_bank_3(spu_bf_rd_data_3),
    .fmap_rd_data_bank_4(spu_bf_rd_data_4),
    .fmap_rd_data_bank_5(spu_bf_rd_data_5),
    .fmap_rd_data_bank_6(spu_bf_rd_data_6),
    .fmap_rd_data_bank_7(spu_bf_rd_data_7),
    .fmap_rd_data_bank_8(spu_bf_rd_data_8),
    .fmap_rd_data_bank_9(spu_bf_rd_data_9),
    .fmap_rd_data_bank_10(spu_bf_rd_data_10),
    .fmap_rd_data_bank_11(spu_bf_rd_data_11),
    .fmap_rd_data_bank_12(spu_bf_rd_data_12),
    .fmap_rd_data_bank_13(spu_bf_rd_data_13),
    .fmap_rd_data_bank_14(spu_bf_rd_data_14),
    .fmap_rd_data_bank_15(spu_bf_rd_data_15)
);

always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) buffer_sel <= 1'b1;
    else if(spu_end) buffer_sel <= 1'b0;
end

reg tb_rd_en_reg1, tb_rd_en_reg2;
always @(posedge core_clk) begin
    tb_rd_en_reg1 <= tb_rd_en;
    tb_rd_en_reg2 <= tb_rd_en_reg1;
end
reg [35:0] total_read_cnt = 'd0;
always @(posedge core_clk) begin
    if (tb_rd_en_reg2) begin
        total_read_cnt <= total_read_cnt + 'd1;
        data_0[0] = spu_bf_rd_data_0[7:0];
        data_0[1] = spu_bf_rd_data_0[15:8];
        data_0[2] = spu_bf_rd_data_0[23:16];
        data_0[3] = spu_bf_rd_data_0[31:24];
        data_0[4] = spu_bf_rd_data_0[39:32];
        data_0[5] = spu_bf_rd_data_0[47:40];
        data_0[6] = spu_bf_rd_data_0[55:48];
        data_0[7] = spu_bf_rd_data_0[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_0[0], data_0[1], data_0[2], data_0[3], data_0[4], data_0[5], data_0[6], data_0[7]);
        data_1[0] = spu_bf_rd_data_1[7:0];
        data_1[1] = spu_bf_rd_data_1[15:8];
        data_1[2] = spu_bf_rd_data_1[23:16];
        data_1[3] = spu_bf_rd_data_1[31:24];
        data_1[4] = spu_bf_rd_data_1[39:32];
        data_1[5] = spu_bf_rd_data_1[47:40];
        data_1[6] = spu_bf_rd_data_1[55:48];
        data_1[7] = spu_bf_rd_data_1[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_1[0], data_1[1], data_1[2], data_1[3], data_1[4], data_1[5], data_1[6], data_1[7]);
        data_2[0] = spu_bf_rd_data_2[7:0];
        data_2[1] = spu_bf_rd_data_2[15:8];
        data_2[2] = spu_bf_rd_data_2[23:16];
        data_2[3] = spu_bf_rd_data_2[31:24];
        data_2[4] = spu_bf_rd_data_2[39:32];
        data_2[5] = spu_bf_rd_data_2[47:40];
        data_2[6] = spu_bf_rd_data_2[55:48];
        data_2[7] = spu_bf_rd_data_2[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_2[0], data_2[1], data_2[2], data_2[3], data_2[4], data_2[5], data_2[6], data_2[7]);
        data_3[0] = spu_bf_rd_data_3[7:0];
        data_3[1] = spu_bf_rd_data_3[15:8];
        data_3[2] = spu_bf_rd_data_3[23:16];
        data_3[3] = spu_bf_rd_data_3[31:24];
        data_3[4] = spu_bf_rd_data_3[39:32];
        data_3[5] = spu_bf_rd_data_3[47:40];
        data_3[6] = spu_bf_rd_data_3[55:48];
        data_3[7] = spu_bf_rd_data_3[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_3[0], data_3[1], data_3[2], data_3[3], data_3[4], data_3[5], data_3[6], data_3[7]);
        data_4[0] = spu_bf_rd_data_4[7:0];
        data_4[1] = spu_bf_rd_data_4[15:8];
        data_4[2] = spu_bf_rd_data_4[23:16];
        data_4[3] = spu_bf_rd_data_4[31:24];
        data_4[4] = spu_bf_rd_data_4[39:32];
        data_4[5] = spu_bf_rd_data_4[47:40];
        data_4[6] = spu_bf_rd_data_4[55:48];
        data_4[7] = spu_bf_rd_data_4[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_4[0], data_4[1], data_4[2], data_4[3], data_4[4], data_4[5], data_4[6], data_4[7]);
        data_5[0] = spu_bf_rd_data_5[7:0];
        data_5[1] = spu_bf_rd_data_5[15:8];
        data_5[2] = spu_bf_rd_data_5[23:16];
        data_5[3] = spu_bf_rd_data_5[31:24];
        data_5[4] = spu_bf_rd_data_5[39:32];
        data_5[5] = spu_bf_rd_data_5[47:40];
        data_5[6] = spu_bf_rd_data_5[55:48];
        data_5[7] = spu_bf_rd_data_5[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_5[0], data_5[1], data_5[2], data_5[3], data_5[4], data_5[5], data_5[6], data_5[7]);
        data_6[0] = spu_bf_rd_data_6[7:0];
        data_6[1] = spu_bf_rd_data_6[15:8];
        data_6[2] = spu_bf_rd_data_6[23:16];
        data_6[3] = spu_bf_rd_data_6[31:24];
        data_6[4] = spu_bf_rd_data_6[39:32];
        data_6[5] = spu_bf_rd_data_6[47:40];
        data_6[6] = spu_bf_rd_data_6[55:48];
        data_6[7] = spu_bf_rd_data_6[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_6[0], data_6[1], data_6[2], data_6[3], data_6[4], data_6[5], data_6[6], data_6[7]);
        data_7[0] = spu_bf_rd_data_7[7:0];
        data_7[1] = spu_bf_rd_data_7[15:8];
        data_7[2] = spu_bf_rd_data_7[23:16];
        data_7[3] = spu_bf_rd_data_7[31:24];
        data_7[4] = spu_bf_rd_data_7[39:32];
        data_7[5] = spu_bf_rd_data_7[47:40];
        data_7[6] = spu_bf_rd_data_7[55:48];
        data_7[7] = spu_bf_rd_data_7[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_7[0], data_7[1], data_7[2], data_7[3], data_7[4], data_7[5], data_7[6], data_7[7]);
        data_8[0] = spu_bf_rd_data_8[7:0];
        data_8[1] = spu_bf_rd_data_8[15:8];
        data_8[2] = spu_bf_rd_data_8[23:16];
        data_8[3] = spu_bf_rd_data_8[31:24];
        data_8[4] = spu_bf_rd_data_8[39:32];
        data_8[5] = spu_bf_rd_data_8[47:40];
        data_8[6] = spu_bf_rd_data_8[55:48];
        data_8[7] = spu_bf_rd_data_8[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_8[0], data_8[1], data_8[2], data_8[3], data_8[4], data_8[5], data_8[6], data_8[7]);
        data_9[0] = spu_bf_rd_data_9[7:0];
        data_9[1] = spu_bf_rd_data_9[15:8];
        data_9[2] = spu_bf_rd_data_9[23:16];
        data_9[3] = spu_bf_rd_data_9[31:24];
        data_9[4] = spu_bf_rd_data_9[39:32];
        data_9[5] = spu_bf_rd_data_9[47:40];
        data_9[6] = spu_bf_rd_data_9[55:48];
        data_9[7] = spu_bf_rd_data_9[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_9[0], data_9[1], data_9[2], data_9[3], data_9[4], data_9[5], data_9[6], data_9[7]);
        data_10[0] = spu_bf_rd_data_10[7:0];
        data_10[1] = spu_bf_rd_data_10[15:8];
        data_10[2] = spu_bf_rd_data_10[23:16];
        data_10[3] = spu_bf_rd_data_10[31:24];
        data_10[4] = spu_bf_rd_data_10[39:32];
        data_10[5] = spu_bf_rd_data_10[47:40];
        data_10[6] = spu_bf_rd_data_10[55:48];
        data_10[7] = spu_bf_rd_data_10[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_10[0], data_10[1], data_10[2], data_10[3], data_10[4], data_10[5], data_10[6], data_10[7]);
        data_11[0] = spu_bf_rd_data_11[7:0];
        data_11[1] = spu_bf_rd_data_11[15:8];
        data_11[2] = spu_bf_rd_data_11[23:16];
        data_11[3] = spu_bf_rd_data_11[31:24];
        data_11[4] = spu_bf_rd_data_11[39:32];
        data_11[5] = spu_bf_rd_data_11[47:40];
        data_11[6] = spu_bf_rd_data_11[55:48];
        data_11[7] = spu_bf_rd_data_11[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_11[0], data_11[1], data_11[2], data_11[3], data_11[4], data_11[5], data_11[6], data_11[7]);
        data_12[0] = spu_bf_rd_data_12[7:0];
        data_12[1] = spu_bf_rd_data_12[15:8];
        data_12[2] = spu_bf_rd_data_12[23:16];
        data_12[3] = spu_bf_rd_data_12[31:24];
        data_12[4] = spu_bf_rd_data_12[39:32];
        data_12[5] = spu_bf_rd_data_12[47:40];
        data_12[6] = spu_bf_rd_data_12[55:48];
        data_12[7] = spu_bf_rd_data_12[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_12[0], data_12[1], data_12[2], data_12[3], data_12[4], data_12[5], data_12[6], data_12[7]);
        data_13[0] = spu_bf_rd_data_13[7:0];
        data_13[1] = spu_bf_rd_data_13[15:8];
        data_13[2] = spu_bf_rd_data_13[23:16];
        data_13[3] = spu_bf_rd_data_13[31:24];
        data_13[4] = spu_bf_rd_data_13[39:32];
        data_13[5] = spu_bf_rd_data_13[47:40];
        data_13[6] = spu_bf_rd_data_13[55:48];
        data_13[7] = spu_bf_rd_data_13[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_13[0], data_13[1], data_13[2], data_13[3], data_13[4], data_13[5], data_13[6], data_13[7]);
        data_14[0] = spu_bf_rd_data_14[7:0];
        data_14[1] = spu_bf_rd_data_14[15:8];
        data_14[2] = spu_bf_rd_data_14[23:16];
        data_14[3] = spu_bf_rd_data_14[31:24];
        data_14[4] = spu_bf_rd_data_14[39:32];
        data_14[5] = spu_bf_rd_data_14[47:40];
        data_14[6] = spu_bf_rd_data_14[55:48];
        data_14[7] = spu_bf_rd_data_14[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_14[0], data_14[1], data_14[2], data_14[3], data_14[4], data_14[5], data_14[6], data_14[7]);
        data_15[0] = spu_bf_rd_data_15[7:0];
        data_15[1] = spu_bf_rd_data_15[15:8];
        data_15[2] = spu_bf_rd_data_15[23:16];
        data_15[3] = spu_bf_rd_data_15[31:24];
        data_15[4] = spu_bf_rd_data_15[39:32];
        data_15[5] = spu_bf_rd_data_15[47:40];
        data_15[6] = spu_bf_rd_data_15[55:48];
        data_15[7] = spu_bf_rd_data_15[63:56];
        $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_15[0], data_15[1], data_15[2], data_15[3], data_15[4], data_15[5], data_15[6], data_15[7]);
        // $fwrite(file1, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", data_0[0], data_0[1], data_0[2], data_0[3], data_0[4], data_0[5], data_0[6], data_0[7], data_1[0], data_1[1], data_1[2], data_1[3], data_1[4], data_1[5], data_1[6], data_1[7], data_2[0], data_2[1], data_2[2], data_2[3], data_2[4], data_2[5], data_2[6], data_2[7], data_3[0], data_3[1], data_3[2], data_3[3], data_3[4], data_3[5], data_3[6], data_3[7], data_4[0], data_4[1], data_4[2], data_4[3], data_4[4], data_4[5], data_4[6], data_4[7], data_5[0], data_5[1], data_5[2], data_5[3], data_5[4], data_5[5], data_5[6], data_5[7], data_6[0], data_6[1], data_6[2], data_6[3], data_6[4], data_6[5], data_6[6], data_6[7], data_7[0], data_7[1], data_7[2], data_7[3], data_7[4], data_7[5], data_7[6], data_7[7], data_8[0], data_8[1], data_8[2], data_8[3], data_8[4], data_8[5], data_8[6], data_8[7], data_9[0], data_9[1], data_9[2], data_9[3], data_9[4], data_9[5], data_9[6], data_9[7], data_10[0], data_10[1], data_10[2], data_10[3], data_10[4], data_10[5], data_10[6], data_10[7], data_11[0], data_11[1], data_11[2], data_11[3], data_11[4], data_11[5], data_11[6], data_11[7], data_12[0], data_12[1], data_12[2], data_12[3], data_12[4], data_12[5], data_12[6], data_12[7], data_13[0], data_13[1], data_13[2], data_13[3], data_13[4], data_13[5], data_13[6], data_13[7], data_14[0], data_14[1], data_14[2], data_14[3], data_14[4], data_14[5], data_14[6], data_14[7], data_15[0], data_15[1], data_15[2], data_15[3], data_15[4], data_15[5], data_15[6], data_15[7]);
    end
    // else if (!tb_rd_en_reg2 && ((total_test_rd_addr > 1 - om_base_addr && tb_rd_cnt == total_test_rd_addr) || (total_test_rd_addr == 1 - om_base_addr && tb_rd_cnt > total_test_rd_addr)))  begin
    //     $fclose(file1);
    //     $finish;
    // end
    else if (total_read_cnt == total_test_rd_addr - om_base_addr)  begin
        $fclose(file1);
        $finish;
    end
end
endmodule
