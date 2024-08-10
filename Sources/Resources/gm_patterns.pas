unit gm_patterns;

interface

uses
  gm_engine, SysUtils, Classes, Types, uDatFile, XML;

type
  TPattern = class
    Name: AnsiString;
    Title: AnsiString;
    pType: AnsiString;
    Next: TPattern;
    Tex: TTexture;
    Offset: TPoint;
    Frame: TPoint;
    Level: Integer;
    Hint: AnsiString;
  end;

type
  TGroundPat = class(TPattern);

type
  TObjPat = class(TPattern)
    Color: Integer;
    IsWall: Boolean;
    BlockWalk: Boolean;
    BlockLook: Boolean;
    Container: Boolean;
  end;

type
  TCrPat = class(TPattern)
    ParamValue: array of Integer;
    ParamsCnt: Integer;
    Equip: AnsiString;
    Skills: AnsiString;
    Exp: Integer;
  end;

type
  TBonus = record
    Strength: Integer;
    Stamina: Integer;
    Dexterity: Integer;
    Agility: Integer;
    Wisdom: Integer;
    Intellect: Integer;
    Life: Integer;
    Mana: Integer;
    RefLife: Integer;
    RefMana: Integer;
    ResFire: Integer;
    ResCold: Integer;
    ResElec: Integer;
    ResPoison: Integer;
  end;

type
  TSkillItemPat = class(TPattern)
    SkillTag: Integer;
    Active: Boolean;
    Top, Left: Integer;
    Cooldown: Integer;
    Bonus: TBonus;
  end;

type
  TEfEnum = (efNone, efPoison, efParal, efFreezing, efHypnosis, efVampirism,
    efLight, efResPoison, efInvulnerability, efBlindness, efManaShield, efRust,
    efWeakness);

type
  TEfRec = record
    Name: AnsiString;
    Enum: TEfEnum;
  end;

const
  AllEffects: array [0 .. Ord(High(TEfEnum))] of TEfRec = ((Name: '';
    Enum: efNone;), (Name: 'POISON'; Enum: efPoison;
    ), (Name: 'PARAL'; Enum: efParal;), (Name: 'FREEZING'; Enum: efFreezing;
    ), (Name: 'HYPNOSIS'; Enum: efHypnosis;
    ), (Name: 'VAMPIRIZM'; Enum: efVampirism;
    ), (Name: 'RESPOISON'; Enum: efResPoison;
    ), (Name: 'INVULNERA'; Enum: efInvulnerability;
    ), (Name: 'BLINDNESS'; Enum: efBlindness;), (Name: 'LIGHT'; Enum: efLight;
    ), (Name: 'MANASHIELD'; Enum: efManaShield;), (Name: 'RUST'; Enum: efRust;
    ), (Name: 'WEAKNESS'; Enum: efWeakness;));

type
  TCatEnum = (icNone, icCoins, icSkill, icJewelry, icAmulet, icRing, icScroll,
    icElixir, icKey, icThrowing, icArrow, icBolt, icTalisman, icArmor, icHelmet,
    icBelt, icCloak, icBoots, icGloves, icShield, icBow, icCrossbow, icAxe,
    icSword, icSpear, icStaff);

type
  TCatRec = record
    Name: AnsiString;
    Enum: TCatEnum;
  end;

const
  Categories: array [0 .. Ord(High(TCatEnum))] of TCatRec = ((Name: '';
    Enum: icNone;), (Name: 'SKILL'; Enum: icSkill;
    ), (Name: 'JEWELRY'; Enum: icJewelry;), (Name: 'AMULET'; Enum: icAmulet;
    ), (Name: 'RING'; Enum: icRing;), (Name: 'COINS'; Enum: icCoins;
    ), (Name: 'TALISMAN'; Enum: icTalisman;), (Name: 'SCROLL'; Enum: icScroll;
    ), (Name: 'ELIXIR'; Enum: icElixir;), (Name: 'KEY'; Enum: icKey;
    ), (Name: 'THROWING'; Enum: icThrowing;), (Name: 'ARROW'; Enum: icArrow;
    ), (Name: 'BOLT'; Enum: icBolt;), (Name: 'ARMOR'; Enum: icArmor;
    ), (Name: 'HELMET'; Enum: icHelmet;), (Name: 'BELT'; Enum: icBelt;
    ), (Name: 'CLOAK'; Enum: icCloak;), (Name: 'BOOTS'; Enum: icBoots;
    ), (Name: 'GLOVES'; Enum: icGloves;), (Name: 'SHIELD'; Enum: icShield;
    ), (Name: 'BOW'; Enum: icBow;), (Name: 'CROSSBOW'; Enum: icCrossbow;
    ), (Name: 'AXE'; Enum: icAxe;), (Name: 'SWORD'; Enum: icSword;
    ), (Name: 'SPEAR'; Enum: icSpear;), (Name: 'STAFF'; Enum: icStaff;));

const
  ThrowingCategories = [icThrowing, icElixir];
  // Предмет можно бросать во врагов
  ConsumableCategories = [icScroll, icElixir]; // Предмет можно использовать ПКМ
  RangedWpnCategories = [icBow, icCrossbow]; // Дист. оружие
  // Предмет имеет свойство "материал"
  MaterialPCategories = [icTalisman, icArmor, icHelmet, icBelt, icCloak,
    icBoots, icGloves, icShield, icBow, icCrossbow, icAxe, icSword,
    icSpear, icStaff];

type
  TDamRange = record
    Min, Max: Integer;
  end;

type
  TDamSingleRange = record
    Min, Max: Single;
  end;

type
  TDamType = (dtPhys, dtFire, dtCold, dtElec, dtPoison);

const
  DamTypeColor: array [TDamType] of Integer = (cPhys, cFire, cCold,
    cElec, cPoison);

type
  TDamRec = record
    Phys: TDamRange;
    Fire: TDamRange;
    Cold: TDamRange;
    Elec: TDamRange;
    Poison: TDamRange;
  end;

type
  TResist = array [TDamType] of Integer;
  TDamage = array [TDamType] of TDamRange;

type
  TItemPat = class(TSkillItemPat)
    CanGroup: Boolean;
    Equip: AnsiString;
    AllowedSuf: AnsiString;
    AllowedMat: AnsiString;
    EquipTex: TTexture;
    Gender: Integer;
    EffectTag: Integer;
    Category: TCatEnum;
    Damage: TDamRec;
    Armor: Integer;
    Block: Integer;
    Durability: Integer;
    Chance: Integer;
    MinCount: Integer;
    MaxCount: Integer;
    ManaCost: Integer;
    Rot: Boolean;
    FlyAng: Boolean;
    UseMaterial: Boolean;
    UseAdvSuf: Boolean;
  end;

type
  TAffixPat = class(TPattern)
    Rarity: Integer;
    Title1: AnsiString;
    Title2: AnsiString;
    Title3: AnsiString;
    Title4: AnsiString;
    Durability: Single;
    Armor: Single;
    DamPhys: TDamSingleRange;
    DamPoison: TDamSingleRange;
    DamFire: TDamSingleRange;
    DamCold: TDamSingleRange;
    DamElec: TDamSingleRange;
  end;

type
  TSuffixPat = class(TAffixPat)
    Bonus: TBonus;
    Radius: Integer;
  end;

type
  TMaterialPat = class(TAffixPat)
    MatClass: AnsiString;
    Sound: TSound;
  end;

type
  TMapPat = class(TPattern)
    TownID: Integer;
    Deep: Integer;
    X, Y, Z: Integer;
  end;

type
  TEfPat = class(TPattern)

  end;

var
  Patterns: TPattern;

function GetPattern(pType, Name: AnsiString): TPattern;
function GetItemPat(Name: AnsiString): TItemPat;
procedure LoadDAT(FileName: AnsiString);
procedure Init(PatDir: AnsiString);
procedure Free;

var
  MaterialClasses: TStringList;

implementation

uses gm_item, Stat, Utils, gm_map, GlobalMap;

procedure LoadBonus(var Bonus: TBonus; Dat: TDat);
begin
  with Bonus do
  begin
    Strength := Dat.Param('Strength').Int(0);
    Stamina := Dat.Param('Stamina').Int(0);
    Dexterity := Dat.Param('Dexterity').Int(0);
    Agility := Dat.Param('Agility').Int(0);
    Wisdom := Dat.Param('Wisdom').Int(0);
    Intellect := Dat.Param('Intellect').Int(0);
    Life := Dat.Param('Life').Int(0);
    Mana := Dat.Param('Mana').Int(0);
    RefLife := Dat.Param('RefLife').Int(0);
    RefMana := Dat.Param('RefMana').Int(0);
    ResFire := Dat.Param('ResFire').Int(0);
    ResCold := Dat.Param('ResCold').Int(0);
    ResElec := Dat.Param('ResElec').Int(0);
    ResPoison := Dat.Param('ResPoison').Int(0);
  end;
end;

procedure AddMatClass(C, P: AnsiString);
var
  I, J: Integer;
  E, F: TExplodeResult;
begin
  F := nil;
  E := nil;
  for I := 0 to MaterialClasses.Count - 1 do
  begin
    if (System.Copy(MaterialClasses[I], 1, Length(C)) = C) then
    begin
      F := Explode(':', MaterialClasses[I]);
      E := Explode(',', F[1]);
      for J := 0 to High(E) do
        if (E[J] = P) then
          Exit;
      MaterialClasses[I] := MaterialClasses[I] + P + ',';
      Exit;
    end;
  end;
  MaterialClasses.Append(C + ':' + P + ',');
end;

function GetPattern(pType, Name: AnsiString): TPattern;
begin
  pType := UpperCase(pType);
  Name := UpperCase(Name);
  Result := Patterns;
  while (Result <> nil) do
  begin
    if (Result.pType = pType) and (Result.Name = Name) then
      Exit;
    Result := Result.Next;
  end;
end;

function GetItemPat(Name: AnsiString): TItemPat;
begin
  Result := TItemPat(GetPattern('ITEM', Name));
end;

procedure LoadDAT(FileName: AnsiString);
var
  Dat: TDat;
  Pat: TPattern;
  S: AnsiString;
  FDir: AnsiString;
  I: Integer;
  E: TExplodeResult;

  function LoadDamage(Param: AnsiString): TDamRange;
  var
    E: TExplodeResult;
    S: AnsiString;
  begin
    E := nil;
    Result.Min := 0;
    Result.Max := 0;
    S := Dat.Param(Param).Str('0-0');
    E := Explode('-', S);
    Result.Min := StrToInt(E[0]);
    if (High(E) > 0) then
      Result.Max := StrToInt(E[1])
    else
      Result.Max := Result.Min;
    Result.Min := Clamp(Result.Min, 0, 1000);
    Result.Max := Clamp(Result.Max, 0, 1000);
  end;

  function LoadSingleDamage(Param: AnsiString): TDamSingleRange;
  var
    E: TExplodeResult;
    F: Integer;
    S: AnsiString;
  begin
    E := nil;
    Result.Min := 0;
    Result.Max := 0;
    S := Dat.Param(Param).Str('1-1');
    E := Explode('-', S);
    Val(E[0], Result.Min, F);
    if (F <> 0) then
      Result.Min := 1;
    if (High(E) > 0) then
    begin
      Val(E[1], Result.Max, F);
      if (F <> 0) then
        Result.Max := 1;
    end
    else
      Result.Max := Result.Min;
  end;

begin
  E := nil;
  Dat := TDat.Create;
  Dat.LoadFromFile(FileName);

  Pat := nil;
  if (UpperCase(Dat.Param('Type').Str('')) = 'GROUND') then
    Pat := TGroundPat.Create;
  if (UpperCase(Dat.Param('Type').Str('')) = 'OBJECT') then
    Pat := TObjPat.Create;
  if (UpperCase(Dat.Param('Type').Str('')) = 'CREATURE') then
    Pat := TCrPat.Create;
  if (UpperCase(Dat.Param('Type').Str('')) = 'ITEM') then
    Pat := TItemPat.Create;
  if (UpperCase(Dat.Param('Type').Str('')) = 'SUFFIX') then
    Pat := TSuffixPat.Create;
  if (UpperCase(Dat.Param('Type').Str('')) = 'MATERIAL') then
    Pat := TMaterialPat.Create;
  if (UpperCase(Dat.Param('Type').Str('')) = 'MAP') then
    Pat := TMapPat.Create;
  if (UpperCase(Dat.Param('Type').Str('')) = 'EFFECT') then
    Pat := TEfPat.Create;

  if Pat = nil then
  begin
    Dat.Free;
    Exit;
  end;

  Pat.pType := UpperCase(Dat.Param('Type').Str(''));
  Pat.Name := GetFileName(FileName);
  Pat.Name := UpperCase(Dat.Param('Name').Str(Pat.Name));
  Pat.Title := Dat.Param('Title').Str(Pat.Name);
  Pat.Next := Patterns;
  Patterns := Pat;

  FDir := GetDirectory(FileName);

  with Pat do
  begin
    S := Dat.Param('Texture').Str('');
    if (S = '') then
      S := Dat.Param('Sprite').Str('');
    Tex := LoadTexture(FDir + S);

    Offset.X := Dat.Param('OffsetX').Int(0);
    Offset.Y := Dat.Param('OffsetY').Int(0);

    Frame.X := Dat.Param('FramesWidth').Int(32);
    Frame.Y := Dat.Param('FramesHeight').Int(32);

    Level := Dat.Param('Level').Int(0);
    Hint := Dat.Param('Hint').Str('');

    if (Frame.X <> 0) and (Frame.Y <> 0) then
      SetFrameSize(Tex, Frame.X, Frame.Y);
  end;

  if (Pat.pType = 'MAP') then
  begin
    with TMapPat(Pat) do
    begin
      AllMapsID := AllMapsID + Name + ',';
      S := Dat.Param('Position').Str('0,0,0');
      E := Explode(',', S);
      X := Clamp(StrToInt(E[0]), 0, GMapWidth - 1);
      Y := Clamp(StrToInt(E[1]), 0, GMapHeight - 1);
      Z := Clamp(StrToInt(E[2]), 0, MapDeepMax);
      Deep := Clamp(Dat.Param('Deep').Int(0), 0, 9);
      TownID := Dat.Param('TownID').Int(0);
      if (PatGMap[X, Y] = nil) and (Z = 0) then
        PatGMap[X, Y] := TMapPat(Pat);
      Level := Clamp(Level, 0, MapLevelMax);
    end;

    // Box(AllMapsID);

  end;

  if Pat.pType = 'GROUND' then
    with TGroundPat(Pat) do
    begin

    end;

  if Pat.pType = 'OBJECT' then
    with TObjPat(Pat) do
    begin
      Color := Dat.Param('Color').Int($00FFFFFF);
      IsWall := Dat.Param('Wall').Bool(False);
      if IsWall then
        BlockWalk := True;
      if IsWall then
        BlockLook := True;
      BlockWalk := Dat.Param('BlockWalk').Bool(BlockWalk);
      BlockLook := Dat.Param('BlockLook').Bool(BlockLook);
      Container := Dat.Param('Container').Bool(False);
    end;

  if Pat.pType = 'CREATURE' then
    with TCrPat(Pat) do
    begin
      Exp := Dat.Param('Exp').Int(1);
      SetLength(ParamValue, CrStatsCnt);
      for I := 0 to CrStatsCnt - 1 do
        if (I < 6) then
          ParamValue[I] := Dat.Param(CrStats[I].ID).Int(5)
        else
          ParamValue[I] := Dat.Param(CrStats[I].ID).Int(0);
      Equip := UpperCase(Dat.Param('Equip').Str(''));
      Skills := UpperCase(Dat.Param('Skills').Str(''));
    end;

  if Pat.pType = 'ITEM' then // Skills
    with TSkillItemPat(Pat) do
    begin
      SkillTag := Dat.Param('SkillTag').Int(0);
      Active := Dat.Param('Active').Bool(False);
      Top := Dat.Param('Top').Int(0);
      Left := Dat.Param('Left').Int(0);
      Cooldown := Dat.Param('Cooldown').Int(0);
      if not Active then
        Cooldown := 0;
      LoadBonus(Bonus, Dat);
    end;

  if Pat.pType = 'ITEM' then // Items
    with TItemPat(Pat) do
    begin
      Category := icNone;
      S := UpperCase(Dat.Param('Category').Str(''));
      for I := 0 to Length(Categories) - 1 do
        if (S = Categories[I].Name) then
        begin
          Category := Categories[I].Enum;
          Break;
        end;

      AllItemsID := AllItemsID + Name + ',';
      EffectTag := Dat.Param('EffectTag').Int(0);
      if (EffectTag > 0) then
      begin
        S := '';
        if (Category = icElixir) then
          S := AnsiLowerCase(Elixir.GetColorName(EffectTag).En) + '.png';
        if (Category = icScroll) then
          S := AnsiLowerCase(Scroll.GetColorName(EffectTag).En) + '.png';
        Tex := LoadTexture(FDir + S);
      end;
      ManaCost := Clamp(Dat.Param('ManaCost').Int(0), 0, 50);
      Chance := Clamp(Dat.Param('Rarity').Int(0), 0, 1000);
      Gender := Clamp(Dat.Param('Gender').Int(1), 1, 4);
      MinCount := Dat.Param('MinCount').Int(1);
      MaxCount := Clamp(Dat.Param('MaxCount').Int(1), 1, 99);
      CanGroup := Dat.Param('CanGroup').Bool(False);
      if (Category in ConsumableCategories) then
        CanGroup := True;
      Equip := UpperCase(Dat.Param('Equip').Str(''));

      UseAdvSuf := Dat.Param('UseAdvSuf').Bool(True);
      if UseAdvSuf then
        S := 'superior,damaged,'
      else
        S := '';
      AllowedSuf := UpperCase(S + Dat.Param('AllowedSuffixes').Str(''));
      AllowedMat := UpperCase(Dat.Param('AllowedMaterials').Str(''));
      UseMaterial := Dat.Param('UseMaterial').Bool(True);

      Durability := Dat.Param('Durability').Int(0);
      if CanGroup then
      begin
        AllowedSuf := '';
        AllowedMat := '';
        Durability := 0;
      end;
      if (Category = icElixir) then
        Equip := 'RHAND';

      Damage.Phys := LoadDamage('DamPhys');
      Damage.Fire := LoadDamage('DamFire');
      Damage.Cold := LoadDamage('DamCold');
      Damage.Elec := LoadDamage('DamElec');
      Damage.Poison := LoadDamage('DamPoison');

      Armor := Clamp(Dat.Param('Armor').Int(0), 0, 500);
      Block := Clamp(Dat.Param('Block').Int(0), 0, 75);
      Rot := Dat.Param('Rotate').Bool(False);
      if (Category = icElixir) then
        Rot := True;
      FlyAng := Dat.Param('FlyAng').Bool(False);
    end;

  if (Pat.pType = 'SUFFIX') or (Pat.pType = 'MATERIAL') then
    with TAffixPat(Pat) do
    begin
      Rarity := Dat.Param('Rarity').Int(0);
      Title := Dat.Param('Title').Str('');
      Title1 := Dat.Param('Title1').Str('');
      Title2 := Dat.Param('Title2').Str('');
      Title3 := Dat.Param('Title3').Str('');
      Title4 := Dat.Param('Title4').Str('');
      Durability := Dat.Param('Durability').Float(1);
      Armor := Dat.Param('Armor').Float(1);
      DamPhys := LoadSingleDamage('DamPhys');
      DamFire := LoadSingleDamage('DamFire');
      DamCold := LoadSingleDamage('DamCold');
      DamElec := LoadSingleDamage('DamElec');
      DamPoison := LoadSingleDamage('DamPoison');
    end;

  if Pat.pType = 'SUFFIX' then
    with TSuffixPat(Pat) do
    begin
      LoadBonus(Bonus, Dat);
      Radius := Clamp(Dat.Param('Radius').Int(0), 0, 1);
    end;

  if Pat.pType = 'MATERIAL' then
    with TMaterialPat(Pat) do
    begin
      S := Dat.Param('Sound').Str('');
      Sound := nil;
      if (S <> '') then
        Sound := LoadSound(FDir + S);

      MatClass := UpperCase(Dat.Param('Class').Str(''));
      if (MatClass <> '') then
        AddMatClass(MatClass, Pat.Name);
    end;

  if Pat.pType = 'EFFECT' then
    with TEfPat(Pat) do
    begin
    end;

  Dat.Free;
end;

procedure Init(PatDir: AnsiString);
var
  SR: TSearchRec;
begin
  if (PatDir <> '') then
    if (PatDir[Length(PatDir)] <> '\') then
      PatDir := PatDir + '\';
  if FindFirst(PatDir + '*.*', faAnyFile, SR) = 0 then
    repeat
      if (SR.Name = '.') or (SR.Name = '..') then
        Continue;
      if (SR.Attr and (faDirectory) <> 0) then
        Init(PatDir + SR.Name)
      else if (UpperCase(GetFileExt(SR.Name)) = 'DAT') then
        LoadDAT(PatDir + SR.Name);
    until (FindNext(SR) <> 0);
  FindClose(SR);
end;

procedure Free;
var
  P, PN: TPattern;
begin
  P := Patterns;
  while (P <> nil) do
  begin
    PN := P.Next;
    P.Free;
    P := PN;
  end;
  Patterns := nil;
end;

initialization

MaterialClasses := TStringList.Create;

finalization

MaterialClasses.Free;
Free;

end.
