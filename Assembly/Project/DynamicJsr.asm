
	// ---------------------------------------------------------------------------

	.mx	0x30

Inline__TestBank1:
	php
	xba
Inline__TestBank1_BankNum:
	lda	$_Program_BankNum
Inline__TestBank1_BankValue:
	cmp	#0xff
	bne	$+b_1
		xba
		plp
Inline__TestBank1_Destination:
		jmp	$=Inline__TestBank1_Trap
b_1:
	jsr	$=DynamicJsr__NewJsrLink
Inline__TestBank1_OriginalCall:
	pea	$0x1337
Inline__TestBank1_Trap:
	trap
Inline__TestBank1_End:


Inline__TestBank2:
Inline__TestBank2_BankValue:
	cmp	#0xff
	bne	$+b_1
		xba
		plp
Inline__TestBank2_Destination:
		jmp	$=Inline__TestBank2_Trap
b_1:
	jsr	$=DynamicJsr__NewJsrLink
Inline__TestBank2_OriginalCall:
	pea	$0x8964
Inline__TestBank2_Trap:
	trap
Inline__TestBank2_End:


	.mx	0x00
	.func	DynamicJsr__CreateJsrLink
	// Entry: A = Original call
	// Return: A = Link address bank, X = Link address
DynamicJsr__CreateJsrLink:
	.local	=call
	sta	$.call

	// Allocate memory for some extra code
	lda	#0x007f
	ldx	#_Inline__TestBank1_End-Inline__TestBank1
	call	Memory__Alloc
	.local	=extraCode
	stx	$.extraCode
	sta	$.extraCode+2

	// Copy our extra code
	lda	#0
	smx	#0x30
	ldy	#.Inline__TestBank1_End-Inline__TestBank1-1
b_loop:
		tyx
		lda	$=Inline__TestBank1,x
		sta	[$.extraCode],y
		dey
		bpl	$-b_loop

	// Write bank comparison constants
	lda	$.call+1
	and	#0xe0
	tax
	ldy	#.Inline__TestBank1_BankNum-Inline__TestBank1+1
	ora	[$.extraCode],y
	sta	[$.extraCode],y
	lda	$_Program_BankNum,x
	ldy	#.Inline__TestBank1_BankValue-Inline__TestBank1+1
	sta	[$.extraCode],y
	sta	$.call+2

	smx	#0x00

	// Write original call
	lda	$.call
	ldy	#_Inline__TestBank1_OriginalCall-Inline__TestBank1+1
	sta	[$.extraCode],y

	// Find destination
	//lda	$.call
	Recompiler__CallFunction	"//"

	// Write destination
	lda	[$.Recompiler_FunctionList+3],y
	tax
	iny
	lda	[$.Recompiler_FunctionList+3],y
	ldy	#_Inline__TestBank1_Destination-Inline__TestBank1+2
	sta	[$.extraCode],y
	txa
	dey
	sta	[$.extraCode],y

	// Return link object
	ldx	$.extraCode+0
	lda	$.extraCode+2
	and	#0x00ff
	return


	.mx	0x30
DynamicJsr__NewJsrLink:
	.vstack		_VSTACK_START
	.local	_a, _x, _y, _dp
	.local	.dummy, =return, .p, 4 extraCode, =call
	// NOTE: 'p' must be just before 'extraCode'
	php
	lock

	// Push registers
	smx	#0x10
	sta	$_a
	tdc
	sta	$_dp
	lda	#_VSTACK_PAGE
	tcd
	stx	$.x
	sty	$.y

	// Get original call and fix stack
	pla
	sta	$.p
	sta	$.return-1
	pla
	sta	$.return+1
	ldy	#2
	lda	[$.return],y
	sta	$.call

	smx	#0x00

	// Allocate memory for some extra code
	lda	#0x007f
	ldx	#_Inline__TestBank2_End-Inline__TestBank2
	call	Memory__Alloc
	stx	$.extraCode
	sta	$.extraCode+2

	// Copy our extra code
	lda	#0
	smx	#0x30
	ldy	#.Inline__TestBank2_End-Inline__TestBank2-1
b_loop:
		tyx
		lda	$=Inline__TestBank2,x
		sta	[$.extraCode],y
		dey
		bpl	$-b_loop

	// Write bank comparison constants
	lda	$.call+1
	and	#0xe0
	tax
	lda	$_Program_BankNum,x
	ldy	#.Inline__TestBank2_BankValue-Inline__TestBank2+1
	sta	[$.extraCode],y
	sta	$.call+2

	smx	#0x00

	// Write original call
	lda	$.call
	ldy	#_Inline__TestBank2_OriginalCall-Inline__TestBank2+1
	sta	[$.extraCode],y

	// Find destination
	//lda	$.call
	Recompiler__CallFunction	"//"

	// Write destination
	lda	[$.Recompiler_FunctionList+3],y
	tax
	iny
	lda	[$.Recompiler_FunctionList+3],y
	ldy	#_Inline__TestBank2_Destination-Inline__TestBank2+2
	sta	[$.extraCode],y
	txa
	dey
	sta	[$.extraCode],y

	// Link to previous bank test
	lda	$.return
	sec
	sbc	#3
	sta	$.return
	lda	$.extraCode+1
	ldy	#2
	sta	[$.return],y
	lda	$.extraCode+0
	dey
	sta	[$.return],y
	// Are the 2 tests in the same bank?
	smx	#0x30
	lda	$.return+2
	eor	$.extraCode+2
	beq	$+b_else
		// Long jump
		lda	#0x5c
		bra	$+b_1
b_else:
		// Short jump
		lda	#0x4c
b_1:
	sta	[$.return]
	smx	#0x10

	// Return to our new link
	pei	($.extraCode+1)
	pei	($.extraCode-1)
	ldx	$.x
	ldy	$.y
	lda	$.dp
	tcd
	lda	$_a
	rti

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	DynamicJsr__IsRangeStatic
DynamicJsr__IsRangeStatic:
	// Entry: A = Source address, Y = Destination address
	// Return: Carry = true when static

	.local	_dest
	sty	$.dest

	// Are source and destination in the same range?
	eor	$.dest
	and	$=RomInfo_PrgBankingMask
	bne	$+b_1
		// Same range
		sec
		return
b_1:

	lda	$=RomInfo_StaticRanges

	// Test bit 15 (must be set)
	asl	$.dest
	bcs	$+b_else
		// Invalid destination range
		clc
		return
b_else:
		lsr	a
		lsr	a
		lsr	a
		lsr	a
b_1:

	// Test bit 14
	asl	$.dest
	bcc	$+b_1
		lsr	a
		lsr	a
b_1:

	// Test bit 13
	asl	$.dest
	bcc	$+b_1
		lsr	a
b_1:

	// Return whether target range is considered static
	lsr	a
	return

	// ---------------------------------------------------------------------------
