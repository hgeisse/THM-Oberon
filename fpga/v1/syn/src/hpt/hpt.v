//
// hpt.v -- high precision timer
//


`timescale 1ns/1ps
`default_nettype none


module hpt(clk, rst,
           stb, we, addr,
           data_in, data_out,
           ack, irq);
    input clk;
    input rst;
    input stb;
    input we;
    input addr;
    input [31:0] data_in;
    output [31:0] data_out;
    output ack;
    output irq;

  reg [31:0] counter;
  reg [31:0] divisor;
  reg divisor_loaded;
  reg underflow;
  reg expired;
  reg ien;

  always @(posedge clk) begin
    if (divisor_loaded) begin
      counter[31:0] <= divisor[31:0];
      underflow <= 1'b0;
    end else begin
      if (counter[31:0] == 32'h00000001) begin
        counter[31:0] <= divisor[31:0];
        underflow <= 1'b1;
      end else begin
        counter[31:0] <= counter[31:0] - 32'h00000001;
        underflow <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      expired <= 1'b0;
    end else begin
      if (underflow) begin
        expired <= 1'b1;
      end else begin
        if (stb & ~we & addr) begin
          // read status
          expired <= 1'b0;
        end
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      divisor[31:0] <= 32'hFFFFFFFF;
      divisor_loaded <= 1'b1;
    end else begin
      if (stb & we & ~addr) begin
        // write divisor
        divisor[31:0] <= data_in[31:0];
        divisor_loaded <= 1'b1;
      end else begin
        divisor_loaded <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      ien <= 1'b0;
    end else begin
      if (stb & we & addr) begin
        // write control
        ien <= data_in[0];
      end
    end
  end

  assign data_out[31:0] = ~addr ? counter[31:0] : { 31'h0, expired };

  assign ack = stb;

  assign irq = expired & ien;

endmodule
