unit SceneChar;

interface

uses Scenes, SceneFrame;

type
  TSceneChar = class(TSceneBaseFrame)
  private

  public
    constructor Create(FramePos: TFramePos);
    procedure Render(); override;
    procedure Update(); override;
    destructor Destroy; override;
  end;

implementation

uses gm_engine, SysUtils, SceneInv, Resources, gm_creature, Stat, Hint,
  Utils;

const
  L = (FrameWidth div 2) - (Span + (Span div 2));   
  AtrCount = 6;
  PrmCount = 12;

{ TSceneChar }

constructor TSceneChar.Create(FramePos: TFramePos);
begin
  inherited;
end;

destructor TSceneChar.Destroy;
begin

  inherited;
end;

procedure TSceneChar.Render;
var
  X, Y, P: Word;
  F: 0..1;

  procedure Add(S, V, H: ansistring; Flag: Boolean = False);
  var
    I, Z: Word;
  begin
    if (F = 0) then
    begin
      TextOut(Font[ttFont1], Self.Left + Span + X, FrameTop + Span + P, S);
      Z := Round(TextWidth(Font[ttFont1], V));
      if Flag then
        TextOut(Font[ttFont1], Left + Span + L + X - Z, FrameTop + Span + P, 1, 0, V, 255, cBonusItem)
          else TextOut(Font[ttFont1], Left + Span + L + X - Z, FrameTop + Span + P, V);
    end else begin
      if (H = '') then Exit;
      if MouseInRect(Self.Left + Span + X, FrameTop + Span + P - (Span div 2), L, CharHeight) then
      begin
        InitSHint(GetMouse.X, GetMouse.Y, H);
        HintBG(SHint.X, SHint.Y, SHint.W, SHint.H);
        for I := 0 to Length(SHint.Text) - 1 do
          TextOut(Font[ttFont1], SHint.X + SHint.W div 2, SHint.Y + (I * 15) + 10, 1, 0, SHint.Text[I], 255, SHint.Color[I], TEXT_HALIGN_CENTER);
      end;
    end;
  end;

begin
  inherited;
  for F := 0 to 1 do
  begin
    X := 0; Y := 0; P := 0;

    Add('Уровень', IntToStr(PC.Level), 'Опыт ' + PC.Exp.ToString);
    Inc(P, CharHeight);
    Inc(P, CharHeight div 2);

    Add('Здоровье', PC.Life.ToString, 'Восстановление здоровья ' + IntToStr(PC.RefLife));
    Inc(P, CharHeight);
    Add('Мана', PC.Mana.ToString, 'Восстановление маны ' + IntToStr(PC.RefMana));
    Inc(P, CharHeight);
    Inc(P, CharHeight div 2);

    Add('Сила', IntToStr(PC.GetParamValue('Strength') + PC.GetParamValue('BonusStr')), 'Влияет на урон в ближнем бою и скорость восстановления здоровья', PC.GetParamValue('BonusStr') > 0);
    Inc(P, CharHeight);
    Add('Стойкость', IntToStr(PC.GetParamValue('Stamina') + PC.GetParamValue('BonusSta')), 'Определяет запас здоровья', PC.GetParamValue('BonusSta') > 0);
    Inc(P, CharHeight);
    Add('Ловкость', IntToStr(PC.GetParamValue('Dexterity') + PC.GetParamValue('BonusDex')), 'Вероятность попасть по врагу', PC.GetParamValue('BonusDex') > 0);
    Inc(P, CharHeight);
    Add('Реакция', IntToStr(PC.GetParamValue('Agility') + PC.GetParamValue('BonusAgi')), 'Вероятность увернуться от врага', PC.GetParamValue('BonusAgi') > 0);
    Inc(P, CharHeight);
    Add('Мудрость', IntToStr(PC.GetParamValue('Wisdom') + PC.GetParamValue('BonusWis')), 'Влияет на скорость восстановления маны', PC.GetParamValue('BonusWis') > 0);
    Inc(P, CharHeight);
    Add('Интеллект', IntToStr(PC.GetParamValue('Intellect') + PC.GetParamValue('BonusInt')), 'Определяет запас маны', PC.GetParamValue('BonusInt') > 0);
    Inc(P, CharHeight);
    Inc(P, CharHeight div 2);

    repeat
      
      if not CrStats[Y].Visible then
      begin
        Inc(Y);
        Continue;
      end;
      Add(CrStats[Y].Title, IntToStr(PC.ParamValue[Y]), CrStats[Y].Hint);
      Inc(Y); Inc(P, CharHeight);
      if (Y = AtrCount) then Inc(P, CharHeight div 2);
      if (Y = AtrCount + PrmCount + 1) then
      begin
        X := (FrameWidth div 2) - (Span div 2); 
        P := 0;
      end;
    until(Y = CrStatsCnt);
  end;
end;

procedure TSceneChar.Update;
begin
  inherited;
  PC.Calculator;
end;

end.

