#
# Makefile for assembler
#

BUILD = ../../../build

EXE = asm-RISC5

all:		$(EXE)

install:	$(EXE)
		mkdir -p $(BUILD)/bin
		cp $(EXE) $(BUILD)/bin

$(EXE):		asm.c
		gcc -g -Wall -o $(EXE) asm.c

clean:
		rm -f *~ $(EXE)
