//
// risc5test.v -- RISC5 testbench
//


`timescale 1ns / 1ps
`default_nettype none


module risc5test;

  reg CLK50M;			// clock, input, 50 MHz

  wire SRce0;			// SRAM, chip enable 0
  wire SRce1;			// SRAM, chip enable 1
  wire SRwe;			// SRAM, write enable
  wire SRoe;			// SRAM, output enable
  wire [3:0] SRbe;		// SRAM, byte enable
  wire [17:0] SRadr;		// SRAM address
  wire [31:0] SRdat;		// SRAM data

  wire [3:0] btn;		// buttons, active high, btn[3] is reset
  wire [7:0] swi;		// switches
  wire [7:0] leds;		// LEDs

  wire RxD;			// serial line, receive data
  wire TxD;			// serial line, transmit data

  wire [1:0] MISO;
  wire [1:0] MOSI;
  wire [1:0] SCLK;
  wire [1:0] SS;
  wire NEN;

  wire hsync;			// video, hsync
  wire vsync;			// video vsync
  wire [2:0] RGB;		// video R, G, B

  wire PS2C;			// keyboard clock
  wire PS2D;			// keyboard data
  wire msclk;			// mouse clock
  wire msdat;			// mouse data

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
    .leds(leds[7:0]),
    .RxD(RxD),
    .TxD(TxD),
    .MISO(MISO[1:0]),
    .MOSI(MOSI[1:0]),
    .SCLK(SCLK[1:0]),
    .SS(SS[1:0]),
    .NEN(NEN),
    .hsync(hsync),
    .vsync(vsync),
    .RGB(RGB[2:0]),
    .PS2C(PS2C),
    .PS2D(PS2D),
    .msclk(msclk),
    .msdat(msdat)
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
    .RxD(RxD),
    .TxD(TxD)
  );

  SPIDev SPIDev_0(
    .MISO(MISO[1:0]),
    .MOSI(MOSI[1:0]),
    .SCLK(SCLK[1:0]),
    .SS(SS[1:0]),
    .NEN(NEN)
  );

  VIDDev VIDDev_0(
    .hsync(hsync),
    .vsync(vsync),
    .RGB(RGB[2:0])
  );

  PS2Dev PS2Dev_0(
    .PS2C(PS2C),
    .PS2D(PS2D),
    .msclk(msclk),
    .msdat(msdat)
  );

endmodule
