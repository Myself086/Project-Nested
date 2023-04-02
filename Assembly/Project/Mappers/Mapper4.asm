
	.pushaddr
		Mapper_Main		4, Mapper4__Main

		.addr	=Mapper_Memory
Mapper4_BankSelect:
		.fill	1
Mapper4_BankValues:
		// 2 bytes per bank; [0] = current bank, [1] = non-zero when changed at least once
		.fill	12
Mapper4_IRQ_Latch:
		.fill	1
Mapper4_IRQ_Line:
		.fill	1
Mapper4_IRQ_Enabled:
		.fill	1
	.pulladdr

	.mx	0x00

Mapper4__Main:
	// Load current bank address
	ldx	#_Mapper1__Main/0x10000
	stx	$.DP_ZeroBank

	// Apply bit mask
	and	#0xe001
	
	IOPort_Compare	0xe000, bne, Mapper4__e000
	IOPort_Compare	0xe001, bne, Mapper4__e001
	IOPort_Compare	0xc000, bne, Mapper4__c000
	IOPort_Compare	0xc001, bne, Mapper4__c001
	IOPort_Compare	0xa000, bne, Mapper4__a000
	IOPort_Compare	0xa001, bne, Mapper4__a001
	IOPort_Compare	0x8000, bne, Mapper4__8000
	IOPort_Compare	0x8001, bne, Mapper4__8001

	IOPort_CompareEnd

	.mx	0x30

	//	-----------------------------------------------------------------------

Mapper4__Error:
	rtl

	//	-----------------------------------------------------------------------

	.macro	Mapper4__DirectIndexed0		reg, dest0, dest1
		php
		xba
		t{0}a
		lsr	a
		xba
		bcs	$+b_else__
			plp
			jmp	$_{1}
b_else__:
			plp
			jmp	$_{2}
	.endm

	.macro	Mapper4__DirectIndexed1		reg, dest0, dest1
		php
		xba
		t{0}a
		lsr	a
		xba
		bcc	$+b_else__
			plp
			jmp	$_{1}
b_else__:
			plp
			jmp	$_{2}
	.endm

	//	-----------------------------------------------------------------------

	// Bank select
Mapper4__8000:
	iIOPort_InterfaceSwitch		Mapper4__Error
		case	iIOPort_stax
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
			Mapper4__DirectIndexed0	x, Mapper4__8000_stai, Mapper4__8001_stai
		case	iIOPort_stay
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
			Mapper4__DirectIndexed0	y, Mapper4__8000_stai, Mapper4__8001_stai
		case	iIOPort_sty
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
			php
			xba
			sty	$_IO_temp
			tya
			bra	$+b_in
		case	iIOPort_stx
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
			php
			xba
			stx	$_IO_temp
			txa
			//bra	$+b_in
b_in:
			// Detect changes
			//lda	$_IO_temp
			eor	$_Mapper4_BankSelect

			// Test high bits
			bit	#0xc0
			bne	$+b_1
				// Save current value
				lda	$_IO_temp
				sta	$_Mapper4_BankSelect

				// Return
				xba
				plp
				rtl
b_1:

			// Bit 7, CHR bank rule
			bit	#0x80
			beq	$+b_1
				pha

				lda	$_IO_temp
				rol	a
				rol	a
				sta	$_IO_MapperChrBankSwap

				pla
b_1:

			// Bit 6, PRG bank rule
			bit	#0x40
			beq	$+b_1
				pha
				phx

				// Swap PRG bank rule
				lda	$_Program_BankNum_8000
				ldx	$_Program_BankNum_c000
				sta	$_Program_BankNum_c000
				stx	$_Program_BankNum_8000

				// Reload Snes bank numbers
				//ldx	$_Program_BankNum_8000
				lda	$=RomInfo_BankLut_80,x
				sta	$_Program_Bank_0+2
				ldx	$_Program_BankNum_c000
				lda	$=RomInfo_BankLut_c0,x
				sta	$_Program_Bank_2+2

				// Reset active bank
				stz	$_Memory_NesBank

				plx
				pla
b_1:

			// Save current value
			lda	$_IO_temp
			sta	$_Mapper4_BankSelect

			// Return
			xba
			plp
			rtl
		case	iIOPort_sta
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_UseN
			CoreCall_UseZ
			CoreCall_Push
			CoreCall_CopyUpTo	+b_1
				lock

				// Detect changes
				eor	$_Mapper4_BankSelect

				// Test high bits
				bit	#0xc0
				beq	$+b_else
					jsr	$=Mapper4__w8000_ai_in
					bra	$+b_2
b_else:
					// Save current value
					eor	$_Mapper4_BankSelect
					sta	$_Mapper4_BankSelect
b_2:
				unlock
b_1:
			CoreCall_IfFreeP	+b_1
				CoreCall_Remove	1
b_1:
			CoreCall_Pull
			CoreCall_End
		case	iIOPort_stai
Mapper4__8000_stai:
			php
			lock

			// Detect changes
			eor	$_Mapper4_BankSelect

			// Test high bits
			bit	#0xc0
			bne	$+b_1
				// Save current value
				eor	$_Mapper4_BankSelect
				sta	$_Mapper4_BankSelect

				// Return
				plp
				rtl

Mapper4__w8000_ai_in:
			// Extra push from partial inline code (TODO: Remove the use of carry)
			php
b_1:

			// Bit 7, CHR bank rule
			bit	#0x80
			beq	$+b_1
				pha

				eor	$_Mapper4_BankSelect
				rol	a
				rol	a
				sta	$_IO_MapperChrBankSwap

				pla
b_1:

			// Bit 6, PRG bank rule
			bit	#0x40
			beq	$+b_1
				pha
				phx

				// Swap PRG bank rule
				lda	$_Program_BankNum_8000
				ldx	$_Program_BankNum_c000
				sta	$_Program_BankNum_c000
				stx	$_Program_BankNum_8000

				// Reload Snes bank numbers
				//ldx	$_Program_BankNum_8000
				lda	$=RomInfo_BankLut_80,x
				sta	$_Program_Bank_0+2
				ldx	$_Program_BankNum_c000
				lda	$=RomInfo_BankLut_c0,x
				sta	$_Program_Bank_2+2

				// Reset active bank
				stz	$_Memory_NesBank

				plx
				pla
b_1:

			// Save current value
			eor	$_Mapper4_BankSelect
			sta	$_Mapper4_BankSelect

			// Return
			plp
			rtl

	//	-----------------------------------------------------------------------
	
	// Bank value
Mapper4__8001:
	iIOPort_InterfaceSwitch		Mapper4__Error
		case	iIOPort_stax
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
			Mapper4__DirectIndexed1	x, Mapper4__8000_stai, Mapper4__8001_stai
		case	iIOPort_stay
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
			Mapper4__DirectIndexed1	y, Mapper4__8000_stai, Mapper4__8001_stai
		case	iIOPort_stx
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
			php
			stx	$_IO_temp
			bra	$+b_in
		case	iIOPort_sty
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
			php
			sty	$_IO_temp
			bra	$+b_in
		case	iIOPort_sta
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
		case	iIOPort_stai
Mapper4__8001_stai:
			php
			sta	$_IO_temp
b_in:
			xba
			phx

			// Get bank number and execute code for this bank
			lda	$_Mapper4_BankSelect
			asl	a
			tax
			jmp	($_Mapper4__8001_Switch,x)
Mapper4__8001_SwitchEnd:

			.macro	Mapper4__8001_ExitMac
				// Return
				plx
				xba
				plp
				rtl
			.endm
			Mapper4__8001_ExitMac

Mapper4__8001_Switch:
	.macro	Mapper4__8001_Switch_RepeatMac
		.data16	_Mapper4__8001_Switch_0, _Mapper4__8001_Switch_1, _Mapper4__8001_Switch_2, _Mapper4__8001_Switch_3
		.data16	_Mapper4__8001_Switch_4, _Mapper4__8001_Switch_5, _Mapper4__8001_Switch_6, _Mapper4__8001_Switch_7
		.data16	_Mapper4__8001_Switch_0, _Mapper4__8001_Switch_1, _Mapper4__8001_Switch_2, _Mapper4__8001_Switch_3
		.data16	_Mapper4__8001_Switch_4, _Mapper4__8001_Switch_5, _Mapper4__8001_Switch_6, _Mapper4__8001_Switch_7
	.endm
	Mapper4__8001_Switch_RepeatMac
	Mapper4__8001_Switch_RepeatMac
	Mapper4__8001_Switch_RepeatMac
	Mapper4__8001_Switch_RepeatMac
	Mapper4__8001_Switch_RepeatMac
	Mapper4__8001_Switch_RepeatMac
	Mapper4__8001_Switch_RepeatMac
	Mapper4__8001_Switch_RepeatMac

			// Send CHR change to our NMI queue as follow:
			//		ChrBank(u8 highBitsVramAddr, u16 highBitsSourceAddr, u8 highBitsLength)
			.macro	Mapper4__8001_Switch_CHRmac		ChrSetIndex, CommentAnd
				lda	$_IO_temp
				{1}and	#0xfe
				sta	$_CHR_{0}_NesBank

				Mapper4__8001_ExitMac
			.endm

Mapper4__8001_Switch_0:
			Mapper4__8001_Switch_CHRmac		0, ""
Mapper4__8001_Switch_1:
			Mapper4__8001_Switch_CHRmac		1, ""
Mapper4__8001_Switch_2:
			Mapper4__8001_Switch_CHRmac		2, "//"
Mapper4__8001_Switch_3:
			Mapper4__8001_Switch_CHRmac		3, "//"
Mapper4__8001_Switch_4:
			Mapper4__8001_Switch_CHRmac		4, "//"
Mapper4__8001_Switch_5:
			Mapper4__8001_Switch_CHRmac		5, "//"
Mapper4__8001_Switch_6:
			// Reset active bank
			stz	$_Memory_NesBank

			// Semi-dynamic PRG bank
			ldx	$_IO_temp

			bit	$_Mapper4_BankSelect
			bvs	$+b_else
				// Low range
				lda	$=RomInfo_BankLut_80,x
				sta	$_Program_Bank_0+2
				stx	$_Program_BankNum_8000

				Mapper4__8001_ExitMac
b_else:
				// High range
				lda	$=RomInfo_BankLut_c0,x
				sta	$_Program_Bank_2+2
				stx	$_Program_BankNum_c000

				Mapper4__8001_ExitMac
Mapper4__8001_Switch_7:
			// Reset active bank
			stz	$_Memory_NesBank

			// Static PRG bank
			ldx	$_IO_temp
			lda	$=RomInfo_BankLut_a0,x

			sta	$_Program_Bank_1+2
			stx	$_Program_BankNum_a000

			Mapper4__8001_ExitMac

	//	-----------------------------------------------------------------------

	// Mirroring
Mapper4__a000:
	iIOPort_InterfaceSwitch		Mapper4__Error
		case	iIOPort_stax
			Mapper4__DirectIndexed0	x, Mapper4__a000_stai, Mapper4__a001_stai
		case	iIOPort_stay
			Mapper4__DirectIndexed0	y, Mapper4__a000_stai, Mapper4__a001_stai
		case	iIOPort_stx
			stx	$_IO_temp
			bra	$+b_in
		case	iIOPort_sty
			sty	$_IO_temp
			bra	$+b_in
		case	iIOPort_sta
		case	iIOPort_stai
Mapper4__a000_stai:
			sta	$_IO_temp
b_in:
			php
			pha
			phx

			// Load mirrors: 2x1, 1x2
			lda	$_IO_temp
			and	#0x01
			inc	a
			jsr	$=Gfx__NameTableMirrorChange

			plx
			pla
			plp
			rtl

	//	-----------------------------------------------------------------------

	// SRAM protection
Mapper4__a001:
	iIOPort_InterfaceSwitch		Mapper4__Error
		case	iIOPort_stax
			Mapper4__DirectIndexed1	x, Mapper4__a000_stai, Mapper4__a001_stai
		case	iIOPort_stay
			Mapper4__DirectIndexed1	y, Mapper4__a000_stai, Mapper4__a001_stai
		case	iIOPort_stx
		case	iIOPort_sty
		case	iIOPort_sta
			CoreCall_Begin
			CoreCall_End
		case	iIOPort_stai
Mapper4__a001_stai:
			// TODO
			rtl

	//	-----------------------------------------------------------------------

	// IRQ latch
Mapper4__c000:
	iIOPort_InterfaceSwitch		Mapper4__Error
		case	iIOPort_stax
			Mapper4__DirectIndexed0	x, Mapper4__c000_stai, Mapper4__c001_stai
		case	iIOPort_stay
			Mapper4__DirectIndexed0	y, Mapper4__c000_stai, Mapper4__c001_stai
		case	iIOPort_stx
			CoreCall_Begin
			CoreCall_CopyUpTo	+b_1
				stx	$_Mapper4_IRQ_Latch
b_1:
			CoreCall_End

		case	iIOPort_sty
			CoreCall_Begin
			CoreCall_CopyUpTo	+b_1
				sty	$_Mapper4_IRQ_Latch
b_1:
			CoreCall_End
			rtl

		case	iIOPort_sta
			CoreCall_Begin
			CoreCall_CopyUpTo	+b_1
				sta	$_Mapper4_IRQ_Latch
b_1:
			CoreCall_End
			rtl

		case	iIOPort_stai
Mapper4__c000_stai:
			sta	$_Mapper4_IRQ_Latch
			rtl

	//	-----------------------------------------------------------------------

	// IRQ reload
Mapper4__c001:
	iIOPort_InterfaceSwitch		Mapper4__Error
		case	iIOPort_stax
			Mapper4__DirectIndexed1	x, Mapper4__c000_stai, Mapper4__c001_stai
		case	iIOPort_stay
			Mapper4__DirectIndexed1	y, Mapper4__c000_stai, Mapper4__c001_stai
		case	iIOPort_stx
		case	iIOPort_sty
		case	iIOPort_sta
			CoreCall_Begin
			CoreCall_UseA8
			CoreCall_UseN
			CoreCall_UseV
			CoreCall_UseZ
			CoreCall_UseC
			CoreCall_Push
			CoreCall_CopyUpTo	+b_1
				// Calculate next IRQ hit
				lda	$_Scanline
				cmp	#0x01
				adc	$_Mapper4_IRQ_Latch
				clc
				adc	#0
				SelfMod_QuickCopy	RomInfo_IrqOffset, 8, -1
				sta	$_Mapper4_IRQ_Line
				and	$_Mapper4_IRQ_Enabled
				sta	$_Scanline_IRQ
b_1:
			CoreCall_Pull
			CoreCall_End
		case	iIOPort_stai
Mapper4__c001_stai:
			php
			xba

			//lda	$_Mapper4_IRQ_Latch
			//inc	a
			//sta	$_Mapper4_IRQ_Line
			//and	$_Mapper4_IRQ_Enabled
			//sta	$_Scanline_IRQ

			// Calculate next IRQ hit
			lda	$_Scanline
			cmp	#0x01
			adc	$_Mapper4_IRQ_Latch
			clc
			adc	#0
			SelfMod_QuickCopy	RomInfo_IrqOffset, 8, -1
			sta	$_Mapper4_IRQ_Line
			and	$_Mapper4_IRQ_Enabled
			sta	$_Scanline_IRQ

			xba
			plp
			rtl

	//	-----------------------------------------------------------------------

	// IRQ disable
Mapper4__e000:
	iIOPort_InterfaceSwitch		Mapper4__Error
		case	iIOPort_stax
			Mapper4__DirectIndexed0	x, Mapper4__e000_stai, Mapper4__e001_stai
		case	iIOPort_stay
			Mapper4__DirectIndexed0	y, Mapper4__e000_stai, Mapper4__e001_stai
		case	iIOPort_stx
		case	iIOPort_sty
		case	iIOPort_sta
			CoreCall_Begin
			CoreCall_CopyUpTo	+b_1
				stz	$_Scanline_IRQ
				stz	$_Mapper4_IRQ_Enabled
b_1:
			CoreCall_End

		case	iIOPort_stai
Mapper4__e000_stai:
			stz	$_Scanline_IRQ
			stz	$_Mapper4_IRQ_Enabled
			rtl

	//	-----------------------------------------------------------------------

	// IRQ enable
Mapper4__e001:
	iIOPort_InterfaceSwitch		Mapper4__Error
		case	iIOPort_stax
			Mapper4__DirectIndexed1	x, Mapper4__e000_stai, Mapper4__e001_stai
		case	iIOPort_stay
			Mapper4__DirectIndexed1	y, Mapper4__e000_stai, Mapper4__e001_stai
		case	iIOPort_stx
		case	iIOPort_sty
		case	iIOPort_sta
			CoreCall_Begin
			CoreCall_UseA8
			CoreCall_UseN
			CoreCall_UseZ
			CoreCall_Push
			CoreCall_CopyUpTo	+b_1
				lda	#0xff
				sta	$_Mapper4_IRQ_Enabled
				lda	$_Mapper4_IRQ_Line
				sta	$_Scanline_IRQ
b_1:
			CoreCall_Pull
			CoreCall_End

		case	iIOPort_stai
Mapper4__e001_stai:
			php
			xba

			lda	#0xff
			sta	$_Mapper4_IRQ_Enabled
			lda	$_Mapper4_IRQ_Line
			sta	$_Scanline_IRQ

			xba
			plp
			rtl

	//	-----------------------------------------------------------------------
