
	// ---------------------------------------------------------------------------

StaticRec_OriginCount:
	.data16	0

	// Non-zero when StaticRec is at work
StaticRec_Active:
	.data16	0

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	StaticRec__Init
StaticRec__Init:
	// Initialize
	call	Main__InitMemory
	call	Feedback__Init
	call	StaticRec__InitMemory
	call	Main__InitEmulation

	// Change bank
	phk
	plb

	// Reset origin count and trap regular emulators
	lda	$_StaticRec_OriginCount
	inc	$_StaticRec_OriginCount
	eor	$_StaticRec_OriginCount
	stz	$_StaticRec_OriginCount
	trapeq

	// Reset call table
	lda	#_StaticRec_Tables+0x400
	sta	$_StaticRec_AddFunctionForExe_CallTableOffset
	stz	$_StaticRec_AddFunctionForExe_CallTableLowByte
	ldx	#0x03fc
b_loop:
		lda	#_StaticRec_Tables+0x400
		sta	$=StaticRec_Tables+0,x
		lda	#0x0000
		sta	$=StaticRec_Tables+2,x
		dex
		dex
		dex
		dex
		bpl	$-b_loop

	call	Main__InitMemory

	// Format ROM
	call	Memory__FormatRom

	// Are we using native stack? If not, turn off every other stack options
	lda	$=RomInfo_StackEmulation
	and	#_RomInfo_StackEmu_NativeReturn
	bne	$+b_1
		lda	$=RomInfo_StackEmulation
		and	#_RomInfo_StackEmu_NATIVE_MASK
		sta	$=RomInfo_StackEmulation
b_1:

	// Copy palette mirror
	ldx	#0x007e
b_loop:
		lda	$=Gfx_PaletteTable,x
		lda	$=Gfx_PaletteTable+0x80,x
		dex
		dex
		bpl	$-b_loop

	return

	// ---------------------------------------------------------------------------

StaticRec_AddFunctionForExe_CallTableOffset:
	.data16		0
StaticRec_AddFunctionForExe_CallTableLowByte:
	.data16		0


	// Entry: int originalAddress, int newAddress, short recompileFlags
StaticRec__AddFunctionListingForExe:
	// OBSOLETE
	trap

	FromExeInit16

	// Low byte of original address must be greater or equal to the previous one entered
	lda	$0x0000
	and	#0x00ff
	cmp	$=StaticRec_AddFunctionForExe_CallTableLowByte
	trapcc
	sta	$=StaticRec_AddFunctionForExe_CallTableLowByte
	beq	$+b_1
		// New low byte
		asl	a
		asl	a
		tax
		lda	$=StaticRec_AddFunctionForExe_CallTableOffset
		sta	$=StaticRec_Tables+0,x
b_1:

	// Add listing
	lda	$=StaticRec_AddFunctionForExe_CallTableOffset
	tax
	lda	$0x0000
	sta	$=StaticRec_Tables+0,x
	lda	$0x0002
	sta	$=StaticRec_Tables+2,x
	lda	$0x0004
	sta	$=StaticRec_Tables+3,x
	lda	$0x0006
	sta	$=StaticRec_Tables+5,x
	lda	$0x0008
	sta	$=StaticRec_Tables+6,x

	// Increment count
	lda	$=StaticRec_AddFunctionForExe_CallTableLowByte
	asl	a
	asl	a
	tax
	lda	$=StaticRec_Tables+2,x
	clc
	adc	#8
	sta	$=StaticRec_Tables+2,x

	// Increment offset
	lda	$=StaticRec_AddFunctionForExe_CallTableOffset
	clc
	adc	#8
	sta	$=StaticRec_AddFunctionForExe_CallTableOffset

	stp

	// ---------------------------------------------------------------------------

	// Entry: short originalReturn, short originalCall
	// Return: int basePointer
StaticRec__AddCallLinkForExe:
	FromExeInit16

	// Get and increment origin count
	lda	$=StaticRec_OriginCount
	tax
	clc
	adc	#4
	trapcs
	sta	$=StaticRec_OriginCount

	// Add link, assuming it's a new link
	lda	$0x0000
	sta	$=StaticRec_Origins+0,x
	lda	$0x0002
	sta	$=StaticRec_Origins+2,x

	// Return base pointer
	stx	$0x0000
	lda	#_StaticRec_Origins/0x10000
	sta	$0x0002

	stp

	// ---------------------------------------------------------------------------

StaticRec__MainForExe:
	FromExeInit16
	call	StaticRec__Main
	stp

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	StaticRec__Main
StaticRec__Main:
	// Apply SelfMod
	call	SelfMod__Apply

	// Change bank
	phk
	plb

	// Index for the first 8 bits
	.local	_lowBits
	lda	#0x00ff
	sta	$.lowBits

	// Activate StaticRec mode
	lda	#1
	sta	$=StaticRec_Active

	// Address for writing call table
	.local	=callTableEP
	lda	#_StaticRec_Tables/0x100
	sta	$.callTableEP+1
	lda	#_StaticRec_Tables+0x400
	sta	$.callTableEP

StaticRec__Main_Loop2:
		// Define starting pointer for feedback addresses
		.local	=pointer
		lda	#_Feedback_Calls_LowerBound/0x100
		sta	$.pointer+1
		lda	#_Feedback_Calls_LowerBound
		sta	$.pointer

		// Start new call table
		lda	$.lowBits
		asl	a
		asl	a
		tax
		lda	$.callTableEP
		sta	$=StaticRec_Tables,x
		lda	#0
		sta	$=StaticRec_Tables+2,x

		// Loop through each known calls from feedback
StaticRec__Main_Loop:
			// Do low bits match?
			lda	[$.pointer]
			and	#0x00ff
			cmp	$.lowBits
			beq	$+b_in
			jmp	$_StaticRec__Main_Loop_Next
b_in:

				ldy	#0x0002
				lda	[$.pointer],y
				call	Recompiler__SetBank

				// Clear known calls
				ldx	#_Recompiler_FunctionList
				call	Array__Clear

				// Was this already done by exe?
				ldy	#2
				lda	[$.pointer],y
				tay
				lda	[$.pointer]
				clc
				WDM_RequestFunction
				bcc	$+b_else
					.local	_entryPoint, _compileFlags, _bankReservation
					sta	$.entryPoint
					stx	$.compileFlags
					sty	$.bankReservation

					// Allocate ROM space for code
					.local	=code
					tya
					WDM_PeekByteArray
					call	Memory__Alloc
					stx	$.code+0
					sta	$.code+2
					// Write code
					tay
					txa
					WDM_SetFunctionSnesAddress
					WDM_PullByteArray

					// Add to list
					// Original address
					ldy	#2
					lda	[$.pointer],y
					sta	[$.callTableEP],y
					lda	[$.pointer]
					sta	[$.callTableEP]
					// Recompiled address
					ldy	#4
					lda	$.code+1
					sta	[$.callTableEP],y
					lda	$.code
					clc
					adc	$.entryPoint
					dey
					sta	[$.callTableEP],y
					// Recompiler flags
					lda	$.compileFlags
					ldy	#6
					sta	[$.callTableEP],y

					bra	$+b_1
					.unlocal	=code
					.unlocal	_entryPoint, _compileFlags, _bankReservation
b_else:
					// Call recompiler
					.precall	Recompiler__Build		_romAddr, _compileType
					lda	[$.pointer]
					// Address must be in ROM range
					//bpl	$+StaticRec__Main_Loop_Next
					// Address must be >= 0x8000
					cmp	#0x8000
					bcc	$+StaticRec__Main_Loop_Next
					sta	$.Param_romAddr
					lda	#_Recompiler_CompileType_MoveToCart
					sta	$.Param_compileType
					call

					// Add to list
					lda	[$.Recompiler_FunctionList+3]
					sta	[$.callTableEP]
					ldy	#2
					lda	[$.Recompiler_FunctionList+3],y
					sta	[$.callTableEP],y
					ldy	#4
					lda	[$.Recompiler_FunctionList+3],y
					sta	[$.callTableEP],y
					ldy	#6
					lda	[$.Recompiler_FunctionList+3],y
					sta	[$.callTableEP],y
b_1:

				// Increment table length, assume carry clear after asl
				lda	$.lowBits
				asl	a
				asl	a
				tax
				lda	#8
				adc	$=StaticRec_Tables+2,x
				sta	$=StaticRec_Tables+2,x

				// Increment table pointer, assume carry clear from previous adc
				lda	#8
				adc	$.callTableEP
				sta	$.callTableEP

StaticRec__Main_Loop_Next:
			// Next
			lda	#3
			clc
			adc	$.pointer
			sta	$.pointer
			cmp	$=Feedback_Calls_Top
			bcs	$+StaticRec__Main_Loop_End
			jmp	$_StaticRec__Main_Loop
StaticRec__Main_Loop_End:

		// Next Loop2
		dec	$.lowBits
		bmi	$+StaticRec__Main_Loop2_End
		jmp	$_StaticRec__Main_Loop2
StaticRec__Main_Loop2_End:

	// Disable StaticRec mode
	lda	#0
	sta	$=StaticRec_Active

	return

	// ---------------------------------------------------------------------------

	// UNUSED
StaticRec_ListStart:
	//.fill	0x200
StaticRec_ListLength:
	//.fill	0x200

	// ---------------------------------------------------------------------------

	.mx	0x00

	.func	StaticRec__InitMemory
StaticRec__InitMemory:
	// Fast access to StaticRec table
	lda	#_StaticRec_Tables/0x100
	sta	$.Recompiler_StaticRec_Table+1

	// Are we using StaticRec?
	lda	$=StaticRec_OriginCount
	bne	$+StaticRec__InitMemory_In
		return
StaticRec__InitMemory_In:
	// Keep origin count for later
	tax

	// Bank 0x7f must be empty
	lda	$=Memory_Top+0x7f0000
	trapne
	Exception	"Memory Not Empty{}{}{}Bank 0x7F was not empty during initialization. The first element in this bank must be reserved for AOT compiler calls."

	// Allocate memory in bank 0x7f
	lda	#0x007f
	call	Memory__Alloc

	lda	$=StaticRec_OriginCount
	tax

	bra	$+StaticRec__InitMemory_Loop_Entry
StaticRec__InitMemory_Loop:
		// Write
		lda	#_Interpret__StaticJsr*0x100+0x22
		sta	$0x7f0000,x
		lda	#_Interpret__StaticJsr/0x100
		sta	$0x7f0002,x

StaticRec__InitMemory_Loop_Entry:
		// Next
		dex
		dex
		dex
		dex
		bpl	$-StaticRec__InitMemory_Loop

	return

	// ---------------------------------------------------------------------------
