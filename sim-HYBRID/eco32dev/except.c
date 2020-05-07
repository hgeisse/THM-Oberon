/*
 * except.c -- glue file
 */


#include "error.h"


void throwException(int exc) {
  error("exception %d thrown", exc);
}
