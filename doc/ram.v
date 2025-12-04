// DESCRIPTION : 
// ram model with configurable wordwidth and depth

module sram#(parameter 	WORDWIDTH = 32, 
            parameter WORDDEPTH = 2048,
            parameter ADDRWIDTH = $clog2(WORDDEPTH))
	(
	input clk,
	input cen,
	input wen,
	input [ADDRWIDTH-1:0] addr,
	input [WORDWIDTH-1:0] din,
	output reg [WORDWIDTH-1:0] dout
	);

reg [WORDWIDTH-1:0] mem [0:WORDDEPTH-1];

always @(posedge clk) begin
	if (cen == 1'b0) begin
		if (wen == 1'b0)
			mem[addr] <= din;
		else
			dout <= mem[addr];
	end
end

endmodule
