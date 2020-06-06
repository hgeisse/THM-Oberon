#
# Makefile for installing Oberon on a simulated bare-metal system
#

BUILD=../../../build
KIT=../../Stable
D2O=$(BUILD)/bin/dos2oberon

DISK_SIZE=64M

#MODGRPS=Apps BootLink BootLoad Compiler Editor Fonts Graphics \
#        InnerCore MacroTool Math Oberon0 Out OuterCore PCLink2 Tools
MODGRPS=Oberon0

all:
		@echo "For installing the system:"
		@echo "    Type 'make install' and 'make install-link' (in"
		@echo "    separate windows, in this order). Then type"
		@echo "    '@ sysinst' in the install-link window. When"
		@echo "    the script has been executed, type 'q' in the"
		@echo "    install-link and CTRL-C in the install window."
		@echo "    Make a backup copy of the disk 'Oberon.dsk'."
		@echo "For running an installed system:"
		@echo "    Type 'make run'. If you want to transfer files"
		@echo "    between the host and the Oberon system, start"
		@echo "    PCLink2.Run by clicking the middle button of the"
		@echo "    mouse on this command. Then type 'make run-link'"
		@echo "    in a separate window of the Linux system."

install:	Oberon.dsk BootLoad.bin
		$(BUILD)/bin/sim-ECO32 -i -m 1 -s 1 -u serial.dev \
		  -d Oberon.dsk -r BootLoad.bin -sb 003

install-link:	$(MODGRPS)
		$(BUILD)/bin/serlink Oberon0.bin

Oberon.dsk:
		$(BUILD)/bin/mkdisk Oberon.dsk $(DISK_SIZE)

BootLoad.bin:
		cp $(KIT)/BootLoad/bin/BootLoad.bin .

Oberon0:
		cp $(KIT)/Oberon0/bin/* .

clean:
		rm -f *~
		rm -f serial.dev Oberon.dsk BootLoad.mem
		rm -f Oberon0.bin Modules.bin BootLoad.bin
		rm -f *.rsc *.smb *.Scn.Fnt *.Lib *.Tool
