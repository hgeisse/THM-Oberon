//
// risc5test.v -- RISC5 testbench
//


`timescale 1ns/1ps
`default_nettype none


module risc5test;

  reg clk;			// clock, 100 MHz
  reg rst;			// reset, active high
  wire test_ended;		// test has ended
  wire test_error;		// test has failed

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
    #6000       $finish;
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

  pipe pipe_0(
    .clk(clk),
    .rst(rst),
    .test_ended(test_ended),
    .test_error(test_error)
  );

endmodule
