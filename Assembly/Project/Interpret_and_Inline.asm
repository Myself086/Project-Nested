
	.macro	Interpret_Misalign
		.misalign	0x100, 0xff
		.misalign	0x100, 0x00
	.endm

	.vstack		_VSTACK_START

	// ---------------------------------------------------------------------------

Inline__Txs_Regular:
	.mx	0x30
	stx	$_IO_Temp16
	ldx	#0xff
	stx	$_IO_Temp16+1
	rep	#0x10
	.mx	0x10
	ldx	$_IO_Temp16
	txs
	sep	#0x30

	.data8	0

Inline__Txs_WithRangeTest:
	.mx	0x30
	stx	$_IO_Temp16
	ldx	#0xff
	stx	$_IO_Temp16+1
	rep	#0x10
	.mx	0x10
	ldx	$_IO_Temp16
	txs
	sep	#0x30
	php
Inline__Txs_WithRangeTest_Bottom:
	cpx	#0xf0
	bcc	$+b_1
Inline__Txs_WithRangeTest_Top:
		cpx	#0xf7
		beq	$+b_in
		bcs	$+b_1
b_in:
			stz	$_NmiReturn_Busy
b_1:
	plp
	.data8	0

	// ---------------------------------------------------------------------------

	.mx	0x30
	
Inline__Cli:
	php
	stz	$_InterruptFlag_6502
	dec	$_InterruptFlag_6502
	plp

	.data8	0
	
Inline__Sei:
	stz	$_InterruptFlag_6502

	.data8	0

	// ---------------------------------------------------------------------------

	.mx	0x30
Inline__PlaIndirect:
	tsc
	inc	a			// Support stack wrap
	tcs
	phx
	tax
	lda	$0x01ff,x
	plx
	ora	#0xff		// Fix flags

	.data8	0

	// ---------------------------------------------------------------------------

Inline__Plp:
	plp
	sep	#0x30
	rep	#0x0c

	.data8	0

	// ---------------------------------------------------------------------------
	
Inline_LoadDirect_LUT:
	.fill16	0x30, 0x0000
	.fill16	0x10, Inline_LoadDirect_60
	.fill16	0x10, Inline_LoadDirect_80
	.fill16	0x10, Inline_LoadDirect_a0
	.fill16	0x10, Inline_LoadDirect_c0
	.fill16	0x10, Inline_LoadDirect_e0
	.fill16	0x30, 0x0000
	.fill16	0x10, Inline_LoadDirectKnown_60
	.fill16	0x10, Inline_LoadDirectKnown_80
	.fill16	0x10, Inline_LoadDirectKnown_a0
	.fill16	0x10, Inline_LoadDirectKnown_c0
	.fill16	0x10, Inline_LoadDirectKnown_e0

Inline_CmdDirect_LUT:
	.fill16	0x30, 0x0000
	.fill16	0x10, Inline_CmdDirect_60
	.fill16	0x10, Inline_CmdDirect_80
	.fill16	0x10, Inline_CmdDirect_a0
	.fill16	0x10, Inline_CmdDirect_c0
	.fill16	0x10, Inline_CmdDirect_e0
	.fill16	0x30, 0x0000
	.fill16	0x10, Inline_CmdDirectKnown_60
	.fill16	0x10, Inline_CmdDirectKnown_80
	.fill16	0x10, Inline_CmdDirectKnown_a0
	.fill16	0x10, Inline_CmdDirectKnown_c0
	.fill16	0x10, Inline_CmdDirectKnown_e0

Inline_StoreDirect_LUT:
	.fill16	0x30, 0x0000
	.fill16	0x10, Inline_StoreDirect_60
	.fill16	0x10, Inline_StoreDirect_80
	.fill16	0x10, Inline_StoreDirect_a0
	.fill16	0x10, Inline_StoreDirect_c0
	.fill16	0x10, Inline_StoreDirect_e0
	.fill16	0x30, 0x0000
	.fill16	0x10, Inline_StoreDirectKnown_60
	.fill16	0x10, Inline_StoreDirectKnown_80
	.fill16	0x10, Inline_StoreDirectKnown_a0
	.fill16	0x10, Inline_StoreDirectKnown_c0
	.fill16	0x10, Inline_StoreDirectKnown_e0
	
	.macro	Inline_LoadDirect_Mac
Inline_LoadDirect_{0}:
		lda	#0x{0}
		eor	$_Memory_NesBank
		beq	$+Inline_LoadDirect_SameBank_{0}
			jsr	$=Interpret_LoadDirect_Call_{0}
Inline_LoadDirect_SameBank_{0}:
		.data8	0
	.endm

	.macro	Inline_CmdDirect_Mac
Inline_CmdDirect_{0}:
		xba
		lda	#0x{0}
		eor	$_Memory_NesBank
		beq	$+Inline_CmdDirect_SameBank_{0}
			jsr	$=Interpret_LoadDirect_Call_{0}
Inline_CmdDirect_SameBank_{0}:
		xba
		.data8	0
	.endm

	.macro	Inline_StoreDirect_Mac
Inline_StoreDirect_{0}:
		php
		xba
		lda	#0x{0}
		eor	$_Memory_NesBank
		beq	$+Inline_StoreDirect_SameBank_{0}
			jsr	$=Interpret_LoadDirect_Call_{0}
Inline_StoreDirect_SameBank_{0}:
		xba
		plp
		.data8	0
	.endm

	.macro	Inline_LoadDirectKnown_Mac
Inline_LoadDirectKnown_{0}:
		jsr	$=Interpret_LoadDirect_Call_{0}
		.data8	0
	.endm

	.macro	Inline_CmdDirectKnown_Mac
Inline_CmdDirectKnown_{0}:
		jsr	$=Interpret_CmdDirectKnown_Call_{0}
		.data8	0
	.endm

	.macro	Inline_StoreDirectKnown_Mac
Inline_StoreDirectKnown_{0}:
		jsr	$=Interpret_StoreDirectKnown_Call_{0}
		.data8	0
	.endm
	
	Inline_LoadDirect_Mac	60
	Inline_LoadDirect_Mac	80
	Inline_LoadDirect_Mac	a0
	Inline_LoadDirect_Mac	c0
	Inline_LoadDirect_Mac	e0
	
	Inline_CmdDirect_Mac	60
	Inline_CmdDirect_Mac	80
	Inline_CmdDirect_Mac	a0
	Inline_CmdDirect_Mac	c0
	Inline_CmdDirect_Mac	e0
	
	Inline_StoreDirect_Mac	60
	Inline_StoreDirect_Mac	80
	Inline_StoreDirect_Mac	a0
	Inline_StoreDirect_Mac	c0
	Inline_StoreDirect_Mac	e0

	Inline_LoadDirectKnown_Mac	60
	Inline_LoadDirectKnown_Mac	80
	Inline_LoadDirectKnown_Mac	a0
	Inline_LoadDirectKnown_Mac	c0
	Inline_LoadDirectKnown_Mac	e0

	Inline_CmdDirectKnown_Mac	60
	Inline_CmdDirectKnown_Mac	80
	Inline_CmdDirectKnown_Mac	a0
	Inline_CmdDirectKnown_Mac	c0
	Inline_CmdDirectKnown_Mac	e0

	Inline_StoreDirectKnown_Mac	60
	Inline_StoreDirectKnown_Mac	80
	Inline_StoreDirectKnown_Mac	a0
	Inline_StoreDirectKnown_Mac	c0
	Inline_StoreDirectKnown_Mac	e0

	Interpret_Misalign

Interpret_LoadDirect_Call_60:
	lda	#0x60
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

	Interpret_Misalign

Interpret_LoadDirect_Call_80:
	lda	#0x80
	sta	$_Memory_NesBank
	lda	$_Program_Bank_0+2
	pha
	plb
	rtl

	Interpret_Misalign

Interpret_LoadDirect_Call_a0:
	lda	#0xa0
	sta	$_Memory_NesBank
	lda	$_Program_Bank_1+2
	pha
	plb
	rtl

	Interpret_Misalign

Interpret_LoadDirect_Call_c0:
	lda	#0xc0
	sta	$_Memory_NesBank
	lda	$_Program_Bank_2+2
	pha
	plb
	rtl

	Interpret_Misalign

Interpret_LoadDirect_Call_e0:
	lda	#0xe0
	sta	$_Memory_NesBank
	lda	$_Program_Bank_3+2
	pha
	plb
	rtl

	Interpret_Misalign

Interpret_CmdDirectKnown_Call_60:
	xba
	lda	#0x60
	sta	$_Memory_NesBank
	SelfMod_Begin
	SelfMod_IfSet	RomInfo_MemoryEmulation, RomInfo_MemEmu_StaticSram
	SelfMod_Do	+b_1
		lda	#0xb0
		pha
		plb
		xba
		rtl
b_1:
	SelfMod_End
	lda	$_Program_Bank_Sram+2
	pha
	plb
	xba
	rtl

	Interpret_Misalign

Interpret_CmdDirectKnown_Call_80:
	xba
	lda	#0x80
	sta	$_Memory_NesBank
	lda	$_Program_Bank_0+2
	pha
	plb
	xba
	rtl

	Interpret_Misalign

Interpret_CmdDirectKnown_Call_a0:
	xba
	lda	#0xa0
	sta	$_Memory_NesBank
	lda	$_Program_Bank_1+2
	pha
	plb
	xba
	rtl

	Interpret_Misalign

Interpret_CmdDirectKnown_Call_c0:
	xba
	lda	#0xc0
	sta	$_Memory_NesBank
	lda	$_Program_Bank_2+2
	pha
	plb
	xba
	rtl

	Interpret_Misalign

Interpret_CmdDirectKnown_Call_e0:
	xba
	lda	#0xe0
	sta	$_Memory_NesBank
	lda	$_Program_Bank_3+2
	pha
	plb
	xba
	rtl

	Interpret_Misalign

Interpret_StoreDirectKnown_Call_60:
	php
	xba
	lda	#0x60
	sta	$_Memory_NesBank
	SelfMod_Begin
	SelfMod_IfSet	RomInfo_MemoryEmulation, RomInfo_MemEmu_StaticSram
	SelfMod_Do	+b_1
		lda	#0xb0
		pha
		plb
		xba
		plp
		rtl
b_1:
	SelfMod_End
	lda	$_Program_Bank_Sram+2
	pha
	plb
	xba
	plp
	rtl

	Interpret_Misalign

Interpret_StoreDirectKnown_Call_80:
	php
	xba
	lda	#0x80
	sta	$_Memory_NesBank
	lda	$_Program_Bank_0+2
	pha
	plb
	xba
	plp
	rtl

	Interpret_Misalign

Interpret_StoreDirectKnown_Call_a0:
	php
	xba
	lda	#0xa0
	sta	$_Memory_NesBank
	lda	$_Program_Bank_1+2
	pha
	plb
	xba
	plp
	rtl

	Interpret_Misalign

Interpret_StoreDirectKnown_Call_c0:
	php
	xba
	lda	#0xc0
	sta	$_Memory_NesBank
	lda	$_Program_Bank_2+2
	pha
	plb
	xba
	plp
	rtl

	Interpret_Misalign

Interpret_StoreDirectKnown_Call_e0:
	php
	xba
	lda	#0xe0
	sta	$_Memory_NesBank
	lda	$_Program_Bank_3+2
	pha
	plb
	xba
	plp
	rtl

	// ---------------------------------------------------------------------------
	
	.macro	Inline_DirectXBankCrossing_Mac
Inline_DirectXBankCrossing_{0}:
		php
		xba
		// Compare X to how much is left before crossing bank
		cpx	#0xff
		jsr	$=Interpret_DirectBankCrossing_{0}
		xba
		plp

		.data8	0
	.endm

	.macro	Inline_DirectYBankCrossing_Mac
Inline_DirectXBankCrossing_{0}:
		php
		xba
		// Compare Y to how much is left before crossing bank
		cpy	#0xff
		jsr	$=Interpret_DirectBankCrossing_{0}
		xba
		plp

		.data8	0
	.endm

Inline_DirectXBankCrossing_LUT:
	switch	0x80, Zero, Zero
		casesx	0x00, 0x1f
			rtl
		casesx	0x20, 0x5f
			trap
			Exception	"Unsupported Bank Crossing{}{}{}An X indexed direct access crossed to IO range."
		casesx	0x60, 0x7f
			Inline_DirectXBankCrossing_Mac	60
		casesx	0x80, 0x9f
			Inline_DirectXBankCrossing_Mac	80
		casesx	0xa0, 0xbf
			Inline_DirectXBankCrossing_Mac	a0
		casesx	0xc0, 0xdf
			Inline_DirectXBankCrossing_Mac	c0
		casesx	0xe0, 0xff
			Inline_DirectXBankCrossing_Mac	e0

Inline_DirectYBankCrossing_LUT:
	switch	0x80, Zero, Zero
		casesx	0x00, 0x1f
			rtl
		casesx	0x20, 0x5f
			trap
			Exception	"Unsupported Bank Crossing{}{}{}A Y indexed direct access crossed to IO range."
		casesx	0x60, 0x7f
			Inline_DirectYBankCrossing_Mac	60
		casesx	0x80, 0x9f
			Inline_DirectYBankCrossing_Mac	80
		casesx	0xa0, 0xbf
			Inline_DirectYBankCrossing_Mac	a0
		casesx	0xc0, 0xdf
			Inline_DirectYBankCrossing_Mac	c0
		casesx	0xe0, 0xff
			Inline_DirectYBankCrossing_Mac	e0


	Interpret_Misalign

Interpret_DirectBankCrossing_60:
	bcs	$+b_1
		lda	#0x60
		sta	$_Memory_NesBank
		SelfMod_Begin
		SelfMod_IfSet	RomInfo_MemoryEmulation, RomInfo_MemEmu_StaticSram
		SelfMod_Do	+b_2
			lda	#0xb0
			pha
			plb
			rtl
b_2:
		SelfMod_End
		lda	$_Program_Bank_Sram+2
		pha
		plb
		rtl
b_1:
	lda	#0x80
	sta	$_Memory_NesBank
	lda	$_Program_Bank_0+2
	pha
	plb
	rtl


	Interpret_Misalign

Interpret_DirectBankCrossing_80:
	bcs	$+b_1
		lda	#0x80
		sta	$_Memory_NesBank
		lda	$_Program_Bank_0+2
		pha
		plb
		rtl
b_1:
	lda	#0xa0
	sta	$_Memory_NesBank
	lda	$_Program_Bank_1+2
	pha
	plb
	rtl


	Interpret_Misalign

Interpret_DirectBankCrossing_a0:
	bcs	$+b_1
		lda	#0xa0
		sta	$_Memory_NesBank
		lda	$_Program_Bank_1+2
		pha
		plb
		rtl
b_1:
	lda	#0xc0
	sta	$_Memory_NesBank
	lda	$_Program_Bank_2+2
	pha
	plb
	rtl


	Interpret_Misalign

Interpret_DirectBankCrossing_c0:
	bcs	$+b_1
		lda	#0xc0
		sta	$_Memory_NesBank
		lda	$_Program_Bank_2+2
		pha
		plb
		rtl
b_1:
	lda	#0xe0
	sta	$_Memory_NesBank
	lda	$_Program_Bank_3+2
	pha
	plb
	rtl


	Interpret_Misalign

Interpret_DirectBankCrossing_e0:
	bcs	$+b_1
		lda	#0xe0
		sta	$_Memory_NesBank
		lda	$_Program_Bank_3+2
		pha
		plb
		rtl
b_1:
	rtl

	// ---------------------------------------------------------------------------

Inline__RmwToIO:
	php
	pha
Inline__RmwToIO_Load:
	lda	$0x50da
Inline__RmwToIO_Call:
	jsr	$0xc0ffee
	pla
	plp

	.data8	0

	// ---------------------------------------------------------------------------

Inline__JmpToRam:
	php
Inline__JmpToRam_OriginalValue:
	pea $0x50da
	jmp $=Interpreter__Execute

	.data8	0

Inline__JslToRam:
	phk
Inline__JslToRam_Per:
	per $0xff07
	php
Inline__JslToRam_OriginalValue:
	pea $0x50da
	jmp $=Interpreter__Execute

	.data8	0

Inline__JsrToRam:
Inline__JsrToRam_OriginalReturn:
	pea $0x50da
	php
Inline__JsrToRam_OriginalValue:
	pea $0x50da
	jmp $=Interpreter__Execute

	.data8	0

	// ---------------------------------------------------------------------------

	.mx	0x30

Inline__PushConstantReturn:
	lda	#0x85
	phk
	per	$0xff01
	bra	$+Inline__PushConstantReturn_end
Inline__PushConstantReturn_OriginalReturn:
		pea	$0x50da
Inline__PushConstantReturn_OriginalValue:
		pea	$0x50da
		jsr	$=Interpret__Jsr
		nop
		rtl
Inline__PushConstantReturn_end:

	.data8	0

Inline__PushConstantReturnAOT:
	lda	#0x85
	phk
	per	$0xff01
	bra	$+Inline__PushConstantReturnAOT_End
Inline__PushConstantReturnAOT_JmpToRam:
		jsr	$0x7f01d5
		nop
		rtl
Inline__PushConstantReturnAOT_End:

	.data8	0

	// ---------------------------------------------------------------------------

	.mx	0x30

Inline__StaticJmpAcrossBank:
	sta	$2,s
	php
	pla
	sta	$3,s
	pla
	pla
	plp
Inline__StaticJmpAcrossBank_Jmp:
	jmp	$0xc0ffee
Inline__StaticJmpAcrossBank_End:

	// ---------------------------------------------------------------------------

	.mx	0x30

Inline__StaticOriginalReturn:
	sta	$2,s
	php
	pla
	sta	$3,s
	pla
	pla
	plp
Inline__StaticOriginalReturn_Pea:
	pea	$0x50da
Inline__StaticOriginalReturn_Jmp:
	jmp	$0xc0ffee
Inline__StaticOriginalReturn_End:


//Inline__StaticOriginalReturn:
//	pea	$0x50da
//	jsr	$=Interpret__StaticOriginalReturn
//	jmp	$0xc0ffee
//Inline__StaticOriginalReturn_End:

	// Entry: s1[2] = callIndex
Interpret__StaticOriginalReturn:
	.vstack		_VSTACK_START
	.local	.x, .a
	.local	=return

	// Preserve A and X
	sta	$_a
	stx	$_x

	// Fix stack
	//         1, 2, 3, 4, 5, 6, 7, 8
	// Before: i, i, R, R, R, r, r, r
	// After:                 p, o, o
	php
	pla
	sta	$6,s
	lda	$5,s
	sta	$_return+2
	rep	#0x30
	.mx	0x00
	// Pull index
	plx
	// Read original return address
	lda	$=StaticRec_Origins,x
	sta	$5,s
	// Copy low bits of return
	pla
	sta	$_return
	// Pull either 0x7e or 0x7f into P which puts MX in 8-bit mode and clears 1 byte from stack
	plp
	.mx	0x30

	// Restore A and X
	lda	$_a
	ldx	$_x

	// Restore P and "return"
	plp
	jmp	[$_return]

	// ---------------------------------------------------------------------------

	Interpret_Misalign
	.mx	0x30

	EmuCall		"Interpret__Jsr", "?", "?"
Interpret__Jsr:
	//        1   2           3-5     6-7           8-9
	// Stack: db, p register, return, originalCall, originalReturn
	//                  1-2 3   4           5-7     8-9
	// Stack reordered: dp, db, p register, return, originalReturn
	
	.vstack		_VSTACK_START
	.local	.a, .x, .y, .p, =return, .return_b
	.local	_originalCall, _originalReturn

	// Push P and disable interrupts
	php
	lock
	WDM_LoadPreviousEntryPoint

	// Push without changing DP
	sta	$_a
	stx	$_x
	sty	$_y
	phb
	
	// Keep stack pointer in X so we can write return for emulated RTS
	tsx

	// Change to full 16-bit mode
	rep	#0x30
	.mx	0x00

	// Fix stack and call recompiler
	lda	$8,s
	sta	$_StackEmu_Compare+8,x
	sta	$_originalReturn
	lda	$3,s
	sta	$_StackEmu_LowBits+8,x
	sta	$_return
	lda	$4,s
	sta	$_StackEmu_HighBits+8,x
	sta	$_return+1
	pla
	phd
	sta	$3,s
	// Change DP to our Vstack base address
	lda	#_VSTACK_PAGE
	tcd
	// Call recompiler
	lda	$6,s
	sta	$.originalCall
	Recompiler__CallFunction	"//"

	// Do we rewrite this as call or jump?
	.local	_functionListIndex
	sty	$.functionListIndex
	iny
	iny
	iny
	lda	[$.Recompiler_FunctionList+3],y
	and	#_Opcode_F_PullReturn
	beq	$+Interpret__Jsr_RewriteJsr
	jmp	$_Interpret__Jsr_RewriteJmp
Interpret__Jsr_RewriteJsr:
		// Rewrite return, get current return address -9 because JSR contains a combination of 10 bytes

		// Before
		//		0	1	2	3	4	5	6	7	8	9
		//		pea	#	#	pea	#	#	jsr	#	#	#
		// After: dummy STA for debugging, dummy branch forward, NOP, JSR to the recompiled function
		//		0	1	2	3	4	5	6	7	8	9
		//		sta	#	#	bra	+1	nop	jsr	#	#	#
		// No dummy STA in non debugging mode
		//		0	1	2	3	4	5	6	7	8	9
		//		bra	+4	nop nop	nop	nop	jsr	#	#	#
		// Note: NOPs are used for later optimizations

		// Fix return address so we point to the first PEA
		lda	$.return
		sec
		sbc	#0x0009
		sta	$.return

		// Do we debug this call?
		ldy	#0x0001
		lda	[$.return],y
		bpl	$+Interpret__Jsr_NoDebugCall
		lda	$=RomInfo_DebugCalls-1
		bpl	$+Interpret__Jsr_NoDebugCall
Interpret__Jsr_DebugCall:
			// Write STA for debugging calls
			lda	[$.return]
			and	#0xff00
			ora	#0x008d
			sta	[$.return]

			// Write BRA 1 and NOP
			ldy	#0x0003
			lda	#0x0180
			sta	[$.return],y
			iny
			lda	#0xea01
			sta	[$.return],y

			bra	$+Interpret__Jsr_SkipDebugCall

Interpret__Jsr_NoDebugCall:
			// Write BRA 4 and NOPs
			lda	#0x0480
			sta	[$.return]
			lda	#0xeaea
			ldy	#0x0002
			sta	[$.return],y
			ldy	#0x0004
			sta	[$.return],y

Interpret__Jsr_SkipDebugCall:

		// Dynamic JSR?
		lda	$=RomInfo_CpuSettings
		and	#_RomInfo_Cpu_DynamicJsr
		beq	$+b_else
			// Are we crossing bank?
			lda	$.originalReturn
			ldy	$.originalCall
			call	DynamicJsr__IsRangeStatic
			bcs	$+b_else
				lda	$.originalCall
				call	DynamicJsr__CreateJsrLink
				xba
				ldy	#0x0008
				sta	[$.return],y
				txa
				dey
				sta	[$.return],y
				bra	$+b_1
b_else:
				// Rewrite JSR destination
				ldy	$.functionListIndex
				lda	[$.Recompiler_FunctionList+3],y
				ldy	#0x0007
				sta	[$.return],y
				ldy	$.functionListIndex
				iny
				lda	[$.Recompiler_FunctionList+3],y
				ldy	#0x0008
				sta	[$.return],y
b_1:

		// Is this call followed by a NOP+RTL?
		ldy	#0x000a
		lda	[$.return],y
		cmp	#0x6bea
		bne	$+Interpret__Jsr_RewriteJsr_NoRtl
			// Replace JSL with JMP
			ldy	#0x0006
			lda	[$.return],y
			and	#0xff00
			ora	#0x005c
			sta	[$.return],y

Interpret__Jsr_RewriteJsr_NoRtl:

		// Fix stack
		//         1, 2, 3, 4, 5, 6, 7, 8, 9
		// Before: d, d, b, p, r, r, r, o, o
		// After:        d, d, b, p, _, _, _	(return address is set later)
		ply
		plx
		pla
		sta	$1,s
		phx
		phy

		// Continue as normal
		jmp	$_Interpret__Jsr_NoRewrite

Interpret__Jsr_RewriteJmp:
		// Rewrite return, get current return address -9 because JSR contains a combination of 10 bytes

		// Before
		//		0	1	2	3	4	5	6	7	8	9
		//		pea	#	#	pea	#	#	jsr	#	#	#
		// After
		//		0	1	2	3	4	5	6	7	8	9
		//		pea	#	#	jmp	#	#	#	nop	nop	nop

		// Fix return address so we point to the first PEA
		lda	$.return
		sec
		sbc	#0x0009
		sta	$.return

		// Write JMP
		lda	#0x005c
		ldy	#0x0003
		sta	[$.return],y

		// Dynamic JSR?
		lda	$=RomInfo_CpuSettings
		and	#_RomInfo_Cpu_DynamicJsr
		beq	$+b_else
			// Are we crossing bank?
			lda	$.originalReturn
			ldy	$.originalCall
			call	DynamicJsr__IsRangeStatic
			bcs	$+b_else
				lda	$.originalCall
				call	DynamicJsr__CreateJsrLink
				xba
				ldy	#0x0005
				sta	[$.return],y
				txa
				dey
				sta	[$.return],y
				bra	$+b_1
b_else:
				// Rewrite JMP destination
				ldy	$.functionListIndex
				lda	[$.Recompiler_FunctionList+3],y
				ldy	#0x0004
				sta	[$.return],y
				ldy	$.functionListIndex
				iny
				lda	[$.Recompiler_FunctionList+3],y
				ldy	#0x0005
				sta	[$.return],y
b_1:

		// Write NOPs
		lda	#0xeaea
		ldy	#7
		sta	[$.return],y
		iny
		sta	[$.return],y

		// Original return
		ldy	#0x0001
		lda	[$.return],y
		sta	$8,s

		// Is this call followed by a NOP+RTL?
		ldy	#0x000a
		lda	[$.return],y
		cmp	#0x6bea
		bne	$+b_else
			// Remove the first PEA
			lda	#0xeaea
			ldy	#1
			sta	[$.return],y
			lda	#0x0180
			sta	[$.return]

			// Fix stack, remove the original return
			//         1, 2, 3, 4, 5, 6, 7, 8, 9
			// Before: d, d, b, p, r, r, r, o, o
			// After:        d, d, b, p, r, r, r
			lda	$6,s
			sta	$8,s
			lda	$4,s
			sta	$6,s
			lda	$2,s
			sta	$4,s
			pla
			sta	$1,s

			bra	$+b_1
b_else:
			// Link return if necessary
			ldy	$.functionListIndex
			iny
			iny
			iny
			lda	[$.Recompiler_FunctionList+3],y
			and	#_Opcode_F_HasReturn
			beq	$+b_1
				.precall	JMPi__Add	=originalCall, =newAddr
				lda	$.return+1
				sta	$.Param_newAddr+1
				lda	$.return
				clc
				adc	#0x000a
				sta	$.Param_newAddr
				lda	$8,s
				inc	a
				tay
				and	#0xe000
				xba
				tax
				lda	$_Program_BankNum-1,x
				sta	$.Param_originalCall+1
				sty	$.Param_originalCall
				sec
				call
b_1:

		// Return back to the JMP
		lda	$.return+1
		sta	$6,s
		lda	$.return
		clc
		adc	#0x0002
		sta	$5,s
		bra	$+Interpret__Jsr_FakeReturn

Interpret__Jsr_NoRewrite:
	// Return back to JSR to trigger stack debugger on EmulSNES
	lda	$.return+1
	sta	$6,s
	lda	$.return
	clc
	adc	#0x0005
	sta	$5,s

	// OLD: Write call destination
	//ldy	$.functionListIndex
	//iny
	//lda	[$.Recompiler_FunctionList+3],y
	//sta	$6,s
	//dey
	//lda	[$.Recompiler_FunctionList+3],y
	//dec	a
	//sta	$5,s

Interpret__Jsr_FakeReturn:
	// Return
	sep	#0x30
	lda	$.a
	ldx	$.x
	ldy	$.y
	pld
	plb
	plp
	WDM_StorePreviousEntryPoint
	rtl

	// ---------------------------------------------------------------------------

	.mx	0x30

	// Entry: s1[3] = Rewrite address + 3
Interpret__StaticJsr:
	.vstack		_VSTACK_START
	.local	.a, .x, .y, .p, =return, =return2

	// Push P and disable interrupts
	php
	lock
	WDM_LoadPreviousEntryPoint

	// Push without changing DP
	sta	$_a
	stx	$_x
	sty	$_y
	phb
	phd

	// Copy return bank before changing mode
	lda	$7,s
	sta	$_return+2

	// Change mode
	rep	#0x31
	.mx	0x00

	// Change DP
	lda	#_VSTACK_PAGE
	tcd

	// Copy return address and subtract it by 3, assume carry clear from rep
	lda	$5,s
	adc	#_Zero-3
	sta	$.return
	sta	$5,s
	tax

	// Copy return2 address
	lda	$=StaticRec_OriginsB+0,x
	sta	$.return2+0
	lda	$=StaticRec_OriginsB+1,x
	sta	$.return2+1

	// Call recompiler
	lda	$=StaticRec_Origins+2,x
	Recompiler__CallFunction	"//"
	// Keep returned value
	.local	_functionListIndex
	sty	$.functionListIndex

	// Are we using non-native return address?
	andbne	$=RomInfo_StackEmulation, #_RomInfo_StackEmu_NativeReturn, $+b_1
		jmp	$_Interpret__StaticJsr_Regular
b_1:

	// Is it followed by a NOP+RTL?
	ldy	#1
	lda	[$.return2],y
	cmp	#0x6bea
	bne	$+b_1
		// JMP crossing bank boundary

		// Allocate memory for some extra code
		lda	#0x007f
		ldx	#_Inline__StaticJmpAcrossBank_End-Inline__StaticJmpAcrossBank
		call	Memory__Alloc
		.local	=extraCode
		stx	$.extraCode
		sta	$.extraCode+2

		// Copy our extra code
		sep	#0x20
		.mx	0x20
		ldy	#_Inline__StaticJmpAcrossBank_End-Inline__StaticJmpAcrossBank-1
b_loop:
			tyx
			lda	$=Inline__StaticJmpAcrossBank,x
			sta	[$.extraCode],y
			dey
			bpl	$-b_loop
		rep	#0x20
		.mx	0x00

		// Dynamic JSR?
		lda	$=RomInfo_CpuSettings
		and	#_RomInfo_Cpu_DynamicJsr
		beq	$+b_else
			// Are we crossing bank?
			ldx	$.return
			lda	$=StaticRec_Origins+2,x		// Original call
			tay
			lda	$=StaticRec_Origins+0,x		// Original return
			call	DynamicJsr__IsRangeStatic
			bcs	$+b_else
				ldx	$.return
				lda	$=StaticRec_Origins+2,x		// Original call
				call	DynamicJsr__CreateJsrLink
				xba
				bra	$+b_2
b_else:
				ldy	$.functionListIndex
				lda	[$.Recompiler_FunctionList+3],y
				tax
				iny
				lda	[$.Recompiler_FunctionList+3],y
b_2:
		// Write new destination in our extra code
		ldy	#_Inline__StaticJmpAcrossBank_Jmp-Inline__StaticJmpAcrossBank+2
		sta	[$.extraCode],y
		txa
		dey
		sta	[$.extraCode],y

		// Write jump to our extra code
		lda	$.extraCode-1
		and	#0xff00
		ora	#0x005c
		sta	[$.return]
		ldy	#2
		lda	$.extraCode+1
		sta	[$.return],y

		jmp	$_Interpret__StaticJsr_Return
b_1:

	// Do we rewrite this as call or jump?
	ldy	$.functionListIndex
	iny
	iny
	iny
	lda	[$.Recompiler_FunctionList+3],y
	and	#_Opcode_F_PullReturn
	bne	$+Interpret__StaticJsr_PullReturn
Interpret__StaticJsr_Regular:
		lda	#0x5c5c
		sta	[$.return]

		// Dynamic JSR?
		lda	$=RomInfo_CpuSettings
		and	#_RomInfo_Cpu_DynamicJsr
		beq	$+b_else
			// Are we crossing bank?
			ldx	$.return
			lda	$=StaticRec_Origins+2,x		// Original call
			tay
			lda	$=StaticRec_Origins+0,x		// Original return
			call	DynamicJsr__IsRangeStatic
			bcs	$+b_else
				ldx	$.return
				lda	$=StaticRec_Origins+2,x		// Original call
				call	DynamicJsr__CreateJsrLink
				xba
				bra	$+b_1
b_else:
				ldy	$.functionListIndex
				lda	[$.Recompiler_FunctionList+3],y
				tax
				iny
				lda	[$.Recompiler_FunctionList+3],y
b_1:
		// Copy destination address
		ldy	#2
		sta	[$.return],y
		txa
		dey
		sta	[$.return],y

		// Return
		jmp	$_Interpret__StaticJsr_Return

Interpret__StaticJsr_PullReturn:
		// Allocate memory for some extra code
		lda	#0x007f
		ldx	#_Inline__StaticOriginalReturn_End-Inline__StaticOriginalReturn
		call	Memory__Alloc
		//.local	=extraCode
		stx	$.extraCode
		sta	$.extraCode+2

		// Copy our extra code
		sep	#0x20
		.mx	0x20
		ldy	#_Inline__StaticOriginalReturn_End-Inline__StaticOriginalReturn-1
Interpret__StaticJsr_PullReturn_Loop:
			tyx
			lda	$=Inline__StaticOriginalReturn,x
			sta	[$.extraCode],y
			dey
			bpl	$-Interpret__StaticJsr_PullReturn_Loop
		rep	#0x20
		.mx	0x00

		// Write original return in our extra code
		ldy	#_Inline__StaticOriginalReturn_Pea-Inline__StaticOriginalReturn+1
		ldx	$.return
		lda	$=StaticRec_Origins+0,x
		sta	[$.extraCode],y

		// Dynamic JSR?
		lda	$=RomInfo_CpuSettings
		and	#_RomInfo_Cpu_DynamicJsr
		beq	$+b_else
			// Are we crossing bank?
			ldx	$.return
			lda	$=StaticRec_Origins+2,x		// Original call
			tay
			lda	$=StaticRec_Origins+0,x		// Original return
			call	DynamicJsr__IsRangeStatic
			bcs	$+b_else
				ldx	$.return
				lda	$=StaticRec_Origins+2,x		// Original call
				call	DynamicJsr__CreateJsrLink
				xba
				bra	$+b_2
b_else:
				ldy	$.functionListIndex
				lda	[$.Recompiler_FunctionList+3],y
				tax
				iny
				lda	[$.Recompiler_FunctionList+3],y
b_2:
		// Write new destination in our extra code
		ldy	#_Inline__StaticOriginalReturn_Jmp-Inline__StaticOriginalReturn+2
		sta	[$.extraCode],y
		txa
		dey
		sta	[$.extraCode],y

		// Write jump to our extra code
		lda	$.extraCode-1
		and	#0xff00
		ora	#0x005c
		sta	[$.return]
		ldy	#2
		lda	$.extraCode+1
		sta	[$.return],y

		//jmp	$_Interpret__StaticJsr_Return

Interpret__StaticJsr_Return:

	// Link return if necessary
	// Is it followed by NOP+RTL?
	ldy	#1
	lda	[$.return2],y
	cmp	#0x6bea
	beq	$+b_1
	// Is destination using non-native return?
	ldy	$.functionListIndex
	iny
	iny
	iny
	lda	[$.Recompiler_FunctionList+3],y
	and	#_Opcode_F_HasReturn
	beq	$+b_1
		.precall	JMPi__Add	=originalCall, =newAddr
		lda	$.return2+1
		sta	$.Param_newAddr+1
		lda	$.return2
		beq	$+b_1			// Exit if invalid return
		inc	a
		sta	$.Param_newAddr
		ldx	$.return
		lda	$=StaticRec_Origins+0,x
		inc	a
		tay
		and	#0xe000
		xba
		tax
		lda	$_Program_BankNum-1,x
		sta	$.Param_originalCall+1
		sty	$.Param_originalCall
		sec
		call
b_1:

	sep	#0x30
	.mx	0x30
	// Return
	lda	$.a
	ldx	$.x
	ldy	$.y
	pld
	plb
	// RTI instead of RTL because RTI removes a DEC and a PLP
	WDM_StorePreviousEntryPoint
	rti

	// ---------------------------------------------------------------------------

	.mx	0x30

Interpret__Rti:
	// TODO: Proper RTI emulation
	plp
Interpret__Rts:
	//        1  2  3  4  5-6
	// Stack: a, x, p, k, originalReturn
	phk
	php
	phx
	pha

	// Change mode
	rep	#0x30
	.mx	0x00

	// Keep stack pointer in X
	tsx

	// Has the return changed?
	lda	$5,s
	cmp	$_StackEmu_Compare+5-0x100,x
	bne	$+Interpret__Rts_Changed
	stz	$_StackEmu_Compare+5-0x100,x

	// Push return
	lda	$_StackEmu_HighBits+5-0x100,x
	sta	$5,s
	lda	$_StackEmu_LowBits+5-0x100,x
	sta	$4,s
	
	// Change mode back
	sep	#0x30
	.mx	0x30

	pla
	plx
	plp
	rtl

Interpret__Rts_Changed:
	// Disable interrupts
	lock

	.vstack		_VSTACK_START
	phd
	pea	$_VSTACK_PAGE
	pld

	.local	_y
	sty	$.y

	.mx	0x00
	// Call new return address
	inc	a
	Recompiler__CallFunction	"//"
	phb
	call
	plb

	// Write return
	iny
	lda	[$.Recompiler_FunctionList+3],y
	sta	$7,s
	dey
	lda	[$.Recompiler_FunctionList+3],y
	sta	$6,s

	// Change mode back
	sep	#0x30
	.mx	0x30

	ldy	$.y
	pld
	pla
	plx
	rti
	//plp
	//rtl
	.mx	0x30

	// ---------------------------------------------------------------------------

Interpret__Brk:
Interpret__Brk_PushReturn:
	pea	$0xcafe			// Coffee break! :D
	php					// B flag is set
	pea	$12939			// I don't drink this nor coffee anymore...
	php
	sta	$_IO_Temp
	lda	$0xffff
	sta	$3,s
	lda	$0xfffe
	sta	$2,s
	jmp	$=JMPiU__FromBRK

	.data8	0

	// ---------------------------------------------------------------------------

Inline__JmpIError:
	pea	$0x50da
	jmp	$=Interpret__JmpIError

	.data8	0

	// Indirect jump error
	Interpret_Misalign
Interpret__JmpIError:
	rep	#0x20
	pla
	trap
	Exception	"Indirect JMP Failed{}{}{}Indirect JMP attempted to read destination address from 0x{A:X}."

	// ---------------------------------------------------------------------------

	JMPiU_Inline_ZpNoWrap
	JMPiU_Inline_ZpWrap
	JMPiU_Inline_AbsNoWrap
	JMPiU_Inline_AbsWrap
	.mx	0x30

	// ---------------------------------------------------------------------------

Inline__UnsupportedOpcode:
Inline__UnsupportedOpcode_PC:
	pea	$0x50da
Inline__UnsupportedOpcode_OpcodeAndBank:
	pea	$0x50da
	jmp	$=Interpret__UnsupportedOpcode

	.data8	0

	Interpret_Misalign

Interpret__UnsupportedOpcode:
	// Stack: opcode, NES bank, NES PC.lo, NES PC.hi
	rep	#0x30
	pla
	ply
	sep	#0x20
	ora	#0
	beq	$+b_brk
		trap
		Exception	"Unsupported Opcode{}{}{}The CPU attempted to execute opcode 0x{a:X} at NES address {ah:X}:{Y:X}{}{}Some illegal opcodes are supported but must be activated on the EXE under CPU settings."

b_brk:
	trap
	Exception	"BRK in native mode{}{}{}The CPU attempted to execute opcode BRK at NES address {ah:X}:{Y:X}{}{}Disable 'Stack emulation, Native return from interrupt' on the converter."
	

	// ---------------------------------------------------------------------------

	// Make sure that Interpret__Idle's address doesn't contain any 0x00
	.misalign	0x100, 0

	.mx	0x30
Interpret__Idle:
	php
	dec	$_Vblank_Busy
	pha
	phx
	phy

	// Is IRQ set?
	lock
	lda	$_Scanline_IRQ
	beq	$+b_1
		// Is IRQ set after current scanline?
		cmp	$_Scanline_HDMA
		bcc	$+b_1
		beq	$+b_1
			// Change mode
			rep	#0x10
			.mx	0x20

			// Call next IRQ and return
			sta	$_Scanline
			phb
			phd
			call	Hdma__UpdateScrolling
			pld
			plb
			sep	#0x30
			ply
			plx
			pla
			plp
			rtl
b_1:

	// Change mode
	rep	#0x34
	.mx	0x00

	// TODO: Remove DP change?
	.vstack		_VSTACK_START
	lda	#_VSTACK_PAGE
	tcd

	// Next frame
	call	Interpret__Wait4Vblank

	// Get NMI address
	lda	$_Program_Bank_3+2
	cmp	$_NMI_NesBank
	beq	$+b_1
		sta	$_NMI_NesBank
		sep	#0x30
		.mx	0x30
		phb
		pha
		plb
		rep	#0x30
		.mx	0x00
		lda	$0xfffa
		Recompiler__CallFunction	"//"
		plb

		// Write destination address
		lda	[$.Recompiler_FunctionList+3],y
		sta	$_NMI_SnesPointer
		iny
		lda	[$.Recompiler_FunctionList+3],y
		sta	$_NMI_SnesPointer+1
b_1:

	// Are we using native return from interrupt?
	lda	$=RomInfo_StackEmulation
	and	#_RomInfo_StackEmu_NativeReturnInterrupt
	bne	$+b_1
		// Fix stack   1   2   3   4   5   6   7
		//  Before:    y,  x,  a,  p, r0, r1, r2	(r = native return)
		//  After:                     p, R0, R1	(R = non-native return)

		// Fix return (part 1)
		lda	$6,s
		sta	$_NmiReturn_ReturnAddress2+1
		lda	#_NmiReturn_FakeNesAddress2
		sta	$6,s

		// Change DP
		lda	#0x0000
		tcd

		// Change to 8-bit mode
		sep	#0x30

		// Fix return (part 2)
		lda	$5,s
		inc	a
		sta	$_NmiReturn_ReturnAddress2+0
		bne	$+b_2
			// Fix page number
			inc	$_NmiReturn_ReturnAddress2+1
b_2:
		lda	$4,s
		sta	$5,s

		// Pull registers
		ply
		plx
		pla

		// Call NMI
		stz	$_Vblank_Busy
		plp
		jmp	[$_NMI_SnesPointer]
b_1:

	// Call NMI
	lda	#0x0000
	tcd
	sep	#0x30
	stz	$_Vblank_Busy
	ply
	plx
	pla
	jmp	[$_NMI_SnesPointer]

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Interpret__Wait4Vblank

Interpret__Wait4Vblank:
	php
	sep	#0x24
	.mx	0x20

	// Copy content of register 2001 for avoiding left column flicker
	lda	$_IO_2001
	sta	$_IO_2001_EarlyValue

	lda	#0xef
	sta	$_Scanline
	phb
	phd
	call	Hdma__UpdateScrolling

	// Swap buffers while delaying IRQ
	lock
	//call	Hdma__SwapBuffers
	jsr	$=Hdma__SwapBuffers

	// Update sound
	call	Sound__Update
	pld
	plb

	// Change mode back and clear thread lock (if necessary)
	plp
	.mx	0x00

	// Reset free cycle counter
	ldy	#0x0000

	// Do we have free time?
	ldx	$_Nmi_Count
	bne	$+Interpret__Wait4Vblank_Loop_PreExit

		// Start counting cycles, 21.00 cycles between the first 2 BNE
		sep	#0x20
		bit	$_Nmi_Count
		rep	#0x21			// Clear carry and keep it clear during the loop below
		lda	#21
Interpret__Wait4Vblank_Loop:
			// 10.66 cycles (10.66 total)
			ldx	$_Nmi_Count
			bne	$+Interpret__Wait4Vblank_Loop_Exit
			adc	#11

			// 10.66 cycles (21.33 total)
			ldx	$_Nmi_Count
			bne	$+Interpret__Wait4Vblank_Loop_Exit
			adc	#10

			// 13.66 cycles (35.00 total)
			ldx	$_Nmi_Count
			bne	$+Interpret__Wait4Vblank_Loop_Exit
			adc	#14

			// Branch back indirectly just to keep the number of free cycles accurate, the above branch couldn't been changed
			bra	$-Interpret__Wait4Vblank_Loop

Interpret__Wait4Vblank_Loop_Exit:
		// Exited from loop
		// Preserve cycle count
		tay
		// Add cycle count to total, assume carry clear from the loop above
		adc	$_Idle_CyclesTotal
		sta	$_Idle_CyclesTotal
		bcc	$+b_1
			inc	$_Idle_CyclesTotal+2
b_1:

Interpret__Wait4Vblank_Loop_PreExit:

	// Write cycle count
	sty	$_Idle_CycleCounter

	// Directly decrement just to be thread safe
	dec	$_Nmi_Count

	// Reset scanline
	stz	$_Scanline
	stz	$_Scanline_HDMA

	// Reset sprite 0 hit detection
	stz	$_IO_2002_LastReturn
	stz	$_IO_2002_CallCount-1

	// Copy some PPU settings
	lda	$_IO_2000
	sta	$_IO_2000_EarlyValue

	// Decrement frame count
	dec	$_Idle_FrameCount
	bmi	$+b_1
		return
b_1:
	// Calculate average free time over 64 frames (>> 6)
	lda	$_Idle_CyclesTotal-1
	asl	a
	and	#0x8000
	ora	$_Idle_CyclesTotal+1
	rol	a
	rol	a
	sta	$_Idle_Average

	// Reset frame counter
	ldx	#63
	stx	$_Idle_FrameCount

	// Reset total cycles
	stz	$_Idle_CyclesTotal+0
	stz	$_Idle_CyclesTotal+2

	return
