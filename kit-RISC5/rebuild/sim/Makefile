#
# Makefile for re-building Oberon binaries on a simulated Oberon system
#

BUILD=../../../build
KIT=../..
INSTALL=$(KIT)/install/sim
D2O=$(BUILD)/bin/dos2oberon
O2U=$(BUILD)/bin/oberon2unix
NEW=./new

all:
		@echo "For re-building the system binaries:"
		@echo "    Type 'make rebuild' and start PCLink2.Run by"
		@echo "    clicking the middle button of the mouse on this"
		@echo "    command. Type 'make rebuild-link' in a separate"
		@echo "    window, followed by '@ sysbuild'. When the script"
		@echo "    has been executed, type 'q' in the rebuild-link"
		@echo "    and CTRL-C in the rebuild window. The newly built"
		@echo "    system binaries are copied to the 'new' directory."
		@echo "For checking the newly built system binaries:"
		@echo "    Type 'make check'. This compares the new system"
		@echo "    binaries with the old ones. Any differences are"
		@echo "    reported."

rebuild:	Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim -d Oberon.dsk -p BootLoad.mem -s 000

rebuild-link:
		$(MAKE) prologue
		$(BUILD)/bin/serlink
		$(MAKE) epilogue

prologue:
		mkdir -p $(NEW)/Apps/txt
		cp $(KIT)/Apps/txt/* $(NEW)/Apps/txt
		$(D2O) $(NEW)/Apps/txt/Blink.Mod.txt Blink.Mod
		$(D2O) $(NEW)/Apps/txt/TestInt.Mod.txt TestInt.Mod
		#
		mkdir -p $(NEW)/BootLink/txt
		cp $(KIT)/BootLink/txt/* $(NEW)/BootLink/txt
		$(D2O) $(NEW)/BootLink/txt/BootLink.Mod.txt BootLink.Mod
		#
		mkdir -p $(NEW)/BootLoad/txt
		cp $(KIT)/BootLoad/txt/* $(NEW)/BootLoad/txt
		$(D2O) $(NEW)/BootLoad/txt/BootLoad.Mod.txt BootLoad.Mod
		#
		mkdir -p $(NEW)/Compiler/txt
		cp $(KIT)/Compiler/txt/* $(NEW)/Compiler/txt
		$(D2O) $(NEW)/Compiler/txt/ORB.Mod.txt ORB.Mod
		$(D2O) $(NEW)/Compiler/txt/ORG.Mod.txt ORG.Mod
		$(D2O) $(NEW)/Compiler/txt/ORP.Mod.txt ORP.Mod
		$(D2O) $(NEW)/Compiler/txt/ORS.Mod.txt ORS.Mod
		$(D2O) $(NEW)/Compiler/txt/ORTool.Mod.txt ORTool.Mod
		#
		mkdir -p $(NEW)/Dummy/txt
		cp $(KIT)/Dummy/txt/* $(NEW)/Dummy/txt
		$(D2O) $(NEW)/Dummy/txt/Dummy.Mod.txt Dummy.Mod
		#
		mkdir -p $(NEW)/Editor/txt
		cp $(KIT)/Editor/txt/* $(NEW)/Editor/txt
		$(D2O) $(NEW)/Editor/txt/Edit.Mod.txt Edit.Mod
		#
		mkdir -p $(NEW)/InnerCore/txt
		cp $(KIT)/InnerCore/txt/* $(NEW)/InnerCore/txt
		$(D2O) $(NEW)/InnerCore/txt/FileDir.Mod.txt FileDir.Mod
		$(D2O) $(NEW)/InnerCore/txt/Files.Mod.txt Files.Mod
		$(D2O) $(NEW)/InnerCore/txt/Kernel.Mod.txt Kernel.Mod
		$(D2O) $(NEW)/InnerCore/txt/Modules.Mod.txt Modules.Mod
		#
		mkdir -p $(NEW)/Math/txt
		cp $(KIT)/Math/txt/* $(NEW)/Math/txt
		$(D2O) $(NEW)/Math/txt/Math.Mod.txt Math.Mod
		#
		mkdir -p $(NEW)/Oberon0/txt
		cp $(KIT)/Oberon0/txt/* $(NEW)/Oberon0/txt
		$(D2O) $(NEW)/Oberon0/txt/Oberon0.Mod.txt Oberon0.Mod
		$(D2O) $(NEW)/Oberon0/txt/RS232.Mod.txt RS232.Mod
		#
		mkdir -p $(NEW)/OuterCore/txt
		cp $(KIT)/OuterCore/txt/* $(NEW)/OuterCore/txt
		$(D2O) $(NEW)/OuterCore/txt/Display.Mod.txt Display.Mod
		$(D2O) $(NEW)/OuterCore/txt/Fonts.Mod.txt Fonts.Mod
		$(D2O) $(NEW)/OuterCore/txt/Input.Mod.txt Input.Mod
		$(D2O) $(NEW)/OuterCore/txt/MenuViewers.Mod.txt MenuViewers.Mod
		$(D2O) $(NEW)/OuterCore/txt/Oberon.Mod.txt Oberon.Mod
		$(D2O) $(NEW)/OuterCore/txt/System.Mod.txt System.Mod
		$(D2O) $(NEW)/OuterCore/txt/TextFrames.Mod.txt TextFrames.Mod
		$(D2O) $(NEW)/OuterCore/txt/Texts.Mod.txt Texts.Mod
		$(D2O) $(NEW)/OuterCore/txt/Viewers.Mod.txt Viewers.Mod
		mkdir -p $(NEW)/OuterCore/fnt
		cp $(KIT)/OuterCore/fnt/* $(NEW)/OuterCore/fnt
		#
		mkdir -p $(NEW)/PCLink2/txt
		cp $(KIT)/PCLink2/txt/* $(NEW)/PCLink2/txt
		$(D2O) $(NEW)/PCLink2/txt/PCLink2.Mod.txt PCLink2.Mod
		#
		mkdir -p $(NEW)/Tools/txt
		cp $(KIT)/Tools/txt/* $(NEW)/Tools/txt
		$(D2O) $(NEW)/Tools/txt/Tools.Mod.txt Tools.Mod

epilogue:
		mkdir -p $(NEW)/Apps/rsc
		mv Blink.rsc Blink.smb $(NEW)/Apps/rsc
		mv TestInt.rsc TestInt.smb $(NEW)/Apps/rsc
		#
		mkdir -p $(NEW)/BootLink/rsc
		mv BootLink.rsc BootLink.smb $(NEW)/BootLink/rsc
		#
		mkdir -p $(NEW)/BootLoad/rsc
		mv BootLoad.rsc $(NEW)/BootLoad/rsc
		mkdir -p $(NEW)/BootLoad/mem
		$(O2U) BootLoad.prm $(NEW)/BootLoad/mem/BootLoad.mem
		rm BootLoad.prm
		#
		mkdir -p $(NEW)/Compiler/rsc
		mv ORB.rsc ORB.smb $(NEW)/Compiler/rsc
		mv ORG.rsc ORG.smb $(NEW)/Compiler/rsc
		mv ORP.rsc ORP.smb $(NEW)/Compiler/rsc
		mv ORS.rsc ORS.smb $(NEW)/Compiler/rsc
		mv ORTool.rsc ORTool.smb $(NEW)/Compiler/rsc
		#
		mkdir -p $(NEW)/Dummy/rsc
		mv Dummy.rsc Dummy.smb $(NEW)/Dummy/rsc
		#
		mkdir -p $(NEW)/Editor/rsc
		mv Edit.rsc Edit.smb $(NEW)/Editor/rsc
		#
		mkdir -p $(NEW)/InnerCore/rsc
		mv FileDir.rsc FileDir.smb $(NEW)/InnerCore/rsc
		mv Files.rsc Files.smb $(NEW)/InnerCore/rsc
		mv Kernel.rsc Kernel.smb $(NEW)/InnerCore/rsc
		mv Modules.rsc Modules.smb $(NEW)/InnerCore/rsc
		mkdir -p $(NEW)/InnerCore/bin
		mv Modules.bin $(NEW)/InnerCore/bin
		#
		mkdir -p $(NEW)/Math/rsc
		mv Math.rsc Math.smb $(NEW)/Math/rsc
		#
		mkdir -p $(NEW)/Oberon0/rsc
		mv Oberon0.rsc Oberon0.smb $(NEW)/Oberon0/rsc
		mv RS232.rsc RS232.smb $(NEW)/Oberon0/rsc
		mkdir -p $(NEW)/Oberon0/bin
		mv Oberon0.bin $(NEW)/Oberon0/bin
		#
		mkdir -p $(NEW)/OuterCore/rsc
		mv Display.rsc Display.smb $(NEW)/OuterCore/rsc
		mv Fonts.rsc Fonts.smb $(NEW)/OuterCore/rsc
		mv Input.rsc Input.smb $(NEW)/OuterCore/rsc
		mv MenuViewers.rsc MenuViewers.smb $(NEW)/OuterCore/rsc
		mv Oberon.rsc Oberon.smb $(NEW)/OuterCore/rsc
		mv System.rsc System.smb $(NEW)/OuterCore/rsc
		mv TextFrames.rsc TextFrames.smb $(NEW)/OuterCore/rsc
		mv Texts.rsc Texts.smb $(NEW)/OuterCore/rsc
		mv Viewers.rsc Viewers.smb $(NEW)/OuterCore/rsc
		#
		mkdir -p $(NEW)/PCLink2/rsc
		mv PCLink2.rsc PCLink2.smb $(NEW)/PCLink2/rsc
		#
		mkdir -p $(NEW)/Tools/rsc
		mv Tools.rsc Tools.smb $(NEW)/Tools/rsc

check:
		diff -r $(NEW)/Apps $(KIT)/Apps
		diff -r $(NEW)/BootLink $(KIT)/BootLink
		diff -r $(NEW)/BootLoad $(KIT)/BootLoad
		diff -r $(NEW)/Compiler $(KIT)/Compiler
		diff -r $(NEW)/Dummy $(KIT)/Dummy
		diff -r $(NEW)/Editor $(KIT)/Editor
		diff -r $(NEW)/InnerCore $(KIT)/InnerCore
		diff -r $(NEW)/Math $(KIT)/Math
		diff -r $(NEW)/Oberon0 $(KIT)/Oberon0
		diff -r $(NEW)/OuterCore $(KIT)/OuterCore
		diff -r $(NEW)/PCLink2 $(KIT)/PCLink2
		diff -r $(NEW)/Tools $(KIT)/Tools

Oberon.dsk:
		cp $(INSTALL)/Oberon.dsk .

BootLoad.mem:
		cp $(KIT)/BootLoad/mem/BootLoad.mem .

mostly-clean:
		rm -f *~
		rm -f serial.dev Oberon.dsk BootLoad.mem
		rm -f Modules.bin
		rm -f *.Mod *.rsc *.smb

clean:		mostly-clean
		rm -rf new
