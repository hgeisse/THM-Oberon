//
// risc5test.v -- RISC5 testbench
//


`timescale 1ns / 1ps
`default_nettype none


module risc5test;

  reg CLK50M;			// clock, input, 50 MHz

  wire SRce0;
  wire SRce1;
  wire SRwe;
  wire SRoe;
  wire [3:0] SRbe;
  wire [17:0] SRadr;
  wire [31:0] SRdat;

  wire [3:0] btn;		// buttons, active high, btn[3] is reset
  wire [7:0] swi;		// switches
  wire [7:0] leds;		// LEDs

  //
  // simulation control
  //

  initial begin
    #0          $timeformat(-9, 1, " ns", 12);
                $dumpfile("dump.vcd");
                $dumpvars(0, risc5test);
                CLK50M = 1;
    #300000     $finish;
  end

  //
  // clock generator
  //

  always begin
    #10 CLK50M = ~CLK50M;	// 20 nsec cycle time
  end

  //
  // module instantiations
  //

  RISC5Top RISC5Top_0(
    .CLK50M(CLK50M),
    .SRce0(SRce0),
    .SRce1(SRce1),
    .SRwe(SRwe),
    .SRoe(SRoe),
    .SRbe(SRbe[3:0]),
    .SRadr(SRadr[17:0]),
    .SRdat(SRdat[31:0]),
    .btn(btn[3:0]),
    .swi(swi[7:0]),
    .leds(leds[7:0])
  );

  Memory Memory_0(
    .SRce0(SRce0),
    .SRce1(SRce1),
    .SRwe(SRwe),
    .SRoe(SRoe),
    .SRbe(SRbe[3:0]),
    .SRadr(SRadr[17:0]),
    .SRdat(SRdat[31:0])
  );

  BoardDev BoardDev_0(
    .btn(btn[3:0]),
    .swi(swi[7:0]),
    .leds(leds[7:0])
  );

  RS232Dev RS232Dev_0(
  );

  PS2Dev PS2Dev_0(
  );

  SPIDev SPIDev_0(
  );

endmodule
