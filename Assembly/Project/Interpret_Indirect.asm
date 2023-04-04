
	.mx	0x30
	.vstack		_VSTACK_START

	// This code must be placed in a LoROM bank, non-zero bank and non-zero page

	// ---------------------------------------------------------------------------

	.macro	Interpret_Indirect_Switch		OpcodeName, IsLdaY, IndexRegister
		.align	0x100
Interpret__{0}Indirect{2}_Page:
		// Break this page into segments of 0x20 bytes
		SegmentStart	0x20
			.if {1} == 0
			{
				sta	$_Memory_NesBank
			}
			rtl

Interpret__{0}Indirect{2}_Main:
			// Flags NZ don't matter here
			eor	$_Memory_NesBank
			sta	$_Indirect{2}_{0}_Action
			jmp	($_Indirect{2}_{0}_Action)
b_{0}_00_e:

		SegmentNext
			jmp	$_Interpret__Indirect{2}IO_{0}
b_{0}_20_e:

		SegmentNext
			jmp	$_Interpret__Indirect{2}IO_{0}
b_{0}_40_e:

		SegmentNext
			.if {1} == 0
			{
				sta	$_Memory_NesBank
			}
			SelfMod_Begin
			SelfMod_IfSet	RomInfo_MemoryEmulation, RomInfo_MemEmu_StaticSram
			SelfMod_Do	+b_1__
				lda	#0xb0
				pha
				plb
				rtl
b_1__:
			SelfMod_End
			lda	$_Program_Bank_Sram+2
			pha
			plb
			rtl
b_{0}_60_e:

		SegmentNext
			.if {1} == 0
			{
				sta	$_Memory_NesBank
			}
			lda	$_Program_Bank_0+2
			pha
			plb
			rtl
b_{0}_80_e:

		SegmentNext
			.if {1} == 0
			{
				sta	$_Memory_NesBank
			}
			lda	$_Program_Bank_1+2
			pha
			plb
			rtl
b_{0}_a0_e:

		SegmentNext
			.if {1} == 0
			{
				sta	$_Memory_NesBank
			}
			lda	$_Program_Bank_2+2
			pha
			plb
			rtl
b_{0}_c0_e:

		SegmentNext
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

	Interpret_Indirect_Switch	Ora, 0, "Y"
	Interpret_Indirect_Switch	And, 0, "Y"
	Interpret_Indirect_Switch	Eor, 0, "Y"
	Interpret_Indirect_Switch	Adc, 0, "Y"
	Interpret_Indirect_Switch	Lda, 1, "Y"
	Interpret_Indirect_Switch	Cmp, 0, "Y"
	Interpret_Indirect_Switch	Sbc, 0, "Y"

	// ---------------------------------------------------------------------------

	.align	0x100

Interpret__StaIndirectY_Page:
	// Break this page into segments of 0x20 bytes
	SegmentStart	0x20
		sta	$_Memory_NesBank
		rtl
b_sta_00_e:

	SegmentNext
		jmp	$_Interpret__IndirectYIO_sta
b_sta_20_e:

	SegmentNext
		jmp	$_Interpret__IndirectYIO_sta
b_sta_40_e:

	SegmentNext
		sta	$_Memory_NesBank
		SelfMod_Begin
		SelfMod_IfSet	RomInfo_MemoryEmulation, RomInfo_MemEmu_StaticSram
		SelfMod_Do	+b_1
			lda	#0xb0
			pha
			plb
			rtl
b_1:
		SelfMod_End
		lda	$_Program_Bank_Sram+2
		pha
		plb
		rtl
b_sta_60_e:

	SegmentNext
		jmp	$_Interpret__IndirectYIO_sta
b_sta_80_e:

	SegmentNext
		jmp	$_Interpret__IndirectYIO_sta
b_sta_a0_e:

	SegmentNext
		jmp	$_Interpret__IndirectYIO_sta
b_sta_c0_e:

	SegmentNext
		jmp	$_Interpret__IndirectYIO_sta
b_sta_e0_e:

	SegmentEnd

	// ---------------------------------------------------------------------------

	Interpret_Indirect_Switch	Ora, 0, "X"
	Interpret_Indirect_Switch	And, 0, "X"
	Interpret_Indirect_Switch	Eor, 0, "X"
	Interpret_Indirect_Switch	Adc, 0, "X"
	Interpret_Indirect_Switch	Lda, 0, "X"
	Interpret_Indirect_Switch	Cmp, 0, "X"
	Interpret_Indirect_Switch	Sbc, 0, "X"

	// ---------------------------------------------------------------------------

	.align	0x100

Interpret__StaIndirectX_Page:
	// Break this page into segments of 0x20 bytes
	SegmentStart	0x20
		sta	$_Memory_NesBank
		rtl
b_sta_00_e:

	SegmentNext
		jmp	$_Interpret__IndirectXIO_sta
b_sta_20_e:

	SegmentNext
		jmp	$_Interpret__IndirectXIO_sta
b_sta_40_e:

	SegmentNext
		sta	$_Memory_NesBank
		SelfMod_Begin
		SelfMod_IfSet	RomInfo_MemoryEmulation, RomInfo_MemEmu_StaticSram
		SelfMod_Do	+b_1
			lda	#0xb0
			pha
			plb
			rtl
b_1:
		SelfMod_End
		lda	$_Program_Bank_Sram+2
		pha
		plb
		rtl
b_sta_60_e:

	SegmentNext
		jmp	$_Interpret__IndirectXIO_sta
b_sta_80_e:

	SegmentNext
		jmp	$_Interpret__IndirectXIO_sta
b_sta_a0_e:

	SegmentNext
		jmp	$_Interpret__IndirectXIO_sta
b_sta_c0_e:

	SegmentNext
		jmp	$_Interpret__IndirectXIO_sta
b_sta_e0_e:

	SegmentEnd

	// ---------------------------------------------------------------------------

Interpret__IndirectYIO_PageTable:
	.data16	Interpret__OraIndirectY_Main
	.data16	Interpret__AndIndirectY_Main
	.data16	Interpret__EorIndirectY_Main
	.data16	Interpret__AdcIndirectY_Main
	.data16	0
	.data16	Interpret__LdaIndirectY_Main
	.data16	Interpret__CmpIndirectY_Main
	.data16	Interpret__SbcIndirectY_Main

Interpret__IndirectXIO_PageTable:
	.data16	Interpret__OraIndirectX_Main
	.data16	Interpret__AndIndirectX_Main
	.data16	Interpret__EorIndirectX_Main
	.data16	Interpret__AdcIndirectX_Main
	.data16	0
	.data16	Interpret__LdaIndirectX_Main
	.data16	Interpret__CmpIndirectX_Main
	.data16	Interpret__SbcIndirectX_Main

	// ---------------------------------------------------------------------------

	// Put the following code in between segments
	.pushaddr
		.macro	Interpret_WriteWithinSegment	addr
			.addr	{0}, {0}|0x1f
			.def	{0}	{0}|0x1f		// Prevent further uses of this segment
		.endm

		.mx	0x30

		Interpret_WriteWithinSegment	b_sta_00_e
Inline_LoadIndirectY:
		lda	$0xff
		and	#0xe0
		eor	$_Memory_NesBank
		beq	$+b_1
			jsr	$=Interpret_LoadIndirectY
b_1:
		.data8	0

Inline_LoadIndirectX:
		lda	$0xff,X
		and	#0xe0
		eor	$_Memory_NesBank
		beq	$+b_1
			jsr	$=Interpret_LoadIndirectX
b_1:
		.data8	0


		Interpret_WriteWithinSegment	b_sta_20_e
Inline_CmdIndirectY:
		xba
		lda	$0xff
		and	#0xe0
		eor	$_Memory_NesBank
		beq	$+b_1
Inline_CmdIndirectY_Call:
			jsr	$=Interpret_LoadIndirectY
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
Inline_CmdIndirectX_Call:
			jsr	$=Interpret_LoadIndirectX
b_1:
		xba
		.data8	0


		Interpret_WriteWithinSegment	b_sta_60_e
Interpret_LoadIndirectY:
		// Flags NZ don't matter here
		eor	$_Memory_NesBank
Interpret_LoadIndirectYCmp:
		sta	$_Memory_NesBank
		//sta	$_IndirectY_Lda_Action
		jmp	($_IndirectY_Lda_Action)


		.mx	0x30

		Interpret_WriteWithinSegment	b_sta_80_e
Inline_StoreIndirectY:
		php
		xba
		lda	$0xff
		and	#0xe0
		cmp	$_Memory_NesBank
		beq	$+b_1
			jsr	$=Interpret_StoreIndirectYCmp
b_1:
		xba
		plp
		.data8	0


		Interpret_WriteWithinSegment	b_sta_a0_e
Inline_StoreIndirectX:
		php
		xba
		lda	$0xff,X
		and	#0xe0
		eor	$_Memory_NesBank
		beq	$+b_1
			jsr	$=Interpret_StoreIndirectX
b_1:
		xba
		plp
		.data8	0


Interpret_StoreIndirectY:
		// Flags NZ don't matter here
		eor	$_Memory_NesBank
Interpret_StoreIndirectYCmp:
		//sta	$_Memory_NesBank		// Writing this was moved to individual cases because it isn't necessary for IO ranges
		sta	$_IndirectY_Sta_Action
		jmp	($_IndirectY_Sta_Action)


		Interpret_WriteWithinSegment	b_sta_c0_e
Interpret_LoadIndirectX:
		// Flags NZ don't matter here
		eor	$_Memory_NesBank
Interpret_LoadIndirectXCmp:
		//sta	$_Memory_NesBank		// Writing this was moved to individual cases because it isn't necessary for IO ranges
		sta	$_IndirectX_Lda_Action
		jmp	($_IndirectX_Lda_Action)


Interpret_StoreIndirectX:
		// Flags NZ don't matter here
		eor	$_Memory_NesBank
Interpret_StoreIndirectXCmp:
		//sta	$_Memory_NesBank		// Writing this was moved to individual cases because it isn't necessary for IO ranges
		sta	$_IndirectX_Sta_Action
		jmp	($_IndirectX_Sta_Action)

		// Done placing code between segments
	.pulladdr

	// ---------------------------------------------------------------------------

	.mx	0x30

Inline_LoadIndirectYCross:
Inline_LoadIndirectYCross_LSB:
		lda	$0xfe
		beq	$+b_else
			php
			clc
Inline_LoadIndirectYCross_AdditionTable:
			adc	$_Addition|1,y
			lda	$0xff
Inline_LoadIndirectYCross_AdcZero:
			adc	#1
			plp
			bra	$+b_1
b_else:
			lda	$0xff
b_1:
		and	#0xe0
		eor	$_Memory_NesBank
		beq	$+b_1
			jsr	$=Interpret_LoadIndirectY
b_1:
		.data8	0


Inline_CmdIndirectYCross:
		xba
Inline_CmdIndirectYCross_LSB:
		lda	$0xfe
		beq	$+b_else
			php
			clc
Inline_CmdIndirectYCross_AdditionTable:
			adc	$_Addition|1,y
			lda	$0xff
Inline_CmdIndirectYCross_AdcZero:
			adc	#1
			plp
			bra	$+b_1
b_else:
			lda	$0xff
b_1:
		and	#0xe0
		eor	$_Memory_NesBank
		beq	$+b_1
Inline_CmdIndirectYCross_Call:
			jsr	$=Interpret_LoadIndirectY
b_1:
		xba
		.data8	0


Inline_StoreIndirectYCross:
		php
		xba
Inline_StoreIndirectYCross_LSB:
		lda	$0xfe
		beq	$+b_else
			clc
Inline_StoreIndirectYCross_AdditionTable:
			adc	$_Addition|1,y
			lda	$0xff
Inline_StoreIndirectYCross_AdcZero:
			adc	#1
			bra	$+b_1
b_else:
			lda	$0xff
b_1:
		and	#0xe0
		cmp	$_Memory_NesBank
		beq	$+b_1
			jsr	$=Interpret_StoreIndirectYCmp
b_1:
		xba
		plp
		.data8	0

	// ---------------------------------------------------------------------------

Interpret_IndirectIO_trap:
	unlock
	trap
	Exception	"Indirect IO Access Fail{}{}{}Unable to find target address."

	.macro	Interpret_IndirectIO	OpcodeInput, FixStack
		.mx	0x30
		.if {1} == 0
		{
			lock
		}
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

		// Increment one more time to point to the operand and adjust return address in order to skip the indirect access
		inc16dp	0x07

		.def	temp__		Zero+{0}
		.if		temp__&0x10 == 0
		{
			// Load ZP address
			txa
			clc
			adc	[$0x07]
			tax

			// Get target address
			rmx	#0x01
			lda	$0x0000,x
			tax
		}
		.else
		{
			// Load ZP address
			lda	[$0x07]
			tax

			// Get target address
			rmx	#0x01
			tya
			adc	$0x0000,x
			tax
		}

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
			ldy	#_iIOPort_stai*2
		}
		.else
		{
			ldy	#_iIOPort_ldai*2
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
		.else
		{
			unlock
		}
	.endm

	// ---------------------------------------------------------------------------

Interpret__IndirectYIO_Ora:
	Interpret_IndirectIO	0x11, 0
	ora	$_IO_Temp
	rtl

Interpret__IndirectYIO_And:
	Interpret_IndirectIO	0x31, 0
	and	$_IO_Temp
	rtl

Interpret__IndirectYIO_Eor:
	Interpret_IndirectIO	0x51, 0
	eor	$_IO_Temp
	rtl

Interpret__IndirectYIO_Adc:
	Interpret_IndirectIO	0x71, 0
	adc	$_IO_Temp
	rtl

Interpret__IndirectYIO_Sta:
	Interpret_IndirectIO	0x91, 1
	rtl

Interpret__IndirectYIO_Lda:
	Interpret_IndirectIO	0xb1, 0
	lda	$_IO_Temp
	stz	$_Memory_NesBank			// Clear memory range represented by DB
	rtl

Interpret__IndirectYIO_Cmp:
	Interpret_IndirectIO	0xd1, 0
	cmp	$_IO_Temp
	rtl

Interpret__IndirectYIO_Sbc:
	Interpret_IndirectIO	0xf1, 0
	sbc	$_IO_Temp
	rtl

	// ---------------------------------------------------------------------------

Interpret__IndirectXIO_Ora:
	Interpret_IndirectIO	0x01, 0
	ora	$_IO_Temp
	rtl

Interpret__IndirectXIO_And:
	Interpret_IndirectIO	0x21, 0
	and	$_IO_Temp
	rtl

Interpret__IndirectXIO_Eor:
	Interpret_IndirectIO	0x41, 0
	eor	$_IO_Temp
	rtl

Interpret__IndirectXIO_Adc:
	Interpret_IndirectIO	0x61, 0
	adc	$_IO_Temp
	rtl

Interpret__IndirectXIO_Sta:
	Interpret_IndirectIO	0x81, 1
	rtl

Interpret__IndirectXIO_Lda:
	Interpret_IndirectIO	0xa1, 0
	lda	$_IO_Temp
	rtl

Interpret__IndirectXIO_Cmp:
	Interpret_IndirectIO	0xc1, 0
	cmp	$_IO_Temp
	rtl

Interpret__IndirectXIO_Sbc:
	Interpret_IndirectIO	0xe1, 0
	sbc	$_IO_Temp
	rtl

	// ---------------------------------------------------------------------------
