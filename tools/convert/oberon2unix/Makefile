#
# Makefile for Oberon-to-UNIX text converter
#

BUILD = ../../../build

all:		oberon2unix

install:	oberon2unix
		mkdir -p $(BUILD)/bin
		cp oberon2unix $(BUILD)/bin

oberon2unix:	oberon2unix.c
		gcc -g -Wall -o oberon2unix oberon2unix.c

clean:
		rm -f *~ oberon2unix
