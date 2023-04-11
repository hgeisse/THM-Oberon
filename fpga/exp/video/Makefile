#
# Makefile for video experiment
#

SRCS = vx.v

all:		show

vx:		$(SRCS)
		iverilog -Wall -o vx $(SRCS)

show:		vx
		./vx
		gtkwave dump.vcd vx.cfg

clean:
		rm -f *~ vx dump.vcd
