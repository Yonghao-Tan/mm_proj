`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/10 03:06:21
// Design Name: 
// Module Name: sm_max
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


module spu_sm_xmax(
    input core_clk,
    input rst_n,
    input comp_en,
    input comp_rst,
    input signed [7:0] sm_process_data_0,
    input signed [7:0] sm_process_data_1,
    input signed [7:0] sm_process_data_2,
    input signed [7:0] sm_process_data_3,
    output reg signed [7:0] max_comp
    );

wire signed [7:0] comp_s00 = sm_process_data_0 > sm_process_data_1 ? sm_process_data_0 : sm_process_data_1;
wire signed [7:0] comp_s01 = sm_process_data_2 > sm_process_data_3 ? sm_process_data_2 : sm_process_data_3;

wire signed [7:0] comp_s10 = comp_s00 > comp_s01 ? comp_s00 : comp_s01;

always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) max_comp <= 8'b10000001;
    else if (comp_en) max_comp <= comp_s10 > max_comp ? comp_s10 : max_comp;
    else if (comp_rst) max_comp <= 8'b10000001;
end
endmodule
