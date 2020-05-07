/*
 * cpu.h -- glue file
 */


#define IRQ_TIMER_0	14	/* timer 0 interrupt */


void cpuSetInterrupt(int irq);
void cpuResetInterrupt(int irq);
