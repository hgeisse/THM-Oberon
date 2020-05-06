/*
 * eco32dev.c -- common definitions for ECO32 devices
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "common.h"
#include "eco32dev.h"
#include "bio.h"


extern Bool enable_ECO32_board;


Word cpuGetPC(void);


static void devDisabled(char *access, char *device) {
  error("%s disabled ECO32 I/O device '%s', PC = 0x%08X",
        access, device, cpuGetPC() - 4);
}


Word ECO32_readIO(Word addr) {
  switch (addr & ECO32_DEV_MASK) {
    case ECO32_BOARD:
      if (enable_ECO32_board) {
        return bioRead(addr & ~ECO32_DEV_MASK);
      } else {
        devDisabled("read from", "board");
        return 0;
      }
    default:
      error("ECO32_readIO, unknown addr = 0x%08X, PC = 0x%08X",
            addr, cpuGetPC() - 4);
      return 0;
  }
}


void ECO32_writeIO(Word addr, Word data) {
  switch (addr & ECO32_DEV_MASK) {
    case ECO32_BOARD:
      if (enable_ECO32_board) {
        bioWrite(addr & ~ECO32_DEV_MASK, data);
      } else {
        devDisabled("write to", "board");
      }
      break;
    default:
      error("ECO32_writeIO, unknown addr = 0x%08X, PC = 0x%08X",
            addr, cpuGetPC() - 4);
      break;
  }
}
