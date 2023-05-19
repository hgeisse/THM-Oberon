
Bootstrap Loader
----------------

The bootstrap loader is a program located in "PROM", i.e., in a small
block RAM within the FPGA (or the simulator) at address 0xFFE000. This
is also the "reset address" where the CPU begins execution after either
power-on or reset. The bootstrap loader is written into the memory when
the FPGA configuration is loaded (or with the command-line argument
"-p <PROM>" in the simulator, where <PROM> is a file in .mem format).

The purpose of the bootstrap loader is to load the program, which the
RISC5 CPU should eventually run, into main memory. There are two possible
sources for the program which is to be loaded: either it is transferred
over a serial line (rather slow), or it is read from an SD card (to which
it has been written beforehand). The source is chosen with switch SW1 on
the board (in the simulator: command-line argument "-s <3 nibbles>"). The
"ON" position loads from the serial line, "OFF" loads from the SD card.
The switch SW0 enforces a "cold start", and should always be set to "ON"
if an actual bootstrap is to be performed. If SW0 is in "OFF" position,
and the system has already been running before the bootstrap loader was
started (e.g., by pressing the reset button during program execution),
the bootstrap proper is skipped, and control is directly transferred to
memory location 0.

Note: In the simulator, there is a third possibility to get a program
into main memory. The command-line argument "-r <RAM>" loads the memory
directly with the file <RAM>, which also must be in .mem format. In the
real world however, there is no magic - this is of course not possible
with an FPGA board.


Serial Line Bootstrap
---------------------

The program "serlink", running on any computer connected to the other side
of the serial line, is essentially a terminal emulator: it sends keyboard
input over the serial line and displays characters arriving over the line
on the screen. But it is also able to send a binary file over the line
before entering terminal emulation mode, observing the following protocol.

1. Power-on and reset the board or start the simulator, with the bootstrap
   loader in memory, and SW1/SW0 both set to "ON".
2. Start serlink, specifying the name of a binary file as its argument.
3. serlink sends n (unsigned integer), the number of bytes to transfer.
   n must be divisible by 4.
4. serlink sends addr (unsigned integer), the load address.
   addr must be divisible by 4.
5. serlink sends exactly n bytes of data. The bootstrap loader stores
   these bytes in main memory, starting at addr.
6. serlink repeats steps 3, 4, and 5, until there is no data left.
7. serlink sends n = 0, signalling end of transfer.
8. The bootstrap loader responds with a single byte of 0x10 ("ACK"), and
   jumps to address 0 in main memory. Any other answer means "failure".
9. serlink enters terminal emulation mode.

Integers are transmitted as 4 bytes, least significand byte first.


SD Card Bootstrap
-----------------

1. Prepare a disk image by installing the Oberon system with the help of
   the simulator on a "disk", which in fact is a file in the host system.
   That's all if you want to use the simulator.
   If you want to use the FPGA board, the easiest way is to copy the disk
   image directly to an SD card ("directly" means: straight to the raw
   device, *not* as a file in some file system). Proceed as follows:
   Insert a blank SD card into a USB SD card writer, and plug the USB
   device into the development system. NOTE: Do not mount the device
   (or, if it is automatically mounted, unmount it)! Any file system on
   the device will be overwritten. Now use "dd" to copy the disk image
   directly to the USB device. NOTE: You have to do this as root. An error
   in the output device specification may destroy the file system of your
   development computer! The command is:
     sudo dd if=Oberon.dsk of=/dev/???
   Replace "???" by the device name of the USB SD card writer.
   Remove the SD card from the USB SD card writer and insert it into the
   card slot of the FPGA board.
   An alternative, safer, and more time-consuming way to get the Oberon
   system onto an SD card would be installing the system directly on the
   FPGA board, using the serial line as communication channel.
   All of these procedures are supported by scripts, which can be found
   in the "install" subdirectory.
2. Power-on and reset the board or start the simulator, with the bootstrap
   loader in memory, SW1 set to "OFF" and SW0 set to "ON".
3. The disk bootstrap loads the 512-byte SD card block FSoffset+4 into
   memory at address 0. In our implementation, FSoffset is zero, so that
   SD card block number 4 is loaded. In units of the Oberon file system,
   with sectors of size 1 KB, this equals sector number 2. This is the
   place of the pre-linked "Modules.bin" inner core on disk (sector 0 is
   not used, and sector 1 holds the root page of the disk's directory).
   After this first sector is loaded, the "limit" (the first address in
   memory which is *not* loaded by the bootstrap) can be found at memory
   address 16.
4. The bootstrap loads consecutive sectors from the disk into consecutive
   memory locations, until the destination address has reached the limit.
   The bootstrap stores "MemLim" (top of heap, 0xFE0000 in our system) and
   "stackOrg" (top of stack, 0x800000 in our system) into memory locations
   12 and 24, respectively, and transfers execution to memory location zero.


LED Indicators
--------------

Eight LEDs are used to indicate the progress of the bootstrap.

1. After power-on, all LEDs are off.
2. As soon as the bootstrap loader executes a cold start, the LEDs show
   a pattern of 0x80 (8 bits, leftmost bit is ON, all others are OFF).
3. SPI gets initialized and switch 1 is tested. If switch 1 is "ON"
   (i.e., loading from the serial line is requested), the LEDs change
   to 0x81. If switch 1 is "OFF" (i.e., loading from disk is requested),
   the LEDs change to 0x82. Then loading starts.
4. In either case, when the loading is finished, the LEDs change to 0x84,
   and the processor executes a jump to address 0.

