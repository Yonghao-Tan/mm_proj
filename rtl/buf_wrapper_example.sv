module buf_wrapper (
  input   wire           clka,
  input   wire           wea,
  input   wire  [9:0]    addra,
  input   wire  [63:0]   dina,
  `ifdef ASIC
  input   wire           pd,   //Active-high Power Down
  `endif

  input   wire           clkb,
  input   wire           rstb_n,
  input   wire           enb,
  input   wire  [9:0]    addrb,
  output  wire  [63:0]   doutb
);

`ifdef ASIC
// ASIC memory instantiation by Memory compiler
TS6N40LPA1024X64M2S u_2prf_1024x64(
            // write port
            .AA     (addra          ),//Address write bus
            .D      (dina           ),//Date input bus
            .BWEB   ({64{1'b0}}     ),//BW data input bus
            .WEB    (~wea           ),//Active-low Write enable
            .CLKW   (clka           ),//Clock A
            // read port
            .AB     (addrb          ),//Address read bus
            .REB    (~enb           ),//Active-low Read enable
            .CLKR   (clkb           ),//Clock B
            .PD     (pd             ),//Active-high Power Down
            .Q      (doutb          ) //Data output bus
            );
`else
// FPGA block memory
fpga_sdp_ram #(
  .RAM_WIDTH(64),                      // Specify RAM data width
  .RAM_DEPTH(1024),                    // Specify RAM depth (number of entries)
  .RAM_PERFORMANCE("LOW_LATENCY"),      // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
  .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
) u_cnn_weibuf(
  .addra(addra),                        // Write address bus, width determined from RAM_DEPTH
  .addrb(addrb),                        // Read address bus, width determined from RAM_DEPTH
  .dina(dina),                          // RAM input data
  .clka(clka),                          // Write clock
  .clkb(clkb),                          // Read clock
  .wea(wea),                            // Write enable
  .enb(enb),                            // Read Enable, for additional power savings, disable when not in use
  .rstb(~rstb_n),                       // Output reset (does not affect memory contents)
  .regceb(1'b0),                        // Output register enable
  .doutb(doutb)                         // RAM output data
);                                         

`endif

endmodule
