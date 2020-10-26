
	// ---------------------------------------------------------------------------

Cop__Table:
	// 0x00, Wait4Vblank infinite loop
	.data16	_Cop__Wait4VblankInfinite


	.fill16	0xff, _Cop__Wait4VblankInfinite_Error

	// ---------------------------------------------------------------------------

Cop__Wait4VblankInfinite:
	//        1-2 3-5     6-7
	// Stack: dp, return, originalReturn
	.vstack		_VSTACK_START

	// Call NMI infinitely

	// Change mode
	rep	#0x31
	.mx	0x00

	// Fix for my private disassembler
	pla
	pha

	// Change DP
	phd
	lda	#_VSTACK_PAGE
	tcd

	// Get stack pointer
	tsx

	// Keep return address for RTI, minus 7 because we loop back to this call infinitely, assume carry clear then carry set
	lda	$7,s
	sbc	#0x0001
	sta	$7,s
	sta	$_StackEmu_Compare+7-0x100,x
	lda	$3,s
	sbc	#0x0008
	sta	$3,s
	sta	$_StackEmu_LowBits+7-0x100,x
	lda	$4,s
	sta	$_StackEmu_HighBits+7-0x100,x

	// Wait for next NMI
	call	Interpret__Wait4Vblank

	// Call NMI address
	.precall	Recompiler__CallFunction		_originalFunction
	phb
	lda	$_Program_Bank_3+1
	pha
	plb
	plb
	lda	$0xfffa
	sta	$.Param_originalFunction
	call
	plb

	// Write return
	iny
	lda	[$.Recompiler_FunctionList+3],y
	sta	$4,s
	dey
	lda	[$.Recompiler_FunctionList+3],y
	dec	a
	sta	$3,s

	// Return
	sep	#0x30
	pld
	rtl
	
	// ---------------------------------------------------------------------------

Cop__Wait4VblankInfinite_Error:
	bra	$-Cop__Wait4VblankInfinite_Error

