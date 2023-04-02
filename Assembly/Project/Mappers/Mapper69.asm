
	.pushaddr
		Mapper_Main		69, Mapper69__Main
		Mapper_Init		69, Mapper69__Init

		.addr	=Mapper_Memory
Mapper69_Command:
		.fill	1
Mapper69_AudioRegister:
		.fill	1
Mapper69_IRQ_Ctrl:
		.fill	1
Mapper69_IRQ_Counter:
		.fill	2
	.pulladdr

	.mx	0x00

Mapper69__Main:
	// Load current bank address
	ldx	#_Mapper69__Main/0x10000
	stx	$.DP_ZeroBank

	// Apply bit mask
	and	#0xe000

	IOPort_Compare	0x8000, bne, Mapper69__8000
	IOPort_Compare	0xa000, bne, Mapper69__a000
	IOPort_Compare	0xc000, bne, Mapper69__c000
	IOPort_Compare	0xe000, bne, Mapper69__e000

	IOPort_CompareEnd

	.mx	0x30

	//	-----------------------------------------------------------------------

Mapper69__Error:
	rtl

	//	-----------------------------------------------------------------------

Mapper69__Init:
	lda	#0xff
	sta	$_Program_BankNum_6000

	IOPort_InitEnd

	//	-----------------------------------------------------------------------

	// Command Register
Mapper69__8000:
	iIOPort_InterfaceSwitch		Mapper69__Error
		case	iIOPort_sty
			CoreCall_Begin
			CoreCall_CopyUpTo	+b_1
				sty	$_Mapper69_Command
b_1:
			CoreCall_End
		case	iIOPort_stx
			CoreCall_Begin
			CoreCall_CopyUpTo	+b_1
				stx	$_Mapper69_Command
b_1:
			CoreCall_End
		case	iIOPort_sta
		case	iIOPort_stax
		case	iIOPort_stay
			CoreCall_Begin
			CoreCall_CopyUpTo	+b_1
				sta	$_Mapper69_Command
b_1:
			CoreCall_End
		case	iIOPort_stai
			sta	$_Mapper69_Command
			rtl

	//	-----------------------------------------------------------------------

	// Parameter Register
Mapper69__a000:
	iIOPort_InterfaceSwitch		Mapper69__Error
		case	iIOPort_sty
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
			php
			sty	$_IO_temp
			bra	$+b_in
		case	iIOPort_stx
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
			php
			stx	$_IO_temp
			bra	$+b_in
		case	iIOPort_sta
		case	iIOPort_stax
		case	iIOPort_stay
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
		case	iIOPort_stai
			php
			sta	$_IO_temp
b_in:
			lock
			xba
			phx

			// Get command number and execute code for this command
			lda	$_Mapper69_Command
			asl	a
			tax
			jmp	($_Mapper69__a000_Switch,x)


			.macro	Mapper69__a000_ExitMac
				// Return
				plx
				xba
				plp
				rtl
			.endm

Mapper69__a000_Switch:
	.macro	Mapper69__a000_Switch_RepeatMac
		.data16	_Mapper69__a000_Switch_0, _Mapper69__a000_Switch_1, _Mapper69__a000_Switch_2, _Mapper69__a000_Switch_3
		.data16	_Mapper69__a000_Switch_4, _Mapper69__a000_Switch_5, _Mapper69__a000_Switch_6, _Mapper69__a000_Switch_7
		.data16	_Mapper69__a000_Switch_8, _Mapper69__a000_Switch_9, _Mapper69__a000_Switch_a, _Mapper69__a000_Switch_b
		.data16	_Mapper69__a000_Switch_c, _Mapper69__a000_Switch_d, _Mapper69__a000_Switch_e, _Mapper69__a000_Switch_f
	.endm
	.repeat	8, Mapper69__a000_Switch_RepeatMac

	.macro	Mapper69__a000_Switch_CHRmac		ChrSetIndex
		lda	$_IO_temp
		sta	$_CHR_{0}_NesBank

		Mapper69__a000_ExitMac
	.endm

Mapper69__a000_Switch_0:
	Mapper69__a000_Switch_CHRmac	0
Mapper69__a000_Switch_1:
	Mapper69__a000_Switch_CHRmac	1
Mapper69__a000_Switch_2:
	Mapper69__a000_Switch_CHRmac	2
Mapper69__a000_Switch_3:
	Mapper69__a000_Switch_CHRmac	3
Mapper69__a000_Switch_4:
	Mapper69__a000_Switch_CHRmac	4
Mapper69__a000_Switch_5:
	Mapper69__a000_Switch_CHRmac	5
Mapper69__a000_Switch_6:
	Mapper69__a000_Switch_CHRmac	6
Mapper69__a000_Switch_7:
	Mapper69__a000_Switch_CHRmac	7


Mapper69__a000_Switch_8:
	bit	$_IO_temp
	bvc	$+b_else
		// RAM
		bmi	$+b_else2
			// RAM disabled
			lda	#0xff
			sta	$_Program_BankNum_6000
			stz	$_Program_Bank_Sram+2
			Mapper69__a000_ExitMac
b_else2:
			// RAM enabled
			lda	#0xff
			sta	$_Program_BankNum_6000
			lda	#0xb0
			sta	$_Program_Bank_Sram+2
			Mapper69__a000_ExitMac
b_else:
		phy

		// ROM
		.vstack		_VSTACK_START
		rmx	#0x04
		phd
		lda	#_VSTACK_PAGE
		tcd

		// Get SRAM bank
		lda	$_IO_temp
		and	#0x003f
		pha
		call	RomCache__GetNesBank
		pla

		smx	#0x34						// 8-bit mode + interrupt disabled
		stx	$_Program_Bank_Sram+2
		sta	$_Program_BankNum_6000

		pld
		ply
		Mapper69__a000_ExitMac


Mapper69__a000_Switch_9:
	// Reset active bank
	stz	$_Memory_NesBank

	// Change bank
	ldx	$_IO_temp
	lda	$=RomInfo_BankLut_80,x
	sta	$_Program_Bank_0+2
	stx	$_Program_BankNum_8000

	Mapper69__a000_ExitMac


Mapper69__a000_Switch_a:
	// Reset active bank
	stz	$_Memory_NesBank

	// Change bank
	ldx	$_IO_temp
	lda	$=RomInfo_BankLut_a0,x
	sta	$_Program_Bank_1+2
	stx	$_Program_BankNum_a000

	Mapper69__a000_ExitMac


Mapper69__a000_Switch_b:
	// Reset active bank
	stz	$_Memory_NesBank

	// Change bank
	ldx	$_IO_temp
	lda	$=RomInfo_BankLut_c0,x
	sta	$_Program_Bank_2+2
	stx	$_Program_BankNum_c000

	Mapper69__a000_ExitMac


Mapper69__a000_Switch_c:
	// Load mirrors: 2x1, 1x2, 1x1, 1x1+
	lda	$_IO_temp
	lsr	a
	lsr	a
	lsr	a
	and	#0x03
	tax
	lda	$=Mapper69__a000_BGmirrors,x
	jsr	$=Gfx__NameTableMirrorChange
	Mapper69__a000_ExitMac

Mapper69__a000_BGmirrors:
	.data8	1, 2, 0, 4


Mapper69__a000_Switch_d:
	lda	$_IO_temp
	sta	$_Mapper69_IRQ_Ctrl
	and	#0x81
	eor	#0x81
	bne	$+b_1
		// Enable IRQ
		lda	$_Mapper69_IRQ_Counter+0
		sta	$0x4204
		lda	$_Mapper69_IRQ_Counter+1
		sta	$0x4205
		lda	#113						// Actual value should be 113.66
		sta	$0x4206						// Wait 16 cycles before reading the result
		nop
		nop
		lda	$_Scanline
		bne	$+b_2
			// Emulating vblank
			lda	#.Zero-22
b_2:
		cmp	#0x01
		adc	$0x4214
		clc
		adc	#0
		SelfMod_QuickCopy	RomInfo_IrqOffset, 8, -1
		sta	$_Scanline_IRQ
b_1:
	Mapper69__a000_ExitMac


Mapper69__a000_Switch_e:
	lda	$_IO_temp
	sta	$_Mapper69_IRQ_Counter+0
	Mapper69__a000_ExitMac


Mapper69__a000_Switch_f:
	lda	$_IO_temp
	sta	$_Mapper69_IRQ_Counter+1
	Mapper69__a000_ExitMac

	//	-----------------------------------------------------------------------

	// Audio Register Select
Mapper69__c000:
	iIOPort_InterfaceSwitch		Mapper69__Error
		case	iIOPort_sty
			CoreCall_Begin
			CoreCall_CopyUpTo	+b_1
				sty	$_Mapper69_AudioRegister
b_1:
			CoreCall_End
		case	iIOPort_stx
			CoreCall_Begin
			CoreCall_CopyUpTo	+b_1
				stx	$_Mapper69_AudioRegister
b_1:
			CoreCall_End
		case	iIOPort_sta
		case	iIOPort_stax
		case	iIOPort_stay
			CoreCall_Begin
			CoreCall_CopyUpTo	+b_1
				sta	$_Mapper69_AudioRegister
b_1:
			CoreCall_End
		case	iIOPort_stai
			sta	$_Mapper69_AudioRegister
			rtl

	//	-----------------------------------------------------------------------

	// Audio Register Write (TODO)
Mapper69__e000:
	iIOPort_InterfaceSwitch		Mapper69__Error
		case	iIOPort_sty
		case	iIOPort_stx
			rtl
		case	iIOPort_sta
		case	iIOPort_stax
		case	iIOPort_stay
			rtl
		case	iIOPort_stai
			rtl

	//	-----------------------------------------------------------------------
