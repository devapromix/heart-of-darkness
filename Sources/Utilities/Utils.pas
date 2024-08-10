unit Utils;

interface

type
  TExplodeResult = array of AnsiString;

procedure Box(); overload;
procedure Box(const BoxStrMessage: AnsiString); overload;
procedure Box(const BoxIntMessage: Integer); overload;
procedure Box(const Value: Single); overload;
procedure Box(const BoxBoolMessage: Boolean); overload;
procedure Box(const BoxStrMessage, Title: AnsiString); overload;
procedure Box(const BoxStrMessage: AnsiString; I: Integer); overload;
function RemoveBack(C: ansiChar; S: AnsiString): AnsiString;
function BarWidth(CX, MX, WX: Integer): Integer;
function LastPos(const SubStr, Source: AnsiString;
  const IgnoreCase: Boolean = True): Integer;
function Percent(N, P: Integer): Integer;
function RandStr(const Separator: ansiChar; S: AnsiString): AnsiString;
function GetStr(const Separator: ansiChar; S: AnsiString; I: Integer)
  : AnsiString;
function FirstStr(const Separator: ansiChar; S: AnsiString): AnsiString;
function ClampCycle(Value, AMin, AMax: Integer): Integer;
function Clamp(Value, AMin, AMax: Integer): Integer;
function Explode(const Separator: ansiChar; Source: AnsiString)
  : TExplodeResult; overload;
function Explode(const Count: Integer; Source: AnsiString)
  : TExplodeResult; overload;
function GetPath: AnsiString;

implementation

uses Windows, Math, SysUtils;

function RemoveBack(C: ansiChar; S: AnsiString): AnsiString;
begin
  Result := S;
  if (Result[System.Length(Result)] = C) then
    Delete(Result, System.Length(Result), 1);
end;

function BarWidth(CX, MX, WX: Integer): Integer;
begin
  Result := Round(CX / MX * WX);
end;

function RandStr(const Separator: ansiChar; S: AnsiString): AnsiString;
var
  E: TExplodeResult;
begin
  E := nil;
  S := RemoveBack(Separator, S);
  E := Explode(Separator, S);
  Result := Trim(E[Math.RandomRange(0, Length(E))]);
end;

function GetStr(const Separator: ansiChar; S: AnsiString; I: Integer)
  : AnsiString;
var
  E: TExplodeResult;
begin
  E := nil;
  S := RemoveBack(Separator, S);
  E := Explode(Separator, S);
  Result := Trim(E[I]);
end;

function FirstStr(const Separator: ansiChar; S: AnsiString): AnsiString;
begin
  Result := '';
  S := Trim(S);
  if (S = '') then
    Exit;
  if (Pos(Separator, S) > 0) then
    Result := Trim(Copy(S, 1, Pos(Separator, S) - 1))
  else
    Result := S;
end;

procedure Box(); overload;
begin
  MessageBox(0, '', 'Info', MB_OK);
end;

procedure Box(const BoxStrMessage: AnsiString); overload;
begin
  MessageBox(0, PwideChar(BoxStrMessage), 'Info', MB_OK);
end;

procedure Box(const BoxIntMessage: Integer); overload;
begin
  MessageBox(0, PChar(IntToStr(BoxIntMessage)), 'Info', MB_OK);
end;

procedure Box(const Value: Single); overload;
begin
  MessageBox(0, PwideChar(FloatToStr(Value)), 'Info', MB_OK);
end;

procedure Box(const BoxBoolMessage: Boolean); overload;
begin
  MessageBox(0, PwideChar(BoolToStr(BoxBoolMessage)), 'Info', MB_OK);
end;

procedure Box(const BoxStrMessage, Title: AnsiString);
begin
  MessageBox(0, PwideChar(BoxStrMessage), PwideChar(Title), MB_OK);
end;

procedure Box(const BoxStrMessage: AnsiString; I: Integer);
begin
  MessageBox(0, PwideChar(BoxStrMessage), PwideChar(IntToStr(I)), MB_OK);
end;

function Clamp(Value, AMin, AMax: Integer): Integer;
begin
  Result := Value;
  if (Result < AMin) then
    Result := AMin;
  if (Result > AMax) then
    Result := AMax;
end;

function ClampCycle(Value, AMin, AMax: Integer): Integer;
begin
  Result := Value;
  if (Result < AMin) then
    Result := AMax;
  if (Result > AMax) then
    Result := AMin;
end;

function Percent(N, P: Integer): Integer;
begin
  Result := MulDiv(N, P, 100);
end;

function LastPos(const SubStr, Source: AnsiString;
  const IgnoreCase: Boolean): Integer;
var
  Found, Len, Pos: Integer;
begin
  Pos := System.Length(Source);
  Len := System.Length(SubStr);
  Found := 0;
  while (Pos > 0) and (Found = 0) do
  begin
    if IgnoreCase then
    begin
      if (LowerCase(Copy(Source, Pos, Len)) = LowerCase(SubStr)) then
        Found := Pos;
      Dec(Pos);
    end
    else
    begin
      if (Copy(Source, Pos, Len) = SubStr) then
        Found := Pos;
      Dec(Pos);
    end;
  end;
  Result := Found;
end;

function Explode(const Count: Integer; Source: AnsiString): TExplodeResult;
var
  S, P: AnsiString;
  A: Integer;
begin
  S := Source;
  SetLength(Result, 0);
  while (System.Length(S) > Count) do
  begin
    SetLength(Result, System.Length(Result) + 1);
    P := Copy(S, 1, Count);
    A := LastPos(#32, P);
    P := Copy(S, 1, A);
    Result[High(Result)] := P;
    Delete(S, 1, A);
  end;
  SetLength(Result, System.Length(Result) + 1);
  Result[High(Result)] := S;
end;

function Explode(const Separator: ansiChar; Source: AnsiString): TExplodeResult;
var
  I: Integer;
  S: AnsiString;
begin
  Result := nil;
  S := Source;
  SetLength(Result, 0);
  I := 0;
  while Pos(Separator, S) > 0 do
  begin
    SetLength(Result, System.Length(Result) + 1);
    Result[I] := Copy(S, 1, Pos(Separator, S) - 1);
    Inc(I);
    S := Copy(S, Pos(Separator, S) + System.Length(Separator),
      System.Length(S));
  end;
  SetLength(Result, System.Length(Result) + 1);
  Result[I] := Copy(S, 1, System.Length(S));
end;

function GetPath: AnsiString;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

end.
