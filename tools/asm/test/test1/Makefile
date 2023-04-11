#
# Makefile for RISC5 assembler test
#

BUILD = ../../../../build

all:		patterns all.asm

install:	all

check:		all
		$(BUILD)/bin/asm all.asm all.mem
		diff all.mem patterns

patterns:	gen1
		./gen1 >patterns

gen1:		gen1.c
		gcc -Wall -o gen1 gen1.c

all.asm:	patterns gen2
		./gen2 patterns >all.asm

gen2:		gen2.c
		gcc -Wall -o gen2 gen2.c

clean:
		rm -f *~ gen1 gen2 patterns all.asm all.mem
