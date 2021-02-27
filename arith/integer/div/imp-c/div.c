/*
 * mul.c -- divide/modulo test
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


typedef enum { false = 0, true = 1 } Bool;

typedef signed int S32;
typedef unsigned int U32;

typedef struct {
  U32 quo;
  U32 rem;
} Pair;


/**************************************************************/


U32 subu(U32 x, U32 y, Bool *borrow) {
  U32 res;

  res = x - y;
  *borrow = (res > x);
  return res;
}


Pair div_sim(U32 x, U32 y, Bool ops_unsigned) {
  Bool x_neg;
  Bool y_neg;
  U32 y_abs;
  U32 upper;
  U32 lower;
  int i;
  U32 aux1;
  U32 aux2;
  Bool borrow;
  Bool corr;
  U32 quot;
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
    aux1 = (upper << 1) | (lower >> 31);
    aux2 = subu(aux1, y_abs, &borrow);
    if (borrow) {
      upper = aux1;
      lower <<= 1;
    } else {
      upper = aux2;
      lower <<= 1;
      lower |= 1;
    }
  }
  corr = x_neg && (upper != 0);
  quot = corr ? lower + 1 : lower;
  res.quo = (x_neg == y_neg) ? quot : -quot;
  res.rem = corr ? y_abs - upper : upper;
  return res;
}


/**************************************************************/


Bool abs_lt_u(U32 a, U32 b) {
  return a < b;
}


Bool abs_lt_s(U32 a, U32 b) {
  if ((S32) a < 0) {
    a = -a;
  }
  if ((S32) b < 0) {
    b = -b;
  }
  return a < b;
}


Pair div_ref(U32 x, U32 y, Bool ops_unsigned) {
  Pair res;

  if (ops_unsigned) {
    /* unsigned division */
    res.quo = x / y;
    res.rem = x % y;
    /* internal checks */
    if (!abs_lt_u(res.rem, y)) {
      printf("ERROR: internal check 1 failed!\n");
      printf("x = 0x%08X, y = 0x%08X, quo = 0x%08X, rem = 0x%08X\n",
             x, y, res.quo, res.rem);
      exit(1);
    }
    if (x != res.quo * y + res.rem) {
      printf("ERROR: internal check 2 failed!\n");
      printf("x = 0x%08X, y = 0x%08X, quo = 0x%08X, rem = 0x%08X\n",
             x, y, res.quo, res.rem);
      exit(1);
    }
  } else {
    /* signed division */
    res.quo = (signed) x / (signed) y;
    res.rem = (signed) x % (signed) y;
    if ((signed) res.rem < 0) {
      if ((signed) y < 0) {
        res.quo++;
        res.rem -= y;
      } else {
        res.quo--;
        res.rem += y;
      }
    }
    /* internal checks */
    if (!abs_lt_s(res.rem, y) || (S32) res.rem < 0) {
      printf("ERROR: internal check 3 failed!\n");
      printf("x = 0x%08X, y = 0x%08X, quo = 0x%08X, rem = 0x%08X\n",
             x, y, res.quo, res.rem);
      exit(1);
    }
    if ((S32) x != (S32) res.quo * (S32) y + (S32) res.rem) {
      printf("ERROR: internal check 4 failed!\n");
      printf("x = 0x%08X, y = 0x%08X, quo = 0x%08X, rem = 0x%08X\n",
             x, y, res.quo, res.rem);
      exit(1);
    }
  }
  return res;
}


/**************************************************************/


U32 vals[] = {
  0x00000003,
  0x0000000C,
  0x0000000E,
  0xFFFFFFF2,
  0xFFFFFFF4,
  0xFFFFFFFD,
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
};

#define N	(sizeof(vals)/sizeof(vals[0]))


void check_div(Bool ops_unsigned, Bool wr_file) {
  char outName[20];
  FILE *outFile;
  int i, j;
  U32 x, y;
  Pair res, ref;

  if (wr_file) {
    sprintf(outName, "div_%c.dat", ops_unsigned ? 'u' : 's');
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
      if (y == 0x00000000) continue;
      if (!ops_unsigned && x == 0x80000000 && y == 0xFFFFFFFF) continue;
      res = div_sim(x, y, ops_unsigned);
      ref = div_ref(x, y, ops_unsigned);
      if (res.quo != ref.quo || res.rem != ref.rem) {
        printf("div_%c(0x%08X, 0x%08X) = (0x%08X, 0x%08X)\n"
               "\t\t\t  ref = (0x%08X, 0x%08X)\n",
               ops_unsigned? 'u' : 's', x, y,
               res.quo, res.rem, ref.quo, ref.rem);
      }
      if (wr_file) {
        fprintf(outFile, "%08X_%08X_%c_%08X_%08X\n",
                x, y, ops_unsigned ? '1' : '0', ref.quo, ref.rem);
      }
    }
  }
  if (wr_file) {
    /* fill output file to 2500 lines before closing,
       so that the Verilog simulation doesn't complain */
    if (!ops_unsigned) {
      x = 0xDEADBEEF;
      y = 0x12345678;
      res = div_sim(x, y, ops_unsigned);
      ref = div_ref(x, y, ops_unsigned);
      fprintf(outFile, "%08X_%08X_%c_%08X_%08X\n",
              x, y, ops_unsigned ? '1' : '0', ref.quo, ref.rem);
    }
    for (i = 0; i < 50; i++) {
      x = i + 333;
      y = i + 777;
      res = div_sim(x, y, ops_unsigned);
      ref = div_ref(x, y, ops_unsigned);
      fprintf(outFile, "%08X_%08X_%c_%08X_%08X\n",
              x, y, ops_unsigned ? '1' : '0', ref.quo, ref.rem);
    }
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
  check_div(true, wr_file);
  check_div(false, wr_file);
  return 0;
}
