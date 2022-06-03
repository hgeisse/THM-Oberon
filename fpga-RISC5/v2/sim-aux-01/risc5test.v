//
// risc5test.v -- RISC5 testbench
//


`timescale 1ns / 1ps
`default_nettype none


module risc5test;

  reg clk;			// clock, 100 MHz
  reg rst;			// reset, active high
  reg stb;
  reg we;
  reg [21:0] addr;
  reg [31:0] data_in;
  wire [31:0] data_out;
  wire ack;

  //
  // simulation control
  //

  initial begin
    #0          $timeformat(-9, 1, " ns", 12);
                $dumpfile("dump.vcd");
                $dumpvars(0, risc5test);
                clk = 1;
                rst = 1;
    #51         rst = 0;
                stb = 0;
    #100        stb = 1;
                we = 0;
                addr[21:0] = 22'h1000;
    #70         stb = 0;
    #80         stb = 1;
                we = 1;
                addr[21:0] = 22'h1000;
    #70         stb = 0;
    #80         stb = 1;
                we = 0;
                addr[21:0] = 22'h1000;
    #70         stb = 0;
    #30000      $finish;
  end

  //
  // clock generator
  //

  always begin
    #5 clk = ~clk;		// 10 nsec cycle time
  end

  //
  // module instantiations
  //

  ram ram_0(
    .clk(clk),
    .rst(rst),
    .stb(stb),
    .we(we),
    .addr(addr[21:0]),
    .data_in(data_in[31:0]),
    .data_out(data_out[31:0]),
    .ack(ack)
  );

  //
  // write data generator
  //

  always @(posedge clk) begin
    if (rst) begin
      data_in[31:0] <= 32'h44444444;
    end else begin
      if (we & ack) begin
        data_in[31:0] <= data_in[31:0] + 32'h11111111;
      end
    end
  end

endmodule
