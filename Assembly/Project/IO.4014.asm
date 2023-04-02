

	.macro	IO__w4014_mac8x8	addr
		//ldy	#0xef
		cpy	$.Zero+0+{0}
		bcc	$+b_next
			// A
			ldx	$.Zero+2+{0}
			lda	$_IO__SpriteAttributeLUT,x
			eor	$_IO_Temp
			pha
			// Y, T
			pei	($.Zero+0+{0})
			// X
			ldx	$.Zero+3+{0}
			phx
b_next:
	.endm

	.macro	IO__w4014_mac8x16	addr
		{1}stz	$_Sprite0Line
		cmp	$.Zero+0+{0}
		bcc	$+b_end
b_in:
		ldy	$.Zero+2+{0}
		bpl	$+b_NoYFlip
			// With Y flip

			// Prepare T1 and A1, keep A1/A2 in A and T1/T2 in X
			lda	$.Zero+1+{0}
			ora	#0x01
			tax
			eor	$.Zero+1+{0}
			eor	$_IO__SpriteAttributeLUT2,y
			eor	$_IO_Temp
			// A1
			pha
			// T1
			phx
			// Y1
			ldy	$.Zero+0+{0}
			phy
			// X1
			ldy	$.Zero+3+{0}
			phy
			// A2
			pha
			// T2
			dex
			phx
			// Y2, assume carry set from BCC
			lda	$.Zero+0+{0}
			tay
			adc	#7
			{1}sta	$_Sprite0Line
			pha
			// Mark scanline for potentially hitting the 8 sprites limit
			ldx	$_IO__SR3,y
			dec	$_Sprites_CountdownPer8Lines+0,x
			dec	$_Sprites_CountdownPer8Lines+1,x
			dec	$_Sprites_CountdownPer8Lines+2,x
			// X2
			ldy	$.Zero+3+{0}
			phy

			// Compare next (TODO: Compare and jump directly into the next macro)
			lda	#0xef
			bra	$+b_end

		// Else
b_NoYFlip:
			// Without Y flip

			// Prepare T1 and A1, keep A1/A2 in A and T1/T2 in X
			lda	$.Zero+1+{0}
			and	#0xfe
			tax
			eor	$.Zero+1+{0}
			eor	$_IO__SpriteAttributeLUT,y
			eor	$_IO_Temp
			// A1
			pha
			// T1
			phx
			// Y1
			ldy	$.Zero+0+{0}
			phy
			// X1
			ldy	$.Zero+3+{0}
			phy
			// A2
			pha
			// T2
			inx
			phx
			// Y2, assume carry set from BCC
			lda	$.Zero+0+{0}
			tay
			adc	#7
			{1}sta	$_Sprite0Line
			pha
			// Mark scanline for potentially hitting the 8 sprites limit
			ldx	$_IO__SR3,y
			dec	$_Sprites_CountdownPer8Lines+0,x
			dec	$_Sprites_CountdownPer8Lines+1,x
			dec	$_Sprites_CountdownPer8Lines+2,x
			// X2
			ldy	$.Zero+3+{0}
			phy

			// Compare next
			lda	#0xef
b_end:
	.endm

	.macro	IO__w4014_mac8x16_nolimit	addr
		cmp	$.Zero+0+{0}
		bcc	$+b_end
b_in:
		ldy	$.Zero+2+{0}
		bpl	$+b_NoYFlip
			// With Y flip

			// Prepare T1 and A1, keep A1/A2 in A and T1/T2 in X
			lda	$.Zero+1+{0}
			ora	#0x01
			tax
			eor	$.Zero+1+{0}
			eor	$_IO__SpriteAttributeLUT2,y
			eor	$_IO_Temp
			// A1
			pha
			// T1
			phx
			// Y1
			ldy	$.Zero+0+{0}
			phy
			// X1
			ldy	$.Zero+3+{0}
			phy
			// A2
			pha
			// T2
			dex
			phx
			// Y2, assume carry set from BCC
			lda	$.Zero+0+{0}
			adc	#7
			pha
			// X2
			phy

			// Compare next (TODO: Compare and jump directly into the next macro)
			lda	#0xef
			bra	$+b_end

		// Else
b_NoYFlip:
			// Without Y flip

			// Prepare T1 and A1, keep A1/A2 in A and T1/T2 in X
			lda	$.Zero+1+{0}
			and	#0xfe
			tax
			eor	$.Zero+1+{0}
			eor	$_IO__SpriteAttributeLUT,y
			eor	$_IO_Temp
			// A1
			pha
			// T1
			phx
			// Y1
			ldy	$.Zero+0+{0}
			phy
			// X1
			ldy	$.Zero+3+{0}
			phy
			// A2
			pha
			// T2
			inx
			phx
			// Y2, assume carry set from BCC
			lda	$.Zero+0+{0}
			adc	#7
			pha
			// X2
			phy

			// Compare next
			lda	#0xef
b_end:
	.endm

	// ---------------------------------------------------------------------------

	.mx	0x30
IO__r4014_RangeFix:
	// Is it between 0x08-0x1f?
	cmp	#0x20
	bcs	$+b_1
		and	#0x07
		sta	$_IO_Temp
		bra	$+IO__w4014_RangeFixExit
b_1:

	// Is it between 0x20-0x5f? (TODO: Support mappers using this range?)
	cmp	#0x60
	trapcc
	Exception	"DMA Transfer Failed{}{}{}IO.w4014 attempted to copy bytes from page 0x{a:X}"

	// Is between 0x60-0xff

	// Load correct bank
	and	#0xe0
	tax
	lda	$_Program_Bank+2,x
	pha
	plb

	// Prepare countdown before changing to 16-bit mode
	ldy	#0x10

	smx	0x00

	// Copy sprite data
	ldx	$_IO_Temp-1
b_loop:
		lda	$0x0000,x
		sta	$_NesSpriteRemap+0x00,x
		lda	$0x0020,x
		sta	$_NesSpriteRemap+0x20,x
		lda	$0x0040,x
		sta	$_NesSpriteRemap+0x40,x
		lda	$0x0060,x
		sta	$_NesSpriteRemap+0x60,x
		lda	$0x0080,x
		sta	$_NesSpriteRemap+0x80,x
		lda	$0x00a0,x
		sta	$_NesSpriteRemap+0xa0,x
		lda	$0x00c0,x
		sta	$_NesSpriteRemap+0xc0,x
		lda	$0x00e0,x
		sta	$_NesSpriteRemap+0xe0,x
		inx
		inx
		dey
		bne	$-b_loop

	smx	0x30

	// Change page
	lda	#.NesSpriteRemap/0x100
	sta	$_IO_Temp

	bra	$+IO__w4014_RangeFixExit

	.mx	0x30
IO__w4014_In:
	php
	phb
	pha
	phx
	phy

	lock

	// Do we need to fix the page number?
	lda	$_IO_Temp
	cmp	#0x08
	bcs	$-IO__r4014_RangeFix
IO__w4014_RangeFixExit:

	phk
	plb

	// Nes:  Y, T, A, X
	// Snes: X, Y, T, A

	// What size are sprites?
	lda	$_IO_2000_EarlyValue
	and	#0x20
	SelfMod_Begin
	SelfMod_IfSet	RomInfo_SpriteLimit, 0x80
	SelfMod_Do	+b_1
		jne	$_IO__w4014_8x16_limit
		jmp	$_IO__w4014_8x8_limit
b_1:
	SelfMod_End
	jne	$_IO__w4014_8x16_nolimit

IO__w4014_8x8_nolimit:
	// Change mode
	.mx	0x00
	rep	#0x31

	// Change DP to point to Nes sprite
	lda	$_IO_Temp-1
	tcd

	// Keep stack pointer and replace it to the sprite buffer
	tsc
	sta	$_IO_Temp16

	// Replace stack pointer to the sprite buffer
	lda	#_Sprites_Buffer+0x1ff
	tcs

	// Change mode
	.mx	0x30
	sep	#0x30

	// Nes:  Y, T, A, X
	// Snes: X, Y, T, A

	// Update sprite 0 hit, assume carry clear from REP
	lda	$0x00
	adc	#0
	SelfMod_QuickCopy	RomInfo_SpriteZeroOffset, 8, -1
	bcc	$+b_1
		lda	#0xf0
b_1:
	sta	$_Sprite0Line

	// Which sprite bank to use?
	lda	$_IO_2000_EarlyValue
	lsr	a
	lsr	a
	lsr	a
	eor	$_IO_MapperChrBankSwap
	and	#0x01
	sta	$_IO_Temp

	// Convert all sprites
	ldy	#0xef
	IO__w4014_mac8x8	0xfc
	IO__w4014_mac8x8	0xf8
	IO__w4014_mac8x8	0xf4
	IO__w4014_mac8x8	0xf0
	IO__w4014_mac8x8	0xec
	IO__w4014_mac8x8	0xe8
	IO__w4014_mac8x8	0xe4
	IO__w4014_mac8x8	0xe0
	IO__w4014_mac8x8	0xdc
	IO__w4014_mac8x8	0xd8
	IO__w4014_mac8x8	0xd4
	IO__w4014_mac8x8	0xd0
	IO__w4014_mac8x8	0xcc
	IO__w4014_mac8x8	0xc8
	IO__w4014_mac8x8	0xc4
	IO__w4014_mac8x8	0xc0
	IO__w4014_mac8x8	0xbc
	IO__w4014_mac8x8	0xb8
	IO__w4014_mac8x8	0xb4
	IO__w4014_mac8x8	0xb0
	IO__w4014_mac8x8	0xac
	IO__w4014_mac8x8	0xa8
	IO__w4014_mac8x8	0xa4
	IO__w4014_mac8x8	0xa0
	IO__w4014_mac8x8	0x9c
	IO__w4014_mac8x8	0x98
	IO__w4014_mac8x8	0x94
	IO__w4014_mac8x8	0x90
	IO__w4014_mac8x8	0x8c
	IO__w4014_mac8x8	0x88
	IO__w4014_mac8x8	0x84
	IO__w4014_mac8x8	0x80
	IO__w4014_mac8x8	0x7c
	IO__w4014_mac8x8	0x78
	IO__w4014_mac8x8	0x74
	IO__w4014_mac8x8	0x70
	IO__w4014_mac8x8	0x6c
	IO__w4014_mac8x8	0x68
	IO__w4014_mac8x8	0x64
	IO__w4014_mac8x8	0x60
	IO__w4014_mac8x8	0x5c
	IO__w4014_mac8x8	0x58
	IO__w4014_mac8x8	0x54
	IO__w4014_mac8x8	0x50
	IO__w4014_mac8x8	0x4c
	IO__w4014_mac8x8	0x48
	IO__w4014_mac8x8	0x44
	IO__w4014_mac8x8	0x40
	IO__w4014_mac8x8	0x3c
	IO__w4014_mac8x8	0x38
	IO__w4014_mac8x8	0x34
	IO__w4014_mac8x8	0x30
	IO__w4014_mac8x8	0x2c
	IO__w4014_mac8x8	0x28
	IO__w4014_mac8x8	0x24
	IO__w4014_mac8x8	0x20
	IO__w4014_mac8x8	0x1c
	IO__w4014_mac8x8	0x18
	IO__w4014_mac8x8	0x14
	IO__w4014_mac8x8	0x10
	IO__w4014_mac8x8	0x0c
	IO__w4014_mac8x8	0x08
	IO__w4014_mac8x8	0x04
	IO__w4014_mac8x8	0x00

	// Queue sprite DMA
	smx	#0x10
	ldx	#.VramQ_SpritePartialXferNL
	stx	$0x2180
	tsc
	inc	a
	lsr	a
	cmp	#_Sprites_Buffer/2+0x100
	.mx	0x30
	sep	#0x31			// Set carry for SBC later down
	bne	$+b_1
		// Move "first" sprite off screen
		pea	$0xf0f0
		pea	$0xf0f0
		// No sprite on screen but count it as 1
		lda	#0xfe
b_1:

	// Do we have more sprites than before? Assume carry set from SEP
	tax
	sbc	$_IO_4014_UsedSpriteOffset
	bcs	$+b_1
		// Top sprite from current upload
		stx	$0x2180
		// More sprites than before, don't erase any sprite
		stx	$_IO_4014_UsedSpriteOffset
		jmp	$_IO__w4014_QuickFillSwitch_End
b_1:

	// Top sprite from previous upload
	ldy	$_IO_4014_UsedSpriteOffset
	sty	$0x2180

	// Save number of sprites used this time
	stx	$_IO_4014_UsedSpriteOffset
	// X = number of sprites to fill (times 2)
	tax

	// Fill newly unused sprites
	rmx	0x20
	tsc
	tay
	lda	#0xf0
	jmp	($_IO__w4014_QuickFillSwitch,x)


IO__w4014_8x8_limit:
	// Change mode
	.mx	0x00
	rep	#0x31

	// Change DP to point to Nes sprite
	lda	$_IO_Temp-1
	tcd

	// Keep stack pointer and replace it to the sprite buffer
	tsc
	sta	$_IO_Temp16

	// Replace stack pointer to the sprite buffer
	lda	#_Sprites_Buffer+0x0ff
	tcs

	// Change mode
	.mx	0x30
	sep	#0x30

	// Nes:  Y, T, A, X
	// Snes: X, Y, T, A

	// Update sprite 0 hit, assume carry clear from REP
	lda	$0x00
	adc	#0
	SelfMod_QuickCopy	RomInfo_SpriteZeroOffset, 8, -1
	bcc	$+b_1
		lda	#0xf0
b_1:
	sta	$_Sprite0Line

	// Which sprite bank to use?
	lda	$_IO_2000_EarlyValue
	lsr	a
	lsr	a
	lsr	a
	eor	$_IO_MapperChrBankSwap
	and	#0x01
	sta	$_IO_Temp

	// Convert all sprites
	ldy	#0xef
	IO__w4014_mac8x8	0x00
	IO__w4014_mac8x8	0x04
	IO__w4014_mac8x8	0x08
	IO__w4014_mac8x8	0x0c
	IO__w4014_mac8x8	0x10
	IO__w4014_mac8x8	0x14
	IO__w4014_mac8x8	0x18
	IO__w4014_mac8x8	0x1c
	IO__w4014_mac8x8	0x20
	IO__w4014_mac8x8	0x24
	IO__w4014_mac8x8	0x28
	IO__w4014_mac8x8	0x2c
	IO__w4014_mac8x8	0x30
	IO__w4014_mac8x8	0x34
	IO__w4014_mac8x8	0x38
	IO__w4014_mac8x8	0x3c
	IO__w4014_mac8x8	0x40
	IO__w4014_mac8x8	0x44
	IO__w4014_mac8x8	0x48
	IO__w4014_mac8x8	0x4c
	IO__w4014_mac8x8	0x50
	IO__w4014_mac8x8	0x54
	IO__w4014_mac8x8	0x58
	IO__w4014_mac8x8	0x5c
	IO__w4014_mac8x8	0x60
	IO__w4014_mac8x8	0x64
	IO__w4014_mac8x8	0x68
	IO__w4014_mac8x8	0x6c
	IO__w4014_mac8x8	0x70
	IO__w4014_mac8x8	0x74
	IO__w4014_mac8x8	0x78
	IO__w4014_mac8x8	0x7c
	IO__w4014_mac8x8	0x80
	IO__w4014_mac8x8	0x84
	IO__w4014_mac8x8	0x88
	IO__w4014_mac8x8	0x8c
	IO__w4014_mac8x8	0x90
	IO__w4014_mac8x8	0x94
	IO__w4014_mac8x8	0x98
	IO__w4014_mac8x8	0x9c
	IO__w4014_mac8x8	0xa0
	IO__w4014_mac8x8	0xa4
	IO__w4014_mac8x8	0xa8
	IO__w4014_mac8x8	0xac
	IO__w4014_mac8x8	0xb0
	IO__w4014_mac8x8	0xb4
	IO__w4014_mac8x8	0xb8
	IO__w4014_mac8x8	0xbc
	IO__w4014_mac8x8	0xc0
	IO__w4014_mac8x8	0xc4
	IO__w4014_mac8x8	0xc8
	IO__w4014_mac8x8	0xcc
	IO__w4014_mac8x8	0xd0
	IO__w4014_mac8x8	0xd4
	IO__w4014_mac8x8	0xd8
	IO__w4014_mac8x8	0xdc
	IO__w4014_mac8x8	0xe0
	IO__w4014_mac8x8	0xe4
	IO__w4014_mac8x8	0xe8
	IO__w4014_mac8x8	0xec
	IO__w4014_mac8x8	0xf0
	IO__w4014_mac8x8	0xf4
	IO__w4014_mac8x8	0xf8
	IO__w4014_mac8x8	0xfc

	// Are extra sprites already loaded?
	bit	$_IO_4014_SpriteSize
	bpl	$+b_1
		// Change mode
		.mx	0x00
		rep	#0x30

		// Adjust sprite size
		ldx	#0xffff
		stx	$_Sprites_Buffer+0x210
		ldx	#0x55ff
		stx	$_Sprites_Buffer+0x212
		ldx	#0x5555
		stx	$_Sprites_Buffer+0x214
		stx	$_Sprites_Buffer+0x216
		stx	$_Sprites_Buffer+0x218
		stx	$_Sprites_Buffer+0x21a
		stx	$_Sprites_Buffer+0x21c
		stx	$_Sprites_Buffer+0x21e

		// Write 60 8x8 sprites, 2 for each 8 lines (some of which are overwritten after this loop)
		lda	#0xf000
		ldx	#0x0074
		sec
b_loop:
			sbc	#0x0800
			sta	$_Sprites_Buffer+0x110,x
			sta	$_Sprites_Buffer+0x188,x
			dex
			dex
			dex
			dex
			bpl	$-b_loop

		// Write big sprites
		stz	$_Sprites_Buffer+0x100
		stz	$_Sprites_Buffer+0x110
		stz	$_Sprites_Buffer+0x120
		lda	#0xc000
		sta	$_Sprites_Buffer+0x104
		sta	$_Sprites_Buffer+0x114
		sta	$_Sprites_Buffer+0x124
		asl	a
		sta	$_Sprites_Buffer+0x108
		sta	$_Sprites_Buffer+0x118
		sta	$_Sprites_Buffer+0x128
		lsr	a
		sta	$_Sprites_Buffer+0x10c
		sta	$_Sprites_Buffer+0x11c
		sta	$_Sprites_Buffer+0x12c

		// Change mode
		.mx	0x30
		sep	#0x30
b_1:
	// Change mode
	.mx	0x20
	rep	#0x10

	// Queue sprite DMA
	lda	#.VramQ_SpriteXfer8x8
	sta	$0x2180
	tsc
	inc	a
	lsr	a
	sta	$0x2180

	// Do we have 8 free sprites?
	tsx
	cpx	#_Sprites_Buffer+0x021
	bcc	$+b_1
		// Are these 8 sprites already written?
		lda	#0x01
		and	$_IO_4014_SpriteSize
		bne	$+b_2
			// Move our 8 sprites offscreen
			ldy	#0x5555
			sty	$_Sprites_Buffer+0x200

			// Write our 8 sprites
			ldy	#0x0000
			sty	$_Sprites_Buffer+0x000
			ldy	#0x0800
			sty	$_Sprites_Buffer+0x004
			ldy	#0x1000
			sty	$_Sprites_Buffer+0x008
			ldy	#0x1800
			sty	$_Sprites_Buffer+0x00c
			ldy	#0x2000
			sty	$_Sprites_Buffer+0x010
			ldy	#0x2800
			sty	$_Sprites_Buffer+0x014
			ldy	#0x3000
			sty	$_Sprites_Buffer+0x018
			ldy	#0x3800
			sty	$_Sprites_Buffer+0x01c

			// Save sprite size
			lda	#0x01
			sta	$_IO_4014_SpriteSize

			// Reset sprite count
			lda	#0x20
			sta	$_IO_4014_UsedSpriteOffset
b_2:
		// Fill remaining space in the sprite buffer (Except first 8 sprites)
		//tsx
		lda	#0xf0
		jmp	($_IO__w4014_FillSwitch2+1-Sprites_Buffer,x)
b_1:
	// Move sprites on screen
	stz	$_Sprites_Buffer+0x200
	stz	$_Sprites_Buffer+0x201

	// Save sprite size
	stz	$_IO_4014_SpriteSize

	// Fill remaining space in the sprite buffer
	//tsx
	lda	#0xf0
	jmp	($_IO__w4014_FillSwitch+1-Sprites_Buffer,x)


	.mx	0x30
IO__w4014_8x16_nolimit:
	// Change mode and clear carry for sprite 0 math
	.mx	0x10
	rep	#0x21

	// Change DP to point to Nes sprite
	lda	$_IO_Temp-1
	tcd

	// Keep stack pointer
	tsc
	sta	$_IO_Temp16

	// Replace stack pointer to the sprite buffer
	lda	#_Sprites_Buffer+0x1ff
	tcs

	// Change mode
	.mx	0x30
	sep	#0x30

	// Which sprite bank to use?
	lda	$_IO_MapperChrBankSwap
	and	#0x01
	sta	$_IO_Temp

	// Nes:  Y, T, A, X
	// Snes: X, Y, T, A

	// Update sprite 0 hit, assume carry clear from REP
	lda	$0x00
	adc	#0
	SelfMod_QuickCopy	RomInfo_SpriteZeroOffset, 8, -1
	bcc	$+b_1
		lda	#0xf0
b_1:
	sta	$_Sprite0Line

	lda	#0xef
	IO__w4014_mac8x16_nolimit	0xfc
	IO__w4014_mac8x16_nolimit	0xf8
	IO__w4014_mac8x16_nolimit	0xf4
	IO__w4014_mac8x16_nolimit	0xf0
	IO__w4014_mac8x16_nolimit	0xec
	IO__w4014_mac8x16_nolimit	0xe8
	IO__w4014_mac8x16_nolimit	0xe4
	IO__w4014_mac8x16_nolimit	0xe0
	IO__w4014_mac8x16_nolimit	0xdc
	IO__w4014_mac8x16_nolimit	0xd8
	IO__w4014_mac8x16_nolimit	0xd4
	IO__w4014_mac8x16_nolimit	0xd0
	IO__w4014_mac8x16_nolimit	0xcc
	IO__w4014_mac8x16_nolimit	0xc8
	IO__w4014_mac8x16_nolimit	0xc4
	IO__w4014_mac8x16_nolimit	0xc0
	IO__w4014_mac8x16_nolimit	0xbc
	IO__w4014_mac8x16_nolimit	0xb8
	IO__w4014_mac8x16_nolimit	0xb4
	IO__w4014_mac8x16_nolimit	0xb0
	IO__w4014_mac8x16_nolimit	0xac
	IO__w4014_mac8x16_nolimit	0xa8
	IO__w4014_mac8x16_nolimit	0xa4
	IO__w4014_mac8x16_nolimit	0xa0
	IO__w4014_mac8x16_nolimit	0x9c
	IO__w4014_mac8x16_nolimit	0x98
	IO__w4014_mac8x16_nolimit	0x94
	IO__w4014_mac8x16_nolimit	0x90
	IO__w4014_mac8x16_nolimit	0x8c
	IO__w4014_mac8x16_nolimit	0x88
	IO__w4014_mac8x16_nolimit	0x84
	IO__w4014_mac8x16_nolimit	0x80
	IO__w4014_mac8x16_nolimit	0x7c
	IO__w4014_mac8x16_nolimit	0x78
	IO__w4014_mac8x16_nolimit	0x74
	IO__w4014_mac8x16_nolimit	0x70
	IO__w4014_mac8x16_nolimit	0x6c
	IO__w4014_mac8x16_nolimit	0x68
	IO__w4014_mac8x16_nolimit	0x64
	IO__w4014_mac8x16_nolimit	0x60
	IO__w4014_mac8x16_nolimit	0x5c
	IO__w4014_mac8x16_nolimit	0x58
	IO__w4014_mac8x16_nolimit	0x54
	IO__w4014_mac8x16_nolimit	0x50
	IO__w4014_mac8x16_nolimit	0x4c
	IO__w4014_mac8x16_nolimit	0x48
	IO__w4014_mac8x16_nolimit	0x44
	IO__w4014_mac8x16_nolimit	0x40
	IO__w4014_mac8x16_nolimit	0x3c
	IO__w4014_mac8x16_nolimit	0x38
	IO__w4014_mac8x16_nolimit	0x34
	IO__w4014_mac8x16_nolimit	0x30
	IO__w4014_mac8x16_nolimit	0x2c
	IO__w4014_mac8x16_nolimit	0x28
	IO__w4014_mac8x16_nolimit	0x24
	IO__w4014_mac8x16_nolimit	0x20
	IO__w4014_mac8x16_nolimit	0x1c
	IO__w4014_mac8x16_nolimit	0x18
	IO__w4014_mac8x16_nolimit	0x14
	IO__w4014_mac8x16_nolimit	0x10
	IO__w4014_mac8x16_nolimit	0x0c
	IO__w4014_mac8x16_nolimit	0x08
	IO__w4014_mac8x16_nolimit	0x04
	IO__w4014_mac8x16_nolimit	0x00

	// Queue sprite DMA
	smx	#0x10
	ldx	#.VramQ_SpritePartialXferNL
	stx	$0x2180
	tsc
	inc	a
	lsr	a
	cmp	#_Sprites_Buffer/2+0x100
	.mx	0x30
	sep	#0x31			// Set carry for SBC later down
	bne	$+b_1
		// Move "first" sprite off screen
		pea	$0xf0f0
		pea	$0xf0f0
		// No sprite on screen but count it as 1
		lda	#0xfe
b_1:

	// Do we have more sprites than before? Assume carry set from SEP
	tax
	sbc	$_IO_4014_UsedSpriteOffset
	bcs	$+b_1
		// Top sprite from current upload
		stx	$0x2180
		// More sprites than before, don't erase any sprite
		stx	$_IO_4014_UsedSpriteOffset
		jmp	$_IO__w4014_QuickFillSwitch_End
b_1:

	// Top sprite from previous upload
	ldy	$_IO_4014_UsedSpriteOffset
	sty	$0x2180

	// Save number of sprites used this time
	stx	$_IO_4014_UsedSpriteOffset
	// X = number of sprites to fill (times 2)
	tax

	// Fill newly unused sprites
	rmx	0x20
	tsc
	tay
	lda	#0xf0
	jmp	($_IO__w4014_QuickFillSwitch,x)


IO__w4014_8x16_limit:

	// Change mode and clear carry for sprite 0 math
	.mx	0x10
	rep	#0x21

	// Change DP to point to Nes sprite
	lda	$_IO_Temp-1
	tcd

	// Keep stack pointer
	tsc
	sta	$_IO_Temp16

	// Reset sprite count per scanline
	lda	#_Sprites_CountdownPer8Lines+0x1d
	tcs
	lda	#0x0808
	pha
	pha
	pha
	pha
	pha
	pha
	pha
	pha
	pha
	pha
	pha
	pha
	pha
	pha
	pha

	// Replace stack pointer to the sprite buffer (Already done from overriding extra attribute bits)
	//lda	#_Sprites_Buffer+0x1ff
	//tcs

	// Change mode
	.mx	0x30
	sep	#0x30

	// Which sprite bank to use?
	lda	$_IO_MapperChrBankSwap
	and	#0x01
	sta	$_IO_Temp

	// Nes:  Y, T, A, X
	// Snes: X, Y, T, A

	// Update sprite 0 hit, assume carry clear from REP
	lda	$0x00
	adc	#0
	SelfMod_QuickCopy	RomInfo_SpriteZeroOffset, 8, -1
	bcc	$+b_1
		lda	#0xf0
b_1:
	sta	$_Sprite0Line

	lda	#0xef
	IO__w4014_mac8x16	0x00, "//"
	IO__w4014_mac8x16	0x04, "//"
	IO__w4014_mac8x16	0x08, "//"
	IO__w4014_mac8x16	0x0c, "//"
	IO__w4014_mac8x16	0x10, "//"
	IO__w4014_mac8x16	0x14, "//"
	IO__w4014_mac8x16	0x18, "//"
	IO__w4014_mac8x16	0x1c, "//"
	IO__w4014_mac8x16	0x20, "//"
	IO__w4014_mac8x16	0x24, "//"
	IO__w4014_mac8x16	0x28, "//"
	IO__w4014_mac8x16	0x2c, "//"
	IO__w4014_mac8x16	0x30, "//"
	IO__w4014_mac8x16	0x34, "//"
	IO__w4014_mac8x16	0x38, "//"
	IO__w4014_mac8x16	0x3c, "//"
	IO__w4014_mac8x16	0x40, "//"
	IO__w4014_mac8x16	0x44, "//"
	IO__w4014_mac8x16	0x48, "//"
	IO__w4014_mac8x16	0x4c, "//"
	IO__w4014_mac8x16	0x50, "//"
	IO__w4014_mac8x16	0x54, "//"
	IO__w4014_mac8x16	0x58, "//"
	IO__w4014_mac8x16	0x5c, "//"
	IO__w4014_mac8x16	0x60, "//"
	IO__w4014_mac8x16	0x64, "//"
	IO__w4014_mac8x16	0x68, "//"
	IO__w4014_mac8x16	0x6c, "//"
	IO__w4014_mac8x16	0x70, "//"
	IO__w4014_mac8x16	0x74, "//"
	IO__w4014_mac8x16	0x78, "//"
	IO__w4014_mac8x16	0x7c, "//"
	IO__w4014_mac8x16	0x80, "//"
	IO__w4014_mac8x16	0x84, "//"
	IO__w4014_mac8x16	0x88, "//"
	IO__w4014_mac8x16	0x8c, "//"
	IO__w4014_mac8x16	0x90, "//"
	IO__w4014_mac8x16	0x94, "//"
	IO__w4014_mac8x16	0x98, "//"
	IO__w4014_mac8x16	0x9c, "//"
	IO__w4014_mac8x16	0xa0, "//"
	IO__w4014_mac8x16	0xa4, "//"
	IO__w4014_mac8x16	0xa8, "//"
	IO__w4014_mac8x16	0xac, "//"
	IO__w4014_mac8x16	0xb0, "//"
	IO__w4014_mac8x16	0xb4, "//"
	IO__w4014_mac8x16	0xb8, "//"
	IO__w4014_mac8x16	0xbc, "//"
	IO__w4014_mac8x16	0xc0, "//"
	IO__w4014_mac8x16	0xc4, "//"
	IO__w4014_mac8x16	0xc8, "//"
	IO__w4014_mac8x16	0xcc, "//"
	IO__w4014_mac8x16	0xd0, "//"
	IO__w4014_mac8x16	0xd4, "//"
	IO__w4014_mac8x16	0xd8, "//"
	IO__w4014_mac8x16	0xdc, "//"
	IO__w4014_mac8x16	0xe0, "//"
	IO__w4014_mac8x16	0xe4, "//"
	IO__w4014_mac8x16	0xe8, "//"
	IO__w4014_mac8x16	0xec, "//"
	IO__w4014_mac8x16	0xf0, "//"
	IO__w4014_mac8x16	0xf4, "//"
	IO__w4014_mac8x16	0xf8, "//"
	IO__w4014_mac8x16	0xfc, "//"

	// Queue sprite transfer with sprite priority
	.mx	0x10
	rep	#0x20
	tsc
	lsr	a
	inc	a
	tax
	cmp	#_Sprites_Buffer/2+0x100
	bne	$+b_else
		// No sprite on screen
		ldy	#.VramQ_SpriteXferEmpty
		sty	$0x2180
		bra	$+b_1
b_else:
		ldy	#.VramQ_SpriteXfer8x16
		sty	$0x2180
		stx	$0x2180
b_1:

	// Adjust our pointer from 1-byte empty address to 4-byte full offset
	.mx	0x00
	rep	#0x30
	txa
	asl	a
	tax

	// Add 12 big sprites
	sbc	#_Zero-1+0x30

	// Do we have enough free space?
	jmi	$_IO__w4014_8x16_exit
	tax

	// Add big sprites regardless of need, at least in this version
	stz	$_Sprites_Buffer+0x00,x
	stz	$_Sprites_Buffer+0x10,x
	stz	$_Sprites_Buffer+0x20,x
	lda	#0xc000
	sta	$_Sprites_Buffer+0x04,x
	sta	$_Sprites_Buffer+0x14,x
	sta	$_Sprites_Buffer+0x24,x
	asl	a
	sta	$_Sprites_Buffer+0x08,x
	sta	$_Sprites_Buffer+0x18,x
	sta	$_Sprites_Buffer+0x28,x
	lsr	a
	sta	$_Sprites_Buffer+0x0c,x
	sta	$_Sprites_Buffer+0x1c,x
	sta	$_Sprites_Buffer+0x2c,x

	.macro	IO__w4014_SpriteLimit_mac8x16	linePair
		//lda	#0x0080
		bit	$_Sprites_CountdownPer8Lines+{0}
		bmi	$+b_both
		beq	$+b_none
b_even:		// 00f0
		// Reserve 2 sprites
		txa
		sec
		sbc	#8
		jmi	$_IO__w4014_8x16_exit
		tax

		// Add 2 sprites
		lda	#_Zero+{0}*0x800
		sta	$_Sprites_Buffer+0x00,x
		sta	$_Sprites_Buffer+0x04,x

		// Next
		lda	#0x0080
		bra	$+b_none
b_both:		// f0f0
		beq	$+b_odd

		// Reserve 4 sprites
		txa
		sec
		sbc	#16
		jmi	$_IO__w4014_8x16_exit
		tax

		// Add 4 sprites
		lda	#_Zero+{0}*0x800
		sta	$_Sprites_Buffer+0x00,x
		sta	$_Sprites_Buffer+0x04,x
		lda	#_Zero+{0}*0x800+0x800
		sta	$_Sprites_Buffer+0x08,x
		sta	$_Sprites_Buffer+0x0c,x

		// Next
		lda	#0x0080
		bra	$+b_none
b_odd:		// f000
		// Reserve 2 sprites
		txa
		sec
		sbc	#8
		jmi	$_IO__w4014_8x16_exit
		tax

		// Add 2 sprites
		lda	#_Zero+{0}*0x800+0x800
		sta	$_Sprites_Buffer+0x00,x
		sta	$_Sprites_Buffer+0x04,x

		// Next
		lda	#0x0080
		//bra	$+b_none
b_none:		// 0000
	.endm

	lda	#0x0080
	IO__w4014_SpriteLimit_mac8x16	0x00
	IO__w4014_SpriteLimit_mac8x16	0x02
	IO__w4014_SpriteLimit_mac8x16	0x04
	IO__w4014_SpriteLimit_mac8x16	0x06
	IO__w4014_SpriteLimit_mac8x16	0x08
	IO__w4014_SpriteLimit_mac8x16	0x0a
	IO__w4014_SpriteLimit_mac8x16	0x0c
	IO__w4014_SpriteLimit_mac8x16	0x0e
	IO__w4014_SpriteLimit_mac8x16	0x10
	IO__w4014_SpriteLimit_mac8x16	0x12
	IO__w4014_SpriteLimit_mac8x16	0x14
	IO__w4014_SpriteLimit_mac8x16	0x16
	IO__w4014_SpriteLimit_mac8x16	0x18
	IO__w4014_SpriteLimit_mac8x16	0x1a
	IO__w4014_SpriteLimit_mac8x16	0x1c
	//IO__w4014_SpriteLimit_mac8x16	0x1e

IO__w4014_8x16_exit:
	sep	#0x20
	.mx	0x20

	// Save sprite size, set bit 7 for 8x16
	lda	#0xf0
	sta	$_IO_4014_SpriteSize

	// Fill remaining space in the sprite buffer
	//lda	#0xf0
	jmp	($_IO__w4014_FillSwitch,x)

IO__w4014_FillSwitch:
	switch		0x200, IO__w4014_FillSwitch_End, IO__w4014_FillSwitch_End
		.macro	IO__w4014_FillSwitch_mac
			case	{0}
				sta	$_Sprites_Buffer+1+{0}*2-4
		.endm

		.macro	IO__w4014_FillSwitch_mac2
			IO__w4014_FillSwitch_mac		{0}e
			IO__w4014_FillSwitch_mac		{0}c
			IO__w4014_FillSwitch_mac		{0}a
			IO__w4014_FillSwitch_mac		{0}8
			IO__w4014_FillSwitch_mac		{0}6
			IO__w4014_FillSwitch_mac		{0}4
			IO__w4014_FillSwitch_mac		{0}2
			{1}IO__w4014_FillSwitch_mac	{0}0
		.endm
		
		IO__w4014_FillSwitch_mac2	0x1f, ""
		IO__w4014_FillSwitch_mac2	0x1e, ""
		IO__w4014_FillSwitch_mac2	0x1d, ""
		IO__w4014_FillSwitch_mac2	0x1c, ""
		IO__w4014_FillSwitch_mac2	0x1b, ""
		IO__w4014_FillSwitch_mac2	0x1a, ""
		IO__w4014_FillSwitch_mac2	0x19, ""
		IO__w4014_FillSwitch_mac2	0x18, ""
		IO__w4014_FillSwitch_mac2	0x17, ""
		IO__w4014_FillSwitch_mac2	0x16, ""
		IO__w4014_FillSwitch_mac2	0x15, ""
		IO__w4014_FillSwitch_mac2	0x14, ""
		IO__w4014_FillSwitch_mac2	0x13, ""
		IO__w4014_FillSwitch_mac2	0x12, ""
		IO__w4014_FillSwitch_mac2	0x11, ""
		IO__w4014_FillSwitch_mac2	0x10, ""
		IO__w4014_FillSwitch_mac2	0x0f, ""
		IO__w4014_FillSwitch_mac2	0x0e, ""
		IO__w4014_FillSwitch_mac2	0x0d, ""
		IO__w4014_FillSwitch_mac2	0x0c, ""
		IO__w4014_FillSwitch_mac2	0x0b, ""
		IO__w4014_FillSwitch_mac2	0x0a, ""
		IO__w4014_FillSwitch_mac2	0x09, ""
		IO__w4014_FillSwitch_mac2	0x08, ""
		IO__w4014_FillSwitch_mac2	0x07, ""
		IO__w4014_FillSwitch_mac2	0x06, ""
		IO__w4014_FillSwitch_mac2	0x05, ""
		IO__w4014_FillSwitch_mac2	0x04, ""
		IO__w4014_FillSwitch_mac2	0x03, ""
		IO__w4014_FillSwitch_mac2	0x02, ""
		IO__w4014_FillSwitch_mac2	0x01, ""
		IO__w4014_FillSwitch_mac2	0x00, "//"
IO__w4014_FillSwitch_End:

	// Fix DP
	rep	#0x20
	.mx	0x00
	lda	#0x0000
	tcd

	// Fix stack pointer
	lda	$_IO_Temp16
	tcs

	// Change mode back
	sep	#0x30
	.mx	0x30

	ply
	plx
	pla
	plb
	plp
	rtl

IO__w4014_FillSwitch2:
	switch		0x200, IO__w4014_FillSwitch2_End, IO__w4014_FillSwitch2_End
		IO__w4014_FillSwitch_mac2	0x1f, ""
		IO__w4014_FillSwitch_mac2	0x1e, ""
		IO__w4014_FillSwitch_mac2	0x1d, ""
		IO__w4014_FillSwitch_mac2	0x1c, ""
		IO__w4014_FillSwitch_mac2	0x1b, ""
		IO__w4014_FillSwitch_mac2	0x1a, ""
		IO__w4014_FillSwitch_mac2	0x19, ""
		IO__w4014_FillSwitch_mac2	0x18, ""
		IO__w4014_FillSwitch_mac2	0x17, ""
		IO__w4014_FillSwitch_mac2	0x16, ""
		IO__w4014_FillSwitch_mac2	0x15, ""
		IO__w4014_FillSwitch_mac2	0x14, ""
		IO__w4014_FillSwitch_mac2	0x13, ""
		IO__w4014_FillSwitch_mac2	0x12, ""
		IO__w4014_FillSwitch_mac2	0x11, ""
		IO__w4014_FillSwitch_mac2	0x10, ""
		IO__w4014_FillSwitch_mac2	0x0f, ""
		IO__w4014_FillSwitch_mac2	0x0e, ""
		IO__w4014_FillSwitch_mac2	0x0d, ""
		IO__w4014_FillSwitch_mac2	0x0c, ""
		IO__w4014_FillSwitch_mac2	0x0b, ""
		IO__w4014_FillSwitch_mac2	0x0a, ""
		IO__w4014_FillSwitch_mac2	0x09, ""
		IO__w4014_FillSwitch_mac2	0x08, ""
		IO__w4014_FillSwitch_mac2	0x07, ""
		IO__w4014_FillSwitch_mac2	0x06, ""
		IO__w4014_FillSwitch_mac2	0x05, ""
		IO__w4014_FillSwitch_mac2	0x04, ""
		IO__w4014_FillSwitch_mac2	0x03, ""
		IO__w4014_FillSwitch_mac2	0x02, ""
		IO__w4014_FillSwitch_mac2	0x01, "//"
IO__w4014_FillSwitch2_End:

	// Fix DP
	rep	#0x20
	.mx	0x00
	lda	#0x0000
	tcd

	// Fix stack pointer
	lda	$_IO_Temp16
	tcs

	// Change mode back
	sep	#0x30
	.mx	0x30

	ply
	plx
	pla
	plb
	plp
	rtl

IO__w4014_QuickFillSwitch:
	switch		0x80, IO__w4014_QuickFillSwitch_End, IO__w4014_QuickFillSwitch_End
		.macro	IO__w4014_QuickFillSwitch_mac
			.def	temp__		{0}
			case	temp__/4
				sta	$_Zero-{0}+2,y
		.endm

		.macro	IO__w4014_QuickFillSwitch_mac2
			IO__w4014_QuickFillSwitch_mac		{0}c
			IO__w4014_QuickFillSwitch_mac		{0}8
			IO__w4014_QuickFillSwitch_mac		{0}4
			{1}IO__w4014_QuickFillSwitch_mac	{0}0
		.endm
		
		IO__w4014_QuickFillSwitch_mac2	0x1f, ""
		IO__w4014_QuickFillSwitch_mac2	0x1e, ""
		IO__w4014_QuickFillSwitch_mac2	0x1d, ""
		IO__w4014_QuickFillSwitch_mac2	0x1c, ""
		IO__w4014_QuickFillSwitch_mac2	0x1b, ""
		IO__w4014_QuickFillSwitch_mac2	0x1a, ""
		IO__w4014_QuickFillSwitch_mac2	0x19, ""
		IO__w4014_QuickFillSwitch_mac2	0x18, ""
		IO__w4014_QuickFillSwitch_mac2	0x17, ""
		IO__w4014_QuickFillSwitch_mac2	0x16, ""
		IO__w4014_QuickFillSwitch_mac2	0x15, ""
		IO__w4014_QuickFillSwitch_mac2	0x14, ""
		IO__w4014_QuickFillSwitch_mac2	0x13, ""
		IO__w4014_QuickFillSwitch_mac2	0x12, ""
		IO__w4014_QuickFillSwitch_mac2	0x11, ""
		IO__w4014_QuickFillSwitch_mac2	0x10, ""
		IO__w4014_QuickFillSwitch_mac2	0x0f, ""
		IO__w4014_QuickFillSwitch_mac2	0x0e, ""
		IO__w4014_QuickFillSwitch_mac2	0x0d, ""
		IO__w4014_QuickFillSwitch_mac2	0x0c, ""
		IO__w4014_QuickFillSwitch_mac2	0x0b, ""
		IO__w4014_QuickFillSwitch_mac2	0x0a, ""
		IO__w4014_QuickFillSwitch_mac2	0x09, ""
		IO__w4014_QuickFillSwitch_mac2	0x08, ""
		IO__w4014_QuickFillSwitch_mac2	0x07, ""
		IO__w4014_QuickFillSwitch_mac2	0x06, ""
		IO__w4014_QuickFillSwitch_mac2	0x05, ""
		IO__w4014_QuickFillSwitch_mac2	0x04, ""
		IO__w4014_QuickFillSwitch_mac2	0x03, ""
		IO__w4014_QuickFillSwitch_mac2	0x02, ""
		IO__w4014_QuickFillSwitch_mac2	0x01, ""
		IO__w4014_QuickFillSwitch_mac2	0x00, "//"
IO__w4014_QuickFillSwitch_End:

	// Fix DP
	rep	#0x20
	.mx	0x00
	lda	#0x0000
	tcd

	// Fix stack pointer
	lda	$_IO_Temp16
	tcs

	// Change mode back
	sep	#0x30
	.mx	0x30

	ply
	plx
	pla
	plb
	plp
	rtl


	// Align to avoid page boundary crossing penalty (TODO: Move this to a better place within the bank)
	.align	0x100

IO__SpriteAttributeLUT:
	.data8	0x20, 0x22, 0x24, 0x26, 0x20, 0x22, 0x24, 0x26, 0x20, 0x22, 0x24, 0x26, 0x20, 0x22, 0x24, 0x26
	.data8	0x20, 0x22, 0x24, 0x26, 0x20, 0x22, 0x24, 0x26, 0x20, 0x22, 0x24, 0x26, 0x20, 0x22, 0x24, 0x26
	.data8	0x00, 0x02, 0x04, 0x06, 0x00, 0x02, 0x04, 0x06, 0x00, 0x02, 0x04, 0x06, 0x00, 0x02, 0x04, 0x06
	.data8	0x00, 0x02, 0x04, 0x06, 0x00, 0x02, 0x04, 0x06, 0x00, 0x02, 0x04, 0x06, 0x00, 0x02, 0x04, 0x06
	.data8	0x60, 0x62, 0x64, 0x66, 0x60, 0x62, 0x64, 0x66, 0x60, 0x62, 0x64, 0x66, 0x60, 0x62, 0x64, 0x66
	.data8	0x60, 0x62, 0x64, 0x66, 0x60, 0x62, 0x64, 0x66, 0x60, 0x62, 0x64, 0x66, 0x60, 0x62, 0x64, 0x66
	.data8	0x40, 0x42, 0x44, 0x46, 0x40, 0x42, 0x44, 0x46, 0x40, 0x42, 0x44, 0x46, 0x40, 0x42, 0x44, 0x46
	.data8	0x40, 0x42, 0x44, 0x46, 0x40, 0x42, 0x44, 0x46, 0x40, 0x42, 0x44, 0x46, 0x40, 0x42, 0x44, 0x46
	.data8	0xa0, 0xa2, 0xa4, 0xa6, 0xa0, 0xa2, 0xa4, 0xa6, 0xa0, 0xa2, 0xa4, 0xa6, 0xa0, 0xa2, 0xa4, 0xa6
	.data8	0xa0, 0xa2, 0xa4, 0xa6, 0xa0, 0xa2, 0xa4, 0xa6, 0xa0, 0xa2, 0xa4, 0xa6, 0xa0, 0xa2, 0xa4, 0xa6
	.data8	0x80, 0x82, 0x84, 0x86, 0x80, 0x82, 0x84, 0x86, 0x80, 0x82, 0x84, 0x86, 0x80, 0x82, 0x84, 0x86
	.data8	0x80, 0x82, 0x84, 0x86, 0x80, 0x82, 0x84, 0x86, 0x80, 0x82, 0x84, 0x86, 0x80, 0x82, 0x84, 0x86
	.data8	0xe0, 0xe2, 0xe4, 0xe6, 0xe0, 0xe2, 0xe4, 0xe6, 0xe0, 0xe2, 0xe4, 0xe6, 0xe0, 0xe2, 0xe4, 0xe6
	.data8	0xe0, 0xe2, 0xe4, 0xe6, 0xe0, 0xe2, 0xe4, 0xe6, 0xe0, 0xe2, 0xe4, 0xe6, 0xe0, 0xe2, 0xe4, 0xe6
	.data8	0xc0, 0xc2, 0xc4, 0xc6, 0xc0, 0xc2, 0xc4, 0xc6, 0xc0, 0xc2, 0xc4, 0xc6, 0xc0, 0xc2, 0xc4, 0xc6
	.data8	0xc0, 0xc2, 0xc4, 0xc6, 0xc0, 0xc2, 0xc4, 0xc6, 0xc0, 0xc2, 0xc4, 0xc6, 0xc0, 0xc2, 0xc4, 0xc6

IO__SpriteAttributeLUT2:
	.data8	0x21, 0x23, 0x25, 0x27, 0x21, 0x23, 0x25, 0x27, 0x21, 0x23, 0x25, 0x27, 0x21, 0x23, 0x25, 0x27
	.data8	0x21, 0x23, 0x25, 0x27, 0x21, 0x23, 0x25, 0x27, 0x21, 0x23, 0x25, 0x27, 0x21, 0x23, 0x25, 0x27
	.data8	0x01, 0x03, 0x05, 0x07, 0x01, 0x03, 0x05, 0x07, 0x01, 0x03, 0x05, 0x07, 0x01, 0x03, 0x05, 0x07
	.data8	0x01, 0x03, 0x05, 0x07, 0x01, 0x03, 0x05, 0x07, 0x01, 0x03, 0x05, 0x07, 0x01, 0x03, 0x05, 0x07
	.data8	0x61, 0x63, 0x65, 0x67, 0x61, 0x63, 0x65, 0x67, 0x61, 0x63, 0x65, 0x67, 0x61, 0x63, 0x65, 0x67
	.data8	0x61, 0x63, 0x65, 0x67, 0x61, 0x63, 0x65, 0x67, 0x61, 0x63, 0x65, 0x67, 0x61, 0x63, 0x65, 0x67
	.data8	0x41, 0x43, 0x45, 0x47, 0x41, 0x43, 0x45, 0x47, 0x41, 0x43, 0x45, 0x47, 0x41, 0x43, 0x45, 0x47
	.data8	0x41, 0x43, 0x45, 0x47, 0x41, 0x43, 0x45, 0x47, 0x41, 0x43, 0x45, 0x47, 0x41, 0x43, 0x45, 0x47
	.data8	0xa1, 0xa3, 0xa5, 0xa7, 0xa1, 0xa3, 0xa5, 0xa7, 0xa1, 0xa3, 0xa5, 0xa7, 0xa1, 0xa3, 0xa5, 0xa7
	.data8	0xa1, 0xa3, 0xa5, 0xa7, 0xa1, 0xa3, 0xa5, 0xa7, 0xa1, 0xa3, 0xa5, 0xa7, 0xa1, 0xa3, 0xa5, 0xa7
	.data8	0x81, 0x83, 0x85, 0x87, 0x81, 0x83, 0x85, 0x87, 0x81, 0x83, 0x85, 0x87, 0x81, 0x83, 0x85, 0x87
	.data8	0x81, 0x83, 0x85, 0x87, 0x81, 0x83, 0x85, 0x87, 0x81, 0x83, 0x85, 0x87, 0x81, 0x83, 0x85, 0x87
	.data8	0xe1, 0xe3, 0xe5, 0xe7, 0xe1, 0xe3, 0xe5, 0xe7, 0xe1, 0xe3, 0xe5, 0xe7, 0xe1, 0xe3, 0xe5, 0xe7
	.data8	0xe1, 0xe3, 0xe5, 0xe7, 0xe1, 0xe3, 0xe5, 0xe7, 0xe1, 0xe3, 0xe5, 0xe7, 0xe1, 0xe3, 0xe5, 0xe7
	.data8	0xc1, 0xc3, 0xc5, 0xc7, 0xc1, 0xc3, 0xc5, 0xc7, 0xc1, 0xc3, 0xc5, 0xc7, 0xc1, 0xc3, 0xc5, 0xc7
	.data8	0xc1, 0xc3, 0xc5, 0xc7, 0xc1, 0xc3, 0xc5, 0xc7, 0xc1, 0xc3, 0xc5, 0xc7, 0xc1, 0xc3, 0xc5, 0xc7

IO__SR3:
	.fill	8, 0x00
	.fill	8, 0x01
	.fill	8, 0x02
	.fill	8, 0x03
	.fill	8, 0x04
	.fill	8, 0x05
	.fill	8, 0x06
	.fill	8, 0x07
	.fill	8, 0x08
	.fill	8, 0x09
	.fill	8, 0x0a
	.fill	8, 0x0b
	.fill	8, 0x0c
	.fill	8, 0x0d
	.fill	8, 0x0e
	.fill	8, 0x0f
	.fill	8, 0x10
	.fill	8, 0x11
	.fill	8, 0x12
	.fill	8, 0x13
	.fill	8, 0x14
	.fill	8, 0x15
	.fill	8, 0x16
	.fill	8, 0x17
	.fill	8, 0x18
	.fill	8, 0x19
	.fill	8, 0x1a
	.fill	8, 0x1b
	.fill	8, 0x1c
	.fill	8, 0x1d
	.fill	8, 0x1e
	.fill	8, 0x1f
