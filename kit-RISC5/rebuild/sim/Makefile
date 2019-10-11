#
# Makefile for re-building Oberon binaries on a simulated bare-metal system
#

BUILD=../../../build
KIT=../..
INSTALL=$(KIT)/install/sim
D2O=$(BUILD)/bin/dos2oberon

all:
		@echo "For running the installed system use:"
		@echo "    'make run' and 'make run-link'"
		@echo "    (in separate windows, in this order)"

run:		Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim -d Oberon.dsk -p BootLoad.mem -s 000

run-link:
		$(BUILD)/bin/serlink

Oberon.dsk:
		cp $(INSTALL)/Oberon.dsk .

BootLoad.mem:
		cp $(KIT)/BootLoad/mem/BootLoad.mem .

doit1:
		$(D2O) $(KIT)/Editor/txt/Edit.Mod.txt Edit.Mod

doit2:
		$(D2O) $(KIT)/Compiler/txt/ORP.Mod.txt ORP.Mod
		$(D2O) $(KIT)/Compiler/txt/ORG.Mod.txt ORG.Mod
		$(D2O) $(KIT)/Compiler/txt/ORB.Mod.txt ORB.Mod
		$(D2O) $(KIT)/Compiler/txt/ORS.Mod.txt ORS.Mod
		$(D2O) $(KIT)/Compiler/txt/ORTool.Mod.txt ORTool.Mod

doit3:
		$(D2O) $(KIT)/BootLink/txt/BootLink.Mod.txt BootLink.Mod

clean:
		rm -f *~
		rm -f serial.dev Oberon.dsk BootLoad.mem
		rm -f Edit.Mod
