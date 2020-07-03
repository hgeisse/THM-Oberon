#
# Makefile for running standalone tests
#

BUILD=../../../build
RISC5=../../../kit-x-RISC5
CROSS=../../../kit-x-cross
D2O=$(BUILD)/bin/dos2oberon

DIRS=Stand01 Stand02

all:
		@echo "Please use 'make build' and 'make build-link'!"

build:		Oberon.dsk BootLoad.mem
		$(BUILD)/bin/sim-RISC5 -d Oberon.dsk -p BootLoad.mem \
		  -s 001

build-link:	sources
		$(BUILD)/bin/serlink

sources:
		for i in $(DIRS) ; do \
		  for j in ../$$i/*.Mod.txt ; do \
		    $(BUILD)/bin/unix2oberon $$j `basename $$j .txt`; \
		  done ; \
		done

Oberon.dsk:
		cp $(CROSS)/build/sim/Oberon.dsk .

BootLoad.mem:
		cp $(RISC5)/Stable/BootLoad/mem/BootLoad.mem .

clean:
		rm -f *~
		rm -f Oberon.dsk BootLoad.mem serial.dev
		rm -f *.Mod *.smb *.rsc *.bin
