#
# Makefile for installing Oberon on a simulated bare-metal system
#

BUILD=../../../build
KIT=../..

all:
		@echo "For installing the system use:"
		@echo "    'make install' and 'make install-link'"
		@echo "    (in separate windows, in this order)."
		@echo "    Then type '@ sysinst' in the install-link window."
		@echo "For running an installed system use:"
		@echo "    'make run' and 'make run-link'"
		@echo "    (in separate windows, in this order)."

install:	Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim -d Oberon.dsk -p BootLoad.mem -s 003

install-link:	Oberon0.bin InnerCore OuterCore Compiler Editor PCLink1 BootLink
		$(BUILD)/bin/serlink Oberon0.bin

run:		Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim -d Oberon.dsk -p BootLoad.mem -s 000

run-link:
		$(BUILD)/bin/serlink

Oberon.dsk:
		$(BUILD)/bin/mkdisk Oberon.dsk 300M

BootLoad.mem:
		cp $(KIT)/BootLoad/mem/BootLoad.mem .

Oberon0.bin:
		cp $(KIT)/Oberon0/bin/Oberon0.bin .

InnerCore:
		cp $(KIT)/InnerCore/bin/Modules.bin .
		cp $(KIT)/InnerCore/rsc/* .

OuterCore:
		cp $(KIT)/OuterCore/rsc/* .

Compiler:
		cp $(KIT)/Compiler/rsc/* .

Editor:
		cp $(KIT)/Editor/rsc/* .

PCLink1:
		cp $(KIT)/PCLink1/rsc/* .

BootLink:
		cp $(KIT)/BootLink/rsc/* .

clean:
		rm -f *~
		rm -f serial.dev Oberon.dsk BootLoad.mem
		rm -f Oberon0.bin Modules.bin
		rm -f *.rsc *.smb Oberon10.Scn.Fnt System.Tool
