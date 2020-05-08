#
# Makefile for ECO32 device library
#

CC = gcc
CFLAGS = -g -Wall

LIBOBJS = eco32dev.o except.o cpu.o timer.o bio.o serial.o

all:		libeco32dev.a

libeco32dev.a:	$(LIBOBJS)
		ar cr libeco32dev.a $(LIBOBJS)

%.o:		%.c
		$(CC) $(CFLAGS) -o $@ -c $<

clean:
		rm -f *~ libeco32dev.a $(LIBOBJS)
