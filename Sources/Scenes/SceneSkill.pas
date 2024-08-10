unit SceneSkill;

interface

uses Scenes, SceneFrame;

const
  SkillCount    = 12; // Количество навыков.
  SkillMax      = 5;  // Максимальный уровень навыка.
  SkillIconSize = 32; // Размер иконки навыка.
  SkillYSpan    = 50; // Расстояние между иконками по вертикали.
  SkillXSpan    = 50; // Расстояние между иконками по горизонтали.

type
  TSceneSkill = class(TSceneBaseFrame)
  private

  public
    constructor Create(FramePos: TFramePos);
    procedure Render(); override;
    procedure Update(); override;
    destructor Destroy; override;
    function MouseOnSkillIcon(): Byte;
  end;

implementation

uses gm_engine, SceneInv, Resources, gm_creature, Stat, gm_patterns, Utils,
  gm_item, Hint;

{ TSceneSkill }

constructor TSceneSkill.Create(FramePos: TFramePos);
begin
  inherited;
end;

destructor TSceneSkill.Destroy;
begin

  inherited;
end;

procedure TSceneSkill.Render;
var
  Item: TItem;
  Prop: TItemProp;
  I, Icon: Integer;
begin
  inherited;
  for I := 0 to PC.SkillCount - 1 do
  begin
    Item.Pat := GetItemPat(PC.GetSkillName(I));
    Item_Draw(@Item, Left + Span + (Item.Pat.Left * SkillXSpan), FrameTop + Span + (Item.Pat.Top * SkillYSpan), 1, Prop, 0);
  end;
  Icon := MouseOnSkillIcon();
  if (Icon > 0) then 
  if IHint.Show and (Drag.Item = nil) then
  begin
    HintBG(IHint.X, IHint.Y, IHint.W, IHint.H);
    for I := 0 to Length(IHint.Text) - 1 do
      TextOut(Font[ttFont1], IHint.X + IHint.W div 2, IHint.Y + (I * 15) + 10, 1, 0, IHint.Text[I], 255, IHint.Color[I], TEXT_HALIGN_CENTER);
  end;
  if (Drag.Item <> nil) then Item_Draw(Drag.Item, GetMouse.X - 16, GetMouse.Y - 16, Drag.Count, Drag.Prop, 2);
end;

function TSceneSkill.MouseOnSkillIcon(): Byte;
var
  I: Byte;
  SPat: TItemPat;
begin
  Result := 0;
  for I := 0 to PC.SkillCount - 1 do
  begin
    SPat := GetItemPat(PC.GetSkillName(I));
    if MouseInRect(Left + Span + (SPat.Left * SkillXSpan),
      FrameTop + Span + (SPat.Top * SkillYSpan),
      SkillIconSize, SkillIconSize) then
    begin
      Result := I + 1;
      Break;
    end;  
  end;
end;

procedure TSceneSkill.Update;
var
  Index: Integer;
  Prop: TItemProp;
  Icon: Integer;
  Item: TItem;
begin
  inherited;
  Index := -1;
  Icon := MouseOnSkillIcon();
  if (Icon > 0) and (Drag.Item = nil) then
  begin
    Item.Pat := GetItemPat(PC.GetSkillName(Icon - 1));
    InitIHint(Left + Span + (Item.Pat.Left * SkillXSpan), FrameTop + Span + (Item.Pat.Top * SkillYSpan), @Item);
    IHint.Show := True;
  end;
  if MouseClick(M_BLEFT) then
  begin
    if (Icon > 0) then
    begin
      if (Drag.Item <> nil) and (Drag.Item.Pat.Category <> icSkill) then Exit;
      if (Drag.Item = nil) then
      begin
        if not Item.Pat.Active then Exit;
        ClearItemProp(Prop);
        if (not PC.HasItem(Item.Pat, 1) and not PC.CreateItem(Item.Pat, 1, Prop, Index)) or (Index <= -1) then Exit;
        Drag.Item := @PC.Items[Index];
        Drag.Count := 1;
        Drag.Prop := Prop;
        PC.DelItem(Item.Pat, 9999);
      end else Drag.Item := nil;
    end;
  end;
end;

end.

