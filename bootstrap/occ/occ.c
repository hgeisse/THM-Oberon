/*
 * occ.c -- Oberon cross compiler
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <ctype.h>


/**************************************************************/

/*
 * type definitions
 */


typedef enum { false = 0, true = 1 } Bool;


/**************************************************************/

/*
 * global variables
 */


Bool debugScanner = false;


/**************************************************************/

/*
 * error handling, memory allocation
 */


void error(char *fmt, ...) {
  va_list ap;

  va_start(ap, fmt);
  printf("\nError: ");
  vprintf(fmt, ap);
  printf("\n");
  va_end(ap);
  exit(1);
}


void *memAlloc(unsigned int size) {
  void *p;

  p = malloc(size);
  if (p == NULL) {
    error("no memory");
  }
  return p;
}


void memFree(void *p) {
  if (p == NULL) {
    error("NULL pointer in memFree()");
  }
  free(p);
}


/**************************************************************/

/*
 * scanner
 */


//#define TOK_null	0
#define TOK_times	1
#define TOK_div		3
#define TOK_mod		4
#define TOK_and		5
#define TOK_plus	6
#define TOK_minus	7
#define TOK_or		8
#define TOK_eql		9
#define TOK_neq		10
#define TOK_lss		11
#define TOK_leq		12
#define TOK_gtr		13
#define TOK_geq		14
#define TOK_period	18
#define TOK_int		21
#define TOK_false	23
#define TOK_true	24
#define TOK_not		27
#define TOK_lparen	28
#define TOK_lbrak	29
#define TOK_ident	31
#define TOK_if		32
#define TOK_while	34
#define TOK_repeat	35
#define TOK_comma	40
#define TOK_colon	41
#define TOK_becomes	42
#define TOK_rparen	44
#define TOK_rbrak	45
#define TOK_then	47
#define TOK_of		48
#define TOK_do		49
#define TOK_semicolon	52
#define TOK_end		53
#define TOK_else	55
#define TOK_elsif	56
#define TOK_until	57
#define TOK_array	60
#define TOK_record	61
#define TOK_const	63
#define TOK_type	64
#define TOK_var		65
#define TOK_procedure	66
#define TOK_begin	67
#define TOK_module	69
#define TOK_eof		70


FILE *sourceFile;
int lineno;
int ch;

int nextToken;
int tokenValInt;
char *tokenValStr;

struct {
  char *name;
  int token;
} keyTbl[50];

int numKW;


void enterKW(int token, char *name) {
  keyTbl[numKW].name = name;
  keyTbl[numKW].token = token;
  numKW++;
}


int lookupKW(char *name) {
  int i;

  for (i = 0; i < numKW; i++) {
    if (strcmp(keyTbl[i].name, name) == 0) {
      return keyTbl[i].token;
    }
  }
  return -1;
}


void initScanner(void) {
  lineno = 1;
  ch = ' ';
  numKW = 0;
  enterKW(TOK_array,     "ARRAY");
  enterKW(TOK_begin,     "BEGIN");
  enterKW(TOK_const,     "CONST");
  enterKW(TOK_div,       "DIV");
  enterKW(TOK_do,        "DO");
  enterKW(TOK_else,      "ELSE");
  enterKW(TOK_elsif,     "ELSIF");
  enterKW(TOK_end,       "END");
  enterKW(TOK_false,     "FALSE");
  enterKW(TOK_if,        "IF");
  enterKW(TOK_mod,       "MOD");
  enterKW(TOK_module,    "MODULE");
  enterKW(TOK_of,        "OF");
  enterKW(TOK_or,        "OR");
  enterKW(TOK_procedure, "PROCEDURE");
  enterKW(TOK_record,    "RECORD");
  enterKW(TOK_repeat,    "REPEAT");
  enterKW(TOK_then,      "THEN");
  enterKW(TOK_true,      "TRUE");
  enterKW(TOK_type,      "TYPE");
  enterKW(TOK_until,     "UNTIL");
  enterKW(TOK_var,       "VAR");
  enterKW(TOK_while,     "WHILE");
}


int Get(void) {
  char buffer[100];
  char *p;
  int token;

  while (1) {
    if (ch == EOF) {
      return TOK_eof;
    }
    while (ch == ' ' || ch == '\t' || ch == '\r') {
      ch = fgetc(sourceFile);
    }
    if (ch == '\n') {
      lineno++;
      ch = fgetc(sourceFile);
      continue;
    }
    if (ch == '(') {
      ch = fgetc(sourceFile);
      if (ch == '*') {
        /* comment */
        ch = fgetc(sourceFile);
        while (1) {
          while (ch != '*') {
            if (ch == EOF) {
              error("EOF within comment");
            }
            if (ch == '\n') {
              lineno++;
            }
            ch = fgetc(sourceFile);
          }
          ch = fgetc(sourceFile);
          if (ch == ')') {
            break;
          }
        }
        ch = fgetc(sourceFile);
        continue;
      } else {
        /* LPAREN */
        return TOK_lparen;
      }
    }
    if (isalpha(ch)) {
      p = buffer;
      while (isalpha(ch) || isdigit(ch)) {
        *p++ = ch;
        ch = fgetc(sourceFile);
      }
      *p = '\0';
      token = lookupKW(buffer);
      if (token != -1) {
        /* keyword */
        return token;
      }
      /* identifier */
      tokenValStr = memAlloc(strlen(buffer) + 1);
      strcpy(tokenValStr, buffer);
      return TOK_ident;
    }
    if (isdigit(ch)) {
      p = buffer;
      while (isdigit(ch)) {
        *p++ = ch;
        ch = fgetc(sourceFile);
      }
      *p = '\0';
      tokenValInt = atoi(buffer);
      return TOK_int;
    }
    if (ch == '<') {
      ch = fgetc(sourceFile);
      if (ch == '=') {
        ch = fgetc(sourceFile);
        return TOK_leq;
      }
      return TOK_lss;
    }
    if (ch == '>') {
      ch = fgetc(sourceFile);
      if (ch == '=') {
        ch = fgetc(sourceFile);
        return TOK_geq;
      }
      return TOK_gtr;
    }
    if (ch == ':') {
      ch = fgetc(sourceFile);
      if (ch == '=') {
        ch = fgetc(sourceFile);
        return TOK_becomes;
      }
      return TOK_colon;
    }
    switch (ch) {
      case '*':
        token = TOK_times;
        break;
      case '&':
        token = TOK_and;
        break;
      case '+':
        token = TOK_plus;
        break;
      case '-':
        token = TOK_minus;
        break;
      case '=':
        token = TOK_eql;
        break;
      case '#':
        token = TOK_neq;
        break;
      case '.':
        token = TOK_period;
        break;
      case '~':
        token = TOK_not;
        break;
      case '(':
        token = TOK_lparen;
        break;
      case '[':
        token = TOK_lbrak;
        break;
      case ',':
        token = TOK_comma;
        break;
      case ')':
        token = TOK_rparen;
        break;
      case ']':
        token = TOK_rbrak;
        break;
      case ';':
        token = TOK_semicolon;
        break;
      default:
        error("illegal character 0x%02X ('%c') in line %d",
              ch, ch, lineno);
        break;
    }
    ch = fgetc(sourceFile);
    return token;
  }
  /* never reached */
  return -1;
}


void showToken(int token) {
  printf("DEBUG: line = %d, token = ", lineno);
  switch (token) {
    case TOK_times:
      printf("times");
      break;
    case TOK_div:
      printf("div");
      break;
    case TOK_mod:
      printf("mod");
      break;
    case TOK_and:
      printf("and");
      break;
    case TOK_plus:
      printf("plus");
      break;
    case TOK_minus:
      printf("minus");
      break;
    case TOK_or:
      printf("or");
      break;
    case TOK_eql:
      printf("eql");
      break;
    case TOK_neq:
      printf("neq");
      break;
    case TOK_lss:
      printf("lss");
      break;
    case TOK_leq:
      printf("leq");
      break;
    case TOK_gtr:
      printf("gtr");
      break;
    case TOK_geq:
      printf("geq");
      break;
    case TOK_period:
      printf("period");
      break;
    case TOK_int:
      printf("int, val = %d", tokenValInt);
      break;
    case TOK_false:
      printf("false");
      break;
    case TOK_true:
      printf("true");
      break;
    case TOK_not:
      printf("not");
      break;
    case TOK_lparen:
      printf("lparen");
      break;
    case TOK_lbrak:
      printf("lbrak");
      break;
    case TOK_ident:
      printf("ident, name = %s", tokenValStr);
      break;
    case TOK_if:
      printf("if");
      break;
    case TOK_while:
      printf("while");
      break;
    case TOK_repeat:
      printf("repeat");
      break;
    case TOK_comma:
      printf("comma");
      break;
    case TOK_colon:
      printf("colon");
      break;
    case TOK_becomes:
      printf("becomes");
      break;
    case TOK_rparen:
      printf("rparen");
      break;
    case TOK_rbrak:
      printf("rbrak");
      break;
    case TOK_then:
      printf("then");
      break;
    case TOK_of:
      printf("of");
      break;
    case TOK_do:
      printf("do");
      break;
    case TOK_semicolon:
      printf("semicolon");
      break;
    case TOK_end:
      printf("end");
      break;
    case TOK_else:
      printf("else");
      break;
    case TOK_elsif:
      printf("elsif");
      break;
    case TOK_until:
      printf("until");
      break;
    case TOK_array:
      printf("array");
      break;
    case TOK_record:
      printf("record");
      break;
    case TOK_const:
      printf("const");
      break;
    case TOK_type:
      printf("type");
      break;
    case TOK_var:
      printf("var");
      break;
    case TOK_procedure:
      printf("procedure");
      break;
    case TOK_begin:
      printf("begin");
      break;
    case TOK_module:
      printf("module");
      break;
    case TOK_eof:
      printf("eof");
      break;
    default:
      error("unknown token %d in showToken()", token);
      break;
  }
  printf("\n");
}


char *tokenToString(int token) {
  char *s;

  switch (token) {
    case TOK_times:
      s = "*";
      break;
    case TOK_div:
      s = "DIV";
      break;
    case TOK_mod:
      s = "MOD";
      break;
    case TOK_and:
      s = "&";
      break;
    case TOK_plus:
      s = "+";
      break;
    case TOK_minus:
      s = "-";
      break;
    case TOK_or:
      s = "OR";
      break;
    case TOK_eql:
      s = "=";
      break;
    case TOK_neq:
      s = "#";
      break;
    case TOK_lss:
      s = "<";
      break;
    case TOK_leq:
      s = "<=";
      break;
    case TOK_gtr:
      s = ">";
      break;
    case TOK_geq:
      s = ">=";
      break;
    case TOK_period:
      s = ".";
      break;
    case TOK_int:
      s = "<integer>";
      break;
    case TOK_false:
      s = "FALSE";
      break;
    case TOK_true:
      s = "TRUE";
      break;
    case TOK_not:
      s = "~";
      break;
    case TOK_lparen:
      s = "(";
      break;
    case TOK_lbrak:
      s = "[";
      break;
    case TOK_ident:
      s = "<ident>";
      break;
    case TOK_if:
      s = "IF";
      break;
    case TOK_while:
      s = "WHILE";
      break;
    case TOK_repeat:
      s = "REPEAT";
      break;
    case TOK_comma:
      s = ",";
      break;
    case TOK_colon:
      s = ":";
      break;
    case TOK_becomes:
      s = ":=";
      break;
    case TOK_rparen:
      s = ")";
      break;
    case TOK_rbrak:
      s = "]";
      break;
    case TOK_then:
      s = "THEN";
      break;
    case TOK_of:
      s = "OF";
      break;
    case TOK_do:
      s = "DO";
      break;
    case TOK_semicolon:
      s = ";";
      break;
    case TOK_end:
      s = "END";
      break;
    case TOK_else:
      s = "ELSE";
      break;
    case TOK_elsif:
      s = "ELSIF";
      break;
    case TOK_until:
      s = "UNTIL";
      break;
    case TOK_array:
      s = "ARRAY";
      break;
    case TOK_record:
      s = "RECORD";
      break;
    case TOK_const:
      s = "CONST";
      break;
    case TOK_type:
      s = "TYPE";
      break;
    case TOK_var:
      s = "VAR";
      break;
    case TOK_procedure:
      s = "PROCEDURE";
      break;
    case TOK_begin:
      s = "BEGIN";
      break;
    case TOK_module:
      s = "MODULE";
      break;
    case TOK_eof:
      s = "-EOF-";
      break;
    default:
      error("unknown token %d in tokenToString()", token);
      break;
  }
  return s;
}


/**************************************************************/

/*
 * parser
 */


void initParser(void) {
  initScanner();
  nextToken = Get();
}


void expect(int token) {
  if (token != nextToken) {
    error("line %d: token '%s' expected, but got '%s'",
          lineno, tokenToString(token), tokenToString(nextToken));
  }
  nextToken = Get();
}


void parseSelector(void);
void parseFactor(void);
void parseTerm(void);
void parseSimpleExpression(void);
void parseExpression(void);
void parseAssignment(void);
void parseActualParameters(void);
void parseProcedureCall(void);
void parseIfStatement(void);
void parseWhileStatement(void);
void parseRepeatStatement(void);
void parseStatement(void);
void parseStatementSequence(void);
void parseIdentList(void);
void parseArrayType(void);
void parseFieldList(void);
void parseRecordType(void);
void parseType(void);
void parseFPSection(void);
void parseFormalParameters(void);
void parseProcedureHeading(void);
void parseProcedureBody(void);
void parseProcedureDeclaration(void);
void parseDeclarations(void);
void parseModule(void);


void parseSelector(void) {
  while (nextToken == TOK_period ||
         nextToken == TOK_lbrak) {
    if (nextToken == TOK_period) {
      expect(TOK_period);
      expect(TOK_ident);
    } else
    if (nextToken == TOK_lbrak) {
      expect(TOK_lbrak);
      parseExpression();
      expect(TOK_rbrak);
    }
  }
}


void parseFactor(void) {
  if (nextToken == TOK_ident) {
    expect(TOK_ident);
    parseProcedureCall();
    parseSelector();
  } else
  if (nextToken == TOK_int) {
    expect(TOK_int);
  } else
  if (nextToken == TOK_lparen) {
    expect(TOK_lparen);
    parseExpression();
    expect(TOK_rparen);
  } else
  if (nextToken == TOK_not) {
    expect(TOK_not);
    parseFactor();
  } else
  if (nextToken == TOK_false) {
    expect(TOK_false);
  } else
  if (nextToken == TOK_true) {
    expect(TOK_true);
  } else {
    error("line %d: cannot parse factor, token = '%s'",
          lineno, tokenToString(nextToken));
  }
}


void parseTerm(void) {
  parseFactor();
  while (nextToken == TOK_times ||
         nextToken == TOK_div ||
         nextToken == TOK_mod ||
         nextToken == TOK_and) {
    expect(nextToken);
    parseFactor();
  }
}


void parseSimpleExpression(void) {
  if (nextToken == TOK_plus ||
      nextToken == TOK_minus) {
    expect(nextToken);
  }
  parseTerm();
  while (nextToken == TOK_plus ||
         nextToken == TOK_minus ||
         nextToken == TOK_or) {
    expect(nextToken);
    parseTerm();
  }
}


void parseExpression(void) {
  parseSimpleExpression();
  if (nextToken == TOK_eql ||
      nextToken == TOK_neq ||
      nextToken == TOK_lss ||
      nextToken == TOK_leq ||
      nextToken == TOK_gtr ||
      nextToken == TOK_geq) {
    expect(nextToken);
    parseSimpleExpression();
  }
}


void parseAssignment(void) {
  /* NOTE: the leftmost identifier has already been swallowed! */
  parseSelector();
  expect(TOK_becomes);
  parseExpression();
}


void parseActualParameters(void) {
  expect(TOK_lparen);
  if (nextToken != TOK_rparen) {
    parseExpression();
    while (nextToken == TOK_comma) {
      expect(TOK_comma);
      parseExpression();
    }
  }
  expect(TOK_rparen);
}


void parseProcedureCall(void) {
  /* NOTE: the leftmost identifier has already been swallowed! */
  if (nextToken == TOK_lparen) {
    parseActualParameters();
  }
}


void parseIfStatement(void) {
  expect(TOK_if);
  parseExpression();
  expect(TOK_then);
  parseStatementSequence();
  while (nextToken == TOK_elsif) {
    expect(TOK_elsif);
    parseExpression();
    expect(TOK_then);
    parseStatementSequence();
  }
  if (nextToken == TOK_else) {
    expect(TOK_else);
    parseStatementSequence();
  }
  expect(TOK_end);
}


void parseWhileStatement(void) {
  expect(TOK_while);
  parseExpression();
  expect(TOK_do);
  parseStatementSequence();
  expect(TOK_end);
}


void parseRepeatStatement(void) {
  expect(TOK_repeat);
  parseStatementSequence();
  expect(TOK_until);
  parseExpression();
}


void parseStatement(void) {
  if (nextToken == TOK_ident) {
    /* NOTE: second token needed */
    expect(TOK_ident);
    if (nextToken == TOK_becomes ||
        nextToken == TOK_period ||
        nextToken == TOK_lbrak) {
      parseAssignment();
    } else {
      parseProcedureCall();
    }
  } else
  if (nextToken == TOK_if) {
    parseIfStatement();
  } else
  if (nextToken == TOK_while) {
    parseWhileStatement();
  } else
  if (nextToken == TOK_repeat) {
    parseRepeatStatement();
  }
}


void parseStatementSequence(void) {
  parseStatement();
  while (nextToken == TOK_semicolon) {
    expect(TOK_semicolon);
    parseStatement();
  }
}


void parseIdentList(void) {
  expect(TOK_ident);
  while (nextToken == TOK_comma) {
    expect(TOK_comma);
    expect(TOK_ident);
  }
}


void parseArrayType(void) {
  expect(TOK_array);
  parseExpression();
  expect(TOK_of);
  parseType();
}


void parseFieldList(void) {
  if (nextToken == TOK_ident) {
    parseIdentList();
    expect(TOK_colon);
    parseType();
  }
}


void parseRecordType(void) {
  expect(TOK_record);
  parseFieldList();
  while (nextToken == TOK_semicolon) {
    expect(TOK_semicolon);
    parseFieldList();
  }
  expect(TOK_end);
}


void parseType(void) {
  if (nextToken == TOK_ident) {
    expect(TOK_ident);
  } else
  if (nextToken == TOK_array) {
    parseArrayType();
  } else
  if (nextToken == TOK_record) {
    parseRecordType();
  } else {
    error("line %d: cannot parse type, token = '%s'",
          lineno, tokenToString(nextToken));
  }
}


void parseFPSection(void) {
  if (nextToken == TOK_var) {
    expect(TOK_var);
  }
  parseIdentList();
  expect(TOK_colon);
  parseType();
}


void parseFormalParameters(void) {
  expect(TOK_lparen);
  if (nextToken == TOK_ident ||
      nextToken == TOK_var) {
    parseFPSection();
    while (nextToken == TOK_semicolon) {
      expect(TOK_semicolon);
      parseFPSection();
    }
  }
  expect(TOK_rparen);
}


void parseProcedureHeading(void) {
  expect(TOK_procedure);
  expect(TOK_ident);
  if (nextToken == TOK_times) {
    expect(TOK_times);
  }
  if (nextToken == TOK_lparen) {
    parseFormalParameters();
  }
}


void parseProcedureBody(void) {
  parseDeclarations();
  if (nextToken == TOK_begin) {
    expect(TOK_begin);
    parseStatementSequence();
  }
  expect(TOK_end);
}


void parseProcedureDeclaration(void) {
  parseProcedureHeading();
  expect(TOK_semicolon);
  parseProcedureBody();
  expect(TOK_ident);
}


void parseDeclarations(void) {
  if (nextToken == TOK_const) {
    expect(TOK_const);
    while (nextToken == TOK_ident) {
      expect(TOK_ident);
      expect(TOK_eql);
      parseExpression();
      expect(TOK_semicolon);
    }
  }
  if (nextToken == TOK_type) {
    expect(TOK_type);
    while (nextToken == TOK_ident) {
      expect(TOK_ident);
      expect(TOK_eql);
      parseType();
      expect(TOK_semicolon);
    }
  }
  if (nextToken == TOK_var) {
    expect(TOK_var);
    while (nextToken == TOK_ident) {
      parseIdentList();
      expect(TOK_colon);
      parseType();
      expect(TOK_semicolon);
    }
  }
  while (nextToken == TOK_procedure) {
    parseProcedureDeclaration();
    expect(TOK_semicolon);
  }
}


void parseModule(void) {
  expect(TOK_module);
  expect(TOK_ident);
  expect(TOK_semicolon);
  parseDeclarations();
  if (nextToken == TOK_begin) {
    expect(TOK_begin);
    parseStatementSequence();
  }
  expect(TOK_end);
  expect(TOK_ident);
  expect(TOK_period);
}


/**************************************************************/

/*
 * code generator
 */


/**************************************************************/

/*
 * main program
 */


void usage(char *myself) {
  printf("Usage: %s <source file>\n", myself);
  exit(1);
}


int main(int argc, char *argv[]) {
  char *sourceName;

  if (argc != 2) {
    usage(argv[0]);
  }
  sourceName = argv[1];
  sourceFile = fopen(sourceName, "r");
  if (sourceFile == NULL) {
    error("cannot open source file '%s'", sourceName);
  }
  if (debugScanner) {
    initScanner();
    do {
      nextToken = Get();
      showToken(nextToken);
    } while (nextToken != TOK_eof);
    fclose(sourceFile);
    return 0;
  }
  initParser();
  parseModule();
  fclose(sourceFile);
  return 0;
}
