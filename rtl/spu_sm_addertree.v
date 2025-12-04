`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/08 02:02:13
// Design Name: 
// Module Name: AdderTree
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


module spu_sm_addertree (
    input core_clk,
    input en,
    input rst_n,
    input  [7:0] x_0,
    input  [7:0] x_1,
    input  [7:0] x_2,
    input  [7:0] x_3,
    input  [7:0] x_4,
    input  [7:0] x_5,
    input  [7:0] x_6,
    input  [7:0] x_7,
    output reg [19:0] dataOut
);

wire [8:0] adderStageA_0 = x_0 + x_1;
wire [8:0] adderStageA_1 = x_2 + x_3;
wire [8:0] adderStageA_2 = x_4 + x_5;
wire [8:0] adderStageA_3 = x_6 + x_7;

wire [9:0] adderStageB_0 = adderStageA_0 + adderStageA_1;
wire [9:0] adderStageB_1 = adderStageA_2 + adderStageA_3;

wire [10:0] adderStageC_0 = adderStageB_0 + adderStageB_1;


always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) dataOut <= 20'd0;
    else if (en) dataOut <= dataOut + adderStageC_0;
    else dataOut <= 20'd0;
end
endmodule
