/*
 * asm.c -- RISC5 assembler
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <ctype.h>


/**************************************************************/


#define LINE_SIZE	200

#define TOK_EOL		0
#define TOK_LABEL	1
#define TOK_IDENT	2
#define TOK_STRING	3
#define TOK_NUMBER	4
#define TOK_REGISTER	5
#define TOK_COMMA	6


/**************************************************************/


#define OP_		0

#define OP_MOV		0x00000000

#define OP_ADD		0x00080000
#define OP_SUB		0x00090000
#define OP_MUL		0x000A0000
#define OP_DIV		0x000B0000
#define OP_FAD		0x000C0000
#define OP_FSB		0x000D0000
#define OP_FML		0x000E0000
#define OP_FDV		0x000F0000
#define OP_AND		0x00040000
#define OP_ANN		0x00050000
#define OP_IOR		0x00060000
#define OP_XOR		0x00070000
#define OP_LSL		0x00010000
#define OP_ASR		0x00020000
#define OP_ROR		0x00030000

#define OP_B		0xC7000000
#define OP_BCC		0xCA000000
#define OP_BCS		0xC2000000
#define OP_BEQ		0xC1000000
#define OP_BGE		0xCD000000
#define OP_BGT		0xCE000000
#define OP_BHI		0xCC000000
#define OP_BLE		0xC6000000
#define OP_BLS		0xC4000000
#define OP_BLT		0xC5000000
#define OP_BMI		0xC0000000
#define OP_BNE		0xC9000000
#define OP_BNVR		0xCF000000
#define OP_BPL		0xC8000000
#define OP_BVC		0xCB000000
#define OP_BVS		0xC3000000

#define OP_C		0xD7000000
#define OP_CCC		0xDA000000
#define OP_CCS		0xD2000000
#define OP_CEQ		0xD1000000
#define OP_CGE		0xDD000000
#define OP_CGT		0xDE000000
#define OP_CHI		0xDC000000
#define OP_CLE		0xD6000000
#define OP_CLS		0xD4000000
#define OP_CLT		0xD5000000
#define OP_CMI		0xD0000000
#define OP_CNE		0xD9000000
#define OP_CNVR		0xDF000000
#define OP_CPL		0xD8000000
#define OP_CVC		0xDB000000
#define OP_CVS		0xD3000000

#define OP_LDW		0x80000000
#define OP_LDB		0x90000000
#define OP_STW		0xA0000000
#define OP_STB		0xB0000000

#define OP_CLI		0xCF000020
#define OP_STI		0xCF000021
#define OP_RTI		0xC7000010


/**************************************************************/


typedef enum { false, true } Bool;


/**************************************************************/


Bool debugToken = false;

FILE *inFile;
FILE *outFile;

char line[LINE_SIZE];
char *lineptr;
int lineno;

int token;
char tokenvalString[LINE_SIZE];
int tokenvalNumber;

unsigned int currAddr = 0;


/**************************************************************/


void error(char *fmt, ...) {
  va_list ap;

  va_start(ap, fmt);
  fprintf(stderr, "Error: ");
  vfprintf(stderr, fmt, ap);
  fprintf(stderr, "\n");
  va_end(ap);
  exit(1);
}


void *allocMem(unsigned int size) {
  void *p;

  p = malloc(size);
  if (p == NULL) {
    error("out of memory");
  }
  return p;
}


void freeMem(void *p) {
  free(p);
}


/**************************************************************/


#define MAX_CODE_INIT		256
#define MAX_CODE_MULT		4


unsigned char *codeArray = NULL;	/* the code proper */
unsigned int codeSize = 0;		/* the current code size */

static unsigned int codeMaxSize = 0;	/* the code array's current size */


void growCodeArray(void) {
  unsigned int newMaxSize;
  unsigned char *newCodeArray;
  unsigned int i;

  if (codeMaxSize == 0) {
    /* first allocation */
    newMaxSize = MAX_CODE_INIT;
  } else {
    /* subsequent allocation */
    newMaxSize = codeMaxSize * MAX_CODE_MULT;
  }
  newCodeArray = allocMem(newMaxSize);
  for (i = 0; i < codeSize; i++) {
    newCodeArray[i] = codeArray[i];
  }
  if (codeArray != NULL) {
    freeMem(codeArray);
  }
  codeArray = newCodeArray;
  codeMaxSize = newMaxSize;
}


void emitWord(unsigned int data) {
  if (codeSize + 4 > codeMaxSize) {
    growCodeArray();
  }
  *(unsigned int *)(codeArray + codeSize) = data;
  codeSize += 4;
  currAddr += 4;
}


void emitByte(unsigned char data) {
  if (codeSize + 1 > codeMaxSize) {
    growCodeArray();
  }
  *(unsigned char *)(codeArray + codeSize) = data;
  codeSize++;
  currAddr++;
}


void writeCode(void) {
  unsigned int data;
  unsigned int i;

  while (currAddr & 3) {
    emitByte(0);
  }
  for (i = 0; i < codeSize; i += 4) {
    data = *(unsigned int *)(codeArray + i);
    fprintf(outFile, "%08X\n", data);
  }
}


/**************************************************************/


Bool isReg(char *str) {
  int num;

  if (*str != 'R') {
    return false;
  }
  num = 0;
  str++;
  do {
    if (!isdigit(*str)) {
      return false;
    }
    num *= 10;
    num += (*str - '0');
    str++;
  } while (*str != '\0');
  if (num < 0 || num > 15) {
    error("register number out of bounds in line %d", lineno);
  }
  tokenvalNumber = num;
  return true;
}


int getNextToken(void) {
  char *p;
  int base;
  int digit;
  Bool negate;

  while (*lineptr == ' ' || *lineptr == '\t') {
    lineptr++;
  }
  if (*lineptr == '\n' || *lineptr == '\0' ||
      (lineptr[0] == '/' && lineptr[1] == '/')) {
    return TOK_EOL;
  }
  if (isalpha((int) *lineptr) || *lineptr == '_' || *lineptr == '.') {
    p = tokenvalString;
    while (isalnum((int) *lineptr) || *lineptr == '_' || *lineptr == '.') {
      *p++ = *lineptr++;
    }
    *p = '\0';
    if (*lineptr == ':') {
      lineptr++;
      return TOK_LABEL;
    } else {
      if (isReg(tokenvalString)) {
        return TOK_REGISTER;
      } else {
        return TOK_IDENT;
      }
    }
  }
  if (isdigit((int) *lineptr) || *lineptr == '+' || *lineptr == '-') {
    negate = false;
    if (*lineptr == '+') {
      lineptr++;
    } else
    if (*lineptr == '-') {
      negate = true;
      lineptr++;
    }
    base = 10;
    tokenvalNumber = 0;
    if (*lineptr == '0') {
      lineptr++;
      if (*lineptr == 'x' || *lineptr == 'X') {
        base = 16;
        lineptr++;
      } else
      if (isdigit((int) *lineptr)) {
        base = 8;
      } else {
        if (negate) {
          tokenvalNumber = -tokenvalNumber;
        }
        return TOK_NUMBER;
      }
    }
    while (isxdigit((int) *lineptr)) {
      digit = *lineptr++ - '0';
      if (digit >= 'A' - '0') {
        if (digit >= 'a' - '0') {
          digit += '0' - 'a' + 10;
        } else {
          digit += '0' - 'A' + 10;
        }
      }
      if (digit >= base) {
        error("illegal digit value %d in line %d", digit, lineno);
      }
      tokenvalNumber *= base;
      tokenvalNumber += digit;
    }
    if (negate) {
      tokenvalNumber = -tokenvalNumber;
    }
    return TOK_NUMBER;
  }
  if (*lineptr == '\'') {
    lineptr++;
    if (!isprint((int) *lineptr)) {
      error("cannot quote character 0x%02X in line %d", *lineptr, lineno);
    }
    tokenvalNumber = *lineptr;
    lineptr++;
    if (*lineptr != '\'') {
      error("unbalanced quote in line %d", lineno);
    }
    lineptr++;
    return TOK_NUMBER;
  }
  if (*lineptr == '\"') {
    lineptr++;
    p = tokenvalString;
    while (1) {
      if (*lineptr == '\n' || *lineptr == '\0') {
        error("unterminated string constant in line %d", lineno);
      }
      if (!isprint((int) *lineptr)) {
        error("string contains illegal character 0x%02X in line %d",
              *lineptr, lineno);
      }
      if (*lineptr == '\"') {
        break;
      }
      *p++ = *lineptr++;
    }
    lineptr++;
    *p = '\0';
    return TOK_STRING;
  }
  switch (*lineptr) {
    case ',':
      lineptr++;
      return TOK_COMMA;
  }
  /* no match */
  error("illegal character 0x%02X in line %d", *lineptr, lineno);
  /* not reached */
  return 0;
}


void showToken(void) {
  printf("DEBUG: ");
  switch (token) {
    case TOK_EOL:
      printf("token = TOK_EOL\n");
      break;
    case TOK_LABEL:
      printf("token = TOK_LABEL, value = '%s'\n", tokenvalString);
      break;
    case TOK_IDENT:
      printf("token = TOK_IDENT, value = '%s'\n", tokenvalString);
      break;
    case TOK_STRING:
      printf("token = TOK_STRING, value = '%s'\n", tokenvalString);
      break;
    case TOK_NUMBER:
      printf("token = TOK_NUMBER, value = 0x%08X\n", tokenvalNumber);
      break;
    case TOK_REGISTER:
      printf("token = TOK_REGISTER, value = %d\n", tokenvalNumber);
      break;
    case TOK_COMMA:
      printf("token = TOK_COMMA\n");
      break;
    default:
      error("illegal token %d in showToken()", token);
  }
}


void getToken(void) {
  token = getNextToken();
  if (debugToken) {
    showToken();
  }
}


/**************************************************************/


void format_(unsigned int code) {
}


void format_4(unsigned int code) {
  int reg1;
  int reg2;
  unsigned int imm;

  if (token != TOK_REGISTER) {
    error("missing register in line %d", lineno);
  }
  reg1 = tokenvalNumber;
  getToken();
  if (token != TOK_COMMA) {
    error("comma expected in line %d", lineno);
  }
  getToken();
  if (token == TOK_REGISTER) {
    reg2 = tokenvalNumber;
    getToken();
    emitWord(code | (reg1 << 24) | reg2);
  } else
  if (token == TOK_NUMBER) {
    imm = tokenvalNumber;
    getToken();
    if ((imm >> 16) == 0x0000) {
      emitWord(code | (4 << 28) | (reg1 << 24) | (imm & 0x0000FFFF));
    } else
    if ((imm >> 16) == 0xFFFF) {
      emitWord(code | (5 << 28) | (reg1 << 24) | (imm & 0x0000FFFF));
    } else {
      error("illegal immediate value in line %d", lineno);
    }
  } else {
    error("missing register or immediate value in line %d", lineno);
  }
}


void format_3(unsigned int code) {
  int reg1;
  int reg2;
  int reg3;
  unsigned int imm;

  if (token != TOK_REGISTER) {
    error("missing register in line %d", lineno);
  }
  reg1 = tokenvalNumber;
  getToken();
  if (token != TOK_COMMA) {
    error("comma expected in line %d", lineno);
  }
  getToken();
  if (token != TOK_REGISTER) {
    error("missing second register in line %d", lineno);
  }
  reg2 = tokenvalNumber;
  getToken();
  if (token != TOK_COMMA) {
    error("comma expected in line %d", lineno);
  }
  getToken();
  if (token == TOK_REGISTER) {
    reg3 = tokenvalNumber;
    getToken();
    emitWord(code | (reg1 << 24) | (reg2 << 20) | reg3);
  } else
  if (token == TOK_NUMBER) {
    imm = tokenvalNumber;
    getToken();
    if ((imm >> 16) == 0x0000) {
      emitWord(code | (4 << 28) | (reg1 << 24) |
               (reg2 << 20) | (imm & 0x0000FFFF));
    } else
    if ((imm >> 16) == 0xFFFF) {
      emitWord(code | (5 << 28) | (reg1 << 24) |
               (reg2 << 20) | (imm & 0x0000FFFF));
    } else {
      error("illegal immediate value in line %d", lineno);
    }
  } else {
    error("missing register or immediate value in line %d", lineno);
  }
}


void format_2(unsigned int code) {
  int reg;
  int target;
  int offset;

  if (token == TOK_REGISTER) {
    reg = tokenvalNumber;
    getToken();
    emitWord(code | reg);
  } else
  if (token == TOK_NUMBER) {
    target = tokenvalNumber;
    getToken();
    offset = (target - currAddr - 4) / 4;
    /* target is never out of reach */
    emitWord(code | (1 << 29) | (offset & 0x003FFFFF));
  } else {
    error("missing register or target address in line %d", lineno);
  }
}


void format_1(unsigned int code) {
  int reg1;
  int reg2;
  int offset;

  if (token != TOK_REGISTER) {
    error("missing register in line %d", lineno);
  }
  reg1 = tokenvalNumber;
  getToken();
  if (token != TOK_COMMA) {
    error("comma expected in line %d", lineno);
  }
  getToken();
  if (token != TOK_REGISTER) {
    error("missing second register in line %d", lineno);
  }
  reg2 = tokenvalNumber;
  getToken();
  if (token != TOK_COMMA) {
    error("comma expected in line %d", lineno);
  }
  getToken();
  if (token != TOK_NUMBER) {
    error("missing offset in line %d", lineno);
  }
  offset = tokenvalNumber;
  getToken();
  if (offset < -(1 << 19) || offset >= (1 << 19)) {
    error("offset out of bounds in line %d", lineno);
  }
  emitWord(code | (reg1 << 24) | (reg2 << 20) | (offset & 0x000FFFFF));
}


void format_0(unsigned int code) {
  emitWord(code);
}


void dotWord(unsigned int code) {
}


void dotByte(unsigned int code) {
}


void dotSet(unsigned int code) {
}


void dotLoc(unsigned int code) {
}


void dotSpace(unsigned int code) {
}


void dotAlign(unsigned int code) {
  while (currAddr & 3) {
    emitByte(0);
  }
}


/**************************************************************/


typedef struct {
  char *name;
  void (*func)(unsigned int code);
  unsigned int code;
} Instr;


Instr instrTable[] = {
  /* register data move */
  { "MOV",    format_4, OP_MOV	},
  { "MOVH",   format_, OP_	},
  { "GETF",   format_, OP_	},
  { "GETH",   format_, OP_	},
  /* integer arithmetic */
  { "ADD",    format_3, OP_ADD	},
  { "ADDC",   format_, OP_	},
  { "SUB",    format_3, OP_SUB	},
  { "SUBB",   format_, OP_	},
  { "MUL",    format_3, OP_MUL	},
  { "MULU",   format_, OP_	},
  { "DIV",    format_3, OP_DIV	},
  { "DIVU",   format_, OP_	},
  /* floating-point arithmetic */
  { "FAD",    format_3, OP_FAD	},
  { "FSB",    format_3, OP_FSB	},
  { "FML",    format_3, OP_FML	},
  { "FDV",    format_3, OP_FDV	},
  { "FLR",    format_, OP_	},
  { "FLT",    format_, OP_	},
  /* logic */
  { "AND",    format_3, OP_AND	},
  { "ANN",    format_3, OP_ANN	},
  { "IOR",    format_3, OP_IOR	},
  { "XOR",    format_3, OP_XOR	},
  /* shift */
  { "LSL",    format_3, OP_LSL	},
  { "ASR",    format_3, OP_ASR	},
  { "ROR",    format_3, OP_ROR	},
  /* branch */
  { "B",      format_2, OP_B	},
  { "BCC",    format_2, OP_BCC	},
  { "BCS",    format_2, OP_BCS	},
  { "BEQ",    format_2, OP_BEQ	},
  { "BGE",    format_2, OP_BGE	},
  { "BGT",    format_2, OP_BGT	},
  { "BHI",    format_2, OP_BHI	},
  { "BLE",    format_2, OP_BLE	},
  { "BLS",    format_2, OP_BLS	},
  { "BLT",    format_2, OP_BLT	},
  { "BMI",    format_2, OP_BMI	},
  { "BNE",    format_2, OP_BNE	},
  { "BNVR",   format_2, OP_BNVR	},
  { "BPL",    format_2, OP_BPL	},
  { "BVC",    format_2, OP_BVC	},
  { "BVS",    format_2, OP_BVS	},
  /* call */
  { "C",      format_2, OP_C	},
  { "CCC",    format_2, OP_CCC	},
  { "CCS",    format_2, OP_CCS	},
  { "CEQ",    format_2, OP_CEQ	},
  { "CGE",    format_2, OP_CGE	},
  { "CGT",    format_2, OP_CGT	},
  { "CHI",    format_2, OP_CHI	},
  { "CLE",    format_2, OP_CLE	},
  { "CLS",    format_2, OP_CLS	},
  { "CLT",    format_2, OP_CLT	},
  { "CMI",    format_2, OP_CMI	},
  { "CNE",    format_2, OP_CNE	},
  { "CNVR",   format_2, OP_CNVR	},
  { "CPL",    format_2, OP_CPL	},
  { "CVC",    format_2, OP_CVC	},
  { "CVS",    format_2, OP_CVS	},
  /* load/store memory */
  { "LDW",    format_1, OP_LDW	},
  { "LDB",    format_1, OP_LDB	},
  { "STW",    format_1, OP_STW	},
  { "STB",    format_1, OP_STB	},
  /* interrupt control */
  { "CLI",    format_0, OP_CLI	},
  { "STI",    format_0, OP_STI	},
  { "RTI",    format_0, OP_RTI	},
  /* assembler directives */
  { ".WORD",  dotWord,  0	},
  { ".BYTE",  dotByte,  0	},
  { ".SET",   dotSet,   0	},
  { ".LOC",   dotLoc,   0	},
  { ".SPACE", dotSpace, 0	},
  { ".ALIGN", dotAlign, 0	},
};


static int cmpInstr(const void *instr1, const void *instr2) {
  return strcmp(((Instr *) instr1)->name, ((Instr *) instr2)->name);
}


void sortInstrTable(void) {
  qsort(instrTable, sizeof(instrTable)/sizeof(instrTable[0]),
        sizeof(instrTable[0]), cmpInstr);
}


Instr *lookupInstr(char *name) {
  int lo, hi, tst;
  int res;

  lo = 0;
  hi = sizeof(instrTable) / sizeof(instrTable[0]) - 1;
  while (lo <= hi) {
    tst = (lo + hi) / 2;
    res = strcmp(instrTable[tst].name, name);
    if (res == 0) {
      return &instrTable[tst];
    }
    if (res < 0) {
      lo = tst + 1;
    } else {
      hi = tst - 1;
    }
  }
  return NULL;
}


/**************************************************************/


void assemble(void) {
  Instr *instr;

  lineno = 0;
  while (fgets(line, LINE_SIZE, inFile) != NULL) {
    lineno++;
    lineptr = line;
    getToken();
    while (token == TOK_LABEL) {
      getToken();
    }
    if (token == TOK_IDENT) {
      instr = lookupInstr(tokenvalString);
      if (instr == NULL) {
        error("unknown instruction '%s' in line %d",
              tokenvalString, lineno);
      }
      getToken();
      (*instr->func)(instr->code);
    }
    if (token != TOK_EOL) {
      error("garbage in line %d", lineno);
    }
  }
  writeCode();
}


/**************************************************************/


void usage(char *myself) {
  fprintf(stderr, "Usage: %s <input file> <output file>\n", myself);
  exit(1);
}


int main(int argc, char *argv[]) {
  char *inName;
  char *outName;

  sortInstrTable();
  if (argc != 3) {
    usage(argv[0]);
  }
  inName = argv[1];
  outName = argv[2];
  inFile = fopen(inName, "r");
  if (inFile == NULL) {
    error("cannot open input file '%s'", inName);
  }
  outFile = fopen(outName, "w");
  if (outFile == NULL) {
    error("cannot open output file '%s'", outName);
  }
  assemble();
  fclose(inFile);
  fclose(outFile);
  return 0;
}
