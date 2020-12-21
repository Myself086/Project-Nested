
	// NOTE: There are more macros in other files but macros in this file are global

	// ---------------------------------------------------------------------------
	// Thread lock/unlock (prevent IRQ)

	.macro	lock
		sei
	.endm

	.macro	unlock
		cli
	.endm
	
	// ---------------------------------------------------------------------------
	// Inc/dec alias macros

	.macro	ina
		inc	a
	.endm

	.macro	dea
		dec	a
	.endm

	// ---------------------------------------------------------------------------
	// Stack related macros

	// 15.33 cycles to change DB based on a local variable, 15.00 is possible but ruins register A
	.macro	ldb		dp
		pei	({0}-1)
		plb
		plb
	.endm

	// ---------------------------------------------------------------------------
	// Breakpoint

	// 7e0afe
	.macro	breakpoint
		sta	$=Breakpoint
	.endm

	// ---------------------------------------------------------------------------
	// Trap/exception related macros

	.macro	trap
trap__:
		bra	$-trap__
	.endm


	.macro	trapcc
trap__:
		bcc	$-trap__
	.endm


	.macro	trapcs
trap__:
		bcs	$-trap__
	.endm


	.macro	trapeq
trap__:
		beq	$-trap__
	.endm


	.macro	trapne
trap__:
		bne	$-trap__
	.endm


	.macro	trappl
trap__:
		bpl	$-trap__
	.endm


	.macro	trapmi
trap__:
		bmi	$-trap__
	.endm


	// Exception template:
	//  Exception	"Exception name{}{}{}Details.{}{}Solution."


	.macro	exception		Message
		Exception	"{0}"
	.endm


	.macro	Exception		Message
		ExceptionStart
		.string0	"{0}"
		ExceptionEnd
	.endm


	.macro	ExceptionStart
		.pushaddr
		.addr	ExceptionData,		ExceptionData|0x7fff
ExceptionStart__:
		// Pointer to next element
		.data16	0
		// PC value of last trap
		.data8	3
		.data24	trap__
	.endm


	.macro	ExceptionEnd
this__:
		// Link this element to the next
		.addr	ExceptionData,		ExceptionData|0x7fff
		.data16	this__
		.def	ExceptionData,		this__
		.pulladdr
	.endm

	// ---------------------------------------------------------------------------
	// Branch related macros

	.macro	jcc		dest
		bcs	$+branch__
			jmp	{0}
branch__:
	.endm

	.macro	jcs		dest
		bcc	$+branch__
			jmp	{0}
branch__:
	.endm

	.macro	jne		dest
		beq	$+branch__
			jmp	{0}
branch__:
	.endm

	.macro	jeq		dest
		bne	$+branch__
			jmp	{0}
branch__:
	.endm

	.macro	jpl		dest
		bmi	$+branch__
			jmp	{0}
branch__:
	.endm

	.macro	jmi		dest
		bpl	$+branch__
			jmp	{0}
branch__:
	.endm

	// ---------------------------------------------------------------------------
	// Switch related macros

	.macro	switch		count, defaultDestination, breakDestination
case_value__:
		.fill16	{0}, _{1}
		.def	case_break__	{2}
	.endm

	.macro	case		value
case_destination__:
		.pushaddr
		.addr	case_value__+{0}*2
		.data16	_case_destination__
		.pulladdr
	.endm

	.macro	casex		value
		.def	case_param1__	=Zero+{0}/2
		case	case_param1__
	.endm

	.macro	cases		value1, value2
case_destination__:
		.pushaddr
		.addr	case_value__+{0}*2
		.fill16	_Zero+{1}-{0}+1, _case_destination__
		.pulladdr
	.endm

	.macro	casesx		value1, value2
		.def	case_param1__	=Zero+{0}/2
		.def	case_param2__	=Zero+{1}/2
		cases	case_param1__, case_param2__
	.endm

	.macro	caseat		value, destination
		.pushaddr
		.addr	case_value__+{0}*2
		.data16	_Zero+{1}
		.pulladdr
	.endm

	.macro	break
		jmp	$_case_break__
	.endm

	// ---------------------------------------------------------------------------
	// Dictionary related macros

	.macro	Dict_NodeBegin		string
Dict_Node__:
		// Pointer to next element
		.data16	0
		// String size
		.data8	0
		// String data
this__:
		.string		"{0}"
that__:

		// Fix string size
		.pushaddr
		.addr		this__-1
		.data8		that__-this__
		.pulladdr
	.endm


	.macro	Dict_NodeEnd
This__:
		.pushaddr
		.addr	Dict_Node__
		.data16	This__
		.pulladdr
		.def	Dict_Node__		0
	.endm


	.macro	Dict_Null
		.data16	0
	.endm


	.macro	Dict_FakeNull
		.pushaddr
		.data16	0
		.pulladdr
	.endm


	.macro	Dict_Case		text
		Dict_NodeEnd
		Dict_NodeBegin	"{0}"
	.endm


	.macro	Dict_EndCase
		Dict_NodeEnd
		Dict_Null
	.endm

	// ---------------------------------------------------------------------------
	// Memory allocation related macros

	.macro	Mac_MemoryClear		object
		.precall	Memory__Trim	=StackPointer, _Length
		lda	$.{0}
		sta	$.Param_StackPointer
		lda	$.{0}+1
		sta	$.Param_StackPointer+1
		stz	$.Param_Length
		call
	.endm

	// ---------------------------------------------------------------------------
	// Call management related macros

	.macro	FakeCall	destination
		.pushaddr
			call	{0}
		.pulladdr
	.endm

	// ---------------------------------------------------------------------------
	// Mapper related macros

	.macro	iIOPort_InterfaceSwitch		defaultDestination
		switch	11, {0}, DP_Zero
	.endm

	// Load instructions
	.def	iIOPort_lda		0
	.def	iIOPort_ldx		1
	.def	iIOPort_ldy		2
	// Load indexed instructions
	.def	iIOPort_loadindexed		3
	.def	iIOPort_ldax	3
	.def	iIOPort_lday	4
	// Store instructions
	.def	iIOPort_store			5
	.def	iIOPort_sta		5
	.def	iIOPort_stx		6
	.def	iIOPort_sty		7
	.def	iIOPort_stax	8
	.def	iIOPort_stay	9
	// RMW instructions
	.def	iIOPort_readwrite		10
	.def	iIOPort_rmw		10

	.macro	IOPort_Compare		value, opcode, destination
		cmp	#_Zero+{0}
		{1}	$+b_skip__
			ldx	#_Zero+{2}
			jmp	$=Recompiler__GetIOAccess_ReturnMapper
b_skip__:
	.endm

	.macro	IOPort_CompareEnd
		jmp	$=Recompiler__GetIOAccess_DefaultMapper
	.endm

	// ---------------------------------------------------------------------------
	// Data segmentation related macros

	.macro	SegmentStart	ByteCount
		.pushaddr
		.def	segmentByteCount__	{0}
		.align	segmentByteCount__
	.endm
	.macro	SegmentEnd
		// Workaround for keeping end address
this__:
		// Pull address and verify that we haven't gone over the original limit (+1)
		.pulladdr
		.addrlow	this__
		.pushaddr
		.data8	0
		.pulladdr
	.endm

	.macro	Segment
this__:
		// Uncap address limit temporarily so we can align to the next segment
		.addr		this__
		.misalign	segmentByteCount__
		.align		segmentByteCount__
this__:

		// Lock address range to the new segment
		.def	temp__	segmentByteCount__-1
		.addr	this__, this__|temp__
	.endm
