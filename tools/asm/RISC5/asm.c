/*
 * asm.c -- RISC5 assembler
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <ctype.h>


/**************************************************************/

/* constant definitions */


#define LINE_SIZE	200


#define TOK_EOL		0
#define TOK_LABEL	1
#define TOK_IDENT	2
#define TOK_STRING	3
#define TOK_NUMBER	4
#define TOK_REGISTER	5
#define TOK_COMMA	6


#define OP_MOV		0x00000000
#define OP_MOVH		0x20000000
#define OP_GETH		0x20000000
#define OP_GETF		0x30000000

#define OP_LSL		0x00010000
#define OP_ASR		0x00020000
#define OP_ROR		0x00030000
#define OP_AND		0x00040000
#define OP_ANN		0x00050000
#define OP_IOR		0x00060000
#define OP_XOR		0x00070000
#define OP_ADD		0x00080000
#define OP_ADDC		0x20080000
#define OP_SUB		0x00090000
#define OP_SUBB		0x20090000
#define OP_MUL		0x000A0000
#define OP_MULU		0x200A0000
#define OP_DIV		0x000B0000
#define OP_DIVU		0x200B0000
#define OP_FAD		0x000C0000
#define OP_FSB		0x000D0000
#define OP_FML		0x000E0000
#define OP_FDV		0x000F0000
#define OP_FLR		0x100C0000
#define OP_FLT		0x200C0000

#define OP_LDW		0x80000000
#define OP_LDB		0x90000000
#define OP_STW		0xA0000000
#define OP_STB		0xB0000000

#define OP_BMI		0xC0000000
#define OP_BEQ		0xC1000000
#define OP_BCS		0xC2000000
#define OP_BVS		0xC3000000
#define OP_BLS		0xC4000000
#define OP_BLT		0xC5000000
#define OP_BLE		0xC6000000
#define OP_B		0xC7000000
#define OP_BPL		0xC8000000
#define OP_BNE		0xC9000000
#define OP_BCC		0xCA000000
#define OP_BVC		0xCB000000
#define OP_BHI		0xCC000000
#define OP_BGE		0xCD000000
#define OP_BGT		0xCE000000
#define OP_BNVR		0xCF000000

#define OP_CMI		0xD0000000
#define OP_CEQ		0xD1000000
#define OP_CCS		0xD2000000
#define OP_CVS		0xD3000000
#define OP_CLS		0xD4000000
#define OP_CLT		0xD5000000
#define OP_CLE		0xD6000000
#define OP_C		0xD7000000
#define OP_CPL		0xD8000000
#define OP_CNE		0xD9000000
#define OP_CCC		0xDA000000
#define OP_CVC		0xDB000000
#define OP_CHI		0xDC000000
#define OP_CGE		0xDD000000
#define OP_CGT		0xDE000000
#define OP_CNVR		0xDF000000

#define OP_RTI		0xC7000010
#define OP_CLI		0xCF000020
#define OP_STI		0xCF000021


#define FIXUP_ILLEGAL	0
#define FIXUP_IMMEDIATE	1
#define FIXUP_TARGET	2
#define FIXUP_OFFSET	3
#define FIXUP_WORD	4
#define FIXUP_BYTE	5


/**************************************************************/

/* type definitions */


typedef enum { false, true } Bool;


typedef struct symbol {
  char *name;			/* name of symbol */
  Bool isDefined;		/* is the symbol defined? */
  unsigned int value;		/* the symbol's value, if defined */
  struct symbol *left;		/* left son in binary search tree */
  struct symbol *right;		/* right son in binary search tree */
} Symbol;


typedef struct fixup {
  unsigned int codeOffset;	/* at which code offset */
  Symbol *symbol;		/* where to get the value from */
  int fixupMethod;		/* what fixup method to use */
  unsigned int locus;		/* address of instruction to be patched */
  struct fixup *next;		/* next fixup in list */
} Fixup;


/**************************************************************/

/* global variables */


Bool debugToken = false;
Bool debugFixup = false;

FILE *inFile;
FILE *outFile;

char line[LINE_SIZE];
char *lineptr;
int lineno;

int token;
char tokenvalString[LINE_SIZE];
int tokenvalNumber;

unsigned int currAddr = 0;

Symbol *symbolTable = NULL;

Fixup *fixupList = NULL;


/**************************************************************/

/* error and memory handling */


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

/* code emitter */


#define MAX_CODE_INIT		256
#define MAX_CODE_MULT		4


unsigned char *codeArray = NULL;	/* the code proper */
unsigned int codeSize = 0;		/* the current code size */

unsigned int codeMaxSize = 0;		/* the code array's current size */


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


unsigned int getWord(unsigned int offset) {
  return *(unsigned int *)(codeArray + offset);
}


void putWord(unsigned int offset, unsigned int data) {
  *(unsigned int *)(codeArray + offset) = data;
}


void putByte(unsigned int offset, unsigned char data) {
  *(unsigned char *)(codeArray + offset) = data;
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

/* symbol table */


Symbol *newSymbol(char *name) {
  Symbol *p;

  p = allocMem(sizeof(Symbol));
  p->name = allocMem(strlen(name) + 1);
  strcpy(p->name, name);
  p->isDefined = false;
  p->value = 0;
  p->left = NULL;
  p->right = NULL;
  return p;
}


Symbol *lookupEnter(char *name) {
  Symbol *p, *q, *r;
  int cmp;

  p = symbolTable;
  if (p == NULL) {
    /* the very first symbol */
    r = newSymbol(name);
    symbolTable = r;
    return r;
  }
  /* try to look up symbol in binary search tree */
  while (1) {
    q = p;
    cmp = strcmp(name, q->name);
    if (cmp == 0) {
      /* found */
      return q;
    }
    if (cmp < 0) {
      p = q->left;
    } else {
      p = q->right;
    }
    if (p == NULL) {
      /* symbol is not in tree, enter */
      r = newSymbol(name);
      if (cmp < 0) {
        q->left = r;
      } else {
        q->right = r;
      }
      return r;
    }
  }
  /* never reached */
  return NULL;
}


/**************************************************************/

/* backpatching */


void addFixup(unsigned int codeOffset, Symbol *symbol,
              int fixupMethod, unsigned int locus) {
  Fixup *fixup;

  fixup = allocMem(sizeof(Fixup));
  fixup->codeOffset = codeOffset;
  fixup->symbol = symbol;
  fixup->fixupMethod = fixupMethod;
  fixup->locus = locus;
  fixup->next = fixupList;
  fixupList = fixup;
}


void fixupSingle(unsigned int codeOffset, Symbol *symbol,
                 int fixupMethod, unsigned int locus) {
  unsigned int value;
  unsigned int mask;
  unsigned int instr;
  unsigned int imm;
  int target;
  int offset;

  if (debugFixup) {
    printf("FIXUP: code offset 0x%08X, symbol name '%s',\n"
           "       fixup method %d, locus 0x%08X\n",
           codeOffset, symbol->name, fixupMethod, locus);
  }
  if (!symbol->isDefined) {
    error("undefined symbol '%s'", symbol->name);
  }
  value = symbol->value;
  switch (fixupMethod) {
    case FIXUP_IMMEDIATE:
      imm = value;
      instr = getWord(codeOffset);
      if ((imm >> 16) == 0x0000) {
        instr &= ~(1 << 28);
      } else
      if ((imm >> 16) == 0xFFFF) {
        instr |= (1 << 28);
      } else {
        error("illegal immediate value 0x%08X", imm);
      }
      mask = 0x0000FFFF;
      instr &= ~mask;
      instr |= (imm & mask);
      putWord(codeOffset, instr);
      break;
    case FIXUP_TARGET:
      target = value;
      /* target is never out of reach */
      offset = (target - locus - 4) / 4;
      mask = 0x003FFFFF;
      instr = getWord(codeOffset);
      instr &= ~mask;
      instr |= (offset & mask);
      putWord(codeOffset, instr);
      break;
    case FIXUP_OFFSET:
      offset = value;
      if (offset < -(1 << 19) || offset >= (1 << 19)) {
        error("offset %d out of bounds, symbol '%s'", offset, symbol->name);
      }
      mask = 0x000FFFFF;
      instr = getWord(codeOffset);
      instr &= ~mask;
      instr |= (offset & mask);
      putWord(codeOffset, instr);
      break;
    case FIXUP_WORD:
      putWord(codeOffset, value);
      break;
    case FIXUP_BYTE:
      putByte(codeOffset, value & 0x000000FF);
      break;
    default:
      error("illegal fixup method %d", fixupMethod);
      break;
  }
}


void fixupAll(void) {
  Fixup *fixup;

  fixup = fixupList;
  while (fixup != NULL) {
    fixupSingle(fixup->codeOffset, fixup->symbol,
                fixup->fixupMethod, fixup->locus);
    fixup = fixup->next;
  }
}


/**************************************************************/

/* scanner */


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

/* get value, either as constant or from symbol table */


unsigned int getValue(int fixupMethod) {
  unsigned int value;
  Symbol *symbol;

  if (token == TOK_NUMBER) {
    value = tokenvalNumber;
    getToken();
  } else
  if (token == TOK_IDENT) {
    symbol = lookupEnter(tokenvalString);
    if (symbol->isDefined) {
      value = symbol->value;
    } else {
      if (fixupMethod == FIXUP_ILLEGAL) {
        error("undefined symbol '%s' (cannot be fixed up later) in line %d",
              symbol->name, lineno);
      }
      addFixup(codeSize, symbol, fixupMethod, currAddr);
      value = 0;
    }
    getToken();
  } else {
    error("value missing in line %d", lineno);
    /* never reached */
    value = 0;
  }
  return value;
}


/**************************************************************/

/* assemblers for the different formats */


/*
 * operands: register, register
 */
void format_6(unsigned int code) {
  int reg1;
  int reg2;

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
  emitWord(code | (reg1 << 24) | (reg2 << 20));
}


/*
 * operand: register
 */
void format_5(unsigned int code) {
  int reg;

  if (token != TOK_REGISTER) {
    error("missing register in line %d", lineno);
  }
  reg = tokenvalNumber;
  getToken();
  emitWord(code | (reg << 24));
}


/*
 * operands: register, register or immediate
 */
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
  } else {
    imm = getValue(FIXUP_IMMEDIATE);
    if ((imm >> 16) == 0x0000) {
      emitWord(code | (4 << 28) | (reg1 << 24) | (imm & 0x0000FFFF));
    } else
    if ((imm >> 16) == 0xFFFF) {
      emitWord(code | (5 << 28) | (reg1 << 24) | (imm & 0x0000FFFF));
    } else {
      error("illegal immediate value in line %d", lineno);
    }
  }
}


/*
 * operands: register, register, register or immediate
 */
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
  } else {
    imm = getValue(FIXUP_IMMEDIATE);
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
  }
}


/*
 * operand: register or target address
 */
void format_2(unsigned int code) {
  int reg;
  int target;
  int offset;

  if (token == TOK_REGISTER) {
    reg = tokenvalNumber;
    getToken();
    emitWord(code | reg);
  } else {
    target = getValue(FIXUP_TARGET);
    /* target is never out of reach */
    offset = (target - currAddr - 4) / 4;
    emitWord(code | (1 << 29) | (offset & 0x003FFFFF));
  }
}


/*
 * operands: register, register, offset
 */
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
  offset = getValue(FIXUP_OFFSET);
  if (offset < -(1 << 19) || offset >= (1 << 19)) {
    error("offset out of bounds in line %d", lineno);
  }
  emitWord(code | (reg1 << 24) | (reg2 << 20) | (offset & 0x000FFFFF));
}


/*
 * operands: none
 */
void format_0(unsigned int code) {
  emitWord(code);
}


/**************************************************************/

/* assemblers for the directives */


void dotWord(unsigned int code) {
  unsigned int val;

  while (1) {
    val = getValue(FIXUP_WORD);
    emitWord(val);
    if (token != TOK_COMMA) {
      break;
    }
    getToken();
  }
}


void dotByte(unsigned int code) {
  char *p;
  unsigned int val;

  while (1) {
    if (token == TOK_STRING) {
      p = tokenvalString;
      while (*p != '\0') {
        emitByte(*p);
        p++;
      }
      getToken();
    } else {
      val = getValue(FIXUP_BYTE);
      emitByte(val);
    }
    if (token != TOK_COMMA) {
      break;
    }
    getToken();
  }
}


void dotSet(unsigned int code) {
  Symbol *symbol;
  unsigned int val;

  if (token != TOK_IDENT) {
    error("identifier missing in line %d", lineno);
  }
  symbol = lookupEnter(tokenvalString);
  if (symbol->isDefined) {
    error("symbol '%s' multiply defined in line %d",
          symbol->name, lineno);
  }
  getToken();
  if (token != TOK_COMMA) {
    error("comma expected in line %d", lineno);
  }
  getToken();
  val = getValue(FIXUP_ILLEGAL);
  symbol->isDefined = true;
  symbol->value = val;
}


void dotLoc(unsigned int code) {
  unsigned int val;

  val = getValue(FIXUP_ILLEGAL);
  currAddr = val;
}


void dotSpace(unsigned int code) {
  unsigned int val;
  unsigned int i;

  val = getValue(FIXUP_ILLEGAL);
  for (i = 0; i < val; i++) {
    emitByte(0);
  }
}


void dotAlign(unsigned int code) {
  while (currAddr & 3) {
    emitByte(0);
  }
}


/**************************************************************/

/* instruction table */


typedef struct {
  char *name;
  void (*func)(unsigned int code);
  unsigned int code;
} Instr;


Instr instrTable[] = {
  /* register data move */
  { "MOV",    format_4, OP_MOV	},
  { "MOVH",   format_4, OP_MOVH	},
  { "GETH",   format_5, OP_GETH	},
  { "GETF",   format_5, OP_GETF	},
  /* shift */
  { "LSL",    format_3, OP_LSL	},
  { "ASR",    format_3, OP_ASR	},
  { "ROR",    format_3, OP_ROR	},
  /* logic */
  { "AND",    format_3, OP_AND	},
  { "ANN",    format_3, OP_ANN	},
  { "IOR",    format_3, OP_IOR	},
  { "XOR",    format_3, OP_XOR	},
  /* integer arithmetic */
  { "ADD",    format_3, OP_ADD	},
  { "ADDC",   format_3, OP_ADDC	},
  { "SUB",    format_3, OP_SUB	},
  { "SUBB",   format_3, OP_SUBB	},
  { "MUL",    format_3, OP_MUL	},
  { "MULU",   format_3, OP_MULU	},
  { "DIV",    format_3, OP_DIV	},
  { "DIVU",   format_3, OP_DIVU	},
  /* floating-point arithmetic */
  { "FAD",    format_3, OP_FAD	},
  { "FSB",    format_3, OP_FSB	},
  { "FML",    format_3, OP_FML	},
  { "FDV",    format_3, OP_FDV	},
  /* floating-point conversions */
  { "FLR",    format_6, OP_FLR	},
  { "FLT",    format_6, OP_FLT	},
  /* load/store memory */
  { "LDW",    format_1, OP_LDW	},
  { "LDB",    format_1, OP_LDB	},
  { "STW",    format_1, OP_STW	},
  { "STB",    format_1, OP_STB	},
  /* branch */
  { "BMI",    format_2, OP_BMI	},
  { "BEQ",    format_2, OP_BEQ	},
  { "BCS",    format_2, OP_BCS	},
  { "BVS",    format_2, OP_BVS	},
  { "BLS",    format_2, OP_BLS	},
  { "BLT",    format_2, OP_BLT	},
  { "BLE",    format_2, OP_BLE	},
  { "B",      format_2, OP_B	},
  { "BPL",    format_2, OP_BPL	},
  { "BNE",    format_2, OP_BNE	},
  { "BCC",    format_2, OP_BCC	},
  { "BVC",    format_2, OP_BVC	},
  { "BHI",    format_2, OP_BHI	},
  { "BGE",    format_2, OP_BGE	},
  { "BGT",    format_2, OP_BGT	},
  { "BNVR",   format_2, OP_BNVR	},
  /* call */
  { "CMI",    format_2, OP_CMI	},
  { "CEQ",    format_2, OP_CEQ	},
  { "CCS",    format_2, OP_CCS	},
  { "CVS",    format_2, OP_CVS	},
  { "CLS",    format_2, OP_CLS	},
  { "CLT",    format_2, OP_CLT	},
  { "CLE",    format_2, OP_CLE	},
  { "C",      format_2, OP_C	},
  { "CPL",    format_2, OP_CPL	},
  { "CNE",    format_2, OP_CNE	},
  { "CCC",    format_2, OP_CCC	},
  { "CVC",    format_2, OP_CVC	},
  { "CHI",    format_2, OP_CHI	},
  { "CGE",    format_2, OP_CGE	},
  { "CGT",    format_2, OP_CGT	},
  { "CNVR",   format_2, OP_CNVR	},
  /* interrupt control */
  { "RTI",    format_0, OP_RTI	},
  { "CLI",    format_0, OP_CLI	},
  { "STI",    format_0, OP_STI	},
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

/* assembler for a whole file */


void assemble(void) {
  Symbol *label;
  Instr *instr;

  lineno = 0;
  while (fgets(line, LINE_SIZE, inFile) != NULL) {
    lineno++;
    lineptr = line;
    getToken();
    while (token == TOK_LABEL) {
      label = lookupEnter(tokenvalString);
      if (label->isDefined) {
        error("label '%s' multiply defined in line %d",
              label->name, lineno);
      }
      label->isDefined = true;
      label->value = currAddr;
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
  fixupAll();
  writeCode();
}


/**************************************************************/

/* main program */


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
