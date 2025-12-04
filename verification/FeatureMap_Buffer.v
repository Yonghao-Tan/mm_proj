`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/30 15:29:18
// Design Name: 
// Module Name: FeatureMap_Buffer
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


module FeatureMap_Buffer(
    input core_clk,
    input [12:0] fmap_rd_addr,
    input [12:0] fmap_wr_addr,
    input fmap_rd_en,
    input fmap_wr_en,
    input [63:0] fmap_wr_data_bank_0,
    input [63:0] fmap_wr_data_bank_1,
    input [63:0] fmap_wr_data_bank_2,
    input [63:0] fmap_wr_data_bank_3,
    input [63:0] fmap_wr_data_bank_4,
    input [63:0] fmap_wr_data_bank_5,
    input [63:0] fmap_wr_data_bank_6,
    input [63:0] fmap_wr_data_bank_7,
    input [63:0] fmap_wr_data_bank_8,
    input [63:0] fmap_wr_data_bank_9,
    input [63:0] fmap_wr_data_bank_10,
    input [63:0] fmap_wr_data_bank_11,
    input [63:0] fmap_wr_data_bank_12,
    input [63:0] fmap_wr_data_bank_13,
    input [63:0] fmap_wr_data_bank_14,
    input [63:0] fmap_wr_data_bank_15,
    output [63:0] fmap_rd_data_bank_0,
    output [63:0] fmap_rd_data_bank_1,
    output [63:0] fmap_rd_data_bank_2,
    output [63:0] fmap_rd_data_bank_3,
    output [63:0] fmap_rd_data_bank_4,
    output [63:0] fmap_rd_data_bank_5,
    output [63:0] fmap_rd_data_bank_6,
    output [63:0] fmap_rd_data_bank_7,
    output [63:0] fmap_rd_data_bank_8,
    output [63:0] fmap_rd_data_bank_9,
    output [63:0] fmap_rd_data_bank_10,
    output [63:0] fmap_rd_data_bank_11,
    output [63:0] fmap_rd_data_bank_12,
    output [63:0] fmap_rd_data_bank_13,
    output [63:0] fmap_rd_data_bank_14,
    output [63:0] fmap_rd_data_bank_15
);

FeatureMap_Bank_0 u_FeatureMap_Bank_0(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_0),
    .data_rd(fmap_rd_data_bank_0)
);
FeatureMap_Bank_1 u_FeatureMap_Bank_1(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_1),
    .data_rd(fmap_rd_data_bank_1)
);
FeatureMap_Bank_2 u_FeatureMap_Bank_2(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_2),
    .data_rd(fmap_rd_data_bank_2)
);
FeatureMap_Bank_3 u_FeatureMap_Bank_3(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_3),
    .data_rd(fmap_rd_data_bank_3)
);
FeatureMap_Bank_4 u_FeatureMap_Bank_4(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_4),
    .data_rd(fmap_rd_data_bank_4)
);
FeatureMap_Bank_5 u_FeatureMap_Bank_5(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_5),
    .data_rd(fmap_rd_data_bank_5)
);
FeatureMap_Bank_6 u_FeatureMap_Bank_6(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_6),
    .data_rd(fmap_rd_data_bank_6)
);
FeatureMap_Bank_7 u_FeatureMap_Bank_7(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_7),
    .data_rd(fmap_rd_data_bank_7)
);
FeatureMap_Bank_8 u_FeatureMap_Bank_8(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_8),
    .data_rd(fmap_rd_data_bank_8)
);
FeatureMap_Bank_9 u_FeatureMap_Bank_9(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_9),
    .data_rd(fmap_rd_data_bank_9)
);
FeatureMap_Bank_10 u_FeatureMap_Bank_10(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_10),
    .data_rd(fmap_rd_data_bank_10)
);
FeatureMap_Bank_11 u_FeatureMap_Bank_11(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_11),
    .data_rd(fmap_rd_data_bank_11)
);
FeatureMap_Bank_12 u_FeatureMap_Bank_12(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_12),
    .data_rd(fmap_rd_data_bank_12)
);
FeatureMap_Bank_13 u_FeatureMap_Bank_13(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_13),
    .data_rd(fmap_rd_data_bank_13)
);
FeatureMap_Bank_14 u_FeatureMap_Bank_14(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_14),
    .data_rd(fmap_rd_data_bank_14)
);
FeatureMap_Bank_15 u_FeatureMap_Bank_15(
    .clk_rd(core_clk),
    .clk_wr(core_clk),
    .rd_en(fmap_rd_en),
    .wr_en(fmap_wr_en),
    .addr_rd(fmap_rd_addr),
    .addr_wr(fmap_wr_addr),
    .data_wr(fmap_wr_data_bank_15),
    .data_rd(fmap_rd_data_bank_15)
);
endmodule
