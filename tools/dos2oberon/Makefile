#
# Makefile for DOS-to-Oberon text converter
#

BUILD = ../../build

all:		dos2oberon

install:	dos2oberon
		mkdir -p $(BUILD)/bin
		cp dos2oberon $(BUILD)/bin

dos2oberon:	dos2oberon.c
		gcc -g -Wall -o dos2oberon dos2oberon.c

clean:
		rm -f *~ dos2oberon
