unit SceneTavern;

interface

uses Classes, Button, Scenes, SceneStage, Resources;

type
  TMenuItem = (miBack, miNew, miStart, miUp, miDown, miInfo, miCup, miDel);

type
  TSceneTavern = class(TSceneStage)
  private
    MenuPos: TMenuItem;
    SaveMenuPos: ShortInt;
    SceneButton: array [TMenuItem] of TButton;
    procedure SellectScene(I: TMenuItem);
  public
    constructor Create();
    procedure Render(); override;
    procedure Update(); override;
    destructor Destroy; override;
  end;

implementation

uses gm_engine, Sound, Utils, Storage, SceneGame;

const
  BordWidth = 318;
  BordHeight = 38;
  SavesMaxCount = 12;
  SaveFrame = 390;

{ TSceneTavern }

constructor TSceneTavern.Create;
begin
  SaveMenuPos := 0;
  SceneButton[miBack]  := TButton.Create(10,  540, 'Назад');
  SceneButton[miNew]   := TButton.Create(220, 540, 'Новый');
  SceneButton[miStart] := TButton.Create(590, 540, 'Играть');
  SceneButton[miUp]    := TButton.Create(728, 22,  ttUp);
  SceneButton[miDown]  := TButton.Create(728, 470, ttDown);
  SceneButton[miInfo]  := TButton.Create(428, 540, ttInfo);
  SceneButton[miCup]   := TButton.Create(480, 540, ttCup);
  SceneButton[miDel]   := TButton.Create(532, 540, ttDelete);
  MenuPos := miBack;
end;

destructor TSceneTavern.Destroy;
begin

  inherited;
end;

procedure TSceneTavern.Render;
var
  I: TMenuItem;
  J, C: Integer;
begin
  Background := ttTavernBG;
  inherited Render;
  DrawFrame(SaveFrame, 10, 400, 522);
  for I := Low(TMenuItem) to High(TMenuItem) do
  begin
    SceneButton[I].Sellected := (I = MenuPos);
    SceneButton[I].Render;
  end;

  if (MenuPos = miStart) then
    Rect2D(SaveFrame+10, 22 + (SaveMenuPos * 42), BordWidth, BordHeight, cDkYellow);

  for J := 0 to SavesMaxCount - 1 do
  begin
    if (J = SaveMenuPos) and (MenuPos = miStart) then C := cDkYellow else C := cDkWhite;
    RenderSaveItem('Apromix', 'Орк Варвар 1 уровень', SaveFrame, J * 42, C);
  end;
end;

procedure TSceneTavern.SellectScene(I: TMenuItem);
begin
  case I of
    miBack:
      SceneManager.SetScene(scMenu);
    miNew:;
    miInfo:;
    miCup:;
    miDel:;
    miStart:
    begin
      TSceneGame(Scenes.SceneManager.CurrentScene[scGame]).Refresh();
      IsGame := True;
      IsTown := True;
      IsPortal := False;
      SceneManager.SetScene(scGame);
    end;
  end;
end;

procedure TSceneTavern.Update;
var
  I: TMenuItem;
begin
  inherited;
  if KeyPress(K_UP) then Dec(SaveMenuPos);
  if KeyPress(K_DOWN) then Inc(SaveMenuPos);
  SaveMenuPos := ClampCycle(SaveMenuPos, 0, SavesMaxCount - 1);
  if KeyPress(K_LEFT) then
    if (MenuPos = miBack) then
      MenuPos := miStart else Dec(MenuPos);
  if KeyPress(K_RIGHT) then Inc(MenuPos);
  if (MenuPos < miBack) then MenuPos := miStart;
  if (MenuPos > miStart) then MenuPos := miBack;
  if KeyPress(K_ENTER) then
  begin
    Play(ttSndClick);
    SellectScene(MenuPos);
  end;
  if KeyPress(K_ESCAPE) then
  begin
    Play(ttSndClick);
    SceneManager.SetScene(scMenu);
  end;
  for I := Low(TMenuItem) to High(TMenuItem) do
    if SceneButton[I].Click then
      SellectScene(I);
  ClearStates;
end;

end.
