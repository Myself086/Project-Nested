
	// ---------------------------------------------------------------------------

	.macro	Gui__WriteTextFormat	text, left, top, right
		.precall	Gui__WriteTextFormat
		ldy	#_Zero+{0}
		lda	#_Zero+{1}
		sta	$.Param_left
		lda	#_Zero+{3}+1
		sta	$.Param_right
		lda	#_Zero+{2}
		sta	$.Param_top
		call
	.endm

	.macro	Gui__WriteTextFormatY	left, top, right
		.precall	Gui__WriteTextFormat
		lda	#_Zero+{0}
		sta	$.Param_left
		lda	#_Zero+{2}+1
		sta	$.Param_right
		lda	#_Zero+{1}
		sta	$.Param_top
		call
	.endm

	.mx	0x00
	.func	Gui__WriteTextFormat	_left, _right, _top
	// Entry: Y = source
Gui__WriteTextFormat:
	.local	_x, _y
	.local	_wordIndex, 32 wordBuffer
	.local	_source

	stz	$.wordIndex

	lda	#0
	smx	#0x20

	ldx	$.top
	stx	$.y

	//bra	$+b_loop1_in
b_loop1:
b_loop1_in:
		ldx	$.left
		stx	$.x

		// Start reading text
		bra	$+b_loop2_in
b_loop2:
			// Is it '{'?
			cmp	#0x7b
			bne	$+b_1
				// Is it followed by '}'?
				iny
				lda	[$.Debug_ReadBank],y
				cmp	#0x7d
				bne	$+b_2
					iny
					jsr	$_Gui__WriteTextFormat_WriteWord

					// New line
					inc	$.y
					bra	$-b_loop1
b_2:
				jsr	$_Gui__WriteTextFormat_Formatting
				bra	$+b_loop2_next
b_1:

			// Is it ' '?
			cmp	#0x20
			bne	$+b_1
				jsr	$_Gui__WriteTextFormat_WriteWord
				bra	$+b_loop2_next
b_1:

			// Default character, write it directly
			ldx	$.wordIndex
			sta	$.wordBuffer,x
			inx
			stx	$.wordIndex

b_loop2_next:
			// Next character
			iny
b_loop2_in:
			lda	[$.Debug_ReadBank],y
			bne	$-b_loop2
b_exit:
	jsr	$_Gui__WriteTextFormat_WriteWord

	smx	#0x00

	return


	.mx	0x20
	// Returns carry true if the text was written to a new line
Gui__WriteTextFormat_WriteWord:
	.local	_rtn, _keepY
	stz	$.rtn
	sty	$.keepY

	rmx	#0x01

	// Is there enough space on this word?
	lda	$.wordIndex
	clc
	adc	$.x
	cmp	$.right
	bcc	$+b_1
		inc	$.y
		lda	$.left
		sta	$.x
		dec	$.rtn
b_1:

	// Locate cursor
	lda	$.y
	xba
	lsr	a
	lsr	a
	lsr	a
	ora	$.x
	asl	a
	tax
	Gui__MarkLine

	ldy	#0
	cpy	$.wordIndex
	bcs	$+b_exit
b_loop:
		lda	$_wordBuffer,y
		and	#0x00ff
		ora	$.Debug_TileAttribute
		sta	$=Debug_NameTable,x
		inx
		inx
		iny
		cpy	$.wordIndex
		bcc	$-b_loop
b_exit:

	// Move cursor X position
	lda	$.x
	clc
	adc	$.wordIndex
	sta	$.x
	stz	$.wordIndex

	// Write space if X isn't too far to the right
	//lda	$.x
	cmp	$.right
	bcs	$+b_1
		lda	#0x0020
		ora	$.Debug_TileAttribute
		sta	$=Debug_NameTable,x
b_1:
	inc	$.x

	// Return
	lda	#0
	smx	#0x20
	ldy	$.keepY
	asl	$.rtn
	rts
	.unlocal	_rtn, _keepY


	.macro	Gui__WriteTextFormat_Call_FindElement	list, compareString, length, outObject
		.precall	Dict__FindElement		=list, =compareString, .length
		ldx	#_{0}
		stx	$.Param_list
		lda	#.{0}/0x10000
		sta	$.Param_list+2
		ldx	$.{1}
		stx	$.Param_compareString
		lda	$.{1}+2
		sta	$.Param_compareString+2
		lda	$.{2}
		sta	$.Param_length
		smx	#0x00
		call
		and	#0x00ff
		smx	#0x20
		stx	$.{3}
		sta	$.{3}+2
		// Carry true when element isn't null
	.endm

	.mx	0x20
Gui__WriteTextFormat_Formatting:
	.local	=varPointer, _varSize, =varObject, =var
	.local	=formatPointer, _formatSize, =formatObject

	stz	$.varSize
	stz	$.formatSize

	// Copy variable pointer and part of format pointer
	lda	$.Debug_ReadBank+2
	sta	$.formatPointer+2
	sta	$.varPointer+2
	sty	$.varPointer

	bra	$+b_loop_in
b_loop:
		// Is it ':'?
		cmp	#0x3a
		bne	$+b_1
			// Calculate variable name length, assume carry set from CMP+BNE
			tya
			sbc	$.varPointer
			sta	$.varSize

			// Write format pointer
			iny
			sty	$.formatPointer
			dey

b_loop2:
				// Next character
				iny
				lda	[$.Debug_ReadBank],y
				cmp	#0x7d
				bne	$-b_loop2

			// Calculate format name length, assume carry set from CMP+BNE
			tya
			sbc	$.varPointer
			clc
			sbc	$.varSize
			sta	$.formatSize

			bra	$+b_exit
b_1:

		// Next character
		iny
b_loop_in:
		lda	[$.Debug_ReadBank],y
		cmp	#0x7d
		bne	$-b_loop

	// Calculate variable name length, assume carry set from CMP+BNE
	tya
	sbc	$.varPointer
	sta	$.varSize

b_exit:
	// Find variable
	sty	$.source
	Gui__WriteTextFormat_Call_FindElement	Gui__WriteTextFormat_VarList, varPointer, varSize, varObject
	bcc	$+b_1
		lda	[$.varObject]
		sta	$.var+0
		ldy	#1
		lda	[$.varObject],y
		sta	$.var+1
		iny
		lda	[$.varObject],y
		sta	$.var+2
		iny
		lda	[$.varObject],y
		asl	a
		tax
		jsr	($_Gui__WriteTextFormat_Formatting_Switch,x)
b_1:
	ldy	$.source
	rts


Gui__WriteTextFormat_Rts:
	rts


Gui__WriteTextFormat_Formatting_Switch:
	switch	0x80, Gui__WriteTextFormat_Rts, Gui__WriteTextFormat_Rts
		case	0
			// String zero (TODO: Support breaking into a new line with spaces)
			ldy	#0
			ldx	$.wordIndex
			bra	$+b_loop_in
b_loop:
				sta	$.wordBuffer,x
				inx
				iny
b_loop_in:
				// Next
				lda	[$.var],y
				bne	$-b_loop
			stx	$.wordIndex
			rts
		cases	1, 4
			Gui__WriteTextFormat_Call_FindElement	Gui__WriteTextFormat_Formatting_NumFormat, formatPointer, formatSize, formatObject
			bcc	$+b_1
				jmp	[$_formatObject]
b_1:
			// TODO: Format not found
			rts


	.mx	0x20
Gui__WriteTextFormat_Formatting_NumFormat:
	Dict_Case	""
		// TODO
		rts
	Dict_Case	"x"
		lda	#0x26
		bra	$+b_in
	Dict_Case	"X"
		lda	#0x06
b_in:
		.local	.letterAdd, .byteCount
		sta	$.letterAdd
		ldy	#3
		lda	[$.varObject],y
		sta	$.byteCount

		// Loop through each byte
		ldx	$.wordIndex
b_loop:
			// Next byte
			dec	$.byteCount
			bmi	$+b_exit

			// Load byte offset
			ldy	$.byteCount

			// Write high nibble
			lda	[$.var],y
			lsr	a
			lsr	a
			lsr	a
			lsr	a
			cmp	#0x0a
			bcc	$+b_1
				// Letters A-F, assume carry set from BCC
				adc	$.letterAdd
b_1:
			// Add digit offset, assume carry clear from BCC and ADC
			adc	#0x30
			sta	$.wordBuffer,x
			inx

			// Write low nibble
			lda	[$.var],y
			and	#0x0f
			cmp	#0x0a
			bcc	$+b_1
				// Letters A-F, assume carry set from BCC
				adc	$.letterAdd
b_1:
			// Add digit offset, assume carry clear from BCC and ADC
			adc	#0x30
			sta	$.wordBuffer,x
			inx

			bra	$-b_loop
b_exit:

		// Store word index
		stx	$.wordIndex

		rts
		.unlocal	.letterAdd, .byteCount

	// End Dict_Case chain
	Dict_EndCase

	// ---------------------------------------------------------------------------

Gui__WriteTextFormat_VarList:
	.macro	Gui__WriteTextFormat_VarList		Text, VarPointer, ByteSize
		Dict_NodeBegin	{0}
			// Variable pointer
			.data24		{1}
			// Length & type
			.data8		{2}
		Dict_NodeEnd
	.endm
	Gui__WriteTextFormat_VarList		"A", BlueScreen_A, 2
	Gui__WriteTextFormat_VarList		"a", BlueScreen_A, 1
	Gui__WriteTextFormat_VarList		"ah", BlueScreen_A+1, 1
	Gui__WriteTextFormat_VarList		"X", BlueScreen_X, 2
	Gui__WriteTextFormat_VarList		"x", BlueScreen_X, 1
	Gui__WriteTextFormat_VarList		"Y", BlueScreen_Y, 2
	Gui__WriteTextFormat_VarList		"y", BlueScreen_Y, 1
	Gui__WriteTextFormat_VarList		"S", BlueScreen_S, 2
	Gui__WriteTextFormat_VarList		"DP", BlueScreen_DP, 2
	Gui__WriteTextFormat_VarList		"DB", BlueScreen_DB, 1
	Gui__WriteTextFormat_VarList		"P", BlueScreen_P, 1
	Gui__WriteTextFormat_VarList		"PC", BlueScreen_PC, 3
	Gui__WriteTextFormat_VarList		"title", RomInfo_Title, 0
	Gui__WriteTextFormat_VarList		"version", RomInfo_Version, 0
	Gui__WriteTextFormat_VarList		"buildDate", RomInfo_BuildDate, 0
	Dict_Null

	// ---------------------------------------------------------------------------

