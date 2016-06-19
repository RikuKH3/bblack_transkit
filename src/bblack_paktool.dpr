program bblack_paktool;

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Windows, System.SysUtils, System.Classes, IOUtils, System.Types;

{$SETPEFLAGS IMAGE_FILE_RELOCS_STRIPPED}

procedure unpack;
var
  FileStream1, FileStream2: TFileStream;
  MemoryStream1: TMemoryStream;
  Word1: Word;
  Byte1: Byte;
  i,x: Integer;
  DataStartPos: array of LongWord;
  DataNameList: array of String;
  DataEndPos: LongWord;
  OutDir: String;
begin
  try
    FileStream1:=TFileStream.Create(ParamStr(1), fmOpenRead or fmShareDenyWrite);
    try
      FileStream1.ReadBuffer(Word1,2);
      Word1:=Word1-1;
      SetLength(DataStartPos,Word1);
      SetLength(DataNameList,Word1);
      MemoryStream1:=TMemoryStream.Create;
      try
        MemoryStream1.CopyFrom(FileStream1,Word1*16);
        MemoryStream1.Position:=0;
        for i:=0 to Word1-1 do
        begin
          for x:=1 to 8 do begin MemoryStream1.ReadBuffer(Byte1,1); DataNameList[i]:=DataNameList[i]+Char(Byte1); end;
          DataNameList[i]:=TrimRight(DataNameList[i])+'.';
          for x:=1 to 3 do begin MemoryStream1.ReadBuffer(Byte1,1); DataNameList[i]:=DataNameList[i]+Char(Byte1); end;
          DataNameList[i]:=TrimRight(DataNameList[i]);
          MemoryStream1.Position:=MemoryStream1.Position+1;
          MemoryStream1.ReadBuffer(DataStartPos[i],4);
        end;
      finally MemoryStream1.Free; end;

      if Length(DataStartPos)=1 then OutDir:='' else OutDir:='s';
      Writeln('Extracting '+IntToStr(Length(DataStartPos))+' file'+OutDir+' from '+#39+ExtractFileName(ParamStr(1)+#39+'...'));

      OutDir:=ExpandFileName(ParamStr(1));
      OutDir:=Copy(OutDir,1,Length(OutDir)-Length(ExtractFileExt(OutDir)))+'\';
      x:=Length(DataStartPos)-1;
      if not (DirectoryExists(OutDir)) then CreateDir(OutDir);
      for i:=0 to x do
      begin
        if i<x then DataEndPos:=DataStartPos[i+1] else DataEndPos:=FileStream1.Size;
        FileStream2:=TFileStream.Create(OutDir+DataNameList[i], fmCreate or fmOpenWrite or fmShareDenyWrite);
        try
          FileStream1.Position:=DataStartPos[i];
          FileStream2.CopyFrom(FileStream1,DataEndPos-DataStartPos[i])
        finally FileStream2.Free end;
        Writeln('['+StringOfChar('0',Length(IntToStr(x+1))-Length(IntToStr(i+1)))+IntToStr(i+1)+'/'+IntToStr(x+1)+'] '+DataNameList[i]);
      end;
      Writeln('');
    finally FileStream1.Free end;
  except on E: Exception do begin Writeln(E.Message); Readln end end;
end;

procedure pack;
const
  ZeroByte: Byte=0;
var
  InputFiles: TStringDynArray;
  FileStream1, FileStream2: TFileStream;
  MemoryStream1: TMemoryStream;
  i: Integer;
  Word1: Word;
  LongWord1: LongWord;
  s: AnsiString;
begin
  try
    InputFiles:=TDirectory.GetFiles(ParamStr(1), '*.*', TSearchOption.soTopDirectoryOnly);
    if Length(InputFiles)=0 then begin Writeln('No input files found in selected directory. Nothing to pack.'); Readln; exit end;
    if Length(InputFiles)=1 then s:='' else s:='s';
    Writeln('Packing '+IntToStr(Length(InputFiles))+' file'+String(s)+' into '+#39+ExtractFileName(ParamStr(1)+'.PAK'+#39+'...'));

    FileStream1:=TFileStream.Create(ExpandFileName(ParamStr(1))+'.PAK', fmCreate or fmOpenWrite or fmShareDenyWrite); MemoryStream1:=TMemoryStream.Create;
    try
      FileStream1.Size:=Length(InputFiles)*16+18;
      Word1:=Length(InputFiles)+1;
      MemoryStream1.WriteBuffer(Word1,2);
      for i:=0 to Length(InputFiles)-1 do begin
        FileStream2:=TFileStream.Create(InputFiles[i], fmOpenRead or fmShareDenyWrite);
        try
          s:=AnsiString(UpperCase(ExtractFileName(InputFiles[i])));
          s:=AnsiString(StringReplace( Copy(String(s),1,Length(s)-Length(ExtractFileExt(String(s)))) ,'.','',[rfReplaceAll]));
          if Length(s)>8 then s:=Copy(s,1,6)+'~1';
          s:=s+AnsiString(StringOfChar(' ',8-Length(s)));
          MemoryStream1.WriteBuffer(s[1],8);
          s:=AnsiString(UpperCase(Copy(ExtractFileExt(InputFiles[i]),2)));
          if Length(s)>3 then SetLength(s,3);
          s:=s+AnsiString(StringOfChar(' ',3-Length(s)));
          MemoryStream1.WriteBuffer(s[1],3);
          MemoryStream1.WriteBuffer(ZeroByte,1);
          LongWord1:=FileStream1.Size;
          MemoryStream1.WriteBuffer(LongWord1,4);
          FileStream1.CopyFrom(FileStream2,FileStream2.Size);
        finally FileStream2.Free end;
        Writeln('['+StringOfChar('0',Length(IntToStr(Length(InputFiles)))-Length(IntToStr(i+1)))+IntToStr(i+1)+'/'+IntToStr(Length(InputFiles))+'] '+ExtractFileName(InputFiles[i]));
      end;
      s:='..END      ';
      MemoryStream1.WriteBuffer(s[1],11);
      MemoryStream1.WriteBuffer(ZeroByte,1);
      LongWord1:=FileStream1.Size;
      MemoryStream1.WriteBuffer(LongWord1,4);
      MemoryStream1.Position:=0;
      FileStream1.Position:=0;
      FileStream1.CopyFrom(MemoryStream1,MemoryStream1.Size);
    finally FileStream1.Free; MemoryStream1.Free end;
    Writeln('');
  except on E: Exception do begin Writeln(E.Message); Readln end end;
end;

var
  s: String;
begin
  try
    Writeln('Bible Black PAK Tool v1.0 by RikuKH3');
    Writeln('------------------------------------');
    if ParamCount<1 then begin Writeln('Please specify input PAK file for extraction or input directory for packing'); Readln; exit end;
    s:=UpperCase(ExtractFileExt(ParamStr(1)));
    if s='.PAK' then unpack else
      if s='' then pack else
        begin Writeln('Unknown input file extension'); Readln; exit end;
  except on E: Exception do begin Writeln(E.Message); Readln end end;
end.
