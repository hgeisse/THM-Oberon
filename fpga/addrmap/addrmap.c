/*
 * addrmap.c -- view address map
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define ADDR_MASK	((1 << 24) - 1)


#define OFF		0
#define ON		1
#define UNDEF		2


char *mark[3] = {
  /* OFF */   "-",
  /* ON  */   "*",
  /* UNDEF*/  "?",
};


int main(int argc, char *argv[]) {
  unsigned int addr;
  int prom, ram, vid, io;
  int any_change;
  int selected;

  printf("\n");
  printf("ADDR        PROM    RAM     VIDEO   I/O\n");
  printf("---------------------------------------\n");
  prom = UNDEF;
  ram = UNDEF;
  vid = UNDEF;
  io = UNDEF;
  addr = 0;
  do {
    any_change = 0;
    /* PROM */
    /* bus_addr[23:12] == 12'hFFE && bus_addr[11] == 1'b0 */
    selected = (((addr >> 12) & 0xFFF) == 0xFFE &&
                ((addr >> 11) & 0x1) == 0x0) ? ON : OFF;
    if (prom != selected) {
      prom = selected;
      any_change = 1;
    }
    /* RAM */
    /* bus_addr[23:13] != 11'h7FF */
    selected = (((addr >> 13) & 0x7FF) != 0x7FF) ? ON : OFF;
    if (ram != selected) {
      ram = selected;
      any_change = 1;
    }
    /* VIDEO */
    /* bus_addr[23:17] == 7'h7F && bus_addr[16:15] != 2'b11 */
    selected = (((addr >> 17) & 0x7F) == 0x7F &&
                ((addr >> 15) & 0x3) != 0x3) ? ON : OFF;
    if (vid != selected) {
      vid = selected;
      any_change = 1;
    }
    /* I/O */
    /* bus_addr[23:8] == 16'hFFFF && bus_addr[7:6] == 2'b11 */
    selected = (((addr >> 8) & 0xFFFF) == 0xFFFF &&
                ((addr >> 6) & 0x3) == 0x3) ? ON : OFF;
    if (io != selected) {
      io = selected;
      any_change = 1;
    }
    /* output, but only if anything changed */
    if (any_change) {
      printf("0x%06X     %s       %s        %s      %s\n",
             addr, mark[prom], mark[ram], mark[vid], mark[io]);
    }
    /* increment address */
    addr = (addr + 1) & ADDR_MASK;
  } while (addr != 0);
  printf("\n");
  return 0;
}
