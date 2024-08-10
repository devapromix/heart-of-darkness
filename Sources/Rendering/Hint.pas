unit Hint;
         
interface

uses gm_engine, gm_item, gm_creature;

procedure HintBG(X, Y, W, H: Integer);
procedure InitSHint(X, Y: Integer; S: AnsiString);
procedure InitCHint(C: TCreature);
procedure InitIHint(X, Y: Integer; Item: PItem = nil);
//procedure RenderRightHint(Title: AnsiString; Hint: AnsiString = ''; Time: AnsiString = '');
procedure RenderRightHint(S: array of AnsiString);
procedure Render;

type
  THint = record
    X, Y: Integer;
    W, H: Integer;
    Color: array of Integer;
    Text: array of AnsiString;
    Show: Boolean;
  end;

type
  TCHint = record
    Title: AnsiString;
    Show: Boolean;
    Life: Integer;
    MaxLife: Integer;
  end;

var
  IHint: THint;
  SHint: THint;
  CHint: TCHint;
  HItem: PItem;

implementation

uses Resources, SysUtils, Utils, gm_patterns, SceneFrame;

const
  LW = 20;

procedure HintBG(X, Y, W, H: Integer);
begin
  Rect2D(X, Y, W, H, cBlack, 150, PR2D_FILL);
end;

procedure InitHint(var H: THint; X, Y, W: Integer);
begin
  H.H := Length(H.Text) * 15 + 20;
  H.W := W + 20;
  H.X := X + CharHeight;
  H.Y := Y + CharHeight;
  H.X := Clamp(H.X, 0, ScreenWidth - H.W);
  H.Y := Clamp(H.Y, 0, ScreenHeight - H.H);
end;

procedure AddLine(I: Integer; S: AnsiString; C: Integer; var H: THint; var L: Integer);
begin
  SetLength(H.Text, I);
  SetLength(H.Color, I);
  H.Color[I - 1] := C;
  H.Text[I - 1] := S;
  L := I;
end;

procedure InitSHint(X, Y: Integer; S: AnsiString);
var
  L, I, J, W, Width: Integer;
  T: array [1..2] of AnsiString;

begin
  L := 1;
  if (Length(S) > LW) then
  begin
    for J := Length(S) div 2 to Length(S) do
      if (S[J] = #32) then Break;
    T[1] := Trim(Copy(S, 1, J - 1));
    T[2] := Trim(Copy(S, J + 1, Length(S)));
    for I := 1 to 2 do if (T[I] <> '') then AddLine(I, T[I], cWhite, SHint, L);
  end else AddLine(1, S, cWhite, SHint, L);
  W := 0;
  for I := 0 to Length(SHint.Text) - 1 do
  begin
    Width := Round(TextWidth(Font[ttFont1], SHint.Text[I]));
    if (Width > W) then W := Width;
  end;
  InitHint(SHint, X, Y, W);
end;

procedure InitIHint(X, Y: Integer; Item: PItem = nil);
var
  C, L, I, W, H, Width, Height, Tag, Color: Integer;
  SufPat: TSuffixPat;
  MatPat: TMaterialPat;
  T: array [1..2] of AnsiString;
  F: Boolean;
  S: AnsiString;

  function GetTitle(Pat: TAffixPat): AnsiString;
  begin
    Result := '';
    if (Item = nil) or (Pat = nil) then Exit;
    case Item.Pat.Gender of
      1: Result := Pat.Title1;
      2: Result := Pat.Title2;
      3: Result := Pat.Title3;
      4: Result := Pat.Title4;
      else Result := '';
    end;
  end;

  procedure SetTitle;
  var
    S: AnsiString;
    I, J: Byte;
    MatFlag: Boolean;
    SufFlag: Boolean;
    Color: Integer;
  begin
    MatFlag := False;
    SufFlag := False;
    Color := cWhite;
    S := Item.Pat.Title;

    if Item.Pat.UseMaterial then
      if (Item.Prop.Material <> '') then
        if (MatPat.Title <> '') then
          S := Trim(S + ' ' + MatPat.Title)
            else MatFlag := True;

    if (Item.Prop.Suffix <> '') then
    begin
      Color := cDkYellow;
      if (SufPat.Title = '') then
        SufFlag := True
          else S := S + ' ' + SufPat.Title;
    end;

    if MatFlag then S := Trim(GetTitle(MatPat) + ' ' + S);
    if SufFlag then
    begin
      if (Item.Prop.Suffix = 'SUPERIOR') or (Item.Prop.Suffix = 'DAMAGED') then Color := cWhite;
      S := Trim(GetTitle(SufPat) + ' ' + S);
    end;

    if (Item.Pat.Category = icElixir) then Color := cDkGreen;
    if (Item.Pat.Category = icScroll) then Color := cDkBlue;

    if (Length(S) > LW) then
    begin
      for J := 1 to Length(S) do
        if (S[J] = #32) then Break;
      T[1] := Trim(Copy(S, 1, J - 1));
      T[2] := Trim(Copy(S, J + 1, Length(S)));
      for I := 1 to 2 do if (T[I] <> '') then AddLine(I, T[I], Color, IHint, L);
    end else AddLine(1, S, Color, IHint, L);
  end;

  procedure ShowHint(S: AnsiString);
  var
    I, J: Byte;
  begin
    if (Item.Pat.Category = icElixir) and not Elixir.IsDefined(Tag) then Exit;
    if (Item.Pat.Category = icScroll) and not Scroll.IsDefined(Tag) then Exit;
    if (Length(S) > LW) then
    begin
      for J := Length(S) div 2 to Length(S) do
        if (S[J] = #32) then Break;
      T[1] := Trim(Copy(S, 1, J - 1));
      T[2] := Trim(Copy(S, J + 1, Length(S)));
      for I := 1 to 2 do if (T[I] <> '') then AddLine(L + 1, T[I], cHintItem, IHint, L);
    end else AddLine(L + 1, S, cHintItem, IHint, L);
  end;

  procedure ShowDamage(S: AnsiString; D: TDamRange; ipMin, ipMax: TItemProperty);
  begin
    if (D.Min > 0) and (D.Max > 0) then
      AddLine(L + 1, S + ' ' + IntToStr(GetItemProp(Item, ipMin)) + '-' +
        IntToStr(GetItemProp(Item, ipMax)), Color, IHint, L);
  end;

begin
  if Item.Count = 0 then Exit;

  SufPat := nil; MatPat := nil;

  SufPat := TSuffixPat(GetPattern('SUFFIX', Item.Prop.Suffix));
  MatPat := TMaterialPat(GetPattern('MATERIAL', Item.Prop.Material));

  SetTitle;

  // Elixirs
  if (Item.Pat.Category = icElixir) then
  begin
    Tag := Item.Pat.EffectTag;
    if (Elixir.IsDefined(Tag)) then
      IHint.Text[0] := Elixir.Title(Tag)
        else AddLine(1, Elixir.GetColorName(Tag).Ru + ' Эликсир', cRed, IHint, L);
  end;

  // Scrolls
  if (Item.Pat.Category = icScroll) then
  begin
    Tag := Item.Pat.EffectTag;
    if (Scroll.IsDefined(Tag)) then
      IHint.Text[0] := Scroll.Title(Tag)
        else AddLine(1, 'Свиток ' + Scroll.GetName(Tag), cRed, IHint, L);
  end;

  // Hint
  if (Item.Pat.Hint <> '') then ShowHint(Item.Pat.Hint);
  // Level
  if (Item.Pat.Level > 0) then AddLine(L + 1, 'Уровень ' + IntToStr(Item.Pat.Level), cWhite, IHint, L);
  // Armor
  if (Item.Pat.Armor > 0) then AddLine(L + 1, 'Защита ' + IntToStr(GetItemProp(Item, ipArmor)), cWhite, IHint, L);

  // Bonuses
  Color := cBonusItem;
  if (SufPat <> nil) and (SufPat.Radius > 0) then AddLine(L + 1, 'Обзор +' + IntToStr(GetItemProp(Item, ipRadius)), Color, IHint, L);
  if ((SufPat <> nil) and (SufPat.Bonus.ResFire > 0)) or (Item.Pat.Bonus.ResFire > 0) then AddLine(L + 1, 'Сопр. огню ' + IntToStr(GetItemProp(Item, ipResFire)) + '%', Color, IHint, L);
  if ((SufPat <> nil) and (SufPat.Bonus.ResCold > 0)) or (Item.Pat.Bonus.ResCold > 0) then AddLine(L + 1, 'Сопр. холоду ' + IntToStr(GetItemProp(Item, ipResCold)) + '%', Color, IHint, L);
  if ((SufPat <> nil) and (SufPat.Bonus.ResElec > 0)) or (Item.Pat.Bonus.ResElec > 0) then AddLine(L + 1, 'Сопр. электр. ' + IntToStr(GetItemProp(Item, ipResElec)) + '%', Color, IHint, L);
  if ((SufPat <> nil) and (SufPat.Bonus.ResPoison > 0)) or (Item.Pat.Bonus.ResPoison > 0) then AddLine(L + 1, 'Сопр. яду ' + IntToStr(GetItemProp(Item, ipResPoison)) + '%', Color, IHint, L);
  if ((SufPat <> nil) and (SufPat.Bonus.Strength > 0)) or (Item.Pat.Bonus.Strength > 0) then AddLine(L + 1, 'Сила +' + IntToStr(GetItemProp(Item, ipStr)), Color, IHint, L);
  if ((SufPat <> nil) and (SufPat.Bonus.Stamina > 0)) or (Item.Pat.Bonus.Stamina > 0) then AddLine(L + 1, 'Стойкость +' + IntToStr(GetItemProp(Item, ipSta)), Color, IHint, L);
  if ((SufPat <> nil) and (SufPat.Bonus.Dexterity > 0)) or (Item.Pat.Bonus.Dexterity > 0) then AddLine(L + 1, 'Ловкость +' + IntToStr(GetItemProp(Item, ipDex)), Color, IHint, L);
  if ((SufPat <> nil) and (SufPat.Bonus.Agility > 0)) or (Item.Pat.Bonus.Agility > 0) then AddLine(L + 1, 'Реакция +' + IntToStr(GetItemProp(Item, ipAgi)), Color, IHint, L);
  if ((SufPat <> nil) and (SufPat.Bonus.Wisdom > 0)) or (Item.Pat.Bonus.Wisdom > 0) then AddLine(L + 1, 'Мудрость +' + IntToStr(GetItemProp(Item, ipWis)), Color, IHint, L);
  if ((SufPat <> nil) and (SufPat.Bonus.Intellect > 0)) or (Item.Pat.Bonus.Intellect > 0) then AddLine(L + 1, 'Интеллект +' + IntToStr(GetItemProp(Item, ipInt)), Color, IHint, L);
  if ((SufPat <> nil) and (SufPat.Bonus.Life > 0)) or (Item.Pat.Bonus.Life > 0) then AddLine(L + 1, 'Здоровье +' + IntToStr(GetItemProp(Item, ipLife)), Color, IHint, L);
  if ((SufPat <> nil) and (SufPat.Bonus.Mana > 0)) or (Item.Pat.Bonus.Mana > 0) then AddLine(L + 1, 'Мана +' + IntToStr(GetItemProp(Item, ipMana)), Color, IHint, L);
  if ((SufPat <> nil) and (SufPat.Bonus.RefLife > 0)) or (Item.Pat.Bonus.RefLife > 0) then AddLine(L + 1, 'Восст. Здоровья +' + IntToStr(GetItemProp(Item, ipRefLife)), Color, IHint, L);
  if ((SufPat <> nil) and (SufPat.Bonus.RefMana > 0)) or (Item.Pat.Bonus.RefMana > 0) then AddLine(L + 1, 'Восст. Маны +' + IntToStr(GetItemProp(Item, ipRefMana)), Color, IHint, L);

  if (SufPat <> nil) and not ((Item.Prop.Suffix = 'SUPERIOR') or (Item.Prop.Suffix = 'DAMAGED')) then Color := cBonusItem else Color := cWhite;

  ShowDamage('Урон', Item.Pat.Damage.Phys, ipDamPhysMin, ipDamPhysMax);
  ShowDamage('Урон огнем', Item.Pat.Damage.Fire, ipDamFireMin, ipDamFireMax);
  ShowDamage('Урон холодом', Item.Pat.Damage.Cold, ipDamColdMin, ipDamColdMax);
  ShowDamage('Урон ядом', Item.Pat.Damage.Poison, ipDamPoisonMin, ipDamPoisonMax);
  ShowDamage('Урон электр.', Item.Pat.Damage.Elec, ipDamElecMin, ipDamElecMax);

  if (Item.Pat.Block > 0) then AddLine(L + 1, 'Шанс блока ' + IntToStr(Item.Pat.Block) + '%', cWhite, IHint, L);
  if (Item.Pat.Durability > 0) then
  begin
    if (Item.Prop.Durability > 0) then C := cWhite else C := cRed;
    AddLine(L + 1, 'Прочность ' + IntToStr(Item.Prop.Durability) + '/' +
      IntToStr(GetItemProp(Item, ipDurability)), C, IHint, L);
  end;
//  if (Item.Pat.Cooldown > 0) then AddLine(L + 1, 'Кулдаун ' + IntToStr(PC.TimeEffect(Item.Pat.Name)) + '/' + IntToStr(Item.Pat.Cooldown), cWhite, IHint, L);
  if (Item.Pat.SkillTag > 0) and not Item.Pat.Active then AddLine(L + 1, 'Пассивный', cLtBlue, IHint, L);

  if Debug and (Item.Prop.Suffix <> '') then AddLine(L + 1, 'Суффикс ' + Item.Prop.Suffix, cDebug, IHint, L);
  if Debug and (Item.Prop.Material <> '') then AddLine(L + 1, 'Материал ' + Item.Prop.Material, cDebug, IHint, L);

  W := 0;
  for I := 0 to Length(IHint.Text) - 1 do
  begin
    Width := Round(TextWidth(Font[ttFont1], IHint.Text[I]));
    if (Width > W) then W := Width;
  end;
  InitHint(IHint, X, Y, W);
  HItem := Item;
end;

procedure InitCHint(C: TCreature);
begin
  if (C = nil) then Exit;
  CHint.Title := C.Pat.Title;
  CHint.Life := C.Life.Cur;
  CHint.MaxLife := C.Life.Max;
  CHint.Show := True;
end;

procedure RenderRightHint(S: array of AnsiString);
var
  I, J, L, H, K: Integer;

  procedure AddLine(S: AnsiString; C: Integer);
  begin
    TextOut(Font[ttFont1], ScreenWidth - 111, ((ScreenHeight - 66) - H) + 10 + (CharHeight * L), 1, 0, S, 255, C, TEXT_HALIGN_CENTER);
    Inc(L);
  end;

begin
  L := 0;
  H := (Length(S) * CharHeight) + 20;
  HintBG(ScreenWidth - 210 - 2, (ScreenHeight - 66) - H - 2, 202, H);
  for I := 0 to High(S) do
    if (I = 0) then AddLine(S[I], cDkYellow)
      else begin
        K := Length(S[I]);    
        if (K <= 38) then AddLine(S[I], cHintItem)
        else begin
          J := LastPos(#32, Copy(S[I], 1, 28));
          AddLine(Copy(S[I], 1, J), cHintItem);
          AddLine(Copy(S[I], J+1, Length(S[I])), cHintItem);
        end;
      end;
end;

procedure Render;
var
  I: Integer;
begin
  if SHint.Show then
  begin
    HintBG(SHint.X, SHint.Y, SHint.W, SHint.H);
    for I := 0 to Length(SHint.Text) - 1 do
      TextOut(Font[ttFont1], SHint.X + SHint.W div 2, SHint.Y + (I * 15) + 10, 1, 0,
        SHint.Text[I], 255, SHint.Color[I], TEXT_HALIGN_CENTER);
  end;
end;

end.
