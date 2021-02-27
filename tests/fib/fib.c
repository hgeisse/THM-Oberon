/*
 * fib.c -- collect execution statistics from computing Fibonacci numbers
 */


#include <stdio.h>


#define INSTRS_IN_BASE_CASE	((long) 18)
#define INSTRS_IN_REC_CASE	((long) 28)


int numBaseCalls;
int numRecCalls;


int fib(int k) {
  if (k < 2) {
    numBaseCalls++;
    return k;
  } else {
    numRecCalls++;
    return fib(k - 1) + fib(k - 2);
  }
}


int main(int argc, char *argv[]) {
  int n, m;
  long instrs;

  for (n = 0; n <= 43; n++) {
    numBaseCalls = 0;
    numRecCalls = 0;
    m = fib(n);
    instrs = (long) numBaseCalls * INSTRS_IN_BASE_CASE +
             (long) numRecCalls * INSTRS_IN_REC_CASE;
    printf("fib(%2d) = %9d, %10d func calls, %11ld instrs\n",
           n, m, numBaseCalls + numRecCalls, instrs);
  }
  return 0;
}
