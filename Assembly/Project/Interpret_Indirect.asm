
	.vstack		_VSTACK_START

	// ---------------------------------------------------------------------------

	.align	0x100
Interpret__LoadIndirect_Page:
	// Break this page into segments of 0x20 bytes
	SegmentStart	0x20
		rtl
b_ld_00e:

	Segment
		bra	$+b_1
b_ld_20e:

	Segment
b_1:
		ora	#0x1f
		trap
		Exception	"Indirect IO Access{}{}{}An indirect load was requested to page range 0x{x:X}-0x{a:X}."
b_ld_40e:

	Segment
		lda	#0xb0
		pha
		plb
		rtl
b_ld_60e:

	Segment
		lda	$_Program_Bank_0+2
		pha
		plb
		rtl
b_ld_80e:

	Segment
		lda	$_Program_Bank_1+2
		pha
		plb
		rtl
b_ld_a0e:

	Segment
		lda	$_Program_Bank_2+2
		pha
		plb
		rtl
b_ld_c0e:

	Segment
		lda	$_Program_Bank_3+2
		pha
		plb
		rtl
b_ld_e0e:

	SegmentEnd

	// ---------------------------------------------------------------------------

	.align	0x100
Interpret__StoreIndirect_Page:
	// Break this page into segments of 0x20 bytes
	SegmentStart	0x20
		rtl
b_st_00e:

	Segment
		bra	$+b_1
b_st_20e:

	Segment
		bra	$+b_1
b_st_40e:

	Segment
		lda	#0xb0
		pha
		plb
		rtl
b_st_60e:

	Segment
b_1:
		ora	#0x1f
		trap
		Exception	"Indirect IO Access{}{}{}An indirect store was requested to page range 0x{x:X}-0x{a:X}."
b_st_80e:

	Segment
		bra	$-b_1
b_st_a0e:

	Segment
		bra	$-b_1
b_st_c0e:

	Segment
		bra	$-b_1
//b_st_e0e:

	SegmentEnd

	// ---------------------------------------------------------------------------

	// Put the following code in between segments
	// Assuming that loads are in page 0, we shouldn't be pointing to page 0 during inline
	.pushaddr

	.macro	Interpret_WriteWithinSegment	addr
		.addr	{0}, {0}|0x1f
	.endm

	// ---------------------------------------------------------------------------

	.mx	0x30

	Interpret_WriteWithinSegment	b_ld_00e
Inline_LoadIndirect:
	lda	$0xff
	and	#0xe0
	eor	$_Memory_NesBank
	beq	$+Inline_LoadIndirect_SameBank
		jsr	$=Interpret_LoadIndirect
Inline_LoadIndirect_SameBank:
	.data8	0


	Interpret_WriteWithinSegment	b_ld_20e
Inline_CmdIndirect:
	php
	xba
	lda	$0xff
	and	#0xe0
	eor	$_Memory_NesBank
	beq	$+Inline_CmdIndirect_SameBank
		jsr	$=Interpret_LoadIndirect
Inline_CmdIndirect_SameBank:
	xba
	plp
	.data8	0


	Interpret_WriteWithinSegment	b_ld_40e
Inline_LoadIndirectX:
	lda	$0xff,X
	and	#0xe0
	eor	$_Memory_NesBank
	beq	$+Inline_LoadIndirectX_SameBank
		jsr	$=Interpret_LoadIndirect
Inline_LoadIndirectX_SameBank:
	.data8	0


	Interpret_WriteWithinSegment	b_ld_60e
Inline_CmdIndirectX:
	php
	xba
	lda	$0xff,X
	and	#0xe0
	eor	$_Memory_NesBank
	beq	$+Inline_CmdIndirectX_SameBank
		jsr	$=Interpret_LoadIndirect
Inline_CmdIndirectX_SameBank:
	xba
	plp
	.data8	0


	Interpret_WriteWithinSegment	b_st_00e
Interpret_LoadIndirect:
	// Flags NZ don't matter here
	eor	$_Memory_NesBank
	sta	$_Memory_NesBank
	//sta	$_LoadIndirect_Action
	jmp	[$_LoadIndirect_Action]

	// ---------------------------------------------------------------------------

	.mx	0x30

	Interpret_WriteWithinSegment	b_ld_e0e
Inline_StoreIndirect:
	php
	xba
	lda	$0xff
	and	#0xe0
	eor	$_Memory_NesBank
	beq	$+Inline_StoreIndirect_SameBank
		jsr	$=Interpret_StoreIndirect
Inline_StoreIndirect_SameBank:
	xba
	plp
	.data8	0


	Interpret_WriteWithinSegment	b_st_20e
Interpret_StoreIndirect:
	// Flags NZ don't matter here
	eor	$_Memory_NesBank
	sta	$_Memory_NesBank
	sta	$_StoreIndirect_Action
	jmp	[$_StoreIndirect_Action]

	// ---------------------------------------------------------------------------

	// Done placing code between segments
	.pulladdr
