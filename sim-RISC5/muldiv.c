/*
 * muldiv.c -- integer multiply and divide, signed and unsigned
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "common.h"
#include "muldiv.h"


/**************************************************************/


static Word addWord(Word x, Word y, Bool *carry) {
  Word res;

  res = x + y;
  *carry = (res < x);
  return res;
}


void intMul(Word x, Word y, Bool u, Word *loResPtr, Word *hiResPtr) {
  Bool x_neg;
  Bool y_neg;
  Word y_abs;
  Word upper;
  Word lower;
  int i;
  Bool carry;

  x_neg = !u && ((x & 0x80000000) != 0);
  if (x_neg) {
    upper = 0;
    lower = ~x + 1;
  } else {
    upper = 0;
    lower = x;
  }
  y_neg = !u && ((y & 0x80000000) != 0);
  if (y_neg) {
    y_abs = ~y + 1;
  } else {
    y_abs = y;
  }
  for (i = 0; i < 32; i++) {
    upper = addWord(upper, (lower & 1) ? y_abs : 0, &carry);
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
    upper = ~upper;
    lower = ~lower;
    lower++;
    if (lower == 0) {
      upper++;
    }
  }
  *loResPtr = lower;
  *hiResPtr = upper;
}


/**************************************************************/


static Word subWord(Word x, Word y, Bool *borrow) {
  Word res;

  res = x - y;
  *borrow = (res > x);
  return res;
}


void intDiv(Word x, Word y, Bool u, Word *quoPtr, Word *remPtr) {
  Bool x_neg;
  Bool y_neg;
  Word y_abs;
  Word upper;
  Word lower;
  int i;
  Word aux1;
  Word aux2;
  Bool borrow;
  Bool corr;
  Word quot;

  x_neg = !u && ((x & 0x80000000) != 0);
  if (x_neg) {
    upper = 0;
    lower = ~x + 1;
  } else {
    upper = 0;
    lower = x;
  }
  y_neg = !u && ((y & 0x80000000) != 0);
  if (y_neg) {
    y_abs = ~y + 1;
  } else {
    y_abs = y;
  }
  for (i = 0; i < 32; i++) {
    aux1 = (upper << 1) | (lower >> 31);
    aux2 = subWord(aux1, y_abs, &borrow);
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
  *quoPtr = (x_neg == y_neg) ? quot : -quot;
  *remPtr = corr ? y_abs - upper : upper;
}
