#
# Makefile for prom memory to plain binary converter
#

BUILD = ../../build

all:		mem2bin

install:	mem2bin
		mkdir -p $(BUILD)/bin
		cp mem2bin $(BUILD)/bin

mem2bin:	mem2bin.c
		gcc -g -Wall -o mem2bin mem2bin.c

clean:
		rm -f *~ mem2bin
