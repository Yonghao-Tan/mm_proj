module spu_ln_sqrt #(
    parameter DW = 16                       //输入数据位宽
)(
    input wire core_clk,                         //时钟
    input wire rst_n,                       //低电平复位，异步复位同步释放

    input wire [DW-1:0] din_i,              //开方数据输入
    input wire din_valid_i,                 //数据输入有效

    output reg sqrt_finish,
    output wire [(DW+(DW%2))/2-1:0] sqrt_o //开方结果输出, from reg
);
//数据输入位宽，向上扩展到偶数
localparam din_width = DW + (DW%2);
//迭代次数
localparam iteration_number = din_width/2;
//迭代计数器位宽
localparam icnt_width = $clog2(iteration_number);
//开方结果位宽
localparam sqrt_width = iteration_number;

//开方数据输入寄存器
reg [din_width-1:0]din_reg;
//迭代计数器
reg [icnt_width-1:0]icnt;
//开方状态寄存器，1;计算中，0:等待
reg sqrt_en;
//开方结果寄存器
reg [sqrt_width-1:0]sqrt_data;
//开方余数/部分余数寄存器
reg [DW-2:0]rem_data;

//结果左移2位+1
wire [DW:0]sqrt_l2a1 = {sqrt_data, 2'b01};
//部分余数与下个2位合成
wire [DW:0]rem_a2b = {rem_data, din_reg[din_width-1:din_width-2]}; // 之前的余数和最新从还没有进行开根操作的最高两位拿过来拼在一起，进行开根判断
//比较
wire rem_cmp = (rem_a2b>=sqrt_l2a1) ? 1'b1 : 1'b0; // l2a1是作为一个阈值，计算方式是已经求出来的商<<2+1，如已经有101，就是10100+1=10101，要上回合剩的余数和10101比较，余数大则商的新位置置1
//下一个部分余数
wire [DW-2:0]rem_next = rem_cmp ? (rem_a2b-sqrt_l2a1) : rem_a2b; // 如果商的最新位置（最低位）置1，就需要用余数减去1*刚才求出来的l2a1值（阈值）作为新的商；否则余数沿用，
//下一个部分结果
wire sqrt_next = rem_cmp;


//状态控制
always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) begin
        sqrt_en <= 1'b0;
        icnt <= 1'b0;
        din_reg <= 1'b0;
        sqrt_data <= 1'b0;
        rem_data <= 1'b0;
    end
    else begin
        case (sqrt_en)
            1'b0 : begin//等待中
                if (din_valid_i) begin//输入有效
                    sqrt_en <= 1'b1;
                    icnt <= iteration_number-1;
                    din_reg <= {1'b0, din_i};//输入数据扩展到偶数
                    sqrt_data <= 0;
                    rem_data <= 0;
                end
            end
            1'b1 : begin//迭代中
                icnt <= icnt-1;
                din_reg <= {din_reg[din_width-3:0], 2'b00};
                sqrt_data <= {sqrt_data[sqrt_width-2:0], sqrt_next};
                rem_data <= rem_next;
                if (icnt==0) begin//结束迭代
                    sqrt_en <= 1'b0;
                end
            end
        endcase
    end
end

always @(posedge core_clk or negedge rst_n) begin
    if (~rst_n) sqrt_finish <= 1'b0;
    else sqrt_finish <= sqrt_en && icnt==0;
end
assign sqrt_o = sqrt_data;

endmodule