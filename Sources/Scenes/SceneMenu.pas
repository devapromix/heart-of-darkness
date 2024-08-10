unit SceneMenu;

interface

uses Classes, Button, Scenes, SceneStage;

type
  TMenuItem = (miTavern, miResume, miHelp, miConfig, miAbout, miQuit);

const
  ButtonCaption: array [TMenuItem] of string =
    ('Таверна', 'Продолжить', 'Справка', 'Настройки', 'Авторы', 'Выход');

type
  TSceneMenu = class(TSceneStage)
  private
    MenuPos: TMenuItem;
    SceneButton: array [TMenuItem] of TButton;
    procedure SellectScene(I: TMenuItem);
    procedure Resume;
  public
    constructor Create();
    procedure Render(); override;
    procedure Update(); override;
    destructor Destroy; override;
  end;

implementation

uses gm_engine, Resources, Sound;

const
  Right = 50;     // Отступ меню справа
  ButWidth = 200; // Ширина кнопки
  ButHeight = 50; // Высота кнопки
  Mid = 10;       // Верт. расстояние между кнопками

var
  Top: Integer;   // Отступ меню сверху

{ TSceneMenu }

constructor TSceneMenu.Create;
var
  I: TMenuItem;
begin
  Top := (ScreenHeight div 2) - (((Ord(High(TMenuItem)) + 1) * (ButHeight + Mid)) div 2);
  for I := Low(TMenuItem) to High(TMenuItem) do
    SceneButton[I] := TButton.Create(ScreenWidth - (ButWidth + Right),
      Top + (Ord(I) * (ButHeight + Mid)), ButtonCaption[I]);
  MenuPos := miTavern;
end;

destructor TSceneMenu.Destroy;
var
  I: TMenuItem;
begin
  for I := Low(TMenuItem) to High(TMenuItem) do
    SceneButton[I].Free;
  inherited;
end;

procedure TSceneMenu.Render;
var
  I: TMenuItem;
begin
  Background := ttMenuBG;
  inherited Render;
  DrawFrame(ScreenWidth - (ButWidth + Right) - Mid, Top - Mid,
    ButWidth + (Mid * 2), (Ord(High(TMenuItem)) + 1) * (ButHeight + Mid) + Mid);
  for I := Low(TMenuItem) to High(TMenuItem) do
  begin
    SceneButton[I].Sellected := (I = MenuPos);
    SceneButton[I].Render;
    TextOut(Font[ttFont1], 10, ScreenHeight - 26, 1, 0, Version, 255, cDkYellow, 0);
  end;
end;

procedure TSceneMenu.Resume;
begin
  SceneManager.SetScene(scGame);
end;

procedure TSceneMenu.SellectScene(I: TMenuItem);
begin
  case I of
    miTavern:
    begin
      IsGame := False;
      SceneManager.SetScene(scTavern);
    end;
    miResume:
      if IsGame then Resume;
    miHelp:
      SceneManager.SetScene(scHelp);
    miConfig:
      SceneManager.SetScene(scConfig);
    miAbout:
      SceneManager.SetScene(scAbout);
    miQuit:
      Quit;
  end;
end;

procedure TSceneMenu.Update;
var
  I: TMenuItem;
begin
  inherited;
  if IsGame and KeyPress(K_ESCAPE) then Resume;
  if KeyPress(K_UP) then
    if (MenuPos = miTavern) then
      MenuPos := miQuit else Dec(MenuPos);
  if KeyPress(K_DOWN) then Inc(MenuPos);
  if (MenuPos < miTavern) then MenuPos := miQuit;
  if (MenuPos > miQuit) then MenuPos := miTavern;
  if KeyPress(K_ENTER) then
  begin
    Play(ttSndClick);
    SellectScene(MenuPos);
  end;
  for I := Low(TMenuItem) to High(TMenuItem) do
    if SceneButton[I].Click then
      SellectScene(I);
  ClearStates;
end;

end.

