#
# Makefile for testing RISC5
#

SRCS = risc5test.v \
       src/toplevel/risc5.v \
       src/clk_rst/clk_rst.v \
       src/cpu/cpu.v \
       src/cpu/cpu_bus.v \
       src/cpu/cpu_core.v

all:		show

show:		risc5test
		./risc5test
		gtkwave dump.vcd risc5test.cfg

risc5test:	$(SRCS)
		iverilog -Wall -o risc5test $(SRCS)

clean:
		rm -f *~
		rm -f risc5test dump.vcd
