#
# Makefile for multiply test
#

all:		mul

mul:		mul.c
		gcc -g -Wall -o mul mul.c

run:		mul
		./mul

ref:		mul
		./mul -w

clean:
		rm -f *~ mul mul_u.dat mul_s.dat
