/*
 * mem2bin.c -- convert prom memory format to plain binary
 */


#include <stdio.h>
#include <stdlib.h>


#define LINE_SIZE	150


int main(int argc, char *argv[]) {
  FILE *in, *out;
  int lineno;
  char line[LINE_SIZE];
  char *p;
  unsigned int w;
  char *endp;
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
  lineno = 0;
  while (fgets(line, LINE_SIZE, in) != NULL) {
    lineno++;
    p = line;
    while (*p == ' ' || *p == '\t') {
      p++;
    }
    if (*p == '\n') {
      continue;
    }
    if (*(p + 0) == '/' &&
        *(p + 1) == '/') {
      continue;
    }
    w = strtoul(p, &endp, 16);
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
    p = endp;
    while (*p == ' ' || *p == '\t') {
      p++;
    }
    if (*p == '\n') {
      continue;
    }
    if (*(p + 0) == '/' &&
        *(p + 1) == '/') {
      continue;
    }
    printf("error: garbage at end of line %d\n", lineno);
    return 1;
  }
  fclose(in);
  fclose(out);
  return 0;
}
