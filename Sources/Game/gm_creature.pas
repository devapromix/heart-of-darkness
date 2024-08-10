unit gm_creature;

interface

uses
  Classes, Math, Types, gm_engine, gm_patterns, gm_item, gm_obj, Spell, Entity,
  CustomCreature, TimeVars;   

var
  FlagBlood        : Word = 0;
  FlagPoison       : Word = 0;
  FlagPrayer       : Word = 0;
  FlagScroll       : TEfEnum;

procedure ClearDamage(var Damage: TDamage);
procedure MultDamage(var Damage: TDamage; Value: Word);

type
  TSlotRec = record
    Item: TItem;
    Name: AnsiString;
    Pos: TPoint;
  end;

type
  TSlot = (slHead, slAmulet, slBody, slCloak, slRing1, slRing2, slGloves, slRHand, slLHand, slBelt, slBoots);

type
  TCreature = class(TCustomCreature)
  private
    NextStep  : TPoint;
    procedure Hit(Dam: TDamage; Flag: Boolean = True; Cr: TCreature = nil);
  public
    Pat       : TCrPat;
    MP        : Pointer;
    Sp        : TPoint;
    WalkTo    : TPoint;
    AtT       : Integer;
    Team      : Integer;
    Enemy     : TCreature;
    InFog     : Boolean;
    NoAtack   : Boolean;
    LifeTime  : Integer;
    Spells    : array of TSpell;
    SpellsCnt : Integer;
    SpellName : AnsiString;
    UseSpellN : Integer;
    Effects   : array of TSpell;
    EffectsCnt: Integer;
    ParamValue: array of Integer;
    Items     : array of TItem;
    ItemsCnt  : Integer;
    Moved     : Boolean;
    SlotItem  : array [TSlot] of TSlotRec;
    GMapPos   : TPoint;
    SpellPower: Integer;
    RefMana   : Integer;
    RefLife   : Integer;
    ETV       : TTimeVars;
    constructor Create(CrPat: TCrPat);
    destructor Destroy; override;
    procedure Draw;
    procedure Update;
    function GetDamageInfo: AnsiString;
    procedure Walk(dx, dy: Integer);
    function CreateItem(ItemPat: TItemPat; Count: Integer; Prop: TItemProp; var Index: Integer): Boolean;
    function HasItem(ItemPat: TItemPat; Count: Integer): Boolean;
    function ItemCount(ItemName: AnsiString): Integer;
    function AddItem(ItemPat: TItemPat; Count: Integer): Boolean; overload;
    function AddItem(ItemName: AnsiString; Count: Integer): Boolean; overload;
    function DelItem(ItemPat: TItemPat; Count: Integer): Boolean; overload;
    function DelItem(ItemName: AnsiString; Count: Integer = 1): Boolean; overload;
    function GetParamValue(Title: AnsiString): Integer;
    procedure SetParamValue(Title: AnsiString; Value: Integer);
    procedure AddExp(ExpCnt: Integer);
    procedure Loot;
    procedure ReFill;
    procedure WalkAway(tx1, ty1: Integer);
    procedure UseSkill(Tag: Byte; Item: PItem);
    procedure AddSpell(SpellName: AnsiString);
    procedure UseSpell(SpellN: Integer);
    procedure Calculator;
    procedure AddEffect(E: TEfEnum; Time: Integer);
    procedure DelEffect(E: TEfEnum);
    function HasEffect(E: TEfEnum): Boolean;
    function TimeEffect(E: TEfEnum): Word;
    function SkillCount: Byte;
    function HasSkill(SkillName: AnsiString): Boolean;
    function GetSkillName(I: Byte): AnsiString;
    procedure Combat(Dmg: TDamage; Cr: TCreature; Pat: TItemPat = nil);
    function GetRadius: Byte;
    function GetRes(Dmg: TDamType): Word;
    procedure UpdateEffects;
    procedure RandEquip;
    procedure DamageItem(S: TSlot);
    procedure DamageWeapon;
    procedure SetCam;
    function GetRandArmorSlot: TSlot;
    function IsRangedWpn(Weapon: TCatEnum): Boolean;
    procedure Rest;
    function DoSpell(Name, PatID: AnsiString): Boolean;
end;

  TPC = class(TCreature)
  private
  public
    procedure Calculator;
    procedure Info(Text: AnsiString; B: Boolean = False; S: Boolean = True);
    procedure LoadFromFile(const ZipFileName: AnsiString);
    procedure SaveToFile(const ZipFileName: AnsiString);
    procedure LoadSlots(const ZipFileName: AnsiString);
    procedure SaveSlots(const ZipFileName: AnsiString);
    procedure LoadItems(const ZipFileName: AnsiString);
    procedure SaveItems(const ZipFileName: AnsiString);
    procedure LoadEffects(const ZipFileName: AnsiString);
    procedure SaveEffects(const ZipFileName: AnsiString);
  end;

  TNPC = class(TCreature)

  end;

var
  PC: TPC;

implementation

uses
  SysUtils, gm_map, PathFind, Utils, Resources, Stat, SceneFrame, Digit, 
  gm_generator, SceneGame, Scenes, Sound, LibZip, Bar, Belt, GlobalMap, StrUtils;

procedure ClearDamage(var Damage: TDamage);
var
  I: TDamType;
begin
  for I := Low(TDamType) to High(TDamType) do
  begin
    Damage[I].Min := 0;
    Damage[I].Max := 0;
  end;
end;

procedure MultDamage(var Damage: TDamage; Value: Word);
var
  I: TDamType;
begin
  for I := Low(TDamType) to High(TDamType) do
    if (Damage[I].Min > 0) then
    begin
      Damage[I].Min := Damage[I].Min * Value;
      Damage[I].Max := Damage[I].Max * Value;
      Damage[I].Min := Clamp(Damage[I].Min, 1, 1000);
      Damage[I].Max := Clamp(Damage[I].Max, 1, 1000);
    end else begin
      Damage[I].Min := 0;
      Damage[I].Max := 0;
    end;
end;

{ TCreature }

procedure TPC.Info(Text: AnsiString; B: Boolean = False; S: Boolean = True);
begin
  if (Text = '') or not IsGame then Exit;
  if B then
    DrawText(ScreenWidth div 2, ScreenHeight - 60, Text)
      else begin
        DrawText(ScreenWidth div 2, ScreenHeight div 2 - 32, Text);
        if S then Play(ttSndInfo);
      end;
end;

constructor TCreature.Create(CrPat: TCrPat);
var
  I: Integer;
  P: TPoint;
  S: TSlot;
  N: AnsiString;

  procedure AddSlot(S: TSlot; V: AnsiString; P: TPoint);
  begin
    if (V = '') then Exit;
    SlotItem[S].Name := V;
    SlotItem[S].Pos := P;
  end;

begin
  inherited Create(1, 1);
  Pat        := CrPat;
  SpellName  := '';       
  ETV := TTimeVars.Create;
  WalkTo.X   := -1;
  NoAtack    := True;
  SpellsCnt  := 0;
  EffectsCnt := 0;
  LifeTime   := 0;
  RefLife    := 0;
  RefMana    := 0;
  SpellPower := 0;
  SetLength(ParamValue, CrStatsCnt);
  for I := 0 to CrStatsCnt - 1 do ParamValue[i] := Pat.ParamValue[i];
  ItemsCnt := 0;
  //
  P := Point(0, 0);
  for S := slHead to slBoots do
  begin
    N := '';
    case S of
      slBody   : N := 'BODY';
      slHead   : N := 'HEAD';
      slBelt   : N := 'BELT';
      slBoots  : N := 'BOOTS';
      slGloves : N := 'GLOVES';
      slAmulet : N := 'AMULET';
      slCloak  : N := 'CLOAK';
      slRHand  : N := 'RHAND';
      slLHand  : N := 'LHAND';
      slRing1  : N := 'RING';
      slRing2  : N := 'RING';
    end;
    AddSlot(S, N, P);
    SlotItem[S].Pos := P;
    if (S = slRHand) then Continue;
    Inc(P.X, (4 * SlotSize));
    if (P.X > (4 * SlotSize)) then
    begin
      Inc(P.Y, SlotSize);
      P.X := 0;
    end;
  end;
end;

destructor TCreature.Destroy;
begin
  FreeAndNil(ETV);
  inherited;
end;

procedure TCreature.Draw;
var
  S: TSlot;
  I: Integer;
  Tex: TTexture;

  function IsItem(S: TSlot): Boolean;
  begin
    with SlotItem[S].Item do Result := (Count > 0) and (Prop.Durability > 0);
  end;

  procedure RenderItem(S: TSlot);
  begin
    if IsItem(S) then
      Render2D(SlotItem[S].Item.Pat.Tex, Pos.X * 32 + Sp.X,
        Pos.Y * 32 + Sp.Y, 32, 32, 0, 2);
  end;

begin
  // Cloak
  RenderItem(slCloak);
  // Creature
  RenderSprite2D(Pat.Tex, Pos.X * 32 + Sp.X + Pat.Offset.X, Pos.Y * 32 + Sp.Y + Pat.Offset.Y, Pat.Tex.Width, Pat.Tex.Height, 0);

  for S := slHead to slBoots do
    if (S <> slCloak) and (S <> slBody) and IsItem(S) then
    begin
      Tex := SlotItem[S].Item.Pat.Tex;
      if (Tex.Width > 32) then
        Render2D(Tex, Pos.X * 32 + Sp.X, Pos.Y * 32 + Sp.Y, 32, 32, 0, 2);
    end;
  // Body
  RenderItem(slBody);

  if HasEffect(efFreezing) then RenderSprite2D(Resource[ttIce], Pos.X * 32, Pos.Y * 32, 32, 32, 0, 150);

  DrawMBar(Life.Cur, Life.Max, Pos.X * 32 + 4, Pos.Y * 32 - 4, 24, cDkRed);
  DrawMBar(Mana.Cur, Mana.Max, Pos.X * 32 + 4, Pos.Y * 32 - 7, 24, cDkBlue);
end;

function TCreature.DoSpell(Name, PatID: AnsiString): Boolean;
var
  M: TMap;
begin
  Result := False;
  M := TMap(MP);
  if (Enemy <> nil) and (SpellName = Name)
    and M.LineOfSight(Pos, Enemy.Pos, False) then
  begin
    M.CreateBullet(GetItemPat(PatID), Self, Enemy);
    SpellName := '';
    WalkTo.X  := -1;
    if Self = PC then
    begin
      Enemy    := nil;
      PC.Moved := True;
    end;
    Result := True;
  end;
end;

procedure TCreature.Update;
var
  M: TMap;
  p: TPoint;
  si: PItem;
  S: ShortInt;
begin
  if Life.IsMin then Exit;
  M := TMap(MP);

  if (SpellName <> '') then
  begin
    if DoSpell('Огненный Шар', 'Fireball') then Exit;
    if DoSpell('Шаровая Молния', 'Chargedball') then Exit;
  end;
  SpellName := '';

  if Enemy <> nil then
    if not Enemy.Life.IsMin then
    begin
      si := nil;

      if (Self = PC) then
      begin
        S := PCBelt.ActSlot;
        with PC.Items[S] do
          if (Count > 0) then
            if (Pat.Category in ThrowingCategories) then
              si := @PC.Items[S];
      end else begin
        with SlotItem[slRHand].Item do
          if (Count > 0) then
            if (Pat.Category in ThrowingCategories) then
              si := @SlotItem[slRHand];
      end;

      if (SlotItem[slRHand].Item.Count > 0) and (SlotItem[slLHand].Item.Count > 0) then
      begin
        if IsRangedWpn(icBow) or IsRangedWpn(icCrossbow) then
            si := @SlotItem[slLHand];
      end;

      if (si <> nil) then
        if GetDist(Pos, Enemy.Pos) <= GetRadius then
          if M.LineOfSight(Pos, Enemy.Pos, False) then
          begin
            M.CreateBullet(si.Pat, Self, Enemy);
            si.Count := si.Count - 1;
            WalkTo.X := -1;
            if (Self = PC) then
            begin
              Enemy    := nil;
              PC.Moved := True;
            end;
            Exit;
          end;

      if (Pat.Name = 'NECROMANCER') then
        if (GetDist(Pos, Enemy.Pos) <= GetRadius) then
          if (M.LineOfSight(Pos, Enemy.Pos, False) = True) then
          begin
            M.CreateBullet(GetItemPat('chargedball'), Self, Enemy);
            WalkTo.X  := -1;
            Exit;
          end;

      WalkTo := Enemy.Pos;

      if (si = nil) and (SlotItem[slRHand].Item.Count > 0) then
        if (SlotItem[slRHand].Item.Pat.Category in RangedWpnCategories) then
        begin
          Enemy := nil;
          WalkTo.X := -1;
        end;
    end;

  if (WalkTo.X = Pos.X) and (WalkTo.Y = Pos.Y) then WalkTo.X := -1;

  if WalkTo.X <> -1 then
  begin
    CreateWave(M, WalkTo.X, WalkTo.Y, Pos.X, Pos.Y);
    NextStep := GetNextStep(Pos);
    if NextStep.X = -1 then
    begin
      WalkTo.X  := -1;
      if (Self = PC) then Enemy := nil;
    end;

    P := Pos;
    if WalkTo.X <> -1 then Walk(NextStep.X - Pos.X, NextStep.Y - Pos.Y);
    if (Pos.X = p.X) and (Pos.Y = p.Y) then WalkTo.X := -1;
  end;
end;

procedure TCreature.Walk(dx, dy: Integer);
var
  Dmg: TDamage;
  I, J, S: Integer;
  M: TMap;
  P: TPoint;
  Cr: TCreature;
  si: Single;
  V: Integer;
  F: Boolean;
  C: TItemPat;
  H: TItemProp;
begin
  LookAtObj := nil;
  M := TMap(MP);
  if HasEffect(efParal) then
  begin
    dx := 0;
    dy := 0;
    Moved := True;
  end;
  P.X := Pos.X + dx;
  P.Y := Pos.Y + dy;
  if (P.X < 0) or (P.Y < 0) or (P.X >= M.Width) or (P.Y >= M.Height) then Exit;
  if (M.Objects.Obj[P.X, P.Y] <> nil) then
  begin
    if (Self = PC) and (M.Objects.Obj[P.X, P.Y].Pat.Container) then
      LookAtObj := M.Objects.Obj[P.X, P.Y];

    if M.Objects.Obj[P.X, P.Y].Pat.Name = 'DOOR' then
      if M.Objects.Obj[P.X, P.Y].FrameN = 0 then
      begin
        if (Self = PC) then PC.Moved := True;
        M.Objects.Obj[P.X, P.Y].FrameN := 1;
        M.Objects.Obj[P.X, P.Y].BlockLook := False;
        M.Objects.Obj[P.X, P.Y].BlockWalk := False;
        M.UpdateFog(Self);
        Exit;
      end;

    if (M.Objects.Obj[P.X, P.Y].Pat.Name = 'CHEST') then
      if M.Objects.Obj[P.X, P.Y].FrameN = 0 then
      begin
        M.Objects.Obj[P.X, P.Y].FrameN := 1;
        Exit;
      end;

    if (M.Objects.Obj[P.X, P.Y].Pat.Name = 'LIFESHRINE') then
      if M.Objects.Obj[P.X, P.Y].FrameN = 0 then
      begin
        if not Life.IsMax then
        begin
          M.Objects.Obj[P.X, P.Y].FrameN := 1;
          PC.Info('Полное исцеление');
          Life.SetToMax;
        end;
        Exit;
      end;

    if (M.Objects.Obj[P.X, P.Y].Pat.Name = 'MANASHRINE') then
      if M.Objects.Obj[P.X, P.Y].FrameN = 0 then
      begin
        if not Mana.IsMax then
        begin
          M.Objects.Obj[P.X, P.Y].FrameN := 1;
          PC.Info('Мана восстановилась');
          Mana.SetToMax;
        end;
        Exit;
      end;

    if M.Objects.Obj[P.X, P.Y].BlockWalk then Exit;
  end;

  for i := 0 to M.Creatures.Count - 1 do
  begin
    Cr := TCreature(M.Creatures[i]);
    if Cr = Self then Continue;
    if (Cr.Pos.X = P.X) and (Cr.Pos.Y = P.Y) then
    begin
      if (Team = Cr.Team) then Exit;
      with SlotItem[slRHand].Item do
      if (Count > 0) then
      begin
        if (Pat.Category in RangedWpnCategories) then Exit;
      end;
      if (Self = PC) then
      begin
        PC.Moved := True;
        Enemy := nil;
      end;
      if Cr.HasEffect(efFreezing) then Cr.AddEffect(efFreezing, 1);

      // Melee
      ClearDamage(Dmg);
      if (SlotItem[slRHand].Item.Count = 0) then
      begin
        Dmg[dtPhys].Min   := GetParamValue('Strength') div 2;
        Dmg[dtPhys].Max   := GetParamValue('Strength');
      end else begin
        Dmg[dtPhys].Min   := GetParamValue('DamPhysMin');
        Dmg[dtPhys].Max   := GetParamValue('DamPhysMax');
        Dmg[dtPoison].Min := GetParamValue('DamPoisonMin');
        Dmg[dtPoison].Max := GetParamValue('DamPoisonMax');
        Dmg[dtFire].Min   := GetParamValue('DamFireMin');
        Dmg[dtFire].Max   := GetParamValue('DamFireMax');
        Dmg[dtCold].Min   := GetParamValue('DamColdMin');
        Dmg[dtCold].Max   := GetParamValue('DamColdMax');
        Dmg[dtElec].Min   := GetParamValue('DamElecMin');
        Dmg[dtElec].Max   := GetParamValue('DamElecMax');
      end;
      Combat(Dmg, Cr);

      Sp.X := (Cr.Pos.X - Pos.X) * 5;
      Sp.Y := (Cr.Pos.Y - Pos.Y) * 5;
      AtT  := 10;

      if HasEffect(efVampirism) then
      begin
        S :=  Math.RandomRange(GetParamValue('Магия') + 3, GetParamValue('Магия') + 6);
        Digit.Add(Pos.X, Pos.Y, IntToStr(S), $88FFFF);
        Life.Inc(S);
      end;
      // Существо отравляет
      if ((Pat.Name = 'SCORPION') or (Pat.Name = 'SNAKE')) and (Random(7) = 0)
        and not HasEffect(efResPoison) then
      begin
        Cr.AddEffect(efPoison, 100);
      end;
      Cr.WalkTo.X := -1;
      if (Cr = PC) then Cr.Enemy := nil;
      Exit;
    end;
  end;

  Self.SetPosition(P);

  // Автоподнятие предметов с пола
  if (Self = PC) then
  begin
    I := 0;
    F := True;
    while (I < M.ItemsCnt) do
    begin
      if (M.Items[i].Pos.X = Pos.X) and (M.Items[i].Pos.Y = Pos.Y) then
      begin
        C := M.Items[I].Pat;
        H := M.Items[i].Prop;
        if not CreateItem(M.Items[i].Pat, M.Items[i].Count, M.Items[i].Prop, V) then
        begin
          I := I + 1;
          Continue;
        end;
        for j := I to M.ItemsCnt - 2 do M.Items[j] := M.Items[j + 1];
        M.ItemsCnt := M.ItemsCnt - 1;
        SetLength(M.Items, M.ItemsCnt);
        if F then
        begin
          Play(ttSndPickup);
          PlayItem(C, H);
          F := False;
        end;
        WalkTo.X := -1;
        i := i - 1;
      end;
      i := i + 1;
    end;
  end;
end;

function TCreature.CreateItem(ItemPat: TItemPat; Count: Integer; Prop: TItemProp; var Index: Integer): Boolean;
var
  I: Integer;
begin
  Index := -1;
  Result := True;
  if ItemPat.CanGroup then
    for i := 0 to ItemsCnt - 1 do
      if (Items[i].Count > 0) then
        if (Items[i].Pat = ItemPat) then
        begin
          Items[i].Count := Items[i].Count + Count;
          Index := I;
          Exit;
        end;
  for i := 0 to ItemsCnt - 1 do
    if (Items[i].Count = 0) then
    begin
      Items[i].Count := Count;
      Items[I].Prop := Prop;
      Items[i].Pat := ItemPat;
      Index := I;
      Exit;
    end;
  if (ItemsCnt = InvCapacity) then
  begin
    Result := False;
    Exit;
  end;
  ItemsCnt := ItemsCnt + 1;
  SetLength(Items, ItemsCnt);
  Index := ItemsCnt - 1;
  Items[Index].Pat := ItemPat;
  Items[Index].Count := Count;
  Items[Index].Prop := Prop;
  AddItemProp(@Items[Index]);
end;

function TCreature.HasItem(ItemPat: TItemPat; Count: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to ItemsCnt - 1 do
    if (Items[i].Count > 0) then
      if (Items[i].Pat = ItemPat) then
      begin
        Result := True;
        Exit;
      end;
end;

function TCreature.ItemCount(ItemName: AnsiString): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to ItemsCnt - 1 do
    if (Items[I].Count > 0) then
      if (Items[I].Pat.Name = ItemName) then
        Inc(Result, Items[I].Count);
end;

function TCreature.DelItem(ItemPat: TItemPat; Count: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to ItemsCnt - 1 do
    if (Items[i].Count > 0) then
      if (Items[i].Pat = ItemPat) then
      begin
        Items[i].Count := 0;
        Exit;
      end;
end;

function TCreature.DelItem(ItemName: AnsiString; Count: Integer = 1): Boolean;
var
  I, C: Integer;
begin
  Result := False;
  ItemName := UpperCase(ItemName);
  if (ItemCount(ItemName) < Count) then Exit;
  C := Count;
  for I := 0 to ItemsCnt - 1 do
    if (Items[I].Count > 0) then
      if (Items[I].Pat.Name = ItemName) then
      begin
        if (Items[I].Count >= C) then
        begin
          Items[I].Count := Items[I].Count - C;
          C := 0;
        end else begin
          C := C - Items[I].Count;
          Items[I].Count := 0;
        end;
        if (C <= 0) then
        begin
          Result := True;
          Exit;
        end;
      end;
end;

function TCreature.AddItem(ItemPat: TItemPat; Count: Integer): Boolean;
var
  I, F: Integer;
  Prop: TItemProp;
begin
  Result := False;
  if HasItem(ItemPat, 1) then
  begin
    for I := 0 to ItemsCnt - 1 do
      if (Items[i].Count > 0) then
        if (Items[i].Pat = ItemPat) then
        begin
          Inc(Items[I].Count, Count);
          Exit;
        end;
  end else begin
    ClearItemProp(Prop);
    Result := CreateItem(ItemPat, Count, Prop, F);
  end;
end;

function TCreature.AddItem(ItemName: AnsiString; Count: Integer): Boolean;
var
  Item: TItem;
begin
  ItemName := UpperCase(ItemName);
  Item.Pat := GetItemPat(ItemName);
  Result := AddItem(Item.Pat, Count);
end;

procedure TCreature.SetParamValue(Title: AnsiString; Value: Integer);
var
  I: Integer;
begin
  for I := 0 to CrStatsCnt - 1 do
    if (CrStats[I].Title = Title) or (CrStats[I].ID = Title) then
    begin
      ParamValue[I] := Value;
      Exit;
    end;
end;

function TCreature.GetParamValue(Title: AnsiString): Integer;
var
  I: Integer;
begin
  Result := 0;
  for i := 0 to CrStatsCnt - 1 do
    if (CrStats[i].Title = Title) then
    begin
      Result := ParamValue[i];
      Exit;
    end;
  for i := 0 to CrStatsCnt - 1 do
    if (CrStats[i].ID = Title) then
    begin
      Result := ParamValue[i];
      Exit;
    end;
end;

procedure TCreature.AddExp(ExpCnt: Integer);
var
  V: Integer;
begin
  V := Exp.Cur + ExpCnt;
  Exp.Cur := V;
  if (V >= Exp.Max) then
  begin
    Level := Level + 1;
    Exp.Cur := V - Exp.Max;
    Exp.Max := Exp.Max + Round(Exp.Max * 0.8);
    if Self = PC then
    begin
      Self.Fill;
      FlagPrayer := 50;
      StatPoints := StatPoints + 3;
      SkillPoints := SkillPoints + 1;
      PC.Info('Повышение уровня');
      Play(ttSndLevel);
    end;
  end;
end;

procedure TCreature.WalkAway(tx1, ty1: Integer);
var
  M: TMap;
  P: TPoint;
  I: Integer;
  B: Boolean;
begin
  M := TMap(MP);
  for i := 0 to 8 do
  begin
    P := Pos;
    if i = 0 then
    begin
      P.X := Pos.X + (Pos.X - tx1);
      P.Y := Pos.Y + (Pos.Y - ty1);
    end;
    if i = 1 then P.X := P.X - 1;
    if i = 2 then P.X := P.X + 1;
    if i = 3 then P.Y := P.Y - 1;
    if i = 4 then P.Y := P.Y + 1;
    if (i = 5) or (i = 6) then P.X := P.X - 1;
    if (i = 7) or (i = 8) then P.X := P.X + 1;
    if (i = 5) or (i = 7) then P.Y := P.Y - 1;
    if (i = 6) or (i = 8) then P.Y := P.Y + 1;
    if (P.X < 0) or (P.Y < 0) or (P.X >= Map.Width) or (P.Y >= Map.Height) then Continue;
    B := True;
    if M.Objects.Obj[P.X, P.Y] <> nil then
      if M.Objects.Obj[P.X, P.Y].BlockWalk = True then B := False;
    if M.GetCreature(P) <> nil then B := False;
    if B then
    begin
      Walk(P.X - Pos.X, P.Y - Pos.Y);
      PC.Moved := True;
      Exit;
    end;
  end;
end;

procedure TCreature.AddSpell(SpellName : AnsiString);
var
  i, n : Integer;
begin
  n := -1;
  for i := 0 to AllSpellsCnt - 1 do
    if (AllSpells[i].Name = SpellName) then
    begin
      n := i;
      Break;
    end;
  if n = -1 then Exit;
  SpellsCnt := SpellsCnt + 1;
  Setlength(Spells, SpellsCnt);
  Spells[SpellsCnt - 1] := AllSpells[n];
end;

procedure TCreature.UseSpell(SpellN : Integer);
var
  i, j, k : Integer;
  M       : TMap;
begin
  if Spells[SpellN].Name = 'Армагеддон' then
  begin
    M := TMap(MP);
    for k := 0 to 50 do
    begin
      i := Random(M.Width);
      j := Random(M.Height);
      //if (ABS(PC.TX - i) < 3) and (ABS(PC.TY - j) < 3) then Continue;
      M.Explosive(i, j);
    end;
    Mana.Cur := Mana.Cur - Spells[SpellN].Mana;
    SellSpellN := -1;
    PC.Moved := True;
    Exit;
  end;
end;

procedure TCreature.AddEffect(E: TEfEnum; Time: Integer);
var
  I: Integer;
  Pat: TEfPat;
begin
  for I := 0 to Length(AllEffects) - 1 do
    if (E = AllEffects[I].Enum) then Break;
  ETV.Add(AllEffects[I].Name, Time);
  if (Self = PC) then
  begin
    Pat := TEfPat(GetPattern('EFFECT', AllEffects[I].Name));
    if (Pat = nil) then Exit;
    PC.Info(Pat.Title);
    if (E = efPoison) then FlagPoison := 50;
  end;
end;

procedure TCreature.DelEffect(E: TEfEnum);
var
  I: Integer;
begin
  for I := 0 to Length(AllEffects) - 1 do
    if (E = AllEffects[I].Enum) then Break;
  ETV.Del(AllEffects[I].Name);
end;

function TCreature.HasEffect(E: TEfEnum): Boolean;
var
  I: Integer;
begin
  for I := 0 to Length(AllEffects) - 1 do
    if (E = AllEffects[I].Enum) then Break;
  Result := ETV.IsVar(AllEffects[I].Name)
end;

function TCreature.TimeEffect(E: TEfEnum): Word;
var
  I: Integer;
begin
  for I := 0 to Length(AllEffects) - 1 do
    if (E = AllEffects[I].Enum) then Break;
  Result := ETV.Value(AllEffects[I].Name)
end;

procedure TCreature.UpdateEffects;
var
  I: Integer;
  Dam: TDamage;
begin
  if HasEffect(efPoison) then
  begin
    ClearDamage(Dam);
    Dam[dtPoison].Min := 1;
    Dam[dtPoison].Max := 1;
    Self.Hit(Dam, False);
    if (Self = PC) then FlagPoison := 50;
  end;
  if HasEffect(efWeakness) then Mana.Dec(Math.RandomRange(2, 5));
  if HasEffect(efRust) then
    for I := 1 to 7 do
    begin
      DamageWeapon;
      DamageItem(GetRandArmorSlot);
    end;
  if HasEffect(efHypnosis) and (TimeEffect(efHypnosis) = 1) then Team := 1;
  ETV.Move;
end;

procedure TCreature.Calculator;
var
  S: TSlot;
  Bow, Crossbow, Arrow, Bolt: Boolean;
  X, Y, Z: Integer;
  Str, Sta, Dex, Agi, Wis, Int: Word;

  function IsNSlot(S: TSlot): Boolean;
  begin
    Result := (SlotItem[S].Item.Pat = nil) or (SlotItem[S].Item.Count <= 0)
  end;

  procedure Add(ParamName: AnsiString; Value: Integer);
  begin
    if (Value > 0) then SetParamValue(ParamName, GetParamValue(ParamName) + Value);
  end;

  procedure CalcBonus(Item: PItem);
  begin
    Add('Block', Item.Pat.Block);
    Add('Radius', GetItemProp(Item, ipRadius));
    Add('Armor', GetItemProp(Item, ipArmor));
    Add('ResFire', GetItemProp(Item, ipResFire));
    Add('ResCold', GetItemProp(Item, ipResCold));
    Add('ResElec', GetItemProp(Item, ipResElec));
    Add('ResPoison', GetItemProp(Item, ipResPoison));
    Add('BonusStr', GetItemProp(Item, ipStr));
    Add('BonusSta', GetItemProp(Item, ipSta));
    Add('BonusDex', GetItemProp(Item, ipDex));
    Add('BonusAgi', GetItemProp(Item, ipAgi));
    Add('BonusWis', GetItemProp(Item, ipWis));
    Add('BonusInt', GetItemProp(Item, ipInt));
    Add('BonusLife', GetItemProp(Item, ipLife));
    Add('BonusMana', GetItemProp(Item, ipMana));
    Add('BonusRefLife', GetItemProp(Item, ipRefLife));
    Add('BonusRefMana', GetItemProp(Item, ipRefMana));
  end;

begin
  SetParamValue('DamPhysMin', 0);
  SetParamValue('DamPhysMax', 0);
  SetParamValue('DamPoisonMin', 0);
  SetParamValue('DamPoisonMax', 0);
  SetParamValue('DamFireMin', 0);
  SetParamValue('DamFireMax', 0);
  SetParamValue('DamColdMin', 0);
  SetParamValue('DamColdMax', 0);
  SetParamValue('DamElecMin', 0);
  SetParamValue('DamElecMax', 0);

  SetParamValue('Block',     0);
  SetParamValue('Radius',    0);
  SetParamValue('Armor',     0);
  SetParamValue('ResFire',   0);
  SetParamValue('ResCold',   0);
  SetParamValue('ResElec',   0);
  SetParamValue('ResPoison',  0);
  SetParamValue('BonusStr',  0);
  SetParamValue('BonusSta',  0);
  SetParamValue('BonusDex',  0);
  SetParamValue('BonusAgi',  0);
  SetParamValue('BonusWis',  0);
  SetParamValue('BonusInt',  0);
  SetParamValue('BonusLife', 0);
  SetParamValue('BonusMana', 0);
  SetParamValue('BonusRefLife', 0);
  SetParamValue('BonusRefMana', 0);
  // Weapons
  Bow := not IsNSlot(slRHand) and (SlotItem[slRHand].Item.Pat.Category = icBOW);
  Crossbow := not IsNSlot(slRHand) and (SlotItem[slRHand].Item.Pat.Category = icCROSSBOW);
  // Projectiles
  Arrow := not IsNSlot(slLHand) and (SlotItem[slLHand].Item.Pat.Category = icARROW);
  Bolt := not IsNSlot(slLHand) and (SlotItem[slLHand].Item.Pat.Category = icBOLT);
  //
  for S := slHead to slBoots do
  begin
    if IsNSlot(S) then Continue;
    if (SlotItem[S].Item.Pat.Durability > 0) and (SlotItem[S].Item.Prop.Durability <= 0) then Continue;
    if not (((S = slRHand) and Bow and not Arrow) or ((S = slLHand) and Arrow and not Bow))
    and not (((S = slRHand) and Crossbow and not Bolt) or ((S = slLHand) and Bolt and not Crossbow)) then
    begin
      Add('DamPhysMin', GetItemProp(@SlotItem[S].Item, ipDamPhysMin));
      Add('DamPhysMax', GetItemProp(@SlotItem[S].Item, ipDamPhysMax));
      Add('DamPoisonMin', GetItemProp(@SlotItem[S].Item, ipDamPoisonMin));
      Add('DamPoisonMax', GetItemProp(@SlotItem[S].Item, ipDamPoisonMax));
      Add('DamFireMin', GetItemProp(@SlotItem[S].Item, ipDamFireMin));
      Add('DamFireMax', GetItemProp(@SlotItem[S].Item, ipDamFireMax));
      Add('DamColdMin', GetItemProp(@SlotItem[S].Item, ipDamColdMin));
      Add('DamColdMax', GetItemProp(@SlotItem[S].Item, ipDamColdMax));
      Add('DamElecMin', GetItemProp(@SlotItem[S].Item, ipDamElecMin));
      Add('DamElecMax', GetItemProp(@SlotItem[S].Item, ipDamElecMax));
    end;
    CalcBonus(@SlotItem[S].Item);
  end;
  if (ItemsCnt > 0) then
  for Y := 0 to InvHeight - 1 do
    for X := 0 to InvWidth - 1 do
    begin
      Z := Y * InvWidth + X;
      if (Z >= ItemsCnt) then Continue;
      if (Items[Z].Count = 0) then Continue;
      if (Items[Z].Pat.Category = icTalisman) then
        CalcBonus(@Items[Z]);
    end;

  Str := GetParamValue('Strength') + GetParamValue('BonusStr');
  Sta := GetParamValue('Stamina') + GetParamValue('BonusSta');

  Int := GetParamValue('Intellect') + GetParamValue('BonusInt');
  Wis := GetParamValue('Wisdom') + GetParamValue('BonusWis');

  Life.Max := (Sta * 5) + GetParamValue('BonusLife');
  Mana.Max := (Int * 5) + GetParamValue('BonusMana');

  RefLife := Round(Str / 6.9) + GetParamValue('BonusRefLife');
  RefMana := Round(Wis * 1.4) + GetParamValue('BonusRefMana');

  if (GetParamValue('DamPhysMin') < 1) then SetParamValue('DamPhysMin', 1);
  if (GetParamValue('DamPhysMax') < 2) then SetParamValue('DamPhysMax', 2);
end;

procedure TPC.Calculator;
begin
  inherited Calculator;
  Map.UpdateFog(Self);
end;

function TCreature.GetDamageInfo: AnsiString;
begin
  if (GetParamValue('DamPhysMin') > 0) and (GetParamValue('DamPhysMax') > 0) then
    Result := IntToStr(GetParamValue('DamPhysMin')) + '-' + IntToStr(GetParamValue('DamPhysMax')) else Result := '0';
end;                  

procedure TCreature.Hit(Dam: TDamage; Flag: Boolean = True; Cr: TCreature = nil);
var
  Strength: Integer;
  I: TDamType;
  D: Integer;
begin
  if (Cr <> nil) then Cr.Adr.Inc(Math.RandomRange(1, 4));
  if (Self = PC) then FlagBlood := 50;
  if (Self = PC) and Self.HasEffect(efInvulnerability) then Exit;
  if Flag then
  begin
    Strength := Cr.GetParamValue('Strength') div 15;
    Strength := Clamp(Strength, 0, 75);
    Dam[dtPhys].Min := Dam[dtPhys].Min + Strength;
    Dam[dtPhys].Max := Dam[dtPhys].Max + Strength;
  end;
  for I := Low(TDamType) to High(TDamType) do
    if (Dam[I].Min > 0) and (Dam[I].Max > 0) then
    begin
      D := Math.RandomRange(Dam[I].Min, Dam[I].Max + 1);
      Life.Dec(D);
      Digit.Add(Pos.X, Pos.Y, IntToStr(D), DamTypeColor[I]);
      //if I = dtFire then PC.Info(IntToStr(D));
    end;
  if Life.IsMin then
    if (Team <> PC.Team) then
    begin
      PC.AddExp(Pat.Exp);
      Loot();
    end;
  if (Cr <> nil) then Cr.DamageWeapon;
  if (Dam[dtPhys].Min > 1) and (Self = PC) then DamageItem(GetRandArmorSlot);
end;

procedure TCreature.Loot;
begin
  RandomItem(Pos.X, Pos.Y, True);
end;

procedure TCreature.RandEquip;
var
  ItemPat: TItemPat;

  procedure RangedWeap(Category: TCatEnum);
  var
    I: Byte;
  begin
    for I := 0 to Length(Categories) - 1 do
      if (GetRangedWeaponProjCat(Category) = Categories[I].Enum) then Break;
    SlotItem[slLHand].Item.Pat := GetItemPat(Categories[I].Name);
    SlotItem[slLHand].Item.Count := Math.RandomRange(SlotItem[slLHand].Item.Pat.MinCount,
      SlotItem[slLHand].Item.Pat.MaxCount) + Math.RandomRange(8, 19);
  end;

begin
  if (Pat.Equip <> '') then
  begin
    ItemPat := nil;
    ItemPat := GetItemPat(Utils.RandStr(',', Pat.Equip));
    if (ItemPat <> nil) then
    begin
      SlotItem[slRHand].Item.Pat := ItemPat;
      SlotItem[slRHand].Item.Prop := GenItemProp(ItemPat);
      SlotItem[slRHand].Item.Count := 1;
      if (ItemPat.Category in ThrowingCategories) then
        SlotItem[slRHand].Item.Count := Math.RandomRange(SlotItem[slRHand].Item.Pat.MinCount,
          SlotItem[slRHand].Item.Pat.MaxCount + 1);
      if (ItemPat.Category in RangedWpnCategories) then RangedWeap(ItemPat.Category);
    end;
  end;
  Self.Calculator;
  Self.Fill;
end;

function TCreature.GetRadius: Byte;
begin
  Result := Self.GetParamValue('Radius') + 7;
  if HasEffect(efBlindness) then Result := 0;
  if HasEffect(efLight) then Result := High(Byte);
  Result := Clamp(Result, 1, 12);
end;

function TCreature.GetRes(Dmg: TDamType): Word;
begin
  case Dmg of
    dtPhys  : Result := GetParamValue('Armor') div 10;
    dtPoison: Result := GetParamValue('ResPoison');
    dtFire  : Result := GetParamValue('ResFire');
    dtCold  : Result := GetParamValue('ResCold');
    dtElec  : Result := GetParamValue('ResElec');
  end;
  Result := Clamp(Result, 0, 100);
end;

{
function TPC.GetProtect: Integer;
begin
  Result := 0;
  try
    Result := Prop.Protect;
    if TempSys.IsVar('Blessed') then
      Result := Result + Percent(Prop.Protect, TempSys.Power('Blessed'));
    if TempSys.IsVar('Cursed') then
      Result := Result - Percent(Prop.Protect, TempSys.Power('Cursed'));
    Result := Clamp(Result, 0, GetProtectMax);
  except
    on E: Exception do Error.Add('PC.GetProtect', E.Message);
  end;
end
}

procedure TCreature.Combat(Dmg: TDamage; Cr: TCreature; Pat: TItemPat = nil);
var
  P: TItemProp;
  Res: TResist;
  I: TDamType;

  procedure ShowMsg(S: AnsiString);
  begin
    Digit.Add(Cr.Pos.X, Cr.Pos.Y, S, cLtGray, True);
  end;

begin
  if (Pat <> nil) and (Pat.Category = icElixir) then Exit;
  // Шанс уклониться
  if (Math.RandomRange(1, Cr.GetParamValue('Agility') + 1)
  // Шанс нанести урон
    > Math.RandomRange(1, Self.GetParamValue('Dexterity') + 1)) then
  begin
    ShowMsg('промах');
    if (Pat <> nil) and Pat.CanGroup then Map.CreateItem(Pat, 1, Cr.Pos.X, Cr.Pos.Y, P);
    Exit;
  end;
  // Блок
  if (Math.RandomRange(0, 100) + 1 < Cr.GetParamValue('Block')) then
  begin
    ShowMsg('блок');
    Cr.DamageItem(slLHand);
    Exit;
  end;
  // Защита, поглощение урона, в %
  for I := Low(TDamType) to High(TDamType) do
  begin
    Res[I]:= Cr.GetRes(I);
    if (Dmg[I].Min > 0) then
    begin
      Res[I] := Clamp(Res[I], 0, 100);
      Dmg[I].Min := Percent(Dmg[I].Min, 100 - Res[I]);
      Dmg[I].Min := Clamp(Dmg[I].Min, 1, 1000);
      Dmg[I].Max := Percent(Dmg[I].Max, 100 - Res[I]);
      Dmg[I].Max := Clamp(Dmg[I].Max, 1, 1000);
    end else begin
      Dmg[I].Min := 0;
      Dmg[I].Max := 0;
    end;
    // Щит маны
    if Cr.HasEffect(efManaShield) and (Dmg[I].Min > 1) and (Cr.Mana.Cur > 0) then
    begin
      if (Cr.Mana.Cur >= (Dmg[I].Min div 2)) then
      begin
        Dmg[I].Min := Dmg[I].Min div 2;
        Cr.Mana.Dec(Dmg[I].Min);
      end else begin
        Dmg[I].Min := Dmg[I].Min - Cr.Mana.Cur;
        Cr.Mana.SetToMin;
      end;
    end;
  end;
  // Крит. урон
  if (Math.RandomRange(0, 100) + 1 < Adr.Cur) then
  begin
    ShowMsg('крит'); 
    MultDamage(Dmg, 2);
    Cr.Hit(Dmg, True, Self);
  end else begin
    // Обычный урон
    Cr.Hit(Dmg, True, Self);
  end;
end;

function TCreature.SkillCount: Byte;
var
  E: TExplodeResult;
begin
  E := nil;
  Result := 0;
  if (Pat.Skills = '') then Exit;
  E := Explode(',', Pat.Skills);
  Result := Length(E);
end;

function TCreature.HasSkill(SkillName: AnsiString): Boolean;
var
  I: Byte;
  E: TExplodeResult;
begin
  E := nil;
  Result := False;
  if (Pat.Skills = '') then Exit;
  E := Explode(',', Pat.Skills);
  SkillName := UpperCase(SkillName);
  for I := 0 to High(E) do
    if (E[I] = SkillName) then
    begin
      Result := True;
      Break;
    end;
end;

function TCreature.GetSkillName(I: Byte): AnsiString;
var
  E: TExplodeResult;
begin
  Result := '';
  E := Explode(',', Pat.Skills);
  Result := E[I];
end;

procedure TCreature.UseSkill(Tag: Byte; Item: PItem);
begin
  if (Tag <= 0) then Exit;
//  if (Tag = 1) then FlagScroll := 'Шаровая Молния';
//  AddEffect(Item.Pat.Name, Item.Pat.Cooldown);
//  Box(Tag);
end;

procedure TCreature.DamageWeapon;
var
  S: ShortInt;
begin
  if (Math.RandomRange(0, 9) > 0) then Exit;
  if (Self = PC) then
  begin
    S := PCBelt.ActSlot;
    with PC.Items[S] do
    if (Count > 0)
      and (Pat.Durability > 0) then
      with Prop do
        if (Durability > 0) then
        begin
          // Если это дист. оружие, то ломается оно еще реже
          if (Pat.Category in RangedWpnCategories)
            and (Math.RandomRange(0, 9) > 0) then Exit;
          Durability := Durability - 1;
          if (Durability = 0) then
            Play(ttSndDamageItem);
          Calculator;
        end;
  end;
end;

procedure TCreature.DamageItem(S: TSlot);
begin
  if (Math.RandomRange(0, 9) > 0) then Exit;
  with SlotItem[S].Item do
  if (Count > 0)
    and (Pat.Durability > 0) then
    with Prop do
      if (Durability > 0) then
      begin
        Durability := Durability - 1;
        if (Durability = 0) then
          Play(ttSndDamageItem);
        Calculator;
      end;
end;

function TCreature.GetRandArmorSlot: TSlot;
begin
  case Math.RandomRange(0, 6) of
    0: Result := slHead;
    1: Result := slBody;
    2: Result := slCloak;
    3: Result := slGloves;
    4: Result := slBelt;
    else Result := slBoots;
  end;
end;

procedure TCreature.SetCam;
begin
  Cam.X := Pos.X * 32 - ScreenWidth div 2 + 16;
  Cam.Y := Pos.Y * 32 - ScreenHeight div 2 + 16;
end;

procedure TPC.LoadFromFile(const ZipFileName: AnsiString);
var
  F: TStringList;
  X, Y, ID: Integer;

  function Get(Default: Integer): Integer; overload;
  begin
    Result := SysUtils.StrToInt(F[ID]);
    Inc(ID);
  end;

  function Get(Default: AnsiString): AnsiString; overload;
  begin
    Result := F[ID];
    Inc(ID);
  end;

begin
  F := TStringList.Create;
  try
    ID := 0;
    if (SysUtils.FileExists(ZipFileName)) then
    begin
      if (LibZip.FileExists(ZipFileName, 'Character')) then
      begin
        F.Text := string(LibZip.Load(ZipFileName, 'Character'));
        Self.Name := Get('Dark');
        X := Get(1);
        Y := Get(1);
        Self.SetPosition(X, Y);
        Self.Level := Get(1);
        Self.StatPoints := Get(0);
        Self.SkillPoints := Get(0);
        Self.Life.Cur := Get(0);
        Self.Life.Max := Get(0);
        Self.Life.Adv := Get(0);
        Self.Mana.Cur := Get(0);
        Self.Mana.Max := Get(0);
        Self.Mana.Adv := Get(0);
        Self.Exp.Cur := Get(0);
        Self.Exp.Max := Get(0);
        Self.Exp.Adv := Get(0);
        Self.Adr.Cur := Get(0);
        Self.Adr.Max := Get(0);
        Self.Adr.Adv := Get(0);
        Self.GMapPos.X := Get(0);
        Self.GMapPos.Y := Get(3);
        PCBelt.Slot := Get(0);
        PCAllMapsID := Get('');
      end;
      LoadSlots(ZipFileName);
      LoadItems(ZipFileName);
      LoadEffects(ZipFileName);
      Self.Calculator;
    end;
  finally
    F.Free;
  end;
end;

procedure TPC.SaveToFile(const ZipFileName: AnsiString);
var
  F: TStringList;

  procedure Add(Value: AnsiString); overload;
  begin
    F.Append(Value);
  end;

  procedure Add(Value: Integer); overload;
  begin
    F.Append(IntToStr(Value));
  end;

begin
  F := TStringList.Create;
  try
    Add(Self.Name);
    Add(Self.Pos.X);
    Add(Self.Pos.Y);
    Add(Self.Level);
    Add(Self.StatPoints);
    Add(Self.SkillPoints);
    Add(Self.Life.Cur);
    Add(Self.Life.Max);
    Add(Self.Life.Adv);
    Add(Self.Mana.Cur);
    Add(Self.Mana.Max);
    Add(Self.Mana.Adv);
    Add(Self.Exp.Cur);
    Add(Self.Exp.Max);
    Add(Self.Exp.Adv);
    Add(Self.Adr.Cur);
    Add(Self.Adr.Max);
    Add(Self.Adr.Adv);
    Add(PC.GMapPos.X);
    Add(PC.GMapPos.Y);
    Add(PCBelt.Slot);
    Add(PCAllMapsID);
    LibZip.Save(ZipFileName, 'Character', AnsiString(F.Text));
    Elixir.SaveToFile(ZipFileName);
    Scroll.SaveToFile(ZipFileName);
    SaveSlots(ZipFileName);
    SaveItems(ZipFileName);
    SaveEffects(ZipFileName);
  finally
    F.Free;
  end;
end;

procedure TPC.LoadSlots(const ZipFileName: AnsiString);
var
  E: TExplodeResult;
  Item: TItem;
  F: TStringList;
  S: TSlot;
  I: ShortInt;
begin
  E := nil;
  F := TStringList.Create;
  try
    I := -1;
    F.Text := string(LibZip.Load(ZipFileName, 'Slots'));
    for S := slHead to slBoots do
    begin
      Inc(I);
      if (S = slRHand) or (F[I] = '') then Continue;
      E := nil;
      E := Explode(',', F[I]);
      Item.Pat := GetItemPat(E[0]);
      Item.Count := StrToInt(E[1]);
      Item.Prop.Durability := StrToInt(E[2]);
      Item.Prop.Suffix := E[3];
      Item.Prop.Material := E[4];
      Self.SlotItem[S].Item := Item;
    end;
  finally
    F.Free;
  end;
end;

procedure TPC.SaveSlots(const ZipFileName: AnsiString);
var
  F: TStringList;
  S: TSlot;
begin
  F := TStringList.Create;
  try
    for S := slHead to slBoots do
    begin
      if (SlotItem[S].Item.Count > 0) and (S <> slRHand) then
        with SlotItem[S].Item do
          F.Append(Format('%s,%d,%d,%s,%s', [Pat.Name, Count, Prop.Durability, Prop.Suffix, Prop.Material]))
            else F.Append('');
    end;
    LibZip.Save(ZipFileName, 'Slots', AnsiString(F.Text));
  finally
    F.Free;
  end;
end;

procedure TPC.LoadItems(const ZipFileName: AnsiString);
var
  E: TExplodeResult;
  Item: TItem;
  F: TStringList;
  I: ShortInt;
  N: AnsiString;
begin
  E := nil;
  F := TStringList.Create;
  try
    F.Text := string(LibZip.Load(ZipFileName, 'Items'));
    for I := 0 to F.Count - 1 do
    begin
      if (F[I] = '') or (I >= InvCapacity) then Continue;
      E := nil;
      E := Explode(',', F[I]);
      Items[I].Pat := GetItemPat(E[0]);
      Items[I].Count := StrToInt(E[1]);
      Items[I].Prop.Durability := StrToInt(E[2]);
      Items[I].Prop.Suffix := E[3];
      Items[I].Prop.Material := E[4];
    end;
  finally
    F.Free;
  end;
end;

procedure TPC.SaveItems(const ZipFileName: AnsiString);
var
  F: TStringList;
  I: Integer;
begin
  F := TStringList.Create;
  try
    for I := 0 to PC.ItemsCnt - 1 do
    begin
      if (Items[I].Count > 0) then
        with Items[I] do
          F.Append(Format('%s,%d,%d,%s,%s', [Pat.Name, Count, Prop.Durability, Prop.Suffix, Prop.Material]))
            else F.Append('');
    end;
    LibZip.Save(ZipFileName, 'Items', AnsiString(F.Text));
  finally
    F.Free;
  end;
end;

procedure TPC.LoadEffects(const ZipFileName: AnsiString);
begin
  ETV.Text := LibZip.Load(ZipFileName, 'Effects');
end;

procedure TPC.SaveEffects(const ZipFileName: AnsiString);
begin
  LibZip.Save(ZipFileName, 'Effects', ETV.Text);
end;

function TCreature.IsRangedWpn(Weapon: TCatEnum): Boolean;
begin
  Result := (SlotItem[slRHand].Item.Pat.Category = Weapon)
    and (SlotItem[slLHand].Item.Pat.Category = GetRangedWeaponProjCat(Weapon))
end;

procedure TCreature.Rest;
begin
  PC.Moved := True;
end;

procedure TCreature.ReFill;
var
  Bonus: Word;
const
  M = 100;
begin
  {TODO: Починить вост. здоровья и маны}
  // Восстановление маны и здоровья во время каждого хода
  if (RefLife >= M) then
  begin
    Bonus := RefLife div M;
    RefLife := RefLife - (Bonus * M);
    Life.Inc(Bonus);
  end;
  if (RefMana >= M) then
  begin
    Bonus := RefMana div M;
    RefMana := RefMana - (Bonus * M);
    Mana.Inc(Bonus);
  end;
end;

end.
