/*
 * bin2boot.c -- convert plain binary to boot-via-serial-line format
 */


#include <stdio.h>
#include <stdlib.h>


#define BLOCK_SIZE	512
#define DELAY_CYCLES	16


void sndByte(FILE *out, unsigned char b) {
  fprintf(out, "%08X %02X\n", DELAY_CYCLES, b);
}


void sndInt(FILE *out, unsigned int n) {
  sndByte(out, (n >>  0) & 0xFF);
  sndByte(out, (n >>  8) & 0xFF);
  sndByte(out, (n >> 16) & 0xFF);
  sndByte(out, (n >> 24) & 0xFF);
}


int main(int argc, char *argv[]) {
  FILE *in, *out;
  unsigned char buf[BLOCK_SIZE];
  int n, i;
  unsigned int addr;

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
  addr = 0;
  while (1) {
    n = fread(buf, 1, BLOCK_SIZE, in);
    if (n < 0) {
      printf("error: cannot read input file\n");
      return 1;
    }
    if (n == 0) {
      break;
    }
    sndInt(out, n);
    sndInt(out, addr);
    for (i = 0; i < n; i++) {
      sndByte(out, buf[i]);
    }
    addr += n;
    if (n < BLOCK_SIZE) {
      break;
    }
  }
  sndInt(out, 0);
  fclose(in);
  fclose(out);
  return 0;
}
