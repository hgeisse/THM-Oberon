#
# Makefile for testing RISC5
#

SRCS = risc5test.v ramctrl/ramctrl.v ramctrl/ram.v

all:		show

show:		risc5test
		./risc5test
		gtkwave dump.vcd risc5test.cfg

risc5test:	$(SRCS)
		iverilog -Wall -o risc5test $(SRCS)

clean:
		rm -f *~
		rm -f risc5test dump.vcd
