unit Sound;

interface

uses Resources;

procedure Play(Value: TSndEnum);

implementation

uses gm_engine;

procedure Play(Value: TSndEnum);
begin
  PlaySound(Resources.Sound[Value]);
end;

end.
