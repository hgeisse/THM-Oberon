#
# Makefile for testing RISC5
#

SRCS = risc5test.v \
       src/RISC5Top.v \
       src/RISC5.v \
       src/Registers.v \
       src/Multiplier.v \
       src/Divider.v \
       src/LeftShifter.v \
       src/RightShifter.v \
       src/FPAdder.v \
       src/FPMultiplier.v \
       src/FPDivider.v \
       src/PROM.v \
       src/RS232R.v \
       src/RS232T.v \
       src/SPI.v \
       src/VID.v \
       src/PS2.v \
       src/MouseP.v \
       lib/IOBUF.v \
       lib/RAM16X1D.v \
       lib/DCM.v \
       env/Memory.v \
       env/BoardDev.v \
       env/RS232Dev.v \
       env/SPIDev.v \
       env/VIDDev.v \
       env/PS2Dev.v

all:		show

show:		risc5test
		./risc5test
		gtkwave dump.vcd risc5test.cfg

risc5test:	$(SRCS)
		iverilog -Wall -o risc5test $(SRCS)

clean:
		rm -f *~
		rm -f risc5test dump.vcd
