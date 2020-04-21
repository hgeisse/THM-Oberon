#
# Makefile for Oberon RISC simulator
#

BUILD = ../build

CC = gcc
CFLAGS = -g -Wall
LDFLAGS = -g -Wall
LDLIBS = -lX11 -lpthread -lm

SRCS = sim.c common.c fp.c graph.c
OBJS = $(patsubst %.c,%.o,$(SRCS))
BIN = sim-RISC5

all:		$(BIN)

install:	$(BIN)
		mkdir -p $(BUILD)/bin
		cp $(BIN) $(BUILD)/bin

$(BIN):		$(OBJS)
		$(CC) $(LDFLAGS) -o $(BIN) $(OBJS) $(LDLIBS)

%.o:		%.c
		$(CC) $(CFLAGS) -o $@ -c $<

clean:
		rm -f *~ $(OBJS) $(BIN) serial.dev
