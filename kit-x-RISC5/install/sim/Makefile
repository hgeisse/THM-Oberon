#
# Makefile for installing Oberon on a simulated bare-metal system
#

BUILD=../../../build
KIT=../../Stable
D2O=$(BUILD)/bin/dos2oberon

DISK_SIZE=64M

MODGRPS=Apps BootLink BootLoad Compiler Editor Fonts Graphics \
        InnerCore MacroTool Math Oberon0 Out OuterCore PCLink2 Tools

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
		$(BUILD)/bin/sim-RISC5 -d Oberon.dsk -p BootLoad.mem \
		  -s 003

install-link:	$(MODGRPS)
		$(BUILD)/bin/serlink Oberon0.bin

run:		Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim-RISC5 -d Oberon.dsk -p BootLoad.mem \
		  -s 001

debug:		Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim-RISC5 -i -d Oberon.dsk -p BootLoad.mem \
		  -s 001

debug-rmdev:	Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim-HYBRID -i -d Oberon.dsk -p BootLoad.mem \
		  -s 001 -r i

debug-rmall:	Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim-HYBRID -i -d Oberon.dsk -p BootLoad.mem \
		  -s 001 -r a

run-link:
		$(BUILD)/bin/serlink

Oberon.dsk:
		$(BUILD)/bin/mkdisk Oberon.dsk $(DISK_SIZE)

BootLoad.mem:
		cp $(KIT)/BootLoad/mem/BootLoad.mem .

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
		rm -f serial.dev Oberon.dsk BootLoad.mem
		rm -f Oberon0.bin Modules.bin BootLoad.bin
		rm -f *.rsc *.smb *.Scn.Fnt *.Lib *.Tool
