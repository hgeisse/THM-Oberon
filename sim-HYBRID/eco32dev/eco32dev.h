/*
 * eco32dev.h -- common definitions for ECO32 devices
 */


#include "../common.h"


#define ECO32_IO_BASE	0xC00000
#define ECO32_IO_SIZE	0x100000

#define ECO32_DEV_MASK	0xFF0000

#define ECO32_TIMER	0xC00000
#define ECO32_BOARD	0xC10000
#define ECO32_RS232	0xC20000
#define ECO32_SDCRD	0xC30000
#define ECO32_KEYBD	0xC40000
#define ECO32_MOUSE	0xC50000


Word ECO32_readIO(Word addr);
void ECO32_writeIO(Word addr, Word data);
