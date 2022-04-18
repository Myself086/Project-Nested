
	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Feedback__Init
Feedback__Init:
	.local	=source, =destination
	.local	_compare

	php
	rep	#0x30

	// Is feedback active?
	lda	$_Feedback_Active-1
	bmi	$+b_in
		plp
		return
b_in:

	// Load source and destination
	lda	#_Rom_Title
	sta	$.source
	lda	#_Rom_Title/0x10000+Feedback_Start*0x100
	sta	$.source+2
	lda	#_Feedback_Start/0x100
	sta	$.destination+1

	// Copy SNES ROM title (emulator's name)
	ldy	#_Feedback_EmulatorName_LENGTH
	jsr	$_Feedback__Init_Copy
	sta	$.compare

	// Copy SNES ROM version (emulator version)
	lda	#_Rom_Version
	sta	$.source
	lda	#_Rom_Version/0x100
	sta	$.source+1
	ldy	#_Feedback_EmulatorVersion_LENGTH
	jsr	$_Feedback__Init_Copy
	ora	$.compare
	sta	$.compare

	// Copy NES ROM title
	lda	#_RomInfo_GameName
	sta	$.source
	lda	#_RomInfo_GameName/0x100
	sta	$.source+1
	ldy	#_Feedback_ProfileName_LENGTH
	jsr	$_Feedback__Init_Copy
	ora	$.compare

	// Was feedback header correct?
	beq	$+b_1
		// Erase feedback address and return
		lda	#_Feedback_Calls_LowerBound
		sta	$=Feedback_Calls_Write
		sta	$=Feedback_Calls_Top
		plp
		return
b_1:

	// Is feedback write pointer correct?
	lda	$=Feedback_Calls_Write
	sec
	sbc	#0x6000
	cmp	#0x2000
	bcc	$+b_1
		// Erase feedback address and return
		lda	#_Feedback_Calls_LowerBound
		sta	$=Feedback_Calls_Write
b_1:

	// Is feedback top pointer correct?
	lda	$=Feedback_Calls_Top
	sec
	sbc	#0x6000
	cmp	#0x2000
	bcc	$+b_1
		// Erase feedback address and return
		lda	$=Feedback_Calls_Write
		sta	$=Feedback_Calls_Top
b_1:

	plp
	return


	// Entry: Y = Length
	// Return: A = Comparison
Feedback__Init_Copy:
	// Compare old and new data
	.local	_cmp
	stz	$.cmp

	// Add length for returned destination address
	tya
	clc
	adc	$.destination
	tax

	// Is Y odd? If so, process one individual byte
	tya
	lsr	a
	bcc	$+Feedback__Init_Copy_SkipOdd
		dey
		smx	#0x20
		lda	[$.source],y
		eor	[$.destination],y
		tsb	$.cmp
		eor	[$.destination],y
		sta	[$.destination],y
		smx	#0x00
Feedback__Init_Copy_SkipOdd:

	bra	$+Feedback__Init_Copy_Loop_Entry
Feedback__Init_Copy_Loop:
		lda	[$.source],y
		eor	[$.destination],y
		tsb	$.cmp
		eor	[$.destination],y
		sta	[$.destination],y
Feedback__Init_Copy_Loop_Entry:
		dey
		dey
		bpl	$-Feedback__Init_Copy_Loop

	// Write destination address and return
	stx	$.destination
	lda	$.cmp
	rts
	
	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Feedback__Add
	// Entry: X = Address, Y = Bank number
Feedback__Add:
	WDM_AddFeedback

	// Is feedback active?
	lda	$_Feedback_Active-1
	bmi	$+b_in
		return
b_in:

	// Set up destination address for writing
	.local	=pointer
	lda	#_Feedback_Calls_Write/0x100
	sta	$.pointer+1
	lda	$=Feedback_Calls_Write
	beq	$+Feedback__Add_Return
	sta	$.pointer

	// Increment address
	clc
	adc	#_Feedback_Inc

	// Are we past the top?
	cmp	#_Feedback_Calls_UpperBound+1
	bcc	$+b_1
		// Wrap feedback
		lda	#_Feedback_Calls_LowerBound
b_1:

	// Write address back
	sta	$=Feedback_Calls_Write

	// Adjust top address
	cmp	$=Feedback_Calls_Top
	bcc	$+b_1
		sta	$=Feedback_Calls_Top
b_1:

	// Write lower bytes
	txa
	sta	[$.pointer]

	// Write upper bytes and free Y in the process
	tya
	smx	#0x30
	ldy	#2
	sta	[$.pointer],y
	smx	#0x00

Feedback__Add_Return:
	return

	// ---------------------------------------------------------------------------
