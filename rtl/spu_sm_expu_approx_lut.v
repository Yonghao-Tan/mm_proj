`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/14 19:47:27
// Design Name: 
// Module Name: NN_LUT
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


module spu_sm_expu_approx_lut( 
    input core_clk,
    input rst_n,
    input [2:0] sm_state,
    input signed [3:0] din_q_0,
    input signed [3:0] din_q_1,
    input signed [3:0] din_q_2,
    input signed [3:0] din_q_3,
    input signed [3:0] din_q_4,
    input signed [3:0] din_q_5,
    input signed [3:0] din_q_6,
    input signed [3:0] din_q_7,
    input [127:0] sm_lut_config,
    input [4:0] output_scale_shift,
    output reg [7:0] dout_q_0,
    output reg [7:0] dout_q_1,
    output reg [7:0] dout_q_2,
    output reg [7:0] dout_q_3,
    output reg [7:0] dout_q_4,
    output reg [7:0] dout_q_5,
    output reg [7:0] dout_q_6,
    output reg [7:0] dout_q_7
    );
// sm state machine
localparam IDLE = 3'b000;
localparam EU_STAGE_A = 3'b001;
localparam RECI = 3'b011; // now is the divider stage
localparam EU_STAGE_B = 3'b100;
localparam MAX = 3'b101;

// supported scale shift range: [-4, 4] (scale value: [0.0625, 4])
// supported input range: [-4, 3]

wire [15:0] exp_lut [7:0];

assign exp_lut[0] = sm_lut_config[15:0];
assign exp_lut[1] = sm_lut_config[31:16];
assign exp_lut[2] = sm_lut_config[47:32];
assign exp_lut[3] = sm_lut_config[63:48];
assign exp_lut[4] = sm_lut_config[79:64];
assign exp_lut[5] = sm_lut_config[95:80];
assign exp_lut[6] = sm_lut_config[111:96];
assign exp_lut[7] = sm_lut_config[127:112];


reg signed [3:0] din_q_0_reg;
reg signed [3:0] din_q_1_reg;
reg signed [3:0] din_q_2_reg;
reg signed [3:0] din_q_3_reg;
reg signed [3:0] din_q_4_reg;
reg signed [3:0] din_q_5_reg;
reg signed [3:0] din_q_6_reg;
reg signed [3:0] din_q_7_reg;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        din_q_0_reg <= 'd0;
        din_q_1_reg <= 'd0;
        din_q_2_reg <= 'd0;
        din_q_3_reg <= 'd0;
        din_q_4_reg <= 'd0;
        din_q_5_reg <= 'd0;
        din_q_6_reg <= 'd0;
        din_q_7_reg <= 'd0;
    end
    else if (sm_state == EU_STAGE_A) begin
        din_q_0_reg <= din_q_0;
        din_q_1_reg <= din_q_1;
        din_q_2_reg <= din_q_2;
        din_q_3_reg <= din_q_3;
        din_q_4_reg <= din_q_4;
        din_q_5_reg <= din_q_5;
        din_q_6_reg <= din_q_6;
        din_q_7_reg <= din_q_7;
    end
end


wire signed [3:0] q_addr_0 = din_q_0_reg + 4'd4;
wire signed [3:0] q_addr_1 = din_q_1_reg + 4'd4;
wire signed [3:0] q_addr_2 = din_q_2_reg + 4'd4;
wire signed [3:0] q_addr_3 = din_q_3_reg + 4'd4;
wire signed [3:0] q_addr_4 = din_q_4_reg + 4'd4;
wire signed [3:0] q_addr_5 = din_q_5_reg + 4'd4;
wire signed [3:0] q_addr_6 = din_q_6_reg + 4'd4;
wire signed [3:0] q_addr_7 = din_q_7_reg + 4'd4;

reg [15:0] lut_approx_0;
reg [15:0] lut_approx_1;
reg [15:0] lut_approx_2;
reg [15:0] lut_approx_3;
reg [15:0] lut_approx_4;
reg [15:0] lut_approx_5;
reg [15:0] lut_approx_6;
reg [15:0] lut_approx_7;

always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        lut_approx_0 <= 'd0;
        lut_approx_1 <= 'd0;
        lut_approx_2 <= 'd0;
        lut_approx_3 <= 'd0;
        lut_approx_4 <= 'd0;
        lut_approx_5 <= 'd0;
        lut_approx_6 <= 'd0;
        lut_approx_7 <= 'd0;
    end
    else if (sm_state == EU_STAGE_A) begin
        lut_approx_0 <= exp_lut[q_addr_0[2:0]];
        lut_approx_1 <= exp_lut[q_addr_1[2:0]];
        lut_approx_2 <= exp_lut[q_addr_2[2:0]];
        lut_approx_3 <= exp_lut[q_addr_3[2:0]];
        lut_approx_4 <= exp_lut[q_addr_4[2:0]];
        lut_approx_5 <= exp_lut[q_addr_5[2:0]];
        lut_approx_6 <= exp_lut[q_addr_6[2:0]];
        lut_approx_7 <= exp_lut[q_addr_7[2:0]];
    end
end

// must be left shift since 0 | 16 -> 8 | 0
// 0 | 16 -> 12 | 16
wire [27:0] lut_approx_0_extend = {12'b0000_0000_0000, lut_approx_0};
wire [27:0] lut_approx_1_extend = {12'b0000_0000_0000, lut_approx_1};
wire [27:0] lut_approx_2_extend = {12'b0000_0000_0000, lut_approx_2};
wire [27:0] lut_approx_3_extend = {12'b0000_0000_0000, lut_approx_3};
wire [27:0] lut_approx_4_extend = {12'b0000_0000_0000, lut_approx_4};
wire [27:0] lut_approx_5_extend = {12'b0000_0000_0000, lut_approx_5};
wire [27:0] lut_approx_6_extend = {12'b0000_0000_0000, lut_approx_6};
wire [27:0] lut_approx_7_extend = {12'b0000_0000_0000, lut_approx_7};

wire [27:0] lut_approx_0_shift = lut_approx_0_extend << output_scale_shift;
wire [27:0] lut_approx_1_shift = lut_approx_1_extend << output_scale_shift;
wire [27:0] lut_approx_2_shift = lut_approx_2_extend << output_scale_shift;
wire [27:0] lut_approx_3_shift = lut_approx_3_extend << output_scale_shift;
wire [27:0] lut_approx_4_shift = lut_approx_4_extend << output_scale_shift;
wire [27:0] lut_approx_5_shift = lut_approx_5_extend << output_scale_shift;
wire [27:0] lut_approx_6_shift = lut_approx_6_extend << output_scale_shift;
wire [27:0] lut_approx_7_shift = lut_approx_7_extend << output_scale_shift;

wire [8-1:0] dout_q_0_pre = lut_approx_0_shift[27:16] >= 8'd255 ? 8'd255 : lut_approx_0_shift[15] && (lut_approx_0_shift[16] || lut_approx_0_shift[15:0]) ? lut_approx_0_shift[23:16] + 8'd1 : lut_approx_0_shift[23:16];
wire [8-1:0] dout_q_1_pre = lut_approx_1_shift[27:16] >= 8'd255 ? 8'd255 : lut_approx_1_shift[15] && (lut_approx_1_shift[16] || lut_approx_1_shift[15:0]) ? lut_approx_1_shift[23:16] + 8'd1 : lut_approx_1_shift[23:16];
wire [8-1:0] dout_q_2_pre = lut_approx_2_shift[27:16] >= 8'd255 ? 8'd255 : lut_approx_2_shift[15] && (lut_approx_2_shift[16] || lut_approx_2_shift[15:0]) ? lut_approx_2_shift[23:16] + 8'd1 : lut_approx_2_shift[23:16];
wire [8-1:0] dout_q_3_pre = lut_approx_3_shift[27:16] >= 8'd255 ? 8'd255 : lut_approx_3_shift[15] && (lut_approx_3_shift[16] || lut_approx_3_shift[15:0]) ? lut_approx_3_shift[23:16] + 8'd1 : lut_approx_3_shift[23:16];
wire [8-1:0] dout_q_4_pre = lut_approx_4_shift[27:16] >= 8'd255 ? 8'd255 : lut_approx_4_shift[15] && (lut_approx_4_shift[16] || lut_approx_4_shift[15:0]) ? lut_approx_4_shift[23:16] + 8'd1 : lut_approx_4_shift[23:16];
wire [8-1:0] dout_q_5_pre = lut_approx_5_shift[27:16] >= 8'd255 ? 8'd255 : lut_approx_5_shift[15] && (lut_approx_5_shift[16] || lut_approx_5_shift[15:0]) ? lut_approx_5_shift[23:16] + 8'd1 : lut_approx_5_shift[23:16];
wire [8-1:0] dout_q_6_pre = lut_approx_6_shift[27:16] >= 8'd255 ? 8'd255 : lut_approx_6_shift[15] && (lut_approx_6_shift[16] || lut_approx_6_shift[15:0]) ? lut_approx_6_shift[23:16] + 8'd1 : lut_approx_6_shift[23:16];
wire [8-1:0] dout_q_7_pre = lut_approx_7_shift[27:16] >= 8'd255 ? 8'd255 : lut_approx_7_shift[15] && (lut_approx_7_shift[16] || lut_approx_7_shift[15:0]) ? lut_approx_7_shift[23:16] + 8'd1 : lut_approx_7_shift[23:16];
// |(lut_approx_0_shift[27:20]) ? 8'd255 avoid upperbound overflow, but bitwidth has been increased, no longer needed

always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        dout_q_0 <= 'd0;
        dout_q_1 <= 'd0;
        dout_q_2 <= 'd0;
        dout_q_3 <= 'd0;
        dout_q_4 <= 'd0;
        dout_q_5 <= 'd0;
        dout_q_6 <= 'd0;
        dout_q_7 <= 'd0;
    end
    else if (sm_state == EU_STAGE_A) begin
        dout_q_0 <= dout_q_0_pre;
        dout_q_1 <= dout_q_1_pre;
        dout_q_2 <= dout_q_2_pre;
        dout_q_3 <= dout_q_3_pre;
        dout_q_4 <= dout_q_4_pre;
        dout_q_5 <= dout_q_5_pre;
        dout_q_6 <= dout_q_6_pre;
        dout_q_7 <= dout_q_7_pre;
    end
end

endmodule