unit Digit;

interface

uses gm_Engine;

type
  TDigitRec = record  
    Active: Boolean;
    X, Y, NX, NY, DX, DY: Integer;
    Color: Integer;
    Delta: Single;
    Value: AnsiString;
    Flag: Boolean;
  end;

var
  Digits: array of TDigitRec;

procedure Add(X, Y: Integer; Value: AnsiString; Color: Integer; F: Boolean = False);
procedure Update();
procedure Render();

implementation

uses Math, Utils, Resources;

procedure Add(X, Y: Integer; Value: AnsiString; Color: Integer; F: Boolean = False);
var
  I: Integer;

  procedure SetDigit(I, X, Y: Integer);
  begin
    Digits[i].Active := True;
    Digits[i].Value := Value;
    Digits[i].Delta := 0;
    Digits[i].Color := Color;
    Digits[i].Flag := F;
    Digits[i].DX := Math.RandomRange(0, 32);
    Digits[i].DY := Math.RandomRange(1, 10);
    Digits[i].X := X;
    Digits[i].Y := Y;
  end;

begin
  if System.Length(Digits) <> 0 then
  for i := 0 to System.Length(Digits)-1 do
    if not Digits[i].Active then
    begin
      SetDigit(I, X, Y);
      Exit;
    end;
  SetLength(Digits, System.Length(Digits) + 1);
  SetDigit(System.Length(Digits) - 1, X, Y);
end;

procedure Update;
const
  A = 0.9;
var
  I: Integer;
begin
  for I := 0 to System.Length(Digits) - 1 do
    if Digits[i].Active then
    begin
      Digits[i].NX := Round(System.Sin(Digits[i].Delta * A) * 2 * 9 + Digits[i].Delta * 0.2) + 32;
      Digits[i].NY := Round(-1.0 * 2 * 32 / 14 * Digits[i].Delta - (32 div 2));
      Digits[i].Delta := Digits[i].Delta + 0.1;
      if (Digits[i].Delta > 9) then Digits[i].Active := False;
    end;
end;

procedure Render;
var
  I: Integer;
  A: Byte;
begin
  for I := 0 to System.Length(Digits) - 1 do
  begin
    if (Digits[I].Delta = 0) then Exit;
    if Digits[I].Active then
    begin
      A := 255 - Round(Digits[I].Delta * 25);
      if Digits[I].Flag then
        TextOut(Font[ttFont1], ((Digits[i].X - 1) * 32) - Cam.X + Digits[i].NX + Digits[I].DX,
          (Digits[i].Y * 32) - Cam.Y + Digits[i].NY + Digits[I].DY, 1, 0,
            Digits[I].Value, A, Digits[I].Color) else
              TextOut(Font[ttFont2], ((Digits[i].X - 1) * 32) - Cam.X + Digits[i].NX + Digits[I].DX,
                (Digits[i].Y * 32) - Cam.Y + Digits[i].NY + Digits[I].DY, 1, 0,
                  Digits[I].Value, A, Digits[I].Color);
    end;
  end;
end;

end.
