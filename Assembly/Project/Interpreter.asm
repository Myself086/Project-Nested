
	.mx	0x30

	// ---------------------------------------------------------------------------

	.macro	Interpreter_ReadPCinc
		lda	($.pc)
		inc	$.pc
		bne	$+b_1__
			inc	$.pc+1
b_1__:
	.endm

	.macro	Interpreter_IncPC
		inc	$.pc
		bne	$+b_1__
			inc	$.pc+1
b_1__:
	.endm

	// ---------------------------------------------------------------------------

	.misalign	0x100, 0xff
	.misalign	0x100, 0x00

	// Entry: s1 = 16-bit destination for PC
Interpreter__Execute:
	// Change DP
	.vstack		_VSTACK_START
	pea	$_VSTACK_PAGE
	pld

	// Keep registers
	.local	.a, .x, .y
	sta	$.a
	stx	$.x
	sty	$.y

	// Get new PC address
	.local	_pc
	pla
	sta	$.pc+0
	pla
	sta	$.pc+1

	// Internal variables
	.local	=addr
	.local	_temp

Interpreter__Execute_Next:
	// Load next instruction
	Interpreter_ReadPCinc
	asl	a
	tax
	bcs	$+b_1
	jmp	($_Interpreter__Execute_Switch,x)
b_1:
	jmp	($_Interpreter__Execute_Switch+0x100,x)

Interpreter__Execute_SwitchEnd:
	// Return
	pea	$0x0000
	pld
	plp
	rtl


interpreter__Execute_Switch_Trap:
	// Opcode not supported
	ror	a
	unlock
	trap
	Exception	"Interpreter Failed{}{}{}The interpreter is not fully supported in this version. It attempted to execute opcode 0x{a:X}.{}{}This form of emulation is used for code located in WRAM."

Interpreter__Execute_Switch:
	switch	0x100, Interpreter__Execute_Switch_Trap, Interpreter__Execute_Next
		case	0x4c	// JMP addr -------------------------------------------------------
			// Read destination
			Interpreter_ReadPCinc
			sta	$.addr
			Interpreter_ReadPCinc

			// Is address pointing to ROM?
			ora	#0
			bpl	$+b_else
				// Write address page
				sta	$.addr+1
				// Use indirect JMP
				lda	$.a
				ldx	$.x
				ldy	$.y
				sta	$_IO_Temp
				//php
				rep	#0x20
				.mx	0x10
				lda	$.addr
				and	#0xe0ff
				xba
				sta	$_JMPiU_Action
				lda	#0
				tcd
				lda	$_addr+1
				jmp	[$_JMPiU_Action]
				.mx	0x30
b_else:
				// Copy to PC
				sta	$.pc+1
				lda	$.addr
				sta	$.pc
				break

		case	0x6c	// JMP (addr) -----------------------------------------------------
			// Read indirect address
			Interpreter_ReadPCinc
			sta	$.addr
			Interpreter_ReadPCinc
			sta	$.addr+1
			and	#0xe0
			tax
			lda	$_Program_Bank+2,x
			sta	$.addr+2
			// Read destination (with page wrapping)
			lda	[$.addr]
			sta	$.temp
			inc	$.addr
			lda	[$.addr]
			sta	$.temp+1

			// Use indirect JMP
			lda	$.a
			ldx	$.x
			ldy	$.y
			sta	$_IO_Temp
			//php
			rep	#0x20
			.mx	0x10
			lda	$.temp
			and	#0xe0ff
			xba
			sta	$_JMPiU_Action
			lda	#0
			tcd
			lda	$_temp+1
			jmp	[$_JMPiU_Action]
			.mx	0x30

