
	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Patch__IsInRange
	// Entry: A = Bank, X = Address
	// Return: carry = true when address is in a patch range
Patch__IsInRange:
	phb

	.local	=addr
	// Ignore some bits in the address based on mapper PRG bank size
	sta	$.addr+2
	txa
	bpl	$+b_1
		ora	$=RomInfo_PrgBankingMask
b_1:
	sta	$.addr

	.local	_min, _max
	// Prepare min/max
	lda	$=RomInfo_PatchRanges_Length
	beq	$+b_return_false
	sec
	sbc	#8
	clc
	adc	$=RomInfo_PatchRanges
	sta	$.max
	lda	$=RomInfo_PatchRanges
	sta	$.min

	// Get patch range list pointer
	smx	#0x20
	lda	$=RomInfo_PatchRanges+2
	pha
	plb
	smx	#0x00

b_loop:
		// Calculate mid
		lda	$.min
		adc	$.max		// Ignore carry because first 3 bits are always clear
		ror	a
		and	#0xfff8
		tay

		// Test bottom.hi
		lda	$.addr+1
		cmp	$0x0001,y
		bcc	$+b_lower
		bne	$+b_1
			// Test bottom.lo
			lda	$.addr+0
			cmp	$0x0000,y
			bcc	$+b_lower
			beq	$+b_return_true
b_1:

		// Test top.hi
		lda	$0x0005,y
		cmp	$.addr+1
		bcc	$+b_greater
		bne	$+b_1
			// Test top.lo
			lda	$0x0004,y
			cmp	$.addr+0
			bcc	$+b_greater
b_1:

b_return_true:
		plb
		sec
		return

b_lower:
			tya
			adc	#0xfff8				// Assume carry clear from BCC
			bcc	$+b_return_false	// Underflow
			sta	$.max
			cmp	$.min
			bcc	$+b_return_false
			bra	$-b_loop

b_greater:
			tya
			adc	#0x0008				// Assume carry clear from BCC
			sta	$.min
			cmp	$.max
			//bcs	$+b_return_false
			bcc	$-b_loop
			beq	$-b_loop

b_return_false:
	plb
	clc
	return

	// ---------------------------------------------------------------------------
