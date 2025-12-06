`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/08 16:46:40
// Design Name: 
// Module Name: I_Layernorm
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



module spu_sm_block(
    input core_clk,
    input rst_n,

    input [2:0] sm_state,

    input comp_en,
    input comp_rst,
    input adder_tree_en,
    input reci_exp_sum_en,
    output reci_exp_sum_finish,

    input [3:0] sm_shift_input,
    input [4:0] sm_exp_shift_output,
    input [3:0] sm_shift_output,
    input signed [31:0] sm_b_data_in,
    output signed [31:0] sm_b_data_out
);
// sm state machine
localparam IDLE = 3'b000;
localparam EU_STAGE_A = 3'b001;
localparam RECI = 3'b011;
localparam EU_STAGE_B = 3'b100;
localparam MAX = 3'b101;

// decompose rdata for 8 processing units
reg signed [7:0] sm_process_data_0_pwl, sm_process_data_1_pwl, sm_process_data_2_pwl, sm_process_data_3_pwl;
always @(*) begin
    sm_process_data_0_pwl = sm_b_data_in[8*1-1:8*0];
    sm_process_data_1_pwl = sm_b_data_in[8*2-1:8*1];
    sm_process_data_2_pwl = sm_b_data_in[8*3-1:8*2];
    sm_process_data_3_pwl = sm_b_data_in[8*4-1:8*3];
end

// calculate max of x, 1 per token

wire signed [7:0] x_max;
spu_sm_xmax u_spu_sm_xmax(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_process_data_0(sm_process_data_0_pwl),
    .sm_process_data_1(sm_process_data_1_pwl),
    .sm_process_data_2(sm_process_data_2_pwl),
    .sm_process_data_3(sm_process_data_3_pwl),
    .max_comp(x_max)
    );

// calculate exp_out = exp(-(xmax - x))
// EU_A_in = xmax - x
// Stage A and B share logic structure but data flow might differ in context of pipeline, 
// here we reuse the logic for both stages since input is always sm_b_data_in
wire signed [8:0] sm_eu_process_data_0_pwl = sm_process_data_0_pwl - x_max;
wire signed [8:0] sm_eu_process_data_1_pwl = sm_process_data_1_pwl - x_max;
wire signed [8:0] sm_eu_process_data_2_pwl = sm_process_data_2_pwl - x_max;
wire signed [8:0] sm_eu_process_data_3_pwl = sm_process_data_3_pwl - x_max;

wire [7:0] sm_expu_data_out_0_pwl;
wire [7:0] sm_expu_data_out_1_pwl;
wire [7:0] sm_expu_data_out_2_pwl;
wire [7:0] sm_expu_data_out_3_pwl;
spu_sm_expu_approx u_spu_sm_expu_approx_pwl( 
    .core_clk(core_clk),
    .rst_n(rst_n),
    .sm_state(sm_state),
    .din_q_0(sm_eu_process_data_0_pwl),
    .din_q_1(sm_eu_process_data_1_pwl),
    .din_q_2(sm_eu_process_data_2_pwl),
    .din_q_3(sm_eu_process_data_3_pwl),
    .input_scale_shift(sm_shift_input),
    .output_scale_shift(sm_exp_shift_output[3:0]),
    .dout_q_0(sm_expu_data_out_0_pwl),
    .dout_q_1(sm_expu_data_out_1_pwl),
    .dout_q_2(sm_expu_data_out_2_pwl),
    .dout_q_3(sm_expu_data_out_3_pwl)
    );

wire [7:0] sm_expu_data_out_0 = sm_expu_data_out_0_pwl;
wire [7:0] sm_expu_data_out_1 = sm_expu_data_out_1_pwl;
wire [7:0] sm_expu_data_out_2 = sm_expu_data_out_2_pwl;
wire [7:0] sm_expu_data_out_3 = sm_expu_data_out_3_pwl;

wire [19:0] sm_sum_exp; // din: 8, num: 2048 -> 12 -> dout 8+12=20
spu_sm_addertree u_spu_sm_addertree(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .en(adder_tree_en),
    .x_0(sm_expu_data_out_0), // 至于eu_stage b的输入,就无所谓了，错了也没事
    .x_1(sm_expu_data_out_1),
    .x_2(sm_expu_data_out_2),
    .x_3(sm_expu_data_out_3),
    .dataOut(sm_sum_exp)
);


wire [20:0] div_data_out_unsigned;
spu_divider_unsign #(.DIVIDEND_DW(1),.DIVISOR_DW(20),.PRECISION_DW(20), .STAGE_LIST(21'b1010_1010_1010_1010_1010_1)) u_reci_exp_sum(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .data0(1'd1),
    .data1(sm_sum_exp), // 20'd1
    .div_vld(reci_exp_sum_en),
    .div_data_out(div_data_out_unsigned),
    .div_ack(reci_exp_sum_finish)
);

// Removed cache registers
// reg [7:0] sm_expu_cache_data_0, sm_expu_cache_data_1, sm_expu_cache_data_2, sm_expu_cache_data_3;

// In Stage B, we need to process the input data again through the exp unit
// Since the logic for sm_expu_data_out_* is combinational and depends on sm_b_data_in,
// we can directly use sm_expu_data_out_* for the multiplication.
// The input to multiplication should be the output of the EXP unit, which is already calculated above.

wire [28:0] sm_out_data_0_f_long;
wire [28:0] sm_out_data_1_f_long;
wire [28:0] sm_out_data_2_f_long;
wire [28:0] sm_out_data_3_f_long;

// Combinational logic for multiplication
assign sm_out_data_0_f_long = sm_expu_data_out_0 * div_data_out_unsigned; // 1,7,0 * 0,1,20 = 1,8,20
assign sm_out_data_1_f_long = sm_expu_data_out_1 * div_data_out_unsigned;
assign sm_out_data_2_f_long = sm_expu_data_out_2 * div_data_out_unsigned;
assign sm_out_data_3_f_long = sm_expu_data_out_3 * div_data_out_unsigned;

wire [12:0] sm_out_data_0_f = sm_out_data_0_f_long[20:8]; // 1,8,20 -> 1,12
wire [12:0] sm_out_data_1_f = sm_out_data_1_f_long[20:8];
wire [12:0] sm_out_data_2_f = sm_out_data_2_f_long[20:8];
wire [12:0] sm_out_data_3_f = sm_out_data_3_f_long[20:8];

// output quantization, shift by output scale shift
wire [27:0] sm_out_data_0_extend = sm_out_data_0_f <<< sm_shift_output; // 0,12 -> 8,12 not enough; 0,12 -> 16,12 may enough
wire [27:0] sm_out_data_1_extend = sm_out_data_1_f <<< sm_shift_output;
wire [27:0] sm_out_data_2_extend = sm_out_data_2_f <<< sm_shift_output;
wire [27:0] sm_out_data_3_extend = sm_out_data_3_f <<< sm_shift_output;

wire [8-1:0] sm_out_data_0_pre = sm_out_data_0_extend[27:12] >= 8'd127 ? 8'd127 : sm_out_data_0_extend[11] && (sm_out_data_0_extend[12] || sm_out_data_0_extend[10:0]) ? sm_out_data_0_extend[19:12] + 8'd1 : sm_out_data_0_extend[19:12];
wire [8-1:0] sm_out_data_1_pre = sm_out_data_1_extend[27:12] >= 8'd127 ? 8'd127 : sm_out_data_1_extend[11] && (sm_out_data_1_extend[12] || sm_out_data_1_extend[10:0]) ? sm_out_data_1_extend[19:12] + 8'd1 : sm_out_data_1_extend[19:12];
wire [8-1:0] sm_out_data_2_pre = sm_out_data_2_extend[27:12] >= 8'd127 ? 8'd127 : sm_out_data_2_extend[11] && (sm_out_data_2_extend[12] || sm_out_data_2_extend[10:0]) ? sm_out_data_2_extend[19:12] + 8'd1 : sm_out_data_2_extend[19:12];
wire [8-1:0] sm_out_data_3_pre = sm_out_data_3_extend[27:12] >= 8'd127 ? 8'd127 : sm_out_data_3_extend[11] && (sm_out_data_3_extend[12] || sm_out_data_3_extend[10:0]) ? sm_out_data_3_extend[19:12] + 8'd1 : sm_out_data_3_extend[19:12];

reg [8-1:0] sm_out_data_0;
reg [8-1:0] sm_out_data_1;
reg [8-1:0] sm_out_data_2;
reg [8-1:0] sm_out_data_3;

// Changed to combinational logic
always @(*) begin
    sm_out_data_0 = sm_out_data_0_pre;
    sm_out_data_1 = sm_out_data_1_pre;
    sm_out_data_2 = sm_out_data_2_pre;
    sm_out_data_3 = sm_out_data_3_pre;
end

// gather output data
assign sm_b_data_out = {sm_out_data_3, sm_out_data_2, sm_out_data_1, sm_out_data_0};
endmodule
