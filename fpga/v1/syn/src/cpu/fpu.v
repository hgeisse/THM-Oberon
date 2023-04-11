//
// fpu.v -- floating-point unit
//


`timescale 1ns / 1ps
`default_nettype none


module fpadd_orig(
  input clk, run,
  output stall,
  input u, v,
  input [31:0] x, y,
  output [31:0] z);

  reg [1:0] State;

  wire xs, ys, xn, yn;  // signs, null
  wire [7:0] xe, ye;
  wire [24:0] xm, ym;

  wire [8:0] dx, dy, e0, e1;
  wire [7:0] sx, sy;  // shift counts
  wire [1:0] sx0, sx1, sy0, sy1;
  wire sxh, syh;
  wire [24:0] x0, x1, x2, y0, y1, y2;
  reg [24:0] x3, y3;

  reg [26:0] Sum;
  wire [26:0] s;

  wire z24, z22, z20, z18, z16, z14, z12, z10, z8, z6, z4, z2;
  wire [4:0] sc;  // shift count
  wire [1:0] sc0, sc1;
  wire [24:0] t1, t2;
  reg [24:0] t3;

  assign xs = x[31];  // sign x
  assign xe = u ? 8'h96 : x[30:23];  // expo x
  assign xm = {~u|x[23], x[22:0], 1'b0};  //mant x
  assign xn = (x[30:0] == 0);
  assign ys = y[31];  // sign y
  assign ye = y[30:23];  // expo y
  assign ym = {~u&~v, y[22:0], 1'b0};  //mant y
  assign yn = (y[30:0] == 0);

  assign dx = xe - ye;
  assign dy = ye - xe;
  assign e0 = (dx[8]) ? ye : xe;
  assign sx = dy[8] ? 8'd0 : dy[7:0];
  assign sy = dx[8] ? 8'd0 : dx[7:0];
  assign sx0 = sx[1:0];
  assign sx1 = sx[3:2];
  assign sy0 = sy[1:0];
  assign sy1 = sy[3:2];
  assign sxh = sx[7] | sx[6] | sx[5];
  assign syh = sy[7] | sy[6] | sy[5];

  // denormalize, shift right
  assign x0 = xs&~u ? -xm : xm;
  assign x1 = (sx0 == 3) ? {{3{xs}}, x0[24:3]} :
    (sx0 == 2) ? {{2{xs}}, x0[24:2]} : (sx0 == 1) ? {xs, x0[24:1]} : x0;
  assign x2 = (sx1 == 3) ? {{12{xs}}, x1[24:12]} :
    (sx1 == 2) ? {{8{xs}}, x1[24:8]} : (sx1 == 1) ? {{4{xs}}, x1[24:4]} : x1;
  always @ (posedge(clk))
  x3 <= sxh ? {25{xs}} : (sx[4] ? {{16{xs}}, x2[24:16]} : x2);

  assign y0 = ys&~u ? -ym : ym;
  assign y1 = (sy0 == 3) ? {{3{ys}}, y0[24:3]} :
    (sy0 == 2) ? {{2{ys}}, y0[24:2]} : (sy0 == 1) ? {ys, y0[24:1]} : y0;
  assign y2 = (sy1 == 3) ? {{12{ys}}, y1[24:12]} :
    (sy1 == 2) ? {{8{ys}}, y1[24:8]} : (sy1 == 1) ? {{4{ys}}, y1[24:4]} : y1;
  always @ (posedge(clk))
	y3 <= syh ? {25{ys}} : (sy[4] ? {{16{ys}}, y2[24:16]} : y2);

  // add
  always @ (posedge(clk)) Sum <= {xs, xs, x3} + {ys, ys, y3};
  assign s = (Sum[26] ? -Sum : Sum) + 27'd1;

  // post-normalize
  assign z24 = ~s[25] & ~ s[24];
  assign z22 = z24 & ~s[23] & ~s[22];
  assign z20 = z22 & ~s[21] & ~s[20];
  assign z18 = z20 & ~s[19] & ~s[18];
  assign z16 = z18 & ~s[17] & ~s[16];
  assign z14 = z16 & ~s[15] & ~s[14];
  assign z12 = z14 & ~s[13] & ~s[12];
  assign z10 = z12 & ~s[11] & ~s[10];
  assign z8 = z10 & ~s[9] & ~s[8];
  assign z6 = z8 & ~s[7] & ~s[6];
  assign z4 = z6 & ~s[5] & ~s[4];
  assign z2 = z4 & ~s[3] & ~s[2];

  assign sc[4] = z10;  // sc = shift count of post normalization
  assign sc[3] = z18 & (s[17] | s[16] | s[15] | s[14] | s[13] | s[12] | s[11] | s[10])
      | z2;
  assign sc[2] = z22 & (s[21] | s[20] | s[19] | s[18])
      | z14 & (s[13] | s[12] | s[11] | s[10])
      | z6 & (s[5] | s[4] | s[3] | s[2]);
  assign sc[1] = z24 & (s[23] | s[22])
      | z20 & (s[19] | s[18])
      | z16 & (s[15] | s[14])
      | z12 & (s[11] | s[10])
      | z8 & (s[7] | s[6])
      | z4 & (s[3] | s[2]);
  assign sc[0] = ~s[25] & s[24]
      | z24 & ~s[23] & s[22]
      | z22 & ~s[21] & s[20]
      | z20 & ~s[19] & s[18]
      | z18 & ~s[17] & s[16]
      | z16 & ~s[15] & s[14]
      | z14 & ~s[13] & s[12]
      | z12 & ~s[11] & s[10]
      | z10 & ~s[9] & s[8]
      | z8 & ~s[7] & s[6]
      | z6 & ~s[5] & s[4]
      | z4 & ~s[3] & s[2];

  assign e1 = e0 - sc + 9'd1;
  assign sc0 = sc[1:0];
  assign sc1 = sc[3:2];

  assign t1 = (sc0 == 3) ? {s[22:1], 3'b0} :
    (sc0 == 2) ? {s[23:1], 2'b0} : (sc0 == 1) ? {s[24:1], 1'b0} : s[25:1];
  assign t2 = (sc1 == 3) ? {t1[12:0], 12'b0} :
    (sc1 == 2) ? {t1[16:0], 8'b0} : (sc1 == 1) ? {t1[20:0], 4'b0} : t1;
  always @ (posedge(clk)) t3 <= sc[4] ? {t2[8:0], 16'b0} : t2;

  assign stall = run & ~(State == 3);
  always @ (posedge(clk)) State <= run ? State + 2'd1 : 2'd0;

  assign z = v ? {{7{Sum[26]}}, Sum[25:1]} :  // FLOOR
    xn ? (u|yn ? 0 : y) :   // FLT or x = y = 0
    yn ? x :
    ((t3 == 0) | e1[8]) ? 0 : 
	 {Sum[26], e1[7:0], t3[23:1]};
endmodule


module fpadd(clk, run, stall,
             op, x, y, z);
    input clk;
    input run;
    output stall;
    input [1:0] op;
    input [31:0] x;
    input [31:0] y;
    output [31:0] z;

  reg u_aux;
  reg v_aux;
  reg [31:0] y_aux;

  always @(*) begin
    case (op)
      2'b00:  // z = FAD(x, y)
        begin
          u_aux = 1'b0;
          v_aux = 1'b0;
          y_aux = y[31:0];
        end
      2'b01:  // z = FLR(x)
        begin
          u_aux = 1'b0;
          v_aux = 1'b1;
          y_aux = 32'h4B000000;
        end
      2'b10:  // z = FLT(x)
        begin
          u_aux = 1'b1;
          v_aux = 1'b0;
          y_aux = 32'h4B000000;
        end
      2'b11:  // z = FSB(x, y)
        begin
          u_aux = 1'b0;
          v_aux = 1'b0;
          y_aux = { ~y[31], y[30:0] };
        end
    endcase
  end

  fpadd_orig fpadd_orig_0(
    .clk(clk),
    .run(run),
    .stall(stall),
    .u(u_aux),
    .v(v_aux),
    .x(x[31:0]),
    .y(y_aux[31:0]),
    .z(z[31:0])
  );

endmodule


module fpmul(clk, run, stall,
             x, y, z);
    input clk;
    input run;
    output stall;
    input [31:0] x;
    input [31:0] y;
    output [31:0] z;

  reg [4:0] S;  // state
  reg [47:0] P; // product

  wire sign;
  wire [7:0] xe, ye;
  wire [8:0] e0, e1;
  wire [24:0] w1, z0;
  wire [23:0] w0;

  assign sign = x[31] ^ y[31];
  assign xe = x[30:23];
  assign ye = y[30:23];
  assign e0 = xe + ye;
  assign e1 = e0 - 9'd127 + P[47];

  assign stall = run & ~(S == 25);
  assign w0 = P[0] ? { 1'b1, y[22:0] } : 24'd0;
  assign w1 = { 1'b0, P[47:24] } + { 1'b0, w0 };
  assign z0 = P[47] ? P[47:23] + 25'd1 : P[46:22] + 25'd1;  // round+normalize
  assign z =
    (xe == 0) | (ye == 0) ? 0 :
    (~e1[8]) ? { sign, e1[7:0], z0[23:1] } :
    (~e1[7]) ? { sign, 8'b11111111, z0[23:1] } :
    0;

  always @ (posedge(clk)) begin
    P <= (S == 0) ? { 24'b0, 1'b1, x[22:0] } : { w1, P[23:1] };
    S <= run ? S + 5'd1 : 5'd0;
  end

endmodule


module fpdiv(clk, run, stall,
             x, y, z);
    input clk;
    input run;
    output stall;
    input [31:0] x;
    input [31:0] y;
    output [31:0] z;

  reg [4:0] S;  // state
  reg [23:0] R;
  reg [25:0] Q;

  wire sign;
  wire [7:0] xe, ye;
  wire [8:0] e0, e1;
  wire [24:0] r0, r1, d;
  wire [25:0] q0;
  wire [24:0] z0, z1;

  assign sign = x[31] ^ y[31];
  assign xe = x[30:23];
  assign ye = y[30:23];
  assign e0 = { 1'b0, xe } - { 1'b0, ye };
  assign e1 = e0 + 9'd126 + Q[25];
  assign stall = run & ~(S == 26);

  assign r0 = (S == 0) ? { 2'b01, x[22:0] } : { R, 1'b0 };
  assign r1 = d[24] ? r0 : d;
  assign d = r0 - { 2'b01, y[22:0] };
  assign q0 = (S == 0) ? 26'd0 : Q;

  assign z0 = Q[25] ? Q[25:1] : Q[24:0];
  assign z1 = z0 + 25'd1;
  assign z =
    (xe == 0) ? 0 :
    (ye == 0) ? { sign, 8'b11111111, 23'b0 } :  // div by 0
    (~e1[8]) ? { sign, e1[7:0], z1[23:1] } :
    (~e1[7]) ? { sign, 8'b11111111, z0[23:1] } :  // NaN
    0;

  always @ (posedge(clk)) begin
    R <= r1[23:0];
    Q <= { q0[24:0], ~d[24] };
    S <= run ? S + 5'd1 : 5'd0;
  end

endmodule
