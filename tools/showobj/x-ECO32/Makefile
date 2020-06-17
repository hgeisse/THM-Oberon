#
# Makefile for Extended Oberon object file viewer (ECO32)
#

BUILD = ../../../build

CC = gcc
CFLAGS = -g -Wall
LDFLAGS = -g -Wall
LDLIBS = -lm

SRCS = showobj.c disasm.c instr.c
OBJS = $(patsubst %.c,%.o,$(SRCS))
BIN = showobj-x-ECO32

all:		$(BIN)

install:	$(BIN)
		mkdir -p $(BUILD)/bin
		cp $(BIN) $(BUILD)/bin

$(BIN):		$(OBJS)
		$(CC) $(LDFLAGS) -o $(BIN) $(OBJS) $(LDLIBS)

%.o:		%.c
		$(CC) $(CFLAGS) -o $@ -c $<

clean:
		rm -f *~ $(OBJS) $(BIN)
