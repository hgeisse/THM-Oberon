#
# Makefile for Oberon-to-DOS text converter
#

BUILD = ../../build

all:		oberon2dos

install:	oberon2dos
		mkdir -p $(BUILD)/bin
		cp oberon2dos $(BUILD)/bin

oberon2dos:	oberon2dos.c
		gcc -g -Wall -o oberon2dos oberon2dos.c

clean:
		rm -f *~ oberon2dos
