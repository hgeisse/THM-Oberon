/*
 * intdiv.c -- check integer division
 */


#include <stdio.h>


typedef enum { false = 0, true = 1 } Bool;

typedef unsigned int Word;


Word intDiv(Word op1, Word op2, Word *remPtr, Bool u) {
  Bool neg1, neg2;
  Word op1abs, op2abs;
  Word quo, rem;
  int i;

  neg1 = (op1 >> 31) & 1;
  neg2 = (op2 >> 31) & 1;
  op1abs = (!u && neg1) ? -op1 : op1;
  op2abs = (!u && neg2) ? -op2 : op2;
  quo = 0;
  rem = 0;
  for (i = 0; i < 32; i++) {
    if (op1abs & 0x80000000) {
      rem <<= 1;
      rem++;
    } else {
      rem <<= 1;
    }
    op1abs <<= 1;
    quo <<= 1;
    if (rem >= op2abs) {
      rem -= op2abs;
      quo++;
    }
  }
  if (!u) {
    if (neg1 != neg2) {
      quo = -quo;
      if (rem != 0) {
        quo--;
        rem -= op2abs;
      }
    }
    if (neg1) {
      rem = -rem;
    }
  }
  *remPtr = rem;
  return quo;
}


void checkDiv(void) {
  Word x, y, res, hi;
  Bool u;
  int refq, refr;
  unsigned int refqu, refru;

  printf("\n");
  /* -------- */
  x = 14;
  y = 3;
  u = 0;
  res = intDiv(x, y, &hi, u);
  refq = (int) x / (int) y;
  refr = (int) x % (int) y;
  if (((int) x < 0) != ((int) y < 0) && refr != 0) {
    refq--;
    refr += (int) y;
  }
  printf("0x%08X / 0x%08X [u=%d] = 0x%08X rem 0x%08X\n",
         x, y, u, res, hi);
  printf("%11d / %11d = %11d rem %11d\n",
         (int) x, (int) y, (int) res, (int) hi);
  printf("                  should be %11d rem %11d\n",
         refq, refr);
  printf("\n");
  /* -------- */
  x = -14;
  y = 3;
  u = 0;
  res = intDiv(x, y, &hi, u);
  refq = (int) x / (int) y;
  refr = (int) x % (int) y;
  if (((int) x < 0) != ((int) y < 0) && refr != 0) {
    refq--;
    refr += (int) y;
  }
  printf("0x%08X / 0x%08X [u=%d] = 0x%08X rem 0x%08X\n",
         x, y, u, res, hi);
  printf("%11d / %11d = %11d rem %11d\n",
         (int) x, (int) y, (int) res, (int) hi);
  printf("                  should be %11d rem %11d\n",
         refq, refr);
  printf("\n");
  /* -------- */
  x = 14;
  y = -3;
  u = 0;
  res = intDiv(x, y, &hi, u);
  refq = (int) x / (int) y;
  refr = (int) x % (int) y;
  if (((int) x < 0) != ((int) y < 0) && refr != 0) {
    refq--;
    refr += (int) y;
  }
  printf("0x%08X / 0x%08X [u=%d] = 0x%08X rem 0x%08X\n",
         x, y, u, res, hi);
  printf("%11d / %11d = %11d rem %11d\n",
         (int) x, (int) y, (int) res, (int) hi);
  printf("                  should be %11d rem %11d\n",
         refq, refr);
  printf("\n");
  /* -------- */
  x = -14;
  y = -3;
  u = 0;
  res = intDiv(x, y, &hi, u);
  refq = (int) x / (int) y;
  refr = (int) x % (int) y;
  if (((int) x < 0) != ((int) y < 0) && refr != 0) {
    refq--;
    refr += (int) y;
  }
  printf("0x%08X / 0x%08X [u=%d] = 0x%08X rem 0x%08X\n",
         x, y, u, res, hi);
  printf("%11d / %11d = %11d rem %11d\n",
         (int) x, (int) y, (int) res, (int) hi);
  printf("                  should be %11d rem %11d\n",
         refq, refr);
  printf("\n");
  /* -------- */
  x = 12;
  y = 3;
  u = 0;
  res = intDiv(x, y, &hi, u);
  refq = (int) x / (int) y;
  refr = (int) x % (int) y;
  if (((int) x < 0) != ((int) y < 0) && refr != 0) {
    refq--;
    refr += (int) y;
  }
  printf("0x%08X / 0x%08X [u=%d] = 0x%08X rem 0x%08X\n",
         x, y, u, res, hi);
  printf("%11d / %11d = %11d rem %11d\n",
         (int) x, (int) y, (int) res, (int) hi);
  printf("                  should be %11d rem %11d\n",
         refq, refr);
  printf("\n");
  /* -------- */
  x = -12;
  y = 3;
  u = 0;
  res = intDiv(x, y, &hi, u);
  refq = (int) x / (int) y;
  refr = (int) x % (int) y;
  if (((int) x < 0) != ((int) y < 0) && refr != 0) {
    refq--;
    refr += (int) y;
  }
  printf("0x%08X / 0x%08X [u=%d] = 0x%08X rem 0x%08X\n",
         x, y, u, res, hi);
  printf("%11d / %11d = %11d rem %11d\n",
         (int) x, (int) y, (int) res, (int) hi);
  printf("                  should be %11d rem %11d\n",
         refq, refr);
  printf("\n");
  /* -------- */
  x = 12;
  y = -3;
  u = 0;
  res = intDiv(x, y, &hi, u);
  refq = (int) x / (int) y;
  refr = (int) x % (int) y;
  if (((int) x < 0) != ((int) y < 0) && refr != 0) {
    refq--;
    refr += (int) y;
  }
  printf("0x%08X / 0x%08X [u=%d] = 0x%08X rem 0x%08X\n",
         x, y, u, res, hi);
  printf("%11d / %11d = %11d rem %11d\n",
         (int) x, (int) y, (int) res, (int) hi);
  printf("                  should be %11d rem %11d\n",
         refq, refr);
  printf("\n");
  /* -------- */
  x = -12;
  y = -3;
  u = 0;
  res = intDiv(x, y, &hi, u);
  refq = (int) x / (int) y;
  refr = (int) x % (int) y;
  if (((int) x < 0) != ((int) y < 0) && refr != 0) {
    refq--;
    refr += (int) y;
  }
  printf("0x%08X / 0x%08X [u=%d] = 0x%08X rem 0x%08X\n",
         x, y, u, res, hi);
  printf("%11d / %11d = %11d rem %11d\n",
         (int) x, (int) y, (int) res, (int) hi);
  printf("                  should be %11d rem %11d\n",
         refq, refr);
  printf("\n");
  /* -------- */
  x = 14;
  y = 3;
  u = 1;
  res = intDiv(x, y, &hi, u);
  refqu = (unsigned) x / (unsigned) y;
  refru = (unsigned) x % (unsigned) y;
  printf("0x%08X / 0x%08X [u=%d] = 0x%08X rem 0x%08X\n",
         x, y, u, res, hi);
  printf("%11u / %11u = %11u rem %11u\n",
         (unsigned) x, (unsigned) y, (unsigned) res, (unsigned) hi);
  printf("                  should be %11u rem %11u\n",
         refqu, refru);
  printf("\n");
  /* -------- */
  x = -14;
  y = 3;
  u = 1;
  res = intDiv(x, y, &hi, u);
  refqu = (unsigned) x / (unsigned) y;
  refru = (unsigned) x % (unsigned) y;
  printf("0x%08X / 0x%08X [u=%d] = 0x%08X rem 0x%08X\n",
         x, y, u, res, hi);
  printf("%11u / %11u = %11u rem %11u\n",
         (unsigned) x, (unsigned) y, (unsigned) res, (unsigned) hi);
  printf("                  should be %11u rem %11u\n",
         refqu, refru);
  printf("\n");
  /* -------- */
  x = 14;
  y = -3;
  u = 1;
  res = intDiv(x, y, &hi, u);
  refqu = (unsigned) x / (unsigned) y;
  refru = (unsigned) x % (unsigned) y;
  printf("0x%08X / 0x%08X [u=%d] = 0x%08X rem 0x%08X\n",
         x, y, u, res, hi);
  printf("%11u / %11u = %11u rem %11u\n",
         (unsigned) x, (unsigned) y, (unsigned) res, (unsigned) hi);
  printf("                  should be %11u rem %11u\n",
         refqu, refru);
  printf("\n");
  /* -------- */
  x = -14;
  y = -3;
  u = 1;
  res = intDiv(x, y, &hi, u);
  refqu = (unsigned) x / (unsigned) y;
  refru = (unsigned) x % (unsigned) y;
  printf("0x%08X / 0x%08X [u=%d] = 0x%08X rem 0x%08X\n",
         x, y, u, res, hi);
  printf("%11u / %11u = %11u rem %11u\n",
         (unsigned) x, (unsigned) y, (unsigned) res, (unsigned) hi);
  printf("                  should be %11u rem %11u\n",
         refqu, refru);
  printf("\n");
  /* -------- */
}


int main(int argc, char *argv[]) {
  checkDiv();
  return 0;
}
