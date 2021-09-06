#
# Makefile for installing Oberon on a bare-metal system
#

BUILD=../../../build
KIT=../../Stable
D2O=$(BUILD)/bin/dos2oberon

MODGRPS=Apps BootLink BootLoad Compiler Editor Fonts Graphics In \
        InnerCore MacroTool Math Oberon0 Out OuterCore PCLink2 Tools

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
		@echo "For running an installed system:"
		@echo "    Power up the FPGA board and load the RISC5"
		@echo "    configuration into the FPGA (presumably using"
		@echo "    a RISC5 description compiled to an SVF file,"
		@echo "    together with a suitable SVF player over JTAG)."
		@echo "    Set the switch SW1 to 'off' and the switch SW0"
		@echo "    to 'on'. Press the reset button on the board."
		@echo "    The Oberon system should boot from the SD card."
		@echo "    If you want to transfer files between the host"
		@echo "    and the Oberon system, start PCLink2.Run by"
		@echo "    clicking the middle button of the mouse on this"
		@echo "    command. Then type 'make run-link' in a window"
		@echo "    of the Linux system."

install-link:	$(MODGRPS)
		$(BUILD)/bin/serlink Oberon0.bin

run-link:
		$(BUILD)/bin/serlink

Apps:
		cp $(KIT)/Apps/rsc/* .

BootLink:
		cp $(KIT)/BootLink/rsc/* .

BootLoad:
		cp $(KIT)/BootLoad/rsc/* .
		cp $(KIT)/BootLoad/mem/* .
		cp $(KIT)/BootLoad/bin/* .

Compiler:
		cp $(KIT)/Compiler/rsc/* .

Editor:
		cp $(KIT)/Editor/rsc/* .

Fonts:
		cp $(KIT)/Fonts/rsc/* .
		cp $(KIT)/Fonts/fonts/* .

Graphics:
		cp $(KIT)/Graphics/rsc/* .
		$(D2O) $(KIT)/Graphics/tools/Draw.Tool.txt Draw.Tool
		cp $(KIT)/Graphics/libs/* .

In:
		cp $(KIT)/In/rsc/* .

InnerCore:
		cp $(KIT)/InnerCore/rsc/* .
		cp $(KIT)/InnerCore/bin/* .

MacroTool:
		cp $(KIT)/MacroTool/rsc/* .

Math:
		cp $(KIT)/Math/rsc/* .

Oberon0:
		cp $(KIT)/Oberon0/rsc/* .
		cp $(KIT)/Oberon0/bin/* .

Out:
		cp $(KIT)/Out/rsc/* .

OuterCore:
		cp $(KIT)/OuterCore/rsc/* .
		$(D2O) $(KIT)/OuterCore/tools/System.Tool.txt System.Tool

PCLink2:
		cp $(KIT)/PCLink2/rsc/* .

Tools:
		cp $(KIT)/Tools/rsc/* .

clean:
		rm -f *~
		rm -f BootLoad.mem
		rm -f Oberon0.bin Modules.bin BootLoad.bin
		rm -f *.rsc *.smb *.Scn.Fnt *.Lib *.Tool
