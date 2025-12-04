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
    parameter RLATENCY = 3, // Rd latency, will be 1 more cycle than global since had pulse 1 in top
    parameter RADDR_WIDTH = 13,
    parameter WADDR_WIDTH = 13,
    parameter SM_MAX_CHANNEL_DEPTH = 12, //  2^12 = 4096
    parameter CACHE_RLATENCY = 2,
    parameter CACHE_DATA_WIDTH = 16*64,
    parameter CACHE_DATA_DEPTH = SM_MAX_CHANNEL_DEPTH - 3
)
(
    // Global Signals definition
    input core_clk, // process clock
    input rst_n, // reset input, active-low

    // Control Interface definition
    input sm_start, // ln process start (a pulse)
    input sm_op, // 0: 8bit w/ rowmax & pwl, 1: 3bit w/o rowmax & lut
    output reg sm_end, // ln process ending (a pulse)

    input [10:0] spu_matrix_x_h,
    input [11:0] spu_matrix_x_w,
    input [1:0] h_pad,
    input [1:0] w_pad,
    // extend information signals
    input [SM_MAX_CHANNEL_DEPTH:0] sm_channel_number,
    input [127:0] sm_lut_config,
    input [15:0] im_base_addr,
    input [15:0] om_base_addr,
    input [11:0] ifm_addr_align,
    input [11:0] ofm_addr_align,
    input [11:0] token_per_block,
    input [3:0] sm_shift_input,
    input [4:0] sm_exp_shift_output,
    input [3:0] sm_shift_output,

    // fmbuf Interface definition
    output reg sm_lbuf_ren, // lbuf read enable
    output [RADDR_WIDTH-1:0] sm_lbuf_raddr, // lbuf read address, validated by sm_lbuf_ren
    input [16*64-1:0] sm_lbuf_rdata, // lbuf read data, 2cycle delay from sm_lbuf_ren
    output sm_lbuf_wen, // lbuf write enable
    output [WADDR_WIDTH-1:0] sm_lbuf_waddr, // lbuf write address, validated by sm_lbuf_wen
    output [16*64-1:0] sm_lbuf_wdata, // lbuf write data, validated by sm_lbuf_wen

    // cache Interface definition
    output reg sm_cache_ren,
    output [CACHE_DATA_DEPTH-1:0] sm_cache_raddr,
    input [CACHE_DATA_WIDTH-1:0] sm_cache_rdata,
    output reg sm_cache_wen,
    output [CACHE_DATA_DEPTH-1:0] sm_cache_waddr,
    output [CACHE_DATA_WIDTH-1:0] sm_cache_wdata
);
// sm state machine
localparam IDLE = 3'b000;
localparam EU_STAGE_A = 3'b001;
localparam RECI = 3'b011; // now is the divider stage
localparam EU_STAGE_B = 3'b100;
localparam MAX = 3'b101;

// other params
wire [CACHE_DATA_DEPTH:0] sm_channel_number_per_unit = sm_channel_number >> 3;

reg [2:0] sm_next_state, sm_state; // ln state machine signals

// decompose rdata for 16 processing blocks
wire [63:0] sm_data_in_0 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*1-1:64*0] : sm_cache_rdata[64*1-1:64*0];
wire [63:0] sm_data_in_1 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*2-1:64*1] : sm_cache_rdata[64*2-1:64*1];
wire [63:0] sm_data_in_2 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*3-1:64*2] : sm_cache_rdata[64*3-1:64*2];
wire [63:0] sm_data_in_3 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*4-1:64*3] : sm_cache_rdata[64*4-1:64*3];
wire [63:0] sm_data_in_4 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*5-1:64*4] : sm_cache_rdata[64*5-1:64*4];
wire [63:0] sm_data_in_5 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*6-1:64*5] : sm_cache_rdata[64*6-1:64*5];
wire [63:0] sm_data_in_6 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*7-1:64*6] : sm_cache_rdata[64*7-1:64*6];
wire [63:0] sm_data_in_7 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*8-1:64*7] : sm_cache_rdata[64*8-1:64*7];
wire [63:0] sm_data_in_8 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*9-1:64*8] : sm_cache_rdata[64*9-1:64*8];
wire [63:0] sm_data_in_9 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*10-1:64*9] : sm_cache_rdata[64*10-1:64*9];
wire [63:0] sm_data_in_10 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*11-1:64*10] : sm_cache_rdata[64*11-1:64*10];
wire [63:0] sm_data_in_11 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*12-1:64*11] : sm_cache_rdata[64*12-1:64*11];
wire [63:0] sm_data_in_12 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*13-1:64*12] : sm_cache_rdata[64*13-1:64*12];
wire [63:0] sm_data_in_13 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*14-1:64*13] : sm_cache_rdata[64*14-1:64*13];
wire [63:0] sm_data_in_14 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*15-1:64*14] : sm_cache_rdata[64*15-1:64*14];
wire [63:0] sm_data_in_15 = (sm_op == 1'b0 && sm_state == MAX) || (sm_op == 1'b1 && sm_state == EU_STAGE_A) ? sm_lbuf_rdata[64*16-1:64*15] : sm_cache_rdata[64*16-1:64*15];

// gather wdata from 16 processing blocks
wire [63:0] sm_data_out_0; 
wire [63:0] sm_data_out_1; 
wire [63:0] sm_data_out_2; 
wire [63:0] sm_data_out_3; 
wire [63:0] sm_data_out_4; 
wire [63:0] sm_data_out_5; 
wire [63:0] sm_data_out_6; 
wire [63:0] sm_data_out_7; 
wire [63:0] sm_data_out_8; 
wire [63:0] sm_data_out_9; 
wire [63:0] sm_data_out_10;
wire [63:0] sm_data_out_11;
wire [63:0] sm_data_out_12;
wire [63:0] sm_data_out_13;
wire [63:0] sm_data_out_14;
wire [63:0] sm_data_out_15;
assign sm_lbuf_wdata = {sm_data_out_15,sm_data_out_14,sm_data_out_13,sm_data_out_12,sm_data_out_11,sm_data_out_10,
sm_data_out_9,sm_data_out_8,sm_data_out_7,sm_data_out_6,sm_data_out_5,sm_data_out_4,sm_data_out_3,sm_data_out_2,sm_data_out_1,sm_data_out_0};

// cache data
assign sm_cache_wdata = sm_state == EU_STAGE_A ? sm_lbuf_wdata : sm_lbuf_rdata;

// counters for inner states
reg [CACHE_DATA_DEPTH:0] max_cnt;
reg [CACHE_DATA_DEPTH:0] eu_stage_a_cnt;
reg [8-1:0] reci_cnt;
reg [CACHE_DATA_DEPTH:0] eu_stage_b_cnt;

// addr control
reg [RADDR_WIDTH-1:0] sm_lbuf_raddr_sum;
reg [WADDR_WIDTH-1:0] sm_lbuf_waddr_sum; // accumulation of row addr
reg [CACHE_DATA_DEPTH-1:0] sm_lbuf_raddr_token;
reg [CACHE_DATA_DEPTH-1:0] sm_lbuf_waddr_token; // basic addr to process 1 row (token)
reg [RADDR_WIDTH-4:0] finish_token_cnt; // count finished rows (tokens), for state transition, maximum 32768/16, should be [15:0] to represent
reg [2:0] rd_flag; // handle mutiple read loops in state EU_STAGE_A and EU_STAGE_B

// state transition
always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) sm_state <= IDLE;
    else sm_state <= sm_next_state;
end

// substate control signals
wire max_tr = (max_cnt == sm_channel_number_per_unit - 1 + RLATENCY);
wire comp_en = (sm_state == MAX && max_cnt >= RLATENCY);
wire comp_rst = (sm_state == MAX && max_cnt == 0);

reg eu_stage_a_tr;
always @(*) begin
    case (sm_op)
        1'b0: eu_stage_a_tr = (eu_stage_a_cnt == sm_channel_number_per_unit - 1 + CACHE_RLATENCY + 3);
        1'b1: eu_stage_a_tr = (eu_stage_a_cnt == sm_channel_number_per_unit - 1 + RLATENCY + 3);
        default: eu_stage_a_tr = (eu_stage_a_cnt == sm_channel_number_per_unit - 1 + CACHE_RLATENCY + 3);
    endcase
end
// wire eu_stage_a_tr = (eu_stage_a_cnt == sm_channel_number_per_unit - 1 + CACHE_RLATENCY + 3);

reg adder_tree_en;
always @(*) begin
    case (sm_op)
        1'b0: adder_tree_en = (sm_state == EU_STAGE_A && eu_stage_a_cnt >= CACHE_RLATENCY + 3);
        1'b1: adder_tree_en = (sm_state == EU_STAGE_A && eu_stage_a_cnt >= RLATENCY + 3);
        default: adder_tree_en = (sm_state == EU_STAGE_A && eu_stage_a_cnt >= CACHE_RLATENCY + 3);
    endcase
end
// wire adder_tree_en = (sm_state == EU_STAGE_A && eu_stage_a_cnt >= CACHE_RLATENCY + 3); // after RLATENCY, data comes, then expu needs 3 clk

wire reci_exp_sum_en = (sm_state == RECI && reci_cnt == 0);
wire reci_exp_sum_finish;
wire eu_state_b_tr = (eu_stage_b_cnt == sm_channel_number_per_unit - 1 + CACHE_RLATENCY + 1 + 1); // plus 1st 1 since eu_b pulse 3, plus 2nd 1 since mul pulse plus 3rd 1 since output pulse

// state transition conditions
always @(*) begin
    case(sm_state)
        IDLE: begin
            if (sm_start) begin
                if (!sm_op) sm_next_state = MAX;
                else sm_next_state = EU_STAGE_A;
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
            if (eu_state_b_tr && finish_token_cnt < token_per_block) begin
                if (!sm_op) sm_next_state = MAX; // whole process continues
                else sm_next_state = EU_STAGE_A;
            end
            else if (eu_state_b_tr && finish_token_cnt == token_per_block) sm_next_state = IDLE; // whole process ends
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

// lbuf interface control
always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) finish_token_cnt <= 'd0;
    else if (sm_state == EU_STAGE_B) begin
        if (eu_stage_b_cnt == sm_channel_number_per_unit - 1 + CACHE_RLATENCY) finish_token_cnt <= finish_token_cnt + 'd1;
    end
    else if (sm_state == IDLE) finish_token_cnt <= 'd0;
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) sm_lbuf_raddr_sum <= 'd0;
    else if (sm_state == EU_STAGE_B && eu_state_b_tr) begin
        sm_lbuf_raddr_sum <= sm_lbuf_raddr_sum + ifm_addr_align;
    end
    else if (sm_start) sm_lbuf_raddr_sum <= im_base_addr;
    else if (sm_state == IDLE) sm_lbuf_raddr_sum <= 'd0;
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) sm_lbuf_waddr_sum <= 'd0;
    else if (sm_state == EU_STAGE_B && eu_state_b_tr) begin
        sm_lbuf_waddr_sum <= sm_lbuf_waddr_sum + ofm_addr_align;
    end
    else if (sm_start) sm_lbuf_waddr_sum <= om_base_addr;
    else if (sm_state == IDLE) sm_lbuf_waddr_sum <= 'd0;
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) rd_flag <= 3'b000;
    else begin
        if (!sm_op) begin
            if (sm_state == MAX && rd_flag == 3'b001 && sm_lbuf_raddr_token == sm_channel_number_per_unit - 1) rd_flag <= 3'b010; // max lock
            else if (sm_state == EU_STAGE_A && rd_flag == 3'b011 && sm_lbuf_raddr_token == sm_channel_number_per_unit - 1) rd_flag <= 3'b100; // max lock
            else if (sm_state == EU_STAGE_B && rd_flag == 3'b101 && sm_lbuf_raddr_token == sm_channel_number_per_unit - 1) rd_flag <= 3'b000; // max lock
            else if (sm_next_state == MAX && rd_flag == 3'b000) rd_flag <= 3'b001;
            else if (sm_next_state == EU_STAGE_A && rd_flag == 3'b010) rd_flag <= 3'b011;
            else if (sm_next_state == EU_STAGE_B && rd_flag == 3'b100) rd_flag <= 3'b101;
            else if (sm_state == IDLE) rd_flag <= 3'b000;
        end
        else begin
            if (sm_state == EU_STAGE_A && rd_flag == 3'b011 && sm_lbuf_raddr_token == sm_channel_number_per_unit - 1) rd_flag <= 3'b100;
            else if (sm_state == EU_STAGE_B && rd_flag == 3'b101 && sm_lbuf_raddr_token == sm_channel_number_per_unit - 1) rd_flag <= 3'b000;
            else if (sm_next_state == EU_STAGE_A && rd_flag == 3'b000) rd_flag <= 3'b011;
            else if (sm_next_state == EU_STAGE_B && rd_flag == 3'b100) rd_flag <= 3'b101;
            else if (sm_state == IDLE) rd_flag <= 3'b000;
        end
    end
end

// raddr per token rules
always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) sm_lbuf_raddr_token <= 'd0;
    else begin
        case(sm_state)
            MAX: begin
                if (sm_lbuf_raddr_token == sm_channel_number_per_unit - 1) sm_lbuf_raddr_token <= 'd0;
                else if (rd_flag == 3'b001) sm_lbuf_raddr_token <= sm_lbuf_raddr_token + 'd1;
            end
            EU_STAGE_A: begin
                if (sm_lbuf_raddr_token == sm_channel_number_per_unit - 1) sm_lbuf_raddr_token <= 'd0;
                else if (rd_flag == 3'b011) sm_lbuf_raddr_token <= sm_lbuf_raddr_token + 'd1;
            end
            EU_STAGE_B: begin
                if (sm_lbuf_raddr_token == sm_channel_number_per_unit - 1) sm_lbuf_raddr_token <= 'd0;
                else if (rd_flag == 3'b101) sm_lbuf_raddr_token <= sm_lbuf_raddr_token + 'd1;
            end
            IDLE: sm_lbuf_raddr_token <= 'd0;
        endcase
    end
end

assign sm_lbuf_raddr = sm_lbuf_raddr_token + sm_lbuf_raddr_sum;
always @(*) begin
    case (sm_op)
        1'b0: sm_lbuf_ren = (sm_state == MAX && rd_flag == 3'b001);
        1'b1: sm_lbuf_ren = (sm_state == EU_STAGE_A && rd_flag == 3'b011);
        default: sm_lbuf_ren = (sm_state == MAX && rd_flag == 3'b001);
    endcase
end
// assign sm_lbuf_ren = (sm_state == MAX && rd_flag == 3'b001);

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) sm_lbuf_waddr_token <= 'd0;
    else begin
        if (sm_state == MAX && max_cnt >= RLATENCY) sm_lbuf_waddr_token <= sm_lbuf_waddr_token + 'd1;
        else if (sm_state == EU_STAGE_A && ((sm_op==1'b0 && eu_stage_a_cnt >= CACHE_RLATENCY + 3) || (sm_op==1'b1 && eu_stage_a_cnt >= RLATENCY + 3)))
                sm_lbuf_waddr_token <= sm_lbuf_waddr_token + 'd1;
        else if (sm_state == EU_STAGE_B && eu_stage_b_cnt >= CACHE_RLATENCY + 1 + 1) sm_lbuf_waddr_token <= sm_lbuf_waddr_token + 'd1;
        else sm_lbuf_waddr_token <= 'd0;
    end
end
assign sm_lbuf_wen = sm_state == EU_STAGE_B && eu_stage_b_cnt >= CACHE_RLATENCY + 1 + 1;
// rd_data received at RLATENCY, EU process needs 3 cycle, Multiply with reci needs 1 cycle, so the wen should be RLATENCY + 1 + 1
// plus 1 more since output pulse
assign sm_lbuf_waddr = sm_lbuf_waddr_token + sm_lbuf_waddr_sum;

// ln-spu cache control
always @(*) begin
    case (sm_op)
        1'b0: sm_cache_ren = (sm_state == EU_STAGE_A && rd_flag == 3'b011) || (sm_state == EU_STAGE_B && rd_flag == 3'b101);
        1'b1: sm_cache_ren = (sm_state == EU_STAGE_B && rd_flag == 3'b101);
        default: sm_cache_ren = (sm_state == EU_STAGE_A && rd_flag == 3'b011) || (sm_state == EU_STAGE_B && rd_flag == 3'b101);
    endcase
end
assign sm_cache_raddr = sm_lbuf_raddr_token;

always @(*) begin
    case (sm_op)
        1'b0: sm_cache_wen = (sm_state == MAX && max_cnt >= RLATENCY && max_cnt <= (sm_channel_number_per_unit - 1 + RLATENCY)) ||
                             (sm_state == EU_STAGE_A && eu_stage_a_cnt >= CACHE_RLATENCY+3 && eu_stage_a_cnt <= (sm_channel_number_per_unit - 1 + CACHE_RLATENCY)+3);
        1'b1: sm_cache_wen = (sm_state == EU_STAGE_A && eu_stage_a_cnt >= RLATENCY+3 && eu_stage_a_cnt <= (sm_channel_number_per_unit - 1 + RLATENCY)+3);
        default: sm_cache_wen = 1'b0;
    endcase
end

assign sm_cache_waddr = sm_lbuf_waddr_token;

// assign sm_cache_addr = sm_cache_ren ? sm_cache_raddr : sm_cache_waddr;


// padding control
reg [10:0] h_cnt;
reg [11:0] w_cnt;

wire sm_lbuf_ren_reg;
reg [RLATENCY-1-1:0] sm_lbuf_ren_shift_reg;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        sm_lbuf_ren_shift_reg <= 0;
    end 
    else if (RLATENCY >= 3) begin
        sm_lbuf_ren_shift_reg <= {sm_lbuf_ren_shift_reg[RLATENCY-2-1:0], sm_lbuf_ren};
    end
    else if (RLATENCY == 2) begin
        sm_lbuf_ren_shift_reg <= sm_lbuf_ren;
    end
end
assign sm_lbuf_ren_reg = sm_lbuf_ren_shift_reg[RLATENCY-1-1];

wire sm_cache_ren_reg;
reg [CACHE_RLATENCY-1-1:0] sm_cache_ren_shift_reg;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        sm_cache_ren_shift_reg <= 0;
    end 
    else if (CACHE_RLATENCY >= 3) begin
        sm_cache_ren_shift_reg <= {sm_cache_ren_shift_reg[CACHE_RLATENCY-2-1:0], sm_cache_ren}; // TODO
    end
    else if (CACHE_RLATENCY == 2) begin
        sm_cache_ren_shift_reg <= sm_cache_ren; // TODO
    end
end
assign sm_cache_ren_reg = sm_cache_ren_shift_reg[CACHE_RLATENCY-1-1];

reg pad_ren;
always @(*) begin
    if (sm_state == MAX) pad_ren = sm_lbuf_ren_reg;
    else if (sm_state == EU_STAGE_A) begin
        case (sm_op) 
            1'b0: pad_ren = sm_cache_ren_reg;
            1'b1: pad_ren = sm_lbuf_ren_reg;
            default: pad_ren = sm_cache_ren_reg;
        endcase
    end
    else if (sm_state == EU_STAGE_B) begin
        pad_ren = sm_cache_ren_reg;
    end
    else pad_ren = 1'b0;
end

wire pad_ren_reg;
reg [3-1:0] pad_ren_shift_reg; // exp needs 3 cycles
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        pad_ren_shift_reg <= 0;
    end 
    else if (sm_state == EU_STAGE_A) begin // 仍会有影响，比如max时候虽然不用它，但是如果他reg了，一旦转到下个state，max那个残留会弄过来
        pad_ren_shift_reg <= {pad_ren_shift_reg[3-2:0], pad_ren};
    end
    else if (sm_state == EU_STAGE_B) begin
        pad_ren_shift_reg <= {pad_ren_shift_reg[3-2:0], pad_ren};
    end
end
assign pad_ren_reg = sm_state == MAX ? pad_ren : sm_state == EU_STAGE_B ? pad_ren_shift_reg[3-3] : pad_ren_shift_reg[3-1];

// for w
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) w_cnt <= 'd0;
    // else if (eu_state_b_tr) h_cnt <= 'd0;
    else if (pad_ren_reg) begin
        if (w_cnt + 'd2 == spu_matrix_x_w + w_pad) w_cnt <= 'd0;
        else w_cnt <= w_cnt + 'd2;
    end
end
wire w_pad_flag = pad_ren_reg && w_cnt >= spu_matrix_x_w + w_pad - 4; // for every row, only once for 2 clk

reg [2:0] w_pad_en; // once active, will active for 2 clk
always @(*) begin
    if (w_pad_flag) begin
        case (w_pad)
            2'd0: w_pad_en = 3'b000;
            2'd1: w_pad_en = 3'b100;
            2'd2: w_pad_en = 3'b110;
            2'd3: w_pad_en = 3'b111;
            default: w_pad_en = 3'b000;
        endcase
    end
    else w_pad_en = 3'b000;
end

// for h
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) h_cnt <= 'd0;
    else begin
        // if (eu_state_b_tr) h_cnt <= 'd0;
        if (pad_ren_reg && w_cnt + 'd2 == spu_matrix_x_w + w_pad) begin
            if (h_cnt + 'd4 == spu_matrix_x_h + h_pad) h_cnt <= 'd0;
            else h_cnt <= h_cnt + 'd4;
        end
    end
end

wire h_pad_flag = pad_ren_reg && h_cnt >= spu_matrix_x_h + h_pad - 4;
// always @(posedge core_clk or negedge rst_n) begin
//     if (~rst_n) h_pad_flag <= 1'b0;
//     else if (h_cnt >= spu_matrix_x_h + h_pad - 4) h_pad_flag <= 1'b1; // once activate, will continute until the last row of tiles ends
//     else h_pad_flag <= 1'b0;
// end
reg h_pad_status;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) h_pad_status <= 'b0;
    else if (h_pad_flag) h_pad_status <= ~h_pad_status;
    else h_pad_status <= 'b0;
end


reg [1:0] h_pad_en;
always @(*) begin
    if (h_pad_flag) begin
        if (h_pad_status == 0) begin
            case (h_pad)
                2'd3: h_pad_en = 2'b10;
                default: h_pad_en = 2'b00;
            endcase
        end
        else begin
            case (h_pad)
                2'd1: h_pad_en = 2'b10;
                2'd2: h_pad_en = 2'b11;
                2'd3: h_pad_en = 2'b11;
                default: h_pad_en = 2'b00;
            endcase
        end
    end
    else h_pad_en = 2'b00;
end

wire [7:0] w_pad_en_broadcast = {w_pad_en[2], w_pad_en[1], w_pad_en[0], 1'b0, w_pad_en[2], w_pad_en[1], w_pad_en[0], 1'b0};
wire [7:0] h_pad_en_broadcast = {h_pad_en[1], h_pad_en[1], h_pad_en[1], h_pad_en[1], h_pad_en[0], h_pad_en[0], h_pad_en[0], h_pad_en[0]};
wire [7:0] pad_en_pre = w_pad_en_broadcast | h_pad_en_broadcast; // bitwise or operation, should be reg since rd latency
reg [7:0] pad_en;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) pad_en <= 8'b0;
    else pad_en <= pad_en_pre;
end

// sm processing block instances
spu_sm_block u_spu_sm_block_0(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(reci_exp_sum_finish),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_0),
    .sm_b_data_out(sm_data_out_0)
);
spu_sm_block u_spu_sm_block_1(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_1),
    .sm_b_data_out(sm_data_out_1)
);
spu_sm_block u_spu_sm_block_2(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_2),
    .sm_b_data_out(sm_data_out_2)
);
spu_sm_block u_spu_sm_block_3(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_3),
    .sm_b_data_out(sm_data_out_3)
);
spu_sm_block u_spu_sm_block_4(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_4),
    .sm_b_data_out(sm_data_out_4)
);
spu_sm_block u_spu_sm_block_5(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_5),
    .sm_b_data_out(sm_data_out_5)
);
spu_sm_block u_spu_sm_block_6(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_6),
    .sm_b_data_out(sm_data_out_6)
);
spu_sm_block u_spu_sm_block_7(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_7),
    .sm_b_data_out(sm_data_out_7)
);
spu_sm_block u_spu_sm_block_8(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_8),
    .sm_b_data_out(sm_data_out_8)
);
spu_sm_block u_spu_sm_block_9(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_9),
    .sm_b_data_out(sm_data_out_9)
);
spu_sm_block u_spu_sm_block_10(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_10),
    .sm_b_data_out(sm_data_out_10)
);
spu_sm_block u_spu_sm_block_11(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_11),
    .sm_b_data_out(sm_data_out_11)
);
spu_sm_block u_spu_sm_block_12(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_12),
    .sm_b_data_out(sm_data_out_12)
);
spu_sm_block u_spu_sm_block_13(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_13),
    .sm_b_data_out(sm_data_out_13)
);
spu_sm_block u_spu_sm_block_14(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_14),
    .sm_b_data_out(sm_data_out_14)
);
spu_sm_block u_spu_sm_block_15(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .sm_op(sm_op),
    .sm_state(sm_state),
    .adder_tree_en(adder_tree_en),
    .comp_en(comp_en),
    .comp_rst(comp_rst),
    .sm_lut_config(sm_lut_config),
    .reci_exp_sum_en(reci_exp_sum_en),
    .reci_exp_sum_finish(),
    .sm_shift_input(sm_shift_input),
    .sm_exp_shift_output(sm_exp_shift_output),
    .sm_shift_output(sm_shift_output),
    .sm_b_data_in(sm_data_in_15),
    .sm_b_data_out(sm_data_out_15)
);
endmodule
