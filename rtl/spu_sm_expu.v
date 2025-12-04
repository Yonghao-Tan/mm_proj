`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/07 17:40:48
// Design Name: 
// Module Name: EU
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


module spu_sm_expu(
    input [15:0] dataIn, // 0000_0000.0000_0000
    output [11:0] dataOut
);

wire [15:0] mulIn = dataIn;
// wire [7:0] intU, DecV;
wire [7:0] intU;
wire [7:0] DecV;
spu_sm_expu_mul u_spu_sm_expu_mul( // multiply bu 1.0111/1.01110001
    .dataIn(mulIn),
    .dataOut({intU, DecV})
);

wire [7:0] b = 8'b11_1110_00; // 11_1110_1000_00
wire [7:0] tmp = b - (DecV >> 1);
wire [15:0] dataOut_long = {tmp, 8'b0000_0000};
wire [15:0] dataOut_tmp = dataOut_long >> intU;
assign dataOut = dataIn[15] ? 12'b1111_1111_1111 : dataOut_tmp[15:4];
endmodule
