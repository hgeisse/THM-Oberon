#
# Makefile for testing the integer divider
#

all:
		@echo "Please read the README file!"

choose-Wirth:
		cp Divider-Wirth.v divider.v

choose-Geisse:
		cp Divider-Geisse.v divider.v

choose-s:
		cp div_s.dat ref.dat

choose-u:
		cp div_u.dat ref.dat

run:		check
		./check
		gtkwave dump.vcd check.cfg

check:		check.v divider.v
		iverilog -Wall -o check check.v divider.v

clean:
		rm -f *~ check dump.vcd

clobber:	clean
		rm -f divider.v ref.dat
