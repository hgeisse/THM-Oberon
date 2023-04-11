//
// RS232Dev.v -- Serial line
//


`timescale 1ns / 1ps
`default_nettype none


module RS232Dev(RxD, TxD);
    output reg RxD;
    input TxD;

  initial begin
    #0          RxD = 1'b1;
  end

endmodule
