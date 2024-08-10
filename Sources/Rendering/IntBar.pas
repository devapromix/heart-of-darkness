unit IntBar;

interface

uses gm_engine, Resources;

type
  TIntBar = class(TObject)
  private
    ttRes: TResEnum;
    Top, Left, Prev: Integer;
  public
    constructor Create(Left, Top: Integer; Res: TResEnum);
    destructor Destroy; override;
    procedure Render(Cur, Max: Integer; F: Boolean = False);
    function MouseOver(): Boolean;
  end;

implementation

uses SysUtils, Utils;

{ TIntBar }

constructor TIntBar.Create(Left, Top: Integer; Res: TResEnum);
begin
  Prev := 0;
  ttRes := Res;
  Self.Top := Top;  
  Self.Left := Left;
end;

destructor TIntBar.Destroy;
begin
  inherited;
end;

function TIntBar.MouseOver: Boolean;   
begin
  Result := (GetMouse.X > Left) and (GetMouse.X < Left + 202) and (GetMouse.Y > Top) and (GetMouse.Y < Top + 18) and not IsGate and not IsWorld;
end;

procedure TIntBar.Render(Cur, Max: Integer; F: Boolean = False);
var
  S: ansistring;
begin
  Render2D(Resource[ttBackbar], Left, Top, Resource[ttBackbar].Width, Resource[ttBackbar].Height, 0, 0);
  Render2D(Resource[ttRes], Left + 1, Top + 1, BarWidth(Cur, Max, 200), Resource[ttRes].Height, 0, 0);
  if MouseOver or F then
  begin
    S := IntToStr(Cur) + '/' + IntToStr(Max);  
    TextOut(Font[ttFont1], Left + 101 - (Round(TextWidth(Font[ttFont1], S)) div 2), Top + 3, S);
  end;
end;

end.
