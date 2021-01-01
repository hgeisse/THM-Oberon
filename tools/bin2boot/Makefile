#
# Makefile for plain binary to boot-via-serial-line converter
#

BUILD = ../../build

EXE = bin2boot

all:		$(EXE)

install:	$(EXE)
		mkdir -p $(BUILD)/bin
		cp $(EXE) $(BUILD)/bin

$(EXE):		bin2boot.c
		gcc -g -Wall -o $(EXE) bin2boot.c

clean:
		rm -f *~ $(EXE)
