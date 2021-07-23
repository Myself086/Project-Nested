
Gfx_PaletteTable:
	.data16	0x318c, 0x34a0, 0x3c62, 0x3c47, 0x302c, 0x182e, 0x002e, 0x006b, 0x00a6, 0x00c1, 0x00e0, 0x08e0, 0x20e0, 0x0000, 0x0000, 0x0000, 0x56b5, 0x5981, 0x6948, 0x650f, 0x54d4, 0x38d8, 0x18f7, 0x0133, 0x016d, 0x01a6, 0x01c0, 0x1de0, 0x3dc0, 0x0000, 0x0000, 0x0000, 0x7fff, 0x7ecb, 0x7e91, 0x7e59, 0x7e1e, 0x621f, 0x3e3f, 0x267d, 0x16b7, 0x16f0, 0x2b0a, 0x4727, 0x6707, 0x2529, 0x0000, 0x0000, 0x7fff, 0x7f77, 0x7f7a, 0x7f5d, 0x7f3f, 0x733f, 0x673f, 0x5b5f, 0x577c, 0x5799, 0x5fb7, 0x6bb5, 0x7795, 0x5ad6, 0x0000, 0x0000
	.data16	0x318c, 0x34a0, 0x3c62, 0x3c47, 0x302c, 0x182e, 0x002e, 0x006b, 0x00a6, 0x00c1, 0x00e0, 0x08e0, 0x20e0, 0x0000, 0x0000, 0x0000, 0x56b5, 0x5981, 0x6948, 0x650f, 0x54d4, 0x38d8, 0x18f7, 0x0133, 0x016d, 0x01a6, 0x01c0, 0x1de0, 0x3dc0, 0x0000, 0x0000, 0x0000, 0x7fff, 0x7ecb, 0x7e91, 0x7e59, 0x7e1e, 0x621f, 0x3e3f, 0x267d, 0x16b7, 0x16f0, 0x2b0a, 0x4727, 0x6707, 0x2529, 0x0000, 0x0000, 0x7fff, 0x7f77, 0x7f7a, 0x7f5d, 0x7f3f, 0x733f, 0x673f, 0x5b5f, 0x577c, 0x5799, 0x5fb7, 0x6bb5, 0x7795, 0x5ad6, 0x0000, 0x0000

Gfx_PaletteOffset:
	.macro	Gfx_PaletteOffset_mac
		// Background palettes
		.data8	0x00, 0x41, 0x44, 0x45
		.data8	0x50, 0x51, 0x54, 0x55
		.data8	0x60, 0x61, 0x64, 0x65
		.data8	0x70, 0x71, 0x74, 0x75
		// Sprite palettes
		.data8	0x00, 0x81, 0x84, 0x85
		.data8	0x50, 0x91, 0x94, 0x95
		.data8	0x60, 0xa1, 0xa4, 0xa5
		.data8	0x70, 0xb1, 0xb4, 0xb5
	.endm
	Gfx_PaletteOffset_mac
	Gfx_PaletteOffset_mac
	Gfx_PaletteOffset_mac
	Gfx_PaletteOffset_mac
	Gfx_PaletteOffset_mac
	Gfx_PaletteOffset_mac
	Gfx_PaletteOffset_mac
	Gfx_PaletteOffset_mac

	// Palette layout
	//	00 !! !! !! -- !! !! !!  -- !! !! !! -- !! !! !! <- First palette for BGs
	//	-- !! !! !! -- !! !! !!  -- !! !! !! -- !! !! !!
	//	-- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --
	//	-- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --
	//	-- 01 21 41 02 03 -- 42  22 -- 23 -- -- -- -- 43
	//	-- 05 25 45 06 07 -- 46  26 -- 27 -- -- -- -- 47
	//	-- 09 29 49 0a 0b -- 4a  2a -- 2b -- -- -- -- 4b
	//	-- 0d 2d 4d 0e 0f -- 4e  2e -- 2f -- -- -- -- 4f
	//	-- 11 31 51 12 13 -- 52  32 -- 33 -- -- -- -- 53 <- First palette for sprites
	//	-- 15 35 55 16 17 -- 56  36 -- 37 -- -- -- -- 57
	//	-- 19 39 59 1a 1b -- 5a  3a -- 3b -- -- -- -- 5b
	//	-- 1d 3d 5d 1e 1f -- 5e  3e -- 3f -- -- -- -- 5f
	//	-- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --
	//	-- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --
	//	-- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --
	//	-- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --
	// Ranges:
	//  00-0f = background colors, first region
	//  10-1f = sprite colors, first region
	//  20-2f = background colors, second region (concept only)
	//  30-3f = sprite colors, second region (concept only)
	//  40-4f = background colors, third region (concept only)
	//  50-5f = sprite colors, third region (concept only)
	//  !!    = debug background colors (concept only)

	// ---------------------------------------------------------------------------
	
	.mx	0x00
	.func	Gfx__Restart
Gfx__Restart:
	rep	#0x30
	.mx	0x00

	call	Chr__LoadInitialBank
	call	Hdma__LoadBuffers
	call	Hdma__InitChannels

	// Record sprite size as being 8x16, forcing reset on assumption if sprites were to be 8x8
	sep	#0x30
	.mx	0x30
	lda	#0xf0
	sta	$_IO_4014_SpriteSize
	rep	#0x30
	.mx	0x00

	return

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Gfx__LoadNameTableRemaps
Gfx__LoadNameTableRemaps:
	// Queue a nametable mirror change
	php

	smx	#0x30
	lda	$=RomInfo_ScreenMode
	jsr	$=Gfx__NameTableMirrorChange_in

	plp
	return

	// ---------------------------------------------------------------------------

	.mx	0x30
	// Entry: A = Nametable mirror (1x1, 2x1, 1x2, 2x2, 1x1+)
	// Return: Y = Unused
Gfx__NameTableMirrorChange:
	// Was a change made to the BG mirror?
	cmp	$_NameTable_ActiveMap
	bne	$+Gfx__NameTableMirrorChange_in
		rtl
Gfx__NameTableMirrorChange_in:

	tax

	// Load SNES BG mirror
	lda	$=Gfx__NameTableMirrorChange_BGmirror,x
	sta	$_IO_BG_MIRRORS

	// Load data table offset
	lda	$=Gfx__NameTableMirrorChange_Indexer,x
	tax

	// Queue nametable change
	lock
	lda	#.VramQ_NameTableMirrorChange
	sta	$0x2180
	stx	$0x2180

	rmx	#0x15

	.macro	Gfx__NameTableMirrorChange_mac		offset
		sta	$_NameTable_Remap_Main+0x0+{0}
		adc	#0x0202
		sta	$_NameTable_Remap_Main+0x2+{0}
	.endm

	lda	$=Gfx__NameTableMirrorChange_Data+0,x
	Gfx__NameTableMirrorChange_mac		0x0
	lda	$=Gfx__NameTableMirrorChange_Data+2,x
	Gfx__NameTableMirrorChange_mac		0x4
	lda	$=Gfx__NameTableMirrorChange_Data+4,x
	Gfx__NameTableMirrorChange_mac		0x8
	lda	$=Gfx__NameTableMirrorChange_Data+6,x
	Gfx__NameTableMirrorChange_mac		0xc

	sep	#0x20

	rtl

Gfx__NameTableMirrorChange_Indexer:
	.data8	0, 8, 16, 24, 32

Gfx__NameTableMirrorChange_BGmirror:
	.data8	0x20, 0x21, 0x22, 0x23, 0x30

Gfx__NameTableMirrorChange_Data:
	.data16	0x2120, 0x2120, 0x2120, 0x2120	// 1x1
	.data16	0x2120, 0x2524, 0x2120, 0x2524	// 2x1
	.data16	0x2120, 0x2120, 0x2524, 0x2524	// 1x2
	.data16	0x2120, 0x2524, 0x2928, 0x2d2c	// 2x2
	.data16	0x2524, 0x2524, 0x2524, 0x2524	// 1x1 second screen

	// ---------------------------------------------------------------------------

	// Note: IRQ writes 6 bytes to stack

Start__Irq_Out:
		// Acknowledge IRQ and return
		bit	$0x4211

		plb
		rti

	.mx	0x00
	.func	Start__Irq_Fast
Start__Irq_Fast:
	.vstack	_IRQ_VSTACK_START
	.local	_a, _s

	// Change bank
	phb
	phk
	plb

	// Change mode, clear decimal and carry
	rep	#0x39

	// Is interrupt already in process?
	bit	$_IRQ_InterruptInProcess
	bmi	$-Start__Irq_Out

	// Push A and S to Vstack
	sta	$_a
	tsc
	sta	$_s
	lda	#_HDMA_SideBufferReady&0xff00		// Change both DP and SP to the same page
	tcs
	// Push the rest of the registers to interrupt stack
	phx
	phy
	phd
	tcd

	// Change mode
	.mx	0x10
	sep	#0x10

	// Are we in Vblank? Also acknowledge IRQ at the same time
	lda	$0x4211
	bpl	$+b_1
		// Swap HDMA buffers if ready
		ldx	$.HDMA_SideBufferReady+1
		beq	$+b_2
			stz	$.HDMA_SideBufferReady
			.macro	Gfx__HdmaSwap_Mac	VarName, DmaChannel
				ldx	$.{0}_Front+1
				ldy	$.{0}_Side+1
				stx	$.{0}_Side+1
				sty	$.{0}_Front+1
				sty	$_Zero+0x4303+{1}*0x10
			.endm
			Gfx__HdmaSwap_Mac	HDMA_Scroll, 6
			Gfx__HdmaSwap_Mac	HDMA_CHR, 5
			Gfx__HdmaSwap_Mac	HDMA_SpriteCHR, 4
			Gfx__HdmaSwap_Mac	HDMA_LayersEnabled, 3
b_2:
		ldx	$.Sound_Ready
		beq	$+b_1
			// Always swap sound buffers
			Gfx__HdmaSwap_Mac	HDMA_Sound, 1
			stz	$.Sound_Ready
b_1:

	// Has VramQ overflown? Keep result in carry for Gfx__VramQueue
	lda	[$.Vram_Queue_Top_2]
	cmp	#1

	// Change DP to page 21 for faster IO access
	lda	#0x2100
	tcd

	// Black screen until transfer is done (TODO: Test recycling the value read from $0x4211)
	//cpx	#0x80
	//trapcc
	ldx	#0x80
	stx	$0x00

	// Interrupt in process
	stx	$_IRQ_InterruptInProcess+1

	// Clip 8 pixels on the left of the screen if set
	ldy	$_IO_2001
	ldx	$_Gfx__WindowClip_LUT,y
	stx	$0x2e

	// Screen size (TODO: Only write this once OR move this to VramQ to support mappers with dynamic nametable mirrors)
	ldx	$_IO_BG_MIRRORS
	stx	$0x07

	// Do VRAM updates, assume carry clear from CMP way above
	Gfx__VramQueue

	// Show screen
	ldx	#0x0f
	stx	$0x00

	// Change mode
	.mx	0x00
	rep	#0x30

	// Change DP
	lda	#_IRQ_VSTACK_PAGE
	tcd

	// Do debug updates
	dec	$.Debug_WaitState
	bpl	$+b_1

		// Fake call for adjusting vstack
		FakeCall	Gui__FrameUpdate
		FakeCall	Gui__BlueScreen

		// Do debug update
		jsr	$=Gfx__IndirectCallGuiUpdate
b_1:

	// Test main thread
	dec	$.BlueScreen_WaitState
	bpl	$+b_1
		Int__TestMainThread
b_1:

	// Do debug render
	Gui__Render

	// Increment NMI count, up to 3
	lda	$.Nmi_Count
	cmp	#_Nmi_Count_TOP
	bcs	$+b_else
		inc	a
		sta	$.Nmi_Count
		cmp	#_Nmi_Count_TOP
		bcc	$+b_1
b_else:
		// Is Vblank loop busy?
		ldx	$.Vblank_Busy
		bne	$+b_1
		// Are we emulating Nes NMI now?
		lda	$=RomInfo_NmiMode
		and	#_RomInfo_NmiMode_AtSnesNmi
		bne	$+Start__Irq_NesNmi
b_1:

Start__Irq_Return:
	// Interrupt no longer in process
	stz	$.IRQ_InterruptInProcess

	// Restore stack pointer (top half)
	lda	$.s

	// Pull from interrupt stack
	pld
	ply
	plx

	// Restore stack pointer and A
	//lda	$_s
	tcs
	lda	$_a

	plb
	rti

	.macro	Start__Irq_Return
		// Pull from interrupt stack
		pld
		ply
		plx

		// Restore stack pointer and A
		lda	$_s
		tcs
		lda	$_a

		// Interrupt no longer in process
		stz	$_IRQ_InterruptInProcess

		plb
		rti
	.endm


Start__Irq_NesNmi:
	.local	_stack
	.local	.keepNesBank
	.local	_keepIOTemp16
	.local	.keepIOTemp
	.local	_keepJMPiU

	// Is NMI enabled?
	bit	$_IO_2000-1
	bpl	$-Start__Irq_Return

	// Use main thread's DP if not in use, otherwise skip this frame
	lda	$1,s
	bne	$-Start__Irq_Return
	lda	#_VSTACK_PAGE
	tcd

	// Keep some necessary variables
	sep	#0x30
	.mx	0x30
	lda	$_Memory_NesBank
	sta	$_keepNesBank
	stz	$_Memory_NesBank
	lda	$_IO_Temp
	sta	$_keepIOTemp
	rep	#0x30
	.mx	0x00
	lda	$_IO_Temp16
	sta	$_keepIOTemp16
	lda	$_JMPiU_Action
	sta	$_keepJMPiU

	// Next frame
	call	Interpret__Wait4Vblank

	// Get NMI address
	lda	$_Program_Bank_3+2
	cmp	$_NMI_NesBank
	beq	$+b_1
		sta	$_NMI_NesBank
		sep	#0x30
		.mx	0x30
		phb
		pha
		plb
		rep	#0x30
		.mx	0x00
		.precall	Recompiler__CallFunction		_originalFunction
		lda	$0xfffa
		sta	$.Param_originalFunction
		call
		plb

		// Write destination address
		lda	[$.Recompiler_FunctionList+3],y
		sta	$_NMI_SnesPointer
		iny
		lda	[$.Recompiler_FunctionList+3],y
		sta	$_NMI_SnesPointer+1
b_1:

	// Fix registers and call
	tsc
	sta	$_stack
	lda	#0
	tcd
	lda	$_s
	tcs
	sep	#0x30
	// Push fake return (Final Fantasy 1 fix)
	phk
	pea	$_Start__Irq_NesNmi_FakeReturn-1
	// Push return
	phk
	pea	$_Start__Irq_NesNmi_Return-1
	php
	jmp	[$_NMI_SnesPointer]

	.mx	0x30
Start__Irq_NesNmi_Return:
	// Fix DB
	phk
	plb

	// Restore necessary variables
	lda	$_keepNesBank
	sta	$_Memory_NesBank
	lda	$_keepIOTemp
	sta	$_IO_Temp
	.mx	0x00
	rep	#0x30
	lda	$_keepIOTemp16
	sta	$_IO_Temp16
	lda	$_keepJMPiU
	sta	$_JMPiU_Action

	// Fix stack and go to proper return
	lda	$_stack
	tcs
	Start__Irq_Return

	.mx	0x30
Start__Irq_NesNmi_FakeReturn:
	// Fix DB
	phk
	plb

	// Restore necessary variables
	lda	$_keepNesBank
	sta	$_Memory_NesBank
	lda	$_keepIOTemp
	sta	$_IO_Temp
	.mx	0x00
	rep	#0x30
	lda	$_keepIOTemp16
	sta	$_IO_Temp16
	lda	$_keepJMPiU
	sta	$_JMPiU_Action

	// Fix stack
	lda	$_stack
	tcs

	// Interrupt no longer in process
	stz	$_IRQ_InterruptInProcess

	// Pull from interrupt stack
	pld
	ply
	plx

	// Restore stack and bank
	lda	$_s
	tcs
	plb

	// Skip original return
	lda	$0,s
	sta	$3,s
	tsc
	clc
	adc	#3
	tcs

	// Restore A
	lda	$=a

	plp
	rtl

	// ------------------------------------------------------------------------

Gfx__IndirectCallGuiUpdate:
	jmp	[$_Debug_CodePointer]

	// ---------------------------------------------------------------------------

	.macro	Int__TestMainThread
		lda	#59
		sta	$.BlueScreen_WaitState

		// Test VramQ overflow
		lda	[$.Vram_Queue_Top]
		bne	$+b_in2__

		// Expected main stack:
		//     0,  1, 2, 3-5
		// empty, db, p, pc

		// Get main thread's P and PC
		ldy	$.s
		lda	$0x0002,y
		sta	$.BlueScreen_P
		lda	$0x0004,y
		sta	$.BlueScreen_PC+1

		// Has main thread hit a trap?
		lda	[$.BlueScreen_PC]
		and	#0xff0f
		cmp	#0xfe00
		bne	$+out__

		// Test condition, if valid opcode
		eor	[$.BlueScreen_PC]
		lsr	a
		lsr	a
		lsr	a
		tax
		lda	$.BlueScreen_P
		and	#0x00ff
		bit	$_Int__TestMainThread_BranchType,x
		bvs	$+out__
		bpl	$+b_1__
			eor	#0x00ff
b_1__:
		and	$_Int__TestMainThread_BranchType,x
		bne	$+out__
b_in__:
			// Expected IRQ stack:
			//     0, 1-2, 3-4, 5-6
			// empty,  dp,   y,   x

			// Copy the remaining registers
			ldx	$0x0001,y
			stx	$.BlueScreen_DB
			lda	$1,s
			sta	$.BlueScreen_DP
			lda	$3,s
			sta	$.BlueScreen_Y
			lda	$5,s
			sta	$.BlueScreen_X
			lda	$.a
			sta	$.BlueScreen_A
			lda	$.s
			sta	$.BlueScreen_S

			// Activate blue screen
			lda	#_Gui__BlueScreen
			sta	$.Debug_CodePointer
			stz	$.Debug_WaitState

			bra	$+out__
b_in2__:
			jmp	$_Int__TestMainThread_outlined
out__:
	.endm


Int__TestMainThread_outlined:
	// Trap here
	lda	#0x0000
	sta	[$.Vram_Queue_Top]
	stz	$.BlueScreen_WaitState
	stz	$.IRQ_InterruptInProcess
	ldx	$.s
	txs
	lda	$=RomInfo_VramQBufferSize
	unlock
	trap
	Exception	"VramQ Overflow{}{}{}The amount of data in VramQ overflowed and potentially damaged other data.{}{}Raise the buffer size for VramQ, it is currently 0x{A:X}. Raising it too much may cause this program to run out of memory."


Int__TestMainThread_BranchType:
	// bit 15 = true/false condition
	// bit 14 = invalid
	// bit 7 = negative
	// bit 6 = overflow
	// bit 1 = zero
	// bit 0 = carry
	.data16	0x4000, 0x0080
	.data16	0x4000, 0x8080
	.data16	0x4000, 0x0040
	.data16	0x4000, 0x8040
	.data16	0x0000, 0x0001
	.data16	0x4000, 0x8001
	.data16	0x4000, 0x0002
	.data16	0x4000, 0x8002

	// ------------------------------------------------------------------------

	// End()
	.def	VramQ_End					0x00
	// Init()
	.def	VramQ_Init					0x02
	// Tile(u8 value)
	.def	VramQ_Tile					0x04
	// TileAttribute(u8 value)
	.def	VramQ_TileAttribute			0x06
	// Palette(u8 palette)
	.def	VramQ_Palette				0x08
	// SpriteXfer8x8(u8 priority)
	.def	VramQ_SpriteXfer8x8			0x0a
	// SpriteXfer8x16(u8 priority)
	.def	VramQ_SpriteXfer8x16		0x0c
	// SpriteEmpty()
	.def	VramQ_SpriteXferEmpty		0x0e
	// PpuAddr(u16)
	.def	VramQ_PpuAddr				0x10
	// PpuAddrLow(u8)
	.def	VramQ_PpuAddrLow			0x12
	// PpuAddrHigh(u8)
	.def	VramQ_PpuAddrHigh			0x14
	// PpuAddrInc(u8)
	.def	VramQ_PpuAddrInc			0x16
	// Read()
	.def	VramQ_Read					0x18
	// ScrollY(u8)
	.def	VramQ_ScrollY				0x1a
	// ScrollX(u8)
	.def	VramQ_ScrollX				0x1c
	// ChrBank(u8 highBitsVramAddr, u16 highBitsSourceAddr, u8 highBitsLength)
	.def	VramQ_ChrBank				0x1e
	// Tiles(u8[u8 length] tileData)
	.def	VramQ_Tiles					0x20
	// TilesAtAddress(u16 vramAddress, u8[u8 length] tileData)
	.def	VramQ_TilesAtAddress		0x22
	// NameTableMirrorChange(u8 value)
	.def	VramQ_NameTableMirrorChange	0x24
	// DebugRow0()
	.def	VramQ_DebugRow0				0x26
	// DebugRow1()
	.def	VramQ_DebugRow1				0x28
	// DebugRow2()
	.def	VramQ_DebugRow2				0x2a
	// DebugRow3()
	.def	VramQ_DebugRow3				0x2c
	// DebugRow4()
	.def	VramQ_DebugRow4				0x2e
	// DebugRow6()
	.def	VramQ_DebugRow5				0x30
	// DebugRow6()
	.def	VramQ_DebugRow6				0x32
	// DebugRow7()
	.def	VramQ_DebugRow7				0x34
	// DebugRow8()
	.def	VramQ_DebugRow8				0x36
	// DebugRow9()
	.def	VramQ_DebugRow9				0x38
	// DebugRow10()
	.def	VramQ_DebugRow10			0x3a
	// DebugRow11()
	.def	VramQ_DebugRow11			0x3c
	// DebugRow12()
	.def	VramQ_DebugRow12			0x3e
	// DebugRow13()
	.def	VramQ_DebugRow13			0x40
	// DebugRow14()
	.def	VramQ_DebugRow14			0x42
	// DebugRow15()
	.def	VramQ_DebugRow15			0x44

	.mx	0x10
	.macro	Gfx__VramQueue
		// Entry: Carry set if the queue overflown

		// Has VramQ overflown?
		bcs	$+Gfx__VramQueue_VramQ_SkipError

		// Write ending and reset queue reading position
		stz	$0x80
		ldy	#.Vram_Queue/0x100
		sty	$0x82

		// PPU increment mode on first byte
		ldx	#0
		stx	$0x15

		// Clear carry and load PpuAddr
		//clc
		lda	$_Vram_Queue_PpuAddr

		// Read next instruction
		ldx	$0x80
		jmp	($_Gfx__VramQueue_Switch,x)
		FakeCall	Gfx__VramQueue

Gfx__VramQueue_VramQ_End:
		// Return
		sta	$_Vram_Queue_PpuAddr
Gfx__VramQueue_VramQ_SkipError:

		// Reset Wram direct access for queuing vblank actions
		lda	#_Vram_Queue
		sta	$0x81
	.endm

Gfx__VramQueue_Switch:
	.data16	_Gfx__VramQueue_VramQ_End
	.data16	_Gfx__VramQueue_VramQ_Init
	.data16	_Gfx__VramQueue_VramQ_Tile
	.data16	_Gfx__VramQueue_VramQ_TileAttribute
	.data16	_Gfx__VramQueue_VramQ_Palette
	.data16	_Gfx__VramQueue_VramQ_SpriteXfer8x8
	.data16	_Gfx__VramQueue_VramQ_SpriteXfer8x16
	.data16	_Gfx__VramQueue_VramQ_SpriteXferEmpty
	.data16	_Gfx__VramQueue_VramQ_PpuAddr
	.data16	_Gfx__VramQueue_VramQ_PpuAddrLow
	.data16	_Gfx__VramQueue_VramQ_PpuAddrHigh
	.data16	_Gfx__VramQueue_VramQ_PpuAddrInc
	.data16	_Gfx__VramQueue_VramQ_Read
	.data16	_Gfx__VramQueue_VramQ_ScrollY
	.data16	_Gfx__VramQueue_VramQ_ScrollX
	.data16	_Gfx__VramQueue_VramQ_ChrBank
	.data16	_Gfx__VramQueue_VramQ_Tiles
	.data16	_Gfx__VramQueue_VramQ_TilesAtAddress
	.data16	_Gfx__VramQueue_VramQ_NameTableMirrorChange
	.data16	_Gfx__VramQueue_VramQ_DebugRow0
	.data16	_Gfx__VramQueue_VramQ_DebugRow1
	.data16	_Gfx__VramQueue_VramQ_DebugRow2
	.data16	_Gfx__VramQueue_VramQ_DebugRow3
	.data16	_Gfx__VramQueue_VramQ_DebugRow4
	.data16	_Gfx__VramQueue_VramQ_DebugRow5
	.data16	_Gfx__VramQueue_VramQ_DebugRow6
	.data16	_Gfx__VramQueue_VramQ_DebugRow7
	.data16	_Gfx__VramQueue_VramQ_DebugRow8
	.data16	_Gfx__VramQueue_VramQ_DebugRow9
	.data16	_Gfx__VramQueue_VramQ_DebugRow10
	.data16	_Gfx__VramQueue_VramQ_DebugRow11
	.data16	_Gfx__VramQueue_VramQ_DebugRow12
	.data16	_Gfx__VramQueue_VramQ_DebugRow13
	.data16	_Gfx__VramQueue_VramQ_DebugRow14
	.data16	_Gfx__VramQueue_VramQ_DebugRow15


Gfx__VramQueue_VramQ_Init:
	.macro	Gfx__VramQueue_VramQ_Init_Mac	VarName, DmaChannel
		//lda	$_{0}_Front
		sta	$_Zero+0x4302+{1}*0x10
	.endm
	pha
	lda	#_Addition
	Gfx__VramQueue_VramQ_Init_Mac	HDMA_Scroll, 6
	Gfx__VramQueue_VramQ_Init_Mac	HDMA_CHR, 5
	Gfx__VramQueue_VramQ_Init_Mac	HDMA_SpriteCHR, 4
	Gfx__VramQueue_VramQ_Init_Mac	HDMA_LayersEnabled, 3
	Gfx__VramQueue_VramQ_Init_Mac	HDMA_Sound, 1
	pla

	// Activate HDMA (01111010b)
	ldy	#0x7a
	sty	$0x420c

	// Next
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


Gfx__VramQueue_VramQ_Tile:
	// Write tile
	//sta	$_Vram_Queue_PpuAddr
	//and	#0xefff
	sta	$0x16
	ldx	$0x80
	stx	$0x18
	//lda	$_Vram_Queue_PpuAddr

	// Next
	adc	$_Vram_Queue_PpuAddrInc
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


Gfx__VramQueue_VramQ_TileAttribute:
	// Keep current PPU address (temporarily write to DMA, 0.33 cycles faster than PHA+PLA)
	sta	$0x4302

	// Translate address for PPU (TODO: Remove AND at some point)
	tay
	ldx	$_Gfx__MultiplyBy2,y
	and	#0xff00
	eor	$_Gfx__TileAttributeAddrLUT,x
	ldy	$0x80

	// From here: A = SNES PPU address, X = free, Y = value
	
	// Change PPU increment mode on second byte
	ldx	#0x80
	stx	$0x15

	// Do first row: 0 0 1 1
	sta	$0x16
	ldx	$_Gfx__TileAttributeSplit0LUT,y
	stx	$0x19
	stx	$0x19
	ldx	$_Gfx__TileAttributeSplit1LUT,y
	stx	$0x19
	stx	$0x19
	
	// Do second row: 0 0 1 1
	adc	#0x0020
	sta	$0x16
	ldx	$_Gfx__TileAttributeSplit0LUT,y
	stx	$0x19
	stx	$0x19
	ldx	$_Gfx__TileAttributeSplit1LUT,y
	stx	$0x19
	stx	$0x19
	
	// Do third row: 2 2 3 3
	adc	#0x0020
	sta	$0x16
	ldx	$_Gfx__TileAttributeSplit2LUT,y
	stx	$0x19
	stx	$0x19
	ldx	$_Gfx__TileAttributeSplit3LUT,y
	stx	$0x19
	stx	$0x19
	
	// Do third row: 2 2 3 3
	adc	#0x0020
	sta	$0x16
	ldx	$_Gfx__TileAttributeSplit2LUT,y
	stx	$0x19
	stx	$0x19
	ldx	$_Gfx__TileAttributeSplit3LUT,y
	stx	$0x19
	stx	$0x19

	// Restore PPU increment mode
	ldx	#0x00
	stx	$0x15

	// Next
	lda	$0x4302
	adc	$_Vram_Queue_PpuAddrInc
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


Gfx__VramQueue_VramQ_Palette:
	// Translate offset
	tax
	ldy	$_Gfx_PaletteOffset,x
	sty	$0x21

	// Translate color from NES to SNES
	ldx	$0x80
	ldy	$_Gfx_PaletteTable+0,x
	sty	$0x22
	ldy	$_Gfx_PaletteTable+1,x
	sty	$0x22

	// Next
	adc	$_Vram_Queue_PpuAddrInc
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


Gfx__VramQueue_VramQ_SpriteXfer8x8:
	// Keep current PPU address
	pha

	// Reset sprite address
	stz	$0x02

	// Set DMA
	lda	#0x0400
	sta	$0x4300
	lda	#_Sprites_Buffer
	sta	$0x4302
	ldy	#0x7e
	sty	$0x4304
	lda	#0x0220
	sta	$0x4305
	ldy	#0x01
	sty	$0x420b

	// Set sprite priority
	ldy	$0x80
	sty	$0x02
	ldy	#0x80
	sty	$0x03

	// Next
	pla
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


Gfx__VramQueue_VramQ_SpriteXfer8x16:
	// Keep current PPU address
	pha

	// Reset sprite address
	stz	$0x02

	// Set DMA
	lda	#0x0400
	sta	$0x4300
	lda	#_Sprites_Buffer
	sta	$0x4302
	ldy	#0x7e
	sty	$0x4304
	lda	#0x0200
	sta	$0x4305
	ldy	#0x01
	sty	$0x420b

	// Extra bits based on the lookup table below
	ldy	$0x80
	lda	$_Gfx__VramQueue_ExtraBitsLUT,y
	sta	$0x4302
	ldx	#.Gfx__VramQueue_ExtraBitsLUT/0x10000
	stx	$0x4304
	lda	#0x0020
	sta	$0x4305
	ldx	#1
	stx	$0x420b

	// Set sprite priority
	sty	$0x02
	ldy	#0x80
	sty	$0x03

	// Next
	pla
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


	.macro	Gfx__VramQueue_ExtraBitsLUT_mac
		.data16	_Gfx__VramQueue_ExtraBitsData0-{0}
		.data16	_Gfx__VramQueue_ExtraBitsData1-{0}
		.data16	_Gfx__VramQueue_ExtraBitsData2-{0}
		.data16	_Gfx__VramQueue_ExtraBitsData3-{0}
	.endm

Gfx__VramQueue_ExtraBitsLUT:
	Gfx__VramQueue_ExtraBitsLUT_mac		0x00
	Gfx__VramQueue_ExtraBitsLUT_mac		0x01
	Gfx__VramQueue_ExtraBitsLUT_mac		0x02
	Gfx__VramQueue_ExtraBitsLUT_mac		0x03
	Gfx__VramQueue_ExtraBitsLUT_mac		0x04
	Gfx__VramQueue_ExtraBitsLUT_mac		0x05
	Gfx__VramQueue_ExtraBitsLUT_mac		0x06
	Gfx__VramQueue_ExtraBitsLUT_mac		0x07
	Gfx__VramQueue_ExtraBitsLUT_mac		0x08
	Gfx__VramQueue_ExtraBitsLUT_mac		0x09
	Gfx__VramQueue_ExtraBitsLUT_mac		0x0a
	Gfx__VramQueue_ExtraBitsLUT_mac		0x0b
	Gfx__VramQueue_ExtraBitsLUT_mac		0x0c
	Gfx__VramQueue_ExtraBitsLUT_mac		0x0d
	Gfx__VramQueue_ExtraBitsLUT_mac		0x0e
	Gfx__VramQueue_ExtraBitsLUT_mac		0x0f
	Gfx__VramQueue_ExtraBitsLUT_mac		0x10
	Gfx__VramQueue_ExtraBitsLUT_mac		0x11
	Gfx__VramQueue_ExtraBitsLUT_mac		0x12
	Gfx__VramQueue_ExtraBitsLUT_mac		0x13
	Gfx__VramQueue_ExtraBitsLUT_mac		0x14
	Gfx__VramQueue_ExtraBitsLUT_mac		0x15
	Gfx__VramQueue_ExtraBitsLUT_mac		0x16
	Gfx__VramQueue_ExtraBitsLUT_mac		0x17
	Gfx__VramQueue_ExtraBitsLUT_mac		0x18
	Gfx__VramQueue_ExtraBitsLUT_mac		0x19
	Gfx__VramQueue_ExtraBitsLUT_mac		0x1a
	Gfx__VramQueue_ExtraBitsLUT_mac		0x1b
	Gfx__VramQueue_ExtraBitsLUT_mac		0x1c
	Gfx__VramQueue_ExtraBitsLUT_mac		0x1d
	Gfx__VramQueue_ExtraBitsLUT_mac		0x1e
	Gfx__VramQueue_ExtraBitsLUT_mac		0x1f

	.fill	0x20, 0x55
	.data8	0x55, 0xff, 0xff, 0xff
Gfx__VramQueue_ExtraBitsData0:
	.data8	0x00
	.fill	0x1f, 0x00
	
	.fill	0x20, 0x55
	.data8	0x55, 0xfd, 0xff, 0xff
Gfx__VramQueue_ExtraBitsData1:
	.data8	0x03
	.fill	0x1f, 0x00

	.fill	0x20, 0x55
	.data8	0x55, 0xf5, 0xff, 0xff
Gfx__VramQueue_ExtraBitsData2:
	.data8	0x0f
	.fill	0x1f, 0x00

	.fill	0x20, 0x55
	.data8	0x55, 0xd5, 0xff, 0xff
Gfx__VramQueue_ExtraBitsData3:
	.data8	0x3f
	.fill	0x1f, 0x00


Gfx__VramQueue_VramQ_SpriteXferEmpty:
	// Keep current PPU address
	pha

	// Reset sprite address
	stz	$0x02

	// Set DMA
	lda	#0x0400
	sta	$0x4300
	lda	#_Gfx__VramQueue_VramQ_SpriteXferEmpty_value
	sta	$0x4302
	ldy	#.Gfx__VramQueue_VramQ_SpriteXferEmpty_value/0x10000
	sty	$0x4304
	lda	#0x0220
	sta	$0x4305
	ldy	#0x01
	sty	$0x420b

	// Next
	pla
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


Gfx__VramQueue_VramQ_SpriteXferEmpty_value:
	.fill	0x200, 0xf0
	.fill	0x20, 0x00


Gfx__VramQueue_VramQ_PpuAddr:
	ldx	$0x80
	stx	$_Vram_Queue_PpuAddr
	ldx	$0x80
	ldy	$_Gfx__VramQueue_VramQ_PpuAddrHigh_IsNameTableLUT,x
	bmi	$+Gfx__VramQueue_VramQ_PpuAddrHigh_NameTable
	stx	$_Vram_Queue_PpuAddr+1
	lda	$_Vram_Queue_PpuAddr

	// Next
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


Gfx__VramQueue_VramQ_PpuAddrLow:
	sta	$_Vram_Queue_PpuAddr
	ldx	$0x80
	stx	$_Vram_Queue_PpuAddr
	lda	$_Vram_Queue_PpuAddr

	// Next
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


Gfx__VramQueue_VramQ_PpuAddrHigh:
	sta	$_Vram_Queue_PpuAddr
	ldx	$0x80
	ldy	$_Gfx__VramQueue_VramQ_PpuAddrHigh_IsNameTableLUT,x
	bmi	$+Gfx__VramQueue_VramQ_PpuAddrHigh_NameTable
	stx	$_Vram_Queue_PpuAddr+1
	lda	$_Vram_Queue_PpuAddr

	// Next
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)

Gfx__VramQueue_VramQ_PpuAddrHigh_NameTable:
	ldy	$_NameTable_Remap_Irq-0x20,x
	sty	$_Vram_Queue_PpuAddr+1
	lda	$_Vram_Queue_PpuAddr

	// Next
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)

Gfx__VramQueue_VramQ_PpuAddrHigh_IsNameTableLUT:
	.fill	0x20, 0x00
	.fill	0x10, 0xff
	.fill	0xd0, 0x00


Gfx__VramQueue_VramQ_PpuAddrInc:
	ldx	$0x80
	stx	$_Vram_Queue_PpuAddrInc

	// Next
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


Gfx__VramQueue_VramQ_Read:
	// Increment pointer
	adc	$_Vram_Queue_PpuAddrInc

	// Next
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


Gfx__VramQueue_VramQ_ScrollX:
	ldx	$0x80
	stx	$_IO_SCROLL_X

	// Next
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


Gfx__VramQueue_VramQ_ScrollY:
	ldx	$0x80
	stx	$_IO_SCROLL_Y

	// Next
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


Gfx__VramQueue_VramQ_ChrBank:
	// ChrBank(u8 highBitsVramAddr, u16 highBitsSourceAddr, u8 highBitsLength)

	// Set VRAM address
	stz	$0x16
	ldx	$0x80
	stx	$0x17

	// Set the DMA
	stz	$0x4300
	ldx	#0x18
	stx	$0x4301
	stz	$0x4302
	ldx	$0x80
	stx	$0x4303
	ldx	$0x80
	stx	$0x4304
	stz	$0x4305
	ldx	$0x80
	stx	$0x4306
	ldx	#0x01
	stx	$0x420b

	// Next
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


Gfx__VramQueue_VramQ_Tiles:
	// Tiles(u8[u8 length] tileData)

	// Set VRAM address
	sta	$0x16

	// Transfer tiles (tile count range is 0-255)
	ldy	$0x80
	ldx	$_Gfx__VramQueue_VramQ_Tiles_AND0FSL1,y
b_trap:
	jmp	($_Gfx__VramQueue_VramQ_Tiles_Switch,x)


Gfx__VramQueue_VramQ_TilesAtAddress:
	// TilesAtAddress(u16 vramAddress, u8[u8 length] tileData)

	// Set VRAM address
	ldx	$0x80
	stx	$0x16
	ldx	$0x80
	stx	$0x17

	// Transfer tiles (tile count range is 0-255)
	ldy	$0x80
	ldx	$_Gfx__VramQueue_VramQ_Tiles_AND0FSL1,y
Gfx__VramQueue_VramQ_Tiles_Switch_Trap:
	jmp	($_Gfx__VramQueue_VramQ_Tiles_Switch,x)


Gfx__VramQueue_VramQ_NameTableMirrorChange:
	// Keep current PPU address (temporarily write to DMA, 0.33 cycles faster than PHA+PLA)
	sta	$0x4302

	.macro	Gfx__VramQueue_VramQ_NameTableMirrorChange_mac		offset
		sta	$_NameTable_Remap_Irq+0x0+{0}
		adc	#0x0202
		sta	$_NameTable_Remap_Irq+0x2+{0}
	.endm

	// Load mirror index
	ldx	$0x80

	// Apply mirror change
	lda	$_Gfx__NameTableMirrorChange_Data+0,x
	Gfx__VramQueue_VramQ_NameTableMirrorChange_mac		0x0
	lda	$_Gfx__NameTableMirrorChange_Data+2,x
	Gfx__VramQueue_VramQ_NameTableMirrorChange_mac		0x4
	lda	$_Gfx__NameTableMirrorChange_Data+4,x
	Gfx__VramQueue_VramQ_NameTableMirrorChange_mac		0x8
	lda	$_Gfx__NameTableMirrorChange_Data+6,x
	Gfx__VramQueue_VramQ_NameTableMirrorChange_mac		0xc

	// Next
	lda	$0x4302
	ldx	$0x80
	jmp	($_Gfx__VramQueue_Switch,x)


	.macro	Gfx__VramQueue_VramQ_DebugRow_mac	row
Gfx__VramQueue_VramQ_DebugRow{0}:
		// Keep current PPU address
		pha

		.def	temp__	=Debug_NameTable+{0}*0x80

		// Change PPU increment mode on second byte
		ldx	#0x80
		stx	$0x15

		// Set VRAM address
		lda	#_Zero+0x3800+{0}*0x40
		sta	$0x16

		// Set the DMA (01 18 xx xx xx 80 00*)
		lda	#0x1801
		tay
		sta	$0x4300
		lda	#_temp__
		sta	$0x4302
		lda	#_temp__/0x10000+0x8000
		sta	$0x4304
		sty	$0x420b

		// Restore PPU increment mode
		stz	$0x15

		// Next
		pla
		ldx	$0x80
		jmp	($_Gfx__VramQueue_Switch,x)
	.endm
	
	Gfx__VramQueue_VramQ_DebugRow_mac	0
	Gfx__VramQueue_VramQ_DebugRow_mac	1
	Gfx__VramQueue_VramQ_DebugRow_mac	2
	Gfx__VramQueue_VramQ_DebugRow_mac	3
	Gfx__VramQueue_VramQ_DebugRow_mac	4
	Gfx__VramQueue_VramQ_DebugRow_mac	5
	Gfx__VramQueue_VramQ_DebugRow_mac	6
	Gfx__VramQueue_VramQ_DebugRow_mac	7
	Gfx__VramQueue_VramQ_DebugRow_mac	8
	Gfx__VramQueue_VramQ_DebugRow_mac	9
	Gfx__VramQueue_VramQ_DebugRow_mac	10
	Gfx__VramQueue_VramQ_DebugRow_mac	11
	Gfx__VramQueue_VramQ_DebugRow_mac	12
	Gfx__VramQueue_VramQ_DebugRow_mac	13
	Gfx__VramQueue_VramQ_DebugRow_mac	14
	Gfx__VramQueue_VramQ_DebugRow_mac	15

	// ------------------------------------------------------------------------

	.macro	Gfx__VramQueue_VramQ_Tiles_CopyByte		reg
		ld{0}	$0x80
		st{0}	$0x18
	.endm

Gfx__VramQueue_VramQ_Tiles_Switch:
	switch		0x10, Gfx__VramQueue_VramQ_Tiles_Switch_Trap, Gfx__VramQueue_VramQ_Tiles_Switch_Trap
		case	0x0f
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x0e
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x0d
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x0c
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x0b
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x0a
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x09
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x08
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x07
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x06
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x05
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x04
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x03
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x02
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x01
			Gfx__VramQueue_VramQ_Tiles_CopyByte	x
		case	0x00
			ldx	$_Gfx__VramQueue_VramQ_Tiles_SR4,y
			beq	$+b_exit
b_loop:
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				Gfx__VramQueue_VramQ_Tiles_CopyByte	y
				dex
				bne	$-b_loop

b_exit:
			// Next
			ldx	$0x80
			jmp	($_Gfx__VramQueue_Switch,x)

	// ------------------------------------------------------------------------

	// UNUSED CODE

	// Write ending and find write position
	stx	$0x80
	stx	$0x80
	stx	$0x80
	ldy	#0xc0
	sty	$0x80
	ldy	#0xff
	sty	$0x80
	dey
	sty	$0x80
	ldy	#0x21
	ldy	$0x80
	tya
	sbc	#0x0006
	tay
Gfx__VramQueue_loop1:
		clc
		adc	#0x0100

		lda	$_Vram_Queue-0x100+0,y
		cmp	#0x0000
		bne	$-Gfx__VramQueue_loop1

		lda	$_Vram_Queue-0x100+2,y
		cmp	#0xc000
		bne	$-Gfx__VramQueue_loop1

		lda	$_Vram_Queue-0x100+4,y
		cmp	#0xfeff
		bne	$-Gfx__VramQueue_loop1

	return

	// ------------------------------------------------------------------------

	.align	0x100

Gfx__WindowClip_LUT:
	.macro	Gfx__WindowClip_LUT_Mac
		.data8	0x11, 0x11, 0x10, 0x10, 0x01, 0x01, 0x00, 0x00
		.data8	0x11, 0x11, 0x10, 0x10, 0x01, 0x01, 0x00, 0x00
		.data8	0x11, 0x11, 0x10, 0x10, 0x01, 0x01, 0x00, 0x00
		.data8	0x11, 0x11, 0x10, 0x10, 0x01, 0x01, 0x00, 0x00
	.endm
	Gfx__WindowClip_LUT_Mac
	Gfx__WindowClip_LUT_Mac
	Gfx__WindowClip_LUT_Mac
	Gfx__WindowClip_LUT_Mac
	Gfx__WindowClip_LUT_Mac
	Gfx__WindowClip_LUT_Mac
	Gfx__WindowClip_LUT_Mac
	Gfx__WindowClip_LUT_Mac

Gfx__TileAttributeAddrLUT:
	// eor'd with 0x0300 for palettes 4-7
	.data16	0x0300, 0x0304, 0x0308, 0x030c, 0x0310, 0x0314, 0x0318, 0x031c
	.data16	0x0380, 0x0384, 0x0388, 0x038c, 0x0390, 0x0394, 0x0398, 0x039c
	.data16	0x0200, 0x0204, 0x0208, 0x020c, 0x0210, 0x0214, 0x0218, 0x021c
	.data16	0x0280, 0x0284, 0x0288, 0x028c, 0x0290, 0x0294, 0x0298, 0x029c
	.data16	0x0100, 0x0104, 0x0108, 0x010c, 0x0110, 0x0114, 0x0118, 0x011c
	.data16	0x0180, 0x0184, 0x0188, 0x018c, 0x0190, 0x0194, 0x0198, 0x019c
	.data16	0x0000, 0x0004, 0x0008, 0x000c, 0x0010, 0x0014, 0x0018, 0x001c
	.data16	0x0080, 0x0084, 0x0088, 0x008c, 0x0090, 0x0094, 0x0098, 0x009c
	// Mirrors
	.data16	0x0300, 0x0304, 0x0308, 0x030c, 0x0310, 0x0314, 0x0318, 0x031c
	.data16	0x0380, 0x0384, 0x0388, 0x038c, 0x0390, 0x0394, 0x0398, 0x039c
	.data16	0x0200, 0x0204, 0x0208, 0x020c, 0x0210, 0x0214, 0x0218, 0x021c
	.data16	0x0280, 0x0284, 0x0288, 0x028c, 0x0290, 0x0294, 0x0298, 0x029c
	.data16	0x0100, 0x0104, 0x0108, 0x010c, 0x0110, 0x0114, 0x0118, 0x011c
	.data16	0x0180, 0x0184, 0x0188, 0x018c, 0x0190, 0x0194, 0x0198, 0x019c
	.data16	0x0000, 0x0004, 0x0008, 0x000c, 0x0010, 0x0014, 0x0018, 0x001c
	.data16	0x0080, 0x0084, 0x0088, 0x008c, 0x0090, 0x0094, 0x0098, 0x009c
	.data16	0x0300, 0x0304, 0x0308, 0x030c, 0x0310, 0x0314, 0x0318, 0x031c
	.data16	0x0380, 0x0384, 0x0388, 0x038c, 0x0390, 0x0394, 0x0398, 0x039c
	.data16	0x0200, 0x0204, 0x0208, 0x020c, 0x0210, 0x0214, 0x0218, 0x021c
	.data16	0x0280, 0x0284, 0x0288, 0x028c, 0x0290, 0x0294, 0x0298, 0x029c
	.data16	0x0100, 0x0104, 0x0108, 0x010c, 0x0110, 0x0114, 0x0118, 0x011c
	.data16	0x0180, 0x0184, 0x0188, 0x018c, 0x0190, 0x0194, 0x0198, 0x019c
	.data16	0x0000, 0x0004, 0x0008, 0x000c, 0x0010, 0x0014, 0x0018, 0x001c
	.data16	0x0080, 0x0084, 0x0088, 0x008c, 0x0090, 0x0094, 0x0098, 0x009c
	.data16	0x0300, 0x0304, 0x0308, 0x030c, 0x0310, 0x0314, 0x0318, 0x031c
	.data16	0x0380, 0x0384, 0x0388, 0x038c, 0x0390, 0x0394, 0x0398, 0x039c
	.data16	0x0200, 0x0204, 0x0208, 0x020c, 0x0210, 0x0214, 0x0218, 0x021c
	.data16	0x0280, 0x0284, 0x0288, 0x028c, 0x0290, 0x0294, 0x0298, 0x029c
	.data16	0x0100, 0x0104, 0x0108, 0x010c, 0x0110, 0x0114, 0x0118, 0x011c
	.data16	0x0180, 0x0184, 0x0188, 0x018c, 0x0190, 0x0194, 0x0198, 0x019c
	.data16	0x0000, 0x0004, 0x0008, 0x000c, 0x0010, 0x0014, 0x0018, 0x001c
	.data16	0x0080, 0x0084, 0x0088, 0x008c, 0x0090, 0x0094, 0x0098, 0x009c
	
Gfx__TileAttributeSplit0LUT:
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c
	.data8	0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c, 0x10, 0x14, 0x18, 0x1c

Gfx__TileAttributeSplit1LUT:
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c
	.data8	0x10, 0x10, 0x10, 0x10, 0x14, 0x14, 0x14, 0x14, 0x18, 0x18, 0x18, 0x18, 0x1c, 0x1c, 0x1c, 0x1c

Gfx__TileAttributeSplit2LUT:
	.fill	16, 0x10
	.fill	16, 0x14
	.fill	16, 0x18
	.fill	16, 0x1c
	.fill	16, 0x10
	.fill	16, 0x14
	.fill	16, 0x18
	.fill	16, 0x1c
	.fill	16, 0x10
	.fill	16, 0x14
	.fill	16, 0x18
	.fill	16, 0x1c
	.fill	16, 0x10
	.fill	16, 0x14
	.fill	16, 0x18
	.fill	16, 0x1c

Gfx__TileAttributeSplit3LUT:
	.fill	64, 0x10
	.fill	64, 0x14
	.fill	64, 0x18
	.fill	64, 0x1c

Gfx__MultiplyBy2:
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x20, 0x22, 0x24, 0x26, 0x28, 0x2a, 0x2c, 0x2e, 0x30, 0x32, 0x34, 0x36, 0x38, 0x3a, 0x3c, 0x3e
	.data8	0x40, 0x42, 0x44, 0x46, 0x48, 0x4a, 0x4c, 0x4e, 0x50, 0x52, 0x54, 0x56, 0x58, 0x5a, 0x5c, 0x5e
	.data8	0x60, 0x62, 0x64, 0x66, 0x68, 0x6a, 0x6c, 0x6e, 0x70, 0x72, 0x74, 0x76, 0x78, 0x7a, 0x7c, 0x7e
	.data8	0x80, 0x82, 0x84, 0x86, 0x88, 0x8a, 0x8c, 0x8e, 0x90, 0x92, 0x94, 0x96, 0x98, 0x9a, 0x9c, 0x9e
	.data8	0xa0, 0xa2, 0xa4, 0xa6, 0xa8, 0xaa, 0xac, 0xae, 0xb0, 0xb2, 0xb4, 0xb6, 0xb8, 0xba, 0xbc, 0xbe
	.data8	0xc0, 0xc2, 0xc4, 0xc6, 0xc8, 0xca, 0xcc, 0xce, 0xd0, 0xd2, 0xd4, 0xd6, 0xd8, 0xda, 0xdc, 0xde
	.data8	0xe0, 0xe2, 0xe4, 0xe6, 0xe8, 0xea, 0xec, 0xee, 0xf0, 0xf2, 0xf4, 0xf6, 0xf8, 0xfa, 0xfc, 0xfe
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x20, 0x22, 0x24, 0x26, 0x28, 0x2a, 0x2c, 0x2e, 0x30, 0x32, 0x34, 0x36, 0x38, 0x3a, 0x3c, 0x3e
	.data8	0x40, 0x42, 0x44, 0x46, 0x48, 0x4a, 0x4c, 0x4e, 0x50, 0x52, 0x54, 0x56, 0x58, 0x5a, 0x5c, 0x5e
	.data8	0x60, 0x62, 0x64, 0x66, 0x68, 0x6a, 0x6c, 0x6e, 0x70, 0x72, 0x74, 0x76, 0x78, 0x7a, 0x7c, 0x7e
	.data8	0x80, 0x82, 0x84, 0x86, 0x88, 0x8a, 0x8c, 0x8e, 0x90, 0x92, 0x94, 0x96, 0x98, 0x9a, 0x9c, 0x9e
	.data8	0xa0, 0xa2, 0xa4, 0xa6, 0xa8, 0xaa, 0xac, 0xae, 0xb0, 0xb2, 0xb4, 0xb6, 0xb8, 0xba, 0xbc, 0xbe
	.data8	0xc0, 0xc2, 0xc4, 0xc6, 0xc8, 0xca, 0xcc, 0xce, 0xd0, 0xd2, 0xd4, 0xd6, 0xd8, 0xda, 0xdc, 0xde
	.data8	0xe0, 0xe2, 0xe4, 0xe6, 0xe8, 0xea, 0xec, 0xee, 0xf0, 0xf2, 0xf4, 0xf6, 0xf8, 0xfa, 0xfc, 0xfe

Gfx__VramQueue_VramQ_Tiles_SR4:
	.fill	0x10, 0
	.fill	0x10, 1
	.fill	0x10, 2
	.fill	0x10, 3
	.fill	0x10, 4
	.fill	0x10, 5
	.fill	0x10, 6
	.fill	0x10, 7
	.fill	0x10, 8
	.fill	0x10, 9
	.fill	0x10, 10
	.fill	0x10, 11
	.fill	0x10, 12
	.fill	0x10, 13
	.fill	0x10, 14
	.fill	0x10, 15

Gfx__VramQueue_VramQ_Tiles_AND0FSL1:
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
	.data8	0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e
