MODULE Fonts; (*module Fonts for a boot file containing the entire Oberon system / Original Oberon 2013 / AP 11.11.17*)
  IMPORT SYSTEM, Files;

  CONST FontFileId = 0DBH;

  TYPE Font* = POINTER TO FontDesc;
    FontDesc* = RECORD
      name*: ARRAY 32 OF CHAR;
      height*, minX*, maxX*, minY*, maxY*: INTEGER;
      next*: Font;
      T: ARRAY 128 OF INTEGER;
      raster: ARRAY 2360 OF BYTE
    END ;

    LargeFontDesc = RECORD (FontDesc) ext: ARRAY 2560 OF BYTE END ;
    LargeFont = POINTER TO LargeFontDesc;

  (* raster sizes: Syntax8 1367, Syntax10 1628, Syntax12 1688, Syntax14 1843, Syntax14b 1983,
      Syntax16 2271, Syntax20 3034, Syntac24 4274, Syntax24b 4302  *)

VAR Default*, root*: Font;

PROCEDURE GetPat*(fnt: Font; ch: CHAR; VAR dx, x, y, w, h, patadr: INTEGER);
  VAR pa: INTEGER;  dxb, xb, yb, wb, hb: BYTE;
BEGIN pa := fnt.T[ORD(ch) MOD 80H]; patadr := pa;
  SYSTEM.GET(pa-3, dxb); SYSTEM.GET(pa-2, xb); SYSTEM.GET(pa-1, yb); SYSTEM.GET(pa, wb); SYSTEM.GET(pa+1, hb);
  dx := dxb; x := xb; y := yb; w := wb; h := hb;
  IF yb < 128 THEN y := yb ELSE y := yb - 256 END
END GetPat;

PROCEDURE This*(name: ARRAY OF CHAR): Font;

  TYPE RunRec = RECORD beg, end: BYTE END ;
    BoxRec = RECORD dx, x, y, w, h: BYTE END ;
    
  VAR F: Font; LF: LargeFont;
    f: Files.File; R: Files.Rider;
    NofRuns, NofBoxes: BYTE;
    NofBytes: INTEGER;
    height, minX, maxX, minY, maxY: BYTE;
    i, j, k, m, n: INTEGER;
    a, a0: INTEGER;
    b, beg, end: BYTE;
    run: ARRAY 16 OF RunRec;
    box: ARRAY 512 OF BoxRec;

  PROCEDURE RdInt16(VAR R: Files.Rider; VAR b0: BYTE);
    VAR b1: BYTE;
  BEGIN Files.ReadByte(R, b0); Files.ReadByte(R, b1)
  END RdInt16;

BEGIN F := root;
  WHILE (F # NIL) & (name # F.name) DO F := F.next END;
  IF F = NIL THEN
    f := Files.Old(name);
    IF f # NIL THEN
      Files.Set(R, f, 0); Files.ReadByte(R, b);
      IF b = FontFileId THEN
        Files.ReadByte(R, b); (*abstraction*)
        Files.ReadByte(R, b); (*family*)
        Files.ReadByte(R, b); (*variant*)
        NEW(F); F.name := name;
        RdInt16(R, height); RdInt16(R, minX); RdInt16(R, maxX); RdInt16(R, minY); RdInt16(R, maxY); RdInt16(R, NofRuns);
        NofBoxes := 0; k := 0;
        WHILE k # NofRuns DO
          RdInt16(R, beg);
          run[k].beg := beg; RdInt16(R, end);
          run[k].end := end; NofBoxes := NofBoxes + end - beg; INC(k)
        END;
        NofBytes := 5; j := 0;
        WHILE j # NofBoxes DO
          RdInt16(R, box[j].dx); RdInt16(R, box[j].x); RdInt16(R, box[j].y);
          RdInt16(R, box[j].w); RdInt16(R, box[j].h);
          NofBytes := NofBytes + 5 + (box[j].w + 7) DIV 8 * box[j].h;
          INC(j)
        END;
        IF NofBytes < 2300 THEN NEW(F) ELSE NEW(LF); F := LF END ;
        F.name := name;
        F.height := height; F.minX := minX; F.maxX := maxX; F.maxY := maxY;
        IF minY >= 80H THEN F.minY := minY - 100H ELSE F.minY := minY END ;
        a0 := SYSTEM.ADR(F.raster);
        SYSTEM.PUT(a0, 0X); SYSTEM.PUT(a0+1, 0X); SYSTEM.PUT(a0+2, 0X); SYSTEM.PUT(a0+3, 0X); SYSTEM.PUT(a0+4, 0X);
        (*null pattern for characters not in a run*)
        INC(a0, 2); a := a0+3; j := 0; k := 0; m := 0;
        WHILE k < NofRuns DO
          WHILE (m < run[k].beg) & (m < 128) DO F.T[m] := a0; INC(m) END;
          WHILE (m < run[k].end) & (m < 128) DO
            F.T[m] := a+3;
            SYSTEM.PUT(a, box[j].dx); SYSTEM.PUT(a+1, box[j].x); SYSTEM.PUT(a+2, box[j].y);
            SYSTEM.PUT(a+3, box[j].w); SYSTEM.PUT(a+4, box[j].h); INC(a, 5);
            n := (box[j].w + 7) DIV 8 * box[j].h;
            WHILE n # 0 DO DEC(n); Files.ReadByte(R, b); SYSTEM.PUT(a, b); INC(a) END ;
            INC(j); INC(m)
          END;
          INC(k)
        END;
        WHILE m < 128 DO F.T[m] := a0; INC(m) END ;
        F.next := root; root := F
      ELSE (*bad file id*) F := Default
      END
    ELSE (*font file not available*) F := Default
    END
  END;
  RETURN F
END This;

PROCEDURE Free*;  (*remove all but first two from font list*)
  VAR f: Font;
BEGIN f := root.next;
  IF f # NIL THEN f := f.next END ;
  f.next := NIL
END Free;

PROCEDURE Init; (*create the default font file Oberon10.Scn.Fnt if needed*)
  VAR FntAdr: ARRAY 16 OF INTEGER;
    FntSize, i: INTEGER; ch: CHAR;
    F: Files.File; R: Files.Rider;
BEGIN F := Files.Old("Oberon10.Scn.Fnt");
  IF F = NIL THEN F := Files.New("Oberon10.Scn.Fnt");
    IF F # NIL THEN FntSize := 8*8*32 + 7*32 + 12; (*2284*)
      (*hexstrings created with hexdump command*)
      FntAdr[0] := SYSTEM.ADR($
        DB 00 53 20 0C 00 00 00 0A 00 FD FF 09 00 06 00
        09 00 0A 00 1A 00 7F 00 80 00 96 00 9B 00 9C 00
        9F 00 A0 00 AB 00 AC 00 0C 00 00 00 00 00 00 00
        00 00 08 00 02 00 00 00 05 00 09 00 08 00 02 00
        00 00 05 00 09 00 08 00 01 00 00 00 06 00 06 00
        08 00 01 00 00 00 06 00 06 00 08 00 01 00 00 00
        05 00 09 00 08 00 01 00 00 00 05 00 09 00 03 00
        00 00 00 00 00 00 00 00 04 00 02 00 00 00 01 00
        08 00 05 00 01 00 05 00 03 00 03 00 07 00 01 00
        00 00 05 00 08 00 06 00 00 00 FF FF 05 00 0A 00
        08 00 01 00 00 00 06 00 08 00 06 00 00 00 00 00
        05 00 08 00 03 00 01 00 05 00 01 00 03 00 04 00
        01 00 FE FF 03 00 0B 00 04 00 00 00 FE FF 03 00
        0B 00 06 00 01 00 01 00 05 00 05 00 06 00 01 00
        01 00 05 00 05 00 03 00 01 00 FE FF 01 00 04 00
        06 00 01 00 03 00 05 00 01 00 03 00 01 00 00 00$);
      FntAdr[1] := SYSTEM.ADR($
        01 00 02 00 06 00 01 00 00 00 04 00 08 00 06 00
        00 00 00 00 05 00 08 00 06 00 01 00 00 00 03 00
        08 00 06 00 01 00 00 00 05 00 08 00 06 00 01 00
        00 00 04 00 08 00 06 00 00 00 00 00 06 00 08 00
        06 00 01 00 00 00 04 00 08 00 06 00 00 00 00 00
        05 00 08 00 06 00 00 00 00 00 05 00 08 00 06 00
        00 00 00 00 05 00 08 00 06 00 00 00 00 00 05 00
        08 00 03 00 01 00 00 00 01 00 06 00 03 00 01 00
        FE FF 01 00 08 00 06 00 00 00 00 00 06 00 06 00
        06 00 01 00 02 00 05 00 03 00 06 00 00 00 00 00
        06 00 06 00 05 00 01 00 00 00 04 00 08 00 0A 00
        01 00 FE FF 08 00 0A 00 07 00 00 00 00 00 07 00
        08 00 07 00 01 00 00 00 05 00 08 00 06 00 01 00
        00 00 05 00 08 00 08 00 01 00 00 00 06 00 08 00
        06 00 01 00 00 00 04 00 08 00 05 00 01 00 00 00
        04 00 08 00 07 00 00 00 00 00 06 00 08 00 07 00$);
      FntAdr[2] := SYSTEM.ADR($
        01 00 00 00 05 00 08 00 03 00 01 00 00 00 01 00
        08 00 03 00 00 00 00 00 02 00 08 00 06 00 01 00
        00 00 05 00 08 00 05 00 01 00 00 00 04 00 08 00
        09 00 00 00 00 00 09 00 08 00 08 00 01 00 00 00
        06 00 08 00 09 00 01 00 00 00 07 00 08 00 06 00
        01 00 00 00 05 00 08 00 09 00 01 00 FE FF 07 00
        0A 00 07 00 01 00 00 00 05 00 08 00 06 00 01 00
        00 00 04 00 08 00 05 00 00 00 00 00 05 00 08 00
        07 00 01 00 00 00 05 00 08 00 06 00 00 00 00 00
        06 00 08 00 0A 00 00 00 00 00 0A 00 08 00 07 00
        01 00 00 00 05 00 08 00 05 00 00 00 00 00 05 00
        08 00 06 00 01 00 00 00 04 00 08 00 04 00 01 00
        FE FF 03 00 0B 00 06 00 01 00 FF FF 04 00 08 00
        04 00 00 00 FE FF 03 00 0B 00 06 00 01 00 00 00
        05 00 07 00 03 00 00 00 03 00 03 00 01 00 05 00
        01 00 07 00 02 00 02 00 06 00 01 00 00 00 04 00$);
      FntAdr[3] := SYSTEM.ADR($
        06 00 06 00 01 00 00 00 04 00 09 00 05 00 01 00
        00 00 04 00 06 00 06 00 01 00 00 00 04 00 09 00
        06 00 01 00 00 00 04 00 06 00 03 00 00 00 00 00
        03 00 09 00 06 00 01 00 FD FF 05 00 09 00 06 00
        01 00 00 00 04 00 09 00 03 00 01 00 00 00 01 00
        08 00 03 00 00 00 FD FF 02 00 0B 00 05 00 01 00
        00 00 04 00 09 00 03 00 01 00 00 00 01 00 09 00
        09 00 01 00 00 00 07 00 06 00 06 00 01 00 00 00
        04 00 06 00 06 00 01 00 00 00 04 00 06 00 06 00
        01 00 FD FF 04 00 09 00 06 00 01 00 FD FF 04 00
        09 00 04 00 01 00 00 00 03 00 06 00 04 00 01 00
        00 00 03 00 06 00 04 00 00 00 00 00 04 00 08 00
        06 00 01 00 00 00 04 00 06 00 05 00 00 00 00 00
        05 00 06 00 09 00 00 00 00 00 09 00 06 00 06 00
        01 00 00 00 04 00 06 00 05 00 00 00 FD FF 05 00
        09 00 04 00 00 00 00 00 04 00 06 00 04 00 00 00$);
      FntAdr[4] := SYSTEM.ADR($
        FE FF 03 00 0B 00 05 00 02 00 FE FF 01 00 0B 00
        04 00 01 00 FE FF 03 00 0B 00 06 00 00 00 02 00
        06 00 02 00 07 00 00 00 00 00 07 00 09 00 09 00
        01 00 00 00 07 00 09 00 07 00 01 00 00 00 05 00
        08 00 06 00 01 00 00 00 04 00 08 00 06 00 01 00
        00 00 04 00 08 00 06 00 01 00 00 00 04 00 08 00
        06 00 01 00 00 00 04 00 09 00 06 00 01 00 00 00
        04 00 09 00 03 00 00 00 00 00 03 00 09 00 06 00
        01 00 00 00 04 00 09 00 06 00 01 00 00 00 04 00
        09 00 06 00 01 00 00 00 04 00 09 00 06 00 01 00
        00 00 04 00 09 00 03 00 01 00 00 00 02 00 09 00
        06 00 01 00 00 00 04 00 09 00 06 00 01 00 00 00
        04 00 09 00 06 00 01 00 00 00 04 00 09 00 06 00
        01 00 00 00 04 00 08 00 03 00 00 00 00 00 03 00
        08 00 05 00 01 00 FD FF 04 00 09 00 06 00 01 00
        00 00 04 00 09 00 06 00 01 00 00 00 04 00 09 00$);
      FntAdr[5] := SYSTEM.ADR($
        06 00 00 00 02 00 06 00 01 00 06 00 00 00 00 00
        00 00 00 00 06 00 01 00 00 00 05 00 09 00 01 03
        05 09 11 09 05 03 01 01 03 07 0F 1F 0F 07 03 01
        3F 21 21 21 21 3F 3F 3F 3F 3F 3F 3F 10 18 14 12
        11 12 14 18 10 10 18 1C 1E 1F 1E 1C 18 10 01 00
        00 01 01 01 01 01 05 05 05 0A 0A 1F 0A 0A 1F 0A
        0A 04 0F 14 14 0C 06 05 05 1E 04 1A 2A 2C 34 0B
        0D 15 16 1B 0D 19 0A 04 0A 0A 0C 01 01 01 04 02
        02 01 01 01 01 01 02 02 04 01 02 02 04 04 04 04
        04 02 02 01 0A 04 1F 04 0A 04 04 1F 04 04 01 01
        01 01 1F 01 01 01 01 02 02 04 04 08 08 0E 11 11
        11 11 11 11 0E 04 04 04 04 04 05 06 04 1F 01 02
        04 04 08 08 07 07 08 08 08 07 08 08 07 08 08 08
        3F 09 0A 0C 08 07 08 08 08 07 01 02 0E 0E 11 11
        13 0D 01 02 1C 02 02 04 04 08 08 10 1F 0E 11 11
        11 0E 11 11 0E 07 08 10 16 19 11 11 0E 01 01 00$);
      FntAdr[6] := SYSTEM.ADR($
        00 01 01 01 01 01 01 00 00 01 01 30 0C 03 03 0C
        30 1F 00 1F 03 0C 30 30 0C 03 02 00 02 02 04 08
        08 07 1C 02 6D B5 A5 A5 A5 B9 42 3C 41 41 22 3E
        14 14 08 08 0F 11 11 11 0F 11 11 0F 1C 02 01 01
        01 01 02 1C 0F 11 21 21 21 21 11 0F 0F 01 01 01
        0F 01 01 0F 01 01 01 01 0F 01 01 0F 3C 22 21 21
        01 01 02 1C 11 11 11 11 1F 11 11 11 01 01 01 01
        01 01 01 01 03 02 02 02 02 02 02 02 11 09 05 03
        03 05 09 11 0F 01 01 01 01 01 01 01 11 01 11 01
        11 01 AA 00 AA 00 AA 00 44 00 44 00 31 31 29 29
        25 25 23 23 1C 22 41 41 41 41 22 1C 01 01 01 01
        0F 11 11 0F 60 10 1C 22 41 41 41 41 22 1C 11 11
        09 05 0F 11 11 0F 07 08 08 04 02 01 01 0E 04 04
        04 04 04 04 04 1F 0E 11 11 11 11 11 11 11 0C 0C
        12 12 12 21 21 21 84 00 84 00 4A 01 4A 01 4A 01
        31 02 31 02 31 02 11 11 0A 04 04 0A 11 11 04 04$);
      FntAdr[7] := SYSTEM.ADR($
        04 04 0A 0A 11 11 0F 01 02 02 04 04 08 0F 07 01
        01 01 01 01 01 01 01 01 07 08 08 04 04 02 02 01
        01 07 04 04 04 04 04 04 04 04 04 07 04 04 04 04
        15 0A 04 07 02 01 0B 0D 09 0E 09 0E 07 09 09 09
        0B 0D 01 01 01 07 09 01 01 01 0E 0B 0D 09 09 09
        0E 08 08 08 07 09 01 0F 09 0E 02 02 02 02 02 07
        02 02 06 07 09 09 0E 02 07 09 09 1E 09 09 09 09
        0B 0D 01 01 01 01 01 01 01 01 01 00 01 01 02 02
        02 02 02 02 02 02 00 02 09 05 03 03 05 09 01 01
        01 01 01 01 01 01 01 01 01 01 49 49 49 49 5B 6D
        09 09 09 09 0B 0D 07 09 09 09 09 0E 01 01 01 07
        09 09 09 0B 0D 08 08 08 0B 0D 09 09 09 0E 01 01
        01 01 07 05 03 04 06 03 01 06 06 0A 02 02 02 0F
        02 02 0B 0D 09 09 09 09 04 04 0A 0A 11 11 44 00
        44 00 AA 00 AA 00 11 01 11 01 09 09 06 06 09 09
        01 02 02 04 04 0A 0A 11 11 0F 01 02 04 08 0F 04$);
      FntAdr[8] := SYSTEM.ADR($
        02 02 02 02 01 02 02 02 02 04 01 01 01 01 01 01
        01 01 01 01 01 01 02 02 02 02 04 02 02 02 02 01
        19 26 41 41 22 3E 14 14 08 08 22 1C 22 41 41 41
        41 22 1C 22 0E 11 11 11 11 11 15 15 0B 0D 09 0E
        09 0E 00 0A 07 09 09 09 09 0E 00 0A 0B 0D 09 09
        09 09 00 09 0B 0D 09 0E 09 0E 00 0A 04 07 09 01
        0F 09 0E 00 0A 04 02 02 02 02 02 02 00 05 02 07
        09 09 09 09 0E 00 09 06 0B 0D 09 09 09 09 00 09
        06 0B 0D 09 0E 09 0E 00 04 02 07 09 01 0F 09 0E
        00 04 02 01 01 01 01 01 01 00 02 01 07 09 09 09
        09 0E 00 04 02 0B 0D 09 09 09 09 00 04 02 07 09
        01 0F 09 0E 00 04 08 07 09 01 0F 09 0E 00 0A 02
        02 02 02 02 02 00 05 04 06 00 07 09 01 01 01 0E
        0B 0D 09 0E 09 0E 00 04 08 09 09 09 09 0B 0D 00
        05 0A 3F 0D 11 11 11 09 05 09 09 06$);
      Files.Set(R, F, 0); Files.Set(R, F, 0);
      FOR i := 0 TO FntSize-1 DO SYSTEM.GET(FntAdr[0] + i, ch); Files.Write(R, ch) END ;
      Files.Register(F)
    END
  END
END Init;

BEGIN Init; root := NIL; Default := This("Oberon10.Scn.Fnt")
END Fonts.
