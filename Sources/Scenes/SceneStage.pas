unit SceneStage;

interface

uses Scenes, Resources;

type
  TSceneStage = class(TScene)
  private
  public
    Background: TResEnum;
    procedure Render(); override;
    procedure Update(); override;
  end;

implementation

uses gm_engine;

{ TSceneStage }

procedure TSceneStage.Render;
begin
  inherited;
  Render2D(Resource[Background], 0, 0, ScreenWidth, ScreenHeight, 0, 0);
end;

procedure TSceneStage.Update;
begin
  inherited;

end;

end.
