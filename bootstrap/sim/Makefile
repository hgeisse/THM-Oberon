#
# Makefile for RISC simulator
#

CC=gcc
CFLAGS=-g -Wall
LDFLAGS=-g -Wall
LDLIBS=-lX11 -lpthread -lm

SRCS=sim.c common.c graph.c
OBJS=$(patsubst %.c,%.o,$(SRCS))
BIN=sim

all:		$(BIN)

$(BIN):		$(OBJS)
		$(CC) $(LDFLAGS) -o $(BIN) $(OBJS) $(LDLIBS)

%.o:		%.c
		$(CC) $(CFLAGS) -o $@ -c $<

clean:
		rm -f *~ $(OBJS) $(BIN)
