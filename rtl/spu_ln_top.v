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


module spu_ln_top #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32,
    parameter RLATENCY = 1
)
(
    // Global Signals definition
    input core_clk, // process clock
    input rst_n, // reset input, active-low

    // Control Interface definition
    input ln_start, // ln process start (a pulse)
    output reg ln_end, // ln process ending (a pulse)

    // extend information signals
    input [ADDR_WIDTH-1:0] spu_matrix_y,
    input [ADDR_WIDTH-1:0] spu_matrix_x,
    input [ADDR_WIDTH-1:0] im_base_addr,
    input [ADDR_WIDTH-1:0] om_base_addr,
    input [ADDR_WIDTH-1:0] ifm_addr_align,
    input [ADDR_WIDTH-1:0] ofm_addr_align,
    input [3:0] ln_shift_output,
    input [6:0] ln_div_m,
    input [4:0] ln_div_e,

    // fmbuf Interface definition
    output reg ln_gbuf_ren, // gbuf read enable
    output [ADDR_WIDTH-1:0] ln_gbuf_raddr, // gbuf read address, validated by ln_gbuf_ren
    input [DATA_WIDTH-1:0] ln_gbuf_rdata, // gbuf read data, 2cycle delay from ln_gbuf_ren
    output reg ln_gbuf_wen, // gbuf write enable
    output [ADDR_WIDTH-1:0] ln_gbuf_waddr, // gbuf write address, validated by ln_gbuf_wen
    output [DATA_WIDTH-1:0] ln_gbuf_wdata // gbuf write data, validated by ln_gbuf_wen
);

// ln state machine
localparam IDLE = 3'b000;
localparam SUM_COUNT = 3'b001;
localparam SUM_DIV = 3'b011;
localparam SQRT = 3'b100;
localparam OUT = 3'b110;

localparam OUT_COMP_LATENCY = 0;
localparam SUM_COUNT_LATENCY = 0;

reg [2:0] ln_next_state, ln_state; // ln state machine signals

// other params
wire [ADDR_WIDTH-1:0] spu_matrix_x_per_unit = spu_matrix_x >> 2;

// decompose rdata for 16 processing blocks
wire [DATA_WIDTH-1:0] ln_data_in = ln_gbuf_rdata;

// gather wdata from 16 processing blocks
wire [DATA_WIDTH-1:0] ln_data_out; 
assign ln_gbuf_wdata = ln_data_out;

// counters for inner states
reg [ADDR_WIDTH-1:0] sum_count_cnt;
reg sum_div_cnt;
reg [7:0] sqrt_cnt;
reg [ADDR_WIDTH-1:0] out_cnt;

// addr control
reg [ADDR_WIDTH-1:0] ln_gbuf_raddr_sum;
reg [ADDR_WIDTH-1:0] ln_gbuf_waddr_sum; // accumulation of row addr
reg [ADDR_WIDTH-1:0] ln_gbuf_raddr_token;
reg [ADDR_WIDTH-1:0] ln_gbuf_waddr_token; // basic addr to process 1 row (token)
reg [ADDR_WIDTH-1:0] finish_token_cnt; // count finished rows (tokens), for state transition
reg [2:0] rd_flag; // handle mutiple read loops in state SUM_COUNT and OUT

// Toggle for interleaved read/write in OUT stage
reg rw_toggle;

// state transition
always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) ln_state <= IDLE;
    else ln_state <= ln_next_state;
end

// substate control signals
wire sum_count_tr = (sum_count_cnt == (spu_matrix_x_per_unit - 1 + SUM_COUNT_LATENCY + RLATENCY)); // plus1 because sum(X^2) pulse 2 clk
// pulse 1 because sum of 8 x^2 use 2 cycles, when SUM_COUNT ends, and transfer to next state
wire sum_en = (ln_state == SUM_COUNT && sum_count_cnt >= RLATENCY + SUM_COUNT_LATENCY); // enbale accumulators
wire sum_div_finish; // tranfer SUM_DIV to next state
wire sqrt_reci_finish;
// OUT transition needs to account for 2x cycles due to interleaved R/W
// Adjusted threshold: -2 to match SM fix
wire out_tr = (out_cnt == (spu_matrix_x_per_unit - 2 + RLATENCY + OUT_COMP_LATENCY)) && rw_toggle;

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
            if (out_tr && finish_token_cnt < spu_matrix_y) ln_next_state = SUM_COUNT; // whole process continues
            else if (out_tr && finish_token_cnt == spu_matrix_y) ln_next_state = IDLE; // whole process ends
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

// rw_toggle control
always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) rw_toggle <= 1'b0; // Start with Read
    else if (ln_state == OUT) begin
        rw_toggle <= ~rw_toggle;
    end
    else begin
        rw_toggle <= 1'b0;
    end
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) out_cnt <= 'd0;
    else if (ln_state == OUT) begin
        if (out_tr) out_cnt <= 'd0;
        else if (rw_toggle) out_cnt <= out_cnt + 'd1; // Increment only after Write cycle
    end
end

// gbuf interface control
always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) ln_gbuf_raddr_sum <= 'd0;
    else if (ln_state == OUT && out_tr) begin
        ln_gbuf_raddr_sum <= ln_gbuf_raddr_sum + ifm_addr_align;
    end
    else if (ln_start) ln_gbuf_raddr_sum <= im_base_addr;
    else if (ln_state == IDLE) ln_gbuf_raddr_sum <= 'd0;
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) ln_gbuf_waddr_sum <= 'd0;
    else if (ln_state == OUT && out_tr) begin
        ln_gbuf_waddr_sum <= ln_gbuf_waddr_sum + ofm_addr_align;
    end
    else if (ln_start) ln_gbuf_waddr_sum <= om_base_addr;
    else if (ln_state == IDLE) ln_gbuf_waddr_sum <= 'd0;
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) rd_flag <= 3'b000;
    else begin
        if (ln_state == SUM_COUNT && rd_flag == 3'b001 && ln_gbuf_raddr_token == spu_matrix_x_per_unit - 1) rd_flag <= 3'b010; // max lock
        else if (ln_state == OUT && rd_flag == 3'b011 && ln_gbuf_raddr_token == spu_matrix_x_per_unit - 1 && !rw_toggle) rd_flag <= 3'b000; // max lock - wait for last read
        else if (ln_next_state == SUM_COUNT && rd_flag == 3'b000) rd_flag <= 3'b001;
        else if (ln_next_state == OUT && rd_flag == 3'b010) rd_flag <= 3'b011;
        else if (ln_state == IDLE) rd_flag <= 3'b000;
    end
end

// raddr per token rules
always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) ln_gbuf_raddr_token <= 'd0;
    else begin
        case(ln_state)
            SUM_COUNT: begin
                if (ln_gbuf_raddr_token == spu_matrix_x_per_unit - 1) ln_gbuf_raddr_token <= 'd0;
                else if (rd_flag == 3'b001) ln_gbuf_raddr_token <= ln_gbuf_raddr_token + 'd1;
            end
            OUT: begin
                if (ln_gbuf_raddr_token == spu_matrix_x_per_unit - 1 && !rw_toggle) ln_gbuf_raddr_token <= 'd0;
                else if (rd_flag == 3'b011 && !rw_toggle) ln_gbuf_raddr_token <= ln_gbuf_raddr_token + 'd1; // Only increment on Read cycles
            end
            IDLE: ln_gbuf_raddr_token <= 'd0;
        endcase
    end
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) ln_gbuf_waddr_token <= 'd0;
    else begin
        if (ln_state == OUT) begin
             if (out_cnt + 1 >= RLATENCY + OUT_COMP_LATENCY && rw_toggle) ln_gbuf_waddr_token <= ln_gbuf_waddr_token + 'd1;
        end
        else ln_gbuf_waddr_token <= 'd0;
    end
end

assign ln_gbuf_raddr = ln_gbuf_raddr_token + ln_gbuf_raddr_sum;
always @(*) begin
    ln_gbuf_ren = (ln_state == SUM_COUNT && rd_flag == 3'b001) || (ln_state == OUT && rd_flag == 3'b011 && !rw_toggle);
end

always @(posedge core_clk or negedge rst_n) begin
    if (!rst_n) finish_token_cnt <= 'd0;
    else if (ln_state == OUT) begin
        if (out_cnt == spu_matrix_x_per_unit - 2 + RLATENCY + OUT_COMP_LATENCY && ~rw_toggle) finish_token_cnt <= finish_token_cnt + 'd1;
    end
    else if (ln_state == IDLE) finish_token_cnt <= 'd0;
end

always @(*) begin
    ln_gbuf_wen = (ln_state == OUT && 
                   out_cnt + 1 >= RLATENCY + OUT_COMP_LATENCY && 
                   out_cnt < spu_matrix_x_per_unit - 1 + RLATENCY + OUT_COMP_LATENCY && 
                   rw_toggle);
end

assign ln_gbuf_waddr = ln_gbuf_waddr_token + ln_gbuf_waddr_sum;

// ln processing block instances
spu_ln_block u_spu_ln_block(
    .core_clk(core_clk),
    .rst_n(rst_n),
    .ln_state(ln_state),
    .sum_div_cnt(sum_div_cnt),
    .sqrt_cnt(sqrt_cnt),
    .ln_shift_output(ln_shift_output),
    .ln_div_m(ln_div_m),
    .ln_div_e(ln_div_e),
    .sum_en(sum_en),
    .sum_div_finish(sum_div_finish),
    .sqrt_reci_finish(sqrt_reci_finish),
    .ln_b_data_in(ln_data_in),
    .ln_b_data_out(ln_data_out)
);
endmodule
