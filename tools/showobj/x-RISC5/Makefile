#
# Makefile for Extended Oberon object file viewer (RISC5)
#

BUILD = ../../../build

CC = gcc
CFLAGS = -g -Wall
LDFLAGS = -g -Wall
LDLIBS = -lm

SRCS = showobj.c
OBJS = $(patsubst %.c,%.o,$(SRCS))
BIN = showobj-x-RISC5

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
