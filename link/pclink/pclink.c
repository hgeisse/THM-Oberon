/*
 * pclink.c -- serial line file transfer program
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>


#define MAX_RETRIES	5
#define MAX_WAIT	1000000

#define REQ		((unsigned char) 0x20)
#define REC		((unsigned char) 0x21)
#define SND		((unsigned char) 0x22)
#define ACK		((unsigned char) 0x10)
#define NAK		((unsigned char) 0x11)


static int debug = 0;

static int sfd = -1;
static struct termios origOptions;
static struct termios currOptions;


void serialClose(void);


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


void serialOpen(char *serialPort) {
  sfd = open(serialPort, O_RDWR | O_NOCTTY | O_NDELAY);
  if (sfd == -1) {
    error("cannot open serial port '%s'", serialPort);
  }
  tcgetattr(sfd, &origOptions);
  currOptions = origOptions;
  cfsetispeed(&currOptions, B38400);
  cfsetospeed(&currOptions, B38400);
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


int connect(void) {
  unsigned char b;
  int retries;
  int wait;

  retries = MAX_RETRIES;
  while (retries--) {
    printf("Trying to connect... ");
    fflush(stdout);
    while (serialRcv(&b)) ;
    while (!serialSnd(REQ)) ;
    wait = MAX_WAIT;
    while (!serialRcv(&b) && --wait != 0) ;
    if (wait != 0 && b == ACK) {
      printf("connected to Oberon system\n");
      return 1;
    }
    if (wait != 0) {
      printf("no ACK from Oberon system\n");
    } else {
      printf("no answer from Oberon system\n");
    }
  }
  return 0;
}


int sendName(char *name) {
  unsigned char b;

  while (*name != '\0') {
    while (!serialSnd(*name)) ;
    name++;
  }
  while (!serialSnd('\0')) ;
  while (!serialRcv(&b)) ;
  return b == ACK;
}


int sendContents(FILE *file) {
  unsigned char buf[255];
  int n, i;
  unsigned char b;

  while (1) {
    n = fread(buf, 1, 255, file);
    if (n < 0) {
      error("cannot read local file");
    }
    if (n == 0) {
      if (debug) {
        printf("SEND 0\n");
      }
      while (!serialSnd(0)) ;
      while (!serialRcv(&b)) ;
      return b == ACK;
    }
    if (debug) {
      printf("SEND %d\n", n);
    }
    while (!serialSnd(n & 0xFF)) ;
    for (i = 0; i < n; i++) {
      while (!serialSnd(buf[i])) ;
    }
    while (!serialRcv(&b)) ;
    if (b != ACK) {
      return 0;
    }
    if (n < 255) {
      return 1;
    }
  }
}


int recvContents(FILE *file) {
  unsigned char buf[255];
  int n, i;
  unsigned char b;

  while (1) {
    while (!serialRcv(&b)) ;
    n = b;
    if (n == 0) {
      if (debug) {
        printf("RECV 0\n");
      }
      while (!serialSnd(ACK)) ;
      return 1;
    }
    if (debug) {
      printf("RECV %d\n", n);
    }
    for (i = 0; i < n; i++) {
      while (!serialRcv(&buf[i])) ;
    }
    if (fwrite(buf, 1, n, file) != n) {
      error("cannot write local file");
    }
    while (!serialSnd(ACK)) ;
    if (n < 255) {
      return 1;
    }
  }
}


void usage(char *myself) {
  printf("Usage: %s -p <serial port>\n", myself);
  printf("       %s -p <serial port> -s <file>\n", myself);
  printf("       %s -p <serial port> -r <file>\n", myself);
  exit(1);
}


int main(int argc, char *argv[]) {
  int i;
  char *argp;
  int action;
  char *serialPort;
  char *fileName;
  FILE *file;

  action = 0;
  serialPort = NULL;
  fileName = NULL;
  for (i = 1; i < argc; i++) {
    argp = argv[i];
    if (*argp == '-') {
      /* option */
      if (strcmp(argp, "-p") == 0) {
        if (i == argc - 1 || serialPort != NULL) {
          usage(argv[0]);
        }
        i++;
        serialPort = argv[i];
      } else
      if (strcmp(argp, "-s") == 0) {
        action = 1;
        if (i == argc - 1 || fileName != NULL) {
          usage(argv[0]);
        }
        i++;
        fileName = argv[i];
      } else
      if (strcmp(argp, "-r") == 0) {
        action = 2;
        if (i == argc - 1 || fileName != NULL) {
          usage(argv[0]);
        }
        i++;
        fileName = argv[i];
      } else {
        usage(argv[0]);
      }
    } else {
      usage(argv[0]);
    }
  }
  if (serialPort == NULL) {
    error("no serial port specified");
  }
  serialOpen(serialPort);
  if (!connect()) {
    error("too many retries");
  }
  if (action == 0) {
    /* check connection to Oberon system */
    printf("PCLink1 is running on Oberon system\n");
  } else
  if (action == 1) {
    /* send file (receive in Oberon system) */
    file = fopen(fileName, "r");
    if (file == NULL) {
      error("cannot open local file '%s' for write", fileName);
    }
    while (!serialSnd(REC)) ;
    if (!sendName(fileName)) {
      error("no ACK for filename from Oberon system");
    }
    if (!sendContents(file)) {
      error("cannot send file contents");
    }
    fclose(file);
    printf("file '%s' sent successfully\n", fileName);
  } else {
    /* receive file (send in Oberon system) */
    file = fopen(fileName, "w");
    if (file == NULL) {
      error("cannot open local file '%s' for read", fileName);
    }
    while (!serialSnd(SND)) ;
    if (!sendName(fileName)) {
      error("no ACK for filename from Oberon system");
    }
    if (!recvContents(file)) {
      error("cannot receive file contents");
    }
    fclose(file);
    printf("file '%s' received successfully\n", fileName);
  }
  serialClose();
  return 0;
}
