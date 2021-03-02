

	.mx	0x20
	.func	Recompiler__Reset
Recompiler__Reset:
	//               0         2           3      5        6     8       9
	// Array format: _current, .current_b, _base, .base_b, _top, .top_b, _increment
	
	sep	#0x20
	.mx	0x20

	// Set arrays
	ldy	#_BranchSrc_Start
	sty	$_Recompiler_BranchSrcList+0
	sty	$_Recompiler_BranchSrcList+3
	lda	#^BranchSrc_Start
	sta	$_Recompiler_BranchSrcList+2
	sta	$_Recompiler_BranchSrcList+5
	ldy	#_BranchSrc_End
	sty	$_Recompiler_BranchSrcList+6
	lda	#^BranchSrc_End
	sta	$_Recompiler_BranchSrcList+8
	ldy	#_BranchSrc_ELength
	sty	$_Recompiler_BranchSrcList+9

	ldy	#_BranchDest_Start
	sty	$_Recompiler_BranchDestList+0
	sty	$_Recompiler_BranchDestList+3
	lda	#^BranchDest_Start
	sta	$_Recompiler_BranchDestList+2
	sta	$_Recompiler_BranchDestList+5
	ldy	#_BranchDest_End
	sty	$_Recompiler_BranchDestList+6
	lda	#^BranchDest_End
	sta	$_Recompiler_BranchDestList+8
	ldy	#_BranchDest_ELength
	sty	$_Recompiler_BranchDestList+9

	ldy	#_KnownCalls_Start
	sty	$_Recompiler_FunctionList+0
	sty	$_Recompiler_FunctionList+3
	lda	#^KnownCalls_Start
	sta	$_Recompiler_FunctionList+2
	sta	$_Recompiler_FunctionList+5
	ldy	#_KnownCalls_End
	sty	$_Recompiler_FunctionList+6
	lda	#^KnownCalls_End
	sta	$_Recompiler_FunctionList+8
	ldy	#_KnownCalls_ELength
	sty	$_Recompiler_FunctionList+9

	rep	#0x30
	.mx	0x00

	// Reset known calls
	ldx	#_Recompiler_FunctionList
	call	Array__Clear

	// Tell EmulSNES where the known calls are
	lda	#_RomInfo_BankLut/0x100
	ldx	#_Recompiler_FunctionList
	ldy	#_StaticRec_Tables/0x100
	WDM_ExportCallList

	// Prepare recompile RAM range
	lda	$=RomInfo_CpuSettings
	and	#_RomInfo_Cpu_RecompilePrgRam
	beq	$+b_else
		lda	#0x6000
		bra	$+b_1
b_else:
		lda	#0x8000
b_1:
	sta	$_Recompile_PrgRamTopRange

	return

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Recompiler__Build		_romAddr, _compileType
	// Compile type flags
	.def	Recompiler_CompileType_MoveToRom	0x0001
	// Return: A = Index for function list, X = HeapStack pointer, Y = HeapStack pointer bank
Recompiler__Build:
	.local	=destListReadP
	.local	_startAddr, =readAddr
	.local	_opcodeX2
	.local	_recompileFlags, _stackTrace, _stackTraceReset, _stackDepth
	.local	=bankStart
	// TODO: Replace stackTrace with stackDepth

	// Change bank
	phk
	plb

	// Prepare forced recompile flags
	stz	$.recompileFlags
	lda	$=RomInfo_StackEmulation
	and	#_RomInfo_StackEmu_NativeReturn
	bne	$+b_else
		lda	#_Opcode_F_PullReturn
		tsb	$.recompileFlags
		lda	#0x4000
		sta	$.stackTrace
		sta	$.stackTraceReset
		bra	$+b_1
b_else:
		stz	$.stackTrace
		stz	$.stackTraceReset
b_1:

	// Clear lists
	ldx	#_Recompiler_BranchSrcList
	call	Array__Clear
	ldx	#_Recompiler_BranchDestList
	call	Array__Clear
	
	// Keep base address for reading
	ldx	$.Recompiler_BranchDestList
	stx	$.destListReadP
	ldx	$.Recompiler_BranchDestList+1
	stx	$.destListReadP+1

	// Add current ROM address to destinations
	lda	$.romAddr
	sta	[$.Recompiler_BranchDestList]
	lda	#0x0100
	ldy	#0x0006
	sta	[$.Recompiler_BranchDestList],y
	ldx	#_Recompiler_BranchDestList
	ldy	#0x0002
	call	Array__InsertIfDifferent

	// Set bank for readAddr
	lda	$.romAddr
	bmi	$+Recompiler__Build_RomRange
		// Is this within recompile range?
		cmp	$_Recompile_PrgRamTopRange
		bcs	$+b_1
			lda	$.romAddr
			unlock
			trap
			Exception	"Compiler Error - Bad Call{}{}{}A call was made to 0x{A:X}, this address is in an unsupported range."
b_1:

		// SRAM range
		lda	#0xb0b0
		sta	$.readAddr+1
		sta	$.bankStart+1
		stz	$.bankStart
		bra	$+Recompiler__Build_SkipRomRange

Recompiler__Build_RomRange:
		xba
		and	#0x00e0
		tax
		lda	$_Program_Bank+1,x
		sta	$.readAddr+1
		sta	$.bankStart+1
		stz	$.bankStart

Recompiler__Build_SkipRomRange:

	// Loop through the list of destination
Recompiler__Build_loop1:
		// Read next destination
		lda	[$.destListReadP]
		sta	$.readAddr
		sta	$.startAddr
		ldy	#0x0006
		lda	[$.destListReadP],y
		sta	$.stackDepth

Recompiler__Build_loop1_loop:
			lda	[$.readAddr]
			and	#0x00ff
			asl	a
			tay
			ldx	$_Opcode__RecompileType,y
			jmp	($_Recompiler__Build_loop1_loop_switch,x)
			// Assume carry clear for any destination

Recompiler__Build_loop1_loop_switch:
				.data16	_Recompiler__Build_loop1_loop_switch_Error
				.data16	_Recompiler__Build_loop1_loop_switch_Regular
				.data16	_Recompiler__Build_loop1_loop_switch_Branch
				.data16	_Recompiler__Build_loop1_loop_switch_Jmp
				.data16	_Recompiler__Build_loop1_loop_switch_JmpIndexed
				.data16	_Recompiler__Build_loop1_loop_switch_Jsr
				.data16	_Recompiler__Build_loop1_loop_switch_Brk
				.data16	_Recompiler__Build_loop1_loop_switch_Return
				.data16	_Recompiler__Build_loop1_loop_switch_Cop
				.data16	_Recompiler__Build_loop1_loop_switch_Push
				.data16	_Recompiler__Build_loop1_loop_switch_Pull
				.data16	_Recompiler__Build_loop1_loop_switch_Tsx
				.data16	_Recompiler__Build_loop1_loop_switch_Branch
				.data16	_Recompiler__Build_loop1_loop_switch_NesReturn
				.data16	_Recompiler__Build_loop1_loop_switch_SnesReturn
				.data16	_Recompiler__Build_loop1_loop_switch_IllegalNop

Recompiler__Build_loop1_loop_switch_IllegalNop:
					// Are we allowed to recompile it?
					lda	$=RomInfo_CpuSettings
					and	#_RomInfo_Cpu_IllegalNop
					jeq	$_Recompiler__Build_loop1_loop_switch_Error
						// Yes
						jmp	$_Recompiler__Build_loop1_loop_next


Recompiler__Build_loop1_loop_switch_Branch:
					// Add destination
					sty	$.opcodeX2
					ldy	#0x0001
					lda	[$.readAddr],y
					and	#0x00ff
					adc	#0x7f80
					eor	#0x7f80
					adc	$.readAddr
					inc	a
					inc	a
					sta	[$.Recompiler_BranchDestList]
					ldx	#_Recompiler_BranchDestList
					ldy	#0x0002
					call	Array__InsertIfDifferent

					// Merge stack depth
					clc
					adc	#6
					tay
					lda	$.stackDepth
					ora	[$.Recompiler_BranchDestList+3],y
					sta	[$.Recompiler_BranchDestList+3],y

					// Are at least 2 bits set? If so, flag a stack depth error
					dec	a
					and	[$.Recompiler_BranchDestList],y
					beq	$+b_1
						lda	#_Opcode_F_StackDepthError
						tsb	$.recompileFlags
b_1:

					// Continue to next case
					ldy	$.opcodeX2
					clc
					jmp	$_Recompiler__Build_loop1_loop_next

Recompiler__Build_loop1_loop_switch_Jsr:
					jmp	$_Recompiler__Build_loop1_loop_next

Recompiler__Build_loop1_loop_switch_Jmp:
					// Point to index 1 while testing address ranges
					ldy	#0x0001

					// Is this jump pointing towards another bank?
					lda	$.readAddr
					eor	[$.readAddr],y
					and	$=RomInfo_PrgBankingMask
					beq	$+b_1
						// Is target range considered static?
						lda	[$.readAddr],y
						jsr	$_Recompiler__Build_IsRangeStatic
						jcc	$_Recompiler__Build_loop1_next
b_1:

					// Is this jump going out of range?
					lda	$=RomInfo_JmpRange
					bmi	$+Recompiler__Build_loop1_loop_switch_Jmp_NoRangeTest
						//ldy	#0x0001
						sec
						sbc	[$.readAddr],y
						adc	$.readAddr
						cmp	$=RomInfo_JmpRange_x2
						jcs	$_Recompiler__Build_loop1_next_clc
Recompiler__Build_loop1_loop_switch_Jmp_NoRangeTest:

					// Add to list
					sty	$.opcodeX2
					lda	[$.readAddr],y
					sta	[$.Recompiler_BranchDestList]
					ldx	#_Recompiler_BranchDestList
					ldy	#0x0002
					call	Array__InsertIfDifferent

					// Merge stack depth
					clc
					adc	#6
					tay
					lda	$.stackDepth
					ora	[$.Recompiler_BranchDestList+3],y
					sta	[$.Recompiler_BranchDestList+3],y

					// Are at least 2 bits set? If so, flag a stack depth error
					dec	a
					and	[$.Recompiler_BranchDestList],y
					beq	$+b_1
						lda	#_Opcode_F_StackDepthError
						tsb	$.recompileFlags
b_1:

					// Next
					jmp	$_Recompiler__Build_loop1_next_clc

Recompiler__Build_loop1_loop_switch_Push:
					lda	#_Opcode_F_UsePush
					tsb	$.recompileFlags
					inc	$.stackTrace
					asl	$.stackDepth
					clc
					jmp	$_Recompiler__Build_loop1_loop_next

Recompiler__Build_loop1_loop_switch_Pull:
					lda	#_Opcode_F_UsePull
					tsb	$.recompileFlags

					// Is it followed by another pull?
					lda	#0x6868
					eor	[$.readAddr]
					beq	$+b_1

b_tonext:
					lsr	$.stackDepth
					clc
					//dec	$.stackTrace
					//bpl	$+Recompiler__Build_loop1_loop_next
					lda	$.stackTrace
					bne	$+Recompiler__Build_loop1_loop_next

					// Using legacy stack underflow detection?
					lda	$=RomInfo_StackEmulation
					and	#_RomInfo_StackEmu_StackUnderflow
					beq	$+b_2
						lda	#_Opcode_F_PullReturn
						tsb	$.recompileFlags
b_2:

					jmp	$_Recompiler__Build_loop1_loop_next

b_1:
						// Detecting pulling return
						tyx
						ldy	#0
						lda	#0x6868
b_loop:
							iny
							cmp	[$.readAddr],y
							beq	$-b_loop

						// Add to readAddr to point to the last PLA
						clc
						tya
						adc	$.readAddr
						sta	$.readAddr

						// Next
						txy
						jmp	$_Recompiler__Build_loop1_loop_next

Recompiler__Build_loop1_loop_switch_Tsx:
					// Flag as pulling return
					lda	#_Opcode_F_PullReturn
					tsb	$.recompileFlags
					jmp	$_Recompiler__Build_loop1_loop_next


Recompiler__Build_loop1_loop_switch_NesReturn:
					// Set "pull return" flag to change caller's code
					lda	#_Opcode_F_PullReturn
					tsb	$.recompileFlags
					jmp	$_Recompiler__Build_loop1_next


Recompiler__Build_loop1_loop_switch_Brk:
					// Nothing special here yet?
Recompiler__Build_loop1_loop_switch_SnesReturn:
Recompiler__Build_loop1_loop_switch_JmpIndexed:
Recompiler__Build_loop1_loop_switch_Error:
Recompiler__Build_loop1_loop_switch_Return:
					// Break from this loop
					jmp	$_Recompiler__Build_loop1_next

Recompiler__Build_loop1_loop_switch_Cop:
Recompiler__Build_loop1_loop_switch_Regular:
Recompiler__Build_loop1_loop_next:
			// Next opcode
			lda	$_Opcode__BytesTable,y
			adc	$.readAddr
			sta	$.readAddr
			jmp	$_Recompiler__Build_loop1_loop

Recompiler__Build_loop1_next_clc:
		clc
Recompiler__Build_loop1_next:
		// Assume carry clear from everything pointing here

		// Complete this range
		lda	$.readAddr
		ldy	#0x0002
		sta	[$.destListReadP],y

		// Next if more destinations are available
		lda	$.destListReadP
		adc	$.Recompiler_BranchDestList+9
		sta	$.destListReadP
		cmp	$.Recompiler_BranchDestList
		bcs	$+Recompiler__Build_loop1_exit
		jmp	$_Recompiler__Build_loop1
Recompiler__Build_loop1_exit:

//	// Is this function starting with PLA+PLA? (TODO: Replace this)
//	ldy	$.romAddr
//	lda	[$.bankStart],y
//	cmp	#0x6868
//	bne	$+b_1
//		// Remove "pull return" flag
//		lda	#_Opcode_F_PullReturn
//		trb	$.recompileFlags
//b_1:

	// Sort branch destinations
	ldx	#_Recompiler_BranchDestList
	ldy	#0x0002
	call	Array__Sort

	// Last used prefix for memory emulation, contains 0 when unknown or unpredictable
	.local	_memoryPrefix
	stz	$.memoryPrefix

	// Block flags, only applies if the first branch of a block goes back to the beginning of that block
	// - 0x8000, when false, indicates that a loop is waiting for something to change
	.local	_blockFlags
	.local	_blockStart
	stz	$.blockFlags
	stz	$.blockStart

	// Reset stack trace
	lda	$.stackTraceReset
	sta	$.stackTrace

	// Prepare reading destination list
	.local	=destRead, _destInc
	.local	=writeAddr
	lda	$.Recompiler_BranchDestList+3
	sta	$.destRead+0
	lda	$.Recompiler_BranchDestList+4
	sta	$.destRead+1
	lda	$.Recompiler_BranchDestList+9
	sta	$.destInc
	lda	#0x0000
	sta	[$.Recompiler_BranchDestList]
	// Add dummy destination to mark the end of the array
	lda	#0
	sta	[$.Recompiler_BranchDestList]
	ldx	#_Recompiler_BranchDestList
	call	Array__Insert
	// Reserve memory
	.local	=heapStackIndex
	lda	#0x007f
	ldx	#0x2000
	call	Memory__Alloc
	xba
	sta	$.heapStackIndex+1
	sta	$.writeAddr+1
	sty	$.heapStackIndex+0
	stx	$.writeAddr+0
Recompiler__Build_loop2:
		//.local	=readAddr
		.local	_lastReadAddr
		ldx	$.bankStart+1
		stx	$.readAddr+1
		lda	[$.destRead]
		sta	$.readAddr
		sta	$.blockStart
		ldy	#0x0002
		lda	[$.destRead],y
		inc	a
		sta	$.lastReadAddr
		// Load stack depth
		ldy	#0x0006
		lda	[$.destRead],y
		sta	$.stackDepth

Recompiler__Build_loop2_loop:
			// Are we on a branch destination?
			lda	[$.destRead]
			beq	$+Recompiler__Build_loop2_loop_skip2
			cmp	$.readAddr
			beq	$+Recompiler__Build_loop2_loop_in1
			bcs	$+Recompiler__Build_loop2_loop_skip2
				// TODO: Solve branches pointing inside another opcode's operand within the same function
				bra	$+Recompiler__Build_loop2_loop_skip1

Recompiler__Build_loop2_loop_in1:
					// Write new address for this branch
					lda	$.writeAddr
					ldy	#0x0004
					sta	[$.destRead],y

					// Merge stack depth
					ldy	#0x0006
					lda	[$.destRead],y
					ora	$.stackDepth
					sta	$.stackDepth

					// Reset block flags, keep starting address for this block
					stz	$.blockFlags
					lda	[$.destRead]
					sta	$.blockStart

					// Clear carry for ADC
					clc

Recompiler__Build_loop2_loop_skip1:

				// Increment destRead, assume carry clear from skipping bcs
				lda	$.destInc
				adc	$.destRead
				sta	$.destRead

				// Clear known memory prefix for optimizing memory emulation
				stz	$.memoryPrefix

				// Clear stack trace (old version of stackDepth)
				lda	$.stackTraceReset
				sta	$.stackTrace

Recompiler__Build_loop2_loop_skip2:

			// Read next byte and clear carry in the process (asl)
			.local	_thisOpcodeX2
			lda	[$.readAddr]
			and	#0x00ff
			asl	a
			tay
			sty	$.thisOpcodeX2

			// Read opcode type and execute code for this type
			ldx	$_Opcode__AddrMode,y
			jsr	($_Recompiler__Build_OpcodeType,x)

			// Reload opcode
			rep	#0x31
			ldy	$.thisOpcodeX2

			// Apply block flags
			lda	$_Opcode__BlockFlag,y
			tsb	$.blockFlags

			// Increment readAddr
			lda	$_Opcode__BytesTable_OneOrMore,y
			adc	$.readAddr
			sta	$.readAddr

			// Are we done?
			cmp	$.lastReadAddr
			bcc	$-Recompiler__Build_loop2_loop

		// Clear first range out of bound
		lda	#0x0000
		sta	[$.Recompiler_BranchDestList]
		// Find next address range
		ldx	$.destInc
		bra	$+Recompiler__Build_loop2_FindNext_In
Recompiler__Build_loop2_FindNext:
		// Next range
		txa
		adc	$.destRead
		sta	$.destRead

Recompiler__Build_loop2_FindNext_In:
		// Read next destination, assuming the array is sorted and we cover ranges that start at a lower than current address
		ldy	#0x0006
		lda	[$.destRead],y
		sta	$.stackDepth
		lda	[$.destRead]
		beq	$+Recompiler__Build_loop2_Exit
		cmp	$.readAddr
		bcc	$-Recompiler__Build_loop2_FindNext

		// Next
		jmp	$_Recompiler__Build_loop2
Recompiler__Build_loop2_Exit:

	// Fix branches and jumps
	.local	_srcRead, =srcBank, _srcReplace
	ldy	$.writeAddr+1
	sty	$.srcBank+1
	ldy	#0x0000
	tya	
	sta	[$.Recompiler_BranchSrcList],y
Recompiler__Build_loop3:
		sty	$.srcRead
		lda	[$.Recompiler_BranchSrcList+3],y
		beq	$+Recompiler__Build_loop3_exit

		// Find address
		sta	$.srcBank
		lda	[$.srcBank]
		sta	[$.Recompiler_BranchDestList]
		ldx	#_Recompiler_BranchDestList
		ldy	#0x0002
		call	Array__Find

		// Change jump address in the new code
		clc
		adc	#0x0004
		bcc	$+b_1
			unlock
			trap
			Exception	"Compiler Error - Bad Branch{}{}{}Branch source not found."
b_1:
		tay
		lda	[$.Recompiler_BranchDestList+3],y
		sta	[$.srcBank]

		// Next
		ldy	$.srcRead
		iny
		iny
		bra	$-Recompiler__Build_loop3
Recompiler__Build_loop3_exit:


	// Trim memory used
	.precall	Memory__Trim	=StackPointer, _Length
	lda	$.heapStackIndex+1
	sta	$.Param_StackPointer+1
	lda	$.heapStackIndex+0
	sta	$.Param_StackPointer+0
	lda	$.writeAddr
	sec
	sbc	[$.heapStackIndex]
	sta	$.Param_Length
	call

	// Are we copying to ROM?
	lda	#_Recompiler_CompileType_MoveToRom
	and	$.compileType
	bne	$+Recompiler__Build_CopyToRom
		// Find this function's starting address
		lda	$.romAddr
		sta	[$.Recompiler_BranchDestList]
		ldx	#_Recompiler_BranchDestList
		ldy	#0x0002
		call	Array__Find

		// Add this address to function list
		.precall	Recompiler__AddFunction		=originalFunction, =newFunction, _recompileFlags
		// Load new function address
		clc
		adc	#0x0004
		tay
		lda	[$.Recompiler_BranchDestList+3],y
		ldx	$.heapStackIndex+1
		stx	$.Param_newFunction+1
		tay
		// Load original function address
		lda	$.romAddr
		sta	$.Param_originalFunction
		xba
		and	#0x00e0
		tax
		lda	$_Program_BankNum,x
		sta	$.Param_originalFunction+2

		sty	$.Param_newFunction+0
		// Load flags
		lda	$.recompileFlags
		sta	$.Param_recompileFlags
		call
		// Return index for function list and HeapStack pointer
		ldx	$.heapStackIndex
		ldy	$.heapStackIndex+2
		return

Recompiler__Build_CopyToRom:
	.local	_length, =rtnHeapStack
	// Allocate memory in ROM
	lda	$.writeAddr
	sec
	sbc	[$.heapStackIndex]
	sta	$.length
	tax
	lda	#0xffff
	call	Memory__Alloc
	sta	$.rtnHeapStack+2
	sty	$.rtnHeapStack

	// Change read and write addresses
	ldy	$.writeAddr+1
	xba
	sta	$.writeAddr+1
	stx	$.writeAddr
	sty	$.readAddr+1
	lda	[$.heapStackIndex]
	sta	$.readAddr

	// Copy bytes over to ROM
	// Load banks
	phb
	sep	#0x20
	.mx	0x20
	lda	$.readAddr+2
	xba
	lda	$.writeAddr+2
	rep	#0x20
	.mx	0x00
	sta	$_Recompiler__Build_CopyToRom_Mvn+1
	// Load length
	lda	$.length
	// Load source and destination addresses
	ldx	$.readAddr
	ldy	$.writeAddr
	// Copy
Recompiler__Build_CopyToRom_Mvn:
	.data8	0x54, 0xff, 0xff
	// Restore bank
	plb

	// Look for JMP and replace their destination, keep carry clear during this loop
	ldy	#0
Recompiler__Build_CopyToRom_Loop:
		// Load next opcode
		lda	[$.readAddr],y
		and	#0x00ff
		asl	a
		tax

		// Is it a short JMP?
		eor	#_Zero+0x4c*2
		bne	$+Recompiler__Build_CopyToRom_Loop_Next
			// Fix JMP destination address
			iny
			lda	[$.readAddr],y
			sec
			sbc	$.readAddr
			clc
			adc	$.writeAddr
			sta	[$.writeAddr],y
			dey
			clc
Recompiler__Build_CopyToRom_Loop_Next:
		// Next opcode
		tya
		adc	$_Opcode__BytesTable65816,x
		tay

Recompiler__Build_CopyToRom_Loop_Next2:
		cpy	$.length
		bcc	$-Recompiler__Build_CopyToRom_Loop

	// Delete memory used
	.precall	Memory__Trim	=StackPointer, _Length
	lda	$.heapStackIndex+1
	sta	$.Param_StackPointer+1
	lda	$.heapStackIndex+0
	sta	$.Param_StackPointer+0
	stz	$.Param_Length
	call

	// Find this function's starting address
	lda	$.romAddr
	sta	[$.Recompiler_BranchDestList]
	ldx	#_Recompiler_BranchDestList
	ldy	#0x0002
	call	Array__Find

	// Add this address to function list
	.precall	Recompiler__AddFunction		=originalFunction, =newFunction, _recompileFlags
	// Load new function address
	clc
	adc	#0x0004
	tay
	lda	[$.Recompiler_BranchDestList+3],y
	sec
	sbc	$.readAddr
	clc
	adc	$.writeAddr
	ldx	$.writeAddr+1
	stx	$.Param_newFunction+1
	tay
	// Load original function address
	lda	$.romAddr
	sta	$.Param_originalFunction
	xba
	and	#0x00e0
	tax
	lda	$_Program_BankNum,x
	sta	$.Param_originalFunction+2

	sty	$.Param_newFunction+0
	// Load flags
	lda	$.recompileFlags
	sta	$.Param_recompileFlags
	call
	// Return index for function list and HeapStack pointer
	ldx	$.rtnHeapStack
	ldy	$.rtnHeapStack+2
	return

	.unlocal	_length, =rtnHeapStack


	// Recompile table
Recompiler__Build_OpcodeType:
	.data16	_Recompiler__Build_OpcodeType_None
	.data16	_Recompiler__Build_OpcodeType_Impl
	.data16	_Recompiler__Build_OpcodeType_Abs
	.data16	_Recompiler__Build_OpcodeType_AbsX
	.data16	_Recompiler__Build_OpcodeType_AbsY
	.data16	_Recompiler__Build_OpcodeType_Const
	.data16	_Recompiler__Build_OpcodeType_Ind
	.data16	_Recompiler__Build_OpcodeType_XInd
	.data16	_Recompiler__Build_OpcodeType_IndY
	.data16	_Recompiler__Build_OpcodeType_Br
	.data16	_Recompiler__Build_OpcodeType_Zpg
	.data16	_Recompiler__Build_OpcodeType_ZpgX
	.data16	_Recompiler__Build_OpcodeType_ZpgY
	.data16	_Recompiler__Build_OpcodeType_Jmp
	.data16	_Recompiler__Build_OpcodeType_JmpI
	.data16	_Recompiler__Build_OpcodeType_Jsr
	.data16	_Recompiler__Build_OpcodeType_Brk
	.data16	_Recompiler__Build_OpcodeType_Rts
	.data16	_Recompiler__Build_OpcodeType_Rti
	.data16	_Recompiler__Build_OpcodeType_StaA
	.data16	_Recompiler__Build_OpcodeType_StxA
	.data16	_Recompiler__Build_OpcodeType_StyA
	.data16	_Recompiler__Build_OpcodeType_Pha
	.data16	_Recompiler__Build_OpcodeType_LdaA
	.data16	_Recompiler__Build_OpcodeType_LdxA
	.data16	_Recompiler__Build_OpcodeType_LdyA
	.data16	_Recompiler__Build_OpcodeType_Pla
	.data16	_Recompiler__Build_OpcodeType_Txs
	.data16	_Recompiler__Build_OpcodeType_Cop
	.data16	_Recompiler__Build_OpcodeType_StaAbsX
	.data16	_Recompiler__Build_OpcodeType_StaAbsY
	.data16	_Recompiler__Build_OpcodeType_StaXInd
	.data16	_Recompiler__Build_OpcodeType_StaIndY
	.data16	_Recompiler__Build_OpcodeType_LdaXInd
	.data16	_Recompiler__Build_OpcodeType_LdaIndY
	.data16	_Recompiler__Build_OpcodeType_YAbsX
	.data16	_Recompiler__Build_OpcodeType_LdaConst
	.data16	_Recompiler__Build_OpcodeType_Sei
	.data16	_Recompiler__Build_OpcodeType_Cli
	.data16	_Recompiler__Build_OpcodeType_LdaAbsX
	.data16	_Recompiler__Build_OpcodeType_LdaAbsY
	.data16	_Recompiler__Build_OpcodeType_Php
	.data16	_Recompiler__Build_OpcodeType_Plp
	.data16	_Recompiler__Build_OpcodeType_Brw
	.data16	_Recompiler__Build_OpcodeType_RtsNes
	.data16	_Recompiler__Build_OpcodeType_Jsl
	.data16	_Recompiler__Build_OpcodeType_Rmw
	.data16	_Recompiler__Build_OpcodeType_RmwX
	.data16	_Recompiler__Build_OpcodeType_RtlSnes
	.data16	_Recompiler__Build_OpcodeType_IllyNop

	// Entry: A = Opcode * 2, X = Free, Y = Free
	// Allowed to return any mode

Recompiler__Build_OpcodeType_Impl:
	// Implied:		inx, dex, clc ...
	lsr	a
	sta	[$.writeAddr]
	inc	$.writeAddr
	rts


Recompiler__Build_OpcodeType_Sei:
	ldx	#_Inline__Sei
	lda	#_Inline__Sei/0x10000
	jmp	$_Recompiler__Build_Inline


Recompiler__Build_OpcodeType_Cli:
	ldx	#_Inline__Cli
	lda	#_Inline__Cli/0x10000
	jmp	$_Recompiler__Build_Inline


Recompiler__Build_OpcodeType_Php:
	asl	$.stackDepth
	inc	$.stackTrace
	jmp	$_Recompiler__Build_OpcodeType_Impl


Recompiler__Build_OpcodeType_Plp:
	lsr	$.stackDepth
	ldx	#_Inline__Plp
	lda	#_Inline__Plp/0x10000
	jmp	$_Recompiler__Build_Inline


Recompiler__Build_OpcodeType_LdaA:
	ldx	#_iIOPort_lda*2
	bra	$+Recompiler__Build_OpcodeType_AbsIO
Recompiler__Build_OpcodeType_LdxA:
	//ldx	#_iIOPort_ldx*2
	ldx	#_iIOPort_lda*2
	bra	$+Recompiler__Build_OpcodeType_AbsIO
Recompiler__Build_OpcodeType_LdyA:
	//ldx	#_iIOPort_ldy*2
	ldx	#_iIOPort_lda*2
	bra	$+Recompiler__Build_OpcodeType_AbsIO
Recompiler__Build_OpcodeType_StaA:
	ldx	#_iIOPort_sta*2
	bra	$+Recompiler__Build_OpcodeType_AbsIO
Recompiler__Build_OpcodeType_StxA:
	ldx	#_iIOPort_stx*2
	bra	$+Recompiler__Build_OpcodeType_AbsIO
Recompiler__Build_OpcodeType_StyA:
	ldx	#_iIOPort_sty*2
	bra	$+Recompiler__Build_OpcodeType_AbsIO
Recompiler__Build_OpcodeType_RmwX:
	// TODO: Support RMW Abs,X
Recompiler__Build_OpcodeType_Rmw:
	ldx	#_iIOPort_rmw*2
	bra	$+Recompiler__Build_OpcodeType_AbsIO

Recompiler__Build_OpcodeType_Abs:
	ldx	#0x0000
Recompiler__Build_OpcodeType_AbsIO:
	// Absolute:	lda	$0x0123
	lsr	a
	sta	[$.writeAddr]
	ldy	#0x0001

	// Are we in ROM range?
	lda	[$.readAddr],y
	bpl	$+Recompiler__Build_OpcodeType_Abs_SkipStoreCondition
		// Is it a store opcode?
		cpx	#_iIOPort_store*2
		bcs	$+Recompiler__Build_OpcodeType_Abs_IO
		jmp	$_Recompiler__Build_OpcodeType_Abs_HighRange
Recompiler__Build_OpcodeType_Abs_SkipStoreCondition:
	// Are we in SRAM range?
	cmp	#0x6000
	bcc	$+Recompiler__Build_OpcodeType_Abs_SkipSramRange
		// Is it storing?
		cpx	#_iIOPort_store*2
		bcs	$+b_1
			// Load instruction, clear carry before jumping to another case
			//clc
			jmp	$_Recompiler__Build_OpcodeType_Abs_HighRange
b_1:
		// Store instruction
		jmp	$_Recompiler__Build_OpcodeType_StaAbs_HighRange
Recompiler__Build_OpcodeType_Abs_SkipSramRange:
	// Are we reading gamepad inputs?
	and	#0xfffe
	cmp	#0x4016
	jeq	$_Recompiler__Build_OpcodeType_Abs_HighRange
	// Are we in I/O range?
	lda	[$.readAddr],y
	bit	#0x6000
	beq	$+Recompiler__Build_OpcodeType_Abs_Pass2
Recompiler__Build_OpcodeType_Abs_IO:
		// Set block flag
		ldy	#0xffff
		sty	$.blockFlags

		// Get IO access call pointer (TODO: Fix iIOPort_rmw)
		cpx	#_iIOPort_rmw*2
		beq	$+Recompiler__Build_OpcodeType_Abs_PassRmw
		phx
		txy
		tax
		call	Recompiler__GetIOAccess
		plx
		cpx	#_iIOPort_loadindexed*2
		bcc	$+Recompiler__Build_OpcodeType_Abs_Pass4

Recompiler__Build_OpcodeType_Abs_Pass3:
	jmp	$_Recompiler__Build_CoreCall

Recompiler__Build_OpcodeType_Abs_Pass4:
	jsr	$_Recompiler__Build_CoreCall

	// Write original read
	lda	$.thisOpcodeX2
	lsr	a
	ldy	#0x0001
	sta	[$.writeAddr]
	lda	#_IO_Temp
	sta	[$.writeAddr],y

	// Add to write address, assume carry clear from the 'lsr'
	lda	#0x0003
	adc	$.writeAddr
	sta	$.writeAddr
	rts

Recompiler__Build_OpcodeType_Abs_Pass2:
	and	#0x07ff
	sta	[$.writeAddr],y
	lda	#0x0003
	clc
	adc	$.writeAddr
	sta	$.writeAddr
	rts

Recompiler__Build_OpcodeType_Abs_PassRmw:
	ldy	#_iIOPort_stai*2
	tax
	call	Recompiler__GetIOAccess
	pha

	// Prepare memory emulation prefix
	ldy	#1
	lda	[$.readAddr],y
	cmp	#0x6000
	bcc	$+b_1
		// ROM and SRAM range
		pha
		xba
		and	#0x00e0
		tay
		// Is memory prefix known?
		ldx	$.memoryPrefix
		beq	$+b_2
			// Is it the same memory prefix?
			cpy	$.memoryPrefix
			bne	$+b_diff
				// Same
				pla
				bra	$+b_noPrefix
b_diff:
				// Different
				ora	#0x0100
				tay
				and	#0x00ff
b_2:
		sta	$.memoryPrefix
		// Write prefix
		lda	[$.writeAddr]
		pha
		tyx
		lda	$=Inline_StoreDirect_LUT,x
		tax
		lda	#_Inline_StoreDirect_LUT/0x10000
		jsr	$_Recompiler__Build_Inline2
		// Write original code
		ldy	#0x0001
		pla
		sta	[$.writeAddr]
		pla
		sta	[$.writeAddr],y
b_1:
b_noPrefix:

	// Write inlined code
	ldx	#_Inline__RmwToIO
	lda	#_Inline__RmwToIO/0x10000
	jsr	$_Recompiler__Build_InlineNoInc
	tyx
	// Change load address
	ldy	#1
	lda	[$.readAddr],y
	ldy	#_Inline__RmwToIO_Load-Inline__RmwToIO+1
	sta	[$.writeAddr],y
	// Change call
	lda	$.DP_ZeroBank-1
	ldy	#_Inline__RmwToIO_Call-Inline__RmwToIO+2
	sta	[$.writeAddr],y
	pla
	dey
	sta	[$.writeAddr],y

	// Add to write address
	txa
	clc
	adc	$.writeAddr
	sta	$.writeAddr
	rts


Recompiler__Build_OpcodeType_AbsX:
Recompiler__Build_OpcodeType_YAbsX:
Recompiler__Build_OpcodeType_AbsY:
	// TODO: Support IO

	// Write opcode
	lsr	a
	sta	[$.writeAddr]

	// Jumping from regular Abs
Recompiler__Build_OpcodeType_Abs_HighRange:

	// Preload Y index
	ldy	#0x0001

	// Are we using banking emulation?
	lda	$=RomInfo_MemoryEmulation
	bit	#_RomInfo_MemEmu_AbsBank
	beq	$+b_1
		// Are we using bank crossing emulation?
		bit	#_RomInfo_MemEmu_AbsCrossBank
		beq	$+b_1
			// Is this opcode indexed?
			lda	[$.readAddr]
			and	#0x00ff
			tax
			lda	$_Opcode__IndexRegister,x
			and	#0x00ff
			beq	$+b_1
			cmp	#3
			bcs	$+b_1
			tax
			// Verify that the address can cross bank boundary
			lda	[$.readAddr],y
			ora	$=RomInfo_PrgBankingMask
			cmp	#0xff01
			jcs	$_Recompiler__Build_OpcodeType_Abs_BankCrossing
b_1:

	// Read and write address
	lda	[$.readAddr],y
	sta	[$.writeAddr],y

	// Are we in either SRAM or ROM range?
	cmp	#0x6000
	bcc	$+b_1
		// ROM and SRAM range
		pha
		xba
		and	#0x00e0
		tay
		// Is memory prefix known?
		ldx	$.memoryPrefix
		beq	$+b_2
			// Is it the same memory prefix?
			cpy	$.memoryPrefix
			bne	$+b_diff
				// Same
				pla
				bra	$+b_noPrefix
b_diff:
				// Different
				ora	#0x0100
				tay
				and	#0x00ff
b_2:
		sta	$.memoryPrefix
		// Write prefix
		lda	[$.writeAddr]
		pha
		tyx
		lda	$=Inline_CmdDirect_LUT,x
		tax
		lda	#_Inline_CmdDirect_LUT/0x10000
		jsr	$_Recompiler__Build_Inline2
		// Write original code
		ldy	#0x0001
		pla
		sta	[$.writeAddr]
		pla
		sta	[$.writeAddr],y

b_noPrefix:
		// Add to write address
		lda	#0x0003
		clc
		adc	$.writeAddr
		sta	$.writeAddr
		rts
b_1:
	lda	[$.readAddr],y
	sta	[$.writeAddr],y

	// Add to write address, assume carry clear from the 'lsr'
	lda	#0x0003
	adc	$.writeAddr
	sta	$.writeAddr
	rts


Recompiler__Build_OpcodeType_LdaAbsX:
Recompiler__Build_OpcodeType_LdaAbsY:
	// TODO: Support IO

	// Preload Y index and write opcode
	lsr	a
	sta	[$.writeAddr]
	ldy	#0x0001

	// Are we using banking emulation?
	lda	$=RomInfo_MemoryEmulation
	bit	#_RomInfo_MemEmu_AbsBank
	beq	$+Recompiler__Build_OpcodeType_LdaAbsY_Regular
		// Are we using bank crossing emulation?
		bit	#_RomInfo_MemEmu_AbsCrossBank
		beq	$+b_1
			// Is this opcode indexed?
			lda	[$.readAddr]
			and	#0x00ff
			tax
			lda	$_Opcode__IndexRegister,x
			and	#0x00ff
			beq	$+b_1
			cmp	#3
			bcs	$+b_1
			tax
			// Verify that the address can cross bank boundary
			lda	[$.readAddr],y
			ora	$=RomInfo_PrgBankingMask
			cmp	#0xff01
			jcs	$_Recompiler__Build_OpcodeType_Abs_BankCrossing
b_1:

		// Read and write address
		lda	[$.readAddr],y
		sta	[$.writeAddr],y

		// Are we in either SRAM or ROM range?
		cmp	#0x6000
		bcc	$+Recompiler__Build_OpcodeType_LdaAbsY_Regular
			// ROM and SRAM range
			pha
			xba
			and	#0x00e0
			tay
			// Is memory prefix known?
			ldx	$.memoryPrefix
			beq	$+b_2
				// Is it the same memory prefix?
				cpy	$.memoryPrefix
				bne	$+b_diff
					// Same
					pla
					bra	$+b_noPrefix
b_diff:
					// Different
					ora	#0x0100
					tay
					and	#0x00ff
b_2:
			sta	$.memoryPrefix
			lda	[$.writeAddr]
			pha
			tyx
			lda	$=Inline_LoadDirect_LUT,x
			tax
			lda	#_Inline_LoadDirect_LUT/0x10000
			jsr	$_Recompiler__Build_Inline2
			// Write original code
			ldy	#0x0001
			pla
			sta	[$.writeAddr]
			pla
			sta	[$.writeAddr],y

b_noPrefix:
			// Add to write address
			lda	#0x0003
			clc
			adc	$.writeAddr
			sta	$.writeAddr
			rts
Recompiler__Build_OpcodeType_LdaAbsY_Regular:
	lda	[$.readAddr],y
	sta	[$.writeAddr],y

	// Add to write address, assume carry clear from the 'lsr'
	lda	#0x0003
	adc	$.writeAddr
	sta	$.writeAddr
	rts


Recompiler__Build_OpcodeType_Abs_BankCrossing:
	// Ignore known memory prefix
	stz	$.memoryPrefix
	// Preserve opcode
	lda	[$.readAddr]
	pha
	// Read and preserve address
	ldy	#1
	lda	[$.readAddr],y
	pha
	// Calculate difference until boundary crossing
	eor	#0xffff
	inc	a
	and	#0x00ff
	sta	$.DP_Temp
	// Get page range
	lda	[$.readAddr],y
	xba
	and	#0x00e0
	// Which index register are we using? X should already contain 1 or 2
	clc
	dex
	beq	$+b_else
		// Indexed by Y
		adc	#_Inline_DirectYBankCrossing_LUT
		bra	$+b_1
b_else:
		// Indexed by X
		adc	#_Inline_DirectXBankCrossing_LUT
b_1:
	// Write prefix
	tax
	lda	$=Inline_DirectXBankCrossing_LUT&0xff0000,x
	tax
	lda	#_Inline_DirectXBankCrossing_LUT/0x010000
	ldy	$.DP_Temp
	jsr	$_Recompiler__Build_Inline2
	// Write original code
	ldy	#0x0001
	pla
	sta	[$.writeAddr],y
	pla
	sta	[$.writeAddr]

	// Add to write address
	lda	#0x0003
	clc
	adc	$.writeAddr
	sta	$.writeAddr
	rts


Recompiler__Build_OpcodeType_StaAbsY:
	ldx	#_iIOPort_stay*2
	bra	$+b_1
Recompiler__Build_OpcodeType_StaAbsX:
	ldx	#_iIOPort_stax*2
	//bra	$+b_1

b_1:
	// Write original opcode
	lsr	a
	sta	[$.writeAddr]

	// Are we in IO range?
	ldy	#0x0001
	lda	[$.readAddr],y
	and	#0xe000
	beq	$+b_1
	cmp	#0x6000
	beq	$+b_1
		// Interprete IO port
		lda	[$.readAddr],y
		jmp	$_Recompiler__Build_OpcodeType_Abs_IO
b_1:

	// Jumping from regular Abs
Recompiler__Build_OpcodeType_StaAbs_HighRange:

	// Copy destination address
	ldy	#0x0001
	lda	[$.readAddr],y
	sta	[$.writeAddr],y

	// Are we using banking emulation?
	lda	$=RomInfo_MemoryEmulation
	and	#_RomInfo_MemEmu_AbsBank
	beq	$+b_1
		// Are we in either SRAM or ROM range?
		lda	[$.readAddr],y
		cmp	#0x6000
		bcc	$+b_1
			// ROM and SRAM range
			pha
			xba
			and	#0x00e0
			tay
			// Is memory prefix known?
			ldx	$.memoryPrefix
			beq	$+b_2
				// Is it the same memory prefix?
				cpy	$.memoryPrefix
				bne	$+b_diff
					// Same
					pla
					bra	$+b_noPrefix
b_diff:
					// Different
					ora	#0x0100
					tay
					and	#0x00ff
b_2:
			sta	$.memoryPrefix
			lda	[$.writeAddr]
			pha
			tyx
			lda	$=Inline_StoreDirect_LUT,x
			tax
			lda	#_Inline_StoreDirect_LUT/0x10000
			jsr	$_Recompiler__Build_Inline2
			// Write original code
			ldy	#0x0001
			pla
			sta	[$.writeAddr]
			pla
			sta	[$.writeAddr],y

b_noPrefix:
			// Add to write address
			lda	#0x0003
			clc
			adc	$.writeAddr
			sta	$.writeAddr
			rts

b_1:
	// Add to write address
	lda	#0x0003
	clc
	adc	$.writeAddr
	sta	$.writeAddr
	rts


Recompiler__Build_OpcodeType_Ind:
Recompiler__Build_OpcodeType_IndY:
	// Do we have memory emulation turned on?
	lda	$=RomInfo_MemoryEmulation
	and	#_RomInfo_MemEmu_Load
	beq	$+Recompiler__Build_OpcodeType_Zpg
		stz	$.memoryPrefix
		lda	[$.readAddr]
		xba
		tay
		iny
		ldx	#_Inline_CmdIndirect
		lda	#_Inline_CmdIndirect/0x10000
		jsr	$_Recompiler__Build_Inline2NoInc
		phy

		// Fix call page
		lda	[$.readAddr]
		and	#0x00e0
		lsr	a
		lsr	a
		lsr	a
		lsr	a
		tax
		lda	$=Interpret__IndirectIO_PageTable,x
		ldy	#_Inline_CmdIndirect_Call-Inline_CmdIndirect+1
		sta	[$.writeAddr],y

		// Add to write address, assume carry clear from LSR
		pla
		adc	$.writeAddr
		sta	$.writeAddr

		bra	$+Recompiler__Build_OpcodeType_Zpg

Recompiler__Build_OpcodeType_LdaIndY:
	// Do we have memory emulation turned on?
	lda	$=RomInfo_MemoryEmulation
	and	#_RomInfo_MemEmu_Load
	beq	$+Recompiler__Build_OpcodeType_Zpg
		stz	$.memoryPrefix
		lda	[$.readAddr]
		xba
		tay
		iny
		ldx	#_Inline_LoadIndirect
		lda	#_Inline_LoadIndirect/0x10000
		jsr	$_Recompiler__Build_Inline2
		bra	$+Recompiler__Build_OpcodeType_Zpg

Recompiler__Build_OpcodeType_StaIndY:
	// Do we have memory emulation turned on?
	lda	$=RomInfo_MemoryEmulation
	and	#_RomInfo_MemEmu_Store
	beq	$+Recompiler__Build_OpcodeType_Zpg
		stz	$.memoryPrefix
		lda	[$.readAddr]
		xba
		tay
		iny
		ldx	#_Inline_StoreIndirect
		lda	#_Inline_StoreIndirect/0x10000
		jsr	$_Recompiler__Build_Inline2
		//bra	$+Recompiler__Build_OpcodeType_Zpg

Recompiler__Build_OpcodeType_Const:
Recompiler__Build_OpcodeType_Zpg:
Recompiler__Build_OpcodeType_ZpgX:
Recompiler__Build_OpcodeType_ZpgY:
	lda	[$.readAddr]
Recompiler__Build_OpcodeType_LdaConst_Regular:
	sta	[$.writeAddr]

	// Add to write address
	lda	$.writeAddr
	inc	a
	inc	a
	sta	$.writeAddr
	rts

Recompiler__Build_OpcodeType_LdaConst:
	// Is this a sequence for pushing a constant return address?
	ldy	#2
	lda	[$.readAddr],y
	cmp	#0xa948
	beq	$+Recompiler__Build_OpcodeType_LdaConst_PushReturn
b_back:

	// Is it LDA #0?
	lda	[$.readAddr]
	cmp	#0x00a9
	bne	$-Recompiler__Build_OpcodeType_LdaConst_Regular

	// Write TDC instead
	lda	#0x007b
	sta	[$.writeAddr]
	inc	$.writeAddr
	rts

Recompiler__Build_OpcodeType_LdaConst_PushReturn:
	// Are we using native stack?
	lda	$=RomInfo_StackEmulation
	and	#_RomInfo_StackEmu_NativeReturn
	beq	$-b_back

	// Expected sequence of code:
	//  lda	#high
	//  pha
	//  lda	#low
	//  pha
	// Expected sequence of bytes (from code above):
	//   0  1  2  3  4  5
	//  a9 __ 48 a9 __ 48
	// Resulting JIT code:
	//  lda	#low
	//  jsr	+
	//   pea $_originalReturn
	//   pea $_originalValue
	//   jsr $=Interpret
	//   nop
	//   rtl
	//  +
	// Resulting AOT code:
	//  lda	#low
	//  jsr	+
	//   jsr $=Interpret
	//   nop
	//   rtl
	//  +

	// Test last byte of the sequence
	ldy	#5
	lda	[$.readAddr],y
	and	#0x00ff
	cmp	#0x0048
	bne	$-Recompiler__Build_OpcodeType_Const

	// Is this sequence uninterrupted by labels? Assume carry set from CMP+BNE
	ldy	$.destInc
	lda	[$.destRead],y
	sbc	$.readAddr
	cmp	#6
	bcc	$-Recompiler__Build_OpcodeType_Const
		// Are we compiling into ROM?
		lda	#_Recompiler_CompileType_MoveToRom
		and	$.compileType
		bne	$+b_1
			// Write code
			ldx	#_Inline__PushConstantReturn
			lda	#_Inline__PushConstantReturn/0x10000
			jsr	$_Recompiler__Build_InlineNoInc
			tyx

			// Copy last LDA
			ldy	#3
			lda	[$.readAddr],y
			sta	[$.writeAddr]

			// Write call
			ldy	#_Inline__PushConstantReturn_Call-Inline__PushConstantReturn+2
			lda	$.writeAddr+1
			sta	[$.writeAddr],y
			dey
			txa
			clc
			adc	$.writeAddr
			sta	[$.writeAddr],y

			// Write original return
			ldy	#4
			lda	[$.readAddr],y
			eor	[$.readAddr]
			eor	#0x48a9
			inc	a
			ldy	#_Inline__PushConstantReturn_OriginalReturn-Inline__PushConstantReturn+1
			sta	[$.writeAddr],y

			// Write original value
			ldy	#_Inline__PushConstantReturn_OriginalValue-Inline__PushConstantReturn+1
			sta	[$.writeAddr],y

			// Add to read address to skip the sequence, 2 is added after RTS
			lda	#4
			clc
			adc	$.readAddr
			sta	$.readAddr

			// Add to write address
			txa
			clc
			adc	$.writeAddr
			sta	$.writeAddr
			rts

b_1:
		// TODO: Test this

		// Write code
		ldx	#_Inline__PushConstantReturnAOT
		lda	#_Inline__PushConstantReturnAOT/0x10000
		ldy	#0
		jsr	$_Recompiler__Build_Inline2NoInc
		tyx

		// Copy last LDA
		ldy	#3
		lda	[$.readAddr],y
		sta	[$.writeAddr]

		// Write original return
		lda	$=StaticRec_OriginCount
		tax
		ldy	#4
		lda	[$.readAddr],y
		eor	[$.readAddr]
		eor	#0x48a9
		inc	a
		sta	$=StaticRec_Origins+0,x

		// Write original value
		sta	$=StaticRec_Origins+2,x

		// Write and increment origin count, assume carry clear from previous adc
		txa
		ldy	#_Inline__PushConstantReturnAOT_JmpToRam-Inline__PushConstantReturnAOT+1
		sta	[$.writeAddr],y
		adc	#4
		sta	$=StaticRec_OriginCount

		// Add to read address to skip the sequence, 2 is added after RTS
		lda	#4
		adc	$.readAddr
		sta	$.readAddr

		// Add to write address
		lda	#_Inline__PushConstantReturnAOT_End-Inline__PushConstantReturnAOT
		adc	$.writeAddr
		sta	$.writeAddr
		rts


Recompiler__Build_OpcodeType_LdaXInd:
Recompiler__Build_OpcodeType_StaXInd:
Recompiler__Build_OpcodeType_XInd:
	// Do we have memory emulation turned on?
	lda	$=RomInfo_MemoryEmulation
	and	#_RomInfo_MemEmu_Load
	beq	$+b_1
		stz	$.memoryPrefix
		lda	[$.readAddr]
		xba
		tay
		iny
		ldx	#_Inline_CmdIndirectX
		lda	#_Inline_CmdIndirectX/0x10000
		jsr	$_Recompiler__Build_Inline2
b_1:
	jmp	$_Recompiler__Build_OpcodeType_Zpg


Recompiler__Build_OpcodeType_Brw:
	// Branch + wait, overrides STP illegal opcodes (TODO: Confirmation code for using these branches)

	// Remove bit 2 (originally bit 1 but the value is shifted)
	and	#0xfffb

	// Write branch opcode
	lsr	a
	eor	#0x0320
	sta	[$.writeAddr]
	lda	#0x004c
	ldy	#0x0002
	sta	[$.writeAddr],y

	// Calculate destination address
	lda	[$.readAddr]
	xba
	and	#0x00ff
	adc	#0x7f80
	eor	#0x7f80
	// Address + branch + 2
	adc	$.readAddr
	inc	a
	inc	a
	// Write destination address
	iny
	sta	[$.writeAddr],y

	// Reset block flags
	stz	$.blockFlags

	tax
	jmp	$_Recompiler__Build_OpcodeType_Brw_in


Recompiler__Build_OpcodeType_Br:
	// Couple this branch with a jump
	// Example for 'bne':
	// beq $+3
	// jmp $_destination

	// Write branch opcode
	lsr	a
	eor	#0x0320
	sta	[$.writeAddr]
	lda	#0x004c
	ldy	#0x0002
	sta	[$.writeAddr],y

	// Calculate destination address
	lda	[$.readAddr]
	xba
	and	#0x00ff
	adc	#0x7f80
	eor	#0x7f80
	// Address + branch + 2
	adc	$.readAddr
	inc	a
	inc	a
	// Write destination address
	iny
	sta	[$.writeAddr],y
	tax

	// Is Destination address the same as block's start?
	cmp	$.blockStart
	bne	$+b_1
	bit	$.blockFlags
	bmi	$+b_1
Recompiler__Build_OpcodeType_Brw_in:
	lda	$=RomInfo_NmiMode
	and	#_RomInfo_NmiMode_DetectIdling
	beq	$+b_1
		// Reset memory prefix
		stz	$.memoryPrefix

		// Keep current branch
		inc	$.writeAddr

		// Keep destination address
		phx

		// Get pointer for code to be written
		jsr	$_Recompiler__Build_OpcodeType_Br_Idle

		// Write code
		lda	#_Recompiler__Build_OpcodeType_Br_Idle/0x10000
		jsr	$_Recompiler__Build_Inline

		// Write destination address
		pla
		sta	[$.writeAddr]

		// Record this address so we can fix it later
		lda	$.writeAddr
		sta	[$.Recompiler_BranchSrcList]
		ldx	#_Recompiler_BranchSrcList
		call	Array__Insert

		// Add to write address
		inc	$.writeAddr
		inc	$.writeAddr

		rts
b_1:

	// Find address
	txa
	sta	[$.Recompiler_BranchDestList]
	ldx	#_Recompiler_BranchDestList
	ldy	#0x0002
	call	Array__Find

	// Is this destination known?
	clc
	adc	#0x0004
	bcs	$+b_1
		// Is this destination in range? Assume carry clear from BCS
		// destination - (writeAddr + 2)
		// destination - 2 - writeAddr
		tay
		lda	[$.Recompiler_BranchDestList+3],y
		beq	$+b_1
			sbc	#1
			sec								// Fix bug when destination is 0x0000
			sbc	$.writeAddr
			cmp	#0xff80
			bcc	$+b_1
				// Write branch
				sta	$.DP_ZeroBank
				lda	[$.readAddr]
				and	#0x00ff
				ora	$.DP_ZeroBank-1
				sta	[$.writeAddr]

				// Add to write address
				inc	$.writeAddr
				inc	$.writeAddr
				rts
b_1:

	// Record this address so we can fix it later
	lda	#3
	clc
	adc	$.writeAddr
	sta	[$.Recompiler_BranchSrcList]
	ldx	#_Recompiler_BranchSrcList
	call	Array__Insert

	// Add to write address
	lda	#0x0005
	clc
	adc	$.writeAddr
	sta	$.writeAddr
	rts

Recompiler__Build_OpcodeType_Br_Idle:
		// Keep destination address and number of bytes until branch
		.local	=brStart, _brByteCount
		lda	$.readAddr+1
		sta	$.brStart+1
		stx	$.brStart
		lda	$.readAddr
		sec
		sbc	$.brStart
		sta	$.brByteCount

		// Compare exception flags
		ldx	$.blockFlags

		// Bit shift
		cpx	#_Opcode__BlockFlag_BitShift
		bne	$+b_1
			lda	[$.brStart]
			tay
			lda	$_Opcode__BytesTable,y
			cmp	$.brByteCount
			bne	$+b_1
				ldx	#_Recompiler__Build_OpcodeType_Br_Idle_BitShift
				rts
b_1:

		// Default
		ldx	#_Recompiler__Build_OpcodeType_Br_Idle_Default
		rts

		.unlocal	=brStart, _brByteCount

Recompiler__Build_OpcodeType_Br_Idle_Default:
		// b.. $+7
		//  jsl $=Interpret__Idle
		//  stz $_Memory_NesBank
		// jmp $_destination
		.data8	10
		jsr	$=Interpret__Idle
		stz	$_Memory_NesBank
		.data8	0x4c, 0x00

Recompiler__Build_OpcodeType_Br_Idle_Infinite:
		// jsl $=Interpret__Idle
		// bra -
b_back:
		jsr $=Interpret__Idle
		bra $-b_back
		.data8	0x00

Recompiler__Build_OpcodeType_Br_Idle_BitShift:
		// b.. $+12
		// beq +
		//  jsl $=Interpret__Idle
		//  stz $_Memory_NesBank
		// jmp $_destination
		.data8	12
		beq	$+b_1
			jsr	$=Interpret__Idle
			stz	$_Memory_NesBank
b_1:
		.data8	0x4c, 0x00


Recompiler__Build_OpcodeType_Jmp:
	// Write the original jump
	lsr	a
	sta	[$.writeAddr]
	ldy	#0x0001
	lda	[$.readAddr],y
	sta	[$.writeAddr],y

	// Is destination in WRAM?
	cmp	$_Recompile_PrgRamTopRange
	bcs	$+b_1
		// Is it in SRAM?
		and	#0xe000
		beq	$+b_2
		bmi	$+b_2
			lda	#_Inline_StoreDirectKnown_60/0x10000
			ldx	#_Inline_StoreDirectKnown_60
			jsr	$_Recompiler__Build_Inline2
b_2:

		// Call interpreter like this:
		// pea $_originalValue
		// jmp $=Interpreter__Execute
		lda	#0x5cf4
		ldy	#2
		sta	[$.writeAddr]
		sta	[$.writeAddr],y
		dey
		lda	[$.readAddr],y
		sta	[$.writeAddr],y
		lda	#_Interpreter__Execute
		ldy	#4
		sta	[$.writeAddr],y
		lda	#_Interpreter__Execute/0x100
		iny
		sta	[$.writeAddr],y

		// Add to write address
		lda	#7
		clc
		adc	$.writeAddr
		sta	$.writeAddr
		rts
b_1:

	// Is destination address the same as read address?
	cmp	$.readAddr
	bne	$+Recompiler__Build_OpcodeType_Jmp_SkipInfinite
		lda	$=RomInfo_NmiMode
		and	#_RomInfo_NmiMode_DetectIdling
		bne	$+Recompiler__Build_OpcodeType_Jmp_Infinite
		// Reload A
		lda	[$.readAddr],y
Recompiler__Build_OpcodeType_Jmp_SkipInfinite:

	// Is this jump pointing towards another bank?
	//lda	[$.readAddr],y
	eor	$.readAddr
	and	$=RomInfo_PrgBankingMask
	beq	$+b_1
		// Is target range considered static?
		lda	[$.readAddr],y
		jsr	$_Recompiler__Build_IsRangeStatic
		bcc	$+Recompiler__Build_OpcodeType_Jmp_OutOfRange
b_1:

	// Is destination out of range?
	lda	$=RomInfo_JmpRange
	bmi	$+Recompiler__Build_OpcodeType_Jmp_NoRangeTest
		//ldy	#0x0001
		sec
		sbc	[$.readAddr],y
		adc	$.readAddr
		cmp	$=RomInfo_JmpRange_x2
		bcs	$+Recompiler__Build_OpcodeType_Jmp_OutOfRange
Recompiler__Build_OpcodeType_Jmp_NoRangeTest:

	// Record this address so we can fix it later
	lda	$.writeAddr
	inc	a
	sta	[$.Recompiler_BranchSrcList]
	ldx	#_Recompiler_BranchSrcList
	call	Array__Insert

	// Add to write address
	lda	#0x0003
	clc
	adc	$.writeAddr
	sta	$.writeAddr
	rts


Recompiler__Build_OpcodeType_Jmp_OutOfRange:
	// Do JSR+NOP+RTL combo
	jsr	$_Recompiler__Build_OpcodeType_Jsr
	lda	#0x6bea
	sta	[$.writeAddr]
	inc	$.writeAddr
	inc	$.writeAddr
	rts


Recompiler__Build_OpcodeType_Jmp_Infinite:
	// Write code
	ldx	#_Recompiler__Build_OpcodeType_Br_Idle_Infinite
	lda	#_Recompiler__Build_OpcodeType_Br_Idle/0x10000
	jmp	$_Recompiler__Build_Inline


Recompiler__Build_OpcodeType_JmpI:
	// Flag this function as having a return and indirect jump
	lda	#_Opcode_F_HasReturn|Opcode_F_IndirectJmp
	tsb	$.recompileFlags

	// Is destination in ROM or SRAM?
	ldy	#1
	lda	[$.readAddr],y
	cmp	#0x6000
	bcc	$+b_1
		// ROM and SRAM range
		pha
		xba
		and	#0x00e0
		tay
		// Is memory prefix known?
		ldx	$.memoryPrefix
		beq	$+b_2
			// Is it the same memory prefix?
			cpy	$.memoryPrefix
			bne	$+b_diff
				// Same
				lda	$1,s
				bra	$+b_InlineJmpI
b_diff:
				// Different
				ora	#0x0100
				tay
				and	#0x00ff
b_2:
		sta	$.memoryPrefix
		// Write prefix
		tyx
		lda	$=Inline_StoreDirect_LUT,x
		tax
		lda	#_Inline_StoreDirect_LUT/0x10000
		jsr	$_Recompiler__Build_Inline2

		lda	$1,s
		bra	$+b_InlineJmpI
b_1:

	// Is destination in WRAM?
	cmp	#0x2000
	bcs	$+b_1
		and	#0x07ff
		pha
b_InlineJmpI:
		// What kind of indirect JMP is this?
		ldy	#0
		// Is it in ZP?
		cmp	#0x0100
		bcc	$+b_2
			iny
			iny
			iny
			iny
b_2:
		// Is it page wrapping?
		ora	#0xff00
		inc	a
		bne	$+b_2
			iny
			iny
b_2:

		// Write inlined code
		phy
		ldx	$_Recompiler__Build_OpcodeType_JmpI_Table,y
		lda	#_JMPiU_Inline_ZpNoWrap/0x10000
		jsr	$_Recompiler__Build_InlineNoInc

		// Change some parameters
		plx
		pla
		jsr	($_Recompiler__Build_OpcodeType_JmpI_Switch,x)

		// Add to write address
		txa
		clc
		adc	$.writeAddr
		sta	$.writeAddr
		rts
b_1:

	// Write inlined error
	ldx	#_Inline__JmpIError
	lda	#_Inline__JmpIError/0x10000
	jsr	$_Recompiler__Build_InlineNoInc
	tyx

	// Write original address
	pla
	ldy	#1
	sta	[$.writeAddr],y

	// Add to write address
	txa
	clc
	adc	$.writeAddr
	sta	$.writeAddr
	rts

Recompiler__Build_OpcodeType_JmpI_Table:
	.data16	_JMPiU_Inline_ZpNoWrap, _JMPiU_Inline_ZpWrap
	.data16	_JMPiU_Inline_AbsNoWrap, _JMPiU_Inline_AbsWrap

	// Entry: A = Read address for indirect JMP, Y = Inline byte count
	// Return: X = Inline byte count
Recompiler__Build_OpcodeType_JmpI_Switch:
	.data16	_Recompiler__Build_OpcodeType_JmpI_ZpNoWrap, _Recompiler__Build_OpcodeType_JmpI_ZpWrap
	.data16	_Recompiler__Build_OpcodeType_JmpI_AbsNoWrap, _Recompiler__Build_OpcodeType_JmpI_AbsWrap

		.mx	0x00
Recompiler__Build_OpcodeType_JmpI_ZpNoWrap:
		tyx
		smx	#0x30
		ldy	#.JMPiU_Inline_ZpNoWrap_Load-JMPiU_Inline_ZpNoWrap+1
		sta	[$.writeAddr],y
		inc	a
		ldy	#.JMPiU_Inline_ZpNoWrap_LastLoad-JMPiU_Inline_ZpNoWrap+1
		sta	[$.writeAddr],y
		smx	#0x00
		rts

		.mx	0x00
Recompiler__Build_OpcodeType_JmpI_ZpWrap:
		tyx
		smx	#0x30
		ldy	#.JMPiU_Inline_ZpWrap_Load-JMPiU_Inline_ZpWrap+1
		sta	[$.writeAddr],y
		inc	a
		ldy	#.JMPiU_Inline_ZpWrap_LastLoad-JMPiU_Inline_ZpWrap+1
		sta	[$.writeAddr],y
		smx	#0x00
		rts

		.mx	0x00
Recompiler__Build_OpcodeType_JmpI_AbsNoWrap:
		tyx
		ldy	#_JMPiU_Inline_AbsNoWrap_Load-JMPiU_Inline_AbsNoWrap+1
		sta	[$.writeAddr],y
		inc	a
		ldy	#_JMPiU_Inline_AbsNoWrap_LastLoad-JMPiU_Inline_AbsNoWrap+1
		sta	[$.writeAddr],y
		rts

		.mx	0x00
Recompiler__Build_OpcodeType_JmpI_AbsWrap:
		tyx
		ldy	#_JMPiU_Inline_AbsWrap_FirstLoad-JMPiU_Inline_AbsWrap+1
		sta	[$.writeAddr],y
		and	#0xff00
		ldy	#_JMPiU_Inline_AbsWrap_SecondLoad-JMPiU_Inline_AbsWrap+1
		sta	[$.writeAddr],y
		ldy	#_JMPiU_Inline_AbsWrap_LastLoad-JMPiU_Inline_AbsWrap+1
		sta	[$.writeAddr],y
		rts

	.mx	0x00


Recompiler__Build_OpcodeType_Jsr:
	stz	$.memoryPrefix

	// Is destination in RAM?
	ldy	#1
	lda	[$.readAddr],y
	cmp	$_Recompile_PrgRamTopRange
	bcs	$+b_1
		// Is it in SRAM?
		and	#0xe000
		beq	$+b_2
		bmi	$+b_2
			lda	#_Inline_StoreDirectKnown_60/0x10000
			ldx	#_Inline_StoreDirectKnown_60
			jsr	$_Recompiler__Build_Inline2
b_2:

		// Call interpreter like this:
		// phk
		// per $0x0006
		// pea $_originalValue
		// jmp $=Interpreter__Execute
		lda	#0x624b
		sta	[$.writeAddr]
		lda	#0x0006
		ldy	#2
		sta	[$.writeAddr],y
		lda	#0x5cf4
		ldy	#6
		sta	[$.writeAddr],y
		ldy	#4
		sta	[$.writeAddr],y
		ldy	#1
		lda	[$.readAddr],y
		ldy	#5
		sta	[$.writeAddr],y
		lda	#_Interpreter__Execute
		ldy	#8
		sta	[$.writeAddr],y
		lda	#_Interpreter__Execute/0x100
		iny
		sta	[$.writeAddr],y

		// Add to write address
		lda	#11
		clc
		adc	$.writeAddr
		sta	$.writeAddr
		rts
b_1:

	clc

	// Are we compiling into ROM?
	lda	#_Recompiler_CompileType_MoveToRom
	and	$.compileType
	bne	$+Recompiler__Build_OpcodeType_Jsr_Static
		// Call interpreter like this:
		// pea $_originalReturn
		// pea $_originalValue
		// jsr $=Interpret
		//		0	1	2	3	4	5	6	7	8	9
		//		pea	#	#	pea	#	#	jsr	#	#	#
		lda	#_Interpret__BANK*0x100+0xf4
		ldy	#0x0003
		sta	[$.writeAddr]
		sta	[$.writeAddr],y
		ldy	#0x0008
		sta	[$.writeAddr],y
		lda	#_Interpret__Jsr
		dey
		sta	[$.writeAddr],y
		lda	#0x2222
		ldy	#0x0005
		sta	[$.writeAddr],y
		ldy	#0x0001
		lda	[$.readAddr],y
		ldy	#0x0004
		sta	[$.writeAddr],y

		// Write return address
		lda	$.readAddr
		inc	a
		inc	a
		ldy	#0x0001
		sta	[$.writeAddr],y

		// Add to write address
		lda	#0x000a
		adc	$.writeAddr
		sta	$.writeAddr
		rts

Recompiler__Build_OpcodeType_Jsr_Static:
	// Call interpreter like this:
	// jsr $=Interpret
	//		0	1	2	3
	//		jsr	#	#	0x7f
	lda	#0x7f22
	ldy	#2
	sta	[$.writeAddr]
	sta	[$.writeAddr],y

	// Write origin data
	lda	$=StaticRec_OriginCount
	tax
	dey
	lda	[$.readAddr],y
	sta	$=StaticRec_Origins+2,x
	lda	$.readAddr
	adc	#2
	sta	$=StaticRec_Origins+0,x

	// Write and increment origin count, assume carry clear from previous adc
	txa
	sta	[$.writeAddr],y
	adc	#4
	sta	$=StaticRec_OriginCount

	// Add to write address, assume carry clear from previous adc
	lda	#0x0004
	adc	$.writeAddr
	sta	$.writeAddr
	rts


Recompiler__Build_OpcodeType_Rts:
	// Flag this function as having a return
	lda	#_Opcode_F_HasReturn
	tsb	$.recompileFlags

	// Is stack consistent?
	lda	$.stackDepth
	dec	a
	and	$.stackDepth
	bne	$+b_3
		// Does the stack contain at least 2 bytes? Detecting using RTS as indirect jump
		lda	$.stackDepth
		cmp	#0x0400
		bcs	$+Recompiler__Build_OpcodeType_RtsI
b_3:

	// Is this function pulling return?
	lda	$.recompileFlags
	and	#_Opcode_F_PullReturn
	beq	$+Recompiler__Build_OpcodeType_RtlSnes_JumpIn

	// (Old condition, may have no effect?) is stack pointer below the original return address?
	lda	$.stackTrace
	bmi	$+Recompiler__Build_OpcodeType_RtlSnes_JumpIn

Recompiler__Build_OpcodeType_RtsNes:
Recompiler__Build_OpcodeType_RtsI:
	// Call interpreter like this:
	// jmp $=Interpret
	lda	#_JMPiU__FromStack/0x10000*0x100+0x5c
	ldy	#0x0002
	sta	[$.writeAddr]
	sta	[$.writeAddr],y
	lda	#_JMPiU__FromStack
	dey
	sta	[$.writeAddr],y
	
	// Add to write address
	lda	#0x0004
	adc	$.writeAddr
	sta	$.writeAddr
	rts


Recompiler__Build_OpcodeType_RtlSnes:
	// Flag this function as having a return
	lda	#_Opcode_F_HasReturn
	tsb	$.recompileFlags

	// Are we using native returns?
	lda	$=RomInfo_StackEmulation
	and	#_RomInfo_StackEmu_NativeReturn
	beq	$-Recompiler__Build_OpcodeType_RtsNes

Recompiler__Build_OpcodeType_RtlSnes_JumpIn:
	// Regular return
	lda	#0x006b
	sta	[$.writeAddr]
	inc	$.writeAddr
	rts


Recompiler__Build_OpcodeType_Rti:
	// Flag this function as having a return
	lda	#_Opcode_F_HasReturn
	tsb	$.recompileFlags

	// Are we using RTL or long RTI emulation?
	lda	$=RomInfo_NmiMode
	and	#_RomInfo_NmiMode_InfiniteJmp
	bne	$+Recompiler__Build_OpcodeType_Rti_Emulate
		// Write RTL
		lda	#0x6b28
		sta	[$.writeAddr]
		inc	$.writeAddr
		inc	$.writeAddr
		rts

Recompiler__Build_OpcodeType_Rti_Emulate:
	// Call interpreter like this:
	// jmp $=Interpret
	lda	#_Interpret__BANK*0x100+0x5c
	ldy	#0x0002
	sta	[$.writeAddr]
	sta	[$.writeAddr],y
	lda	#_Interpret__Rti
	dey
	sta	[$.writeAddr],y
	
	// Add to write address
	lda	#0x0004
	adc	$.writeAddr
	sta	$.writeAddr
	rts


Recompiler__Build_OpcodeType_Jsl:
	// Repurposed illegal opcode 0x22, giving access to any code on SNES side
	ldy	#2
	lda	[$.readAddr]
	sta	[$.writeAddr]
	lda	[$.readAddr],y
	sta	[$.writeAddr],y

	// Add to write address
	lda	#0x0004
	adc	$.writeAddr
	sta	$.writeAddr
	rts


Recompiler__Build_OpcodeType_Txs:
	ldx	#_Inline__Txs
	lda	#_Inline__Txs/0x10000
	jmp	$_Recompiler__Build_Inline


Recompiler__Build_OpcodeType_Pha:
	asl	$.stackDepth
	inc	$.stackTrace
	jmp	$_Recompiler__Build_OpcodeType_Impl

	// Call interpreter like this:
	// jsr $=Interpret
	//lda	#_Interpret__BANK*0x100+0x22
	//ldy	#0x0002
	//sta	[$.writeAddr]
	//sta	[$.writeAddr],y
	//lda	#_Interpret__Pha
	//dey
	//sta	[$.writeAddr],y
	
	// Add to write address
	//lda	#0x0004
	//adc	$.writeAddr
	//sta	$.writeAddr
	//rts


Recompiler__Build_OpcodeType_Pla:
	// Write opcode as is
	lda	#0x6868
	sta	[$.writeAddr]

	// Are we at function's entry point? (TODO: Replace this)
//	ldy	$.readAddr
//	cpy	$.romAddr
//	bne	$+b_1
//		// Is this a double PLA?
//		cmp	[$.readAddr]
//		bne	$+b_1
//			// Function starts with double PLA, add another one
//			inc	$.writeAddr
//			inc	$.writeAddr
//
//			// Adjust stack trace
//			dec	$.stackTrace
//			rts
//b_1:

	// Do we skip first condition?
	lda	$=RomInfo_StackEmulation
	and	#_RomInfo_StackEmu_LazyDoubleReturn
	bne	$+b_in
	// Is stack empty?
	lda	$.stackTrace
	bne	$+b_1
b_in:
		// How many PLA do we have in a row?
		ldy	#0x0000
		lda	#0x6868
		cmp	[$.readAddr],y
		bne	$+b_1
b_loop:
			iny
			cmp	[$.readAddr],y
			beq	$-b_loop

		// Z flag boolean for whether we write RTL at the end, zero = write RTL
		.local	_writeRtl
		lda	#0x6068
		eor	[$.readAddr],y
		sta	$.writeRtl

		// Adjust Y because we compared 16-bit at a time
		iny

		// Multiply this number by 1.5
		sty	$.DP_Temp
		tya
		lsr	a
		clc
		adc	$.DP_Temp
		tax

		// Round up to a multiple of 2
		inc	a
		and	#0xfffe
		tay

		// Write PLAs
		lda	#0x6868
b_loop:
			sta	[$.writeAddr],y
			dey
			dey
			bpl	$-b_loop

		// Adjust stack trace (breaks logic?)
		//txa
		//eor	#0xffff
		//sec
		//adc	$.stackTrace
		//sta	$.stackTrace

		// Remove pull return flag (TODO: Test this with Donkey Kong)
		//lda	#_Opcode_F_PullReturn
		//trb	$.recompileFlags

		// Add to read address
		lda	$.DP_Temp
		dec	a
		clc
		adc	$.readAddr
		sta	$.readAddr

		// Add to write address, decrement by 1 if "pull return" flag is set
		lda	#_Opcode_F_PullReturn
		and	$.recompileFlags
		beq	$+b_2
			dex
b_2:
		txa
		clc
		adc	$.writeAddr
		sta	$.writeAddr

		// Write RTL?
		lda	$.writeRtl
		bne	$+b_3
			lda	#0x6b6b
			sta	[$.writeAddr]
			inc	$.writeAddr
b_3:

		.unlocal	_writeRtl
		rts
b_1:

	// Adjust stack trace
	dec	$.stackTrace
	lsr	$.stackDepth

.false
{
	// Is this function pulling return?
	lda	$.recompileFlags
	and	#_Opcode_F_PullReturn
	beq	$+Recompiler__Build_OpcodeType_Pla_SkipPullReturn
		// Is this a sequence for PLA, PLA, RTS?
		lda	#0x6068
		ldy	#1
		cmp	[$.readAddr],y
		bne	$+Recompiler__Build_OpcodeType_Pla_SkipPullReturn
			// Write work around for this sequence
			lda	#0x6b68
			sta	[$.writeAddr]
			inc	$.writeAddr
			inc	$.writeAddr
			inc	$.readAddr
			rts
Recompiler__Build_OpcodeType_Pla_SkipPullReturn:
}

	inc	$.writeAddr
	rts


Recompiler__Build_OpcodeType_Cop:
	// Read first 2 bytes, swap them and multiply by 2. Expected result for high byte is 0x04 or 0x05
	lda	[$.readAddr]
	xba
	asl	a
	tax
	// Read COP function pointer
	lda	$=Cop__Table-0x400,x
	// Write core call
	ldy	#_Cop__Table/0x10000
	sty	$.DP_ZeroBank
	jmp	$_Recompiler__Build_CoreCall


Recompiler__Build_OpcodeType_Brk:
Recompiler__Build_OpcodeType_None:
	ldx	#_Inline__UnsupportedOpcode
	lda	#_Inline__UnsupportedOpcode/0x10000
	jsr	$_Recompiler__Build_InlineNoInc
	tyx

	// Write original PC
	lda	$.readAddr
	ldy	#_Inline__UnsupportedOpcode_PC-Inline__UnsupportedOpcode+1
	sta	[$.writeAddr],y

	// 8-bit A
	tya
	smx	#0x20

	// Write original bank
	lda	$.readAddr+1
	and	#0xe0
	tay
	lda	$_Program_BankNum,y
	ldy	#_Inline__UnsupportedOpcode_OpcodeAndBank-Inline__UnsupportedOpcode+2
	sta	[$.writeAddr],y
	// Write opcode
	lda	$.thisOpcodeX2+1
	lsr	a
	lda	$.thisOpcodeX2
	ror	a
	dey
	sta	[$.writeAddr],y

	// 16-bit A
	rmx	#0x01

	// Add to write address
	txa
	adc	$.writeAddr
	sta	$.writeAddr
	rts


Recompiler__Build_OpcodeType_IllyNop:
	// Are we allowed to recompile it?
	lda	$=RomInfo_CpuSettings
	and	#_RomInfo_Cpu_IllegalNop
	jeq	$_Recompiler__Build_OpcodeType_None
		// Yes, do nothing
	rts


Recompiler__Build_Inline:
	// Entry: X = source address, A = source bank
	.local	=inline

	// Change mode
	sep	#0x20
	.mx	0x20

	stx	$.inline
	sta	$.inline+2

	ldy	#0x0000
	lda	[$.inline],y
	beq	$+Recompiler__Build_Inline_LoopEnd
Recompiler__Build_Inline_Loop:
		sta	[$.writeAddr],y
		iny
Recompiler__Build_Inline_LoopStart:
		lda	[$.inline],y
		bne	$-Recompiler__Build_Inline_Loop
Recompiler__Build_Inline_LoopEnd:

	// Change mode back
	rep	#0x31
	.mx	0x00

	// Add to write address
	tya
	adc	$.writeAddr
	sta	$.writeAddr

	rts
	.unlocal	=inline


Recompiler__Build_InlineNoInc:
	// Entry: X = source address, A = source bank
	// Return: Y = number of bytes added
	.local	=inline

	// Change mode
	sep	#0x20
	.mx	0x20

	stx	$.inline
	sta	$.inline+2

	ldy	#0x0000
	lda	[$.inline],y
	beq	$+b_LoopEnd
b_Loop:
		sta	[$.writeAddr],y
		iny
b_LoopStart:
		lda	[$.inline],y
		bne	$-b_Loop
b_LoopEnd:

	// Change mode back
	rep	#0x31
	.mx	0x00

	rts
	.unlocal	=inline


Recompiler__Build_Inline2:
	// Entry: X = source address, A = source bank, Y = Replacement for 0xff
	.local	=inline, .inlineValue

	// Change mode
	sep	#0x20
	.mx	0x20

	stx	$.inline
	sta	$.inline+2
	sty	$.inlineValue

	ldy	#0x0000
	lda	[$.inline],y
	beq	$+Recompiler__Build_Inline2_LoopEnd
Recompiler__Build_Inline2_Loop:
		cmp	#0xff
		bne	$+Recompiler__Build_Inline2_Loop_SkipFF
			lda	$.inlineValue
Recompiler__Build_Inline2_Loop_SkipFF:
		sta	[$.writeAddr],y
		iny
Recompiler__Build_Inline2_LoopStart:
		lda	[$.inline],y
		bne	$-Recompiler__Build_Inline2_Loop
Recompiler__Build_Inline2_LoopEnd:

	// Change mode back
	rep	#0x31
	.mx	0x00

	// Add to write address
	tya
	adc	$.writeAddr
	sta	$.writeAddr

	rts
	.unlocal	=inline, .inlineValue


Recompiler__Build_Inline2NoInc:
	// Entry: X = source address, A = source bank, Y = Replacement for 0xff
	// Return: Y = number of bytes added
	.local	=inline, .inlineValue

	// Change mode
	sep	#0x20
	.mx	0x20

	stx	$.inline
	sta	$.inline+2
	sty	$.inlineValue

	ldy	#0x0000
	lda	[$.inline],y
	beq	$+b_LoopEnd
b_loop:
		cmp	#0xff
		bne	$+b_1
			lda	$.inlineValue
b_1:
		sta	[$.writeAddr],y
		iny
b_LoopStart:
		lda	[$.inline],y
		bne	$-b_loop
b_LoopEnd:

	// Change mode back
	rep	#0x31
	.mx	0x00

	rts
	.unlocal	=inline, .inlineValue


Recompiler__Build_IsRangeStatic:
	// Entry: A = Destination address
	// Return: Carry = true when static, X & Y = Unchanged

	.local	_temp
	sta	$.temp

	// Is read address in ROM range?
	bit	$.readAddr
	bmi	$+b_1
		// Invalid source range
		clc
		rts
b_1:

	lda	$=RomInfo_StaticRanges

	// Test bit 15 (must be set)
	asl	$.temp
	bcs	$+b_else
		// Invalid destination range
		clc
		rts
b_else:
		lsr	a
		lsr	a
		lsr	a
		lsr	a
b_1:

	// Test bit 14
	asl	$.temp
	bcc	$+b_1
		lsr	a
		lsr	a
b_1:

	// Test bit 13
	asl	$.temp
	bcc	$+b_1
		lsr	a
b_1:

	// Return whether target range is considered static
	lsr	a
	rts


	// Entry: A = Call address, ZeroBank = Bank for call address
Recompiler__Build_CoreCall:
	tay

	// Do we have instructions for calling this function?
	lda	[$.DP_Zero],y
	and	#0x00ff
	beq	$+b_else
		// No, call this function directly
		tyx
		lda	$.DP_ZeroBank-1
		ora	#0x0022
		ldy	#0x0002
		sta	[$.writeAddr]
		sta	[$.writeAddr],y
		txa
		dey
		sta	[$.writeAddr],y

		// Add to write address
		lda	#0x0004
		clc
		adc	$.writeAddr
		sta	$.writeAddr
		rts
b_else:
		.local	_pushFlags, _freeRegs, =src
		stz	$.pushFlags

		// Default free registers (TODO: Predictions)
		stz	$.freeRegs

		// Prepare proper source pointer
		lda	$.DP_Zero+1
		sta	$.src+1
		iny
		sty	$.src

Recompiler__Build_CoreCall_Switch_Break:
			// Next instruction
			lda	[$.src]
			inc	$.src
			and	#0x00ff
			asl	a
			tax
			jmp	($_Recompiler__Build_CoreCall_Switch,x)


Recompiler__Build_CoreCall_Switch:
	switch	0x100, Recompiler__Build_CoreCall_Switch_Default, Recompiler__Build_CoreCall_Switch_Break
Recompiler__Build_CoreCall_Switch_Default:
		unlock
		trap
		Exception	"Inline failed{}{}{}Undefined inline instruction for a core call."

	case	CoreCall_End
		rts

	case	CoreCall_Call
		// Write JSL to destination
		lda	$.DP_ZeroBank-1
		ora	#0x0022
		ldy	#0x0002
		sta	[$.writeAddr]
		sta	[$.writeAddr],y
		lda	[$.src]
		inc	$.src
		inc	$.src
		dey
		sta	[$.writeAddr],y

		// Add to write address
		lda	#0x0004
		clc
		adc	$.writeAddr
		sta	$.writeAddr
		break

	case	CoreCall_Lock
		// Lock thread regardless of PHP/PLP
		lda	#_CoreCallFlag_Lock
		tsb	$.pushFlags
		break

	case	CoreCall_UseA8
		lda	$.freeRegs
		and	#0x0100
		bne	$+b_1
			lda	#_CoreCallFlag_Xba
			tsb	$.pushFlags
			lda	#_CoreCallFlag_PushA
			trb	$.pushFlags
b_1:
		break

	case	CoreCall_UseA16
		lda	$.freeRegs
		and	#0x0100
		bne	$+b_1
			lda	#_CoreCallFlag_PushA
			tsb	$.pushFlags
			lda	#_CoreCallFlag_Xba
			trb	$.pushFlags
b_1:
		break

	case	CoreCall_UseX
		lda	$.freeRegs
		and	#0x0200
		bne	$+b_1
			lda	#_CoreCallFlag_PushX
			tsb	$.pushFlags
b_1:
		break

	case	CoreCall_UseY
		lda	$.freeRegs
		and	#0x0400
		bne	$+b_1
			lda	#_CoreCallFlag_PushY
			tsb	$.pushFlags
b_1:
		break

	case	CoreCall_UseN
		lda	$.freeRegs
		and	#0x0080
		bne	$+b_1
			lda	#_CoreCallFlag_PushP
			tsb	$.pushFlags
b_1:
		break

	case	CoreCall_UseV
		lda	$.freeRegs
		and	#0x0040
		bne	$+b_1
			lda	#_CoreCallFlag_PushP
			tsb	$.pushFlags
b_1:
		break

	case	CoreCall_UseZ
		lda	$.freeRegs
		and	#0x0002
		bne	$+b_1
			lda	#_CoreCallFlag_PushP
			tsb	$.pushFlags
b_1:
		break

	case	CoreCall_UseC
		lda	$.freeRegs
		and	#0x0002
		bne	$+b_1
			lda	#_CoreCallFlag_PushP
			tsb	$.pushFlags
b_1:
		break

	case	CoreCall_Push
		.macro	Recompiler__Build_CoreCall_PushFlag		flag, opcode
			lda	#_{0}
			and	$.pushFlags
			beq	$+b_1__
				lda	#0x00{1}
				sta	[$.writeAddr]
				inc	$.writeAddr
b_1__:
		.endm
		Recompiler__Build_CoreCall_PushFlag		CoreCallFlag_Lock,  78		// Sei
		Recompiler__Build_CoreCall_PushFlag		CoreCallFlag_PushP, 08		// Php
		Recompiler__Build_CoreCall_PushFlag		CoreCallFlag_Xba,   EB		// Xba
		Recompiler__Build_CoreCall_PushFlag		CoreCallFlag_PushA, 48		// Pha
		Recompiler__Build_CoreCall_PushFlag		CoreCallFlag_PushX, DA		// Phx
		Recompiler__Build_CoreCall_PushFlag		CoreCallFlag_PushY, 5A		// Phy
		break

	case	CoreCall_Pull
		Recompiler__Build_CoreCall_PushFlag		CoreCallFlag_PushY, 7A		// Ply
		Recompiler__Build_CoreCall_PushFlag		CoreCallFlag_PushX, FA		// Plx
		Recompiler__Build_CoreCall_PushFlag		CoreCallFlag_PushA, 68		// Pla
		Recompiler__Build_CoreCall_PushFlag		CoreCallFlag_Xba,   EB		// Xba
		Recompiler__Build_CoreCall_PushFlag		CoreCallFlag_PushP, 28		// Plp
		Recompiler__Build_CoreCall_PushFlag		CoreCallFlag_Lock,  58		// Cli
		break

		.macro	Recompiler__Build_CoreCall_IfGoto
			lda	${0}
			and	#{1}
			b{2}	$-b_branch
			inc	$.src
			break
		.endm

b_branch:
		lda	[$.src]
		and	#0x00ff
		clc
		adc	#0x7f80
		eor	#0x7f80
		adc	$.src
		inc	a
		sta	$.src
		break

	case	CoreCall_IfFreeA
		Recompiler__Build_CoreCall_IfGoto	.freeRegs, 0x0100, ne

	case	CoreCall_IfNotFreeA
		Recompiler__Build_CoreCall_IfGoto	.freeRegs, 0x0100, eq

	case	CoreCall_IfFreeX
		Recompiler__Build_CoreCall_IfGoto	.freeRegs, 0x0200, ne

	case	CoreCall_IfNotFreeX
		Recompiler__Build_CoreCall_IfGoto	.freeRegs, 0x0200, eq

	case	CoreCall_IfFreeY
		Recompiler__Build_CoreCall_IfGoto	.freeRegs, 0x0400, ne

	case	CoreCall_IfNotFreeY
		Recompiler__Build_CoreCall_IfGoto	.freeRegs, 0x0400, eq

	case	CoreCall_IfJit
		Recompiler__Build_CoreCall_IfGoto	=StaticRec_Active, 0x0001, ne

	case	CoreCall_IfAot
		Recompiler__Build_CoreCall_IfGoto	=StaticRec_Active, 0x0001, eq

	case	CoreCall_Jump
		lda	[$.src]
		sta	$.src
		break

	case	CoreCall_Copy		// TODO: Test it
		// Prepare data source pointer
		.local	=dataSrc
		lda	$.src+1
		sta	$.dataSrc+1
		lda	[$.src]
		inc	$.src
		inc	$.src
		sta	$.dataSrc

		// Y = number of bytes to copy
		lda	[$.src]
		inc	$.src
		inc	$.src
		sec
		sbc	$.dataSrc
		tax				// Keep correct byte count before rounding down
		dec	a
		and	#0xfffe
		tay
b_loop:
			lda	[$.dataSrc],y
			sta	[$.writeAddr],y
			dey
			dey
			bpl	$-b_loop

		// Add to write address
		txa
		clc
		adc	$.writeAddr
		sta	$.writeAddr

		break
		.unlocal	=dataSrc

	case	CoreCall_CopyUpTo
		lda	[$.src]
		inc	$.src
		and	#0x00ff
		tax				// Keep number of bytes copied
		dec	a
		and	#0xfffe
		tay				// Y = number of bytes to copy but we can go slightly over
		bmi	$+b_exit
b_loop:
			lda	[$.src],y
			sta	[$.writeAddr],y
			dey
			dey
			bpl	$-b_loop
b_exit:

		// Add to write address
		txa
		clc
		adc	$.writeAddr
		sta	$.writeAddr

		// Go to next instruction
		txa
		clc
		adc	$.src
		sta	$.src

		break

	case	CoreCall_Remove		// TODO: Test it
		// Remove some written bytes
		lda	$.writeAddr
		sec
		sbc	[$.src]
		inc	$.src
		inc	$.src
		sta	$.writeAddr
		break

	.unlocal	_pushFlags, _freeRegs, =src

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Recompiler__GetIOAccess
	// Entry: X = Original address, Y = Access type "iIOPort" (found in Macros.asm)
	// Return: A = Call address, ZeroBank = Bank for call address
Recompiler__GetIOAccess:
	// Load default bank address
	lda	#_IO__BANK
	sta	$.DP_ZeroBank

	// Is it 0x2000?
	cpx	#0x2000
	bne	$+Recompiler__GetIOAccess_Skip2000
		ldx	#_Recompiler__GetIOAccess_2000
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip2000:

	// Is it 0x2001?
	cpx	#0x2001
	bne	$+Recompiler__GetIOAccess_Skip2001
		ldx	#_Recompiler__GetIOAccess_2001
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip2001:

	// Is it 0x2002?
	cpx	#0x2002
	bne	$+Recompiler__GetIOAccess_Skip2002
		ldx	#_Recompiler__GetIOAccess_2002
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip2002:

	// Is it 0x2003?
	cpx	#0x2003
	bne	$+Recompiler__GetIOAccess_Skip2003
		ldx	#_Recompiler__GetIOAccess_2003
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip2003:

	// Is it 0x2004?
	cpx	#0x2004
	bne	$+Recompiler__GetIOAccess_Skip2004
		ldx	#_Recompiler__GetIOAccess_2004
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip2004:

	// Is it 0x2005?
	cpx	#0x2005
	bne	$+Recompiler__GetIOAccess_Skip2005
		ldx	#_Recompiler__GetIOAccess_2005
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip2005:

	// Is it 0x2006?
	cpx	#0x2006
	bne	$+Recompiler__GetIOAccess_Skip2006
		ldx	#_Recompiler__GetIOAccess_2006
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip2006:

	// Is it 0x2007?
	cpx	#0x2007
	bne	$+Recompiler__GetIOAccess_Skip2007
		ldx	#_Recompiler__GetIOAccess_2007
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip2007:

	// Is it 0x4000?
	cpx	#0x4000
	bne	$+Recompiler__GetIOAccess_Skip4000
		ldx	#_Recompiler__GetIOAccess_4000
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4000:

	// Is it 0x4001?
	cpx	#0x4001
	bne	$+Recompiler__GetIOAccess_Skip4001
		ldx	#_Recompiler__GetIOAccess_4001
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4001:

	// Is it 0x4002?
	cpx	#0x4002
	bne	$+Recompiler__GetIOAccess_Skip4002
		ldx	#_Recompiler__GetIOAccess_4002
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4002:

	// Is it 0x4003?
	cpx	#0x4003
	bne	$+Recompiler__GetIOAccess_Skip4003
		ldx	#_Recompiler__GetIOAccess_4003
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4003:

	// Is it 0x4004?
	cpx	#0x4004
	bne	$+Recompiler__GetIOAccess_Skip4004
		ldx	#_Recompiler__GetIOAccess_4004
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4004:

	// Is it 0x4005?
	cpx	#0x4005
	bne	$+Recompiler__GetIOAccess_Skip4005
		ldx	#_Recompiler__GetIOAccess_4005
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4005:

	// Is it 0x4006?
	cpx	#0x4006
	bne	$+Recompiler__GetIOAccess_Skip4006
		ldx	#_Recompiler__GetIOAccess_4006
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4006:

	// Is it 0x4007?
	cpx	#0x4007
	bne	$+Recompiler__GetIOAccess_Skip4007
		ldx	#_Recompiler__GetIOAccess_4007
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4007:

	// Is it 0x4008?
	cpx	#0x4008
	bne	$+Recompiler__GetIOAccess_Skip4008
		ldx	#_Recompiler__GetIOAccess_4008
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4008:

	// Is it 0x4009?
	cpx	#0x4009
	bne	$+Recompiler__GetIOAccess_Skip4009
		ldx	#_Recompiler__GetIOAccess_4009
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4009:

	// Is it 0x400a?
	cpx	#0x400a
	bne	$+Recompiler__GetIOAccess_Skip400a
		ldx	#_Recompiler__GetIOAccess_400a
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip400a:

	// Is it 0x400b?
	cpx	#0x400b
	bne	$+Recompiler__GetIOAccess_Skip400b
		ldx	#_Recompiler__GetIOAccess_400b
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip400b:

	// Is it 0x400c?
	cpx	#0x400c
	bne	$+Recompiler__GetIOAccess_Skip400c
		ldx	#_Recompiler__GetIOAccess_400c
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip400c:

	// Is it 0x400d?
	cpx	#0x400d
	bne	$+Recompiler__GetIOAccess_Skip400d
		ldx	#_Recompiler__GetIOAccess_400d
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip400d:

	// Is it 0x400e?
	cpx	#0x400e
	bne	$+Recompiler__GetIOAccess_Skip400e
		ldx	#_Recompiler__GetIOAccess_400e
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip400e:

	// Is it 0x400f?
	cpx	#0x400f
	bne	$+Recompiler__GetIOAccess_Skip400f
		ldx	#_Recompiler__GetIOAccess_400f
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip400f:

	// Is it 0x4010?
	cpx	#0x4010
	bne	$+Recompiler__GetIOAccess_Skip4010
		ldx	#_Recompiler__GetIOAccess_4010
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4010:

	// Is it 0x4011?
	cpx	#0x4011
	bne	$+Recompiler__GetIOAccess_Skip4011
		ldx	#_Recompiler__GetIOAccess_4011
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4011:

	// Is it 0x4012?
	cpx	#0x4012
	bne	$+Recompiler__GetIOAccess_Skip4012
		ldx	#_Recompiler__GetIOAccess_4012
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4012:

	// Is it 0x4013?
	cpx	#0x4013
	bne	$+Recompiler__GetIOAccess_Skip4013
		ldx	#_Recompiler__GetIOAccess_4013
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4013:

	// Is it 0x4014?
	cpx	#0x4014
	bne	$+Recompiler__GetIOAccess_Skip4014
		ldx	#_Recompiler__GetIOAccess_4014
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4014:

	// Is it 0x4015?
	cpx	#0x4015
	bne	$+Recompiler__GetIOAccess_Skip4015
		ldx	#_Recompiler__GetIOAccess_4015
		jmp	$_Recompiler__GetIOAccess_Return
Recompiler__GetIOAccess_Skip4015:

	// Do we have a mapper?
	txa
	ldx	$_Mapper_x2
	jmp	($_MapperTable,x)

	// Return default value
Recompiler__GetIOAccess_DefaultMapper:
Recompiler__GetIOAccess_Default:
	// Load default bank address
	lda	#_IO__Error/0x10000
	sta	$.DP_ZeroBank
	lda	#_IO__Error
	return

Recompiler__GetIOAccess_Return:
	.local	=temp
	lda	#_Recompiler__GetIOAccess_Return/0x100
	sta	$.temp+1
	stx	$.temp
	lda	[$.temp],y
	return

Recompiler__GetIOAccess_ReturnMapper:
	stx	$.DP_Zero
	lda	[$.DP_Zero],y
	stz	$.DP_Zero
	return

Recompiler__GetIOAccess_2000:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r2000_a
		caseat	iIOPort_ldai	IO__r2000_a_i
		caseat	iIOPort_sta		IO__w2000_a
		caseat	iIOPort_stx		IO__w2000_x
		caseat	iIOPort_sty		IO__w2000_y
		caseat	iIOPort_stai	IO__w2000_a_i
Recompiler__GetIOAccess_2001:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r2001_a
		caseat	iIOPort_ldai	IO__r2001_a_i
		caseat	iIOPort_sta		IO__w2001_a
		caseat	iIOPort_stx		IO__w2001_x
		caseat	iIOPort_sty		IO__w2001_y
		caseat	iIOPort_stai	IO__w2001_a_i
Recompiler__GetIOAccess_2002:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r2002_a
		caseat	iIOPort_ldai	IO__r2002_a_i
		caseat	iIOPort_sta		IO__w2002_a
		caseat	iIOPort_stx		IO__w2002_x
		caseat	iIOPort_sty		IO__w2002_y
		caseat	iIOPort_stai	IO__w2002_a_i
Recompiler__GetIOAccess_2003:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r2003_a
		caseat	iIOPort_ldai	IO__r2003_a_i
		caseat	iIOPort_sta		IO__w2003_a
		caseat	iIOPort_stx		IO__w2003_x
		caseat	iIOPort_sty		IO__w2003_y
		caseat	iIOPort_stai	IO__w2003_a_i
Recompiler__GetIOAccess_2004:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r2004_a
		caseat	iIOPort_ldai	IO__r2004_a_i
		caseat	iIOPort_sta		IO__w2004_a
		caseat	iIOPort_stx		IO__w2004_x
		caseat	iIOPort_sty		IO__w2004_y
		caseat	iIOPort_stai	IO__w2004_a_i
Recompiler__GetIOAccess_2005:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r2005_a
		caseat	iIOPort_ldai	IO__r2005_a_i
		caseat	iIOPort_sta		IO__w2005_a
		caseat	iIOPort_stx		IO__w2005_x
		caseat	iIOPort_sty		IO__w2005_y
		caseat	iIOPort_stai	IO__w2005_a_i
Recompiler__GetIOAccess_2006:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r2006_a
		caseat	iIOPort_ldai	IO__r2006_a_i
		caseat	iIOPort_sta		IO__w2006_a
		caseat	iIOPort_stx		IO__w2006_x
		caseat	iIOPort_sty		IO__w2006_y
		caseat	iIOPort_stai	IO__w2006_a_i
Recompiler__GetIOAccess_2007:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r2007_a
		caseat	iIOPort_ldai	IO__r2007_a_i
		caseat	iIOPort_sta		IO__w2007_a
		caseat	iIOPort_stx		IO__w2007_x
		caseat	iIOPort_sty		IO__w2007_y
		caseat	iIOPort_stai	IO__w2007_a_i
Recompiler__GetIOAccess_4000:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4000_a
		caseat	iIOPort_ldai	IO__r4000_a_i
		caseat	iIOPort_sta		IO__w4000_a
		caseat	iIOPort_stx		IO__w4000_x
		caseat	iIOPort_sty		IO__w4000_y
		caseat	iIOPort_stax	IO__w4000_a_x
		caseat	iIOPort_stay	IO__w4000_a_y
		caseat	iIOPort_stai	IO__w4000_a_i
Recompiler__GetIOAccess_4001:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4001_a
		caseat	iIOPort_ldai	IO__r4001_a_i
		caseat	iIOPort_sta		IO__w4001_a
		caseat	iIOPort_stx		IO__w4001_x
		caseat	iIOPort_sty		IO__w4001_y
		caseat	iIOPort_stax	IO__w4001_a_x
		caseat	iIOPort_stay	IO__w4001_a_y
		caseat	iIOPort_stai	IO__w4001_a_i
Recompiler__GetIOAccess_4002:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4002_a
		caseat	iIOPort_ldai	IO__r4002_a_i
		caseat	iIOPort_sta		IO__w4002_a
		caseat	iIOPort_stx		IO__w4002_x
		caseat	iIOPort_sty		IO__w4002_y
		caseat	iIOPort_stax	IO__w4002_a_x
		caseat	iIOPort_stay	IO__w4002_a_y
		caseat	iIOPort_stai	IO__w4002_a_i
Recompiler__GetIOAccess_4003:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4003_a
		caseat	iIOPort_ldai	IO__r4003_a_i
		caseat	iIOPort_sta		IO__w4003_a
		caseat	iIOPort_stx		IO__w4003_x
		caseat	iIOPort_sty		IO__w4003_y
		caseat	iIOPort_stax	IO__w4003_a_x
		caseat	iIOPort_stay	IO__w4003_a_y
		caseat	iIOPort_stai	IO__w4003_a_i
Recompiler__GetIOAccess_4004:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4004_a
		caseat	iIOPort_ldai	IO__r4004_a_i
		caseat	iIOPort_sta		IO__w4004_a
		caseat	iIOPort_stx		IO__w4004_x
		caseat	iIOPort_sty		IO__w4004_y
		caseat	iIOPort_stax	IO__w4004_a_x
		caseat	iIOPort_stay	IO__w4004_a_y
		caseat	iIOPort_stai	IO__w4004_a_i
Recompiler__GetIOAccess_4005:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4005_a
		caseat	iIOPort_ldai	IO__r4005_a_i
		caseat	iIOPort_sta		IO__w4005_a
		caseat	iIOPort_stx		IO__w4005_x
		caseat	iIOPort_sty		IO__w4005_y
		caseat	iIOPort_stax	IO__w4005_a_x
		caseat	iIOPort_stay	IO__w4005_a_y
		caseat	iIOPort_stai	IO__w4005_a_i
Recompiler__GetIOAccess_4006:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4006_a
		caseat	iIOPort_ldai	IO__r4006_a_i
		caseat	iIOPort_sta		IO__w4006_a
		caseat	iIOPort_stx		IO__w4006_x
		caseat	iIOPort_sty		IO__w4006_y
		caseat	iIOPort_stax	IO__w4006_a_x
		caseat	iIOPort_stay	IO__w4006_a_y
		caseat	iIOPort_stai	IO__w4006_a_i
Recompiler__GetIOAccess_4007:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4007_a
		caseat	iIOPort_ldai	IO__r4007_a_i
		caseat	iIOPort_sta		IO__w4007_a
		caseat	iIOPort_stx		IO__w4007_x
		caseat	iIOPort_sty		IO__w4007_y
		caseat	iIOPort_stax	IO__w4007_a_x
		caseat	iIOPort_stay	IO__w4007_a_y
		caseat	iIOPort_stai	IO__w4007_a_i
Recompiler__GetIOAccess_4008:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4008_a
		caseat	iIOPort_ldai	IO__r4008_a_i
		caseat	iIOPort_sta		IO__w4008_a
		caseat	iIOPort_stx		IO__w4008_x
		caseat	iIOPort_sty		IO__w4008_y
		caseat	iIOPort_stax	IO__w4008_a_x
		caseat	iIOPort_stay	IO__w4008_a_y
		caseat	iIOPort_stai	IO__w4008_a_i
Recompiler__GetIOAccess_4009:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4009_a
		caseat	iIOPort_ldai	IO__r4009_a_i
		caseat	iIOPort_sta		IO__w4009_a
		caseat	iIOPort_stx		IO__w4009_x
		caseat	iIOPort_sty		IO__w4009_y
		caseat	iIOPort_stax	IO__w4009_a_x
		caseat	iIOPort_stay	IO__w4009_a_y
		caseat	iIOPort_stai	IO__w4009_a_i
Recompiler__GetIOAccess_400a:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r400a_a
		caseat	iIOPort_ldai	IO__r400a_a_i
		caseat	iIOPort_sta		IO__w400a_a
		caseat	iIOPort_stx		IO__w400a_x
		caseat	iIOPort_sty		IO__w400a_y
		caseat	iIOPort_stax	IO__w400a_a_x
		caseat	iIOPort_stay	IO__w400a_a_y
		caseat	iIOPort_stai	IO__w400a_a_i
Recompiler__GetIOAccess_400b:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r400b_a
		caseat	iIOPort_ldai	IO__r400b_a_i
		caseat	iIOPort_sta		IO__w400b_a
		caseat	iIOPort_stx		IO__w400b_x
		caseat	iIOPort_sty		IO__w400b_y
		caseat	iIOPort_stax	IO__w400b_a_x
		caseat	iIOPort_stay	IO__w400b_a_y
		caseat	iIOPort_stai	IO__w400b_a_i
Recompiler__GetIOAccess_400c:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r400c_a
		caseat	iIOPort_ldai	IO__r400c_a_i
		caseat	iIOPort_sta		IO__w400c_a
		caseat	iIOPort_stx		IO__w400c_x
		caseat	iIOPort_sty		IO__w400c_y
		caseat	iIOPort_stax	IO__w400c_a_x
		caseat	iIOPort_stay	IO__w400c_a_y
		caseat	iIOPort_stai	IO__w400c_a_i
Recompiler__GetIOAccess_400d:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r400d_a
		caseat	iIOPort_ldai	IO__r400d_a_i
		caseat	iIOPort_sta		IO__w400d_a
		caseat	iIOPort_stx		IO__w400d_x
		caseat	iIOPort_sty		IO__w400d_y
		caseat	iIOPort_stax	IO__w400d_a_x
		caseat	iIOPort_stay	IO__w400d_a_y
		caseat	iIOPort_stai	IO__w400d_a_i
Recompiler__GetIOAccess_400e:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r400e_a
		caseat	iIOPort_ldai	IO__r400e_a_i
		caseat	iIOPort_sta		IO__w400e_a
		caseat	iIOPort_stx		IO__w400e_x
		caseat	iIOPort_sty		IO__w400e_y
		caseat	iIOPort_stax	IO__w400e_a_x
		caseat	iIOPort_stay	IO__w400e_a_y
		caseat	iIOPort_stai	IO__w400e_a_i
Recompiler__GetIOAccess_400f:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r400f_a
		caseat	iIOPort_ldai	IO__r400f_a_i
		caseat	iIOPort_sta		IO__w400f_a
		caseat	iIOPort_stx		IO__w400f_x
		caseat	iIOPort_sty		IO__w400f_y
		caseat	iIOPort_stax	IO__w400f_a_x
		caseat	iIOPort_stay	IO__w400f_a_y
		caseat	iIOPort_stai	IO__w400f_a_i
Recompiler__GetIOAccess_4010:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4010_a
		caseat	iIOPort_ldai	IO__r4010_a_i
		caseat	iIOPort_sta		IO__w4010_a
		caseat	iIOPort_stx		IO__w4010_x
		caseat	iIOPort_sty		IO__w4010_y
		caseat	iIOPort_stax	IO__w4010_a_x
		caseat	iIOPort_stay	IO__w4010_a_y
		caseat	iIOPort_stai	IO__w4010_a_i
Recompiler__GetIOAccess_4011:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4011_a
		caseat	iIOPort_ldai	IO__r4011_a_i
		caseat	iIOPort_sta		IO__w4011_a
		caseat	iIOPort_stx		IO__w4011_x
		caseat	iIOPort_sty		IO__w4011_y
		caseat	iIOPort_stax	IO__w4011_a_x
		caseat	iIOPort_stay	IO__w4011_a_y
		caseat	iIOPort_stai	IO__w4011_a_i
Recompiler__GetIOAccess_4012:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4012_a
		caseat	iIOPort_ldai	IO__r4012_a_i
		caseat	iIOPort_sta		IO__w4012_a
		caseat	iIOPort_stx		IO__w4012_x
		caseat	iIOPort_sty		IO__w4012_y
		caseat	iIOPort_stax	IO__w4012_a_x
		caseat	iIOPort_stay	IO__w4012_a_y
		caseat	iIOPort_stai	IO__w4012_a_i
Recompiler__GetIOAccess_4013:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4013_a
		caseat	iIOPort_ldai	IO__r4013_a_i
		caseat	iIOPort_sta		IO__w4013_a
		caseat	iIOPort_stx		IO__w4013_x
		caseat	iIOPort_sty		IO__w4013_y
		caseat	iIOPort_stax	IO__w4013_a_x
		caseat	iIOPort_stay	IO__w4013_a_y
		caseat	iIOPort_stai	IO__w4013_a_i
Recompiler__GetIOAccess_4014:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4014_a
		caseat	iIOPort_ldai	IO__r4014_a_i
		caseat	iIOPort_sta		IO__w4014_a
		caseat	iIOPort_stx		IO__w4014_x
		caseat	iIOPort_sty		IO__w4014_y
		caseat	iIOPort_stai	IO__w4014_a_i
Recompiler__GetIOAccess_4015:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4015_a
		caseat	iIOPort_ldai	IO__r4015_a_i
		caseat	iIOPort_sta		IO__w4015_a
		caseat	iIOPort_stx		IO__w4015_x
		caseat	iIOPort_sty		IO__w4015_y
		caseat	iIOPort_stai	IO__w4015_a_i
	// TODO: 4016 and 4017


	// ---------------------------------------------------------------------------

MapperTable:
	.data16	_Recompiler__GetIOAccess_DefaultMapper
	.fill	0x3fe, 0xff

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Recompiler__AddFunction		=originalFunction, =newFunction, _recompileFlags
	// Return: A = Index for Recompiler_FunctionList
Recompiler__AddFunction:
	// Add to list
	lda	$.originalFunction+0
	sta	[$.Recompiler_FunctionList]
	lda	$.originalFunction+2
	ldy	#0x0002
	sta	[$.Recompiler_FunctionList],y
	lda	$.originalFunction+4
	ldy	#0x0004
	sta	[$.Recompiler_FunctionList],y
	lda	$.recompileFlags
	ldy	#0x0006
	sta	[$.Recompiler_FunctionList],y

	ldx	#_Recompiler_FunctionList
	ldy	#1
	call	Array__FindLow

	// Was something found?
	tay
	inc	a
	beq	$+Recompiler__AddFunction_regularAdd

		.local	_temp
		sty	$.temp

		ldx	#_Recompiler_FunctionList
		call	Array__InsertAt

		// Are we in StaticRec mode?
		lda	$=StaticRec_Active
		bne	$+Recompiler__AddFunction_SkipQuickFunc
			// Add to feedback
			ldx	$.originalFunction
			ldy	$.originalFunction+2
			call	Feedback__Add

			lda	$.originalFunction
			call	Recompiler__AddQuickFunction
Recompiler__AddFunction_SkipQuickFunc:

		lda	$.temp
		.unlocal	_temp

		return

Recompiler__AddFunction_regularAdd:
	// Are we in StaticRec mode?
	lda	$=StaticRec_Active
	bne	$+Recompiler__AddFunction_SkipQuickFunc2
		// Increment element count
		ldx	#_Recompiler_FunctionList
		call	Array__Insert

		// Adjust quick function table
		lda	$.originalFunction
		call	Recompiler__AddQuickFunction

		// Add to feedback
		ldx	$.originalFunction
		ldy	$.originalFunction+2
		call	Feedback__Add
Recompiler__AddFunction_SkipQuickFunc2:

	// Return index for function list
	lda	$.Recompiler_FunctionList
	sec
	sbc	$.Recompiler_FunctionList+3
	sec
	sbc	$.Recompiler_FunctionList+9
	
	return
	
	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Recompiler__AddQuickFunction
	// Entry: A = Low bits of original function pointer
Recompiler__AddQuickFunction:
	// Only use lower bits
	and	#0x00ff
	tay
	asl	a
	tax

	// Add 8 to each pointers lower than this value, assume carry always clear during the loop
	clc
Recompiler__AddQuickFunction_loop:
		dey
		bmi	$+Recompiler__AddQuickFunction_loopEnd
		dex
		dex
		lda	$_QuickFunction,x
		adc	$.Recompiler_FunctionList+9
		sta	$_QuickFunction,x
		bra	$-Recompiler__AddQuickFunction_loop

Recompiler__AddQuickFunction_loopEnd:

	return
	
	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Recompiler__CallFunction		_originalFunction
	// Return: Y = index for known calls
Recompiler__CallFunction:
	.local	_originalFunction_b
	.local	_base, _add

	// Find this function's bank
	lda	$.originalFunction+1
	and	#0x00e0
	tax
	lda	$_Program_BankNum,x
	sta	$.originalFunction_b

	// Was this function recompiled statically?
	jsr	$_Recompiler__CallFunction_FindStatic
	bcc	$+Recompiler__CallFunction_SkipStatic
		// Return data found, assume carry set from bcc and sbc
		lda	$.Recompiler_FunctionList+0
		sbc	$.Recompiler_FunctionList+3
		adc	#2
		tay
		return
Recompiler__CallFunction_SkipStatic:

	// Keep base pointer
	lda	$.Recompiler_FunctionList+3
	sta	$.base
	
	// Increment base pointer
	lda	$.originalFunction
	and	#0x00ff
	asl	a
	tax
	lda	$_QuickFunction,x
	sta	$.add
	adc	$.base
	sta	$.Recompiler_FunctionList+3
	
	// Find this function
	lda	$.originalFunction+0
	sta	[$.Recompiler_FunctionList]
	lda	$.originalFunction_b
	ldy	#0x0002
	sta	[$.Recompiler_FunctionList],y

	ldx	#_Recompiler_FunctionList
	iny
	call	Array__Find

	// Restore base pointer
	ldx	$.base
	stx	$.Recompiler_FunctionList+3

	tay
	bpl	$+Recompiler__CallFunction_call
		// Not listed, create it
		.precall	Recompiler__Build		_romAddr, _compileType
		lda	$.originalFunction
		sta	$.Param_romAddr
		stz	$.Param_compileType
		phb
		call
		plb

		// Keep function index
		.local	_rtn
		clc
		adc	#3
		sta	$.rtn

		// Optimize
//		lda	$=RomInfo_Optimize
//		and	#_RomInfo_Optimize_MainThread
//		beq	$+b_1
//			.precall	Optimize__Simplify		=functionHeapStackPointer, _callIndex
//			stx	$.Param_functionHeapStackPointer
//			sty	$.Param_functionHeapStackPointer+2
//			lda	$.rtn
//			sta	$.Param_callIndex
//			call
//b_1:

		ldy	$.rtn
		return

		.unlocal	_rtn

Recompiler__CallFunction_call:
	// Return index
	sec
	adc	$.add
	tay
	iny
	iny

	return


Recompiler__CallFunction_FindStatic:
	// Change bank
	phb
	pea	$_StaticRec_Tables/0x100
	plb
	plb

	// Load low bits as array index
	lda	$.originalFunction
	and	#0x00ff
	asl	a
	asl	a
	tax

	// Load pointer and length for this array, return false if the array is empty, assume carry clear from asl
	.local	_table
	lda	$_StaticRec_Tables+2,x
	beq	$+Recompiler__CallFunction_FindStatic_ReturnCarry
	adc	#_Zero-7
	tay
	lda	$_StaticRec_Tables+0,x
	sta	$.table

	// Loop through, keep carry set during this loop
	ldx	$.originalFunction+1
	//sec
Recompiler__CallFunction_FindStatic_Loop:
		// Is it the function pointer we're looking for?
		txa
		eor	($.table),y
		beq	$+Recompiler__CallFunction_FindStatic_ReturnTrue

		// Next
		tya
		sbc	#8
		tay
		bcs	$-Recompiler__CallFunction_FindStatic_Loop

Recompiler__CallFunction_FindStatic_ReturnCarry:
	plb
	rts

Recompiler__CallFunction_FindStatic_ReturnTrue:
	// Copy data
	dey
	tya
	clc
	adc	$.table
	tax
	lda	$0x0000,x
	sta	[$.Recompiler_FunctionList]
	ldy	#2
	lda	$0x0002,x
	sta	[$.Recompiler_FunctionList],y
	ldy	#4
	lda	$0x0004,x
	sta	[$.Recompiler_FunctionList],y
	ldy	#6
	lda	$0x0006,x
	sta	[$.Recompiler_FunctionList],y

	// Return true
	sec
	plb
	rts

	// ---------------------------------------------------------------------------

	.macro	Recompiler__CallFunctionJMPi_mac
		.local	_originalFunction, _originalFunction_b
		.local	_base, _add
		
		// Find this function's bank
		sta	$.originalFunction+0
		xba
		and	#0x00e0
		tay
		lda	$_Program_BankNum,y
		sta	$.originalFunction_b

		// Was this function recompiled statically? (inlined)
mac_FindStatic:
		// Load low bits as array index
		txa
		and	#0x00ff
		asl	a
		asl	a
		tax

		// Load pointer and length for this array, return false if the array is empty, assume carry clear from asl
		lda	$=StaticRec_Tables+2,x
		beq	$+mac_SkipStatic
		adc	#_Zero-7
		tay
		lda	$=StaticRec_Tables+0,x
		sta	$.Recompiler_StaticRec_Table
		
		// Loop through, keep carry set during this loop
		ldx	$.originalFunction+1
		//sec
mac_FindStatic_Loop:
			// Is it the function pointer we're looking for?
			txa
			eor	[$.Recompiler_StaticRec_Table],y
			beq	$+mac_FindStatic_ReturnTrue

			// Next
			tya
			sbc	#8
			tay
			bcs	$-mac_FindStatic_Loop

mac_FindStatic_ReturnCarry:
		bra	$+mac_SkipStatic

mac_FindStatic_ReturnTrue:
		// Copy data
		iny
		iny
		lda	[$.Recompiler_StaticRec_Table],y
		{0}
		iny
		lda	[$.Recompiler_StaticRec_Table],y
		{1}

mac_DoStatic:
		jmp	$_mac_Return
mac_SkipStatic:

		//.local	=pCurrent, =pThis

		// Keep base pointer
		lda	$.Recompiler_FunctionList+3
		sta	$.base

		// Increment base pointer
		lda	$.originalFunction
		and	#0x00ff
		asl	a
		tax
		lda	$_QuickFunction,x
		sta	$.add
		adc	$.Recompiler_FunctionList+3
		sta	$.Recompiler_FunctionList+3
	
		// Find this function
		lda	$.originalFunction+0
		sta	[$.Recompiler_FunctionList]
		lda	$.originalFunction_b
		ldy	#0x0002
		sta	[$.Recompiler_FunctionList],y

		// Inline for Array__Find 3
mac_loop3:
		lda	[$.Recompiler_FunctionList]
		tax
		ldy	#0x0001
		bra	$+mac_loop3_QuickStart
mac_loop3_reset:
		ldy	#0x0001
mac_loop3_inc:
		lda	$.Recompiler_FunctionList+9
		adc	$.Recompiler_FunctionList+3
		sta	$.Recompiler_FunctionList+3
mac_loop3_0:
		txa
mac_loop3_QuickStart:
		eor	[$.Recompiler_FunctionList+3]
		bne	$-mac_loop3_inc
		lda	[$.Recompiler_FunctionList],y
		eor	[$.Recompiler_FunctionList+3],y
		bne	$-mac_loop3_inc

		// Is it new?
		lda	$.Recompiler_FunctionList
		eor	$.Recompiler_FunctionList+3
		beq	$+mac_NotFound
			lda	$.Recompiler_FunctionList+3
			sec
			sbc	$.base
			bra	$+mac_Found

mac_NotFound:
		dec	a
mac_Found:

		// Restore base pointer
		ldx	$.base
		stx	$.Recompiler_FunctionList+3

		tay
		bpl	$+mac_call
			// Not listed, create it
			.precall	Recompiler__Build		_romAddr, _compileType
			lda	$.originalFunction
			sta	$.Param_romAddr
			stz	$.Param_compileType
			phb
			call
			plb
			clc
			adc	#3
			tay
			lda	[$.Recompiler_FunctionList+3],y
			{0}
			iny
			lda	[$.Recompiler_FunctionList+3],y
			{1}

			bra	$+mac_Return

mac_call:
		// Return index
		sec
		//adc	$.add
		adc	#2
		tay

		lda	[$.Recompiler_FunctionList+3],y
		{0}
		iny
		lda	[$.Recompiler_FunctionList+3],y
		{1}

mac_Return:
	.endm

	// ---------------------------------------------------------------------------
