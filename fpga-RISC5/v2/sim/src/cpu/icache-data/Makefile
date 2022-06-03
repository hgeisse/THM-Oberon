#
# Makefile to prepare icache contents
#

BUILD = ../../../../../../build

ICACHE_PRG = prog00.asm prog01.asm prog02.asm \
             prog03.asm prog04.asm prog05.asm
ICACHE_MEM = $(patsubst %.asm,%.mem,$(ICACHE_PRG))
ICACHE_LDA = $(patsubst %.asm,%.lda,$(ICACHE_PRG))
ICACHE_DAT = $(patsubst %.asm,%.dat,$(ICACHE_PRG))

all:		$(ICACHE_MEM) $(ICACHE_LDA) $(ICACHE_DAT)

%.mem:		%.asm
		$(BUILD)/bin/asm-RISC5 $< $@

%.lda:		%.asm
		grep ".LOC" $< >$@

%.dat:		%.mem %.lda
		icacheld/icacheld $^ $@

clean:
		rm -f *~ *.mem *.lda *.dat
