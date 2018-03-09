/*
 * oberon2dos.c -- convert Oberon line endings to DOS line endings
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
      fputc(c, stdout);
      c = '\n';
      fputc(c, stdout);
    } else {
      fputc(c, stdout);
    }
  }
  return 0;
}
