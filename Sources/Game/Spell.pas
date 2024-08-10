unit Spell;

interface

type
  TSpell = record
    Name  : AnsiString;
    Mana  : Integer;
    Time  : Integer;
  end;

var
  AllSpells    : array of TSpell;
  AllSpellsCnt : Integer = 0;

procedure Load;

implementation

procedure Add(Name: AnsiString; Mana, Int: Integer);
begin
  AllSpellsCnt := AllSpellsCnt + 1;
  SetLength(AllSpells, AllSpellsCnt);
  AllSpells[AllSpellsCnt - 1].Name := Name;
  AllSpells[AllSpellsCnt - 1].Mana := Mana;
  AllSpells[AllSpellsCnt - 1].Time := Int;
end;

procedure Load;
begin
  Add('ְנלאדוההמם', 30, 8);
end;

end.
