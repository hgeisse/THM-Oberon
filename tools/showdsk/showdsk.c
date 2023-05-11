/*
 * showdsk.c -- Oberon disk viewer
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>


#define BLOCK_SIZE	512	/* storage unit on SD card, bytes */
#define SECTOR_SIZE	1024	/* storage unit of file system, bytes */
#define BPS		(SECTOR_SIZE / BLOCK_SIZE)

#define SECTOR_FACTOR	29	/* factor used for storing sector numbers */

#define LINE_SIZE	100	/* input line buffer size in bytes */
#define LINES_PER_BATCH	32	/* number of lines output in one batch */


/**************************************************************/


typedef unsigned int Word;
typedef unsigned char Byte;

typedef enum { false = 0, true = 1 } bool;


/**************************************************************/


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


void readSector(FILE *disk, Word sector, Byte *buffer) {
  fseek(disk, (unsigned long) sector * SECTOR_SIZE, SEEK_SET);
  if (fread(buffer, SECTOR_SIZE, 1, disk) != 1) {
    error("cannot read sector %u (0x%X)", sector, sector);
  }
}


/**************************************************************/


bool waitForReturn(void) {
  char line[LINE_SIZE];

  printf("press <enter> to continue, <esc> to break, q to quit: ");
  fflush(stdout);
  if (fgets(line, LINE_SIZE, stdin) == NULL) {
    printf("\n");
    exit(0);
  }
  if (line[0] == 'q') {
    exit(0);
  }
  if (line[0] == 0x1B) {
    return true;
  }
  return false;
}


bool checkBatch(int numLines) {
  static int lines;
  bool r;

  r = false;
  if (numLines == 0) {
    /* initialize */
    lines = 0;
  } else {
    /* output numLines lines */
    lines += numLines;
    if (lines >= LINES_PER_BATCH) {
      r = waitForReturn();
      lines = 0;
    }
  }
  return r;
}


/**************************************************************/


void showRawSector(Byte *p) {
  int i, j;
  Byte c;

  checkBatch(0);
  for (i = 0; i < SECTOR_SIZE / 16; i++) {
    printf("%04X   ", i * 16);
    for (j = 0; j < 16; j++) {
      c = p[i * 16 + j];
      printf("%02X ", c);
    }
    printf("   ");
    for (j = 0; j < 16; j++) {
      c = p[i * 16 + j];
      if (c < 0x20 || c >= 0x7F) {
        printf(".");
      } else {
        printf("%c", c);
      }
    }
    printf("\n");
    if (checkBatch(1)) return;
  }
}


/**************************************************************/


#define DIR_MARK	0x9B1EA38D	/* magic number for directory page */
#define FN_LENGTH	32	/* max length of file name */
#define FILLER_SIZE	52	/* area not used in a directory page */
#define DIR_PG_SIZE	24	/* max number of dir entries in a page */


typedef struct {
  char name[FN_LENGTH];		/* name of file */
  Word addr;			/* sector # of file header */
  Word p;			/* sector # of right child in node */
} DirEntry;


typedef struct {
  /* directory page (B-tree node) */
  Word mark;			/* must be DIR_MARK */
  Word m;			/* number of entries in e[] */
  Word p0;			/* sector # of leftmost child in node */
  Byte fill[FILLER_SIZE];	/* not used */
  DirEntry e[DIR_PG_SIZE];	/* directory entries, right children */
} DirPage;


void showDirSector(Byte *p) {
  DirPage *dp;
  Word numEntries;
  Word child;
  char *name;
  Word addr;
  int i;

  checkBatch(0);
  dp = (DirPage *) p;
  printf("mark = 0x%08X ", dp->mark);
  if (dp->mark != DIR_MARK) {
    printf("(*** invalid directory page ***)\n");
    return;
  }
  printf("(this is a valid directory page)\n");
  if (checkBatch(1)) return;
  numEntries = dp->m;
  printf("%u entries in this directory page\n", numEntries);
  if (checkBatch(1)) return;
  child = dp->p0 / SECTOR_FACTOR;
  printf("    child = %u (0x%X)\n", child, child);
  if (checkBatch(1)) return;
  for (i = 0; i < numEntries; i++) {
    name = dp->e[i].name;
    addr = dp->e[i].addr / SECTOR_FACTOR;
    child = dp->e[i].p / SECTOR_FACTOR;
    printf("%2d: file = %u (0x%X), name = '%s'\n",
           i, addr, addr, name);
    if (checkBatch(1)) return;
    printf("    child = %u (0x%X)\n", child, child);
    if (checkBatch(1)) return;
  }
}


/**************************************************************/


#define HDR_MARK	0x9BA71D86	/* magic number for file header */
#define EX_TAB_SIZE	12	/* size of extension table */
#define SEC_TAB_SIZE	64	/* size of sector table */
#define HEADER_SIZE	352	/* file data starts at this offset */


typedef struct {
  /* first sector of each file on disk */
  Word mark;			/* must be HDR_MARK */
  char name[FN_LENGTH];		/* name of file */
  /* total size in bytes (including header) = alen * SECTOR_SIZE + blen */
  Word alen;			/* number of totally filled sectors */
  Word blen;			/* number of bytes in last sector */
  /* date coded as year(6), month(4), day(5), hour(5), min(6), sec(6) */
  Word date;
  Word ext[EX_TAB_SIZE];	/* extension (single-indirect) table */
  Word sec[SEC_TAB_SIZE];	/* sector table (first entry: this sector) */
  Byte fill[SECTOR_SIZE - HEADER_SIZE];
} FileHeader;


#define MASK(n)		((1 << (n)) - 1)


char *monthNames[] = {
  /* 00 */  "???",
  /* 01 */  "Jan",
  /* 02 */  "Feb",
  /* 03 */  "Mar",
  /* 04 */  "Apr",
  /* 05 */  "May",
  /* 06 */  "Jun",
  /* 07 */  "Jul",
  /* 08 */  "Aug",
  /* 09 */  "Sep",
  /* 10 */  "Oct",
  /* 11 */  "Nov",
  /* 12 */  "Dec",
  /* 13 */  "???",
  /* 14 */  "???",
  /* 15 */  "???",
};


char *date2str(Word date) {
  static char line[LINE_SIZE];
  int year, month, day, hour, min, sec;

  year = (date >> 26) & MASK(6);
  month = (date >> 22) & MASK(4);
  day = (date >> 17) & MASK(5);
  hour = (date >> 12) & MASK(5);
  min = (date >> 6) & MASK(6);
  sec = (date >> 0) & MASK(6);
  sprintf(line,
          "%02d-%s-20%02d %02d:%02d:%02d",
          day, monthNames[month], year, hour, min, sec);
  return line;
}


void showFhdSector(Byte *p) {
  FileHeader *fp;
  Word alen;
  Word blen;
  Word date;
  Word addr;
  Byte c;
  int i, j;

  checkBatch(0);
  fp = (FileHeader *) p;
  printf("mark = 0x%08X ", fp->mark);
  if (fp->mark != HDR_MARK) {
    printf("(*** invalid file header sector ***)\n");
    return;
  }
  printf("(this is a valid file header sector)\n");
  if (checkBatch(1)) return;
  alen = fp->alen;
  blen = fp->blen;
  date = fp->date;
  printf("alen = %u (0x%X)\n", alen, alen);
  if (checkBatch(1)) return;
  printf("blen = %u (0x%X)\n", blen, blen);
  if (checkBatch(1)) return;
  printf("date = %u (0x%X) = '%s'\n", date, date, date2str(date));
  if (checkBatch(1)) return;
  for (i = 0; i < EX_TAB_SIZE; i++) {
    addr = fp->ext[i] / SECTOR_FACTOR;
    printf("ext[%2d] = %u (0x%X)\n", i, addr, addr);
    if (checkBatch(1)) return;
  }
  for (i = 0; i < SEC_TAB_SIZE; i++) {
    addr = fp->sec[i] / SECTOR_FACTOR;
    printf("sec[%2d] = %u (0x%X)\n", i, addr, addr);
    if (checkBatch(1)) return;
  }
  for (i = 0; i < (SECTOR_SIZE - HEADER_SIZE) / 16; i++) {
    printf("%04X   ", i * 16);
    for (j = 0; j < 16; j++) {
      c = fp->fill[i * 16 + j];
      printf("%02X ", c);
    }
    printf("   ");
    for (j = 0; j < 16; j++) {
      c = fp->fill[i * 16 + j];
      if (c < 0x20 || c >= 0x7F) {
        printf(".");
      } else {
        printf("%c", c);
      }
    }
    printf("\n");
    if (checkBatch(1)) return;
  }
}


/**************************************************************/


#define SECNUMS_PER_SECTOR	(SECTOR_SIZE / sizeof(Word))


typedef struct {
  Word addr[SECNUMS_PER_SECTOR];
} ExtSector;


void showExtSector(Byte *p) {
  ExtSector *xp;
  Word addr;
  int i;

  checkBatch(0);
  xp = (ExtSector *) p;
  for (i = 0; i < SECNUMS_PER_SECTOR; i++) {
    addr = xp->addr[i] / SECTOR_FACTOR;
    printf("sec[%3d] = %u (0x%X)\n", i, addr, addr);
    if (checkBatch(1)) return;
  }
}


/**************************************************************/


void help(void) {
  printf("Commands are:\n");
  printf("  h        help\n");
  printf("  q        quit\n");
  printf("  r        show current sector as raw data\n");
  printf("  d        show current sector as directory sector\n");
  printf("  f        show current sector as file header sector\n");
  printf("  x        show current sector as extension sector\n");
  printf("  s <num>  set current sector to <num>\n");
  printf("  +        increment current sector\n");
  printf("  -        decrement current sector\n");
}


bool parseNumber(char **pc, unsigned int *pi) {
  char *p;
  unsigned int base, dval;
  unsigned int n;

  p = *pc;
  while (*p == ' ' || *p == '\t') {
    p++;
  }
  if (*p == '\0' || *p == '\n') {
    printf("Error: number is missing!\n");
    return false;
  }
  base = 10;
  if (*p == '0') {
    p++;
    if (*p != '\0' && *p != '\n') {
      if (*p == 'x' || *p == 'X') {
        base = 16;
        p++;
      } else {
        base = 8;
      }
    }
  }
  n = 0;
  while ((*p >= '0' && *p <= '9') ||
         (*p >= 'a' && *p <= 'f') ||
         (*p >= 'A' && *p <= 'F')) {
    if (*p >= '0' && *p <= '9') {
      dval = (*p - '0');
    } else
    if (*p >= 'a' && *p <= 'f') {
      dval = (*p - 'a' + 10);
    } else
    if (*p >= 'A' && *p <= 'F') {
      dval = (*p - 'A' + 10);
    }
    if (dval >= base) {
      printf("Error: digit value %d is illegal in number base %d\n",
             dval, base);
      return false;
    }
    n *= base;
    n += dval;
    p++;
  }
  while (*p == ' ' || *p == '\t') {
    p++;
  }
  *pc = p;
  *pi = n;
  return true;
}


void usage(char *myself) {
  printf("Usage: %s <disk image>\n", myself);
  exit(1);
}


int main(int argc, char *argv[]) {
  FILE *disk;
  unsigned int fsSize;
  Word numSectors;
  Word currSector;
  Byte sectorBuffer[SECTOR_SIZE];
  bool quit;
  char line[LINE_SIZE];
  char *p;
  Word n;

  if (argc != 2) {
    usage(argv[0]);
  }
  disk = fopen(argv[1], "r");
  if (disk == NULL) {
    error("cannot open disk image '%s'", argv[1]);
  }
  fseek(disk, 0, SEEK_END);
  fsSize = ftell(disk) / BLOCK_SIZE;
  printf("File system has size %u (0x%X) blocks of %d bytes each.\n",
         fsSize, fsSize, BLOCK_SIZE);
  if (fsSize % BPS != 0) {
    printf("File system size is not a multiple of sector size.\n");
  }
  numSectors = fsSize / BPS;
  printf("This equals %u (0x%X) sectors of %d bytes each.\n",
         numSectors, numSectors, SECTOR_SIZE);
  currSector = 1;
  readSector(disk, currSector, sectorBuffer);
  help();
  quit = false;
  while (!quit) {
    printf("showdsk [sector %u (0x%X)] > ", currSector, currSector);
    fflush(stdout);
    if (fgets(line, LINE_SIZE, stdin) == NULL) {
      printf("\n");
      break;
    }
    if (line[0] == '\0' || line[0] == '\n') {
      continue;
    }
    switch (line[0]) {
      case 'h':
      case '?':
        help();
        break;
      case 'q':
        quit = true;
        break;
      case 'r':
        showRawSector(sectorBuffer);
        break;
      case 'd':
        showDirSector(sectorBuffer);
        break;
      case 'f':
        showFhdSector(sectorBuffer);
        break;
      case 'x':
        showExtSector(sectorBuffer);
        break;
      case 's':
        p = line + 1;
        if (!parseNumber(&p, &n)) {
          break;
        }
        if (*p != '\0' && *p != '\n') {
          printf("Error: cannot parse sector number!\n");
          break;
        }
        if (n >= numSectors) {
          printf("Error: sector number too big for file system!\n");
          break;
        }
        currSector = n;
        readSector(disk, currSector, sectorBuffer);
        break;
      case '+':
        n = currSector + 1;
        if (n >= numSectors) {
          printf("Error: sector number too big for file system!\n");
          break;
        }
        currSector = n;
        readSector(disk, currSector, sectorBuffer);
        break;
      case '-':
        n = currSector - 1;
        if (n >= numSectors) {
          printf("Error: sector number too big for file system!\n");
          break;
        }
        currSector = n;
        readSector(disk, currSector, sectorBuffer);
        break;
      default:
        printf("Unknown command, type 'h' for help!\n");
        break;
    }
  }
  fclose(disk);
  return 0;
}
