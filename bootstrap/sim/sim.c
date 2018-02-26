/*
 * sim.c -- RISC simulator
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <signal.h>


#define RAM_START	0x00000000		/* byte address */
#define RAM_SIZE	0x00100000		/* counted in bytes */
#define ROM_START	0x00FFE000		/* byte address */
#define ROM_SIZE	0x00000800		/* counted in bytes */
#define IO_START	0x00FFFFC0		/* byte address */
#define IO_SIZE		0x00000040		/* counted in bytes */

#define SIGN_EXT_24(x)	((x) & 0x00800000 ? (x) | 0xFF000000 : (x))

#define LINE_SIZE	200
#define MAX_TOKENS	20


/**************************************************************/

/*
 * type definitions
 */


typedef enum { false = 0, true = 1 } Bool;


typedef unsigned int Word;
typedef unsigned char Byte;


/**************************************************************/

/*
 * error handling
 */


void error(char *fmt, ...) {
  va_list ap;

  va_start(ap, fmt);
  printf("Error: ");
  vprintf(fmt, ap);
  printf("\n");
  va_end(ap);
  exit(1);
}


/**************************************************************/

/*
 * I/O
 */


Word readIO(int dev) {
  printf("I/O: reading from I/O device %d\n", dev);
  return 0;
}


void writeIO(int dev, Word data) {
  printf("I/O: writing to I/O device %d\n", dev);
}


/**************************************************************/

/*
 * main memory
 */


static Word ram[RAM_SIZE >> 2];
static Word rom[ROM_SIZE >> 2];


Word readWord(Word addr) {
  if (addr >= RAM_START && addr < RAM_START + RAM_SIZE) {
    return ram[(addr - RAM_START) >> 2];
  }
  if (addr >= ROM_START && addr < ROM_START + ROM_SIZE) {
    return rom[(addr - ROM_START) >> 2];
  }
  if (addr >= IO_START && addr < IO_START + IO_SIZE) {
    return readIO((addr - IO_START) >> 2);
  }
  error("memory read @ 0x%08X off bounds", addr);
  /* never reached */
  return 0;
}


void writeWord(Word addr, Word data) {
  if (addr >= RAM_START && addr < RAM_START + RAM_SIZE) {
    ram[(addr - RAM_START) >> 2] = data;
    return;
  }
  if (addr >= ROM_START && addr < ROM_START + ROM_SIZE) {
    error("PROM write @ 0x%08X", addr);
  }
  if (addr >= IO_START && addr < IO_START + IO_SIZE) {
    return writeIO((addr - IO_START) >> 2, data);
  }
  error("memory write @ 0x%08X off bounds", addr);
}


Byte readByte(Word addr) {
  Word w;
  Byte b;

  w = readWord(addr);
  switch (addr & 3) {
    case 0:
      b = (w >> 0) & 0xFF;
      break;
    case 1:
      b = (w >> 8) & 0xFF;
      break;
    case 2:
      b = (w >> 16) & 0xFF;
      break;
    case 3:
      b = (w >> 24) & 0xFF;
      break;
  }
  return b;
}


void writeByte(Word addr, Byte data) {
  Word w;

  w = readWord(addr);
  switch (addr & 3) {
    case 0:
      w &= ~(0xFF << 0);
      w |= (Word) data << 0;
      break;
    case 1:
      w &= ~(0xFF << 8);
      w |= (Word) data << 8;
      break;
    case 2:
      w &= ~(0xFF << 16);
      w |= (Word) data << 16;
      break;
    case 3:
      w &= ~(0xFF << 24);
      w |= (Word) data << 24;
      break;
  }
  writeWord(addr, w);
}


void memInit(char *promName) {
  FILE *promFile;
  Word addr;
  int lineno;
  char line[LINE_SIZE];
  char *p;
  Word data;
  char *endp;

  if (promName == NULL) {
    /* no prom file to load */
    return;
  }
  promFile = fopen(promName, "r");
  if (promFile == NULL) {
    error("cannot open prom file '%s'", promName);
  }
  addr = 0;
  lineno = 0;
  while (fgets(line, LINE_SIZE, promFile) != NULL) {
    lineno++;
    p = line;
    while (*p == ' ' || *p == '\t') {
      p++;
    }
    if (*p == '\n') {
      continue;
    }
    data = strtoul(p, &endp, 16);
    p = endp;
    while (*p == ' ' || *p == '\t') {
      p++;
    }
    if (*endp != '\n') {
      error("garbage at end of line %d in prom file '%s'",
            lineno, promName);
    }
    rom[addr++] = data;
  }
  printf("0x%08X words loaded from prom file '%s'\n",
         addr, promName);
  fclose(promFile);
}


/**************************************************************/

/*
 * CPU
 */


static Word pc;			/* program counter, as word index */
static Word reg[16];		/* general purpose registers */
static Bool N, Z, C, V;		/* flags */

static Bool breakSet;		/* breakpoint set if true */
static Word breakAddr;		/* if breakSet, this is where */

static Bool run;		/* CPU runs continuously if true */


static void execNextInstruction(void) {
  Word ir;
  int pq, u, v;
  int a, b, op, c;
  int imm;
  Word n, aux;
  Bool cond;

  ir = readWord(pc << 2);
  pc++;
  pq = (ir >> 30) & 0x03;
  u = (ir >> 29) & 0x01;
  v = (ir >> 28) & 0x01;
  a = (ir >> 24) & 0x0F;
  b = (ir >> 20) & 0x0F;
  op = (ir >> 16) & 0x0F;
  c = ir & 0x0F;
  switch (pq) {
    case 0:
    case 1:
      /* register instructions */
      imm = ir & 0x0000FFFF;
      if (pq == 0) {
        /* second operand is register value */
        n = reg[c];
      } else {
        /* second operand is immediate value */
        if (v == 0) {
          /* extend with zeros */
          n = imm;
        } else {
          /* extend with ones */
          n = 0xFFFF0000 | imm;
        }
      }
      switch (op) {
        case 0:
          /* MOV */
          error("illegal register instruction %d", op);
          reg[a] = n;
          break;
        case 1:
          /* LSL */
          error("illegal register instruction %d", op);
          reg[a] = reg[b] << n;
          break;
        case 2:
          /* ASR */
          error("illegal register instruction %d", op);
          break;
        case 3:
          /* ROR */
          error("illegal register instruction %d", op);
          break;
        case 4:
          /* AND */
          error("illegal register instruction %d", op);
          break;
        case 5:
          /* ANN */
          error("illegal register instruction %d", op);
          break;
        case 6:
          /* IOR */
          error("illegal register instruction %d", op);
          break;
        case 7:
          /* XOR */
          error("illegal register instruction %d", op);
          break;
        case 8:
          /* ADD */
          error("illegal register instruction %d", op);
          break;
        case 9:
          /* SUB */
          error("illegal register instruction %d", op);
          break;
        case 10:
          /* MUL */
          error("illegal register instruction %d", op);
          break;
        case 11:
          /* DIV */
          error("illegal register instruction %d", op);
          break;
        case 12:
          /* FAD */
          error("illegal register instruction %d", op);
          break;
        case 13:
          /* FSB */
          error("illegal register instruction %d", op);
          break;
        case 14:
          /* FML */
          error("illegal register instruction %d", op);
          break;
        case 15:
          /* FDV */
          error("illegal register instruction %d", op);
          break;
      }
      break;
    case 2:
      /* memory instructions */
      imm = ir & 0x000FFFFF;
      if (u) {
        /* store */
        if (v) {
          /* byte */
          error("store byte not yet");
        } else {
          /* word */
          error("store word not yet");
        }
      } else {
        /* load */
        if (v) {
          /* byte */
          error("load byte not yet");
        } else {
          /* word */
          error("load word not yet");
        }
      }
      break;
    case 3:
      /* branch instructions */
      imm = ir & 0x00FFFFFF;
      cond = (a >> 3) & 1;
      switch (a & 7) {
        case 0:
          cond ^= N;
          break;
        case 1:
          cond ^= Z;
          break;
        case 2:
          cond ^= C;
          break;
        case 3:
          cond ^= V;
          break;
        case 4:
          cond ^= (C ^ 1) | Z;
          break;
        case 5:
          cond ^= N ^ V;
          break;
        case 6:
          cond ^= (N ^ V) | Z;
          break;
        case 7:
          cond ^= true;
          break;
      }
      if (cond) {
        /* take the branch */
        aux = pc << 2;
        if (u) {
          /* target is pc + off */
          pc += SIGN_EXT_24(imm);
        } else {
          /* target is reg[c] */
          pc = reg[c] >> 2;
        }
        if (v) {
          /* set link register */
          reg[15] = aux;
        }
      }
      break;
  }
}


Word cpuGetPC(void) {
  return pc << 2;
}


void cpuSetPC(Word addr) {
  pc = addr >> 2;
}


Word cpuGetReg(int regno) {
  return reg[regno & 0x0F];
}


void cpuSetReg(int regno, Word value) {
  reg[regno & 0x0F] = value;
}


Byte cpuGetFlags(void) {
  return (N << 3) | (Z << 2) | (C << 1) | (V << 0);
}


void cpuSetFlags(Byte value) {
  N = (value >> 3) & 1;
  Z = (value >> 2) & 1;
  C = (value >> 1) & 1;
  V = (value >> 0) & 1;
}


Bool cpuTestBreak(void) {
  return breakSet;
}


Word cpuGetBreak(void) {
  return breakAddr << 2;
}


void cpuSetBreak(Word addr) {
  breakAddr = addr >> 2;
  breakSet = true;
}


void cpuResetBreak(void) {
  breakSet = false;
}


void cpuStep(void) {
  execNextInstruction();
}


void cpuRun(void) {
  run = true;
  while (run) {
    execNextInstruction();
    if (breakSet && pc == breakAddr) {
      run = false;
    }
  }
}


void cpuHalt(void) {
  run = false;
}


void cpuInit(Word initialPC) {
  int i;

  pc = initialPC >> 2;
  for (i = 0; i < 16; i++) {
    reg[i] = 0;
  }
  N = Z = C = V = false;
  breakSet = false;
}


/**************************************************************/

/*
 * disassembler
 */


static char instrBuffer[100];


static char *regOps[16] = {
  /* 0x00 */  "MOV",
  /* 0x01 */  "LSL",
  /* 0x02 */  "ASR",
  /* 0x03 */  "ROR",
  /* 0x04 */  "AND",
  /* 0x05 */  "ANN",
  /* 0x06 */  "IOR",
  /* 0x07 */  "XOR",
  /* 0x08 */  "ADD",
  /* 0x09 */  "SUB",
  /* 0x0A */  "MUL",
  /* 0x0B */  "DIV",
  /* 0x0C */  "FAD",
  /* 0x0D */  "FSB",
  /* 0x0E */  "FML",
  /* 0x0F */  "FDV",
};


static void disasmF0(Word instr) {
  int a, b, op, c;

  a = (instr >> 24) & 0x0F;
  b = (instr >> 20) & 0x0F;
  op = (instr >> 16) & 0x0F;
  c = instr & 0x0F;
  if (op == 0) {
    sprintf(instrBuffer, "%-7s R%d,R%d", regOps[op], a, c);
  } else {
    sprintf(instrBuffer, "%-7s R%d,R%d,R%d", regOps[op], a, b, c);
  }
}


static void disasmF1(Word instr) {
  int a, b, op, im;

  a = (instr >> 24) & 0x0F;
  b = (instr >> 20) & 0x0F;
  op = (instr >> 16) & 0x0F;
  im = instr & 0xFFFF;
  if ((instr >> 28) & 1) {
    im |= 0xFFFF0000;
  }
  if (op == 0) {
    sprintf(instrBuffer, "%-7s R%d,0x%08X", regOps[op], a, im);
  } else {
    sprintf(instrBuffer, "%-7s R%d,R%d,0x%08X", regOps[op], a, b, im);
  }
}


static void disasmF2(Word instr) {
  char *opName;
  int a, b;
  Word offset;

  if (((instr >> 29) & 1) == 0) {
    if (((instr >> 28) & 1) == 0) {
      opName = "LDW";
    } else {
      opName = "LDB";
    }
  } else {
    if (((instr >> 28) & 1) == 0) {
      opName = "STW";
    } else {
      opName = "STB";
    }
  }
  a = (instr >> 24) & 0x0F;
  b = (instr >> 20) & 0x0F;
  offset = instr & 0xFFFFF;
  sprintf(instrBuffer, "%-7s R%d,R%d,%08X", opName, a, b, offset);
}


static void disasmF3(Word instr, Word locus) {
  char *cond;
  int c;
  int offset;
  Word target;

  switch ((instr >> 24) & 0x0F) {
    case 0x00:
      cond = "MI";
      break;
    case 0x01:
      cond = "EQ";
      break;
    case 0x02:
      cond = "CS";
      break;
    case 0x03:
      cond = "VS";
      break;
    case 0x04:
      cond = "LS";
      break;
    case 0x05:
      cond = "LT";
      break;
    case 0x06:
      cond = "LE";
      break;
    case 0x07:
      cond = "";
      break;
    case 0x08:
      cond = "PL";
      break;
    case 0x09:
      cond = "NE";
      break;
    case 0x0A:
      cond = "CC";
      break;
    case 0x0B:
      cond = "VC";
      break;
    case 0x0C:
      cond = "HI";
      break;
    case 0x0D:
      cond = "GE";
      break;
    case 0x0E:
      cond = "GT";
      break;
    case 0x0F:
      cond = "NVR";
      break;
  }
  if (((instr >> 29) & 1) == 0) {
    /* branch target is in register */
    c = instr & 0x0F;
    if (((instr >> 28) & 1) == 0) {
      /* branch */
      sprintf(instrBuffer, "B%-6s R%d", cond, c);
    } else {
      /* call */
      sprintf(instrBuffer, "C%-6s R%d", cond, c);
    }
  } else {
    /* branch target is pc + 1 + offset */
    offset = SIGN_EXT_24(instr & 0x00FFFFFF);
    target = ((locus >> 2) + 1 + offset) << 2;
    if (((instr >> 28) & 1) == 0) {
      /* branch */
      sprintf(instrBuffer, "B%-6s %08X", cond, target);
    } else {
      /* call */
      sprintf(instrBuffer, "C%-6s %08X", cond, target);
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

/*
 * command interpreter
 */


Bool quit;


typedef struct {
  char *name;
  void (*hlpProc)(void);
  void (*cmdProc)(char *tokens[], int n);
} Command;


extern Command commands[];
extern int numCommands;


Bool getHexNumber(char *str, Word *valptr) {
  char *end;

  *valptr = strtoul(str, &end, 16);
  return *end == '\0';
}


Bool getDecNumber(char *str, int *valptr) {
  char *end;

  *valptr = strtoul(str, &end, 10);
  return *end == '\0';
}


void showPC(void) {
  Word pc;
  Word instr;

  pc = cpuGetPC();
  instr = readWord(pc);
  printf("PC   %08X     [PC]   %08X   %s\n",
         pc, instr, disasm(instr, pc));
}


void showBreak(void) {
  Word brk;

  brk = cpuGetBreak();
  printf("Brk  ");
  if (cpuTestBreak()) {
    printf("%08X", brk);
  } else {
    printf("--------");
  }
  printf("\n");
}


void showFlags(void) {
  Byte flags;

  flags = cpuGetFlags();
  printf("Flags: N Z C V = %c %c %c %c\n",
         '0' + ((flags >> 3) & 1),
         '0' + ((flags >> 2) & 1),
         '0' + ((flags >> 1) & 1),
         '0' + ((flags >> 0) & 1));
}


void help(void) {
  printf("valid commands are:\n");
  printf("  help    get help\n");
  printf("  +       add and subtract\n");
  printf("  u       unassemble\n");
  printf("  b       set/reset breakpoint\n");
  printf("  c       continue from breakpoint\n");
  printf("  s       single-step\n");
  printf("  #       show/set PC\n");
  printf("  r       show/set register\n");
  printf("  d       dump memory\n");
  printf("  q       quit simulator\n");
  printf("type 'help <cmd>' to get help for <cmd>\n");
}


void helpHelp(void) {
  printf("  help              show a list of commands\n");
  printf("  help <cmd>        show help for <cmd>\n");
}


void doHelp(char *tokens[], int n) {
  int i;

  if (n == 1) {
    help();
  } else if (n == 2) {
    for (i = 0; i < numCommands; i++) {
      if (strcmp(commands[i].name, tokens[1]) == 0) {
        (*commands[i].hlpProc)();
        return;
      }
    }
    printf("no help available for '%s', sorry\n", tokens[1]);
  } else {
    helpHelp();
  }
}


void helpArith(void) {
  printf("  +  <num1> <num2>  add and subtract <num1> and <num2>\n");
}


void doArith(char *tokens[], int n) {
  Word num1, num2, num3, num4;

  if (n == 3) {
    if (!getHexNumber(tokens[1], &num1)) {
      printf("illegal first number\n");
      return;
    }
    if (!getHexNumber(tokens[2], &num2)) {
      printf("illegal second number\n");
      return;
    }
    num3 = num1 + num2;
    num4 = num1 - num2;
    printf("add = %08X, sub = %08X\n", num3, num4);
  } else {
    helpArith();
  }
}


void helpUnassemble(void) {
  printf("  u                 unassemble 16 instrs starting at PC\n");
  printf("  u  <addr>         unassemble 16 instrs starting at <addr>\n");
  printf("  u  <addr> <cnt>   unassemble <cnt> instrs starting at <addr>\n");
}


void doUnassemble(char *tokens[], int n) {
  Word addr, count;
  int i;
  Word instr;

  if (n == 1) {
    addr = cpuGetPC();
    count = 16;
  } else if (n == 2) {
    if (!getHexNumber(tokens[1], &addr)) {
      printf("illegal address\n");
      return;
    }
    count = 16;
  } else if (n == 3) {
    if (!getHexNumber(tokens[1], &addr)) {
      printf("illegal address\n");
      return;
    }
    if (!getHexNumber(tokens[2], &count)) {
      printf("illegal count\n");
      return;
    }
    if (count == 0) {
      return;
    }
  } else {
    helpUnassemble();
    return;
  }
  addr &= ~0x00000003;
  for (i = 0; i < count; i++) {
    instr = readWord(addr);
    printf("%08X:  %08X    %s\n",
           addr, instr, disasm(instr, addr));
    if (addr + 4 < addr) {
      /* wrap-around */
      break;
    }
    addr += 4;
  }
}


void helpBreak(void) {
  printf("  b                 reset break\n");
  printf("  b  <addr>         set break at <addr>\n");
}


void doBreak(char *tokens[], int n) {
  Word addr;

  if (n == 1) {
    cpuResetBreak();
    showBreak();
  } else if (n == 2) {
    if (!getHexNumber(tokens[1], &addr)) {
      printf("illegal address\n");
      return;
    }
    addr &= ~0x00000003;
    cpuSetBreak(addr);
    showBreak();
  } else {
    helpBreak();
  }
}


void helpContinue(void) {
  printf("  c                 continue execution\n");
  printf("  c  <cnt>          continue execution <cnt> times\n");
}


void doContinue(char *tokens[], int n) {
  Word count, i;
  Word addr;

  if (n == 1) {
    count = 1;
  } else if (n == 2) {
    if (!getHexNumber(tokens[1], &count) || count == 0) {
      printf("illegal count\n");
      return;
    }
  } else {
    helpContinue();
    return;
  }
  printf("CPU is running, press ^C to interrupt...\n");
  for (i = 0; i < count; i++) {
    cpuRun();
  }
  addr = cpuGetPC();
  printf("Break at %08X\n", addr);
  showPC();
}


void helpStep(void) {
  printf("  s                 single-step one instruction\n");
  printf("  s  <cnt>          single-step <cnt> instructions\n");
}


void doStep(char *tokens[], int n) {
  Word count, i;

  if (n == 1) {
    count = 1;
  } else if (n == 2) {
    if (!getHexNumber(tokens[1], &count) || count == 0) {
      printf("illegal count\n");
      return;
    }
  } else {
    helpStep();
    return;
  }
  for (i = 0; i < count; i++) {
    cpuStep();
  }
  showPC();
}


void helpPC(void) {
  printf("  #                 show PC\n");
  printf("  #  <addr>         set PC to <addr>\n");
}


void doPC(char *tokens[], int n) {
  Word addr;

  if (n == 1) {
    showPC();
  } else if (n == 2) {
    if (!getHexNumber(tokens[1], &addr)) {
      printf("illegal address\n");
      return;
    }
    addr &= ~0x00000003;
    cpuSetPC(addr);
    showPC();
  } else {
    helpPC();
  }
}


void helpRegister(void) {
  printf("  r                 show all registers\n");
  printf("  r  <reg>          show register <reg>\n");
  printf("  r  <reg> <data>   set register <reg> to <data>\n");
}


void doRegister(char *tokens[], int n) {
  int i, j;
  int regno;
  Word data;

  if (n == 1) {
    for (i = 0; i < 4; i++) {
      for (j = 0; j < 4; j++) {
        regno = 4 * j + i;
        data = cpuGetReg(regno);
        printf("R%-2d  %08X     ", regno, data);
      }
      printf("\n");
    }
    showFlags();
    showBreak();
    showPC();
  } else if (n == 2) {
    if (!getDecNumber(tokens[1], &regno) || regno < 0 || regno >= 16) {
      printf("illegal register number\n");
      return;
    }
    data = cpuGetReg(regno);
    printf("R%-2d  %08X\n", regno, data);
  } else if (n == 3) {
    if (!getDecNumber(tokens[1], &regno) || regno < 0 || regno >= 16) {
      printf("illegal register number\n");
      return;
    }
    if (!getHexNumber(tokens[2], &data)) {
      printf("illegal data\n");
      return;
    }
    cpuSetReg(regno, data);
  } else {
    helpRegister();
  }
}


void helpDump(void) {
  printf("  d                 dump 256 bytes starting at PC\n");
  printf("  d  <addr>         dump 256 bytes starting at <addr>\n");
  printf("  d  <addr> <cnt>   dump <cnt> bytes starting at <addr>\n");
}


void doDump(char *tokens[], int n) {
  Word addr, count;
  Word lo, hi, curr;
  int lines, i, j;
  Word tmp;
  Byte c;

  if (n == 1) {
    addr = cpuGetPC();
    count = 16 * 16;
  } else if (n == 2) {
    if (!getHexNumber(tokens[1], &addr)) {
      printf("illegal address\n");
      return;
    }
    count = 16 * 16;
  } else if (n == 3) {
    if (!getHexNumber(tokens[1], &addr)) {
      printf("illegal address\n");
      return;
    }
    if (!getHexNumber(tokens[2], &count)) {
      printf("illegal count\n");
      return;
    }
    if (count == 0) {
      return;
    }
  } else {
    helpDump();
    return;
  }
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
        c = readByte(tmp);
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
        c = readByte(tmp);
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


void helpQuit(void) {
  printf("  q                 quit simulator\n");
}


void doQuit(char *tokens[], int n) {
  if (n == 1) {
    quit = true;
  } else {
    helpQuit();
  }
}


Command commands[] = {
  { "help", helpHelp,       doHelp       },
  { "+",    helpArith,      doArith      },
  { "u",    helpUnassemble, doUnassemble },
  { "b",    helpBreak,      doBreak      },
  { "c",    helpContinue,   doContinue   },
  { "s",    helpStep,       doStep       },
  { "#",    helpPC,         doPC         },
  { "r",    helpRegister,   doRegister   },
  { "d",    helpDump,       doDump       },
  { "q",    helpQuit,       doQuit       },
};

int numCommands = sizeof(commands) / sizeof(commands[0]);


Bool execCommand(char *line) {
  char *tokens[MAX_TOKENS];
  int n;
  char *p;
  int i;

  n = 0;
  p = strtok(line, " \t\n");
  while (p != NULL) {
    if (n == MAX_TOKENS) {
      printf("too many tokens on line\n");
      return false;
    }
    tokens[n++] = p;
    p = strtok(NULL, " \t\n");
  }
  if (n == 0) {
    return false;
  }
  quit = false;
  for (i = 0; i < sizeof(commands)/sizeof(commands[0]); i++) {
    if (strcmp(commands[i].name, tokens[0]) == 0) {
      (*commands[i].cmdProc)(tokens, n);
      return quit;
    }
  }
  help();
  return false;
}


/**************************************************************/

/*
 * main program
 */


void usage(char *myself) {
  printf("Usage: %s\n", myself);
  printf("    [-i]           set interactive mode\n");
  printf("    [-p <prom>]    set prom file name\n");
  exit(1);
}


void sigIntHandler(int signum) {
  signal(SIGINT, sigIntHandler);
  cpuHalt();
}


int main(int argc, char *argv[]) {
  int i;
  char *argp;
  Bool interactive;
  char *promName;
  char line[LINE_SIZE];

  interactive = false;
  promName = NULL;
  for (i = 1; i < argc; i++) {
    argp = argv[i];
    if (strcmp(argp, "-i") == 0) {
      interactive = true;
    } else
    if (strcmp(argp, "-p") == 0) {
      if (i == argc - 1 || promName != NULL) {
        usage(argv[0]);
      }
      promName = argv[++i];
    } else {
      usage(argv[0]);
    }
  }
  signal(SIGINT, sigIntHandler);
  printf("RISC Simulator started\n");
  if (promName == NULL && !interactive) {
    printf("No program to load was specified, ");
    printf("so interactive mode is assumed.\n");
    interactive = true;
  }
  memInit(promName);
  cpuInit(0xFFE000);
  if (!interactive) {
    printf("Start executing...\n");
    strcpy(line, "c\n");
    execCommand(line);
  } else {
    while (1) {
      printf("RISC > ");
      fflush(stdout);
      if (fgets(line, LINE_SIZE, stdin) == NULL) {
        printf("\n");
        break;
      }
      if (execCommand(line)) {
        break;
      }
    }
  }
  printf("RISC Simulator finished\n");
  return 0;
}
