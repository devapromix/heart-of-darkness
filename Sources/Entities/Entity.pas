unit Entity;

interface

uses Types;

type
  TEntity = class(TObject)   
  private
    FPos: TPoint;
    FName: ansistring;
    function GetPos: TPoint;
    procedure SetName(const Value: ansistring);
  public
    procedure SetPosition(const A: TPoint); overload;
    procedure SetPosition(const X, Y: Integer); overload;
    constructor Create();
    procedure Empty;
    destructor Destroy; override;
    property Pos: TPoint read GetPos;
    property Name: ansistring read FName write SetName;
  end;

implementation    

{ TEntity }

constructor TEntity.Create;
begin
  Empty;
end;

destructor TEntity.Destroy;
begin

  inherited;
end;

procedure TEntity.Empty;
begin
  Name := ''
end;

function TEntity.GetPos: TPoint;
begin
  Result := FPos
end;

procedure TEntity.SetName(const Value: ansistring);
begin
  FName := Value
end;

procedure TEntity.SetPosition(const X, Y: Integer);
begin
  FPos := Point(X, Y)
end;

procedure TEntity.SetPosition(const A: TPoint);
begin
  FPos := A
end;

end.
