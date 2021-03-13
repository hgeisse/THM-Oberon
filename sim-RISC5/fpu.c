/*
 * fpu.c -- floating-point unit
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <fenv.h>

#include "common.h"
#include "fpu.h"


typedef union {
  Word w;
  float f;
} FP_Union;


Word fpAdd(Word x, Word y, Bool sub) {
  FP_Union X, Y, Z;

  X.w = x;
  Y.w = y;
  if (sub) {
    Z.f = X.f - Y.f;
  } else {
    Z.f = X.f + Y.f;
  }
  return Z.w;
}


Word fpMul(Word x, Word y) {
  FP_Union X, Y, Z;

  X.w = x;
  Y.w = y;
  Z.f = X.f * Y.f;
  return Z.w;
}


Word fpDiv(Word x, Word y) {
  FP_Union X, Y, Z;

  X.w = x;
  Y.w = y;
  Z.f = X.f / Y.f;
  return Z.w;
}


Word fpFlt(Word x) {
  FP_Union Z;

  Z.f = (float) (int) x;
  return Z.w;
}


Word fpFlr(Word x) {
  FP_Union X;

  X.w = x;
  return (Word) (int) floorf(X.f);
}


Word fpGetFlags(void) {
  fexcept_t fe;
  Word flags;

  fegetexceptflag(&fe, FE_ALL_EXCEPT);
  flags = ((fe & FE_DIVBYZERO) ? _FP_I_FLAG : 0) |
          ((fe & FE_INEXACT)   ? _FP_X_FLAG : 0) |
          ((fe & FE_INVALID)   ? _FP_V_FLAG : 0) |
          ((fe & FE_OVERFLOW)  ? _FP_O_FLAG : 0) |
          ((fe & FE_UNDERFLOW) ? _FP_U_FLAG : 0);
  return flags;
}


void fpClrFlags(void) {
  feclearexcept(FE_ALL_EXCEPT);
}
