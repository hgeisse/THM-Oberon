/*
 * mul.c -- multiply test
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


typedef enum { false = 0, true = 1 } Bool;

typedef signed int S32;
typedef unsigned int U32;
typedef signed long S64;
typedef unsigned long U64;

typedef struct {
  U32 hi;
  U32 lo;
} Pair;


/**************************************************************/


U32 addu(U32 x, U32 y, Bool *carry) {
  U32 res;

  res = x + y;
  *carry = (res < x);
  return res;
}


Pair mul_sim(U32 x, U32 y, Bool ops_unsigned) {
  Bool x_neg;
  Bool y_neg;
  U32 y_abs;
  U32 upper;
  U32 lower;
  int i;
  Bool carry;
  Pair res;

  x_neg = !ops_unsigned && ((x & 0x80000000) != 0);
  if (x_neg) {
    upper = 0;
    lower = ~x + 1;
  } else {
    upper = 0;
    lower = x;
  }
  y_neg = !ops_unsigned && ((y & 0x80000000) != 0);
  if (y_neg) {
    y_abs = ~y + 1;
  } else {
    y_abs = y;
  }
  for (i = 0; i < 32; i++) {
    upper = addu(upper, (lower & 1) ? y_abs : 0, &carry);
    lower >>= 1;
    if (upper & 1) {
      lower |= 0x80000000;
    }
    upper >>= 1;
    if (carry) {
      upper |= 0x80000000;
    }
  }
  if (x_neg != y_neg) {
    res.hi = ~upper;
    res.lo = ~lower;
    res.lo++;
    if (res.lo == 0) {
      res.hi++;
    }
  } else {
    res.hi = upper;
    res.lo = lower;
  }
  return res;
}


/**************************************************************/


Pair mul_ref(U32 x, U32 y, Bool ops_unsigned) {
  U64 aux1;
  S64 aux2;
  Pair res;

  if (ops_unsigned) {
    aux1 = (U64) x * (U64) y;
    res.hi = (aux1 >> 32) & 0x00000000FFFFFFFFUL;
    res.lo = aux1 & 0x00000000FFFFFFFFUL;
  } else {
    aux2 = (S64) (S32) x * (S64) (S32) y;
    res.hi = (aux2 >> 32) & 0x00000000FFFFFFFFUL;
    res.lo = aux2 & 0x00000000FFFFFFFFUL;
  }
  return res;
}


/**************************************************************/


U32 vals[] = {
  0x00000000,
  0x00000001,
  0x00000002,
  0x3FFFFFFE,
  0x3FFFFFFF,
  0x40000000,
  0x40000001,
  0x40000002,
  0x7FFFFFFE,
  0x7FFFFFFF,
  0x80000000,
  0x80000001,
  0x80000002,
  0xBFFFFFFE,
  0xBFFFFFFF,
  0xC0000000,
  0xC0000001,
  0xC0000002,
  0xFFFFFFFE,
  0xFFFFFFFF,
  0x12345678,
  0x87654321,
  0x00001234,
  0x12340000,
  0x0000FEDC,
  0xFEDC0000,
  0x3AE82DD4,
  0x44FCB67D,
  0x1AA09232,
  0x0412CF03,
  0x8F0B45C0,
  0xF5A5F2F9,
  0xE7B79BFE,
  0x3AECCFDF,
  0xFB23146C,
  0xA883CF35,
  0x8F953A8A,
  0xC053767B,
  0x42DE85D8,
  0xEB5DC731,
  0x37B239D6,
  0xB1CA9ED7,
  0x0E134604,
  0x374B16ED,
  0x090C25E2,
  0x0FABE4F3,
  0xEEA9C0F0,
  0x032EBA69,
  0xD7F14AAE,
  0x8402A4CF,
};

#define N	(sizeof(vals)/sizeof(vals[0]))


void check_mul(Bool ops_unsigned, Bool wr_file) {
  char outName[20];
  FILE *outFile;
  int i, j;
  U32 x, y;
  Pair res, ref;

  if (wr_file) {
    sprintf(outName, "mul_%c.dat", ops_unsigned ? 'u' : 's');
    outFile = fopen(outName, "w");
    if (outFile == NULL) {
      printf("error: cannot open output file '%s'\n", outName);
      exit(1);
    }
  }
  for (i = 0; i < N; i++) {
    for (j = 0; j < N; j++) {
      x = vals[i];
      y = vals[j];
      res = mul_sim(x, y, ops_unsigned);
      ref = mul_ref(x, y, ops_unsigned);
      if (res.hi != ref.hi || res.lo != ref.lo) {
        printf("mul_%c(0x%08X, 0x%08X) = (0x%08X, 0x%08X)\n"
               "\t\t\t  ref = (0x%08X, 0x%08X)\n",
               ops_unsigned? 'u' : 's', x, y,
               res.hi, res.lo, ref.hi, ref.lo);
      }
      if (wr_file) {
        fprintf(outFile, "%08X_%08X_%c_%08X_%08X\n",
                x, y, ops_unsigned ? '1' : '0', ref.hi, ref.lo);
      }
    }
  }
  if (wr_file) {
    fclose(outFile);
  }
}


/**************************************************************/


void usage(char *myself) {
  printf("usage: %s [-w]\n", myself);
  exit(1);
}


int main(int argc, char *argv[]) {
  Bool wr_file;

  if (argc == 1) {
    wr_file = false;
  } else
  if (argc == 2 && strcmp(argv[1], "-w") == 0) {
    wr_file = true;
  } else {
    usage(argv[0]);
  }
  check_mul(true, wr_file);
  check_mul(false, wr_file);
  return 0;
}
