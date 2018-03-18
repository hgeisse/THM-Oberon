//
// risc5test.v -- RISC5 testbench
//


`timescale 1ns/1ps
`default_nettype none


module risc5test;

  reg clk_in;			// clock, input, 50 MHz
  reg rst_in_n;			// reset, input, active low

  //
  // simulation control
  //

  initial begin
    #0          $timeformat(-9, 1, " ns", 12);
                $dumpfile("dump.vcd");
                $dumpvars(0, risc5test);
                clk_in = 1;
                rst_in_n = 0;
    #145        rst_in_n = 1;
    #10000      $finish;
  end

  //
  // clock generator
  //

  always begin
    #10 clk_in = ~clk_in;	// 20 nsec cycle time
  end

  //
  // module instantiations
  //

  risc5top risc5top_1(
    .clk_in(clk_in),
    .rst_in_n(rst_in_n)
  );

endmodule
