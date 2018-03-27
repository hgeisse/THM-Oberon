#
# Makefile for testing RISC5
#

SRCS = risc5test.v \
       src/toplevel/risc5.v \
       src/clk_rst/clk_rst.v \
       src/cpu/RISC5cpu.v \
       src/cpu/PROM.v \
       src/cpu/Multiplier.v \
       src/cpu/Divider.v \
       src/cpu/LeftShifter.v \
       src/cpu/RightShifter.v \
       src/cpu/FPAdder.v \
       src/cpu/FPMultiplier.v \
       src/cpu/FPDivider.v \
       src/ram/ram.v \
       src/ram/sram/sram.v \
       src/vid/vid.v \
       src/tmr/tmr.v \
       src/ser/ser.v \
       src/bio/bio.v

all:		show

risc5test:	$(SRCS)
		iverilog -Wall -o risc5test $(SRCS)

show:		risc5test
		./risc5test
		gtkwave dump.vcd risc5test.cfg

clean:
		rm -f *~ risc5test dump.vcd
