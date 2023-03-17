
	// ---------------------------------------------------------------------------

	.mx	0x00
JMPi__Listing:
JMPi__Listing_Compare:
		cmp	#0xffff
		bne	$+b_1
JMPi__Listing_Pull:
			lda	$_IO_Temp
			plp
JMPi__Listing_Destination:
			jmp	$=JMPi__Listing_Destination
b_1:
JMPi__Listing_Next:
		jmp	$=JMPi__Listing_Next
JMPi__Listing_End:

	// Incremental step constant
	.def	JMPi_Inc	JMPi__Listing_End-JMPi__Listing

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	JMPi__Init
JMPi__Init:
	php
	rep	#0x30

	// Is feedback active?
	lda	$_Feedback_Active-1
	bpl	$+b_else
		// Use feedback bank
		lda	#_JMPi_InitialPoolBottomValue/0x100
		sta	$_JMPi_EmptyPointer+1
		sta	$_JMPi_CurrentPoolTop+1
		lda	#_JMPi_InitialPoolBottomValue
		sta	$_JMPi_EmptyPointer
		lda	#_JMPi_InitialPoolTopValue
		sta	$_JMPi_CurrentPoolTop
		bra	$+b_1
b_else:
		// Wait for new pool to be generated
		stz	$_JMPi_EmptyPointer
		stz	$_JMPi_EmptyPointer+1
		stz	$_JMPi_CurrentPoolTop
b_1:

	// Reset pointers to the linker
	ldx	#0x08fd
	ldy	#_JMPi__LinkerEntryTable+JMPi__LinkerEntryTable_Inc*0x2ff
b_loop:
		lda	#_JMPi__LinkerEntryTable/0x100
		sta	$=JMPi_Start+1,x
		tya
		sta	$=JMPi_Start+0,x
		sec
		sbc	#_JMPi__LinkerEntryTable_Inc
		tay
		dex
		dex
		dex
		bpl	$-b_loop

	plp
	return

	// ---------------------------------------------------------------------------

	.vstack		_VSTACK_START
	.local	_a, _x, _y, _rawLSB
	.mx	0x10

	.def	temp__	0
	.def	temp2__	0
	.macro	JMPi__Linker_mac
		lock
		sta	$_a
		lda	#_temp__*0x100+temp2__
		jmp	$_JMPi__Linker_in
		.def	temp__	temp__+1
	.endm

JMPi__LinkerEntryTable:
	JMPi__Linker_mac
b_1:
	.def	JMPi__LinkerEntryTable_Inc		b_1-JMPi__LinkerEntryTable
	.repeat		0x0ff, "JMPi__Linker_mac"
	.def		temp2__		0x01
	.repeat		0x100, "JMPi__Linker_mac"
	.repeat		0x100, "JMPi__Linker_mac"

	.mx	0x10
JMPi__Linker_in:
	lock

	// Write jump destination's LSB
	sta	$_rawLSB

	// Fix stack and push
	//sta	$_a
	stz	$_a+1
	stx	$_x
	sty	$_y
	plx		// Pull P
	phd
	phk
	phx
	phb

	// Change mode
	rep	#0x30
	.mx	0x00

	// Remove interrupt flag
	pla
	and	#0xfbff
	pha

	// Change dp
	lda	#_VSTACK_PAGE
	tcd

	unlock

	// Get function pointer
	lda	$.rawLSB
	lsr	a				// Carry set when using RtsNes
	lda	$.rawLSB
	and	#0xff00
	ora	$.a
	xba
	adc	#0				// Add 1 if RtsNes
	cmp	$_Recompile_PrgRamTopRange
	bcc	$+b_else
		Recompiler__CallFunction	"//"

		// Add node for JMPi and change return address
		.precall	JMPi__Add	=originalCall, =newAddr
		lda	[$.Recompiler_FunctionList+3],y
		sta	$3,s
		sta	$.Param_newAddr+0
		iny
		lda	[$.Recompiler_FunctionList+3],y
		sta	$4,s
		sta	$.Param_newAddr+1
		// Original address
		dey
		dey
		dey
		lda	[$.Recompiler_FunctionList+3],y
		sta	$.Param_originalCall+1
		dey
		lda	[$.Recompiler_FunctionList+3],y
		sta	$.Param_originalCall+0

		bra	$+b_1
b_else:
		// Add interpreted destination
		stz	$.Param_newAddr+0
		stz	$.Param_newAddr+1
		tay
		xba
		and	#0x00e0
		tax
		lda	$_Program_BankNum-1,x
		sta	$.Param_originalCall+1
		sty	$.Param_originalCall+0
		sty	$_IO_Temp16

		lda	#_JMPi__Interpreter_FirstIteration
		sta	$3,s
		lda	#_JMPi__Interpreter_FirstIteration/0x100
		sta	$4,s
b_1:
	lda	$.rawLSB
	lsr	a			// Set carry if RtsNes
	call

	// Return
	ldy	$.y
	ldx	$.x
	lda	#0
	tcd
	lda	$_IO_Temp
	plb
	rti

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	JMPi__Add	=originalCall, =newAddr
	// Entry: Carry = true when using non-native RTS
JMPi__Add:
	.local	_useRtsNes			// True when negative
	.local	=nodeAddr, =oldNodeAddr
	.local	=originalCallCmp

	ror	$.useRtsNes

	// Reserve another node
	lda	$=JMPi_EmptyPointer+1
	sta	$.nodeAddr+1
	lda	$=JMPi_EmptyPointer
	sta	$.nodeAddr
	clc
	adc	#_JMPi_Inc
	sta	$=JMPi_EmptyPointer

	// Do we have enough space for the new node?
	cmp	$=JMPi_CurrentPoolTop
	bcc	$+b_1
		// Create new pool
		lda	#0x007f
		ldx	#_JMPi_PoolSize
		call	Memory__Alloc

		xba
		sta	$=JMPi_EmptyPointer+1
		sta	$.nodeAddr+1
		sta	$=JMPi_CurrentPoolTop+1
		txa
		sta	$.nodeAddr
		clc
		adc	#_JMPi_PoolSize
		sta	$=JMPi_CurrentPoolTop

		// Reserve another node
		txa
		clc
		adc	#_JMPi_Inc
		sta	$=JMPi_EmptyPointer
b_1:

	// Copy code template
	smx	#0x30
	ldx	#.JMPi_Inc-1
b_loop:
		lda	$=JMPi__Listing,x
		txy
		sta	[$.nodeAddr],y
		dex
		bpl	$-b_loop
	smx	#0x00

	// Copy original call
	lda	$.originalCall+1
	sta	$.originalCallCmp+1
	lda	$.originalCall
	sta	$.originalCallCmp

	// Get base array offset
	.local	_temp
	//lda	$.originalCall
	bit	$.useRtsNes
	bpl	$+b_else
		dec	$.originalCallCmp
		dec	a
		bit	#0x2000
		beq	$+b_else2
			// High range
			and	#0x00ff
			ora	#0x0200
			bra	$+b_1
b_else2:
			// Low range
			and	#0x00ff
			ora	#0x0100
			bra	$+b_1
b_else:
		and	#0x00ff
b_1:
	sta	$.temp
	asl	a
	adc	$.temp
	tax
	.unlocal	_temp

	// Replace base pointer to the new node
	lda	$_JMPi_Start,x
	sta	$.oldNodeAddr
	lda	$_JMPi_Start+1,x
	sta	$.oldNodeAddr+1
	lda	$.nodeAddr
	sta	$_JMPi_Start,x
	lda	$.nodeAddr+1
	sta	$_JMPi_Start+1,x

	// Are we linking to a different bank?
	lda	$.oldNodeAddr+1
	eor	$.nodeAddr+1
	and	#0xff00
	beq	$+b_else
		// Link across banks
		lda	$.oldNodeAddr
		ldy	#_JMPi__Listing_Next-JMPi__Listing+1
		sta	[$.nodeAddr],y
		lda	$.oldNodeAddr+1
		iny
		sta	[$.nodeAddr],y

		bra	$+b_1
b_else:
		// Link within bank
		lda	#0x004c
		ldy	#_JMPi__Listing_Next-JMPi__Listing
		sta	[$.nodeAddr],y
		lda	$.oldNodeAddr
		iny
		sta	[$.nodeAddr],y

		// Use one fewer byte for this node
		lda	$=JMPi_EmptyPointer
		dec	a
		sta	$=JMPi_EmptyPointer
b_1:

	// Write compare
	lda	$.originalCallCmp+1
	ldy	#_JMPi__Listing_Compare-JMPi__Listing+1
	sta	[$.nodeAddr],y

	// Is destination interpreted?
	lda	$.newAddr+0
	ora	$.newAddr+1
	bne	$+b_else
		// Call interpreter like this:
		//  pea	...
		//  jmp Interpreter

		// Write opcodes
		lda	#0x5cf4
		ldy	#_JMPi__Listing_Pull-JMPi__Listing+0
		sta	[$.nodeAddr],y
		ldy	#_JMPi__Listing_Pull-JMPi__Listing+2
		sta	[$.nodeAddr],y

		// Write original call
		lda	$.originalCall
		dey
		sta	[$.nodeAddr],y

		// Write interpreter's address
		lda	#_JMPi__Interpreter
		ldy	#_JMPi__Listing_Pull-JMPi__Listing+4
		sta	[$.nodeAddr],y
		lda	#_JMPi__Interpreter/0x100
		iny
		sta	[$.nodeAddr],y

		bra	$+b_1
b_else:
		// Write destination
		lda	$.newAddr+0
		ldy	#_JMPi__Listing_Destination-JMPi__Listing+1
		sta	[$.nodeAddr],y
		lda	$.newAddr+1
		iny
		sta	[$.nodeAddr],y
b_1:

	return

	// ---------------------------------------------------------------------------

JMPi__Interpreter:
	sep	#0x30
	lda	$_IO_Temp
	jmp	$=Interpreter__Execute

JMPi__Interpreter_FirstIteration:
	php
	lda	$_IO_Temp16+1
	pha
	lda	$_IO_Temp16+0
	pha
	jmp	$=Interpreter__Execute

	// ---------------------------------------------------------------------------
