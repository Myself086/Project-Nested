
	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Feedback__Init
Feedback__Init:
	.local	=source, =destination
	.local	_compare

	// Load source and destination
	lda	#_Rom_Title
	sta	$.source
	lda	#_Rom_Title/0x10000+Feedback_Start*0x100
	sta	$.source+2
	lda	#_Feedback_Start/0x100
	sta	$.destination+1

	// Copy SNES ROM title (emulator's name)
	ldy	#20
	jsr	$_Feedback__Init_Copy
	sta	$.compare

	// Copy NES ROM title
	lda	#_RomInfo_GameName
	sta	$.source
	lda	#_RomInfo_GameName/0x100
	sta	$.source+1
	ldy	#40
	jsr	$_Feedback__Init_Copy
	ora	$.compare

	// Was feedback header correct?
	beq	$+Feedback__Init_SkipResetFeedback
		// Erase feedback address and return
		lda	#_Feedback_EmptyPointer+2
		sta	$=Feedback_EmptyPointer
		return
Feedback__Init_SkipResetFeedback:

	// Is cache pointer correct?
	lda	$=Feedback_EmptyPointer
	sec
	sbc	#0x6000
	cmp	#0x2000
	bcc	$+Feedback__Init_SkipResetFeedback2
		// Erase feedback address and return
		lda	#_Feedback_EmptyPointer+2
		sta	$=Feedback_EmptyPointer
		return
Feedback__Init_SkipResetFeedback2:

	// TODO: Fix Array__DeleteDuplicates
	return

	// Define an array list for sorting feedback
	.local	=list, =listBase, =listTop, _listInc

	// Set bank number
	lda	#_Feedback_EmptyPointer/0x100
	sta	$.list+1
	sta	$.listBase+1
	sta	$.listTop+1

	// Set address range
	lda	$=Feedback_EmptyPointer
	sta	$.list
	lda	#_Feedback_EmptyPointer+2
	sta	$.listBase
	lda	#_Feedback_ArrayTop
	sta	$.listTop

	// Set incremental step
	lda	#_Feedback_Inc
	sta	$.listInc

	// Delete duplicates
	ldx	#_list
	call	Array__DeleteDuplicates

	// Save pointer to SRAM
	lda	$.list
	sta	$=Feedback_EmptyPointer

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

	// Is Y odd? If so, add one
	tya
	lsr	a
	bcc	$+Feedback__Init_Copy_SkipOdd
		iny
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
	// Is native return active?
	lda	$=RomInfo_StackEmulation
	and	#_RomInfo_StackEmu_NativeReturn
	bne	$+b_1
		return
b_1:

	// Set up destination address for writing
	.local	=pointer
	lda	#_Feedback_EmptyPointer/0x100
	sta	$.pointer+1
	lda	$=Feedback_EmptyPointer
	beq	$+Feedback__Add_Return
	sta	$.pointer

	// Increment address
	clc
	adc	#_Feedback_Inc

	// Are we past the top?
	cmp	#_Feedback_ArrayTop+1
	bcs	$+Feedback__Add_Return

		// Write address back
		sta	$=Feedback_EmptyPointer

		// Write upper bytes and free Y in the process
		tya
		ldy	#0x0002
		sta	[$.pointer],y

		// Write lower bytes
		txa
		sta	[$.pointer]

Feedback__Add_Return:
	return

	// ---------------------------------------------------------------------------
