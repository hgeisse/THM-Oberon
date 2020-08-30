#
# Makefile for running pattern tests
#

BUILD=../../../build
KIT=../../../kit-RISC5
D2O=$(BUILD)/bin/dos2oberon

DIRS=Pattern01 Pattern02 Pattern03 Pattern04 Pattern05 Pattern06 \
     Pattern07 Pattern08 Pattern09 Pattern10 Pattern11 Pattern12 \
     Pattern13 Pattern14 Pattern15 Pattern16 Pattern17

all:
		@echo "Please use 'make run' and 'make run-link!'"

run:		Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim-RISC5 -d Oberon.dsk -p BootLoad.mem \
		  -s 001

run-link:	sources
		$(BUILD)/bin/serlink

sources:
		for i in $(DIRS) ; do \
		  for j in ../$$i/*.Mod.txt ; do \
		    $(BUILD)/bin/unix2oberon $$j `basename $$j .txt`; \
		  done ; \
		done

Oberon.dsk:
		cp $(KIT)/install/sim/Oberon.dsk .

BootLoad.mem:
		cp $(KIT)/Stable/BootLoad/mem/BootLoad.mem .

clean:
		rm -f *~
		rm -f Oberon.dsk BootLoad.mem serial.dev
		rm -f *.Mod *.smb *.rsc
