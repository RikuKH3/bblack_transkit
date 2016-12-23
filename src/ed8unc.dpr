program ed8unc;

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Windows, System.SysUtils, System.Classes;

{$SETPEFLAGS IMAGE_FILE_RELOCS_STRIPPED}

procedure Inverse8bitBitmap (MemoryStreamIn, MemoryStreamOut: TMemoryStream; ImageWidth, ImageHeight, BmpDataSize: LongWord);
var
  i: Integer;
begin
  MemoryStreamIn.Position:=(MemoryStreamIn.Position+BmpDataSize)-ImageWidth;
  for i:=1 to ImageHeight do
  begin
    MemoryStreamOut.CopyFrom(MemoryStreamIn,ImageWidth);
    if (MemoryStreamIn.Position-ImageWidth*2)>0 then MemoryStreamIn.Position:=MemoryStreamIn.Position-ImageWidth*2;
  end;
end;

procedure bmp2ed8;
var
  MemoryStream1, MemoryStream2: TMemoryStream;
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
    MemoryStream1.Position:=$1C;
    MemoryStream1.ReadBuffer(Word1,2);
    if not (Word1=8) then begin Writeln('Error: Input file is not a valid 8-bit BMP image file'); Readln; exit end;
    MemoryStream1.ReadBuffer(LongWord1,4);
    if not (LongWord1=0) then begin Writeln('Error: Compressed BMP images are not supported'); Readln; exit end;
    MemoryStream1.Position:=$12;
    InversedFlag:=False;
    MemoryStream1.ReadBuffer(ImageWidth,4);
    if ImageWidth<0 then begin ImageWidth:=Abs(ImageWidth); InversedFlag:=True end;
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
    LongWord1:=BmpDataSize+8;
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
    LongWord1:=$4F434E55;
    MemoryStream2.WriteBuffer(LongWord1,4);
    LongWord1:=$2E52504D;
    MemoryStream2.WriteBuffer(LongWord1,4);

    MemoryStream1.Position:=BmpDataStart;
    if InversedFlag=False then Inverse8bitBitmap (MemoryStream1, MemoryStream2, ImageWidth, ImageHeight, BmpDataSize) else MemoryStream2.CopyFrom(MemoryStream1, BmpDataSize);
    i:=Pos('.',ParamStr(1)); if i>0 then MemoryStream2.SaveToFile(Copy(ParamStr(1),1,Length(ParamStr(1))-(Length(ParamStr(1))-i+1))+'_UNCOMPR.ED8') else MemoryStream2.SaveToFile(ParamStr(1)+'_UNCOMPR.ED8');
  finally MemoryStream1.Free; MemoryStream2.Free end;
end;

procedure ed82bmp;
const
  ZeroByte: Byte=0;
  ZeroLongWord: LongWord=0;
var
  MemoryStream1, MemoryStream2: TMemoryStream;
  LongWord1, BmpDataSize: LongWord;
  Word1, ImageWidth, ImageHeight, NumOfColors: Word;
  Byte1: Byte;
  i: Integer;
begin
  MemoryStream1:=TMemoryStream.Create; MemoryStream2:=TMemoryStream.Create;
  try
    MemoryStream1.LoadFromFile(ParamStr(1));
    MemoryStream1.Position:=$E;
    MemoryStream1.ReadBuffer(ImageWidth,2);
    MemoryStream1.ReadBuffer(ImageHeight,2);
    MemoryStream1.ReadBuffer(NumOfColors,2);
    BmpDataSize:=ImageWidth*ImageHeight;
    MemoryStream1.Position:=$16;
    MemoryStream1.ReadBuffer(LongWord1,4);
    if not (ImageWidth*ImageHeight+8=LongWord1) then begin Writeln('Error: Input file is not an uncompressed ED8 image file'); Readln; exit end;

    Word1:=$4D42;
    MemoryStream2.WriteBuffer(Word1,2);
    LongWord1:=NumOfColors*4+BmpDataSize+$36;
    MemoryStream2.WriteBuffer(LongWord1,4);
    MemoryStream2.WriteBuffer(ZeroLongWord,4);
    LongWord1:=NumOfColors*4+$36;
    MemoryStream2.WriteBuffer(LongWord1,4);
    LongWord1:=$28; //DIB header start
    MemoryStream2.WriteBuffer(LongWord1,4);
    LongWord1:=ImageWidth;
    MemoryStream2.WriteBuffer(LongWord1,4);
    LongWord1:=ImageHeight;
    MemoryStream2.WriteBuffer(LongWord1,4);
    LongWord1:=$80001;
    MemoryStream2.WriteBuffer(LongWord1,4);
    MemoryStream2.WriteBuffer(ZeroLongWord,4);
    MemoryStream2.WriteBuffer(BmpDataSize,4);
    MemoryStream2.WriteBuffer(ZeroLongWord,4);
    MemoryStream2.WriteBuffer(ZeroLongWord,4);
    if NumOfColors=256 then LongWord1:=0 else LongWord1:=NumOfColors;
    MemoryStream2.WriteBuffer(LongWord1,4);
    MemoryStream2.WriteBuffer(ZeroLongWord,4); //DIB header end

    for i:=1 to NumOfColors do
    begin
      MemoryStream1.ReadBuffer(Byte1,1);
      MemoryStream2.WriteBuffer(Byte1,1);
      MemoryStream1.ReadBuffer(Byte1,1);
      MemoryStream2.WriteBuffer(Byte1,1);
      MemoryStream1.ReadBuffer(Byte1,1);
      MemoryStream2.WriteBuffer(Byte1,1);
      MemoryStream2.WriteBuffer(ZeroByte,1);
    end;
    MemoryStream1.Position:=MemoryStream1.Position+8;
    Inverse8bitBitmap (MemoryStream1, MemoryStream2, ImageWidth, ImageHeight, BmpDataSize);

    if Copy(ParamStr(1),Pos('_UNCOMPR.ED8',UpperCase(ParamStr(1))))='_UNCOMPR.ED8' then MemoryStream2.SaveToFile(Copy(ParamStr(1),1,Length(ParamStr(1))-12)+'.bmp') else
    begin
      i:=Pos('.',ParamStr(1));
      if i>0 then MemoryStream2.SaveToFile(Copy(ParamStr(1),1,Length(ParamStr(1))-(Length(ParamStr(1))-i+1))+'.bmp') else MemoryStream2.SaveToFile(ParamStr(1)+'.bmp');
    end;
  finally MemoryStream1.Free; MemoryStream2.Free end;
end;

var
  FileStream1: TFileStream;
  Int641: Int64;
begin
  try
    Writeln('Uncompressed ED8 Image Converter v1.0 by RikuKH3');
    Writeln('------------------------------------------------');
    if ParamCount<1 then begin Writeln('Usage: ed8unc.exe <Input 8-bit BMP or uncompressed ED8>'); Readln; exit end;
    FileStream1:=TFileStream.Create(ParamStr(1), fmOpenRead or fmShareDenyWrite);
    try
      FileStream1.ReadBuffer(Int641,8);
    finally FileStream1.Free end;
    if Int641=$8C5D8D746942382E then ed82bmp else bmp2ed8;
  except on E: Exception do begin Writeln('Error: '+E.Message); Readln; exit end end;
end.
