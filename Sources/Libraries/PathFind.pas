unit PathFind;

interface

uses
  Types, gm_map, gm_creature;

type
  TPath = record
    Value: array of TPoint;
    Count, Length: Integer;  
  end;

var
  A, B: TPath;
  Wave: array of array of Integer;
  WaveW, WaveH: Integer;

procedure CreateWave(M : TMap; x, y, x2, y2 : Integer; IgnoreFog : Boolean = False; IgnoreCr : Boolean = False);
function GetNextStep(P: TPoint) : TPoint;

implementation

function Wave_GetNear(t : TPoint; napr : Byte; var t2 : TPoint) : Integer;
begin
  Result := -1;
  case napr of
    1 : t2 := Point(t.X + 1, t.Y);
    2 : t2 := Point(t.X, t.Y + 1);
    3 : t2 := Point(t.X - 1, t.Y);
    4 : t2 := Point(t.X, t.Y - 1);
    5 : t2 := Point(t.X + 1, t.Y + 1);
    6 : t2 := Point(t.X + 1, t.Y - 1);
    7 : t2 := Point(t.X - 1, t.Y + 1);
    8 : t2 := Point(t.X - 1, t.Y - 1);
  end;
  if (t2.X < 0) or (t2.X >= WaveW) or (t2.Y < 0) or (t2.Y >= WaveH) then Exit;
  Result := Wave[t2.X, t2.Y];
end;

procedure FillWave(x, y, x2, y2 : Integer);
var
  i, k    : Integer;
  t2      : TPoint;
  Napr    : Byte;
begin
  Wave[x, y] := 1;
  k := 1;

  A.Count := 1;
  B.Count := 0;
  if A.Count > A.Length - 10 then
  begin
    A.Length := A.Length + 100;
    SetLength(A.Value, A.Length);
  end;
  if B.Count > B.Length - 10 then
  begin
    B.Length := B.Length + 100;
    SetLength(B.Value, B.Length);
  end;
  A.Value[0] := Point(x, y);

  while True do
  begin
    B.Count := 0;
    k := k + 1;
    for i := 0 to A.Count - 1 do
    begin
      for Napr := 1 to 8 do
        if Wave_GetNear(A.Value[i], Napr, t2) = 0 then
        begin
          INC(B.Count);
          B.Value[B.Count - 1] := t2;
          Wave[t2.X, t2.Y] := k;
          if (t2.X = x2) and (t2.Y = y2) then Exit;
        end;
      if B.Count > B.Length - 10 then
      begin
        B.Length := B.Length + 100;
        SetLength(B.Value, B.Length);
      end;
    end;

    if B.Count = 0 then Exit;

    A.Count := 0;
    k := k + 1;
    for i := 0 to B.Count - 1 do
    begin
      for Napr := 1 to 8 do
        if Wave_GetNear(B.Value[i], Napr, t2) = 0 then
        begin
          INC(A.Count);
          A.Value[A.Count - 1] := t2;
          Wave[t2.X, t2.Y] := k;
          if (t2.X = x2) and (t2.Y = y2) then Exit;
        end;
      if A.Count > A.Length - 10 then
      begin
        A.Length := A.Length + 100;
        SetLength(A.Value, A.Length);
      end;
    end;

    if A.Count = 0 then Exit;
  end;
end;

procedure CreateWave(M : TMap; x, y, x2, y2 : Integer; IgnoreFog : Boolean = False; IgnoreCr : Boolean = False);
var
  w, h : Integer;
  i, j : Integer;
  Cr   : TCreature;
begin
  w := M.Width;
  h := M.Height;
  if (x < 0) or (x >= w) or (y < 0) or (y >= h) then Exit;

  if (w > WaveW) or (h > WaveH) then SetLength(Wave, w, h);
  WaveW := w;
  WaveH := h;

  for j := 0 to WaveH - 1 do
    for i := 0 to WaveW - 1 do
    begin
      Wave[i, j] := 0;
      if M.Objects.Obj[i, j] <> nil then
        if M.Objects.Obj[i, j].BlockWalk then Wave[i, j] := -1;
      if (IgnoreFog = False) and (M.Fog[i, j] = 0) then Wave[i, j] := -1;
    end;

  if IgnoreCr = False then
    for i := 0 to Map.Creatures.Count - 1 do
    begin
      Cr := TCreature(Map.Creatures[i]);
      if (IgnoreFog = False) and (M.Fog[Cr.Pos.X, Cr.Pos.Y] <> 2) then Continue;
      Wave[Cr.Pos.X, Cr.Pos.Y] := -1;
    end;

  FillWave(x, y, x2, y2);
end;

function GetNextStep(P: TPoint) : TPoint;
var
  Napr  : Byte;
  t, t2 : TPoint;
  i, j  : Integer;
begin
  j  := 1000000;
  t2 := Point(-1, 0);
  for Napr := 1 to 8 do
  begin
    i := Wave_GetNear(Point(P.X, P.Y), Napr, t);
    if (i > 0) and (i < j) then
    begin
      j  := i;
      t2 := t;
    end;
  end;
  Result := t2;
end;

end.
