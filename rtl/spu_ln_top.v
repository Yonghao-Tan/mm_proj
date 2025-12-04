`timescale  1ns / 1ps
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


module spu_ln_top#( // (LN / ln)
    parameter RLATENCY = 3, // Rd latency, will be 1 more cycle than global since had pulse 1 in top
    parameter RADDR_WIDTH = 13,
    parameter WADDR_WIDTH = 13,
    parameter LN_MAX_CHANNEL_DEPTH = 11, //  2^11 = 2048
    parameter CACHE_RLATENCY = 2,
    parameter CACHE_DATA_WIDTH = 16*64,
    parameter CACHE_DATA_DEPTH = LN_MAX_CHANNEL_DEPTH - 3 // divided by channel parallelism
)
(
    // Global Signals definition
    input core_clk, // process clock
    input rst_n, // reset input, active-low

    // Control Interface definition
    input ln_start, // ln process start (a pulse)
    input ln_op,
    output reg ln_end, // ln process ending (a pulse)

    input [10:0] spu_matrix_x_h,
    input [11:0] spu_matrix_x_w,
    input [1:0] h_pad,
    input [1:0] w_pad,
    // extend information signals
    input [LN_MAX_CHANNEL_DEPTH:0] ln_channel_number,
    input [15:0] im_base_addr,
    input [15:0] om_base_addr,
    input [11:0] ifm_addr_align,
    input [11:0] ofm_addr_align,
    input [11:0] token_per_block,
    input [3:0] ln_shift_output,
    input [6:0] ln_div_m_0,
    input [6:0] ln_div_m_1,
    input [6:0] ln_div_m_2,
    input [6:0] ln_div_m_3,
    input [4:0] ln_div_e_0,
    input [4:0] ln_div_e_1,
    input [4:0] ln_div_e_2,
    input [4:0] ln_div_e_3,

    // fmbuf Interface definition
    output ln_lbuf_ren, // lbuf read enable
    output [RADDR_WIDTH-1:0] ln_lbuf_raddr, // lbuf read address, validated by ln_lbuf_ren
    input [16*64-1:0] ln_lbuf_rdata, // lbuf read data, 2cycle delay from ln_lbuf_ren
    output ln_lbuf_wen, // lbuf write enable
    output [WADDR_WIDTH-1:0] ln_lbuf_waddr, // lbuf write address, validated by ln_lbuf_wen
    output [16*64-1:0] ln_lbuf_wdata, // lbuf write data, validated by ln_lbuf_wen

    // cache Interface definition
    output ln_cache_ren,
    output [CACHE_DATA_DEPTH-1:0] ln_cache_addr,
    input [CACHE_DATA_WIDTH-1:0] ln_cache_rdata,
    output ln_cache_wen,
    output [CACHE_DATA_WIDTH-1:0] ln_cache_wdata
);

// ln state machine
localparam IDLE = 3'b000;
localparam SUM_COUNT = 3'b001;
localparam SUM_DIV = 3'b011;
localparam SQRT = 3'b100;
localparam OUT = 3'b110;
reg [2:0] ln_next_state, ln_state; // ln state machine signals

// other params
wire [CACHE_DATA_DEPTH:0] ln_channel_number_per_unit = ln_channel_number >> 3;

// decompose rdata for 16 processing blocks
wire [63:0] ln_data_in_0 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*1-1:64*0] : ln_cache_rdata[64*1-1:64*0];
wire [63:0] ln_data_in_1 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*2-1:64*1] : ln_cache_rdata[64*2-1:64*1];
wire [63:0] ln_data_in_2 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*3-1:64*2] : ln_cache_rdata[64*3-1:64*2];
wire [63:0] ln_data_in_3 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*4-1:64*3] : ln_cache_rdata[64*4-1:64*3];
wire [63:0] ln_data_in_4 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*5-1:64*4] : ln_cache_rdata[64*5-1:64*4];
wire [63:0] ln_data_in_5 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*6-1:64*5] : ln_cache_rdata[64*6-1:64*5];
wire [63:0] ln_data_in_6 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*7-1:64*6] : ln_cache_rdata[64*7-1:64*6];
wire [63:0] ln_data_in_7 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*8-1:64*7] : ln_cache_rdata[64*8-1:64*7];
wire [63:0] ln_data_in_8 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*9-1:64*8] : ln_cache_rdata[64*9-1:64*8];
wire [63:0] ln_data_in_9 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*10-1:64*9] : ln_cache_rdata[64*10-1:64*9];
wire [63:0] ln_data_in_10 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*11-1:64*10] : ln_cache_rdata[64*11-1:64*10];
wire [63:0] ln_data_in_11 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*12-1:64*11] : ln_cache_rdata[64*12-1:64*11];
wire [63:0] ln_data_in_12 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*13-1:64*12] : ln_cache_rdata[64*13-1:64*12];
wire [63:0] ln_data_in_13 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*14-1:64*13] : ln_cache_rdata[64*14-1:64*13];
wire [63:0] ln_data_in_14 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*15-1:64*14] : ln_cache_rdata[64*15-1:64*14];
wire [63:0] ln_data_in_15 = ln_state == SUM_COUNT ? ln_lbuf_rdata[64*16-1:64*15] : ln_cache_rdata[64*16-1:64*15];

// gather wdata from 16 processing blocks
wire [63:0] ln_data_out_0; 
wire [63:0] ln_data_out_1; 
wire [63:0] ln_data_out_2; 
wire [63:0] ln_data_out_3; 
wire [63:0] ln_data_out_4; 
wire [63:0] ln_data_out_5; 
wire [63:0] ln_data_out_6; 
wire [63:0] ln_data_out_7; 
wire [63:0] ln_data_out_8; 
wire [63:0] ln_data_out_9; 
wire [63:0] ln_data_out_10;
wire [63:0] ln_data_out_11;
wire [63:0] ln_data_out_12;
wire [63:0] ln_data_out_13;
wire [63:0] ln_data_out_14;
wire [63:0] ln_data_out_15;
assign ln_lbuf_wdata = {ln_data_out_15,ln_data_out_14,ln_data_out_13,ln_data_out_12,ln_data_out_11,ln_data_out_10,
ln_data_out_9,ln_data_out_8,ln_data_out_7,ln_data_out_6,ln_data_out_5,ln_data_out_4,ln_data_out_3,ln_data_out_2,ln_data_out_1,ln_data_out_0};

// cache data
assign ln_cache_wdata = ln_lbuf_rdata;

// counters for inner states
reg [CACHE_DATA_DEPTH:0] sum_count_cnt;
reg sum_div_cnt;
reg [7:0] sqrt_cnt;
reg [CACHE_DATA_DEPTH:0] out_cnt;

// addr control
reg [RADDR_WIDTH-1:0] ln_lbuf_raddr_sum;
reg [WADDR_WIDTH-1:0] ln_lbuf_waddr_sum; // accumulation of row addr
reg [CACHE_DATA_DEPTH-1:0] ln_lbuf_raddr_token;
reg [CACHE_DATA_DEPTH-1:0] ln_lbuf_waddr_token; // basic addr to process 1 row (token)
reg [RADDR_WIDTH-4:0] finish_token_cnt; // count finished rows (tokens), for state transition
reg [2:0] rd_flag; // handle mutiple read loops in state SUM_COUNT and OUT

// state transition
always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) ln_state <= IDLE;
    else ln_state <= ln_next_state;
end

// substate control signals
wire sum_count_tr = (sum_count_cnt == (ln_channel_number_per_unit - 1 + 1 + RLATENCY)); // plus1 because sum(X^2) pulse 2 clk
// pulse 1 because sum of 8 x^2 use 2 cycles, when SUM_COUNT ends, and transfer to next state
wire sum_en = (ln_state == SUM_COUNT && sum_count_cnt >= RLATENCY + 1); // enbale accumulators
wire sum_div_finish; // tranfer SUM_DIV to next state
wire sqrt_reci_finish;
wire out_tr = (out_cnt == (ln_channel_number_per_unit - 1 + CACHE_RLATENCY + 2)); // when OUT ends, and transfer to next state, plus 2 since pulse 2 cycle
// state transition conditions
always @(*) begin
    case(ln_state)
        IDLE: begin
            if (ln_start) ln_next_state = SUM_COUNT;
            else ln_next_state = ln_state;
        end
        SUM_COUNT: begin
            if (sum_count_tr) ln_next_state = SUM_DIV;
            else ln_next_state = ln_state;
        end
        SUM_DIV: begin
            if (sum_div_finish) ln_next_state = SQRT;
            else ln_next_state = ln_state;
        end
        SQRT: begin
            if (sqrt_reci_finish) ln_next_state = OUT;
            else ln_next_state = ln_state;
        end
        OUT: begin
            if (out_tr && finish_token_cnt < token_per_block) ln_next_state = SUM_COUNT; // whole process continues
            else if (out_tr && finish_token_cnt == token_per_block) ln_next_state = IDLE; // whole process ends
            else ln_next_state = ln_state;
        end
        default: begin
            ln_next_state = ln_state;
        end
    endcase
end

// send ln_end signal
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) ln_end <= 1'b0;
    else begin
        if (ln_end) ln_end <= 1'b0;
        else if (ln_next_state == IDLE && ln_state == OUT) ln_end <= 1'b1;
    end
end


always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) sum_count_cnt <= 'd0;
    else if (ln_state == SUM_COUNT) begin
        if (sum_count_tr) sum_count_cnt <= 'd0;
        else sum_count_cnt <= sum_count_cnt + 'd1;
    end
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) sum_div_cnt <= 'd0;
    else if (ln_state == SUM_DIV) begin
        if (sum_div_finish) sum_div_cnt <= 'd0;
        else sum_div_cnt <= sum_div_cnt + 'd1;
    end
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) sqrt_cnt <= 8'd0;
    else if (ln_state == SQRT) begin
        if (sqrt_reci_finish) sqrt_cnt <= 8'd0;
        else sqrt_cnt <= sqrt_cnt + 8'd1;
    end
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) out_cnt <= 'd0;
    else if (ln_state == OUT) begin
        if (out_tr) out_cnt <= 'd0;
        else out_cnt <= out_cnt + 'd1;
    end
end

// lbuf interface control
always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) ln_lbuf_waddr_token <= 'd0;
    else begin
        if (ln_state == SUM_COUNT && sum_count_cnt >= RLATENCY) ln_lbuf_waddr_token <= ln_lbuf_waddr_token + 'd1; // plus 2 since pluse 2
        else if (ln_state == OUT && out_cnt >= CACHE_RLATENCY + 2) ln_lbuf_waddr_token <= ln_lbuf_waddr_token + 'd1; // plus 2 since pluse 2
        else ln_lbuf_waddr_token <= 'd0;
    end
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) ln_lbuf_raddr_sum <= 'd0;
    else if (ln_state == OUT && out_tr) begin
        ln_lbuf_raddr_sum <= ln_lbuf_raddr_sum + ifm_addr_align;
    end
    else if (ln_start) ln_lbuf_raddr_sum <= im_base_addr;
    else if (ln_state == IDLE) ln_lbuf_raddr_sum <= 'd0;
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) ln_lbuf_waddr_sum <= 'd0;
    else if (ln_state == OUT && out_tr) begin
        ln_lbuf_waddr_sum <= ln_lbuf_waddr_sum + ofm_addr_align;
    end
    else if (ln_start) ln_lbuf_waddr_sum <= om_base_addr;
    else if (ln_state == IDLE) ln_lbuf_waddr_sum <= 'd0;
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) rd_flag <= 3'b000;
    else begin
        if (ln_state == SUM_COUNT && rd_flag == 3'b001 && ln_lbuf_raddr_token == ln_channel_number_per_unit - 1) rd_flag <= 3'b010; // max lock
        else if (ln_state == OUT && rd_flag == 3'b011 && ln_lbuf_raddr_token == ln_channel_number_per_unit - 1) rd_flag <= 3'b000; // max lock
        else if (ln_next_state == SUM_COUNT && rd_flag == 3'b000) rd_flag <= 3'b001;
        else if (ln_next_state == OUT && rd_flag == 3'b010) rd_flag <= 3'b011;
        else if (ln_state == IDLE) rd_flag <= 3'b000;
    end
end

// raddr per token rules
always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) ln_lbuf_raddr_token <= 'd0;
    else begin
        case(ln_state)
            SUM_COUNT: begin
                if (ln_lbuf_raddr_token == ln_channel_number_per_unit - 1) ln_lbuf_raddr_token <= 'd0;
                else if (rd_flag == 3'b001) ln_lbuf_raddr_token <= ln_lbuf_raddr_token + 'd1;
            end
            OUT: begin
                if (ln_lbuf_raddr_token == ln_channel_number_per_unit - 1) ln_lbuf_raddr_token <= 'd0;
                else if (rd_flag == 3'b011) ln_lbuf_raddr_token <= ln_lbuf_raddr_token + 'd1;
            end
            IDLE: ln_lbuf_raddr_token <= 'd0;
        endcase
    end
end

assign ln_lbuf_ren = (ln_state == SUM_COUNT && rd_flag == 3'b001);
assign ln_lbuf_raddr = ln_lbuf_raddr_token + ln_lbuf_raddr_sum;

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) finish_token_cnt <= 'd0;
    else if (ln_state == OUT) begin
        if (out_cnt == ln_channel_number_per_unit - 1 + CACHE_RLATENCY) finish_token_cnt <= finish_token_cnt + 'd1;
    end
    else if (ln_state == IDLE) finish_token_cnt <= 'd0;
end

assign ln_lbuf_wen = ln_state == OUT && out_cnt >= CACHE_RLATENCY + 2;
assign ln_lbuf_waddr = ln_lbuf_waddr_token + ln_lbuf_waddr_sum;

// ln-spu cache control
wire [CACHE_DATA_DEPTH-1:0] ln_cache_raddr, ln_cache_waddr;
assign ln_cache_ren = (ln_state == OUT && rd_flag == 3'b011);
assign ln_cache_raddr = ln_lbuf_raddr_token;

assign ln_cache_wen = (ln_state == SUM_COUNT && sum_count_cnt >= RLATENCY && sum_count_cnt <= (ln_channel_number_per_unit - 1 + RLATENCY));
assign ln_cache_waddr = ln_lbuf_waddr_token;

assign ln_cache_addr = ln_cache_ren ? ln_cache_raddr : ln_cache_waddr;

// padding control
reg [10:0] h_cnt;
reg [11:0] w_cnt;

wire ln_lbuf_ren_reg;
reg [RLATENCY-1-1:0] ln_lbuf_ren_shift_reg;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        ln_lbuf_ren_shift_reg <= 0;
    end 
    else if (RLATENCY >= 3) begin
        ln_lbuf_ren_shift_reg <= {ln_lbuf_ren_shift_reg[RLATENCY-2-1:0], ln_lbuf_ren};
    end
    else if (RLATENCY == 2) begin
        ln_lbuf_ren_shift_reg <= ln_lbuf_ren;
    end
end
assign ln_lbuf_ren_reg = ln_lbuf_ren_shift_reg[RLATENCY-1-1];

wire ln_cache_ren_reg;
reg [CACHE_RLATENCY-1-1:0] ln_cache_ren_shift_reg;
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        ln_cache_ren_shift_reg <= 0;
    end 
    else if (CACHE_RLATENCY >= 3) begin
        ln_cache_ren_shift_reg <= {ln_cache_ren_shift_reg[CACHE_RLATENCY-2-1:0], ln_cache_ren}; // TODO
    end
    else if (CACHE_RLATENCY == 2) begin
        ln_cache_ren_shift_reg <= ln_cache_ren; // TODO
    end
end
assign ln_cache_ren_reg = ln_cache_ren_shift_reg[CACHE_RLATENCY-1-1];


reg pad_ren;
always @(*) begin
    if (ln_state == SUM_COUNT) pad_ren = ln_lbuf_ren_reg;
    else if (ln_state == OUT) pad_ren = ln_cache_ren_reg;
    else pad_ren = 1'b0;
end

wire pad_ren_reg;
assign pad_ren_reg = pad_ren;

// for w
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) w_cnt <= 'd0;
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

// ln processing block instances
spu_ln_block u_spu_ln_block_0(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_0),
    .ln_div_e(ln_div_e_0),
    .sum_en(sum_en),
    .sum_div_finish(sum_div_finish),
    .sqrt_reci_finish(sqrt_reci_finish),
    .ln_b_data_in(ln_data_in_0),
    .ln_b_data_out(ln_data_out_0)
);
spu_ln_block u_spu_ln_block_1(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_0),
    .ln_div_e(ln_div_e_0),
    .sum_en(sum_en),
    .sum_div_finish(), // peng
    .sqrt_reci_finish(), // peng
    .ln_b_data_in(ln_data_in_1),
    .ln_b_data_out(ln_data_out_1)
);
spu_ln_block u_spu_ln_block_2(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_0),
    .ln_div_e(ln_div_e_0),
    .sum_en(sum_en),
    .sum_div_finish(),
    .sqrt_reci_finish(),
    .ln_b_data_in(ln_data_in_2),
    .ln_b_data_out(ln_data_out_2)
);
spu_ln_block u_spu_ln_block_3(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_0),
    .ln_div_e(ln_div_e_0),
    .sum_en(sum_en),
    .sum_div_finish(),
    .sqrt_reci_finish(),
    .ln_b_data_in(ln_data_in_3),
    .ln_b_data_out(ln_data_out_3)
);
spu_ln_block u_spu_ln_block_4(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_1),
    .ln_div_e(ln_div_e_1),
    .sum_en(sum_en),
    .sum_div_finish(),
    .sqrt_reci_finish(),
    .ln_b_data_in(ln_data_in_4),
    .ln_b_data_out(ln_data_out_4)
);
spu_ln_block u_spu_ln_block_5(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_1),
    .ln_div_e(ln_div_e_1),
    .sum_en(sum_en),
    .sum_div_finish(),
    .sqrt_reci_finish(),
    .ln_b_data_in(ln_data_in_5),
    .ln_b_data_out(ln_data_out_5)
);
spu_ln_block u_spu_ln_block_6(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_1),
    .ln_div_e(ln_div_e_1),
    .sum_en(sum_en),
    .sum_div_finish(),
    .sqrt_reci_finish(),
    .ln_b_data_in(ln_data_in_6),
    .ln_b_data_out(ln_data_out_6)
);
spu_ln_block u_spu_ln_block_7(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_1),
    .ln_div_e(ln_div_e_1),
    .sum_en(sum_en),
    .sum_div_finish(),
    .sqrt_reci_finish(),
    .ln_b_data_in(ln_data_in_7),
    .ln_b_data_out(ln_data_out_7)
);
spu_ln_block u_spu_ln_block_8(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_2),
    .ln_div_e(ln_div_e_2),
    .sum_en(sum_en),
    .sum_div_finish(),
    .sqrt_reci_finish(),
    .ln_b_data_in(ln_data_in_8),
    .ln_b_data_out(ln_data_out_8)
);
spu_ln_block u_spu_ln_block_9(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_2),
    .ln_div_e(ln_div_e_2),
    .sum_en(sum_en),
    .sum_div_finish(),
    .sqrt_reci_finish(),
    .ln_b_data_in(ln_data_in_9),
    .ln_b_data_out(ln_data_out_9)
);
spu_ln_block u_spu_ln_block_10(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_2),
    .ln_div_e(ln_div_e_2),
    .sum_en(sum_en),
    .sum_div_finish(),
    .sqrt_reci_finish(),
    .ln_b_data_in(ln_data_in_10),
    .ln_b_data_out(ln_data_out_10)
);
spu_ln_block u_spu_ln_block_11(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_2),
    .ln_div_e(ln_div_e_2),
    .sum_en(sum_en),
    .sum_div_finish(),
    .sqrt_reci_finish(),
    .ln_b_data_in(ln_data_in_11),
    .ln_b_data_out(ln_data_out_11)
);
spu_ln_block u_spu_ln_block_12(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_3),
    .ln_div_e(ln_div_e_3),
    .sum_en(sum_en),
    .sum_div_finish(),
    .sqrt_reci_finish(),
    .ln_b_data_in(ln_data_in_12),
    .ln_b_data_out(ln_data_out_12)
);
spu_ln_block u_spu_ln_block_13(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_3),
    .ln_div_e(ln_div_e_3),
    .sum_en(sum_en),
    .sum_div_finish(),
    .sqrt_reci_finish(),
    .ln_b_data_in(ln_data_in_13),
    .ln_b_data_out(ln_data_out_13)
);
spu_ln_block u_spu_ln_block_14(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_3),
    .ln_div_e(ln_div_e_3),
    .sum_en(sum_en),
    .sum_div_finish(),
    .sqrt_reci_finish(),
    .ln_b_data_in(ln_data_in_14),
    .ln_b_data_out(ln_data_out_14)
);
spu_ln_block u_spu_ln_block_15(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .pad_en(pad_en),
    .ln_op(ln_op),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m_3),
    .ln_div_e(ln_div_e_3),
    .sum_en(sum_en),
    .sum_div_finish(),
    .sqrt_reci_finish(),
    .ln_b_data_in(ln_data_in_15),
    .ln_b_data_out(ln_data_out_15)
);
endmodule
