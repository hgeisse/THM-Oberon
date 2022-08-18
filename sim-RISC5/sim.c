/*
 * sim.c -- RISC5 simulator
 */


#ifdef __linux__
#define _GNU_SOURCE
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <fcntl.h>

#include "common.h"
#include "muldiv.h"
#include "fpu.h"
#include "graph.h"

#include "getline.h"


#define SERDEV_FILE	"serial.dev"		/* serial dev file */

#define CPU_VERSION	0x80			/* 8.0 */
#define CPU_ID		(CPU_VERSION)

#define INST_PER_MSEC	17000			/* execution speed */
#define INST_PER_CHAR	10000			/* serial line speed */

#define IRQPRIO_TIMER	15			/* timer IRQ priority */

#define RAM_BASE	0x00000000		/* byte address */
#define RAM_SIZE	0x00FFE000		/* counted in bytes */
#define GRAPH_BASE	0x00FE0000		/* frame buffer memory */
#define GRAPH_SIZE	0x00018000		/* located within RAM */
#define ROM_BASE	0x00FFE000		/* byte address */
#define ROM_SIZE	0x00000800		/* counted in bytes */
#define IO_BASE		0x00FFFFC0		/* byte address */
#define IO_SIZE		0x00000040		/* counted in bytes */
#define ADDR_MASK	0x00FFFFFF		/* 24-bit addresses */

#define INITIAL_PC	0xFFE000		/* start executing here */
#define EXC_VECTOR	0x000008		/* exceptions land here */

#define SIGN_EXT_20(x)	((x) & 0x00080000 ? (x) | 0xFFF00000 : (x))

#define LINE_SIZE	200
#define MAX_TOKENS	20


/**************************************************************/

/*
 * I/O device 0: timer
 */


static Word milliSeconds;


void cpuSetInterrupt(int priority);
void cpuResetInterrupt(int priority);


void tickTimer(void) {
  static int count = 0;

  if (count++ == INST_PER_MSEC) {
    count = 0;
    milliSeconds++;
    cpuSetInterrupt(IRQPRIO_TIMER);
  }
}


/*
 * read device 0: milliseconds counter value
 */
Word readTimer(void) {
  cpuResetInterrupt(IRQPRIO_TIMER);
  return milliSeconds;
}


/*
 * write dev 0: ignore
 */
void writeTimer(Word data) {
}


void initTimer(void) {
  milliSeconds = 0;
}


/**************************************************************/

/*
 * I/O device 1: switches, LEDs
 */


static Word currentSwitches;


void setSwitches(Word data) {
  currentSwitches = data & 0x0FFF;
}


/*
 * read dev 1: buttons and switches
 *    { 20'bx, button[3:0], switch[7:0] }
 *    button: press = 1
 *    switch: up = on = 1
 */
Word readSwitches(void) {
  return currentSwitches;
}


/*
 * write dev 1: LEDs
 *    { 24'bx, led[7:0] }
 *    led: 1 = on
 */
void writeLEDs(Word data) {
  static Word currentLEDs = -1;
  int i;

  data &= 0x000000FF;
  if (currentLEDs != data) {
    currentLEDs = data;
    printf("LED change:");
    for (i = 7; i >= 0; i--) {
      printf("  %s", currentLEDs & (1 << i) ? "ON " : "OFF");
    }
    printf("\n");
  }
}


void initSWLED(Word initialSwitches) {
  setSwitches(initialSwitches);
  writeLEDs(0);
}


/**************************************************************/

/*
 * I/O devices 2, 3: RS232
 */


#define SERIAL_RX_RDY		0x01
#define SERIAL_TX_RDY		0x02


static FILE *serialIn;
static FILE *serialOut;
static Word serialRxData;
static Word serialTxData;
static Word serialStatus;


void tickSerial(void) {
  static int rxCount = 0;
  static int txCount = 0;
  int c;

  if (rxCount++ == INST_PER_CHAR) {
    rxCount = 0;
    c = fgetc(serialIn);
    if (c != EOF) {
      serialRxData = c & 0xFF;
      serialStatus |= SERIAL_RX_RDY;
    }
  }
  if ((serialStatus & SERIAL_TX_RDY) == 0) {
    if (txCount++ == INST_PER_CHAR) {
      txCount = 0;
      fputc(serialTxData & 0xFF, serialOut);
      serialStatus |= SERIAL_TX_RDY;
    }
  }
}


/*
 * read dev 2: receiver data
 *     { 24'bx, rx_data[7:0] }
 */
Word readRS232_0(void) {
  serialStatus &= ~SERIAL_RX_RDY;
  return serialRxData;
}


/*
 * write dev 2: transmitter data
 *     { 24'bx, tx_data[7:0] }
 */
void writeRS232_0(Word data) {
  serialTxData = data & 0xFF;
  serialStatus &= ~SERIAL_TX_RDY;
}


/*
 * read dev 3: status
 *     { 30'bx, tx_rdy, rx_rdy }
 */
Word readRS232_1(void) {
  return serialStatus;
}


/*
 * write dev 3: control
 *     { 31'bx, bitrate }
 *     bitrate: 0 = 19200 bps, 1 = 115200 bps
 */
void writeRS232_1(Word data) {
  /* ignore bitrate in simulation */
}


void initRS232(void) {
  int master;
  char slavePath[100];
  FILE *serdevFile;

  serialIn = NULL;
  serialOut = NULL;
  master = open("/dev/ptmx", O_RDWR | O_NONBLOCK);
  if (master < 0) {
    error("cannot open pseudo terminal master for serial line");
  }
  grantpt(master);
  unlockpt(master);
  strcpy(slavePath, ptsname(master));
  printf("The serial line can be accessed by opening device '%s'.\n",
         slavePath);
  serdevFile = fopen(SERDEV_FILE, "w");
  if (serdevFile == NULL) {
    error("cannot open file for writing serial device path");
  }
  fprintf(serdevFile, "%s\n", slavePath);
  fclose(serdevFile);
  printf("This path was also written to file '%s'.\n", SERDEV_FILE);
  fcntl(master, F_SETFL, O_NONBLOCK);
  serialIn = fdopen(master, "r");
  setvbuf(serialIn, NULL, _IONBF, 0);
  serialOut = fdopen(master, "w");
  setvbuf(serialOut, NULL, _IONBF, 0);
  while (fgetc(serialIn) != EOF) ;
  serialStatus = SERIAL_TX_RDY;
}


/**************************************************************/

/*
 * I/O device 4, 5: SPI (SD card, WiFi network)
 */


/* ---------------------------------------------------------- */

/* SD card */


/*
 * NOTE: The SD card protocol machinery was shamelessly copied
 *       from Peter de Wachter's emulator. It should be enhanced
 *       to simulate an SD card more exactly.
 */


#define DISK_CMD	0
#define DISK_READ	1
#define DISK_WRT0	2
#define DISK_WRT1	3


static Bool debugDisk = false;

static FILE *diskImage;
static int diskState;
static Word diskOffset;
static Word diskRxBuf[128];
static int diskRxIdx;
static Word diskTxBuf[128 + 2];
static int diskTxCnt;
static int diskTxIdx;


static void diskSeekSector(Word secnum) {
  if (debugDisk) {
    printf("DISK: seek to sector 0x%08X\n", secnum);
  }
  if (diskImage == NULL) {
    return;
  }
  fseek(diskImage, secnum * 512, SEEK_SET);
}


static void diskReadSector(Word *buf) {
  Byte bytes[512];
  int i;

  if (debugDisk) {
    printf("DISK: read sector\n");
  }
  if (diskImage == NULL) {
    return;
  }
  if (fread(bytes, 512, 1, diskImage) != 1) {
    error("read error on disk image");
  }
  for (i = 0; i < 128; i++) {
    buf[i] = (Word) bytes[4 * i + 0] <<  0 |
             (Word) bytes[4 * i + 1] <<  8 |
             (Word) bytes[4 * i + 2] << 16 |
             (Word) bytes[4 * i + 3] << 24;
  }
}


static void diskWriteSector(Word *buf) {
  Byte bytes[512];
  int i;

  if (debugDisk) {
    printf("DISK: write sector\n");
  }
  if (diskImage == NULL) {
    return;
  }
  for (i = 0; i < 128; i++) {
    bytes[4 * i + 0] = buf[i] >>  0;
    bytes[4 * i + 1] = buf[i] >>  8;
    bytes[4 * i + 2] = buf[i] >> 16;
    bytes[4 * i + 3] = buf[i] >> 24;
  }
  if (fwrite(bytes, 512, 1, diskImage) != 1) {
    error("write error on disk image");
  }
}


static void diskRunCmd(void) {
  Word cmd;
  Word arg;

  cmd = diskRxBuf[0];
  arg = diskRxBuf[1] << 24 |
        diskRxBuf[2] << 16 |
        diskRxBuf[3] <<  8 |
        diskRxBuf[4] <<  0;
  switch (cmd) {
    case 81:
      diskState = DISK_READ;
      diskTxBuf[0] = 0;
      diskTxBuf[1] = 254;
      diskSeekSector(arg - diskOffset);
      diskReadSector(diskTxBuf + 2);
      diskTxCnt = 2 + 128;
      break;
    case 88:
      diskState = DISK_WRT0;
      diskSeekSector(arg - diskOffset);
      diskTxBuf[0] = 0;
      diskTxCnt = 1;
      break;
    default:
      diskTxBuf[0] = 0;
      diskTxCnt = 1;
      break;
  }
  diskTxIdx = -1;
}


static Word diskRead(void) {
  Word result;

  if (diskTxIdx >= 0 && diskTxIdx < diskTxCnt) {
    result = diskTxBuf[diskTxIdx];
  } else {
    result = 255;
  }
  if (debugDisk) {
    printf("DISK: read, result = 0x%08X\n", result);
  }
  return result;
}


static void diskWrite(Word value) {
  if (debugDisk) {
    printf("DISK: write, value = 0x%08X, state = %d\n",
           value, diskState);
  }
  diskTxIdx++;
  switch (diskState) {
    case DISK_CMD:
      if ((value & 0xFF) != 0xFF || diskRxIdx != 0) {
        diskRxBuf[diskRxIdx] = value;
        diskRxIdx++;
        if (diskRxIdx == 6) {
          diskRunCmd();
          diskRxIdx = 0;
        }
      }
      break;
    case DISK_READ:
      if (diskTxIdx == diskTxCnt) {
        diskState = DISK_CMD;
        diskTxCnt = 0;
        diskTxIdx = 0;
      }
      break;
    case DISK_WRT0:
      if (value == 254) {
        diskState = DISK_WRT1;
      }
      break;
    case DISK_WRT1:
      if (diskRxIdx < 128) {
        diskRxBuf[diskRxIdx] = value;
      }
      diskRxIdx++;
      if (diskRxIdx == 128) {
        diskWriteSector(diskRxBuf);
      }
      if (diskRxIdx == 130) {
        diskTxBuf[0] = 5;
        diskTxCnt = 1;
        diskTxIdx = -1;
        diskRxIdx = 0;
        diskState = DISK_CMD;
      }
      break;
  }
}


void diskInit(char *diskName) {
  if (diskName == NULL) {
    diskImage = NULL;
    return;
  }
  diskImage = fopen(diskName, "r+");
  if (diskImage == NULL) {
    error("cannot open disk file '%s'", diskName);
  }
  diskState = DISK_CMD;
  diskSeekSector(0);
  diskReadSector(diskTxBuf);
  if (diskTxBuf[0] == 0x9B1EA38D) {
    diskOffset = 0x80002;
  } else {
    diskOffset = 0;
  }
  diskRxIdx = 0;
  diskTxCnt = 0;
  diskTxIdx = 0;
}


/* ---------------------------------------------------------- */

/* WiFi network */


void netInit(void) {
}


/* ---------------------------------------------------------- */


#define SPI_SEL_DISK	(1 << 0)
#define SPI_SEL_WIFI	(1 << 1)


static Bool debugSPI = false;

static Word spiSelect;


/*
 * read dev 4: read data
 */
Word readSPIdata(void) {
  Word data;

  if (spiSelect & SPI_SEL_DISK) {
    data = diskRead();
  } else {
    data = 255;
  }
  if (debugSPI) {
    printf("SPI: read data, data = 0x%08X\n", data);
  }
  return data;
}


/*
 * write dev 4: write data
 */
void writeSPIdata(Word data) {
  if (debugSPI) {
    printf("SPI: write data, data = 0x%08X\n", data);
  }
  if (spiSelect & SPI_SEL_DISK) {
    diskWrite(data);
    return;
  }
}


/*
 * read dev 5: status
 *     { 31'bx, spi_rdy }
 */
Word readSPIctrl(void) {
  Word data;

  data = 1;
  if (debugSPI) {
    printf("SPI: read ctrl, data = 0x%08X\n", data);
  }
  return data;
}


/*
 * write dev 5: ctrl
 *     { 28'bx, net_en, fast, wifi_sel, sdc_sel }
 */
void writeSPIctrl(Word data) {
  if (debugSPI) {
    printf("SPI: write ctrl, data = 0x%08X\n", data);
  }
  spiSelect = data & 3;
}


void initSPI(char *diskName) {
  /* init SPI */
  spiSelect = 0;
  /* init SD card interface */
  diskInit(diskName);
  /* init network interface */
  netInit();
}


/**************************************************************/

/*
 * I/O device 6, 7: PS/2 (mouse, keyboard)
 */


static Bool debugKeycode = false;


/*
 * read dev 6: mouse data, keyboard status
 *     { 3'bx, kbd_rdy, 1'bx, btn[2:0], 2'bx, ypos[9:0], 2'bx, xpos[9:0] }
 */
Word readMouse(void) {
  return mouseRead();
}


/*
 * write dev 6: ignore
 */
void writeMouse(Word data) {
}


/*
 * read dev 7: keyboard data
 *     { 24'bx, kbd_data[7:0] }
 */
Word readKeybd(void) {
  Word data;

  data = keybdRead();
  if (debugKeycode) {
    printf("DEBUG: kbd data = 0x%08X\n", data);
  }
  return data;
}


/*
 * write dev 7: ignore
 */
void writeKeybd(Word data) {
}


void initMouseKeybd(void) {
  mouseKeybdInit();
}


/**************************************************************/

/*
 * I/O device 8, 9: GPIO
 */


/*
 * read dev 8: ignore, return 0
 */
Word readGPIO_0(void) {
  return 0;
}


/*
 * write dev 8: ignore
 */
void writeGPIO_0(Word data) {
}


/*
 * read dev 9: ignore, return 0
 */
Word readGPIO_1(void) {
  return 0;
}


/*
 * write dev 9: ignore
 */
void writeGPIO_1(Word data) {
}


void initGPIO(void) {
}


/**************************************************************/

/*
 * I/O device 10: FPU
 */


/*
 * read dev 10: get FP exception flags
 */
Word readFPU(void) {
  return fpGetFlags();
}


/*
 * write dev 10: clear FP exception flags
 */
void writeFPU(Word data) {
  fpClrFlags();
}


void initFPU(void) {
}


/**************************************************************/

/*
 * I/O : address of device n = IO_BASE + 4 * n
 *       this can be expressed in decimal as -4 * (16 - n)
 */


Word readIO(int dev) {
  Word data;

  switch (dev) {
    case 0:
      data = readTimer();
      break;
    case 1:
      data = readSwitches();
      break;
    case 2:
      data = readRS232_0();
      break;
    case 3:
      data = readRS232_1();
      break;
    case 4:
      data = readSPIdata();
      break;
    case 5:
      data = readSPIctrl();
      break;
    case 6:
      data = readMouse();
      break;
    case 7:
      data = readKeybd();
      break;
    case 8:
      data = readGPIO_0();
      break;
    case 9:
      data = readGPIO_1();
      break;
    case 10:
      data = readFPU();
      break;
    default:
      error("reading from unknown I/O device %d", dev);
      data = 0;
      break;
  }
  return data;
}


void writeIO(int dev, Word data) {
  switch (dev) {
    case 0:
      writeTimer(data);
      break;
    case 1:
      writeLEDs(data);
      break;
    case 2:
      writeRS232_0(data);
      break;
    case 3:
      writeRS232_1(data);
      break;
    case 4:
      writeSPIdata(data);
      break;
    case 5:
      writeSPIctrl(data);
      break;
    case 6:
      writeMouse(data);
      break;
    case 7:
      writeKeybd(data);
      break;
    case 8:
      writeGPIO_0(data);
      break;
    case 9:
      writeGPIO_1(data);
      break;
    case 10:
      writeFPU(data);
      break;
    default:
      error("writing to unknown I/O device %d, data = 0x%08X", dev, data);
      break;
  }
}


/**************************************************************/

/*
 * main memory
 */


static Word ram[RAM_SIZE >> 2];
static Word rom[ROM_SIZE >> 2];


Word cpuGetPC(void);


Word readWord(Word addr) {
  addr &= ADDR_MASK;
  if ((addr & 3) != 0) {
    error("memory read word @ 0x%08X not word aligned, PC = 0x%08X",
          addr, cpuGetPC() - 4);
  }
  if (addr >= RAM_BASE && addr < RAM_BASE + RAM_SIZE) {
    if (addr >= GRAPH_BASE && addr < GRAPH_BASE + GRAPH_SIZE) {
      return graphRead((addr - GRAPH_BASE) >> 2);
    } else {
      return ram[(addr - RAM_BASE) >> 2];
    }
  }
  if (addr >= ROM_BASE && addr < ROM_BASE + ROM_SIZE) {
    return rom[(addr - ROM_BASE) >> 2];
  }
  if (addr >= IO_BASE && addr < IO_BASE + IO_SIZE) {
    return readIO((addr - IO_BASE) >> 2);
  }
  error("memory read word @ 0x%08X off bounds, PC = 0x%08X",
        addr, cpuGetPC() - 4);
  /* never reached */
  return 0;
}


void writeWord(Word addr, Word data) {
  addr &= ADDR_MASK;
  if ((addr & 3) != 0) {
    error("memory write word @ 0x%08X not word aligned, PC = 0x%08X",
          addr, cpuGetPC() - 4);
  }
  if (addr >= RAM_BASE && addr < RAM_BASE + RAM_SIZE) {
    if (addr >= GRAPH_BASE && addr < GRAPH_BASE + GRAPH_SIZE) {
      graphWrite((addr - GRAPH_BASE) >> 2, data);
    } else {
      ram[(addr - RAM_BASE) >> 2] = data;
    }
    return;
  }
  if (addr >= ROM_BASE && addr < ROM_BASE + ROM_SIZE) {
    error("PROM write word @ 0x%08X, PC = 0x%08X",
          addr, cpuGetPC() - 4);
  }
  if (addr >= IO_BASE && addr < IO_BASE + IO_SIZE) {
    writeIO((addr - IO_BASE) >> 2, data);
    return;
  }
  error("memory write word @ 0x%08X off bounds, PC = 0x%08X",
        addr, cpuGetPC() - 4);
}


Byte readByte(Word addr) {
  Word w;
  Byte b;

  w = readWord(addr & ~3);
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

  w = readWord(addr & ~3);
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
  writeWord(addr & ~3, w);
}


void promInit(char *promName) {
  FILE *promFile;
  Word addr;
  int lineno;
  char line[LINE_SIZE];
  char *p;
  Word data;
  char *endp;

  if (promName == NULL) {
    /* no PROM file to load */
    return;
  }
  promFile = fopen(promName, "r");
  if (promFile == NULL) {
    error("cannot open PROM file '%s'", promName);
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
    if (*(p + 0) == '/' &&
        *(p + 1) == '/') {
      continue;
    }
    data = strtoul(p, &endp, 16);
    rom[addr++] = data;
    p = endp;
    while (*p == ' ' || *p == '\t') {
      p++;
    }
    if (*p == '\n') {
      continue;
    }
    if (*(p + 0) == '/' &&
        *(p + 1) == '/') {
      continue;
    }
    error("garbage at end of line %d in PROM file '%s'",
          lineno, promName);
  }
  printf("0x%08X words loaded from PROM file '%s'\n",
         addr, promName);
  fclose(promFile);
}


void ramInit(char *ramName) {
  FILE *ramFile;
  Word addr;
  int lineno;
  char line[LINE_SIZE];
  char *p;
  Word data;
  char *endp;

  if (ramName == NULL) {
    /* no RAM file to load */
    return;
  }
  ramFile = fopen(ramName, "r");
  if (ramFile == NULL) {
    error("cannot open RAM file '%s'", ramName);
  }
  addr = 0;
  lineno = 0;
  while (fgets(line, LINE_SIZE, ramFile) != NULL) {
    lineno++;
    p = line;
    while (*p == ' ' || *p == '\t') {
      p++;
    }
    if (*p == '\n') {
      continue;
    }
    if (*(p + 0) == '/' &&
        *(p + 1) == '/') {
      continue;
    }
    data = strtoul(p, &endp, 16);
    ram[addr++] = data;
    p = endp;
    while (*p == ' ' || *p == '\t') {
      p++;
    }
    if (*p == '\n') {
      continue;
    }
    if (*(p + 0) == '/' &&
        *(p + 1) == '/') {
      continue;
    }
    error("garbage at end of line %d in RAM file '%s'",
          lineno, ramName);
  }
  printf("0x%08X words loaded from RAM file '%s'\n",
         addr, ramName);
  fclose(ramFile);
}


/**************************************************************/

/*
 * CPU
 */


static Bool debugIRQ = false;	/* set to true if debugging IRQs */

static Word pc;			/* program counter, as byte index */
static Word reg[16];		/* general purpose registers */
static Word ID;			/* special register for CPU identification */
static Word H;			/* special register for mul/div */
static Word X;			/* { 1'N, 1'Z, 1'C, 1'V, 1'I, 3'0, 24'pc } */
static Bool N, Z, C, V, I;	/* flags */
static unsigned irqAck;		/* interrupt last acknowledged */
static unsigned irqMask;	/* one bit for each IRQ */
static unsigned irqPending;	/* one bit for each pending IRQ */

static Bool breakSet;		/* breakpoint set if true */
static Word breakAddr;		/* if breakSet, this is where */

static Bool run;		/* CPU runs continuously if true */


static void execNextInstruction(void) {
  Word ir;
  int p, q, u, v;
  int ira, irb, op, irc;
  int imm;
  Word a, b, c, d;
  Word res;
  Word mask;
  Bool cond;
  Word aux;

  ir = readWord(pc);
  pc += 4;
  pc &= ADDR_MASK;
  p = (ir >> 31) & 0x01;
  q = (ir >> 30) & 0x01;
  u = (ir >> 29) & 0x01;
  v = (ir >> 28) & 0x01;
  ira = (ir >> 24) & 0x0F;
  irb = (ir >> 20) & 0x0F;
  op = (ir >> 16) & 0x0F;
  irc = ir & 0x0F;
  if (p == 0) {
    /* register instructions */
    imm = (v ? 0xFFFF0000 : 0x00000000) | (ir & 0x0000FFFF);
    b = reg[irb];
    c = reg[irc];
    d = q ? imm : c;
    switch (op) {
      case 0x00:
        /* MOV */
        if (q == 0) {
          /* register operand */
          if (u == 0) {
            /* general register */
            res = c;
          } else {
            /* special register */
            if (v == 0) {
              /* put special register */
              res = reg[ira];
              switch (irc) {
                case 0:
                  /* ID */
                  warning("PUTS to special register ID ignored");
                  break;
                case 1:
                  /* H */
                  H = res;
                  break;
                case 2:
                  /* X */
                  X = res;
                  break;
                case 3:
                  /* PSW */
                  N = (res >> 31) & 1;
                  Z = (res >> 30) & 1;
                  C = (res >> 29) & 1;
                  V = (res >> 28) & 1;
                  I = (res >> 27) & 1;
                  irqAck = (res >> 16) & 0x0000001F;
                  irqMask = (res >> 0) & 0x0000FFFF;
                  break;
                default:
                  error("PUTS with illegal special register %d", irc);
                  break;
              }
            } else {
              /* get special register */
              switch (irc) {
                case 0:
                  /* ID */
                  res = ID;
                  break;
                case 1:
                  /* H */
                  res = H;
                  break;
                case 2:
                  /* X */
                  res = X;
                  break;
                case 3:
                  /* PSW */
                  res = ((Word) N << 31) |
                        ((Word) Z << 30) |
                        ((Word) C << 29) |
                        ((Word) V << 28) |
                        ((Word) I << 27) |
                        (irqAck   << 16) |
                        (irqMask  <<  0);
                  break;
                default:
                  error("GETS with illegal special register %d", irc);
                  res = 0;
                  break;
              }
            }
          }
        } else {
          /* immediate operand */
          if (u == 0) {
            res = imm;
          } else {
            res = imm << 16;
          }
        }
        break;
      case 0x01:
        /* LSL */
        res = b << (d & 0x1F);
        break;
      case 0x02:
        /* ASR */
        mask = b & 0x80000000 ?
                 ~(((Word) 0xFFFFFFFF) >> (d & 0x1F)) : 0x00000000;
        res = mask | (b >> (d & 0x1F));
        break;
      case 0x03:
        /* ROR */
        res = (b << (-d & 0x1F)) | (b >> (d & 0x1F));
        break;
      case 0x04:
        /* AND */
        res = b & d;
        break;
      case 0x05:
        /* ANN */
        res = b & ~d;
        break;
      case 0x06:
        /* IOR */
        res = b | d;
        break;
      case 0x07:
        /* XOR */
        res = b ^ d;
        break;
      case 0x08:
        /* ADD */
        res = b + d + (u & C);
        C = res < b;
        V = ((res ^ d) & (res ^ b)) >> 31;
        break;
      case 0x09:
        /* SUB */
        res = b - d - (u & C);
        C = res > b;
        V = ((b ^ d) & (res ^ b)) >> 31;
        break;
      case 0x0A:
        /* MUL */
        intMul(b, d, u, &res, &H);
        break;
      case 0x0B:
        /* DIV */
        intDiv(b, d, u, &res, &H);
        break;
      case 0x0C:
        /* FAD, FLT, FLR */
        if (u == 0) {
          if (v == 0) {
            /* uv = 00 : FAD */
            res = fpAdd(b, c, false);
          } else {
            /* uv = 01 : FLR */
            res = fpFlr(b);
          }
        } else {
          if (v == 0) {
            /* uv = 10 : FLT */
            res = fpFlt(b);
          } else {
            /* uv = 11 : illegal */
            error("FAD with uv = 11 is illegal");
          }
        }
        break;
      case 0x0D:
        /* FSB */
        res = fpAdd(b, c, true);
        break;
      case 0x0E:
        /* FML */
        res = fpMul(b, c);
        break;
      case 0x0F:
        /* FDV */
        res = fpDiv(b, c);
        break;
    }
    reg[ira] = res;
    N = (res >> 31) & 1;
    Z = res == 0;
  } else {
    if (q == 0) {
      /* memory instructions */
      imm = SIGN_EXT_20(ir & 0x000FFFFF);
      a = reg[ira];
      b = reg[irb];
      if (u == 0) {
        /* load */
        if (v == 0) {
          /* word */
          res = readWord(b + imm);
        } else {
          /* byte */
          res = readByte(b + imm);
        }
        reg[ira] = res;
        N = (res >> 31) & 1;
        Z = res == 0;
      } else {
        /* store */
        if (v == 0) {
          /* word */
          writeWord(b + imm, a);
        } else {
          /* byte */
          writeByte(b + imm, a);
        }
      }
    } else {
      /* branch instructions */
      imm = ir & 0x003FFFFF;
      c = reg[irc];
      cond = (ira >> 3) & 1;
      switch (ira & 7) {
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
          cond ^= C | Z;
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
      if (u == 0) {
        /* branch target is in register */
        if (v == 0) {
          /* branch or interrupt handling */
          switch ((ir >> 4) & 3) {
            case 0:
              /* branch */
              if (cond) {
                pc = c & ADDR_MASK;
              }
              break;
            case 1:
              /* return from interrupt */
              N = (X >> 31) & 1;
              Z = (X >> 30) & 1;
              C = (X >> 29) & 1;
              V = (X >> 28) & 1;
              I = (X >> 27) & 1;
              pc = (X >> 0) & ADDR_MASK;
              break;
            case 2:
              /* interrupt disable/enable */
              I = ir & 1;
              break;
            case 3:
              /* undefined */
              error("undefined instruction 0x%08X, PC = 0x%08X",
                    ir, (pc - 4) & ADDR_MASK);
              break;
          }
        } else {
          /* call */
          if (cond) {
            aux = pc;
            pc = c & ADDR_MASK;
            reg[15] = aux;
          }
        }
      } else {
        /* branch target is pc + 4 + offset * 4 */
        if (v == 0) {
          /* branch */
          if (cond) {
            pc += imm << 2;
            pc &= ADDR_MASK;
          }
        } else {
          /* call */
          if (cond) {
            aux = pc;
            pc += imm << 2;
            pc &= ADDR_MASK;
            reg[15] = aux;
          }
        }
      }
    }
  }
}


static void handleInterrupts(void) {
  unsigned fullMask;
  unsigned irqSeen;
  int priority;

  /* handle exceptions and interrupts */
  if (irqPending == 0) {
    /* no exception or interrupt pending */
    return;
  }
  /* at least one exception or interrupt is pending */
  fullMask = 0xFFFF0000 | irqMask;
  if (debugIRQ) {
    printf("**** IRQ  = 0x%08X ****\n", irqPending);
    printf("**** MASK = 0x%08X ****\n", fullMask);
  }
  irqSeen = irqPending & irqMask;
  if (irqSeen == 0) {
    /* none that gets through */
    return;
  }
  /* determine the one with the highest priority */
  for (priority = 31; priority >= 0; priority--) {
    if ((irqSeen & ((unsigned) 1 << priority)) != 0) {
      /* highest priority among visible ones found */
      break;
    }
  }
  /* acknowledge exception, or interrupt if enabled */
  if (priority >= 16 || I) {
    if (priority >= 16) {
      /* clear corresponding bit in irqPending vector */
      /* only done for exceptions, since interrupts are level-sensitive */
      irqPending &= ~((unsigned) 1 << priority);
    }
    /* save interrupt status */
    X = ((Word) N << 31) |
        ((Word) Z << 30) |
        ((Word) C << 29) |
        ((Word) V << 28) |
        ((Word) I << 27) |
        (pc << 0);
    /* disable interrupts */
    I = false;
    /* start service routine */
    pc = EXC_VECTOR;
  }
}


Word cpuGetPC(void) {
  return pc;
}


void cpuSetPC(Word addr) {
  pc = addr & ADDR_MASK;
}


Word cpuGetReg(int regno) {
  return reg[regno & 0x0F];
}


void cpuSetReg(int regno, Word value) {
  reg[regno & 0x0F] = value;
}


Word cpuGetID(void) {
  return ID;
}


Word cpuGetH(void) {
  return H;
}


void cpuSetH(Word value) {
  H = value;
}


Word cpuGetX(void) {
  return X;
}


void cpuSetX(Word value) {
  X = value & 0xF8FFFFFF;
}


Word cpuGetPSW(void) {
  return ((Word) N << 31) |
         ((Word) Z << 30) |
         ((Word) C << 29) |
         ((Word) V << 28) |
         ((Word) I << 27) |
         (irqAck   << 16) |
         (irqMask  <<  0);
}


void cpuSetPSW(Word value) {
  N = (value >> 31) & 1;
  Z = (value >> 30) & 1;
  C = (value >> 29) & 1;
  V = (value >> 28) & 1;
  I = (value >> 27) & 1;
  irqAck = (value >> 16) & 0x0000001F;
  irqMask = (value >> 0) & 0x0000FFFF;
}


Word cpuGetIRQ(void) {
  return irqPending;
}


Bool cpuTestBreak(void) {
  return breakSet;
}


Word cpuGetBreak(void) {
  return breakAddr;
}


void cpuSetBreak(Word addr) {
  breakAddr = addr & ADDR_MASK;
  breakSet = true;
}


void cpuResetBreak(void) {
  breakSet = false;
}


void cpuStep(void) {
  tickTimer();
  tickSerial();
  execNextInstruction();
  handleInterrupts();
}


void cpuRun(void) {
  run = true;
  while (run) {
    tickTimer();
    tickSerial();
    execNextInstruction();
    handleInterrupts();
    if (breakSet && pc == breakAddr) {
      run = false;
    }
  }
}


void cpuHalt(void) {
  run = false;
}


void cpuSetInterrupt(int priority) {
  irqPending |= ((unsigned) 1 << priority);
}


void cpuResetInterrupt(int priority) {
  irqPending &= ~((unsigned) 1 << priority);
}


void cpuInit(Word initialPC) {
  int i;

  pc = initialPC;
  for (i = 0; i < 16; i++) {
    reg[i] = 0;
  }
  ID = CPU_ID;
  H = 0;
  X = 0;
  N = Z = C = V = I = false;
  irqAck = 0;
  irqMask = 0;
  irqPending = 0;
  breakSet = false;
}


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
      /* u = 1: move to/from special register */
      if (((instr >> 28) & 1) == 0) {
        /* v = 0: put special register */
        sprintf(instrBuffer, "%-7s R%d,%d", "PUTS", a, c);
      } else {
        /* v = 1: get special register */
        sprintf(instrBuffer, "%-7s R%d,%d", "GETS", a, c);
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
      sprintf(instrBuffer, "%-7s R%d,0x%08X", regOps[op], a, im << 16);
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
    /* u = 1: branch target is pc + 4 + offset * 4 */
    offset = instr & 0x003FFFFF;
    target = (locus + 4 + (offset << 2)) & ADDR_MASK;
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

/*
 * command interpreter
 */


static Bool quit;


typedef struct {
  char *name;
  void (*hlpProc)(void);
  void (*cmdProc)(char *tokens[], int n);
} Command;


extern Command commands[];
extern int numCommands;


static Bool getHexNumber(char *str, Word *valptr) {
  char *end;

  *valptr = strtoul(str, &end, 16);
  return *end == '\0';
}


static Bool getDecNumber(char *str, int *valptr) {
  char *end;

  *valptr = strtoul(str, &end, 10);
  return *end == '\0';
}


static void showPC(void) {
  Word pc;
  Word instr;

  pc = cpuGetPC();
  instr = readWord(pc);
  printf("PC   %06X     [PC]   %08X   %s\n",
         pc, instr, disasm(instr, pc));
}


static void showBreak(void) {
  Word brk;

  brk = cpuGetBreak();
  printf("Brk  ");
  if (cpuTestBreak()) {
    printf("%06X", brk);
  } else {
    printf("------");
  }
  printf("\n");
}


static void showIRQ(void) {
  Word irq;
  int i;

  irq = cpuGetIRQ();
  printf("IRQ                     ");
  for (i = 15; i >= 0; i--) {
    printf("%c", irq & (1 << i) ? '1' : '0');
  }
  printf("\n");
}


static void showPSW(void) {
  Word psw;
  int i;

  psw = cpuGetPSW();
  printf("     NZCVI xxxxxx ACK   MASK\n");
  printf("PSW  ");
  for (i = 31; i >= 0; i--) {
    if (i == 26 || i == 20 || i == 15) {
      printf(" ");
    }
    printf("%c", psw & (1 << i) ? '1' : '0');
  }
  printf("\n");
}


static void help(void) {
  printf("valid commands are:\n");
  printf("  help    get help\n");
  printf("  +       add and subtract\n");
  printf("  u       unassemble\n");
  printf("  b       set/reset breakpoint\n");
  printf("  c       continue from breakpoint\n");
  printf("  s       single-step\n");
  printf("  #       show/set PC\n");
  printf("  r       show/set register\n");
  printf("  rh      show/set H\n");
  printf("  rx      show/set X\n");
  printf("  rp      show/set PSW\n");
  printf("  d       dump memory\n");
  printf("  mw      show/set memory word\n");
  printf("  mb      show/set memory byte\n");
  printf("  ss      show/set switches\n");
  printf("  q       quit simulator\n");
  printf("type 'help <cmd>' to get help for <cmd>\n");
}


static void helpHelp(void) {
  printf("  help              show a list of commands\n");
  printf("  help <cmd>        show help for <cmd>\n");
}


static void doHelp(char *tokens[], int n) {
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


static void helpArith(void) {
  printf("  +  <num1> <num2>  add and subtract <num1> and <num2>\n");
}


static void doArith(char *tokens[], int n) {
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


static void helpUnassemble(void) {
  printf("  u                 unassemble 16 instrs starting at PC\n");
  printf("  u  <addr>         unassemble 16 instrs starting at <addr>\n");
  printf("  u  <addr> <cnt>   unassemble <cnt> instrs starting at <addr>\n");
}


static void doUnassemble(char *tokens[], int n) {
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
  addr &= ADDR_MASK;
  addr &= ~0x00000003;
  for (i = 0; i < count; i++) {
    instr = readWord(addr);
    printf("%06X:  %08X    %s\n",
           addr, instr, disasm(instr, addr));
    if (((addr + 4) & ADDR_MASK) < addr) {
      /* wrap-around */
      break;
    }
    addr += 4;
    addr &= ADDR_MASK;
  }
}


static void helpBreak(void) {
  printf("  b                 reset break\n");
  printf("  b  <addr>         set break at <addr>\n");
}


static void doBreak(char *tokens[], int n) {
  Word addr;

  if (n == 1) {
    cpuResetBreak();
    showBreak();
  } else if (n == 2) {
    if (!getHexNumber(tokens[1], &addr)) {
      printf("illegal address\n");
      return;
    }
    addr &= ADDR_MASK;
    addr &= ~0x00000003;
    cpuSetBreak(addr);
    showBreak();
  } else {
    helpBreak();
  }
}


static void helpContinue(void) {
  printf("  c                 continue execution\n");
  printf("  c  <cnt>          continue execution <cnt> times\n");
}


static void doContinue(char *tokens[], int n) {
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
  printf("Break at %06X\n", addr);
  showPC();
}


static void helpStep(void) {
  printf("  s                 single-step one instruction\n");
  printf("  s  <cnt>          single-step <cnt> instructions\n");
}


static void doStep(char *tokens[], int n) {
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


static void helpPC(void) {
  printf("  #                 show PC\n");
  printf("  #  <addr>         set PC to <addr>\n");
}


static void doPC(char *tokens[], int n) {
  Word addr;

  if (n == 1) {
    showPC();
  } else if (n == 2) {
    if (!getHexNumber(tokens[1], &addr)) {
      printf("illegal address\n");
      return;
    }
    addr &= ADDR_MASK;
    addr &= ~0x00000003;
    cpuSetPC(addr);
    showPC();
  } else {
    helpPC();
  }
}


static void helpRegister(void) {
  printf("  r                 show all registers\n");
  printf("  r  <reg>          show register <reg>\n");
  printf("  r  <reg> <data>   set register <reg> to <data>\n");
}


static void doRegister(char *tokens[], int n) {
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
    printf("ID   %08X     H    %08X     X    %08X\n",
           cpuGetID(), cpuGetH(), cpuGetX());
    showPSW();
    showIRQ();
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


static void helpH(void) {
  printf("  rh                show H\n");
  printf("  rh <data>         set H to <data>\n");
}


static void doH(char *tokens[], int n) {
  Word data;

  if (n == 1) {
    data = cpuGetH();
    printf("H    %08X\n", data);
  } else if (n == 2) {
    if (!getHexNumber(tokens[1], &data)) {
      printf("illegal data\n");
      return;
    }
    cpuSetH(data);
  } else {
    helpH();
  }
}


static void helpX(void) {
  printf("  rx                show X\n");
  printf("  rx <data>         set X to <data>\n");
}


static void doX(char *tokens[], int n) {
  Word data;

  if (n == 1) {
    data = cpuGetX();
    printf("X    %08X\n", data);
  } else if (n == 2) {
    if (!getHexNumber(tokens[1], &data)) {
      printf("illegal data\n");
      return;
    }
    cpuSetX(data);
  } else {
    helpX();
  }
}


static void helpPSW(void) {
  printf("  rp                show PSW\n");
  printf("  rp <data>         set PSW to <data>\n");
}


static void doPSW(char *tokens[], int n) {
  Word data;

  if (n == 1) {
    data = cpuGetPSW();
    printf("PSW  %08X\n", data);
  } else if (n == 2) {
    if (!getHexNumber(tokens[1], &data)) {
      printf("illegal data\n");
      return;
    }
    cpuSetPSW(data);
  } else {
    helpPSW();
  }
}


static void helpDump(void) {
  printf("  d                 dump 256 bytes starting at PC\n");
  printf("  d  <addr>         dump 256 bytes starting at <addr>\n");
  printf("  d  <addr> <cnt>   dump <cnt> bytes starting at <addr>\n");
}


static void doDump(char *tokens[], int n) {
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
  addr &= ADDR_MASK;
  lo = addr & ~0x0000000F;
  hi = (addr + count - 1) & ADDR_MASK;
  if (hi < lo) {
    /* wrap-around */
    hi = ADDR_MASK;
  }
  lines = (hi - lo + 16) >> 4;
  curr = lo;
  for (i = 0; i < lines; i++) {
    printf("%06X:  ", curr);
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


static void helpMemoryWord(void) {
  printf("  mw                show memory word at PC\n");
  printf("  mw <addr>         show memory word at <addr>\n");
  printf("  mw <addr> <data>  set memory word at <addr> to <data>\n");
}


static void doMemoryWord(char *tokens[], int n) {
  Word addr;
  Word data;
  Word tmpData;

  if (n == 1) {
    addr = cpuGetPC();
    data = readWord(addr);
    printf("%06X:  %08X\n", addr, data);
  } else if (n == 2) {
    if (!getHexNumber(tokens[1], &addr)) {
      printf("illegal address\n");
      return;
    }
    addr &= ADDR_MASK;
    addr &= ~0x00000003;
    data = readWord(addr);
    printf("%06X:  %08X\n", addr, data);
  } else if (n == 3) {
    if (!getHexNumber(tokens[1], &addr)) {
      printf("illegal address\n");
      return;
    }
    if (!getHexNumber(tokens[2], &tmpData)) {
      printf("illegal data\n");
      return;
    }
    addr &= ADDR_MASK;
    addr &= ~0x00000003;
    data = tmpData;
    writeWord(addr, data);
  } else {
    helpMemoryWord();
  }
}


static void helpMemoryByte(void) {
  printf("  mb                show memory byte at PC\n");
  printf("  mb <addr>         show memory byte at <addr>\n");
  printf("  mb <addr> <data>  set memory byte at <addr> to <data>\n");
}


static void doMemoryByte(char *tokens[], int n) {
  Word addr;
  Byte data;
  Word tmpData;

  if (n == 1) {
    addr = cpuGetPC();
    data = readByte(addr);
    printf("%06X:  %02X\n", addr, data);
  } else if (n == 2) {
    if (!getHexNumber(tokens[1], &addr)) {
      printf("illegal address\n");
      return;
    }
    addr &= ADDR_MASK;
    data = readByte(addr);
    printf("%06X:  %02X\n", addr, data);
  } else if (n == 3) {
    if (!getHexNumber(tokens[1], &addr)) {
      printf("illegal address\n");
      return;
    }
    if (!getHexNumber(tokens[2], &tmpData)) {
      printf("illegal data\n");
      return;
    }
    addr &= ADDR_MASK;
    data = (Byte) tmpData;
    writeByte(addr, data);
  } else {
    helpMemoryByte();
  }
}


static void helpSwitches(void) {
  printf("  ss                show button/switch settings\n");
  printf("  ss <data>         set buttons/switches to <data>\n");
}


static void doSwitches(char *tokens[], int n) {
  static char *st[2] = { "off", "on " };
  Word cs;

  if (n == 1) {
    cs = readSwitches();
    printf("buttons: %s %s %s %s",
           st[(cs >> 11) & 1], st[(cs >> 10) & 1],
           st[(cs >>  9) & 1], st[(cs >>  8) & 1]);
    printf("    ");
    printf("switches: %s %s %s %s %s %s %s %s\n",
           st[(cs >>  7) & 1], st[(cs >>  6) & 1],
           st[(cs >>  5) & 1], st[(cs >>  4) & 1],
           st[(cs >>  3) & 1], st[(cs >>  2) & 1],
           st[(cs >>  1) & 1], st[(cs >>  0) & 1]);
  } else
  if (n == 2) {
    if (!getHexNumber(tokens[1], &cs)) {
      printf("illegal data\n");
      return;
    }
    setSwitches(cs);
  } else {
    helpSwitches();
  }
}


static void helpQuit(void) {
  printf("  q                 quit simulator\n");
}


static void doQuit(char *tokens[], int n) {
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
  { "rh",   helpH,          doH          },
  { "rx",   helpX,          doX          },
  { "rp",   helpPSW,        doPSW        },
  { "d",    helpDump,       doDump       },
  { "mw",   helpMemoryWord, doMemoryWord },
  { "mb",   helpMemoryByte, doMemoryByte },
  { "ss",   helpSwitches,   doSwitches   },
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


static void usage(char *myself) {
  printf("Usage: %s\n", myself);
  printf("    [-i]                set interactive mode\n");
  printf("    [-p <PROM>]         set PROM image file name\n");
  printf("    [-r <RAM>]          set RAM image file name\n");
  printf("    [-d <disk>]         set disk image file name\n");
  printf("    [-s <3 nibbles>]    set initial buttons(1)/switches(2)\n");
  exit(1);
}


static void sigIntHandler(int signum) {
  signal(SIGINT, sigIntHandler);
  cpuHalt();
}


int main(int argc, char *argv[]) {
  int i;
  char *argp;
  Bool interactive;
  char *promName;
  char *ramName;
  char *diskName;
  Word initialSwitches;
  char *endp;
  char command[20];
  char *line;

  interactive = false;
  promName = NULL;
  ramName = NULL;
  diskName = NULL;
  initialSwitches = 0;
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
    } else
    if (strcmp(argp, "-r") == 0) {
      if (i == argc - 1 || ramName != NULL) {
        usage(argv[0]);
      }
      ramName = argv[++i];
    } else
    if (strcmp(argp, "-d") == 0) {
      if (i == argc - 1 || diskName != NULL) {
        usage(argv[0]);
      }
      diskName = argv[++i];
    } else
    if (strcmp(argp, "-s") == 0) {
      if (i == argc - 1) {
        usage(argv[0]);
      }
      i++;
      initialSwitches = strtoul(argv[i], &endp, 16);
      if (*endp != '\0') {
        error("illegal button/switch value, must be 3 hex digits");
      }
    } else {
      usage(argv[0]);
    }
  }
  signal(SIGINT, sigIntHandler);
  printf("RISC5 Simulator started\n");
  if (promName == NULL && !interactive) {
    printf("No PROM file was specified, ");
    printf("so interactive mode is assumed.\n");
    interactive = true;
  }
  initTimer();
  initSWLED(initialSwitches);
  initRS232();
  initSPI(diskName);
  initMouseKeybd();
  initGPIO();
  initFPU();
  graphInit();
  promInit(promName);
  ramInit(ramName);
  cpuInit(INITIAL_PC);
  if (!interactive) {
    printf("Start executing...\n");
    strcpy(command, "c\n");
    execCommand(command);
  } else {
    while (1) {
      line = gl_getline("RISC5 > ");
      if (*line == '\0') {
        break;
      }
      gl_histadd(line);
      if (execCommand(line)) {
        break;
      }
    }
  }
  graphExit();
  printf("RISC5 Simulator finished\n");
  return 0;
}
