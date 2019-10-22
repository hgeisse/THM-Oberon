#
# Makefile for installing Oberon on a simulated bare-metal system
#

BUILD=../../../build
KIT=../..
D2O=$(BUILD)/bin/dos2oberon

all:
		@echo "For installing the system:"
		@echo "    Type 'make install' and 'make install-link' (in"
		@echo "    separate windows, in this order). Then type"
		@echo "    '@ sysinst' in the install-link window. When"
		@echo "    the script has been executed, type 'q' in the"
		@echo "    install-link and CTRL-C in the install window."
		@echo "    Make a backup copy of the disk 'Oberon.dsk'."
		@echo "For running an installed system:"
		@echo "    Type 'make run'. If you want to transfer files"
		@echo "    between the host and the Oberon system, start"
		@echo "    PCLink1.Run by clicking the middle button of the"
		@echo "    mouse on this command. Then type 'make run-link'"
		@echo "    in a separate window."

install:	Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim -d Oberon.dsk -p BootLoad.mem -s 003

install-link:	Oberon0 InnerCore OuterCore Compiler Editor PCLink1 BootLink
		$(BUILD)/bin/serlink Oberon0.bin

run:		Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim -d Oberon.dsk -p BootLoad.mem -s 000

run-link:
		$(BUILD)/bin/serlink

Oberon.dsk:
		$(BUILD)/bin/mkdisk Oberon.dsk 300M

BootLoad.mem:
		cp $(KIT)/BootLoad/mem/BootLoad.mem .

Oberon0:
		cp $(KIT)/Oberon0/bin/Oberon0.bin .
		cp $(KIT)/Oberon0/rsc/* .

InnerCore:
		cp $(KIT)/InnerCore/bin/Modules.bin .
		cp $(KIT)/InnerCore/rsc/* .

OuterCore:
		cp $(KIT)/OuterCore/rsc/* .
		$(D2O) $(KIT)/OuterCore/txt/System.Tool.txt System.Tool

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
