unit Town;

interface

uses Classes, Button, Scenes, SceneGame;

type
  TTownItem = (tiTavern, tiGate, tiPortal);

const
  ButtonCaption: array [TTownItem] of string =
    ('Семь Глаз Химеры', 'Главные Врaта Города', 'Магический Портал');

type
  TTown = class(TObject)
  private

    TownPos: TTownItem;
    SceneButton: array [TTownItem] of TButton;
    procedure SellectScene(I: TTownItem);
  protected

  public
    constructor Create;
    destructor Destroy; override;
    procedure Render;
    procedure Update;
  published

  end;

var
  PCTown: TTown;

implementation

uses gm_engine, Resources, Sound;

const
  ButWidth = 200; // Ширина кнопки
  ButHeight = 50; // Высота кнопки
  Mid = 10;       // Верт. расстояние между кнопками

{ TTown }

constructor TTown.Create;
var
  I: TTownItem;
  Top: Integer;
begin
  Top := 100;
  for I := Low(TTownItem) to High(TTownItem) do
    SceneButton[I] := TButton.Create((ScreenWidth div 2) - (ButWidth div 2),
      ((ScreenHeight div 2) - ((Ord(High(TTownItem)) + 1) * (ButHeight + Mid)) - 100) +
      (Ord(I) * (ButHeight + Mid)) + Top,
      ButtonCaption[I]);
  TownPos := tiTavern;
end;

destructor TTown.Destroy;
var
  I: TTownItem;
begin
  inherited;
  for I := Low(TTownItem) to High(TTownItem) do
    SceneButton[I].Free;
end;

procedure TTown.Render;
var
  I: TTownItem;
begin
  Exit;
  SetCamera2D(nil);
  for I := Low(TTownItem) to High(TTownItem) do
  begin
    SceneButton[I].Sellected := (I = TownPos);
    SceneButton[I].Render;
  end;
end;

procedure TTown.SellectScene(I: TTownItem);
begin
  case I of
    tiTavern:
    begin
    end;
    tiGate:
    begin
      IsWorld := True;
      Play(ttSndClick);
      //IsGate := True;
    end;
    tiPortal:
      if IsGame and IsPortal then
      begin
        IsGate := False;
        IsTown := False;
        IsWorld := False;
        IsPortal := False;
        Play(ttSndUsePortal);
      end;
  end;
end;

procedure TTown.Update;
var
  I: TTownItem;
begin
  if KeyPress(K_UP) then
    if (TownPos = tiTavern) then
      TownPos := tiPortal else Dec(TownPos);
  if KeyPress(K_DOWN) then Inc(TownPos);
  if (TownPos < tiTavern) then TownPos := tiPortal;
  if (TownPos > tiPortal) then TownPos := tiTavern;
  if KeyPress(K_ENTER) then SellectScene(TownPos);
  for I := Low(TTownItem) to High(TTownItem) do
    if SceneButton[I].Click then
      SellectScene(I);
  ClearStates;
end;

end.
