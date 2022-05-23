/*
 * generate bit patterns for assembler test
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


int F0(void) {
  int n;
  unsigned int word;

  n = 0;
  /* standard register/register operations */
  for (word = 0; word < (1 << 16); word++) {
    if ((word & 0x00F0) == 0x0000 &&
        (word & 0x0F00) != 0x0000) {
      /* skip redundant MOV encodings */
      continue;
    }
    printf("%08X\n", (0x0 << 28) |
                     ((word & 0xFFF0) << 12) |
                     ((word & 0x000F) <<  0));
    n++;
  }
  /* get H register */
  for (word = 0; word < 16; word++) {
    printf("%08X\n", (0x2 << 28) | (word << 24));
    n++;
  }
  /* get F register */
  for (word = 0; word < 16; word++) {
    printf("%08X\n", (0x3 << 28) | (word << 24));
    n++;
  }
  /* add with carry */
  for (word = 0; word < (1 << 12); word++) {
    printf("%08X\n", (0x2 << 28) | (0x8 << 16) |
                     ((word & 0xFF0) << 16) |
                     ((word & 0x00F) << 0));
    n++;
  }
  /* subtract with borrow */
  for (word = 0; word < (1 << 12); word++) {
    printf("%08X\n", (0x2 << 28) | (0x9 << 16) |
                     ((word & 0xFF0) << 16) |
                     ((word & 0x00F) << 0));
    n++;
  }
  /* multiply unsigned */
  for (word = 0; word < (1 << 12); word++) {
    printf("%08X\n", (0x2 << 28) | (0xA << 16) |
                     ((word & 0xFF0) << 16) |
                     ((word & 0x00F) << 0));
    n++;
  }
  /* divide unsigned */
  for (word = 0; word < (1 << 12); word++) {
    printf("%08X\n", (0x2 << 28) | (0xB << 16) |
                     ((word & 0xFF0) << 16) |
                     ((word & 0x00F) << 0));
    n++;
  }
  /* convert to integer */
  for (word = 0; word < 256; word++) {
    printf("%08X\n", (0x1 << 28) | (0xC << 16) | (word << 20));
    n++;
  }
  /* convert to floating-point */
  for (word = 0; word < 256; word++) {
    printf("%08X\n", (0x2 << 28) | (0xC << 16) | (word << 20));
    n++;
  }
  return n;
}


int F1(void) {
  int n;
  unsigned int word;

  n = 0;
  /* standard register/immediate operations, extension bit = 0 */
  for (word = 0; word < (1 << 16); word++) {
    if ((word & 0x00F0) == 0x0000 &&
        (word & 0x0F00) != 0x0000) {
      /* skip redundant MOV encodings */
      continue;
    }
    printf("%08X\n", (0x4 << 28) |
                     ((word & 0xFFF0) << 12) |
                     ((word & 0x000F) <<  0));
    n++;
  }
  /* standard register/immediate operations, extension bit = 1 */
  for (word = 0; word < (1 << 16); word++) {
    if ((word & 0x00F0) == 0x0000 &&
        (word & 0x0F00) != 0x0000) {
      /* skip redundant MOV encodings */
      continue;
    }
    printf("%08X\n", (0x5 << 28) |
                     ((word & 0xFFF0) << 12) |
                     ((word & 0x000F) <<  0));
    n++;
  }
  /* move to high part of register, extension bit = 0 */
  for (word = 0; word < 256; word++) {
    printf("%08X\n", (0x6 << 28) |
                     ((word & 0xF0) << 20) |
                     ((word & 0x0F) << 0));
    n++;
  }
  /* move to high part of register, extension bit = 1 */
  for (word = 0; word < 256; word++) {
    printf("%08X\n", (0x7 << 28) |
                     ((word & 0xF0) << 20) |
                     ((word & 0x0F) << 0));
    n++;
  }
  /* add with carry, extension bit = 0 */
  for (word = 0; word < (1 << 12); word++) {
    printf("%08X\n", (0x6 << 28) | (0x8 << 16) |
                     ((word & 0xFF0) << 16) |
                     ((word & 0x00F) << 0));
    n++;
  }
  /* subtract with borrow, extension bit = 0 */
  for (word = 0; word < (1 << 12); word++) {
    printf("%08X\n", (0x6 << 28) | (0x9 << 16) |
                     ((word & 0xFF0) << 16) |
                     ((word & 0x00F) << 0));
    n++;
  }
  /* multiply unsigned, extension bit = 0 */
  for (word = 0; word < (1 << 12); word++) {
    printf("%08X\n", (0x6 << 28) | (0xA << 16) |
                     ((word & 0xFF0) << 16) |
                     ((word & 0x00F) << 0));
    n++;
  }
  /* divide unsigned, extension bit = 0 */
  for (word = 0; word < (1 << 12); word++) {
    printf("%08X\n", (0x6 << 28) | (0xB << 16) |
                     ((word & 0xFF0) << 16) |
                     ((word & 0x00F) << 0));
    n++;
  }
  /* add with carry, extension bit = 1 */
  for (word = 0; word < (1 << 12); word++) {
    printf("%08X\n", (0x7 << 28) | (0x8 << 16) |
                     ((word & 0xFF0) << 16) |
                     ((word & 0x00F) << 0));
    n++;
  }
  /* subtract with borrow, extension bit = 1 */
  for (word = 0; word < (1 << 12); word++) {
    printf("%08X\n", (0x7 << 28) | (0x9 << 16) |
                     ((word & 0xFF0) << 16) |
                     ((word & 0x00F) << 0));
    n++;
  }
  /* multiply unsigned, extension bit = 1 */
  for (word = 0; word < (1 << 12); word++) {
    printf("%08X\n", (0x7 << 28) | (0xA << 16) |
                     ((word & 0xFF0) << 16) |
                     ((word & 0x00F) << 0));
    n++;
  }
  /* divide unsigned, extension bit = 1 */
  for (word = 0; word < (1 << 12); word++) {
    printf("%08X\n", (0x7 << 28) | (0xB << 16) |
                     ((word & 0xFF0) << 16) |
                     ((word & 0x00F) << 0));
    n++;
  }
  return n;
}


int F2(void) {
  int n;
  unsigned int word;

  n = 0;
  /* load word */
  for (word = 0; word < (1 << 16); word++) {
    printf("%08X\n", (0x8 << 28) |
                     ((word & 0xFFF0) << 12) |
                     ((word & 0x000F) <<  0));
    n++;
  }
  /* load byte */
  for (word = 0; word < (1 << 16); word++) {
    printf("%08X\n", (0x9 << 28) |
                     ((word & 0xFFF0) << 12) |
                     ((word & 0x000F) <<  0));
    n++;
  }
  /* store word */
  for (word = 0; word < (1 << 16); word++) {
    printf("%08X\n", (0xA << 28) |
                     ((word & 0xFFF0) << 12) |
                     ((word & 0x000F) <<  0));
    n++;
  }
  /* store byte */
  for (word = 0; word < (1 << 16); word++) {
    printf("%08X\n", (0xB << 28) |
                     ((word & 0xFFF0) << 12) |
                     ((word & 0x000F) <<  0));
    n++;
  }
  return n;
}


int F3(void) {
  int n;
  unsigned int word;

  n = 0;
  /* branch with register */
  for (word = 0; word < (1 << 8); word++) {
    printf("%08X\n", (0xC << 28) |
                     ((word & 0xF0) << 20) |
                     ((word & 0x0F) <<  0));
    n++;
  }
  /* call with register */
  for (word = 0; word < (1 << 8); word++) {
    printf("%08X\n", (0xD << 28) |
                     ((word & 0xF0) << 20) |
                     ((word & 0x0F) <<  0));
    n++;
  }
  /* branch with offset */
  for (word = 0; word < (1 << 12); word++) {
    printf("%08X\n", (0xE << 28) |
                     ((word & 0xF00) << 16) |
                     ((word & 0x0F0) << 14) |
                     ((word & 0x00F) <<  0));
    n++;
  }
  /* call with offset */
  for (word = 0; word < (1 << 12); word++) {
    printf("%08X\n", (0xF << 28) |
                     ((word & 0xF00) << 16) |
                     ((word & 0x0F0) << 14) |
                     ((word & 0x00F) <<  0));
    n++;
  }
  /* return from interrupt */
  printf("%08X\n", 0xC7000010);
  n++;
  /* clear interrupt enable */
  printf("%08X\n", 0xCF000020);
  n++;
  /* set interrupt enable */
  printf("%08X\n", 0xCF000021);
  n++;
  return n;
}


int main(int argc, char *argv[]) {
  int n0, n1, n2, n3;

  n0 = F0();
  fprintf(stderr, "number of F0 patterns = %d\n", n0);
  n1 = F1();
  fprintf(stderr, "number of F1 patterns = %d\n", n1);
  n2 = F2();
  fprintf(stderr, "number of F2 patterns = %d\n", n2);
  n3 = F3();
  fprintf(stderr, "number of F3 patterns = %d\n", n3);
  fprintf(stderr, "total number of patterns = %d\n", n0 + n1 + n2 + n3);
  return 0;
}
