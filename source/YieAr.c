#include <gba.h>

#include "YieAr.h"
#include "Gfx.h"
#include "cpu.h"
#include "Sound.h"
#include "YieArVideo/YieArVideo.h"
#include "SN76496/SN76496.h"
#include "ARM6809/ARM6809.h"


int packState(void *statePtr) {
	int size = 0;
	size += yiearSaveState(statePtr+size, &yieAr_0);
	size += sn76496SaveState(statePtr+size, &SN76496_0);
	size += m6809SaveState(statePtr+size, &m6809CPU0);
	return size;
}

void unpackState(const void *statePtr) {
	int size = 0;
	size += yiearLoadState(&yieAr_0, statePtr+size);
	size += sn76496LoadState(&SN76496_0, statePtr+size);
	m6809LoadState(&m6809CPU0, statePtr+size);
}

int getStateSize() {
	int size = 0;
	size += yiearGetStateSize();
	size += sn76496GetStateSize();
	size += m6809GetStateSize();
	return size;
}
