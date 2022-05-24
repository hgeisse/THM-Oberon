#
# Makefile for RISC5 assembler test
#

all:
		gcc -Wall -o gen1 gen1.c
		gcc -Wall -o gen2 gen2.c
		./gen1 >patterns
		./gen2 patterns >all.asm

clean:
		rm -f *~ gen1 gen2 patterns all.asm
