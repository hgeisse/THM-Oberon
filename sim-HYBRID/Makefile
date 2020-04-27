#
# Makefile for Oberon HYBRID simulator
# This is essentially a RISC5 simulator,
# supplemented by some ECO32 devices.
#

BUILD = ../build

CC = gcc
CFLAGS = -g -Wall -I./getline -I/usr/X11R7/include
LDFLAGS = -g -L./getline -L/usr/X11R7/lib -Wl,-rpath -Wl,/usr/X11R7/lib
LDLIBS = -lgetline -lX11 -lpthread -lm

SRCS = sim.c common.c fp.c graph.c
OBJS = $(patsubst %.c,%.o,$(SRCS))
BIN = sim-HYBRID

all:		$(BIN)

install:	$(BIN)
		mkdir -p $(BUILD)/bin
		cp $(BIN) $(BUILD)/bin

getline/libgetline.a:
		$(MAKE) -C getline

$(BIN):		$(OBJS) getline/libgetline.a
		$(CC) $(LDFLAGS) -o $(BIN) $(OBJS) $(LDLIBS)

%.o:		%.c
		$(CC) $(CFLAGS) -o $@ -c $<

depend.mak:
		$(CC) -MM -MG $(CFLAGS) $(SRCS) >depend.mak

-include depend.mak

clean:
		$(MAKE) -C getline clean
		rm -f *~ $(OBJS) $(BIN) depend.mak serial.dev
