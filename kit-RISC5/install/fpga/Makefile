#
# Makefile for installing Oberon on a real bare-metal system
#

BUILD=../../../build
KIT=../..
D2O=$(BUILD)/bin/dos2oberon

MODGRPS=Oberon0 InnerCore OuterCore Compiler Editor PCLink2 BootLink \
        BootLoad Tools Math Graphics MacroTool Apps

all:
		@echo "For installing the system:"
		@echo "    Power up the FPGA board and load the RISC5"
		@echo "    configuration into the FPGA (presumably using"
		@echo "    a RISC5 description compiled to an SVF file,"
		@echo "    together with a suitable SVF player over JTAG)."
		@echo "    Set the switches SW1 and SW0 both to 'on', and"
		@echo "    press the reset button on the FPGA board. Type"
		@echo "    'make install-link', followed by '@ sysinst'."
		@echo "    When the script has been executed, type 'q', set"
		@echo "    the switch SW1 to 'off' (but leave the switch"
		@echo "    SW0 at 'on'), and press the reset button again."
		@echo "    The Oberon system now boots from the SD card."
		@echo "For communicating with an installed system:"
		@echo "    Install the system as described above. Start"
		@echo "    PCLink2.Run by clicking the middle button of the"
		@echo "    mouse on this command. Then type 'make run-link'"
		@echo "    in a separate window of the Linux system."

install-link:	$(MODGRPS)
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
		cp $(KIT)/OuterCore/fonts/* .
		$(D2O) $(KIT)/OuterCore/tools/System.Tool.txt System.Tool

Compiler:
		cp $(KIT)/Compiler/rsc/* .

Editor:
		cp $(KIT)/Editor/rsc/* .

PCLink2:
		cp $(KIT)/PCLink2/rsc/* .

BootLink:
		cp $(KIT)/BootLink/rsc/* .

BootLoad:
		cp $(KIT)/BootLoad/rsc/* .

Tools:
		cp $(KIT)/Tools/rsc/* .

Math:
		cp $(KIT)/Math/rsc/* .

Graphics:
		cp $(KIT)/Graphics/rsc/* .
		cp $(KIT)/Graphics/fonts/* .
		cp $(KIT)/Graphics/libs/* .
		$(D2O) $(KIT)/Graphics/tools/Draw.Tool.txt Draw.Tool

MacroTool:
		cp $(KIT)/MacroTool/rsc/* .

Apps:
		cp $(KIT)/Apps/rsc/* .

clean:
		rm -f *~
		rm -f Oberon0.bin Modules.bin
		rm -f *.rsc *.smb *.Scn.Fnt *.Lib *.Tool
