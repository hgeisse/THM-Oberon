/*
 * generate assembler source from bit patterns
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define LINE_SIZE	200

#define SIGN_EXT_20(x)	((x) & 0x00080000 ? (x) | 0xFFF00000 : (x))

#define ADDR_MASK	0x00FFFFFF


typedef unsigned int Word;


/**************************************************************/

/*
 * disassembler
 */


static char instrBuffer[100];


static char *regOps[16] = {
  /* 0x00 */  "MOV", "LSL", "ASR", "ROR",
  /* 0x04 */  "AND", "ANN", "IOR", "XOR",
  /* 0x08 */  "ADD", "SUB", "MUL", "DIV",
  /* 0x0C */  "FAD", "FSB", "FML", "FDV",
};


static void disasmF0(Word instr) {
  int a, b, op, c;

  a = (instr >> 24) & 0x0F;
  b = (instr >> 20) & 0x0F;
  op = (instr >> 16) & 0x0F;
  c = instr & 0x0F;
  if (op == 0) {
    /* MOV */
    if (((instr >> 29) & 1) == 0) {
      /* u = 0: move from any general register */
      sprintf(instrBuffer, "%-7s R%d,R%d", regOps[op], a, c);
    } else {
      /* u = 1: move from special register */
      if (((instr >> 28) & 1) == 0) {
        /* v = 0: get H register */
        sprintf(instrBuffer, "%-7s R%d", "GETH", a);
      } else {
        /* v = 1: get flag values and CPU ID */
        sprintf(instrBuffer, "%-7s R%d", "GETF", a);
      }
    }
  } else {
    /* any operation other than MOV */
    sprintf(instrBuffer, "%-7s R%d,R%d,R%d", regOps[op], a, b, c);
    if ((op == 8 || op == 9) && ((instr >> 29) & 1) != 0) {
      /* ADD/SUB with u = 1: add/subtract with carry/borrow */
      instrBuffer[3] = (op == 8) ? 'C' : 'B';
    } else
    if ((op == 10 || op == 11) && ((instr >> 29) & 1) != 0) {
      /* MUL/DIV with u = 1: unsigned mul/div */
      instrBuffer[3] = 'U';
    } else
    if (op == 12 && ((instr >> 29) & 1) != 0 && ((instr >> 28) & 1) == 0) {
      /* FAD with u = 1, v = 0: FLT (INTEGER -> REAL) */
      sprintf(instrBuffer, "%-7s R%d,R%d", "FLT", a, b);
    } else
    if (op == 12 && ((instr >> 29) & 1) == 0 && ((instr >> 28) & 1) != 0) {
      /* FAD with u = 0, v = 1: FLR (REAL -> INTEGER) */
      sprintf(instrBuffer, "%-7s R%d,R%d", "FLR", a, b);
    }
  }
}


static void disasmF1(Word instr) {
  int a, b, op, im;

  a = (instr >> 24) & 0x0F;
  b = (instr >> 20) & 0x0F;
  op = (instr >> 16) & 0x0F;
  im = instr & 0xFFFF;
  if ((instr >> 28) & 1) {
    /* v = 1: fill upper 16 bits with 1 */
    im |= 0xFFFF0000;
  }
  if (op == 0) {
    /* MOV */
    if (((instr >> 29) & 1) == 0) {
      /* u = 0: use immediate value as is */
      sprintf(instrBuffer, "%-7s R%d,0x%08X", regOps[op], a, im);
    } else {
      /* u = 1: shift immediate value to upper 16 bits */
      sprintf(instrBuffer, "%-7s R%d,0x%08X", regOps[op], a, im);
      instrBuffer[3] = 'H';
    }
  } else {
    /* any operation other than MOV */
    sprintf(instrBuffer, "%-7s R%d,R%d,0x%08X", regOps[op], a, b, im);
    if ((op == 8 || op == 9) && ((instr >> 29) & 1) != 0) {
      /* ADD/SUB with u = 1: add/subtract with carry/borrow */
      instrBuffer[3] = (op == 8) ? 'C' : 'B';
    } else
    if ((op == 10 || op == 11) && ((instr >> 29) & 1) != 0) {
      /* MUL/DIV with u = 1: unsigned mul/div */
      instrBuffer[3] = 'U';
    }
  }
}


static void disasmF2(Word instr) {
  char *opName;
  int a, b;
  int offset;

  if (((instr >> 29) & 1) == 0) {
    /* u = 0: load */
    if (((instr >> 28) & 1) == 0) {
      /* v = 0: word */
      opName = "LDW";
    } else {
      /* v = 1: byte */
      opName = "LDB";
    }
  } else {
    /* u = 1: store */
    if (((instr >> 28) & 1) == 0) {
      /* v = 0: word */
      opName = "STW";
    } else {
      /* v = 1: byte */
      opName = "STB";
    }
  }
  a = (instr >> 24) & 0x0F;
  b = (instr >> 20) & 0x0F;
  offset = SIGN_EXT_20(instr & 0x000FFFFF);
  sprintf(instrBuffer, "%-7s R%d,R%d,%s0x%05X",
          opName, a, b,
          offset < 0 ? "-" : "+",
          offset < 0 ? -offset : offset);
}


static char *condName[16] = {
  /* 0x00 */  "MI", "EQ", "CS", "VS", "LS", "LT", "LE", "",
  /* 0x08 */  "PL", "NE", "CC", "VC", "HI", "GE", "GT", "NVR",
};


static void disasmF3(Word instr, Word locus) {
  char *cond;
  int c;
  int offset;
  Word target;

  cond = condName[(instr >> 24) & 0x0F];
  if (((instr >> 29) & 1) == 0) {
    /* u = 0: branch target is in register */
    c = instr & 0x0F;
    if (((instr >> 28) & 1) == 0) {
      /* v = 0: branch or interrupt handling */
      switch ((instr >> 4) & 3) {
        case 0:
          /* branch */
          sprintf(instrBuffer, "B%-6s R%d", cond, c);
          break;
        case 1:
          /* return from interrupt */
          sprintf(instrBuffer, "RTI");
          break;
        case 2:
          /* clear/set interrupt enable */
          if ((instr & 1) == 0) {
            sprintf(instrBuffer, "CLI");
          } else {
            sprintf(instrBuffer, "STI");
          }
          break;
        case 3:
          /* undefined */
          sprintf(instrBuffer, "<undefined>");
          break;
      }
    } else {
      /* v = 1: call */
      sprintf(instrBuffer, "C%-6s R%d", cond, c);
    }
  } else {
    /* u = 1: branch target is pc + 1 + offset */
    offset = instr & 0x003FFFFF;
    target = (((locus >> 2) + 1 + offset) << 2) & ADDR_MASK;
    if (((instr >> 28) & 1) == 0) {
      /* v = 0: branch */
      sprintf(instrBuffer, "B%-6s 0x%08X", cond, target);
    } else {
      /* v = 1: call */
      sprintf(instrBuffer, "C%-6s 0x%08X", cond, target);
    }
  }
}


char *disasm(Word instr, Word locus) {
  switch ((instr >> 30) & 3) {
    case 0:
      disasmF0(instr);
      break;
    case 1:
      disasmF1(instr);
      break;
    case 2:
      disasmF2(instr);
      break;
    case 3:
      disasmF3(instr, locus);
      break;
  }
  return instrBuffer;
}


/**************************************************************/


int main(int argc, char *argv[]) {
  FILE *bitpat;
  char line[LINE_SIZE];
  Word instr, locus;
  char *instrText;

  if (argc != 2) {
    printf("usage: %s <input file>\n", argv[0]);
    return 1;
  }
  bitpat = fopen(argv[1], "r");
  if (bitpat == NULL) {
    printf("error: cannot open input file '%s'\n", argv[1]);
    return 1;
  }
  locus = 0;
  while (fgets(line, LINE_SIZE, bitpat) != NULL) {
    instr = strtoul(line, NULL, 16);
    instrText = disasm(instr, locus);
    printf("\t%s\t\t// 0x%06X: 0x%08X\n", instrText, locus, instr);
    locus += 4;
  }
  fclose(bitpat);
  return 0;
}
