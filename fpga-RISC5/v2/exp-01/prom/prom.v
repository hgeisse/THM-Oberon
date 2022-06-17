//
// prom.v -- PROM realized by block RAM
//           512 x 32 bit = 2 KB
//


`timescale 1ns/1ps
`default_nettype none


module prom(clk, rst,
            stb, addr,
            data_out, ack);
    input clk;
    input rst;
    input stb;
    input [8:0] addr;
    output reg [31:0] data_out;
    output reg ack;

  reg [8:0] addr_buf;
  reg [31:0] mem[0:511];
  wire xfer_start;
  reg [3:0] address_cnt;
  wire xfer_stop;
  wire [2:0] prom_addr_lo;
  wire [8:0] prom_addr;

  assign xfer_start = stb & xfer_stop;

  always @(posedge clk) begin
    if (rst) begin
      address_cnt[3:0] <= 4'h8;
    end else begin
      if (xfer_start) begin
        addr_buf[8:0] <= addr[8:0];
        address_cnt[3:0] <= 4'h0;
      end else begin
        if (~xfer_stop) begin
          address_cnt[3:0] <= address_cnt[3:0] + 4'h1;
        end
      end
    end
  end

  assign xfer_stop = address_cnt[3];

  always @(posedge clk) begin
    if (rst) begin
      ack <= 1'b0;
    end else begin
      ack <= ~xfer_stop;
    end
  end

  assign prom_addr_lo[2:0] = addr_buf[2:0] + address_cnt[2:0];
  assign prom_addr[8:0] = { addr_buf[8:3], prom_addr_lo[2:0] };

  always @(posedge clk) begin
    if (~xfer_stop) begin
      data_out <= mem[prom_addr];
    end
  end

  initial begin
    mem[9'h1A0] = 32'hDEADBEEF;
    mem[9'h1A1] = 32'hDEADBEEF;
    mem[9'h1A2] = 32'hDEADBEEF;
    mem[9'h1A3] = 32'hDEADBEEF;
    mem[9'h1A4] = 32'hDEADBEEF;
    mem[9'h1A5] = 32'hDEADBEEF;
    mem[9'h1A6] = 32'hDEADBEEF;
    mem[9'h1A7] = 32'hDEADBEEF;
    mem[9'h1A8] = 32'h11111111;
    mem[9'h1A9] = 32'h22222222;
    mem[9'h1AA] = 32'h33333333;
    mem[9'h1AB] = 32'h44444444;
    mem[9'h1AC] = 32'h55555555;
    mem[9'h1AD] = 32'h66666666;
    mem[9'h1AE] = 32'h77777777;
    mem[9'h1AF] = 32'h88888888;
    mem[9'h1B0] = 32'hDEADBEEF;
    mem[9'h1B1] = 32'hDEADBEEF;
    mem[9'h1B2] = 32'hDEADBEEF;
    mem[9'h1B3] = 32'hDEADBEEF;
    mem[9'h1B4] = 32'hDEADBEEF;
    mem[9'h1B5] = 32'hDEADBEEF;
    mem[9'h1B6] = 32'hDEADBEEF;
    mem[9'h1B7] = 32'hDEADBEEF;
  end

endmodule
