#
# Makefile for serial line link support
#

BUILD = ../build

CC = gcc
CFLAGS = -g -Wall
LDFLAGS = -g -Wall
LDLIBS = -lm

SRCS = serlink.c
OBJS = $(patsubst %.c,%.o,$(SRCS))
BIN = serlink

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
