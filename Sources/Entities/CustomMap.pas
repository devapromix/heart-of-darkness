unit CustomMap;

interface

type
  TCustomMap = class(TObject)
  private
    FHeight: Integer;
    FWidth: Integer;
    function GetHeight: Integer;
    function GetWidth: Integer;
  public
    constructor Create(Width, Height: Integer);
    property Width: Integer read GetWidth;
    property Height: Integer read GetHeight;
  end;

implementation    

{ TCustomMap }

constructor TCustomMap.Create(Width, Height: Integer);
begin
  FHeight := Height;
  FWidth := Width;
end;

function TCustomMap.GetHeight: Integer;
begin
  Result := FHeight;
end;

function TCustomMap.GetWidth: Integer;
begin
  Result := FWidth;
end;

end.
