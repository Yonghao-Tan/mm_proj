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
    output reg [19:0] dataOut
);

wire [8:0] adderStageA = x_0 + x_1;
wire [8:0] adderStageB = x_2 + x_3;

wire [10:0] adderStageC = adderStageA + adderStageB;


always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) dataOut <= 20'd0;
    else if (en) dataOut <= dataOut + adderStageC;
    else dataOut <= 20'd0;
end
endmodule
