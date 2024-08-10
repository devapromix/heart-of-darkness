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
  Add('Strength', 'Сила', '', False);
  Add('Stamina', 'Стойкость', '', False);
  Add('Dexterity', 'Ловкость', '', False);
  Add('Agility', 'Реакция', '', False);
  Add('Wisdom', 'Мудрость', '', False);
  Add('Intellect', 'Интеллект', '', False);

  Add('Armor', 'Защита', '');
  Add('Block', 'Шанс блока, %', '');

  Add('ResFire', 'Сопр. огню, %', '');
  Add('ResCold', 'Сопр. холоду, %', '');
  Add('ResElec', 'Сопр. электр., %', '');
  Add('ResPoison', 'Сопр. яду, %', '');

  Add('Radius', 'Бонус к обзору', '');

  Add('DamPhysMin', 'Мин. физ. урон', '');
  Add('DamPhysMax', 'Макс. физ. урон', '');
  Add('DamFireMin', 'Мин. урон огнем', '');
  Add('DamFireMax', 'Макс. урон огнем', '');
  Add('DamColdMin', 'Мин. урон холодом', '');
  Add('DamColdMax', 'Макс. урон холодом', '');
  Add('DamElecMin', 'Мин. урон электр.', '');
  Add('DamElecMax', 'Макс. урон электр.', '');
  Add('DamPoisonMin', 'Мин. урон ядом', '');
  Add('DamPoisonMax', 'Макс. урон ядом', '');

  Add('BonusStr', 'Бонус к силе', '');
  Add('BonusSta', 'Бонус к стойкости', '');
  Add('BonusDex', 'Бонус к ловкости', '');
  Add('BonusAgi', 'Бонус к реакции', '');
  Add('BonusWis', 'Бонус к мудрости', '');
  Add('BonusInt', 'Бонус к интеллекту', '');

  Add('BonusLife', 'Бонус к здоровью', '');
  Add('BonusMana', 'Бонус к мане', '');

  Add('BonusRefLife', 'Бонус к в. здоровья', '');
  Add('BonusRefMana', 'Бонус к в. маны', '');

  Add('Unarmed', 'Без оружия', '');
  Add('Sword', 'Меч', '');
  Add('Axe', 'Топор', '');
  Add('Spear', 'Копье', '');
  Add('Bow', 'Лук', '');
  Add('CrossBow', 'Арбалет', '');
  Add('Throwing', 'Метание', '');
  Add('Magic', 'Магия', '');
end;

end.
