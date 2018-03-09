/*
 * dos2oberon.c -- convert DOS line endings to Oberon line endings
 */


#include <stdio.h>


int main(int argc, char *argv[]) {
  int c1, c2;

  c1 = fgetc(stdin);
  if (c1 == EOF) {
    return 0;
  }
  while (1) {
    c2 = fgetc(stdin);
    if (c2 == EOF) {
      fputc(c1, stdout);
      return 0;
    }
    if (c1 == '\r' && c2 == '\n') {
      fputc(c1, stdout);
      c1 = fgetc(stdin);
      if (c1 == EOF) {
        return 0;
      }
    } else {
      fputc(c1, stdout);
      c1 = c2;
    }
  }
  return 0;
}
