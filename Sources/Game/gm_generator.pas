unit gm_generator;

interface

uses
  Types, gm_engine, gm_patterns, gm_map, gm_creature, gm_item, PathFind;

type
  PRoom = ^TRoom;

  TRoom = record
    TX, TY: Integer;
    W, H: Integer;
    Walls: array of array of Byte;
  end;

procedure GenerateWalls(M: TMap);
procedure ClearSmallRooms(M: TMap);
procedure GenerateDoors(M: TMap);
procedure GenerateObjects(M: TMap);
procedure GenerateTreasures(M: TMap);
procedure TreasuresConvert(M: TMap);
procedure GenerateCreatures(M: TMap);
procedure CreateItems(ItemPat: TItemPat; Count, X, Y: Integer; Prop: TItemProp);
function GenItemProp(ItemPat: TItemPat): TItemProp;
procedure RandomItem(X, Y: Integer; F: Boolean = False);
procedure GenerateMaterials(var S: ansistring);

implementation

uses SysUtils, Math, Utils, Sound, Resources, GlobalMap;

procedure InitRoom(Room: PRoom);
var
  i, j, x1, y1, W, H, k: Integer;
begin
  Room.W := Random(8) + 5;
  Room.H := Random(8) + 5;
  SetLength(Room.Walls, Room.W, Room.H);
  for j := 0 to Room.H - 1 do
    for i := 0 to Room.W - 1 do
    begin
      Room.Walls[i, j] := 1;
      if (i = 0) or (j = 0) or (i = Room.W - 1) or (j = Room.H - 1) then
        Room.Walls[i, j] := 2;
    end;

  W := Random(Room.W - 3);
  H := Random(Room.H - 3);
  if (W <= 1) or (H <= 1) then
    Exit;
  x1 := 0;
  y1 := 0;
  k := Random(3);
  if (k = 0) or (k = 2) then
    x1 := Room.W - W;
  if (k = 1) or (k = 2) then
    y1 := Room.H - H;
  if Random(5) = 0 then
  begin
    x1 := Random(Room.W - W);
    y1 := Random(Room.H - H);
  end;

  for j := y1 to y1 + H do
    for i := x1 to x1 + W do
    begin
      if (i < 0) or (j < 0) or (i >= Room.W) or (j >= Room.H) then
        Continue;
      Room.Walls[i, j] := 0;
      if (i = 0) or (j = 0) or (i = W) or (j = H) then
        if not((i = 0) or (j = 0) or (i = Room.W - 1) or (j = Room.H - 1)) then
          Room.Walls[i, j] := 2;
    end;
end;

procedure GenerateWalls(M: TMap);
var
  i, j, n, l, X, Y, dx, dy, k, napr: Integer;
  WallPat: TObjPat;
  Room: TRoom;
  Walls: array of array of Byte;
  bool: Boolean;
  con: Integer;
  Tnl: array of TPoint;
  TnlLen: Integer;
begin
  WallPat := TObjPat(GetPattern('OBJECT', 'Wall'));

  SetLength(Walls, M.Width, M.Height);
  for j := 0 to M.Height - 1 do
    for i := 0 to M.Width - 1 do
      Walls[i, j] := 0;

  for n := 0 to 1500 do
  begin
    InitRoom(@Room);
    Room.TX := Random(M.Width - Room.W + 1);
    Room.TY := Random(M.Height - Room.H + 1);

    con := 0;
    bool := True;
    for j := 0 to Room.H - 1 do
    begin
      for i := 0 to Room.W - 1 do
      begin
        if (Walls[i + Room.TX, j + Room.TY] = 1) and (Room.Walls[i, j] = 2) then
          bool := False;
        if (Room.Walls[i, j] = 2) and (Walls[i + Room.TX, j + Room.TY] = 2) then
          con := con + 1;
        if bool = False then
          Break;
      end;
      if bool = False then
        Break;
    end;

    if (n > 0) and (con < 4) then
      Continue;
    if bool = False then
      Continue;

    for j := 0 to Room.H - 1 do
      for i := 0 to Room.W - 1 do
        Walls[i + Room.TX, j + Room.TY] := Room.Walls[i, j];
  end;

  for n := 0 to 300 do
  begin
    X := Random(M.Width);
    Y := Random(M.Height);
    if Walls[X, Y] <> 2 then
      Continue;

    TnlLen := 1;
    SetLength(Tnl, TnlLen);
    Tnl[TnlLen - 1] := Point(X, Y);

    k := Random(4) + 1;
    for j := 0 to k do
    begin
      l := Random(5) + 3;
      napr := Random(4);
      dx := 0;
      dy := 0;
      if napr = 0 then
        dx := -1;
      if napr = 1 then
        dx := 1;
      if napr = 2 then
        dy := -1;
      if napr = 3 then
        dy := 1;
      for i := 0 to l do
      begin
        X := X + dx;
        Y := Y + dy;
        if (X < 0) or (Y < 0) or (X >= M.Width) or (Y >= M.Height) then
          Break;
        if Walls[X, Y] <> 0 then
          Break;
        TnlLen := TnlLen + 1;
        SetLength(Tnl, TnlLen);
        Tnl[TnlLen - 1] := Point(X, Y);
      end;
      if TnlLen < 3 then
        Break;
      X := Tnl[TnlLen - 1].X;
      Y := Tnl[TnlLen - 1].Y;
    end;

    if TnlLen > 5 then
      for i := 0 to TnlLen - 1 do
        Walls[Tnl[i].X, Tnl[i].Y] := 1;
  end;

  for j := 0 to M.Height - 1 do
    for i := 0 to M.Width - 1 do
      if Walls[i, j] = 1 then
        Walls[i, j] := 0
      else
        Walls[i, j] := 1;

  n := 0;
  for j := 1 to M.Height - 2 do
    for i := 0 to M.Width - 1 do
    begin
      l := n;
      if (Walls[i, j] = 1) and (Walls[i, j - 1] = 0) and (Walls[i, j + 1] = 0) then
        n := n + 1
      else
        n := 0;
      if (l > 0) and (n = 0) then
      begin
        l := Random(l) + 1;
        Walls[i - l, j] := 0;
      end;
      if i = M.Width - 1 then
        n := 0;
    end;

  n := 0;
  for i := 1 to M.Width - 2 do
    for j := 0 to M.Height - 1 do
    begin
      l := n;
      if (Walls[i, j] = 1) and (Walls[i - 1, j] = 0) and (Walls[i + 1, j] = 0) then
        n := n + 1
      else
        n := 0;
      if (l > 0) and (n = 0) then
      begin
        l := Random(l) + 1;
        Walls[i, j - l] := 0;
      end;
      if j = M.Height - 1 then
        n := 0;
    end;

  for j := 0 to M.Height - 1 do
    for i := 0 to M.Width - 1 do
      if (i = 0) or (j = 0) or (i = M.Width - 1) or (j = M.Height - 1) then
        Walls[i, j] := 1;

  for k := 0 to 5 do
    for j := 1 to M.Height - 2 do
      for i := 1 to M.Width - 2 do
      begin
        if (Walls[i, j] = 0) and (Walls[i + 1, j + 1] = 0) and (Walls[i + 1, j] = 1) and (Walls[i, j + 1] = 1) then
          Walls[i, j] := 1;
        if (Walls[i, j] = 1) and (Walls[i + 1, j + 1] = 1) and (Walls[i + 1, j] = 0) and (Walls[i, j + 1] = 0) then
          Walls[i + 1, j] := 1;
        if (Walls[i, j] = 0) and (Walls[i - 1, j] = 0) and (Walls[i + 1, j] = 1) and (Walls[i, j - 1] = 1) and (Walls[i, j + 1] = 1) then
          Walls[i, j] := 1;
        if (Walls[i, j] = 0) and (Walls[i - 1, j] = 1) and (Walls[i + 1, j] = 0) and (Walls[i, j - 1] = 1) and (Walls[i, j + 1] = 1) then
          Walls[i, j] := 1;
        if (Walls[i, j] = 0) and (Walls[i - 1, j] = 1) and (Walls[i + 1, j] = 1) and (Walls[i, j - 1] = 0) and (Walls[i, j + 1] = 1) then
          Walls[i, j] := 1;
        if (Walls[i, j] = 0) and (Walls[i - 1, j] = 1) and (Walls[i + 1, j] = 1) and (Walls[i, j - 1] = 1) and (Walls[i, j + 1] = 0) then
          Walls[i, j] := 1;
      end;

  for j := 0 to M.Height - 1 do
    for i := 0 to M.Width - 1 do
    begin
      if Walls[i, j] = 1 then
        M.Objects.ObjCreate(i, j, WallPat);
    end;
end;

procedure ClearSmallRooms(M: TMap);
var
  WallPat: TObjPat;
  i, j: Integer;
begin
  WallPat := TObjPat(GetPattern('OBJECT', 'Wall'));
  for j := 0 to M.Height - 1 do
    for i := 0 to M.Width - 1 do
      if Wave[i, j] = 0 then
        M.Objects.ObjCreate(i, j, WallPat);
end;

procedure GenerateDoors(M: TMap);
var
  i, j, k: Integer;
  DoorPat: TObjPat;
  WallPat: TObjPat;
begin
  DoorPat := TObjPat(GetPattern('OBJECT', 'Door'));
  WallPat := TObjPat(GetPattern('OBJECT', 'Wall'));

  for j := 1 to M.Height - 2 do
    for i := 1 to M.Width - 2 do
      if M.Objects.Obj[i, j] = nil then
      begin
        k := 0;
        if (M.Objects.Obj[i - 1, j] = nil) and (M.Objects.Obj[i + 1, j] = nil) and (M.Objects.Obj[i, j - 1] <> nil) and
          (M.Objects.Obj[i, j + 1] <> nil) then
        begin
          if M.Objects.Obj[i - 1, j - 1] = nil then
            k := k + 1;
          if M.Objects.Obj[i + 1, j - 1] = nil then
            k := k + 1;
          if M.Objects.Obj[i - 1, j + 1] = nil then
            k := k + 1;
          if M.Objects.Obj[i + 1, j + 1] = nil then
            k := k + 1;
          if k > 1 then
            if Random(10) > 0 then
              M.Objects.ObjCreate(i, j, DoorPat);
        end;
        if M.Objects.Obj[i, j] <> nil then
          Continue;
        k := 0;
        if (M.Objects.Obj[i - 1, j] <> nil) and (M.Objects.Obj[i + 1, j] <> nil) and (M.Objects.Obj[i, j - 1] = nil) and
          (M.Objects.Obj[i, j + 1] = nil) then
        begin
          if M.Objects.Obj[i - 1, j - 1] = nil then
            k := k + 1;
          if M.Objects.Obj[i + 1, j - 1] = nil then
            k := k + 1;
          if M.Objects.Obj[i - 1, j + 1] = nil then
            k := k + 1;
          if M.Objects.Obj[i + 1, j + 1] = nil then
            k := k + 1;
          if k > 1 then
            if Random(10) > 0 then
              M.Objects.ObjCreate(i, j, DoorPat);
        end;
      end;

  for j := 0 to M.Height - 2 do
    for i := 0 to M.Width - 2 do
    begin
      if M.Objects.Obj[i, j] = nil then
        Continue;
      if M.Objects.Obj[i, j].Pat <> DoorPat then
        Continue;
      k := 0;
      if M.Objects.Obj[i + 1, j] <> nil then
        if M.Objects.Obj[i + 1, j].Pat = DoorPat then
          k := 1;
      if M.Objects.Obj[i, j + 1] <> nil then
        if M.Objects.Obj[i, j + 1].Pat = DoorPat then
          k := 1;
      { if M.Objects.Obj[i + 1, j + 1] <> nil then
        if M.Objects.Obj[i + 1, j + 1].Pat = DoorPat then k := 1; }
      if k = 1 then
      begin
        M.Objects.Obj[i, j].Free;
        M.Objects.Obj[i, j] := nil;
      end;
    end;

  for j := 1 to M.Height - 2 do
    for i := 1 to M.Width - 2 do
    begin
      if M.Objects.Obj[i, j] = nil then
        Continue;
      if M.Objects.Obj[i, j].Pat <> DoorPat then
        Continue;
      if (M.Objects.Obj[i - 1, j] = nil) and (M.Objects.Obj[i + 1, j] = nil) then
      begin
        if M.Objects.Obj[i, j - 1] = nil then
          M.Objects.ObjCreate(i, j - 1, WallPat);
        if M.Objects.Obj[i, j + 1] = nil then
          M.Objects.ObjCreate(i, j + 1, WallPat);
      end;
      if (M.Objects.Obj[i, j - 1] = nil) and (M.Objects.Obj[i, j + 1] = nil) then
      begin
        if M.Objects.Obj[i - 1, j] = nil then
          M.Objects.ObjCreate(i - 1, j, WallPat);
        if M.Objects.Obj[i + 1, j] = nil then
          M.Objects.ObjCreate(i + 1, j, WallPat);
      end;
    end;

  for j := 1 to M.Height - 2 do
    for i := 1 to M.Width - 2 do
    begin
      if M.Objects.Obj[i, j] = nil then
        Continue;
      if M.Objects.Obj[i, j].Pat.Name <> 'DOOR' then
        Continue;
      if M.Objects.Obj[i - 1, j] = nil then
      begin
        CreateWave(M, i - 1, j, -1, 0, True);
        if Wave[i + 1, j] <> 0 then
        begin
          M.Objects.Obj[i, j].Free;
          M.Objects.Obj[i, j] := nil;
          Continue;
        end;
      end;
      if M.Objects.Obj[i, j - 1] = nil then
      begin
        CreateWave(M, i, j - 1, -1, 0, True);
        if Wave[i, j + 1] <> 0 then
        begin
          M.Objects.Obj[i, j].Free;
          M.Objects.Obj[i, j] := nil;
          Continue;
        end;
      end;
    end;

  for j := 1 to M.Height - 2 do
    for i := 1 to M.Width - 2 do
    begin
      if M.Objects.Obj[i, j] = nil then
        Continue;
      if M.Objects.Obj[i, j].Pat.Name <> 'DOOR' then
        Continue;
      M.Objects.Obj[i, j].BlockWalk := False;
    end;

  for j := 1 to M.Height - 2 do
    for i := 1 to M.Width - 2 do
    begin
      if M.Objects.Obj[i, j] = nil then
        Continue;
      if M.Objects.Obj[i, j].Pat.Name <> 'DOOR' then
        Continue;
      M.Objects.Obj[i, j].BlockWalk := True;
      if M.Objects.Obj[i - 1, j] = nil then
      begin
        CreateWave(M, i - 1, j, -1, 0, True);
        if (Wave[i + 1, j] > 0) and (Wave[i + 1, j] < 20) and (Random(3) = 0) then
        begin
          M.Objects.Obj[i, j].Free;
          M.Objects.Obj[i, j] := nil;
          M.Objects.ObjCreate(i, j, WallPat);
        end;
      end;
      if M.Objects.Obj[i, j - 1] = nil then
      begin
        CreateWave(M, i, j - 1, -1, 0, True);
        if (Wave[i, j + 1] > 0) and (Wave[i, j + 1] < 20) and (Random(3) = 0) then
        begin
          M.Objects.Obj[i, j].Free;
          M.Objects.Obj[i, j] := nil;
          M.Objects.ObjCreate(i, j, WallPat);
        end;
      end;
      if M.Objects.Obj[i, j].Pat.Name = 'DOOR' then
        M.Objects.Obj[i, j].BlockWalk := False;
    end;

  for j := 1 to M.Height - 2 do
    for i := 1 to M.Width - 2 do
    begin
      if M.Objects.Obj[i, j] = nil then
        Continue;
      if M.Objects.Obj[i, j].Pat.Name <> 'DOOR' then
        Continue;
      M.Objects.Obj[i, j].BlockWalk := True;
    end;
end;

procedure GenerateObjects(M: TMap);

  procedure AddMapObject(ObjName: ansistring; Count: Word);
  var
    P: TObjPat;
    i, j, X, Y, C: Integer;
    B: Boolean;
  begin
    P := TObjPat(GetPattern('OBJECT', ObjName));
    C := Count;
    repeat
      X := Random(M.Width - 3) + 2;
      Y := Random(M.Height - 3) + 2;
      B := True;
      for i := X - 1 to X + 1 do
        for j := Y - 1 to Y + 1 do
          if (M.Objects <> nil) and (M.Objects.Obj[i, j] <> nil) then
          begin
            B := False;
            Break;
          end;
      if B then
      begin
        M.Objects.ObjCreate(X, Y, P);
        Dec(C);
      end;
    until C = 0;
  end;

begin
  AddMapObject('LifeShrine', 5);
  AddMapObject('ManaShrine', 5);
  AddMapObject('Up', 50);
  AddMapObject('Down', 50);
  // Map.CreateSpot('Pine', Point(30, 30), 100);
end;

procedure GenerateTreasures(M: TMap);
var
  i, j, k, i1, j1, cnt: Integer;
  ChestPat: TObjPat;
  bool: Boolean;
  PatNames: array [0 .. 3] of ansistring;
begin
  ChestPat := TObjPat(GetPattern('OBJECT', 'Chest'));

  cnt := Random(10) + 20;
  repeat
    i := Random(M.Width - 2) + 1;
    j := Random(M.Height - 2) + 1;
    if M.Objects.Obj[i, j] <> nil then
      Continue;

    PatNames[0] := M.Objects.PatName(i - 1, j);
    PatNames[1] := M.Objects.PatName(i + 1, j);
    PatNames[2] := M.Objects.PatName(i, j - 1);
    PatNames[3] := M.Objects.PatName(i, j + 1);

    bool := True;

    if bool = True then
    begin
      for j1 := j - 2 to j + 2 do
      begin
        for i1 := i - 2 to i + 2 do
          if M.Objects.PatName(i1, j1) = 'DOOR' then
          begin
            bool := False;
            Break;
          end;
        if bool = False then
          Break;
      end;

      if ((PatNames[0] <> '') and (PatNames[1] <> '')) or ((PatNames[2] <> '') and (PatNames[3] <> '')) then
        bool := False;
    end;

    if bool = True then
    begin
      k := 0;
      for j1 := j - 1 to j + 1 do
        for i1 := i - 1 to i + 1 do
          if M.Objects.PatName(i1, j1) = 'WALL' then
            k := k + 1;
      if (k = 0) and (Random(3) > 0) then
        bool := False;
    end;

    if bool = True then
      if (M.Objects.PatName(i, j + 1) = '') and (M.Objects.PatName(i - 1, j + 1) = 'WALL') and (M.Objects.PatName(i + 1, j + 1) = 'WALL') then
        bool := False;
    if bool = True then
      if (M.Objects.PatName(i, j - 1) = '') and (M.Objects.PatName(i - 1, j - 1) = 'WALL') and (M.Objects.PatName(i + 1, j - 1) = 'WALL') then
        bool := False;
    if bool = True then
      if (M.Objects.PatName(i + 1, j) = '') and (M.Objects.PatName(i + 1, j + 1) = 'WALL') and (M.Objects.PatName(i + 1, j - 1) = 'WALL') then
        bool := False;
    if bool = True then
      if (M.Objects.PatName(i - 1, j) = '') and (M.Objects.PatName(i - 1, j + 1) = 'WALL') and (M.Objects.PatName(i - 1, j - 1) = 'WALL') then
        bool := False;

    if bool = True then
    begin
      k := 0;
      for j1 := j - 7 to j + 7 do
        for i1 := i - 7 to i + 7 do
          if M.Objects.PatName(i1, j1) = 'CHEST' then
            k := k + 1;
      if k > 2 then
        bool := False;
      if (k = 2) and (Random(10) = 0) then
        bool := False;
      if (k = 1) and (Random(5) = 0) then
        bool := False;
    end;

    if bool = True then
    begin
      M.Objects.ObjCreate(i, j, ChestPat);
      cnt := cnt - 1;
    end;
  until cnt = 0;

  for j := 1 to M.Height - 2 do
    for i := 1 to M.Width - 2 do
    begin
      if M.Objects.Obj[i, j] <> nil then
        Continue;

      k := 0;
      if M.Objects.PatName(i - 1, j) = 'WALL' then
        k := k + 1;
      if M.Objects.PatName(i + 1, j) = 'WALL' then
        k := k + 1;
      if M.Objects.PatName(i, j - 1) = 'WALL' then
        k := k + 1;
      if M.Objects.PatName(i, j + 1) = 'WALL' then
        k := k + 1;
      if (k = 3) and (Random(5) > 0) then
        M.Objects.ObjCreate(i, j, ChestPat);
    end;
end;

function GetRandSuffix(ItemPat: TItemPat): ansistring;
var
  S: ansistring;
  MapPat: TMapPat;
  SufPat: TSuffixPat;
  B: Boolean;
begin
  Result := '';
  if ItemPat.CanGroup or (ItemPat.Category = icSkill) then
    Exit;
  S := Trim(ItemPat.AllowedSuf);
  if (S = '') then
    Exit;
  S := UpperCase(RandStr(',', S));
  MapPat := nil;
  MapPat := TMapPat(GetPattern('MAP', PCCurMapID));
  if (MapPat = nil) then
    Exit;
  SufPat := nil;
  SufPat := TSuffixPat(GetPattern('SUFFIX', S));
  if (SufPat = nil) then
    Exit;
  B := InRange(SufPat.Level, Clamp(MapPat.Level - 2, 1, MapLevelMax), MapPat.Level);
  if (SufPat <> nil) and (SufPat.Level = 0) then
    B := True;
  if (S <> '') and (SufPat <> nil) and (SufPat.Rarity > 0) and (SufPat.Rarity > Math.RandomRange(0, 1001)) and B then
    Result := S
  else
    Result := '';
end;

function GetRandMaterial(ItemPat: TItemPat): ansistring;
var
  S, M: ansistring;
  MatPat: TMaterialPat;
begin
  Result := '';
  if ItemPat.CanGroup or (ItemPat.Category = icSkill) then
    Exit;
  S := Trim(ItemPat.AllowedMat);
  if (S = '') then
    Exit;
  GenerateMaterials(S);
  M := UpperCase(RandStr(',', S));
  // Box(S);
  MatPat := nil;
  MatPat := TMaterialPat(GetPattern('MATERIAL', M));
  if (M <> '') and (MatPat <> nil) and (MatPat.Rarity > 0) and (MatPat.Rarity > Math.RandomRange(0, 1001)) then
    Result := M
  else
    Result := '';
  if (S <> '') and (Result = '') then
    Result := UpperCase(FirstStr(',', S));
end;

function GetRandDurability(ItemPat: TItemPat): Integer;
begin
  Result := 0;
  if ItemPat.CanGroup then
    Exit;
  Result := Math.RandomRange(ItemPat.Durability div 2, ItemPat.Durability * 2);
end;

function GenItemProp(ItemPat: TItemPat): TItemProp;
begin
  Result := GetItemProp(GetRandSuffix(ItemPat), GetRandMaterial(ItemPat), GetRandDurability(ItemPat));
end;

procedure CreateItems(ItemPat: TItemPat; Count, X, Y: Integer; Prop: TItemProp);
var
  i: Byte;
  C, D, F: Integer;
begin
  if (Count > 2) then
  begin
    C := Count div 3;
    D := Count - (C * 2);
    for i := 1 to 3 do
    begin
      if (i < 3) then
        F := C
      else
        F := D;
      Map.CreateItem(ItemPat, F, X, Y, Prop);
    end;
  end
  else
    Map.CreateItem(ItemPat, Count, X, Y, Prop);
end;

function CreateItem(ItemID: ansistring; X, Y: Integer; F: Boolean = False): Boolean;
var
  Count: Integer;
  ItemPat: TItemPat;
  MapPat: TMapPat;
  Prop: TItemProp;
  B: Boolean;
begin
  Count := 1;
  Result := False;
  ItemPat := nil;
  ItemPat := GetItemPat(ItemID);
  MapPat := nil;
  MapPat := TMapPat(GetPattern('MAP', PCCurMapID));
  if (MapPat = nil) then
  begin
    Result := True;
    Exit;
  end;
  B := InRange(ItemPat.Level, Clamp(MapPat.Level - 1, 1, MapLevelMax), MapPat.Level);
  if (ItemPat <> nil) and (ItemPat.Level = 0) then
    B := True;
  if (ItemPat <> nil) and (ItemPat.Chance > 0) and (ItemPat.Chance > Math.RandomRange(0, 1001)) and B then
  begin
    Result := True;
    Prop := GenItemProp(ItemPat);
    Count := Math.RandomRange(ItemPat.MinCount, ItemPat.MaxCount + 1);
    if (Map.Objects.Obj[X, Y] <> nil) and (Map.Objects.Obj[X, Y].Pat.Name = 'CHEST') then
      Map.Objects.Obj[X, Y].CreateItem(ItemPat, Count, Prop)
    else
      CreateItems(ItemPat, Count, X, Y, Prop);
    if F then
    begin
      Play(ttSndDrop);
      PlayItem(ItemPat, Prop);
    end;
  end;
end;

function GetRandItemName: ansistring;
begin
  Result := '';
  if (AllItemsID = '') then
    Exit;
  Result := RandStr(',', AllItemsID);
end;

procedure RandomItem(X, Y: Integer; F: Boolean = False);
begin
  if not CreateItem(GetRandItemName, X, Y, F) then
    RandomItem(X, Y, F);
end;

procedure TreasuresConvert(M: TMap);
var
  X, Y, Z: Integer;
begin
  for Y := 0 to M.Height - 1 do
    for X := 0 to M.Width - 1 do
    begin
      if (M.Objects.Obj[X, Y] <> nil) and (M.Objects.Obj[X, Y].Pat.Name = 'CHEST') then
        for Z := 1 to Math.RandomRange(30, 41) do
          RandomItem(X, Y)
      else if (Math.RandomRange(1, 501) = 1) then
        RandomItem(X, Y);
    end;
end;

procedure GenerateCreatures(M: TMap);
var
  P: TPoint;
  B: Boolean;
  Cr: TCreature;
  C, k: Integer;
  ItemPat: TItemPat;
begin
  C := Random(10) + 25;
  repeat
    P.X := Random(M.Width - 2) + 1;
    P.Y := Random(M.Height - 2) + 1;
    if (M.GetCreature(P) <> nil) then
      Continue;
    B := True;
    for k := 0 to M.Creatures.Count - 1 do
    begin
      Cr := TCreature(M.Creatures[k]);
      if (ABS(Cr.Pos.X - P.X) < 7) and (ABS(Cr.Pos.Y - P.Y) < 7) then
        if (Math.RandomRange(0, 2) = 0) then
          B := False;
      if not B then
        Break;
    end;
    if not B then
      Continue;
    if (Wave[P.X, P.Y] = 0) or (Wave[P.X, P.Y] > 8) then
    begin
      Cr := nil;
      case Math.RandomRange(0, 9) of
        0 .. 1:
          Cr := Map.CreateCreature('Skelet', P);
        2 .. 3:
          Cr := Map.CreateCreature('Darkeye', P);
        4 .. 5:
          Cr := Map.CreateCreature('Rogue', P);
        6:
          Cr := Map.CreateCreature('Necromancer', P);
        7:
          Cr := Map.CreateCreature('StoneGolem', P);
        8:
          Cr := Map.CreateCreature('Spider', P);
      end;
      if (Cr = nil) then
        Continue;
      Cr.Team := 1;
      Cr.RandEquip();
      RandomItem(Cr.Pos.X, Cr.Pos.Y);
      Dec(C);
    end;
  until (C = 0);
end;

procedure GenerateMaterials(var S: ansistring);
var
  i, j: Integer;
  E: TExplodeResult;
  F: Boolean;
  V: ansistring;
begin
  V := '';
  E := nil;
  S := RemoveBack(',', S);
  // S := 'WOOD,LEATHER'; // Test
  // if (MaterialClasses.Text <> '') then Box(MaterialClasses.Text);
  E := Explode(',', S);
  S := '';
  for j := 0 to High(E) do
  begin
    F := True;
    for i := 0 to MaterialClasses.Count - 1 do
      if (System.Copy(MaterialClasses[i], 1, Length(E[j])) = E[j]) then
      begin
        V := MaterialClasses[i];
        System.Delete(V, 1, Length(E[j]) + 1);
        S := S + V;
        F := False;
        Break;
      end;
    if F then
      S := S + E[j] + ',';
  end;
end;

end.
