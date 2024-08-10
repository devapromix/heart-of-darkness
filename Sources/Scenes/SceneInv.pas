unit SceneInv;

interface

uses Scenes, SceneFrame;

type
  TSceneInv = class(TSceneBaseFrame)
  private
  
  public
    constructor Create(FramePos: TFramePos);
    procedure Render(); override;
    procedure Update(); override;
    destructor Destroy; override;
  end;
  
procedure ChRHandItemInBelt;
procedure PickUpAllItems;

implementation

uses gm_engine, SysUtils, Resources, gm_creature, gm_item, gm_obj,
  Utils, Hint, SceneGame, Belt, Sound;

var
  BtnDwn  : Word;
  CraftTop: Word;

procedure ChRHandItemInBelt;
var
  S: ShortInt;
begin
  S := PCBelt.ActSlot;
  if (PC.Items[S].Count > 0)
    and (UpperCase(PC.Items[S].Pat.Equip) = PC.SlotItem[slRHand].Name) then
      PC.SlotItem[slRHand].Item := PC.Items[S]
        else PC.SlotItem[slRHand].Item.Count := 0;
  PC.Calculator;
  if ChBIFlag and (PC.Items[S].Count > 0)
    and (UpperCase(PC.Items[S].Pat.Equip) = PC.SlotItem[slRHand].Name)
    and (PC.GetDamageInfo > '0') then
  begin
    PC.Info('Урон ' + PC.GetDamageInfo, True);
    ChBIFlag := False;
  end;
end;

procedure PickUpAllItems;
var
  X, Y, Z, Index: Integer;
begin
  if (LookAtObj = nil) then Exit; // Если не сундук
  for Y := 0 to ChestHeight - 1 do
    for X := 0 to ChestWidth - 1 do
    begin
      Z := Y * ChestWidth + X;
      if (Z >= LookAtObj.ItemsCnt) then Continue;
      if (LookAtObj.Items[Z].Count = 0) then Continue;
      if not PC.CreateItem(LookAtObj.Items[Z].Pat,
        LookAtObj.Items[Z].Count, LookAtObj.Items[Z].Prop, Index) then
          Continue;
      LookAtObj.Items[Z].Count := 0;
      Play(ttSndPickup);
      PC.Calculator;
    end;
end;

{ TSceneInv }

constructor TSceneInv.Create(FramePos: TFramePos);
begin
  inherited;
end;

destructor TSceneInv.Destroy;
begin

  inherited;
end;

procedure TSceneInv.Render;
var
  I, J, X, Y, Z, P: Integer;
  S: TSlot;
  V: ansistring;
begin
  inherited;
  CraftTop := FrameTop + Span;
  // Doll
  J := 1;
  Render2D(Resource[ttDoll], Span + SlotSize, FrameTop + Span, Resource[ttDoll].Width, Resource[ttDoll].Height - 25, 0, 0);
  for S := slHead to slBoots do
    begin
      if (S <> slRHand) then RenderSprite2D(Resource[ttItemSlot], DollLeft + PC.SlotItem[S].Pos.X, DollTop + FrameTop + PC.SlotItem[S].Pos.Y, SlotSize, SlotSize, 0);
      if (S <> slRHand) and (PC.SlotItem[S].Item.Count > 0) then
      begin
        Item_Draw(@PC.SlotItem[S], DollLeft + PC.SlotItem[S].Pos.X,
          DollTop + FrameTop + PC.SlotItem[S].Pos.Y, PC.SlotItem[S].Item.Count, PC.SlotItem[S].Item.Prop, 1);
        if (S <> slRHand) then Inc(J);
      end else begin
        Render2D(Resource[ttIL], DollLeft + PC.SlotItem[S].Pos.X,
          DollTop + FrameTop + PC.SlotItem[S].Pos.Y, SlotSize, SlotSize, 0, J);
        if (S <> slRHand) then Inc(J);
      end;
    end;

  for S := slHead to slBoots do
    if (Drag.Item <> nil) then
      if (S <> slRHand) and (UpperCase(Drag.Item.Pat.Equip) = PC.SlotItem[S].Name) then
        Render2D(Resource[ttSellCell], DollLeft + PC.SlotItem[S].Pos.X - 15,
          DollTop + FrameTop + PC.SlotItem[S].Pos.Y - 15, 64, 64, 0, 2);

  // Craft
  for Y := 0 to 2 do for X := 0 to 2 do
    Render2D(Resource[ttItemSlot], InvLeft + (SlotSize * (X + 6)), CraftTop + (SlotSize * Y));
  Render2D(Resource[ttDnArrow], InvLeft + (SlotSize * 7), CraftTop + (SlotSize * 3));
  Render2D(Resource[ttItemSlot], InvLeft + (SlotSize * 7), CraftTop + (SlotSize * 4));

  // Inv
  for Y := 0 to InvHeight - 1 do
    for X := 0 to InvWidth - 1 do
    begin
      if (Y < InvHeight - 1) then P := 0 else P := Span;
      RenderSprite2D(Resource[ttItemSlot], InvLeft + X * SlotSize, InvTop + Y * SlotSize + P + FrameTop, SlotSize, SlotSize, 0);
      Z := Y * InvWidth + X;
      if (Z >= PC.ItemsCnt) then Continue;
      if (PC.Items[Z].Count = 0) then Continue;
      Item_Draw(@PC.Items[Z], InvLeft + X * SlotSize, InvTop + Y * SlotSize + P + FrameTop, PC.Items[Z].Count, PC.Items[Z].Prop, 1);
    end;
    if (Drag.Item <> nil) and (Drag.Item.Pat.Durability = 0) then
      for Y := 0 to InvHeight - 1 do
        for X := 0 to InvWidth - 1 do
        begin
          if (Y < InvHeight - 1) then P := 0 else P := Span;
          Z := Y * InvWidth + X;
          if (Z >= PC.ItemsCnt) then Continue;
          if (PC.Items[Z].Count = 0) then Continue;
          if (Drag.Item.Pat = PC.Items[Z].Pat) then
            RenderSprite2D(Resource[ttSellCell], InvLeft + X * SlotSize - 15, InvTop + Y * SlotSize + P + FrameTop - 15, 64, 64, 0);
        end;

  for I := 0 to InvWidth - 1 do
  begin
    if (I + 1 > 9) then V := '0' else V := IntToStr(I + 1);
    TextOut(Font[ttFont2], InvLeft + I * SlotSize + 3, (InvTop + Y * SlotSize + P + FrameTop) - 12, V);
  end;
  RenderSprite2D(Resource[ttNSellCell], InvLeft + (PCBelt.Slot * SlotSize) - 15, (InvTop + (Y - 1) * SlotSize + P + FrameTop) - 15, 64, 64, 0);

  // Chest
  if (LookAtObj <> nil) then
  begin
  for Y := 0 to ChestHeight - 1 do
    for X := 0 to ChestWidth - 1 do
    begin
      RenderSprite2D(Resource[ttItemSlot], ChestLeft + X * SlotSize, ChestTop + Y * SlotSize + FrameTop, SlotSize, SlotSize, 0);
      Z := Y * ChestWidth + X;
      if (Z >= LookAtObj.ItemsCnt) then Continue;
      if (LookAtObj.Items[Z].Count = 0) then Continue;
      Item_Draw(@LookAtObj.Items[Z], ChestLeft + X * SlotSize, ChestTop + Y * SlotSize + FrameTop, LookAtObj.Items[Z].Count, LookAtObj.Items[Z].Prop, 1);
    end;
  end;

  // Gold
  Render2D(Resource[ttGold], Span, FrameTop + FrameHeight - (Span + CharHeight), Resource[ttGold].Width, Resource[ttGold].Height, 0, 0);
  TextOut(Font[ttFont1], (Span * 2) + Resource[ttGold].Width, FrameTop + FrameHeight - (Span + CharHeight), 1, 0,
    'Золото ' + IntToStr(PC.ItemCount('GOLDCOIN')), 255, cDkYellow, TEXT_HALIGN_LEFT);

  if (Drag.Item <> nil) then Item_Draw(Drag.Item, GetMouse.X - 16, GetMouse.Y - 16, Drag.Count, Drag.Prop, 2);

  if IHint.Show then
  if (Drag.Item = nil) then
  begin
    HintBG(IHint.X, IHint.Y, IHint.W, IHint.H);
    for I := 0 to Length(IHint.Text) - 1 do
      TextOut(Font[ttFont1], IHint.X + IHint.W div 2, IHint.Y + (I * 15) + 10, 1, 0,
        IHint.Text[I], 255, IHint.Color[I], TEXT_HALIGN_CENTER);
  end;
end;

procedure TSceneInv.Update;
var
  X, Y, Z: Integer;
  S: TSlot;
begin
  inherited;
  // Mouse DblClick
  if (LookAtObj <> nil)then
  begin
    if (MouseDblClick(M_BLEFT)) and (Drag.Item <> nil) then
    begin
      if not PC.CreateItem(Drag.Item.Pat, Drag.Count, Drag.Prop, Z) then Exit;
      PlayItem(Drag.Item.Pat, Drag.Prop);
      ClearItemProp(Drag.Prop);
      Drag.Item := nil;
      Drag.Count := 0;
    end;
  end;
  // Doll
  for S := slHead to slBoots do
    if (S <> slRHand) and MouseInRect(DollLeft + PC.SlotItem[S].Pos.X, DollTop + FrameTop + PC.SlotItem[S].Pos.Y, SlotSize, SlotSize) then
    begin
      if MouseClick(M_BLEFT) then Item_UpdateSlot(@PC.SlotItem[S], PC.SlotItem[S].Name, 0, True);
      InitIHint(DollLeft + PC.SlotItem[S].Pos.X, DollTop + FrameTop + PC.SlotItem[S].Pos.Y, @PC.SlotItem[S]);
      IHint.Show := True;
    end;
  // Craft
  if MouseInRect(InvLeft + (SlotSize * 6), CraftTop, CraftGridSize, CraftGridSize) then
  begin
    X := (GetMouse.X - (InvLeft + (SlotSize * 6))) div SlotSize;
    Y := (GetMouse.Y - (Span + FrameTop)) div SlotSize;
    Z := Y * 3 + X;
    if MouseClick(M_BLEFT) then
    begin
      Box(Z);
    end;
  end;
  if MouseInRect(InvLeft + (SlotSize * 7), CraftTop + (SlotSize * 4), SlotSize, SlotSize) then
  begin
    if MouseClick(M_BLEFT) then
    begin
      Box();
    end;
  end;

  // Inv
  X := 0;
  Y := 0;
  Z := -1;
  if MouseInRect(InvLeft, InvTop + FrameTop, InvWidth * SlotSize, InvHeight * SlotSize) then
  begin
    X := (GetMouse.X - InvLeft) div SlotSize;
    Y := (GetMouse.Y - (InvTop + FrameTop)) div SlotSize;
    X := Clamp(X, 0, InvWidth - 1);
    Y := Clamp(Y, 0, InvHeight - 1);
    Z := Y * InvWidth + X;
    if (Z > InvCapacity - 1) then Z := InvCapacity - 1;
    if (Z <> -1) then IHint.Show := True;
  end;    

  // Chest
  if (LookAtObj <> nil) and (Drag.Item = nil) then
    if MouseClick(M_BLEFT) then
      if MouseInRect(ChestLeft, ChestTop + FrameTop, ChestWidth * SlotSize, ChestHeight * SlotSize) then
        BtnDwn := 0;  

  if (MouseClick(M_BLEFT)) and (Z <> -1) then Item_UpdateSlot(@PC.Items[Z], '', Z, True);
  if (MouseClick(M_BRIGHT)) and (Z <> -1) and (BtnDwn = 0) then Item_Use(@PC.Items[Z], PC);
  if (Z <> -1) then InitIHint(X * SlotSize + InvLeft, Y * SlotSize + InvTop + FrameTop, @PC.Items[Z]);
  if (Z = PCBelt.Slot + (InvCapacity - InvWidth)) then ChRHandItemInBelt;
  if not MouseDown(M_BLEFT) then BtnDwn := 0;

  //
  X := 0;   
  Y := 0;
  Z := -1;
  if (LookAtObj <> nil) and (BtnDwn = 0) then
    if MouseInRect(ChestLeft, ChestTop + FrameTop, ChestWidth * SlotSize, ChestHeight * SlotSize) then
    begin
      X := (GetMouse.X - ChestLeft) div SlotSize;
      Y := (GetMouse.Y - (ChestTop + FrameTop)) div SlotSize;
      X := Clamp(X, 0, ChestWidth - 1);
      Y := Clamp(Y, 0, ChestHeight - 1);
      Z := Y * ChestWidth + X;
      if (Z <> -1) then IHint.Show := True;
    end;

  if (MouseClick(M_BLEFT)) and (Z <> -1) then Item_UpdateSlot(@LookAtObj.Items[Z], '', Z);
  if (MouseClick(M_BRIGHT)) and (Z <> -1) and (BtnDwn = 0) then Item_Use(@LookAtObj.Items[Z], PC);
  if (Z <> -1) then InitIHint(X * SlotSize + ChestLeft, Y * SlotSize + ChestTop + FrameTop, @LookAtObj.Items[Z]);

  if (Drag.Item <> nil) then
  begin
{    if MouseClick(M_BRIGHT) then
    begin
      Drag.Item.Count := Drag.Item.Count + Drag.Count;
    //Drag.Item.Suffix := Drag.Suffix;
      Drag.Item  := nil;
    end; }
    if MouseWheel(M_WUP) then
      if (Drag.Item.Count > 0) then
      begin
        Drag.Count := Drag.Count + 1;
        Drag.Item.Count := Drag.Item.Count - 1;
      end;
    if MouseWheel(M_WDOWN) then
      if (Drag.Count > 1) then
      begin
        Drag.Count := Drag.Count - 1;
        Drag.Item.Count := Drag.Item.Count + 1;
      end;
  end;
end;

end.

