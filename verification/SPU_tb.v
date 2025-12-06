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


assign spu_op = 1'b0;
assign matrix_y = 16'd1;
assign matrix_x = 16'd16;
assign shift0 = 4'b1100;
assign shift1 = 4'b0011;
assign shift2 = 5'b00101;
assign ln_div_m = 7'd0;
assign ln_div_e = 5'd0;
assign im_base_addr = 16'd0;
assign om_base_addr = 16'd0;
assign im_block_align = 12'b000000000100;
assign om_block_align = 12'b000000000100;

wire [35:0] total_test_rd_addr = matrix_y*matrix_x / 4 + om_base_addr;

reg [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0];
// Read buffer content from file
initial begin
	$readmemh("../../../../../../test_scripts/data/gbuf_input.hex", mem);
end

wire [ADDR_WIDTH-1:0] gbuf_addr;
wire gbuf_wen;
reg [DATA_WIDTH-1:0] gbuf_dout;
wire [DATA_WIDTH-1:0] gbuf_din;

reg [ADDR_WIDTH-1:0] tb_rd_cnt;
wire tb_rd_en;

always @(posedge core_clk) begin
	if (gbuf_cen == 1'b0) begin
		if (gbuf_wen == 1'b0)
			mem[gbuf_addr] <= gbuf_din;
		else
			gbuf_dout <= mem[gbuf_addr];
	end
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

    .gbuf_cen(gbuf_cen),
    .gbuf_wen(gbuf_wen),
    .gbuf_addr(gbuf_addr),
    .gbuf_din(gbuf_din),
    .gbuf_dout(gbuf_dout)
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
        data_0[0] = mem[tb_rd_cnt][7:0];
        data_0[1] = mem[tb_rd_cnt][15:8];
        data_0[2] = mem[tb_rd_cnt][23:16];
        data_0[3] = mem[tb_rd_cnt][31:24];
        $fwrite(file1, "%d\n%d\n%d\n%d\n", data_0[0], data_0[1], data_0[2], data_0[3]);
    end
    else if (total_read_cnt == total_test_rd_addr - om_base_addr)  begin
        $fclose(file1);
        $finish;
    end
end
endmodule
