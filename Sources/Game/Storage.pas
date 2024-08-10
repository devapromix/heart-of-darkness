unit Storage;

interface

uses gm_engine;

procedure RenderSaveItem(CharName, CharInfo: AnsiString; Left, Top, Color: Integer);

implementation

uses Resources;

procedure RenderSaveItem(CharName, CharInfo: AnsiString; Left, Top, Color: Integer);
begin
  TextOut(Font[ttFont1], Left + 20, Top + 25, 1, 0, CharName, 255, Color, 0);
  TextOut(Font[ttFont1], Left + 20, Top + 42, 1, 0, CharInfo, 255, Color, 0);
end;

end.
