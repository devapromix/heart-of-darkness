unit GlobalMap;

interface

uses Types, gm_engine, Classes, Button, Scenes, gm_patterns;

const
  GMapWidth = 35;
  GMapHeight = 25;

var
  M: TPoint;
  PatGMap: array [0..GMapWidth - 1, 0..GMapHeight - 1] of TMapPat;
  FogGMap: array [0..GMapWidth - 1, 0..GMapHeight - 1] of Boolean;

type
  TGate = class(TObject)
  private
    Buttons: array of TButton;
  public
    constructor Create();
    procedure Clear();
    function GenList(X, Y: Integer): Boolean;
    procedure Render();
    procedure Update();
    destructor Destroy; override;
    procedure LoadMap(P: TMapPat);
  end;

type
  TGMap = class(TObject)
  private
    Top, Left: Integer;
  public
    constructor Create();
    procedure Render();
    procedure Update();
    destructor Destroy; override;
    procedure SetGMapPoint(AX, AY: Byte);
  end;

var
  Gate: TGate;
  GMap: TGMap;

implementation

uses Resources, Sound, Utils, SceneGame, gm_creature, Hint;

const
  Span = 5;
  ButWidth = 300;
  ButHeight = 20;
  ButSpan = ButHeight + Span;
  BordWidth = ButWidth + (Span * 2);
  GMTileSize = 16;

{ TGate }

procedure TGate.Clear;
var
  I: Integer;
begin
  for I := 0 to Length(Buttons) - 1 do Buttons[I].Free;
  SetLength(Buttons, 0);
end;

constructor TGate.Create;
begin
  Clear;
end;

destructor TGate.Destroy;
begin

  inherited;
end;

function TGate.GenList(X, Y: Integer): Boolean;
var
  I, J, T: Integer;
  L: TStringList;
  P: TMapPat;
  E: TExplodeResult;
begin
  Result := False;
  L := TStringList.Create;
  for I := 0 to 9 do L.Append('');
  try
    Clear;
    E := nil;
    E := Explode(',', AllMapsID);
    for J := 0 to High(E) do
    begin
      if (E[J] = '') then Continue;
      P := TMapPat(GetPattern('MAP', E[J]));
      if (P = nil) then Continue;   
      if (P.Z > 0) and not (System.Pos(E[J], PCAllMapsID) > 0) then Continue;
      if ((X = P.X) and (Y = P.Y)) then
      begin
        L[P.Z] := E[J];
        SetLength(Buttons, Length(Buttons) + 1);
      end;
    end;
    I := 0;
    for J := 0 to L.Count - 1 do
    begin
      if (L[J] = '') then Continue;
      P := TMapPat(GetPattern('MAP', L[J]));
      if (P = nil) then Continue;
      T := (ScreenHeight div 2) - ((Length(Buttons) * ButSpan) div 2);
      Buttons[I] := TButton.Create((ScreenWidth div 2) - (ButWidth div 2),
        (I * ButSpan) + T, P.Title, P.Tex);
      Buttons[I].Tag := P.Name;
      Inc(I);
    end;
  finally
    L.Free;
  end;
  Result := (Length(Buttons) > 0);
//  Box(PCAllMapsID);
end;

procedure TGate.LoadMap(P: TMapPat);
begin
  //PC.SaveToFile('hero.sav');
  //TSceneGame(Scenes.SceneManager.CurrentScene[scGame]).LoadLevel(P);
end;

procedure TGate.Render;
var
  BordHeight: Word;
  Top, Left: Word;
  I: Integer;
begin
  if (Length(Buttons) <= 0) then IsGate := False;
  if not IsGate then Exit;
  DrawBG;
  BordHeight := (Length(Buttons) + 1) * ButSpan + ButHeight;
  Top := (ScreenHeight div 2) - ((Length(Buttons) * ButSpan) div 2) - ButSpan;
  Left := (ScreenWidth div 2) - (BordWidth div 2);
  DrawFrame(Left, Top, BordWidth, BordHeight);
  TextOut(Font[ttFont1], ScreenWidth div 2, Top + 5, 1, 0, 'Выберите локацию', 255, cWhite, TEXT_HALIGN_CENTER);
  for I := 0 to Length(Buttons) - 1 do Buttons[I].Render;
  Render2D(Resource[ttClose], Left + BordWidth - ButHeight, Top + BordHeight - ButHeight);
end;

procedure TGate.Update;
var
  P: TMapPat;
  I: Integer;
begin
  if (Length(Buttons) <= 0) then Exit;
  for I := 0 to Length(Buttons) - 1 do
    if Buttons[I].Click then
    begin
      IsTown := False;
      IsGate := False;
      IsWorld := False;
      IsPortal := False;
      P := TMapPat(GetPattern('MAP', Buttons[I].Tag));
      if (P = nil) then Exit;
      LoadMap(P);
      GMap.SetGMapPoint(M.X, M.Y);
    end;
  ClearStates;
end;

{ TGMap }

var
  D: TPoint;

constructor TGMap.Create;
var
  X, Y: Integer;
begin
  Top := (ScreenHeight div 2) - (GMapHeight * GMTileSize div 2);
  Left := (ScreenWidth div 2) - (GMapWidth * GMTileSize div 2);
  for Y := 0 to GMapHeight - 1 do
    for X := 0 to GMapWidth - 1 do
    begin
      FogGMap[X, Y] := False;
      PatGMap[X, Y] := nil;
    end;
end;

destructor TGMap.Destroy;
begin

  inherited;
end;

procedure TGMap.Render;
var
  A, B, X, Y, H, W: Word;
begin
  if not IsWorld then Exit;
  W := GMapWidth * GMTileSize + (Span * 2);
  H := GMapHeight * GMTileSize + (Span * 2) + GMTileSize + ButHeight;
  DrawBG;
  DrawFrame(Left - Span, Top - ButHeight, W, H);
  TextOut(Font[ttFont1], ScreenWidth div 2, Top - GMTileSize, 1, 0,
    'Карта Мира Королевства Семицветных Городов', 255, cDkYellow, TEXT_HALIGN_CENTER);
  for Y := 0 to GMapHeight - 1 do
    for X := 0 to GMapWidth - 1 do
    begin
      A := Left + (X * GMTileSize);
      B := Top + (Y * GMTileSize);
      if not FogGMap[X, Y] then
      begin
        Rect2D(A, B, GMTileSize, GMTileSize, 0, 255, PR2D_FILL);
        Continue;
      end;
      Render2D(Resource[ttEffects], A, B, GMTileSize, GMTileSize, 0, 12);
      if (PatGMap[X, Y] <> nil) then Render2D(PatGMap[X, Y].Tex, A, B);
    end;
  Rect2D(Left, Top, GMapWidth * GMTileSize, GMapHeight * GMTileSize, cDkYellow);
  Render2D(Resource[ttClose], Left + W - ((Span * 2) + GMTileSize), Top + H - (Span + GMTileSize + ButHeight));
//  Render2D(Resource[ttChar], Left + (PC.GMapPos.X * GMTileSize), Top + (PC.GMapPos.Y * GMTileSize));
  Circ2D(Left + (PC.GMapPos.X * GMTileSize) + 8, Top + (PC.GMapPos.Y * GMTileSize) + 8, CursorRad - 8, cLtYellow);
  if (PatGMap[D.X, D.Y] <> nil) and FogGMap[D.X, D.Y] then
  begin
    InitSHint(Left + (D.X * GMTileSize), Top + (D.Y * GMTileSize), PatGMap[D.X, D.Y].Title);
    SHint.Show := True;
    Hint.Render;
  end;
end;

procedure TGMap.SetGMapPoint(AX, AY: Byte);
var
  A, B, X, Y: Integer;
begin
  D := gm_engine.Point(AX, AY);
  PC.GMapPos := gm_engine.Point(AX, AY);
  for Y := -1 to +1 do
    for X := -1 to +1 do
    begin
      A := D.X + X;
      A := Clamp(A, 0, GMapWidth - 1);
      B := D.Y + Y;
      B := Clamp(B, 0, GMapHeight - 1);
      FogGMap[A, B] := True;
    end;
end;

procedure TGMap.Update;
begin
  D.X := (GetMouse.X - Left) div GMTileSize;
  D.X := Clamp(D.X, 0, GMapWidth - 1);
  D.Y := (GetMouse.Y - Top) div GMTileSize;
  D.Y := Clamp(D.Y, 0, GMapHeight - 1);
  if (MouseUp(M_BLEFT)) and FogGMap[D.X, D.Y] then
  begin
    M := D;
    if Gate.GenList(D.X, D.Y) then
    begin
      IsWorld := False;
      IsGate := True;
    end;
    ClearStates;
  end;
end;

initialization
  Gate := TGate.Create;
  GMap := TGMap.Create;

finalization
  Gate.Free;
  GMap.Free;

end.
