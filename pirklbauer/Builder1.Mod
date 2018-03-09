MODULE Builder; (*System building tools for Original Oberon 2013 with enlarged boot area; AP 11.11.17*)
  IMPORT Kernel, Files, Texts, Oberon;
  CONST beg = 2; end = 159; NofSecs = end - beg + 1; (*enlarged boot area = sectors 2-159*)
    CR = 0DX; maxCode = 8000;

  VAR W: Texts.Writer;

  PROCEDURE Load*; (*load boot file M.bin onto the boot area of the local disk*)
    VAR i, len, secno: INTEGER; b: BYTE;
      F: Files.File; R: Files.Rider;
      buf: ARRAY Kernel.SectorLength OF BYTE;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN F := Files.Old(S.s);
      IF F # NIL THEN len := Files.Length(F);
        IF len <= NofSecs*Kernel.SectorLength THEN
          Texts.WriteString(W, "  loading "); Texts.WriteString(W, S.s); Texts.WriteInt(W, len, 7);
          Texts.WriteString(W, " onto the boot area of the local disk");
          secno := beg; i := 0; Files.Set(R, F, 0); Files.ReadByte(R, b);
          WHILE ~R.eof & (secno <= end) DO buf[i] := b; INC(i);
            IF i = Kernel.SectorLength THEN Kernel.PutSector(secno*29, buf); INC(secno); i := 0 END ;
            Files.ReadByte(R, b)
          END ;
          IF (i > 0) & (secno <= end) THEN
            WHILE i < Kernel.SectorLength DO buf[i] := 0; INC(i) END ;
            Kernel.PutSector(secno*29, buf);
          END
        ELSE Texts.WriteString(W, S.s); Texts.WriteInt(W, len, 7);
          Texts.WriteString(W, " too large to fit in the boot area of the local disk")
        END
      ELSE Texts.WriteString(W, S.s); Texts.WriteString(W, " not found")
      END
    ELSE Texts.WriteString(W, "Usage: Builder.Load M.bin")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Load;

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
    IF res = -1 THEN Texts.WriteString(W, "Usage: Builder.WriteCode M.rsc M.code") END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END WriteCode;

  PROCEDURE WriteHex*(VAR R: Files.Rider; x: LONGINT); (*write a 4 byte LONGINT in 8 digit hex format*)
    VAR i: INTEGER; y: LONGINT;
      a: ARRAY 10 OF CHAR;
  BEGIN i := 0;
    REPEAT y := x MOD 10H;
      IF y < 10 THEN a[i] := CHR(y + 30H) ELSE a[i] := CHR(y + 37H) END ;
      x := x DIV 10H; INC(i)
    UNTIL i = 8;
    REPEAT DEC(i); Files.Write(R, a[i]) UNTIL i = 0
  END WriteHex;

  PROCEDURE WriteLn*(VAR R: Files.Rider);
  BEGIN Files.Write(R, CR)
  END WriteLn;

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
                      WHILE i < size DO WriteHex(or, code[i]); WriteLn(or); INC(i) END ;
                      WHILE i < len DO WriteHex(or, 0); WriteLn(or); INC(i) END ;
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
    IF res = -1 THEN Texts.WriteString(W, "Usage: Builder.WritePROM M.rsc 512 prom.mem") END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END WritePROM;

  PROCEDURE MakeStream*(VAR ir, or: Files.Rider; blocksize, adr: INTEGER);
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

  PROCEDURE WriteStream*; (*convert boot file M.bin to stream format with specified blocksize and dest adr*)
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
                      IF blocksize = 0 THEN blocksize := len END;
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
    IF res = -1 THEN Texts.WriteString(W, "Usage: Builder.WriteStream M.bin M.stream 512 0") END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END WriteStream;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OR Builder  AP 11.11.17");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END Builder.
