# -------------------------------------------------------------------------------------------------
#  Generate the binaries for the "build-up" boot process
# -------------------------------------------------------------------------------------------------

ORP.Compile Kernel.Mod FileDir.Mod Files.Mod Modules.Mod ~       # modules for the "regular" boot file
ORP.Compile RS232.Mod Oberon0.Mod ~                              # additional modules for the "build-up" boot file
ORP.Compile ORC.Mod/s Oberon0Tool.Mod/s ~                        # partner program ORC and Oberon0 tool module
ORP.Compile Boot.Mod/s ~                                         # boot linker/loader and system building tool

ORP.Compile BootLoadDisk.Mod/s ~      # generate a boot loader for booting the target system from the local disk
ORP.Compile BootLoadLine.Mod/s ~      # generate a boot loader for booting the target system over the data link

Boot.Link Modules ~                   # generate a pre-linked binary file of the "regular" boot file (Modules.bin)
Boot.Link Oberon0 ~                   # generate a pre-linked binary file of the "build-up" boot file (Oberon0.bin)

# -------------------------------------------------------------------------------------------------
#  Build Oberon on the target system by executing the following commands on the host system.
#  Restart the target system over the data link first.
# -------------------------------------------------------------------------------------------------

ORC.Load Oberon0.bin      # load the Oberon-0 command interpreter over the serial link to the target system and start it
ORC.SR 0 1234 ~           # test whether the Oberon-0 command interpreter is running (send and mirror integer s)
ORC.SR 101 ~              # clear the file directory on the target system

ORC.Send Input.rsc Display.rsc Viewers.rsc
      Fonts.rsc Texts.rsc Oberon.rsc
      MenuViewers.rsc TextFrames.rsc
      System.rsc System.Tool
      Oberon10.Scn.Fnt
      Modules.bin
      BootLoadDisk.rsc ~              # send the required files to build the target system

ORC.Send RS232.rsc
      Oberon0.rsc Oberon0Tool.rsc
      Edit.rsc PCLink1.rsc ~          # send additional files to the target system (optional)

ORC.SR 100 Modules.bin ~              # load the "regular" boot file onto the boot area of the local disk of the target system
ORC.SR 102 BootLoadDisk.rsc ~         # reboot the target system from the local disk (i.e. initiate the "regular" boot process)

Alternatively, one can simply load module Oberon on the target system:

ORC.SR 20 Oberon ~                    # load module Oberon on the target system (this will load module System and its imports)

# -------------------------------------------------------------------------------------------------
#  Other Oberon-0 commands
# -------------------------------------------------------------------------------------------------

Rebooting

  ORC.Send Modules.bin ~              # send the "regular" boot file to the target system
  ORC.SR 100 Modules.bin ~            # load the "regular" boot file onto the boot area of the local disk of the target system

  ORC.Send BootLoadDisk.rsc ~         # send the boot loader for booting from the local disk of the target system
  ORC.SR 102 BootLoadDisk.rsc ~       # reboot from the boot area of the local disk ("regular" boot process)

  ORC.Send BootLoadLine.rsc ~         # send the boot loader for booting the target system over the serial link
  ORC.SR 102 BootLoadLine.rsc ~       # reboot the target system over the serial link ("build-up" boot process)
  ORC.Load Oberon0.bin ~              # after booting over the data link, one needs to run ORC.Load Oberon0.bin again

System

  ORC.SR 0 1234 ~                     # send and mirror integer s (test whether the Oberon-0 command interpreter is running)
  ORC.SR 7 ~                          # show allocation, nof sectors, switches, and timer

Files

  ORC.Send System.Tool ~              # send a file to the target system
  ORC.Receive System.Tool ~           # receive a file from the target system
  ORC.SR 13 System.Tool ~             # delete a file on the target system

  ORC.SR 12 "*.rsc" ~                 # list files matching the specified prefix
  ORC.SR 12 "*.Mod!" ~                # list files matching the specified prefix and the directory option set
  ORC.SR 4 System.Tool ~              # show the contents of the specified file

Modules

  ORC.SR 10 ~                         # list modules on the target system
  ORC.SR 11 Kernel ~                  # list commands of a module on the target system
  ORC.SR 22 M.P ~                     # call command on the target system

  ORC.SR 20 Oberon ~                  # load module on the target system
  ORC.SR 21 Edit ~                    # unload module on the target system

Disk

  ORC.SR 3 123 ~                      # show sector   secno
  ORC.SR 52 123 3 10 20 30 ~          # write sector  secno, n, list of n values (words)
  ORC.SR 53 123 3 ~                   # clear sector  secno, n (n words))

Memory

  ORC.SR 1 50000 16 ~                 # show memory   adr, n words (in hex) M[a], M[a+4],...,M[a+n*4]
  ORC.SR 50 50000 3 10 20 30 ~        # write memory  adr, n, list of n values (words)
  ORC.SR 51 50000 32 ~                # clear memory  adr, n (n words))

Display

  ORC.SR 2 0 ~                        # fill display with words w (0 = black)
  ORC.SR 2 4294967295 ~               # fill display with words w (4294967295 = white)

# -------------------------------------------------------------------------------------------------
#  Update the boot area of the local disk with the "regular" boot file
# -------------------------------------------------------------------------------------------------

Boot.Load Modules.bin ~               # load the "regular" boot file onto the boot area of the local disk

# -------------------------------------------------------------------------------------------------
#  Load an entire Oberon system in a single boot file to a target system.
#  This requires the source files Fonts1.Mod, Oberon1.Mod and System1.Mod from the Oberon building tools.
#  Restart the target system over the data link first.
# -------------------------------------------------------------------------------------------------

ORP.Compile Fonts1.Mod Oberon1.Mod System1.Mod/s ~   # compile the files needed to include an entire Oberon system in a boot file
Boot.Link System ~                                   # generate a new boot file containing the entire Oberon system (System.bin)
ORC.Load System.bin ~                                # load the entire Oberon system over the data link to the target system and start it

# -------------------------------------------------------------------------------------------------
#  Load an entire Oberon system in a single boot file to a target system AND configure
#  an ENLARGED boot area on the target system to hold the just transferred boot file.
#  This requires the source files Kernel1.Mod, Fonts1.Mod, Oberon1.Mod and System1.Mod from the Oberon building tools.
#  Restart the target system over the data link first.
# -------------------------------------------------------------------------------------------------

# STEP 1: On the host system execute the following commands:

ORP.Compile Kernel1.Mod Fonts1.Mod Oberon1.Mod System1.Mod ~     # compile the files needed to include an entire Oberon system with an enlarged boot area in a boot file
Boot.Link System ~                                               # generate a new boot file containing the entire Oberon system (System.bin)
ORC.Load System.bin ~                                            # load the entire Oberon system over the data link to the target system and start it

ORC.Send System.bin System.Tool
      BootLoadDisk.rsc RS232.rsc
      Oberon0.rsc Oberon0Tool.rsc                                # send the required files to the target system

# STEP 2: On the target system execute the following commands:

PCLink1.Stop                # stop the PCLink1 background task on the target system (as it uses the same RS232 queue as Oberon0)
Oberon0Tool.Run             # start the Oberon0 background task on the target system

# STEP 3: On the host system execute the following commands:

ORC.SR 100 System.bin ~         # load the enlarged regular boot file onto the enlarged boot area of the disk of the target system (sectors 2-159)
ORC.SR 102 BootLoadDisk.rsc ~   # reboot the target system from its local disk (i.e. initiate the "regular" boot process)

Alternatively, one can manually restart the target system from the local disk.
