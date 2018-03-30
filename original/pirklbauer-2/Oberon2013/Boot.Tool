# -----------------------------------------------------------------------------------------
#  Generate the necessary binaries for the build-up boot process
# -----------------------------------------------------------------------------------------

ORP.Compile Kernel.Mod FileDir.Mod Files.Mod Modules.Mod ~   # modules for the "regular" boot file
ORP.Compile RS232.Mod Oberon0.Mod ~                          # additional modules for the "build-up" boot file
ORP.Compile ORC.Mod/s Oberon0Tool.Mod/s ~                    # partner program ORC and Oberon0 tool module

ORP.Compile BootLoadDisk.Mod/s ~      # generate a boot loader for booting the target system from the local disk
ORP.Compile BootLoadLine.Mod/s ~      # generate a boot loader for booting the target system over the data link

Boot.Link Modules RISC2013.Boot ~     # generate a pre-linked binary file of the "regular" boot file
Boot.Link Oberon0 RISC2013.Boot0 ~    # generate a pre-linked binary file of the "build-up" boot file

Boot.Load RISC2013.Boot ~             # load the "regular" boot file onto the boot area of the local disk

# -----------------------------------------------------------------------------------------
#  Build a new Oberon system on a bare metal target system (restart the target system over the data link first)
# -----------------------------------------------------------------------------------------

ORC.Load RISC2013.Boot0          # load the Oberon-0 command interpreter over the serial link to the target system and start it
ORC.SR 0 1234 ~                  # test whether the Oberon-0 command interpreter is running (send and mirror integer s)

ORC.SR 101 ~                     # clear the file directory on the target system

ORC.Send Input.rsc Display.rsc Viewers.rsc
      Fonts.rsc Texts.rsc Oberon.rsc
      MenuViewers.rsc TextFrames.rsc
      System.rsc System.Tool
      Oberon10.Scn.Fnt
      RISC2013.Boot
      BootLoadDisk.rsc ~         # send the required files to start Oberon from the local disk of the target system

ORC.Send RS232.rsc
      Oberon0.rsc Oberon0Tool.rsc
      Boot.rsc
      Edit.rsc PCLink1.rsc ~     # send additional files to the target system (optional)

ORC.SR 100 RISC2013.Boot ~       # load the regular boot file onto the boot area of the local disk of the target system
ORC.SR 102 BootLoadDisk.rsc ~    # reboot the target system from the local disk (initiates the "regular" boot process)

ORC.SR 20 Oberon ~               # load module "Oberon" on the target system (this will also load module "System" and its imports)

# -----------------------------------------------------------------------------------------
#  Other Oberon-0 commands that can be executed via the partner program ORC running on the host system
# -----------------------------------------------------------------------------------------

Rebooting

  ORC.Send RISC2013.Boot ~       # send the regular boot file "RISC2013.Boot" to the target system
  ORC.SR 100 RISC2013.Boot ~     # load the regular boot file onto the boot area of the local disk of the target system

  ORC.Send BootLoadDisk.rsc ~    # send the boot loader for booting from the local disk of the target system
  ORC.SR 102 BootLoadDisk.rsc ~  # reboot from the boot area of the local disk ("regular" boot process)

  ORC.Send BootLoadLine.rsc ~    # send the boot loader for booting the target system over the serial link
  ORC.SR 102 BootLoadLine.rsc ~  # reboot the target system over the serial link ("build-up" boot process)
  ORC.Load RISC2013.Boot0 ~      # after booting over the data link, one needs to run ORC.Load RISC2013.Boot0 again

System

  ORC.SR 0 1234 ~                # send and mirror integer s (test whether the Oberon-0 command interpreter is running)
  ORC.SR 7 ~                     # show allocation, nof sectors, switches, and timer

Files

  ORC.Send Draw.Tool ~           # send a file to the target system
  ORC.Receive Draw.Tool ~        # receive a file from the target system
  ORC.SR 13 Draw.Tool ~          # delete a file on the target system

  ORC.SR 12 "*.rsc" ~            # list files matching the specified prefix
  ORC.SR 12 "*.Mod!" ~           # list files matching the specified prefix and the directory option set
  ORC.SR 4 Boot.Tool ~           # show the contents of the specified file

Modules

  ORC.SR 10 ~                    # list modules on the target system
  ORC.SR 11 Kernel ~             # list commands of a module on the target system
  ORC.SR 22 M.P ~                # call command on the target system

  ORC.SR 20 Oberon ~             # load module on the target system
  ORC.SR 21 Edit ~               # unload module on the target system

Disk

  ORC.SR 3 123 ~                 # show sector   secno
  ORC.SR 52 123 3 10 20 30 ~     # write sector  secno, n, list of n values (words)
  ORC.SR 53 123 3 ~              # clear sector  secno, n (n words))

Memory

  ORC.SR 1 50000 16 ~            # show memory   adr, n words (in hex) M[a], M[a+4],...,M[a+n*4]
  ORC.SR 50 50000 3 10 20 30 ~   # write memory  adr, n, list of n values (words)
  ORC.SR 51 50000 32 ~           # clear memory  adr, n (n words))

Display

  ORC.SR 2 0 ~                   # fill display with words w (0 = black)
  ORC.SR 2 4294967295 ~          # fill display with words w (4294967295 = white)

# -----------------------------------------------------------------------------------------
#  Load an entire Oberon system in a single build-up boot file to a target system (restart the target
#  system over the data link first; requires the source files Fonts1.Mod, Oberon1.Mod, System1.Mod)
# -----------------------------------------------------------------------------------------

# STEP 1: On the host system execute the following commands:
ORP.Compile Fonts1.Mod Oberon1.Mod System1.Mod/s ~   # compile the files needed to include an entire Oberon system in a boot file
Boot.Link System RISC2013.Boot1~                     # generate a new boot file containing the entire Oberon system

ORC.Load RISC2013.Boot1 ~                            # load the entire Oberon system over the data link to the target system and start it

ORC.Send Input.rsc Display.rsc Viewers.rsc ~         # {Fonts,Oberon,System}.rsc created from {Fonts1,Oberon1,System1}.Mod
ORC.Send Fonts.rsc Texts.rsc Oberon.rsc ~
ORC.Send MenuViewers.rsc TextFrames.rsc ~
ORC.Send System.rsc System.Tool Oberon10.Scn.Fnt ~   # send the required files to start Oberon from the local disk
ORC.Send RS232.rsc Oberon0.rsc Oberon0Tool.rsc ~     # send additional files to the target system (optional)
ORC.Send Boot.rsc Edit.rsc PCLink1.rsc ~             # send additional files to the target system (optional)

ORC.Send RISC2013.Boot1 ~                            # send the regular boot file "RISC2013.Boot1" to the target system
ORC.Send BootLoadDisk.rsc ~                          # send the boot loader for booting from the local disk of the target system

# STEP 2: On the target system execute the following commands:
PCLink1.Stop                     # stop the PCLink1 background task on the target system
Oberon0Tool.Run                  # start the Oberon0 background task on the target system

# STEP 3: Back on the host system execute the following commands:
ORC.SR 100 RISC2013.Boot1 ~      # load the regular boot file onto the boot area of the local disk of the target system
ORC.SR 102 BootLoadDisk.rsc ~    # reboot the target system from the local disk (initiates the "regular" boot process)

As an alternative to the first command, one can execute the command Boot.Load RISC2013.Boot1 on the target system.
