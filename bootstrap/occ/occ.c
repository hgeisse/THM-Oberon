/*
 * occ.c -- Oberon cross compiler
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>


/**************************************************************/

/*
 * error handling
 */


void error(char *fmt, ...) {
  va_list ap;

  va_start(ap, fmt);
  printf("Error: ");
  vprintf(fmt, ap);
  printf("\n");
  va_end(ap);
  exit(1);
}


/**************************************************************/

/*
 * scanner
 */


/**************************************************************/

/*
 * parser
 */


/**************************************************************/

/*
 * code generator
 */


/**************************************************************/

/*
 * main program
 */


int main(int argc, char *argv[]) {
  error("nothing yet");
  return 0;
}
