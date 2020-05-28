/*
 * cpu.c -- glue file
 */


#include "cpu.h"


void cpuIRQ(void);


void cpuSetInterrupt(int irq) {
  if (irq == IRQ_TIMER_0) {
    cpuIRQ();
  }
}


void cpuResetInterrupt(int irq) {
}
