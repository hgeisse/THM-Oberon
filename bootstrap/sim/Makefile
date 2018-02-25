#
# Makefile for RISC simulator
#

CC=gcc
CFLAGS=-g -Wall
LDFLAGS=-g -Wall
LDLIBS=-lm

SRCS=sim.c
OBJS=$(patsubst %.c,%.o,$(SRCS))
BIN=sim

all:		$(BIN)

$(BIN):		$(OBJS)
		$(CC) $(LDFLAGS) -o $(BIN) $(OBJS) $(LDLIBS)

%.o:		%.c
		$(CC) $(CFLAGS) -o $@ -c $<

clean:
		rm -f *~ $(OBJS) $(BIN)
