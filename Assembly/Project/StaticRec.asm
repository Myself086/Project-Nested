
	// ---------------------------------------------------------------------------

StaticRec_OriginCount:
	.data16	0

	// Non-zero when StaticRec is at work
StaticRec_Active:
	.data16	0

	// ---------------------------------------------------------------------------

	.mx	0x00

	.func	StaticRec__Main
StaticRec__Main:
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

	// Activate StaticRec mode
	sta	$_StaticRec_Active

	call	Main__InitMemory

	// Format ROM
	lda	$=RomInfo_StaticRecBanks
	sta	$.DP_ZeroBank
	stz	$.DP_Zero
StaticRec__Main_LoopFormat:
		// Write bottom and top addresses
		lda	#0x0000
		ldy	#_Memory_Bottom-0x8000
		sta	[$.DP_Zero],y
		ldy	#_Memory_Top-0x8000
		sta	[$.DP_Zero],y
		lda	#_Memory_HeapStack-0x8000-4
		ldy	#_Memory_HeapStack-0x8000
		sta	[$.DP_Zero],y

		// Next bank
		inc	$.DP_ZeroBank
		lda	$.DP_ZeroBank
		xba
		cmp	$.DP_ZeroBank
		bcc	$-StaticRec__Main_LoopFormat
		beq	$-StaticRec__Main_LoopFormat

	// Index for the first 8 bits
	.local	_lowBits
	lda	#0x00ff
	sta	$.lowBits

	// Address for writing call table
	.local	=tableEP
	lda	#_StaticRec_Tables/0x100
	sta	$.tableEP+1
	lda	#_StaticRec_Tables+0x400
	sta	$.tableEP

StaticRec__Main_Loop2:
		// Define starting pointer for feedback addresses
		.local	=pointer
		lda	#_Feedback_EmptyPointer/0x100
		sta	$.pointer+1
		lda	#_Feedback_EmptyPointer+2
		sta	$.pointer

		// Start new call table
		lda	$.lowBits
		asl	a
		asl	a
		tax
		lda	$.tableEP
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

				// Set banks
				sep	#0x20
				.mx	0x20
				ldy	#0x0002
				lda	[$.pointer],y
				sta	$_Program_BankNum_8000
				sta	$_Program_BankNum_a000
				sta	$_Program_BankNum_c000
				sta	$_Program_BankNum_e000
				tax
				lda	$=RomInfo_BankLut_80,x
				sta	$_Program_Bank_0+2
				lda	$=RomInfo_BankLut_a0,x
				sta	$_Program_Bank_1+2
				lda	$=RomInfo_BankLut_c0,x
				sta	$_Program_Bank_2+2
				lda	$=RomInfo_BankLut_e0,x
				sta	$_Program_Bank_3+2
				rep	#0x20
				.mx	0x00

				// Clear known calls
				ldx	#_Recompiler_FunctionList
				call	Array__Clear

				// Call recompiler
				.precall	Recompiler__Build		_romAddr, _compileType
				lda	[$.pointer]
				// Address must be in ROM range
				//bpl	$+StaticRec__Main_Loop_Next
				// Address must be >= 0x8000
				cmp	#0x8000
				bcc	$+StaticRec__Main_Loop_Next
				sta	$.Param_romAddr
				lda	#_Recompiler_CompileType_MoveToRom
				sta	$.Param_compileType
				call

				// Optimize
//				.precall	Optimize__Simplify		=functionHeapStackPointer, _callIndex
//				sta	$.Param_callIndex
//				// Are we optimizing?
//				lda	$=RomInfo_Optimize
//				and	#_RomInfo_Optimize_StaticRec
//				beq	$+b_1
//					stx	$.Param_functionHeapStackPointer
//					sty	$.Param_functionHeapStackPointer+2
//					call
//b_1:

				// Add to list
				lda	[$.Recompiler_FunctionList+3]
				sta	[$.tableEP]
				ldy	#2
				lda	[$.Recompiler_FunctionList+3],y
				sta	[$.tableEP],y
				ldy	#4
				lda	[$.Recompiler_FunctionList+3],y
				sta	[$.tableEP],y
				ldy	#6
				lda	[$.Recompiler_FunctionList+3],y
				sta	[$.tableEP],y

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
				adc	$.tableEP
				sta	$.tableEP

StaticRec__Main_Loop_Next:
			// Next
			lda	#3
			clc
			adc	$.pointer
			sta	$.pointer
			cmp	$=Feedback_EmptyPointer
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

	// Are we using native stack? If not, turn off every other stack options
	lda	$=RomInfo_StackEmulation
	and	#_RomInfo_StackEmu_NativeReturn
	bne	$+b_1
		//lda	#0
		sta	$=RomInfo_StackEmulation
b_1:

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
