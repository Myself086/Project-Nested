
	// ---------------------------------------------------------------------------	

	.mx	0x00
	.func	Hdma__LoadBuffers
Hdma__LoadBuffers:
	// Reserve 3x 256 bytes per struct
	.local	_index, _addr
	ldx	#0
b_loop:
		// Load next pointer
		lda	$=Hdma__LoadBuffers_BufferNames,x
		beq	$+b_exit
		sta	$.addr

		// Keep index
		stx	$.index

		// Allocate memory
		lda	#_HDMA_BUFFER_BANK/0x10000
		ldx	#0x0300
		call	Memory__AllocInBank
		sta	$.DP_ZeroBank
		txa
		ldx	$.addr
		sta	$0x0000,x
		clc
		adc	#0x0100
		sta	$0x0002,x
		sta	$0x0004,x
		clc
		adc	#0x0100
		sta	$0x0006,x

		// Error out if memory is misalinged to page
		and	#0x00ff
		trapne
		Exception	"Memory Misaligned{}{}{}Hdma.LoadBuffers allocated misaligned memory. Memory is expected to be page aligned when initializing."

		// Zero out the first element of each buffer, assume A==0 from AND
		//lda	#0
		ldy	$0x0000,x
		sta	[$.DP_Zero],y
		ldy	$0x0004,x
		sta	[$.DP_Zero],y
		ldy	$0x0006,x
		sta	[$.DP_Zero],y

		// Restore index and next...
		ldx	$.index
		inx
		inx
		bra	$-b_loop
b_exit:
	return

Hdma__LoadBuffers_BufferNames:
	.data16	_HDMA_Scroll, _HDMA_CHR, _HDMA_SpriteCHR, _HDMA_LayersEnabled, _HDMA_Sound
	.data16	0

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Hdma__InitChannels
Hdma__InitChannels:
	// Write constants for each HDMA channel

	// Change mode
	sep	#0x10
	.mx	0x10

	// WRAM bank in X
	ldx	#0x7e

	// BG Scroll
	lda	#0x0d03
	sta	$0x4360
	stx	$0x4364

	// CHR bank
	lda	#0x0b00
	sta	$0x4350
	stx	$0x4354

	// Sprite CHR bank
	lda	#0x0100
	sta	$0x4340
	stx	$0x4344

	// BG/Sprites enabled/disabled
	lda	#0x2c00
	sta	$0x4330
	stx	$0x4334

	// Sound ports 0, 1, 2, 3
	lda	#0x4004
	sta	$0x4310
	stx	$0x4314

	// Change mode
	rep	#0x10
	.mx	0x00

	return

	// ---------------------------------------------------------------------------

	.mx	0x20
	.func	Hdma__UpdateScrolling
	// Return: DB = HDMA_BUFFER_BANK/0x10000, DP = HDMA_VSTACK_PAGE
Hdma__UpdateScrolling_ReturnFromIRQ:
	nop

	// Restore mode, DP
	rep	#0x30
	.mx	0x00
	lda	#_HDMA_VSTACK_PAGE
	tcd
	plb

	// Change mode
	sep	#0x20
	.mx	0x20

	// Reset memory range
	stz	$_Memory_NesBank

	pla
	cmp	$.Scanline_IRQ
	sta	$.Scanline
	bne	$+b_SkipNewFrame
		stz	$.Scanline_Busy
b_exit:
		return

Hdma__UpdateScrolling:
	// Change DP and DB
	ldatcd8		HDMA_VSTACK_PAGE
	lda	#.HDMA_BUFFER_BANK/0x10000
	pha
	plb

	// Is UpdateScroll busy?
	lda	#0x80
	tsb	$.Scanline_Busy
	bne	$-b_exit

	// Is this a new frame?
	lda	$.Scanline_HDMA
	bne	$+b_SkipNewFrame
		// New frame, transfer scroll values
		ldx	$_PPU_SCROLL_X
		ldy	$_PPU_SCROLL_Y
		stx	$_IO_SCROLL_X
		sty	$_IO_SCROLL_Y

b_SkipNewFrame:
	// Is IRQ active?
	lda	$.Scanline_IRQ
	//and	$_InterruptFlag_6502
	beq	$+b_1
		// Are we crossing IRQ?
		cmp	$.Scanline_HDMA
		beq	$+b_1
		bcc	$+b_1
		cmp	$.Scanline
		beq	$+b_irq
		bcs	$+b_1
b_irq:

			// Adjust current scanline
			lda	$.Scanline
			pha
			lda	$.Scanline_IRQ
			sta	$.Scanline
			jsr	$_Hdma__UpdateScrolling_RecursiveCall

			// Keep DB
			phb

			// Get IRQ address
			lda	$_Program_Bank_3+2
			pha
			plb
			cmp	$_IRQ_NesBank
			beq	$+b_2
				phb
				sta	$_IRQ_NesBank
				rep	#0x30
				.mx	0x00
				ldatcd16	VSTACK_PAGE
				lda	$0xfffe
				Recompiler__CallFunction	"//"
				plb

				// Write destination address
				lda	[$.Recompiler_FunctionList+3],y
				sta	$_IRQ_SnesPointer
				iny
				lda	[$.Recompiler_FunctionList+3],y
				sta	$_IRQ_SnesPointer+1
b_2:
			sep	#0x30
			.mx	0x30

			unlock

			stz	$_Memory_NesBank

			// Zero page
			ldatcd8		0x0000

			// Are we using native return from interrupt?
			lda	$=RomInfo_StackEmulation+1
			and	#.RomInfo_StackEmu_NativeReturnInterrupt/0x100
			bne	$+b_2
				// Call IRQ, the following data must be in stack: Fake P, Non-native Return, _
				// "Fake P" contains break flag cleared to distinguish IRQ from BRK
				pea	$_IrqReturn_FakeNesAddress
				lda	#0
				pha
				jmp	[$_IRQ_SnesPointer]
b_2:

			// Call IRQ, the following data must be in stack: Fake P, Native Return, _, _
			// "Fake P" contains break flag cleared to distinguish IRQ from BRK
			pea	$_Hdma__UpdateScrolling_ReturnFromIRQ/0x100
			pea	$_Hdma__UpdateScrolling_ReturnFromIRQ*0x100
			jmp	[$_IRQ_SnesPointer]
b_1:
	jsr	$_Hdma__UpdateScrolling_RecursiveCall
	stz	$.Scanline_Busy
	return


Hdma__UpdateScrolling_RecursiveCall:
	.mx	0x20

	// Was Y scroll changed midframe?
	lda	#0x80
	tsb	$_IO_SCROLL_Y+1
	bne	$+b_1
		// Adjust scroll value
		lda	$_IO_SCROLL_Y
		cmp	#0xf0
		bcc	$+b_else
			inc	$_IO_SCROLL_Y+1
			sbc	$.Scanline_HDMA
			sec
			sbc	#0x10
			bra	$+b_2
b_else:
			sec
			sbc	$.Scanline_HDMA
			bcs	$+b_2
				inc	$_IO_SCROLL_Y+1
				sbc	#0x0f
b_2:
		sta	$_IO_SCROLL_Y
b_1:

	// Copy X scrolling
	ldx	$_PPU_SCROLL_X
	stx	$_IO_SCROLL_X

	// Do we go past 240?
	lda	$.Scanline_HDMA
	Hdma__UpdateScrolling_IsPast240_Mac
	bcs	$+Hdma__UpdateScrolling_Single
	lda	$.Scanline
	Hdma__UpdateScrolling_IsPast240_Mac2	0
	bcc	$+Hdma__UpdateScrolling_Single
		// Double scroll change

		// Do top lines, assume carry set from bcc
		eor	#0xff
		adc	$.Scanline
		xba
		lda	$.Scanline
		pha
		xba
		sta	$.Scanline
		jsr	$_Hdma__UpdateScrolling_In

		// Do bottom lines
		lda	$.Scanline
		sta	$.Scanline_HDMA
		pla
		sta	$.Scanline
		jsr	$_Hdma__UpdateScrolling_In

		// Change current HDMA line
		lda	$.Scanline
		sta	$.Scanline_HDMA

		rts

Hdma__UpdateScrolling_Single:
		// Single scroll change
		jsr	$_Hdma__UpdateScrolling_In

		// Change current HDMA line
		lda	$.Scanline
		sta	$.Scanline_HDMA

		rts


	// Entry: A = Scanline number
	// Return: Carry set when crossing line 240, A = How many lines overflown (if carry set)
	.macro	Hdma__UpdateScrolling_IsPast240_Mac
		clc
		adc	#0x10
		clc
		adc	$_IO_SCROLL_Y
		inc	a
	.endm
	.macro	Hdma__UpdateScrolling_IsPast240_Mac2	Add
		adc	#.Zero+0x10+{0}
		clc
		adc	$_IO_SCROLL_Y
		inc	a
	.endm
Hdma__UpdateScrolling_IsPast240:
	clc
	adc	#0x10
	clc
	adc	$_IO_SCROLL_Y
	inc	a
b_exit:
	rts


	.macro	Hdma__UpdateScrolling_IncBackBuffers_Mac	AmountScroll, AmountMisc
		lda	$.HDMA_Scroll_Back
		adc	#{0}
		sta	$.HDMA_Scroll_Back
		lda	$.HDMA_CHR_Back
		adc	#{1}
		sta	$.HDMA_CHR_Back
		sta	$.HDMA_SpriteCHR_Back
		sta	$.HDMA_LayersEnabled_Back
		bcc	$+b_1__
			inc	$.HDMA_CHR_Back+1
			inc	$.HDMA_SpriteCHR_Back+1
			inc	$.HDMA_LayersEnabled_Back+1
b_1__:
	.endm


b_exit:
	rts

	.mx	0x20
Hdma__UpdateScrolling_In:
	// HDMA repeats
	lda	$.Scanline
	sec
	sbc	$.Scanline_HDMA
	beq	$-b_exit
		dec	a
		pha
		and	#0x7f
		inc	a
		ldx	$.HDMA_Scroll_Back
		sta	$_HDMA_BUFFER_BANK+0,x
		//sta	($.HDMA_Scroll_Back)
		sta	($.HDMA_CHR_Back)
		sta	($.HDMA_SpriteCHR_Back)
		sta	($.HDMA_LayersEnabled_Back)

		// Change mode
		rep	#0x20
		.mx	0x00

		// Background scrolling X and Y
		lda	$_IO_SCROLL_X
		sta	$_HDMA_BUFFER_BANK+1,x
		lda	$_IO_SCROLL_Y
		sta	$_HDMA_BUFFER_BANK+3,x

		// Change mode
		sep	#0x20
		.mx	0x20

		// CHR bank (TODO: Speed this up with a LUT?)
		Hdma__UpdateScrolling_RegisterChrSet
		ldy	#1
		sta	($.HDMA_SpriteCHR_Back),y
		lda	$_IO_2000
		lsr	a
		lsr	a
		lsr	a
		lsr	a
		eor	$_IO_MapperChrBankSwap
		and	#0x01
		sta	($.HDMA_CHR_Back),y

		// Enable BG and sprites
		ldx	$_IO_2001
		lda	$=Hdma__UpdateScrolling_RR4AND11MIX,x
		sta	($.HDMA_LayersEnabled_Back),y

		// Reload scroll buffer pointer
		ldx	$.HDMA_Scroll_Back

		// Add 16 lines if we're past 240
		lda	$.Scanline_HDMA
		sec
		Hdma__UpdateScrolling_IsPast240_Mac2	0
		bcc	$+Hdma__UpdateScrolling_No240a
			ldx	$.HDMA_Scroll_Back
			lda	$_HDMA_BUFFER_BANK+3,x
			//clc						// Assume carry set from BCC
			adc	#0x0f
			sta	$_HDMA_BUFFER_BANK+3,x
			bcc	$+b_2
				inc	$_HDMA_BUFFER_BANK+3+1,x
b_2:
Hdma__UpdateScrolling_No240a:

		pla
		bmi	$+Hdma__UpdateScrolling_Over127
			// Save HDMA index back, assume carry clear from bcc and adc
			Hdma__UpdateScrolling_IncBackBuffers_Mac	5, 2

			rts

Hdma__UpdateScrolling_Over127:
		// Repeat 128 times
		lda	#0x80
		sta	$_HDMA_BUFFER_BANK+5,x

		// Change mode
		rep	#0x20
		.mx	0x00

		// Background scrolling X and Y
		lda	$_IO_SCROLL_X
		sta	$_HDMA_BUFFER_BANK+6,x
		lda	$_IO_SCROLL_Y
		sta	$_HDMA_BUFFER_BANK+8,x

		// Copy data for other HDMAs
		ldy	#2
		lda	($.HDMA_CHR_Back)
		sta	($.HDMA_CHR_Back),y
		lda	($.HDMA_SpriteCHR_Back)
		sta	($.HDMA_SpriteCHR_Back),y
		lda	($.HDMA_LayersEnabled_Back)
		sta	($.HDMA_LayersEnabled_Back),y

		// Change mode
		sep	#0x21
		.mx	0x20

		// Write length, repeat 128 times
		lda	#0x80
		sta	$_HDMA_BUFFER_BANK+5,x
		sta	($.HDMA_CHR_Back),y
		sta	($.HDMA_SpriteCHR_Back),y
		sta	($.HDMA_LayersEnabled_Back),y

		// Add 16 lines if we're past 240, assume carry set from SEP
		lda	$.Scanline_HDMA
		Hdma__UpdateScrolling_IsPast240_Mac2	0
		bcc	$+Hdma__UpdateScrolling_No240b
			ldx	$.HDMA_Scroll_Back
			lda	$_HDMA_BUFFER_BANK+8,x
			//clc						// Assume carry set from BCC
			adc	#0x0f
			sta	$_HDMA_BUFFER_BANK+8,x
			bcc	$+b_2
				inc	$_HDMA_BUFFER_BANK+8+1,x
b_2:
Hdma__UpdateScrolling_No240b:

		// Save HDMA index back, assume carry clear from bcc and adc
		Hdma__UpdateScrolling_IncBackBuffers_Mac	10, 4

b_exit:
	rts


	.mx	0x20
	// Return: A = requested index for this frame
	.macro	Hdma__UpdateScrolling_RegisterChrSet
		lda	#0
		ldx	$.CHR_BanksInUse_x2
		jsr	($_Hdma__UpdateScrolling_RegisterChrSet_Switch,x)
	.endm

Hdma__UpdateScrolling_RegisterChrSet_Switch_Break:
	rts

Hdma__UpdateScrolling_RegisterChrSet_Switch:
	switch	0x10, Hdma__UpdateScrolling_RegisterChrSet_Switch_Break, Hdma__UpdateScrolling_RegisterChrSet_Switch_Break
			.macro	Hdma__UpdateScrolling_RegisterChrSet_Mac	Comment2, Comment4, Comment6
				cmp	$.CHR_SetsRequest_Index
				bne	$+b_1
					inc	$.CHR_SetsRequest_Index
					// Write request here
					{2}ldy	$.CHR_0_NesBank+6
					{2}sty	$.CHR_SetsRequest_0+6
					{1}ldy	$.CHR_0_NesBank+4
					{1}sty	$.CHR_SetsRequest_0+4
					{0}ldy	$.CHR_0_NesBank+2
					{0}sty	$.CHR_SetsRequest_0+2
					ldy	$.CHR_0_NesBank+0
					sty	$.CHR_SetsRequest_0+0
					rts
b_1:
				// Find matching request
				{2}ldy	$.CHR_0_NesBank+6
				{2}cpy	$.CHR_SetsRequest_0+6
				{2}bne	$+b_next
				{1}ldy	$.CHR_0_NesBank+4
				{1}cpy	$.CHR_SetsRequest_0+4
				{1}bne	$+b_next
				{0}ldy	$.CHR_0_NesBank+2
				{0}cpy	$.CHR_SetsRequest_0+2
				{0}bne	$+b_next
				ldy	$.CHR_0_NesBank+0
				cpy	$.CHR_SetsRequest_0+0
				bne	$+b_next
					// Found matching request
					rts
b_next:
				inc	a
				cmp	$.CHR_SetsRequest_Index
				bne	$+b_1
					inc	$.CHR_SetsRequest_Index
					// Write request here
					{2}ldy	$.CHR_0_NesBank+6
					{2}sty	$.CHR_SetsRequest_1+6
					{1}ldy	$.CHR_0_NesBank+4
					{1}sty	$.CHR_SetsRequest_1+4
					{0}ldy	$.CHR_0_NesBank+2
					{0}sty	$.CHR_SetsRequest_1+2
					ldy	$.CHR_0_NesBank+0
					sty	$.CHR_SetsRequest_1+0
					rts
b_1:
				// Find matching request
				{2}ldy	$.CHR_0_NesBank+6
				{2}cpy	$.CHR_SetsRequest_1+6
				{2}bne	$+b_next
				{1}ldy	$.CHR_0_NesBank+4
				{1}cpy	$.CHR_SetsRequest_1+4
				{1}bne	$+b_next
				{0}ldy	$.CHR_0_NesBank+2
				{0}cpy	$.CHR_SetsRequest_1+2
				{0}bne	$+b_next
				ldy	$.CHR_0_NesBank+0
				cpy	$.CHR_SetsRequest_1+0
				bne	$+b_next
					// Found matching request
					rts
b_next:
				inc	a
				cmp	$.CHR_SetsRequest_Index
				bne	$+b_1
					inc	$.CHR_SetsRequest_Index
					// Write request here
					{2}ldy	$.CHR_0_NesBank+6
					{2}sty	$.CHR_SetsRequest_2+6
					{1}ldy	$.CHR_0_NesBank+4
					{1}sty	$.CHR_SetsRequest_2+4
					{0}ldy	$.CHR_0_NesBank+2
					{0}sty	$.CHR_SetsRequest_2+2
					ldy	$.CHR_0_NesBank+0
					sty	$.CHR_SetsRequest_2+0
					rts
b_1:
				// Find matching request
				{2}ldy	$.CHR_0_NesBank+6
				{2}cpy	$.CHR_SetsRequest_2+6
				{2}bne	$+b_next
				{1}ldy	$.CHR_0_NesBank+4
				{1}cpy	$.CHR_SetsRequest_2+4
				{1}bne	$+b_next
				{0}ldy	$.CHR_0_NesBank+2
				{0}cpy	$.CHR_SetsRequest_2+2
				{0}bne	$+b_next
				ldy	$.CHR_0_NesBank+0
				cpy	$.CHR_SetsRequest_2+0
				bne	$+b_next
					// Found matching request
					rts
b_next:
				lda	#0xff
				rts
			.endm
		case	0x8
		case	0x7
			Hdma__UpdateScrolling_RegisterChrSet_Mac	"", "", ""
		case	0x6
		case	0x5
			Hdma__UpdateScrolling_RegisterChrSet_Mac	"", "", "//"
		case	0x4
		case	0x3
			Hdma__UpdateScrolling_RegisterChrSet_Mac	"", "//", "//"
		case	0x2
		case	0x1
			Hdma__UpdateScrolling_RegisterChrSet_Mac	"//", "//", "//"
		case	0x0
			// Return
			lda	#0
			rts


Hdma__UpdateScrolling_RR4AND11MIX:
	.macro	Gfx__WriteBG_RR4AND11MIX_mac
		.fill	8, 0x04
		.fill	8, 0x05
		.fill	8, 0x14
		.fill	8, 0x15
	.endm
	Gfx__WriteBG_RR4AND11MIX_mac
	Gfx__WriteBG_RR4AND11MIX_mac
	Gfx__WriteBG_RR4AND11MIX_mac
	Gfx__WriteBG_RR4AND11MIX_mac
	Gfx__WriteBG_RR4AND11MIX_mac
	Gfx__WriteBG_RR4AND11MIX_mac
	Gfx__WriteBG_RR4AND11MIX_mac
	Gfx__WriteBG_RR4AND11MIX_mac

Hdma__UpdateScrolling_SoundUpdateLine:
	.fill	43, 0x01
	.fill	65, 0x02
	.fill	66, 0x03
	.fill	65, 0x04
	// In case of overflow
	.fill	17, 0x04

	// ---------------------------------------------------------------------------

	.mx	0x30
	// Entry: A = Scanline increment (up to 127)
Hdma__QuickScanline:
	// Increment adjust count for later
	pha
	clc
	adc	$_QuickScanline_AdjustCount
	sta	$_QuickScanline_AdjustCount

	// Was Y scroll changed midframe?
	lda	#0x80
	tsb	$_IO_SCROLL_Y+1
	bne	$+b_1
		// Adjust scroll value
		lda	$_IO_SCROLL_Y
		cmp	#0xf0
		bcc	$+b_else
			inc	$_IO_SCROLL_Y+1
			sbc	$.Scanline_HDMA
			sec
			sbc	#0x10
			bra	$+b_2
b_else:
			sec
			sbc	$.Scanline_HDMA
			bcs	$+b_2
				inc	$_IO_SCROLL_Y+1
				sbc	#0x0f
b_2:
		sta	$_IO_SCROLL_Y
b_1:

	pla

	rep	#0x31
	.mx	0x00

	// Skip 'A' scanlines
	inc	a
	ldx	$_HDMA_Scroll_Back
	sta	$=HDMA_BUFFER_BANK+0,x

	// Copy new scroll values
	lda	$_IO_SCROLL_X
	sta	$=HDMA_BUFFER_BANK+1,x
	lda	$_IO_SCROLL_Y
	sta	$=HDMA_BUFFER_BANK+3,x

	// Increment HDMA pointer, assume carry clear from REP
	txa
	//clc
	adc	#5
	sta	$_HDMA_Scroll_Back

	sep	#0x30
	.mx	0x30

	rtl

	// ---------------------------------------------------------------------------

	.mx	0x30
	// Entry: A = Scanline increment (up to 127)
Hdma__EndQuickScanline:
	ldy	$_QuickScanline_AdjustCount
	stz	$_QuickScanline_AdjustCount

	tya
	clc
	adc	$_Scanline_HDMA
	sta	$_Scanline_HDMA

	rep	#0x31
	.mx	0x00

	// Copy data from previous HDMA element
	ldx	$_HDMA_CHR_Back
	lda	$_HDMA_BUFFER_BANK-1,x
	sta	$_HDMA_BUFFER_BANK+1,x
	tya
	sta	$_HDMA_BUFFER_BANK+0,x
	inx
	inx
	stx	$_HDMA_CHR_Back
	//
	ldx	$_HDMA_SpriteCHR_Back
	lda	$_HDMA_BUFFER_BANK-1,x
	sta	$_HDMA_BUFFER_BANK+1,x
	tya
	sta	$_HDMA_BUFFER_BANK+0,x
	inx
	inx
	stx	$_HDMA_SpriteCHR_Back
	//
	ldx	$_HDMA_LayersEnabled_Back
	lda	$_HDMA_BUFFER_BANK-1,x
	sta	$_HDMA_BUFFER_BANK+1,x
	tya
	sta	$_HDMA_BUFFER_BANK+0,x
	inx
	inx
	stx	$_HDMA_LayersEnabled_Back

	sep	#0x30
	.mx	0x30

	rtl

	// ---------------------------------------------------------------------------

	.mx	0x20
	//.func	Hdma__SwapBuffers
	// Entry: DB = HDMA_BUFFER_BANK/0x10000, DP = HDMA_VSTACK_PAGE
Hdma__SwapBuffers:
	.vstack		HDMA_VSTACK_START

	// Invalidate side buffer in case it was already queued (not necessary because our only caller is locking thread)
	//stz	$.HDMA_SideBufferReady+1

	// Solve requests by calculating how many VRAM pages match our requests

	// 3x3 solving table (left digit is request, right digit is active)
	// Each element contains a negative number of how many pages are mismatched
	.local	.solve_00, .solve_01, .solve_02
	.local	.solve_10, .solve_11, .solve_12
	.local	.solve_20, .solve_21, .solve_22

	// Link from request to active
	.local	.link_0, .link_1, .link_2

	// Which active sets are used, positive when used, link from active to request
	.local	.used_0, .used_1, .used_2

	// Reset some variables
	ldx	#0xffff
	stx	$.link_0
	//stx	$.link_1
	stx	$.link_2
	//stx	$.used_0
	stx	$.used_1
	//stx	$.used_2

	// Change mode
	sep	#0x30
	.mx	0x30

	// Solve requests
	.macro	Hdma__SwapBuffers_SkipRq_Mac	Request
		lda	$.CHR_SetsRequest_Index
		cmp	#.Zero+{0}+1
		bcc	$+b_skip
	.endm
	.macro	Hdma__SwapBuffers_SkipRq2_Mac	Request
		lda	$.link_{0}
		bpl	$+b_skip
	.endm
	.macro	Hdma__SwapBuffers_SolveRq_Mac	Request, Active
		lda	#0x20
		ldy	#.CHR_SetsRequest_{0}
		ldx	$.CHR_BanksInUse_x2
		jsr	($_Hdma__SwapBuffers_CompareChrSet{1}_Switch,x)
		sta	$.solve_{0}{1}
		tay
		bne	$+b_next
			ldx	#.Zero+{1}
			stx	$.link_{0}
			lda	#.Zero+{0}
			sta	$.used_{1}
			bra	$+b_skip
b_next:
	.endm
	.macro	Hdma__SwapBuffers_PerfectLink_Mac	Request, Active
		lda	$.solve_{0}{1}
		bne	$+b_next
			ldx	#.Zero+{1}
			bra	$+b_solved
b_next:
	.endm
	.macro	Hdma__SwapBuffers_StartLink_Mac		Request
		// Best active index in X, best score in A
		ldx	#0xff
		txa
	.endm
	.macro	Hdma__SwapBuffers_StrongLink_Mac	Request, Active
		bit	$.used_{1}
		bpl	$+b_next
		cmp	$.solve_{0}{1}
		bcc	$+b_next
			ldx	#.Zero+{1}
			lda	$.solve_{0}{1}
b_next:
	.endm
	.macro	Hdma__SwapBuffers_EndLink_Mac		Request
		stx	$.link_{0}
		lda	#.Zero+{0}
		sta	$.used_0,x
	.endm
	.macro	Hdma__SwapBuffers_UpdateActive_Mac	Active
		lda	$.used_{0}
		bmi	$+b_next
			asl	a
			asl	a
			asl	a
			adc	#.CHR_SetsRequest_0
			tay
			ldx	$.CHR_BanksInUse_x2
			jsr	($_Hdma__SwapBuffers_ActivateChrSet{0}_Switch,x)
b_next:
	.endm

	// Compare requests to active sets
	Hdma__SwapBuffers_SkipRq_Mac	0
	Hdma__SwapBuffers_SolveRq_Mac	0, 0
	Hdma__SwapBuffers_SolveRq_Mac	0, 1
	Hdma__SwapBuffers_SolveRq_Mac	0, 2
b_skip:
	Hdma__SwapBuffers_SkipRq_Mac	1
	Hdma__SwapBuffers_SolveRq_Mac	1, 0
	Hdma__SwapBuffers_SolveRq_Mac	1, 1
	Hdma__SwapBuffers_SolveRq_Mac	1, 2
b_skip:
	Hdma__SwapBuffers_SkipRq_Mac	2
	Hdma__SwapBuffers_SolveRq_Mac	2, 0
	Hdma__SwapBuffers_SolveRq_Mac	2, 1
	Hdma__SwapBuffers_SolveRq_Mac	2, 2
b_skip:

	// Link each request to current active sets so that transferring the new CHR data costs as little time as possible
	Hdma__SwapBuffers_SkipRq_Mac		0
	Hdma__SwapBuffers_SkipRq2_Mac		0
	//Hdma__SwapBuffers_PerfectLink_Mac	0, 0
	//Hdma__SwapBuffers_PerfectLink_Mac	0, 1
	//Hdma__SwapBuffers_PerfectLink_Mac	0, 2
	Hdma__SwapBuffers_StartLink_Mac		0
	Hdma__SwapBuffers_StrongLink_Mac	0, 0
	Hdma__SwapBuffers_StrongLink_Mac	0, 1
	Hdma__SwapBuffers_StrongLink_Mac	0, 2
b_solved:
	Hdma__SwapBuffers_EndLink_Mac		0
b_skip:
	Hdma__SwapBuffers_SkipRq_Mac		1
	Hdma__SwapBuffers_SkipRq2_Mac		1
	//Hdma__SwapBuffers_PerfectLink_Mac	1, 0
	//Hdma__SwapBuffers_PerfectLink_Mac	1, 1
	//Hdma__SwapBuffers_PerfectLink_Mac	1, 2
	Hdma__SwapBuffers_StartLink_Mac		1
	Hdma__SwapBuffers_StrongLink_Mac	1, 0
	Hdma__SwapBuffers_StrongLink_Mac	1, 1
	Hdma__SwapBuffers_StrongLink_Mac	1, 2
b_solved:
	Hdma__SwapBuffers_EndLink_Mac		1
b_skip:
	Hdma__SwapBuffers_SkipRq_Mac		2
	Hdma__SwapBuffers_SkipRq2_Mac		2
	//Hdma__SwapBuffers_PerfectLink_Mac	2, 0
	//Hdma__SwapBuffers_PerfectLink_Mac	2, 1
	//Hdma__SwapBuffers_PerfectLink_Mac	2, 2
	Hdma__SwapBuffers_StartLink_Mac		2
	Hdma__SwapBuffers_StrongLink_Mac	2, 0
	Hdma__SwapBuffers_StrongLink_Mac	2, 1
	Hdma__SwapBuffers_StrongLink_Mac	2, 2
b_solved:
	Hdma__SwapBuffers_EndLink_Mac		2
b_skip:

	Hdma__SwapBuffers_UpdateActive_Mac	0
	Hdma__SwapBuffers_UpdateActive_Mac	1
	Hdma__SwapBuffers_UpdateActive_Mac	2

	// Change mode and clear carry for SBC (Back - BackBase - 1)
	rep	#0x31
	.mx	0x00

	// Fix HDMA for BG&sprite CHR
	lda	$.HDMA_CHR_Back
	sbc	$.HDMA_CHR_BackBase
	tay
	lda	#0x0000
	sep	#0x20
	.mx	0x20
b_loop:
		lda	($.HDMA_SpriteCHR_BackBase),y
		tax
		lda	$.link_0,x
		beq	$+b_1
			// Skip over nametables
			inc	a
			// Skip invalid link
			beq	$+b_next
b_1:
		ora	#0x40
		sta	($.HDMA_SpriteCHR_BackBase),y
		asl	a
		ora	($.HDMA_CHR_BackBase),y
		sta	($.HDMA_CHR_BackBase),y

b_next:
		// Next
		dey
		dey
		bpl	$-b_loop

	.macro	Hdma__SwapBuffers_Mac	VarName, ZeroEnd
		// Load back buffer
		{1}ldx	$.{0}_Back

		// Mark end of HDMA buffer
		{1}stz	$_HDMA_BUFFER_BANK+0,x

		// Swap buffers
		ldx	$.{0}_BackBase
		ldy	$.{0}_Side
		sty	$.{0}_Back
		sty	$.{0}_BackBase
		stx	$.{0}_Side
	.endm

	Hdma__SwapBuffers_Mac	HDMA_Scroll, ""
	Hdma__SwapBuffers_Mac	HDMA_CHR, ""
	Hdma__SwapBuffers_Mac	HDMA_SpriteCHR, ""
	Hdma__SwapBuffers_Mac	HDMA_LayersEnabled, ""
	Hdma__SwapBuffers_Mac	HDMA_Sound, "//"

	// Side buffers ready to be swapped on next vblank, write pretty much any non-zero value here
	stx	$.HDMA_SideBufferReady

	// Reset CHR sets
	stz	$.CHR_SetsRequest_Index

	// Reset sound update number
	stz	$.Sound_UpdateNumber

	rtl


b_trap:
	trap
	Exception	"Undefined Case{}{}{}Hdma.SwapBuffers attempted to compare a larger than usual amount of VRAM ranges."

	.macro	Hdma__SwapBuffers_CompareChrSet_Mac		ActiveSetNum, Index
		// Start from 0x00 and count down because CPY sets carry when equal
		//lda	#0x00
		// Count pages to transfer
		ldx	$.Zero+{1},y
		cpx	$.CHR_SetsActive_{0}+{1}
		bne	$+b_1
			sbc	$.CHR_{1}_PageLength
b_1:
	.endm
	
	.mx	0x30
	// Entry: Y = Request struct address (8-bit)
	// Return: A = Entry A - Number of pages matching
Hdma__SwapBuffers_CompareChrSet0_Switch:
	switch	0x10, b_trap, Zero
		case	0x8
			Hdma__SwapBuffers_CompareChrSet_Mac		0, 7
		case	0x7
			Hdma__SwapBuffers_CompareChrSet_Mac		0, 6
		case	0x6
			Hdma__SwapBuffers_CompareChrSet_Mac		0, 5
		case	0x5
			Hdma__SwapBuffers_CompareChrSet_Mac		0, 4
		case	0x4
			Hdma__SwapBuffers_CompareChrSet_Mac		0, 3
		case	0x3
			Hdma__SwapBuffers_CompareChrSet_Mac		0, 2
		case	0x2
			Hdma__SwapBuffers_CompareChrSet_Mac		0, 1
		case	0x1
			Hdma__SwapBuffers_CompareChrSet_Mac		0, 0
		case	0x0
			// Return
			rts

	.mx	0x30
	// Entry: Y = Request struct address (8-bit)
	// Return: A = Entry A - Number of pages matching
Hdma__SwapBuffers_CompareChrSet1_Switch:
	switch	0x10, b_trap, Zero
		case	0x8
			Hdma__SwapBuffers_CompareChrSet_Mac		1, 7
		case	0x7
			Hdma__SwapBuffers_CompareChrSet_Mac		1, 6
		case	0x6
			Hdma__SwapBuffers_CompareChrSet_Mac		1, 5
		case	0x5
			Hdma__SwapBuffers_CompareChrSet_Mac		1, 4
		case	0x4
			Hdma__SwapBuffers_CompareChrSet_Mac		1, 3
		case	0x3
			Hdma__SwapBuffers_CompareChrSet_Mac		1, 2
		case	0x2
			Hdma__SwapBuffers_CompareChrSet_Mac		1, 1
		case	0x1
			Hdma__SwapBuffers_CompareChrSet_Mac		1, 0
		case	0x0
			// Return
			rts

	.mx	0x30
	// Entry: Y = Request struct address (8-bit)
	// Return: A = Entry A - Number of pages matching
Hdma__SwapBuffers_CompareChrSet2_Switch:
	switch	0x10, b_trap, Zero
		case	0x8
			Hdma__SwapBuffers_CompareChrSet_Mac		2, 7
		case	0x7
			Hdma__SwapBuffers_CompareChrSet_Mac		2, 6
		case	0x6
			Hdma__SwapBuffers_CompareChrSet_Mac		2, 5
		case	0x5
			Hdma__SwapBuffers_CompareChrSet_Mac		2, 4
		case	0x4
			Hdma__SwapBuffers_CompareChrSet_Mac		2, 3
		case	0x3
			Hdma__SwapBuffers_CompareChrSet_Mac		2, 2
		case	0x2
			Hdma__SwapBuffers_CompareChrSet_Mac		2, 1
		case	0x1
			Hdma__SwapBuffers_CompareChrSet_Mac		2, 0
		case	0x0
			// Return
			rts

	.macro	Hdma__SwapBuffers_ActivateChrSet_Mac		ActiveSetNum, Index, VramPage
		// Compare CHR bank
		ldx	$.Zero+{1},y
		cpx	$.CHR_SetsActive_{0}+{1}
		beq	$+b_1
			// Write new bank
			stx	$.CHR_SetsActive_{0}+{1}
			// Send to VramQ: ChrBank(u8 highBitsVramAddr, u16 highBitsSourceAddr, u8 highBitsLength)
			lda	#.VramQ_ChrBank
			sta	$0x002180
			lda	$.CHR_{1}_VramPage
			ora	#.Zero+{2}
			sta	$0x002180
			lda	$=RomInfo_ChrBankLut_lo,x
			sta	$0x002180
			lda	$=RomInfo_ChrBankLut_hi,x
			sta	$0x002180
			lda	$.CHR_{1}_PageLength
			sta	$0x002180
b_1:
	.endm

	.mx	0x30
	// Entry: Y = Request struct address (8-bit)
Hdma__SwapBuffers_ActivateChrSet0_Switch:
	switch	0x10, b_trap, Zero
		case	0x8
			Hdma__SwapBuffers_ActivateChrSet_Mac	0, 7, 0x00
		case	0x7
			Hdma__SwapBuffers_ActivateChrSet_Mac	0, 6, 0x00
		case	0x6
			Hdma__SwapBuffers_ActivateChrSet_Mac	0, 5, 0x00
		case	0x5
			Hdma__SwapBuffers_ActivateChrSet_Mac	0, 4, 0x00
		case	0x4
			Hdma__SwapBuffers_ActivateChrSet_Mac	0, 3, 0x00
		case	0x3
			Hdma__SwapBuffers_ActivateChrSet_Mac	0, 2, 0x00
		case	0x2
			Hdma__SwapBuffers_ActivateChrSet_Mac	0, 1, 0x00
		case	0x1
			Hdma__SwapBuffers_ActivateChrSet_Mac	0, 0, 0x00
		case	0x0
			// Return
			rts

	.mx	0x30
	// Entry: Y = Request struct address (8-bit)
Hdma__SwapBuffers_ActivateChrSet1_Switch:
	switch	0x10, b_trap, Zero
		case	0x8
			Hdma__SwapBuffers_ActivateChrSet_Mac	1, 7, 0x40
		case	0x7
			Hdma__SwapBuffers_ActivateChrSet_Mac	1, 6, 0x40
		case	0x6
			Hdma__SwapBuffers_ActivateChrSet_Mac	1, 5, 0x40
		case	0x5
			Hdma__SwapBuffers_ActivateChrSet_Mac	1, 4, 0x40
		case	0x4
			Hdma__SwapBuffers_ActivateChrSet_Mac	1, 3, 0x40
		case	0x3
			Hdma__SwapBuffers_ActivateChrSet_Mac	1, 2, 0x40
		case	0x2
			Hdma__SwapBuffers_ActivateChrSet_Mac	1, 1, 0x40
		case	0x1
			Hdma__SwapBuffers_ActivateChrSet_Mac	1, 0, 0x40
		case	0x0
			// Return
			rts

	.mx	0x30
	// Entry: Y = Request struct address (8-bit)
Hdma__SwapBuffers_ActivateChrSet2_Switch:
	switch	0x10, b_trap, Zero
		case	0x8
			Hdma__SwapBuffers_ActivateChrSet_Mac	2, 7, 0x60
		case	0x7
			Hdma__SwapBuffers_ActivateChrSet_Mac	2, 6, 0x60
		case	0x6
			Hdma__SwapBuffers_ActivateChrSet_Mac	2, 5, 0x60
		case	0x5
			Hdma__SwapBuffers_ActivateChrSet_Mac	2, 4, 0x60
		case	0x4
			Hdma__SwapBuffers_ActivateChrSet_Mac	2, 3, 0x60
		case	0x3
			Hdma__SwapBuffers_ActivateChrSet_Mac	2, 2, 0x60
		case	0x2
			Hdma__SwapBuffers_ActivateChrSet_Mac	2, 1, 0x60
		case	0x1
			Hdma__SwapBuffers_ActivateChrSet_Mac	2, 0, 0x60
		case	0x0
			// Return
			rts

	// ---------------------------------------------------------------------------

