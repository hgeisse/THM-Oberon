/*
 * common.c -- common definitions and functions
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include "common.h"
#include "graph.h"


void error(char *fmt, ...) {
  va_list ap;

  graphExit();
  va_start(ap, fmt);
  printf("Error: ");
  vprintf(fmt, ap);
  printf("\n");
  va_end(ap);
  exit(1);
}
