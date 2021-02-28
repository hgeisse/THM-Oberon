#
# Makefile for divide/modulo test
#

all:		div

div:		div.c
		gcc -g -Wall -o div div.c

run:		div
		./div

ref:		div
		./div -w

clean:
		rm -f *~ div div_u.dat div_s.dat
