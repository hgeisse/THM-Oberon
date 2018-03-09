/*
 * unix2oberon.c -- convert UNIX line endings to Oberon line endings
 */


#include <stdio.h>


int main(int argc, char *argv[]) {
  int c;

  while (1) {
    c = fgetc(stdin);
    if (c == EOF) {
      return 0;
    }
    if (c == '\n') {
      c = '\r';
    }
    fputc(c, stdout);
  }
  return 0;
}
