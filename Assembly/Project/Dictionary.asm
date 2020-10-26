
	// Expected dictionary structure:
	// [0] = 16-bit pointer to the next element
	// [2] = 8-bit string length
	// [3] = String start
	// [3+[2]] = Value start, anonymous type from the perspective of this module

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Dict__FindElement		=list, =compareString, .length
	// Return: X = Value pointer, A = Value pointer bank, Carry true when element isn't null
Dict__FindElement:
	// Is length zero?
	lda	$.length
	and	#0x00ff
	beq	$+b_ZeroLength

	// Merge first character into MSB of length
	.local	.firstChar
	lda	[$.compareString]
	sta	$.firstChar

	// Move compareString pointer to match list's string offset
	lda	$.compareString
	sec
	sbc	#3
	sta	$.compareString

	bra	$+b_loop_in
b_loop_continue:
		// Next after testing the wrong string
		lda	[$.list]
		sta	$.list
		bra	$+b_loop_in
b_loop:
		// Next
		stx	$.list

b_loop_in:
		// Is this element null?
		lda	[$.list]
		beq	$+b_ReturnFalse
		tax

		// Is this element starting with what we're looking for?
		ldy	#2
		lda	[$.list],y
		cmp	$.length
		bne	$-b_loop

		// Prepare comparing strings
		and	#0x00ff
		lsr	a
		bcs	$+b_1
			dey
b_1:
		tax
		beq	$+b_success

		// Loop comparing strings
b_loop2:
			iny
			iny
			lda	[$.list],y
			cmp	[$.compareString],y
			bne	$-b_loop_continue
			dex
			bne	$-b_loop2

b_success:
		// Success! Return value's pointer (list pointer + Y + 2)
		tya
		sec
		inc	a
		adc	$.list
		tax
		lda	$.list+2
		//bra	$+b_ReturnTrue

b_ReturnTrue:
	sec
	return

b_ReturnFalse:
	clc
	return


b_ZeroLength:
	// Find zero length string
	ldy	#2

	bra	$+b_loop_in
b_loop:
		// Next
		stx	$.list

b_loop_in:
		// Is this element null?
		lda	[$.list]
		beq	$-b_ReturnFalse
		tax

		// Is this element starting with what we're looking for?
		lda	[$.list],y
		and	#0x00ff
		bne	$-b_loop

		dey
		bra	$-b_success

	// ---------------------------------------------------------------------------


