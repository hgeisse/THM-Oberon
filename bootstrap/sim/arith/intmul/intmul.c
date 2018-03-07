/*
 * intmul.c -- check integer multiply
 */


#include <stdio.h>


typedef enum { false = 0, true = 1 } Bool;

typedef unsigned int Word;


Word intMul(Word op1, Word op2, Word *hiResPtr, Bool u) {
  Bool neg1, neg2;
  Word op1abs, op2abs;
  Word hiRes, loRes;
  int i;

  neg1 = (op1 >> 31) & 1;
  neg2 = (op2 >> 31) & 1;
  op1abs = (!u && neg1) ? -op1 : op1;
  op2abs = (!u && neg2) ? -op2 : op2;
  hiRes = 0;
  loRes = 0;
  for (i = 0; i < 32; i++) {
    if (loRes & 0x80000000) {
      hiRes <<= 1;
      hiRes++;
    } else {
      hiRes <<= 1;
    }
    loRes <<= 1;
    if (op2abs & 0x80000000) {
      loRes += op1abs;
      if (loRes < op1abs) {
        hiRes++;
      }
    }
    op2abs <<= 1;
  }
  if (!u && (neg1 != neg2)) {
    hiRes = ~hiRes;
    loRes = ~loRes;
    if (loRes == 0xFFFFFFFF) {
      loRes = 0;
      hiRes++;
    } else {
      loRes++;
    }
  }
  *hiResPtr = hiRes;
  return loRes;
}


void checkMul(void) {
  Word x, y, res, hi;
  Bool u;
  long resl, refl;
  unsigned long resu, refu;

  printf("\n");
  /* -------- */
  x = 1122334455;
  y = 2010403070;
  u = 0;
  res = intMul(x, y, &hi, u);
  resl = (long)((unsigned long) hi << 32 | (unsigned long) res);
  refl = (long) (int) x *
         (long) (int) y;
  printf("0x%08X * 0x%08X [u=%d] = 0x%08X 0x%08X\n",
         x, y, u, hi, res);
  printf("%11d * %11d = %22ld\n                  should be %22ld\n",
         (int) x, (int) y, resl, refl);
  printf("\n");
  /* -------- */
  x = -1122334455;
  y = 2010403070;
  u = 0;
  res = intMul(x, y, &hi, u);
  resl = (long)((unsigned long) hi << 32 | (unsigned long) res);
  refl = (long) (int) x *
         (long) (int) y;
  printf("0x%08X * 0x%08X [u=%d] = 0x%08X 0x%08X\n",
         x, y, u, hi, res);
  printf("%11d * %11d = %22ld\n                  should be %22ld\n",
         (int) x, (int) y, resl, refl);
  printf("\n");
  /* -------- */
  x = 1122334455;
  y = -2010403070;
  u = 0;
  res = intMul(x, y, &hi, u);
  resl = (long)((unsigned long) hi << 32 | (unsigned long) res);
  refl = (long) (int) x *
         (long) (int) y;
  printf("0x%08X * 0x%08X [u=%d] = 0x%08X 0x%08X\n",
         x, y, u, hi, res);
  printf("%11d * %11d = %22ld\n                  should be %22ld\n",
         (int) x, (int) y, resl, refl);
  printf("\n");
  /* -------- */
  x = -1122334455;
  y = -2010403070;
  u = 0;
  res = intMul(x, y, &hi, u);
  resl = (long)((unsigned long) hi << 32 | (unsigned long) res);
  refl = (long) (int) x *
         (long) (int) y;
  printf("0x%08X * 0x%08X [u=%d] = 0x%08X 0x%08X\n",
         x, y, u, hi, res);
  printf("%11d * %11d = %22ld\n                  should be %22ld\n",
         (int) x, (int) y, resl, refl);
  printf("\n");
  /* -------- */
  x = 1122334455;
  y = 2010403070;
  u = 1;
  res = intMul(x, y, &hi, u);
  resu = ((unsigned long) hi << 32 | (unsigned long) res);
  refu = (unsigned long) (unsigned int) x *
         (unsigned long) (unsigned int) y;
  printf("0x%08X * 0x%08X [u=%d] = 0x%08X 0x%08X\n",
         x, y, u, hi, res);
  printf("%11u * %11u = %22lu\n                  should be %22lu\n",
         (unsigned int) x, (unsigned int) y, resu, refu);
  printf("\n");
  /* -------- */
  x = -1122334455;
  y = 2010403070;
  u = 1;
  res = intMul(x, y, &hi, u);
  resu = ((unsigned long) hi << 32 | (unsigned long) res);
  refu = (unsigned long) (unsigned int) x *
         (unsigned long) (unsigned int) y;
  printf("0x%08X * 0x%08X [u=%d] = 0x%08X 0x%08X\n",
         x, y, u, hi, res);
  printf("%11u * %11u = %22lu\n                  should be %22lu\n",
         (unsigned int) x, (unsigned int) y, resu, refu);
  printf("\n");
  /* -------- */
  x = 1122334455;
  y = -2010403070;
  u = 1;
  res = intMul(x, y, &hi, u);
  resu = ((unsigned long) hi << 32 | (unsigned long) res);
  refu = (unsigned long) (unsigned int) x *
         (unsigned long) (unsigned int) y;
  printf("0x%08X * 0x%08X [u=%d] = 0x%08X 0x%08X\n",
         x, y, u, hi, res);
  printf("%11u * %11u = %22lu\n                  should be %22lu\n",
         (unsigned int) x, (unsigned int) y, resu, refu);
  printf("\n");
  /* -------- */
  x = -1122334455;
  y = -2010403070;
  u = 1;
  res = intMul(x, y, &hi, u);
  resu = ((unsigned long) hi << 32 | (unsigned long) res);
  refu = (unsigned long) (unsigned int) x *
         (unsigned long) (unsigned int) y;
  printf("0x%08X * 0x%08X [u=%d] = 0x%08X 0x%08X\n",
         x, y, u, hi, res);
  printf("%11u * %11u = %22lu\n                  should be %22lu\n",
         (unsigned int) x, (unsigned int) y, resu, refu);
  printf("\n");
  /* -------- */
}


int main(int argc, char *argv[]) {
  checkMul();
  return 0;
}
