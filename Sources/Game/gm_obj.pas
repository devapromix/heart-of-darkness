unit gm_obj;

interface

uses
  gm_engine, gm_patterns, gm_item, CustomMap;

type
  TObj = class(TObject)
    Pat       : TObjPat;
    FrameN    : Byte;
    BlockWalk : Boolean;
    BlockLook : Boolean;
    Items     : array of TItem;
    ItemsCnt  : Integer;
    function CreateItem(ItemPat: TItemPat; Count: Integer; Prop: TItemProp): Boolean;
  end;

type
  TObjects = class(TCustomMap)
    Obj: array of array of TObj;
    constructor Create;
    destructor Destroy; override;
    procedure Draw;
    procedure Update;
    procedure ObjCreate(tx, ty: Integer; ObjPat: TObjPat);
    procedure Clear;
    function IsWall(tx, ty : Integer) : Boolean;
    function PatName(tx, ty : Integer) : AnsiString;
  end;

var
  LookAtObj: TObj;

implementation

uses Resources, Utils, SceneInv, SceneFrame, gm_map;

function TObj.CreateItem(ItemPat: TItemPat; Count: Integer; Prop: TItemProp): Boolean;
var
  I: Integer;
begin
  Result := True;
  if ItemPat.CanGroup then
    for i := 0 to ItemsCnt - 1 do
      if (Items[i].Count > 0) then
        if (Items[i].Pat = ItemPat) then
        begin
          Items[i].Count := Items[i].Count + Count;
          Exit;
        end;
  for i := 0 to ItemsCnt - 1 do
    if (Items[i].Count = 0) then
    begin
      Items[i].Pat := ItemPat;
      Items[i].Count := Count;
      Items[i].Prop := Prop;
      Exit;
    end;
  if ItemsCnt = ChestCapacity then
  begin
    Result := False;
    Exit;
  end;
  ItemsCnt := ItemsCnt + 1; {I}
  SetLength(Items, ItemsCnt);
  Items[ItemsCnt - 1].Pat := ItemPat;
  Items[ItemsCnt - 1].Count := Count;
  Items[ItemsCnt - 1].Prop := Prop;
  AddItemProp(@Items[ItemsCnt - 1]);  
end;

constructor TObjects.Create;
begin
  inherited Create(MapSide, MapSide);
  SetLength(Obj, Width, Height);
end;

destructor TObjects.Destroy;
var
  i, j: Integer;
begin
  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
      if (Obj[i, j] <> nil) then
      begin
        Obj[i, j].Free;
        Obj[i, j] := nil;
      end;
  inherited;
end;

procedure TObjects.Draw;
var
  i, j: Integer;
  Pat: TObjPat;
begin
  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
    begin
      if (Obj[i, j] = nil) then Continue;
      Pat := Obj[i, j].Pat;

      Render2D(Pat.Tex, i * 32, j * 32, 32, 32, 0, Obj[i, j].FrameN + 1);

      if not Obj[i, j].Pat.IsWall then Continue;
      
      if not IsWall(i, j + 1) then
      begin
//        RenderSprite2D(Resource[ttBlack], i * 32, j * 32, 32, 32, 180, 200);
//        RenderSprite2D(Resource[ttShadow], i * 32, j * 32 + 32, Resource[ttShadow].Width, Resource[ttShadow].Height, 0, 30);
      end;
      if not IsWall(i + 1, j) then
      begin
//        RenderSprite2D(Resource[ttBlack], i * 32, j * 32, 32, 32, 90, 200);
//        RenderSprite2D(Resource[ttShadow], i * 32 + 16, j * 32 + 16, Resource[ttShadow].Width, Resource[ttShadow].Height, 90, 30, FX_BLEND or FX2D_FLIPX);
      end;
//      if IsWall(i, j - 1) = False then RenderSprite2D(Resource[ttWhite], i * 32, j * 32, 32, 32, 0, 100);
//      if IsWall(i - 1, j) = False then RenderSprite2D(Resource[ttWhite], i * 32, j * 32, 32, 32, 270, 100);
    end;
end;

procedure TObjects.Update;
begin

end;

procedure TObjects.ObjCreate(tx, ty: Integer; ObjPat: TObjPat);
begin
  if (tx < 0) or (ty < 0) or (tx >= Width) or (ty >= Height) then Exit;
  if Obj[tx, ty] <> nil then Obj[tx, ty].Free;
  Exit;
  Obj[tx, ty] := TObj.Create;
  Obj[tx, ty].Pat := ObjPat;
  Obj[tx, ty].BlockWalk := ObjPat.BlockWalk;
  Obj[tx, ty].BlockLook := ObjPat.BlockLook;
  if ObjPat.Container then
  begin
    Obj[tx, ty].ItemsCnt := ChestCapacity;
    SetLength(Obj[tx, ty].Items, ChestCapacity);
  end;
end;

procedure TObjects.Clear;
var
  i, j: Integer;
begin
  for j := 0 to Height - 1 do
    for i := 0 to Width - 1 do
      if (Obj[i, j] <> nil) then
      begin
        Obj[i, j].Free;
        Obj[i, j] := nil;
      end;
end;

function TObjects.IsWall(tx, ty: Integer): Boolean;
begin
  Result := False;
  if (tx < 0) or (ty < 0) or (tx >= Width) or (ty >= Height) then Exit;
  if (Obj[tx, ty] = nil) then Exit;
  Result := Obj[tx, ty].Pat.IsWall;
end;

function TObjects.PatName(tx, ty: Integer): AnsiString;
begin
  Result := '';
  if (tx < 0) or (ty < 0) or (tx >= Width) or (ty >= Height) then Exit;
  if (Obj[tx, ty] = nil) then Exit;
  Result := Obj[tx, ty].Pat.Name;
end;

end.
