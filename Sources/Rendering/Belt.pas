unit Belt;

interface

type
  TBelt = class(TObject)
  private
    FSlot: Integer;
    procedure SetSlot(const Value: ShortInt);
    function GetSlot: ShortInt;
  public
    Top, Left: Integer;
    function MouseOver: Boolean;
    procedure Render;
    procedure Update;
    constructor Create;
    destructor Destroy; override;
    function GetLeft(I: Integer): Integer;
    property Slot: ShortInt read GetSlot write SetSlot;
    function ActSlot: ShortInt;
  end;

var
  PCBelt: TBelt;

implementation

uses gm_engine, SceneFrame, Resources, SysUtils, gm_creature, Hint, gm_item,
  Effect, Scenes;

{ TBelt }

function TBelt.ActSlot: ShortInt;
begin
  Result := (InvHeight - 1) * InvWidth + FSlot;
end;

constructor TBelt.Create;
begin
  Top := ScreenHeight - (SlotSize + Span);
  Left := (ScreenWidth div 2) - ((InvWidth * SlotSize) div 2);
end;

destructor TBelt.Destroy;
begin

  inherited;
end;

function TBelt.GetLeft(I: Integer): Integer;
begin
  Result := Left + (I * SlotSize);
end;

function TBelt.GetSlot: ShortInt;
begin
  Result := FSlot;
end;

function TBelt.MouseOver: Boolean;
begin
  Result := (GetMouse.X > Left) and (GetMouse.X < Left + (InvWidth * SlotSize)) and (GetMouse.Y > Top) and (GetMouse.Y < Top + SlotSize + Span) and not IsGate and not IsWorld;
end;

procedure TBelt.Render;
var
  I, P: Integer;
  S: ansistring;
begin
  Render2D(Resource[ttBack], Left - Span, ScreenHeight - (SlotSize + (Span * 2)), (InvWidth * SlotSize) + (Span * 2), ScreenHeight, 0, 0);
  for I := 0 to InvWidth - 1 do
  begin
    P := (InvHeight - 1) * InvWidth + I;
    RenderSprite2D(Resource[ttItemSlot], GetLeft(I), Top, SlotSize, SlotSize, 0);
    if (I >= PC.ItemsCnt) then Continue;
    if (PC.Items[P].Count = 0) then Continue;
    Item_Draw(@PC.Items[P], GetLeft(I), Top, PC.Items[P].Count, PC.Items[P].Prop, 1);
  end;
  for I := 0 to InvWidth - 1 do
  begin
    if (I + 1 > 9) then S := '0' else S := IntToStr(I + 1);
    TextOut(Font[ttFont2], GetLeft(I) + 3, ScreenHeight - (SlotSize + Span - 22), S);
  end;
  RenderSprite2D(Resource[ttSellCell], GetLeft(Slot) - 15, Top - 15, 64, 64, 0);
  Hint.Render;
end;

procedure TBelt.SetSlot(const Value: ShortInt);
begin
  FSlot := Value;
end;

procedure TBelt.Update;
var
  I, V: Integer;
begin
  if MouseOver then
  begin
    I := (GetMouse.X - ((ScreenWidth div 2) - (InvWidth * SlotSize) div 2)) div SlotSize;
    if (MouseClick(M_BLEFT)) then
    begin
      Slot := I;
      ChBIFlag := True;
    end;
    V := (InvHeight - 1) * InvWidth + I;
    if (PC.Items[V].Count > 0) then
    begin
      InitIHint((ScreenWidth div 2) - (InvWidth * SlotSize) div 2 + (I * SlotSize), Top, @PC.Items[V]);
      IHint.Show := True;
      if (MouseClick(M_BRIGHT)) then Item_Use(@PC.Items[V], PC);
    end;
  end;
end;

end.