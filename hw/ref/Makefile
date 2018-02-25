#
# Makefile for testing RISC5
#

SRCS = risc5test.v risc5top.v RISC5.v PROM.v \
       Multiplier.v Divider.v \
       LeftShifter.v RightShifter.v \
       FPAdder.v FPMultiplier.v FPDivider.v \
       ram.v

all:		show

risc5test:	$(SRCS)
		iverilog -Wall -o risc5test $(SRCS)

show:		risc5test
		./risc5test
		gtkwave dump.vcd risc5test.cfg

clean:
		rm -f *~ risc5test dump.vcd
