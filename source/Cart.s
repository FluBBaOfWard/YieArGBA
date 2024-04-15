#ifdef __arm__

#include "Shared/gba_asm.h"
#include "Shared/EmuSettings.h"
#include "ARM6809/ARM6809mac.h"
#include "YieArVideo/YieArVideo.i"

	.global emuFlags
	.global romNum
	.global cartFlags
//	.global romStart
	.global vromBase0
	.global vromBase1
	.global promBase
	.global ROM_Space
	.global testState

	.global machineInit
	.global loadCart
	.global m6809Mapper


	.syntax unified
	.arm

	.section .rodata
	.align 2

rawRom:
ROM_Space:

// Code
	.incbin "yiear/407_i08.10d"
	.incbin "yiear/407_i07.8d"
// Gfx1
	.incbin "yiear/407_c01.6h"
	.incbin "yiear/407_c02.7h"
// Gfx2
	.incbin "yiear/407_d05.16h"
	.incbin "yiear/407_d06.17h"
	.incbin "yiear/407_d03.14h"
	.incbin "yiear/407_d04.15h"
// Prom
	.incbin "yiear/407c10.1g"
// VLM data
	.incbin "yiear/407_c09.8b"

/*
// Code
	.incbin "yiear/407_g08.10d"
	.incbin "yiear/407_g07.8d"
// Gfx1
	.incbin "yiear/407_c01.6h"
	.incbin "yiear/407_c02.7h"
// Gfx2
	.incbin "yiear/407_d05.16h"
	.incbin "yiear/407_d06.17h"
	.incbin "yiear/407_d03.14h"
	.incbin "yiear/407_d04.15h"
// Prom
	.incbin "yiear/407c10.1g"
// VLM data
	.incbin "yiear/407_c09.8b"
*/
	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
machineInit: 	;@ Called from C
	.type   machineInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#0x0014				;@ 3/1 wait state
	ldr r1,=REG_WAITCNT
	strh r0,[r1]

	bl gfxInit
//	bl ioInit
	bl soundInit
	bl cpuInit

	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
loadCart: 		;@ Called from C:  r0=rom number, r1=emuflags
	.type   loadCart STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	str r0,romNum
	str r1,emuFlags

	ldr r3,=rawRom
//	ldr r3,=ROM_Space
								;@ r3=rombase til end of loadcart so DON'T FUCK IT UP
	str r3,romStart				;@ Set rom base
	add r0,r3,#0x8000			;@ 0x8000
	str r0,vromBase0			;@ Background
	add r0,r0,#0x4000
	str r0,vromBase1			;@ Sprites
	add r0,r0,#0x10000
	str r0,promBase				;@ Colour prom
	add r0,r0,#0x20
	str r0,vlmBase				;@ VLM speech data

	bl doCpuMappingYieAr

	bl gfxReset
	bl ioReset
	bl soundReset
	bl cpuReset

	ldmfd sp!,{r4-r11,lr}
	bx lr


;@----------------------------------------------------------------------------
doCpuMappingYieAr:
;@----------------------------------------------------------------------------
	adr r2,yieArMapping
	b do6809MainCpuMapping
;@----------------------------------------------------------------------------
yieArMapping:						;@ Yie Ar Kung-Fu
	.long emptySpace, VLM_R, empty_W							;@ IO
	.long emptySpace, empty_R, empty_W							;@ Empty
	.long emuRAM-0x1000, YieArIO_R, YieArIO_W					;@ Graphic
	.long emptySpace, empty_R, empty_W							;@ Empty
	.long 0, mem6809R4, rom_W									;@ ROM
	.long 1, mem6809R5, rom_W									;@ ROM
	.long 2, mem6809R6, rom_W									;@ ROM
	.long 3, mem6809R7, rom_W									;@ ROM
;@----------------------------------------------------------------------------
do6809MainCpuMapping:
;@----------------------------------------------------------------------------
	ldr r0,=m6809CPU0
	ldr r1,=mainCpu
	ldr r1,[r1]
;@----------------------------------------------------------------------------
m6809Mapper:		;@ Rom paging.. r0=cpuptr, r1=romBase, r2=mapping table.
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}

	add r7,r0,#m6809MemTbl
	add r8,r0,#m6809ReadTbl
	add lr,r0,#m6809WriteTbl

	mov r6,#8
m6809M2Loop:
	ldmia r2!,{r3-r5}
	cmp r3,#0x100
	addmi r3,r1,r3,lsl#13
	rsb r0,r6,#8
	sub r3,r3,r0,lsl#13

	str r3,[r7],#4
	str r4,[r8],#4
	str r5,[lr],#4
	subs r6,r6,#1
	bne m6809M2Loop
;@------------------------------------------
m6809Flush:		;@ Update cpu_pc & lastbank
;@------------------------------------------
	reEncodePC
	ldmfd sp!,{r4-r8,lr}
	bx lr


;@----------------------------------------------------------------------------

romNum:
	.long 0						;@ RomNumber
romInfo:						;@ Keep emuflags/BGmirror together for savestate/loadstate
emuFlags:
	.byte 0						;@ EmuFlags      (label this so UI.C can take a peek) see EmuSettings.h for bitfields
	.byte SCALED				;@ (display type)
	.byte 0,0					;@ (sprite follow val)
cartFlags:
	.byte 0 					;@ CartFlags
	.space 3

romStart:
mainCpu:
	.long 0
vromBase0:
	.long 0
vromBase1:
	.long 0
promBase:
	.long 0
vlmBase:
	.long 0

	.section .sbss
WRMEMTBL_:
	.space 256*4
RDMEMTBL_:
	.space 256*4
MEMMAPTBL_:
	.space 256*4
testState:
	.space 0x1004+0x34+0x28
emptySpace:
	.space 0x2000

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
