#
# Makefile for UNIX-to-Oberon text converter
#

BUILD = ../../build

all:		unix2oberon

install:	unix2oberon
		mkdir -p $(BUILD)/bin
		cp unix2oberon $(BUILD)/bin

unix2oberon:	unix2oberon.c
		gcc -g -Wall -o unix2oberon unix2oberon.c

clean:
		rm -f *~ unix2oberon
