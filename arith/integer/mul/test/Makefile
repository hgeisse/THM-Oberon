#
# Makefile for testing the integer multiplier
#

all:
		@echo "Please read the README file!"

choose-Wirth:
		cp Multiplier-Wirth.v multiplier.v

choose-Straube:
		cp Multiplier-Straube.v multiplier.v

choose-Geisse:
		cp Multiplier-Geisse.v multiplier.v

choose-s:
		cp mul_s.dat ref.dat

choose-u:
		cp mul_u.dat ref.dat

run:		check
		./check
		gtkwave dump.vcd check.cfg

check:		check.v multiplier.v
		iverilog -Wall -o check check.v multiplier.v

clean:
		rm -f *~ check dump.vcd

clobber:	clean
		rm -f multiplier.v ref.dat
