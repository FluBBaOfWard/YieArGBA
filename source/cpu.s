#ifdef __arm__

#include "Shared/gba_asm.h"
#include "ARM6809/ARM6809mac.h"
#include "YieArVideo/YieArVideo.i"

#define CYCLE_PSL (96)

	.global frameTotal
	.global waitMaskIn
	.global waitMaskOut
	.global m6809CPU0

	.global run
	.global stepFrame
	.global cpuInit
	.global cpuReset


	.syntax unified
	.arm

#ifdef GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
	.align 2
;@----------------------------------------------------------------------------
run:						;@ Return after X frame(s)
	.type   run STT_FUNC
;@----------------------------------------------------------------------------
	ldrh r0,waitCountIn
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountIn
	bxne lr
	stmfd sp!,{r4-r11,lr}

;@----------------------------------------------------------------------------
runStart:
;@----------------------------------------------------------------------------
	ldr r0,=EMUinput
	ldr r0,[r0]

	ldr r2,=yStart
	ldrb r1,[r2]
	tst r0,#0x200				;@ L?
	subsne r1,#1
	movmi r1,#0
	tst r0,#0x100				;@ R?
	addne r1,#1
	cmp r1,#GAME_HEIGHT-SCREEN_HEIGHT
	movpl r1,#GAME_HEIGHT-SCREEN_HEIGHT
	strb r1,[r2]

	bl refreshEMUjoypads		;@ Z=1 if communication ok

	ldr m6809ptr,=m6809CPU0
	add r0,m6809ptr,#m6809Regs
	ldmia r0,{m6809f-m6809pc,m6809sp}	;@ Restore M6809 state
	b konamiFrameLoop

	.section .iwram, "ax", %progbits	;@ For the GBA
;@----------------------------------------------------------------------------
konamiFrameLoop:
;@----------------------------------------------------------------------------
	mov r0,#CYCLE_PSL
	bl m6809RunXCycles
	ldr koptr,=yieAr_0
	bl yiearDoScanline
	cmp r0,#0
	bne konamiFrameLoop
	b konamiEnd
;@----------------------------------------------------------------------------

	.section .ewram,"ax"
konamiEnd:
	add r0,m6809ptr,#m6809Regs
	stmia r0,{m6809f-m6809pc,m6809sp}	;@ Save M6809 state

	ldr r1,=fpsValue
	ldr r0,[r1]
	add r0,r0,#1
	str r0,[r1]

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldrh r0,waitCountOut
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountOut
	ldmfdeq sp!,{r4-r11,lr}		;@ Exit here if doing single frame:
	bxeq lr						;@ Return to rommenu()
	b runStart

;@----------------------------------------------------------------------------
cyclesPerScanline:	.long 0
frameTotal:			.long 0		;@ Let Gui.c see frame count for savestates
waitCountIn:		.byte 0
waitMaskIn:			.byte 0
waitCountOut:		.byte 0
waitMaskOut:		.byte 0

;@----------------------------------------------------------------------------
stepFrame:					;@ Return after 1 frame
	.type   stepFrame STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	ldr m6809ptr,=m6809CPU0
	add r0,m6809ptr,#m6809Regs
	ldmia r0,{m6809f-m6809pc,m6809sp}	;@ Restore M6809 state
;@----------------------------------------------------------------------------
konamiStepLoop:
;@----------------------------------------------------------------------------
	mov r0,#CYCLE_PSL
	bl m6809RunXCycles
	ldr koptr,=yieAr_0
	bl yiearDoScanline
	cmp r0,#0
	bne konamiStepLoop
;@----------------------------------------------------------------------------
	add r0,m6809ptr,#m6809Regs
	stmia r0,{m6809f-m6809pc,m6809sp}	;@ Save M6809 state

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldmfd sp!,{r4-r11,lr}
	bx lr

;@----------------------------------------------------------------------------
bloHack:		;@ BLO -7 (0x25 0xF9), speed hack.
;@----------------------------------------------------------------------------
	ldrsb r0,[m6809pc],#1
	tst m6809f,#PSR_C
	beq skipBlo
	add m6809pc,m6809pc,r0
	cmp r0,#-7
	andeq cycles,cycles,#CYC_MASK
skipBlo:
	fetch 3
;@----------------------------------------------------------------------------
cpuInit:			;@ Called by machineInit
;@----------------------------------------------------------------------------
	ldr r0,=m6809CPU0
	b m6809Init
;@----------------------------------------------------------------------------
cpuReset:		;@ Called by loadCart/resetGame
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

;@---Speed - 1.536MHz / 60Hz			;Yie Ar.
	ldr r0,=CYCLE_PSL
	str r0,cyclesPerScanline

;@--------------------------------------
	ldr m6809ptr,=m6809CPU0

	adr r4,cpuMapData
	bl map6809Memory

	mov r0,m6809ptr
	bl m6809Reset

	mov r0,m6809ptr
	mov r1,#0x25
	adr r2,bloHack
	bl m6809PatchOpcode

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
cpuMapData:
;@	.byte 0x07,0x06,0x05,0x04,0xFD,0xF8,0xFE,0xFF			;@ Double Dribble CPU0
;@	.byte 0x0B,0x0A,0x09,0x08,0xFB,0xFB,0xF9,0xF8			;@ Double Dribble CPU1
;@	.byte 0x0F,0x0E,0x0D,0x0C,0xFB,0xFB,0xFB,0xFA			;@ Double Dribble CPU2
;@	.byte 0x09,0x08,0x03,0x02,0x01,0x00,0xFE,0xFF			;@ Jackal CPU0
;@	.byte 0x0D,0x0C,0x0B,0x0A,0xF8,0xFD,0xFA,0xFB			;@ Jackal CPU1
;@	.byte 0x05,0x04,0x03,0x02,0x01,0x00,0xFE,0xFF			;@ Iron Horse
;@	.byte 0x05,0x04,0x03,0x02,0x01,0x00,0xFE,0xFF			;@ Finalizer
;@	.byte 0x03,0x02,0x01,0x00,0xF9,0xF9,0xFF,0xFE			;@ Jail Break
;@	.byte 0xFF,0xFE,0x05,0x04,0x03,0x02,0x01,0x00			;@ Green Beret
	.byte 0x03,0x02,0x01,0x00,0x88,0xFF,0x88,0xFE			;@ Yie Ar
;@----------------------------------------------------------------------------
map6809Memory:
	stmfd sp!,{lr}
	mov r5,#0x80
m6809DataLoop:
	mov r0,r5
	ldrb r1,[r4],#1
	bl m6809Mapper
	movs r5,r5,lsr#1
	bne m6809DataLoop
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
#ifdef NDS
	.section .dtcm, "ax", %progbits		;@ For the NDS
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#endif
	.align 2
;@----------------------------------------------------------------------------
m6809CPU0:
	.space m6809Size
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
