
	.mx	0x30

	// ---------------------------------------------------------------------------

	.macro	Interpreter_ReadPC
		lda	($.pc)
	.endm

	.macro	Interpreter_AdcReadPC
		adc	($.pc)
	.endm

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

	.macro	Interpreter_IncPC16
		inc	$.pc
	.endm

	.macro	Interpreter_DoubleIncPC16	reg
		ld{0}	$.pc
		in{0}
		in{0}
		st{0}	$.pc
	.endm

	.macro	Interpreter_Do		command
		plp
		{0}
		php
	.endm

	.macro	Interpreter_Do2		command0, command1
		plp
		{0}
		{1}
		php
	.endm

	// ---------------------------------------------------------------------------

	.macro	Interpreter_LoadAddr		reg, indexReg, do0, do1
		.if	{1} == 0
		{
			rep	#0x30
			Interpreter_ReadPC
		}
		.else
		{
			ldy	$.{1}
			rep	#0x31
			tya
			Interpreter_AdcReadPC
		}
		Interpreter_DoubleIncPC16	y
		call	Interpreter__ReadByte
		//sep	#0x30
		Interpreter_Do2	"{2}", "{3}"
		.if	{0} != 0
		{
			sta	$.{0}
		}
		break
	.endm

	.macro	Interpreter_StoreAddr		reg, indexReg
		ldx	$.{0}
		.if	{1} == 0
		{
			rep	#0x30
			Interpreter_ReadPC
		}
		.else
		{
			ldy	$.{1}
			rep	#0x31
			tya
			Interpreter_AdcReadPC
		}
		Interpreter_DoubleIncPC16	y
		call	Interpreter__WriteByte
		sep	#0x30
		break
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
	rep	#0x30
	.mx	0x00
	unlock
	trap
	Exception	"Interpreter Failed{}{}{}The interpreter is not fully supported in this version. It attempted to execute opcode 0x{a:X} at address 0x{X:X}.{}{}This form of emulation is used for code located in WRAM."

	.mx	0x30

Interpreter__Execute_Switch:
	switch	0x100, Interpreter__Execute_Switch_Trap, Interpreter__Execute_Next
		case	0x4c	// JMP addr -------------------------------------------------------
			// Read destination
			Interpreter_ReadPCinc
			tax
			Interpreter_ReadPC

			// Is address pointing to ROM?
			bpl	$+b_else
				// Write address page
				stx	$.addr
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
				Interpreter_IncPC
				// Copy to PC
				stx	$.pc
				sta	$.pc+1
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
		case	0xa5	// LDA dp ---------------------------------------------------------
			Interpreter_ReadPCinc
			tax
			Interpreter_Do	"lda	$0x0000,x"
			sta	$.a
			break
		case	0xa9	// LDA #const -----------------------------------------------------
			Interpreter_Do	"Interpreter_ReadPC"
			sta	$.a
			Interpreter_IncPC
			break
		case	0xad	// LDA addr -------------------------------------------------------
			Interpreter_LoadAddr		a, 0, "tax", ""
			break
		case	0xb9	// LDA addr,y -----------------------------------------------------
			Interpreter_LoadAddr		a, y, "tax", ""
			break
		case	0xbd	// LDA addr,x -----------------------------------------------------
			Interpreter_LoadAddr		a, x, "tax", ""
			break
		case	0xa2	// LDX #const -----------------------------------------------------
			Interpreter_Do	"Interpreter_ReadPC"
			sta	$.x
			Interpreter_IncPC
			break
		case	0xa0	// LDY #const -----------------------------------------------------
			Interpreter_Do	"Interpreter_ReadPC"
			sta	$.y
			Interpreter_IncPC
			break
		case	0x48	// PHA ------------------------------------------------------------
			lda	$.a
			Interpreter_Do	"pha"
			break
		case	0x08	// PHP ------------------------------------------------------------
			Interpreter_Do	"php"
			break
		case	0x68	// PLA ------------------------------------------------------------
			Interpreter_Do	"pla"
			sta	$.a
			break
		case	0x28	// PLP ------------------------------------------------------------
			pla
			pla
			and	#0xc3
			ora	#0x30
			pha
			break
		case	0x40	// RTI ------------------------------------------------------------
			// Are we using native return from interrupt?
			lda	$=RomInfo_StackEmulation+1
			and	#.RomInfo_StackEmu_NativeReturnInterrupt/0x100
			beq	$+b_1
				// Native RTI

				// Fix registers
				lda	$.a
				ldx	$.x
				ldy	$.y
				// Fix DP
				pea	$0x0000
				pld
				// Return
				plp
				plp
				rtl
b_1:
			// Non-native RTI

			// Fix registers
			lda	$.a
			ldx	$.x
			ldy	$.y
			// Fix DP
			pea	$0x0000
			pld
			// Return
			plp
			jmp	$=JMPiU__FromRti
		case	0x8d	// STA addr -------------------------------------------------------
			Interpreter_StoreAddr		a, 0
			break
		case	0x99	// STA addr,y -----------------------------------------------------
			Interpreter_StoreAddr		a, y
			break
		case	0x9d	// STA addr,x -----------------------------------------------------
			Interpreter_StoreAddr		a, x
			break

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Interpreter__ReadByte
	// Entry: A = NES address, MX = Unknown
Interpreter__ReadByte:
	tay

	// Which range are we in?
	and	#0xe000
	xba
	tax
	jmp	($_Interpreter__ReadByte_Switch,x)

Interpreter__ReadByte_Switch_Trap:
	trap

Interpreter__ReadByte_Switch:
	switch	0x80, Interpreter__ReadByte_Switch_Trap, Interpreter__ReadByte_Switch_Trap
		case	0x00, 0x0f		// 0x00
			lda	$0x0000,y
			return

		case	0x10, 0x1f		// 0x20
		case	0x20, 0x2f		// 0x40
			tyx
			ldy	#_iIOPort_ldai*2
			call	Recompiler__GetIOAccess
			ldx	$.DP_ZeroBank-1
			stx	$_InterpretIO_Action+1
			sta	$_InterpretIO_Action
			sep	#0x30
			jsr	$=InterpretIO_Action_JMP
			return

			.macro	Interpreter__ReadByte_ChangeBank	bankRange
				sep	#0x20
				cmp	$_Memory_NesBank
				beq	$+b_1__
					sta	$_Memory_NesBank
					lda	$_{0}+2
					pha
					plb
b_1__:
				lda	$0x0000,y
				return
			.endm
		case	0x30, 0x3f		// 0x60
			Interpreter__ReadByte_ChangeBank	Program_Bank_Sram
		case	0x40, 0x4f		// 0x80
			Interpreter__ReadByte_ChangeBank	Program_Bank_0
		case	0x50, 0x5f		// 0xa0
			Interpreter__ReadByte_ChangeBank	Program_Bank_1
		case	0x60, 0x6f		// 0xc0
			Interpreter__ReadByte_ChangeBank	Program_Bank_2
		case	0x70, 0x7f		// 0xe0
			Interpreter__ReadByte_ChangeBank	Program_Bank_3

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Interpreter__WriteByte
	// Entry: A = NES address, X = Value, MX = Unknown
Interpreter__WriteByte:
	.local	_value
	stx	$.value
	tay

	// Which range are we in?
	and	#0xe000
	xba
	tax
	jmp	($_Interpreter__WriteByte_Switch,x)

Interpreter__WriteByte_Switch_Trap:
	trap

Interpreter__WriteByte_Switch:
	switch	0x80, Interpreter__WriteByte_Switch_Trap, Interpreter__WriteByte_Switch_Trap
		case	0x00, 0x0f		// 0x00
			sep	#0x20
			lda	$.value
			sta	$0x0000,y
			return

		case	0x10, 0x1f		// 0x20
		case	0x20, 0x2f		// 0x40
		case	0x40, 0x4f		// 0x80
		case	0x50, 0x5f		// 0xa0
		case	0x60, 0x6f		// 0xc0
		case	0x70, 0x7f		// 0xe0
			tyx
			ldy	#_iIOPort_stai*2
			call	Recompiler__GetIOAccess
			ldx	$.DP_ZeroBank-1
			stx	$_InterpretIO_Action+1
			sta	$_InterpretIO_Action
			lda	$.value
			sep	#0x30
			jsr	$=InterpretIO_Action_JMP
			return

			.macro	Interpreter__WriteByte_ChangeBank	bankRange
				sep	#0x20
				cmp	$_Memory_NesBank
				beq	$+b_1__
					sta	$_Memory_NesBank
					lda	$_{0}+2
					pha
					plb
b_1__:
				lda	$.value
				sta	$0x0000,y
				return
			.endm
		case	0x30, 0x3f		// 0x60
			Interpreter__WriteByte_ChangeBank	Program_Bank_Sram

	// ---------------------------------------------------------------------------
