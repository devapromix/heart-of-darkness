unit uDatFile;

interface

uses
  gm_engine;

type
  TDatAnsiStrings = array of AnsiString;

type
  TDatParam = class
    Name: AnsiString;
    Value: AnsiString;
    IsZero: Boolean;
    constructor Create;
    destructor Destroy; override;
    function Str(const DefValue: AnsiString): AnsiString;
    function Int(const DefValue: Integer): Integer;
    function Float(const DefValue: Single): Single;
    function Bool(const DefValue: Boolean): Boolean;
  end;

type
  TDatBlock = class
    Name: AnsiString;
    TextBlock: Boolean;
    AnsiStrings: array of AnsiString;
    AnsiStringsCnt: Integer;
    Blocks: array of TDatBlock;
    BlocksCnt: Integer;
    Params: array of TDatParam;
    ParamsCnt: Integer;
    ZeroParam: TDatParam;
    constructor Create;
    destructor Destroy; override;
    procedure AddAnsiString(Str: AnsiString);
    procedure DeleteAnsiString(StrN: Integer);
    function AddBlock(BlockName: AnsiString): TDatBlock;
    function Block(BlockName: AnsiString): TDatBlock;
    function Param(ParamName: AnsiString): TDatParam;
    procedure SetParam(ParamName, ParamValue: AnsiString);
    function StrGetValid(Str: AnsiString): AnsiString;
    procedure ParseAnsiStrings(Strs: TDatAnsiStrings; ParseLen: Integer;
      var ParsePos: Integer);
    procedure GetAllAnsiStrings(var Str: TDatAnsiStrings; var Cnt: Integer);
  end;

type
  TDat = class(TDatBlock)
    procedure LoadFromFile(FileName: AnsiString);
    procedure SaveToFile(FileName: AnsiString);
    function GetAnsiString: AnsiString;
  end;

implementation

constructor TDatParam.Create;
begin
  Name := '';
  Value := '';
  IsZero := False;
end;

destructor TDatParam.Destroy;
begin
  Name := '';
  Value := '';
  inherited;
end;

// ==============================================================================
function TDatParam.Str(const DefValue: AnsiString): AnsiString;
begin
  if IsZero = True then
  begin
    Result := DefValue;
    Exit;
  end;
  Result := Value;
end;

// ==============================================================================
function TDatParam.Int(const DefValue: Integer): Integer;
var
  e: Integer;
begin
  Val(Value, Result, e);
  if e <> 0 then
    Result := DefValue;
end;

// ==============================================================================
function TDatParam.Float(const DefValue: Single): Single;
var
  e: Integer;
begin
  Val(Value, Result, e);
  if e <> 0 then
    Result := DefValue;
end;

// ==============================================================================
function TDatParam.Bool(const DefValue: Boolean): Boolean;
begin
  if IsZero = True then
  begin
    Result := DefValue;
    Exit;
  end;
  if Value = '' then
  begin
    Result := True;
    Exit;
  end;
  Result := StrToBool(Value);
end;

constructor TDatBlock.Create;
begin
  Name := '';
  TextBlock := False;
  AnsiStringsCnt := 0;
  BlocksCnt := 0;
  ParamsCnt := 0;
  ZeroParam := TDatParam.Create;
  ZeroParam.IsZero := True;
end;

// ==============================================================================
destructor TDatBlock.Destroy;
var
  i: Integer;
begin
  Name := '';
  for i := 0 to AnsiStringsCnt - 1 do
    AnsiStrings[i] := '';
  SetLength(AnsiStrings, 0);
  for i := 0 to BlocksCnt - 1 do
    Blocks[i].Free;
  SetLength(Blocks, 0);
  for i := 0 to ParamsCnt - 1 do
    Params[i].Free;
  SetLength(Params, 0);
  ZeroParam.Free;
  inherited;
end;

// ==============================================================================
procedure TDatBlock.AddAnsiString(Str: AnsiString);
begin
  Inc(AnsiStringsCnt);
  SetLength(AnsiStrings, AnsiStringsCnt);
  AnsiStrings[AnsiStringsCnt - 1] := Str;
end;

// ==============================================================================
procedure TDatBlock.DeleteAnsiString(StrN: Integer);
var
  i: Integer;
begin
  for i := StrN to AnsiStringsCnt - 2 do
    AnsiStrings[i] := AnsiStrings[i + 1];
  Dec(AnsiStringsCnt);
  SetLength(AnsiStrings, AnsiStringsCnt);
end;

// ==============================================================================
function TDatBlock.AddBlock(BlockName: AnsiString): TDatBlock;
begin
  Inc(BlocksCnt);
  SetLength(Blocks, BlocksCnt);
  Blocks[BlocksCnt - 1] := TDatBlock.Create;
  Blocks[BlocksCnt - 1].Name := BlockName;
  Result := Blocks[BlocksCnt - 1];
end;

// ==============================================================================
function TDatBlock.Block(BlockName: AnsiString): TDatBlock;
var
  i: Integer;
begin
  Result := nil;
  BlockName := UpperCase(BlockName);

  for i := 0 to BlocksCnt - 1 do
    if UpperCase(Blocks[i].Name) = BlockName then
    begin
      Result := Blocks[i];
      Exit;
    end;
end;

// ==============================================================================
function TDatBlock.Param(ParamName: AnsiString): TDatParam;
var
  i: Integer;
begin
  Result := ZeroParam;
  ParamName := UpperCase(ParamName);

  for i := 0 to ParamsCnt - 1 do
    if UpperCase(Params[i].Name) = ParamName then
    begin
      Result := Params[i];
      Exit;
    end;
end;

// ==============================================================================
procedure TDatBlock.SetParam(ParamName, ParamValue: AnsiString);
var
  i: Integer;
  PName: AnsiString;
begin
  PName := UpperCase(ParamName);

  for i := 0 to ParamsCnt - 1 do
    if UpperCase(Params[i].Name) = PName then
    begin
      Params[i].Value := ParamValue;
      Exit;
    end;

  Inc(ParamsCnt);
  SetLength(Params, ParamsCnt);
  Params[ParamsCnt - 1] := TDatParam.Create;
  Params[ParamsCnt - 1].Name := ParamName;
  Params[ParamsCnt - 1].Value := ParamValue;
end;

// ==============================================================================
function TDatBlock.StrGetValid(Str: AnsiString): AnsiString;
var
  len, i: Integer;
  IsAnsiString: Boolean;
  IsValid: Boolean;
begin
  Result := '';
  len := Length(Str);
  if len = 0 then
    Exit;

  IsAnsiString := False;

  for i := 1 to len do
  begin
    if Str[i] = '"' then
      IsAnsiString := not(IsAnsiString);

    if (IsAnsiString = False) and (Str[i] = '/') and (i < len) then
      if Str[i + 1] = '/' then
        Break;

    IsValid := True;
    if (Str[i] = ' ') and (IsAnsiString = False) then
      IsValid := False;
    if Str[i] = '"' then
      IsValid := False;
    if Ord(Str[i]) = 9 then
      IsValid := False;

    if IsValid = True then
      Result := Result + Str[i];
  end;
end;

// ==============================================================================
procedure TDatBlock.ParseAnsiStrings(Strs: TDatAnsiStrings; ParseLen: Integer;
  var ParsePos: Integer);
var
  j: Integer;
  Str: AnsiString;
  len: Integer;
  BlockName: AnsiString;
  Blck: TDatBlock;
  ParamName: AnsiString;
  ParamValue: AnsiString;
  IsParam: Boolean;
begin
  while ParsePos > 0 do
  begin
    Str := StrGetValid(Strs[ParseLen - ParsePos]);
    if Str = '</' + Name + '>' then
    begin
      ParsePos := ParsePos - 1;
      Exit;
    end;
    len := Length(Str);

    if TextBlock then
    begin
      while Str <> '[/' + Name + ']' do
      begin
        AddAnsiString(Strs[ParseLen - ParsePos]);
        ParsePos := ParsePos - 1;
        if ParsePos = 0 then
          Exit;
        Str := Strs[ParseLen - ParsePos];
        if Str <> '' then
        begin
          len := Length(Str);
          for j := 1 to len do
          begin
            if Str[j] = '[' then
            begin
              Str := StrGetValid(Strs[ParseLen - ParsePos]);
              Break;
            end;
            if not((Str[j] = ' ') or (Ord(Str[j]) = 9)) then
              Break;
          end;
        end;
      end;
      ParsePos := ParsePos - 1;
      Exit;
    end;

    if len > 0 then
    begin
      if ((Str[1] = '<') and (Str[len] = '>')) or
        ((Str[1] = '[') and (Str[len] = ']')) then
      begin
        BlockName := '';
        for j := 2 to len - 1 do
          BlockName := BlockName + Str[j];

        Blck := AddBlock(BlockName);
        if Str[1] = '[' then
          Blck.TextBlock := True;

        ParsePos := ParsePos - 1;
        if ParsePos = 0 then
          Exit;
        Blck.ParseAnsiStrings(Strs, ParseLen, ParsePos);

        Continue;
      end;

      ParamName := '';
      ParamValue := '';
      IsParam := False;
      for j := 1 to len do
      begin
        if (Str[j] = '=') and (IsParam = False) then
        begin
          IsParam := True;
          Continue;
        end;

        if IsParam = False then
          ParamName := ParamName + Str[j]
        else
          ParamValue := ParamValue + Str[j];
      end;

      Inc(ParamsCnt);
      SetLength(Params, ParamsCnt);
      Params[ParamsCnt - 1] := TDatParam.Create;
      Params[ParamsCnt - 1].Name := ParamName;
      Params[ParamsCnt - 1].Value := ParamValue;
    end;

    ParsePos := ParsePos - 1;
  end;
end;

// ==============================================================================
procedure TDatBlock.GetAllAnsiStrings(var Str: TDatAnsiStrings;
  var Cnt: Integer);
var
  i: Integer;
begin
  if Name <> '' then
  begin
    Inc(Cnt);
    SetLength(Str, Cnt);
    if TextBlock = False then
      Str[Cnt - 1] := '<' + Name + '>'
    else
      Str[Cnt - 1] := '[' + Name + ']';
  end;
  for i := 0 to AnsiStringsCnt - 1 do
  begin
    Inc(Cnt);
    SetLength(Str, Cnt);
    Str[Cnt - 1] := AnsiStrings[i];
  end;
  for i := 0 to BlocksCnt - 1 do
    Blocks[i].GetAllAnsiStrings(Str, Cnt);
  if Name <> '' then
  begin
    Inc(Cnt);
    SetLength(Str, Cnt);
    if TextBlock = False then
      Str[Cnt - 1] := '</' + Name + '>'
    else
      Str[Cnt - 1] := '[/' + Name + ']';
  end;
end;

// ==============================================================================
// ======== TDat ================================================================
// ==============================================================================
procedure TDat.LoadFromFile(FileName: AnsiString);
var
  f: TFile;
  sz: LongWord;
  sCnt, sLen: Integer;
  n, k: Integer;
  Str, str2: AnsiString;
  Strs: TDatAnsiStrings;
begin
  FileOpen(f, FileName, FOM_OPENR);
  sz := FileGetSize(f);
  SetLength(Str, sz);
  FileRead(f, Str[1], sz);
  FileClose(f);
  n := Pos('﻿', Str);
  if n = 1 then
    Delete(Str, 1, 3);
  k := 1;
  if Pos(#13, Str) > 0 then
    k := 2;

  str2 := '';
  sCnt := 0;
  sLen := 32;
  SetLength(Strs, sLen);
  repeat
    n := Pos(#10, Str);
    if n > 0 then
    begin
      Strs[sCnt] := Copy(Str, 1, n - k);
      Delete(Str, 1, n);
    end
    else
    begin
      Strs[sCnt] := Str;
      Break;
    end;

    Inc(sCnt);
    if sCnt = sLen then
    begin
      sLen := sLen + 32;
      SetLength(Strs, sLen);
    end;
  until False;
  Inc(sCnt);
  SetLength(Strs, sCnt);

  ParseAnsiStrings(Strs, sCnt, sCnt);
end;

// ==============================================================================
procedure TDat.SaveToFile(FileName: AnsiString);
var
  f: TFile;
  i: Integer;
  Strs: TDatAnsiStrings;
  sCnt: Integer;
  Str: AnsiString;
begin
  sCnt := 0;
  GetAllAnsiStrings(Strs, sCnt);
  Str := '';
  for i := 0 to sCnt - 1 do
  begin
    Str := Str + Strs[i];
    if i < sCnt - 1 then
      Str := Str + #13#10;
  end;

  FileOpen(f, FileName, FOM_CREATE);
  FileWrite(f, Str[1], Length(Str));
  FileClose(f);
end;

// ==============================================================================
function TDat.GetAnsiString: AnsiString;
var
  i: Integer;
  Str: TDatAnsiStrings;
  sCnt: Integer;
begin
  Result := '';
  sCnt := 0;
  GetAllAnsiStrings(Str, sCnt);

  for i := 0 to sCnt - 1 do
  begin
    Result := Result + Str[i];
    Result := Result + #13;
    Result := Result + #10;
  end;
end;

end.
