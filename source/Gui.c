#include <gba.h>

#include "Gui.h"
#include "Shared/EmuMenu.h"
#include "Shared/AsmExtra.h"
#include "Main.h"
#include "FileHandling.h"
#include "Cart.h"
#include "Gfx.h"
#include "io.h"
#include "cpu.h"
#include "ARM6809/Version.h"
#include "SN76496/Version.h"
#include "YieArVideo/Version.h"

#define EMUVERSION "V0.1.6 2024-04-15"

static void uiDebug(void);

const fptr fnMain[] = {nullUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI};

const fptr fnList0[] = {uiDummy};
const fptr fnList1[] = {ui2, ui3, ui4, ui5, ui6, ui7, ui8, gbaSleep, resetGame};
const fptr fnList2[] = {ui9, loadState, saveState, saveSettings, resetGame};
const fptr fnList3[] = {autoBSet, autoASet, controllerSet, swapABSet};
const fptr fnList4[] = {scalingSet, flickSet, gammaSet};
const fptr fnList5[] = {speedSet, autoStateSet, autoSettingsSet, autoPauseGameSet, ewramSet, sleepSet};
const fptr fnList6[] = {debugTextSet, bgrLayerSet, sprLayerSet, stepFrame};
const fptr fnList7[] = {coinASet, coinBSet, bonusSet, demoSet, livesSet, cabinetSet, difficultSet, uprightSet, flipSet, serviceSet};
const fptr fnList8[] = {uiDummy};
const fptr fnList9[] = {quickSelectGame, quickSelectGame};
const fptr *const fnListX[] = {fnList0, fnList1, fnList2, fnList3, fnList4, fnList5, fnList6, fnList7, fnList8, fnList9};
const u8 menuXItems[] = {ARRSIZE(fnList0), ARRSIZE(fnList1), ARRSIZE(fnList2), ARRSIZE(fnList3), ARRSIZE(fnList4), ARRSIZE(fnList5), ARRSIZE(fnList6), ARRSIZE(fnList7), ARRSIZE(fnList8), ARRSIZE(fnList9)};
const fptr drawUIX[] = {uiNullNormal, uiMainMenu, uiFile, uiController, uiDisplay, uiSettings, uiDebug, uiDipswitches, uiAbout, uiLoadGame};

u8 gGammaValue = 0;

char *const autoTxt[]   = {"Off","On","With R"};
char *const speedTxt[]  = {"Normal","200%","Max","50%"};
char *const sleepTxt[]  = {"5min","10min","30min","Off"};
char *const brighTxt[]  = {"I","II","III","IIII","IIIII"};
char *const ctrlTxt[]   = {"1P","2P"};
char *const dispTxt[]   = {"Unscaled","Scaled"};
char *const flickTxt[]  = {"No Flicker","Flicker"};

const char *const coinTxt[] = {
	"1 Coin 1 Credit",  "1 Coin 2 Credits", "1 Coin 3 Credits", "1 Coin 4 Credits",
	"1 Coin 5 Credits", "1 Coin 6 Credits", "1 Coin 7 Credits", "2 Coins 1 Credit",
	"2 Coins 3 Credits","2 Coins 5 Credits","3 Coins 1 Credit", "3 Coins 2 Credits",
	"3 Coins 4 Credits","4 Coins 1 Credit", "4 Coins 3 Credits","Free Play"
};
const char *const diffTxt[] = {"Easy","Normal","Hard","Very Hard"};
const char *const livesTxt[] = {"1","2","3","5"};
const char *const bonusTxt[] = {"30K 80K+","40K 90K+"};
const char *const cabTxt[] = {"Cocktail","Upright"};
const char *const singleTxt[] = {"Single","Dual"};


/// This is called at the start of the emulator
void setupGUI() {
//	keysSetRepeat(25, 4);	// Delay, repeat.
	closeMenu();
}

/// This is called when going from emu to ui.
void enterGUI() {
}

/// This is called going from ui to emu.
void exitGUI() {
}

void quickSelectGame(void) {
	while (loadGame()) {
		redrawUI();
		return;
	}
	closeMenu();
}

void uiNullNormal() {
	uiNullDefault();
}

void uiFile() {
	setupSubMenu("File Handling");
	drawMenuItem("Load Game->");
	drawMenuItem("Load State");
	drawMenuItem("Save State");
	drawMenuItem("Save Settings");
	drawMenuItem("Reset Game");
}

void uiMainMenu() {
	setupSubMenu("Main Menu");
	drawMenuItem("File->");
	drawMenuItem("Controller->");
	drawMenuItem("Display->");
	drawMenuItem("Settings->");
	drawMenuItem("Debug->");
	drawMenuItem("DipSwitches->");
	drawMenuItem("Help->");
	drawMenuItem("Sleep");
	drawMenuItem("Restart");
	if (enableExit) {
		drawMenuItem("Exit");
	}
}

void uiAbout() {
	setupSubMenu("Help");
	drawText("Select: Insert coin", 3);
	drawText("Start:  Start button", 4);
	drawText("DPad:   Move character", 5);
	drawText("Up:     Jump", 6);
	drawText("B:      Punch", 7);
	drawText("A:      Kick", 8);

	drawText("YieArGBA   " EMUVERSION, 17);
	drawText("ARM6809    " ARM6809VERSION, 18);
	drawText("ARMSN76496 " ARMSN76496VERSION, 19);
}

void uiController() {
	setupSubMenu("Controller Settings");
	drawSubItem("B Autofire: ", autoTxt[autoB]);
	drawSubItem("A Autofire: ", autoTxt[autoA]);
	drawSubItem("Controller: ", ctrlTxt[(joyCfg>>29)&1]);
	drawSubItem("Swap A-B:   ", autoTxt[(joyCfg>>10)&1]);
}

void uiDisplay() {
	setupSubMenu("Display Settings");
	drawSubItem("Display: ", dispTxt[gScaling]);
	drawSubItem("Scaling: ", flickTxt[gFlicker]);
	drawSubItem("Gamma: ", brighTxt[gGammaValue]);
}

void uiSettings() {
	setupSubMenu("Other Settings");
	drawSubItem("Speed: ", speedTxt[(emuSettings>>6)&3]);
	drawSubItem("Autoload State: ", autoTxt[(emuSettings>>2)&1]);
	drawSubItem("Autosave Settings: ", autoTxt[(emuSettings>>9)&1]);
	drawSubItem("Autopause Game: ", autoTxt[emuSettings&1]);
	drawSubItem("EWRAM Overclock: ", autoTxt[ewram&1]);
	drawSubItem("Autosleep: ", sleepTxt[(emuSettings>>4)&3]);
}

void uiDipswitches() {
	char s[10];
	setupSubMenu("Dipswitch Settings");
	drawSubItem("Coin A: ", coinTxt[g_dipSwitch0 & 0xF]);
	drawSubItem("Coin B: ", coinTxt[(g_dipSwitch0>>4) & 0xF]);
	drawSubItem("Bonus: ", bonusTxt[(g_dipSwitch1>>3)&1]);
	drawSubItem("Demo Sound: ", autoTxt[(g_dipSwitch1>>7)&1]);
	drawSubItem("Lives: ", livesTxt[g_dipSwitch1 & 3]);
	drawSubItem("Cabinet: ", cabTxt[(g_dipSwitch1>>2)&1]);
	drawSubItem("Difficulty: ", diffTxt[(g_dipSwitch1>>4)&3]);
	drawSubItem("Upright Controls: ", singleTxt[(g_dipSwitch2>>1)&1]);
	drawSubItem("Flip Screen: ", autoTxt[g_dipSwitch2&1]);
	drawSubItem("Service Mode: ", autoTxt[(g_dipSwitch2>>2)&1]);

	setMenuItemRow(15);
	int2Str(coinCounter0, s);
	drawSubItem("CoinCounter1:       ", s);
	int2Str(coinCounter1, s);
	drawSubItem("CoinCounter2:       ", s);
}

void uiDebug() {
	setupSubMenu("Debug");
	drawSubItem("Debug Output: ", autoTxt[gDebugSet&1]);
	drawSubItem("Disable Background: ", autoTxt[gGfxMask&1]);
	drawSubItem("Disable Sprites: ", autoTxt[(gGfxMask>>4)&1]);
	drawSubItem("Step Frame ", NULL);
}

void uiLoadGame() {
	setupSubMenu("Load game");
	drawMenuItem("Yie Ar Kung Fu (US)");
	drawMenuItem("Yie Ar Kung Fu (JP)");
}

void nullUINormal(int key) {
}

void nullUIDebug(int key) {
}

void resetGame() {
	loadCart(0,0);
}


//---------------------------------------------------------------------------------
/// Switch between Player 1 & Player 2 controls
void controllerSet() {				// See io.s: refreshEMUjoypads
	joyCfg ^= 0x20000000;
}

/// Swap A & B buttons
void swapABSet() {
	joyCfg ^= 0x400;
}

/// Turn on/off scaling
void scalingSet(){
	gScaling ^= 0x01;
	refreshGfx();
}

/// Change gamma (brightness)
void gammaSet() {
	gGammaValue++;
	if (gGammaValue > 4) gGammaValue=0;
	paletteInit(gGammaValue);
	paletteTxAll();					// Make new palette visible
	setupMenuPalette();
}

/// Turn on/off rendering of background
void bgrLayerSet(){
	gGfxMask ^= 0x03;
}
/// Turn on/off rendering of sprites
void sprLayerSet(){
	gGfxMask ^= 0x10;
}

/// Number of coins for credits
void coinASet() {
	int i = (g_dipSwitch0+1) & 0xF;
	g_dipSwitch0 = (g_dipSwitch0 & ~0xF) | i;
}
/// Number of coins for credits
void coinBSet() {
	int i = (g_dipSwitch0+0x10) & 0xF0;
	g_dipSwitch0 = (g_dipSwitch0 & ~0xF0) | i;
}
/// At which score you get bonus lifes
void bonusSet() {
	g_dipSwitch1 ^= 0x08;
}
/// Demo sound on/off
void demoSet() {
	g_dipSwitch1 ^= 0x80;
}
/// Number of lifes to start with
void livesSet() {
	int i = (g_dipSwitch1+1) & 3;
	g_dipSwitch1 = (g_dipSwitch1 & ~3) | i;
}
/// Cocktail/upright
void cabinetSet() {
	g_dipSwitch1 ^= 0x04;
}
/// Game difficulty
void difficultSet() {
	int i = (g_dipSwitch1+0x10) & 0x30;
	g_dipSwitch1 = (g_dipSwitch1 & ~0x30) | i;
}
/// Dual or single controlls for upright set
void uprightSet() {
	g_dipSwitch2 ^= 0x02;
}
/// Flip screen
void flipSet() {
	g_dipSwitch2 ^= 0x01;
}
/// Test/Service mode
void serviceSet() {
	g_dipSwitch2 ^= 0x04;
}
