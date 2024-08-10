unit gm_engine;

interface

uses
  zglHeader, Scenes, Types;

// Version
const
  Version: AnsiString = 'v. 0.1 (r. 379)';

  // Colors
const
  cWhite = $FFFFFF;
  cDkWhite = $DDDDDD;
  cBlack = $000000;
  cGray = $232323;
  cLtGray = $666666;
  cDkGray = $333333;
  cRed = $FF0000;
  cDkRed = $FF3333;
  cGreen = $00FF00;
  cLtGreen = $42E741;
  cDkGreen = $20551E;
  cLtBlue = $57A2F8;
  cDkBlue = $21438D;
  cLtYellow = $FFF73A;
  cDkYellow = $D6B96D;
  //
  cDebug = cRed;
  cBonusItem = cLtYellow;
  cHintItem = $999999;
  cMenuCmd = $BBA374;
  cSelMenuCmd = $FFEFB6;
  cAMenuCmd = $FFFFCC;

  cPhys = cWhite;
  cFire = cRed;
  cCold = cLtBlue;
  cElec = cLtYellow;
  cPoison = cLtGreen;

  // MOUSE
const
  M_BLEFT = 0;
  M_BMIDDLE = 1;
  M_BRIGHT = 2;
  M_WUP = 0;
  M_WDOWN = 1;

const
  // KEYBOARD
  K_SYSRQ = $B7;
  K_PAUSE = $C5;
  K_ESCAPE = $01;
  K_ENTER = $1C;
  K_KP_ENTER = $9C;

  K_UP = $C8;
  K_DOWN = $D0;
  K_LEFT = $CB;
  K_RIGHT = $CD;

  K_BACKSPACE = $0E;
  K_SPACE = $39;
  K_TAB = $0F;
  K_TILDE = $29;

  K_INSERT = $D2;
  K_DELETE = $D3;
  K_HOME = $C7;
  K_END = $CF;
  K_PAGEUP = $C9;
  K_PAGEDOWN = $D1;

  K_CTRL = $FF - $01;
  K_CTRL_L = $1D;
  K_CTRL_R = $9D;
  K_ALT = $FF - $02;
  K_ALT_L = $38;
  K_ALT_R = $B8;
  K_SHIFT = $FF - $03;
  K_SHIFT_L = $2A;
  K_SHIFT_R = $36;
  K_SUPER = $FF - $04;
  K_SUPER_L = $DB;
  K_SUPER_R = $DC;
  K_APP_MENU = $DD;

  K_CAPSLOCK = $3A;
  K_NUMLOCK = $45;
  K_SCROLL = $46;

  K_BRACKET_L = $1A; // [ {
  K_BRACKET_R = $1B; // ] }
  K_BACKSLASH = $2B; // \
  K_SLASH = $35; // /
  K_COMMA = $33; // ,
  K_DECIMAL = $34; // .
  K_SEMICOLON = $27; // : ;
  K_APOSTROPHE = $28; // ' "

  K_0 = $0B;
  K_1 = $02;
  K_2 = $03;
  K_3 = $04;
  K_4 = $05;
  K_5 = $06;
  K_6 = $07;
  K_7 = $08;
  K_8 = $09;
  K_9 = $0A;

  K_MINUS = $0C;
  K_EQUALS = $0D;

  K_A = $1E;
  K_B = $30;
  K_C = $2E;
  K_D = $20;
  K_E = $12;
  K_F = $21;
  K_G = $22;
  K_H = $23;
  K_I = $17;
  K_J = $24;
  K_K = $25;
  K_L = $26;
  K_M = $32;
  K_N = $31;
  K_O = $18;
  K_P = $19;
  K_Q = $10;
  K_R = $13;
  K_S = $1F;
  K_T = $14;
  K_U = $16;
  K_V = $2F;
  K_W = $11;
  K_X = $2D;
  K_Y = $15;
  K_Z = $2C;

  K_KP_0 = $52;
  K_KP_1 = $4F;
  K_KP_2 = $50;
  K_KP_3 = $51;
  K_KP_4 = $4B;
  K_KP_5 = $4C;
  K_KP_6 = $4D;
  K_KP_7 = $47;
  K_KP_8 = $48;
  K_KP_9 = $49;

  K_KP_SUB = $4A;
  K_KP_ADD = $4E;
  K_KP_MUL = $37;
  K_KP_DIV = $B5;
  K_KP_DECIMAL = $53;

  K_F1 = $3B;
  K_F2 = $3C;
  K_F3 = $3D;
  K_F4 = $3E;
  K_F5 = $3F;
  K_F6 = $40;
  K_F7 = $41;
  K_F8 = $42;
  K_F9 = $43;
  K_F10 = $44;
  K_F11 = $57;
  K_F12 = $58;

  KA_DOWN = 0;
  KA_UP = 1;

const // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  K_INV = K_I;
  K_CHAR = K_C;
  K_SKILL = K_A;

const
  FOM_CREATE = $01; // Create
  FOM_OPENR = $02; // Read

  PR2D_FILL = $010000;
  PR2D_SMOOTH = $020000;

const
  TEXT_HALIGN_LEFT = $000001;
  TEXT_HALIGN_CENTER = $000002;
  TEXT_HALIGN_RIGHT = $000004;
  TEXT_HALIGN_JUSTIFY = $000008;
  TEXT_VALIGN_TOP = $000010;
  TEXT_VALIGN_CENTER = $000020;
  TEXT_VALIGN_BOTTOM = $000040;
  TEXT_CLIP_RECT = $000080;
  TEXT_FX_VCA = $000100;
  TEXT_FX_LENGTH = $000200;

  // FX
const
  FX_BLEND_NORMAL = $00;
  FX_BLEND_ADD = $01;
  FX_BLEND_MULT = $02;
  FX_BLEND_BLACK = $03;
  FX_BLEND_WHITE = $04;
  FX_BLEND_MASK = $05;

  FX_COLOR_MIX = $00;
  FX_COLOR_SET = $01;

  FX_BLEND = $100000;
  FX_COLOR = $200000;

  // FX 2D
const
  FX2D_FLIPX = $000001;
  FX2D_FLIPY = $000002;
  FX2D_VCA = $000004;
  FX2D_VCHANGE = $000008;
  FX2D_SCALE = $000010;
  FX2D_RPIVOT = $000020;

type
  TRect = record
    Left, Top, Width, Height: Integer;
  end;

type
  TCamera2D = zglTCamera2D;
  TPCamera2D = zglPCamera2D;

type
  TFont = zglPFont;
  TFile = zglTFile;
  TTexture = zglPTexture;
  TSound = zglPSound;

const
  SlotSize = 34;
  CraftGridSize = SlotSize * 3;

var
  ScreenWidth: Integer = 800; // + 500;
  ScreenHeight: Integer = 600; // + 0;// + 300;

  Debug: Boolean = False;

  IsMenu: Boolean = True;
  IsGame: Boolean = False;
  IsTown: Boolean = True;
  IsPortal: Boolean = False;
  IsGate: Boolean = False;
  IsWorld: Boolean = False;

  FullScr: Boolean = False;
  VSync: Boolean = False;

  ChBIFlag: Boolean = False;

  Cam: TCamera2D;
  MPrev: TPoint;

  AllItemsID: AnsiString = '';

  PCAllMapsID: AnsiString = '';
  AllMapsID: AnsiString = '';
  PCCurMapID: AnsiString = '';
  PCDeep: Integer = 0;
  PCMapLevel: Integer = 0;

  NMTime: Integer;
  NewGame: Boolean = False;

  SomeText: AnsiString;
  STPos: TPoint;
  STTime: Integer;

  ShowMinimap: Boolean = True;

  SpellPoints: Integer = 0;
  SellSpellN: Integer = -1;
  BtnDwn: Integer;

  WalkPause: Integer;

  CursorRad: Single = 20;
  CursorFlag: Boolean = True;

procedure DrawMBar(Value, MaxValue, X, Y, W, C: Integer);
procedure DrawBG(C: Integer = cGray; F: Integer = 220);
procedure DrawFrame(X, Y, W, H: Integer);
procedure DrawText(X, Y: Integer; Text: AnsiString);
procedure Sleep(Milliseconds: LongWord);
function CalcX2D(const X: Single): Single;
function CalcY2D(const Y: Single): Single;
function Rect(X, Y, Width, Height: Integer): TRect;
function PointInRect(P: TPoint; X, Y, Width, Height: Integer): Boolean;
function MouseInRect(X, Y, Width, Height: Integer): Boolean;
function StrToPAChar(const Value: AnsiString): PAnsiChar;
function Angle(x1, y1, x2, y2: Single): Single;
function Sin(Angle: Integer): Single;
function Cos(Angle: Integer): Single;
function GetFileExt(const FileName: AnsiString): UTF8String;
function GetDirectory(const FileName: AnsiString): UTF8String;
function GetFileName(const FileName: AnsiString): UTF8String;
// function IntToStr(Value: Integer): UTF8String;
procedure SetFrameSize(var Texture: zglPTexture; FrameWidth, FrameHeight: Word);
function LoadFont(const FileName: AnsiString): TFont;
function LoadTexture(const FileName: AnsiString; TransparentColor: LongWord = TEX_NO_COLORKEY; Flags: LongWord = TEX_DEFAULT_2D): TTexture;
function LoadSound(const FileName: AnsiString; SourceCount: Integer = 8): TSound;
function GetDist(A, B: TPoint): Single;
function MouseDown(Button: Byte): Boolean;
function MouseUp(Button: Byte): Boolean;
function MouseClick(Button: Byte): Boolean;
function MouseDblClick(Button: Byte): Boolean;
function MouseWheel(Axis: Byte): Boolean;
function SetScreenOptions(Width, Height, Refresh: Word; FullScreen, VSync: Boolean): Boolean;
function KeyDown(KeyCode: Byte): Boolean;
function KeyPress(KeyCode: Byte): Boolean;
procedure ClearStates;
procedure ClearKeyState;
procedure ClearMouseState;
procedure TextOut(Font: TFont; X, Y: Single; const Text: AnsiString; Flags: LongWord = 0); overload;
procedure TextOut(Font: TFont; X, Y, Scale, Step: Single; const Text: AnsiString; Alpha: Byte = 255; Color: LongWord = $FFFFFF;
  Flags: LongWord = 0); overload;
function TextWidth(Font: TFont; const Text: AnsiString; Step: Single = 0.0): Single;
procedure InitCamera2D(out Camera: TCamera2D);
procedure SetCamera2D(Camera: TPCamera2D);
function FileGetSize(FileHandle: TFile): LongWord;
function FileWrite(FileHandle: TFile; const Buffer; Bytes: LongWord): LongWord;
function FileOpen(out FileHandle: TFile; const FileName: UTF8String; Mode: Byte): Boolean;
function FileRead(FileHandle: TFile; var Buffer; Bytes: LongWord): LongWord;
procedure FileClose(var FileHandle: TFile);
function StrToBool(const S: AnsiString): Boolean;
function UpperCase(const S: AnsiString): UTF8String;
procedure Circ2D(X, Y, Radius: Single; Color: LongWord = $FFFFFF; Alpha: Byte = 255; Quality: Word = 32; FX: LongWord = 0);
procedure Rect2D(X, Y, W, H: Single; Color: LongWord = $FFFFFF; Alpha: Byte = 255; FX: LongWord = 0);
procedure Line2D(x1, y1, x2, y2: Single; Color: LongWord = $FFFFFF; Alpha: Byte = 255; FX: LongWord = 0);
function PlaySound(Sound: zglPSound; Loop: Boolean = False; X: Single = 0; Y: Single = 0; Z: Single = 0; Volume: Single = SND_VOLUME_DEFAULT)
  : Integer;
procedure Render2D(Texture: zglPTexture; X, Y, W, H, Angle: Single; Frame: Word; Alpha: Byte = 255; FX: LongWord = FX_BLEND); overload;
procedure Render2D(Texture: zglPTexture; X, Y: Single); overload;
procedure RenderSprite2D(Texture: zglPTexture; X, Y, W, H, Angle: Single; Alpha: Byte = 255; FX: LongWord = FX_BLEND);
function Point(X, Y: Integer): TPoint;
function GetMouse: TPoint;
procedure Quit;

implementation

uses Windows, gm_creature, Resources;

procedure DrawMBar(Value, MaxValue, X, Y, W, C: Integer);
var
  I: Byte;
begin
  if (Value = MaxValue) then
    Exit;
  I := Round(Value / MaxValue * (W - 2));
  Rect2D(X + 1, Y + 1, W - 2, 2, cDkGray, 255, PR2D_FILL);
  Rect2D(X + 1, Y + 1, I, 2, C, 255, PR2D_FILL);
  Rect2D(X, Y, W, 4, cBlack, 255);

end;

procedure DrawBG(C: Integer = cGray; F: Integer = 220);
begin
  Rect2D(0, 0, ScreenWidth, ScreenHeight, C, F, PR2D_FILL);
end;

procedure DrawFrame(X, Y, W, H: Integer);
begin
  Render2D(Resource[ttBack], X, Y, W, H, 0, 0);
  Rect2D(X + 1, Y + 1, W - 2, H - 2, cDkYellow);
end;

procedure DrawText(X, Y: Integer; Text: AnsiString);
var
  W: Integer;
begin
  SomeText := Text;
  STPos := Point(X, Y);
  STTime := Length(Text) * 10;
  W := Round(TextWidth(Font[ttFont1], Text));
  if STPos.X + W div 2 > ScreenWidth then
    STPos.X := ScreenWidth - W div 2;
  if STPos.X + W div 2 < 0 then
    STPos.X := W div 2;
end;

procedure Sleep(Milliseconds: LongWord);
begin
  u_Sleep(Milliseconds);
end;

function CalcX2D(const X: Single): Single;
begin
  Result := (X - ScreenWidth / 2) * (1 / ScreenWidth / 2);
end;

function CalcY2D(const Y: Single): Single;
begin
  Result := (Y - ScreenHeight / 2) * (1 / ScreenHeight / 2);
end;

function PlaySound(Sound: zglPSound; Loop: Boolean = False; X: Single = 0; Y: Single = 0; Z: Single = 0; Volume: Single = SND_VOLUME_DEFAULT)
  : Integer;
begin
  // Exit;
  Result := snd_Play(Sound, Loop, X, Y, Z, Volume);
end;

function Rect(X, Y, Width, Height: Integer): TRect;
begin
  Result.Left := X;
  Result.Top := Y;
  Result.Width := Width;
  Result.Height := Height;
end;

function MouseInRect(X, Y, Width, Height: Integer): Boolean;
begin
  Result := (GetMouse.X > X) and (GetMouse.Y > Y) and (GetMouse.X < X + Width) and (GetMouse.Y < Y + Height);
end;

function PointInRect(P: TPoint; X, Y, Width, Height: Integer): Boolean;
begin
  Result := (P.X > X) and (P.Y > Y) and (P.X < X + Width) and (P.Y < Y + Height);
end;

function StrToPAChar(const Value: AnsiString): PAnsiChar;
begin
  Result := PAnsiChar(AnsiString(Value));
end;

function A2U8(const S: AnsiString): AnsiString;
begin
  Result := S;
end;

{ function A2U8(const S: AnsiString; const cp: Integer = 1251): UTF8String;
  var
  wlen, ulen: Integer;
  wbuf: PWideChar;
  begin
  Result := '';
  wlen := MultiByteToWideChar(cp, 0, StrToPAChar(S), Length(S), NIL, 0);
  // wlen is the number of UCS2 without NULL terminater.
  if wlen = 0 then
  Exit;
  wbuf := GetMemory(wlen * sizeof(wchar));
  try
  MultiByteToWideChar(cp, 0, StrToPAChar(S), Length(S), wbuf, wlen);
  ulen := WideCharToMultiByte(CP_UTF8, 0, wbuf, wlen, NIL, 0, NIL, NIL);
  setlength(Result, ulen);
  WideCharToMultiByte(CP_UTF8, 0, wbuf, wlen, StrToPAChar(Result), ulen,
  NIL, NIL);
  finally
  FreeMemory(wbuf);
  end;
  end; }

function Cos(Angle: Integer): Single;
begin
  Result := m_Cos(Angle)
  // Result := System.Cos(Angle)
end;

function Sin(Angle: Integer): Single;
begin
  Result := m_Sin(Angle)
  // Result := System.Sin(Angle)
end;

function Angle(x1, y1, x2, y2: Single): Single;
begin
  Result := m_Angle(x1, y1, x2, y2)
end;

function GetFileExt(const FileName: AnsiString): UTF8String;
begin
  Result := file_GetExtension(A2U8(FileName))
end;

function GetDirectory(const FileName: AnsiString): UTF8String;
begin
  Result := file_GetDirectory(A2U8(FileName))
end;

function GetFileName(const FileName: AnsiString): UTF8String;
begin
  Result := file_GetName(A2U8(FileName))
end;

function IntToStr(Value: Integer): UTF8String;
begin
  Result := u_IntToStr(Value)
end;

procedure SetFrameSize(var Texture: zglPTexture; FrameWidth, FrameHeight: Word);
begin
  tex_SetFrameSize(Texture, FrameWidth, FrameHeight)
end;

function LoadTexture(const FileName: AnsiString; TransparentColor: LongWord = TEX_NO_COLORKEY; Flags: LongWord = TEX_DEFAULT_2D): TTexture;
begin
  Result := tex_LoadFromFile(A2U8(FileName), TransparentColor, Flags)
end;

function LoadSound(const FileName: AnsiString; SourceCount: Integer = 8): TSound;
begin
  Result := snd_LoadFromFile(A2U8(FileName), SourceCount);
end;

function LoadFont(const FileName: AnsiString): TFont;
begin
  Result := font_LoadFromFile(A2U8(FileName))
end;

function GetDist(A, B: TPoint): Single;
begin
  // Result := m_Distance(x1, y1, x2, y2)
  Result := sqrt(sqr(B.X - A.X) + sqr(B.Y - A.Y));
end;

function MouseDown(Button: Byte): Boolean;
begin
  Result := mouse_Down(Button)
end;

function MouseUp(Button: Byte): Boolean;
begin
  Result := mouse_Up(Button)
end;

function MouseClick(Button: Byte): Boolean;
begin
  Result := mouse_Click(Button)
end;

function MouseDblClick(Button: Byte): Boolean;
begin
  Result := mouse_DblClick(Button)
end;

function MouseWheel(Axis: Byte): Boolean;
begin
  Result := mouse_Wheel(Axis)
end;

function SetScreenOptions(Width, Height, Refresh: Word; FullScreen, VSync: Boolean): Boolean;
begin
  Result := scr_SetOptions(Width, Height, Refresh, FullScreen, VSync);
end;

function KeyDown(KeyCode: Byte): Boolean;
begin
  Result := key_Down(KeyCode)
end;

function KeyPress(KeyCode: Byte): Boolean;
begin
  Result := key_Press(KeyCode)
end;

procedure ClearMouseState;
begin
  mouse_ClearState
end;

procedure ClearKeyState;
begin
  key_ClearState
end;

procedure ClearStates;
begin
  mouse_ClearState;
  key_ClearState;
end;

procedure TextOut(Font: TFont; X, Y: Single; const Text: AnsiString; Flags: LongWord = 0); overload;
begin
  text_Draw(Font, X, Y, Text { A2U8(Text) } , Flags)
end;

procedure TextOut(Font: TFont; X, Y, Scale, Step: Single; const Text: AnsiString; Alpha: Byte = 255; Color: LongWord = $FFFFFF;
  Flags: LongWord = 0); overload;
begin
  text_DrawEx(Font, X, Y, Scale, Step, Text { A2U8(Text) } , Alpha, Color, Flags)
end;

function TextWidth(Font: TFont; const Text: AnsiString; Step: Single = 0.0): Single;
begin
  Result := text_GetWidth(Font, Text { A2U8(Text) } , Step)
end;

procedure InitCamera2D(out Camera: TCamera2D);
begin
  cam2d_Init(Camera)
end;

procedure SetCamera2D(Camera: TPCamera2D);
begin
  cam2d_Set(Camera)
end;

function FileGetSize(FileHandle: TFile): LongWord;
begin
  Result := file_GetSize(FileHandle)
end;

function FileWrite(FileHandle: TFile; const Buffer; Bytes: LongWord): LongWord;
begin
  Result := file_Write(FileHandle, Buffer, Bytes)
end;

function FileOpen(out FileHandle: TFile; const FileName: UTF8String; Mode: Byte): Boolean;
begin
  Result := file_Open(FileHandle, FileName, Mode)
end;

function FileRead(FileHandle: TFile; var Buffer; Bytes: LongWord): LongWord;
begin
  Result := file_Read(FileHandle, Buffer, Bytes)
end;

procedure FileClose(var FileHandle: TFile);
begin
  file_Close(FileHandle)
end;

function StrToBool(const S: AnsiString): Boolean;
begin
  Result := u_StrToBool(A2U8(S))
end;

function UpperCase(const S: AnsiString): UTF8String;
begin
  Result := u_StrUp(A2U8(S))
end;

procedure Rect2D(X, Y, W, H: Single; Color: LongWord = $FFFFFF; Alpha: Byte = 255; FX: LongWord = 0);
begin
  pr2d_Rect(X, Y, W, H, Color, Alpha, FX);
  pr2d_Pixel(X + W - 1, Y + H - 1, Color, Alpha);
end;

procedure Circ2D(X, Y, Radius: Single; Color: LongWord = $FFFFFF; Alpha: Byte = 255; Quality: Word = 32; FX: LongWord = 0);
begin
  pr2d_Circle(X, Y, Radius, Color, Alpha, Quality, FX);
end;

procedure Line2D(x1, y1, x2, y2: Single; Color: LongWord = $FFFFFF; Alpha: Byte = 255; FX: LongWord = 0);
begin
  pr2d_Line(x1, y1, x2, y2, Color, Alpha, FX);
end;

procedure Render2D(Texture: zglPTexture; X, Y, W, H, Angle: Single; Frame: Word; Alpha: Byte = 255; FX: LongWord = FX_BLEND);
begin
  asprite2d_Draw(Texture, X, Y, W, H, Angle, Frame, Alpha, FX)
end;

procedure Render2D(Texture: zglPTexture; X, Y: Single);
begin
  asprite2d_Draw(Texture, X, Y, Texture.Width, Texture.Height, 0, 0, 255, FX_BLEND)
end;

procedure RenderSprite2D(Texture: zglPTexture; X, Y, W, H, Angle: Single; Alpha: Byte = 255; FX: LongWord = FX_BLEND);
begin
  ssprite2d_Draw(Texture, X, Y, W, H, Angle, Alpha, FX);
end;

function Point(X, Y: Integer): TPoint;
begin
  Result.X := X;
  Result.Y := Y;
end;

function GetMouse: TPoint;
begin
  Result := Point(mouse_X, mouse_Y);
end;

procedure Quit;
begin
  zgl_Exit;
end;

end.
