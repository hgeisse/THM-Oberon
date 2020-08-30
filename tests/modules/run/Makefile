#
# Makefile for running module tests
#

BUILD=../../../build
KIT=../../../kit-RISC5
D2O=$(BUILD)/bin/dos2oberon

DIRS=Module01 Module02 Module03 Module04 Module05 \
     Module10 \
     Module20 Module21 Module22 \
     Module30 Module31

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
