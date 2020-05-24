#
# Makefile for running pattern tests
#

BUILD=../../build
KIT=../../kit-x-RISC5
D2O=$(BUILD)/bin/dos2oberon

TESTS=Pattern01 Pattern02 Pattern03 Pattern04 Pattern05 Pattern06 \
      Pattern16 Pattern17

all:
		@echo "Please use 'make run' and 'make run-link!'"

run:		Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim-RISC5 -d Oberon.dsk -p BootLoad.mem \
		  -s 001

run-link:	sources
		$(BUILD)/bin/serlink

sources:
		for i in $(TESTS) ; do \
		  $(BUILD)/bin/unix2oberon ../$$i/$$i.Mod.txt $$i.Mod ; \
		done

Oberon.dsk:
		cp $(KIT)/install/sim/Oberon.dsk .

BootLoad.mem:
		cp $(KIT)/BootLoad/mem/BootLoad.mem .

clean:
		rm -f *~
		rm -f Oberon.dsk BootLoad.mem serial.dev
		rm -f *.Mod *.smb *.rsc
