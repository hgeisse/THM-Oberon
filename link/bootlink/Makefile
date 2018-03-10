#
# Makefile for serial line boot support
#

BUILD = ../build

CC = gcc
CFLAGS = -g -Wall
LDFLAGS = -g -Wall
LDLIBS = -lm

SRCS = bootlink.c
OBJS = $(patsubst %.c,%.o,$(SRCS))
BIN = bootlink

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
