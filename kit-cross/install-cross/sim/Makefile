#
# Makefile for installing Oberon on a simulated bare-metal system
#

BUILD=../../../build
D2O=$(BUILD)/bin/dos2oberon
KIT=../../Cross

DISK_SIZE=64M

MODGRPS=BootLoad InnerCore Oberon0 OuterCore Editor PCLink2 Out \
        Compiler BootLink Tools Math Fonts Graphics MacroTool Apps

all:
		@echo "For installing the system:"
		@echo "    Type 'make install' and 'make install-link'"
		@echo "    (in separate windows, in this order). Then type"
		@echo "    '@ install-cross' in the install-link window. When"
		@echo "    the script has been executed, type 'q' in the"
		@echo "    install-link and CTRL-C in the install window."
		@echo "    Make a backup copy of the disk 'Oberon.dsk'."
		@echo "For running an installed system:"
		@echo "    Type 'make run'. If you want to transfer files"
		@echo "    between the host and the Oberon system, start"
		@echo "    PCLink2.Run by clicking the middle button of the"
		@echo "    mouse on this command. Then type 'make run-link'"
		@echo "    in a separate window of the Linux system."

install:	BootLoad.bin Oberon.dsk
		$(BUILD)/bin/sim-ECO32 -r BootLoad.bin -D Oberon.dsk \
		  -sb 003 -s 1 -u serial.dev -G

install-link:	Oberon0.bin Modules.bin $(MODGRPS)
		$(BUILD)/bin/serlink Oberon0.bin

run:		BootLoad.bin Oberon.dsk
		$(BUILD)/bin/sim-ECO32 -r BootLoad.bin -D Oberon.dsk \
		  -sb 001 -s 1 -u serial.dev -G

debug:		BootLoad.bin Oberon.dsk
		$(BUILD)/bin/sim-ECO32 -i -r BootLoad.bin -D Oberon.dsk \
		  -sb 001 -s 1 -u serial.dev -G

run-link:
		$(BUILD)/bin/serlink

BootLoad.bin:
		cp $(KIT)/BootLoad/bin/BootLoad.bin .

Oberon.dsk:
		$(BUILD)/bin/mkdisk Oberon.dsk $(DISK_SIZE)

Oberon0.bin:
		cp $(KIT)/Oberon0/bin/Oberon0.bin .

Modules.bin:
		cp $(KIT)/InnerCore/bin/Modules.bin .

BootLoad:
		cp $(KIT)/BootLoad/rsc/* .

InnerCore:
		cp $(KIT)/InnerCore/rsc/* .

Oberon0:
		cp $(KIT)/Oberon0/rsc/* .

OuterCore:
		cp $(KIT)/OuterCore/rsc/* .
		$(D2O) $(KIT)/OuterCore/tools/System.Tool.txt System.Tool

Editor:
		cp $(KIT)/Editor/rsc/* .

PCLink2:
		cp $(KIT)/PCLink2/rsc/* .

Out:
		cp $(KIT)/Out/rsc/* .

Compiler:
		cp $(KIT)/Compiler/rsc/* .

BootLink:
		cp $(KIT)/BootLink/rsc/* .

Tools:
		cp $(KIT)/Tools/rsc/* .

Math:
		cp $(KIT)/Math/rsc/* .

Fonts:
		cp $(KIT)/Fonts/rsc/* .
		cp $(KIT)/Fonts/fonts/* .

Graphics:
		cp $(KIT)/Graphics/rsc/* .
		$(D2O) $(KIT)/Graphics/tools/Draw.Tool.txt Draw.Tool
		cp $(KIT)/Graphics/libs/* .

MacroTool:
		cp $(KIT)/MacroTool/rsc/* .

Apps:
		cp $(KIT)/Apps/rsc/* .

clean:
		rm -rf *~
		rm -f serial.dev Oberon.dsk
		rm -f BootLoad.bin Oberon0.bin Modules.bin
		rm -f *.rsc *.smb *.Scn.Fnt *.Tool *.Lib
