#
# Makefile for Oberon RISC5 on Terasic DE2-115 board
#

BUILD = ../../../build

all:		build/output_files/risc5.sof build/output_files/risc5.pof

install:	build/output_files/risc5.sof build/output_files/risc5.pof
		mkdir -p $(BUILD)/risc5/de2-115
		cp build/output_files/risc5.sof $(BUILD)/risc5/de2-115
		cp build/output_files/risc5.pof $(BUILD)/risc5/de2-115

clean:
		mv build/risc5.qpf .
		mv build/risc5.qsf .
		if [ -f build/risc5.qws ] ; then \
		  mv build/risc5.qws . ; \
		fi
		if [ -f build/risc5.srf ] ; then \
		  mv build/risc5.srf . ; \
		fi
		if [ -f build/output_files/risc5.sof ] ; then \
		  mv build/output_files/risc5.sof . ; \
		fi
		if [ -f build/output_files/risc5.pof ] ; then \
		  mv build/output_files/risc5.pof . ; \
		fi
		if [ -f build/output_files/risc5.cdf ] ; then \
		  mv build/output_files/risc5.cdf . ; \
		fi
		rm -rf build/*
		mkdir build/output_files
		mv risc5.qpf build
		mv risc5.qsf build
		if [ -f risc5.qws ] ; then \
		  mv risc5.qws build ; \
		fi
		if [ -f risc5.srf ] ; then \
		  mv risc5.srf build ; \
		fi
		if [ -f risc5.sof ] ; then \
		  mv risc5.sof build/output_files ; \
		fi
		if [ -f risc5.pof ] ; then \
		  mv risc5.pof build/output_files ; \
		fi
		if [ -f risc5.cdf ] ; then \
		  mv risc5.cdf build/output_files ; \
		fi
		rm -f *~
