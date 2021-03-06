/*
 * serlink.c -- serial line link support
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>


#define SERDEV_FILE	"serial.dev"

#define BLOCK_SIZE	512

#define LINE_SIZE	200
#define MAX_TOKENS	20

#define ACK		((unsigned char) 0x10)
#define NAK		((unsigned char) 0x11)

#define REQ		((unsigned char) 0x20)
#define REC		((unsigned char) 0x21)
#define SND		((unsigned char) 0x22)
#define CAL		((unsigned char) 0x23)

#define CMD_INSPECT	1
#define CMD_FILLDSP	2
#define CMD_SECTOR	3
#define CMD_SHFILE	4
#define CMD_WATCH	7
#define CMD_MIRROR	8
#define CMD_SHMOD	10
#define CMD_SHCMD	11
#define CMD_DIR		12
#define CMD_DEL		13
#define CMD_LOAD	20
#define CMD_UNLOAD	21
#define CMD_CALL	22
//#define CMD_	50
//#define CMD_	51
//#define CMD_	52
//#define CMD_	53
#define CMD_LDBOOT	100
#define CMD_CLRDIR	101
#define CMD_EXEC	102


typedef struct {
  char *name;
  int minArgc;
  void (*func)(int argc, char *argv[]);
} Cmd;


static int sfd = -1;
static struct termios origOptions;
static struct termios currOptions;

static int run;


void serialClose(void);
Cmd *lookupCmd(char *name);


/**************************************************************/


void error(char *fmt, ...) {
  va_list ap;

  va_start(ap, fmt);
  printf("Error: ");
  vprintf(fmt, ap);
  printf("\n");
  va_end(ap);
  serialClose();
  exit(1);
}


int tokenize(char *line, char *tokens[], int maxTokens) {
  int n;
  char *p;

  n = 0;
  p = strtok(line, " \t\n\r");
  while (p != NULL) {
    if (n < maxTokens) {
      tokens[n++] = p;
    }
    p = strtok(NULL, " \t\n\r");
  }
  return n;
}


/**************************************************************/


void serialOpen(char *serialPort) {
  sfd = open(serialPort, O_RDWR | O_NOCTTY | O_NDELAY);
  if (sfd == -1) {
    error("cannot open serial port '%s'", serialPort);
  }
  tcgetattr(sfd, &origOptions);
  currOptions = origOptions;
  cfsetispeed(&currOptions, B9600);
  cfsetospeed(&currOptions, B9600);
  currOptions.c_cflag |= (CLOCAL | CREAD);
  currOptions.c_cflag &= ~PARENB;
  currOptions.c_cflag &= ~CSTOPB;
  currOptions.c_cflag &= ~CSIZE;
  currOptions.c_cflag |= CS8;
  currOptions.c_cflag &= ~CRTSCTS;
  currOptions.c_lflag &= ~(ICANON | ECHO | ECHONL | ISIG | IEXTEN);
  currOptions.c_iflag &= ~(IGNBRK | BRKINT | IGNPAR | PARMRK);
  currOptions.c_iflag &= ~(INPCK | ISTRIP | INLCR | IGNCR | ICRNL);
  currOptions.c_iflag &= ~(IXON | IXOFF | IXANY);
  currOptions.c_oflag &= ~(OPOST | ONLCR | OCRNL | ONOCR | ONLRET);
  tcsetattr(sfd, TCSANOW, &currOptions);
}


void serialClose(void) {
  if (sfd < 0) {
    return;
  }
  tcsetattr(sfd, TCSANOW, &origOptions);
  close(sfd);
  sfd = -1;
}


int serialSnd(unsigned char b) {
  int n;

  n = write(sfd, &b, 1);
  return n == 1;
}


int serialRcv(unsigned char *bp) {
  int n;

  n = read(sfd, bp, 1);
  return n == 1;
}


/**************************************************************/


unsigned char rcvByte(void) {
  unsigned char b;

  while (!serialRcv(&b)) ;
  return b;
}


int rcvInt(void) {
  int i;
  unsigned char b;

  i = 0;
  while (!serialRcv(&b)) ;
  i |= (unsigned int) b <<  0;
  while (!serialRcv(&b)) ;
  i |= (unsigned int) b <<  8;
  while (!serialRcv(&b)) ;
  i |= (unsigned int) b << 16;
  while (!serialRcv(&b)) ;
  i |= (unsigned int) b << 24;
  return i;
}


char *rcvStr(void) {
  static char buf[100];
  int i;
  unsigned char b;

  i = 0;
  do {
    while (!serialRcv(&b)) ;
    buf[i] = b;
    i++;
  } while (b != '\0');
  return buf;
}


void sndByte(unsigned char b) {
  while (!serialSnd(b)) ;
}


void sndInt(unsigned int i) {
  while (!serialSnd((i >>  0) & 0xFF)) ;
  while (!serialSnd((i >>  8) & 0xFF)) ;
  while (!serialSnd((i >> 16) & 0xFF)) ;
  while (!serialSnd((i >> 24) & 0xFF)) ;
}


void sndStr(char *s) {
  while (*s != '\0') {
    sndByte(*s);
    s++;
  }
  sndByte(0);
}


/**************************************************************/


int sendBootFile(FILE *bootFile, unsigned int addr) {
  unsigned char buf[BLOCK_SIZE];
  int n, i;
  unsigned char b;

  while (1) {
    n = fread(buf, 1, BLOCK_SIZE, bootFile);
    if (n < 0) {
      error("cannot read boot file");
    }
    if (n == 0) {
      break;
    }
    sndInt(n);
    sndInt(addr);
    for (i = 0; i < n; i++) {
      sndByte(buf[i]);
    }
    addr += n;
    if (n < BLOCK_SIZE) {
      break;
    }
  }
  sndInt(0);
  b = rcvByte();
  return b == ACK;
}


/**************************************************************/


void getAndShowAnswer(void) {
  int run;
  unsigned char type;
  unsigned char b;
  int n;

  run = 1;
  while (run) {
    type = rcvByte();
    switch (type) {
      case 1:
        /* integer */
        n = rcvInt();
        printf("%6d  ", n);
        break;
      case 2:
        /* hex */
        n = rcvInt();
        printf("0x%08X  ", n);
        break;
      case 3:
        /* real */
        printf("!!! real not yet\n");
        break;
      case 4:
        /* string */
        while (1) {
          b = rcvByte();
          if (b == 0) {
            break;
          }
          printf("%c", b);
        }
        printf("  ");
        break;
      case 5:
        /* char */
        b = rcvByte();
        printf("%c", b);
        break;
      case 6:
        /* line */
        printf("\n");
        break;
      case 7:
        /* end */
        run = 0;
        break;
      default:
        printf("unknown type byte %u\n", (unsigned int) type);
    }
  }
  printf("\n");
}


/**************************************************************/


void ping(int argc, char *argv[]) {
  unsigned char b;

  sndByte(REQ);
  b = rcvByte();
  if (b == ACK) {
    printf("ACK from Oberon system\n");
  } else
  if (b == NAK) {
    printf("NAK from Oberon system\n");
  } else {
    printf("error: unknown answer from Oberon system\n");
  }
}


void h2oSingleFile(char *name) {
  FILE *file;
  unsigned char b;
  unsigned char buf[255];
  int n, i;

  file = fopen(name, "r");
  if (file == NULL) {
    printf("error: cannot open file '%s' for read on host\n", name);
    return;
  }
  sndByte(REC);
  b = rcvByte();
  if (b != ACK) {
    printf("error: no ACK from Oberon system for REC request\n");
    fclose(file);
    return;
  }
  sndStr(name);
  b = rcvByte();
  if (b != ACK) {
    printf("error: no ACK for filename '%s' from Oberon system\n", name);
    fclose(file);
    return;
  }
  while (1) {
    n = fread(buf, 1, 255, file);
    if (n < 0) {
      error("cannot read local file");
    }
    if (n == 0) {
      sndByte(0);
      b = rcvByte();
      if (b != ACK) {
        printf("error: no ACK for file data from Oberon system\n");
        fclose(file);
        return;
      }
      break;
    }
    sndByte(n & 0xFF);
    for (i = 0; i < n; i++) {
      sndByte(buf[i]);
    }
    b = rcvByte();
    if (b != ACK) {
      printf("error: no ACK for file data from Oberon system\n");
      fclose(file);
      return;
    }
    if (n < 255) {
      break;
    }
  }
  fclose(file);
  sndByte(REQ);
  b = rcvByte();
  if (b != ACK) {
    printf("error: no ACK from Oberon system (file '%s')\n", name);
  } else {
    printf("ACK from Oberon system (file '%s')\n", name);
  }
}


void h2o(int argc, char *argv[]) {
  int i;

  for (i = 1; i < argc; i++) {
    h2oSingleFile(argv[i]);
  }
}


void o2hSingleFile(char *name) {
  FILE *file;
  unsigned char b;
  unsigned char buf[255];
  int n, i;

  file = fopen(name, "w");
  if (file == NULL) {
    printf("error: cannot open file '%s' for write on host\n", name);
    return;
  }
  sndByte(SND);
  b = rcvByte();
  if (b != ACK) {
    printf("error: no ACK from Oberon system for SND request\n");
    fclose(file);
    return;
  }
  sndStr(name);
  b = rcvByte();
  if (b != ACK) {
    printf("error: no ACK for filename '%s' from Oberon system\n", name);
    fclose(file);
    return;
  }
  while (1) {
    n = rcvByte();
    if (n == 0) {
      sndByte(ACK);
      break;
    }
    for (i = 0; i < n; i++) {
      buf[i] = rcvByte();
    }
    if (fwrite(buf, 1, n, file) != n) {
      error("cannot write local file");
    }
    sndByte(ACK);
    if (n < 255) {
      break;
    }
  }
  fclose(file);
  sndByte(REQ);
  b = rcvByte();
  if (b != ACK) {
    printf("error: no ACK from Oberon system (file '%s')\n", name);
  } else {
    printf("ACK from Oberon system (file '%s')\n", name);
  }
}


void o2h(int argc, char *argv[]) {
  int i;

  for (i = 1; i < argc; i++) {
    o2hSingleFile(argv[i]);
  }
}


void calln(int argc, char *argv[]) {
  unsigned char b;
  int i;
  char *res;

  sndByte(CAL);
  b = rcvByte();
  if (b != ACK) {
    printf("error: no ACK from Oberon system for CAL request\n");
    return;
  }
  sndStr(argv[1]);
  b = rcvByte();
  if (b != ACK) {
    printf("error: no ACK for command '%s' from Oberon system\n", argv[1]);
    return;
  }
  sndByte(argc - 2);
  for (i = 2; i < argc; i++) {
    sndStr(argv[i]);
    b = rcvByte();
    if (b != ACK) {
      printf("error: no ACK for argument '%s' from Oberon system\n", argv[i]);
      return;
    }
  }
  res = rcvStr();
  printf("result = '%s'\n", res);
}


void xscript(int argc, char *argv[]) {
  FILE *script;
  int lnum;
  char line[LINE_SIZE];
  char *tokens[MAX_TOKENS];
  int n;
  Cmd *cmd;

  script = fopen(argv[1], "r");
  if (script == NULL) {
    printf("error: cannot open script file '%s'\n", argv[1]);
    return;
  }
  lnum = 0;
  while (run && fgets(line, LINE_SIZE, script) != NULL) {
    lnum++;
    printf("line %d: %s", lnum, line);
    n = tokenize(line, tokens, MAX_TOKENS);
    if (n == 0) {
      continue;
    }
    if (*tokens[0] == '#') {
      continue;
    }
    cmd = lookupCmd(tokens[0]);
    if (cmd == NULL) {
      printf("error in script: unknown command '%s'\n",
             tokens[0]);
      continue;
    }
    if (n < cmd->minArgc) {
      printf("error in script: too few arguments for command '%s'\n",
             tokens[0]);
      continue;
    }
    (*cmd->func)(n, tokens);
  }
  fclose(script);
}


void help(int argc, char *argv[]) {
  printf("Local commands:\n");
  printf("  @       <file>       execute commands from script file\n");
  printf("  h                    help\n");
  printf("  q                    quit\n");
  printf("Remote commands (if talking to PCLink2):\n");
  printf("  p                    check if Oberon system is responding\n");
  printf("  h2o     <file> ...   transfer files from host to Oberon\n");
  printf("  o2h     <file> ...   transfer files from Oberon to host\n");
  printf("  calln   <name> ...   call command <name>, possibly with args\n");
  printf("Remote commands (if talking to Oberon0):\n");
  printf("  p                    check if Oberon system is responding\n");
  printf("  h2o     <file> ...   transfer files from host to Oberon\n");
  printf("  o2h     <file> ...   transfer files from Oberon to host\n");
  printf("  inspect <a> <n>      show <n> words of memory at addr <a>\n");
  printf("  filldsp <integer>    fill display with <integer>\n");
  printf("  sector  <secno>      show disk sector <secno>\n");
  printf("  shfile  <file>       show <file>\n");
  printf("  watch                watch\n");
  printf("  mirror  <integer>    mirror <integer> back\n");
  printf("  shmod                show modules\n");
  printf("  shcmd   <module>     show commands for <module>\n");
  printf("  dir     <prefix>     show directory for <prefix>\n");
  printf("  del     <file>       delete <file>\n");
  printf("  load    <module>     load <module>\n");
  printf("  unload  <module>     unload <module>\n");
  printf("  call    <name>       call command <name>\n");
  printf("  ldboot  <file>       load boot area from <file>\n");
  printf("  clrdir               clear directory\n");
  printf("  exec    <file>       execute standalone program <file>\n");
}


void quit(int argc, char *argv[]) {
  run = 0;
}


/**************************************************************/


void inspect(int argc, char *argv[]) {
  int a;
  int n;
  char *endp;

  a = strtol(argv[1], &endp, 0);
  if (*endp != '\0') {
    printf("error: cannot read address\n");
    return;
  }
  n = strtol(argv[2], &endp, 0);
  if (*endp != '\0') {
    printf("error: cannot read count\n");
    return;
  }
  sndInt(CMD_INSPECT);
  sndInt(a);
  sndInt(n);
  getAndShowAnswer();
}


void filldsp(int argc, char *argv[]) {
  int arg;
  char *endp;

  arg = strtol(argv[1], &endp, 0);
  if (*endp != '\0') {
    printf("error: cannot read filler number\n");
    return;
  }
  sndInt(CMD_FILLDSP);
  sndInt(arg);
  getAndShowAnswer();
}


void sector(int argc, char *argv[]) {
  int secno;
  char *endp;

  secno = strtol(argv[1], &endp, 0);
  if (*endp != '\0') {
    printf("error: cannot read sector number\n");
    return;
  }
  sndInt(CMD_SECTOR);
  sndInt(secno);
  getAndShowAnswer();
}


void shfile(int argc, char *argv[]) {
  sndInt(CMD_SHFILE);
  sndStr(argv[1]);
  getAndShowAnswer();
}


void watch(int argc, char *argv[]) {
  sndInt(CMD_WATCH);
  getAndShowAnswer();
}


void mirror(int argc, char *argv[]) {
  int arg;
  char *endp;

  arg = strtol(argv[1], &endp, 10);
  if (*endp != '\0') {
    printf("error: cannot read number to mirror\n");
    return;
  }
  sndInt(CMD_MIRROR);
  sndInt(arg);
  getAndShowAnswer();
}


void shmod(int argc, char *argv[]) {
  sndInt(CMD_SHMOD);
  getAndShowAnswer();
}


void shcmd(int argc, char *argv[]) {
  sndInt(CMD_SHCMD);
  sndStr(argv[1]);
  getAndShowAnswer();
}


void dir(int argc, char *argv[]) {
  sndInt(CMD_DIR);
  sndStr(argv[1]);
  getAndShowAnswer();
}


void del(int argc, char *argv[]) {
  sndInt(CMD_DEL);
  sndStr(argv[1]);
  getAndShowAnswer();
}


void load(int argc, char *argv[]) {
  sndInt(CMD_LOAD);
  sndStr(argv[1]);
  getAndShowAnswer();
}


void unload(int argc, char *argv[]) {
  sndInt(CMD_UNLOAD);
  sndStr(argv[1]);
  getAndShowAnswer();
}


void call(int argc, char *argv[]) {
  sndInt(CMD_CALL);
  sndStr(argv[1]);
  getAndShowAnswer();
}


void ldboot(int argc, char *argv[]) {
  sndInt(CMD_LDBOOT);
  sndStr(argv[1]);
  getAndShowAnswer();
}


void clrdir(int argc, char *argv[]) {
  sndInt(CMD_CLRDIR);
  getAndShowAnswer();
}


void exec(int argc, char *argv[]) {
  sndInt(CMD_EXEC);
  sndStr(argv[1]);
  getAndShowAnswer();
}


/**************************************************************/


Cmd cmds[] = {
  { "p",        1, ping     },
  { "h2o",      2, h2o      },
  { "o2h",      2, o2h      },
  { "@",        2, xscript  },
  { "h",        1, help     },
  { "q",        1, quit     },
  /* --------------------- */
  { "inspect",  3, inspect  },
  { "filldsp",  2, filldsp  },
  { "sector",   2, sector   },
  { "shfile",   2, shfile   },
  { "watch",    1, watch    },
  { "mirror",   2, mirror   },
  { "shmod",    1, shmod    },
  { "shcmd",    2, shcmd    },
  { "dir",      2, dir      },
  { "del",      2, del      },
  { "load",     2, load     },
  { "unload",   2, unload   },
  { "call",     2, call     },
  { "calln",    2, calln    },
  { "ldboot",   2, ldboot   },
  { "clrdir",   1, clrdir   },
  { "exec",     2, exec     },
};


Cmd *lookupCmd(char *name) {
  int i;

  for (i = 0; i < sizeof(cmds) / sizeof(cmds[0]); i++) {
    if (strcmp(cmds[i].name, name) == 0) {
      return &cmds[i];
    }
  }
  return NULL;
}


/**************************************************************/


void usage(char *myself) {
  printf("Usage: %s [<boot file>]\n", myself);
  exit(1);
}


int main(int argc, char *argv[]) {
  FILE *serdevFile;
  char serialPort[LINE_SIZE];
  char *bootName;
  FILE *bootFile;
  unsigned char b;
  char line[LINE_SIZE];
  char *tokens[MAX_TOKENS];
  int n;
  Cmd *cmd;

  if (argc != 1 && argc != 2) {
    usage(argv[0]);
  }
  serdevFile = fopen(SERDEV_FILE, "r");
  if (serdevFile == NULL) {
    error("cannot open file '%s' for reading the\npath to "
          "the serial device. Please create this file.",
          SERDEV_FILE);
  }
  if (fgets(serialPort, LINE_SIZE, serdevFile) == NULL) {
    error("cannot read file '%s' (should contain a valid path).",
          SERDEV_FILE);
  }
  fclose(serdevFile);
  n = strlen(serialPort) - 1;
  if (serialPort[n] == '\n') {
    serialPort[n] = '\0';
  }
  if (argc == 1) {
    bootName = NULL;
  } else {
    bootName = argv[1];
  }
  serialOpen(serialPort);
  while (serialRcv(&b)) ;
  if (bootName != NULL) {
    bootFile = fopen(bootName, "r");
    if (bootFile == NULL) {
      error("cannot open boot file '%s'", bootName);
    }
    printf("Sending boot file '%s', please wait...\n", bootName);
    if (sendBootFile(bootFile, 0)) {
      printf("Sending boot file succeeded.\n");
    } else {
      printf("Sending boot file failed.\n");
    }
    fclose(bootFile);
  }
  run = 1;
  while (run) {
    printf("cmd > ");
    fflush(stdout);
    if (fgets(line, LINE_SIZE, stdin) == NULL) {
      printf("\n");
      break;
    }
    n = tokenize(line, tokens, MAX_TOKENS);
    if (n == 0) {
      continue;
    }
    cmd = lookupCmd(tokens[0]);
    if (cmd == NULL) {
      printf("error: unknown command '%s', try 'h' for help\n", tokens[0]);
      continue;
    }
    if (n < cmd->minArgc) {
      printf("error: too few arguments for command '%s'\n", tokens[0]);
      continue;
    }
    (*cmd->func)(n, tokens);
  }
  serialClose();
  return 0;
}
