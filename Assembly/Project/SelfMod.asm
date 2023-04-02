
	// This module is for self-modifying (SelfMod) code during conversion
	// This code can be written in C# but I chose asm-only for consistency

	// Can be debugged with a SNES emulator that allows writing ROM areas, it'll find its way here without alteration

	// Change this value to 0 to prevent using SelfMod during conversion
	.def	SelfMod__Apply_SealValue		0xff

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	SelfMod__Apply
SelfMod__Apply:
	php
	phb

	// Break the seal to prevent running this code twice
	smx	#0x20
SelfMod__Apply_Seal:
	lda	#.SelfMod__Apply_SealValue
	bne	$+b_1
		plb
		plp
		return
b_1:
	lda	#0x00
	sta	$=SelfMod__Apply_Seal+1

	// Change bank to the table
	lda	#.SelfMod_Table/0x10000
	pha
	plb
	smx	#0x00

	// Start reading SelfMod_Table
	.local	_condition, _validDo, =doTarget, _doTableOffset, _table
	.local	=varTarget, _valueCmp				// These don't need to be reset
	stz	$.condition
	stz	$.validDo
	stz	$.doTarget+0
	stz	$.doTarget+1
	stz	$.doTableOffset
	lda	#_SelfMod_Table
	sta	$.table
SelfMod__Apply_Switch_Break:
	lda	($.table)
	inc	$.table
	and	#0x00ff
	asl	a						// Clears carry
	tax
	jmp	($_SelfMod__Apply_Switch,x)


SelfMod__Apply_Switch_Error:
	trap


	.macro	SelfMod__Apply_SecIf	condition
		sec
		{0}	$+b_1__
			clc
b_1__:
	.endm


SelfMod__Apply_Switch:
	switch		0x100, SelfMod__Apply_Switch_Error, SelfMod__Apply_Switch_Break
		case	SelfMod_Begin
			// Set condition
			sec
			ror	$.condition

			// Invalid do
			stz	$.validDo

			// Set target
			lda	($.table)
			inc	$.table
			sta	$.doTarget+0
			lda	($.table)
			inc	$.table
			inc	$.table
			sta	$.doTarget+1

			break

		case	SelfMod_EndOfList
			plb
			plp
			return

		case	SelfMod_Do
			// Read length
			lda	($.table)
			inc	$.table
			and	#0x00ff
			tax

			// Copy table offset (can be moved inside the if statement but is safer here until testing)
			lda	$.table
			sta	$.doTableOffset

			// Set validDo if condition is set, then only copy bytes if set
			lda	$.condition
			sta	$.validDo
			bpl	$+b_1
				// Copy bytes
				txy
				dey
				bmi	$+b_1
				smx	#0x20
b_loop:
					// Copy byte
					lda	($.table),y
					sta	[$.doTarget],y

					// Next
					dey
					bpl	$-b_loop
				smx	#0x00
b_1:

			// Increase table pointer (u8)
			txa
			clc
			adc	$.table
			sta	$.table

			break

		case	SelfMod_Copy32
			ldy	#4
			jsr	$_SelfMod__Apply_CopyVar
			break

		case	SelfMod_Copy24
			ldy	#3
			jsr	$_SelfMod__Apply_CopyVar
			break

		case	SelfMod_Copy16
			ldy	#2
			jsr	$_SelfMod__Apply_CopyVar
			break

		case	SelfMod_Copy8
			ldy	#1
			jsr	$_SelfMod__Apply_CopyVar
			break

		case	SelfMod_IfSet
			jsr	$_SelfMod__Apply_ReadVar8
			and	$.valueCmp
			SelfMod__Apply_SecIf	bne
			ror	$.condition
			break

		case	SelfMod_IfClear
			jsr	$_SelfMod__Apply_ReadVar8
			and	$.valueCmp
			SelfMod__Apply_SecIf	beq
			ror	$.condition
			break

		case	SelfMod_OrSet
			jsr	$_SelfMod__Apply_ReadVar8
			and	$.valueCmp
			SelfMod__Apply_SecIf	bne
			ror	$.condition
			jsr	$_SelfMod__Apply_OrCondition
			break

		case	SelfMod_OrClear
			jsr	$_SelfMod__Apply_ReadVar8
			and	$.valueCmp
			SelfMod__Apply_SecIf	beq
			ror	$.condition
			jsr	$_SelfMod__Apply_OrCondition
			break

		case	SelfMod_AndSet
			jsr	$_SelfMod__Apply_ReadVar8
			and	$.valueCmp
			SelfMod__Apply_SecIf	bne
			ror	$.condition
			jsr	$_SelfMod__Apply_AndCondition
			break

		case	SelfMod_AndClear
			jsr	$_SelfMod__Apply_ReadVar8
			and	$.valueCmp
			SelfMod__Apply_SecIf	beq
			ror	$.condition
			jsr	$_SelfMod__Apply_AndCondition
			break

		case	SelfMod_EorSet
			jsr	$_SelfMod__Apply_ReadVar8
			and	$.valueCmp
			SelfMod__Apply_SecIf	bne
			ror	$.condition
			jsr	$_SelfMod__Apply_EorCondition
			break

		case	SelfMod_EorClear
			jsr	$_SelfMod__Apply_ReadVar8
			and	$.valueCmp
			SelfMod__Apply_SecIf	beq
			ror	$.condition
			jsr	$_SelfMod__Apply_EorCondition
			break

		case	SelfMod_IfEq8
			jsr	$_SelfMod__Apply_ReadVar8
			cmp	$.valueCmp
			SelfMod__Apply_SecIf	beq
			ror	$.condition
			break

		case	SelfMod_IfNe8
			jsr	$_SelfMod__Apply_ReadVar8
			cmp	$.valueCmp
			SelfMod__Apply_SecIf	bne
			ror	$.condition
			break

		case	SelfMod_OrEq8
			jsr	$_SelfMod__Apply_ReadVar8
			cmp	$.valueCmp
			SelfMod__Apply_SecIf	beq
			ror	$.condition
			jsr	$_SelfMod__Apply_OrCondition
			break

		case	SelfMod_OrNe8
			jsr	$_SelfMod__Apply_ReadVar8
			cmp	$.valueCmp
			SelfMod__Apply_SecIf	bne
			ror	$.condition
			jsr	$_SelfMod__Apply_OrCondition
			break

		case	SelfMod_AndEq8
			jsr	$_SelfMod__Apply_ReadVar8
			cmp	$.valueCmp
			SelfMod__Apply_SecIf	beq
			ror	$.condition
			jsr	$_SelfMod__Apply_AndCondition
			break

		case	SelfMod_AndNe8
			jsr	$_SelfMod__Apply_ReadVar8
			cmp	$.valueCmp
			SelfMod__Apply_SecIf	bne
			ror	$.condition
			jsr	$_SelfMod__Apply_AndCondition
			break

		case	SelfMod_EorEq8
			jsr	$_SelfMod__Apply_ReadVar8
			cmp	$.valueCmp
			SelfMod__Apply_SecIf	beq
			ror	$.condition
			jsr	$_SelfMod__Apply_EorCondition
			break

		case	SelfMod_EorNe8
			jsr	$_SelfMod__Apply_ReadVar8
			cmp	$.valueCmp
			SelfMod__Apply_SecIf	bne
			ror	$.condition
			jsr	$_SelfMod__Apply_EorCondition
			break


SelfMod__Apply_ReadVar8:
	// Clear valueCmp MSB
	stz	$.valueCmp

	// Copy target
	lda	($.table)
	inc	$.table
	inc	$.table
	sta	$.varTarget+0
	lda	($.table)
	inc	$.table
	inc	$.table
	sta	$.varTarget+2		// varTarget bank and valueCmp LSB

	// Return varTarget's value
	lda	[$.varTarget]
	and	#0x00ff

	rts


	// Entry: Y = length
SelfMod__Apply_CopyVar:
	// Return if invalid do
	bit	$.validDo
	bmi	$+b_1
		rts
b_1:

	// Copy target
	lda	($.table)
	inc	$.table
	inc	$.table
	sta	$.varTarget+0
	lda	($.table)
	inc	$.table
	sta	$.varTarget+2

	// Apply offset
	xba
	and	#0x00ff
	clc
	adc	#0x7f80
	eor	#0x7f80
	adc	$.table
	sec
	sbc	$.doTableOffset
	sec							// +1
	adc	$.doTarget
	.local	=doTargetPlus
	ldx	$.doTarget+1
	stx	$.doTargetPlus+1
	sta	$.doTargetPlus

	// Copy bytes
	tyx
	dey
	smx	#0x20
b_loop:
		// Copy byte
		lda	[$.varTarget],y
		sta	[$.doTargetPlus],y

		// Next
		dey
		bpl	$-b_loop
	smx	#0x00

	// Increase table pointer (u8)
	txa
	clc
	adc	$.table
	sta	$.table

	rts


SelfMod__Apply_OrCondition:
	lda	$.condition
	asl	a
	ora	$.condition
	sta	$.condition
	rts


SelfMod__Apply_AndCondition:
	lda	$.condition
	asl	a
	and	$.condition
	sta	$.condition
	rts


SelfMod__Apply_EorCondition:
	lda	$.condition
	asl	a
	eor	$.condition
	sta	$.condition
	rts

	// ---------------------------------------------------------------------------

	// TODO: Can move this table to a place that is overwritten by the conversion
SelfMod_Table:
	.addrlow	SelfMod_Table_WritePointer
	.data8		SelfMod_EndOfList
	.def		SelfMod_Table_WritePointer		SelfMod_Table

	// ---------------------------------------------------------------------------
