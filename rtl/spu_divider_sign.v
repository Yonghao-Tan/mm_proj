// -----------------------------------------------------------------------------
// Copyright (c) 2023
// AI Chip Center for Emerging Smart Systems
// All rights reserved
// ACCESS Proprietary and Confidential
// -----------------------------------------------------------------------------
// File Name : ewp_divider.v
// Project   :  
// Author    :  
// -----------------------------------------------------------------------------
// Description : 
//     
// -----------------------------------------------------------------------------
module spu_divider_sign #(
    parameter               DIVIDEND_DW = 1             ,
    parameter               DIVISOR_DW = 10             ,
    parameter               PRECISION_DW = 2+12             , // should be equal with the extend precision you prefer + decimal bits of divisor 
    localparam TOTAL_DW = DIVIDEND_DW + PRECISION_DW,
    // parameter  [TOTAL_DW-1:0]     STAGE_LIST = 16'hffff
    parameter  [TOTAL_DW-1:0]     STAGE_LIST = 16'b0101_0101_0101_0101
)
// total cycles org: DW; now should be DIVIDEND_DW + PRECISION_DW
(
    input                   core_clk            ,
    input                   rst_n               ,

    input      [DIVIDEND_DW-1:0]     data0               ,
    input      [DIVISOR_DW-1:0]     data1               ,
    input                   div_vld             ,

    output reg [TOTAL_DW-1:0]     div_data_out        ,
    output reg              div_ack
);

//signed into abs
wire [DIVIDEND_DW-1:0] data0_abs ;
wire [DIVISOR_DW-1:0] data1_abs ;
wire          data_sign ;

assign data0_abs = data0[DIVIDEND_DW-1] ? (~data0 + 1'b1) : data0;
assign data1_abs = data1;
assign data_sign = data0[DIVIDEND_DW-1];


//divider function
reg   [TOTAL_DW:0] ready     ;
reg  [TOTAL_DW-1:0]   dividend[TOTAL_DW:0]  ;
reg  [DIVISOR_DW-1:0]   divisor[TOTAL_DW:0]   ;
reg  [TOTAL_DW-1:0]   quotient[TOTAL_DW:0]  ;
reg             sign[TOTAL_DW:0]      ;

always @(*) begin
    ready[0]    = div_vld;
    dividend[0] = {data0_abs, {PRECISION_DW{1'b0}}};
    divisor[0]  = data1_abs;
    quotient[0] = 1'b0;
    sign[0]     = data_sign;
end

generate
    genvar i;
    for(i=0;i<TOTAL_DW;i=i+1) begin:gen_div
        
        wire [i:0]      m   ;
        wire [i:0]      n   ;
        wire            q   ;
        wire [i:0]      t   ;
        wire [TOTAL_DW-1:0]   u   ;
        wire [TOTAL_DW+i:0]   d   ;
        
        assign m = dividend[i]>>(TOTAL_DW-i-1); // not - i, instead (i-1) because the sign bit is not considered, same as dividend[i][DW-1:DW-i-1] 这样子似乎浪费了第一个周期
        // assign m = dividend[i][DW-1:DW-i-1];
        assign n = divisor[i]; // same as divisor[i:0]
        assign q = (|(divisor[i]>>(i+1))) ? 1'b0 : (m>=n); // a bit like LOD, for example, if 011001 divided by 001000, at i<=2, the divisor has at least 1 one at MSB which is higher than the m we cut from dividedend
        // 即为如果我们从被除数拿出来的数只有三位,而除数起码>=1000那么肯定这次的商是0,没必要继续做,但是当我们拿出被除数的四位,那么除数只是>=4'b1000,不能确定大于拿出的被除数那部分,就需要后续的比较了
        assign t = q ? (m-n) : m;
        assign u = dividend[i]<<(i+1); // 除了当前被除位之外的那几位,准备用来拼接形成新的被除数,如10010÷10那1比不了10,所以q=0,t=1,然后u就是10010<<1即0010,就是剩下那几位,拼接就是d={1,0010}
        assign d = {t,u}>>(i+1);

        if(STAGE_LIST[TOTAL_DW-i-1]) begin:gen_ff
            always @(posedge core_clk or negedge rst_n) begin
                if(rst_n == 1'b0) begin
                    ready[i+1]    <= 1'b0;
                    dividend[i+1] <= {TOTAL_DW{1'b0}};
                    divisor[i+1]  <= {DIVISOR_DW{1'b0}};
                    quotient[i+1] <= {TOTAL_DW{1'b0}};
                    sign[i+1]     <= 1'b0;
                end
                else begin
                    ready[i+1]    <= ready[i];
                    dividend[i+1] <= d;
                    divisor[i+1]  <= divisor[i];
                    quotient[i+1] <= quotient[i]|(q<<(TOTAL_DW-i-1)); // for example, q=1 at this loop, 0000 | 1000 = 1000
                    sign[i+1]     <= sign[i];
                end
            end
        end
        else begin:gen_comb
            always @(*) begin
                ready[i+1]    = ready[i];
                dividend[i+1] = d;
                divisor[i+1]  = divisor[i];
                quotient[i+1] = quotient[i]|(q<<(TOTAL_DW-i-1));
                sign[i+1]     = sign[i];
            end
        end
    end
endgenerate


//abs into signed
always @(posedge core_clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        div_data_out <= {TOTAL_DW{1'b0}};
        div_ack <= 1'b0;
    end
    else begin
        if (|ready) div_data_out <= sign[TOTAL_DW] ? (~quotient[TOTAL_DW] + 1'b1) : quotient[TOTAL_DW];
        div_ack <= ready[TOTAL_DW];
    end
end
endmodule

