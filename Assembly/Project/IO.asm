
IO__BANK:

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
IO__r2000_a_i:
IO__r2000_x:
IO__r2000_y:
	rtl

IO__w2000_a:
	CoreCall_Begin
	CoreCall_Lock
	CoreCall_Push
	CoreCall_Call	IO__w2000_a_i
	CoreCall_Pull
	CoreCall_End

IO__w2000_x:
	CoreCall_Begin
	CoreCall_Lock
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		stx	$_IO_2000
b_1:
	CoreCall_Call	IO__w2000_in
	CoreCall_Pull
	CoreCall_End

IO__w2000_y:
	CoreCall_Begin
	CoreCall_Lock
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		sty	$_IO_2000
b_1:
	CoreCall_Call	IO__w2000_in
	CoreCall_Pull
	CoreCall_End

IO__w2000_a_i:
	sta	$_IO_2000
IO__w2000_in:
	php
	lock
	xba

IO__w2000_in2:
	lda	$_IO_2000
	sta	$_PPU_SCROLL_X+1
	lsr	a
	sta	$_PPU_SCROLL_Y+1	// Bit 7 of Y must be clear here and LSR guarantees it

	and	#2
	cmp	$_IO_PPUADDR_INC_QUEUED
	beq	$+b_1
		sta	$_IO_PPUADDR_INC_QUEUED
		ora	#.VramQ_PpuAddrInc1
		sta	$0x2180
		adc	#.Zero+0x3e-VramQ_PpuAddrInc1		// Sets bit 6 when bit 1 was set and puts the opposite value in bit 1
		lsr	a
		and	#0x21
		sta	$_IO_PPUADDR_INC
b_1:

	xba
	plp
	rtl


IO__r2001_a:
IO__r2001_a_i:
IO__r2001_x:
IO__r2001_y:
	rtl

IO__w2001_a_i:
	sta	$_IO_2001
	rtl

IO__w2001_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_IO_2001
b_1:
	CoreCall_End

IO__w2001_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_IO_2001
b_1:
	CoreCall_End

IO__w2001_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_IO_2001
b_1:
	CoreCall_End


	.macro		IO__r2002_SaveScanline
		lda	$0x2137
		lda	$0x213d
		sta	$_IO_2002_SnesScanline+0
		lda	$0x213d
		//and	#0x01			// Top 7 bits are open bus
		sta	$_IO_2002_SnesScanline+1
	.endm

IO__r2002_a:
	CoreCall_Begin
	CoreCall_ResetMemoryPrefix
	CoreCall_IfSet		RomInfo_SyncPpuStatusToSnes, 0x80, +b_else
		CoreCall_Call		IO__r2002_a_i
		CoreCall_End
b_else:
		// TODO: Fix indirect read
		CoreCall_Call		IO__r2002_a_Sync
		CoreCall_End

IO__r2002_a_i:
	php
	pha

	stz	$_IO_HILO

	// Improved PPUSTATUS loop detection
	lda	$=RomInfo_ImprovedPpuStatusLoop
	bpl	$+b_SkipImprovement
		// Was this recently called? Either this scanline or the previous scanline
		sep	#0x05		// Set interrupt and carry
		lda	$0x2137
		lda	$0x213d
		sbc	$_IO_2002_SnesScanline+0
		xba
		lda	$0x213d
		sbc	$_IO_2002_SnesScanline+1
		lsr	a
		xba
		lsr	a
		beq	$+b_in
b_SkipImprovement:

	// Are we calling from the same address?
	lda	$3,s
	cmp	$_IO_2002_LastReturn
	bne	$+IO__r2002_NewCall
	lda	$4,s
	sbc	$_IO_2002_LastReturn+1
	bne	$+IO__r2002_NewCall
b_in:
		// Increment and compare with 3 to set bit 6, assuming A==0 and carry set from cmp+!bne
		inc	$_IO_2002_CallCount
		adc	$_IO_2002_CallCount
		adc	#0x3c
		and	#0x40

		// Did we hit sprite 0?
		beq	$+IO__r2002_NoSprite0
			stz	$_IO_2002_CallCount
			ora	$_IO_2002
			sta	$_IO_Temp
			stz	$_IO_2002

			// Change scanline to sprite 0
			lda	$_Sprite0Line
			sta	$_Scanline

			// Add new HDMA coordinates
			phx
			phy
			rep	#0x14
			.mx	0x20

			.vstack		_VSTACK_START
			phb
			phd
			call	Hdma__UpdateScrolling
			pld
			plb

			// Change mode back and set interrupt
			sep	#0x34
			.mx	0x30

			// Reset memory range
			stz	$_Memory_NesBank

			IO__r2002_SaveScanline

			ply
			plx
			pla
			plp
			rtl

IO__r2002_NoSprite0:
		ora	$_IO_2002
		and	#0xbf
		sta	$_IO_Temp
		stz	$_IO_2002

		IO__r2002_SaveScanline

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
	sta	$_IO_Temp
	stz	$_IO_2002

	IO__r2002_SaveScanline

	pla
	plp
	rtl

IO__r2002_a_Sync:
	.vstack		_VSTACK_START
	php
	pha
	lock

	lda	$0x2137
	lda	$0x213d
	lsr	$0x213d
	bcs	$+b_in
	cmp	#0xf0
	bcc	$+b_else
b_in:
		// > 0xe0
		lda	$_IO_2002
		sta	$_IO_Temp
		stz	$_IO_2002
		bra	$+b_1
b_else:
		// Sprite overflow (not supported)
		stz	$_IO_Temp

		// Sprite 0
		cmp	$_Sprite0Line
		ror	$_IO_Temp

		// Vblank
		lda	$_IO_2002
		asl	a
		ror	$_IO_Temp
		stz	$_IO_2002

		bit	$_IO_Temp
		bvc	$+b_2
			lda	$_Sprite0Line
			cmp	$_Scanline_HDMA
			beq	$+b_3
			bcc	$+b_3
				// Change scanline to sprite 0
				sta	$_Scanline

				// Add new HDMA coordinates
				phx
				phy
				rep	#0x14
				.mx	0x20

				phb
				phd
				call	Hdma__UpdateScrolling
				pld
				plb

				// Change mode back and set interrupt
				sep	#0x34
				.mx	0x30

				// Reset memory range
				stz	$_Memory_NesBank

				ply
				plx
				pla
				plp
				rtl
b_3:
b_2:
b_1:

	pla
	plp
	rtl

IO__w2002_a:
IO__w2002_a_i:
	rtl
IO__w2002_x:
	rtl
IO__w2002_y:
	rtl

	
IO__r2003_a:
IO__r2003_a_i:
IO__r2003_x:
IO__r2003_y:
	rtl
IO__w2003_a:
IO__w2003_a_i:
	rtl
IO__w2003_x:
	rtl
IO__w2003_y:
	rtl


IO__r2004_a:
IO__r2004_a_i:
IO__r2004_x:
IO__r2004_y:
	rtl
IO__w2004_a:
IO__w2004_a_i:
	rtl
IO__w2004_x:
	rtl
IO__w2004_y:
	rtl

	
IO__r2005_a:
IO__r2005_a_i:
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
IO__w2005_a_i:
	IO__w2005_Mac	a
IO__w2005_x:
	IO__w2005_Mac	x
IO__w2005_y:
	IO__w2005_Mac	y


IO__r2006_a:
IO__r2006_a_i:
IO__r2006_x:
IO__r2006_y:
	rtl

	// Note: Value is in X rather than IO_Temp
	.macro	IO__w2006_Low_Mac
		// Write 2
		stz	$_IO_HILO

		lda	#.VramQ_PpuAddrLow
		sta	$0x2180

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
	.endm
	.macro	IO__w2006_High_Mac
		// Write 1
		ora	#0x80
		sta	$_IO_HILO

		lda	#.VramQ_PpuAddrHigh
		sta	$0x2180

		txa
		and	#0x3f
		sta	$_IO_PPUADDR+1
		sta	$0x2180

		// Change scroll values
		lda	$_PPU_SCROLL_Y
		and	#0x38
		ora	$=IO__w2006_SR4AND03_OR_SL6,x
		sta	$_PPU_SCROLL_Y

		lda	$=IO__w2006_SR2AND03,x
		sta	$_PPU_SCROLL_X+1
		lsr	a
		sta	$_PPU_SCROLL_Y+1
	.endm

IO__w2006_y:
	php
	phx
	xba
	tyx

	lock
	lda	$_IO_HILO
	bpl	$+b_high
		IO__w2006_Low_Mac
		xba
		plx
		plp
		rtl
b_high:
		IO__w2006_High_Mac
		xba
		plx
		plp
		rtl


IO__w2006_x:
	php
	xba

	lock
	lda	$_IO_HILO
	bpl	$+b_high
		IO__w2006_Low_Mac
		xba
		plp
		rtl
b_high:
		IO__w2006_High_Mac
		xba
		plp
		rtl

IO__w2006_a:
IO__w2006_a_i:
	php
	phx
	tax

	lock
	lda	$_IO_HILO
	bpl	$+b_high
		IO__w2006_Low_Mac
		txa
		plx
		plp
		rtl
b_high:
		IO__w2006_High_Mac
		txa
		plx
		plp
		rtl

//IO__w2006_SR4AND03:
//	.fill	0x10, 0
//	.fill	0x10, 1
//	.fill	0x10, 2
//	.fill	0x10, 3
//	.fill	0x10, 0
//	.fill	0x10, 1
//	.fill	0x10, 2
//	.fill	0x10, 3
//	.fill	0x10, 0
//	.fill	0x10, 1
//	.fill	0x10, 2
//	.fill	0x10, 3
//	.fill	0x10, 0
//	.fill	0x10, 1
//	.fill	0x10, 2
//	.fill	0x10, 3

//IO__w2006_SL6:
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
//	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0

IO__w2006_SR4AND03_OR_SL6:
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x01, 0x41, 0x81, 0xc1, 0x01, 0x41, 0x81, 0xc1, 0x01, 0x41, 0x81, 0xc1, 0x01, 0x41, 0x81, 0xc1
	.data8	0x02, 0x42, 0x82, 0xc2, 0x02, 0x42, 0x82, 0xc2, 0x02, 0x42, 0x82, 0xc2, 0x02, 0x42, 0x82, 0xc2
	.data8	0x03, 0x43, 0x83, 0xc3, 0x03, 0x43, 0x83, 0xc3, 0x03, 0x43, 0x83, 0xc3, 0x03, 0x43, 0x83, 0xc3
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x01, 0x41, 0x81, 0xc1, 0x01, 0x41, 0x81, 0xc1, 0x01, 0x41, 0x81, 0xc1, 0x01, 0x41, 0x81, 0xc1
	.data8	0x02, 0x42, 0x82, 0xc2, 0x02, 0x42, 0x82, 0xc2, 0x02, 0x42, 0x82, 0xc2, 0x02, 0x42, 0x82, 0xc2
	.data8	0x03, 0x43, 0x83, 0xc3, 0x03, 0x43, 0x83, 0xc3, 0x03, 0x43, 0x83, 0xc3, 0x03, 0x43, 0x83, 0xc3
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x01, 0x41, 0x81, 0xc1, 0x01, 0x41, 0x81, 0xc1, 0x01, 0x41, 0x81, 0xc1, 0x01, 0x41, 0x81, 0xc1
	.data8	0x02, 0x42, 0x82, 0xc2, 0x02, 0x42, 0x82, 0xc2, 0x02, 0x42, 0x82, 0xc2, 0x02, 0x42, 0x82, 0xc2
	.data8	0x03, 0x43, 0x83, 0xc3, 0x03, 0x43, 0x83, 0xc3, 0x03, 0x43, 0x83, 0xc3, 0x03, 0x43, 0x83, 0xc3
	.data8	0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x40, 0x80, 0xc0
	.data8	0x01, 0x41, 0x81, 0xc1, 0x01, 0x41, 0x81, 0xc1, 0x01, 0x41, 0x81, 0xc1, 0x01, 0x41, 0x81, 0xc1
	.data8	0x02, 0x42, 0x82, 0xc2, 0x02, 0x42, 0x82, 0xc2, 0x02, 0x42, 0x82, 0xc2, 0x02, 0x42, 0x82, 0xc2
	.data8	0x03, 0x43, 0x83, 0xc3, 0x03, 0x43, 0x83, 0xc3, 0x03, 0x43, 0x83, 0xc3, 0x03, 0x43, 0x83, 0xc3

IO__w2006_SR2AND03:
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	.data8	0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3

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


IO__r2007_ChrRamReadCode:
	// This code is copied to RAM at "ChrRam_Read"
	lda	$=ChrRam_CONSTBANK
	jmp	$=IO__r2007_ChrRamCallBack

IO__r2007_ChrRamWriteCode:
	// This code is copied to RAM at "ChrRam_Write"
	sta	$=ChrRam_CONSTBANK
	pla
	plp
	rtl

IO__r2007_a:
IO__r2007_a_i:
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

		// Is this game using CHR RAM?
		ldx	$_CHR_0_PageLength
		bne	$+b_2
			// Read from CHR RAM clone
			lda	$_ChrRam_Page
			trapeq
			Exception	"Reading CHR RAM{}{}{}CPU attempted to read CHR RAM.{}{}CHR RAM clone must be turned on for this game."

			// Calculate destination address, assume carry clear from BCS
			//clc
			adc	$_IO_PPUADDR+1
			sta	$_ChrRam_Read+2
			lda	$_IO_PPUADDR+0
			sta	$_ChrRam_Read+1

			// Increment PPU address, assume carry clear because ADC shouldn't wrap the bank
			//clc
			adc	$_IO_PPUADDR_INC
			sta	$_IO_PPUADDR+0
			bcc	$+b_3
				inc	$_IO_PPUADDR+1
b_3:

			// Call
			plx
			jmp	$=ChrRam_Read
IO__r2007_ChrRamCallBack:
			// "Return" value
			sta	$_IO_2007r

			pla
			plp
			rtl
b_2:

		phy

		// Apply pattern swap
		tay
		lda	$_IO_MapperChrBankSwap
		lsr	a
		tya
		bcc	$+b_2
			eor	#0x10
b_2:

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

		tax
		lda	$_NameTable_Remap_Main-0x20,x
		xba
		lda	$_IO_PPUADDR
		rep	#0x11
		.mx	0x20
		tax

		lda	$=Nes_Nametables-0x2000,x
		sta	$_IO_2007r

		// Increment address
		lda	$_IO_PPUADDR
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
		lda	$=IO__w2007_PaletteMirror,x
		tax
		lda	$_PaletteNes,x
		// Immediate return instead of next read
		sta	$_IO_Temp

		// Increment address
		lda	$_IO_PPUADDR
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
IO__w2007_a_i:
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
		// Is this game using CHR RAM?
		lda	$_CHR_0_PageLength
		bne	$+IO__w2007_skip00

		// Write to CHR banks
		lda	#.VramQ_Tile
		lock
		sta	$0x2180
		lda	$_IO_Temp
		sta	$0x2180

		// Write to CHR RAM clone
		lda	$_ChrRam_Page
		beq	$+b_2
			// Calculate destination address, assume carry clear from BCS
			//clc
			adc	$_IO_PPUADDR+1
			sta	$_ChrRam_Write+2
			lda	$_IO_PPUADDR+0
			sta	$_ChrRam_Write+1

			// Increment PPU address, assume carry clear because ADC shouldn't wrap the bank
			//clc
			adc	$_IO_PPUADDR_INC
			sta	$_IO_PPUADDR+0
			bcc	$+b_3
				inc	$_IO_PPUADDR+1
b_3:

			// Call
			lda	$_IO_Temp
			jmp	$=ChrRam_Write
b_2:

		pla
		plp
		rtl

IO__w2007_skip00:

	// Is it name tables?
	cmp	#0x30
	jcs	$_IO__w2007_skip20
		phx

		tax
		lda	$_NameTable_Remap_Main-0x20,x
		xba
		lda	$_IO_PPUADDR
		rep	#0x10
		.mx	0x20
		tax

		lda	$_IO_Temp
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
			lda	$_IO_PPUADDR
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

		lda	$_IO_PPUADDR
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

			lda	$_IO_PPUADDR
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
	cmp	#0x3f
	bne	$+IO__w2007_skip3f
		phx

		ldx	$_IO_PPUADDR
		lda	$=IO__w2007_PaletteMirror,x
		tax
		lda	$_IO_Temp
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

IO__w2007_PaletteMirror:
	.repeat	8, ".data8	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,  0x00, 0x11, 0x12, 0x13, 0x04, 0x15, 0x16, 0x17, 0x08, 0x19, 0x1a, 0x1b, 0x0c, 0x1d, 0x1e, 0x1f"

IO__r4014_a:
IO__r4014_a_i:
IO__r4014_x:
IO__r4014_y:
	stz	$_IO_Temp
	rtl

IO__w4014_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_IO_Temp
		jsr	$=IO__w4014_In
b_1:
	CoreCall_End

IO__w4014_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_IO_Temp
		jsr	$=IO__w4014_In
b_1:
	CoreCall_End

IO__w4014_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_IO_Temp
		jsr	$=IO__w4014_In
b_1:
	CoreCall_End

IO__w4014_a_i:
	sta	$_IO_Temp
	jmp	$=IO__w4014_In

IO__w4014_ind:
	xba
	sta	$_IO_Temp
	jsr	$=IO__w4014_In
	IO_w40xx_Return

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
		caseat	0x14, IO__w4014_ind
		caseat	0x15, IO__w4015_ind
		caseat	0x16, IO__w4016_ind
		caseat	0x17, IO__w4017_ind

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
IO__r4000_a_i:
IO__r4000_x:
IO__r4000_y:
	rtl

IO__w4000_ind:
	xba
	sta	$_Sound_NesRegs+0x0
	IO_w40xx_Return

IO__w4000_a_i:
	sta	$_Sound_NesRegs+0x0
	rtl

IO__w4000_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0x0
b_1:
	CoreCall_End

IO__w4000_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0x0
b_1:
	CoreCall_End

IO__w4000_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0x0
b_1:
	CoreCall_End


IO__r4001_a:
IO__r4001_a_i:
IO__r4001_x:
IO__r4001_y:
	rtl

IO__w4001_ind:
	lda	#0x40
	tsb	$_Sound_ExtraControl
	xba
	sta	$_Sound_NesRegs+0x1
	IO_w40xx_Return

IO__w4001_a_i:
	sta	$_Sound_NesRegs+0x1
	php
	xba
	lda	#0x40
	tsb	$_Sound_ExtraControl
	xba
	plp
	rtl

IO__w4001_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0x1
b_1:
	CoreCall_UseA8
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		lda	#0x40
		tsb	$_Sound_ExtraControl
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w4001_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0x1
b_1:
	CoreCall_UseA8
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		lda	#0x40
		tsb	$_Sound_ExtraControl
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w4001_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0x1
b_1:
	CoreCall_UseA8
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		lda	#0x40
		tsb	$_Sound_ExtraControl
b_1:
	CoreCall_Pull
	CoreCall_End


IO__r4002_a:
IO__r4002_a_i:
IO__r4002_x:
IO__r4002_y:
	rtl

IO__w4002_ind:
	xba
	sta	$_Sound_NesRegs+0x2
	IO_w40xx_Return

IO__w4002_a_i:
	sta	$_Sound_NesRegs+0x2
	rtl

IO__w4002_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0x2
b_1:
	CoreCall_End

IO__w4002_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0x2
b_1:
	CoreCall_End

IO__w4002_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0x2
b_1:
	CoreCall_End


IO__r4003_a:
IO__r4003_a_i:
IO__r4003_x:
IO__r4003_y:
	rtl

	.macro	IO__w4003_Mac
		lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
		sta	$_Sound_square0_length
		lda	#0x01
		tsb	$_Sound_NesRegs+0x15
		tsb	$_Sound_ExtraControl
	.endm

IO__w4003_ind:
	xba
	sta	$_Sound_NesRegs+0x3
	tax
	IO__w4003_Mac
	txa
	IO_w40xx_Return

IO__w4003_a_i:
	sta	$_Sound_NesRegs+0x3
	php
	phx
	tax
	IO__w4003_Mac
	txa
	plx
	plp
	rtl

IO__w4003_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0x3
b_1:
	CoreCall_UseA8
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		IO__w4003_Mac
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w4003_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0x3
b_1:
	CoreCall_UseA8
	CoreCall_UseX
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		tyx
		IO__w4003_Mac
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w4003_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0x3
b_1:
	CoreCall_UseX
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		tax
		IO__w4003_Mac
		txa					// Removed when A is unused
b_1:
	CoreCall_IfNotFreeA	+b_1
		CoreCall_Remove	1
b_1:
	CoreCall_Pull
	CoreCall_End


IO__r4004_a:
IO__r4004_a_i:
IO__r4004_x:
IO__r4004_y:
	rtl

IO__w4004_ind:
	xba
	sta	$_Sound_NesRegs+0x4
	IO_w40xx_Return

IO__w4004_a_i:
	sta	$_Sound_NesRegs+0x4
	rtl

IO__w4004_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0x4
b_1:
	CoreCall_End

IO__w4004_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0x4
b_1:
	CoreCall_End

IO__w4004_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0x4
b_1:
	CoreCall_End


IO__r4005_a:
IO__r4005_a_i:
IO__r4005_x:
IO__r4005_y:
	rtl

IO__w4005_ind:
	lda	#0x80
	tsb	$_Sound_ExtraControl
	xba
	sta	$_Sound_NesRegs+0x5
	IO_w40xx_Return

IO__w4005_a_i:
	sta	$_Sound_NesRegs+0x5
	php
	xba
	lda	#0x80
	tsb	$_Sound_ExtraControl
	xba
	plp
	rtl

IO__w4005_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0x5
b_1:
	CoreCall_UseA8
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		lda	#0x80
		tsb	$_Sound_ExtraControl
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w4005_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0x5
b_1:
	CoreCall_UseA8
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		lda	#0x80
		tsb	$_Sound_ExtraControl
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w4005_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0x5
b_1:
	CoreCall_UseA8
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		lda	#0x80
		tsb	$_Sound_ExtraControl
b_1:
	CoreCall_Pull
	CoreCall_End


IO__r4006_a:
IO__r4006_a_i:
IO__r4006_x:
IO__r4006_y:
	rtl

IO__w4006_ind:
	xba
	sta	$_Sound_NesRegs+0x6
	IO_w40xx_Return

IO__w4006_a_i:
	sta	$_Sound_NesRegs+0x6
	rtl

IO__w4006_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0x6
b_1:
	CoreCall_End

IO__w4006_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0x6
b_1:
	CoreCall_End

IO__w4006_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0x6
b_1:
	CoreCall_End


IO__r4007_a:
IO__r4007_a_i:
IO__r4007_x:
IO__r4007_y:
	rtl

	.macro	IO__w4007_Mac
		lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
		sta	$_Sound_square1_length
		lda	#0x02
		tsb	$_Sound_NesRegs+0x15
		tsb	$_Sound_ExtraControl
	.endm

IO__w4007_ind:
	xba
	sta	$_Sound_NesRegs+0x7
	tax
	IO__w4007_Mac
	txa
	IO_w40xx_Return

IO__w4007_a_i:
	sta	$_Sound_NesRegs+0x7
	php
	phx
	tax
	IO__w4007_Mac
	txa
	plx
	plp
	rtl

IO__w4007_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0x7
b_1:
	CoreCall_UseA8
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		IO__w4007_Mac
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w4007_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0x7
b_1:
	CoreCall_UseA8
	CoreCall_UseX
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		tyx
		IO__w4007_Mac
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w4007_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0x7
b_1:
	CoreCall_UseX
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		tax
		IO__w4007_Mac
		txa					// Removed when A is unused
b_1:
	CoreCall_IfNotFreeA	+b_1
		CoreCall_Remove	1
b_1:
	CoreCall_Pull
	CoreCall_End


IO__r4008_a:
IO__r4008_a_i:
IO__r4008_x:
IO__r4008_y:
	rtl

IO__w4008_ind:
	xba
	sta	$_Sound_NesRegs+0x8
	IO_w40xx_Return

IO__w4008_a_i:
	sta	$_Sound_NesRegs+0x8
	rtl

IO__w4008_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0x8
b_1:
	CoreCall_End

IO__w4008_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0x8
b_1:
	CoreCall_End

IO__w4008_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0x8
b_1:
	CoreCall_End


IO__r4009_a:
IO__r4009_a_i:
IO__r4009_x:
IO__r4009_y:
	rtl

IO__w4009_ind:
	xba
	sta	$_Sound_NesRegs+0x9
	IO_w40xx_Return

IO__w4009_a_i:
	sta	$_Sound_NesRegs+0x9
	rtl

IO__w4009_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0x9
b_1:
	CoreCall_End

IO__w4009_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0x9
b_1:
	CoreCall_End

IO__w4009_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0x9
b_1:
	CoreCall_End


IO__r400a_a:
IO__r400a_a_i:
IO__r400a_x:
IO__r400a_y:
	rtl

IO__w400a_ind:
	xba
	sta	$_Sound_NesRegs+0xa
	IO_w40xx_Return

IO__w400a_a_i:
	sta	$_Sound_NesRegs+0xa
	rtl

IO__w400a_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0xa
b_1:
	CoreCall_End

IO__w400a_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0xa
b_1:
	CoreCall_End

IO__w400a_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0xa
b_1:
	CoreCall_End


IO__r400b_a:
IO__r400b_a_i:
IO__r400b_x:
IO__r400b_y:
	rtl

	.macro	IO__w400b_Mac
		lda	#0x04
		tsb	$_Sound_ExtraControl
		tsb	$_Sound_NesRegs+0x15

		lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
		sta	$_Sound_triangle_length
	.endm

IO__w400b_ind:
	xba
	sta	$_Sound_NesRegs+0xb
	tax
	IO__w400b_Mac
	txa
	IO_w40xx_Return

IO__w400b_a_i:
	sta	$_Sound_NesRegs+0xb
	php
	phx
	tax
	IO__w400b_Mac
	txa
	plx
	plp
	rtl

IO__w400b_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0xb
b_1:
	CoreCall_UseA8
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		IO__w400b_Mac
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w400b_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0xb
b_1:
	CoreCall_UseA8
	CoreCall_UseX
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		tyx
		IO__w400b_Mac
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w400b_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0xb
b_1:
	CoreCall_UseX
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		tax
		IO__w400b_Mac
		txa					// Removed when A is unused
b_1:
	CoreCall_IfNotFreeA	+b_1
		CoreCall_Remove	1
b_1:
	CoreCall_Pull
	CoreCall_End


IO__r400c_a:
IO__r400c_a_i:
IO__r400c_x:
IO__r400c_y:
	rtl

IO__w400c_ind:
	xba
	sta	$_Sound_NesRegs+0xc
	IO_w40xx_Return

IO__w400c_a_i:
	sta	$_Sound_NesRegs+0xc
	rtl

IO__w400c_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0xc
b_1:
	CoreCall_End

IO__w400c_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0xc
b_1:
	CoreCall_End

IO__w400c_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0xc
b_1:
	CoreCall_End


IO__r400d_a:
IO__r400d_a_i:
IO__r400d_x:
IO__r400d_y:
	rtl

IO__w400d_ind:
	xba
	sta	$_Sound_NesRegs+0xd
	IO_w40xx_Return

IO__w400d_a_i:
	sta	$_Sound_NesRegs+0xd
	rtl

IO__w400d_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0xd
b_1:
	CoreCall_End

IO__w400d_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0xd
b_1:
	CoreCall_End

IO__w400d_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0xd
b_1:
	CoreCall_End


IO__r400e_a:
IO__r400e_a_i:
IO__r400e_x:
IO__r400e_y:
	rtl

IO__w400e_ind:
	xba
	sta	$_Sound_NesRegs+0xe
	IO_w40xx_Return

IO__w400e_a_i:
	sta	$_Sound_NesRegs+0xe
	rtl

IO__w400e_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0xe
b_1:
	CoreCall_End

IO__w400e_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0xe
b_1:
	CoreCall_End

IO__w400e_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0xe
b_1:
	CoreCall_End


IO__r400f_a:
IO__r400f_a_i:
IO__r400f_x:
IO__r400f_y:
	rtl

	.macro	IO__w400f_Mac
		// Update length
		lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
		sta	$_Sound_noise_length

		// Enable noise
		lda	#0x08
		tsb	$_Sound_NesRegs+0x15
		tsb	$_Sound_ExtraControl
	.endm

IO__w400f_ind:
	xba
	sta	$_Sound_NesRegs+0xf
	tax
	IO__w400f_Mac
	txa
	IO_w40xx_Return

IO__w400f_a_i:
	sta	$_Sound_NesRegs+0xf
	php
	phx
	tax
	IO__w400f_Mac
	txa
	plx
	plp
	rtl

IO__w400f_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0xf
b_1:
	CoreCall_UseA8
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		IO__w400f_Mac
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w400f_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0xf
b_1:
	CoreCall_UseA8
	CoreCall_UseX
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		tyx
		IO__w400f_Mac
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w400f_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0xf
b_1:
	CoreCall_UseX
	CoreCall_UseN
	CoreCall_UseZ
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		tax
		IO__w400f_Mac
		txa					// Removed when A is unused
b_1:
	CoreCall_IfNotFreeA	+b_1
		CoreCall_Remove	1
b_1:
	CoreCall_Pull
	CoreCall_End


IO__r4010_a:
IO__r4010_a_i:
IO__r4010_x:
IO__r4010_y:
	rtl

IO__w4010_ind:
	xba
	sta	$_Sound_NesRegs+0x10
	IO_w40xx_Return

IO__w4010_a_i:
	sta	$_Sound_NesRegs+0x10
	rtl

IO__w4010_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0x10
b_1:
	CoreCall_End

IO__w4010_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0x10
b_1:
	CoreCall_End

IO__w4010_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0x10
b_1:
	CoreCall_End


IO__r4011_a:
IO__r4011_a_i:
IO__r4011_x:
IO__r4011_y:
	rtl

IO__w4011_ind:
	xba
	sta	$_Sound_NesRegs+0x11
	IO_w40xx_Return

IO__w4011_a_i:
	sta	$_Sound_NesRegs+0x11
	rtl

IO__w4011_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0x11
b_1:
	CoreCall_End

IO__w4011_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0x11
b_1:
	CoreCall_End

IO__w4011_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0x11
b_1:
	CoreCall_End


IO__r4012_a:
IO__r4012_a_i:
IO__r4012_x:
IO__r4012_y:
	rtl

IO__w4012_ind:
	xba
	sta	$_Sound_NesRegs+0x12
	IO_w40xx_Return

IO__w4012_a_i:
	sta	$_Sound_NesRegs+0x12
	rtl

IO__w4012_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0x12
b_1:
	CoreCall_End

IO__w4012_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0x12
b_1:
	CoreCall_End

IO__w4012_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0x12
b_1:
	CoreCall_End


IO__r4013_a:
IO__r4013_a_i:
IO__r4013_x:
IO__r4013_y:
	rtl

IO__w4013_ind:
	xba
	sta	$_Sound_NesRegs+0x13
	IO_w40xx_Return

IO__w4013_a_i:
	sta	$_Sound_NesRegs+0x13
	rtl

IO__w4013_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sta	$_Sound_NesRegs+0x13
b_1:
	CoreCall_End

IO__w4013_x:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		stx	$_Sound_NesRegs+0x13
b_1:
	CoreCall_End

IO__w4013_y:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		sty	$_Sound_NesRegs+0x13
b_1:
	CoreCall_End


IO__r4015_a:
IO__r4015_a_i:
IO__r4015_x:
IO__r4015_y:
	php
	xba

	lda	$_Sound_NesRegs+0x15
	and	#0x1f
	sta	$_IO_Temp

	xba
	plp
	rtl

IO__w4015_ind:
	plx
	xba
	sta	$_IO_Temp
	xba
	bra	$+IO__w4015_in2
IO__w4015_x:
	stx	$_IO_Temp
	bra	$+IO__w4015_in
IO__w4015_y:
	sty	$_IO_Temp
	bra	$+IO__w4015_in
IO__w4015_a:
IO__w4015_a_i:
	sta	$_IO_Temp
	//bra	$+IO__w4015_in

IO__w4015_in:
	php
	xba

IO__w4015_in2:
	lda	$_IO_Temp
	eor	#0xff
	and	#0x1f
	trb	$_Sound_NesRegs+0x15
	trb	$_Sound_ExtraControl

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

	lsr	$_IO_Temp
	bcc	$+b_1
		// Channel 4
		lda	#0x10
		tsb	$_Sound_NesRegs+0x15
		bne	$+b_1
			tsb	$_Sound_ExtraControl
b_1:

	xba
	plp
	rtl

	// ---------------------------------------------------------------------------
	// Input registers

IO__r4016_a_i:
	xba
	lda	$=RomInfo_InputFlags
	bmi	$+b_else
		lda	$0x4016
		sta	$_IO_Temp

		xba
		rtl
b_else:
		phx
		ldx	$_Input_OffsetA
		lda	$_Input_Remap+0,x
		sta	$_IO_Temp
		inx
		inx
		stx	$_Input_OffsetA
		plx

		xba
		rtl

IO__r4016_a:
	CoreCall_Begin
	CoreCall_Use	"A8Xzn"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		ldx	$_Input_OffsetA
		lda	$_Input_Remap+0,x
		sta	$_IO_Temp
		inx
		inx
		stx	$_Input_OffsetA
b_1:
	CoreCall_Pull
	CoreCall_End

IO__r4016_a_x:
	CoreCall_Begin
	CoreCall_Use	"Yznvc"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		cpx	#1
		beq	$+b_else
		bcs	$+b_1
			// Controller A
			ldy	$_Input_OffsetA
			lda	$_Input_Remap+0,y
			sta	$_IO_Temp
			iny
			iny
			sty	$_Input_OffsetA

			bra	$+b_1
b_else:
			// Controller B
			ldy	$_Input_OffsetB
			lda	$_Input_Remap+0,y
			sta	$_IO_Temp
			iny
			iny
			sty	$_Input_OffsetB
b_1:
	CoreCall_Pull
	CoreCall_End

IO__r4016_a_y:
	CoreCall_Begin
	CoreCall_Use	"Xznvc"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		cpy	#1
		beq	$+b_else
		bcs	$+b_1
			// Controller A
			ldx	$_Input_OffsetA
			lda	$_Input_Remap+0,x
			sta	$_IO_Temp
			inx
			inx
			stx	$_Input_OffsetA

			bra	$+b_1
b_else:
			// Controller B
			ldx	$_Input_OffsetB
			lda	$_Input_Remap+0,x
			sta	$_IO_Temp
			inx
			inx
			stx	$_Input_OffsetB
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w4016_x:
	CoreCall_Begin
	CoreCall_Use	"A16zn"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		txa
b_1:
	CoreCall_Copy	IO__w4016_CopyStart, IO__w4016_CopyEnd
	CoreCall_Pull
	CoreCall_End

IO__w4016_y:
	CoreCall_Begin
	CoreCall_Use	"A16zn"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		tya
b_1:
	CoreCall_Copy	IO__w4016_CopyStart, IO__w4016_CopyEnd
	CoreCall_Pull
	CoreCall_End

IO__w4016_ind:
	xba
	jsr	$=IO__w4016_a_i
	IO_w40xx_Return

IO__w4016_a:
	CoreCall_Begin
	CoreCall_Use	"A16zn"
	CoreCall_Push
	CoreCall_Copy	IO__w4016_CopyStart, IO__w4016_CopyEnd
	CoreCall_Pull
	CoreCall_End

IO__w4016_a_x:
	CoreCall_Begin
	CoreCall_Use	"A16znvc"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		cpx	#1
		bcs	$+b_1
			jsr	$=IO__w4016_CopyStart
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w4016_a_y:
	CoreCall_Begin
	CoreCall_Use	"A16znvc"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		cpy	#1
		bcs	$+b_1
			jsr	$=IO__w4016_CopyStart
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w4016_a_i:
	pha

	// Are we using custom controls?
	lda	$=RomInfo_InputFlags
	bmi	$+b_1
		pla
		sta	$0x4016
		rtl
b_1:
	// Reload A
	lda	$1,s

	jsr	$=IO__w4016_CopyStart
	pla
	rtl

IO__w4016_CopyStart:
		and	#1
		beq	$+b_else
			lda	#26
			sta	$_Input_OffsetA
			sta	$_Input_OffsetB

			bra	$+b_1
b_else:
b_loop:
				// Wait for auto-read not busy, likely not needed
				lda	#1
				and	$0x4212
				bne	$-b_loop
			// Reset input poll
			lda	#1
			sta	$0x4016
			stz	$0x4016

			jsr	$=IO__w4016_ReadInputs
b_1:
IO__w4016_CopyEnd:
	rtl

IO__w4016_ReadInputs:
	phx
	rep	#0x20
	.mx	0x10

	// Read 12 times
	.macro	IO__w4016_ReadInputs	index
		lda	$=RomInfo_InputMap+{0}
		asl	a
		tax
		lda	$0x4016
		sta	$_Input_Remap,x
	.endm
	IO__w4016_ReadInputs	0
	IO__w4016_ReadInputs	1
	IO__w4016_ReadInputs	2
	IO__w4016_ReadInputs	3
	IO__w4016_ReadInputs	4
	IO__w4016_ReadInputs	5
	IO__w4016_ReadInputs	6
	IO__w4016_ReadInputs	7
	IO__w4016_ReadInputs	8
	IO__w4016_ReadInputs	9
	IO__w4016_ReadInputs	10
	IO__w4016_ReadInputs	11

	// Reset indexes
	lda	#0x0302
	sta	$_Input_OffsetA

	sep	#0x20
	.mx	0x30
	plx
	rtl


IO__r4017_a_i:
	xba
	lda	$=RomInfo_InputFlags
	bmi	$+b_else
		lda	$0x4017
		sta	$_IO_Temp

		xba
		rtl
b_else:
		phx
		ldx	$_Input_OffsetB
		lda	$_Input_Remap+0,x
		sta	$_IO_Temp
		inx
		inx
		stx	$_Input_OffsetB
		plx

		xba
		rtl

IO__r4017_a:
	CoreCall_Begin
	CoreCall_Use	"A8Xzn"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		ldx	$_Input_OffsetB
		lda	$_Input_Remap+0,x
		sta	$_IO_Temp
		inx
		inx
		stx	$_Input_OffsetB
b_1:
	CoreCall_Pull
	CoreCall_End

IO__r4017_a_x:
	CoreCall_Begin
	CoreCall_Use	"Yzn"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		txa
		bne	$+b_else
			// Controller B
			ldy	$_Input_OffsetB
			lda	$_Input_Remap+0,y
			sta	$_IO_Temp
			iny
			iny
			sty	$_Input_OffsetB
b_1:
	CoreCall_Pull
	CoreCall_End

IO__r4017_a_y:
	CoreCall_Begin
	CoreCall_Use	"Xzn"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		tya
		bne	$+b_else
			// Controller B
			ldx	$_Input_OffsetB
			lda	$_Input_Remap+0,x
			sta	$_IO_Temp
			inx
			inx
			stx	$_Input_OffsetB
b_1:
	CoreCall_Pull
	CoreCall_End

IO__w4017_a:
IO__w4017_x:
IO__w4017_y:
IO__w4017_a_x:
IO__w4017_a_y:
	// Not supported yet
	CoreCall_Begin
	CoreCall_End

IO__w4017_ind:
	// Not supported yet
	xba
	IO_w40xx_Return

IO__w4017_a_i:
	// Not supported yet
	rtl






