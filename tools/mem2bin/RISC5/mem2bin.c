/*
 * mem2bin.c -- convert prom memory format to plain binary
 */


#include <stdio.h>
#include <stdlib.h>


#define LINE_SIZE	150


int main(int argc, char *argv[]) {
  FILE *in, *out;
  char line[LINE_SIZE];
  char *endp;
  unsigned int w;
  unsigned char b;

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
  while (fgets(line, LINE_SIZE, in) != NULL) {
    w = strtoul(line, &endp, 16);
    if (*endp != '\n') {
      printf("error: illegal input format\n");
      return 1;
    }
    b = (w >> 0) & 0xFF;
    if (fwrite(&b, 1, 1, out) != 1) {
      printf("error: cannot write output file\n");
      return 1;
    }
    b = (w >> 8) & 0xFF;
    if (fwrite(&b, 1, 1, out) != 1) {
      printf("error: cannot write output file\n");
      return 1;
    }
    b = (w >> 16) & 0xFF;
    if (fwrite(&b, 1, 1, out) != 1) {
      printf("error: cannot write output file\n");
      return 1;
    }
    b = (w >> 24) & 0xFF;
    if (fwrite(&b, 1, 1, out) != 1) {
      printf("error: cannot write output file\n");
      return 1;
    }
  }
  fclose(in);
  fclose(out);
  return 0;
}
