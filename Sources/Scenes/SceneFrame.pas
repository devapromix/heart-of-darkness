unit SceneFrame;

interface

uses gm_engine, Scenes, SceneGame;

const // Manual
  Span = 7;

  CharHeight = 16;

  InvLeft = Span;
  InvWidth = 10;
  InvHeight = 5;

  ChestWidth = 10;
  ChestHeight = 4;

  InvTop = (Span * 2) + (5 * SlotSize);

  DollTop = Span;
  DollLeft = Span;

const // Auto
  ChestLeft = Span;
  ChestTop = (InvHeight * SlotSize) + (Span * 2) + InvTop;
  ChestCapacity = ChestWidth * ChestHeight;

  InvCapacity = InvWidth * InvHeight;

  FrameWidth = (InvWidth * SlotSize) + (Span * 2);

type
  TGameFrame = (gfInv, gfInfo, gfSkill);

var
  LeftFrame, RightFrame: set of TGameFrame;

type
  TFramePos = (fpLeft, fpRight);

var
  FrameHeight, FrameTop: Word;

type
  TSceneFrame = class(TSceneGame)
  private
    Scene: array [TGameFrame] of TScene;
  public
    constructor Create();
    procedure Render(); override;
    procedure Update(); override;
    destructor Destroy; override;
  end;

type
  TSceneBaseFrame = class(TScene)
  private
    FramePos: TFramePos;
  public
    Left, CBTop, CBLeft, CPLeft: Integer;
    constructor Create(FramePos: TFramePos);
    procedure Render(); override;
    procedure Update(); override;
    destructor Destroy; override;
  end;

implementation

uses Resources, gm_creature, gm_item, gm_obj, SceneInv, SceneChar,
  SceneSkill, Hint, Utils, Sound, gm_patterns;

procedure SetSceneGame;
begin
  Play(ttSndClick);
  SceneManager.SetScene(scGame);
  if (Drag.Item <> nil) and (Drag.Item.Pat.Category = icSkill) then Drag.Item := nil;
end;

{ TSceneFrame }

constructor TSceneFrame.Create();
begin
  inherited;
  Scene[gfInfo]  := TSceneChar.Create(fpRight);
  Scene[gfSkill] := TSceneSkill.Create(fpRight);
  Scene[gfInv]   := TSceneInv.Create(fpLeft);
end;

destructor TSceneFrame.Destroy;
var
  I: TGameFrame;
begin
  for I := gfInv to gfSkill do Scene[I].Free;
  inherited;
end;

procedure TSceneFrame.Render;
var
  I: TGameFrame;
begin
  inherited;
  if (LookAtObj = nil) then
    FrameHeight := (InvTop + (InvHeight * SlotSize) + (Span * 3)) + CharHeight
      else FrameHeight := (InvTop + ((InvHeight + ChestHeight) * SlotSize) + (Span * 4)) + CharHeight;
  FrameTop := (ScreenHeight div 2) - (FrameHeight div 2);
  DrawBG;

  for I := gfInv to gfSkill do
    if (I in LeftFrame + RightFrame) then Scene[I].Render;
end;

procedure TSceneFrame.Update;
var
  I: TGameFrame;
begin
  HItem := nil;                                                                                      
  SHint.Show := False;

  if KeyPress(K_ESCAPE) or KeyPress(K_INV) or KeyPress(K_CHAR) or KeyPress(K_SKILL) then
  begin
    Play(ttSndClick);
    if (LookAtObj <> nil) then
    begin
      Play(ttSndClose);
      LookAtObj := nil;
    end;
    // Left
    if KeyPress(K_INV) then if not (gfInv in LeftFrame) then LeftFrame := [gfInv] else LeftFrame := [];
    // Right
    if KeyPress(K_CHAR) then if not (gfInfo in RightFrame) then RightFrame := [gfInfo] else RightFrame := [];
    if KeyPress(K_SKILL) then if not (gfSkill in RightFrame) then RightFrame := [gfSkill] else RightFrame := [];
    //
    if KeyPress(K_ESCAPE) then
    begin
      LeftFrame := [];
      RightFrame := [];
    end;
    if (LeftFrame + RightFrame = []) then SetSceneGame;
  end;

  for I := gfInv to gfSkill do
    if (I in LeftFrame + RightFrame) then Scene[I].Update;

   if (HItem = nil) then IHint.Show := False else if (nmtime > 30) then IHint.Show := True;

  ClearStates;
end;

{ TSceneBaseFrame }

constructor TSceneBaseFrame.Create(FramePos: TFramePos);
begin
  inherited Create;
  Self.FramePos := FramePos;
  if (FramePos = fpLeft) then Left := 0 else Left := ScreenWidth - FrameWidth;
end;

destructor TSceneBaseFrame.Destroy;
begin

  inherited;
end;

procedure TSceneBaseFrame.Render;
var
  I: Word;
begin
  DrawFrame(Left, FrameTop, FrameWidth, FrameHeight);
  Render2D(Resource[ttClose], CBLeft, CBTop);
  if (LookAtObj <> nil) then Render2D(Resource[ttPickup], CPLeft, CBTop);
  Hint.Render;
end;

procedure TSceneBaseFrame.Update;

  procedure HClose;
  begin
    InitSHint(CBLeft, CBTop, 'Закрыть');
    SHint.Show := True;
  end;

  procedure HPickUp;
  begin
    InitSHint(CPLeft, CBTop, 'Взять все');
    SHint.Show := True;
  end;

  procedure SetSGame;
  begin
    if (FramePos = fpLeft) then LeftFrame := [];
    if (FramePos = fpRight) then RightFrame := [];
    if (LookAtObj <> nil) then
    begin
      Play(ttSndClose);
      LookAtObj := nil;
    end;
    if (LeftFrame + RightFrame = []) then SetSceneGame;
  end;

begin
  CBTop := FrameTop + FrameHeight - (Span + CharHeight);
  if (FramePos = fpLeft) then CPLeft := FrameWidth - ((Resource[ttClose].Width + Span) * 2);
  if (FramePos = fpLeft) then CBLeft := FrameWidth - Resource[ttClose].Width - Span else CBLeft := Left + Span;
  if MouseInRect(CBLeft, CBTop, Resource[ttClose].Width, Resource[ttClose].Height) then
    if MouseDown(M_BLEFT) then SetSGame else HClose;
  if (FramePos = fpLeft) and (LookAtObj <> nil) and MouseInRect(CPLeft, CBTop, Resource[ttClose].Width, Resource[ttClose].Height) then
    if MouseDown(M_BLEFT) then PickUpAllItems else HPickUp;
end;

end.
