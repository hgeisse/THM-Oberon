`timescale 1ns / 1ps // 32-bit PROM initialised from hex file  PDR 23.12.13
`default_nettype none  // HG 18.03.2018

module PROM (input clk, input en,
  input [8:0] adr,
  output reg [31:0] data);
  
reg [31:0] mem [0:511];

initial $readmemh("../prom.mem", mem);

always @(posedge clk) begin
  if (en) begin
    data <= mem[adr];
  end
end

endmodule
