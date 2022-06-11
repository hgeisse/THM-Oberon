//
// ram.v -- simulate external RAM
//          4M x 32 bit = 16 MB
//


//
// NOTE: This RAM is specifically modified: it cannot store anything.
//       It computes the data output from the address input.
//


`timescale 1ns/1ps
`default_nettype none


`define RD_LATENCY	4'd5	// # cycles read latency, min = 3
`define WR_LATENCY	4'd5	// # cycles write latency, min = 3


module ram(clk, rst,
           stb, we, addr,
           data_in, data_out, ack);
    input clk;
    input rst;
    input stb;
    input we;
    input [21:0] addr;
    input [31:0] data_in;
    output reg [31:0] data_out;
    output ack;

  reg we_buf;
  reg [21:0] addr_buf;
  reg [3:0] latency_cnt;
  wire xfer_start;
  reg [3:0] address_cnt;
  wire xfer_stop;
  reg rd_ack;
  wire [2:0] ram_addr_lo;
  wire [23:0] ram_addr;
  wire [31:0] ram_data;

  always @(posedge clk) begin
    if (rst) begin
      latency_cnt[3:0] <= 4'h0;
    end else begin
      if (latency_cnt[3:0] == 4'h0) begin
        if (xfer_stop & stb) begin
          // handle request
          if (we) begin
            latency_cnt[3:0] <= `WR_LATENCY - 2;
            we_buf <= 1'b1;
          end else begin
            latency_cnt[3:0] <= `RD_LATENCY - 2;
            we_buf <= 1'b0;
          end
          addr_buf[21:0] <= addr[21:0];
        end
      end else begin
        latency_cnt[3:0] <= latency_cnt[3:0] - 4'h1;
      end
    end
  end

  assign xfer_start = (latency_cnt[3:0] == 4'h1);

  always @(posedge clk) begin
    if (rst) begin
      address_cnt[3:0] <= 4'h8;
    end else begin
      if (xfer_start) begin
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
      rd_ack <= 1'b0;
    end else begin
      rd_ack <= ~xfer_stop;
    end
  end

  assign ack = we_buf ? ~xfer_stop : rd_ack;

  assign ram_addr_lo[2:0] = addr_buf[2:0] + address_cnt[2:0];
  assign ram_addr[23:0] = { addr_buf[21:3], ram_addr_lo[2:0], 2'b00 };

  assign ram_data[31:0] =
    { ~ram_addr[18:14], ram_addr[5:2], ~ram_addr[9:7], ram_addr[13:10],
      ram_addr[8:6], ~ram_addr[13:10], ram_addr[23:19], ~ram_addr[5:2] };

  always @(posedge clk) begin
    if (~xfer_stop) begin
      if (~we_buf) begin
        data_out <= ram_data;
      end
    end
  end

endmodule
