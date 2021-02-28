/*
 * muldiv.c -- integer multiply and divide, signed and unsigned
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "common.h"
#include "muldiv.h"


void intMul(Word op1, Word op2, Bool u, Word *loResPtr, Word *hiResPtr) {
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
  *loResPtr = loRes;
  *hiResPtr = hiRes;
}


void intDiv(Word op1, Word op2, Bool u, Word *quoPtr, Word *remPtr) {
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
  *quoPtr = quo;
  *remPtr = rem;
}
