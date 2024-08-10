unit gm_map;

interface

uses
  Classes, Types, gm_engine, gm_patterns, gm_obj, gm_creature, gm_item,
  CustomMap;

const
  MapDeepMax = 9;
  MapLevelMax = 9;
  MapSide = 50;

type
  TMapStairsDir = (sdUp, sdDown, sdTown);

type
  TTile = record
    Pat: TGroundPat;
    Dec: Word;
  end;

type
  TGround = class(TCustomMap)
    Tiles: array of array of TTile;
    constructor Create;
    procedure Render;
    procedure Clear(GroundName: AnsiString; DecID: Word = 0);
  end;

type
  TBullet = record
    Pat       : TItemPat;
    Ang       : Integer;
    Dist      : Single;
    CPos      : TPoint;
    OPos      : TPoint;
    Owner     : TCreature;
    Enemy     : TCreature;
    RotAng    : Integer;
    Damage    : TDamRec;
  end;

type
  TMap = class(TCustomMap)
  private
    FName: AnsiString;
    procedure SetName(const Value: AnsiString);
  public
    Ground        : TGround;
    Objects       : TObjects;
    Creatures     : TList;
    Fog           : array of array of Byte;
    Items         : array of TItem;
    ItemsCnt      : Integer;
    Bullets       : array of TBullet;
    BulletsCnt    : Integer;
    Fire          : array of TPoint;
    FireTime      : array of Integer;
    FireCnt       : Integer;
    property Name: AnsiString read FName write SetName;
    constructor Create;
    destructor Destroy; override;
    procedure Render;
    procedure Clear;
    procedure Update;
    function CreateCreature(CrName : AnsiString; P: TPoint) : TCreature;
    procedure CreateSpot(Name: AnsiString; P: TPoint; Size: Byte);
    function GetCreature(A: TPoint) : TCreature;
    procedure UpdateFog(C: TCreature);
    function LineOfSight(A, B: TPoint; UpdFog : Boolean) : Boolean;
    procedure DrawMinimap(x, y : Integer);
    procedure CreateItem(ItemPat : TItemPat; Count, tx, ty : Integer; Prop: TItemProp);
    function UseItemsOnTile(ItemPat: TItemPat; Count: Integer; Prop: TItemProp; T: TPoint) : Boolean;
    procedure MoveCreatures;
    procedure CreateBullet(BulletItemPat : TItemPat; Owner, Enemy : TCreature);
    procedure Explosive(tx, ty : Integer);
    procedure Go(ADir: TMapStairsDir);
    procedure ExplosiveBombs;
  end;

var
  Map: TMap;

implementation

uses
  SysUtils, Math, PathFind, Resources, Utils, SceneInv, gm_generator, Digit,
  SceneFrame, Scenes, GlobalMap, Sound;

constructor TGround.Create;
begin
  inherited Create(MapSide, MapSide);
  SetLength(Tiles, Width, Height);
end;

procedure TGround.Render;
var
  i, j: Integer;
  Pat : TGroundPat;
begin
  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
    begin
      if (Tiles[i, j].Pat = nil) then Continue;
      Pat := Tiles[i, j].Pat;
      Render2D(Pat.Tex, i * 32, j * 32, 32, 32, 0, 1);
      if (Tiles[i, j].Dec > 0) then
        Render2D(Resource[ttBone], i * 32, j * 32, 32, 32, 0, Tiles[i, j].Dec + 1);
    end;
end;

procedure TGround.Clear(GroundName: AnsiString; DecID: Word = 0);
var
  P: TGroundPat;
  X, Y: Integer;
begin
  P := TGroundPat(GetPattern('GROUND', GroundName));
  if (P = nil) then Exit;
  for Y := 0 to Height - 1 do
    for X := 0 to Width - 1 do
    with Tiles[X, Y] do
    begin
      Pat := P;
      Dec := Math.RandomRange(0, 10);
    end;
end;

procedure TMap.Clear;
var
  I: Integer;
begin
  Ground.Clear('floor');
  Objects.Clear;
//  for I := 0 to Creatures.Count - 1 do
//    TCreature(Creatures[I]).Free;
//  Creatures.Clear;
  ItemsCnt  := 0;
  BulletsCnt:= 0;
  FireCnt   := 0;
end;

constructor TMap.Create;
begin
  inherited Create(MapSide, MapSide);
  SetLength(Fog, Width, Height);
  Ground    := TGround.Create;
  Objects   := TObjects.Create;
  Creatures := TList.Create;
  Self.Clear;
end;

destructor TMap.Destroy;
var
  I: Integer;
begin
  Ground.Free;
  Objects.Free;
  for I := 0 to Creatures.Count - 1 do
    TCreature(Creatures[I]).Free;
  Creatures.Free;
  inherited;
end;

procedure TMap.Render;
var
  i, j: Integer;
  Cr  : TCreature;
  Prop: TItemProp;
begin
  Ground.Render;
  Objects.Draw;

  for i := 0 to ItemsCnt - 1 do
    if Items[i].Count > 0 then Item_Draw(@Items[i], Items[i].Pos.X * 32, Items[i].Pos.Y * 32, 0, Prop, 0, True);

  for i := 0 to Creatures.Count - 1 do
  begin
    Cr := TCreature(Creatures[i]);
    if Cr.Life.IsMin then Continue;
    if Fog[Cr.Pos.X, Cr.Pos.Y] <> 2 then Continue;
    Cr.Draw;
  end;

  for i := 0 to BulletsCnt - 1 do
  begin
    if Bullets[i].Pat.FlyAng then Bullets[i].RotAng := Bullets[i].Ang - 45;
    RenderSprite2D(Bullets[i].Pat.Tex, Bullets[i].OPos.X + 8, Bullets[i].OPos.Y + 8, 16, 16, Bullets[i].RotAng);
  end;

  for i := 0 to FireCnt - 1 do
    RenderSprite2D(Resource[ttFire], Fire[i].X * 32, Fire[i].Y * 32, 32, 32, 0);

  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
    begin
      if Fog[i, j] = 0 then Rect2D(i * 32, j * 32, 32, 32, $000000, 255, PR2D_FILL);
      if Fog[i, j] = 1 then Rect2D(i * 32, j * 32, 32, 32, $000000, 150, PR2D_FILL);
    end;
end;

procedure Ranged(Bullet: TBullet; Cr: TCreature);
var
  Dam: TDamage;
begin
  ClearDamage(Dam);
  if Cr.HasEffect(efFreezing) then Cr.AddEffect(efFreezing, 1);
  case Bullet.Pat.Category of
    icElixir:
      begin
        Elixir.Use(Bullet.Pat.EffectTag, Cr);
        Play(ttSndVase);
        Play(ttSndBubble);
      end;
    icThrowing, icArrow, icBolt:
      begin
        Dam[dtPhys]   := Bullet.Damage.Phys;
        Dam[dtFire]   := Bullet.Damage.Fire;
        Dam[dtCold]   := Bullet.Damage.Cold;
        Dam[dtElec]   := Bullet.Damage.Elec;
        Dam[dtPoison] := Bullet.Damage.Poison;
      end;
  end;
  Bullet.Owner.Combat(Dam, Cr, Bullet.Pat);
  if (Cr = PC) then PC.Enemy := nil;
end;

procedure TMap.Update;
var
  I, J: Integer;
  Cr: TCreature;
  Bool: Boolean;
  T: TSlot;
begin
  I := 0;
  while (I < BulletsCnt) do
  begin
    Bullets[i].OPos.X := Bullets[i].OPos.X - Round(Cos(Bullets[i].Ang) * 5);
    Bullets[i].OPos.Y := Bullets[i].OPos.Y - Round(Sin(Bullets[i].Ang) * 5);
    if Bullets[i].Pat.Rot then Bullets[i].RotAng := Bullets[i].RotAng + 20;
    Bullets[i].Dist := Bullets[i].Dist - 5;
    if (Bullets[i].Dist < 0) then
    begin
      Cr := GetCreature(Bullets[i].CPos);
      if (Cr <> nil) then Ranged(Bullets[i], Cr);
      for j := i to BulletsCnt - 2 do Bullets[j] := Bullets[j + 1];
      Dec(BulletsCnt);
      Dec(i);
    end;
    Inc(i);
  end;

  j := 0;
  for i := 0 to FireCnt - 1 do
  begin
    FireTime[i] := FireTime[i] - 1;
    if (FireTime[i] = 0) then Continue;
    if (i <> j) then
    begin
      Fire[j] := Fire[i];
      FireTime[j] := FireTime[i];
    end;
    j := j + 1;
  end;
  FireCnt := j;

  I := 0;
  while (I < Creatures.Count) do
  begin
    Cr := TCreature(Creatures[i]);
    if (Cr.AtT > 0) then Cr.AtT := Cr.AtT - 1;
    if (Cr.AtT = 0) then Cr.Sp := Point(0, 0);
    if (Cr.Life.IsMin) and (Cr <> PC) then
    begin
      Bool := True;
      for j := 0 to BulletsCnt - 1 do
        if (Bullets[j].Owner = Cr) or (Bullets[j].Enemy = Cr) then Bool := False;
      if bool = True then
      begin
        for j := 0 to Cr.ItemsCnt - 1 do
          if Cr.Items[j].Count > 0 then
            CreateItem(Cr.Items[j].Pat, Cr.Items[j].Count, Cr.Pos.X, Cr.Pos.Y, Cr.Items[j].Prop);

        for T := slHead to slBoots do
          if (Cr.SlotItem[T].Item.Count > 0) then
            CreateItem(Cr.SlotItem[T].Item.Pat, Cr.SlotItem[T].Item.Count, Cr.Pos.X, Cr.Pos.Y, Cr.SlotItem[T].Item.Prop);

        for j := 0 to Creatures.Count - 1 do
          if TCreature(Creatures[j]).Enemy = Cr then TCreature(Creatures[j]).Enemy := nil;
        Cr.Free;
        Creatures.Delete(i);
        i := i - 1;
      end;
    end;
    i := i + 1;
  end;
end;

function TMap.CreateCreature(CrName: AnsiString; P: TPoint): TCreature;
var
  CrPat: TCrPat;
begin
  Result := nil;
  CrPat := TCrPat(GetPattern('CREATURE', CrName));
  if (CrPat = nil) then Exit;
  Result := TCreature.Create(CrPat);
  Result.SetPosition(P);
  Result.MP := Self;
  Creatures.Add(Result);
  if (CrName = 'PC') then
  with Result do
  begin
    ItemsCnt := InvCapacity;
    SetLength(Items, InvCapacity);
  end;
end;

function TMap.GetCreature(A: TPoint): TCreature;
var
  I: Integer;
begin
  for I := 0 to Creatures.Count - 1 do
  begin
    Result := TCreature(Creatures[I]);
    if (Result.Pos.X = A.X) and (Result.Pos.Y = A.Y) then Exit;
  end;
  Result := nil;
end;

procedure TMap.UpdateFog(C: TCreature);
var
  I, J, R: Integer;
  Cr: TCreature;
begin
  R := C.GetRadius;
  for i := 0 to Creatures.Count - 1 do
  begin
    Cr := TCreature(Creatures[i]);
    Cr.InFog := (Fog[Cr.Pos.X, Cr.Pos.Y] <> 2);
  end;

  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
      if (Fog[i, j] <> 0) then Fog[i, j] := 1;

  for j := C.Pos.Y - R to C.Pos.Y + R do
    for i := C.Pos.X - R to C.Pos.X + R do
    begin
      if (i < 0) or (j < 0) or (i >= Width) or (j >= Height) then Continue;
      if (Round(GetDist(C.Pos, Point(i, j))) > R) then Continue;
      LineOfSight(C.Pos, Point(i, j), True);
    end;

  for i := 0 to Creatures.Count - 1 do
  begin
    Cr := TCreature(Creatures[i]);
    if (Cr.Team = PC.Team) then Continue;
    if (Fog[Cr.Pos.X, Cr.Pos.Y] = 2) and Cr.InFog then
    begin
      PC.WalkTo.X := -1;
      Break;
    end;
  end;
end;

function TMap.LineOfSight(A, B: TPoint; UpdFog : Boolean) : Boolean;
var
  I, E : Integer;
  D, P, J, Z: TPoint;
begin
  Result := False;
  P.X := A.X;
  P.Y := A.Y;
  D.X := B.X - A.X;
  D.Y := B.Y - A.Y;
  J.X := 0;
  J.Y := 0;
  if D.X >= 0 then J.X := 1;
  if D.X < 0 then
  begin
    J.X := -1;
    D.X := abs(D.X);
  end;
  if D.Y >= 0 then J.Y := 1;
  if D.Y < 0 then
  begin
    J.Y := -1;
    D.Y := abs(D.Y);
  end;
  Z.X := D.X * 2;
  Z.Y := D.Y * 2;

  if D.X > D.Y then
  begin
    E := Z.Y - D.X;
    for i := 0 to D.X do
    begin
      if UpdFog then Fog[P.X, P.Y] := 2;
      if Objects.Obj[p.x, p.y] <> nil then
        if Objects.Obj[p.x, p.y].BlockLook then Exit;
      if E >= 0 then
      begin
        E := E - Z.X;
        p.y  := p.y + J.Y;
      end;
      E := E + Z.Y;
      p.x  := p.x + J.X;
    end;
  end else
  begin
    E := Z.X - D.Y;
    for i := 0 to D.Y do
    begin
      if UpdFog then Fog[p.x, p.y] := 2;
      if Objects.Obj[p.x, p.y] <> nil then
        if Objects.Obj[p.x, p.y].BlockLook then Exit;
      if E >= 0 then
      begin
        E := E - Z.Y;
        P.X  := P.X + J.X;
      end;
      E := E + Z.X;
      P.Y  := P.Y + J.Y;
    end;
  end;
  Result := True;
end;

procedure TMap.DrawMinimap(x, y : Integer);
var
  I, J, C: Integer;
  Cr  : TCreature;
const
  S = 3;
begin
  Rect2D(X, Y, Width * S, Height * S, $333333, 255, PR2D_FILL);
  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
    begin
      if Fog[i, j] = 0 then
      begin
        Rect2D(x + i * S, y + j * S, S, S, $000000, 255, PR2D_FILL);
        Continue;
      end;
      if (Objects.Obj[i, j] <> nil) then
        Rect2D(x + i * S, y + j * S, S, S, Objects.Obj[i, j].Pat.Color, 255, PR2D_FILL);
    end;

  for i := 0 to Creatures.Count - 1 do
  begin
    Cr := TCreature(Creatures[i]);
    if Cr.Life.IsMin then Continue;
    if (Fog[Cr.Pos.X, Cr.Pos.Y] <> 2) then Continue;
    case Cr.Team of
      0: C := $FFFFFF;
      else C := $FF0000;
    end;
    Circ2D(X + Cr.Pos.X * S + 1 , Y + Cr.Pos.Y * S + 1, S, C, 255, 32, PR2D_FILL);
  end;
  Rect2D(X, Y, Width * S, Height * S, cDkYellow, 255);
  if (Map.Name <> '') then
    TextOut(Font[ttFont1], Span + X + (Width * S), Span + Y, 1, 0,
      Map.Name + ' (' + IntToStr(PCDeep) + '/' + IntToStr(PCMapLevel) + ')', 255, cWhite);
end;

procedure TMap.CreateItem(ItemPat: TItemPat; Count, tx, ty: Integer; Prop: TItemProp);
begin
  if (ItemPat.Category = icSkill) then Exit;
  ItemsCnt := ItemsCnt + 1; {I}
  SetLength(Items, ItemsCnt);
  Items[ItemsCnt - 1].Pat := ItemPat;
  Items[ItemsCnt - 1].Count := Count;
  Items[ItemsCnt - 1].Prop := Prop;
  Items[ItemsCnt - 1].Pos.X := tx;
  Items[ItemsCnt - 1].Pos.Y := ty;
  AddItemProp(@Items[ItemsCnt - 1]);
end;

function TMap.UseItemsOnTile(ItemPat: TItemPat; Count: Integer; Prop: TItemProp; T: TPoint): Boolean;
var
  B: Boolean;
  I: Integer;
  Cr: TCreature;
begin
  Result := False;
  if (T.X < 0) or (T.Y < 0) or (T.X >= Width) or (T.Y >= Height) then Exit;

  if Objects.Obj[T.X, T.Y] <> nil then
  begin
    B := False;
    if (Objects.Obj[T.X, T.Y].Pat.Name = 'DOOR') and (Objects.Obj[T.X, T.Y].FrameN = 1) then B := True;
    if Objects.Obj[T.X, T.Y].Pat.Container then
    begin
      if (Objects.Obj[T.X, T.Y].Pat.Name = 'CHEST') and (Objects.Obj[T.X, T.Y].FrameN = 0) then Exit;
      if Objects.Obj[T.X, T.Y].CreateItem(Drag.Item.Pat, Drag.Count, Drag.Prop) then
      begin
        Result := True;
        Exit;
      end;
    end;
    if not B then Exit;
  end;

  for i := 0 to Creatures.Count - 1 do
  begin
    Cr := TCreature(Creatures[i]);
    if (Cr = PC) then Continue;
    if (T.X = Cr.Pos.X) and (T.Y = Cr.Pos.Y) then Exit;
  end;

  // Положить предмет(ы) на пол
  CreateItems(ItemPat, Count, T.X, T.Y, Prop);
  Play(ttSndDrop);
  PlayItem(ItemPat, Prop);

  Result := True;
end;

procedure TMap.MoveCreatures;
var
  i, j, d, x, y : Integer;
  Cr, Cr2, e    : TCreature;
  Updt          : Boolean;
  V             : Integer;
begin
  for i := 0 to Creatures.Count - 1 do
  begin
    Cr := TCreature(Creatures[i]);
    if (Cr = PC) then Continue;
    if Cr.Life.IsMin then Continue;
    if Cr.HasEffect(efFreezing) then Continue;

    if (Cr.SlotItem[slRHand].Item.Count > 0) and (Cr.SlotItem[slLHand].Item.Count = 0) then
      if (Cr.SlotItem[slRHand].Item.Pat.Category in RangedWpnCategories) then
      begin
        Cr.CreateItem(Cr.SlotItem[slRHand].Item.Pat, 1, Cr.SlotItem[slRHand].Item.Prop, V);
        Cr.SlotItem[slRHand].Item.Count := 0;
      end;

    e := Cr.Enemy;

    if Cr.Enemy = nil then
      for j := 0 to Creatures.Count - 1 do
      begin
        if i = j then Continue;
        Cr2 := TCreature(Creatures[j]);
        if (Cr.Team = Cr2.Team) then Continue;
        if (GetDist(Cr.Pos, Cr2.Pos) > Cr.GetRadius) then Continue; {?}
        if LineOfSight(Cr.Pos, Cr2.Pos, False) then Cr.Enemy := Cr2;
        if (Cr.Enemy <> nil) then Break;
      end;

    if (Cr.Enemy <> nil) then
    begin
      CreateWave(Self, Cr.Pos.X, Cr.Pos.Y, Cr.Enemy.Pos.X, Cr.Enemy.Pos.Y, True, True);
      D := Wave[Cr.Enemy.Pos.X, Cr.Enemy.Pos.Y];
      for j := 0 to Creatures.Count - 1 do
      begin
        if (i = j) then Continue;
        Cr2 := TCreature(Creatures[j]);
        if (Cr.Team = Cr2.Team) then Continue;
        if (Wave[Cr2.Pos.X, Cr2.Pos.Y] > 1) and (Wave[Cr2.Pos.X, Cr2.Pos.Y] < d) then
        begin
          Cr.Enemy := Cr2;
          d := Wave[Cr2.Pos.X, Cr2.Pos.Y];
        end;
      end;
      if d < 2 then Cr.Enemy := nil;
    end;

    if (Cr.Enemy = nil) and (Fog[Cr.Pos.X, Cr.Pos.Y] = 2) then
    begin
      CreateWave(Self, Cr.Pos.X, Cr.Pos.Y, -1, 0, True, True);
      d := 10;
      for j := 0 to Creatures.Count - 1 do
      begin
        if (i = j) then Continue;
        Cr2 := TCreature(Creatures[j]);
        if (Cr.Team = Cr2.Team) then Continue;
        if (Wave[Cr2.Pos.X, Cr2.Pos.Y] > 1) and (Wave[Cr2.Pos.X, Cr2.Pos.Y] < d) then
        begin
          Cr.Enemy := Cr2;
          d := Wave[Cr2.Pos.X, Cr2.Pos.Y];
        end;
      end;
    end;

    if (Cr.Team = 0) and (Cr.Enemy = nil) then
    begin
      Cr.WalkTo.X := -1;
      if not((ABS(Cr.Pos.X - PC.Pos.X) < 3) and (ABS(Cr.Pos.Y - PC.Pos.Y) < 3)) then Cr.WalkTo := PC.Pos;//Point(Hero.H.X, Hero.H.Y);
    end;

    Updt := True;

    if (Cr.Enemy <> nil) and (Cr.Team <> 0) then
      if not((ABS(Cr.Pos.X - Cr.Enemy.Pos.X) < 2) and (ABS(Cr.Pos.Y - Cr.Enemy.Pos.Y) < 2)) then
        if Random(10) = 0 then Updt := False;

    if (e = nil) and (Cr.Enemy <> nil) and (Cr.NoAtack = True) then
    begin
      Cr.NoAtack := False;
      Updt := False;
    end;

    if Updt and (Cr.Pat.Name = 'NECROMANCER') and (Cr.Enemy <> nil) and (Random(5) = 0) then
    begin
      x := 0;
      y := 0;
      if ABS(Cr.Pos.X - Cr.Enemy.Pos.X) > ABS(Cr.Pos.Y - Cr.Enemy.Pos.Y) then x := 1 else y := 1;
      if (x = 1) and (Cr.Pos.X > Cr.Enemy.Pos.X) then x := -1;
      if (y = 1) and (Cr.Pos.Y > Cr.Enemy.Pos.Y) then y := -1;
      if Objects.Obj[Cr.Pos.X + x, Cr.Pos.Y + y] = nil then
        if (GetCreature(Point(Cr.Pos.X + x, Cr.Pos.Y + y)) = nil) then
        begin
          Cr2 := Map.CreateCreature('Skelet', Point(Cr.Pos.X + X, Cr.Pos.Y + Y));
          Cr2.Team := Cr.Team;
          Cr2.RandEquip();
          Cr.Enemy := nil;
          Updt := False;
        end;
    end;

    if Updt and (Cr.Team <> 0) and (Cr.Enemy <> nil) then
    begin
      CreateWave(Self, Cr.Pos.X, Cr.Pos.Y, -1, 0, True, True);
      for j := 0 to Creatures.Count - 1 do
      begin
        Cr2 := TCreature(Creatures[j]);
        if (Cr.Team <> Cr2.Team) then Continue;
        if (Cr2.Enemy <> nil) then Continue;
        if (Wave[Cr2.Pos.X, Cr2.Pos.Y] > 1) and (Wave[Cr2.Pos.X, Cr2.Pos.Y] < 8) then Cr2.Enemy := Cr.Enemy;
      end
    end;

    if Updt then Cr.Update;
  end;

  for I := 0 to BulletsCnt - 1 do
  begin
    Cr  := Bullets[i].Owner;
    Cr2 := Bullets[i].Enemy;
    Bullets[i].CPos := Cr2.Pos;
    Bullets[i].Ang  := Round(Angle(Cr.Pos.X * 32, Cr.Pos.Y * 32, Cr2.Pos.X * 32, Cr2.Pos.Y * 32));
    Bullets[i].Dist := GetDist(Point(Cr.Pos.X * 32, Cr.Pos.Y * 32), Point(Cr2.Pos.X * 32, Cr2.Pos.Y * 32));
  end;
end;

procedure TMap.CreateBullet(BulletItemPat: TItemPat; Owner, Enemy: TCreature);
var
  i : Integer;
begin
  if (BulletItemPat.ManaCost > 0) then
  begin
    if (Owner.Mana.Cur < BulletItemPat.ManaCost) then
    begin
      if (Owner = PC) then NeedManaMsg;
      Exit;
    end;
    Owner.Mana.Dec(BulletItemPat.ManaCost);
  end;

  BulletsCnt := BulletsCnt + 1;
  SetLength(Bullets, BulletsCnt);
  i := BulletsCnt - 1;
  Bullets[i].Pat    := BulletItemPat;
  Bullets[i].Owner  := Owner;
  Bullets[i].Enemy  := Enemy;
  Bullets[i].CPos   := Enemy.Pos;
  Bullets[I].OPos   := Point(Owner.Pos.X * 32, Owner.Pos.Y * 32);
  Bullets[i].Ang    := Round(Angle(Owner.Pos.X * 32, Owner.Pos.Y * 32, Enemy.Pos.X * 32, Enemy.Pos.Y * 32));
  Bullets[i].Dist   := GetDist(Point(Owner.Pos.X * 32, Owner.Pos.Y * 32), Point(Enemy.Pos.X * 32, Enemy.Pos.Y * 32));
  with Bullets[i] do
  if (Owner.SlotItem[slRHand].Item.Count > 0) then
  begin
    // Weapons
    Damage.Phys.Min   := Owner.GetParamValue('DamPhysMin');
    Damage.Phys.Max   := Owner.GetParamValue('DamPhysMax');
    Damage.Fire.Min   := Owner.GetParamValue('DamFireMin');
    Damage.Fire.Max   := Owner.GetParamValue('DamFireMax');
    Damage.Cold.Min   := Owner.GetParamValue('DamColdMin');
    Damage.Cold.Max   := Owner.GetParamValue('DamColdMax');
    Damage.Elec.Min   := Owner.GetParamValue('DamElecMin');
    Damage.Elec.Max   := Owner.GetParamValue('DamElecMax');
    Damage.Poison.Min := Owner.GetParamValue('DamPoisonMin');
    Damage.Poison.Max := Owner.GetParamValue('DamPoisonMax');
  end else
  if (Owner.SpellPower > 0) then
  begin
    // Magics
    Damage.Phys   := Pat.Damage.Phys;
    Damage.Fire   := Pat.Damage.Fire;
    Damage.Cold   := Pat.Damage.Cold;
    Damage.Elec   := Pat.Damage.Elec;
    Damage.Poison := Pat.Damage.Poison;
    Owner.SpellPower := 0;
  end else begin
    // Without weapons
    Damage.Phys.Min := Owner.GetParamValue('Strength') div 2;
    Damage.Phys.Max := Owner.GetParamValue('Strength');
  end;
end;

procedure TMap.Explosive(tx, ty : Integer);
var
  i, j : Integer;
  Cr   : TCreature;
begin
  for j := ty - 1 to ty + 1 do
    for i := tx - 1 to tx + 1 do
    begin
      if (i < 0) or (j < 0) or (i >= Width) or (j >= Height) then Continue;
      {if Objects.Obj[i, j] <> nil then
        if Objects.Obj[i, j].Pat.Name = 'WALL' then Continue;  }
      if Objects.Obj[i, j] <> nil then FreeAndNil(Objects.Obj[i, j]);

      Cr := GetCreature(Point(i, j));
      if Cr <> nil then
      begin
        if Cr.HasEffect(efFreezing) then Cr.AddEffect(efFreezing, 1);
      end;

      FireCnt := FireCnt + 1;
      SetLength(Fire, FireCnt);
      SetLength(FireTime, FireCnt);
      Fire[FireCnt - 1] := Point(i, j);
      FireTime[FireCnt - 1] := 10;
    end;
  PC.WalkTo.X := -1;
  PC.Enemy := nil;
end;

procedure TMap.ExplosiveBombs;
var
  i, j, k : Integer;
  Cr      : TCreature;
  Obj     : TObj;
begin
  i := 0;
  while i < ItemsCnt do
  begin
    if Items[i].Pat.Name = 'FBOMB' then
    begin
      Explosive(Items[i].Pos.X, Items[i].Pos.Y);
      for j := i to ItemsCnt - 2 do
        Items[j] := Items[j + 1];
      ItemsCnt := ItemsCnt - 1;
      SetLength(Items, ItemsCnt);
      i := i - 1;
    end;
    i := i + 1;
  end;

  for i := 0 to Creatures.Count - 1 do
  begin
    Cr := TCreature(Creatures[i]);
    for j := 0 to Cr.ItemsCnt - 1 do
      if Cr.Items[j].Count > 0 then
        if Cr.Items[j].Pat.Name = 'FBOMB' then
        begin
          Explosive(Cr.Pos.X, Cr.Pos.Y);
          Cr.Items[j].Count := 0;
        end
  end;

  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
      if Objects.Obj[i, j] <> nil then
      begin
        Obj := Objects.Obj[i, j];
        if Obj.Pat.Container = False then Continue;
        for k := 0 to Obj.ItemsCnt - 1 do
          if Obj.Items[k].Count > 0 then
            if Obj.Items[k].Pat.Name = 'FBOMB' then
            begin
              Explosive(i, j);
              Break;
            end;
      end;
end;

procedure TMap.CreateSpot(Name: AnsiString; P: TPoint; Size: Byte);
var
  N, S, E, W, I: Integer;

  procedure Put();
  var
    O: TObjPat;
  begin
    O := TObjPat(GetPattern('OBJECT', Name));
    if Objects.Obj[P.X, P.Y] = nil then
    begin
      Objects.ObjCreate(P.X, P.Y, O);
    end;
  end;

begin
  for I := 1 to Size do
  begin
    N := Random(7);
    E := Random(7);
    S := Random(7);
    W := Random(7);
    if (N = 1) then
    begin
      P.X := P.X - 1;
      if (P.X < 0) then P.X := 0;
      Put;
    end;
    if (W = 1) then
    begin
      P.Y := P.Y - 1;
      if (P.Y < 0) then P.Y := 0;
      Put;
    end;
    if (S = 1) then
    begin
      P.X := P.X + 1;
      if (P.X > Width - 1) then P.X := Width - 1;
      Put;
    end;
    if (E = 1) then
    begin
      P.Y := P.Y + 1;
      if (P.Y > Height - 1) then P.Y := Height - 1;
      Put;
    end;
  end;
end;

procedure TMap.Go(ADir: TMapStairsDir);
var
  E: TExplodeResult;
  P: TMapPat;
  I: Integer;
begin
  case ADir of
    sdTown:
    begin
      IsPortal := True;
      IsTown := True;
    end;
    sdUp:
    begin
      IsWorld := True;
    end;
    sdDown:
    begin
      IsWorld := False;
      IsGate := False;
      IsTown := False;

      E := nil;
      E := Explode(',', AllMapsID);
      for I := 0 to High(E) do
      begin
        if (E[I] = '') then Continue;
        P := TMapPat(GetPattern('MAP', E[I]));
        if (P = nil) then Continue;
        PCCurMapID := E[I];
        if ((P.X = PC.GMapPos.X) and (P.Y = PC.GMapPos.Y) and (P.Z = PCDeep + 1)) then
        begin
          Inc(PCDeep);
          PCDeep := Clamp(PCDeep, 0, MapDeepMax);
          if not (System.Pos(P.Name, PCAllMapsID) > 0) then
            PCAllMapsID := PCAllMapsID + P.Name + ',';
          Gate.LoadMap(P);
          Exit;
        end;
      end;
    end;
  end;
end;

procedure TMap.SetName(const Value: AnsiString);
begin
  FName := Value;
end;

end.
