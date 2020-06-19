#
# Makefile for prom memory to plain binary converter
#

BUILD = ../../../build

EXE = mem2bin-ECO32

all:		$(EXE)

install:	$(EXE)
		mkdir -p $(BUILD)/bin
		cp $(EXE) $(BUILD)/bin

$(EXE):		mem2bin.c
		gcc -g -Wall -o $(EXE) mem2bin.c

clean:
		rm -f *~ $(EXE)
