program ed8conv;

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Windows, System.SysUtils, System.Classes;

{$SETPEFLAGS IMAGE_FILE_RELOCS_STRIPPED}

var
  LeftBits, TempBits: Byte;

procedure VerticalFlip(InputStream: TStream; Width, Height: Integer);
var
  tmpStream: TStream;
  i: Integer;
begin
  tmpStream:=TMemoryStream.Create;
  try
    for i:=Height-1 downto 0 do
    begin
      InputStream.Seek(i*Width,soBeginning);
      tmpStream.CopyFrom(InputStream,Width);
    end;
    InputStream.Size:=0;
    tmpStream.Seek(0,soBeginning);
    InputStream.CopyFrom(tmpStream,tmpStream.Size);
  finally tmpStream.Free end;
end;

procedure WriteBit(bit: Byte; OutputStream: TStream);
begin
  TempBits:=((TempBits shr 1) and $7F) or ((bit shl 7) and $80);
  Inc(LeftBits);
  if LeftBits=8 then
  begin
    OutputStream.Write(TempBits, 1);
    TempBits:=0;
    LeftBits:=0;
  end;
end;

procedure bmp2ed8;
var
  MemoryStream1, MemoryStream2, TempStream, TempStream2: TMemoryStream;
  LongWord1, NumOfColors, DIBSize, BmpDataStart, BmpDataSize: LongWord;
  Word1: Word;
  Byte1: Byte;
  i, ImageWidth, ImageHeight: Integer;
  InversedFlag: Boolean;
begin
  MemoryStream1:=TMemoryStream.Create; MemoryStream2:=TMemoryStream.Create;
  try
    MemoryStream1.LoadFromFile(ParamStr(1));
    MemoryStream1.Position:=$A;
    MemoryStream1.ReadBuffer(BmpDataStart,4);
    MemoryStream1.ReadBuffer(DIBSize,4);
    //if not (DIBSize=$28) then begin Writeln('Error: BITMAPINFOHEADER v1 support only'); Readln; exit end;
    MemoryStream1.Position:=$12;
    InversedFlag:=False;
    MemoryStream1.ReadBuffer(ImageWidth,4);
    if ImageWidth<0 then ImageWidth:=Abs(ImageWidth);
    MemoryStream1.ReadBuffer(ImageHeight,4);
    if ImageHeight<0 then begin ImageHeight:=Abs(ImageHeight); InversedFlag:=True end;
    BmpDataSize:=ImageWidth*ImageHeight;
    MemoryStream1.Position:=$2E;
    MemoryStream1.ReadBuffer(NumOfColors,4);
    if NumOfColors=0 then NumOfColors:=256;
    MemoryStream1.Position:=$E+DIBSize;

    LongWord1:=$6942382E;
    MemoryStream2.WriteBuffer(LongWord1,4);
    LongWord1:=$8C5D8D74;
    MemoryStream2.WriteBuffer(LongWord1,4);
    Word1:=$CB;
    MemoryStream2.WriteBuffer(Word1,2);
    LongWord1:=$100;
    MemoryStream2.WriteBuffer(LongWord1,4);
    Word1:=Word(ImageWidth);
    MemoryStream2.WriteBuffer(Word1,2);
    Word1:=Word(ImageHeight);
    MemoryStream2.WriteBuffer(Word1,2);
    MemoryStream2.WriteBuffer(NumOfColors,4);
    MemoryStream2.WriteBuffer(LongWord1,4);
    for i:=1 to NumOfColors do
    begin
      MemoryStream1.ReadBuffer(Byte1,1);
      MemoryStream2.WriteBuffer(Byte1,1);
      MemoryStream1.ReadBuffer(Byte1,1);
      MemoryStream2.WriteBuffer(Byte1,1);
      MemoryStream1.ReadBuffer(Byte1,1);
      MemoryStream2.WriteBuffer(Byte1,1);
      MemoryStream1.Position:=MemoryStream1.Position+1;
    end;

    MemoryStream1.Position:=BmpDataStart;
    LeftBits:=0;
    TempBits:=0;
    TempStream:=TMemoryStream.Create; TempStream2:=TMemoryStream.Create;
    try
      TempStream.CopyFrom(MemoryStream1, BmpDataSize);
      TempStream.Position:=0;
      if InversedFlag=False then begin VerticalFlip(TempStream, ImageWidth, ImageHeight); TempStream.Position:=0 end;
      while TempStream.Position < TempStream.Size do
      begin
        TempStream.Read(Byte1, 1);
        for i := 1 to 8 do
        begin
          WriteBit(((Byte1 shr 7) and 1), TempStream2);
          Byte1 := Byte1 shl 1;
        end;
        WriteBit(1, TempStream2);
      end;
      WriteBit(1, TempStream2);
      TempStream2.Position:=0;
      LongWord1:=TempStream2.Size;
      MemoryStream2.CopyFrom(TempStream2, LongWord1);
    finally TempStream.Free; TempStream2.Free end;
    MemoryStream2.Position:=$16;
    MemoryStream2.WriteBuffer(LongWord1,4);
    i:=Pos('.',ParamStr(1)); if i>0 then MemoryStream2.SaveToFile(Copy(ParamStr(1),1,Length(ParamStr(1))-(Length(ParamStr(1))-i+1))+'_UNCOMPR.ED8') else MemoryStream2.SaveToFile(ParamStr(1)+'_UNCOMPR.ED8');
  finally MemoryStream1.Free; MemoryStream2.Free end;
end;

var
  FileStream1: TFileStream;
  Word1, Word2: Word;
  LongWord1: LongWord;
begin
  try
    Writeln('Uncompressed ED8 Image Converter v1.1 by RikuKH3');
    Writeln('------------------------------------------------');
    if ParamCount<1 then begin Writeln('Usage: ed8conv.exe <Input 8-bit BMP image>'); Readln; exit end;
    FileStream1:=TFileStream.Create(ParamStr(1), fmOpenRead or fmShareDenyWrite);
    try
      FileStream1.ReadBuffer(Word1,2);
      FileStream1.Position:=$1C;
      FileStream1.ReadBuffer(Word2,2);
      FileStream1.ReadBuffer(LongWord1,4);
    finally FileStream1.Free end;
    if not (Word1=$4D42) then begin Writeln('Error: Input file is not a valid BMP image file'); Readln; exit end;
    if not (Word2=8) then begin Writeln('Error: Input file is not a valid 8-bit BMP image file'); Readln; exit end;
    if not (LongWord1=0) then begin Writeln('Error: Compressed BMP images are not supported'); Readln; exit end;
    bmp2ed8;
  except on E: Exception do begin Writeln('Error: '+E.Message); Readln; exit end end;
end.
