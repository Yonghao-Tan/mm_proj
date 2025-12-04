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



module spu_ln_block(
    input core_clk,
    input rst_n,

    input [7:0] pad_en,
    input ln_op,
    input [2:0] ln_state,
    input sum_div_cnt,
    input [7:0] sqrt_cnt,

    input sum_en,
    input [3:0] ln_shift_output, // assume to be left shift only, since it is impossible that the ln_output > 127
    input [6:0] ln_div_m,
    input [4:0] ln_div_e,

    output sum_div_finish,
    output sqrt_reci_finish,

    input [63:0] ln_b_data_in,
    output [63:0] ln_b_data_out
);

// ln state machine
localparam IDLE = 3'b000;
localparam SUM_COUNT = 3'b001;
localparam SUM_DIV = 3'b011;
localparam SQRT = 3'b100;
localparam OUT = 3'b110;

// other params
localparam OPLENGTH = 2048;
localparam MAX_WIDTH = 2*8;
localparam SQRT_INFO = (MAX_WIDTH+(MAX_WIDTH%2))/2+2;

// decompose rdata for 8 processing units
reg signed [8-1:0] ln_process_data_0, ln_process_data_1, ln_process_data_2, ln_process_data_3, ln_process_data_4, ln_process_data_5, ln_process_data_6, ln_process_data_7;
always @(*) begin
    ln_process_data_0 = pad_en[0] ? 8'd0 : ln_b_data_in[8*1-1:8*0];
    ln_process_data_1 = pad_en[1] ? 8'd0 : ln_b_data_in[8*2-1:8*1];
    ln_process_data_2 = pad_en[2] ? 8'd0 : ln_b_data_in[8*3-1:8*2];
    ln_process_data_3 = pad_en[3] ? 8'd0 : ln_b_data_in[8*4-1:8*3];
    ln_process_data_4 = pad_en[4] ? 8'd0 : ln_b_data_in[8*5-1:8*4];
    ln_process_data_5 = pad_en[5] ? 8'd0 : ln_b_data_in[8*6-1:8*5];
    ln_process_data_6 = pad_en[6] ? 8'd0 : ln_b_data_in[8*7-1:8*6];
    ln_process_data_7 = pad_en[7] ? 8'd0 : ln_b_data_in[8*8-1:8*7];
end

// var(x) = E(x^2) - E^2(x)
// E(x) = mean(sum(x)), process sum(x) here: 8 inputs in one group per cycle
wire signed [8-1+1+1+1:0] ln_sumx_process_data = ln_process_data_0+ln_process_data_1+ln_process_data_2+ln_process_data_3+ln_process_data_4+ln_process_data_5+ln_process_data_6+ln_process_data_7;
reg signed [8-1+1+1+1:0] ln_sumx_process_data_reg;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) ln_sumx_process_data_reg <= 'd0;
    else if (ln_state == SUM_COUNT) ln_sumx_process_data_reg <= ln_sumx_process_data;
end
// pipeline 2, < 128chars per line
// E(x^2) = mean(sum(x^2)), process sum(x^2) here
reg [16:0] ln_x2_stage_1_0, ln_x2_stage_1_1, ln_x2_stage_1_2, ln_x2_stage_1_3;
wire [18:0] ln_x2_process_data;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        ln_x2_stage_1_0 <= 'd0;
        ln_x2_stage_1_1 <= 'd0;
        ln_x2_stage_1_2 <= 'd0;
        ln_x2_stage_1_3 <= 'd0;
    end
    else if (ln_state == SUM_COUNT) begin
        ln_x2_stage_1_0 <= ln_process_data_0*ln_process_data_0+ln_process_data_1*ln_process_data_1;
        ln_x2_stage_1_1 <= ln_process_data_2*ln_process_data_2+ln_process_data_3*ln_process_data_3;
        ln_x2_stage_1_2 <= ln_process_data_4*ln_process_data_4+ln_process_data_5*ln_process_data_5;
        ln_x2_stage_1_3 <= ln_process_data_6*ln_process_data_6+ln_process_data_7*ln_process_data_7;
    end
end
assign ln_x2_process_data = ln_x2_stage_1_0 + ln_x2_stage_1_1 + ln_x2_stage_1_2 + ln_x2_stage_1_3;
// wire [2*8-1+1+1+1:0] ln_x2_process_data = ln_process_data_0*ln_process_data_0+ln_process_data_1*ln_process_data_1+
//                                 ln_process_data_2*ln_process_data_2+ln_process_data_3*ln_process_data_3+ln_process_data_4*ln_process_data_4+
//                                 ln_process_data_5*ln_process_data_5+ln_process_data_6*ln_process_data_6+ln_process_data_7*ln_process_data_7;

// definition of sum registors
reg signed [$clog2(OPLENGTH)+8-1:0] x_sum;
reg [$clog2(OPLENGTH)+2*8-1:0] x_square_sum;

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) x_sum <= 'd0;
    else if (sum_en) x_sum <= x_sum + ln_sumx_process_data_reg;
    else if (ln_state == OUT) x_sum <= 'd0; // reset
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) x_square_sum <= 'd0;
    else if (sum_en) x_square_sum <= x_square_sum + ln_x2_process_data;
    else if (ln_state == OUT) x_square_sum <= 'd0; // reset
end

// definition of mean signals (haved pulse in dividers)
// E(x) = mean(sum(x)), process mean(sum(x)) here

reg signed [17+7-1:0] x_sum_m;
wire signed [7:0] ln_div_m_signed = {1'b0, ln_div_m};
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) x_sum_m <= 'd0;
    else if (ln_state == SUM_DIV && sum_div_cnt == 'd0) x_sum_m <= x_sum * ln_div_m_signed;
end

wire signed [17+7+31-1:0] x_sum_m_extend = {x_sum_m, {31{1'b0}}};
wire signed [17+7+31-1:0] x_sum_m_e = x_sum_m_extend >>> ln_div_e; // 24, 31
reg signed [8-1+2:0] x_mean; // 8, 2
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) x_mean <= 'd0;
    else if (ln_state == SUM_DIV && sum_div_cnt == 'd1) x_mean <= x_sum_m_e[38:29];
    // else x_mean_test <= x_sum_m >>> ln_div_e;
end

// E(x^2) = mean(sum(x^2)), process mean(sum(x^2)) here
reg [25+7-1:0] x_square_sum_m;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) x_square_sum_m <= 'd0;
    else if (ln_state == SUM_DIV && sum_div_cnt == 'd0) x_square_sum_m <= x_square_sum * ln_div_m;
end

wire [25+7+31-1:0] x_square_sum_m_extend = {x_square_sum_m, {31{1'b0}}};
wire [25+7+31-1:0] x_square_sum_m_e = x_square_sum_m_extend >>> ln_div_e; // 24, 31
reg [2*8+4-1:0] x_square_mean; // 8, 2
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) x_square_mean <= 'd0;
    else if (ln_state == SUM_DIV && sum_div_cnt == 'd1) x_square_mean <= x_square_sum_m_e[46:27];
    // else x_square_mean_test <= x_sum_m >>> ln_div_e;
end

assign sum_div_finish = ln_state == SUM_DIV && sum_div_cnt == 'd1;

// process E^2(x) here
wire [2*8-1+4:0] x_mean_square = x_mean * x_mean;

// process var(x) = E(x^2) - E^2(x) here
wire [MAX_WIDTH-1+4:0] var_in = ln_op ? x_square_mean : x_square_mean - x_mean_square;

// process std(x) = sqrt(var(x)) here
wire [SQRT_INFO-1+2:0] sqrt_out;
wire sqrt_finish;
spu_ln_sqrt #(MAX_WIDTH+4+4) u_spu_ln_sqrt(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .din_i({var_in,4'b0001}),
    .din_valid_i(ln_state == SQRT && sqrt_cnt == 8'd0),
    .sqrt_o(sqrt_out),
    .sqrt_finish(sqrt_finish)
);

// out = (x-mean) * 1/std(x)
// process 1/std(x) here
wire [18:0] div_data_out_unsigned; // 0 | 1+4 | 14 for sign | integer | decimal
spu_divider_unsign #(.DIVIDEND_DW(1),.DIVISOR_DW(12),.PRECISION_DW(18), .STAGE_LIST(19'b1010_1010_1010_1010_101)) u_reci_sqrt(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .data0(1'd1),
    .data1(sqrt_out),
    .div_vld(ln_state == SQRT && sqrt_finish),
    .div_data_out(div_data_out_unsigned),
    .div_ack(sqrt_reci_finish)
);

// process x-mean here
wire signed [10-1:0] ln_post_data_0 = {ln_process_data_0, 2'b00};
wire signed [10-1:0] ln_post_data_1 = {ln_process_data_1, 2'b00};
wire signed [10-1:0] ln_post_data_2 = {ln_process_data_2, 2'b00};
wire signed [10-1:0] ln_post_data_3 = {ln_process_data_3, 2'b00};
wire signed [10-1:0] ln_post_data_4 = {ln_process_data_4, 2'b00};
wire signed [10-1:0] ln_post_data_5 = {ln_process_data_5, 2'b00};
wire signed [10-1:0] ln_post_data_6 = {ln_process_data_6, 2'b00};
wire signed [10-1:0] ln_post_data_7 = {ln_process_data_7, 2'b00};
wire signed [10:0] x_minus_mean_0 = (ln_op || pad_en[0]) ? ln_post_data_0 : ln_post_data_0 - x_mean; // 1 | 8 | 2
wire signed [10:0] x_minus_mean_1 = (ln_op || pad_en[1]) ? ln_post_data_1 : ln_post_data_1 - x_mean;
wire signed [10:0] x_minus_mean_2 = (ln_op || pad_en[2]) ? ln_post_data_2 : ln_post_data_2 - x_mean;
wire signed [10:0] x_minus_mean_3 = (ln_op || pad_en[3]) ? ln_post_data_3 : ln_post_data_3 - x_mean;
wire signed [10:0] x_minus_mean_4 = (ln_op || pad_en[4]) ? ln_post_data_4 : ln_post_data_4 - x_mean;
wire signed [10:0] x_minus_mean_5 = (ln_op || pad_en[5]) ? ln_post_data_5 : ln_post_data_5 - x_mean;
wire signed [10:0] x_minus_mean_6 = (ln_op || pad_en[6]) ? ln_post_data_6 : ln_post_data_6 - x_mean;
wire signed [10:0] x_minus_mean_7 = (ln_op || pad_en[7]) ? ln_post_data_7 : ln_post_data_7 - x_mean;


wire signed [19:0] div_data_out_signed = {1'b0, div_data_out_unsigned}; // extend to signed, 1 | 5 | 14

reg signed [30:0] quotient_out_0_extend;
reg signed [30:0] quotient_out_1_extend;
reg signed [30:0] quotient_out_2_extend;
reg signed [30:0] quotient_out_3_extend;
reg signed [30:0] quotient_out_4_extend;
reg signed [30:0] quotient_out_5_extend;
reg signed [30:0] quotient_out_6_extend;
reg signed [30:0] quotient_out_7_extend;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        quotient_out_0_extend <= 'd0;
        quotient_out_1_extend <= 'd0;
        quotient_out_2_extend <= 'd0;
        quotient_out_3_extend <= 'd0;
        quotient_out_4_extend <= 'd0;
        quotient_out_5_extend <= 'd0;
        quotient_out_6_extend <= 'd0;
        quotient_out_7_extend <= 'd0;
    end
    else if (ln_state == OUT) begin
        quotient_out_0_extend <= div_data_out_signed * x_minus_mean_0; // 2 | 13 | 16
        quotient_out_1_extend <= div_data_out_signed * x_minus_mean_1;
        quotient_out_2_extend <= div_data_out_signed * x_minus_mean_2;
        quotient_out_3_extend <= div_data_out_signed * x_minus_mean_3;
        quotient_out_4_extend <= div_data_out_signed * x_minus_mean_4;
        quotient_out_5_extend <= div_data_out_signed * x_minus_mean_5;
        quotient_out_6_extend <= div_data_out_signed * x_minus_mean_6;
        quotient_out_7_extend <= div_data_out_signed * x_minus_mean_7;
    end
end

wire signed [30:0] quotient_out_0 = quotient_out_0_extend;
wire signed [30:0] quotient_out_1 = quotient_out_1_extend;
wire signed [30:0] quotient_out_2 = quotient_out_2_extend;
wire signed [30:0] quotient_out_3 = quotient_out_3_extend;
wire signed [30:0] quotient_out_4 = quotient_out_4_extend;
wire signed [30:0] quotient_out_5 = quotient_out_5_extend;
wire signed [30:0] quotient_out_6 = quotient_out_6_extend;
wire signed [30:0] quotient_out_7 = quotient_out_7_extend;

wire signed [17:0] ln_f_0 = quotient_out_0[21:4]; // 1 | 5 | 12
wire signed [17:0] ln_f_1 = quotient_out_1[21:4];
wire signed [17:0] ln_f_2 = quotient_out_2[21:4];
wire signed [17:0] ln_f_3 = quotient_out_3[21:4];
wire signed [17:0] ln_f_4 = quotient_out_4[21:4];
wire signed [17:0] ln_f_5 = quotient_out_5[21:4];
wire signed [17:0] ln_f_6 = quotient_out_6[21:4];
wire signed [17:0] ln_f_7 = quotient_out_7[21:4];

wire signed [25:0] ln_f_extend_0 = ln_f_0 << ln_shift_output; // 1,13,12 may enough
wire signed [25:0] ln_f_extend_1 = ln_f_1 << ln_shift_output; // 1,13,12 may enough
wire signed [25:0] ln_f_extend_2 = ln_f_2 << ln_shift_output; // 1,13,12 may enough
wire signed [25:0] ln_f_extend_3 = ln_f_3 << ln_shift_output; // 1,13,12 may enough
wire signed [25:0] ln_f_extend_4 = ln_f_4 << ln_shift_output; // 1,13,12 may enough
wire signed [25:0] ln_f_extend_5 = ln_f_5 << ln_shift_output; // 1,13,12 may enough
wire signed [25:0] ln_f_extend_6 = ln_f_6 << ln_shift_output; // 1,13,12 may enough
wire signed [25:0] ln_f_extend_7 = ln_f_7 << ln_shift_output; // 1,13,12 may enough

wire signed [13:0] ln_f_clamp_judge_0 = ln_f_extend_0[25:12];
wire signed [13:0] ln_f_clamp_judge_1 = ln_f_extend_1[25:12];
wire signed [13:0] ln_f_clamp_judge_2 = ln_f_extend_2[25:12];
wire signed [13:0] ln_f_clamp_judge_3 = ln_f_extend_3[25:12];
wire signed [13:0] ln_f_clamp_judge_4 = ln_f_extend_4[25:12];
wire signed [13:0] ln_f_clamp_judge_5 = ln_f_extend_5[25:12];
wire signed [13:0] ln_f_clamp_judge_6 = ln_f_extend_6[25:12];
wire signed [13:0] ln_f_clamp_judge_7 = ln_f_extend_7[25:12];

wire ln_clamp_pos_flag_0 = ln_f_clamp_judge_0 >= 127;
wire ln_clamp_pos_flag_1 = ln_f_clamp_judge_1 >= 127;
wire ln_clamp_pos_flag_2 = ln_f_clamp_judge_2 >= 127;
wire ln_clamp_pos_flag_3 = ln_f_clamp_judge_3 >= 127;
wire ln_clamp_pos_flag_4 = ln_f_clamp_judge_4 >= 127;
wire ln_clamp_pos_flag_5 = ln_f_clamp_judge_5 >= 127;
wire ln_clamp_pos_flag_6 = ln_f_clamp_judge_6 >= 127;
wire ln_clamp_pos_flag_7 = ln_f_clamp_judge_7 >= 127;

wire ln_clamp_neg_flag_0 = ln_f_clamp_judge_0 <= -129; // 1218, clamp error, priority
wire ln_clamp_neg_flag_1 = ln_f_clamp_judge_1 <= -129;
wire ln_clamp_neg_flag_2 = ln_f_clamp_judge_2 <= -129;
wire ln_clamp_neg_flag_3 = ln_f_clamp_judge_3 <= -129;
wire ln_clamp_neg_flag_4 = ln_f_clamp_judge_4 <= -129;
wire ln_clamp_neg_flag_5 = ln_f_clamp_judge_5 <= -129;
wire ln_clamp_neg_flag_6 = ln_f_clamp_judge_6 <= -129;
wire ln_clamp_neg_flag_7 = ln_f_clamp_judge_7 <= -129;

wire signed [7:0] ln_q_pos_round_0 = ln_f_extend_0[11] && (ln_f_extend_0[12] || ln_f_extend_0[10:0]) ? ln_f_extend_0[19:12] + 8'd1 : ln_f_extend_0[19:12];
wire signed [7:0] ln_q_pos_round_1 = ln_f_extend_1[11] && (ln_f_extend_1[12] || ln_f_extend_1[10:0]) ? ln_f_extend_1[19:12] + 8'd1 : ln_f_extend_1[19:12];
wire signed [7:0] ln_q_pos_round_2 = ln_f_extend_2[11] && (ln_f_extend_2[12] || ln_f_extend_2[10:0]) ? ln_f_extend_2[19:12] + 8'd1 : ln_f_extend_2[19:12];
wire signed [7:0] ln_q_pos_round_3 = ln_f_extend_3[11] && (ln_f_extend_3[12] || ln_f_extend_3[10:0]) ? ln_f_extend_3[19:12] + 8'd1 : ln_f_extend_3[19:12];
wire signed [7:0] ln_q_pos_round_4 = ln_f_extend_4[11] && (ln_f_extend_4[12] || ln_f_extend_4[10:0]) ? ln_f_extend_4[19:12] + 8'd1 : ln_f_extend_4[19:12];
wire signed [7:0] ln_q_pos_round_5 = ln_f_extend_5[11] && (ln_f_extend_5[12] || ln_f_extend_5[10:0]) ? ln_f_extend_5[19:12] + 8'd1 : ln_f_extend_5[19:12];
wire signed [7:0] ln_q_pos_round_6 = ln_f_extend_6[11] && (ln_f_extend_6[12] || ln_f_extend_6[10:0]) ? ln_f_extend_6[19:12] + 8'd1 : ln_f_extend_6[19:12];
wire signed [7:0] ln_q_pos_round_7 = ln_f_extend_7[11] && (ln_f_extend_7[12] || ln_f_extend_7[10:0]) ? ln_f_extend_7[19:12] + 8'd1 : ln_f_extend_7[19:12];

wire signed [7:0] ln_q_neg_round_0 = ~ln_f_extend_0[11] ? ln_f_extend_0[19:12] : (ln_f_extend_0[12:11]==2'b01 && !(ln_f_extend_0[10:0])) ? ln_f_extend_0[19:12] : (ln_f_extend_0[12:11]==2'b01 && ln_f_extend_0[10:0]) ? {ln_f_extend_0[19:13],1'b1} : ln_f_extend_0[19:12]+1'b1;
wire signed [7:0] ln_q_neg_round_1 = ~ln_f_extend_1[11] ? ln_f_extend_1[19:12] : (ln_f_extend_1[12:11]==2'b01 && !(ln_f_extend_1[10:0])) ? ln_f_extend_1[19:12] : (ln_f_extend_1[12:11]==2'b01 && ln_f_extend_1[10:0]) ? {ln_f_extend_1[19:13],1'b1} : ln_f_extend_1[19:12]+1'b1;
wire signed [7:0] ln_q_neg_round_2 = ~ln_f_extend_2[11] ? ln_f_extend_2[19:12] : (ln_f_extend_2[12:11]==2'b01 && !(ln_f_extend_2[10:0])) ? ln_f_extend_2[19:12] : (ln_f_extend_2[12:11]==2'b01 && ln_f_extend_2[10:0]) ? {ln_f_extend_2[19:13],1'b1} : ln_f_extend_2[19:12]+1'b1;
wire signed [7:0] ln_q_neg_round_3 = ~ln_f_extend_3[11] ? ln_f_extend_3[19:12] : (ln_f_extend_3[12:11]==2'b01 && !(ln_f_extend_3[10:0])) ? ln_f_extend_3[19:12] : (ln_f_extend_3[12:11]==2'b01 && ln_f_extend_3[10:0]) ? {ln_f_extend_3[19:13],1'b1} : ln_f_extend_3[19:12]+1'b1;
wire signed [7:0] ln_q_neg_round_4 = ~ln_f_extend_4[11] ? ln_f_extend_4[19:12] : (ln_f_extend_4[12:11]==2'b01 && !(ln_f_extend_4[10:0])) ? ln_f_extend_4[19:12] : (ln_f_extend_4[12:11]==2'b01 && ln_f_extend_4[10:0]) ? {ln_f_extend_4[19:13],1'b1} : ln_f_extend_4[19:12]+1'b1;
wire signed [7:0] ln_q_neg_round_5 = ~ln_f_extend_5[11] ? ln_f_extend_5[19:12] : (ln_f_extend_5[12:11]==2'b01 && !(ln_f_extend_5[10:0])) ? ln_f_extend_5[19:12] : (ln_f_extend_5[12:11]==2'b01 && ln_f_extend_5[10:0]) ? {ln_f_extend_5[19:13],1'b1} : ln_f_extend_5[19:12]+1'b1;
wire signed [7:0] ln_q_neg_round_6 = ~ln_f_extend_6[11] ? ln_f_extend_6[19:12] : (ln_f_extend_6[12:11]==2'b01 && !(ln_f_extend_6[10:0])) ? ln_f_extend_6[19:12] : (ln_f_extend_6[12:11]==2'b01 && ln_f_extend_6[10:0]) ? {ln_f_extend_6[19:13],1'b1} : ln_f_extend_6[19:12]+1'b1;
wire signed [7:0] ln_q_neg_round_7 = ~ln_f_extend_7[11] ? ln_f_extend_7[19:12] : (ln_f_extend_7[12:11]==2'b01 && !(ln_f_extend_7[10:0])) ? ln_f_extend_7[19:12] : (ln_f_extend_7[12:11]==2'b01 && ln_f_extend_7[10:0]) ? {ln_f_extend_7[19:13],1'b1} : ln_f_extend_7[19:12]+1'b1;

wire signed [7:0] ln_initial_norm_q_0 = ln_clamp_neg_flag_0 ? -8'd128 : ln_clamp_pos_flag_0 ? 8'd127 : quotient_out_0[30] ? ln_q_neg_round_0 : ln_q_pos_round_0;
wire signed [7:0] ln_initial_norm_q_1 = ln_clamp_neg_flag_1 ? -8'd128 : ln_clamp_pos_flag_1 ? 8'd127 : quotient_out_1[30] ? ln_q_neg_round_1 : ln_q_pos_round_1;
wire signed [7:0] ln_initial_norm_q_2 = ln_clamp_neg_flag_2 ? -8'd128 : ln_clamp_pos_flag_2 ? 8'd127 : quotient_out_2[30] ? ln_q_neg_round_2 : ln_q_pos_round_2;
wire signed [7:0] ln_initial_norm_q_3 = ln_clamp_neg_flag_3 ? -8'd128 : ln_clamp_pos_flag_3 ? 8'd127 : quotient_out_3[30] ? ln_q_neg_round_3 : ln_q_pos_round_3;
wire signed [7:0] ln_initial_norm_q_4 = ln_clamp_neg_flag_4 ? -8'd128 : ln_clamp_pos_flag_4 ? 8'd127 : quotient_out_4[30] ? ln_q_neg_round_4 : ln_q_pos_round_4;
wire signed [7:0] ln_initial_norm_q_5 = ln_clamp_neg_flag_5 ? -8'd128 : ln_clamp_pos_flag_5 ? 8'd127 : quotient_out_5[30] ? ln_q_neg_round_5 : ln_q_pos_round_5;
wire signed [7:0] ln_initial_norm_q_6 = ln_clamp_neg_flag_6 ? -8'd128 : ln_clamp_pos_flag_6 ? 8'd127 : quotient_out_6[30] ? ln_q_neg_round_6 : ln_q_pos_round_6;
wire signed [7:0] ln_initial_norm_q_7 = ln_clamp_neg_flag_7 ? -8'd128 : ln_clamp_pos_flag_7 ? 8'd127 : quotient_out_7[30] ? ln_q_neg_round_7 : ln_q_pos_round_7;




// pulse 1 cycle at output
reg signed [8-1:0] ln_out_data_0;
reg signed [8-1:0] ln_out_data_1;
reg signed [8-1:0] ln_out_data_2;
reg signed [8-1:0] ln_out_data_3;
reg signed [8-1:0] ln_out_data_4;
reg signed [8-1:0] ln_out_data_5;
reg signed [8-1:0] ln_out_data_6;
reg signed [8-1:0] ln_out_data_7;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        ln_out_data_0 <= 'd0;
        ln_out_data_1 <= 'd0;
        ln_out_data_2 <= 'd0;
        ln_out_data_3 <= 'd0;
        ln_out_data_4 <= 'd0;
        ln_out_data_5 <= 'd0;
        ln_out_data_6 <= 'd0;
        ln_out_data_7 <= 'd0;
    end
    else if (ln_state == OUT) begin
        ln_out_data_0 <= ln_initial_norm_q_0;
        ln_out_data_1 <= ln_initial_norm_q_1;
        ln_out_data_2 <= ln_initial_norm_q_2;
        ln_out_data_3 <= ln_initial_norm_q_3;
        ln_out_data_4 <= ln_initial_norm_q_4;
        ln_out_data_5 <= ln_initial_norm_q_5;
        ln_out_data_6 <= ln_initial_norm_q_6;
        ln_out_data_7 <= ln_initial_norm_q_7;
    end
end
// gather output data
assign ln_b_data_out = {ln_out_data_7,ln_out_data_6,ln_out_data_5,ln_out_data_4,ln_out_data_3,ln_out_data_2,ln_out_data_1,ln_out_data_0};
endmodule