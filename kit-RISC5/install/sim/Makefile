#
# Makefile for installing Oberon on a simulated bare-metal system
#

BUILD=../../../build
KIT=../..
D2O=$(BUILD)/bin/dos2oberon

MODGRPS=Oberon0 InnerCore OuterCore Compiler Editor PCLink2 BootLink \
        BootLoad Tools Math Graphics MacroTool Apps

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
		@echo "    PCLink2.Run by clicking the middle button of the"
		@echo "    mouse on this command. Then type 'make run-link'"
		@echo "    in a separate window of the Linux system."

install:	Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim -d Oberon.dsk -p BootLoad.mem -s 003

install-link:	$(MODGRPS)
		$(BUILD)/bin/serlink Oberon0.bin

run:		Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim -d Oberon.dsk -p BootLoad.mem -s 000

debug:		Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim -i -d Oberon.dsk -p BootLoad.mem -s 000

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
		rm -f serial.dev Oberon.dsk BootLoad.mem
		rm -f Oberon0.bin Modules.bin
		rm -f *.rsc *.smb *.Scn.Fnt *.Lib *.Tool
