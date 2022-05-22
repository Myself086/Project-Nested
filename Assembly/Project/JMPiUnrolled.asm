
	// ---------------------------------------------------------------------------
	// Indirect JMP "unrolled" sequence example

.false
{
Inline:
		// "InlineA" Timing: 25.00 = 5+3.66+3.66+5.33+4+3.33
		sta	$_IO_Temp
		php
		rep	#0x20
		lda	$0x00
		and	#0xe0ff
		xba
		// "InlineB" Timing: 18.33 = 6+5.33+7
		sta	$_JMPiU_Action
		lda	$0x01
		jmp	[$_JMPiU_Action]
ROM:
		// "ROM" Timing: 15.66 = 3+5.66+7
		and	#0x00ff
		ora	$_Bank
		jmp	[$_List]
List:
		// "List" Timing: 22.66 = 4+2.66+6+4.66+5.33
		cmp	#0xffff
		bne	$+b_next
		lda	$_IO_Temp
		plp
		jmp	$=Destination


		// The "Inline" parts have multiple variants, the JIT+ZP+NoWrap variant is used for the example above
		//  AOT executes "Inline" in ROM which runs at least 6.66 cycles faster
		//  ABS adds 2p to the timing
		//  Wrap adds 1p or 2p to the timing for ZP and ABS respectively
		// The content of "InlineA" is affected by ZP/ABS and NoWarp/Wrap
		// The content of "InlineB" is only affected by ZP/ABS


		// 3 additional instructions are executed for each failed attempt
List:
		// Timing: 11.66 = 4+3.66+4
		cmp	#0xffff
		bne	$+b_next
b_next:
		jmp	$_Next


		// Variants of "InlineA" for page wrapping
		// Timing: 26.33 = 5+3.66+4+3.33+4+2.66+3.66
		sta	$_IO_Temp
		php
		lda	$0xff
		xba
		lda	$0x00
		and	#0xe0
		rep	#0x20


		// TL;DR
		// Total timing first try (ZP+JIT): 81.66 = 25.00 + 18.33 + 15.66 + 22.66
		// Time per failed attempt: 11.66
}

	// ---------------------------------------------------------------------------
	// Code for Interpret_and_Inline.asm, "Inline" part

	.macro	JMPiU_Inline_ZpNoWrap
JMPiU_Inline_ZpNoWrap:
		.mx	0x30
		sta	$_IO_Temp
		php
		rep	#0x20
		.mx	0x10
JMPiU_Inline_ZpNoWrap_Load:
		lda	$0xfe
		and	#0xe0ff
		xba
		sta	$_JMPiU_Action
JMPiU_Inline_ZpNoWrap_LastLoad:
		lda	$0xff
		jmp	[$_JMPiU_Action]
		.data8	0
	.endm


	.macro	JMPiU_Inline_ZpWrap
JMPiU_Inline_ZpWrap:
		.mx	0x30
		sta	$_IO_Temp
		php
		lda	$0xff
		xba
JMPiU_Inline_ZpWrap_Load:
		lda	$0x01
		and	#0xe0
		rep	#0x20
		.mx	0x10
		sta	$_JMPiU_Action
JMPiU_Inline_ZpWrap_LastLoad:
		lda	$0xff
		jmp	[$_JMPiU_Action]
		.data8	0
	.endm


	.macro	JMPiU_Inline_AbsNoWrap
JMPiU_Inline_AbsNoWrap:
		.mx	0x30
		sta	$_IO_Temp
		php
		rep	#0x20
		.mx	0x10
JMPiU_Inline_AbsNoWrap_Load:
		lda	$0x03fe
		and	#0xe0ff
		xba
		sta	$_JMPiU_Action
JMPiU_Inline_AbsNoWrap_LastLoad:
		lda	$0x03ff
		jmp	[$_JMPiU_Action]
		.data8	0
	.endm


	.macro	JMPiU_Inline_AbsWrap
JMPiU_Inline_AbsWrap:
		.mx	0x30
		sta	$_IO_Temp
		php
JMPiU_Inline_AbsWrap_FirstLoad:
		lda	$0x03ff
		xba
JMPiU_Inline_AbsWrap_SecondLoad:
		lda	$0x0301
		and	#0xe0
		rep	#0x20
		.mx	0x10
		sta	$_JMPiU_Action
JMPiU_Inline_AbsWrap_LastLoad:
		lda	$0x0301
		jmp	[$_JMPiU_Action]
		.data8	0
	.endm

	// ---------------------------------------------------------------------------
	// Code for this whole bank, "ROM" part

	.mx	0x10
	.macro	JMPiU_Mac
		.align	0x10
this__:
		// Indirect JMP
		.def	this__	this__&0xffff
		.def	lo__	this__&0xff
		.def	hi__	this__/0x100
		and	#0x00ff
		ora	$_Program_BankNum-1+lo__
		jmp	[$_JMPi_Start+hi__*3]

this__:
		.def	JMPiU_StackPullOffset	this__&0x1f

this__:
		// RTS as indirect jump
		php
		rep	#0x20
		ora	$_Program_BankNum-1+lo__
		jmp	[$_JMPi_Start+hi__*3]
	.endm
	.repeat	0x800, "JMPiU_Mac"

	// ---------------------------------------------------------------------------

JMPiU__Bank:
	.def	JMPiU__Bank		JMPiU__Bank&0xff0000

	.macro	JMPiU__Override		address
		.def	lo__	Zero+{0}&0xff
		.def	hi__	Zero+{0}/0x100
		.def	this__	lo__*0x100+hi__+JMPiU__Bank
		.addr	this__&0xffffe0, this__|0x1f
	.endm

	// ---------------------------------------------------------------------------

	// Interpreted RTS

	JMPiU__Override		0x2000
	trap

	EmuCall		"RtsNes", "?", "?"
	// NOTE: RTS into 0x20xx executes the operand of LDA $2,s which happens to be COP, an unused software interrupt
JMPiU__FromStack:
	sta	$_IO_Temp
	php
	rep	#0x20
	.mx	0x10
	lda	$2,s
	inc	a
	sta	$_IO_Temp16
	and	#0xe0ff
	xba
	sta	$_JMPiU_Action
	ora	#_JMPiU_StackPullOffset-1
	sta	$2,s
	lda	$_IO_Temp16+1
	plp
	rts

	// ---------------------------------------------------------------------------

	// Interpreted RTI

	JMPiU__Override		0x2001
	.data8	0
JMPiU__FromRti:
	sta	$_IO_Temp
	rep	#0x20
	.mx	0x10
	lda	$2,s
	sta	$_IO_Temp16
	and	#0xe0ff
	xba
	sta	$_JMPiU_Action
	ora	#_JMPiU_StackPullOffset-1
	sta	$2,s
	lda	$_IO_Temp16+1
	plp
	sep	#0x30
	rep	#0x0c
	rts

	// ---------------------------------------------------------------------------

	// Return from NMI at vblank
	.def	NmiReturn_FakeNesAddress	0x2008

	JMPiU__Override		NmiReturn_FakeNesAddress
	.fill	JMPiU_StackPullOffset
	jmp	$=Start__Irq_NesNmi_NonNativeReturn

	// ---------------------------------------------------------------------------

	// Return from IRQ
	.def	IrqReturn_FakeNesAddress	0x2009

	JMPiU__Override		IrqReturn_FakeNesAddress
	.fill	JMPiU_StackPullOffset
	jmp	$=Hdma__UpdateScrolling_ReturnFromIRQ

	// ---------------------------------------------------------------------------

	// Return from NMI auto detect
	.def	NmiReturn_FakeNesAddress2	0x200a

	JMPiU__Override		NmiReturn_FakeNesAddress2
	.fill	JMPiU_StackPullOffset
	lda	$_IO_Temp
	jmp	[$_NmiReturn_ReturnAddress2]

	// ---------------------------------------------------------------------------
