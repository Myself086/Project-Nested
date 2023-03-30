
	// RomCache description structure
	.def	RomCache_Desc_GlobalLifetime	RomCache_Desc_CONSTBANK-4		// u16
	.def	RomCache_Desc_TopIndex			RomCache_Desc_CONSTBANK-2		// u16
	.def	RomCache_Desc_NesBank			RomCache_Desc_CONSTBANK+0		// | u8
	.def	RomCache_Desc_SnesBank			RomCache_Desc_CONSTBANK+1		// | u8
	.def	RomCache_Desc_Lifetime			RomCache_Desc_CONSTBANK+2		// | u16
	.def	RomCache_Desc_BYTECOUNT			4

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	RomCache__NewList
RomCache__NewList:
	.local	_temp, _addr, _top

	// Allocate memory for RomCache descriptions (RomInfo_RomCacheBankCount * RomCache_Desc_BYTECOUNT + 4)
	lda	$=RomInfo_RomCacheBankCount
	and	#0x00ff
	trapeq
	Exception	"PRG ROM cache disabled{}{}{}Project Nested attempted to allocate a ROM cache bank but none are available.{}{}Allow at least 1 PRG ROM cache bank in the settings."
	sta	$.temp
	clc
	.repeat		RomCache_Desc_BYTECOUNT-1, "adc	$.temp"
	sta	$.top
	adc	#4
	tax
	stx	$.temp
	lda	#_RomCache_Desc_CONSTBANK/0x10000
	call	Memory__AllocInBank

	inx
	inx
	inx
	inx
	stx	$_RomCache_DescListPointer
	lda	$.top
	sec
	sbc	#_RomCache_Desc_BYTECOUNT
	sta	$=RomCache_Desc_TopIndex,x

	// Clear list
	tay
	smx	#0x20
b_loop:
		lda	#0xff
		sta	$=RomCache_Desc_NesBank,x
		lda	#0x00
		sta	$=RomCache_Desc_SnesBank,x
		sta	$=RomCache_Desc_Lifetime+0,x
		sta	$=RomCache_Desc_Lifetime+1,x

		// Next
		.repeat	RomCache_Desc_BYTECOUNT, "inx"
		.repeat	RomCache_Desc_BYTECOUNT, "dey"
		bpl	$-b_loop
	smx	#0x00

	return

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	RomCache__GetNesBank
	// Entry: A.lo = NES bank
	// Return: X.lo = SNES bank
RomCache__GetNesBank:
	.local	=list
	.local	_nesBank, _snesBank
	sta	$.nesBank

	// Get list pointer or create it if null
b_redo:
	ldx	$_RomCache_DescListPointer
	bne	$+b_1
		call	RomCache__NewList
		bra	$-b_redo
b_1:

	// Search for this NES bank (can be optimized)
	lda	$=RomCache_Desc_TopIndex,x
	tay
	smx	#0x20
	lda	#.RomCache_Desc_CONSTBANK/0x10000
	sta	$.list+2
	stx	$.list+0
	lda	$.nesBank
b_loop:
		// Is this the bank we're looking for?
		cmp	[$.list],y
		beq	$+RomCache__GetNesBank_ReturnBank

		// Next
		.repeat	RomCache_Desc_BYTECOUNT, "dey"
		bpl	$-b_loop

	smx	#0x00
	jmp	$_RomCache__GetNesBank_CopyBank


	.mx	0x20
RomCache__GetNesBank_ReturnBank:
	// Get SNES bank
	iny
	lda	[$.list],y
	iny
	sta	$.snesBank

	smx	#0x00

	// Increment and write global lifetime
	lda	$=RomCache_Desc_GlobalLifetime,x
	inc	a
	beq	$+b_else
		// Return as normal
		sta	[$.list],y
		sta	$=RomCache_Desc_GlobalLifetime,x
		ldx	$.snesBank
		return
b_else:
		// Adjust current lifetime
		dec	a
		sta	[$.list],y
		lda	#0x8000
		sta	$=RomCache_Desc_GlobalLifetime,x

		// Divide each lifetime by 2
		phy
b_loop:
			// Is this the bank we're looking for?
			lda	[$.list],y
			lsr	a
			inc	a								// Result must be non-zero
			sta	[$.list],y

			// Next
			.repeat	RomCache_Desc_BYTECOUNT, "dey"
			bpl	$-b_loop
b_1:
		ply

		// Return
		ldx	$.snesBank
		return


	.mx	0x00
RomCache__GetNesBank_CopyBank:
	// Find oldest bank (code optimization not required here)
	lda	$=RomCache_Desc_TopIndex,x
	tay
	iny
	iny
	.local	_lowestValue
	.local	_lowestIndex
	.local	_emptyIndex
	lda	#0xffff
	sta	$.lowestValue
	sta	$.lowestIndex
	sta	$.emptyIndex
b_loop:
		// Test lifetime
		lda	[$.list],y
		beq	$+b_else						// Lifetime of 0 means unused
			cmp	$.lowestValue
			bcs	$+b_1
				sta	$.lowestValue
				sty	$.lowestIndex
				bra	$+b_1
b_else:
			sty	$.emptyIndex
b_1:

		// Next
		.repeat	RomCache_Desc_BYTECOUNT, "dey"
		bpl	$-b_loop

	// Do we have an empty bank?
	ldy	$.emptyIndex
	bmi	$+b_else
		// Take a SRAM bank if available
		call	Memory__TakeSramBank
		beq	$+b_else
			// SRAM bank available, list it
			ldy	$.emptyIndex
			dey
			dey
			sta	$.snesBank
			smx	#0x20
			xba
			lda	$.nesBank
			smx	#0x00
			sta	[$.list],y					// Write new NES and SNES bank
			bra	$+b_1
b_else:
		// Take oldest bank
		ldy	$.lowestIndex
		dey
		dey
		lda	[$.list],y
		xba
		smx	#0x20
		sta	$.snesBank
		lda	$.nesBank
		sta	[$.list],y						// Write new NES bank
		smx	#0x00
b_1:

	// Keep index for later
	.local	_index
	sty	$.index

	// Copy bytes from ROM to SRAM
	.local	4 copyCode
	lda	#0x6b54
	sta	$.copyCode+0
	sta	$.copyCode+2
	// Load banks
	lda	$.nesBank
	and	#0x00ff
	tax
	smx	#0x20
	lda	$=RomInfo_BankLut_80,x				// TODO: Check static range 8000
	xba
	lda	$.snesBank
	smx	#0x00
	sta	$.copyCode+1
	// Copy
	lda	#0x2000
	ldx	#0x8000
	ldy	#0x6000
	phb
	jsr	$=copyCode
	plb

	// Return bank
	sep	#0x20
	ldy	$.index
	ldx	$_RomCache_DescListPointer
	jmp	$_RomCache__GetNesBank_ReturnBank

	// ---------------------------------------------------------------------------
