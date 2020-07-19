#
# Makefile for building and running the Oberon RISC5-to-ECO32 cross compiler
#

BUILD=../../../build
RISC5KIT=../../../kit-x-RISC5
TOOLDIR=../../Tools
TOOLS=CrossUtil.Mod CORB.Mod CORG.Mod CORP.Mod CORL.Mod CORX.Mod
D2O=$(BUILD)/bin/dos2oberon
O2U=$(BUILD)/bin/oberon2unix
M2B=$(BUILD)/bin/mem2bin-ECO32
SRC=../../Source
NEW=../../New
PATCHES=../../Patches

all:
		@echo "For cross compiling the system:"
		@echo "    Type 'make build' and start PCLink2.Run by"
		@echo "    clicking the middle button of the mouse on this"
		@echo "    command. Type 'make build-link' in a separate"
		@echo "    window, followed by '@ build-tools'. When the"
		@echo "    script has been executed, type '@ build-cross'"
		@echo "    in the rebuild-link window."

build:		Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim-RISC5 -d Oberon.dsk -p BootLoad.mem -s 001

build-link:	$(TOOLS)
		$(MAKE) prologue
		$(BUILD)/bin/serlink
		$(MAKE) epilogue

prologue:
		mkdir -p $(NEW)/Apps/txt
		cp $(SRC)/Apps/txt/* $(NEW)/Apps/txt
		$(D2O) $(NEW)/Apps/txt/Blink.Mod.txt Blink.Mod
		$(D2O) $(NEW)/Apps/txt/Checkers.Mod.txt Checkers.Mod
		$(D2O) $(NEW)/Apps/txt/Dummy.Mod.txt Dummy.Mod
		$(D2O) $(NEW)/Apps/txt/EBNF.Mod.txt EBNF.Mod
		$(D2O) $(NEW)/Apps/txt/Hilbert.Mod.txt Hilbert.Mod
		$(D2O) $(NEW)/Apps/txt/Sierpinski.Mod.txt Sierpinski.Mod
		$(D2O) $(NEW)/Apps/txt/Stars.Mod.txt Stars.Mod
		$(D2O) $(NEW)/Apps/txt/TestInt.Mod.txt TestInt.Mod
		#
		mkdir -p $(NEW)/BootLink/txt
		cp $(SRC)/BootLink/txt/* $(NEW)/BootLink/txt
		$(D2O) $(NEW)/BootLink/txt/ORL.Mod.txt ORL.Mod
		$(D2O) $(NEW)/BootLink/txt/ORX.Mod.txt ORX.Mod
		#
		mkdir -p $(NEW)/BootLoad/txt
		cp $(SRC)/BootLoad/txt/* $(NEW)/BootLoad/txt
		cp $(PATCHES)/BootLoad/txt/* $(NEW)/BootLoad/txt
		$(D2O) $(NEW)/BootLoad/txt/BootLoad.Mod.txt BootLoad.Mod
		#
		mkdir -p $(NEW)/Compiler/txt
		cp $(SRC)/Compiler/txt/* $(NEW)/Compiler/txt
		$(D2O) $(NEW)/Compiler/txt/ORB.Mod.txt ORB.Mod
		$(D2O) $(NEW)/Compiler/txt/ORG.Mod.txt ORG.Mod
		$(D2O) $(NEW)/Compiler/txt/ORP.Mod.txt ORP.Mod
		$(D2O) $(NEW)/Compiler/txt/ORS.Mod.txt ORS.Mod
		$(D2O) $(NEW)/Compiler/txt/ORTool.Mod.txt ORTool.Mod
		#
		mkdir -p $(NEW)/Editor/txt
		cp $(SRC)/Editor/txt/* $(NEW)/Editor/txt
		$(D2O) $(NEW)/Editor/txt/Edit.Mod.txt Edit.Mod
		#
		mkdir -p $(NEW)/Fonts/txt
		cp $(SRC)/Fonts/txt/* $(NEW)/Fonts/txt
		$(D2O) $(NEW)/Fonts/txt/FontTool.Mod.txt FontTool.Mod
		mkdir -p $(NEW)/Fonts/fonts
		cp $(SRC)/Fonts/fonts/* $(NEW)/Fonts/fonts
		cp $(NEW)/Fonts/fonts/* .
		#
		mkdir -p $(NEW)/Graphics/txt
		cp $(SRC)/Graphics/txt/* $(NEW)/Graphics/txt
		$(D2O) $(NEW)/Graphics/txt/Curves.Mod.txt Curves.Mod
		$(D2O) $(NEW)/Graphics/txt/Draw.Mod.txt Draw.Mod
		$(D2O) $(NEW)/Graphics/txt/GraphTool.Mod.txt GraphTool.Mod
		$(D2O) $(NEW)/Graphics/txt/GraphicFrames.Mod.txt \
		  GraphicFrames.Mod
		$(D2O) $(NEW)/Graphics/txt/Graphics.Mod.txt Graphics.Mod
		$(D2O) $(NEW)/Graphics/txt/Rectangles.Mod.txt Rectangles.Mod
		mkdir -p $(NEW)/Graphics/tools
		cp $(SRC)/Graphics/tools/* $(NEW)/Graphics/tools
		$(D2O) $(NEW)/Graphics/tools/Draw.Tool.txt Draw.Tool
		mkdir -p $(NEW)/Graphics/libs
		cp $(SRC)/Graphics/libs/* $(NEW)/Graphics/libs
		cp $(NEW)/Graphics/libs/* .
		#
		mkdir -p $(NEW)/InnerCore/txt
		cp $(SRC)/InnerCore/txt/* $(NEW)/InnerCore/txt
		cp $(PATCHES)/InnerCore/txt/* $(NEW)/InnerCore/txt
		$(D2O) $(NEW)/InnerCore/txt/Disk.Mod.txt Disk.Mod
		$(D2O) $(NEW)/InnerCore/txt/FileDir.Mod.txt FileDir.Mod
		$(D2O) $(NEW)/InnerCore/txt/Files.Mod.txt Files.Mod
		$(D2O) $(NEW)/InnerCore/txt/Kernel.Mod.txt Kernel.Mod
		$(D2O) $(NEW)/InnerCore/txt/Modules.Mod.txt Modules.Mod
		#
		mkdir -p $(NEW)/MacroTool/txt
		cp $(SRC)/MacroTool/txt/* $(NEW)/MacroTool/txt
		$(D2O) $(NEW)/MacroTool/txt/MacroTool.Mod.txt MacroTool.Mod
		#
		mkdir -p $(NEW)/Math/txt
		cp $(SRC)/Math/txt/* $(NEW)/Math/txt
		$(D2O) $(NEW)/Math/txt/Math.Mod.txt Math.Mod
		#
		mkdir -p $(NEW)/Oberon0/txt
		cp $(SRC)/Oberon0/txt/* $(NEW)/Oberon0/txt
		cp $(PATCHES)/Oberon0/txt/* $(NEW)/Oberon0/txt
		$(D2O) $(NEW)/Oberon0/txt/Oberon0.Mod.txt Oberon0.Mod
		$(D2O) $(NEW)/Oberon0/txt/PCLink0.Mod.txt PCLink0.Mod
		$(D2O) $(NEW)/Oberon0/txt/RS232.Mod.txt RS232.Mod
		#
		mkdir -p $(NEW)/Out/txt
		cp $(SRC)/Out/txt/* $(NEW)/Out/txt
		$(D2O) $(NEW)/Out/txt/Out.Mod.txt Out.Mod
		#
		mkdir -p $(NEW)/OuterCore/txt
		cp $(SRC)/OuterCore/txt/* $(NEW)/OuterCore/txt
		cp $(PATCHES)/OuterCore/txt/* $(NEW)/OuterCore/txt
		$(D2O) $(NEW)/OuterCore/txt/Display.Mod.txt Display.Mod
		$(D2O) $(NEW)/OuterCore/txt/Fonts.Mod.txt Fonts.Mod
		$(D2O) $(NEW)/OuterCore/txt/Input.Mod.txt Input.Mod
		$(D2O) $(NEW)/OuterCore/txt/MenuViewers.Mod.txt \
		  MenuViewers.Mod
		$(D2O) $(NEW)/OuterCore/txt/Oberon.Mod.txt Oberon.Mod
		$(D2O) $(NEW)/OuterCore/txt/System.Mod.txt System.Mod
		$(D2O) $(NEW)/OuterCore/txt/TextFrames.Mod.txt \
		  TextFrames.Mod
		$(D2O) $(NEW)/OuterCore/txt/Texts.Mod.txt Texts.Mod
		$(D2O) $(NEW)/OuterCore/txt/Viewers.Mod.txt Viewers.Mod
		mkdir -p $(NEW)/OuterCore/tools
		cp $(SRC)/OuterCore/tools/* $(NEW)/OuterCore/tools
		$(D2O) $(NEW)/OuterCore/tools/System.Tool.txt System.Tool
		#
		mkdir -p $(NEW)/PCLink2/txt
		cp $(SRC)/PCLink2/txt/* $(NEW)/PCLink2/txt
		$(D2O) $(NEW)/PCLink2/txt/PCLink2.Mod.txt PCLink2.Mod
		#
		mkdir -p $(NEW)/Tools/txt
		cp $(SRC)/Tools/txt/* $(NEW)/Tools/txt
		$(D2O) $(NEW)/Tools/txt/Tools.Mod.txt Tools.Mod

epilogue:
		#mkdir -p $(NEW)/Apps/rsc
		#mv Blink.rsc $(NEW)/Apps/rsc
		#mv Checkers.rsc $(NEW)/Apps/rsc
		#mv Dummy.rsc $(NEW)/Apps/rsc
		#mv EBNF.rsc $(NEW)/Apps/rsc
		#mv Hilbert.rsc $(NEW)/Apps/rsc
		#mv Sierpinski.rsc $(NEW)/Apps/rsc
		#mv Stars.rsc $(NEW)/Apps/rsc
		#mv TestInt.rsc $(NEW)/Apps/rsc
		#
		#mkdir -p $(NEW)/BootLink/rsc
		#mv ORL.rsc $(NEW)/BootLink/rsc
		#mv ORX.rsc $(NEW)/BootLink/rsc
		#
		mkdir -p $(NEW)/BootLoad/rsc
		mv BootLoad.rsc $(NEW)/BootLoad/rsc
		mkdir -p $(NEW)/BootLoad/mem
		mkdir -p $(NEW)/BootLoad/bin
		$(O2U) BootLoad.prm BootLoad.mem
		$(M2B) BootLoad.mem BootLoad.bin
		mv BootLoad.mem $(NEW)/BootLoad/mem/BootLoad.mem
		mv BootLoad.bin $(NEW)/BootLoad/bin/BootLoad.bin
		rm BootLoad.prm
		#
		#mkdir -p $(NEW)/Compiler/rsc
		#mv ORB.rsc $(NEW)/Compiler/rsc
		#mv ORG.rsc $(NEW)/Compiler/rsc
		#mv ORP.rsc $(NEW)/Compiler/rsc
		#mv ORS.rsc $(NEW)/Compiler/rsc
		#mv ORTool.rsc $(NEW)/Compiler/rsc
		#
		#mkdir -p $(NEW)/Editor/rsc
		#mv Edit.rsc $(NEW)/Editor/rsc
		#
		#mkdir -p $(NEW)/Fonts/rsc
		#mv FontTool.rsc $(NEW)/Fonts/rsc
		#
		#mkdir -p $(NEW)/Graphics/rsc
		#mv Curves.rsc $(NEW)/Graphics/rsc
		#mv Draw.rsc $(NEW)/Graphics/rsc
		#mv GraphTool.rsc $(NEW)/Graphics/rsc
		#mv GraphicFrames.rsc $(NEW)/Graphics/rsc
		#mv Graphics.rsc $(NEW)/Graphics/rsc
		#mv Rectangles.rsc $(NEW)/Graphics/rsc
		#
		mkdir -p $(NEW)/InnerCore/rsc
		mv Disk.rsc $(NEW)/InnerCore/rsc
		mv FileDir.rsc $(NEW)/InnerCore/rsc
		mv Files.rsc $(NEW)/InnerCore/rsc
		mv Kernel.rsc $(NEW)/InnerCore/rsc
		mv Modules.rsc $(NEW)/InnerCore/rsc
		mkdir -p $(NEW)/InnerCore/bin
		mv Modules.bin $(NEW)/InnerCore/bin
		#
		#mkdir -p $(NEW)/MacroTool/rsc
		#mv MacroTool.rsc $(NEW)/MacroTool/rsc
		#
		#mkdir -p $(NEW)/Math/rsc
		#mv Math.rsc $(NEW)/Math/rsc
		#
		mkdir -p $(NEW)/Oberon0/rsc
		mv Oberon0.rsc $(NEW)/Oberon0/rsc
		mv PCLink0.rsc $(NEW)/Oberon0/rsc
		mv RS232.rsc $(NEW)/Oberon0/rsc
		mkdir -p $(NEW)/Oberon0/bin
		mv Oberon0.bin $(NEW)/Oberon0/bin
		#
		#mkdir -p $(NEW)/Out/rsc
		#mv Out.rsc $(NEW)/Out/rsc
		#
		mkdir -p $(NEW)/OuterCore/rsc
		mv Display.rsc $(NEW)/OuterCore/rsc
		mv Fonts.rsc $(NEW)/OuterCore/rsc
		mv Input.rsc $(NEW)/OuterCore/rsc
		mv MenuViewers.rsc $(NEW)/OuterCore/rsc
		mv Oberon.rsc $(NEW)/OuterCore/rsc
		mv System.rsc $(NEW)/OuterCore/rsc
		mv TextFrames.rsc $(NEW)/OuterCore/rsc
		mv Texts.rsc $(NEW)/OuterCore/rsc
		mv Viewers.rsc $(NEW)/OuterCore/rsc
		#
		#mkdir -p $(NEW)/PCLink2/rsc
		#mv PCLink2.rsc $(NEW)/PCLink2/rsc
		#
		#mkdir -p $(NEW)/Tools/rsc
		#mv Tools.rsc $(NEW)/Tools/rsc

Oberon.dsk:
		cp $(RISC5KIT)/install/sim/Oberon.dsk .

BootLoad.mem:
		cp $(RISC5KIT)/Stable/BootLoad/mem/BootLoad.mem .

CrossUtil.Mod:
		$(D2O) $(TOOLDIR)/CrossUtil.Mod.txt CrossUtil.Mod

CORB.Mod:
		$(D2O) $(TOOLDIR)/CORB.Mod.txt CORB.Mod

CORG.Mod:
		$(D2O) $(TOOLDIR)/CORG.Mod.txt CORG.Mod

CORP.Mod:
		$(D2O) $(TOOLDIR)/CORP.Mod.txt CORP.Mod

CORL.Mod:
		$(D2O) $(TOOLDIR)/CORL.Mod.txt CORL.Mod

CORX.Mod:
		$(D2O) $(TOOLDIR)/CORX.Mod.txt CORX.Mod

clean:
		rm -f *~
		rm -f serial.dev Oberon.dsk BootLoad.mem
		rm -f Oberon0.bin Modules.bin BootLoad.prm BootLoad.bin
		rm -f *.Mod *.rsc *.smb *.Scn.Fnt *.Tool *.Lib
