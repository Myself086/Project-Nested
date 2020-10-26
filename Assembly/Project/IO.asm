
	// ---------------------------------------------------------------------------
	
	.mx	0x30
	
IO__Error:
	rtl

	// ---------------------------------------------------------------------------

	// PPUCTRL	 	$2000 	VPHB SINN 	NMI enable (V), PPU master/slave (P), sprite height (H), background tile select (B), sprite tile select (S), increment mode (I), nametable select (NN)
	// PPUMASK		$2001 	BGRs bMmG 	color emphasis (BGR), sprite enable (s), background enable (b), sprite left column enable (M), background left column enable (m), greyscale (G)
	// PPUSTATUS 	$2002 	VSO- ---- 	vblank (V), sprite 0 hit (S), sprite overflow (O), read resets write pair for $2005/2006
	// OAMADDR		$2003 	aaaa aaaa 	OAM read/write address
	// OAMDATA		$2004 	dddd dddd 	OAM data read/write
	// PPUSCROLL	$2005 	xxxx xxxx 	fine scroll position (two writes: X, Y)
	// PPUADDR		$2006 	aaaa aaaa 	PPU read/write address (two writes: MSB, LSB)
	// PPUDATA		$2007 	dddd dddd 	PPU data read/write
	// OAMDMA	 	$4014 	aaaa aaaa 	OAM DMA high address 
	
	.mx	0x30
	
IO__r2000_a:
IO__r2000_x:
IO__r2000_y:
	rtl

IO__w2000_x:
	stx	$_IO_2000
	bra	$+IO__w2000_in
IO__w2000_y:
	sty	$_IO_2000
	bra	$+IO__w2000_in
IO__w2000_a:
	sta	$_IO_2000
IO__w2000_in:
	php
	xba

	lda	$_IO_2000
	bit	#0x04
	bne	$+IO__w2000_a_inc32
		// Change name tables
		and	#0x03
		sta	$_PPU_SCROLL_X+1
		lsr	a
		sta	$_PPU_SCROLL_Y+1

		// Inc 1
		lda	#.VramQ_PpuAddrInc
		lock
		sta	$0x2180
		lda	#0x01
		sta	$0x2180
		sta	$_IO_PPUADDR_INC

		xba
		plp
		rtl

IO__w2000_a_inc32:
		// Change name tables
		and	#0x03
		sta	$_PPU_SCROLL_X+1
		lsr	a
		sta	$_PPU_SCROLL_Y+1

		// Inc 32
		lda	#.VramQ_PpuAddrInc
		lock
		sta	$0x2180
		lda	#0x20
		sta	$0x2180
		sta	$_IO_PPUADDR_INC

		xba
		plp
		rtl


IO__r2001_a:
IO__r2001_x:
IO__r2001_y:
	rtl
IO__w2001_a:
	sta	$_IO_2001
	rtl
IO__w2001_x:
	stx	$_IO_2001
	rtl
IO__w2001_y:
	sty	$_IO_2001
	rtl


IO__r2002_a:
IO__r2002_x:
IO__r2002_y:
	php
	pha

	stz	$_IO_HILO

	// Did we hit sprite 0?
	lda	$3,s
	cmp	$_IO_2002_LastReturn
	bne	$+IO__r2002_NewCall
	lda	$4,s
	sbc	$_IO_2002_LastReturn+1
	bne	$+IO__r2002_NewCall

		// Increment and compare with 3 to set bit 6, assuming A==0 and carry set from cmp+!bne
		inc	$_IO_2002_CallCount
		adc	$_IO_2002_CallCount
		adc	#0x3c
		and	#0x40

		beq	$+IO__r2002_NoSprite0
			stz	$_IO_2002_CallCount
			ora	$_IO_2002
			eor	#0x80
			sta	$_IO_2002
			sta	$_IO_Temp

			// Change scanline to sprite 0
			lda	$_Sprite0Line
			sta	$_Scanline

			// Add new HDMA coordinates
			phx
			phy
			rep	#0x10
			.mx	0x20

			.vstack		_VSTACK_START
			call	Hdma__UpdateScrolling

			// Change mode back
			sep	#0x30
			.mx	0x30

			ply
			plx
			pla
			plp
			rtl

IO__r2002_NoSprite0:
		ora	$_IO_2002
		and	#0xbf
		eor	#0x80
		sta	$_IO_2002
		sta	$_IO_Temp

		pla
		plp
		rtl

IO__r2002_NewCall:
	lda	$3,s
	sta	$_IO_2002_LastReturn
	lda	$4,s
	sta	$_IO_2002_LastReturn+1

	stz	$_IO_2002_CallCount

	lda	$_IO_2002
	and	#0xbf
	eor	#0x80
	sta	$_IO_2002
	sta	$_IO_Temp
	
	pla
	plp
	rtl

IO__w2002_a:
	rtl
IO__w2002_x:
	rtl
IO__w2002_y:
	rtl

	
IO__r2003_a:
IO__r2003_x:
IO__r2003_y:
	rtl
IO__w2003_a:
	rtl
IO__w2003_x:
	rtl
IO__w2003_y:
	rtl


IO__r2004_a:
IO__r2004_x:
IO__r2004_y:
	rtl
IO__w2004_a:
	rtl
IO__w2004_x:
	rtl
IO__w2004_y:
	rtl

	
IO__r2005_a:
IO__r2005_x:
IO__r2005_y:
	rtl

	.macro	IO__w2005_Mac	reg
		php

		bit	$_IO_HILO
		bmi	$+b_high
b_low:
			sec
			ror	$_IO_HILO

			st{0}	$_PPU_SCROLL_X

			plp
			rtl
b_high:
			stz	$_IO_HILO

			st{0}	$_PPU_SCROLL_Y

			plp
			rtl
	.endm

IO__w2005_a:
	IO__w2005_Mac	a
IO__w2005_x:
	IO__w2005_Mac	x
IO__w2005_y:
	IO__w2005_Mac	y


IO__r2006_a:
IO__r2006_x:
IO__r2006_y:
	rtl
IO__w2006_y:
	sty	$_IO_Temp
	bra	$+b_in
IO__w2006_x:
	stx	$_IO_Temp
	bra	$+b_in
IO__w2006_a:
	sta	$_IO_Temp
b_in:
	php
	phx
	xba

	lock
	lda	$_IO_HILO
	bpl	$+b_high
b_low:
		// Write 2
		stz	$_IO_HILO

		lda	#.VramQ_PpuAddrLow
		sta	$0x2180

		ldx	$_IO_Temp
		stx	$_IO_PPUADDR+0
		stx	$0x2180

		// Change scroll values (also transfer new scroll values)
		lda	$_PPU_SCROLL_Y
		and	#0xc7
		ora	$=IO__w2006_SR2AND38,x
		sta	$_PPU_SCROLL_Y
		sta	$_IO_SCROLL_Y

		lda	$_PPU_SCROLL_X
		and	#0x07
		ora	$=IO__w2006_SL3,x
		sta	$_PPU_SCROLL_X
		sta	$_IO_SCROLL_X

		lda	$_PPU_SCROLL_X+1
		sta	$_IO_SCROLL_X+1
		lsr	a
		sta	$_IO_SCROLL_Y+1

		xba
		plx
		plp
		rtl
b_high:
		// Write 1
		ora	#0x80
		sta	$_IO_HILO

		lda	#.VramQ_PpuAddrHigh
		sta	$0x2180

		lda	$_IO_Temp
		and	#0x3f
		tax
		stx	$_IO_PPUADDR+1
		stx	$0x2180

		// Change scroll values
		lda	$_PPU_SCROLL_Y
		and	#0x38
		ora	$=IO__w2006_SR4AND03,x
		ora	$=IO__w2006_SL6,x
		sta	$_PPU_SCROLL_Y

		lda	$=IO__w2006_SR2AND03,x
		sta	$_PPU_SCROLL_X+1
		lsr	a
		sta	$_PPU_SCROLL_Y+1

		xba
		plx
		plp
		rtl

IO__w2006_SR4AND03:
	.fill	0x10, 0
	.fill	0x10, 1
	.fill	0x10, 2
	.fill	0x10, 3
	.fill	0x10, 0
	.fill	0x10, 1
	.fill	0x10, 2
	.fill	0x10, 3
	.fill	0x10, 0
	.fill	0x10, 1
	.fill	0x10, 2
	.fill	0x10, 3
	.fill	0x10, 0
	.fill	0x10, 1
	.fill	0x10, 2
	.fill	0x10, 3

IO__w2006_SR2AND03:
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3

IO__w2006_SL6:
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0

IO__w2006_SL3:
	.data8	0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38, 0x40, 0x48, 0x50, 0x58, 0x60, 0x68, 0x70, 0x78, 0x80, 0x88, 0x90, 0x98, 0xa0, 0xa8, 0xb0, 0xb8, 0xc0, 0xc8, 0xd0, 0xd8, 0xe0, 0xe8, 0xf0, 0xf8
	.data8	0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38, 0x40, 0x48, 0x50, 0x58, 0x60, 0x68, 0x70, 0x78, 0x80, 0x88, 0x90, 0x98, 0xa0, 0xa8, 0xb0, 0xb8, 0xc0, 0xc8, 0xd0, 0xd8, 0xe0, 0xe8, 0xf0, 0xf8
	.data8	0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38, 0x40, 0x48, 0x50, 0x58, 0x60, 0x68, 0x70, 0x78, 0x80, 0x88, 0x90, 0x98, 0xa0, 0xa8, 0xb0, 0xb8, 0xc0, 0xc8, 0xd0, 0xd8, 0xe0, 0xe8, 0xf0, 0xf8
	.data8	0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38, 0x40, 0x48, 0x50, 0x58, 0x60, 0x68, 0x70, 0x78, 0x80, 0x88, 0x90, 0x98, 0xa0, 0xa8, 0xb0, 0xb8, 0xc0, 0xc8, 0xd0, 0xd8, 0xe0, 0xe8, 0xf0, 0xf8
	.data8	0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38, 0x40, 0x48, 0x50, 0x58, 0x60, 0x68, 0x70, 0x78, 0x80, 0x88, 0x90, 0x98, 0xa0, 0xa8, 0xb0, 0xb8, 0xc0, 0xc8, 0xd0, 0xd8, 0xe0, 0xe8, 0xf0, 0xf8
	.data8	0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38, 0x40, 0x48, 0x50, 0x58, 0x60, 0x68, 0x70, 0x78, 0x80, 0x88, 0x90, 0x98, 0xa0, 0xa8, 0xb0, 0xb8, 0xc0, 0xc8, 0xd0, 0xd8, 0xe0, 0xe8, 0xf0, 0xf8
	.data8	0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38, 0x40, 0x48, 0x50, 0x58, 0x60, 0x68, 0x70, 0x78, 0x80, 0x88, 0x90, 0x98, 0xa0, 0xa8, 0xb0, 0xb8, 0xc0, 0xc8, 0xd0, 0xd8, 0xe0, 0xe8, 0xf0, 0xf8
	.data8	0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38, 0x40, 0x48, 0x50, 0x58, 0x60, 0x68, 0x70, 0x78, 0x80, 0x88, 0x90, 0x98, 0xa0, 0xa8, 0xb0, 0xb8, 0xc0, 0xc8, 0xd0, 0xd8, 0xe0, 0xe8, 0xf0, 0xf8

IO__w2006_SR2AND38:
	.fill	0x20, 0x00
	.fill	0x20, 0x08
	.fill	0x20, 0x10
	.fill	0x20, 0x18
	.fill	0x20, 0x20
	.fill	0x20, 0x28
	.fill	0x20, 0x30
	.fill	0x20, 0x38


IO__r2007_a:
IO__r2007_x:
IO__r2007_y:
	php
	pha

	// Queue a dummy read
	lda	#.VramQ_Read
	sta	$0x2180

	// Return last byte read
	lda	$_IO_2007r
	sta	$_IO_Temp

	// Load higher bits of address
	lda	$_IO_PPUADDR+1

	// Is it CHR banks?
	cmp	#0x20
	bcs	$+b_1
		phx
		phy

		// Is this game using CHR RAM?
		ldx	$_CHR_0_PageLength
		trapeq
		Exception	"Reading CHR RAM{}{}{}CPU reading CHR RAM isn't supported yet."

		// Push bank only for CHR ROM
		phb

		// Which page are we in? Keep carry set during the loop
		ldy	#0xff
		sec
b_loop:
			iny
			sbc	$_CHR_0_PageLength,y
			bcs	$-b_loop

		// Go back by 1 index, assume carry clear from BCS
		adc	$_CHR_0_PageLength,y

		// Push incomplete address to stack
		pha
		lda	$_IO_PPUADDR
		pha

		// Load CHR page and bank
		lda	$_CHR_0_NesBank,y
		tax
		lda	$=RomInfo_ChrBankLut_hi,x
		pha
		plb
		lda	$=RomInfo_ChrBankLut_lo,x
		clc
		adc	$2,s
		sta	$2,s

		// Read byte
		ldy	#0
		lda	($1,s),y

		// Clear pointer and restore DB
		ply
		ply
		plb

		sta	$_IO_2007r

		// Increment address
		lda	$_IO_PPUADDR
		clc
		adc	$_IO_PPUADDR_INC
		sta	$_IO_PPUADDR
		bcc	$+b_2
			inc	$_IO_PPUADDR+1
b_2:

		ply
		plx
		pla
		plp
		rtl
b_1:

	// Is it name tables?
	cmp	#0x30
	bcs	$+IO__r2007_skip20
		phx

		rep	#0x11
		.mx	0x20

		ldx	$_IO_PPUADDR
		lda	$=Nes_Nametables-0x2000,x
		sta	$_IO_2007r

		// Increment address
		txa
		adc	$_IO_PPUADDR_INC
		sta	$_IO_PPUADDR

		sep	#0x30
		.mx	0x30

		plx
		pla
		plp
		rtl
IO__r2007_skip20:

	// Is it palette?
	cmp	#0x3f
	bne	$+IO__r2007_skip3f
		phx

		ldx	$_IO_PPUADDR
		lda	$_PaletteNes,x
		// Immediate return instead of next read
		sta	$_IO_Temp

		// Increment address
		txa
		clc
		adc	$_IO_PPUADDR_INC
		sta	$_IO_PPUADDR

		plx
		pla
		plp
		rtl
IO__r2007_skip3f:

	pla
	plp
	rtl

IO__w2007_y:
	sty	$_IO_Temp
	bra	$+IO__w2007_In
IO__w2007_x:
	stx	$_IO_Temp
	bra	$+IO__w2007_In
IO__w2007_a:
	sta	$_IO_Temp
	//bra	$+IO__w2007_In

IO__w2007_In:
	php
	pha

	// TODO: Properly fix port 2002 shortcut
	stz	$_IO_2002_LastReturn+1

	// Load higher bits of address
	lda	$_IO_PPUADDR+1
	and	#0x3f

	// Is it CHR banks?
	cmp	#0x20
	bcs	$+IO__w2007_skip00
		// Write to CHR banks (TODO: Check if it is CHR RAM)
		lda	#.VramQ_Tile
		lock
		sta	$0x2180
		lda	$_IO_Temp
		sta	$0x2180

		pla
		plp
		rtl

IO__w2007_skip00:

	// Is it name tables?
	eor	#0x20
	cmp	#0x10
	bcs	$+IO__w2007_skip20
		phx

		rep	#0x10
		.mx	0x20

		lda	$_IO_Temp
		ldx	$_IO_PPUADDR
		cmp	$=Nes_Nametables-0x2000,x
		beq	$+IO__w2007_NoChanges_16bit
		sta	$=Nes_Nametables-0x2000,x

		rep	#0x31
		.mx	0x00

		// Is it attribute?
		txa
		and	#0x03c0
		eor	#0x03c0
		bne	$+IO__w2007_skipAttribute
			txa
			adc	$_IO_PPUADDR_INC
			sta	$_IO_PPUADDR

			sep	#0x34
			.mx	0x30

			// Write to queue
			lda	#.VramQ_TileAttribute
			//lock
			sta	$0x2180
			lda	$_IO_Temp
			sta	$0x2180

			plx
			pla
			plp
			rtl
IO__w2007_skipAttribute:
		.mx	0x00

		txa
		adc	$_IO_PPUADDR_INC
		sta	$_IO_PPUADDR

		sep	#0x34
		.mx	0x30

		// Write to queue
		lda	#.VramQ_Tile
		//lock
		sta	$0x2180
		lda	$_IO_Temp
		sta	$0x2180

		plx
		pla
		plp
		rtl
		
IO__w2007_NoChanges_16bit:
			rep	#0x31
			.mx	0x00

			txa
			adc	$_IO_PPUADDR_INC
			sta	$_IO_PPUADDR

			sep	#0x30
			.mx	0x30

			// Value written is unchanged, queue a dummy read instead
			lda	#.VramQ_Read
			sta	$0x2180

			plx
			pla
			plp
			rtl

IO__w2007_NoChanges:
			// Value written is unchanged, queue a dummy read instead
			lda	#.VramQ_Read
			sta	$0x2180

			// Increment address
			lda	$_IO_PPUADDR
			clc
			adc	$_IO_PPUADDR_INC
			sta	$_IO_PPUADDR

			plx
			pla
			plp
			rtl

IO__w2007_skip20:

	// Is it palette?
	lda	$_IO_PPUADDR+1
	and	#0x3f
	cmp	#0x3f
	bne	$+IO__w2007_skip3f
		phx

		lda	$_IO_Temp
		ldx	$_IO_PPUADDR
		cmp	$_PaletteNes,x
		beq	$-IO__w2007_NoChanges
		sta	$_PaletteNes,x

		rep	#0x31
		.mx	0x00

		lda	$_IO_PPUADDR
		adc	$_IO_PPUADDR_INC
		sta	$_IO_PPUADDR

		sep	#0x34
		.mx	0x30

		// Write to queue
		lda	#.VramQ_Palette
		//lock
		sta	$0x2180
		lda	$_IO_Temp
		asl	a
		sta	$0x2180

		plx
		pla
		plp
		rtl
IO__w2007_skip3f:

	// Return
	pla
	plp
	rtl

	
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
IO__r4014_a:
IO__r4014_x:
IO__r4014_y:
	stz	$_IO_Temp
	rtl
IO__w4014_x:
	stx	$_IO_Temp
	bra	$+IO__w4014_In
IO__w4014_y:
	sty	$_IO_Temp
	bra	$+IO__w4014_In
IO__w4014_a:
	sta	$_IO_Temp
	//bra	$+IO__w4014_In
	
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
	beq	$+IO__w4014_8x8
		jmp	$_IO__w4014_8x16
IO__w4014_8x8:

	// Sprite limit?
	lda	$=RomInfo_SpriteLimit
	bpl	$+IO__w4014_8x8_nolimit
		jmp	$_IO__w4014_8x8_limit

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
	lda	#_Sprites_Buffer+0x0ff
	tcs

	// Change mode
	.mx	0x30
	sep	#0x30

	// Nes:  Y, T, A, X
	// Snes: X, Y, T, A

	// Which sprite bank to use?
	lda	$_IO_2000_EarlyValue
	lsr	a
	lsr	a
	lsr	a
	eor	$_IO_MapperChrBankSwap
	and	#0x01
	sta	$_IO_Temp

	// Update sprite 0 hit, assume carry clear from LSR
	lda	$0x00
	adc	$=RomInfo_SpriteZeroOffset
	bcc	$+b_1
		lda	#0xf0
b_1:
	sta	$_Sprite0Line

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

	// Are extra sprites already loaded?
	bit	$_IO_4014_SpriteSize
	bpl	$+b_1
		// Change mode
		.mx	0x00
		rep	#0x30

		// Clear the second half of sprite memory and extra bits
		lda	#0xf000
		ldx	#0x001c
b_loop:
			sta	$_Sprites_Buffer+0x100,x
			sta	$_Sprites_Buffer+0x120,x
			sta	$_Sprites_Buffer+0x140,x
			sta	$_Sprites_Buffer+0x160,x
			sta	$_Sprites_Buffer+0x180,x
			sta	$_Sprites_Buffer+0x1a0,x
			sta	$_Sprites_Buffer+0x1c0,x
			sta	$_Sprites_Buffer+0x1e0,x
			stz	$_Sprites_Buffer+0x200,x
			dex
			dex
			dex
			dex
			bpl	$-b_loop

		// Change mode
		.mx	0x30
		sep	#0x30
b_1:

	// Queue sprite DMA (TODO: No priority transfer)
	lda	#.VramQ_SpriteXfer8x8
	sta	$0x2180
	tsc
	inc	a
	lsr	a
	sta	$0x2180

	// Change mode
	.mx	0x20
	rep	#0x10

	// Save sprite size
	stz	$_IO_4014_SpriteSize

	// Fill remaining space in the sprite buffer
	tsx
	lda	#0xf0
	jmp	($_IO__w4014_FillSwitch+1-Sprites_Buffer,x)


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

	// Which sprite bank to use?
	lda	$_IO_2000_EarlyValue
	lsr	a
	lsr	a
	lsr	a
	eor	$_IO_MapperChrBankSwap
	and	#0x01
	sta	$_IO_Temp

	// Update sprite 0 hit, assume carry clear from LSR
	lda	$0x00
	adc	$=RomInfo_SpriteZeroOffset
	bcc	$+b_1
		lda	#0xf0
b_1:
	sta	$_Sprite0Line

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
IO__w4014_8x16:

	// Sprite limit?
	lda	$=RomInfo_SpriteLimit
	bpl	$+IO__w4014_8x16_nolimit
		jmp	$_IO__w4014_8x16_limit

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
	adc	$=RomInfo_SpriteZeroOffset
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

	// Queue sprite DMA (TODO: No priority transfer)
	lda	#.VramQ_SpriteXfer8x8
	sta	$0x2180
	tsc
	inc	a
	lsr	a
	sta	$0x2180

	// Change mode
	.mx	0x20
	rep	#0x10

	// Save sprite size and fill remaining space in the sprite buffer
	tsx
	lda	#0xf0
	sta	$_IO_4014_SpriteSize
	jmp	($_IO__w4014_FillSwitch+1-Sprites_Buffer,x)


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
	adc	$=RomInfo_SpriteZeroOffset
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
	bne	$+b_1
		// No sprite on screen
		ldy	#.VramQ_SpriteXferEmpty
		sty	$0x2180
		bra	$+b_2
b_1:
		ldy	#.VramQ_SpriteXfer8x16
		sty	$0x2180
		stx	$0x2180
b_2:

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

	// Save sprite size, write any non-zero value for 8x16
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

	// ---------------------------------------------------------------------------
	// Sound registers

IO__w4000_Switch_Trap:
	trap
	Exception	"IO Index Failed{}{}{}A direct indexed IO access in page 0x40 failed."

IO__w4000_Switch:
	switch		0x80, IO__w4000_Switch_Trap, IO__w4000_Switch_Trap
		caseat	0x00, IO__w4000_ind
		caseat	0x01, IO__w4001_ind
		caseat	0x02, IO__w4002_ind
		caseat	0x03, IO__w4003_ind
		caseat	0x04, IO__w4004_ind
		caseat	0x05, IO__w4005_ind
		caseat	0x06, IO__w4006_ind
		caseat	0x07, IO__w4007_ind
		caseat	0x08, IO__w4008_ind
		caseat	0x09, IO__w4009_ind
		caseat	0x0a, IO__w400a_ind
		caseat	0x0b, IO__w400b_ind
		caseat	0x0c, IO__w400c_ind
		caseat	0x0d, IO__w400d_ind
		caseat	0x0e, IO__w400e_ind
		caseat	0x0f, IO__w400f_ind
		caseat	0x10, IO__w4010_ind
		caseat	0x11, IO__w4011_ind
		caseat	0x12, IO__w4012_ind
		caseat	0x13, IO__w4013_ind
		caseat	0x15, IO__w4015_ind

	.macro	IO_w40xx		offset, indexReg
		php
		phx
		xba

		//lda	$_Addition+{0},{1}
		t{1}a
		asl	a
		tax
		jmp	($_IO__w4000_Switch+{0}*2,x)
	.endm
	.macro	IO_w40xx_Return
		plx
		plp
		rtl
	.endm

IO__w4000_a_x:		IO_w40xx	0x00, x
IO__w4000_a_y:		IO_w40xx	0x00, y
IO__w4001_a_x:		IO_w40xx	0x01, x
IO__w4001_a_y:		IO_w40xx	0x01, y
IO__w4002_a_x:		IO_w40xx	0x02, x
IO__w4002_a_y:		IO_w40xx	0x02, y
IO__w4003_a_x:		IO_w40xx	0x03, x
IO__w4003_a_y:		IO_w40xx	0x03, y
IO__w4004_a_x:		IO_w40xx	0x04, x
IO__w4004_a_y:		IO_w40xx	0x04, y
IO__w4005_a_x:		IO_w40xx	0x05, x
IO__w4005_a_y:		IO_w40xx	0x05, y
IO__w4006_a_x:		IO_w40xx	0x06, x
IO__w4006_a_y:		IO_w40xx	0x06, y
IO__w4007_a_x:		IO_w40xx	0x07, x
IO__w4007_a_y:		IO_w40xx	0x07, y
IO__w4008_a_x:		IO_w40xx	0x08, x
IO__w4008_a_y:		IO_w40xx	0x08, y
IO__w4009_a_x:		IO_w40xx	0x09, x
IO__w4009_a_y:		IO_w40xx	0x09, y
IO__w400a_a_x:		IO_w40xx	0x0a, x
IO__w400a_a_y:		IO_w40xx	0x0a, y
IO__w400b_a_x:		IO_w40xx	0x0b, x
IO__w400b_a_y:		IO_w40xx	0x0b, y
IO__w400c_a_x:		IO_w40xx	0x0c, x
IO__w400c_a_y:		IO_w40xx	0x0c, y
IO__w400d_a_x:		IO_w40xx	0x0d, x
IO__w400d_a_y:		IO_w40xx	0x0d, y
IO__w400e_a_x:		IO_w40xx	0x0e, x
IO__w400e_a_y:		IO_w40xx	0x0e, y
IO__w400f_a_x:		IO_w40xx	0x0f, x
IO__w400f_a_y:		IO_w40xx	0x0f, y
IO__w4010_a_x:		IO_w40xx	0x10, x
IO__w4010_a_y:		IO_w40xx	0x10, y
IO__w4011_a_x:		IO_w40xx	0x11, x
IO__w4011_a_y:		IO_w40xx	0x11, y
IO__w4012_a_x:		IO_w40xx	0x12, x
IO__w4012_a_y:		IO_w40xx	0x12, y
IO__w4013_a_x:		IO_w40xx	0x13, x
IO__w4013_a_y:		IO_w40xx	0x13, y

IO__r4000_a:
IO__r4000_x:
IO__r4000_y:
	rtl

IO__w4000_ind:
	xba
	sta	$_Sound_NesRegs+0x0
	IO_w40xx_Return
IO__w4000_a:
	sta	$_Sound_NesRegs+0x0
	rtl
IO__w4000_x:
	stx	$_Sound_NesRegs+0x0
	rtl
IO__w4000_y:
	sty	$_Sound_NesRegs+0x0
	rtl


IO__r4001_a:
IO__r4001_x:
IO__r4001_y:
	rtl

IO__w4001_ind:
	lda	#0x40
	tsb	$_Sound_NesRegs+0x16
	xba
	sta	$_Sound_NesRegs+0x1
	IO_w40xx_Return
IO__w4001_x:
	stx	$_Sound_NesRegs+0x1
	bra	$+b_in
IO__w4001_y:
	sty	$_Sound_NesRegs+0x1
	bra	$+b_in
IO__w4001_a:
	sta	$_Sound_NesRegs+0x1
b_in:
	php
	xba
	lda	#0x40
	tsb	$_Sound_NesRegs+0x16
	xba
	// TODO: Sweep compare
//	lda	$_Sound_NesRegs+0x1
//b_
	plp
	rtl


IO__r4002_a:
IO__r4002_x:
IO__r4002_y:
	rtl

IO__w4002_ind:
	xba
	sta	$_Sound_NesRegs+0x2
	sta	$_Sound_CopyRegs+0x2
	IO_w40xx_Return
IO__w4002_a:
	sta	$_Sound_NesRegs+0x2
	sta	$_Sound_CopyRegs+0x2
	rtl
IO__w4002_x:
	stx	$_Sound_NesRegs+0x2
	stx	$_Sound_CopyRegs+0x2
	rtl
IO__w4002_y:
	sty	$_Sound_NesRegs+0x2
	sty	$_Sound_CopyRegs+0x2
	rtl


IO__r4003_a:
IO__r4003_x:
IO__r4003_y:
	rtl

IO__w4003_ind:
	xba
	sta	$_Sound_NesRegs+0x3
	sta	$_Sound_CopyRegs+0x3
	tax
	lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
	sta	$_Sound_square0_length
	lda	#0x01
	tsb	$_Sound_CopyRegs+0x15
	tsb	$_Sound_NesRegs+0x16
	txa
	IO_w40xx_Return
IO__w4003_x:
	stx	$_Sound_NesRegs+0x3
	stx	$_Sound_CopyRegs+0x3
	bra	$+b_in
IO__w4003_y:
	sty	$_Sound_NesRegs+0x3
	sty	$_Sound_CopyRegs+0x3
	bra	$+b_in
IO__w4003_a:
	sta	$_Sound_NesRegs+0x3
	sta	$_Sound_CopyRegs+0x3
b_in:
	php
	phx
	xba
	ldx	$_Sound_CopyRegs+0x3
	lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
	sta	$_Sound_square0_length
	lda	#0x01
	tsb	$_Sound_CopyRegs+0x15
	tsb	$_Sound_NesRegs+0x16
	xba
	plx
	plp
	rtl


IO__r4004_a:
IO__r4004_x:
IO__r4004_y:
	rtl

IO__w4004_ind:
	xba
	sta	$_Sound_NesRegs+0x4
	IO_w40xx_Return
IO__w4004_a:
	sta	$_Sound_NesRegs+0x4
	rtl
IO__w4004_x:
	stx	$_Sound_NesRegs+0x4
	rtl
IO__w4004_y:
	sty	$_Sound_NesRegs+0x4
	rtl


IO__r4005_a:
IO__r4005_x:
IO__r4005_y:
	rtl

IO__w4005_ind:
	lda	#0x80
	tsb	$_Sound_NesRegs+0x16
	xba
	sta	$_Sound_NesRegs+0x5
	IO_w40xx_Return
IO__w4005_x:
	stx	$_Sound_NesRegs+0x5
	bra	$+b_in
IO__w4005_y:
	sty	$_Sound_NesRegs+0x5
	bra	$+b_in
IO__w4005_a:
	sta	$_Sound_NesRegs+0x5
b_in:
	php
	xba
	lda	#0x80
	tsb	$_Sound_NesRegs+0x16
	xba
	// TODO: Sweep compare
//	lda	$_Sound_NesRegs+0x5
//b_
	plp
	rtl


IO__r4006_a:
IO__r4006_x:
IO__r4006_y:
	rtl

IO__w4006_ind:
	xba
	sta	$_Sound_NesRegs+0x6
	sta	$_Sound_CopyRegs+0x6
	IO_w40xx_Return
IO__w4006_a:
	sta	$_Sound_NesRegs+0x6
	sta	$_Sound_CopyRegs+0x6
	rtl
IO__w4006_x:
	stx	$_Sound_NesRegs+0x6
	stx	$_Sound_CopyRegs+0x6
	rtl
IO__w4006_y:
	sty	$_Sound_NesRegs+0x6
	sty	$_Sound_CopyRegs+0x6
	rtl


IO__r4007_a:
IO__r4007_x:
IO__r4007_y:
	rtl

IO__w4007_ind:
	xba
	sta	$_Sound_NesRegs+0x7
	sta	$_Sound_CopyRegs+0x7
	tax
	lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
	sta	$_Sound_square1_length
	lda	#0x02
	tsb	$_Sound_CopyRegs+0x15
	tsb	$_Sound_NesRegs+0x16
	txa
	IO_w40xx_Return
IO__w4007_x:
	stx	$_Sound_NesRegs+0x7
	stx	$_Sound_CopyRegs+0x7
	bra	$+b_in
IO__w4007_y:
	sty	$_Sound_NesRegs+0x7
	sty	$_Sound_CopyRegs+0x7
	bra	$+b_in
IO__w4007_a:
	sta	$_Sound_NesRegs+0x7
	sta	$_Sound_CopyRegs+0x7
b_in:
	php
	phx
	xba
	ldx	$_Sound_NesRegs+0x7
	lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
	sta	$_Sound_square1_length
	lda	#0x02
	tsb	$_Sound_CopyRegs+0x15
	tsb	$_Sound_NesRegs+0x16
	xba
	plx
	plp
	rtl


IO__r4008_a:
IO__r4008_x:
IO__r4008_y:
	rtl

IO__w4008_ind:
	//lda	#0x04
	//tsb	$_Sound_NesRegs+0x16
	xba
	sta	$_Sound_NesRegs+0x8
	IO_w40xx_Return
IO__w4008_x:
	stx	$_Sound_NesRegs+0x8
	bra	$+b_in
IO__w4008_y:
	sty	$_Sound_NesRegs+0x8
	bra	$+b_in
IO__w4008_a:
	sta	$_Sound_NesRegs+0x8
b_in:
	php
	xba
	//lda	#0x04
	//tsb	$_Sound_NesRegs+0x16
	xba
	plp
	rtl


IO__r4009_a:
IO__r4009_x:
IO__r4009_y:
	rtl

IO__w4009_ind:
	xba
	sta	$_Sound_NesRegs+0x9
	IO_w40xx_Return
IO__w4009_a:
	sta	$_Sound_NesRegs+0x9
	rtl
IO__w4009_x:
	stx	$_Sound_NesRegs+0x9
	rtl
IO__w4009_y:
	sty	$_Sound_NesRegs+0x9
	rtl


IO__r400a_a:
IO__r400a_x:
IO__r400a_y:
	rtl

IO__w400a_ind:
	xba
	sta	$_Sound_NesRegs+0xa
	IO_w40xx_Return
IO__w400a_a:
	sta	$_Sound_NesRegs+0xa
	rtl
IO__w400a_x:
	stx	$_Sound_NesRegs+0xa
	rtl
IO__w400a_y:
	sty	$_Sound_NesRegs+0xa
	rtl


IO__r400b_a:
IO__r400b_x:
IO__r400b_y:
	rtl

IO__w400b_ind:
	xba
	sta	$_Sound_NesRegs+0xb
	sta	$_Sound_CopyRegs+0xb
	bra	$+b_in2
IO__w400b_x:
	stx	$_Sound_NesRegs+0xb
	stx	$_Sound_CopyRegs+0xb
	bra	$+b_in
IO__w400b_y:
	sty	$_Sound_NesRegs+0xb
	sty	$_Sound_CopyRegs+0xb
	bra	$+b_in
IO__w400b_a:
	sta	$_Sound_NesRegs+0xb
	sta	$_Sound_CopyRegs+0xb
b_in:
	php
	phx
b_in2:
	xba

	lda	#0x04
	tsb	$_Sound_NesRegs+0x16
	tsb	$_Sound_CopyRegs+0x15

	ldx	$_Sound_CopyRegs+0xb
	lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
	sta	$_Sound_triangle_length

	xba
	plx
	plp
	rtl


IO__r400c_a:
IO__r400c_x:
IO__r400c_y:
	rtl

IO__w400c_ind:
	xba
	sta	$_Sound_NesRegs+0xc
	IO_w40xx_Return
IO__w400c_a:
	sta	$_Sound_NesRegs+0xc
	rtl
IO__w400c_x:
	stx	$_Sound_NesRegs+0xc
	rtl
IO__w400c_y:
	sty	$_Sound_NesRegs+0xc
	rtl


IO__r400d_a:
IO__r400d_x:
IO__r400d_y:
	rtl

IO__w400d_ind:
	xba
	sta	$_Sound_NesRegs+0xd
	IO_w40xx_Return
IO__w400d_a:
	sta	$_Sound_NesRegs+0xd
	rtl
IO__w400d_x:
	stx	$_Sound_NesRegs+0xd
	rtl
IO__w400d_y:
	sty	$_Sound_NesRegs+0xd
	rtl


IO__r400e_a:
IO__r400e_x:
IO__r400e_y:
	rtl

IO__w400e_ind:
	xba
	sta	$_Sound_NesRegs+0xe
	IO_w40xx_Return
IO__w400e_a:
	sta	$_Sound_NesRegs+0xe
	rtl
IO__w400e_x:
	stx	$_Sound_NesRegs+0xe
	rtl
IO__w400e_y:
	sty	$_Sound_NesRegs+0xe
	rtl


IO__r400f_a:
IO__r400f_x:
IO__r400f_y:
	rtl

IO__w400f_ind:
	xba
	sta	$_Sound_NesRegs+0xf
	sta	$_Sound_CopyRegs+0xf
	tax
	lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
	sta	$_Sound_noise_length
	lda	#0x08
	tsb	$_Sound_CopyRegs+0x15
	txa
	IO_w40xx_Return
IO__w400f_x:
	stx	$_Sound_NesRegs+0xf
	stx	$_Sound_CopyRegs+0xf
	bra	$+b_in
IO__w400f_y:
	sty	$_Sound_NesRegs+0xf
	sty	$_Sound_CopyRegs+0xf
	bra	$+b_in
IO__w400f_a:
	sta	$_Sound_NesRegs+0xf
	sta	$_Sound_CopyRegs+0xf
b_in:
	php
	phx
	xba
	ldx	$_Sound_CopyRegs+0xf
	lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
	sta	$_Sound_noise_length
	lda	#0x08
	tsb	$_Sound_CopyRegs+0x15
	xba
	plx
	plp
	rtl


IO__r4010_a:
IO__r4010_x:
IO__r4010_y:
	rtl

IO__w4010_ind:
	xba
	sta	$_Sound_NesRegs+0x10
	IO_w40xx_Return
IO__w4010_a:
	sta	$_Sound_NesRegs+0x10
	rtl
IO__w4010_x:
	stx	$_Sound_NesRegs+0x10
	rtl
IO__w4010_y:
	sty	$_Sound_NesRegs+0x10
	rtl


IO__r4011_a:
IO__r4011_x:
IO__r4011_y:
	rtl

IO__w4011_ind:
	xba
	sta	$_Sound_NesRegs+0x11
	IO_w40xx_Return
IO__w4011_a:
	sta	$_Sound_NesRegs+0x11
	rtl
IO__w4011_x:
	stx	$_Sound_NesRegs+0x11
	rtl
IO__w4011_y:
	sty	$_Sound_NesRegs+0x11
	rtl


IO__r4012_a:
IO__r4012_x:
IO__r4012_y:
	rtl

IO__w4012_ind:
	xba
	sta	$_Sound_NesRegs+0x12
	IO_w40xx_Return
IO__w4012_a:
	sta	$_Sound_NesRegs+0x12
	rtl
IO__w4012_x:
	stx	$_Sound_NesRegs+0x12
	rtl
IO__w4012_y:
	sty	$_Sound_NesRegs+0x12
	rtl


IO__r4013_a:
IO__r4013_x:
IO__r4013_y:
	rtl

IO__w4013_ind:
	xba
	sta	$_Sound_NesRegs+0x13
	IO_w40xx_Return
IO__w4013_a:
	sta	$_Sound_NesRegs+0x13
	rtl
IO__w4013_x:
	stx	$_Sound_NesRegs+0x13
	rtl
IO__w4013_y:
	sty	$_Sound_NesRegs+0x13
	rtl


IO__r4015_a:
IO__r4015_x:
IO__r4015_y:
	php
	xba

	lda	$_Sound_CopyRegs+0x15
	and	#0x1f
	sta	$_IO_Temp

	xba
	plp
	rtl

IO__w4015_ind:
	plx
	xba
	sta	$_IO_Temp
	bra	$+IO__w4015_in2
IO__w4015_x:
	stx	$_IO_Temp
	bra	$+IO__w4015_in
IO__w4015_y:
	sty	$_IO_Temp
	bra	$+IO__w4015_in
IO__w4015_a:
	sta	$_IO_Temp
	//bra	$+IO__w4015_in

IO__w4015_in:
	php
	xba

	lda	$_IO_Temp
IO__w4015_in2:
	eor	#0xff
	and	#0x1f
	trb	$_Sound_CopyRegs+0x15
	trb	$_Sound_NesRegs+0x16
	trb	$_Sound_CopyRegs+0x16

	lsr	$_IO_Temp
	bcs	$+b_1
		// Channel 0
		//lda	#0x20
		//tsb	$_Sound_NesRegs+0x0
		stz	$_Sound_NesRegs+0x3
		stz	$_Sound_square0_length
b_1:

	lsr	$_IO_Temp
	bcs	$+b_1
		// Channel 1
		//lda	#0x20
		//tsb	$_Sound_NesRegs+0x4
		stz	$_Sound_NesRegs+0x7
		stz	$_Sound_square1_length
b_1:

	lsr	$_IO_Temp
	bcs	$+b_1
		// Channel 2
		//stz	$_Sound_NesRegs+0x8
		stz	$_Sound_triangle_length
b_1:

	lsr	$_IO_Temp
	bcs	$+b_1
		// Channel 3
		stz	$_Sound_NesRegs+0xc
		stz	$_Sound_noise_length
b_1:

	xba
	plp
	rtl

	// ---------------------------------------------------------------------------
	// Input registers

IO__r4016_a:
	xba
	lda	$0x4016
	sta	$_IO_Temp
	xba
	rtl

IO__r4016_a_x:
	lda	$0x4016,x
	rtl

IO__r4016_a_y:
	lda	$0x4016,y
	rtl

IO__w4016_x:
	stx	$0x4016
	rtl

IO__w4016_y:
	sty	$0x4016
	rtl

IO__w4016_a:
	sta	$0x4016
	rtl


IO__r4017_a:
	xba
	lda	$0x4017
	sta	$_IO_Temp
	xba
	rtl

IO__r4017_a_x:
	lda	$0x4017,x
	rtl

IO__r4017_a_y:
	lda	$0x4017,y
	rtl

IO__w4017_x:
	stx	$0x4017
	rtl

IO__w4017_y:
	sty	$0x4017
	rtl

IO__w4017_a:
	sta	$0x4017
	rtl






