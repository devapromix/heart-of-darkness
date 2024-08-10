unit Scenes;

interface

uses Classes;

type
  TSceneEnum = (scMenu, scGame, scFrame, scAbout, scTavern, scConfig, scHelp);

type
  TScene = class(TObject)
    procedure Render(); virtual; abstract;
    procedure Update(); virtual; abstract;
  end;

type
  TScenes = class(TScene)
  private
    FScene: TScene;
    procedure SetScene(const Value: TScene); overload;
  public
    CurrentScene: array [TSceneEnum] of TScene;
    constructor Create;
    destructor Destroy; override;
    procedure Render(); override;
    procedure Update(); override;
    property Scene: TScene read FScene write SetScene default nil;
    procedure SetScene(SceneEnum: TSceneEnum); overload;
    procedure Clear;
  end;

var
  SceneManager: TScenes;

implementation

uses gm_engine;

{ TScenes }

procedure TScenes.Clear;
begin
  Scene := nil;
end;

procedure TScenes.Render;
begin
  if (Scene <> nil) then Scene.Render;
end;

procedure TScenes.Update;
begin
  if (Scene <> nil) then Scene.Update;
end;

procedure TScenes.SetScene(const Value: TScene);
begin
  FScene := Value;
  ClearStates;
end;

procedure TScenes.SetScene(SceneEnum: TSceneEnum);
begin
  Scene := CurrentScene[SceneEnum];
end;

constructor TScenes.Create;
begin

end;

destructor TScenes.Destroy;
var
  I: TSceneEnum;
begin
  for I := Low(TSceneEnum) to High(TSceneEnum) do CurrentScene[I].Free;
  inherited;
end;

end.
