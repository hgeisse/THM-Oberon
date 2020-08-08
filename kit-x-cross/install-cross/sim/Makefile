#
# Makefile for installing Oberon on a simulated bare-metal system
#

BUILD=../../../build
D2O=$(BUILD)/bin/dos2oberon
KIT=../../Cross
MODULES=BootLoad InnerCore Oberon0 OuterCore Editor PCLink2 Out \
        Compiler BootLink Tools Math Fonts Graphics MacroTool Apps

all:
		@echo "Please use 'make install' and 'make install-link',"
		@echo "        or 'make run'     and 'make run-link'!"

install:	BootLoad.bin
		$(BUILD)/bin/sim-ECO32 -r BootLoad.bin -m 6 \
		  -sb 003 -s 1 -u serial.dev -G -o ramdisk.img

install-link:	Oberon0.bin Modules.bin $(MODULES)
		$(BUILD)/bin/serlink Oberon0.bin

run:
		cp ramdisk.img bootdisk.img
		$(BUILD)/bin/sim-ECO32 -m 6 -l bootdisk.img -a 0x1FF800 \
		  -sb 001 -s 1 -u serial.dev -G -o ramdisk.img

run-link:
		$(BUILD)/bin/serlink

BootLoad.bin:
		cp $(KIT)/BootLoad/bin/BootLoad.bin .

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
		rm -f BootLoad.bin Oberon0.bin Modules.bin
		rm -f serial.dev ramdisk.img bootdisk.img
		rm -f *.rsc *.smb *.Scn.Fnt *.Tool *.Lib
