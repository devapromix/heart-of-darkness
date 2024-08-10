unit TimeVars;

interface

uses
  Classes;

type
  TTimeVars = class(TObject)
  private
    FList: TStringList;
    function GetText: AnsiString;
    procedure SetText(const AValue: AnsiString);
  public
    constructor Create;
    destructor Destroy; override;
    function Count: Integer;
    function Name(I: Integer): AnsiString;
    function Value(I: Integer): Integer; overload;
    function Value(I: AnsiString): Integer; overload;
    function IsMove: Boolean;
    function IsVar(I: AnsiString): Boolean;
    property Text: AnsiString read GetText write SetText;
    procedure Add(AName: AnsiString; AValue: Integer);
    procedure Del(AName: AnsiString);
    procedure Clear;
    procedure Move;
  end;

implementation

{ TTimeVars }

uses SysUtils;

const
  LS = '%s=%d';

procedure TTimeVars.Clear;
begin
  FList.Clear;
end;

function TTimeVars.Count: Integer;
begin
  Result := FList.Count;
end;

constructor TTimeVars.Create;
begin
  FList := TStringList.Create;
end;

destructor TTimeVars.Destroy;
begin
  FList.Free;
  inherited;
end;

function TTimeVars.IsMove: Boolean;
begin
  Result := (FList.Count > 0);
end;

function TTimeVars.Name(I: Integer): AnsiString;
begin
  Result := FList.Names[I];
end;

procedure TTimeVars.Move;
var
  I, V: Integer;
begin
  if IsMove then
    with FList do
      for I := Count - 1 downto 0 do
      begin
        V := Value(I);
        System.Dec(V);
        if (V > 0) then
          FList[I] := Format(LS, [Name(I), V])
            else Delete(I);
      end;
end;

function TTimeVars.Value(I: Integer): Integer;
begin
  Result := StrToIntDef(FList.ValueFromIndex[I], 0);
end;

function TTimeVars.Value(I: AnsiString): Integer;
begin
  Result := StrToIntDef(FList.Values[I], 0);
end;

function TTimeVars.IsVar(I: AnsiString): Boolean;
begin
  Result := (Value(I) > 0);
end;

procedure TTimeVars.Add(AName: AnsiString; AValue: Integer);
var
  I, V: Integer;
begin
  if (Trim(AName) = '') or (AValue <= 0)
    or (AValue > 1000) then Exit;
  if IsMove then
    with FList do
      for I := 0 to Count - 1 do
      begin
        if (AName = Name(I)) then
        begin
          V := Value(I);
          if (AValue > V) then V := AValue;
          FList[I] := Format(LS, [Name(I), V]);
          Exit;
        end;
      end;
  FList.Append(Format(LS, [AName, AValue]));
end;

procedure TTimeVars.SetText(const AValue: AnsiString);
begin
  FList.Text := string(AValue);
end;

function TTimeVars.GetText: AnsiString;
begin
  Result := AnsiString(FList.Text);
end;

procedure TTimeVars.Del(AName: AnsiString);
var
  I: Integer;
begin
  with FList do  
    for I := 0 to Count - 1 do
      if (AName = Name(I)) then
      begin
        FList.Delete(I);
        Exit;
      end;
end;

end.
