MODULE Oberon0; (*Oberon-0 command interpreter for Original Oberon 2013; AP 4.4.18*)
  IMPORT SYSTEM, Kernel, FileDir, Files, Modules, RS232;
  CONST swi = -60; (*switches*)
    stat = -52; (*RS-232*)
    BlkLen = 255; (*packet size for Send and Receive*)
    REQ = 20H; REC = 21H; SND = 22H; ACK = 10H; NAK = 11H;
    screenbase = 0E7F00H; screensize = 1024 * 768 DIV 8; (*1024 x 768 pixel monocolor display*)
    maxCode = 8000;

  VAR pat: ARRAY 32 OF CHAR;

  (*------------ send and receive files ------------*)

  PROCEDURE Receive; (*filename - receive file*)
    VAR x, n, n0: INTEGER;
      name: ARRAY 32 OF CHAR;
      F: Files.File; R: Files.Rider;
  BEGIN RS232.RecStr(name); RS232.Send(ACK);
    F := Files.New(name); Files.Set(R, F, 0);
    REPEAT (*receive packet*)
      RS232.Rec(n); n0 := n;
      WHILE n > 0 DO RS232.Rec(x); Files.Write(R, CHR(x)); DEC(n) END ;
      RS232.Send(ACK)
    UNTIL n0 < BlkLen;
    Files.Register(F); RS232.Send(ACK)
  END Receive;

  PROCEDURE Send; (*filename - send file*)
    VAR ch: CHAR;
      x, n, n0, L: INTEGER;
      name: ARRAY 32 OF CHAR;
      F: Files.File; R: Files.Rider;
  BEGIN RS232.RecStr(name); F := Files.Old(name);
    IF F # NIL THEN
      RS232.Send(ACK); L := Files.Length(F); Files.Set(R, F, 0);
      REPEAT (*send packet*)
        IF L > BlkLen THEN n := BlkLen ELSE n := L END ;
        n0 := n; RS232.Send(n); DEC(L, n);
        WHILE n > 0 DO Files.Read(R, ch); RS232.Send(ORD(ch)); DEC(n) END ;
        RS232.Rec(x);
        IF x # ACK THEN n0 := 0 END
      UNTIL n0 < BlkLen;
      RS232.Rec(x)
    ELSE RS232.Send(NAK)
    END
  END Send;

  (*------------ Oberon-0 commands ------------*)

  PROCEDURE Mirror; (*n - mirror integer n*)
    VAR n: INTEGER;
  BEGIN RS232.RecInt(n); RS232.SendStr("Mirror "); RS232.SendInt(n)
  END Mirror;

  PROCEDURE Inspect; (*a, n - show (in hex) M[a], M[a+4], ..., M[a+n*4]*)
    VAR m, n, adr, data: INTEGER;
  BEGIN RS232.RecInt(adr); RS232.RecInt(n); RS232.SendStr("Inspect");
    adr := adr DIV 20H * 20H;
    WHILE n > 0 DO DEC(n, 8);
      RS232.Line; RS232.SendHex(adr); RS232.SendStr("  "); m := 8;
      REPEAT SYSTEM.GET(adr, data); INC(adr, 4); RS232.SendHex(data); DEC(m) UNTIL m = 0
    END
  END Inspect;

  PROCEDURE FillDisplay; (*w - fill display with words w*)
    VAR w, adr: INTEGER;
  BEGIN RS232.RecInt(w); RS232.SendStr("FillDisplay");
    FOR adr := screenbase TO screenbase + screensize BY 4 DO SYSTEM.PUT(adr, w) END
  END FillDisplay;

  PROCEDURE Sector; (*secno - show disk sector*)
    VAR k, m, n, secno: INTEGER;
      buf: ARRAY 256 OF INTEGER;
  BEGIN RS232.RecInt(secno); RS232.SendStr("Sector"); n := 32;
    Kernel.GetSector(secno*29, buf); k := 0;
    REPEAT DEC(n); m := 8; RS232.Line; RS232.SendHex(k*4); RS232.SendStr("  ");
      REPEAT RS232.SendHex(buf[k]); INC(k); DEC(m) UNTIL m = 0
    UNTIL n = 0
  END Sector;

  PROCEDURE ShowFile; (*filename - show file in hex format*)
    VAR x, n: INTEGER;
      name: ARRAY 32 OF CHAR;
      F: Files.File; R: Files.Rider;
  BEGIN RS232.RecStr(name); RS232.SendStr("ShowFile");
    F := Files.Old(name);
    IF F # NIL THEN
      n := 0; Files.Set(R, F, 0); Files.ReadInt(R, x);
      WHILE ~R.eof DO
        IF n MOD 20H = 0 THEN RS232.Line; RS232.SendHex(n); RS232.SendStr("  ") END ;
        RS232.SendHex(x); INC(n, 4); Files.ReadInt(R, x)
      END ;
      RS232.SendHex(x)
    ELSE RS232.SendStr(" not found")
    END
  END ShowFile;

  PROCEDURE Watch; (*show allocation, nof sectors, switches, and timer*)
    VAR s: LONGINT;
  BEGIN RS232.SendStr("Watch"); RS232.Line;
    RS232.SendStr("  Modules space (bytes)"); RS232.SendInt(Modules.AllocPtr);
    RS232.SendInt(Modules.AllocPtr * 100 DIV Kernel.heapOrg); RS232.SendStr("%"); RS232.Line;
    RS232.SendStr("  Heap speace"); RS232.SendInt(Kernel.allocated);
    RS232.SendInt(Kernel.allocated * 100 DIV (Kernel.heapLim - Kernel.heapOrg)); RS232.SendStr("%"); RS232.Line;
    RS232.SendStr("  Disk sectors "); RS232.SendInt(Kernel.NofSectors);
    RS232.SendInt(Kernel.NofSectors * 100 DIV 10000H); RS232.SendStr("%"); RS232.Line;
    RS232.SendStr("  Switches: swi0 = "); SYSTEM.GET(swi, s); RS232.Send(5);
    IF SYSTEM.BIT(swi, 0) THEN RS232.Send(ORD("0")) ELSE RS232.Send(ORD("1")) END ;
    RS232.SendStr(",  swi1 = "); RS232.Send(5);
    IF SYSTEM.BIT(swi, 1) THEN RS232.Send(ORD("0")) ELSE RS232.Send(ORD("1")) END ;
    RS232.Line;  RS232.SendStr("  Time "); s := Kernel.Time(); RS232.SendInt(s)
  END Watch;

  PROCEDURE ShowModules; (*list modules*)
    VAR M: Modules.Module;
  BEGIN RS232.SendStr("ShowModules");
    M := Modules.root;
    WHILE M # NIL DO RS232.Line;
      IF M.name[0] # 0X THEN
        RS232.SendStr(M.name); RS232.SendInt(M.num); RS232.SendStr("  ");
        RS232.SendHex(ORD(M)); RS232.SendHex(M.code); RS232.SendInt(M.refcnt)
      ELSE RS232.SendStr("---")
      END ;
      M := M.next
    END
  END ShowModules;

  PROCEDURE ShowCommands; (*modname - list commands*)
    VAR M: Modules.Module;
      comadr: LONGINT; i: INTEGER;
      name, cmd: ARRAY 32 OF CHAR; ch: CHAR;
  BEGIN RS232.RecStr(name); RS232.SendStr("ShowCommands");
    Modules.Load(name, M);
    IF M # NIL THEN
      comadr := M.cmd; SYSTEM.GET(comadr, ch); INC(comadr);
      WHILE ch # 0X DO
        RS232.Line; RS232.SendStr(name); cmd[0] := "."; i := 1;
        REPEAT cmd[i] := ch; SYSTEM.GET(comadr, ch); INC(comadr); INC(i) UNTIL ch = 0X;
        cmd[i] := 0X; RS232.SendStr(cmd);
        WHILE comadr MOD 4 # 0 DO INC(comadr) END ;
        INC(comadr, 4); SYSTEM.GET(comadr, ch); INC(comadr)
      END
    ELSE RS232.SendStr("module not found")
    END
  END ShowCommands;

  PROCEDURE List(name: FileDir.FileName; adr: LONGINT; VAR cont: BOOLEAN);
    VAR i0, i, j0, j: INTEGER; hp: FileDir.FileHeader;
  BEGIN i := 0;
    WHILE (pat[i] > "*") & (pat[i] = name[i]) DO INC(i) END ;
    IF (pat[i] = 0X) & (name[i] = 0X) THEN i0 := i; j0 := i
    ELSIF pat[i] = "*" THEN
      i0 := i; j0 := i+1;
      WHILE name[i0] # 0X DO
        i := i0; j := j0;
        WHILE (name[i] # 0X) & (name[i] = pat[j]) DO INC(i); INC(j) END ;
        IF pat[j] = 0X THEN
          IF name[i] = 0X THEN (*match*) j0 := j ELSE INC(i0) END
        ELSIF pat[j] = "*" THEN i0 := i; j0 := j+1
        ELSE INC(i0)
        END
      END
    END ;
    IF (name[i0] = 0X) & (pat[j0] = 0X) THEN (*found*)
      RS232.Line; RS232.SendStr(name);
      IF pat[j0+1] = "!" THEN (*option*)
        Kernel.GetSector(adr, hp); RS232.SendStr("  ");
        RS232.SendInt(hp.aleng*FileDir.SectorSize + hp.bleng - FileDir.HeaderSize); (*length*)
        RS232.SendStr("  "); RS232.SendHex(adr)
      END
    END
  END List;

  PROCEDURE Directory; (*prefix - list files matching the prefix (enumerate directory)*)
    VAR i, x: INTEGER; ch: CHAR;
      pre: ARRAY 32 OF CHAR;
  BEGIN RS232.Rec(x); ch := CHR(x);
    WHILE ch = " " DO RS232.Rec(x); ch := CHR(x) END ; (*spaces*)
    i := 0;
    WHILE ch > " " DO (*pattern*)
      IF ch = "!" THEN pat[i] := 0X; INC(i) END ; (*directory option*)
      pat[i] := ch; INC(i);
      RS232.Rec(x); ch := CHR(x)
    END ;
    WHILE ch # 0X DO RS232.Rec(x); ch := CHR(x) END ;
    WHILE i < LEN(pat) DO pat[i] := 0X; INC(i) END ;
    i := 0;
    WHILE pat[i] > "*" DO pre[i] := pat[i]; INC(i) END ; (*prefix*)
    WHILE i < LEN(pre) DO pre[i] := 0X; INC(i) END ;
    RS232.SendStr("Directory"); FileDir.Enumerate(pre, List)
  END Directory;

  PROCEDURE Delete; (*filename - delete file*)
    VAR res: INTEGER; name: ARRAY 32 OF CHAR;
  BEGIN RS232.RecStr(name); RS232.SendStr("Delete "); Files.Delete(name, res); RS232.SendInt(res)
  END Delete;

  PROCEDURE Load; (*modname - load module*)
    VAR M: Modules.Module;
      name: ARRAY 32 OF CHAR;
  BEGIN RS232.RecStr(name); RS232.SendStr("Load "); Modules.Load(name, M); RS232.SendInt(Modules.res)
  END Load;

  PROCEDURE Unload; (*modname - unload module*)
    VAR name: ARRAY 32 OF CHAR;
  BEGIN RS232.RecStr(name); RS232.SendStr("Unload "); Modules.Free(name); RS232.SendInt(Modules.res)
  END Unload;

  PROCEDURE Call; (*name - call command*)
    VAR mod: Modules.Module; P: Modules.Command;
      i, j, res: INTEGER; ch: CHAR;
      name, Cname: ARRAY 32 OF CHAR;
  BEGIN RS232.RecStr(name); RS232.SendStr("Call");
    i := 0; ch := name[0];
    WHILE (ch # ".") & (ch # 0X) DO INC(i); ch := name[i] END ;
    IF ch = "." THEN
      name[i] := 0X; INC(i);
      Modules.Load(name, mod); res := Modules.res;
      IF Modules.res = 0 THEN
        j := 0; ch := name[i]; INC(i);
        WHILE ch # 0X DO Cname[j] := ch; INC(j); ch := name[i]; INC(i) END ;
        Cname[j] := 0X;
        P := Modules.ThisCommand(mod, Cname); res := Modules.res;
        IF Modules.res = 0 THEN P END
      END
    ELSE res := 5
    END ;
    IF res > 0 THEN
      RS232.SendStr(" error: "); RS232.SendStr(name);
      IF res = 1 THEN RS232.SendStr(" module not found")
      ELSIF res = 2 THEN RS232.SendStr(" bad version")
      ELSIF res = 3 THEN RS232.SendStr(" imports ");
        RS232.SendStr(Modules.imported); RS232.SendStr(" with bad key")
      ELSIF res = 4 THEN RS232.SendStr(" corrupted obj file")
      ELSIF res = 5 THEN RS232.SendStr(" command not found")
      ELSIF res = 7 THEN RS232.SendStr(" insufficient space")
      END
    ELSE RS232.SendStr(" done")
    END
  END Call;

  PROCEDURE WriteMemory; (*adr, n, list of n values (words) - write memory*)
    VAR m, n, adr: INTEGER;
  BEGIN RS232.RecInt(adr); RS232.RecInt(n);
    adr := adr DIV 20H * 20H;
    WHILE n > 0 DO DEC(n); RS232.RecInt(m); SYSTEM.PUT(adr, m); INC(adr, 4) END ;
    RS232.SendStr("WriteMemory")
  END WriteMemory;

  PROCEDURE ClearMemory; (*a, n - clear memory (n words)*)
    VAR n, adr: INTEGER;
  BEGIN RS232.RecInt(adr); RS232.RecInt(n); RS232.SendStr("ClearMemory");
    adr := adr DIV 20H * 20H;
    WHILE n > 0 DO DEC(n); SYSTEM.PUT(adr, 0); INC(adr, 4) END
  END ClearMemory;

  PROCEDURE WriteSector; (*secno, n, list of n values (words) - write sector*)
    VAR k, m, n, secno: INTEGER;
      buf: ARRAY 256 OF INTEGER;
  BEGIN RS232.RecInt(secno); RS232.RecInt(n);
    Kernel.GetSector(secno*29, buf); k := 0;
    WHILE k < n DO RS232.RecInt(m); buf[k] := m; INC(k) END ;
    RS232.SendStr("WriteSector"); Kernel.PutSector(secno*29, buf)
  END WriteSector;

  PROCEDURE ClearSector; (*secno, n - clear sector (n words)*)
    VAR k, n, secno: INTEGER;
      buf: ARRAY 256 OF INTEGER;
  BEGIN RS232.RecInt(secno); RS232.RecInt(n); RS232.SendStr("ClearSector");
    Kernel.GetSector(secno*29, buf); k := 0;
    WHILE k < n DO buf[k] := 0; INC(k) END ;
    Kernel.PutSector(secno*29, buf)
  END ClearSector;

  PROCEDURE LoadBootArea; (*filename - load boot file onto the boot area of the local disk, starting at sector 2*)
    VAR i, secno: INTEGER; b: BYTE;
      F: Files.File; R: Files.Rider;
      buf: ARRAY Kernel.SectorLength OF BYTE;
      name: ARRAY 32 OF CHAR;
  BEGIN RS232.RecStr(name); RS232.SendStr("LoadBootArea  ");
    F := Files.Old(name);
    IF F # NIL THEN RS232.SendInt(Files.Length(F)); (*success*)
      secno := 2; i := 0; Files.Set(R, F, 0); Files.ReadByte(R, b);
      WHILE ~R.eof DO buf[i] := b; INC(i);
        IF i = Kernel.SectorLength THEN Kernel.PutSector(secno*29, buf); INC(secno); i := 0 END ;
        Files.ReadByte(R, b)
      END ;
      IF i > 0 THEN
        WHILE i < Kernel.SectorLength DO buf[i] := 0; INC(i) END ;
        Kernel.PutSector(secno*29, buf)
      END
    ELSE RS232.SendInt(-1) (*file not found*)
    END
  END LoadBootArea;

  PROCEDURE ClearDirectory; (*clear file directory (root page)*)
    VAR i: INTEGER;
      u: FileDir.DirEntry; a: FileDir.DirPage;
  BEGIN RS232.SendStr("ClearDirectory");
    a.mark := FileDir.DirMark; a.m := 0; a.p0 := 0; u.adr := 0; u.p := 0;
    FOR i := 0 TO FileDir.FnLength-1 DO u.name[i] := 0X END ;
    FOR i := 0 TO FileDir.DirPgSize-1 DO a.e[i] := u END ;
    Kernel.PutSector(FileDir.DirRootAdr, a)
  END ClearDirectory;

  PROCEDURE ReadCode(VAR R: Files.Rider; VAR code: ARRAY OF LONGINT; VAR size, start, nofimps, res: INTEGER);
    VAR n, data: INTEGER; ch: CHAR; b: BYTE;               (*size in words, start in bytes*)
      name: ARRAY 32 OF CHAR;
  BEGIN Files.ReadString(R, name); Files.ReadInt(R, data); (*key*)
    Files.ReadByte(R, b); (*version*) Files.ReadInt(R, data); (*size*)
    Files.ReadString(R, name); (*imports*) nofimps := 0;
    WHILE name[0] # 0X DO INC(nofimps); Files.ReadInt(R, data); (*key*) Files.ReadString(R, name) END ;
    Files.ReadInt(R, n);
    WHILE n > 0 DO Files.ReadInt(R, data); DEC(n, 4) END ; (*type descriptors*)
    Files.ReadInt(R, n); (*variable space*)
    Files.ReadInt(R, n);
    WHILE n > 0 DO Files.Read(R, ch); DEC(n) END ; (*strings*)
    Files.ReadInt(R, size);
    IF size > LEN(code) THEN (*program too long*) res := 2
    ELSE n := 0;
      WHILE n < size DO Files.ReadInt(R, data); code[n] := data; INC(n) END ; (*code*)
      Files.ReadString(R, name);
      WHILE name[0] # 0X DO Files.ReadInt(R, data); Files.ReadString(R, name) END ; (*commands*)
      Files.ReadInt(R, n);
      WHILE n > 0 DO Files.ReadInt(R, data); DEC(n) END ; (*entries*)
      Files.ReadInt(R, data);
      WHILE data >= 0 DO Files.ReadInt(R, data) END ; (*pointer references*)
      Files.ReadInt(R, data); (*fixorgP*) Files.ReadInt(R, data); (*fixorgD*)
      Files.ReadInt(R, data); (*fixorgT*) Files.ReadInt(R, start); (*entry*)
      Files.Read(R, ch);
      IF ch # "O" THEN (*corrupted file*) res := 1 ELSE res := 0 END
    END
  END ReadCode;

  PROCEDURE Execute; (*filename - execute standalone program  M.rsc*)
    TYPE Command = PROCEDURE;
    VAR code: ARRAY maxCode OF LONGINT;
      size, start, nofimps, res: INTEGER;
      name: ARRAY 32 OF CHAR;
      body: Command;
      F: Files.File; R: Files.Rider;
  BEGIN RS232.RecStr(name); RS232.SendStr("Execute "); RS232.SendStr(name);
    F := Files.Old(name);
    IF F # NIL THEN Files.Set(R, F, 0);
      ReadCode(R, code, size, start, nofimps, res);
      IF res = 0 THEN
        IF nofimps = 0 THEN RS232.SendStr(" done");
          body := SYSTEM.VAL(Command, SYSTEM.ADR(code) + start); body
        ELSE RS232.SendStr(" imports not allowed")
        END
      ELSIF res = 1 THEN RS232.SendStr(" input file format error")
      ELSIF res = 2 THEN RS232.SendStr(" program too long")
      END
    ELSE RS232.SendStr(" program not found")
    END
  END Execute;

  (*------------ Oberon-0 command interpreter ------------*)

  PROCEDURE Task*;
    VAR i, code, y: INTEGER; end: BOOLEAN;
  BEGIN
    IF SYSTEM.BIT(stat, 0) THEN (*byte available*)
      RS232.Rec(code);
      IF code = REQ THEN RS232.Send(ACK)
      ELSIF code = REC THEN Receive (*filename*)
      ELSIF code = SND THEN Send (*filename*)
      ELSE (*Oberon-0 commands*) end := TRUE;
        code := ROR(code, 8); i := 3;
        REPEAT DEC(i); RS232.Rec(y); code := ROR(code+y, 8) UNTIL i = 0;
        IF code = 0 THEN Mirror (*n*)
        ELSIF code = 1 THEN Inspect (*a, n*)
        ELSIF code = 2 THEN FillDisplay (*w*)
        ELSIF code = 3 THEN Sector (*secno*)
        ELSIF code = 4 THEN ShowFile (*filename*)
        ELSIF code = 7 THEN Watch
        ELSIF code = 10 THEN ShowModules
        ELSIF code = 11 THEN ShowCommands (*modname*)
        ELSIF code = 12 THEN Directory (*prefix*)
        ELSIF code = 13 THEN Delete (*filename*)
        ELSIF code = 20 THEN Load (*modname*)
        ELSIF code = 21 THEN Unload (*modname*)
        ELSIF code = 22 THEN Call (*name*)
        ELSIF code = 50 THEN WriteMemory (*adr, n, list of n values*)
        ELSIF code = 51 THEN ClearMemory (*adr, n*)
        ELSIF code = 52 THEN WriteSector (*secno, n, list of n values*)
        ELSIF code = 53 THEN ClearSector (*secno, n*)
        ELSIF code = 100 THEN LoadBootArea (*filename*)
        ELSIF code = 101 THEN ClearDirectory
        ELSIF code = 102 THEN Execute (*filename*)
        ELSE end := FALSE
        END ;
        IF end THEN RS232.End END
      END
    END
  END Task;

  PROCEDURE Loop*;
  BEGIN REPEAT Task UNTIL FALSE
  END Loop;

  (*------------ initialization ------------*)

  PROCEDURE Init*;  (*initialize the file system if needed*)
    VAR a: FileDir.DirPage;
  BEGIN Kernel.GetSector(FileDir.DirRootAdr, a);
    IF a.mark # FileDir.DirMark THEN
      a.mark := FileDir.DirMark; a.m := 0; a.p0 := 0;
      Kernel.PutSector(FileDir.DirRootAdr, a)
    END
  END Init;

BEGIN IF Modules.importing # "Oberon0" THEN (*loaded by the boot loader*) Init; Modules.Init; Loop END
END Oberon0.
