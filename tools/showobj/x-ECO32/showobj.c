/*
 * showobj.c -- show Extended Oberon object file (ECO32)
 */

/*
 * The structure of an object file is defined by the following syntax:
 *   CodeFile = name key version size
 *              imports varsize
 *              strings typedesc
 *              code commands entries
 *              ptrrefs pvrrefs
 *              fixP fixD fixT fixM
 *              body "O".
 *   imports = {modname modkey} 0X.
 *   typedesc = nof {byte}.
 *   strings = nof {char}.
 *   code = nof {word}.
 *   commands = {comname offset} 0X.
 *   entries = nof {word}.
 *   ptrrefs = {word} -1.
 *   pvrrefs = {word} -1.
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
 *  - fixM:	Int
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
 *  - Int: a 4-byte big-endian integer (read by Files.ReadInt)
 *  - Str: a zero-terminated string of chars (read by Files.ReadString)
 *
 * Semantics:
 * - name
 *   The module's name is used to identify the module in the list of
 *   loaded modules.
 * - key
 *   The module's key (i.e., its interface checksum) is used to check
 *   that importing modules get the correct version of the module.
 * - version
 *   This is the format version (0: standalone, 1: linkable).
 * - size
 *   This is the size of the module in memory (in bytes, excluding
 *   the module descriptor).
 * - imports
 *   Every imported module is represented as a pair (modname, modkey).
 *   The modkey is checked against the imported module's key.
 * - varsize
 *   This is the space needed for storing the global variables of this
 *   module (in bytes, always divisible by 4). The area gets zeroed
 *   when the module is loaded.
 * - strings
 *   This area holds constant strings. Each string is terminated by
 *   a NUL byte and is padded to an integral number of words.
 * - typedesc
 *   ?
 * - code
 *   This is the code section of the module (always an integral number
 *   of words). The size is given in words.
 * - commands
 *   ?
 * - entries
 *   This is an array of offsets (in bytes, from the start of the code
 *   section of the module) of the entry points of exported procedures.
 *   Entry 0 is special: it points to the module's body.
 * - ptrrefs
 *   ?
 * - pvrrefs
 *   ?
 * - fixP
 *   This is the start offset of the fixup chain of code references
 *   (in words, from the start of the code section of the module).
 *   Each entry in the chain is a 32-bit word containing (from MSB):
 *     4-bit ignored
 *     6-bit module number (index in the import table)
 *     8-bit procedure number (index in the imported "entry" array)
 *     14-bit displacement to the next entry in the chain (in words)
 *   The generated instruction replaces the word in the chain and is
 *   always a branch-and-link instruction (BLT).
 * - fixD
 *   This is the start offset of the fixup chain of data references
 *   (in words, from the start of the code section of the module).
 *   Each entry in the chain consists of two consecutive 32-bit words.
 *   The first word contains the following fields (from MSB):
 *     ??
 * - fixT
 *   fixup chain of type descriptors
 * - fixM
 *   fixup chain of method tables
 * - body
 *   This is the entry point offset of the module body (in bytes,
 *   from the start of the code section of the module).
 * - "O" (a big Oh, not a zero)
 *   This allows a simple check for a corrupted object file.
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>


#define MAX_STRING	100

#define MASK(n)		((1 << (n)) - 1)


/**************************************************************/


typedef int Bool;

#define FALSE		0
#define TRUE		1


typedef struct fixup {
  unsigned int addr;		/* address where fixup takes place */
  int mno;			/* module which is referenced */
  int val;			/* value (different meanings) */
  struct fixup *next;		/* next fixup record in list */
} Fixup;


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
  *p = (c0 << 24) |
       (c1 << 16) |
       (c2 <<  8) |
       (c3 <<  0);
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


static char instrBuffer[100];


char *disasm(unsigned int instr, unsigned int locus) {
  sprintf(instrBuffer, "-- not yet 0 --");
  return instrBuffer;
}


char *disasmFixProg(unsigned int instr,
                    unsigned int locus,
                    Fixup *fixProg) {
#if 0
  if ((instr >> 28) != 0xF) {
    error("unknown instruction 0x%08X @ 0x%08X on prog fixup list",
          instr, locus);
  }
  sprintf(instrBuffer, "C       extern:module=%d,entry=%d",
          fixProg->mno, fixProg->val);
#endif
  sprintf(instrBuffer, "-- not yet 1 --");
  return instrBuffer;
}


char *disasmFixData1(unsigned int instr,
                     unsigned int locus,
                     Fixup *fixData) {
#if 0
  unsigned int offHi;

  if (fixData->mno == 0) {
    /* global variable */
    offHi = (instr >> 12) & MASK(8);
    sprintf(instrBuffer, "MOVH    R%d,global:offHi=0x%08X",
            fixData->val, offHi);
  } else {
    /* external variable */
    sprintf(instrBuffer, "MOVH    R%d,extern:module=%d",
            fixData->val, fixData->mno);
  }
#endif
  sprintf(instrBuffer, "-- not yet 2 --");
  return instrBuffer;
}


#if 0
static char *memOps[4] = {
  /* 0 */  "LDW",
  /* 1 */  "LDB",
  /* 2 */  "STW",
  /* 3 */  "STB",
};
#endif


char *disasmFixData2(unsigned int instr,
                     unsigned int locus,
                     Fixup *fixData) {
#if 0
  char *opName;
  int a, b;
  unsigned int offLo;
  int entry;
  char *base;

  if ((instr >> 30) == 2) {
    /* memory access */
    opName = memOps[(instr >> 28) & 3];
  } else {
    /* any other instruction */
    opName = "IOR";
  }
  a = (instr >> 24) & MASK(4);
  b = (instr >> 20) & MASK(4);
  if (fixData->mno == 0) {
    /* global variable */
    offLo = instr & MASK(16);
    sprintf(instrBuffer, "%-7s R%d,R%d,global:offLo=0x%05X",
            opName, a, b, offLo);
  } else {
    /* external variable */
    entry = instr & MASK(8);
    base = ((instr >> 8) & 1) ? "code" : "data";
    sprintf(instrBuffer, "%-7s R%d,R%d,extern:entry=%d(%s)",
            opName, a, b, entry, base);
  }
  sprintf(instrBuffer, "-- not yet 3 --");
#endif
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
  printf("    -v       show procedure variable refs\n");
  printf("    -fp      show fixup chain of code references\n");
  printf("    -fd      show fixup chain of data references\n");
  printf("    -ft      show fixup chain of type descriptors\n");
  printf("    -fm      show fixup chain of method tables\n");
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
  Bool vFlag;
  Bool fpFlag;
  Bool fdFlag;
  Bool ftFlag;
  Bool fmFlag;
  char *objFileName;
  char name[MAX_STRING];
  unsigned int key;
  unsigned char version;
  unsigned int size;
  char impName[MAX_STRING];
  unsigned int impKey;
  unsigned int tdsize;
  unsigned int *tdescs;
  unsigned int varsize;
  unsigned int strsize;
  unsigned char *strings;
  unsigned int codesize;
  unsigned int *code;
  unsigned int addr;
  unsigned int instr;
  char *src;
  unsigned char ch;
  unsigned int offset;
  unsigned int numEntries;
  unsigned int entry;
  unsigned int ptrRef;
  unsigned int pvrRef;
  unsigned int fixorgP;
  Fixup *fixP;
  Fixup *fixProg;
  unsigned int fixorgD;
  Fixup *fixD;
  Fixup *fixData;
  unsigned int fixorgT;
  Fixup *fixT;
  Fixup *fixType;
  unsigned int fixorgM;
  Fixup *fixM;
  Fixup *fixMeth;
  unsigned int body;
  unsigned int mno;
  unsigned int val;
  unsigned int disp;

  iFlag = FALSE;
  tFlag = FALSE;
  sFlag = FALSE;
  dFlag = FALSE;
  cFlag = FALSE;
  eFlag = FALSE;
  pFlag = FALSE;
  vFlag = FALSE;
  fpFlag = FALSE;
  fdFlag = FALSE;
  ftFlag = FALSE;
  fmFlag = FALSE;
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
      if (strcmp(argv[i], "-v") == 0) {
        vFlag = TRUE;
      } else
      if (strcmp(argv[i], "-fp") == 0) {
        fpFlag = TRUE;
      } else
      if (strcmp(argv[i], "-fd") == 0) {
        fdFlag = TRUE;
      } else
      if (strcmp(argv[i], "-ft") == 0) {
        ftFlag = TRUE;
      } else
      if (strcmp(argv[i], "-fm") == 0) {
        fmFlag = TRUE;
      } else
      if (strcmp(argv[i], "-a") == 0) {
        iFlag = TRUE;
        tFlag = TRUE;
        sFlag = TRUE;
        dFlag = TRUE;
        cFlag = TRUE;
        eFlag = TRUE;
        pFlag = TRUE;
        vFlag = TRUE;
        fpFlag = TRUE;
        fdFlag = TRUE;
        ftFlag = TRUE;
        fmFlag = TRUE;
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
  /*
   * read and interpret file contents
   */
  /* name */
  readStr(name);
  printf("module name\t\t: %s\n", name);
  /* key */
  readInt(&key);
  printf("module key\t\t: 0x%08X\n", key);
  /* version */
  readByte(&version);
  if (version != 0 && version != 1) {
    error("unknown format version 0x%02X", version);
  }
  printf("format version\t\t: 0x%02X (%s)\n", version,
         (version == 0) ? "standalone" : "linkable");
  /* size */
  readInt(&size);
  printf("memory size\t\t: 0x%08X bytes\n", size);
  /* imports */
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
  /* varsize */
  readInt(&varsize);
  printf("variable size\t\t: 0x%08X bytes\n", varsize);
  /* strings */
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
  /* typedesc */
  readInt(&tdsize);
  if ((tdsize & 3) != 0) {
    error("size of type descriptors (0x%08X) is not a multiple of 4",
          tdsize);
  }
  tdsize >>= 2;
  printf("type descriptor size\t: 0x%08X words\n", tdsize);
  if (tdsize != 0) {
    if (tFlag) {
      printf("type descriptors\t: \n");
    } else {
      printf("type descriptors\t: ...\n");
    }
    tdescs = memAlloc(tdsize << 2);
    for (i = 0; i < tdsize; i++) {
      readInt(tdescs + i);
    }
    if (tFlag) {
      bindump((unsigned char *) tdescs, tdsize << 2);
    }
  }
  /* code */
  readInt(&codesize);
  printf("code size\t\t: 0x%08X words\n", codesize);
  if (codesize != 0) {
    code = memAlloc(codesize << 2);
    for (i = 0; i < codesize; i++) {
      readInt(&instr);
      code[i] = instr;
    }
  }
  /* note: the code cannot be displayed yet, fixups are missing */
  /* commands */
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
  /* entries */
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
  /* ptrrefs */
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
  /* pvrrefs */
  readInt(&pvrRef);
  if ((int) pvrRef < 0) {
    printf("procvar refs\t\t: <none>\n");
  } else {
    if (!vFlag) {
      printf("procvar refs\t\t: ...\n");
    }
  }
  while ((int) pvrRef >= 0) {
    if (vFlag) {
      printf("procvar ref\t: 0x%08X\n", pvrRef);
    }
    readInt(&pvrRef);
  }
  if ((int) pvrRef != -1) {
    error("pvrrefs not properly terminated by -1");
  }
  /* fixup chain of code references */
  readInt(&fixorgP);
  printf("fixorgP\t\t\t: 0x%08X\n", fixorgP);
  fixP = NULL;
  addr = fixorgP << 2;
  while (addr != 0) {
    instr = code[addr >> 2];
    mno = (instr >> 22) & MASK(6);
    val = (instr >> 14) & MASK(8);
    disp = instr & MASK(14);
    fixProg = memAlloc(sizeof(Fixup));
    fixProg->addr = addr;
    fixProg->mno = mno;
    fixProg->val = val;
    fixProg->next = fixP;
    fixP = fixProg;
    addr -= disp << 2;
  }
  if (fpFlag) {
    fixProg = fixP;
    while (fixProg != NULL) {
      printf("fixup code @ 0x%08X, ref to code: ", fixProg->addr);
      printf("mno %d / val %d\n", fixProg->mno, fixProg->val);
      fixProg = fixProg->next;
    }
  }
  /* fixup chain of data references */
  readInt(&fixorgD);
  printf("fixorgD\t\t\t: 0x%08X\n", fixorgD);
  fixD = NULL;
  addr = fixorgD << 2;
  while (addr != 0) {
    instr = code[addr >> 2];
    val = (instr >> 26) & MASK(4);
    mno = (instr >> 20) & MASK(6);
    disp = instr & MASK(12);
    fixData = memAlloc(sizeof(Fixup));
    fixData->addr = addr;
    fixData->mno = mno;
    fixData->val = val;
    fixData->next = fixD;
    fixD = fixData;
    addr -= disp << 2;
  }
  if (fdFlag) {
    fixData = fixD;
    while (fixData != NULL) {
      printf("fixup code @ 0x%08X, ref to data: ", fixData->addr);
      printf("mno %d / val %d\n", fixData->mno, fixData->val);
      fixData = fixData->next;
    }
  }
  /* fixup chain of type descriptors */
  readInt(&fixorgT);
  printf("fixorgT\t\t\t: 0x%08X\n", fixorgT);
  fixT = NULL;
  addr = fixorgT << 2;
  while (addr != 0) {
    instr = tdescs[addr >> 2];
    mno = (instr >> 24) & MASK(6);
    val = (instr >> 12) & MASK(12);
    disp = instr & MASK(12);
    fixType = memAlloc(sizeof(Fixup));
    fixType->addr = addr;
    fixType->mno = mno;
    fixType->val = val;
    fixType->next = fixT;
    fixT = fixType;
    addr -= disp << 2;
  }
  if (ftFlag) {
    fixType = fixT;
    while (fixType != NULL) {
      printf("fixup type @ 0x%08X: ", fixType->addr);
      printf("mno %d / val %d\n", fixType->mno, fixType->val);
      fixType = fixType->next;
    }
  }
  /* fixup chain of method tables */
  readInt(&fixorgM);
  printf("fixorgM\t\t\t: 0x%08X\n", fixorgM);
  fixM = NULL;
  addr = fixorgM << 2;
  while (addr != 0) {
    instr = tdescs[addr >> 2];
    mno = (instr >> 26) & MASK(6);
    val = (instr >> 10) & MASK(16);
    disp = instr & MASK(10);
    fixMeth = memAlloc(sizeof(Fixup));
    fixMeth->addr = addr;
    fixMeth->mno = mno;
    fixMeth->val = val;
    fixMeth->next = fixM;
    fixM = fixMeth;
    addr -= disp << 2;
  }
  if (fmFlag) {
    fixMeth = fixM;
    while (fixMeth != NULL) {
      printf("fixup method @ 0x%08X: ", fixMeth->addr);
      printf("mno %d / val %d\n", fixMeth->mno, fixMeth->val);
      fixMeth = fixMeth->next;
    }
  }
  /* body */
  readInt(&body);
  printf("body\t\t\t: 0x%08X\n", body);
  /* now display the code */
  if (codesize != 0) {
    if (dFlag) {
      printf("code\t\t\t: \n");
      addr = 0;
      fixProg = fixP;
      fixData = fixD;
      for (i = 0; i < codesize; i++) {
        if (fixProg != NULL && addr == fixProg->addr) {
          /* disassemble with prog fixup */
          instr = code[i];
          src = disasmFixProg(instr, addr, fixProg);
          printf("%08X:  %08X    %s\n", addr, instr, src);
          addr += 4;
          fixProg = fixProg->next;
        } else
        if (fixData != NULL && addr == fixData->addr) {
          /* disassemble with data fixup */
          instr = code[i];
          src = disasmFixData1(instr, addr, fixData);
          printf("%08X:  %08X    %s\n", addr, instr, src);
          addr += 4;
          i++;
          instr = code[i];
          src = disasmFixData2(instr, addr, fixData);
          printf("%08X:  %08X    %s\n", addr, instr, src);
          addr += 4;
          fixData = fixData->next;
        } else {
          /* disassemble without any fixup */
          instr = code[i];
          src = disasm(instr, addr);
          printf("%08X:  %08X    %s\n", addr, instr, src);
          addr += 4;
        }
      }
    } else {
      printf("code\t\t\t: ...\n");
    }
  }
  /* "O" */
  readByte(&ch);
  if (ch != 'O') {
    error("missing 'O' at end of object file");
  }
  printf("object file correctly read\n");
  fclose(objFile);
  return 0;
}
