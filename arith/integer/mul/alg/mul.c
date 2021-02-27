/*
 * mul.c -- basic multiplication algorithm
 */


#include <stdio.h>


void mul(unsigned char x, unsigned char y, unsigned short *pp) {
  unsigned short A;
  unsigned char B;
  unsigned short P;
  int i;

  /*
   * invariant:  A * B + P = const
   * start:      A = x, B = y, P = 0 => const = x * y
   * end:        B = 0 => P = x * y
   */
  A = (unsigned short) x;
  B = y;
  P = 0;
  for (i = 0; i < 8; i++) {
    if (B & 1) {
      B = B - 1;
      P = P + A;
    }
    A = A << 1;
    B = B >> 1;
  }
  *pp = P;
}


int main() {
  unsigned char x;
  unsigned char y;
  unsigned short res;
  unsigned short ref;

  x = 0;
  do {
    y = 0;
    do {
      mul(x, y, &res);
      ref = (unsigned short) x * (unsigned short) y;
      if (res != ref) {
        printf("error @ x = 0x%02X, y = 0x%02X, res = 0x%04X, ref = 0x%04X\n",
               (unsigned) x, (unsigned) y, (unsigned) res, (unsigned) ref);
      }
      y++;
    } while (y != 0);
    x++;
  } while (x != 0);
  return 0;
}
