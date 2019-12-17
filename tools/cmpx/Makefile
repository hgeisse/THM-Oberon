#
# Makefile for file comparison tool
#

BUILD = ../../build

all:		cmpx

install:	cmpx
		mkdir -p $(BUILD)/bin
		cp cmpx $(BUILD)/bin

cmpx:		cmpx.c
		gcc -g -Wall -o cmpx cmpx.c

clean:
		rm -f *~ cmpx
