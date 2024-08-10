unit CustomCreature;

interface

uses Entity, Bar;

type
  TCustomCreature = class(TEntity)
  private
    FLife: TBar;
    FMana: TBar;
    FExp: TBar;
    FAdr: TBar;
    FLevel: Byte;
    FSkillPoints: Byte;
    FStatPoints: Byte;
    procedure SetLife(const Value: TBar);
    procedure SetMana(const Value: TBar);
    procedure SetExp(const Value: TBar);
    procedure SetLevel(const Value: Byte);
    procedure SetSkillPoints(const Value: Byte);
    procedure SetStatPoints(const Value: Byte);
    procedure SetAdr(const Value: TBar);
  public
    constructor Create(MaxLife, MaxMana: Integer);
    destructor Destroy; override;
    property Life: TBar read FLife write SetLife;
    property Mana: TBar read FMana write SetMana;
    property Exp: TBar read FExp write SetExp;
    property Adr: TBar read FAdr write SetAdr;
    property Level: Byte read FLevel write SetLevel;
    property StatPoints: Byte read FStatPoints write SetStatPoints;
    property SkillPoints: Byte read FSkillPoints write SetSkillPoints;
    procedure Fill;
  end;

implementation

{ TCustomCreature }

constructor TCustomCreature.Create(MaxLife, MaxMana: Integer);
begin
  inherited Create;
  Level := 1;
  StatPoints := 0;
  SkillPoints := 0;
  Life := TBar.Create;
  Life.Max := MaxLife;
  Life.SetToMax;
  Mana := TBar.Create;
  Mana.Max := MaxMana;
  Mana.SetToMax;
  Exp := TBar.Create;
  Exp.Max := 15;
  Exp.SetToMin; 
  Adr := TBar.Create;  
  Adr.Max := 100; 
  Adr.SetToMin;
end;

destructor TCustomCreature.Destroy;
begin
  Life.Free;
  Mana.Free;
  Exp.Free;
  Adr.Free;
  inherited;
end;

procedure TCustomCreature.Fill;
begin
  Life.SetToMax;
  Mana.SetToMax;
end;

procedure TCustomCreature.SetAdr(const Value: TBar);
begin
  FAdr := Value;
end;

procedure TCustomCreature.SetExp(const Value: TBar);
begin
  FExp := Value;
end;

procedure TCustomCreature.SetLevel(const Value: Byte);
begin
  FLevel := Value;
end;

procedure TCustomCreature.SetLife(const Value: TBar);
begin
  FLife := Value;
end;

procedure TCustomCreature.SetMana(const Value: TBar);
begin
  FMana := Value;
end;

procedure TCustomCreature.SetSkillPoints(const Value: Byte);
begin
  FSkillPoints := Value;
end;

procedure TCustomCreature.SetStatPoints(const Value: Byte);
begin
  FStatPoints := Value;
end;

end.
