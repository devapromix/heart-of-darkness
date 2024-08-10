unit Button;

interface

uses gm_engine, Resources;

type
  TButtonState = (bsNone, bsOver, bsSell);

  TButton = class(TObject)
  private
    Caption: AnsiString;
    Res, Pic: TResEnum;
    Left, Top, D: Integer;
    State: TButtonState;
    Tex: TTexture;
    procedure DrawButton(C: Integer; F: Boolean = True);
  public
    Tag: AnsiString;
    Sellected: Boolean;
    constructor Create(ALeft, ATop: Integer;
      ARes: TResEnum; ACaption: AnsiString; APic: TResEnum; Tex: TTexture); overload;
    constructor Create(ALeft, ATop: Integer; ACaption: AnsiString); overload;
    constructor Create(ALeft, ATop: Integer; ACaption: AnsiString; Tex: TTexture); overload;
    constructor Create(ALeft, ATop: Integer; APic: TResEnum); overload;
    function Click: Boolean;
    function MouseOver: Boolean;
    procedure Render;
  end;

implementation

uses Types, SysUtils, Hint, Sound;

{ TButton }

function TButton.Click: Boolean;
begin
  Result := False;
  if MouseOver and MouseClick(M_BLEFT) then Play(ttSndClick);
  if MouseOver and MouseUp(M_BLEFT) then Result := True;
end;

function TButton.MouseOver: boolean;
begin
  Result := (GetMouse.X > Left) and (GetMouse.X < Left + Resource[Res].Width)
    and (GetMouse.Y > Top) and (GetMouse.Y < Top + Resource[Res].Height);
end;

constructor TButton.Create(ALeft, ATop: Integer; ARes: TResEnum; ACaption: AnsiString; APic: TResEnum; Tex: TTexture);
begin
  D := 0;
  Tag := '';
  Res := ARes;
  Pic := APic;
  Top := ATop;
  Left := ALeft;
  Caption := ACaption;
  Sellected := False;
  Self.Tex := Tex;
end;

constructor TButton.Create(ALeft, ATop: Integer; ACaption: AnsiString);
begin
  Create(ALeft, ATop, ttWButton, ACaption, ttNone, nil);
end;

constructor TButton.Create(ALeft, ATop: Integer; APic: TResEnum);
begin
  Create(ALeft, ATop, ttIButton, '', APic, nil);
end;

constructor TButton.Create(ALeft, ATop: Integer; ACaption: AnsiString; Tex: TTexture);
begin
  Create(ALeft, ATop, ttHButton, ACaption, ttNone, Tex);
end;

procedure TButton.Render;
begin
  if MouseOver and MouseDown(M_BLEFT) then D := 2 else D := 0;
  if MouseOver and not Sellected then State := bsOver else State := bsNone;
  Render2D(Resource[Res], Left + D, Top + D, Resource[Res].Width, Resource[Res].Height, 0, 0);
  case State of
    bsNone: if Sellected then DrawButton(cAMenuCmd) else DrawButton(cMenuCmd, False);
    bsOver: DrawButton(cSelMenuCmd);
  end;
end;

procedure TButton.DrawButton(C: Integer; F: Boolean);
begin
  if (Pic <> ttNone) then Render2D(Resource[Pic], Left + D + 2, Top + D + 2, Resource[Pic].Width, Resource[Pic].Height, 0, 0);
  if (Tex <> nil) then Render2D(Tex, Left + D + 2, Top + D + 2);
  if F then Rect2D(Left + D, Top + D, Resource[Res].Width, Resource[Res].Height, cBlack, 75, PR2D_FILL);
  if (Caption <> '') then
    if (Pic = ttNone) and (Tex = nil) then TextOut(Font[ttFont1], Left + D + ((Resource[Res].Width div 2)
      - (Round(TextWidth(Font[ttFont1], Caption)) div 2)), Top + D +
      ((Resource[Res].Height div 2) - 8), 1, 0, Caption, 255, C, 0)
        else TextOut(Font[ttFont1], Left + D + 20, Top + D +
          ((Resource[Res].Height div 2) - 8), 1, 0, Caption, 255, C, 0);
end;

end.

