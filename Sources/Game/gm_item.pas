unit gm_item;

interface

uses
  Classes, Types, gm_engine, gm_patterns, Resources;

const
  NeedManaStr =
    'Нужно больше маны!,Недостаточно маны!,Заклинание требует больше маны!';
  PortalManaCost = 7; // Цена маны за каждое прохождение в портал

const
  ITEM_AMP = 3;

type
  TItemProp = record
    Suffix: AnsiString;
    Material: AnsiString;
    Durability: Integer;
  end;

type
  PItem = ^TItem;

  TItem = record
    Pat: TItemPat;
    Count: Integer;
    Prop: TItemProp;
    Pos: TPoint;
    Top: Single;
    Dir: Boolean;
    Left: Byte;
  end;

type
  TDrag = record
    Item: PItem;
    Count: Integer;
    Prop: TItemProp;
  end;

var
  Drag: TDrag;

const
  RandItemCount = 14;

const
  clRed = $FF;
  clGreen = $8000;
  clBlue = $FFAAAA;
  clNavy = $FF0000;
  clGray = $808080;
  clPink = $F000F0;
  clPurple = $800080;
  clYellow = $E0FFFF;
  clBrown = $808008;
  clTeal = $808000;
  clDark = $111111;
  clLight = $AAAAAA;
  clBlack = $0;
  clWhite = $FFFFFF;

type
  TRandItemRec = record
    Name: AnsiString;
    Color: Integer;
    Defined: Integer;
  end;

type
  TRandItem = array [1 .. RandItemCount] of TRandItemRec;

type
  TName = record
    En, Ru: AnsiString;
  end;

const
  AllowedColors: array [1 .. RandItemCount] of Integer = (clRed, clGreen,
    clBlue, clNavy, clGray, clTeal, clBrown, clPink, clPurple, clYellow, clDark,
    clLight, clBlack, clWhite);

type
  TRandItems = class(TObject)
  private
    FCount: Byte;
    FF: TStringList;
    RandItem: TRandItem;
    procedure Gen;
    procedure Save;
    procedure Load;
    procedure Clear;
    function GenName: AnsiString;
    function GetText: AnsiString;
    procedure SetText(const Value: AnsiString);
    function IsThisColor(C: Integer): Boolean;
    function Name(En, Ru: AnsiString): TName;
  public
    constructor Create(ACount: Byte);
    destructor Destroy; override;
    property Text: AnsiString read GetText write SetText;
    property Count: Byte read FCount;
    function GetColor(Index: Integer): Integer;
    function GetColorName(Index: Integer): TName;
    function GetName(Index: Integer): AnsiString;
    function IsDefined(Index: Integer): Boolean;
    procedure SetDefined(Index: Integer);
    procedure LoadFromFile(const ZipFileName: AnsiString);
    procedure SaveToFile(const ZipFileName: AnsiString);
    function Title(Tag: Byte): AnsiString; virtual; abstract;
    procedure Use(Tag: Byte; UseCr: Pointer; F: Boolean = True);
      virtual; abstract;
  end;

const
  etAntidote = 1;
  etHeal = 2;
  etMana = 3;
  etBlacksmith = 4;
  etBlind = 5;
  etWeakness = 6;
  etAcid = 7;

const
  ElixirCount = 7;

type
  TElixir = class(TRandItems)
    constructor Create;
    function Title(Tag: Byte): AnsiString; override;
    procedure Use(Tag: Byte; UseCr: Pointer; F: Boolean = True); override;
  end;

var
  Elixir: TElixir;

const
  seHeal = 1;
  sePortal = 2;
  seIdentify = 3;
  seInvulabil = 4;
  seHypnosis = 5;
  seVamp = 6;
  seShLights = 7;
  seManaSh = 8;

const
  ScrollCount = 8;

type
  TScroll = class(TRandItems)
    constructor Create;
    function Title(Tag: Byte): AnsiString; override;
    procedure Use(Tag: Byte; UseCr: Pointer; F: Boolean = True); override;
  end;

var
  Scroll: TScroll;

type
  TItemProperty = (ipTitle, ipArmor, ipResFire, ipResCold, ipResElec,
    ipResPoison, ipDurability, ipRadius, ipDamPhysMin, ipDamPhysMax,
    ipDamPoisonMin, ipDamPoisonMax, ipDamFireMin, ipDamFireMax, ipDamColdMin,
    ipDamColdMax, ipDamElecMin, ipDamElecMax, ipStr, ipSta, ipDex, ipAgi, ipWis,
    ipInt, ipLife, ipMana, ipRefLife, ipRefMana);

procedure NeedManaMsg();
function GetRangedWeaponProjCat(Weapon: TCatEnum): TCatEnum;
function GetItemSoundResource(Category: TCatEnum): TSndEnum;
procedure PlayItem(Pat: TItemPat; Prop: TItemProp);

procedure AddItemProp(I: PItem);
procedure ClearItemProp(var Prop: TItemProp);
function GetItemProp(S, M: AnsiString; D: Integer): TItemProp; overload;
function GetItemProp(Item: PItem; W: TItemProperty): Integer; overload;

procedure Item_Draw(Item: PItem; X, Y, Cnt: Integer; Prop: TItemProp;
  CntPos: Byte; IsOnTile: Boolean = False);
procedure Item_UpdateSlot(Item: PItem; const Equip: AnsiString; CID: Word;
  F: Boolean = False);
procedure Item_Use(Item: PItem; UseCr: Pointer);

implementation

uses
  Math, gm_creature, gm_map, Utils, SysUtils, Spell, Digit,
  SceneFrame, SceneSkill, LibZip, Sound;

procedure AddItemProp(I: PItem);
begin
  I.Left := Math.RandomRange(0, 17);
  I.Top := Math.RandomRange(-ITEM_AMP, ITEM_AMP + 1);
  I.Dir := (Math.RandomRange(0, 2) = 0);
end;

procedure ClearItemProp(var Prop: TItemProp);
begin
  Prop.Suffix := '';
  Prop.Material := '';
  Prop.Durability := 0;
end;

function GetRangedWeaponProjCat(Weapon: TCatEnum): TCatEnum;
begin
  case Weapon of
    icBow:
      Result := icArrow;
    icCrossbow:
      Result := icBolt;
  end;
end;

function GetItemProp(S, M: AnsiString; D: Integer): TItemProp;
begin
  Result.Suffix := S;
  Result.Material := M;
  Result.Durability := D;
end;

function GetItemProp(Item: PItem; W: TItemProperty): Integer;
var
  M, S: Single;
  SufPat: TSuffixPat;
  MatPat: TMaterialPat;
begin
  Result := 0;
  SufPat := nil;
  SufPat := TSuffixPat(GetPattern('SUFFIX', Item.Prop.Suffix));
  MatPat := nil;
  MatPat := TMaterialPat(GetPattern('MATERIAL', Item.Prop.Material));
  case W of
    ipTitle:
      begin

      end;
    ipRadius:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Radius;
        Result := Clamp(Result, 0, 1);
      end;
    ipStr:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Bonus.Strength;
        Result := Result + Item.Pat.Bonus.Strength;
        Result := Clamp(Result, 0, 10);
      end;
    ipSta:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Bonus.Stamina;
        Result := Result + Item.Pat.Bonus.Stamina;
        Result := Clamp(Result, 0, 10);
      end;
    ipDex:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Bonus.Dexterity;
        Result := Result + Item.Pat.Bonus.Dexterity;
        Result := Clamp(Result, 0, 10);
      end;
    ipAgi:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Bonus.Agility;
        Result := Result + Item.Pat.Bonus.Agility;
        Result := Clamp(Result, 0, 10);
      end;
    ipWis:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Bonus.Wisdom;
        Result := Result + Item.Pat.Bonus.Wisdom;
        Result := Clamp(Result, 0, 10);
      end;
    ipInt:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Bonus.Intellect;
        Result := Result + Item.Pat.Bonus.Intellect;
        Result := Clamp(Result, 0, 10);
      end;
    ipLife:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Bonus.Life;
        Result := Result + Item.Pat.Bonus.Life;
        Result := Clamp(Result, 0, 1000);
      end;
    ipMana:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Bonus.Mana;
        Result := Result + Item.Pat.Bonus.Mana;
        Result := Clamp(Result, 0, 1000);
      end;
    ipRefLife:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Bonus.RefLife;
        Result := Result + Item.Pat.Bonus.RefLife;
        Result := Clamp(Result, 0, 1000);
      end;
    ipRefMana:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Bonus.RefMana;
        Result := Result + Item.Pat.Bonus.RefMana;
        Result := Clamp(Result, 0, 1000);
      end;
    ipDamPhysMin:
      begin
        M := 1;
        S := 1;
        if (MatPat <> nil) then
          M := MatPat.DamPhys.Min;
        if (SufPat <> nil) then
          S := SufPat.DamPhys.Min;
        Result := Round(Item.Pat.Damage.Phys.Min * M * S);
        Result := Clamp(Result, 0, 1000);
      end;
    ipDamPhysMax:
      begin
        M := 1;
        S := 1;
        if (MatPat <> nil) then
          M := MatPat.DamPhys.Max;
        if (SufPat <> nil) then
          S := SufPat.DamPhys.Max;
        Result := Round(Item.Pat.Damage.Phys.Max * M * S);
        Result := Clamp(Result, 0, 1000);
      end;
    ipDamPoisonMin:
      begin
        M := 1;
        S := 1;
        if (MatPat <> nil) then
          M := MatPat.DamPoison.Min;
        if (SufPat <> nil) then
          S := SufPat.DamPoison.Min;
        Result := Round(Item.Pat.Damage.Poison.Min * M * S);
        Result := Clamp(Result, 0, 1000);
      end;
    ipDamPoisonMax:
      begin
        M := 1;
        S := 1;
        if (MatPat <> nil) then
          M := MatPat.DamPoison.Max;
        if (SufPat <> nil) then
          S := SufPat.DamPoison.Max;
        Result := Round(Item.Pat.Damage.Poison.Max * M * S);
        Result := Clamp(Result, 0, 1000);
      end;
    ipDamFireMin:
      begin
        M := 1;
        S := 1;
        if (MatPat <> nil) then
          M := MatPat.DamFire.Min;
        if (SufPat <> nil) then
          S := SufPat.DamFire.Min;
        Result := Round(Item.Pat.Damage.Fire.Min * M * S);
        Result := Clamp(Result, 0, 1000);
      end;
    ipDamFireMax:
      begin
        M := 1;
        S := 1;
        if (MatPat <> nil) then
          M := MatPat.DamFire.Max;
        if (SufPat <> nil) then
          S := SufPat.DamFire.Max;
        Result := Round(Item.Pat.Damage.Fire.Max * M * S);
        Result := Clamp(Result, 0, 1000);
      end;
    ipDamColdMin:
      begin
        M := 1;
        S := 1;
        if (MatPat <> nil) then
          M := MatPat.DamCold.Min;
        if (SufPat <> nil) then
          S := SufPat.DamCold.Min;
        Result := Round(Item.Pat.Damage.Cold.Min * M * S);
        Result := Clamp(Result, 0, 1000);
      end;
    ipDamColdMax:
      begin
        M := 1;
        S := 1;
        if (MatPat <> nil) then
          M := MatPat.DamCold.Max;
        if (SufPat <> nil) then
          S := SufPat.DamCold.Max;
        Result := Round(Item.Pat.Damage.Cold.Max * M * S);
        Result := Clamp(Result, 0, 1000);
      end;
    ipDamElecMin:
      begin
        M := 1;
        S := 1;
        if (MatPat <> nil) then
          M := MatPat.DamElec.Min;
        if (SufPat <> nil) then
          S := SufPat.DamElec.Min;
        Result := Round(Item.Pat.Damage.Elec.Min * M * S);
        Result := Clamp(Result, 0, 1000);
      end;
    ipDamElecMax:
      begin
        M := 1;
        S := 1;
        if (MatPat <> nil) then
          M := MatPat.DamElec.Max;
        if (SufPat <> nil) then
          S := SufPat.DamElec.Max;
        Result := Round(Item.Pat.Damage.Elec.Max * M * S);
        Result := Clamp(Result, 0, 1000);
      end;
    ipArmor:
      begin
        M := 1;
        S := 1;
        if (MatPat <> nil) then
          M := MatPat.Armor;
        if (SufPat <> nil) then
          S := SufPat.Armor;
        Result := Round(Item.Pat.Armor * M * S);
        Result := Clamp(Result, 0, 1000);
      end;
    ipResFire:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Bonus.ResFire;
        Result := Result + Item.Pat.Bonus.ResFire;
        Result := Clamp(Result, 0, 100);
      end;
    ipResCold:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Bonus.ResCold;
        Result := Result + Item.Pat.Bonus.ResCold;
        Result := Clamp(Result, 0, 100);
      end;
    ipResElec:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Bonus.ResElec;
        Result := Result + Item.Pat.Bonus.ResElec;
        Result := Clamp(Result, 0, 100);
      end;
    ipResPoison:
      begin
        Result := 0;
        if (SufPat <> nil) then
          Result := SufPat.Bonus.ResPoison;
        Result := Result + Item.Pat.Bonus.ResPoison;
        Result := Clamp(Result, 0, 100);
      end;
    ipDurability:
      begin
        M := 1;
        S := 1;
        if (MatPat <> nil) then
          M := MatPat.Durability;
        if (SufPat <> nil) then
          S := SufPat.Durability;
        Result := Round(Item.Pat.Durability * M * S);
        if (Result < 0) then
          Result := 0;
        if (Item.Prop.Durability > Result) then
          Item.Prop.Durability := Result;
        Result := Clamp(Result, 0, 1000);
      end;
  end;
  if (Result < 0) then
    Result := 0;
end;

{ TRandItems }

function TRandItems.GetColorName(Index: Integer): TName;
begin
  Result := Name('', '');
  case GetColor(Index) of
    clRed:
      Result := Name('Red', 'Красный');
    clGreen:
      Result := Name('Green', 'Зеленый');
    clBlue:
      Result := Name('Blue', 'Голубой');
    clNavy:
      Result := Name('Navy', 'Синий');
    clGray:
      Result := Name('Gray', 'Серый');
    clPink:
      Result := Name('Pink', 'Розовый');
    clPurple:
      Result := Name('Purple', 'Пурпурный');
    clYellow:
      Result := Name('Yellow', 'Желтый');
    clBrown:
      Result := Name('Brown', 'Коричневый');
    clTeal:
      Result := Name('Teal', 'Малахитовый');
    clDark:
      Result := Name('Dark', 'Темный');
    clLight:
      Result := Name('Light', 'Светлый');
    clBlack:
      Result := Name('Black', 'Черный');
    clWhite:
      Result := Name('White', 'Белый');
  end;
end;

procedure TRandItems.Clear;
var
  I: Byte;
begin
  for I := 1 to RandItemCount do
    with RandItem[I] do
    begin
      Defined := 0;
      Color := -1;
      Name := '';
    end;
end;

constructor TRandItems.Create(ACount: Byte);
begin
  FF := TStringList.Create;
  FCount := ACount;
  Self.Gen;
end;

destructor TRandItems.Destroy;
begin
  FF.Free;
  FF := nil;
  inherited;
end;

function TRandItems.IsThisColor(C: Integer): Boolean;
var
  I: Byte;
begin
  Result := False;
  for I := 1 to Count do
    if (RandItem[I].Color = C) then
    begin
      Result := True;
      Exit;
    end;
end;

procedure TRandItems.Gen;
var
  I, C: Integer;
begin
  Clear;
  for I := 1 to Count do
  begin
    repeat
      C := AllowedColors[Math.RandomRange(0, RandItemCount) + 1];
    until not IsThisColor(C);
    with RandItem[I] do
    begin
      Name := GenName;
      Defined := 0;
      Color := C;
    end;
  end;
end;

function TRandItems.GenName: AnsiString;
const
  S = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
var
  I: Byte;
begin
  Result := '';
  for I := 1 to 7 do
    Result := Result + S[Math.RandomRange(0, 26) + 1];
end;

function TRandItems.GetColor(Index: Integer): Integer;
begin
  Result := RandItem[Index].Color;
end;

function TRandItems.GetName(Index: Integer): AnsiString;
begin
  Result := RandItem[Index].Name;
end;

function TRandItems.GetText: AnsiString;
begin
  Self.Save;
  Result := AnsiString(FF.Text);
end;

function TRandItems.IsDefined(Index: Integer): Boolean;
begin
  Result := RandItem[Index].Defined = 1;
end;

procedure TRandItems.SetDefined(Index: Integer);
begin
  RandItem[Index].Defined := 1;
end;

procedure TRandItems.Load;
var
  I, P: Integer;
  E: TExplodeResult;
begin
  Clear;
  P := 1;
  E := nil;
  for I := 0 to FF.Count - 1 do
  begin
    E := Explode('/', FF[I]);
    if (Trim(E[0]) <> '') then
      with RandItem[P] do
      begin
        Name := E[0];
        Color := StrToInt(E[1]);
        Defined := StrToInt(E[2]);
      end;
    Inc(P);
  end;
end;

procedure TRandItems.Save;
var
  I: Byte;
begin
  FF.Clear;
  for I := 1 to Count do
    with RandItem[I] do
      FF.Append(Format('%s/%d/%d', [Name, Color, Defined]));
end;

procedure TRandItems.SetText(const Value: AnsiString);
begin
  FF.Text := string(Value);
  Self.Load;
end;

function TRandItems.Name(En, Ru: AnsiString): TName;
begin
  Result.En := En;
  Result.Ru := Ru;
end;

procedure Item_Draw(Item: PItem; X, Y, Cnt: Integer; Prop: TItemProp;
  CntPos: Byte; IsOnTile: Boolean = False);
var
  P: TPoint;
  S, T: Byte;
  I: Integer;
label nn;
begin
  T := 0;
  P := Point(0, 0);
  if IsOnTile then
  begin
    S := 16;
    T := 16;
    X := X + Item.Left;
    Y := Y + Round(Item.Top) - ITEM_AMP;
  end
  else
  begin
    S := 32;
    if (Prop.Suffix <> '') and (Prop.Suffix <> 'DAMAGED') and
      (Prop.Suffix <> 'SUPERIOR') then
    begin
      if ((Item.Pat.Durability > 0) and (Prop.Durability <= 0)) then
        goto nn;
      RenderSprite2D(Resource[ttBackGoldItem], X, Y, SlotSize,
        SlotSize, 0, 100);
    end;
  nn:
    if (Item.Pat.Category = icElixir) then
      if not Elixir.IsDefined(Item.Pat.EffectTag) then
        RenderSprite2D(Resource[ttBackRedItem], X, Y, SlotSize,
          SlotSize, 0, 100)
      else
        RenderSprite2D(Resource[ttBackGreenItem], X, Y, SlotSize,
          SlotSize, 0, 100);
    if (Item.Pat.Category = icScroll) then
      if not Scroll.IsDefined(Item.Pat.EffectTag) then
        RenderSprite2D(Resource[ttBackRedItem], X, Y, SlotSize,
          SlotSize, 0, 100)
      else
        RenderSprite2D(Resource[ttBackBlueItem], X, Y, SlotSize,
          SlotSize, 0, 100);
    if ((Item.Pat.Durability > 0) and (Prop.Durability <= 0)) then
      RenderSprite2D(Resource[ttBackRedItem], X, Y, SlotSize, SlotSize, 0, 100);
  end;
  Render2D(Item.Pat.Tex, X, T + Y, S, S, 0, 1);

  if not IsOnTile and not Item.Pat.CanGroup and (Item.Pat.Durability > 0) then
    DrawMBar(Item.Prop.Durability, GetItemProp(Item, ipDurability), X + 16,
      T + Y + 28, 16, cDkYellow);
  if (CntPos = 0) then
    Exit;
  if (CntPos = 2) then
    P.Y := 15;
  if (Cnt > 9) then
    P.X := (Length(IntToStr(Cnt)) - 1) * 6;
  if (Cnt > 1) then
    TextOut(Font[ttFont2], X + 25 - P.X, Y + 22 - P.Y, IntToStr(Cnt));
  if (Item.Pat.Category = icSkill) and
    Item.Pat.Active { and PC.HasEffect(Item.Pat.Name) } then
  begin
    Rect2D(X, Y, SkillIconSize, SkillIconSize, $333333, 160, PR2D_FILL);
    // Rect2D(X, Y, SkillIconSize, BarWidth(PC.TimeEffect(Item.Pat.Name),
    // Item.Pat.Cooldown, SkillIconSize), $432323, 160, PR2D_FILL);
  end;
end;

function GetItemSoundResource(Category: TCatEnum): TSndEnum;
begin
  case Category of
    icJewelry:
      Result := ttSndGem;
    icAmulet:
      Result := ttSndAmulet;
    icRing:
      Result := ttSndRing;
    icArrow, icBolt:
      Result := ttSndProj;
    icScroll:
      Result := ttSndScroll;
    icElixir:
      Result := ttSndElixir;
    icCoins:
      Result := ttSndCoins;
    icKey:
      Result := ttSndKey;
  else
    Result := ttSndPickup;
  end;
end;

procedure PlayItem(Pat: TItemPat; Prop: TItemProp);
var
  S: TSndEnum;
  MatPat: TMaterialPat;
begin
  S := GetItemSoundResource(Pat.Category);
  if (S = ttSndPickup) and (Pat.Category in MaterialPCategories) then
  begin
    MatPat := TMaterialPat(GetPattern('MATERIAL', Prop.Material));
    if (MatPat = nil) then
      Exit;
    if (MatPat.Sound <> nil) then
      PlaySound(MatPat.Sound);
    Exit;
  end;
  Play(S);
end;

procedure Item_UpdateSlot(Item: PItem; const Equip: AnsiString; CID: Word;
  F: Boolean = False);
var
  Pat: TItemPat;
  P: TItemProp;
  I: Integer;
  Tag: Byte;

  procedure UpdateDragItemCount();
  begin
    Dec(Drag.Count);
    if (Drag.Count <= 0) then
      Drag.Item := nil;
    PC.Calculator;
  end;

  procedure Update(Item: PItem; B: Boolean = False);
  begin
    if F then
      PC.Calculator;
    if B then
      Play(ttSndPickup)
    else
      PlayItem(Item.Pat, Item.Prop);
  end;

begin
  if (Drag.Item = nil) and (Item.Count > 0) then
  begin
    Drag.Item := Item;
    Drag.Count := Drag.Item.Count;
    Drag.Prop := Item.Prop;
    if KeyDown(K_CTRL) or KeyDown(K_SHIFT) then
      Drag.Count := 1;
    Dec(Drag.Item.Count, Drag.Count);
    Update(Drag.Item, True);
    Exit;
  end;

  if (Drag.Item <> nil) then
  begin
    if (Equip <> '') then
      if (Drag.Item.Pat.Equip <> Equip) then
        Exit;

    if (Drag.Item.Pat.Category = icSkill) then
    begin
      if ((CID < InvWidth * (InvHeight - 1)) or (CID > InvWidth * InvHeight))
      then
        Exit;
      if not Drag.Item.Pat.Active then
      begin
        Drag.Item := nil;
        Exit;
      end;
    end;

    if (Item.Count = 0) then
    begin
      // Put item in empty slot
      if (Drag.Item.Pat.Category = icSkill) and (PC.HasItem(Drag.Item.Pat, 1))
      then
        PC.DelItem(Drag.Item.Pat, 1);
      Item.Pat := Drag.Item.Pat;
      Inc(Item.Count, Drag.Count);
      Item.Prop := Drag.Prop;
      Drag.Item := nil;
      Update(Item);
      Exit;
    end;

    if (Item.Count > 0) and (Drag.Item.Pat = Item.Pat) and
      (Drag.Item.Pat.CanGroup) then
    begin
      if KeyDown(K_CTRL) or KeyDown(K_SHIFT) then
      begin
        Inc(Drag.Count);
        Dec(Item.Count);
        ClearItemProp(Drag.Prop);
        Drag.Item := Item;
      end
      else
      begin
        Inc(Item.Count, Drag.Count);
        ClearItemProp(Item.Prop);
        Drag.Item := nil;
      end;
      Update(Item);
      Exit;
    end;
    if (Item.Count > 0) and ((Drag.Item.Pat <> Item.Pat) or
      (Drag.Item.Pat.CanGroup = False)) then
      if (Drag.Item.Count = 0) then
      begin
        // Use blacksmith oil
        Tag := etBlacksmith;
        if (Drag.Item.Pat.Category = icElixir) and
          (Item.Prop.Durability < GetItemProp(Item, ipDurability)) and
          (Drag.Item.Pat.EffectTag = Tag) and Elixir.IsDefined(Tag) then
        begin
          Item.Prop.Durability := GetItemProp(Item, ipDurability);
          UpdateDragItemCount();
          PC.DelEffect(efRust);
          if (Math.RandomRange(1, 5) = 1) then
            PC.AddEffect(efPoison, 20);
          Play(ttSndSmith);
          Play(ttSndBubble);
          Exit;
        end;
        // Use scroll of identify
        Tag := seIdentify;
        if (Drag.Item.Pat.Category = icScroll) and
          (Drag.Item.Pat.EffectTag = Tag) and Scroll.IsDefined(Tag) and
          (Item.Pat.Category in ConsumableCategories) then
        begin
          Tag := Item.Pat.EffectTag;
          with Elixir do
            if (Item.Pat.Category = icElixir) then
            begin
              if IsDefined(Tag) then
                Exit;
              SetDefined(Tag);
              PC.Info(Title(Tag), False, False);
            end;
          with Scroll do
            if (Item.Pat.Category = icScroll) then
            begin
              if IsDefined(Tag) then
                Exit;
              SetDefined(Tag);
              PC.Info(Title(Tag), False, False);
            end;
          Play(ttSndDefine);
          UpdateDragItemCount();
          Exit;
        end;
        // Replace item
        Pat := Drag.Item.Pat;
        I := Drag.Count;
        P := Drag.Prop;
        Drag.Item.Pat := Item.Pat;
        Drag.Count := Item.Count;
        Drag.Prop := Item.Prop;
        Item.Pat := Pat;
        Item.Count := I;
        Item.Prop := P;
        Update(Item);
        Update(Drag.Item);
        Exit;
      end;
  end;
end;

procedure NeedManaMsg;
begin
  PC.Info(RandStr(',', NeedManaStr), False, False);
  Play(ttSndNoMana);
end;

procedure Item_Use(Item: PItem; UseCr: Pointer);
var
  P: TPoint;
  I, J, K, T: Integer;
  Cr, Cr2: TCreature;
  Bool: Boolean;
begin
  if (Item.Count = 0) then
    Exit;
  if (Drag.Item <> nil) then
    Exit;
  Cr := TCreature(UseCr);

  if (Item.Pat.Category = icSkill) then
  begin
    Cr.UseSkill(Item.Pat.SkillTag, Item);
    Exit;
  end;

  if (Item.Pat.Category = icElixir) then
  begin
    Elixir.Use(Item.Pat.EffectTag, Cr);
    Dec(Item.Count);
  end;

  if (Item.Pat.Category = icScroll) then
  begin
    if (Cr.Mana.Cur >= Item.Pat.ManaCost) then
    begin
      Scroll.Use(Item.Pat.EffectTag, Cr);
      Cr.Mana.Dec(Item.Pat.ManaCost);
      Dec(Item.Count);
    end
    else
      NeedManaMsg;
  end;
end;

procedure TRandItems.LoadFromFile(const ZipFileName: AnsiString);
var
  S, C: AnsiString;
  E: TStringList;
begin
  E := TStringList.Create;
  try
    C := Copy(Self.ClassName, 2, Length(Self.ClassName));
    if LibZip.FileExists(ZipFileName, C) then
    begin
      S := LibZip.Load(ZipFileName, C);
      Text := S;
    end;
  finally
    E.Free;
  end;
end;

procedure TRandItems.SaveToFile(const ZipFileName: AnsiString);
var
  C: AnsiString;
  E: TStringList;
begin
  E := TStringList.Create;
  try
    C := Copy(Self.ClassName, 2, Length(Self.ClassName));
    E.Text := Text;
    LibZip.Save(ZipFileName, C, E.Text)
  finally
    E.Free;
  end;
end;

{ TElixir }

constructor TElixir.Create;
begin
  inherited Create(ElixirCount);
end;

function TElixir.Title(Tag: Byte): AnsiString;
begin
  Result := '';
  case Tag of
    etAntidote:
      Result := 'Противоядие';
    etHeal:
      Result := 'Целительный Эликсир';
    etMana:
      Result := 'Магический Эликсир';
    etBlacksmith:
      Result := 'Кузнечное Масло';
    etBlind:
      Result := 'Снадобье Василиска';
    etWeakness:
      Result := 'Зелье Слабости';
    etAcid:
      Result := 'Кислотное Зелье';
  end;
end;

procedure TElixir.Use(Tag: Byte; UseCr: Pointer; F: Boolean = True);
var
  C: TCreature;
begin
  if (Tag <= 0) then
    Exit;
  Play(ttSndUseElixir);
  C := TCreature(UseCr);
  case Tag of
    etAntidote:
      begin
        C.DelEffect(efPoison);
        C.AddEffect(efResPoison, 21); { ? }
      end;
    etHeal:
      begin
        C.Life.Inc(25);
        Digit.Add(C.Pos.X, C.Pos.Y, '25', $88FFFF);
      end;
    etMana:
      begin
        C.Mana.Inc(25);
        Digit.Add(C.Pos.X, C.Pos.Y, '25', $5555FF);
      end;
    etBlacksmith:
      begin
        if not C.HasEffect(efResPoison) then
          C.AddEffect(efPoison, 99);
      end;
    etBlind:
      begin
        C.AddEffect(efBlindness, 33);
        PC.Calculator;
      end;
    etWeakness:
      begin
        C.AddEffect(efWeakness, 99);
      end;
    etAcid:
      begin
        C.AddEffect(efRust, 25);
        if not C.HasEffect(efResPoison) then
          C.AddEffect(efPoison, 25);
      end;
  end;
  if not IsDefined(Tag) then
  begin
    SetDefined(Tag);
    PC.Info(Title(Tag), False, False);
    Play(ttSndDefine);
  end;
end;

{ TScroll }

constructor TScroll.Create;
begin
  inherited Create(ScrollCount);
end;

function TScroll.Title(Tag: Byte): AnsiString;
begin
  Result := '';
  case Tag of
    seHeal:
      Result := 'Молитва';
    sePortal:
      Result := 'Портал';
    seIdentify:
      Result := 'Определение';
    seInvulabil:
      Result := 'Неуязвимость';
    seHypnosis:
      Result := 'Гипноз';
    seVamp:
      Result := 'Вампиризм';
    seShLights:
      Result := 'Свет';
    seManaSh:
      Result := 'Щит Маны';
  end;
end;

procedure TScroll.Use(Tag: Byte; UseCr: Pointer; F: Boolean = True);
var
  C: TCreature;
  ObjPat: TObjPat;
  P: TPoint;
  M: TMap;
begin
  if (Tag <= 0) then
    Exit;
  Play(ttSndUseScroll);
  C := TCreature(UseCr);
  M := TMap(C.MP);
  P.X := Round(GetMouse.X + Cam.X);
  P.Y := Round(GetMouse.Y + Cam.Y);
  if (P.X > 0) and (P.Y > 0) then
  begin
    P.X := P.X div 32;
    P.Y := P.Y div 32;
    if (P.X >= Map.Width) or (P.Y >= Map.Height) then
      P.X := -1;
  end
  else
    P.X := -1;
  case Tag of
    seHeal:
      begin
        C.Life.SetToMax;
      end;
    sePortal:
      begin
        ObjPat := TObjPat(GetPattern('OBJECT', 'PORTAL'));
        M.Objects.ObjCreate(C.Pos.X, C.Pos.Y, ObjPat);
        Play(ttSndOpenPortal);
      end;
    seIdentify:
      begin
        // Identify scroll
      end;
    seInvulabil:
      begin
        C.AddEffect(efInvulnerability, 11);
      end;
    seHypnosis:
      begin
        FlagScroll := efHypnosis;
      end;
    seVamp:
      begin
        C.AddEffect(efVampirism, 26);
      end;
    seShLights:
      begin
        C.DelEffect(efBlindness);
        C.AddEffect(efLight, 31);
      end;
    seManaSh:
      begin
        C.AddEffect(efManaShield, 36);
      end;
  end;
  if not IsDefined(Tag) then
  begin
    SetDefined(Tag);
    PC.Info(Title(Tag), False, False);
    Play(ttSndDefine);
  end;
  // FlagScroll := 'Огненный шар';
  // FlagScroll := 'Заморозка';
  // FlagScroll := 'Вызов голема';
end;

end.
