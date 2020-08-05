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

#include "common.h"
#include "instr.h"
#include "disasm.h"


#define MAX_STRING	100


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


void readByte(Byte *p) {
  int c;

  c = fgetc(objFile);
  if (c == EOF) {
    error("unexpected EOF");
  }
  *p = (Byte) c;
}


void readInt(Word *p) {
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


void bindump(Byte *bytes, Word nbytes) {
  Word addr, count;
  Word lo, hi, curr;
  int lines, i, j;
  Word tmp;
  Byte c;

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
  Word key;
  Byte version;
  Word size;
  char impName[MAX_STRING];
  Word impKey;
  Word tdsize;
  Word *tdescs;
  Word varsize;
  Word strsize;
  Byte *strings;
  Word codesize;
  Word *code;
  Word addr;
  Word instr;
  char *src;
  Byte ch;
  Word offset;
  Word numEntries;
  Word entry;
  Word ptrRef;
  Word pvrRef;
  Word fixorgP;
  Fixup *fixP;
  Fixup *fixProg;
  Word fixorgD;
  Fixup *fixD;
  Fixup *fixData;
  Word fixorgT;
  Fixup *fixT;
  Fixup *fixType;
  Word fixorgM;
  Fixup *fixM;
  Fixup *fixMeth;
  Word body;
  Word high;
  Word mno;
  Word val1;
  Word val2;
  Word disp;

  iFlag = false;
  tFlag = false;
  sFlag = false;
  dFlag = false;
  cFlag = false;
  eFlag = false;
  pFlag = false;
  vFlag = false;
  fpFlag = false;
  fdFlag = false;
  ftFlag = false;
  fmFlag = false;
  objFileName = NULL;
  for (i = 1; i < argc; i++) {
    optptr = argv[i];
    if (*optptr == '-') {
      /* option */
      if (strcmp(argv[i], "-i") == 0) {
        iFlag = true;
      } else
      if (strcmp(argv[i], "-t") == 0) {
        tFlag = true;
      } else
      if (strcmp(argv[i], "-s") == 0) {
        sFlag = true;
      } else
      if (strcmp(argv[i], "-d") == 0) {
        dFlag = true;
      } else
      if (strcmp(argv[i], "-c") == 0) {
        cFlag = true;
      } else
      if (strcmp(argv[i], "-e") == 0) {
        eFlag = true;
      } else
      if (strcmp(argv[i], "-p") == 0) {
        pFlag = true;
      } else
      if (strcmp(argv[i], "-v") == 0) {
        vFlag = true;
      } else
      if (strcmp(argv[i], "-fp") == 0) {
        fpFlag = true;
      } else
      if (strcmp(argv[i], "-fd") == 0) {
        fdFlag = true;
      } else
      if (strcmp(argv[i], "-ft") == 0) {
        ftFlag = true;
      } else
      if (strcmp(argv[i], "-fm") == 0) {
        fmFlag = true;
      } else
      if (strcmp(argv[i], "-a") == 0) {
        iFlag = true;
        tFlag = true;
        sFlag = true;
        dFlag = true;
        cFlag = true;
        eFlag = true;
        pFlag = true;
        vFlag = true;
        fpFlag = true;
        fdFlag = true;
        ftFlag = true;
        fmFlag = true;
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
  initInstrTable();
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
    tdescs = memAlloc(tdsize << 2);
    for (i = 0; i < tdsize; i++) {
      readInt(tdescs + i);
    }
  }
  /* note: the type descriptors cannot be displayed yet, fixups are missing */
  /* code */
  readInt(&codesize);
  printf("code size\t\t: 0x%08X words\n", codesize);
  if (codesize != 0) {
    code = memAlloc(codesize << 2);
    for (i = 0; i < codesize; i++) {
      readInt(code + i);
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
  /* fixup chain of instrs calling external code */
  readInt(&fixorgP);
  printf("fixorgP\t\t\t: 0x%08X\n", fixorgP);
  fixP = NULL;
  addr = fixorgP << 2;
  while (addr != 0) {
    instr = code[addr >> 2];
    high = (instr >> 28) & MASK(4);
    mno = (instr >> 22) & MASK(6);
    val1 = (instr >> 14) & MASK(8);
    disp = (instr >> 0) & MASK(14);
    fixProg = memAlloc(sizeof(Fixup));
    fixProg->addr = addr;
    fixProg->high = high;
    fixProg->mno = mno;
    fixProg->val1 = val1;
    fixProg->val2 = 0;  /* not used */
    fixProg->next = fixP;
    fixP = fixProg;
    addr -= disp << 2;
  }
  if (fpFlag) {
    fixProg = fixP;
    while (fixProg != NULL) {
      printf("fixup code @ 0x%08X\t: ",
             fixProg->addr);
      printf("high %d / mno %d / val1 %d\n",
             fixProg->high, fixProg->mno, fixProg->val1);
      fixProg = fixProg->next;
    }
  }
  /* fixup chain of instrs referencing global or external code or data */
  readInt(&fixorgD);
  printf("fixorgD\t\t\t: 0x%08X\n", fixorgD);
  fixD = NULL;
  addr = fixorgD << 2;
  while (addr != 0) {
    instr = code[addr >> 2];
    high = (instr >> 30) & MASK(2);
    val1 = (instr >> 26) & MASK(4);
    mno = (instr >> 20) & MASK(6);
    val2 = (instr >> 12) & MASK(8);
    disp = (instr >> 0) & MASK(12);
    fixData = memAlloc(sizeof(Fixup));
    fixData->addr = addr;
    fixData->high = high;
    fixData->mno = mno;
    fixData->val1 = val1;
    fixData->val2 = val2;
    fixData->next = fixD;
    fixD = fixData;
    addr -= disp << 2;
  }
  if (fdFlag) {
    fixData = fixD;
    while (fixData != NULL) {
      printf("fixup code @ 0x%08X\t: ",
             fixData->addr);
      printf("high %d / mno %d / val1 %d / val2 %d\n",
             fixData->high, fixData->mno, fixData->val1, fixData->val2);
      fixData = fixData->next;
    }
  }
  /* fixup chain of type descriptors pointing to global or external data */
  readInt(&fixorgT);
  printf("fixorgT\t\t\t: 0x%08X\n", fixorgT);
  fixT = NULL;
  addr = fixorgT << 2;
  while (addr != 0) {
    instr = tdescs[addr >> 2];
    high = (instr >> 30) & MASK(2);
    mno = (instr >> 24) & MASK(6);
    val1 = (instr >> 12) & MASK(12);
    disp = (instr >> 0) & MASK(12);
    fixType = memAlloc(sizeof(Fixup));
    fixType->addr = addr;
    fixType->high = high;
    fixType->mno = mno;
    fixType->val1 = val1;
    fixType->val2 = 0;  /* not used */
    fixType->next = fixT;
    fixT = fixType;
    addr -= disp << 2;
  }
  if (ftFlag) {
    fixType = fixT;
    while (fixType != NULL) {
      printf("fixup tdsc @ 0x%08X\t: ",
             fixType->addr);
      printf("high %d / mno %d / val1 %d\n",
             fixType->high, fixType->mno, fixType->val1);
      fixType = fixType->next;
    }
  }
  /* fixup chain of type descriptors pointing to global or external code */
  readInt(&fixorgM);
  printf("fixorgM\t\t\t: 0x%08X\n", fixorgM);
  fixM = NULL;
  addr = fixorgM << 2;
  while (addr != 0) {
    instr = tdescs[addr >> 2];
    mno = (instr >> 26) & MASK(6);
    val1 = (instr >> 10) & MASK(16);
    disp = (instr >> 0) & MASK(10);
    fixMeth = memAlloc(sizeof(Fixup));
    fixMeth->addr = addr;
    fixMeth->high = 0;  /* not used */
    fixMeth->mno = mno;
    fixMeth->val1 = val1;
    fixMeth->val2 = 0;  /* not used */
    fixMeth->next = fixM;
    fixM = fixMeth;
    addr -= disp << 2;
  }
  if (fmFlag) {
    fixMeth = fixM;
    while (fixMeth != NULL) {
      printf("fixup tdsc @ 0x%08X\t: ",
             fixMeth->addr);
      printf("mno %d / val1 %d\n",
             fixMeth->mno, fixMeth->val1);
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
  /* now display the type descriptors */
  if (tdsize != 0) {
    if (tFlag) {
      printf("type descriptors\t: \n");
      bindump((Byte *) tdescs, tdsize << 2);
    } else {
      printf("type descriptors\t: ...\n");
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
