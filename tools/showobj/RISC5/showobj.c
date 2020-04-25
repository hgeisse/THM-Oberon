/*
 * showobj.c -- show object file
 */

/*
 * The structure of an object file is defined by the following syntax:
 *   CodeFile = name key version size
 *              imports typedesc varsize
 *              strings code commands entries
 *              ptrrefs fixP fixD fixT body "O".
 *   imports = {modname modkey} 0X.
 *   typedesc = nof {byte}.
 *   strings = nof {char}.
 *   code = nof {word}.
 *   commands = {comname offset} 0X.
 *   entries = nof {word}.
 *   ptrrefs = {word} -1.
 *
 * The entities above are encoded with the following types:
 *  - name:	Str
 *  - key:	Int
 *  - version:	Chr
 *  - size:	Int
 *  - varsize:	Int
 *  - fixP:	Int
 *  - fixD:	Int
 *  - fixT:	Int
 *  - body:	Int
 *  - "O":	Chr
 *  - modname:	Str
 *  - modkey:	Int
 *  - 0X:	Str
 *  - nof:	Int
 *  - byte:	Chr
 *  - char:	Chr
 *  - word:	Int
 *  - comname:	Str
 *  - offset:	Int
 *  - -1:	Int
 *
 * Here are the actual respresentations of these types:
 *  - Chr: a single byte (read by Files.Read)
 *  - Int: a 4-byte little-endian integer (read by Files.ReadInt)
 *  - Str: a zero-terminated string of chars (read by Files.ReadString)
 *
 * Semantics:
 * - name
 *   the module's name
 * - key
 *   the module's key (interface checksum)
 * - version
 *   the format version (0: standalone, 1: linkable)
 * - size
 *   size of the module in memory (in bytes, excluding descriptor)
 * - imports
 *   every imported module is represented as a pair (modname, modkey)
 * - typedesc
 *   ?
 * - varsize
 *   ?
 * - strings
 *   ?
 * - code
 *   the code section of the module (an integral number of words)
 * - commands
 *   ?
 * - entries
 *   ?
 * - ptrrefs
 *   ?
 * - fixP fixD fixT
 *   these are origins of chains of instructions to be fixed-up
 *   fixP: fixup chain of code references
 *   fixD: fixup chain of data references
 *   fixT: fixup chain of type descriptors
 * - body
 *   entry point offset of the module body
 * - "O" (a big Oh, not a zero)
 *   allows a simple check for corrupt object file
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>


#define MAX_STRING	100


/**************************************************************/


typedef int Bool;

#define FALSE		0
#define TRUE		1


/**************************************************************/


void error(char *fmt, ...) {
  va_list ap;

  va_start(ap, fmt);
  printf("error: ");
  vprintf(fmt, ap);
  printf("\n");
  va_end(ap);
  exit(1);
}


void *memAlloc(unsigned int size) {
  void *p;

  p = malloc(size);
  if (p == NULL) {
    error("out of memory");
  }
  return p;
}


/**************************************************************/


FILE *objFile;


void readByte(unsigned char *p) {
  int c;

  c = fgetc(objFile);
  if (c == EOF) {
    error("unexpected EOF");
  }
  *p = (unsigned char) c;
}


void readInt(unsigned int *p) {
  int c0, c1, c2, c3;

  c0 = fgetc(objFile);
  c1 = fgetc(objFile);
  c2 = fgetc(objFile);
  c3 = fgetc(objFile);
  if (c0 == EOF || c1 == EOF || c2 == EOF || c3 == EOF) {
    error("unexpected EOF");
  }
  *p = (c0 <<  0) |
       (c1 <<  8) |
       (c2 << 16) |
       (c3 << 24);
}


void readStr(char *p) {
  int c;

  do {
    c = fgetc(objFile);
    if (c == EOF) {
      error("unexpected EOF");
    }
    *p++ = (char) c;
  } while (c != 0);
}


/**************************************************************/

/*
 * binary dump
 */


void bindump(unsigned char *bytes, unsigned int nbytes) {
  unsigned int addr, count;
  unsigned int lo, hi, curr;
  int lines, i, j;
  unsigned int tmp;
  unsigned char c;

  addr = 0;
  count = nbytes;
  lo = addr & ~0x0000000F;
  hi = addr + count - 1;
  if (hi < lo) {
    /* wrap-around */
    hi = 0xFFFFFFFF;
  }
  lines = (hi - lo + 16) >> 4;
  curr = lo;
  for (i = 0; i < lines; i++) {
    printf("%08X:  ", curr);
    for (j = 0; j < 16; j++) {
      tmp = curr + j;
      if (tmp < addr || tmp > hi) {
        printf("  ");
      } else {
        c = bytes[tmp];
        printf("%02X", c);
      }
      printf(" ");
    }
    printf("  ");
    for (j = 0; j < 16; j++) {
      tmp = curr + j;
      if (tmp < addr || tmp > hi) {
        printf(" ");
      } else {
        c = bytes[tmp];
        if (c >= 32 && c <= 126) {
          printf("%c", c);
        } else {
          printf(".");
        }
      }
    }
    printf("\n");
    curr += 16;
  }
}


/**************************************************************/

/*
 * disassembler
 */


#define SIGN_EXT_24(x)	((x) & 0x00800000 ? (x) | 0xFF000000 : (x))
#define SIGN_EXT_20(x)	((x) & 0x00080000 ? (x) | 0xFFF00000 : (x))


static char instrBuffer[100];


static char *regOps[16] = {
  /* 0x00 */  "MOV", "LSL", "ASR", "ROR",
  /* 0x04 */  "AND", "ANN", "IOR", "XOR",
  /* 0x08 */  "ADD", "SUB", "MUL", "DIV",
  /* 0x0C */  "FAD", "FSB", "FML", "FDV",
};


static void disasmF0(unsigned int instr) {
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
        sprintf(instrBuffer, "%-7s R%d,H", regOps[op], a);
      } else {
        /* v = 1: get flag values */
        sprintf(instrBuffer, "%-7s R%d,F", regOps[op], a);
      }
    }
  } else {
    /* any operation other than MOV */
    sprintf(instrBuffer, "%-7s R%d,R%d,R%d", regOps[op], a, b, c);
    if ((op == 8 || op == 9) && ((instr >> 29) & 1) != 0) {
      /* ADD, SUB with u = 1: add/subtract with carry */
      instrBuffer[3] = 'C';
    } else
    if (op == 10 && ((instr >> 29) & 1) != 0) {
      /* MUL with u = 1: unsigned mul */
      instrBuffer[3] = 'U';
    }
  }
}


static void disasmF1(unsigned int instr) {
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
      sprintf(instrBuffer, "%-7s R%d,0x%08X", regOps[op], a, im << 16);
    }
  } else {
    /* any operation other than MOV */
    sprintf(instrBuffer, "%-7s R%d,R%d,0x%08X", regOps[op], a, b, im);
    if ((op == 8 || op == 9) && ((instr >> 29) & 1) != 0) {
      /* ADD, SUB with u = 1: add/subtract with carry */
      instrBuffer[3] = 'C';
    } else
    if (op == 10 && ((instr >> 29) & 1) != 0) {
      /* MUL with u = 1: unsigned mul */
      instrBuffer[3] = 'U';
    }
  }
}


static void disasmF2(unsigned int instr) {
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
  sprintf(instrBuffer, "%-7s R%d,R%d,%s%05X",
          opName, a, b,
          offset < 0 ? "-" : "+",
          offset < 0 ? -offset : offset);
}


static char *condName[16] = {
  /* 0x00 */  "MI", "EQ", "CS", "VS", "LS", "LT", "LE", "",
  /* 0x08 */  "PL", "NE", "CC", "VC", "HI", "GE", "GT", "NVR",
};


static void disasmF3(unsigned int instr, unsigned int locus) {
  char *cond;
  int c;
  int offset;
  unsigned int target;

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
          /* interrupt disable/enable */
          if ((instr & 1) == 0) {
            sprintf(instrBuffer, "DI");
          } else {
            sprintf(instrBuffer, "EI");
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
    offset = SIGN_EXT_24(instr & 0x00FFFFFF);
    target = ((locus >> 2) + 1 + offset) << 2;
    if (((instr >> 28) & 1) == 0) {
      /* v = 0: branch */
      sprintf(instrBuffer, "B%-6s %08X", cond, target);
    } else {
      /* v = 1: call */
      sprintf(instrBuffer, "C%-6s %08X", cond, target);
    }
  }
}


char *disasm(unsigned int instr, unsigned int locus) {
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


void usage(char *myself) {
  printf("usage: %s [options] <object file>\n", myself);
  printf("options:\n");
  printf("    -i       show imports\n");
  printf("    -t       show type descriptors\n");
  printf("    -s       show strings\n");
  printf("    -d       show disassembled code\n");
  printf("    -c       show commands\n");
  printf("    -e       show entries\n");
  printf("    -p       show pointer refs\n");
  printf("    -a       show all\n");
  exit(1);
}


int main(int argc, char *argv[]) {
  int i;
  char *optptr;
  Bool iFlag;
  Bool tFlag;
  Bool sFlag;
  Bool dFlag;
  Bool cFlag;
  Bool eFlag;
  Bool pFlag;
  char *objFileName;
  char name[MAX_STRING];
  unsigned int key;
  unsigned char version;
  unsigned int size;
  char impName[MAX_STRING];
  unsigned int impKey;
  unsigned int tdsize;
  unsigned char *tdescs;
  unsigned int varsize;
  unsigned int strsize;
  unsigned char *strings;
  unsigned int codesize;
  unsigned int addr;
  unsigned int instr;
  char *src;
  unsigned char ch;
  unsigned int offset;
  unsigned int numEntries;
  unsigned int entry;
  unsigned int ptrRef;
  unsigned int fixorgP;
  unsigned int fixorgD;
  unsigned int fixorgT;
  unsigned int body;

  iFlag = FALSE;
  tFlag = FALSE;
  sFlag = FALSE;
  dFlag = FALSE;
  cFlag = FALSE;
  eFlag = FALSE;
  pFlag = FALSE;
  objFileName = NULL;
  for (i = 1; i < argc; i++) {
    optptr = argv[i];
    if (*optptr == '-') {
      /* option */
      if (strcmp(argv[i], "-i") == 0) {
        iFlag = TRUE;
      } else
      if (strcmp(argv[i], "-t") == 0) {
        tFlag = TRUE;
      } else
      if (strcmp(argv[i], "-s") == 0) {
        sFlag = TRUE;
      } else
      if (strcmp(argv[i], "-d") == 0) {
        dFlag = TRUE;
      } else
      if (strcmp(argv[i], "-c") == 0) {
        cFlag = TRUE;
      } else
      if (strcmp(argv[i], "-e") == 0) {
        eFlag = TRUE;
      } else
      if (strcmp(argv[i], "-p") == 0) {
        pFlag = TRUE;
      } else
      if (strcmp(argv[i], "-a") == 0) {
        iFlag = TRUE;
        tFlag = TRUE;
        sFlag = TRUE;
        dFlag = TRUE;
        cFlag = TRUE;
        eFlag = TRUE;
        pFlag = TRUE;
      } else {
        usage(argv[0]);
      }
    } else {
      /* file */
      if (objFileName != NULL) {
        usage(argv[0]);
      }
      objFileName = argv[i];
    }
  }
  if (objFileName == NULL) {
    usage(argv[0]);
  }
  objFile = fopen(objFileName, "r");
  if (objFile == NULL) {
    error("cannot open object file '%s'", argv[1]);
  }
  /* read and interpret file contents */
  readStr(name);
  printf("module name\t\t: %s\n", name);
  readInt(&key);
  printf("module key\t\t: 0x%08X\n", key);
  readByte(&version);
  if (version != 0 && version != 1) {
    error("unknown format version 0x%02X", version);
  }
  printf("format version\t\t: 0x%02X (%s)\n", version,
         (version == 0) ? "standalone" : "linkable");
  readInt(&size);
  printf("memory size\t\t: 0x%08X bytes\n", size);
  readStr(impName);
  if (impName[0] == '\0') {
    printf("imported modules\t: <none>\n");
  } else {
    if (!iFlag) {
      printf("imported modules\t: ...\n");
    }
  }
  while (impName[0] != '\0') {
    readInt(&impKey);
    if (iFlag) {
      printf("imported module / key\t: %s / 0x%08X\n", impName, impKey);
    }
    readStr(impName);
  }
  readInt(&tdsize);
  printf("type descriptor size\t: 0x%08X bytes\n", tdsize);
  if (tdsize != 0) {
    if (tFlag) {
      printf("type desciptors\t\t: \n");
    } else {
      printf("type desciptors\t\t: ...\n");
    }
    tdescs = memAlloc(tdsize);
    for (i = 0; i < tdsize; i++) {
      readByte(tdescs + i);
    }
    if (tFlag) {
      bindump(tdescs, tdsize);
    }
  }
  readInt(&varsize);
  printf("variable size\t\t: 0x%08X bytes\n", varsize);
  readInt(&strsize);
  printf("string size\t\t: 0x%08X bytes\n", strsize);
  if (strsize != 0) {
    if (sFlag) {
      printf("strings\t\t\t: \n");
    } else {
      printf("strings\t\t\t: ...\n");
    }
    strings = memAlloc(strsize);
    for (i = 0; i < strsize; i++) {
      readByte(strings + i);
    }
    if (sFlag) {
      bindump(strings, strsize);
    }
  }
  readInt(&codesize);
  printf("code size\t\t: 0x%08X words\n", codesize);
  if (codesize != 0) {
    if (dFlag) {
      printf("code\t\t\t: \n");
    } else {
      printf("code\t\t\t: ...\n");
    }
    addr = 0;
    for (i = 0; i < codesize; i++) {
      readInt(&instr);
      src = disasm(instr, addr);
      if (dFlag) {
        printf("%08X:  %08X    %s\n", addr, instr, src);
      }
      addr += 4;
    }
  }
  readStr(name);
  if (name[0] == '\0') {
    printf("commands\t\t: <none>\n");
  } else {
    if (!cFlag) {
      printf("commands\t\t: ...\n");
    }
  }
  while (name[0] != '\0') {
    readInt(&offset);
    if (cFlag) {
      printf("command / offset\t: %s / 0x%08X\n", name, offset);
    }
    readStr(name);
  }
  readInt(&numEntries);
  printf("number of entries\t: %d\n", numEntries);
  if (numEntries != 0) {
    if (!eFlag) {
      printf("entries\t\t\t: ...\n");
    }
    for (i = 0; i < numEntries; i++) {
      readInt(&entry);
      if (eFlag) {
        printf("entry[%d]\t\t: 0x%08X\n", i, entry);
      }
    }
  }
  readInt(&ptrRef);
  if ((int) ptrRef < 0) {
    printf("pointer refs\t\t: <none>\n");
  } else {
    if (!pFlag) {
      printf("pointer refs\t\t: ...\n");
    }
  }
  while ((int) ptrRef >= 0) {
    if (pFlag) {
      printf("pointer ref\t\t: 0x%08X\n", ptrRef);
    }
    readInt(&ptrRef);
  }
  if ((int) ptrRef != -1) {
    error("ptrrefs not properly terminated by -1");
  }
  readInt(&fixorgP);
  printf("fixorgP\t\t\t: 0x%08X\n", fixorgP);
  readInt(&fixorgD);
  printf("fixorgD\t\t\t: 0x%08X\n", fixorgD);
  readInt(&fixorgT);
  printf("fixorgT\t\t\t: 0x%08X\n", fixorgT);
  readInt(&body);
  printf("body\t\t\t: 0x%08X\n", body);
  readByte(&ch);
  if (ch != 'O') {
    error("missing 'O' at end of object file");
  }
  printf("object file correctly read\n");
  fclose(objFile);
  return 0;
}
