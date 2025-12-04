`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/29 15:07:39
// Design Name: 
// Module Name: spu_cache
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


module spu_cache #( // totally 16 * 8 * 512 = 1024 KB
    parameter DATA_WIDTH = 16*64,
    parameter DATA_DEPTH = 9
)
(
    input clka , //ram clk
    input clkb , //ram clk
    input wea,    //ram 写使能 WEA
    input web,    //ram 写使能 WEB
    input [DATA_DEPTH-1:0] addra , //ram 写地址
    input [DATA_DEPTH-1:0] addrb , //ram 写地址
    input [DATA_WIDTH-1:0] dina , //ram 写数据 DINA
    input [DATA_WIDTH-1:0] dinb , //ram 写数据 DINB
    output reg [DATA_WIDTH-1:0] douta , //ram 读数据 DOUTA
    output reg [DATA_WIDTH-1:0] doutb //ram 读数据 DOUTB
);
    //reg define
    
    reg [DATA_WIDTH-1:0] ram [0:2**DATA_DEPTH-1] ; //ram 数据
    //*****************************************************
    //**                   main code
    //*****************************************************
    

    always @(posedge clka) begin
        if(wea) ram[addra] <= dina;
    end 
 
    always @(posedge clkb) begin
        if(web) ram[addrb] <= dinb;
    end 
 
    always @(posedge clka) begin
        if(!wea) douta <= ram[addra];
        else douta <= 'd0;
    end 
 
    always @(posedge clkb) begin
        if(!web) doutb <= ram[addrb];
        else doutb <= 'd0;
    end 
endmodule
