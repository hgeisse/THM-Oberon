/*
 * div.c -- basic division algorithm
 */


#include <stdio.h>


void div(unsigned char x, unsigned char y,
         unsigned char *pq, unsigned char *pr) {
  unsigned short A;
  unsigned char Q;
  unsigned short R;
  int i;

  /*
   * invariant:  A * Q + R = const
   * start:      A = y * (2**N), Q = 0, R = x => const = x
   * end:        A = y => y * Q + R = x
   */
  A = ((unsigned short) y) << 8;
  Q = 0;
  R = (unsigned short) x;
  for (i = 0; i < 8; i++) {
    A = A >> 1;
    Q = Q << 1;
    if (R >= A) {
      R = R - A;
      Q = Q + 1;
    }
  }
  *pq = Q;
  *pr = (unsigned char) R;
}


int main() {
  unsigned char x;
  unsigned char y;
  unsigned char res_q;
  unsigned char res_r;
  unsigned char ref_q;
  unsigned char ref_r;

  x = 0;
  do {
    y = 1;
    do {
      div(x, y, &res_q, &res_r);
      ref_q = x / y;
      ref_r = x % y;
      if (res_q != ref_q || res_r != ref_r) {
        printf("error @ x = 0x%02X, y = 0x%02X, "
               "res = (0x%02X, 0x%02X), "
               "ref = (0x%02X, 0x%02X)\n",
               (unsigned) x, (unsigned) y,
               (unsigned) res_q, (unsigned) res_r,
               (unsigned) ref_q, (unsigned) ref_r);
      }
      y++;
    } while (y != 0);
    x++;
  } while (x != 0);
  return 0;
}
