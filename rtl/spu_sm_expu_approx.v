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


module spu_sm_expu_approx(
    input core_clk,
    input rst_n,
    input [2:0] sm_state,
    input signed [8:0] din_q_0,
    input signed [8:0] din_q_1,
    input signed [8:0] din_q_2,
    input signed [8:0] din_q_3,
    input signed [8:0] din_q_4,
    input signed [8:0] din_q_5,
    input signed [8:0] din_q_6,
    input signed [8:0] din_q_7,
    input [3:0] input_scale_shift, // 0 ~ -8, usually s_i + s_o = -8
    input [3:0] output_scale_shift, // -8 ~ 0
    output [7:0] dout_q_0,
    output [7:0] dout_q_1,
    output [7:0] dout_q_2,
    output [7:0] dout_q_3,
    output [7:0] dout_q_4,
    output [7:0] dout_q_5,
    output [7:0] dout_q_6,
    output [7:0] dout_q_7
    );
// sm state machine
localparam IDLE = 3'b000;
localparam EU_STAGE_A = 3'b001;
localparam RECI = 3'b011; // now is the divider stage
localparam EU_STAGE_B = 3'b100;
localparam MAX = 3'b101;

wire signed [7:0] coeff_q [7:0]; // contains 1 sign bit, 1 integer bit, 6 decimal bits
wire signed [7:0] bias_f [7:0]; // contains 1 sign bit, 1 integer bit, 6 decimal bits, but store after config shifting
// didn't consider scale > 0, which will cause precision loss in bias_f
wire signed [7:0] break_points_f [6:0]; // contains 1 sign bit, 3 integer bits, 4 decimal bits
// seg_point = torch.tensor([-5.5, -3.3125, -2.375, -1.5625, -1.375, -0.75, -0.3125])
// coeff = torch.tensor([0.0, 0.015625, 0.0625, 0.140625, 0.234375, 0.359375, 0.59375, 0.859375])
// intercept = torch.tensor([0.0, 0.078125, 0.234375, 0.421875, 0.578125, 0.734375, 0.90625, 1.0])
assign break_points_f[0] = 8'b10101000;
assign break_points_f[1] = 8'b11001011;
assign break_points_f[2] = 8'b11011010;
assign break_points_f[3] = 8'b11100111;
assign break_points_f[4] = 8'b11101010;
assign break_points_f[5] = 8'b11110100;
assign break_points_f[6] = 8'b11111011;

assign coeff_q[0] = 8'b00000000; 
assign coeff_q[1] = 8'b00000001; 
assign coeff_q[2] = 8'b00000100; 
assign coeff_q[3] = 8'b00001001; 
assign coeff_q[4] = 8'b00001111; 
assign coeff_q[5] = 8'b00010111; 
assign coeff_q[6] = 8'b00100110; 
assign coeff_q[7] = 8'b00110111; 

assign bias_f[0] = 8'b00000000;
assign bias_f[1] = 8'b00000101;
assign bias_f[2] = 8'b00001111;
assign bias_f[3] = 8'b00011011;
assign bias_f[4] = 8'b00100101;
assign bias_f[5] = 8'b00101111;
assign bias_f[6] = 8'b00111010;
assign bias_f[7] = 8'b01000000;


wire signed [15:0] break_points_q_extend [6:0];
assign break_points_q_extend[0] = {8'b1111_1111, break_points_f[0]} << input_scale_shift; // 1, 3, 4 -> 1, 11, 4
assign break_points_q_extend[1] = {8'b1111_1111, break_points_f[1]} << input_scale_shift;
assign break_points_q_extend[2] = {8'b1111_1111, break_points_f[2]} << input_scale_shift;
assign break_points_q_extend[3] = {8'b1111_1111, break_points_f[3]} << input_scale_shift;
assign break_points_q_extend[4] = {8'b1111_1111, break_points_f[4]} << input_scale_shift;
assign break_points_q_extend[5] = {8'b1111_1111, break_points_f[5]} << input_scale_shift;
assign break_points_q_extend[6] = {8'b1111_1111, break_points_f[6]} << input_scale_shift;

reg signed [8:0] break_points_q_0;
reg signed [8:0] break_points_q_1;
reg signed [8:0] break_points_q_2;
reg signed [8:0] break_points_q_3;
reg signed [8:0] break_points_q_4;
reg signed [8:0] break_points_q_5;
reg signed [8:0] break_points_q_6;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        break_points_q_0 <= 'd0;
        break_points_q_1 <= 'd0;
        break_points_q_2 <= 'd0;
        break_points_q_3 <= 'd0;
        break_points_q_4 <= 'd0;
        break_points_q_5 <= 'd0;
        break_points_q_6 <= 'd0;
    end
    else if (sm_state == EU_STAGE_A) begin
        break_points_q_0 <= break_points_q_extend[0][15:4] < -9'd255 ? -9'd256 : break_points_q_extend[0][12:4];
        break_points_q_1 <= break_points_q_extend[1][15:4] < -9'd255 ? -9'd256 : break_points_q_extend[1][12:4];
        break_points_q_2 <= break_points_q_extend[2][15:4] < -9'd255 ? -9'd256 : break_points_q_extend[2][12:4];
        break_points_q_3 <= break_points_q_extend[3][15:4] < -9'd255 ? -9'd256 : break_points_q_extend[3][12:4];
        break_points_q_4 <= break_points_q_extend[4][15:4] < -9'd255 ? -9'd256 : break_points_q_extend[4][12:4];
        break_points_q_5 <= break_points_q_extend[5][15:4] < -9'd255 ? -9'd256 : break_points_q_extend[5][12:4];
        break_points_q_6 <= break_points_q_extend[6][15:4] < -9'd255 ? -9'd256 : break_points_q_extend[6][12:4];
    end
end

wire signed [15:0] bias_q_0;
wire signed [15:0] bias_q_1;
wire signed [15:0] bias_q_2;
wire signed [15:0] bias_q_3;
wire signed [15:0] bias_q_4;
wire signed [15:0] bias_q_5;
wire signed [15:0] bias_q_6;
wire signed [15:0] bias_q_7;
assign bias_q_0 = {8'b0000_0000, bias_f[0]} << input_scale_shift;
assign bias_q_1 = {8'b0000_0000, bias_f[1]} << input_scale_shift;
assign bias_q_2 = {8'b0000_0000, bias_f[2]} << input_scale_shift;
assign bias_q_3 = {8'b0000_0000, bias_f[3]} << input_scale_shift;
assign bias_q_4 = {8'b0000_0000, bias_f[4]} << input_scale_shift;
assign bias_q_5 = {8'b0000_0000, bias_f[5]} << input_scale_shift;
assign bias_q_6 = {8'b0000_0000, bias_f[6]} << input_scale_shift;
assign bias_q_7 = {8'b0000_0000, bias_f[7]} << input_scale_shift;


wire signed [7:0] coeff_q_0;
wire signed [7:0] coeff_q_1;
wire signed [7:0] coeff_q_2;
wire signed [7:0] coeff_q_3;
wire signed [7:0] coeff_q_4;
wire signed [7:0] coeff_q_5;
wire signed [7:0] coeff_q_6;
wire signed [7:0] coeff_q_7;
assign coeff_q_0 = coeff_q[0]; 
assign coeff_q_1 = coeff_q[1]; 
assign coeff_q_2 = coeff_q[2]; 
assign coeff_q_3 = coeff_q[3]; 
assign coeff_q_4 = coeff_q[4]; 
assign coeff_q_5 = coeff_q[5]; 
assign coeff_q_6 = coeff_q[6]; 
assign coeff_q_7 = coeff_q[7]; 

spu_sm_expu_pwl u_spu_sm_expu_pwl_0(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .sm_state(sm_state),
    .din_q(din_q_0),
    .dout_q(dout_q_0),
    .break_points_q_0(break_points_q_0),
    .break_points_q_1(break_points_q_1),
    .break_points_q_2(break_points_q_2),
    .break_points_q_3(break_points_q_3),
    .break_points_q_4(break_points_q_4),
    .break_points_q_5(break_points_q_5),
    .break_points_q_6(break_points_q_6),
    .bias_q_0(bias_q_0),
    .bias_q_1(bias_q_1),
    .bias_q_2(bias_q_2),
    .bias_q_3(bias_q_3),
    .bias_q_4(bias_q_4),
    .bias_q_5(bias_q_5),
    .bias_q_6(bias_q_6),
    .bias_q_7(bias_q_7),
    .coeff_q_0(coeff_q_0),
    .coeff_q_1(coeff_q_1),
    .coeff_q_2(coeff_q_2),
    .coeff_q_3(coeff_q_3),
    .coeff_q_4(coeff_q_4),
    .coeff_q_5(coeff_q_5),
    .coeff_q_6(coeff_q_6),
    .coeff_q_7(coeff_q_7),
    .output_scale_shift(output_scale_shift)
);

spu_sm_expu_pwl u_spu_sm_expu_pwl_1(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .sm_state(sm_state),
    .din_q(din_q_1),
    .dout_q(dout_q_1),
    .break_points_q_0(break_points_q_0),
    .break_points_q_1(break_points_q_1),
    .break_points_q_2(break_points_q_2),
    .break_points_q_3(break_points_q_3),
    .break_points_q_4(break_points_q_4),
    .break_points_q_5(break_points_q_5),
    .break_points_q_6(break_points_q_6),
    .bias_q_0(bias_q_0),
    .bias_q_1(bias_q_1),
    .bias_q_2(bias_q_2),
    .bias_q_3(bias_q_3),
    .bias_q_4(bias_q_4),
    .bias_q_5(bias_q_5),
    .bias_q_6(bias_q_6),
    .bias_q_7(bias_q_7),
    .coeff_q_0(coeff_q_0),
    .coeff_q_1(coeff_q_1),
    .coeff_q_2(coeff_q_2),
    .coeff_q_3(coeff_q_3),
    .coeff_q_4(coeff_q_4),
    .coeff_q_5(coeff_q_5),
    .coeff_q_6(coeff_q_6),
    .coeff_q_7(coeff_q_7),
    .output_scale_shift(output_scale_shift)
);

spu_sm_expu_pwl u_spu_sm_expu_pwl_2(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .sm_state(sm_state),
    .din_q(din_q_2),
    .dout_q(dout_q_2),
    .break_points_q_0(break_points_q_0),
    .break_points_q_1(break_points_q_1),
    .break_points_q_2(break_points_q_2),
    .break_points_q_3(break_points_q_3),
    .break_points_q_4(break_points_q_4),
    .break_points_q_5(break_points_q_5),
    .break_points_q_6(break_points_q_6),
    .bias_q_0(bias_q_0),
    .bias_q_1(bias_q_1),
    .bias_q_2(bias_q_2),
    .bias_q_3(bias_q_3),
    .bias_q_4(bias_q_4),
    .bias_q_5(bias_q_5),
    .bias_q_6(bias_q_6),
    .bias_q_7(bias_q_7),
    .coeff_q_0(coeff_q_0),
    .coeff_q_1(coeff_q_1),
    .coeff_q_2(coeff_q_2),
    .coeff_q_3(coeff_q_3),
    .coeff_q_4(coeff_q_4),
    .coeff_q_5(coeff_q_5),
    .coeff_q_6(coeff_q_6),
    .coeff_q_7(coeff_q_7),
    .output_scale_shift(output_scale_shift)
);

spu_sm_expu_pwl u_spu_sm_expu_pwl_3(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .sm_state(sm_state),
    .din_q(din_q_3),
    .dout_q(dout_q_3),
    .break_points_q_0(break_points_q_0),
    .break_points_q_1(break_points_q_1),
    .break_points_q_2(break_points_q_2),
    .break_points_q_3(break_points_q_3),
    .break_points_q_4(break_points_q_4),
    .break_points_q_5(break_points_q_5),
    .break_points_q_6(break_points_q_6),
    .bias_q_0(bias_q_0),
    .bias_q_1(bias_q_1),
    .bias_q_2(bias_q_2),
    .bias_q_3(bias_q_3),
    .bias_q_4(bias_q_4),
    .bias_q_5(bias_q_5),
    .bias_q_6(bias_q_6),
    .bias_q_7(bias_q_7),
    .coeff_q_0(coeff_q_0),
    .coeff_q_1(coeff_q_1),
    .coeff_q_2(coeff_q_2),
    .coeff_q_3(coeff_q_3),
    .coeff_q_4(coeff_q_4),
    .coeff_q_5(coeff_q_5),
    .coeff_q_6(coeff_q_6),
    .coeff_q_7(coeff_q_7),
    .output_scale_shift(output_scale_shift)
);

spu_sm_expu_pwl u_spu_sm_expu_pwl_4(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .sm_state(sm_state),
    .din_q(din_q_4),
    .dout_q(dout_q_4),
    .break_points_q_0(break_points_q_0),
    .break_points_q_1(break_points_q_1),
    .break_points_q_2(break_points_q_2),
    .break_points_q_3(break_points_q_3),
    .break_points_q_4(break_points_q_4),
    .break_points_q_5(break_points_q_5),
    .break_points_q_6(break_points_q_6),
    .bias_q_0(bias_q_0),
    .bias_q_1(bias_q_1),
    .bias_q_2(bias_q_2),
    .bias_q_3(bias_q_3),
    .bias_q_4(bias_q_4),
    .bias_q_5(bias_q_5),
    .bias_q_6(bias_q_6),
    .bias_q_7(bias_q_7),
    .coeff_q_0(coeff_q_0),
    .coeff_q_1(coeff_q_1),
    .coeff_q_2(coeff_q_2),
    .coeff_q_3(coeff_q_3),
    .coeff_q_4(coeff_q_4),
    .coeff_q_5(coeff_q_5),
    .coeff_q_6(coeff_q_6),
    .coeff_q_7(coeff_q_7),
    .output_scale_shift(output_scale_shift)
);

spu_sm_expu_pwl u_spu_sm_expu_pwl_5(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .sm_state(sm_state),
    .din_q(din_q_5),
    .dout_q(dout_q_5),
    .break_points_q_0(break_points_q_0),
    .break_points_q_1(break_points_q_1),
    .break_points_q_2(break_points_q_2),
    .break_points_q_3(break_points_q_3),
    .break_points_q_4(break_points_q_4),
    .break_points_q_5(break_points_q_5),
    .break_points_q_6(break_points_q_6),
    .bias_q_0(bias_q_0),
    .bias_q_1(bias_q_1),
    .bias_q_2(bias_q_2),
    .bias_q_3(bias_q_3),
    .bias_q_4(bias_q_4),
    .bias_q_5(bias_q_5),
    .bias_q_6(bias_q_6),
    .bias_q_7(bias_q_7),
    .coeff_q_0(coeff_q_0),
    .coeff_q_1(coeff_q_1),
    .coeff_q_2(coeff_q_2),
    .coeff_q_3(coeff_q_3),
    .coeff_q_4(coeff_q_4),
    .coeff_q_5(coeff_q_5),
    .coeff_q_6(coeff_q_6),
    .coeff_q_7(coeff_q_7),
    .output_scale_shift(output_scale_shift)
);

spu_sm_expu_pwl u_spu_sm_expu_pwl_6(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .sm_state(sm_state),
    .din_q(din_q_6),
    .dout_q(dout_q_6),
    .break_points_q_0(break_points_q_0),
    .break_points_q_1(break_points_q_1),
    .break_points_q_2(break_points_q_2),
    .break_points_q_3(break_points_q_3),
    .break_points_q_4(break_points_q_4),
    .break_points_q_5(break_points_q_5),
    .break_points_q_6(break_points_q_6),
    .bias_q_0(bias_q_0),
    .bias_q_1(bias_q_1),
    .bias_q_2(bias_q_2),
    .bias_q_3(bias_q_3),
    .bias_q_4(bias_q_4),
    .bias_q_5(bias_q_5),
    .bias_q_6(bias_q_6),
    .bias_q_7(bias_q_7),
    .coeff_q_0(coeff_q_0),
    .coeff_q_1(coeff_q_1),
    .coeff_q_2(coeff_q_2),
    .coeff_q_3(coeff_q_3),
    .coeff_q_4(coeff_q_4),
    .coeff_q_5(coeff_q_5),
    .coeff_q_6(coeff_q_6),
    .coeff_q_7(coeff_q_7),
    .output_scale_shift(output_scale_shift)
);

spu_sm_expu_pwl u_spu_sm_expu_pwl_7(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .sm_state(sm_state),
    .din_q(din_q_7),
    .dout_q(dout_q_7),
    .break_points_q_0(break_points_q_0),
    .break_points_q_1(break_points_q_1),
    .break_points_q_2(break_points_q_2),
    .break_points_q_3(break_points_q_3),
    .break_points_q_4(break_points_q_4),
    .break_points_q_5(break_points_q_5),
    .break_points_q_6(break_points_q_6),
    .bias_q_0(bias_q_0),
    .bias_q_1(bias_q_1),
    .bias_q_2(bias_q_2),
    .bias_q_3(bias_q_3),
    .bias_q_4(bias_q_4),
    .bias_q_5(bias_q_5),
    .bias_q_6(bias_q_6),
    .bias_q_7(bias_q_7),
    .coeff_q_0(coeff_q_0),
    .coeff_q_1(coeff_q_1),
    .coeff_q_2(coeff_q_2),
    .coeff_q_3(coeff_q_3),
    .coeff_q_4(coeff_q_4),
    .coeff_q_5(coeff_q_5),
    .coeff_q_6(coeff_q_6),
    .coeff_q_7(coeff_q_7),
    .output_scale_shift(output_scale_shift)
);

endmodule