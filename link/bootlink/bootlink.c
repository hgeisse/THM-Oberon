/*
 * bootlink.c -- serial line boot support
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>


//#define MAX_RETRIES	5
//#define MAX_WAIT	1000000

//#define REQ		((unsigned char) 0x20)
//#define REC		((unsigned char) 0x21)
//#define SND		((unsigned char) 0x22)
//#define ACK		((unsigned char) 0x10)
//#define NAK		((unsigned char) 0x11)


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


void usage(char *myself) {
  printf("Usage: %s -p <serial port> -b <boot file>\n", myself);
  exit(1);
}


int main(int argc, char *argv[]) {
  int i;
  char *argp;
  char *serialPort;
  char *bootName;
  FILE *bootFile;

  serialPort = NULL;
  bootName = NULL;
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
      if (strcmp(argp, "-b") == 0) {
        if (i == argc - 1 || bootName != NULL) {
          usage(argv[0]);
        }
        i++;
        bootName = argv[i];
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
  if (bootName == NULL) {
    error("no boot file specified");
  }
  serialOpen(serialPort);
  serialClose();
  return 0;
}
