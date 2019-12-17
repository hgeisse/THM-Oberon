#
# Makefile for installing Oberon on a real bare-metal system
#

BUILD=../../../build
KIT=../..
D2O=$(BUILD)/bin/dos2oberon

all:
		@echo "For installing the system:"
		@echo "    Power up the FPGA board and load the RISC5"
		@echo "    configuration into the FPGA (presumably using"
		@echo "    a RISC5 description compiled to an SVF file,"
		@echo "    together with a suitable SVF player over JTAG)."
		@echo "    Set the switches SW0 and SW1 both to 'on', and"
		@echo "    press the reset button on the FPGA board. Type"
		@echo "    'make install-link', followed by '@ sysinst'."
		@echo "    When the script has been executed, type 'q', set"
		@echo "    the switches SW0 and SW1 both to 'off', and press"
		@echo "    the reset button again. The Oberon system should"
		@echo "    now boot from the SD card."
		@echo "For communicating with an installed system:"
		@echo "    Install the system as described above. Start"
		@echo "    PCLink2.Run by clicking the middle button of the"
		@echo "    mouse on this command. Then type 'make run-link'"
		@echo "    in a separate window of the Linux system."

install-link:	Oberon0 InnerCore OuterCore Compiler Editor PCLink2 BootLink
		$(BUILD)/bin/serlink Oberon0.bin

run-link:
		$(BUILD)/bin/serlink

Oberon0:
		cp $(KIT)/Oberon0/bin/Oberon0.bin .
		cp $(KIT)/Oberon0/rsc/* .

InnerCore:
		cp $(KIT)/InnerCore/bin/Modules.bin .
		cp $(KIT)/InnerCore/rsc/* .

OuterCore:
		cp $(KIT)/OuterCore/rsc/* .
		cp $(KIT)/OuterCore/fnt/* .
		$(D2O) $(KIT)/OuterCore/txt/System.Tool.txt System.Tool

Compiler:
		cp $(KIT)/Compiler/rsc/* .

Editor:
		cp $(KIT)/Editor/rsc/* .

PCLink2:
		cp $(KIT)/PCLink2/rsc/* .

BootLink:
		cp $(KIT)/BootLink/rsc/* .

clean:
		rm -f *~
		rm -f Oberon0.bin Modules.bin
		rm -f *.rsc *.smb Oberon10.Scn.Fnt System.Tool
