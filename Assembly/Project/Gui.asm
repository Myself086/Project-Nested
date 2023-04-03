
	// ---------------------------------------------------------------------------

	.macro	Gui__MarkLine
		lda	$=Gui__MarkLine_BitSet,x
		tsb	$.Debug_RefreshReq
	.endm
	.macro	Gui__MarkLineShort
		lda	$=Gui__MarkLine_BitSetShort,x
		tsb	$.Debug_RefreshReq
	.endm

Gui__MarkLine_BitSet:
	.fill16	0x40, 0x0001
	.fill16	0x40, 0x0002
	.fill16	0x40, 0x0004
	.fill16	0x40, 0x0008
	.fill16	0x40, 0x0010
	.fill16	0x40, 0x0020
	.fill16	0x40, 0x0040
	.fill16	0x40, 0x0080
	.fill16	0x40, 0x0100
	.fill16	0x40, 0x0200
	.fill16	0x40, 0x0400
	.fill16	0x40, 0x0800
	.fill16	0x40, 0x1000
	.fill16	0x40, 0x2000
	.fill16	0x40, 0x4000
	.fill16	0x40, 0x8000

Gui__MarkLine_BitSetShort:
	.data16	0x0001, 0x0002, 0x0004, 0x0008
	.data16	0x0010, 0x0020, 0x0040, 0x0080
	.data16	0x0100, 0x0200, 0x0400, 0x0800
	.data16	0x1000, 0x2000, 0x4000, 0x8000

Gui__MarkLine_BitToVramQ:
	.fill	0x200, 0x00
	.macro	Gui__MarkLine_BitToVramQ_FillMac	offset, value
		.addr	=Gui__MarkLine_BitToVramQ+{0}
		.data8	.Zero+{1}
	.endm
	.pushaddr
		Gui__MarkLine_BitToVramQ_FillMac	0x01, VramQ_DebugRow0
		Gui__MarkLine_BitToVramQ_FillMac	0x02, VramQ_DebugRow1
		Gui__MarkLine_BitToVramQ_FillMac	0x04, VramQ_DebugRow2
		Gui__MarkLine_BitToVramQ_FillMac	0x08, VramQ_DebugRow3
		Gui__MarkLine_BitToVramQ_FillMac	0x10, VramQ_DebugRow4
		Gui__MarkLine_BitToVramQ_FillMac	0x20, VramQ_DebugRow5
		Gui__MarkLine_BitToVramQ_FillMac	0x40, VramQ_DebugRow6
		Gui__MarkLine_BitToVramQ_FillMac	0x80, VramQ_DebugRow7
		Gui__MarkLine_BitToVramQ_FillMac	0x101, VramQ_DebugRow8
		Gui__MarkLine_BitToVramQ_FillMac	0x102, VramQ_DebugRow9
		Gui__MarkLine_BitToVramQ_FillMac	0x104, VramQ_DebugRow10
		Gui__MarkLine_BitToVramQ_FillMac	0x108, VramQ_DebugRow11
		Gui__MarkLine_BitToVramQ_FillMac	0x110, VramQ_DebugRow12
		Gui__MarkLine_BitToVramQ_FillMac	0x120, VramQ_DebugRow13
		Gui__MarkLine_BitToVramQ_FillMac	0x140, VramQ_DebugRow14
		Gui__MarkLine_BitToVramQ_FillMac	0x180, VramQ_DebugRow15
	.pulladdr

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Gui__Init
Gui__Init:
	// Reset scroll position for BG3
	lda	#0x0038
	stz	$0x2111
	smx	#0x20
	stz	$0x2111

	// Screen base and screen size
	//lda	#0x38
	sta	$0x2109

	// CHR base
	lda	#0x03
	sta	$0x210c

	// Get palette pointer
	.local	=palette
	ldx	#_Gfx_PaletteTable
	lda	#.Gfx_PaletteTable/0x10000
	stx	$.palette+0
	sta	$.palette+2

	// Set color palette for BG3: transparent, white, black, any
	stz	$0x2121
	ldx	#0
b_loop:
		.macro	Gui__Init_PickNesColor		index
			ldy	#_Zero+{0}*2
		.endm
		.macro	Gui__Init_WriteNesColor
			jsr	$_Gui__Init_WriteNesColor
		.endm

		// Transparent, skip
		lda	$0x213b
		lda	$0x213b

		// White
		Gui__Init_PickNesColor	0x30
		Gui__Init_WriteNesColor

		// Black
		Gui__Init_PickNesColor	0x3f
		Gui__Init_WriteNesColor

		// Varying color
		lda	$=Gui__Init_Palette,x
		asl	a
		tay
		Gui__Init_WriteNesColor

		inx
		cpx	#8
		bcc	$-b_loop

	// Reset cycles shown (any non-zero should work), assume carry set from BCC
	ror	$_Debug_LastIdleCycles

	// Set VRAM address and increment mode
	stz	$0x2115
	ldx	#0x3000
	stx	$0x2116

	// Transfer CHR data
	stz	$0x4300
	lda	#0x18
	sta	$0x4301
	ldx	#_Gui__Init_CHR
	stx	$0x4302
	lda	#.Gui__Init_CHR/0x10000
	sta	$0x4304
	ldx	#_Gui__Init_CHR_end-Gui__Init_CHR
	stx	$0x4305
	lda	#0x01
	sta	$0x420b

	// Set code pointer
	ldx	#_Gui__FrameUpdate
	lda	#.Gui__FrameUpdate/0x10000
	stx	$_Debug_CodePointer+0
	sta	$_Debug_CodePointer+2
	// Set ROM read pointer (bank)
	sta	$_Debug_ReadBank+2

	smx	#0x00

	// Set ROM read pointer (low)
	stz	$_Debug_ReadBank+0

	// Reset wait-state
	stz	$_Debug_WaitState

	return


Gui__Init_WriteNesColor:
	lda	[$.palette],y
	sta	$0x2122
	iny
	lda	[$.palette],y
	sta	$0x2122
	rts


Gui__Init_Palette:
	.data8	0x00, 0x11, 0x1a, 0x1c, 0x06, 0x14, 0x28, 0x10

Gui__Init_CHR:
	.palette	0x800080, 0xffffff, 0x000000, 0x0000ff
	.image   "Project/Font.png", 1, byte
Gui__Init_CHR_end:

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Gui__FrameUpdate
Gui__FrameUpdate:
	// Is debug enabled?
	lda	$=RomInfo_DebugOverlay-1
	bmi	$+b_1
Gui__FrameUpdate_Disable:
		// Permanent sleep mode
		Gui__SleepAt	0x8000, Gui__FrameUpdate_Disable
b_1:
	// TODO: malloc debug nametable and make changes to X and Y registers

Gui__FrameUpdate_Recall:

	// Has cycle count changed?
	lda	$_Idle_Average
	cmp	$.Debug_LastIdleCycles
	beq	$+b_1
		sta	$.Debug_LastIdleCycles

		// Reverse cycle value
		lda	#57640
		sec
		sbc	$.Debug_LastIdleCycles

		// Calculate CPU%
		call	Gui__CalcCpuPercent
		.local	_temp
		sta	$.temp

		Gui__Color			0
		Gui__Locate			0, 20
		Gui__WriteText		Gui__Text_CpuPercent

		Gui__Locate			7, 20
		Gui__WriteNumber	$.temp

		// Shift dot to the left
		Gui__Locate			7, 20
		Gui__SwapTiles

		.unlocal	_temp
b_1:

	// Has memory usage changed?
	call	Gui__GetRamUsed
	cmp	$.Debug_LastMemoryUsage
	beq	$+b_1
		sta	$.Debug_LastMemoryUsage
		.local	_used, _total
		sta	$.used

		// Calculate RAM total
		call	Gui__GetRamTotal
		sta	$.total

		Gui__Color			0
		Gui__Locate			0, 21
		Gui__WriteText		Gui__Text_RamFraction

		Gui__Locate			6, 21
		Gui__WriteNumber	$.used

		Gui__Locate			10, 21
		Gui__WriteNumber	$.total

		.unlocal	_used, _total
b_1:

	Gui__SleepAt	16, Gui__FrameUpdate_Recall

	// ---------------------------------------------------------------------------
	
	//01234567890123456789012345678901//

	//                                //  0
	//                                //  1
	//                                //  2
	//             Error!             //  3
	//                                //  4
	//  Unknown exception.            //  5
	//                                //  6
	//                                //  7
	//  This exception has no tag or  //  8
	//  was generated by the JIT      //  9
	//  compiler.                     // 10
	//                                // 11
	//                                // 12
	//                                // 13
	//                                // 14
	//                                // 15
	//                                // 16
	//                                // 17
	//                                // 18
	//                                // 19
	//  A:(00)00  P:     00  DB:  00  // 20
	//  X:  0000  S:   0000  DP:0000  // 21
	//  Y:  0000  PC:000000           // 22
	//                                // 23
	//  Project Nested v1.1           // 24
	//                                // 25
	//                                // 26
	//                                // 27

	.mx	0x00
	.func	Gui__BlueScreen
Gui__BlueScreen:
	// Disable NES interrupts
	lda	#0xffff
	sta	$.Vblank_Busy

	// Clear screen to a dark blue
	Gui__ClearPalette		0x02
	Gui__Cls
	Gui__Color				0

	Gui__WriteTextAt		Gui__Text_Error, 13, 3

	// Find error tag
	.precall	Dict__FindElement		=list, =compareString, .length
	ldx	#_ExceptionData
	stx	$.Param_list
	lda	#_ExceptionData/0x10000+0x0300
	sta	$.Param_list+2
	ldx	#_BlueScreen_PC
	stx	$.Param_compareString
	lda	#_BlueScreen_PC/0x10000+0x0300
	sta	$.Param_compareString+2
	call
	txy
	// Carry true when element isn't null
	bcs	$+b_1
		// Default message
		ldy	#_Gui__Text_UnknownException
b_1:
	Gui__WriteTextFormatY	2, 5, 30

	// Show top registers
	lda	$.BlueScreen_P
	bit	#0x0020
	beq	$+b_else
		// 8-bit M
		Gui__WriteTextFormat	Gui__Text_RegisterTop8, 2, 20, 30
		bra	$+b_1
b_else:
		// 16-bit M
		Gui__WriteTextFormat	Gui__Text_RegisterTop16, 2, 20, 30
b_1:

	// Show bottom registers
	lda	$.BlueScreen_P
	bit	#0x0010
	beq	$+b_else
		// 8-bit X
		Gui__WriteTextFormat	Gui__Text_RegisterBottom8, 2, 21, 30
		bra	$+b_1
b_else:
		// 16-bit X
		Gui__WriteTextFormat	Gui__Text_RegisterBottom16, 2, 21, 30
b_1:

	// Disable HDMA
	stz	$0x420b
	// Show BG3
	lda	#0x0004
	sta	$0x212C

Gui__BlueScreen_done:
	lda	#0x8000
	sta	$.BlueScreen_WaitState
	Gui__SleepAt	0x4000, Gui__BlueScreen_done

	// ---------------------------------------------------------------------------

	.macro	Gui__Sleep		frames
		lda	#_Zero+{0}-1
b__:
		ldx	#_b__+6
		jmp	$_Gui__Sleep
	.endm

	.macro	Gui__SleepAt	frames, destination
		lda	#_Zero+{0}-1
		ldx	#_Zero+{1}
		jmp	$_Gui__Sleep
	.endm

Gui__Sleep:
	// Set wait-state and continue address
	sta	$.Debug_WaitState
	stx	$.Debug_CodePointer

	// Start refreshing if not already started
	lda	$.Debug_RefreshScan
	bne	$+b_1
		lda	$.Debug_RefreshReq
		beq	$+b_1
			// Set scan to the lowest requested bit
			dec	a
			and	$.Debug_RefreshReq
			eor	$.Debug_RefreshReq
			sta	$.Debug_RefreshScan
b_1:

	rtl
	
	// ---------------------------------------------------------------------------

	.macro	Gui__Render
		lda	$.Debug_RefreshScan
		beq	$+b_1__
			trb	$.Debug_RefreshReq
			cmp	#0x0100
			bcs	$+b_2__
				// Low
				tax
				sep	#0x21
				lda	$=Gui__MarkLine_BitToVramQ+0x0,x

				bra	$+b_exit__
b_2__:
				// High
				xba
				tax
				sep	#0x21
				lda	$=Gui__MarkLine_BitToVramQ+0x100,x
b_exit__:
			sta	$0x2180
			rep	#0x30

			// Next scan
			lda	#0x0000
			sbc	$.Debug_RefreshScan
			and	$.Debug_RefreshReq
			sta	$.Debug_RefreshScan
			dec	a
			and	$.Debug_RefreshScan
			eor	$.Debug_RefreshScan
			sta	$.Debug_RefreshScan
b_1__:
	.endm

	// ---------------------------------------------------------------------------

	.macro	Gui__GetRamUsage
		.local	4 count__, _index__
		.local	_temp__

		// Calculate WRAM bank 7e
		lda	$=Memory_Top+0x7e0000
		sec
		sbc	$=Memory_HeapStack+0x7e0000
		sta	$.temp__

		// Calculate WRAM bank 7f
		lda	$=Memory_Top+0x7f0000
		sec
		sbc	$=Memory_HeapStack+0x7f0000

		// Add results from both WRAM banks
		clc
		adc	$.temp__
		sta	$.count__
		lda	#0
		rol	a
		sta	$.count__+2

		// Calculate SRAM
		phb
		ldx	$_Memory__CartBanks
		beq	$+b_1__
		lda	$=Memory__CartBanks_CONSTBANK-1,x
		and	#0x00ff
		dec	a
		sta	$.index__
		bmi	$+b_1__
b_loop__:
			// Next pair of banks
			lda	$=Memory__CartBanks_CONSTBANK,x
			inx
			inx
			pha

			// First bank in the pair
			plb
			lda	$_Memory_Top-0x8000
			sec
			sbc	$_Memory_HeapStack-0x8000
			sec
			sbc	#0xe000
			clc
			adc	$.count__
			sta	$.count__
			bcc	$+b_2__
				inc	$.count__+2
b_2__:
			// Next
			dec	$.index__
			bmi	$+b_1b__

			// Secon bank in the pair
			plb
			lda	$_Memory_Top-0x8000
			sec
			sbc	$_Memory_HeapStack-0x8000
			sec
			sbc	#0xe000
			clc
			adc	$.count__
			sta	$.count__
			bcc	$+b_2__
				inc	$.count__+2
b_2__:
			// Next
			dec	$.index__
			bpl	$-b_loop__
			bra	$+b_1__
b_1b__:
		plb
b_1__:
		plb
		// Return KB only
		lda	$.count__+1
		lsr	a
		lsr	a
		// Add non-heap SRAM bank sizes
		clc
		adc	$_Sram_SizeNonDynamicKb
		//.unlocal	4 count__, _index__
	.endm

	.mx	0x00
	.func	Gui__GetRamUsed
Gui__GetRamUsed:
	Gui__GetRamUsage		Memory_HeapStack
	return

	.mx	0x00
	.func	Gui__GetRamTotal
Gui__GetRamTotal:
	lda	#_Zero+128
	clc
	adc	$_Sram_SizeTotalKb

	return

	// ---------------------------------------------------------------------------

.false
{
	.macro	Gui__GetRamUsage
		.local	_temp__
		// Calculate top
		lda	$=Memory_HeapStack+0x7e0000
		clc
		adc	$=Memory_HeapStack+0x7f0000
		ror	a
		sta	$.temp__
		// Calculate bottom
		lda	$=Memory_Top+0x7e0000
		clc
		adc	$=Memory_Top+0x7f0000
		ror	a
		sec
		sbc	$.temp__
		// Bottom - Top
		.unlocal	_temp__
	.endm

	.mx	0x00
	.func	Gui__CalcRamPercent
Gui__CalcRamPercent:
	.local	_low, _high

	// (cycles * 1000) >> 16

	// Preserve entry number from A
	tax

	// Multiply by 1000 (binary: 0011 1110 1000)

	// =Bit 3
	asl	a
	rol	a
	rol	a
	tay
	and	#0x0003
	rol	a
	sta	$.high
	tya
	and	#0xfff8
	sta	$.low

	// +bit 10
	txa
	asl	a
	rol	a
	tay
	and	#0x0001
	rol	a
	adc	$.high+1
	sta	$.high+1
	tya
	and	#0xfffc
	adc	$.low+1
	sta	$.low+1
	bcc	$+b_1
		inc	$.high+1
b_1:

	// -bit 4
	txa
	dec	a
	asl	a
	rol	a
	rol	a
	rol	a
	rol	a
	tay
	ror	a
	eor	#0xfff0
	clc
	adc	$.low
	sta	$.low
	tya
	ora	#0xfff0
	eor	#0x000f
	adc	$.high
	//sta	$.high

	// Return value in A
	//lda	$.high

	return
}

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Gui__CalcCpuPercent
Gui__CalcCpuPercent:
	.local	_low, _high

	// Divide by 57640, or rather: (cycles * 1137) >> 16

	// Preserve entry number from A
	tax

	// Multiply by 1137 (binary: 0100 0111 0001)

	// =Bit 0
	sta	$.low
	stz	$.high

	// +Bit 10
	asl	a
	rol	a
	tay
	and	#0x0001
	rol	a
	//adc	$.high+1
	sta	$.high+1
	tya
	and	#0xfffc
	adc	$.low+1
	sta	$.low+1
	bcc	$+b_1
		inc	$.high+1
b_1:

	// +Bit 7
	txa
	lsr	a
	tay
	lda	#0
	ror	a
	adc	$.low-1
	sta	$.low-1
	tya
	adc	$.low+1
	sta	$.low+1
	bcc	$+b_1
		inc	$.high+1
b_1:

	// -bit 4
	txa
	dec	a
	asl	a
	rol	a
	rol	a
	rol	a
	rol	a
	tay
	ror	a
	eor	#0xfff0
	clc
	adc	$.low
	sta	$.low
	tya
	ora	#0xfff0
	eor	#0x000f
	adc	$.high
	//sta	$.high

	// Return value in A
	//lda	$.high

	return

	// ---------------------------------------------------------------------------

	.macro	Gui__Locate		x, y
		ldx	#_Zero+{0}*0x02+{1}*0x40
	.endm

	// ---------------------------------------------------------------------------

	.macro	Gui__Color		color
		.def	temp__		_Zero+{0}*0x400
		lda	#_temp__|0x2000
		sta	$.Debug_TileAttribute
	.endm

	// ---------------------------------------------------------------------------

	.macro	Gui__WriteTextAt	text, x, y
		Gui__Locate {1}, {2}
		ldy	#_Zero+{0}
		call	Gui__WriteText
	.endm

	.macro	Gui__WriteText	text
		ldy	#_Zero+{0}
		call	Gui__WriteText
	.endm

	.mx	0x00
	.func	Gui__WriteText
	// Entry: X = destination, Y = source
b_loop:
		ora	$.Debug_TileAttribute
		sta	$=Debug_NameTable,x
		inx
		inx
		iny
Gui__WriteText:
		lda	[$.Debug_ReadBank],y
		and	#0x00ff
		bne	$-b_loop

	Gui__MarkLine

	return

	// ---------------------------------------------------------------------------

	.macro	Gui__WriteNumber		num
		ldy	{0}
		call	Gui__WriteNumber
	.endm

	.mx	0x00
	.func	Gui__WriteNumber
	// Entry: X = destination, Y = number
	// Note: destination must point to the lower digit
Gui__WriteNumber:

b_loop:
		// Divide number by 10
		sty	$0x4204
		lda	#0x000a
		sta	$0x4206
		// Do other things while waiting 16 cycles, actually 11 or 12 cycles (-1 from writing to 0x4207, -3 or -4 from reading result)
		dex
		dex
		lda	$.Debug_TileAttribute
		ora	#0x0030

		// Write remainder
		ora	$0x004216
		sta	$=Debug_NameTable+2,x

		// Is there another digit?
		ldy	$0x4214
		bne	$-b_loop

	Gui__MarkLine

	return

	// ---------------------------------------------------------------------------

	.macro	Gui__Cls
		call	Gui__Cls
	.endm

	.func	Gui__Cls
Gui__Cls:
	lda	#0
	ldx	#0x007e
b_loop:
		sta	$=Debug_NameTable+0x000,x
		sta	$=Debug_NameTable+0x080,x
		sta	$=Debug_NameTable+0x100,x
		sta	$=Debug_NameTable+0x180,x
		sta	$=Debug_NameTable+0x200,x
		sta	$=Debug_NameTable+0x280,x
		sta	$=Debug_NameTable+0x300,x
		sta	$=Debug_NameTable+0x380,x
		sta	$=Debug_NameTable+0x400,x
		sta	$=Debug_NameTable+0x480,x
		sta	$=Debug_NameTable+0x500,x
		sta	$=Debug_NameTable+0x580,x
		sta	$=Debug_NameTable+0x600,x
		sta	$=Debug_NameTable+0x680,x
		sta	$=Debug_NameTable+0x700,x
		sta	$=Debug_NameTable+0x780,x
		dex
		dex
		bpl	$-b_loop

	// Mark all lines
	lda	#0xffff
	sta	$.Debug_RefreshReq

	return
	
	// ---------------------------------------------------------------------------

	.macro	Gui__ClearPalette		NesColor
		ldy	#_Zero+{0}
		call	Gui__ClearPalette
	.endm

	.func	Gui__ClearPalette
Gui__ClearPalette:
	// Queue VRAM address change to 0x3f00
	smx	#0x30
	lda	#.VramQ_PpuAddr
	sta	$0x2180
	lda	#0x3f
	stz	$0x2180
	sta	$0x2180

	// Transfer palette changes
	lda	#.VramQ_Palette
	ldx	#0x20
b_loop:
		sta	$0x2180
		sty	$0x2180
		dex
		bne	$-b_loop
	rmx	#0x00

	return

	// ---------------------------------------------------------------------------

	.macro	Gui__SwapTiles
		call	Gui__SwapTiles
	.endm

	.func	Gui__SwapTiles
Gui__SwapTiles:
	lda	$=Debug_NameTable+0,x
	tay
	lda	$=Debug_NameTable+2,x
	sta	$=Debug_NameTable+0,x
	tya
	sta	$=Debug_NameTable+2,x

	return

	// ---------------------------------------------------------------------------

Gui__Text_CpuPercent:
	.string0	"CPU:  00.%"

Gui__Text_RamFraction:
	.string0	"RAM:  0/  0 KB"

Gui__Text_Error:
	.string0	"Error!"

Gui__Text_UnknownException:
	.string0	"Unknown exception.{}{}{}This exception has no tag or was generated by the JIT compiler.{}{}If you see this error, please report it including the PC value of 0x{PC:X}."

Gui__Text_RegisterTop16:
	.string0	"A: {A:X}  P:     {P:X}  DB:  {DB:X}"

Gui__Text_RegisterTop8:
	.string0	"A:{ah:X} {a:X}  P:     {P:X}  DB:  {DB:X}"

Gui__Text_RegisterBottom16:
	.string0	"X: {X:X}  SP:  {S:X}  DP:{DP:X}{}Y: {Y:X}  PC:{PC:X}{}{}{title} v{version}{}{}Build date: {buildDate}"

Gui__Text_RegisterBottom8:
	.string0	"X:   {x:X}  SP:  {S:X}  DP:{DP:X}{}Y:   {y:X}  PC:{PC:X}{}{}{title} v{version}{}{}Build date: {buildDate}"

	// ---------------------------------------------------------------------------

	// Exception data
ExceptionData:
	.addrlow	ExceptionData_WritePointer
	.data8		0
	.def		ExceptionData_WritePointer		ExceptionData

