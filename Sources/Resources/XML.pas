unit XML;

interface

uses Classes;

type
  TXML = class(TObject)
  private
    FXMLFile: TStringList;
    FFileName: AnsiString;
    function ReplaceAnsiString(Str, S1, S2: AnsiString): AnsiString;
  public
    constructor Create(const FileName: AnsiString);
    destructor Destroy; override;
    function Read(const Node, DefaultData: AnsiString): AnsiString;
    procedure Write(const Node, Data: AnsiString);
  end;

implementation

uses SysUtils;

{ TXML }

constructor TXML.Create(const FileName: AnsiString);
var
  XMLFile: TextFile;
begin
  FXMLFile := TStringList.Create;
  if not FileExists(FileName) then
  try
    AssignFile(XMLFile, FileName); 
    Rewrite(XMLFile);
    WriteLn(XMLFile, '<?xml ?>');
    WriteLn(XMLFile, '<root>');
    WriteLn(XMLFile, '</root>');
  finally
    CloseFile(XMLFile);
  end;
  FXMLFile.LoadFromFile(FileName);    
  FFileName := FileName;
end;

destructor TXML.Destroy;
begin
  FreeAndNil(FXMLFile);
  inherited;
end;

function TXML.ReplaceAnsiString(Str, S1, S2: AnsiString): AnsiString;
var
  I: Integer;
  S, T: AnsiString;
begin
  S := '';
  T := Str;
  repeat
    I := Pos(LowerCase(S1), LowerCase(T));
    if (I > 0) then
    begin
      S := S + Copy(T, 1, I - 1) + S2;
      T := Copy(T, I + Length(S1), MaxInt);
    end else S := S + T;
  until (I <= 0);
  Result := S;
end;

function TXML.Read(const Node, DefaultData: AnsiString): AnsiString;
var
  I: Integer;
begin
  I := Pos(LowerCase('<' + Node + '>'), LowerCase(FXMLFile.Text)) + Length('<' + Node + '>');
  Result := Trim(Copy(FXMLFile.Text, I, Pos(LowerCase('</' + Node + '>'), LowerCase(FXMLFile.Text)) - I));
  if (Result = '') then Result := DefaultData;
end;

procedure TXML.Write(const Node, Data: AnsiString);
var
  FData: AnsiString;
begin
  FData := Trim(Self.Read(Node, ''));
  if (FData <> '') then
    FXMLFile.Text := Self.ReplaceAnsiString(FXMLFile.Text,
    LowerCase('<' + Node + '>') + FData + LowerCase('</' + Node + '>'),
    LowerCase('<' + Node + '>') + Data + LowerCase('</' + Node + '>'))
  else begin    
    FData := Trim(FXMLFile.Text);
    Insert(#9 + LowerCase('<' + Node + '>') + Data + LowerCase('</' + Node + '>') + #13#10,
      FData, Length(FXMLFile.Text) - 8);
    FXMLFile.Text := FData;
  end;
  FXMLFile.SaveToFile(FFileName);
end;

end.
