#
# Makefile for installing Oberon on the FPGA board
#

BUILD=../../../build
KIT=../..

all:
		@echo "For installing the system use:"
		@echo "    'make install-link'"
		@echo "For running an installed system use:"
		@echo "    'make run-link'"

install-link:	Oberon0.bin InnerCore OuterCore Compiler Editor PCLink1 Boot
		$(BUILD)/bin/serlink Oberon0.bin

run-link:
		$(BUILD)/bin/serlink

Oberon0.bin:
		cp $(KIT)/Oberon0/bin/Oberon0.bin .

InnerCore:
		cp $(KIT)/InnerCore/bin/Modules.bin .

OuterCore:
		cp $(KIT)/OuterCore/rsc/* .

Compiler:
		cp $(KIT)/Compiler/rsc/* .

Editor:
		cp $(KIT)/Editor/rsc/* .

PCLink1:
		cp $(KIT)/PCLink1/rsc/* .

Boot:
		cp $(KIT)/Boot/rsc/* .

clean:
		rm -f *~
		rm -f Oberon0.bin Modules.bin
		rm -f *.rsc Oberon10.Scn.Fnt System.Tool
