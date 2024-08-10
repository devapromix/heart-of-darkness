program zglHoD;

{.$DEFINE DEBUG}     

uses
  ShareMem,
  SysUtils,
  gm_engine in 'Libraries\gm_engine.pas',
  XML in 'Resources\XML.pas',
  uDatFile in 'Resources\uDatFile.pas',
  gm_creature in 'Game\gm_creature.pas',
  gm_generator in 'Game\gm_generator.pas',
  gm_item in 'Game\gm_item.pas',
  gm_map in 'Game\gm_map.pas',
  gm_obj in 'Game\gm_obj.pas',
  PathFind in 'Libraries\PathFind.pas',
  gm_patterns in 'Resources\gm_patterns.pas',
  Utils in 'Utilities\Utils.pas',
  Spell in 'Game\Spell.pas',
  Resources in 'Resources\Resources.pas',
  CustomMap in 'Entities\CustomMap.pas',
  Stat in 'Game\Stat.pas',
  Entity in 'Entities\Entity.pas',
  CustomCreature in 'Entities\CustomCreature.pas',
  Bar in 'Components\Bar.pas',
  zglHeader in 'Libraries\zglHeader.pas',
  Scenes in 'Scenes\Scenes.pas',
  SceneMenu in 'Scenes\SceneMenu.pas',
  SceneGame in 'Scenes\SceneGame.pas',
  SceneInv in 'Scenes\SceneInv.pas',
  SceneChar in 'Scenes\SceneChar.pas',
  SceneFrame in 'Scenes\SceneFrame.pas',
  SceneSkill in 'Scenes\SceneSkill.pas',
  Hint in 'Rendering\Hint.pas',
  Belt in 'Rendering\Belt.pas',
  IntBar in 'Rendering\IntBar.pas',
  Digit in 'Rendering\Digit.pas',
  Effect in 'Rendering\Effect.pas',
  Sound in 'Resources\Sound.pas',
  SceneRace in 'Scenes\SceneRace.pas',
  Button in 'Controls\Button.pas',
  SceneStage in 'Scenes\SceneStage.pas',
  SceneAbout in 'Scenes\SceneAbout.pas',
  SceneTavern in 'Scenes\SceneTavern.pas',
  Storage in 'Game\Storage.pas',
  SceneConfig in 'Scenes\SceneConfig.pas',
  SceneHelp in 'Scenes\SceneHelp.pas',
  LibZip in 'Libraries\LibZip.pas',
  Town in 'Game\Town.pas',
  GlobalMap in 'Game\GlobalMap.pas',
  TimeVars in 'Components\TimeVars.pas';

procedure OnInit;
begin
  snd_Init();
  Resources.Load;
  InitCamera2D(Cam);
  SceneManager := TScenes.Create;  

  SceneManager.CurrentScene[scMenu] := TSceneMenu.Create;
  SceneManager.CurrentScene[scGame] := TSceneGame.Create;
  SceneManager.CurrentScene[scFrame] := TSceneFrame.Create;
  SceneManager.CurrentScene[scAbout] := TSceneAbout.Create;
  SceneManager.CurrentScene[scTavern] := TSceneTavern.Create;
  SceneManager.CurrentScene[scConfig] := TSceneConfig.Create;
  SceneManager.CurrentScene[scHelp] := TSceneHelp.Create;

  SceneManager.SetScene(scMenu);
end;

procedure Render;
begin
  SceneManager.Render;
end;

procedure Update;
begin
  SceneManager.Update;
end;

procedure OnQuit;
begin
  SceneManager.Free;
end;

var
  I: Byte;

begin
  {$IF COMPILERVERSION >= 18}
  ReportMemoryLeaksOnShutdown := True;
  {$IFEND}
  if not zglLoad(libZenGL) then Exit;

  Randomize;
  {$IFDEF DEBUG} Debug := True; {$ELSE} Debug := False; {$ENDIF}
  for I := 1 to ParamCount do
  begin
    if (ParamStr(I) = '-d') then Debug := True;
  end;

  Timer_Add(@Update, 15);
  zgl_Reg(SYS_LOAD, @OnInit);
  zgl_Reg(SYS_DRAW, @Render);
  zgl_Reg(SYS_EXIT, @OnQuit);

  wnd_SetCaption('Heart of Darkness RL');
  wnd_ShowCursor(True);

  zgl_Enable(APP_USE_LOG);
  zgl_Enable(CLIP_INVISIBLE);

  scr_SetOptions(ScreenWidth, ScreenHeight, 0, FullScr, VSync);

  zgl_Init;
end.
