unit Stat;

interface

type
  TStat = record
    ID, Title, Hint: AnsiString;
    Visible: Boolean;
  end;
  
var
  CrStats    : array of TStat;
  CrStatsCnt : Integer;

type
  TStatEnum = (seStrength, seStamina, seDexterity, seAgility, seWisdom, seIntellect);

procedure Load;

implementation

procedure Add(ID, Title, Hint: AnsiString; Visible: Boolean = True);
begin
  CrStatsCnt := CrStatsCnt + 1;
  SetLength(CrStats, CrStatsCnt);
  CrStats[CrStatsCnt - 1].ID := ID;
  CrStats[CrStatsCnt - 1].Title := Title;
  CrStats[CrStatsCnt - 1].Hint := Hint;
  CrStats[CrStatsCnt - 1].Visible := Visible;
end;

procedure Load;
begin
  CrStatsCnt := 0;
  Add('Strength', '����', '', False);
  Add('Stamina', '���������', '', False);
  Add('Dexterity', '��������', '', False);
  Add('Agility', '�������', '', False);
  Add('Wisdom', '��������', '', False);
  Add('Intellect', '���������', '', False);

  Add('Armor', '������', '');
  Add('Block', '���� �����, %', '');

  Add('ResFire', '����. ����, %', '');
  Add('ResCold', '����. ������, %', '');
  Add('ResElec', '����. ������., %', '');
  Add('ResPoison', '����. ���, %', '');

  Add('Radius', '����� � ������', '');

  Add('DamPhysMin', '���. ���. ����', '');
  Add('DamPhysMax', '����. ���. ����', '');
  Add('DamFireMin', '���. ���� �����', '');
  Add('DamFireMax', '����. ���� �����', '');
  Add('DamColdMin', '���. ���� �������', '');
  Add('DamColdMax', '����. ���� �������', '');
  Add('DamElecMin', '���. ���� ������.', '');
  Add('DamElecMax', '����. ���� ������.', '');
  Add('DamPoisonMin', '���. ���� ����', '');
  Add('DamPoisonMax', '����. ���� ����', '');

  Add('BonusStr', '����� � ����', '');
  Add('BonusSta', '����� � ���������', '');
  Add('BonusDex', '����� � ��������', '');
  Add('BonusAgi', '����� � �������', '');
  Add('BonusWis', '����� � ��������', '');
  Add('BonusInt', '����� � ����������', '');

  Add('BonusLife', '����� � ��������', '');
  Add('BonusMana', '����� � ����', '');

  Add('BonusRefLife', '����� � �. ��������', '');
  Add('BonusRefMana', '����� � �. ����', '');

  Add('Unarmed', '��� ������', '');
  Add('Sword', '���', '');
  Add('Axe', '�����', '');
  Add('Spear', '�����', '');
  Add('Bow', '���', '');
  Add('CrossBow', '�������', '');
  Add('Throwing', '�������', '');
  Add('Magic', '�����', '');
end;

end.
