`timescale 1ns / 1ps
`define core_clk_PERIOD 20
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/30 15:27:48
// Design Name: 
// Module Name: SPU_tb
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


module SPU_tb();
localparam ADDR_WIDTH = 12;
localparam DATA_WIDTH = 32;
// aabbccddee
reg core_clk, rst_n, spu_config_en, spu_start, buffer_sel_wire, buffer_sel;
integer file1;
reg signed [7:0] data_0 [3:0];
initial begin
    file1 = $fopen("../../../../../output_spu.txt", "w");
    core_clk = 1;
    rst_n = 0;
    spu_start = 0;
    buffer_sel_wire = 1;
    #20;
    rst_n = 1;
    #20;
    spu_config_en = 1;
    #20;
    spu_config_en = 0;
    spu_start = 1;
    #20;
    spu_start = 0;
end
always #(`core_clk_PERIOD / 2) core_clk = ~core_clk;
 
wire [1-1:0] spu_op;
wire [ADDR_WIDTH-1:0] matrix_y; 
wire [ADDR_WIDTH-1:0] matrix_x; 
wire [4-1:0] shift0;
wire [4-1:0] shift1;
wire [5-1:0] shift2;
wire [7-1:0] ln_div_m;
wire [5-1:0] ln_div_e;
wire [ADDR_WIDTH-1:0] im_base_addr;   
wire [ADDR_WIDTH-1:0] om_base_addr;   
wire [ADDR_WIDTH-1:0] im_block_align; 
wire [ADDR_WIDTH-1:0] om_block_align;


assign spu_op = 1'b1;
assign matrix_y = 16'd3;
assign matrix_x = 16'd8;
assign shift0 = 4'b1001;
assign shift1 = 4'b0000;
assign shift2 = 5'b00000;
assign ln_div_m = 7'd64;
assign ln_div_e = 5'd9;
assign im_base_addr = 16'd0;
assign om_base_addr = 16'd0;
assign im_block_align = 12'b000000000010;
assign om_block_align = 12'b000000000010;

wire [35:0] total_test_rd_addr = matrix_y*matrix_x / 4 + om_base_addr;

reg [DATA_WIDTH-1:0] lbuf [(2**ADDR_WIDTH)-1:0];
// Read buffer content from file
initial begin
	$readmemh("../../../../../../test_scripts/data/lbuf_input.hex", lbuf);
end

wire [ADDR_WIDTH-1:0] lbuf_raddr;
wire [ADDR_WIDTH-1:0] lbuf_waddr;
wire lbuf_ren;
wire lbuf_wen;
reg [DATA_WIDTH-1:0] lbuf_rdata;
wire [DATA_WIDTH-1:0] lbuf_wdata;

reg [ADDR_WIDTH-1:0] tb_rd_cnt; // not enough bits!!!
wire tb_rd_en;

wire [ADDR_WIDTH-1:0] fmap_rd_addr = buffer_sel ? lbuf_raddr : tb_rd_cnt;
wire fmap_rd_en = buffer_sel ? lbuf_ren : tb_rd_en;

always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) lbuf_rdata <= 'd0;
    else if (lbuf_ren) lbuf_rdata <= lbuf[lbuf_raddr];
end
always @(posedge core_clk) begin
    if (lbuf_wen) lbuf[lbuf_waddr] <= lbuf_wdata;
end

special_pu u_special_pu(
    .core_clk(core_clk),
    .rst_n(rst_n), // system reset for spu, active low
    .spu_config_en(spu_config_en),
    .spu_start(spu_start), // enable for valid instruction, start process
    .spu_end(spu_end),    
    .spu_op_in(spu_op),
    .spu_matrix_y_in(matrix_y),
    .spu_matrix_x_in(matrix_x),
    .shift0_in(shift0),
    .shift1_in(shift1),
    .shift2_in(shift2),
    .im_base_addr_in(im_base_addr),
    .om_base_addr_in(om_base_addr),
    .im_block_align_in(im_block_align),
    .om_block_align_in(om_block_align),
    .ln_div_m_in(ln_div_m),
    .ln_div_e_in(ln_div_e),

    .lbuf_rdata(lbuf_rdata),
    .lbuf_wdata(lbuf_wdata),
    .lbuf_raddr(lbuf_raddr), // read addr for global buffer
    .lbuf_ren(lbuf_ren), // read enable for global buffer
    .lbuf_waddr(lbuf_waddr), // write addr for global buffer
    .lbuf_wen(lbuf_wen) // write enable for global buffer
);

always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) tb_rd_cnt <= 13'd0 + om_base_addr;
    else if (~buffer_sel && total_test_rd_addr > 1 && tb_rd_cnt >= total_test_rd_addr - 1) tb_rd_cnt <= total_test_rd_addr;
    else if (~buffer_sel && total_test_rd_addr == 1 && tb_rd_cnt >= total_test_rd_addr) tb_rd_cnt <= total_test_rd_addr + 1;
    else if (~buffer_sel) tb_rd_cnt <= tb_rd_cnt + 13'd1;
end

assign tb_rd_en = ~buffer_sel && tb_rd_cnt <= total_test_rd_addr - 1;

always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) buffer_sel <= 1'b1;
    else if(spu_end) buffer_sel <= 1'b0;
end

reg [35:0] total_read_cnt = 'd0;
always @(posedge core_clk) begin
    if (tb_rd_en) begin
        total_read_cnt <= total_read_cnt + 'd1;
        data_0[0] = lbuf[tb_rd_cnt][7:0];
        data_0[1] = lbuf[tb_rd_cnt][15:8];
        data_0[2] = lbuf[tb_rd_cnt][23:16];
        data_0[3] = lbuf[tb_rd_cnt][31:24];
        $fwrite(file1, "%d\n%d\n%d\n%d\n", data_0[0], data_0[1], data_0[2], data_0[3]);
    end
    else if (total_read_cnt == total_test_rd_addr - om_base_addr)  begin
        $fclose(file1);
        $finish;
    end
end
endmodule
