`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/07 22:23:26
// Design Name: 
// Module Name: softMax
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


module spu_sm_top #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32,
    parameter RLATENCY = 1
)
(
    // Global Signals definition
    input core_clk, // process clock
    input rst_n, // reset input, active-low

    // Control Interface definition
    input sm_start, // ln process start (a pulse)
    output reg sm_end, // ln process ending (a pulse)

    // extend information signals
    input [ADDR_WIDTH-1:0] spu_matrix_y,
    input [ADDR_WIDTH-1:0] spu_matrix_x,
    input [ADDR_WIDTH-1:0] im_base_addr,
    input [ADDR_WIDTH-1:0] om_base_addr,
    input [ADDR_WIDTH-1:0] ifm_addr_align,
    input [ADDR_WIDTH-1:0] ofm_addr_align,
    input [3:0] sm_shift_input,
    input [4:0] sm_exp_shift_output,
    input [3:0] sm_shift_output,

    // fmbuf Interface definition
    output reg sm_gbuf_ren, // gbuf read enable
    output [ADDR_WIDTH-1:0] sm_gbuf_raddr, // gbuf read address, validated by sm_gbuf_ren
    input [DATA_WIDTH-1:0] sm_gbuf_rdata, // gbuf read data, 2cycle delay from sm_gbuf_ren
    output sm_gbuf_wen, // gbuf write enable
    output [ADDR_WIDTH-1:0] sm_gbuf_waddr, // gbuf write address, validated by sm_gbuf_wen
    output [DATA_WIDTH-1:0] sm_gbuf_wdata // gbuf write data, validated by sm_gbuf_wen
);
// sm state machine
localparam IDLE = 3'b000;
localparam EU_STAGE_A = 3'b001;
localparam RECI = 3'b011; // now is the divider stage
localparam EU_STAGE_B = 3'b100;
localparam MAX = 3'b101;

// other params
wire [ADDR_WIDTH-1:0] spu_matrix_x_per_unit = spu_matrix_x >> 2;

reg [2:0] sm_next_state, sm_state; // ln state machine signals

// decompose rdata for 16 processing blocks
wire [31:0] sm_data_in = sm_gbuf_rdata;

// gather wdata from 16 processing blocks
wire [31:0] sm_data_out; 
assign sm_gbuf_wdata = sm_data_out;

// counters for inner states
reg [ADDR_WIDTH-1:0] max_cnt;
reg [ADDR_WIDTH-1:0] eu_stage_a_cnt;
reg [8-1:0] reci_cnt;
reg [ADDR_WIDTH-1:0] eu_stage_b_cnt;

// addr control
reg [ADDR_WIDTH-1:0] sm_gbuf_raddr_sum;
reg [ADDR_WIDTH-1:0] sm_gbuf_waddr_sum; // accumulation of row addr
reg [ADDR_WIDTH-1:0] sm_gbuf_raddr_token;
reg [ADDR_WIDTH-1:0] sm_gbuf_waddr_token; // basic addr to process 1 row (token)
reg [ADDR_WIDTH-1:0] finish_token_cnt; // count finished rows (tokens), for state transition, maximum 32768/16, should be [15:0] to represent
reg [2:0] rd_flag; // handle mutiple read loops in state EU_STAGE_A and EU_STAGE_B

// state transition
always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) sm_state <= IDLE;
    else sm_state <= sm_next_state;
end

// substate control signals
wire max_tr = (max_cnt == spu_matrix_x_per_unit - 1 + RLATENCY);
wire comp_en = (sm_state == MAX && max_cnt >= RLATENCY);
wire comp_rst = (sm_state == MAX && max_cnt == 0);

reg eu_stage_a_tr;
always @(*) begin
    eu_stage_a_tr = (eu_stage_a_cnt == spu_matrix_x_per_unit - 1 + RLATENCY + 3);
end
// wire eu_stage_a_tr = (eu_stage_a_cnt == spu_matrix_x_per_unit - 1 + RLATENCY + 3);

reg adder_tree_en;
always @(*) begin
    adder_tree_en = (sm_state == EU_STAGE_A && eu_stage_a_cnt >= RLATENCY + 3);
end
// wire adder_tree_en = (sm_state == EU_STAGE_A && eu_stage_a_cnt >= RLATENCY + 3); // after RLATENCY, data comes, then expu needs 3 clk

wire reci_exp_sum_en = (sm_state == RECI && reci_cnt == 0);
wire reci_exp_sum_finish;
wire eu_state_b_tr = (eu_stage_b_cnt == spu_matrix_x_per_unit - 1 + RLATENCY + 1 + 1); // plus 1st 1 since eu_b pulse 3, plus 2nd 1 since mul pulse plus 3rd 1 since output pulse

// state transition conditions
always @(*) begin
    case(sm_state)
        IDLE: begin
            if (sm_start) begin
                sm_next_state = MAX;
            end
            else sm_next_state = sm_state;
        end
        MAX: begin
            if (max_tr) sm_next_state = EU_STAGE_A;
            else sm_next_state = sm_state;
        end
        EU_STAGE_A: begin
            if (eu_stage_a_tr) sm_next_state = RECI;
            else sm_next_state = sm_state;
        end
        RECI: begin
            if (reci_exp_sum_finish) sm_next_state = EU_STAGE_B;
            else sm_next_state = sm_state;
        end
        EU_STAGE_B: begin
            if (eu_state_b_tr && finish_token_cnt < spu_matrix_y) begin
                sm_next_state = MAX; // whole process continues
            end
            else if (eu_state_b_tr && finish_token_cnt == spu_matrix_y) sm_next_state = IDLE; // whole process ends
            else sm_next_state = sm_state;
        end
        default: begin
            sm_next_state = sm_state;
        end
    endcase
end

// send sm_end signal
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) sm_end <= 1'b0;
    else begin
        if (sm_end) sm_end <= 1'b0;
        else if (sm_next_state == IDLE && sm_state == EU_STAGE_B) sm_end <= 1'b1;
    end
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) max_cnt <= 'd0;
    else if (sm_state == MAX) begin
        if (max_tr) max_cnt <= 'd0;
        else max_cnt <= max_cnt + 'd1;
    end
end


always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) reci_cnt <= 'd0;
    else if (sm_state == RECI) begin
        if (reci_exp_sum_finish) reci_cnt <= 'd0;
        else reci_cnt <= reci_cnt + 'd1;
    end
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) eu_stage_a_cnt <= 'd0;
    else if (sm_state == EU_STAGE_A) begin
        if (eu_stage_a_tr) eu_stage_a_cnt <= 'd0;
        else eu_stage_a_cnt <= eu_stage_a_cnt + 'd1;
    end
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) eu_stage_b_cnt <= 'd0;
    else if (sm_state == EU_STAGE_B) begin
        if (eu_state_b_tr) eu_stage_b_cnt <= 'd0;
        else eu_stage_b_cnt <= eu_stage_b_cnt + 'd1;
    end
end

// gbuf interface control
always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) finish_token_cnt <= 'd0;
    else if (sm_state == EU_STAGE_B) begin
        if (eu_stage_b_cnt == spu_matrix_x_per_unit - 1 + RLATENCY) finish_token_cnt <= finish_token_cnt + 'd1;
    end
    else if (sm_state == IDLE) finish_token_cnt <= 'd0;
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) sm_gbuf_raddr_sum <= 'd0;
    else if (sm_state == EU_STAGE_B && eu_state_b_tr) begin
        sm_gbuf_raddr_sum <= sm_gbuf_raddr_sum + ifm_addr_align;
    end
    else if (sm_start) sm_gbuf_raddr_sum <= im_base_addr;
    else if (sm_state == IDLE) sm_gbuf_raddr_sum <= 'd0;
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) sm_gbuf_waddr_sum <= 'd0;
    else if (sm_state == EU_STAGE_B && eu_state_b_tr) begin
        sm_gbuf_waddr_sum <= sm_gbuf_waddr_sum + ofm_addr_align;
    end
    else if (sm_start) sm_gbuf_waddr_sum <= om_base_addr;
    else if (sm_state == IDLE) sm_gbuf_waddr_sum <= 'd0;
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) rd_flag <= 3'b000;
    else begin
        if (sm_state == MAX && rd_flag == 3'b001 && sm_gbuf_raddr_token == spu_matrix_x_per_unit - 1) rd_flag <= 3'b010; // max lock
        else if (sm_state == EU_STAGE_A && rd_flag == 3'b011 && sm_gbuf_raddr_token == spu_matrix_x_per_unit - 1) rd_flag <= 3'b100; // max lock
        else if (sm_state == EU_STAGE_B && rd_flag == 3'b101 && sm_gbuf_raddr_token == spu_matrix_x_per_unit - 1) rd_flag <= 3'b000; // max lock
        else if (sm_next_state == MAX && rd_flag == 3'b000) rd_flag <= 3'b001;
        else if (sm_next_state == EU_STAGE_A && rd_flag == 3'b010) rd_flag <= 3'b011;
        else if (sm_next_state == EU_STAGE_B && rd_flag == 3'b100) rd_flag <= 3'b101;
        else if (sm_state == IDLE) rd_flag <= 3'b000;
    end
end

// raddr per token rules
always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) sm_gbuf_raddr_token <= 'd0;
    else begin
        case(sm_state)
            MAX: begin
                if (sm_gbuf_raddr_token == spu_matrix_x_per_unit - 1) sm_gbuf_raddr_token <= 'd0;
                else if (rd_flag == 3'b001) sm_gbuf_raddr_token <= sm_gbuf_raddr_token + 'd1;
            end
            EU_STAGE_A: begin
                if (sm_gbuf_raddr_token == spu_matrix_x_per_unit - 1) sm_gbuf_raddr_token <= 'd0;
                else if (rd_flag == 3'b011) sm_gbuf_raddr_token <= sm_gbuf_raddr_token + 'd1;
            end
            EU_STAGE_B: begin
                if (sm_gbuf_raddr_token == spu_matrix_x_per_unit - 1) sm_gbuf_raddr_token <= 'd0;
                else if (rd_flag == 3'b101) sm_gbuf_raddr_token <= sm_gbuf_raddr_token + 'd1;
            end
            IDLE: sm_gbuf_raddr_token <= 'd0;
        endcase
    end
end

assign sm_gbuf_raddr = sm_gbuf_raddr_token + sm_gbuf_raddr_sum;
always @(*) begin
    sm_gbuf_ren = (sm_state == EU_STAGE_A && rd_flag == 3'b011) || (sm_state == EU_STAGE_B && rd_flag == 3'b101) || (sm_state == MAX && rd_flag == 3'b001);
end
// assign sm_gbuf_ren = (sm_state == MAX && rd_flag == 3'b001);

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) sm_gbuf_waddr_token <= 'd0;
    else begin
        if (sm_state == MAX && max_cnt >= RLATENCY) sm_gbuf_waddr_token <= sm_gbuf_waddr_token + 'd1;
        else if (sm_state == EU_STAGE_A && eu_stage_a_cnt >= RLATENCY + 3)
                sm_gbuf_waddr_token <= sm_gbuf_waddr_token + 'd1;
        else if (sm_state == EU_STAGE_B && eu_stage_b_cnt >= RLATENCY + 1 + 1) sm_gbuf_waddr_token <= sm_gbuf_waddr_token + 'd1;
        else sm_gbuf_waddr_token <= 'd0;
    end
end
assign sm_gbuf_wen = (sm_state == EU_STAGE_A && eu_stage_a_cnt >= RLATENCY + 3 && eu_stage_a_cnt <= spu_matrix_x_per_unit - 1 + RLATENCY + 3) || (sm_state == EU_STAGE_B && eu_stage_b_cnt >= RLATENCY + 1 + 1);
// rd_data received at RLATENCY, EU process needs 3 cycle, Multiply with reci needs 1 cycle, so the wen should be RLATENCY + 1 + 1
// plus 1 more since output pulse
assign sm_gbuf_waddr = sm_gbuf_waddr_token + sm_gbuf_waddr_sum;

// sm processing block instances
spu_sm_block u_spu_sm_block(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(reci_exp_sum_finish),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in),
    .sm_b_data_out(sm_data_out)
);
endmodule
