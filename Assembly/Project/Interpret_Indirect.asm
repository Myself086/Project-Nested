
	.vstack		_VSTACK_START

	// This code must be placed in a LoROM bank, non-zero bank and non-zero page

	// ---------------------------------------------------------------------------

	.macro	Interpret_Indirect_Switch		OpcodeName, IsLda
		.align	0x100
Interpret__{0}Indirect_Page:
		// Break this page into segments of 0x20 bytes
		SegmentStart	0x20
			.if {1} == 0
			{
				sta	$_Memory_NesBank
			}
			rtl

Interpret__{0}Indirect_Main:
			// Flags NZ don't matter here
			eor	$_Memory_NesBank
			sta	$_Indirect_{0}_Action
			jmp	($_Indirect_{0}_Action)
b_{0}_00_e:

		Segment
			jmp	$_Interpret__IndirectIO_{0}
b_{0}_20_e:

		Segment
			jmp	$_Interpret__IndirectIO_{0}
b_{0}_40_e:

		Segment
			.if {1} == 0
			{
				sta	$_Memory_NesBank
			}
			lda	#0xb0
			pha
			plb
			rtl
b_{0}_60_e:

		Segment
			.if {1} == 0
			{
				sta	$_Memory_NesBank
			}
			lda	$_Program_Bank_0+2
			pha
			plb
			rtl
b_{0}_80_e:

		Segment
			.if {1} == 0
			{
				sta	$_Memory_NesBank
			}
			lda	$_Program_Bank_1+2
			pha
			plb
			rtl
b_{0}_a0_e:

		Segment
			.if {1} == 0
			{
				sta	$_Memory_NesBank
			}
			lda	$_Program_Bank_2+2
			pha
			plb
			rtl
b_{0}_c0_e:

		Segment
			.if {1} == 0
			{
				sta	$_Memory_NesBank
			}
			lda	$_Program_Bank_3+2
			pha
			plb
			rtl
b_{0}_e0_e:

		SegmentEnd
	.endm

	Interpret_Indirect_Switch	Ora, 0
	Interpret_Indirect_Switch	And, 0
	Interpret_Indirect_Switch	Eor, 0
	Interpret_Indirect_Switch	Adc, 0
	Interpret_Indirect_Switch	Lda, 1
	Interpret_Indirect_Switch	Cmp, 0
	Interpret_Indirect_Switch	Sbc, 0

	// ---------------------------------------------------------------------------

	.align	0x100

Interpret__StaIndirect_Page:
	// Break this page into segments of 0x20 bytes
	SegmentStart	0x20
		sta	$_Memory_NesBank
		rtl
b_sta_00_e:

	Segment
		jmp	$_Interpret__IndirectIO_sta
b_sta_20_e:

	Segment
		jmp	$_Interpret__IndirectIO_sta
b_sta_40_e:

	Segment
		sta	$_Memory_NesBank
		lda	#0xb0
		pha
		plb
		rtl
b_sta_60_e:

	Segment
		jmp	$_Interpret__IndirectIO_sta
b_sta_80_e:

	Segment
		jmp	$_Interpret__IndirectIO_sta
b_sta_a0_e:

	Segment
		jmp	$_Interpret__IndirectIO_sta
b_sta_c0_e:

	Segment
		jmp	$_Interpret__IndirectIO_sta
b_sta_e0_e:

	SegmentEnd

	// ---------------------------------------------------------------------------

Interpret__IndirectIO_PageTable:
	.data16	Interpret__OraIndirect_Main
	.data16	Interpret__AndIndirect_Main
	.data16	Interpret__EorIndirect_Main
	.data16	Interpret__AdcIndirect_Main
	.data16	0
	.data16	Interpret__LdaIndirect_Main
	.data16	Interpret__CmpIndirect_Main
	.data16	Interpret__SbcIndirect_Main

	// ---------------------------------------------------------------------------

	// Put the following code in between segments
	.pushaddr
		.macro	Interpret_WriteWithinSegment	addr
			.addr	{0}, {0}|0x1f
		.endm

		.mx	0x30

		Interpret_WriteWithinSegment	b_sta_00_e
Inline_LoadIndirect:
		lda	$0xff
		and	#0xe0
		eor	$_Memory_NesBank
		beq	$+b_1
			jsr	$=Interpret_LoadIndirect
b_1:
		.data8	0

Inline_LoadIndirectX:
		lda	$0xff,X
		and	#0xe0
		eor	$_Memory_NesBank
		beq	$+b_1
			jsr	$=Interpret_LoadIndirect
b_1:
		.data8	0


		Interpret_WriteWithinSegment	b_sta_20_e
Inline_CmdIndirect:
		xba
		lda	$0xff
		and	#0xe0
		eor	$_Memory_NesBank
		beq	$+b_1
Inline_CmdIndirect_Call:
			jsr	$=Interpret_LoadIndirect
b_1:
		xba
		.data8	0


		Interpret_WriteWithinSegment	b_sta_40_e
Inline_CmdIndirectX:
		xba
		lda	$0xff,X
		and	#0xe0
		eor	$_Memory_NesBank
		beq	$+b_1
			jsr	$=Interpret_LoadIndirect
b_1:
		xba
		.data8	0


		Interpret_WriteWithinSegment	b_sta_60_e
Interpret_LoadIndirect:
		// Flags NZ don't matter here
		eor	$_Memory_NesBank
Interpret_LoadIndirectCmp:
		sta	$_Memory_NesBank
		//sta	$_Indirect_Lda_Action
		jmp	($_Indirect_Lda_Action)


		.mx	0x30

		Interpret_WriteWithinSegment	b_sta_80_e
Inline_StoreIndirect:
		php
		xba
		lda	$0xff
		and	#0xe0
		cmp	$_Memory_NesBank
		beq	$+b_1
			jsr	$=Interpret_StoreIndirectCmp
b_1:
		xba
		plp
		.data8	0


		Interpret_WriteWithinSegment	b_sta_a0_e
Interpret_StoreIndirect:
		// Flags NZ don't matter here
		eor	$_Memory_NesBank
Interpret_StoreIndirectCmp:
		//sta	$_Memory_NesBank		// Writing this was moved to individual cases because it isn't necessary for IO ranges
		sta	$_Indirect_Sta_Action
		jmp	($_Indirect_Sta_Action)

		// Done placing code between segments
	.pulladdr

	// ---------------------------------------------------------------------------

Interpret_IndirectIO_trap:
	trap
	Exception	"Indirect IO Access Fail{}{}{}Unable to find target address."

	.macro	Interpret_IndirectIO	OpcodeInput, FixStack
		.mx	0x30
		phd
		phy
		phx
		xba
		pha
		php		// Can be removed if this code can avoid changing P.c and P.v

		tsc
		tcd

		// Find ZP address
		lda	#.Zero+{0}
		inc16dp	0x07
		cmp	[$0x07]
		beq	$+b_1
			inc16dp	0x07
			cmp	[$0x07]
			beq	$+b_1
				inc16dp	0x07
				cmp	[$0x07]
				beq	$+b_1
					jmp	$_Interpret_IndirectIO_trap
b_1:

		// Load ZP address and adjust return address in order to skip the indirect access
		inc16dp	0x07
		lda	[$0x07]
		tax

		// Get target address
		rmx	#0x01
		tya
		adc	$0x0000,x
		tax

		.if {1} != 0
		{
			// Fix return stack while A and Y are free
			// Before: r0, r1, r2, p
			// After:  p,  r0, r1, r2
			ldy	$0x07
			lda	$0x09
			xba
			sta	$0x07
			sta	$0x09
			sty	$0x08
		}

		// Get call pointer, uses X register from above
		lda	#_VSTACK_PAGE
		tcd
		.if {0} == 0x91
		{
			ldy	#_iIOPort_sta*2
		}
		.else
		{
			ldy	#_iIOPort_lda*2
		}
		call	Recompiler__GetIOAccess
		// Load 24-bit call pointer
		ldx	$.DP_ZeroBank-1
		stx	$_InterpretIO_Action+1
		sta	$_InterpretIO_Action

		// Done and call
		.mx	0x30
		plp
		pla
		plx
		ply
		pld
		jsr	$=InterpretIO_Action_JMP
		.if {1} != 0
		{
			plp
		}
	.endm

	// ---------------------------------------------------------------------------

Interpret__IndirectIO_Ora:
	Interpret_IndirectIO	0x11, 0
	ora	$_IO_Temp
	rtl

Interpret__IndirectIO_And:
	Interpret_IndirectIO	0x31, 0
	and	$_IO_Temp
	rtl

Interpret__IndirectIO_Eor:
	Interpret_IndirectIO	0x51, 0
	eor	$_IO_Temp
	rtl

Interpret__IndirectIO_Adc:
	Interpret_IndirectIO	0x71, 0
	adc	$_IO_Temp
	rtl

Interpret__IndirectIO_Sta:
	Interpret_IndirectIO	0x91, 1
	rtl

Interpret__IndirectIO_Lda:
	Interpret_IndirectIO	0xb1, 0
	lda	$_IO_Temp
	stz	$_Memory_NesBank			// Clear memory range represented by DB
	rtl

Interpret__IndirectIO_Cmp:
	Interpret_IndirectIO	0xd1, 0
	cmp	$_IO_Temp
	rtl

Interpret__IndirectIO_Sbc:
	Interpret_IndirectIO	0xf1, 0
	sbc	$_IO_Temp
	rtl

	// ---------------------------------------------------------------------------
