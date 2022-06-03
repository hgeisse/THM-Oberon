/*
 * icacheld.c -- icache loader
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define BUF_SIZE	4096
#define LINE_SIZE	200


int debug = 0;


unsigned int buffer[BUF_SIZE];


int cachePos(unsigned int addr) {
  return (addr >> 2) & 0x0FFF;
}


int main(int argc, char *argv[]) {
  FILE *memFile;
  FILE *ldaFile;
  FILE *datFile;
  int i;
  char line[LINE_SIZE];
  char *p;
  unsigned int addr;
  int pos;
  unsigned int data;

  if (argc != 4) {
    printf("usage: %s <.mem input> <.lda input> <.dat output>\n",
           argv[0]);
    return 1;
  }
  memFile = fopen(argv[1], "r");
  if (memFile == NULL) {
    printf("cannot open input file '%s'\n", argv[1]);
    return 1;
  }
  ldaFile = fopen(argv[2], "r");
  if (ldaFile == NULL) {
    printf("cannot open input file '%s'\n", argv[2]);
    return 1;
  }
  datFile = fopen(argv[3], "w");
  if (datFile == NULL) {
    printf("cannot open output file '%s'\n", argv[3]);
    return 1;
  }
  for (i = 0; i < BUF_SIZE; i++) {
    buffer[i] = 0;
  }
  if (fgets(line, LINE_SIZE, ldaFile) == NULL) {
    printf("cannot read load address from file '%s'\n", argv[2]);
    return 1;
  }
  p = strstr(line, ".LOC");
  if (p == NULL) {
    printf("cannot read load address from file '%s'\n", argv[2]);
    return 1;
  }
  addr = strtoul(p + 4, NULL, 0);
  while (fgets(line, LINE_SIZE, memFile) != NULL) {
    data = strtoul(line, NULL, 16);
    pos = cachePos(addr);
    buffer[pos] = data;
    if (debug) {
      printf("deposit @ addr 0x%08X (pos 0x%08X): data 0x%08X\n",
             addr, pos, data);
    }
    addr += 4;
  }
  for (i = 0; i < BUF_SIZE; i++) {
    fprintf(datFile, "%08X\n", buffer[i]);
  }
  fclose(memFile);
  fclose(ldaFile);
  fclose(datFile);
  return 0;
}
