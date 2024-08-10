unit Resources;

interface

uses gm_engine;

type
  TFontEnum = (ttFont1, ttFont2);

type
  TResEnum = (ttNone, ttBack, ttFire, ttIce, ttSellCell, ttNSellCell, ttItemSlot, ttDoll, ttGold,
    ttBackbar, ttLifebar, ttManabar, ttExpbar, ttAdrbar, ttClose, ttPickup, ttDnArrow,
    ttBackRedItem, ttBackGreenItem, ttBackBlueItem, ttBackGoldItem, ttBackGrayItem, ttPrayer,
    // Map
    ttChar,
    // Buttons
    ttIButton, ttWButton, ttHButton, ttMale, ttFemale, ttGName, ttCup, ttUp, ttDown, ttInfo, ttDelete,
    // Backgrounds
    ttMenuBG, ttAboutBG, ttTavernBG, ttBlankBG, ttConfigBG,
    // Tilesets 16x16
    ttEffects,
    // Tilesets 32x32
    ttIL, ttBlood, ttStone, ttBone);

type
  TSndEnum = (ttSndClick, ttSndMenu, ttSndLevel, ttSndOpen, ttSndClose,
    ttSndClosed, ttSndPickup, ttSndDamageItem, ttSndOpenPortal, ttSndUsePortal,
    ttSndInfo, ttSndDefine, ttSndNoMana, ttSndUseScroll, ttSndScroll,
    ttSndUseElixir, ttSndElixir, ttSndGem, ttSndKey, ttSndAmulet, ttSndRing,
    ttSndProj, ttSndCoins, ttSndDrop, ttSndSmith, ttSndBubble, ttSndGive,
    ttSndVase);

var
  Font: array [TFontEnum] of TFont;
  Resource: array [TResEnum] of TTexture;
  Sound: array [TSndEnum] of TSound;

const
  FontPath: array [TFontEnum] of string = (
  'mods\default\fonts\font.zfi',
  'mods\default\fonts\font2.zfi'
  );
  ResourcePath: array [TResEnum] of string = ('',
  'mods\core\sprites\back.png',
  'mods\core\sprites\fire.png',
  'mods\core\sprites\ice.png',
  'mods\core\sprites\glow.png',
  'mods\core\sprites\nglow.png',
  'mods\core\sprites\itemslot.png',
  'mods\core\sprites\doll.png',
  'mods\core\sprites\gold.png',
  'mods\core\sprites\backbar.png',
  'mods\core\sprites\lifebar.png',
  'mods\core\sprites\manabar.png',
  'mods\core\sprites\expbar.png',
  'mods\core\sprites\adrbar.png',
  'mods\core\sprites\close.png',
  'mods\core\sprites\pickup.png',
  'mods\core\sprites\down.png',
  'mods\core\sprites\backreditem.png',
  'mods\core\sprites\backgreenitem.png',
  'mods\core\sprites\backblueitem.png',
  'mods\core\sprites\backgolditem.png',
  'mods\core\sprites\backgrayitem.png',
  'mods\core\sprites\prayer.png',
  // Map
  'mods\core\sprites\char.png',
  // Buttons
  'mods\default\controls\ibutton.png',
  'mods\default\controls\wbutton.png',
  'mods\default\controls\hbutton.png',
  'mods\default\controls\male.png',
  'mods\default\controls\female.png',
  'mods\default\controls\gname.png',
  'mods\default\controls\cup.png',
  'mods\default\controls\up.png',
  'mods\default\controls\down.png',
  'mods\default\controls\info.png',
  'mods\default\controls\delete.png',
  // Backgrounds
  'mods\default\backgrounds\menu.png',
  'mods\default\backgrounds\about.png',
  'mods\default\backgrounds\tavern.png',
  'mods\default\backgrounds\blank.png',
  'mods\default\backgrounds\config.png',
  // Tilesets 16x16
  'mods\core\sprites\effects.png',
  // Tilesets 32x32
  'mods\core\sprites\il.png',
  'mods\core\sprites\blood.png',
  'mods\core\sprites\stone.png',
  'mods\core\sprites\bone.png'
  );
  SoundPath: array [TSndEnum] of string = (
  'mods\core\sounds\click.ogg',
  'mods\core\sounds\menu.ogg',
  'mods\core\sounds\level.ogg',
  'mods\core\sounds\open.ogg',
  'mods\core\sounds\close.ogg',
  'mods\core\sounds\closed.ogg',
  'mods\core\sounds\pickup.ogg',
  'mods\core\sounds\ditem.ogg',
  'mods\core\sounds\openportal.ogg',
  'mods\core\sounds\useportal.ogg',
  'mods\core\sounds\info.ogg',
  'mods\core\sounds\define.ogg',
  'mods\core\sounds\nomana.ogg',
  'mods\core\sounds\usescroll.ogg',
  'mods\core\sounds\scroll.ogg',
  'mods\core\sounds\useelixir.ogg',
  'mods\core\sounds\elixir.ogg',
  'mods\core\sounds\gem.ogg',
  'mods\core\sounds\key.ogg',
  'mods\core\sounds\amulet.ogg',
  'mods\core\sounds\ring.ogg',
  'mods\core\sounds\projectile.ogg',
  'mods\core\sounds\coins.ogg',
  'mods\core\sounds\drop.ogg',
  'mods\core\sounds\smith.ogg',
  'mods\core\sounds\bubble.ogg',
  'mods\core\sounds\give.ogg',
  'mods\core\sounds\vase.ogg'
  );

procedure Load;

implementation

procedure Load;
var
  J: TFontEnum;
  I: TResEnum;
  S: TSndEnum;
begin
  for J := Low(TFontEnum) to High(TFontEnum) do Font[J] := LoadFont('..\' + FontPath[J]);
  for I := Low(TResEnum) to High(TResEnum) do Resource[I] := LoadTexture('..\' + ResourcePath[I]);
  for S := Low(TSndEnum) to High(TSndEnum) do Sound[S] := LoadSound('..\' + SoundPath[S]);
  // Tilesets 16x16
  for I := ttEffects to ttEffects do SetFrameSize(Resource[I], 16, 16);
  // Tilesets 32x32
  for I := ttIL to ttBone do SetFrameSize(Resource[I], 32, 32);
end;

end.
