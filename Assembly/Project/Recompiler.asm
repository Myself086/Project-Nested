

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

	// Entry: int romAddr
	// Return: int baseAddress, int entryPointOffset, short recompileFlags, byte[] code
Recompiler__BuildForExe:
	FromExeInit16

	lda	#1
	sta	$=StaticRec_Active

	lda	$0x0002
	call	Recompiler__SetBank

	.precall	Recompiler__Build		_romAddr, _compileType
	lda	$0x0000
	sta	$.Param_romAddr
	lda	#_Recompiler_CompileType_MoveToExe
	sta	$.Param_compileType
	call

	sta	$0x0000
	lda	$.DP_ZeroBank
	sta	$0x0002
	stx	$0x0004
	stz	$0x0006
	sty	$0x0008

	lda	#0
	sta	$=StaticRec_Active

	stp

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Recompiler__SetBank
	// Entry: A = NES bank number, A.hi = ingored
	// NOTE: Only used for static recompilation
Recompiler__SetBank:
	// Set banks
	and	#0x00ff
	sep	#0x20
	.mx	0x20
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
	
	return

	// ---------------------------------------------------------------------------

	// To use with local variable popSlideFlags in Recompiler__Build
	.def	PopSlideFlags_Txs				0x01
	.def	PopSlideFlags_PlaStaPpu			0x02

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Recompiler__Build		_romAddr, _compileType
	// Compile type flags
	.def	Recompiler_CompileType_MoveToCart	0x0001
	.def	Recompiler_CompileType_MoveToExe	0x0002
	// Return: A = Index for function list, X = HeapStack pointer, Y = HeapStack pointer bank
	// Return2 (MoveToExe set): A = Base address, X = Entry point offset, Y = Recompile flags, ZeroBank = Base address bank
Recompiler__Build:
	.local	_destListReadOffset
	.local	_startAddr, =readAddr
	.local	_opcodeX2
	.local	_recompileFlags, _stackTrace, _stackTraceReset, _stackDepth
	.local	=bankStart
	.local	.nesBank
	.local	=writeAddr, _writeStart
	.local	_thisOpcodeX2
	.local	=fakeCode
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

	// Add current ROM address to destinations
	lda	$.romAddr
	sta	[$.Recompiler_BranchDestList]
	lda	#0xffff
	ldy	#4
	sta	[$.Recompiler_BranchDestList],y
	lda	#0x0100
	ldy	#6
	sta	[$.Recompiler_BranchDestList],y
	ldx	#_Recompiler_BranchDestList
	ldy	#2
	call	Array__InsertIfDifferent

	// Reserve memory
	.local	=heapStackIndex
	call	Memory__AllocMax
	xba
	sta	$.heapStackIndex+1
	sta	$.writeAddr+1
	sty	$.heapStackIndex+0
	stx	$.writeAddr+0
	stx	$.writeStart

	// Pop slide detection
	.local	.popSlideFlags
	stz	$.popSlideFlags

	// Set bank for readAddr
	lda	$.romAddr
	bmi	$+Recompiler__Build_RomRange
		// Is this within recompile range?
		cmp	$_Recompile_PrgRamTopRange
		bcs	$+b_1
			// Are we in RAM?
			cmp	#0x0800
			bcc	$+b_2
			cmp	#0x6000
			bcs	$+b_2
				// Invalid range
				lda	$.romAddr
				unlock
				trap
				Exception	"Compiler Error - Bad Call{}{}{}A call was made to 0x{A:X}, this address is in an unsupported range."
b_2:

			// Set entry point
			lda	$.writeAddr
			ldy	#4
			sta	[$.Recompiler_BranchDestList+3],y

			// Trick which operand is read from recompiling the following jump below
			stz	$.readAddr+1
			lda	#_fakeCode
			sta	$.readAddr

			// Write new code
			lda	#0x004c
			sta	$.fakeCode
			lda	$.romAddr
			sta	$.fakeCode+1

			// Write JMP to RAM
			lda	#_Zero+0x004c*2
			tay
			sty	$.thisOpcodeX2
			ldx	$_Opcode__AddrMode,y
			jsr	($_Recompiler__Build_OpcodeType,x)
			rep	#0x31

			// Skip the regular recompiler
			jmp	$_Recompiler__Build_SkipRecompiler
b_1:

		// SRAM range
		lda	#0xb0b0
		sta	$.readAddr+1
		sta	$.bankStart+1
		stz	$.bankStart
		smx	#0x20
		stz	$.nesBank
		smx	#0x00
		bra	$+Recompiler__Build_SkipRomRange

Recompiler__Build_RomRange:
		xba
		and	#0x00e0
		tax
		lda	$_Program_Bank+1,x
		sta	$.readAddr+1
		sta	$.bankStart+1
		stz	$.bankStart
		smx	#0x20
		lda	$_Program_BankNum,x
		sta	$.nesBank
		smx	#0x00

Recompiler__Build_SkipRomRange:

	// Loop through the list of destination
	stz	$.destListReadOffset
Recompiler__Build_loop1:
		// Read next destination
		lda	$.destListReadOffset
		tay
		clc
		adc	#6
		tax
		lda	[$.Recompiler_BranchDestList+3],y
		sta	$.readAddr
		sta	$.startAddr
		txy
		lda	[$.Recompiler_BranchDestList+3],y
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
				.data16	_Recompiler__Build_loop1_loop_switch_BranchWait
				.data16	_Recompiler__Build_loop1_loop_switch_NesReturn
				.data16	_Recompiler__Build_loop1_loop_switch_SnesReturn
				.data16	_Recompiler__Build_loop1_loop_switch_IllegalNop
				.data16	_Recompiler__Build_loop1_loop_switch_LoadConst
				.data16	_Recompiler__Build_loop1_loop_switch_Jsl
				.data16	_Recompiler__Build_loop1_loop_switch_Txs

Recompiler__Build_loop1_loop_switch_LoadConst:
					// Is this instruction followed by a conditional branch?
					tyx
					ldy	#2
					lda	[$.readAddr],y
					and	#0x001f
					cmp	#0x0010
					beq	$+b_1
						txy
						clc
						jmp	$_Recompiler__Build_loop1_loop_next
b_1:

					// Read constant
					lda	[$.readAddr]
					and	#0xff00
					php

					// Change to 8-bit mode and clear upper bits of A
					smx	#0x20
					xba

					// Load branch condition
					lda	[$.readAddr],y
					lsr	a
					lsr	a
					lsr	a
					lsr	a
					lsr	a

					// Reverse condition?
					lsr	a
					tay					// Table offset
					pla
					bcs	$+b_1
						eor	#0xc3
b_1:
					// Test condition
					and	$_Recompiler__Build_loop1_loop_switch_LoadConst_BranchTable,y

					// Change back to 16-bit mode and clear carry
					rep	#0x31
					.mx	0x00

					// Condition met? If not, continue as normal
					bne	$+b_else
						txy
						jmp	$_Recompiler__Build_loop1_loop_next
b_else:
						// Condition met, end this block
						lda	$_Opcode__BytesTable,x
						adc	$.readAddr
						sta	$.readAddr

						// "Call" branch case before ending this block
						pea	$_Recompiler__Build_loop1_next-1
						jmp	$_Recompiler__Build_loop1_loop_switch_Branch_in

					.mx	0x00

Recompiler__Build_loop1_loop_switch_LoadConst_BranchTable:
					.data8	0x80, 0, 0, 0x02


Recompiler__Build_loop1_loop_switch_IllegalNop:
					// Are we allowed to recompile it?
					lda	$=RomInfo_CpuSettings
					and	#_RomInfo_Cpu_IllegalNop
					jeq	$_Recompiler__Build_loop1_loop_switch_Error
						// Yes
						jmp	$_Recompiler__Build_loop1_loop_next

Recompiler__Build_loop1_loop_switch_BranchWait:
					sty	$.opcodeX2
					ldx	$.readAddr+0
					ldy	$.nesBank
					call	Patch__IsInRange
					ldy	$.opcodeX2
					jcc	$_Recompiler__Build_loop1_loop_switch_Error
					clc

Recompiler__Build_loop1_loop_switch_Branch:
					// "Call" following code, workaround for using this case when breaking off an unconditional branch
					pea	$_Recompiler__Build_loop1_loop_next-1

Recompiler__Build_loop1_loop_switch_Branch_in:
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
					lda	#0xffff
					ldy	#4
					sta	[$.Recompiler_BranchDestList],y
					ldx	#_Recompiler_BranchDestList
					ldy	#2
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
					rts

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
					lda	[$.readAddr],y
					sta	[$.Recompiler_BranchDestList]
					lda	#0xffff
					ldy	#4
					sta	[$.Recompiler_BranchDestList],y
					ldx	#_Recompiler_BranchDestList
					ldy	#2
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

					// Is it followed by STA to PPU?
					lda	[$.readAddr]
					eor	#0x8d68
					bne	$+b_1
						tyx
						ldy	#2
						lda	[$.readAddr],y
						txy
						and	#0xe000
						eor	#0x2000
						bne	$+b_1
							lda	#_PopSlideFlags_PlaStaPpu
							tsb	$.popSlideFlags
b_1:

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
					jne	$_Recompiler__Build_loop1_loop_next

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
					// Safe TSX?
					lda	$=RomInfo_StackEmulation
					and	#_RomInfo_StackEmu_SafeTsx
					beq	$+b_1
						// Flag as pulling return
						lda	#_Opcode_F_PullReturn
						tsb	$.recompileFlags
b_1:
					jmp	$_Recompiler__Build_loop1_loop_next


Recompiler__Build_loop1_loop_switch_NesReturn:
					sty	$.opcodeX2
					ldx	$.readAddr+0
					ldy	$.nesBank
					call	Patch__IsInRange
					ldy	$.opcodeX2
					bcc	$+Recompiler__Build_loop1_loop_switch_Error
					clc

					// Set "pull return" flag to change caller's code
					lda	#_Opcode_F_PullReturn
					tsb	$.recompileFlags
					jmp	$_Recompiler__Build_loop1_next


Recompiler__Build_loop1_loop_switch_SnesReturn:
					sty	$.opcodeX2
					ldx	$.readAddr+0
					ldy	$.nesBank
					call	Patch__IsInRange
					ldy	$.opcodeX2
					bcc	$+Recompiler__Build_loop1_loop_switch_Error
					clc
					bra	$+Recompiler__Build_loop1_loop_switch_Return


Recompiler__Build_loop1_loop_switch_Jsl:
					sty	$.opcodeX2
					ldx	$.readAddr+0
					ldy	$.nesBank
					call	Patch__IsInRange
					ldy	$.opcodeX2
					bcc	$+Recompiler__Build_loop1_loop_switch_Error
					clc
					bra	$+Recompiler__Build_loop1_loop_switch_Regular


Recompiler__Build_loop1_loop_switch_Txs:
					lda	#_PopSlideFlags_Txs
					tsb	$.popSlideFlags
					bra	$+Recompiler__Build_loop1_loop_switch_Regular


Recompiler__Build_loop1_loop_switch_Brk:
					// Nothing special here yet?
Recompiler__Build_loop1_loop_switch_JmpIndexed:
Recompiler__Build_loop1_loop_switch_Error:
Recompiler__Build_loop1_loop_switch_Return:
					// Break from this loop
					jmp	$_Recompiler__Build_loop1_next

Recompiler__Build_loop1_loop_switch_Cop:
					sty	$.opcodeX2
					ldx	$.readAddr+0
					ldy	$.nesBank
					call	Patch__IsInRange
					ldy	$.opcodeX2
					bcc	$-Recompiler__Build_loop1_loop_switch_Error
					clc

Recompiler__Build_loop1_loop_switch_Regular:
Recompiler__Build_loop1_loop_next:
			// Next opcode
			lda	$_Opcode__BytesTable,y
			adc	$.readAddr
			sta	$.readAddr
			bcs	$+Recompiler__Build_loop1_next_clc			// Overflow into RAM: 0xffff -> 0x0000
			jmp	$_Recompiler__Build_loop1_loop

Recompiler__Build_loop1_next_clc:
		clc
Recompiler__Build_loop1_next:
		// Assume carry clear from everything pointing here

		// Complete this range
		lda	$.readAddr
		ldy	$.destListReadOffset
		iny
		iny
		sta	[$.Recompiler_BranchDestList+3],y

		// Next if more destinations are available
		lda	$.destListReadOffset
		adc	$.Recompiler_BranchDestList+9
		sta	$.destListReadOffset
		adc	$.Recompiler_BranchDestList+3
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
	ldy	#4
	lda	#0xfffe
	sta	[$.Recompiler_BranchDestList],y
	ldx	#_Recompiler_BranchDestList
	call	Array__Insert
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
				bra	$+Recompiler__Build_loop2_loop_skip1

Recompiler__Build_loop2_loop_in1:
					// Write new address for this label
					lda	$.writeAddr
					ldy	#0x0004
					sta	[$.destRead],y

					// Merge stack depth
					ldy	#0x0006
					lda	[$.destRead],y
					ora	$.stackDepth
					sta	$.stackDepth

					// New last address
					ldy	#0x0002
					lda	[$.destRead],y
					inc	a
					sta	$.lastReadAddr

					// Reset block flags, keep start address for this block
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
			bcc	$+b_1
				// Overflow into RAM: 0xffff -> 0x0000
				tax
				tdc		// Not exactly zero but the low byte is zero
				sta	[$.writeAddr]
				inc	$.writeAddr
				txa
b_1:

			// Did we overflow memory?
			ldx	$.writeAddr
			cpx	$.writeStart
			jcc	$_Recompiler__Build_MemoryOverflow

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


	// Reset block flags
	stz	$.blockFlags
	stz	$.blockStart
	// Prepare reading destination list
	lda	$.Recompiler_BranchDestList+3
	sta	$.destRead+0
	lda	$.Recompiler_BranchDestList+4
	sta	$.destRead+1
	// Reset stack trace
	lda	$.stackTraceReset
	sta	$.stackTrace
Recompiler__Build_loop2b:
		// Find unsolved label
		ldy	#4
		lda	#0xffff
		sta	[$.Recompiler_BranchDestList],y
		tya
		ldx	#_Recompiler_BranchDestList
		ldy	#2
		call	Array__Find2
		// Exit if none found
		jmi	$_Recompiler__Build_loop2b_exit

		// Adjust read pointer
		clc
		adc	$.Recompiler_BranchDestList+3
		sta	$.destRead+0

		// Prepare reading block
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

Recompiler__Build_loop2b_loop:
			// Are we on a branch destination?
			lda	[$.destRead]
			beq	$+b_1
			cmp	$.readAddr
			beq	$+b_in
			bcs	$+b_1
				bra	$+b_2
b_in:
					// Is this block already solved?
					ldy	#4
					lda	[$.destRead],y
					inc	a
					beq	$+b_3
						// Jump to the already compiled code
						lda	#0x004c
						sta	[$.writeAddr]
						lda	[$.destRead]
						ldy	#1
						sta	[$.writeAddr],y

						// Record this address so we can fix it later
						lda	$.writeAddr
						inc	a
						sta	[$.Recompiler_BranchSrcList]
						ldx	#_Recompiler_BranchSrcList
						call	Array__Insert

						// Add to write address
						lda	#3
						clc
						adc	$.writeAddr
						sta	$.writeAddr

						// Next
						jmp	$_Recompiler__Build_loop2b
b_3:

					// Write new address for this label
					lda	$.writeAddr
					//ldy	#0x0004
					sta	[$.destRead],y

					// Merge stack depth
					ldy	#0x0006
					lda	[$.destRead],y
					ora	$.stackDepth
					sta	$.stackDepth

					// New last address
					ldy	#0x0002
					lda	[$.destRead],y
					inc	a
					sta	$.lastReadAddr

					// Reset block flags, keep start address for this block
					stz	$.blockFlags
					lda	[$.destRead]
					sta	$.blockStart
b_2:

				// Increment destRead
				lda	$.destInc
				clc
				adc	$.destRead
				sta	$.destRead

				// Clear known memory prefix for optimizing memory emulation
				stz	$.memoryPrefix

				// Clear stack trace (old version of stackDepth)
				lda	$.stackTraceReset
				sta	$.stackTrace
b_1:
			// Read next byte and clear carry in the process (asl)
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
			bcc	$+b_1
				// Overflow into RAM: 0xffff -> 0x0000
				tax
				tdc		// Not exactly zero but the low byte is zero
				sta	[$.writeAddr]
				inc	$.writeAddr
				txa
b_1:

			// Did we overflow memory?
			ldx	$.writeAddr
			cpx	$.writeStart
			jcc	$_Recompiler__Build_MemoryOverflow

			// Are we done?
			cmp	$.lastReadAddr
			jcc	$_Recompiler__Build_loop2b_loop

		// Next
		jmp	$_Recompiler__Build_loop2b
Recompiler__Build_loop2b_exit:


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
			Exception	"Compiler Error - Branch Src{}{}{}Branch source not found."
b_1:
		tay
		lda	[$.Recompiler_BranchDestList+3],y
		sta	[$.srcBank]
		inc	a
		bne	$+b_1
			unlock
			trap
			Exception	"Compiler Error - Branch Dest{}{}{}Branch destination not found."
b_1:

		// Next
		ldy	$.srcRead
		iny
		iny
		bra	$-Recompiler__Build_loop3
Recompiler__Build_loop3_exit:

Recompiler__Build_SkipRecompiler:

	// Are we transferring this code to exe?
	lda	$.compileType
	and	#_Recompiler_CompileType_MoveToExe
	beq	$+b_1
		// Transfer code to exe

		// Push code
		//  X = Length
		lda	$.writeAddr
		sec
		sbc	[$.heapStackIndex]
		tax
		//  Y = Address bank
		lda	$.writeAddr+2
		and	#0x00ff
		tay
		//  A = Address
		lda	[$.heapStackIndex]
		WDM_PushByteArray

		// Find this function's starting address
		lda	$.romAddr
		sta	[$.Recompiler_BranchDestList]
		ldx	#_Recompiler_BranchDestList
		ldy	#0x0002
		call	Array__Find
		clc
		adc	#0x0004
		tay
		lda	[$.Recompiler_BranchDestList+3],y
		sec
		sbc	[$.heapStackIndex]
		.local	_entryPointOffset, =baseAddress
		sta	$.entryPointOffset
		lda	[$.heapStackIndex]
		sta	$.baseAddress
		lda	$.heapStackIndex+2
		sta	$.baseAddress+2

		// Dealloc
		.precall	Memory__Trim	=StackPointer, _Length
		lda	$.heapStackIndex+1
		sta	$.Param_StackPointer+1
		lda	$.heapStackIndex+0
		sta	$.Param_StackPointer+0
		stz	$.Param_Length
		call

		// Return base address and entry point offset
		lda	$.baseAddress+2
		and	#0x00ff
		sta	$.DP_ZeroBank
		ldy	$.recompileFlags
		ldx	$.entryPointOffset
		lda	$.baseAddress
		return
		.unlocal	_entryPointOffset, =baseAddress
b_1:

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

	// Try allocating memory on the cart
	.local	_length, =rtnHeapStack
	lda	$.writeAddr
	sec
	sbc	[$.heapStackIndex]
	sta	$.length
	tax
	lda	#0xffff
	call	Memory__TryAlloc
	ora	#0
	bpl	$+Recompiler__Build_CopyToCart
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

Recompiler__Build_CopyToCart:
	// Continue copying to cart
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

	// Copy bytes over to cart
	.local	4 copyCode
	lda	#0x6054
	sta	$.copyCode+0
	sta	$.copyCode+2
	// Load banks
	phb
	sep	#0x20
	.mx	0x20
	lda	$.readAddr+2
	xba
	lda	$.writeAddr+2
	rep	#0x20
	.mx	0x00
	sta	$.copyCode+1
	// Load length
	lda	$.length
	// Load source and destination addresses
	ldx	$.readAddr
	ldy	$.writeAddr
	// Copy
	jsr	$_copyCode
	// Restore bank
	plb
	.unlocal	4 copyCode

	// Look for JMP and replace their destination, keep carry clear during this loop
	ldy	#0
	tya
	sta	[$.Recompiler_BranchSrcList+0]
	// Load next JMP
	lda	[$.Recompiler_BranchSrcList+3],y
	beq	$+b_1
b_loop:
		// Fix JMP destination address
		sec
		sbc	$.readAddr
		tyx
		tay
		lda	[$.readAddr],y
		sec
		sbc	$.readAddr
		clc
		adc	$.writeAddr
		sta	[$.writeAddr],y

		// Next
		txa
		clc
		adc	$.Recompiler_BranchSrcList+9
		tay
		lda	[$.Recompiler_BranchSrcList+3],y
		bne	$-b_loop
b_1:

	// Fix SNES return addresses
	lda	$=StaticRec_OriginCount
	beq	$+b_loop_exit
b_loop:
		// Next (second half)
		sec
		sbc	#4
		tax

		// Do we need to fix this address?
		lda	$=StaticRec_OriginsB+2,x
		bpl	$+b_loop_exit
		tay

		// Fix address
		lda	$=StaticRec_OriginsB+0,x
		sec
		sbc	$.readAddr
		clc
		adc	$.writeAddr
		sta	$=StaticRec_OriginsB+0,x
		tya								// MSB already in Y register
		sec
		sbc	$.readAddr+2
		clc								// No bank crossing
		adc	$.writeAddr+2
		and	#0x00ff						// Validate SNES return address
		sta	$=StaticRec_OriginsB+2,x

		// Next (first half)
		txa
		bne	$-b_loop
b_loop_exit:
b_1:

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


	// Entry: A.lo = Page range, A.hi = { 0 = Compare, 1 = Forced }, X = Lookup table address, Y = Lookup table bank
	// Return: Carry set = Prefix added
Recompiler__Build_OpcodeType_MemoryPrefix:
	.local	=memPrefixTable
	// Write pointer
	stx	$.memPrefixTable
	sty	$.memPrefixTable+2

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
			clc
			rts
b_diff:
			// Different
			ora	#0x0100
			tay
			and	#0x00ff
b_2:
	sta	$.memoryPrefix

	// Write prefix and preserve 4 written bytes
	lda	[$.memPrefixTable],y
	tax
	ldy	#2
	lda	[$.writeAddr]
	pha
	lda	[$.writeAddr],y
	pha
	lda	$.memPrefixTable+2
	.unlocal	=memPrefixTable
	jsr	$_Recompiler__Build_Inline

	// Rewrite 4 bytes that were already written
	ldy	#2
	pla
	sta	[$.writeAddr],y
	pla
	sta	[$.writeAddr]

	// Return true
	sec
	rts


	// Entry: A.lo = Page range, A.hi = { 0 = Compare, 1 = Forced }, X = Lookup table address, Y = Lookup table bank
	// Return: Carry set = Prefix added
Recompiler__Build_OpcodeType_MemoryPrefixSram:
	.local	=memPrefixTable
	// Write pointer
	stx	$.memPrefixTable
	sty	$.memPrefixTable+2

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
			clc
			rts
b_diff:
			// Different
			ora	#0x0100
			tay
			and	#0x00ff
b_2:
	// Are we accessing SRAM?
	cmp	#0x0060
	bne	$+b_3
		pha
		// Are we using static SRAM?
		andbeq	$=RomInfo_MemoryEmulation, #_RomInfo_MemEmu_StaticSram, $+b_2
			// Are we processing one of the 16 opcodes that we can extend to 24-bit address?
			lda	$.thisOpcodeX2
			and	#0x001e						// Bottom 4 bits
			eor	#0x001a
			jeq	$_Recompiler__Build_OpcodeType_LongSram
b_2:
		pla
b_3:

	sta	$.memoryPrefix

	// Write prefix and preserve 4 written bytes
	lda	[$.memPrefixTable],y
	tax
	ldy	#2
	lda	[$.writeAddr]
	pha
	lda	[$.writeAddr],y
	pha
	lda	$.memPrefixTable+2
	.unlocal	=memPrefixTable
	jsr	$_Recompiler__Build_Inline

	// Rewrite 4 bytes that were already written
	ldy	#2
	pla
	sta	[$.writeAddr],y
	pla
	sta	[$.writeAddr]

	// Return true
	sec
	rts


Recompiler__Build_OpcodeType_LongSram:
	// Fix stack
	pla
	pla

	// Write long version of this instruction and target bank 0xb0
	lda	$.thisOpcodeX2
	lsr	a
	and	#0x00ff
	ora	#0xb00f
	ldy	#2
	sta	[$.writeAddr]
	sta	[$.writeAddr],y
	dey
	lda	[$.readAddr],y
	sta	[$.writeAddr],y

	// Add to write address
	lda	#0x0004
	clc
	adc	$.writeAddr
	sta	$.writeAddr
	rts


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
	andbne	$=RomInfo_InputFlags, #_RomInfo_Input_CustomControl, $+b_1
		// Are we reading gamepad inputs?
		lda	[$.readAddr],y
		and	#0xfffe
		cmp	#0x4016
		jeq	$_Recompiler__Build_OpcodeType_Abs_HighRange
b_1:
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
	// Is this range static?
	tax
	jsr	$_Recompiler__Build_IsRangeStatic
	txa
	bcs	$+b_1
		// ROM and SRAM range
		ldx	#_Inline_StoreDirect_LUT
		ldy	#_Inline_StoreDirect_LUT/0x10000
		jsr	$_Recompiler__Build_OpcodeType_MemoryPrefix
b_1:

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
	// Is this range static?
	tax
	jsr	$_Recompiler__Build_IsRangeStatic
	txa
	bcs	$+b_1
		// ROM and SRAM range
		ldx	#_Inline_CmdDirect_LUT
		ldy	#_Inline_CmdDirect_LUT/0x10000
		jsr	$_Recompiler__Build_OpcodeType_MemoryPrefixSram
		bcs	$+b_1
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
	clc
	adc	$.writeAddr
	sta	$.writeAddr
	rts


Recompiler__Build_OpcodeType_LdaAbsX:
	ldx	#_iIOPort_ldax*2
	bra	$+b_1
Recompiler__Build_OpcodeType_LdaAbsY:
	ldx	#_iIOPort_lday*2
	//bra	$+b_1
b_1:

	// Preload Y index and write opcode
	lsr	a
	sta	[$.writeAddr]
	ldy	#0x0001

	// Are we in IO range?
	lda	[$.readAddr],y
	bmi	$+b_1
	cmp	#0x2000
	bcc	$+b_1
	cmp	#0x5f01			// Accessing PRG RAM via page crossing
	bcs	$+b_1
		andbne	$=RomInfo_InputFlags, #_RomInfo_Input_CustomControl, $+b_2
			// Are we reading gamepad inputs?
			lda	[$.readAddr],y
			and	#0xfffe
			cmp	#0x4016
			bra	$+b_1
b_2:
		// Interprete IO port
		lda	[$.readAddr],y
		jmp	$_Recompiler__Build_OpcodeType_Abs_IO
b_1:

	// Are we using banking emulation?
	lda	$=RomInfo_MemoryEmulation
	bit	#_RomInfo_MemEmu_AbsBank
	jeq	$_Recompiler__Build_OpcodeType_LdaAbsY_Regular
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
		cmp	#0x5f01
		bcc	$+Recompiler__Build_OpcodeType_LdaAbsY_Regular
		// Is this range static?
		tax
		jsr	$_Recompiler__Build_IsRangeStatic
		txa
		bcs	$+Recompiler__Build_OpcodeType_LdaAbsY_Regular
			// Page 0x5f?
			cmp	#0x6000
			bcs	$+b_2
				lda	#0x6000
b_2:
			// ROM and SRAM range
			ldx	#_Inline_LoadDirect_LUT
			ldy	#_Inline_LoadDirect_LUT/0x10000
			jsr	$_Recompiler__Build_OpcodeType_MemoryPrefixSram
			bcs	$+Recompiler__Build_OpcodeType_LdaAbsY_Regular
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
	clc
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
	bmi	$+b_in
	cmp	#0x2000
	bcc	$+b_1
	cmp	#0x5f01			// Accessing PRG RAM via page crossing
	bcs	$+b_1
b_in:
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
		cmp	#0x5f01
		bcc	$+b_1
		// Is this range static?
		tax
		jsr	$_Recompiler__Build_IsRangeStatic
		txa
		bcs	$+b_1
			// Page 0x5f?
			cmp	#0x6000
			bcs	$+b_2
				lda	#0x6000
b_2:

			// ROM and SRAM range
			ldx	#_Inline_StoreDirect_LUT
			ldy	#_Inline_StoreDirect_LUT/0x10000
			jsr	$_Recompiler__Build_OpcodeType_MemoryPrefixSram
			bcs	$+b_1
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
	bit	#_RomInfo_MemEmu_Load
	jeq	$_Recompiler__Build_OpcodeType_Zpg
		stz	$.memoryPrefix
		bit	#_RomInfo_MemEmu_IndCrossBank
		bne	$+b_else
			// Without cross bank
			lda	[$.readAddr]
			xba
			tay
			iny
			ldx	#_Inline_CmdIndirectY
			lda	#_Inline_CmdIndirectY/0x10000
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
			lda	$=Interpret__IndirectYIO_PageTable,x
			ldy	#_Inline_CmdIndirectY_Call-Inline_CmdIndirectY+1
			sta	[$.writeAddr],y

			// Add to write address, assume carry clear from LSR
			pla
			adc	$.writeAddr
			sta	$.writeAddr
			jmp	$_Recompiler__Build_OpcodeType_Zpg
b_else:
			// With cross bank
			lda	[$.readAddr]
			xba
			tay
			iny
			ldx	#_Inline_CmdIndirectYCross
			lda	#_Inline_CmdIndirectYCross/0x10000
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
			lda	$=Interpret__IndirectYIO_PageTable,x
			ldy	#_Inline_CmdIndirectYCross_Call-Inline_CmdIndirectYCross+1
			sta	[$.writeAddr],y

			// Change some parameters
			lda	[$.readAddr]
			smx	#0x30
			lda	#0
			ldy	#.Inline_CmdIndirectYCross_AdditionTable-Inline_CmdIndirectYCross+1
			sta	[$.writeAddr],y
			ldy	#.Inline_CmdIndirectYCross_AdcZero-Inline_CmdIndirectYCross+1
			sta	[$.writeAddr],y
			xba
			ldy	#.Inline_CmdIndirectYCross_LSB-Inline_CmdIndirectYCross+1
			sta	[$.writeAddr],y

			// Add to write address
			rep	#0x31
			.mx	0x00
			pla
			adc	$.writeAddr
			sta	$.writeAddr
			jmp	$_Recompiler__Build_OpcodeType_Zpg

Recompiler__Build_OpcodeType_LdaIndY:
	// Do we have memory emulation turned on?
	lda	$=RomInfo_MemoryEmulation
	bit	#_RomInfo_MemEmu_Load
	jeq	$_Recompiler__Build_OpcodeType_Zpg
		stz	$.memoryPrefix
		bit	#_RomInfo_MemEmu_IndCrossBank
		bne	$+b_else
			// Without cross bank
			lda	[$.readAddr]
			xba
			tay
			iny
			ldx	#_Inline_LoadIndirectY
			lda	#_Inline_LoadIndirectY/0x10000
			jsr	$_Recompiler__Build_Inline2
			jmp	$_Recompiler__Build_OpcodeType_Zpg
b_else:
			// With cross bank
			lda	[$.readAddr]
			xba
			tay
			iny
			ldx	#_Inline_LoadIndirectYCross
			lda	#_Inline_LoadIndirectYCross/0x10000
			jsr	$_Recompiler__Build_Inline2NoInc
			tyx

			// Change some parameters
			lda	[$.readAddr]
			smx	#0x30
			lda	#0
			ldy	#.Inline_LoadIndirectYCross_AdditionTable-Inline_LoadIndirectYCross+1
			sta	[$.writeAddr],y
			ldy	#.Inline_LoadIndirectYCross_AdcZero-Inline_LoadIndirectYCross+1
			sta	[$.writeAddr],y
			xba
			ldy	#.Inline_LoadIndirectYCross_LSB-Inline_LoadIndirectYCross+1
			sta	[$.writeAddr],y

			// Add to write address
			rep	#0x31
			.mx	0x00
			txa
			adc	$.writeAddr
			sta	$.writeAddr
			jmp	$_Recompiler__Build_OpcodeType_Zpg


Recompiler__Build_OpcodeType_StaIndY:
	// Do we have memory emulation turned on?
	lda	$=RomInfo_MemoryEmulation
	bit	#_RomInfo_MemEmu_Store
	jeq	$_Recompiler__Build_OpcodeType_Zpg
		stz	$.memoryPrefix
		bit	#_RomInfo_MemEmu_IndCrossBank
		bne	$+b_else
			// Without cross bank
			lda	[$.readAddr]
			xba
			tay
			iny
			ldx	#_Inline_StoreIndirectY
			lda	#_Inline_StoreIndirectY/0x10000
			jsr	$_Recompiler__Build_Inline2
			jmp	$_Recompiler__Build_OpcodeType_Zpg
b_else:
			// With cross bank
			lda	[$.readAddr]
			xba
			tay
			iny
			ldx	#_Inline_StoreIndirectYCross
			lda	#_Inline_StoreIndirectYCross/0x10000
			jsr	$_Recompiler__Build_Inline2NoInc
			tyx

			// Change some parameters
			lda	[$.readAddr]
			smx	#0x30
			lda	#0
			ldy	#.Inline_StoreIndirectYCross_AdditionTable-Inline_StoreIndirectYCross+1
			sta	[$.writeAddr],y
			ldy	#.Inline_StoreIndirectYCross_AdcZero-Inline_StoreIndirectYCross+1
			sta	[$.writeAddr],y
			xba
			ldy	#.Inline_StoreIndirectYCross_LSB-Inline_StoreIndirectYCross+1
			sta	[$.writeAddr],y

			// Add to write address
			rep	#0x31
			.mx	0x00
			txa
			adc	$.writeAddr
			sta	$.writeAddr
			bra	$+Recompiler__Build_OpcodeType_Zpg


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

	// Are we compiling for the exe?
	andbne	$.compileType, #_Recompiler_CompileType_MoveToExe, $-Recompiler__Build_OpcodeType_Const

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
		lda	#_Recompiler_CompileType_MoveToCart
		and	$.compileType
		bne	$+b_1
			// Write code
			ldx	#_Inline__PushConstantReturn
			lda	#_Inline__PushConstantReturn/0x10000
			ldy	#0
			jsr	$_Recompiler__Build_Inline2NoInc
			tyx

			// Copy last LDA
			ldy	#3
			lda	[$.readAddr],y
			sta	[$.writeAddr]

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

		// Write and increment origin count, assume carry clear from Recompiler__Build_Inline2NoInc
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


Recompiler__Build_OpcodeType_StaXInd:
	// Do we have memory emulation turned on?
	lda	$=RomInfo_MemoryEmulation
	and	#_RomInfo_MemEmu_Store
	beq	$+b_1
		stz	$.memoryPrefix
		lda	[$.readAddr]
		xba
		tay
		iny
		ldx	#_Inline_StoreIndirectX
		lda	#_Inline_StoreIndirectX/0x10000
		jsr	$_Recompiler__Build_Inline2
b_1:
	jmp	$_Recompiler__Build_OpcodeType_Zpg


Recompiler__Build_OpcodeType_LdaXInd:
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
		lda	$=Interpret__IndirectXIO_PageTable,x
		ldy	#_Inline_CmdIndirectX_Call-Inline_CmdIndirectX+1
		sta	[$.writeAddr],y

		// Add to write address, assume carry clear from LSR
		pla
		adc	$.writeAddr
		sta	$.writeAddr
b_1:
	jmp	$_Recompiler__Build_OpcodeType_Zpg


Recompiler__Build_OpcodeType_Brw:
	// This opcode must be in a patch range
	ldx	$.readAddr+0
	ldy	$.nesBank
	call	Patch__IsInRange
	jcc	$_Recompiler__Build_OpcodeType_None
	clc

	// Branch + wait, overrides STP illegal opcodes

	// Remove opcode bit 2
	lda	[$.readAddr]
	and	#0x00fd

	// Write branch opcode
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
		inc	a
		beq	$+b_1
			sbc	#2
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
		// b.. $+10
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

		// Jump to interpreter
			
		// Write inlined code
		ldx	#_Inline__JmpToRam
		lda	#_Inline__JmpToRam/0x10000
		jsr	$_Recompiler__Build_InlineNoInc
		tyx

		// Original value
		ldy	#1
		lda	[$.readAddr],y
		ldy	#_Inline__JmpToRam_OriginalValue-Inline__JmpToRam+1
		sta	[$.writeAddr],y

		// Add to write address
		txa
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


	// Entry: A = Destination
Recompiler__Build_OpcodeType_Jmp_FakeSource:
	// Write new code
	ldx	#0x004c
	stx	$.fakeCode
	sta	$.fakeCode+1

	// Change where code is read from
	pei	($.readAddr)
	stz	$.readAddr+1
	lda	#_fakeCode
	sta	$.readAddr

	jsr	$_Recompiler__Build_OpcodeType_Jmp_OutOfRange

	// Restore where code is read from
	lda	$.bankStart+1
	sta	$.readAddr+1
	pla
	sta	$.readAddr

	rts


Recompiler__Build_OpcodeType_JmpI:
	// Flag this function as having a return and indirect jump
	lda	#_Opcode_F_HasReturn|Opcode_F_IndirectJmp
	tsb	$.recompileFlags

	// Is destination in ROM or SRAM?
	ldy	#1
	lda	[$.readAddr],y
	cmp	#0x6000
	bcc	$+b_1
	// Is this range static?
	tax
	jsr	$_Recompiler__Build_IsRangeStatic
	txa
	bcs	$+b_1
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
	ldy	#1
	lda	[$.readAddr],y
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
	jcs	$_Recompiler__Build_OpcodeType_Jsr_1
		// Is it in SRAM?
		and	#0xe000
		beq	$+b_2
		bmi	$+b_2
			lda	#_Inline_StoreDirectKnown_60/0x10000
			ldx	#_Inline_StoreDirectKnown_60
			jsr	$_Recompiler__Build_Inline2
b_2:

		// Are we using native returns?
		lda	$=RomInfo_StackEmulation
		and	#_RomInfo_StackEmu_NativeReturn
		beq	$+b_else
			// Natively call interpreter
			
			// Write inlined code
			ldx	#_Inline__JslToRam
			lda	#_Inline__JslToRam/0x10000
			jsr	$_Recompiler__Build_InlineNoInc
			tyx

			// Fix PER
			ldy	#_Inline__JslToRam_Per-Inline__JslToRam+1
			lda	#0x00ff
			and	[$.writeAddr],y
			sta	[$.writeAddr],y

			// Original value
			ldy	#1
			lda	[$.readAddr],y
			ldy	#_Inline__JslToRam_OriginalValue-Inline__JslToRam+1
			sta	[$.writeAddr],y

			// Add to write address
			txa
			clc
			adc	$.writeAddr
			sta	$.writeAddr
			rts
b_else:
			// Non-natively call interpreter
			
			// Write inlined code
			ldx	#_Inline__JsrToRam
			lda	#_Inline__JsrToRam/0x10000
			jsr	$_Recompiler__Build_InlineNoInc
			tyx

			// Original return
			lda	$.readAddr
			inc	a
			inc	a
			ldy	#_Inline__JsrToRam_OriginalReturn-Inline__JsrToRam+1
			sta	[$.writeAddr],y

			// Original value
			ldy	#1
			lda	[$.readAddr],y
			ldy	#_Inline__JsrToRam_OriginalValue-Inline__JsrToRam+1
			sta	[$.writeAddr],y

			// Add to write address
			txa
			clc
			adc	$.writeAddr
			sta	$.writeAddr
			rts
Recompiler__Build_OpcodeType_Jsr_1:

	clc

	// Are we compiling into ROM?
	lda	#_Recompiler_CompileType_MoveToCart
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
	// Call interpreter like this (native return version):
	// jsr $=Interpret
	//		0	1	2	3
	//		jsr	#	#	0x7f

	andbeq	$=RomInfo_StackEmulation, #_RomInfo_StackEmu_NativeReturn, $+b_else
		// Native return

		// Write long JSR
		lda	#0x7f22
		bra	$+b_1
b_else:
		// Non-native return

		// Is original opcode a JSR?
		lda	[$.readAddr]
		and	#0x00ff
		cmp	#0x0020
		bne	$+b_2
			// Write PEA for pushing original return address
			lda	#0x00f4
			sta	[$.writeAddr]
			ldy	#1
			lda	$.readAddr
			clc
			adc	#2
			sta	[$.writeAddr],y

			// Add to write address, assume carry clear from previous adc
			lda	#3
			adc	$.writeAddr
			sta	$.writeAddr
			clc					// writeAddr can overflow
b_2:

		// Write long JMP
		lda	#0x7f5c
b_1:

	//lda	#0x7f22
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

	// Write SNES return, assume carry clear from previous adc
	lda	#3
	adc	$.writeAddr
	sta	$=StaticRec_OriginsB+0,x
	lda	$.writeAddr+2
	ora	#0x8000					// Validation for fixing the address later
	sta	$=StaticRec_OriginsB+2,x

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

Recompiler__Build_OpcodeType_RtsNes_in:
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
	clc
	adc	$.writeAddr
	sta	$.writeAddr
	rts


Recompiler__Build_OpcodeType_RtsNes:
	// This opcode must be in a patch range
	ldx	$.readAddr+0
	ldy	$.nesBank
	call	Patch__IsInRange
	jcc	$_Recompiler__Build_OpcodeType_None
	
	bra	$-Recompiler__Build_OpcodeType_RtsNes_in


Recompiler__Build_OpcodeType_RtlSnes:
	// This opcode must be in a patch range
	ldx	$.readAddr+0
	ldy	$.nesBank
	call	Patch__IsInRange
	jcc	$_Recompiler__Build_OpcodeType_None
	clc

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

	// Are we using native return from interrupt?
	lda	$=RomInfo_StackEmulation
	and	#_RomInfo_StackEmu_NativeReturnInterrupt
	beq	$+b_1
		// Write PLP+RTL
		lda	#0x6b28
		sta	[$.writeAddr]
		inc	$.writeAddr
		inc	$.writeAddr
		rts

b_1:
	// Write JMP to interpreted RTI
	lda	#_JMPiU__FromRti*0x100+0x5c
	sta	[$.writeAddr]
	lda	#_JMPiU__FromRti/0x100
	ldy	#2
	sta	[$.writeAddr],y

	// Add to write address
	lda	#0x0004
	adc	$.writeAddr
	sta	$.writeAddr
	rts


Recompiler__Build_OpcodeType_Jsl:
	// This opcode must be in a patch range
	ldx	$.readAddr+0
	ldy	$.nesBank
	call	Patch__IsInRange
	jcc	$_Recompiler__Build_OpcodeType_None
	clc

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
	// Test interrupt reset range?
	lda	$=RomInfo_StackResetRange
	xba
	cmp	$=RomInfo_StackResetRange
	beq	$+b_in
	bcs	$+b_1
b_in:
		ldy	#1
		andbne	$=RomInfo_StackEmulation, #_RomInfo_StackEmu_Page01, $+b_2
			ldy	#9
b_2:
		ldx	#_Inline__Txs_WithRangeTest
		lda	#_Inline__Txs_WithRangeTest/0x10000
		jsr	$_Recompiler__Build_Inline2NoInc

		// Add to write address
		tya
		clc
		adc	$.writeAddr
		tax

		// Fix top and bottom
		lda	$=RomInfo_StackResetRange
		smx	#0x20
		ldy	#_Inline__Txs_WithRangeTest_Bottom-Inline__Txs_WithRangeTest+1
		sta	[$.writeAddr],y
		xba
		ldy	#_Inline__Txs_WithRangeTest_Top-Inline__Txs_WithRangeTest+1
		sta	[$.writeAddr],y

		stx	$.writeAddr
		rts

		.mx	0x00
b_1:

	ldy	#1
	andbne	$=RomInfo_StackEmulation, #_RomInfo_StackEmu_Page01, $+b_1
		ldy	#9
b_1:
	ldx	#_Inline__Txs_Regular
	lda	#_Inline__Txs_Regular/0x10000
	jmp	$_Recompiler__Build_Inline2


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
	// Are we using pop slides?
	lda	$.popSlideFlags
	eor	#0xffff
	and	#_PopSlideFlags_Txs|PopSlideFlags_PlaStaPpu
	bne	$+b_1
		andbne	$=RomInfo_StackEmulation, #_RomInfo_StackEmu_Page01, $+b_1
			lda	#_Inline__PlaIndirect/0x10000
			ldx	#_Inline__PlaIndirect
			ldy	#0
			jsr	$_Recompiler__Build_Inline2

			rts
b_1:

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
	// This opcode must be in a patch range
	ldx	$.readAddr+0
	ldy	$.nesBank
	call	Patch__IsInRange
	bcc	$+Recompiler__Build_OpcodeType_None

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
	andbne	$=RomInfo_StackEmulation, #_RomInfo_StackEmu_NativeReturnInterrupt, $+Recompiler__Build_OpcodeType_None

	// Add prefix if necessary
	lda	#0xfffe
	ldx	#_Inline_StoreDirect_LUT
	ldy	#_Inline_StoreDirect_LUT/0x10000
	jsr	$_Recompiler__Build_OpcodeType_MemoryPrefix

	// Add interpreted BRK code
	ldx	#_Interpret__Brk
	lda	#_Interpret__Brk/0x10000
	jsr	$_Recompiler__Build_InlineNoInc
	tyx
	ldy	#_Interpret__Brk_PushReturn-Interpret__Brk+1
	lda	$.readAddr
	inc	a
	inc	a
	sta	[$.writeAddr],y

	// Increment write address
	txa
	clc
	adc	$.writeAddr
	sta	$.writeAddr

	rts


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


	// Entry: A = Address
	// Return: A = Range bit, nz = A
Recompiler__Build_ConvertAddressToRangeBit:
	asl	a
	rol	a
	rol	a
	rol	a
	and	#0x0007
	tax
	lda	$_Recompiler__Build_ConvertAddressToRangeBit_Data,x
	and	#0x00ff
	rts

Recompiler__Build_ConvertAddressToRangeBit_Data:
	.data8	0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80


Recompiler__Build_MemoryOverflow:
	unlock
	trap
	Exception	"Out of Memory{}{}{}Recompiler.Build ran out of memory while writing code{}{}Try following step 5 on the exe's main window. This will reduce memory usage and improve performance."


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
		and	#0x0001
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
			.ifnamecontains	{2}, "j"
			{
				{2}	$_b_branch
			}
			.else
			{
				{2}	$-b_branch
			}
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
		Recompiler__Build_CoreCall_IfGoto	.freeRegs, 0x0100, bne

	case	CoreCall_IfNotFreeA
		Recompiler__Build_CoreCall_IfGoto	.freeRegs, 0x0100, beq

	case	CoreCall_IfFreeX
		Recompiler__Build_CoreCall_IfGoto	.freeRegs, 0x0200, bne

	case	CoreCall_IfNotFreeX
		Recompiler__Build_CoreCall_IfGoto	.freeRegs, 0x0200, beq

	case	CoreCall_IfFreeY
		Recompiler__Build_CoreCall_IfGoto	.freeRegs, 0x0400, bne

	case	CoreCall_IfNotFreeY
		Recompiler__Build_CoreCall_IfGoto	.freeRegs, 0x0400, beq

	case	CoreCall_IfFreeP
		Recompiler__Build_CoreCall_IfGoto	.pushFlags, _CoreCallFlag_PushP, beq

	case	CoreCall_IfNotFreeP
		Recompiler__Build_CoreCall_IfGoto	.pushFlags, _CoreCallFlag_PushP, bne

	case	CoreCall_IfJit
		Recompiler__Build_CoreCall_IfGoto	=StaticRec_Active, 0x0001, bne

	case	CoreCall_IfAot
		Recompiler__Build_CoreCall_IfGoto	=StaticRec_Active, 0x0001, jeq

	case	CoreCall_IfSet
		.local	=tempPointer
		lda	[$.src]
		sta	$.tempPointer+0
		inc	$.src
		inc	$.src
		lda	[$.src]
		sta	$.tempPointer+2
		inc	$.src
		inc	$.src

		xba
		and	[$.tempPointer]
		and	#0x00ff
		jne	$_b_branch
		inc	$.src
		break

	case	CoreCall_IfClear
		lda	[$.src]
		sta	$.tempPointer+0
		inc	$.src
		inc	$.src
		lda	[$.src]
		sta	$.tempPointer+2
		inc	$.src
		inc	$.src

		xba
		and	[$.tempPointer]
		and	#0x00ff
		jeq	$_b_branch
		inc	$.src
		break
		.unlocal	=tempPointer

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

	case	CoreCall_Remove
		// Remove some written bytes
		lda	[$.src]
		inc	$.src
		and	#0x00ff
		eor	#0xffff
		sec
		adc	$.writeAddr
		sta	$.writeAddr
		break

	case	CoreCall_WriteOriginal
		// Write original opcode
		ldy	#2
		lda	[$.readAddr]
		sta	[$.writeAddr]
		lda	[$.readAddr],y
		sta	[$.writeAddr],y

		// Add to write address
		ldy	$.thisOpcodeX2
		lda	$_Opcode__BytesTable_OneOrMore,y
		clc
		adc	$.writeAddr
		sta	$.writeAddr

		break

	case	CoreCall_ResetMemoryPrefix
		stz	$.memoryPrefix
		break

	case	CoreCall_PrgBankChange
		// Is safe PRG bank change enabled?
		andbne	$=RomInfo_CpuSettings, #_RomInfo_Cpu_SafePrgBankChange, $+b_1
			inc	$.src
			break
b_1:

		// Get range bit for the current address
		lda	$.readAddr
		jsr	$_Recompiler__Build_ConvertAddressToRangeBit

		// Compare to expected range change and static range
		and	[$.src]
		inc	$.src
		and	#0x00ff
		beq	$+b_1
			// Is range static? If not, add an open link jump
			and	$=RomInfo_StaticRanges
			bne	$+b_1
				// TODO: Test every possible output
				lda	$.readAddr
				clc
				adc	#3
				jsr	$_Recompiler__Build_OpcodeType_Jmp_FakeSource
b_1:
		break

	.unlocal	_pushFlags, _freeRegs, =src

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Recompiler__GetIOAccess
	// Entry: X = Original address, Y = Access type "iIOPort" (found in Macros.asm)
	// Return: A = Call address, ZeroBank = Bank for call address
Recompiler__GetIOAccess:
	// Load default bank address
	lda	#_IO__BANK/0x10000
	sta	$.DP_ZeroBank

	.macro	Recompiler__GetIOAccess_Compare		value, opcode, destination
		cmp	#_Zero+{0}
		{1}	$+b_skip__
			ldx	#_Zero+{2}
			jmp	$_Recompiler__GetIOAccess_Return
b_skip__:
	.endm

	// 2000-3fff
	txa
	cmp	#0x4000
	bcs	$+b_1
		and	#0xe007
		Recompiler__GetIOAccess_Compare		0x2000, bne, Recompiler__GetIOAccess_2000
		Recompiler__GetIOAccess_Compare		0x2001, bne, Recompiler__GetIOAccess_2001
		Recompiler__GetIOAccess_Compare		0x2002, bne, Recompiler__GetIOAccess_2002
		Recompiler__GetIOAccess_Compare		0x2003, bne, Recompiler__GetIOAccess_2003
		Recompiler__GetIOAccess_Compare		0x2004, bne, Recompiler__GetIOAccess_2004
		Recompiler__GetIOAccess_Compare		0x2005, bne, Recompiler__GetIOAccess_2005
		Recompiler__GetIOAccess_Compare		0x2006, bne, Recompiler__GetIOAccess_2006
		Recompiler__GetIOAccess_Compare		0x2007, bne, Recompiler__GetIOAccess_2007
		txa
b_1:

	// 4000-4017
	cmp	#0x4018
	jcs	$_b_skip4000
		cmp	#0x4008
		bcs	$+b_1
			Recompiler__GetIOAccess_Compare		0x4000, bne, Recompiler__GetIOAccess_4000
			Recompiler__GetIOAccess_Compare		0x4001, bne, Recompiler__GetIOAccess_4001
			Recompiler__GetIOAccess_Compare		0x4002, bne, Recompiler__GetIOAccess_4002
			Recompiler__GetIOAccess_Compare		0x4003, bne, Recompiler__GetIOAccess_4003
			Recompiler__GetIOAccess_Compare		0x4004, bne, Recompiler__GetIOAccess_4004
			Recompiler__GetIOAccess_Compare		0x4005, bne, Recompiler__GetIOAccess_4005
			Recompiler__GetIOAccess_Compare		0x4006, bne, Recompiler__GetIOAccess_4006
			Recompiler__GetIOAccess_Compare		0x4007, bne, Recompiler__GetIOAccess_4007
b_1:

		cmp	#0x4010
		bcs	$+b_1
			Recompiler__GetIOAccess_Compare		0x4008, bne, Recompiler__GetIOAccess_4008
			Recompiler__GetIOAccess_Compare		0x4009, bne, Recompiler__GetIOAccess_4009
			Recompiler__GetIOAccess_Compare		0x400a, bne, Recompiler__GetIOAccess_400a
			Recompiler__GetIOAccess_Compare		0x400b, bne, Recompiler__GetIOAccess_400b
			Recompiler__GetIOAccess_Compare		0x400c, bne, Recompiler__GetIOAccess_400c
			Recompiler__GetIOAccess_Compare		0x400d, bne, Recompiler__GetIOAccess_400d
			Recompiler__GetIOAccess_Compare		0x400e, bne, Recompiler__GetIOAccess_400e
			Recompiler__GetIOAccess_Compare		0x400f, bne, Recompiler__GetIOAccess_400f
b_1:

		Recompiler__GetIOAccess_Compare		0x4010, bne, Recompiler__GetIOAccess_4010
		Recompiler__GetIOAccess_Compare		0x4011, bne, Recompiler__GetIOAccess_4011
		Recompiler__GetIOAccess_Compare		0x4012, bne, Recompiler__GetIOAccess_4012
		Recompiler__GetIOAccess_Compare		0x4013, bne, Recompiler__GetIOAccess_4013
		Recompiler__GetIOAccess_Compare		0x4014, bne, Recompiler__GetIOAccess_4014
		Recompiler__GetIOAccess_Compare		0x4015, bne, Recompiler__GetIOAccess_4015
		Recompiler__GetIOAccess_Compare		0x4016, bne, Recompiler__GetIOAccess_4016
		Recompiler__GetIOAccess_Compare		0x4017, bne, Recompiler__GetIOAccess_4017
b_skip4000:

	// Do we have a mapper?
	txa
	ldx	$_Mapper_x2
	jmp	($_MapperTable_Main,x)

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
Recompiler__GetIOAccess_4016:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4016_a
		caseat	iIOPort_ldax	IO__r4016_a_x
		caseat	iIOPort_lday	IO__r4016_a_y
		caseat	iIOPort_ldai	IO__r4016_a_i
		caseat	iIOPort_sta		IO__w4016_a
		caseat	iIOPort_stx		IO__w4016_x
		caseat	iIOPort_sty		IO__w4016_y
		caseat	iIOPort_stax	IO__w4016_a_x
		caseat	iIOPort_stay	IO__w4016_a_y
		caseat	iIOPort_stai	IO__w4016_a_i
Recompiler__GetIOAccess_4017:
	iIOPort_InterfaceSwitch		IO__Error
		caseat	iIOPort_lda		IO__r4017_a
		caseat	iIOPort_ldai	IO__r4017_a_i
		caseat	iIOPort_sta		IO__w4017_a
		caseat	iIOPort_stx		IO__w4017_x
		caseat	iIOPort_sty		IO__w4017_y
		caseat	iIOPort_stax	IO__w4017_a_x
		caseat	iIOPort_stay	IO__w4017_a_y
		caseat	iIOPort_stai	IO__w4017_a_i

	// ---------------------------------------------------------------------------

	.mx	0x20
	.func	Recompiler__InitMapper
Recompiler__InitMapper:
	php

	rep	#0x10
	sep	#0x20
	ldx	$_Mapper_x2
	jsr	($_MapperTable_Init,x)

	plp
	return

	// ---------------------------------------------------------------------------

MapperTable_Main:
	.data16	_Recompiler__GetIOAccess_DefaultMapper
	.fill	0x3fe, 0xff

MapperTable_Init:
	.fill16	0x200, MapperTable_Init_Default

MapperTable_Init_Default:
	IOPort_InitEnd

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
	asl	a
	tax

	// Add 8 to each pointers lower than this value, assume carry always clear during the loop
	clc
	bra	$+b_loop_in
b_loop:
		lda	$=QuickFunction,x
		adc	$.Recompiler_FunctionList+9
		sta	$=QuickFunction,x
b_loop_in:
		dex
		dex
		bpl	$-b_loop

	return
	
	// ---------------------------------------------------------------------------

	.macro	Recompiler__CallFunction		CommentLock
		// A = Original address
		{0}lock
			ldx	$_SideStack_Available
			trapne
			tsx
			stx	$_SideStack_Available
			ldx	#_SIDE_STACK_TOP
			txs
		{0}unlock
		call	Recompiler__CallFunction
		ldx	$_SideStack_Available
		txs
		stz	$_SideStack_Available
	.endm

	.mx	0x00
	.func	Recompiler__CallFunction
	// Entry: A = Original address
	// Return: A = Y = index for known calls
Recompiler__CallFunction:
	.local	=originalFunction
	.local	_base, _add

	// Find this function's bank
	sta	$.originalFunction
	xba
	and	#0x00e0
	tax
	lda	$_Program_BankNum,x
	sta	$.originalFunction+2

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
	lda	$=QuickFunction,x
	sta	$.add
	adc	$.base
	sta	$.Recompiler_FunctionList+3
	
	// Find this function
	lda	$.originalFunction+0
	sta	[$.Recompiler_FunctionList]
	lda	$.originalFunction+2
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

		// Return function index
		clc
		adc	#3
		tay
		return

Recompiler__CallFunction_call:
	// Return function index
	clc
	adc	$.add
	clc
	adc	#3
	tay

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
