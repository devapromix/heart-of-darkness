unit Effect;
//http://www.darkswords2.ru/library/fiction/sub/effekty
interface

type
  TEffect = class(TObject)
  private
  public
    Top, Left, Right: Integer;
    function MouseOver: Boolean;
    procedure Render;
    constructor Create;
    destructor Destroy; override;
  end;

var
  PCEffect: TEffect;
  
implementation

uses gm_creature, gm_engine, Resources, SysUtils, Utils, Hint,
  gm_patterns;

{ TEffect }

constructor TEffect.Create;
begin
  Top := ScreenHeight - 66;
  Right := ScreenWidth - 10;
end;

destructor TEffect.Destroy;
begin

  inherited;
end;

function TEffect.MouseOver: Boolean;
begin
  Result := (GetMouse.X > Left) and (GetMouse.X < Right) and (GetMouse.Y > Top) and (GetMouse.Y < Top + 16) and not IsGate and not IsWorld;
end;

procedure TEffect.Render;
var
  I, P: Integer;
  Pat: TEfPat;
begin
  P := 1;
  Left := Right - (PC.ETV.Count * 18);
  for I := 0 to PC.ETV.Count - 1 do
  begin
    Pat := TEfPat(GetPattern('EFFECT', PC.ETV.Name(I)));
    if (Pat = nil) then Continue;
    Render2D(Pat.Tex, Right - (P * 18), Top, 16, 16, 0, 0);
    Inc(P);
  end;
  if MouseOver then
  begin
    I := Clamp(PC.ETV.Count - ((GetMouse.X - Left) div 17) - 1, 0, PC.ETV.Count - 1);
    Pat := TEfPat(GetPattern('EFFECT', PC.ETV.Name(I)));
    if (Pat = nil) then Exit;
    RenderRightHint([Pat.Title, Pat.Hint, 'Длительность ' + IntToStr(PC.ETV.Value(I))]);
  end;
end;

end.
