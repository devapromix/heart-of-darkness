unit SceneAbout;

interface

uses Classes, Button, Scenes, SceneStage;

type
  TSceneAbout = class(TSceneStage)
  private
    BackButton: TButton;
  public
    constructor Create();
    procedure Render(); override;
    procedure Update(); override;
    destructor Destroy; override;
  end;

implementation

uses gm_engine, Resources, Sound;

{ TSceneAbout }

constructor TSceneAbout.Create;
begin
  BackButton := TButton.Create(ScreenWidth - 210, ScreenHeight - 60, 'Назад');
  BackButton.Sellected := True;
end;

destructor TSceneAbout.Destroy;
begin

  inherited;
end;

procedure TSceneAbout.Render;
begin
  Background := ttAboutBG;
  inherited Render;
  BackButton.Render;
end;

procedure TSceneAbout.Update;
begin
  inherited;
  if KeyPress(K_ENTER) or KeyPress(K_ESCAPE) then
  begin
    Play(ttSndClick);
    SceneManager.SetScene(scMenu);
  end;
  if BackButton.Click then
    SceneManager.SetScene(scMenu);
  ClearMouseState;
end;

end.
