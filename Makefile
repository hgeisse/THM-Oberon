#
# Makefile for project THM-Oberon
#

BUILD = `pwd`/build

DIRS = sim serlink tools

all:		builddir
		for i in $(DIRS) ; do \
		  $(MAKE) -C $$i install ; \
		done

builddir:
		mkdir -p $(BUILD)

clean:
		for i in $(DIRS) ; do \
		  $(MAKE) -C $$i clean ; \
		done
		rm -rf $(BUILD)
		rm -f *~
