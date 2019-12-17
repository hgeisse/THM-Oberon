/*
 * cmpx.c -- file comparison with hex output
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


int main(int argc, char *argv[]) {
  FILE *f1, *f2;
  int b1, b2;
  int n;
  int diff;

  if (argc != 3) {
    printf("usage: %s <file1> <file2>\n", argv[0]);
    return 1;
  }
  f1 = fopen(argv[1], "r");
  if (f1 == NULL) {
    printf("error: cannot open '%s'\n", argv[1]);
    return 1;
  }
  f2 = fopen(argv[2], "r");
  if (f2 == NULL) {
    printf("error: cannot open '%s'\n", argv[2]);
    return 1;
  }
  diff = 0;
  n = 0;
  while (1) {
    b1 = fgetc(f1);
    b2 = fgetc(f2);
    if (b1 == EOF || b2 == EOF) {
      break;
    }
    if (b1 != b2) {
      printf("0x%08X  0x%02X  0x%02X\n", n, b1, b2);
      diff = 1;
    }
    n++;
  }
  if (b1 != EOF || b2 != EOF) {
    printf("files have different lengths\n");
    diff = 1;
  }
  fclose(f1);
  fclose(f2);
  return diff;
}
