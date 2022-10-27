#
# Makefile
#

BUILD=../../../../build
KIT=../../../../kit-RISC5

all:
		@echo "Please choose one of the targets"
		@echo "    'make connect-fpga' or"
		@echo "    'run-sim' and 'connect-sim'"

connect-fpga:	Oberon0.bin
		cp serial.ttyUSB serial.dev
		$(BUILD)/bin/serlink Oberon0.bin

run-sim:	BootLoad.mem Oberon.dsk
		$(BUILD)/bin/sim-RISC5 -i -p BootLoad.mem -d Oberon.dsk -s 003

connect-sim:	Oberon0.bin
		$(BUILD)/bin/serlink Oberon0.bin

BootLoad.mem:
		cp $(KIT)/Stable/BootLoad/mem/BootLoad.mem .

Oberon0.bin:
		cp $(KIT)/Stable/Oberon0/bin/Oberon0.bin .

Oberon.dsk:
		$(BUILD)/bin/mkdisk Oberon.dsk 64M

clean:
		rm -f *~ BootLoad.mem Oberon0.bin Oberon.dsk
		rm -f serial.dev
