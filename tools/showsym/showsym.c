/*
 * showsym.c -- show symbol file
 */

/*
 * The structure of a symbol file is defined by the syntax
 * specified below. The following terminal symbols are class
 * and form specifiers or reference numbers for basic types
 * with fixed values:
 *
 * Class Values:
 *   Const = 1, Var = 2, Par = 3, Fld = 4,
 *   Typ = 5, SProc = 6, SFunc = 7, Mod = 8
 *
 * Form Values:
 *   Byte = 1, Bool = 2, Char = 3, Int = 4, Real = 5,
 *   Set = 6, Pointer = 7, NilTyp = 8, NoTyp = 9,
 *   Proc = 10, String = 11, Array = 12, Record = 13
 *
 * Syntax:
 *   SymFile = null key name version {object}.
 *   object = (CON name type (value | exno) |
 *             TYP name type [{fix} 0] |
 *             VAR name type expno).
 *   type = ref (PTR type |
 *               ARR type len |
 *               REC type {field} 0 |
 *               PRO type {param} 0).
 *   field = FLD name type offset.
 *   param = (VAR | PAR) type.
 *
 * Types are numbered consecutively by the compiler. A positive
 * reference number in the symbol file is followed by the type's
 * description. A negative reference number n (which is never
 * followed by a type description) references the type -n.
 *
 * The entities above are encoded in a symbol file with the following types:
 *  - null: Integer, must be 0
 *  - key: Integer
 *  - name: String
 *  - version: Byte2, must be 1
 *  - class: Byte2, must be one of {CON, TYP, VAR}
 *  - ref:
 *  - value:
 *  - exno:
 *  - fix:
 *  - expno:
 *  - len:
 *
 * Here are the actual respresentations of these types:
 *  - Byte: a single byte, unsigned
 *  - Byte2: a single byte, 2's complement
 *  - Char: same as Byte
 *  - Integer: 4-byte little-endian integer
 *  - Set: same as Integer
 *  - Real: 4-byte floating-point number
 *  - String: zero-terminated sequence of characters
 *  - Number: integer of variable size (1..5 bytes)
 *    Here is the coding function ("asr" is "arithmetic shift right"):
 *    void writenum(int x, unsigned char *bytes) {
 *      while (x < -0x40 || x >= 0x40) {
 *        *bytes++ = (x & 0x7F) | 0x80;
 *        x = asr(x, 7);
 *      }
 *      *bytes++ = x & 0x7F;
 *    }
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>


/**************************************************************/


#define CLASS_CON	1
#define CLASS_VAR	2
#define CLASS_PAR	3
#define CLASS_FLD	4
#define CLASS_TYP	5

#define FORM_BYTE	1
#define FORM_BOOL	2
#define FORM_CHAR	3
#define FORM_INT	4
#define FORM_REAL	5
#define FORM_SET	6
#define FORM_POINTER	7
#define FORM_NOTYP	9
#define FORM_PROCTYP	10
#define FORM_ARRAY	12
#define FORM_RECORD	13


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


/**************************************************************/


FILE *symFile;


void readByte(unsigned char *p) {
  int c;

  c = fgetc(symFile);
  if (c == EOF) {
    error("unexpected EOF");
  }
  *p = (unsigned char) c;
}


void readByte2(int *p) {
  int c;

  c = fgetc(symFile);
  if (c == EOF) {
    error("unexpected EOF");
  }
  if (c & 0x80) {
    *p = c - 0x100;
  } else {
    *p = c;
  }
}


void readInt(unsigned int *p) {
  int c0, c1, c2, c3;

  c0 = fgetc(symFile);
  c1 = fgetc(symFile);
  c2 = fgetc(symFile);
  c3 = fgetc(symFile);
  if (c0 == EOF || c1 == EOF || c2 == EOF || c3 == EOF) {
    error("unexpected EOF");
  }
  *p = (c0 <<  0) |
       (c1 <<  8) |
       (c2 << 16) |
       (c3 << 24);
}


void readFlt(float *p) {
  int c0, c1, c2, c3;

  c0 = fgetc(symFile);
  c1 = fgetc(symFile);
  c2 = fgetc(symFile);
  c3 = fgetc(symFile);
  if (c0 == EOF || c1 == EOF || c2 == EOF || c3 == EOF) {
    error("unexpected EOF");
  }
  *p = (float) ((c0 <<  0) |
                (c1 <<  8) |
                (c2 << 16) |
                (c3 << 24));
}


void readStr(unsigned char *p) {
  int c;

  do {
    c = fgetc(symFile);
    if (c == EOF) {
      error("unexpected EOF");
    }
    *p++ = (unsigned char) c;
  } while (c != 0);
}


static unsigned int asr(unsigned int x, int n) {
  unsigned int mask;
  int z;

  mask = x & 0x80000000 ?
           ~(((unsigned int) 0xFFFFFFFF) >> (n & 0x1F)) : 0x00000000;
  z = mask | (x >> (n & 0x1F));
  return z;
}


static unsigned int ror(unsigned int x, int n) {
  int z;

  z = (x << (-n & 0x1F)) | (x >> (n & 0x1F));
  return z;
}


void readNum(int *p) {
  int n, y;
  int c;

  n = 32;
  y = 0;
  c = fgetc(symFile);
  if (c == EOF) {
    error("unexpected EOF");
  }
  while (c & 0x80) {
    y = ror(y | (c & 0x7F), 7);
    n -= 7;
    c = fgetc(symFile);
    if (c == EOF) {
      error("unexpected EOF");
    }
  }
  if (n <= 4) {
    y = ror(y | (c & 0x0F), 4);
  } else {
    y = ror(y | c, 7);
    y = asr(y, n - 7);
  }
  *p = y;
}


/**************************************************************/


int readType(void) {
  int ref;
  int form;

  readByte2(&ref);
  if (ref < 0) {
    printf("[^%d] ", -ref);
    return -ref;
  }
  printf("[#%d ", ref);
  readByte2(&form);
  printf("form = ");
  switch (form) {
    case FORM_RECORD:
      printf("REC");
      break;
    default:
      error("illegal form %d", form);
  }
  return ref;
}


/**************************************************************/


void usage(char *myself) {
  printf("usage: %s <symbol file>\n", myself);
  exit(1);
}


int main(int argc, char *argv[]) {
  unsigned int null;
  unsigned int key;
  unsigned char module[MAX_STRING];
  int version;
  int class;
  unsigned char name[MAX_STRING];
  int form;
  float fltVal;
  int intVal;

  if (argc != 2) {
    usage(argv[0]);
  }
  symFile = fopen(argv[1], "r");
  if (symFile == NULL) {
    error("cannot open symbol file '%s'", argv[1]);
  }
  readInt(&null);
  if (null != 0) {
    error("symbol file does not start with a 0 integer");
  }
  readInt(&key);
  printf("key = 0x%08X\n", key);
  readStr(module);
  printf("module = %s\n", module);
  readByte2(&version);
  printf("version = 0x%02X\n", version);
  readByte2(&class);
  while (class != 0) {
    printf("class = ");
    switch (class) {
      case CLASS_CON:
        printf("CON ");
        readStr(name);
        printf("%s ", name);
        form = readType();
        if (form == FORM_REAL) {
          readFlt(&fltVal);
          printf("%e", fltVal);
        } else {
          readNum(&intVal);
          printf("%d", intVal);
        }
        break;
      case CLASS_TYP:
        printf("TYP ");
        readStr(name);
        printf("%s ", name);
        form = readType();
        break;
      case CLASS_VAR:
        printf("VAR ");
        readStr(name);
        printf("%s ", name);
        form = readType();
        break;
      default:
        error("illegal object class %d", class);
    }
    printf("\n");
    readByte2(&class);
  }
  fclose(symFile);
  return 0;
}
