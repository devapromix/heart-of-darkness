unit SceneGame;

interface

uses Classes, gm_patterns, SysUtils, Belt, Effect, IntBar, Scenes;

type
  TSceneGame = class(TScene)
  private
    Expbar: TIntBar;
    Adrbar: TIntBar;
    Lifebar: TIntBar;
    Manabar: TIntBar;
  public
    constructor Create();
    procedure Render(); override;
    procedure Update(); override;
    destructor Destroy; override;
    function MouseOverGUI: Boolean;
    procedure LoadLevel(P: TMapPat);
    procedure Refresh();
  end;

implementation

uses Types, gm_engine, gm_map, gm_creature, gm_item, gm_obj, Stat, Resources,
  Spell, gm_generator,
  PathFind, SceneFrame, Utils, Hint, SceneInv, Digit, Sound,
  LibZip, Town, GlobalMap;

{ TSceneGame }

function TSceneGame.MouseOverGUI: Boolean;
begin
  Result := True;
  // exit;
  if SceneManager.Scene = SceneManager.CurrentScene[scFrame] then
    exit;

  if BtnDwn <> 0 then
    exit;
  if PC.Life.IsMin then
    exit;
  if PCBelt.MouseOver then
    exit;
  if PCEffect.MouseOver then
    exit;
  if Expbar.MouseOver then
    exit;
  if Adrbar.MouseOver then
    exit;
  if Lifebar.MouseOver then
    exit;
  if Manabar.MouseOver then
    exit;
  if IsTown then
    exit;
  if (GetMouse.X > ScreenWidth) or (GetMouse.Y > ScreenHeight) then
    exit;

  Result := False;
end;

constructor TSceneGame.Create;
begin
  PCBelt := TBelt.Create;
  PCEffect := TEffect.Create;
  Lifebar := TIntBar.Create(10, ScreenHeight - 48, ttLifebar);
  Manabar := TIntBar.Create(10, ScreenHeight - 28, ttManabar);
  Expbar := TIntBar.Create(ScreenWidth - 213, ScreenHeight - 28, ttExpbar);
  Adrbar := TIntBar.Create(ScreenWidth - 213, ScreenHeight - 48, ttAdrbar);
end;

destructor TSceneGame.Destroy;
begin
  inherited;
  FreeAndNil(PCEffect);
  FreeAndNil(Lifebar);
  FreeAndNil(Manabar);
  FreeAndNil(Expbar);
  FreeAndNil(Adrbar);
  FreeAndNil(Scroll);
  FreeAndNil(Elixir);
  FreeAndNil(PCBelt);
  FreeAndNil(PCTown);
  FreeAndNil(Gate);
  FreeAndNil(GMap);
  FreeAndNil(Map);
end;

procedure TSceneGame.Render;
var
  A: Byte;
  C: TPoint;
  I, J, P, L: Integer;
  S: ansistring;
  B: TIntBar;
begin
  SetCamera2D(@Cam);
  if IsTown then
    PCTown.Render
  else
    Map.Render;
  if not MouseOverGUI then
  begin
    C.X := Round(GetMouse.X + Cam.X);
    C.Y := Round(GetMouse.Y + Cam.Y);
    if (C.X > 0) and (C.Y > 0) then
    begin
      C.X := C.X div 32;
      C.Y := C.Y div 32;
      if (C.X < Map.Width) and (C.Y < Map.Height) then
        Circ2D(C.X * 32 + 16, C.Y * 32 + 16, CursorRad, cLtYellow, 200);
    end;
  end;
  SetCamera2D(nil);

  if not IsTown then
  begin
    Digit.Render;
    if (FlagPrayer > 0) then
      RenderSprite2D(Resource[ttPrayer], ScreenWidth div 2 - 16, 0, 32, ScreenHeight div 2 + 16, 0);
    if (FlagBlood > 0) then
      DrawBG(cRed, FlagBlood);
    if (FlagPoison > 0) then
      DrawBG(cGreen, FlagPoison);
  end;
  if ShowMinimap then
    Map.DrawMinimap(1, 1);

  if Drag.Item <> nil then
    Item_Draw(Drag.Item, GetMouse.X - 16, GetMouse.Y - 16, Drag.Count, Drag.Prop, 2);
  with PC.Exp do
    Expbar.Render(Cur, Max);
  with PC.Adr do
    Adrbar.Render(Cur, Max);
  with PC.Life do
    Lifebar.Render(Cur, Max);
  with PC.Mana do
    Manabar.Render(Cur, Max);
  PCBelt.Render;
  if not PC.Life.IsMin then
    PCEffect.Render;

  if not IsTown and (STTime > 0) then
  begin
    A := 255;
    if STTime < 25 then
      A := STTime * 10;
    TextOut(Font[ttFont1], STPos.X, STPos.Y, 1, 0, SomeText, A, cWhite, TEXT_HALIGN_CENTER or TEXT_VALIGN_CENTER);
  end;

  if PC.Life.IsMin then
    DrawBG;

  if (IHint.Show) then
    if (Drag.Item = nil) then
    begin
      HintBG(IHint.X, IHint.Y, IHint.W, IHint.H);
      for I := 0 to Length(IHint.Text) - 1 do
        TextOut(Font[ttFont1], IHint.X + IHint.W div 2, IHint.Y + (I * 15) + 10, 1, 0, IHint.Text[I], 255, IHint.Color[I], TEXT_HALIGN_CENTER);
    end;

  if (PC.SlotItem[slLHand].Item.Count > 0) and (PC.SlotItem[slRHand].Item.Count > 0) and (PC.IsRangedWpn(icBow) or PC.IsRangedWpn(icCrossbow)) then
  begin
    Item_Draw(@PC.SlotItem[slLHand].Item, ScreenWidth - 40, 8, PC.SlotItem[slLHand].Item.Count, PC.SlotItem[slLHand].Item.Prop, 1);
    TextOut(Font[ttFont2], PCBelt.GetLeft(PCBelt.Slot) + 6, PCBelt.Top + 4, 1, 0, IntToStr(PC.SlotItem[slLHand].Item.Count), 255, $FFFFFF,
      TEXT_HALIGN_CENTER);
  end;
  if CHint.Show and (Drag.Item = nil) then
  begin
    B := TIntBar.Create((ScreenWidth div 2) - (Resource[ttBackbar].Width div 2), Span + CharHeight, ttLifebar);
    try
      TextOut(Font[ttFont1], (ScreenWidth div 2) - (Round(TextWidth(Font[ttFont1], CHint.Title)) div 2), Span div 2, CHint.Title);
      B.Render(CHint.Life, CHint.MaxLife, True);
    finally
      B.Free;
    end;
  end;

  if (SceneManager.Scene <> SceneManager.CurrentScene[scGame]) then
    exit;
  if Lifebar.MouseOver then
    Hint.RenderRightHint(['Здоровье', PC.Life.ToString]);
  if Manabar.MouseOver then
    Hint.RenderRightHint(['Мана', PC.Mana.ToString]);
  if Adrbar.MouseOver then
    Hint.RenderRightHint(['Адреналин', PC.Adr.ToString]);
  if Expbar.MouseOver then
    Hint.RenderRightHint(['Опыт', PC.Exp.ToString]);
  GMap.Render;
  Gate.Render;
end;

procedure TSceneGame.Update;
var
  N, I: Integer;
  C, T: Types.TPoint;
  Cr: TCreature;
begin
  ChBIFlag := False;
  IHint.Show := False;
  CHint.Show := False;
  SHint.Show := False;
  if CursorFlag then
    CursorRad := CursorRad + 0.2
  else
    CursorRad := CursorRad - 0.2;
  if (CursorRad < 20) then
    CursorFlag := True;
  if (CursorRad > 24) then
    CursorFlag := False;

  if KeyPress(K_ESCAPE) then
  begin
    if IsGate then
    begin
      IsGate := False;
      ClearStates;
      exit;
    end;
    if IsWorld then
    begin
      IsWorld := False;
      ClearStates;
      exit;
    end;
    SceneManager.SetScene(scMenu);
    // PC.SaveToFile('hero.sav');
  end;

  if KeyDown(K_ALT) and KeyPress(K_ENTER) then
  begin
    FullScr := not FullScr;
    SetScreenOptions(ScreenWidth, ScreenHeight, 0, FullScr, VSync);
  end;

  if IsGate or IsWorld then
  begin
    if IsWorld then
      GMap.Update;
    if IsGate then
      Gate.Update;
    ClearStates;
    exit;
  end;

  if PC.Life.IsMin then
    ClearStates;
  if (MPrev.X = GetMouse.X) and (MPrev.Y = GetMouse.Y) then
    nmtime := nmtime + 1
  else
    nmtime := 0;

  if MouseClick(M_BLEFT) or MouseClick(M_BRIGHT) then
    nmtime := 0;
  MPrev := GetMouse;

  if (WalkPause > 0) then
    WalkPause := WalkPause - 1;
  T := PC.Pos;

  if STTime > 0 then
    STTime := STTime - 1;

  if (LookAtObj <> nil) then
  begin
    Play(ttSndOpen);
    Drag.Item := nil;
    SceneFrame.LeftFrame := [gfInv];
    SceneManager.SetScene(scFrame);
  end;

  C.X := Round(GetMouse.X + Cam.X);
  C.Y := Round(GetMouse.Y + Cam.Y);
  if (C.X > 0) and (C.Y > 0) then
  begin
    C.X := C.X div 32;
    C.Y := C.Y div 32;
    if (C.X >= Map.Width) or (C.Y >= Map.Height) then
      C.X := -1;
  end
  else
    C.X := -1;

  if MouseClick(M_BLEFT) and not MouseOverGUI and (C.X <> -1) then
  begin
    if (Drag.Item = nil) then
    begin
      if (Map.Fog[C.X, C.Y] <> 0) then
      begin
        PC.WalkTo := C;
        Cr := Map.GetCreature(C);
        if (Cr <> nil) then
          if (Cr.Team <> PC.Team) then
            PC.Enemy := Cr;

        if (FlagScroll <> efNone) then
        begin
          if (PC.Enemy <> nil) and (FlagScroll = efHypnosis) then
          begin
            PC.Enemy.AddEffect(efHypnosis, 21);
            PC.Enemy.Enemy := nil;
            PC.Enemy.Team := 0;
            PC.Enemy := nil;
            PC.WalkTo.X := -1;
            PC.Moved := True;
            FlagScroll := efNone;
          end;

          if (PC.Enemy <> nil) and (FlagScroll = efFreezing) then
          begin
            PC.Enemy.AddEffect(efFreezing, 21);
            PC.Enemy := nil;
            PC.WalkTo.X := -1;
            PC.Moved := True;
            FlagScroll := efNone;
          end;

          { if (FlagScroll = 'Вызов голема') then
            begin
            if (abs(C.X - PC.Pos.X) < 2) and (abs(C.Y - PC.Pos.Y) < 2) then
            begin
            bool := True;
            if (Map.GetCreature(C) <> nil) then bool := False;
            if (Map.Objects.Obj[C.X, C.Y] <> nil) then
            if Map.Objects.Obj[C.X, C.Y].BlockWalk then bool := False;
            if bool = True then
            begin
            Cr2 := Map.CreateCreature('StoneGolem', C);
            Cr2.LifeTime := 50;
            PC.Moved := True;
            FlagScroll := '';
            end;
            end;
            PC.WalkTo.X := -1;
            PC.Enemy := nil;
            end;
            // Magic
            if (PC.Enemy <> nil) and (FlagScroll = 'Огненный Шар') then
            begin
            PC.SpellName := FlagScroll;
            PC.SpellPower := 1;
            PC.Moved := True;
            FlagScroll := '';
            end;
            if (PC.Enemy <> nil) and (FlagScroll = 'Ледяная Глыба') then
            begin
            PC.SpellName := FlagScroll;
            PC.SpellPower := 1;
            PC.Moved := True;
            FlagScroll := '';
            end;
            if (PC.Enemy <> nil) and (FlagScroll = 'Ядовитое Облако') then
            begin
            PC.SpellName := FlagScroll;
            PC.SpellPower := 1;
            PC.Moved := True;
            FlagScroll := '';
            end;
            if (PC.Enemy <> nil) and (FlagScroll = 'Шаровая Молния') then
            begin
            PC.SpellName := FlagScroll;
            PC.SpellPower := 1;
            PC.Moved := True;
            FlagScroll := '';
            end; }
        end;
        if (Cr = PC) then
        begin
          PC.Walk(0, 0);
          PC.Moved := True;
        end;
      end;
    end
    else if (ABS(C.X - PC.Pos.X) < 2) and (ABS(C.Y - PC.Pos.Y) < 2) then
      if Map.UseItemsOnTile(Drag.Item.Pat, Drag.Count, Drag.Prop, C) then
        Drag.Item := nil;
  end;

  if (MouseClick(M_BRIGHT)) and (MouseOverGUI = False) and (C.X <> -1) and (Drag.Item = nil) then
  begin
    Cr := Map.GetCreature(C);
    if (Cr <> nil) and (Cr <> PC) then
      if (ABS(Cr.Pos.X - PC.Pos.X) < 2) and (ABS(Cr.Pos.Y - PC.Pos.Y) < 2) then
        if (Cr.Team = 0) and (Cr.Enemy = nil) then
          Cr.WalkAway(PC.Pos.X, PC.Pos.Y);
  end;

  if KeyPress(K_M) then
    ShowMinimap := not ShowMinimap;

  if KeyPress(K_ENTER) and (Map.Objects.Obj[PC.Pos.X, PC.Pos.Y] <> nil) then
  begin
    if (Map.Objects.Obj[PC.Pos.X, PC.Pos.Y].Pat.Name = 'PORTAL') then
    begin
      if (PC.Mana.Cur >= PortalManaCost) then
      begin
        Play(ttSndUsePortal);
        PC.Mana.Dec(PortalManaCost);
        Map.Go(sdTown);
      end
      else
        NeedManaMsg();
    end;
    if (Map.Objects.Obj[PC.Pos.X, PC.Pos.Y].Pat.Name = 'UP') then
    begin
      Map.Go(sdUp);
    end;
    if (Map.Objects.Obj[PC.Pos.X, PC.Pos.Y].Pat.Name = 'DOWN') then
    begin
      Map.Go(sdDown);
    end;
  end;

  if KeyPress(K_T) then
  begin
  end;

  if KeyPress(K_R) then
    Refresh;

  if KeyPress(K_F) then
    with Map do
    begin
      // Clear;
      // GenerateObjects(Map);
      // GenerateTreasures(Map);
      // P := Point(30, 30);
      // CreateWave(Map, P.X, P.Y, -1, 0, True);
      // GenerateCreatures(Map);
    end;

  // if KeyPress(K_Y) then PC.DelItem('GOLDCOIN', 5);
  if KeyPress(K_U) then
    PC.AddItem('GOLDCOIN', 10);

  if KeyPress(K_INV) or KeyPress(K_CHAR) or KeyPress(K_SKILL) then
  begin
    if KeyPress(K_INV) then
    begin
      Play(ttSndClick);
      SceneFrame.LeftFrame := [gfInv];
    end;
    if KeyPress(K_CHAR) then
    begin
      Play(ttSndClick);
      SceneFrame.RightFrame := [gfInfo];
    end;
    if KeyPress(K_SKILL) then
    begin
      Play(ttSndClick);
      SceneFrame.RightFrame := [gfSkill];
    end;
    SceneManager.SetScene(scFrame);
  end;

  N := 0;
  if IsTown then
  begin
    PCTown.Update;
  end
  else
  begin
    if KeyPress(K_LEFT) or KeyPress(K_KP_4) then
      N := 1;
    if KeyPress(K_RIGHT) or KeyPress(K_KP_6) then
      N := 2;
    if KeyPress(K_UP) or KeyPress(K_KP_8) then
      N := 3;
    if KeyPress(K_DOWN) or KeyPress(K_KP_2) then
      N := 4;
    if KeyPress(K_HOME) or KeyPress(K_KP_7) then
      N := 5;
    if KeyPress(K_PAGEUP) or KeyPress(K_KP_9) then
      N := 6;
    if KeyPress(K_END) or KeyPress(K_KP_1) then
      N := 7;
    if KeyPress(K_PAGEDOWN) or KeyPress(K_KP_3) then
      N := 8;
    if KeyPress(K_SPACE) then
      N := 9;
    if N <> 0 then
      PC.WalkTo.X := -1;
    if (Drag.Item <> nil) or (BtnDwn <> 0) then
      N := 0;
    // if NewGame then n := 0;

    if (WalkPause = 0) and (Map.BulletsCnt = 0) then
    begin
      if N = 1 then
        PC.Walk(-1, 0);
      if N = 2 then
        PC.Walk(1, 0);
      if N = 3 then
        PC.Walk(0, -1);
      if N = 4 then
        PC.Walk(0, 1);
      if N = 5 then
        PC.Walk(-1, -1);
      if N = 6 then
        PC.Walk(1, -1);
      if N = 7 then
        PC.Walk(-1, 1);
      if N = 8 then
        PC.Walk(1, 1);
      if N = 9 then
        PC.Rest();

      PC.Update;
    end;
  end;

  if (PC.Pos.X <> T.X) or (PC.Pos.Y <> T.Y) then
    PC.Moved := True;

  { if (SellSpellN <> -1) then PC.UseSpell(SellSpellN);
    if (SellSpellN <> -1) then
    if (PC.Spells[SellSpellN].Mana > PC.Mana.Cur) then SellSpellN := -1; }

  if (MouseOverGUI = False) and (C.X <> -1) and (Map.Fog[C.X, C.Y] <> 0) and (Drag.Item = nil) then
  begin
    Cr := Map.GetCreature(C);
    if (Cr <> nil) and (Cr <> PC) then
      InitCHint(Cr);
  end;

  if KeyPress(K_V) then
    Play(ttSndMenu);

  if not IsTown then
  begin
    if (PC.Moved = True) and (Map.BulletsCnt = 0) then
    begin
      PC.Adr.Dec;
      PC.Moved := False;
      Map.ExplosiveBombs;
      Map.UpdateFog(PC);
      Map.MoveCreatures;
      for N := 0 to Map.Creatures.Count - 1 do
      begin
        Cr := TCreature(Map.Creatures[N]);
        Cr.UpdateEffects;
        Cr.ReFill;
        if Cr.LifeTime > 0 then
          Cr.LifeTime := Cr.LifeTime - 1;
        if Cr.LifeTime = 1 then
          Cr.Life.SetToMin;
      end;

      WalkPause := 16;
      if PC.WalkTo.X = -1 then
        WalkPause := 10;
    end;

    if (Map.BulletsCnt <> 0) then
    begin
      PC.WalkTo.X := -1;
      LookAtObj := nil;
    end
    else
      PC.Moved := False;

    with Map do
      for I := 0 to ItemsCnt - 1 do
        if (Items[I].Count > 0) then
        begin
          if (Map.Fog[Items[I].Pos.X, Items[I].Pos.Y] <> 2) then
            Continue;
          if Items[I].Dir then
            Items[I].Top := Items[I].Top + 0.1
          else
            Items[I].Top := Items[I].Top - 0.1;
          if (Items[I].Top >= ITEM_AMP) then
            Items[I].Dir := False;
          if (Items[I].Top <= -ITEM_AMP) then
            Items[I].Dir := True;
        end;

    Map.Update;
  end;
  HItem := nil;

  PCBelt.Update;
  Digit.Update;

  with PCBelt do
  begin
    if MouseWheel(M_WUP) then
    begin
      Slot := Slot - 1;
      ChBIFlag := True;
    end;
    if MouseWheel(M_WDOWN) then
    begin
      Slot := Slot + 1;
      ChBIFlag := True;
    end;
    Slot := ClampCycle(Slot, 0, 9);
    ChRHandItemInBelt;
  end;
  if (FlagBlood > 0) then
    Dec(FlagBlood);
  if (FlagPoison > 0) then
    Dec(FlagPoison);
  if (FlagPrayer > 0) then
    Dec(FlagPrayer);
  PC.SetCam;

  ClearStates;
end;

procedure TSceneGame.LoadLevel(P: TMapPat);
begin
  if (P.TownID > 0) then
  begin
    PCDeep := 0;
    IsTown := True;
    Map.Name := '';
  end
  else
  begin
    PCDeep := P.Z;
    PCCurMapID := P.Name;
    PCMapLevel := P.Level;
    Self.Refresh;
    Map.Name := P.Title;
  end;
end;

procedure TSceneGame.Refresh;
begin
  IsPortal := False;
  AllItemsID := '';
  AllMapsID := '';

  Stat.Load;
  Spell.Load;

  Elixir.Free;
  Elixir := TElixir.Create;
  //Elixir.LoadFromFile('hero.sav');

  Scroll.Free;
  Scroll := TScroll.Create;
  //Scroll.LoadFromFile('hero.sav');

  gm_patterns.Init('..\mods\');

  PCTown.Free;
  PCTown := TTown.Create;
  Map.Free;
  Map := TMap.Create;
  GenerateObjects(Map);
  GenerateTreasures(Map);
  PC := TPC(Map.CreateCreature('PC', Point(1, 1)));
  GMap.SetGMapPoint(0, 3);

  //PC.LoadFromFile('hero.sav');
  CreateWave(Map, PC.Pos.X, PC.Pos.Y, -1, 0, True);
  GenerateCreatures(Map);
  PC.Calculator;
  PC.Fill;
  Map.UpdateFog(PC);
  TreasuresConvert(Map);
  PC.SetCam;
end;

end.
