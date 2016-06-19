program bblack_hgotext;

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Windows, System.SysUtils, System.Classes;

{$SETPEFLAGS IMAGE_FILE_RELOCS_STRIPPED}

function HexToInt(HexStr : string) : Int64;
var
  RetVar: Int64;
  i: byte;
begin
  HexStr:=UpperCase(HexStr);
  if HexStr[Length(HexStr)]='H' then Delete(HexStr,Length(HexStr),1);
  RetVar:=0;

  for i:=1 to Length(HexStr) do
  begin
      RetVar:=RetVar shl 4;
      if HexStr[i] in ['0'..'9'] then
         RetVar:=RetVar+(Byte(HexStr[i])-48)
      else
         if HexStr[i] in ['A'..'F'] then
            RetVar:=RetVar+(Byte(HexStr[i])-55)
         else begin
            RetVar:=0;
            break;
         end;
  end;
  Result:=RetVar;
end;

const
  ZeroByte: Byte=0;
var
  MemoryStream1, MemoryStream2: TMemoryStream;
  StringList1, StringList2: TStringList;
  TextString, s, s2: String;
  MsgPtr, MsgSize: array of LongWord;
  MsgStart, MsgEnd: array of Int64;
  PhraseLength, LongWord1: LongWord;
  i,x,y,z, BlockSize: Integer;
  Byte1: Byte;
begin
  try
    Writeln('Bible Black HGO Text Tool v1.0 by RikuKH3');
    Writeln('-----------------------------------------');
    if ParamCount<>2 then begin Writeln('Usage: bblack_hgotext.exe inject_hgo_file input_txt_file'); Readln; exit end;
    if not (FileExists(ParamStr(1))) then begin Writeln('Error: Cannot open file "'+ExpandFileName(ParamStr(1))+'". The system cannot find the file specified'); Readln; exit end;
    if not (FileExists(ParamStr(2))) then begin Writeln('Error: Cannot open file "'+ExpandFileName(ParamStr(2))+'". The system cannot find the file specified'); Readln; exit end;
    if not (FileExists(ExpandFileName(Copy(ParamStr(0),1,Length(ParamStr(0))-Length(ExtractFileExt(ParamStr(0))))+'.tbl'))) then begin Writeln('Error: "'+Copy(ExtractFileName(ParamStr(0)),1,Length(ExtractFileName(ParamStr(0)))-Length(ExtractFileExt(ExtractFileName(ParamStr(0)))))+'.tbl" not found'); Readln; exit end;

    MemoryStream1:=TMemoryStream.Create; MemoryStream2:=TMemoryStream.Create; StringList1:=TStringList.Create; StringList2:=TStringList.Create;
    try
      MemoryStream1.LoadFromFile(ParamStr(1));
      StringList1.LoadFromFile(ParamStr(2));
      if StringList1.Count=0 then begin Writeln('Error: "'+ExtractFileName(ParamStr(2))+'" is empty'); Readln; exit end;

      for i:=0 to StringList1.Count-1 do if LowerCase(Copy(StringList1[i],1,6))='#size=' then begin MemoryStream1.Size:=StrToInt(Copy(StringList1[i],7)); break end else if i=StringList1.Count-1 then begin Writeln('Error: Size value not found'); Readln; exit end;
      TextString:=StringReplace(StringList1.Text,#13#10,'',[rfReplaceAll]);

      StringList1.LoadFromFile(ExpandFileName(Copy(ParamStr(0),1,Length(ParamStr(0))-Length(ExtractFileExt(ParamStr(0))))+'.tbl'));
      StringList2.CaseSensitive:=True;
      for x:=0 to StringList1.Count-1 do StringList2.Add(StringList1.ValueFromIndex[x]);

      SetLength(MsgPtr,0); SetLength(MsgSize,0); SetLength(MsgStart,0); SetLength(MsgEnd,0);
      x:=1;
      repeat
        if Copy(TextString,x,5)='[MSG$' then
        begin
          SetLength(MsgPtr,Length(MsgPtr)+1); SetLength(MsgSize,Length(MsgSize)+1); SetLength(MsgStart,Length(MsgStart)+1); SetLength(MsgEnd,Length(MsgEnd)+1);
          MsgEnd[Length(MsgEnd)-1]:=x;
          i:=x+4; repeat i:=i+1 until TextString[i]=']';
          MsgStart[Length(MsgStart)-1]:=i+1;
          s:=Copy(TextString,x,i-x+1);
          i:=Pos(',',s);
          MsgPtr[Length(MsgPtr)-1]:=HexToInt(Copy(s,6,i-6));
          MsgSize[Length(MsgSize)-1]:=StrToInt(Copy(s,i+1,Length(s)-i-1));
          if MsgSize[Length(MsgSize)-1]=0 then begin Writeln('Error: Original phrase size is set to zero in block [MSG$'+IntToHex(MsgPtr[Length(MsgPtr)-1],6)+',0]'); Readln; exit end;
          x:=x+Length(s);
        end else x:=x+1;
      until x>Length(TextString);
      if Length(MsgPtr)=0 then begin Writeln('Error: No message blocks found in "'+ExtractFileName(ParamStr(2))+'"'); Readln; exit end;

      for x:=0 to Length(MsgPtr)-1 do
      begin
        if x<Length(MsgPtr)-1 then PhraseLength:=MsgEnd[x+1]-MsgStart[x] else PhraseLength:=Length(TextString)-MsgStart[x]+1;
        if PhraseLength=0 then begin Writeln('Error: [MSG$'+IntToHex(MsgPtr[x],6)+','+IntToStr(MsgSize[x])+'] block is empty'); Readln; exit end;
        s:=Copy(TextString,MsgStart[x],PhraseLength);

        MemoryStream2.Clear;
        for y:=1 to Length(s) do
        begin
          i:=1;
          z:=StringList2.IndexOf(s[y]);
          if z=-1 then begin Writeln('Error: Out of table symbol '+#39+s[y]+#39' in block [MSG$'+IntToHex(MsgPtr[x],6)+','+IntToStr(MsgSize[x])+']'); Readln; exit end;
          s2:=StringList1.Names[z];
          repeat
            Byte1:=HexToInt(Copy(s2,i,2));
            MemoryStream2.WriteBuffer(Byte1,1);
            i:=i+2;
          until i>Length(s2);
        end;
        MemoryStream2.Position:=0;

        if MemoryStream2.Size=MsgSize[x] then
        begin
          MemoryStream1.Position:=MsgPtr[x];
          MemoryStream1.CopyFrom(MemoryStream2,MemoryStream2.Size);
        end else
        if MsgSize[x]<4 then
        begin
          if MemoryStream2.Size>MsgSize[x] then begin Writeln('Error: Because original phrase size in block [MSG$'+IntToHex(MsgPtr[x],6)+','+IntToStr(MsgSize[x])+'] is less than 4 bytes this phrase can'+#39+'t be relocated, new phrase should be less or equal '+IntToStr(MsgSize[x])+' (currently '+IntToStr(MemoryStream2.Size)+')'); Readln; exit end;
          MemoryStream1.Position:=MsgPtr[x];
          MemoryStream1.CopyFrom(MemoryStream2,MemoryStream2.Size);
          if MemoryStream2.Size<MsgSize[x] then begin Byte1:=$20; for z:=1 to MsgSize[x]-MemoryStream2.Size do MemoryStream1.WriteBuffer(Byte1,1); end;
        end else
        begin
          Byte1:=$7F;
          MemoryStream1.Position:=MsgPtr[x];
          MemoryStream1.WriteBuffer(Byte1,1);
          LongWord1:=MemoryStream1.Size-MsgPtr[x];
          Byte1:=Lo(LongWord1);
          MemoryStream1.WriteBuffer(Byte1,1);
          Byte1:=Hi(LongWord1);
          MemoryStream1.WriteBuffer(Byte1,1);
          Byte1:=Lo(LongWord1 shr 16);
          MemoryStream1.WriteBuffer(Byte1,1);
          MemoryStream1.Position:=MemoryStream1.Size;
          MemoryStream1.CopyFrom(MemoryStream2,MemoryStream2.Size);
          MemoryStream1.WriteBuffer(ZeroByte,1);
        end;
      end;

    MemoryStream1.SaveToFile(ParamStr(1));
    if Length(MsgPtr)=1 then s:='' else s:='s';  Writeln(IntToStr(Length(MsgPtr))+' phrase'+s+' successfully injected into "'+ExtractFileName(ParamStr(1))+'"'); Writeln('');
    finally MemoryStream1.Free; MemoryStream2.Free; StringList1.Free; StringList2.Free end;
  except on E: Exception do begin Writeln('Error: '+E.Message); Readln; exit end end;
end.
