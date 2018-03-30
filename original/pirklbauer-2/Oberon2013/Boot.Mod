MODULE Boot;  (*Oberon boot linker/loader for RISC; NW 20.10.13 / CP 21.5.14 / AP 12.12.17 Original Oberon 2013*)
  IMPORT SYSTEM, Kernel, Files, Modules, Texts, Oberon;
  CONST versionkey = 1X; versionkey0 = 0X; MT = 12; DescSize = 80; CR = 0DX; maxCode = 8000;
    beg = 2; end = 63; NofSecs = end - beg + 1; (*boot area = sectors 2-63 in Oberon 2013*)

  VAR binroot, M: Modules.Module;
    binMTOrg, binStart, binAllocPtr, res*, limit: INTEGER;
    importing*, imported*: Modules.ModuleName;
    nocheck: BOOLEAN;
    W: Texts.Writer;

  PROCEDURE ThisFile(name: ARRAY OF CHAR): Files.File;
    VAR i: INTEGER;
      filename: Modules.ModuleName;
  BEGIN i := 0;
    WHILE name[i] # 0X DO filename[i] := name[i]; INC(i) END ;
    filename[i] := "."; filename[i+1] := "r"; filename[i+2] := "s"; filename[i+3] := "c"; filename[i+4] := 0X;
    RETURN Files.Old(filename)
  END ThisFile;

  PROCEDURE error(n: INTEGER; name: ARRAY OF CHAR);
  BEGIN res := n; importing := name
  END error;

  PROCEDURE LinkOne(name: ARRAY OF CHAR; VAR newmod: Modules.Module);
    VAR mod, impmod: Modules.Module;
      i, n, key, impkey, mno, nofimps, size: INTEGER;
      p, u, v, w: INTEGER;  (*addresses*)
      ch: CHAR;
      body: Modules.Command;
      fixorgP, fixorgD, fixorgT: INTEGER;
      disp, adr, imgadr, inst, pno, vno, dest, offset: INTEGER;
      name1, impname: Modules.ModuleName;
      F: Files.File; R: Files.Rider;
      import: ARRAY 16 OF Modules.Module;
  BEGIN mod := binroot; res := 0; nofimps := 0;
    WHILE (mod # NIL) & (name # mod.name) DO mod := mod.next END ;
    IF mod = NIL THEN (*load*)
      F := ThisFile(name);
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, key); Files.Read(R, ch);
        Files.ReadInt(R, size); importing := name1;
        IF (ch = versionkey) OR (ch = versionkey0) THEN (*also allow standalone programs to be "linked"*)
          Files.ReadString(R, impname);   (*imports*)
          WHILE (impname[0] # 0X) & (res = 0) DO
            Files.ReadInt(R, impkey);
            LinkOne(impname, impmod); import[nofimps] := impmod; importing := name1;
            IF res = 0 THEN
              IF impmod.key = impkey THEN INC(impmod.refcnt); INC(nofimps)
              ELSE error(3, name1); imported := impname
              END
            END ;
            Files.ReadString(R, impname)
          END
        ELSE error(2, name1)
        END
      ELSE error(1, name)
      END ;
      IF res = 0 THEN
        INC(size, DescSize);
        IF binAllocPtr + size < limit THEN (*allocate*)
          p := binAllocPtr; i := p;
          WHILE i < ((p + size + 100H) DIV 20H * 20H) DO SYSTEM.PUT(i, 0); INC(i, 4) END ;
          mod := SYSTEM.VAL(Modules.Module, p);
          SYSTEM.PUT(SYSTEM.ADR(binAllocPtr), (p + size + 100H) DIV 20H * 20H); mod.size := binAllocPtr - p;
          IF binroot = NIL THEN mod.num := 1 ELSE mod.num := binroot.num + 1 END ;
          mod.next := binroot; binroot := mod
        ELSE error(7, name1)
        END
      END ;
      IF res = 0 THEN (*read file*)
        INC(p, DescSize); (*allocate descriptor*)
        mod.name := name; mod.key := key; mod.refcnt := 0;
        mod.data := p;  (*data*)
        SYSTEM.PUT(mod.num * 4 + binMTOrg, p);  (*module table entry*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n, 4) END ;  (*type descriptors*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO SYSTEM.PUT(p, 0); INC(p, 4); DEC(n, 4) END ;  (*variable space*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.Read(R, ch); SYSTEM.PUT(p, ch); INC(p); DEC(n) END ;   (*strings*)
        mod.code := p;  (*program*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n) END ;  (*program code*)
        mod.imp := p;  (*copy imports*)
        i := 0;
        WHILE i < nofimps DO
          SYSTEM.PUT(p, import[i]); INC(p, 4); INC(i)          
        END ;
        mod.cmd := p;  (*commands*) Files.Read(R, ch);
        WHILE ch # 0X DO
          REPEAT SYSTEM.PUT(p, ch); INC(p); Files.Read(R, ch) UNTIL ch = 0X;
          REPEAT SYSTEM.PUT(p, 0X); INC(p) UNTIL p MOD 4 = 0;
          Files.ReadInt(R, n); SYSTEM.PUT(p, n); INC(p, 4); Files.Read(R, ch)
        END ;
        REPEAT SYSTEM.PUT(p, 0X); INC(p) UNTIL p MOD 4 = 0;
        mod.ent := p;  (*entries*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n) END ;
        mod.ptr := p;  (*pointer references*)
        Files.ReadInt(R, w);
        WHILE w >= 0 DO SYSTEM.PUT(p, mod.data + w - binStart); INC(p, 4); Files.ReadInt(R, w) END ;
        SYSTEM.PUT(p, 0); INC(p, 4);
        Files.ReadInt(R, fixorgP); Files.ReadInt(R, fixorgD); Files.ReadInt(R, fixorgT);
        Files.ReadInt(R, w); body := SYSTEM.VAL(Modules.Command, mod.code + w - binStart);
        Files.Read(R, ch);
        IF ch # "O" THEN (*corrupted file*)  mod := NIL; error(4, name) END
      END ;
      IF res = 0 THEN (*fixup of BL*)
        adr := mod.code + fixorgP*4;
        WHILE adr # mod.code DO
          SYSTEM.GET(adr, inst);
          mno := inst DIV 100000H MOD 10H;
          pno := inst DIV 1000H MOD 100H;
          disp := inst MOD 1000H;
          SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
          SYSTEM.GET(impmod.ent + pno*4, dest); dest := dest + impmod.code - binStart;
          offset := (dest - (adr - binStart) - 4) DIV 4;
          SYSTEM.PUT(adr, (offset MOD 1000000H) + 0F7000000H);
          adr := adr - disp*4
        END ;
        (*fixup of LDR/STR/ADD*)
        adr := mod.code + fixorgD*4;
        WHILE adr # mod.code DO
          SYSTEM.GET(adr, inst);
          mno := inst DIV 100000H MOD 10H;
          disp := inst MOD 1000H;
          IF mno = 0 THEN (*global*)
            SYSTEM.PUT(adr, (inst DIV 1000000H * 10H + MT) * 100000H + mod.num * 4)
          ELSE (*import*)
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod); v := impmod.num;
            SYSTEM.PUT(adr, (inst DIV 1000000H * 10H + MT) * 100000H + v*4);
            SYSTEM.GET(adr+4, inst); vno := inst MOD 100H;
            SYSTEM.GET(impmod.ent + vno*4, offset);
            IF ODD(inst DIV 100H) THEN offset := offset + impmod.code - impmod.data END ;
            SYSTEM.PUT(adr+4, inst DIV 10000H * 10000H + offset)
          END ;
          adr := adr - disp*4
        END ;
        (*fixup of type descriptors*)
        adr := mod.data + fixorgT*4;
        WHILE adr # mod.data DO
          SYSTEM.GET(adr, inst);
          mno := inst DIV 1000000H MOD 10H;
          vno := inst DIV 1000H MOD 1000H;
          disp := inst MOD 1000H;
          IF mno = 0 THEN (*global*) inst := mod.data - binStart + vno
          ELSE (*import*)
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(impmod.ent + vno*4, offset);
            inst := impmod.data + offset - binStart
          END ;
          SYSTEM.PUT(adr, inst); adr := adr - disp*4
        END ;
        SYSTEM.PUT(binStart, body) (*module initialization body*)
      ELSIF res = 3 THEN importing := name;
        WHILE nofimps > 0 DO DEC(nofimps); DEC(import[nofimps].refcnt) END
      END
    END ;
    newmod :=  mod;
  END LinkOne;

  PROCEDURE Link*;
    VAR F: Files.File; R: Files.Rider;
      M, p: Modules.Module;
      name: Modules.ModuleName;
      i, v: INTEGER;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN name := S.s; Texts.Scan(S);
      IF S.class = Texts.Name THEN res := 0; F := ThisFile(name); (*input file*)
        IF F # NIL THEN F := Files.New(S.s); (*output file*)
          IF F # NIL THEN
            binStart := Modules.AllocPtr; binMTOrg := binStart + 32; binAllocPtr :=  binStart + 256;
            limit := Kernel.heapOrg; DEC(limit, 8000H); binroot := NIL; i := 0;
            WHILE i < DescSize + 256 DO SYSTEM.PUT(binStart + i, 0); INC(i, 4) END ;
            Texts.WriteString(W, "  linking "); Texts.WriteString(W, name);
            Texts.WriteString(W, "  binary buffer at "); Texts.WriteHex(W, binStart); Texts.WriteLn(W);
            LinkOne(name, M);
            IF res = 0 THEN
              SYSTEM.PUT(binStart + 20, SYSTEM.VAL(INTEGER, binroot) - binStart );
              SYSTEM.PUT(binStart + 252, 12345678H); (*fingerprint*)
              p := SYSTEM.VAL(Modules.Module, binroot);
              WHILE p # NIL DO (*fix up module chain of pointers*)
                Texts.WriteString(W, "    "); Texts.WriteString(W, p.name); Texts.WriteString(W, " at ");
                Texts.WriteHex(W, p.data); Texts.WriteString(W, " ("); Texts.WriteHex(W, p.data - binStart);
                Texts.WriteString(W, ") "); Texts.WriteHex(W, p.num);  Texts.WriteLn(W);
                M := p; p := p.next;
                IF M.next # NIL THEN
                  M.next := SYSTEM.VAL(Modules.Module, SYSTEM.VAL(INTEGER, M.next) - binStart)
                END ;
                M.data := M.data - binStart;
                M.code := M.code - binStart;
                i := M.imp;
                WHILE i < M.cmd DO SYSTEM.GET(i, v); SYSTEM.PUT(i, v - binStart); INC(i, 4) END ;
                M.imp := M.imp - binStart;
                M.cmd := M.cmd - binStart;
                M.ent := M.ent - binStart;
                M.ptr := M.ptr - binStart;
                SYSTEM.PUT(binStart + 20H + (4*M.num), M.data)
              END ;
              Files.Set(R, F, 0); i := binStart;
              SYSTEM.PUT(binStart + 16, binAllocPtr - binStart); (*size of linked binary file*)
              SYSTEM.PUT(binStart + 24, 40000H); (*limit / heapOrg*)
              SYSTEM.GET(binStart, v);
              SYSTEM.PUT(binStart, 0E7H * 1000000H + (v DIV 4) - 1); (*branch to module body*)
              WHILE i < binAllocPtr DO SYSTEM.GET(i, v); Files.WriteInt(R, v); INC(i, 4) END ;
              Files.Register(F); Texts.WriteString(W, "    ");
              Texts.WriteString(W, S.s); Texts.WriteString(W, " binary written ");
              Texts.WriteInt(W, Files.Length(F), 6); Texts.WriteString(W, " bytes")
            END
          ELSE Texts.WriteString(W, " cannot create output file "); Texts.WriteString(W, S.s)
          END
        ELSE Texts.WriteString(W, "  input file "); Texts.WriteString(W, name); Texts.WriteString(W, ".rsc not found")
        END
      END
    END ;
    IF res # 0 THEN
      IF res = -1 THEN Texts.WriteString(W, "Usage: Boot.Link modulename outputfile")
      ELSE Texts.WriteString(W, "Link error: "); Texts.WriteString(W, importing);
        IF res = 1 THEN  Texts.WriteString(W, " module not found")
        ELSIF res = 2 THEN Texts.WriteString(W, " bad version")
        ELSIF res = 3 THEN Texts.WriteString(W, " imports ");
          Texts.WriteString(W, imported); Texts.WriteString(W, " with bad key")
        ELSIF res = 4 THEN Texts.WriteString(W, " corrupted obj file")
        ELSIF res = 7 THEN Texts.WriteString(W, " insufficient space")
        ELSE Texts.WriteString(W, " error"); Texts.WriteInt(W, res, 4)
        END
      END
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Link;

  PROCEDURE Load*; (*load boot file onto the boot area of the local disk*)
    VAR i, len, secno: INTEGER; b: BYTE;
      F: Files.File; R: Files.Rider;
      buf: ARRAY Kernel.SectorLength OF BYTE;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN F := Files.Old(S.s);
      IF F # NIL THEN len := Files.Length(F);
        IF nocheck OR (len <= NofSecs*Kernel.SectorLength) THEN
          Texts.WriteString(W, "  loading "); Texts.WriteString(W, S.s); Texts.WriteInt(W, len, 7);
          Texts.WriteString(W, " onto the boot area of the local disk");
          secno := beg; i := 0; Files.Set(R, F, 0); Files.ReadByte(R, b);
          WHILE ~R.eof & (nocheck OR (secno <= end)) DO buf[i] := b; INC(i);
            IF i = Kernel.SectorLength THEN Kernel.PutSector(secno*29, buf); INC(secno); i := 0 END ;
            Files.ReadByte(R, b)
          END ;
          IF (i > 0) & (nocheck OR (secno <= end)) THEN
            WHILE i < Kernel.SectorLength DO buf[i] := 0; INC(i) END ;
            Kernel.PutSector(secno*29, buf);
          END
        ELSE Texts.WriteString(W, S.s); Texts.WriteInt(W, len, 7);
          Texts.WriteString(W, " too large to fit in the boot area of the local disk")
        END
      ELSE Texts.WriteString(W, S.s); Texts.WriteString(W, " not found")
      END
    ELSE Texts.WriteString(W, "Usage: Boot.Load inputfile")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Load;

  PROCEDURE LoadNoCheck*; (*same as Load, but without checking whether the boot file fits into the boot area*)
  BEGIN nocheck := TRUE; Load; nocheck := FALSE
  END LoadNoCheck;

  PROCEDURE ReadCode(VAR R: Files.Rider; VAR code: ARRAY OF LONGINT; VAR size, start, nofimps, res: INTEGER);
    VAR n, data: INTEGER; ch: CHAR; b: BYTE;               (*size in words, start in bytes*)
      name: ARRAY 32 OF CHAR;
  BEGIN Files.ReadString(R, name); Files.ReadInt(R, data); (*key*)
    Files.ReadByte(R, b); (*version*) Files.ReadInt(R, data); (*size*)
    Files.ReadString(R, name); (*imports*) nofimps := 0;
    WHILE ~R.eof & (name[0] # 0X) DO INC(nofimps); Files.ReadInt(R, data); (*key*) Files.ReadString(R, name) END ;
    Files.ReadInt(R, n);
    WHILE ~R.eof & (n > 0) DO Files.ReadInt(R, data); DEC(n, 4) END ; (*type descriptors*)
    Files.ReadInt(R, n); (*variable space*)
    Files.ReadInt(R, n);
    WHILE ~R.eof & (n > 0) DO Files.Read(R, ch); DEC(n) END ; (*strings*)
    Files.ReadInt(R, size);
    IF size > LEN(code) THEN (*program too long*) res := 2
    ELSE n := 0;
      WHILE ~R.eof & (n < size) DO Files.ReadInt(R, data); code[n] := data; INC(n) END ; (*code*)
      Files.ReadString(R, name);
      WHILE ~R.eof & (name[0] # 0X) DO Files.ReadInt(R, data); Files.ReadString(R, name) END ; (*commands*)
      Files.ReadInt(R, n);
      WHILE ~R.eof & (n > 0) DO Files.ReadInt(R, data); DEC(n) END ; (*entries*)
      Files.ReadInt(R, data);
      WHILE ~R.eof & (data >= 0) DO Files.ReadInt(R, data) END ; (*pointer references*)
      Files.ReadInt(R, data); (*fixorgP*) Files.ReadInt(R, data); (*fixorgD*)
      Files.ReadInt(R, data); (*fixorgT*) Files.ReadInt(R, start); (*entry*)
      Files.Read(R, ch);
      IF ch # "O" THEN (*corrupted file*) res := 1 ELSE res := 0 END
    END
  END ReadCode;

  PROCEDURE WriteCode*; (*write code section of M.rsc in binary format with prefix (size, adr) to output file*)
    VAR if, of: Files.File; ir, or: Files.Rider; (*input file, output file*)
      code: ARRAY maxCode OF LONGINT;
      i, size, start, nofimps, res: INTEGER;
      name: ARRAY 32 OF CHAR;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN name := S.s; Texts.Scan(S);
      IF S.class = Texts.Name THEN res := 0; Texts.WriteString(W, "  WriteCode ");
        Texts.WriteString(W, name); Texts.Write(W, " "); Texts.WriteString(W, S.s);
        if := Files.Old(name);
        IF if # NIL THEN of := Files.New(S.s);
          IF of # NIL THEN Files.Set(ir, if, 0); ReadCode(ir, code, size, start, nofimps, res);
            IF res = 0 THEN
              IF nofimps = 0 THEN Files.Set(or, of, 0); i := 0;
                Texts.WriteInt(W, size*4, 6); Texts.WriteInt(W, start, 6); (*bytes*)
                Files.WriteInt(or, size*4); Files.WriteInt(or, start); (*prefix*)
                WHILE i < size DO Files.WriteInt(or, code[i]); INC(i) END ;
                Files.Register(of); Texts.WriteString(W, "  done")
              ELSE Texts.WriteString(W, "  imports not allowed")
              END
            ELSIF res = 1 THEN Texts.WriteString(W, "  input file format error")
            ELSIF res = 2 THEN Texts.WriteString(W, "  program too long")
            END
          ELSE Texts.WriteString(W, "  cannot create output file")
          END ;
          Files.Close(if)
        ELSE Texts.WriteString(W, "  input file not found")
        END
      END
    END ;
    IF res = -1 THEN Texts.WriteString(W, "Usage: Boot.WriteCode M.rsc M.code") END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END WriteCode;

  PROCEDURE WriteHex(VAR R: Files.Rider; x: LONGINT); (*write a 4 byte LONGINT in 8 digit hex format*)
    VAR i: INTEGER; y: LONGINT;
      a: ARRAY 10 OF CHAR;
  BEGIN i := 0;
    REPEAT y := x MOD 10H;
      IF y < 10 THEN a[i] := CHR(y + 30H) ELSE a[i] := CHR(y + 37H) END ;
      x := x DIV 10H; INC(i)
    UNTIL i = 8;
    REPEAT DEC(i); Files.Write(R, a[i]) UNTIL i = 0
  END WriteHex;

  PROCEDURE WritePROM*; (*write code section of M.rsc in PROM format with specified size to output file*)
    VAR if, of: Files.File; ir, or: Files.Rider; (*input file, output file*)
      code: ARRAY maxCode OF LONGINT;
      i, len, size, start, nofimps, res: INTEGER;
      name: ARRAY 32 OF CHAR;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN name := S.s; Texts.Scan(S);
      IF S.class = Texts.Int THEN len := S.i; Texts.Scan(S);
        IF S.class = Texts.Name THEN res := 0; Texts.WriteString(W, "  WritePROM ");
          Texts.WriteString(W, name); Texts.WriteInt(W, len, 5); Texts.Write(W, " "); Texts.WriteString(W, S.s);
          IF len > 0 THEN if := Files.Old(name);
            IF if # NIL THEN of := Files.New(S.s);
              IF of # NIL THEN Files.Set(ir, if, 0); ReadCode(ir, code, size, start, nofimps, res);
                IF res = 0 THEN
                  IF nofimps = 0 THEN
                    IF size <= len THEN Files.Set(or, of, 0); i := 0;
                      WHILE i < size DO WriteHex(or, code[i]); Files.Write(or, CR); INC(i) END ;
                      WHILE i < len DO WriteHex(or, 0); Files.Write(or, CR); INC(i) END ;
                      Files.Register(of); Texts.WriteString(W, "  done")
                    ELSE  Texts.WriteString(W, "  insufficent size")
                    END
                  ELSE Texts.WriteString(W, " imports not allowed")
                  END
                ELSIF res = 1 THEN Texts.WriteString(W, "  input file format error")
                ELSIF res = 2 THEN Texts.WriteString(W, "  program too long")
                END
              ELSE Texts.WriteString(W, "  cannot create output file")
              END ;
              Files.Close(if)
            ELSE Texts.WriteString(W, "  input file not found")
            END
          ELSE Texts.WriteString(W, "  size must be positive")
          END
        END
      END
    END ;
    IF res = -1 THEN Texts.WriteString(W, "Usage: Boot.WritePROM M.rsc 512 prom.mem") END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END WritePROM;

  PROCEDURE MakeStream(VAR ir, or: Files.Rider; blocksize, adr: INTEGER);
    VAR i, a: INTEGER; b: BYTE;
  BEGIN Files.ReadByte(ir, b); i := 0; a := adr;
    WHILE ~ir.eof DO
      IF (i MOD blocksize = 0) THEN i := 0;
        Files.WriteInt(or, blocksize); Files.WriteInt(or, a); INC(a, blocksize)
      END ;
      Files.WriteByte(or, b); INC(i); Files.ReadByte(ir, b)
    END ;
    WHILE i < blocksize DO Files.WriteByte(or, 0); INC(i) END ;
    Files.WriteInt(or, 0)  (*size of last block*)
  END MakeStream;

  PROCEDURE WriteStream*; (*convert boot file to stream format with specified blocksize and dest adr*)
    VAR if, of: Files.File; ir, or: Files.Rider; (*input file, output file*)
      i, len, blocksize, res: INTEGER;
      name, name1: ARRAY 32 OF CHAR;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN name := S.s; Texts.Scan(S);
      IF S.class = Texts.Name THEN name1 := S.s; Texts.Scan(S);
        IF S.class = Texts.Int THEN blocksize := S.i; Texts.Scan(S);
          IF S.class = Texts.Int THEN res := 0; Texts.WriteString(W, "  WriteStream ");
            Texts.WriteString(W, name); Texts.Write(W, " "); Texts.WriteString(W, name1);
            Texts.WriteInt(W, blocksize, 5); Texts.WriteInt(W, S.i, 5);
            IF blocksize >= 0 THEN
              IF S.i >= 0 THEN if := Files.Old(name);
                IF if # NIL THEN len := Files.Length(if);
                  IF len > 0 THEN of := Files.New(name1);
                    IF of # NIL THEN 
                      IF blocksize = 0 THEN blocksize := len END ;
                      Files.Set(ir, if, 0); Files.Set(or, of, 0); i := 0;
                      MakeStream(ir, or, blocksize, S.i);
                      Files.Register(of); Texts.WriteString(W, "  done")
                    ELSE Texts.WriteString(W, "  cannot create output file")
                    END
                  ELSE Texts.WriteString(W, "  input file empty")
                  END ;
                  Files.Close(if)
                ELSE Texts.WriteString(W, "  input file not found")
                END
              ELSE Texts.WriteString(W, "  destination address must >= 0")
              END
            ELSE Texts.WriteString(W, "  block size must be >= 0")
            END
          END
        END
      END
    END ;
    IF res = -1 THEN Texts.WriteString(W, "Usage: Boot.WriteStream inputfile outputfile 512 0") END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END WriteStream;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OR Boot linker/loader  AP 12.12.17");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); nocheck := FALSE
END Boot.
