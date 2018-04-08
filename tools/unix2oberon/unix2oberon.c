/*
 * unix2oberon.c -- convert UNIX line endings to Oberon line endings
 */


#include <stdio.h>


int main(int argc, char *argv[]) {
  FILE *in, *out;
  int c;

  if (argc != 3) {
    printf("usage: %s <input file> <output file>\n", argv[0]);
    return 1;
  }
  in = fopen(argv[1], "r");
  if (in == NULL) {
    printf("error: cannot open input file '%s'\n", argv[1]);
    return 1;
  }
  out = fopen(argv[2], "w");
  if (out == NULL) {
    printf("error: cannot open output file '%s'\n", argv[2]);
    return 1;
  }
  while (1) {
    c = fgetc(in);
    if (c == EOF) {
      break;
    }
    if (c == '\n') {
      c = '\r';
    }
    fputc(c, out);
  }
  fclose(in);
  fclose(out);
  return 0;
}
