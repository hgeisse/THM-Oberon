/*
 * oberon2unix.c -- convert Oberon line endings to UNIX line endings
 */


#include <stdio.h>


int main(int argc, char *argv[]) {
  int c;

  while (1) {
    c = fgetc(stdin);
    if (c == EOF) {
      return 0;
    }
    if (c == '\r') {
      c = '\n';
    }
    fputc(c, stdout);
  }
  return 0;
}
