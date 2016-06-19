program bblack_win10fix;

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

{$APPTYPE CONSOLE}

{$R *.res}

{$R *.dres}

uses
  Windows, System.SysUtils, System.Classes;

{$SETPEFLAGS IMAGE_FILE_RELOCS_STRIPPED}

var
  ResourceStream1: TResourceStream;
  MemoryStream1: TMemoryStream;
  bblackexepath: String;
  ansis: AnsiString;
begin
  try
    Writeln('Bible Black Windows 10 Fixer by RikuKH3');
    Writeln('---------------------------------------');
    bblackexepath:=ExtractFileDir(ParamStr(0));
    if not (FileExists(bblackexepath+'\BBLACK.EXE')) then begin Writeln('Error: BBLACK.EXE not found! Move this program into Bible Black game'+#39+'s directory and launch it again.'); Readln; exit end;
    if Pos(' ', bblackexepath)>0 then begin Writeln('Error: Game'+#39+'s path shouldn'+#39+'t contain any spaces.'); Readln; exit end;

    ansis:=AnsiString(bblackexepath+'\ACTIVEJP.INI');
    MemoryStream1:=TMemoryStream.Create;
    try
      MemoryStream1.WriteBuffer(ansis[1], Length(ansis));
      if MemoryStream1.Size>70 then begin Writeln('Error: Game'+#39+'s path is too long ('+IntToStr(MemoryStream1.Size)+'/70).'); Readln; exit end;
      MemoryStream1.Clear;

      ResourceStream1:=TResourceStream.Create(HInstance, 'RCDATA', RT_RCDATA);
      try
        MemoryStream1.CopyFrom(ResourceStream1, 1386);
        MemoryStream1.WriteBuffer(ansis[1], Length(ansis));
        ResourceStream1.Position:=1400;
        MemoryStream1.CopyFrom(ResourceStream1, 1605);
        MemoryStream1.SaveToFile(bblackexepath+'\A98SYS.ENV');
        MemoryStream1.Clear;
        ResourceStream1.Position:=3005;
        MemoryStream1.CopyFrom(ResourceStream1, 51);
        ansis:=AnsiString(bblackexepath);
        MemoryStream1.WriteBuffer(ansis[1], Length(ansis));
        ResourceStream1.Position:=3065;
        MemoryStream1.CopyFrom(ResourceStream1, 159);
        MemoryStream1.SaveToFile(bblackexepath+'\ACTIVEJP.INI');
        Writeln('Successfully created '+#39+'A98SYS.ENV'+#39+' and '+#39+'ACTIVEJP.INI'+#39+'.');
        Writeln('Game should work now.');
      finally ResourceStream1.Free end;
    finally MemoryStream1.Free end;
  except on E: Exception do begin Writeln('Error: '+E.Message); Readln; exit end end;
end.
