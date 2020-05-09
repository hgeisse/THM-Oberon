/*
 * eco32dev.c -- common definitions for ECO32 devices
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "common.h"
#include "eco32dev.h"
#include "timer.h"
#include "bio.h"
#include "serial.h"


extern Bool enable_ECO32_timer;
extern Bool enable_ECO32_board;
extern Bool enable_ECO32_serial;


Word cpuGetPC(void);


void devDisabled(char *access, char *device) {
  error("%s disabled ECO32 I/O device '%s', PC = 0x%08X",
        access, device, cpuGetPC() - 4);
}


Word ECO32_readIO(Word addr) {
  switch (addr & ECO32_DEV_MASK) {
    case ECO32_TIMER:
      if (enable_ECO32_timer) {
        return timerRead(addr & ~ECO32_DEV_MASK);
      } else {
        devDisabled("read from", "timer");
        return 0;
      }
    case ECO32_BOARD:
      if (enable_ECO32_board) {
        return bioRead(addr & ~ECO32_DEV_MASK);
      } else {
        devDisabled("read from", "board");
        return 0;
      }
    case ECO32_RS232:
      if (enable_ECO32_serial) {
        return serialRead(addr & ~ECO32_DEV_MASK);
      } else {
        devDisabled("read from", "RS232");
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
    case ECO32_TIMER:
      if (enable_ECO32_timer) {
        timerWrite(addr & ~ECO32_DEV_MASK, data);
      } else {
        devDisabled("write to", "timer");
      }
      break;
    case ECO32_BOARD:
      if (enable_ECO32_board) {
        bioWrite(addr & ~ECO32_DEV_MASK, data);
      } else {
        devDisabled("write to", "board");
      }
      break;
    case ECO32_RS232:
      if (enable_ECO32_serial) {
        serialWrite(addr & ~ECO32_DEV_MASK, data);
      } else {
        devDisabled("write to", "RS232");
      }
      break;
    default:
      error("ECO32_writeIO, unknown addr = 0x%08X, PC = 0x%08X",
            addr, cpuGetPC() - 4);
      break;
  }
}
