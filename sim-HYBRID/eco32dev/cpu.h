/*
 * cpu.h -- glue file
 */


#define IRQ_SERIAL_0_XMTR	0	/* line 0 transmitter interrupt */
#define IRQ_SERIAL_0_RCVR	1	/* line 0 receiver interrupt */
#define IRQ_TIMER_0		14	/* timer 0 interrupt */


void cpuSetInterrupt(int irq);
void cpuResetInterrupt(int irq);
