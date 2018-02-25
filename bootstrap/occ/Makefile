#
# Makefile for Oberon cross compiler
#

CC=gcc
CFLAGS=-g -Wall
LDFLAGS=-g -Wall
LDLIBS=-lm

SRCS=occ.c
OBJS=$(patsubst %.c,%.o,$(SRCS))
BIN=occ

all:		$(BIN)

$(BIN):		$(OBJS)
		$(CC) $(LDFLAGS) -o $(BIN) $(OBJS) $(LDLIBS)

%.o:		%.c
		$(CC) $(CFLAGS) -o $@ -c $<

clean:
		rm -f *~ $(OBJS) $(BIN)
