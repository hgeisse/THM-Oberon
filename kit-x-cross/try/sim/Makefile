#
# Makefile for installing Oberon on a simulated bare-metal system
#

BUILD=../../../build
KIT=../../New

DISK_SIZE=64M

all:
		@echo "Please use 'make try' and 'make try-link'!"

try:		BootLoad.bin Oberon.dsk
		$(BUILD)/bin/sim-ECO32 -i -r BootLoad.bin -d Oberon.dsk \
		  -sb 003 -s 1 -u serial.dev

try-link:	Oberon0.bin
		$(BUILD)/bin/serlink Oberon0.bin

BootLoad.bin:
		cp $(KIT)/BootLoad/bin/BootLoad.bin .

Oberon.dsk:
		$(BUILD)/bin/mkdisk Oberon.dsk $(DISK_SIZE)

Oberon0.bin:
		cp $(KIT)/Oberon0/bin/Oberon0.bin .

clean:
		rm -f *~
		rm -f serial.dev BootLoad.bin Oberon.dsk
		rm -f Oberon0.bin
