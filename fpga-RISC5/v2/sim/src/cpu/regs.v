//
// regs.v -- triple-ported register file
//           implemented by two dual-ported register sets
//


`timescale 1ns / 1ps
`default_nettype none


module regs(clk, rst,
            rd_reg_1, rd_data_1,
            rd_reg_2, rd_data_2,
            wr_reg, wr_data, wr_en);
    input clk;				// system clock
    input rst;				// system reset
    input [3:0] rd_reg_1;
    output reg [31:0] rd_data_1;
    input [3:0] rd_reg_2;
    output reg [31:0] rd_data_2;
    input [3:0] wr_reg;
    input [31:0] wr_data;
    input wr_en;			// write enable

  reg [31:0] r1[0:15];
  reg [31:0] r2[0:15];

  // register set 1

  always @(posedge clk) begin
    if (wr_en) begin
      // NOTE: use "=" here for reading new data below
      r1[wr_reg] <= wr_data;
    end
    rd_data_1 <= r1[rd_reg_1];
  end

  // register set 2

  always @(posedge clk) begin
    if (wr_en) begin
      // NOTE: use "=" here for reading new data below
      r2[wr_reg] <= wr_data;
    end
    rd_data_2 <= r2[rd_reg_2];
  end

  // random initialization

  initial begin
    r1[ 0] = 32'h025DE15E;
    r1[ 1] = 32'h0D4D67E6;
    r1[ 2] = 32'h6D6228D3;
    r1[ 3] = 32'h3ECC6079;
    r1[ 4] = 32'h0E7D6D32;
    r1[ 5] = 32'h1D44B8B0;
    r1[ 6] = 32'h54933EA7;
    r1[ 7] = 32'h3C61EE4A;
    r1[ 8] = 32'h29BD08C8;
    r1[ 9] = 32'h652410B0;
    r1[10] = 32'h4759259C;
    r1[11] = 32'h6EF16AF0;
    r1[12] = 32'h0FCCE109;
    r1[13] = 32'h27831A1D;
    r1[14] = 32'h2F08AF2C;
    r1[15] = 32'h23FD21A9;
    r2[ 0] = 32'h025DE15E;
    r2[ 1] = 32'h0D4D67E6;
    r2[ 2] = 32'h6D6228D3;
    r2[ 3] = 32'h3ECC6079;
    r2[ 4] = 32'h0E7D6D32;
    r2[ 5] = 32'h1D44B8B0;
    r2[ 6] = 32'h54933EA7;
    r2[ 7] = 32'h3C61EE4A;
    r2[ 8] = 32'h29BD08C8;
    r2[ 9] = 32'h652410B0;
    r2[10] = 32'h4759259C;
    r2[11] = 32'h6EF16AF0;
    r2[12] = 32'h0FCCE109;
    r2[13] = 32'h27831A1D;
    r2[14] = 32'h2F08AF2C;
    r2[15] = 32'h23FD21A9;
  end

endmodule
