//
// ram.v -- simulate external RAM
//          4M x 32 bit = 16 MB
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
  reg [31:0] mem[0:4194303];
  reg [3:0] latency_cnt;
  wire xfer_start;
  reg [3:0] address_cnt;
  wire xfer_stop;
  reg rd_ack;
  wire [2:0] ram_addr_lo;
  wire [21:0] ram_addr;

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
  assign ram_addr[21:0] = { addr_buf[21:3], ram_addr_lo[2:0] };

  always @(posedge clk) begin
    if (~xfer_stop) begin
      if (we_buf) begin
        mem[ram_addr] <= data_in;
      end else begin
        data_out <= mem[ram_addr];
      end
    end
  end

  initial begin
    mem[22'h351AFC] = 32'h1234FFFF;
    mem[22'h351AFD] = 32'h1234FFFF;
    mem[22'h351AFE] = 32'h1234FFFF;
    mem[22'h351AFF] = 32'h1234FFFF;

    mem[22'h351B00] = 32'h12340101;
    mem[22'h351B01] = 32'h12341101;
    mem[22'h351B02] = 32'h12342101;
    mem[22'h351B03] = 32'h12343101;
    mem[22'h351B04] = 32'h12344101;
    mem[22'h351B05] = 32'h12345101;
    mem[22'h351B06] = 32'h12346101;
    mem[22'h351B07] = 32'h12347101;
    mem[22'h351B08] = 32'h12348101;
    mem[22'h351B09] = 32'h12349101;
    mem[22'h351B0A] = 32'h1234A101;
    mem[22'h351B0B] = 32'h1234B101;
    mem[22'h351B0C] = 32'h1234C101;
    mem[22'h351B0D] = 32'h1234D101;
    mem[22'h351B0E] = 32'h1234E101;
    mem[22'h351B0F] = 32'h1234F101;

    mem[22'h351B10] = 32'h12340201;
    mem[22'h351B11] = 32'h12341201;
    mem[22'h351B12] = 32'h12342201;
    mem[22'h351B13] = 32'h12343201;
    mem[22'h351B14] = 32'h12344201;
    mem[22'h351B15] = 32'h12345201;
    mem[22'h351B16] = 32'h12346201;
    mem[22'h351B17] = 32'h12347201;
    mem[22'h351B18] = 32'h12348201;
    mem[22'h351B19] = 32'h12349201;
    mem[22'h351B1A] = 32'h1234A201;
    mem[22'h351B1B] = 32'h1234B201;
    mem[22'h351B1C] = 32'h1234C201;
    mem[22'h351B1D] = 32'h1234D201;
    mem[22'h351B1E] = 32'h1234E201;
    mem[22'h351B1F] = 32'h1234F201;

    mem[22'h351B20] = 32'h1234FFFF;
    mem[22'h351B21] = 32'h1234FFFF;
    mem[22'h351B22] = 32'h1234FFFF;
    mem[22'h351B23] = 32'h1234FFFF;
  end

endmodule
