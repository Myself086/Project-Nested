
	.mx	0x30

	// ---------------------------------------------------------------------------

	.macro	Interpreter_ReadPC
		lda	[$.pc]
	.endm

	.macro	Interpreter_AdcReadPC
		adc	[$.pc]
	.endm

	.macro	Interpreter_ReadPCinc
		lda	[$.pc]
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
		.mx	0x30
		plp
		{0}
		php
	.endm

	.macro	Interpreter_Do2		command0, command1
		.mx	0x30
		plp
		{0}
		{1}
		php
	.endm

	.macro	Interpreter_Do3		command0, command1, command2
		.mx	0x30
		plp
		{0}
		{1}
		{2}
		php
	.endm

	.macro	Interpreter_Do4		command0, command1, command2, command3
		.mx	0x30
		plp
		{0}
		{1}
		{2}
		{3}
		php
	.endm

	// ---------------------------------------------------------------------------

	.macro	Interpreter_CmdReg			reg, do0, do1
		lda	$.{0}
		Interpreter_Do2		"{1}", "{2}"
		sta	$.{0}
	.endm

	.macro	Interpreter_LoadDp			reg, indexReg, do0, do1
		.if	{1} == 0
		{
			Interpreter_ReadPC
		}
		.else
		{
			lda	$.{1}
			clc
			Interpreter_AdcReadPC
		}
		Interpreter_IncPC
		tax
		Interpreter_Do3		"lda $0x0000,x", "{2}", "{3}"
		.if	{0} != 0
		{
			sta	$.{0}
		}
		break
	.endm

	.macro	Interpreter_StoreDp			reg, indexReg
		.if	{1} == 0
		{
			Interpreter_ReadPC
		}
		.else
		{
			lda	$.{1}
			clc
			Interpreter_AdcReadPC
		}
		Interpreter_IncPC
		tax
		lda	$.{0}
		sta	$0x0000,x
		break
	.endm

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

	.macro	Interpreter_LoadIndY		reg, do0, do1
		Interpreter_ReadPCinc
		tax
		ldy	$.y
		rep	#0x31
		tya
		adc	$0x0000,x
		call	Interpreter__ReadByte
		//sep	#0x30
		Interpreter_Do2	"{1}", "{2}"
		.if	{0} != 0
		{
			sta	$.{0}
		}
		break
	.endm

	.macro	Interpreter_StoreIndY		reg
		Interpreter_ReadPCinc
		tax
		ldy	$.y
		rep	#0x31
		tya
		adc	$0x0000,x
		ldx	$.{0}
		call	Interpreter__WriteByte
		sep	#0x30
		break
	.endm

	.macro	Interpreter_LoadXInd		reg, do0, do1	// UNTESTED
		lda	$.x
		clc
		Interpreter_AdcReadPC
		Interpreter_IncPC
		tax
		rep	#0x31
		lda	$0x0000,x
		call	Interpreter__ReadByte
		//sep	#0x30
		Interpreter_Do2	"{1}", "{2}"
		.if	{0} != 0
		{
			sta	$.{0}
		}
		break
	.endm

	.macro	Interpreter_StoreXInd		reg				// UNTESTED
		lda	$.x
		clc
		Interpreter_AdcReadPC
		Interpreter_IncPC
		tax
		rep	#0x31
		lda	$0x0000,x
		ldx	$.{0}
		call	Interpreter__WriteByte
		sep	#0x30
		break
	.endm

	.macro	Interpreter_RmwDp			index, opcode
		// Calculate target address
		.if	{0} == 0
		{
			Interpreter_ReadPC
		}
		.else
		{
			ldy	$.{0}
			tya
			clc
			Interpreter_AdcReadPC
		}
		Interpreter_IncPC
		tax
		Interpreter_Do	"{1} $0x0000,x"
	.endm

	.macro	Interpreter_RmwAddr			index, opcode
		// Calculate target address
		.if	{0} == 0
		{
			rep	#0x30
			.mx	0x00
			Interpreter_ReadPC
		}
		.else
		{
			ldy	$.{0}
			rep	#0x31
			.mx	0x00
			tya
			Interpreter_AdcReadPC
		}
		Interpreter_DoubleIncPC16	y

		// Address must be in range 0x0000-0x1fff or 0x6000-0x7fff
		tax
		sep	#0x20
		.mx	0x20
		xba
		and	#0xe0
		beq	$+b_1__
			cmp	#0x60
			beq	$+b_2__
				jmp	$_interpreter__Execute_RmwTrap
b_2__:
			// Change DB if necessary
			cmp	$_Memory_NesBank
			beq	$+b_2__
				sta	$_Memory_NesBank
				lda	$_Program_Bank_Sram+2
				pha
				plb
b_2__:
b_1__:
		stx	$.temp
		Interpreter_Do4	"rep #0x10", "ldx $.temp", "{1} $0x0000,x", "sep #0x10"
	.endm

	// ---------------------------------------------------------------------------

	.macro	Interpreter_Cmp				reg
		eor	#0xff
		sec
		adc	$.{0}
	.endm

	.macro	Interpreter_Sbc				reg
		eor	#0xff
		adc	$.{0}
	.endm

	.macro	Interpreter_Br				flag, value
		lda	#{0}
		and	$1,s
		.if	{1} != 0
		{
			beq	$+b_1__
		}
		.else
		{
			bne	$+b_1__
		}
			// Take branch
			Interpreter_ReadPC
			rep	#0x21
			.mx	0x10
			and	#0x00ff
			adc	#0x7f80
			eor	#0x7f80
			adc	$.pc
			sta	$.pc
			sep	#0x30
			.mx	0x30
b_1__:
		Interpreter_IncPC
	.endm

	.macro	Interpreter_Bit
		sta	$.temp
		lda	$.a
		bit	$.temp
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
	.local	=pc
	pla
	sta	$.pc+0
	pla
	sta	$.pc+1
	lda	$_Program_Bank_Sram+2			// Support PRG RAM
	sta	$.pc+2

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
	ldx	$.pc
	dex
	unlock
	trap
	Exception	"Interpreter Failed{}{}{}The interpreter is not fully supported in this version. It attempted to execute opcode 0x{a:X} at address 0x{X:X}.{}{}This form of emulation is used for code located in WRAM."

interpreter__Execute_RmwTrap:
	rep	#0x30
	.mx	0x00
	ldx	$.pc
	unlock
	trap
	Exception	"Interpreter RMW Failed{}{}{}The interpreter attempted to execute a read-modify-write to I/O from address 0x{X:X}.{}{}This form of emulation is used for code located in WRAM."

	.mx	0x30

Interpreter__Execute_Switch:
	switch	0x100, Interpreter__Execute_Switch_Trap, Interpreter__Execute_Next
		// ADC ... macro below ------------------------------------------------------------
		// AND ... macro below ------------------------------------------------------------
		// ASL ... macro below ------------------------------------------------------------
		case	0x0a	// ASL a ----------------------------------------------------------
			Interpreter_Do				"asl $.a"
			break
		case	0x90	// BCC ------------------------------------------------------------
			Interpreter_Br				0x01, 0
			break
		case	0xb0	// BCS ------------------------------------------------------------
			Interpreter_Br				0x01, 1
			break
		case	0xf0	// BEQ ------------------------------------------------------------
			Interpreter_Br				0x02, 1
			break
		case	0x30	// BMI ------------------------------------------------------------
			Interpreter_Br				0x80, 1
			break
		case	0xd0	// BNE ------------------------------------------------------------
			Interpreter_Br				0x02, 0
			break
		case	0x10	// BPL ------------------------------------------------------------
			Interpreter_Br				0x80, 0
			break
		case	0x50	// BVC ------------------------------------------------------------
			Interpreter_Br				0x40, 0
			break
		case	0x70	// BVS ------------------------------------------------------------
			Interpreter_Br				0x40, 1
			break
		case	0x24	// BIT dp ---------------------------------------------------------		UNTESTED
			Interpreter_LoadDp			0, 0, "Interpreter_Bit", ""
			break
		case	0x2c	// BIT addr -------------------------------------------------------		UNTESTED
			Interpreter_LoadAddr		0, 0, "Interpreter_Bit", ""
			break
		case	0x18	// CLC ------------------------------------------------------------
			Interpreter_Do				"clc"
			break
		case	0xd8	// CLD ------------------------------------------------------------
			// No effect on NES
			break
		case	0x58	// CLI ------------------------------------------------------------
			lda	#0xff
			sta	$_InterruptFlag_6502
			break
		case	0xb8	// CLV ------------------------------------------------------------
			Interpreter_Do				"clv"
			break
		// CMP ... macro below ------------------------------------------------------------
		case	0xe0	// CPX #const -----------------------------------------------------
			Interpreter_ReadPC
			Interpreter_Do				"Interpreter_Cmp x"
			Interpreter_IncPC
			break
		case	0xe4	// CPX dp ---------------------------------------------------------
			Interpreter_LoadDp			0, 0, "Interpreter_Cmp x", ""
			break
		case	0xec	// CPX addr -------------------------------------------------------
			Interpreter_LoadAddr		0, 0, "Interpreter_Cmp x", ""
			break
		case	0xc0	// CPY #const -----------------------------------------------------
			Interpreter_ReadPC
			Interpreter_Do				"Interpreter_Cmp y"
			Interpreter_IncPC
			break
		case	0xc4	// CPY dp ---------------------------------------------------------
			Interpreter_LoadDp			0, 0, "Interpreter_Cmp y", ""
			break
		case	0xcc	// CPY addr -------------------------------------------------------
			Interpreter_LoadAddr		0, 0, "Interpreter_Cmp y", ""
			break
		// DEC ... macro below ------------------------------------------------------------
		case	0xca	// DEX ------------------------------------------------------------
			Interpreter_Do				"dec $.x"
			break
		case	0x88	// DEY ------------------------------------------------------------
			Interpreter_Do				"dec $.y"
			break
		// EOR ... macro below ------------------------------------------------------------
		// INC ... macro below ------------------------------------------------------------
		case	0xe8	// INX ------------------------------------------------------------
			Interpreter_Do				"inc $.x"
			break
		case	0xc8	// INY ------------------------------------------------------------
			Interpreter_Do				"inc $.y"
			break
		case	0x4c	// JMP addr -------------------------------------------------------
			// Read destination
			Interpreter_ReadPCinc
			tax
			Interpreter_ReadPC

Interpreter__Execute_from_jsr_addr:
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
				lock
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
			lock
			tcd
			lda	$_temp+1
			jmp	[$_JMPiU_Action]
			.mx	0x30
		case	0x20	// JSR addr -------------------------------------------------------
			// Are we using native return address?
			lda	$=RomInfo_StackEmulation
			and	#.RomInfo_StackEmu_NativeReturn
			beq	$+b_1
				// Native return

				// Read destination and push PC
				ply						// Pull P
				Interpreter_ReadPCinc
				tax
				Interpreter_ReadPCinc
				pei	($.pc)

				phk
				pea	$_Interpreter__Execute_Return-1
				phy						// Push P
				ora	#0					// Refresh flags based on MSB
				jmp	$_Interpreter__Execute_from_jsr_addr
Interpreter__Execute_Return:
				php

				// Change DP
				pea	$_VSTACK_PAGE
				pld

				// Keep registers
				sta	$.a
				stx	$.x
				sty	$.y

				// Get new PC address
				ply									// Pull P
				pla
				sta	$.pc+0
				pla
				sta	$.pc+1
				lda	$_Program_Bank_Sram+2			// Support PRG RAM
				sta	$.pc+2
				phy									// Push P

				jmp	$_Interpreter__Execute_Next
b_1:
			// Non-native return

			// Read destination and push PC
			ply						// Pull P
			Interpreter_ReadPCinc
			tax
			pei	($.pc)
			Interpreter_ReadPC

			phy						// Push P
			jmp	$_Interpreter__Execute_from_jsr_addr
		// LDA ... macro below ------------------------------------------------------------
		case	0xa2	// LDX #const -----------------------------------------------------
			Interpreter_Do	"Interpreter_ReadPC"
			sta	$.x
			Interpreter_IncPC
			break
		case	0xa6	// LDX dp ---------------------------------------------------------
			Interpreter_LoadDp			x, 0, "", ""
			break
		case	0xae	// LDX addr -------------------------------------------------------
			Interpreter_LoadAddr		x, 0, "tax", ""
			break
		case	0xb6	// LDX dp,y -------------------------------------------------------
			Interpreter_LoadDp			x, y, "", ""
			break
		case	0xbe	// LDX addr,y -----------------------------------------------------
			Interpreter_LoadAddr		x, y, "tax", ""
			break
		case	0xa0	// LDY #const -----------------------------------------------------
			Interpreter_Do	"Interpreter_ReadPC"
			sta	$.y
			Interpreter_IncPC
			break
		case	0xa4	// LDY dp ---------------------------------------------------------
			Interpreter_LoadDp			y, 0, "", ""
			break
		case	0xac	// LDY addr -------------------------------------------------------
			Interpreter_LoadAddr		y, 0, "tax", ""
			break
		case	0xb4	// LDY dp,x -------------------------------------------------------
			Interpreter_LoadDp			y, x, "", ""
			break
		case	0xbc	// LDY addr,x -----------------------------------------------------
			Interpreter_LoadAddr		y, x, "tax", ""
			break
		// LSR ... macro below ------------------------------------------------------------
		case	0x4a	// LSR a ----------------------------------------------------------
			Interpreter_Do				"lsr $.a"
			break
		case	0xea	// NOP ------------------------------------------------------------
			break
		// ORA ... macro below ------------------------------------------------------------
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
		case	0x2a	// ROL a ----------------------------------------------------------
			Interpreter_Do				"rol $.a"
			break
		case	0x6a	// ROR a ----------------------------------------------------------
			Interpreter_Do				"ror $.a"
			break
		// ROL ... macro below ------------------------------------------------------------
		// ROR ... macro below ------------------------------------------------------------
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
		case	0x60	// RTS ------------------------------------------------------------
			// Are we using native return address?
			lda	$=RomInfo_StackEmulation
			and	#.RomInfo_StackEmu_NativeReturn
			beq	$+b_1
				// Native return

				// Fix registers
				lda	$.a
				ldx	$.x
				ldy	$.y
				// Fix DP
				pea	$0x0000
				pld
				// Return
				plp
				rtl
b_1:
			// Non-native return

			// Fix registers
			lda	$.a
			ldx	$.x
			ldy	$.y
			// Fix DP
			pea	$0x0000
			pld
			// Return
			plp
			jmp	$=JMPiU__FromStack
		// SBC ... macro below ------------------------------------------------------------
		case	0x38	// SEC ------------------------------------------------------------
			Interpreter_Do				"sec"
			break
		case	0xf8	// SED ------------------------------------------------------------
			// No effect on NES
			break
		case	0x78	// SEi ------------------------------------------------------------
			stz	$_InterruptFlag_6502
			break
		case	0x81	// STA (dp,x) -----------------------------------------------------
			Interpreter_StoreXInd		a
			break
		case	0x85	// STA dp ---------------------------------------------------------
			Interpreter_StoreDp			a, 0
			break
		case	0x8d	// STA addr -------------------------------------------------------
			Interpreter_StoreAddr		a, 0
			break
		case	0x91	// STA (dp),y -----------------------------------------------------
			Interpreter_StoreIndY		a
			break
		case	0x95	// STA dp,x -------------------------------------------------------
			Interpreter_StoreDp			a, x
			break
		case	0x99	// STA addr,y -----------------------------------------------------
			Interpreter_StoreAddr		a, y
			break
		case	0x9d	// STA addr,x -----------------------------------------------------
			Interpreter_StoreAddr		a, x
			break
		case	0x86	// STX dp ---------------------------------------------------------
			Interpreter_StoreDp			x, 0
			break
		case	0x8e	// STX addr -------------------------------------------------------
			Interpreter_StoreAddr		x, 0
			break
		case	0x96	// STX dp,y -------------------------------------------------------
			Interpreter_StoreDp			x, y
			break
		case	0x84	// STY dp ---------------------------------------------------------
			Interpreter_StoreDp			y, 0
			break
		case	0x8c	// STY addr -------------------------------------------------------
			Interpreter_StoreAddr		y, 0
			break
		case	0x94	// STY dp,x -------------------------------------------------------
			Interpreter_StoreDp			y, x
			break
		case	0xaa	// TAX ------------------------------------------------------------
			Interpreter_Do2				"lda $.a", "sta $.x"
			break
		case	0xa8	// TAY ------------------------------------------------------------
			Interpreter_Do2				"lda $.a", "sta $.y"
			break
		case	0xba	// TSX ------------------------------------------------------------
			Interpreter_Do2				"tsx", "stx $.x"
			break
		case	0x8a	// TXA ------------------------------------------------------------
			Interpreter_Do2				"lda $.x", "sta $.a"
			break
		case	0x9a	// TXS ------------------------------------------------------------
			ply
			tsc
			lda	$.x
			tcs
			phy
			break
		case	0x98	// TYA ------------------------------------------------------------
			Interpreter_Do2				"lda $.y", "sta $.a"
			break


		.macro	Interpreter_CmdBig7		baseOpcode, reg, doDp, doAddr
			.def	baseOp__	{0}
			case	baseOp__+0x01		// cmd (dp,x) -----------------------------------------------------		UNTESTED
				Interpreter_LoadXInd		{1}, "{3}", ""
				break
			case	baseOp__+0x05		// cmd dp ---------------------------------------------------------
				Interpreter_LoadDp			{1}, 0, "{2}", ""
				break
			case	baseOp__+0x09		// cmd #const -----------------------------------------------------
				Interpreter_Do2				"Interpreter_ReadPC", "{2}"
				.if	{1} != 0
				{
					sta	$.{1}
				}
				Interpreter_IncPC
				break
			case	baseOp__+0x0d		// cmd addr -------------------------------------------------------
				Interpreter_LoadAddr		{1}, 0, "{3}", ""
				break
			case	baseOp__+0x11		// cmd (dp),y -----------------------------------------------------
				Interpreter_LoadIndY		{1}, "{3}", ""
				break
			case	baseOp__+0x15		// cmd dp,x -------------------------------------------------------
				Interpreter_LoadDp			{1}, x, "{2}", ""
				break
			case	baseOp__+0x19		// cmd addr,y -----------------------------------------------------
				Interpreter_LoadAddr		{1}, y, "{3}", ""
				break
			case	baseOp__+0x1d		// cmd addr,x -----------------------------------------------------
				Interpreter_LoadAddr		{1}, x, "{3}", ""
				break
		.endm
		Interpreter_CmdBig7		0x00, a, "ora $.a", "ora $.a"
		Interpreter_CmdBig7		0x20, a, "and $.a", "and $.a"
		Interpreter_CmdBig7		0x40, a, "eor $.a", "eor $.a"
		Interpreter_CmdBig7		0x60, a, "adc $.a", "adc $.a"
		Interpreter_CmdBig7		0xa0, a, "", "tax"
		Interpreter_CmdBig7		0xc0, 0, "Interpreter_Cmp a", "Interpreter_Cmp a"
		Interpreter_CmdBig7		0xe0, a, "Interpreter_Sbc a", "Interpreter_Sbc a"


		.macro	Interpreter_CmdRmw		baseOpcode, opcode
			.def	baseOp__	{0}
			case	baseOp__+0x06		// ASL dp ---------------------------------------------------------
				Interpreter_RmwDp			0, "{1}"
				break
			case	baseOp__+0x0e		// ASL addr -------------------------------------------------------
				Interpreter_RmwAddr			0, "{1}"
				break
			case	baseOp__+0x16		// ASL dp,x -------------------------------------------------------
				Interpreter_RmwDp			x, "{1}"
				break
			case	baseOp__+0x1e		// ASL addr,x -----------------------------------------------------
				Interpreter_RmwAddr			x, "{1}"
				break
		.endm
		Interpreter_CmdRmw		0x00, "asl"
		Interpreter_CmdRmw		0x20, "rol"
		Interpreter_CmdRmw		0x40, "lsr"
		Interpreter_CmdRmw		0x60, "ror"
		Interpreter_CmdRmw		0xc0, "dec"
		Interpreter_CmdRmw		0xe0, "inc"

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Interpreter__ReadByte
	// Entry: A = NES address
	// Return: mx = Unknown
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
	// Entry: A = NES address, X = Value
	// Return: mx = Unknown
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
