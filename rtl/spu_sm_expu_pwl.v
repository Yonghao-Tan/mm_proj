`timescale 1ns / 1ps


module spu_sm_expu_pwl(
	input signed [8:0] break_points_q_0,
	input signed [8:0] break_points_q_1,
	input signed [8:0] break_points_q_2,
	input signed [8:0] break_points_q_3,
	input signed [8:0] break_points_q_4,
	input signed [8:0] break_points_q_5,
	input signed [8:0] break_points_q_6,
	input signed [15:0] bias_q_0,
	input signed [15:0] bias_q_1,
	input signed [15:0] bias_q_2,
	input signed [15:0] bias_q_3,
	input signed [15:0] bias_q_4,
	input signed [15:0] bias_q_5,
	input signed [15:0] bias_q_6,
	input signed [15:0] bias_q_7,
	input signed [7:0] coeff_q_0,
	input signed [7:0] coeff_q_1,
	input signed [7:0] coeff_q_2,
	input signed [7:0] coeff_q_3,
	input signed [7:0] coeff_q_4,
	input signed [7:0] coeff_q_5,
	input signed [7:0] coeff_q_6,
	input signed [7:0] coeff_q_7,
	input [3:0] output_scale_shift,
	input signed [8:0] din_q,
	output reg [7:0] dout_q // clamp (0, ~)
);
// sm state machine
localparam IDLE = 3'b000;
localparam EU_STAGE_A = 3'b001;
localparam RECI = 3'b011; // now is the divider stage
localparam EU_STAGE_B = 3'b100;
localparam MAX = 3'b101;

wire signed [7:0] coeff_q [7:0];
assign coeff_q[0] = coeff_q_0;
assign coeff_q[1] = coeff_q_1;
assign coeff_q[2] = coeff_q_2;
assign coeff_q[3] = coeff_q_3;
assign coeff_q[4] = coeff_q_4;
assign coeff_q[5] = coeff_q_5;
assign coeff_q[6] = coeff_q_6;
assign coeff_q[7] = coeff_q_7;

wire signed [15:0] bias_q [7:0];
assign bias_q[0] = bias_q_0;
assign bias_q[1] = bias_q_1;
assign bias_q[2] = bias_q_2;
assign bias_q[3] = bias_q_3;
assign bias_q[4] = bias_q_4;
assign bias_q[5] = bias_q_5;
assign bias_q[6] = bias_q_6;
assign bias_q[7] = bias_q_7;

wire [7:0] comp_case;
assign comp_case[0] = din_q < break_points_q_0;
assign comp_case[1] = din_q < break_points_q_1;
assign comp_case[2] = din_q < break_points_q_2;
assign comp_case[3] = din_q < break_points_q_3;
assign comp_case[4] = din_q < break_points_q_4;
assign comp_case[5] = din_q < break_points_q_5;
assign comp_case[6] = din_q < break_points_q_6;
assign comp_case[7] = din_q >=  break_points_q_6;

reg [2:0] index;
// Changed to combinational logic
always @(*) begin
    casex(comp_case)
        8'bxxxxxxx1: index = 3'd0;
        8'bxxxxxx10: index = 3'd1;
        8'bxxxxx100: index = 3'd2;
        8'bxxxx1000: index = 3'd3;
        8'bxxx10000: index = 3'd4;
        8'bxx100000: index = 3'd5;
        8'bx1000000: index = 3'd6;
        8'b10000000: index = 3'd7;
        default: index = 3'd0;
    endcase
end

// Removed registers for pipeline stages, now direct calculation
wire signed [15:0] dout_f;
assign dout_f = coeff_q[index] * din_q + bias_q[index]; 

wire [18:0] dout_f_extend = dout_f[15] ? 19'd0 : {4'b0000, dout_f[14:0]}; // clamp lowerbound 0; 1, 9, 6 -> 9, 6 -> 13, 6

wire [18:0] dout_f_shift = dout_f_extend << output_scale_shift; // 9, 11

wire [7:0] dout_q_pre = dout_f_shift[18:6] >= 8'd255 ? 8'd255 : dout_f_shift[5] && (dout_f_shift[6] || dout_f_shift[4:0]) ? dout_f_shift[13:6] + 8'd1 : dout_f_shift[13:6];
// |(lut_approx_0_shift[27:20]) ? 8'd255 avoid upperbound overflow, but bitwidth has been increased, no longer needed

// Changed output to combinational logic (or keep as wire if module interface allows, but here it's reg in port list so I'll use always @(*))
always @(*) begin
    dout_q = dout_q_pre;
end

endmodule
