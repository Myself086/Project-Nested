
	.pushaddr
		Mapper_Main		1, Mapper1__Main
		Mapper_Init		1, Mapper1__Init

		.addr	=Mapper_Memory
Mapper1_temp:
		.fill	1
Mapper1_value:
		.fill	1
Mapper1_control:
		.fill	1
Mapper1_prg256:
		.fill	1
	.pulladdr

	.mx	0x00

Mapper1__Main:
	// Load current bank address
	ldx	#_Mapper1__Main/0x10000
	stx	$.DP_ZeroBank

	SelfMod_Begin
	SelfMod_IfSet		RomInfo_PrgBankNumMask, 0x10
	SelfMod_Do	+b_1
		IOPort_Compare	0xe000, bcc, Mapper1__e000
		IOPort_Compare	0xc000, bcc, Mapper1b__c000
		IOPort_Compare	0xa000, bcc, Mapper1b__a000
		IOPort_Compare	0x8000, bcc, Mapper1__8000
b_1:
	SelfMod_End

	// No sub-mapper
	IOPort_Compare	0xe000, bcc, Mapper1__e000
	IOPort_Compare	0xc000, bcc, Mapper1__c000
	IOPort_Compare	0xa000, bcc, Mapper1__a000
	IOPort_Compare	0x8000, bcc, Mapper1__8000

	// Nothing was found
	IOPort_CompareEnd

Mapper1__8000:
	iIOPort_InterfaceSwitch		Mapper1__Error
		caseat	iIOPort_sta		Mapper1__w8000_a
		caseat	iIOPort_stx		Mapper1__w8000_x
		caseat	iIOPort_sty		Mapper1__w8000_y
		caseat	iIOPort_stai	Mapper1__w8000_a_i
Mapper1__a000:
	iIOPort_InterfaceSwitch		Mapper1__Error
		caseat	iIOPort_sta		Mapper1__wa000_a
		caseat	iIOPort_stx		Mapper1__wa000_x
		caseat	iIOPort_sty		Mapper1__wa000_y
		caseat	iIOPort_stai	Mapper1__wa000_a_i
Mapper1__c000:
	iIOPort_InterfaceSwitch		Mapper1__Error
		caseat	iIOPort_sta		Mapper1__wc000_a
		caseat	iIOPort_stx		Mapper1__wc000_x
		caseat	iIOPort_sty		Mapper1__wc000_y
		caseat	iIOPort_stai	Mapper1__wc000_a_i
Mapper1__e000:
	iIOPort_InterfaceSwitch		Mapper1__Error
		caseat	iIOPort_sta		Mapper1__we000_a
		caseat	iIOPort_stx		Mapper1__we000_x
		caseat	iIOPort_sty		Mapper1__we000_y
		caseat	iIOPort_stai	Mapper1__we000_a_i

Mapper1b__a000:
	iIOPort_InterfaceSwitch		Mapper1__Error
		caseat	iIOPort_sta		Mapper1b__wa000_a
		caseat	iIOPort_stx		Mapper1b__wa000_x
		caseat	iIOPort_sty		Mapper1b__wa000_y
		caseat	iIOPort_stai	Mapper1b__wa000_a_i
Mapper1b__c000:
	iIOPort_InterfaceSwitch		Mapper1__Error
		caseat	iIOPort_sta		Mapper1b__wc000_a
		caseat	iIOPort_stx		Mapper1b__wc000_x
		caseat	iIOPort_sty		Mapper1b__wc000_y
		caseat	iIOPort_stai	Mapper1b__wc000_a_i

	//	-----------------------------------------------------------------------

	.mx	0x20
Mapper1__Init:
	// Reset shift
	lda	#0xf0
	sta	$_Mapper1_value

	// Reset PRG bank size
	lda	#0x60
	sta	$_Mapper1_control

	IOPort_InitEnd

	//	-----------------------------------------------------------------------

	.mx	0x30

Mapper1__Error:
	rtl

Mapper1__w8000_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		bit	#0x80
		bne	$+b_reset
		lsr	a
		ror	$_Mapper1_value
		bcc	$+b_2
			jsr	$=Mapper1__w8000_DoStuff2
			bra	$+b_1
b_reset:
			jsr	$=Mapper1__w8000_ResetBits
			bra	$+b_1
b_2:
		bpl	$+b_3
			sec
b_3:
		rol	a
b_1:
	CoreCall_End

Mapper1__w8000_ResetBits:
	// Reset shift and return
	xba
	lda	#0xf0
	sta	$_Mapper1_value
	xba
	rtl

Mapper1__w8000_x:
	stx	$_Mapper1_temp
	bra	$+Mapper1__w8000
Mapper1__w8000_y:
	sty	$_Mapper1_temp
	bra	$+Mapper1__w8000

Mapper1__w8000_a_i:
	sta	$_Mapper1_temp
	//bra	$+Mapper1__w8000
Mapper1__w8000:
	// Do we reset bits? Most likely not so we moved the code up
	bit	$_Mapper1_temp
	bmi	$-Mapper1__w8000_ResetBits

	// Shift bit
	lsr	$_Mapper1_temp
	ror	$_Mapper1_value
	bcs	$+Mapper1__w8000_DoStuff
	rtl

Mapper1__w8000_DoStuff2:
	// Fix A
	bmi	$+b_1
		clc
b_1:
	rol	a

Mapper1__w8000_DoStuff:
	php
	pha
	phx

	// Control (internal, $8000-$9FFF)
	// Bits: CPPMM
	// M = BG mirrors
	// P = Program bank mode
	// C = Chr ROM bank mode

	// Save value
	lda	$_Mapper1_value
	sta	$_Mapper1_control

	// Load mirrors: 1x1, 1x1+, 2x1, 1x2
	lsr	a
	lsr	a
	lsr	a
	and	#0x03
	tax
	lda	$=Mapper1__w8000_BGmirrors,x
	jsr	$=Gfx__NameTableMirrorChange

	// Reset bits
	lda	#0xf0
	sta	$_Mapper1_value

	plx
	pla
	plp
	rtl

Mapper1__w8000_BGmirrors:
	.data8	0, 4, 1, 2

	//	-----------------------------------------------------------------------

Mapper1__wa000_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		bit	#0x80
		bne	$+b_reset
		lsr	a
		ror	$_Mapper1_value
		bcc	$+b_2
			jsr	$=Mapper1__wa000_DoStuff2
			bra	$+b_1
b_reset:
			jsr	$=Mapper1__wa000_ResetBits
			bra	$+b_1
b_2:
		bpl	$+b_3
			sec
b_3:
		rol	a
b_1:
	CoreCall_End

Mapper1__wa000_ResetBits:
	// Reset shift and return
	xba
	lda	#0xf0
	sta	$_Mapper1_value
	xba
	rtl

Mapper1__wa000_x:
	stx	$_Mapper1_temp
	bra	$+Mapper1__wa000
Mapper1__wa000_y:
	sty	$_Mapper1_temp
	bra	$+Mapper1__wa000

Mapper1__wa000_a_i:
	sta	$_Mapper1_temp
	//bra	$+Mapper1__wa000
Mapper1__wa000:
	// Do we reset bits? Most likely not so we moved the code up
	bit	$_Mapper1_temp
	bmi	$-Mapper1__wa000_ResetBits

	// Shift bit
	lsr	$_Mapper1_temp
	ror	$_Mapper1_value
	bcs	$+Mapper1__wa000_DoStuff
	rtl

Mapper1__wa000_DoStuff2:
	// Fix A
	bmi	$+b_1
		clc
b_1:
	rol	a

Mapper1__wa000_DoStuff:
	xba

	// CHR bank 0 (internal, $A000-$BFFF)
	// Bits: CCCCC
	// C = Select 4 KB or 8 KB CHR bank at PPU $0000 (low bit ignored in 8 KB mode)

	// Load bits
	lda	$_Mapper1_value
	lsr	a
	lsr	a
	lsr	a

	// Is CHR in 8kb mode?
	bit	$_Mapper1_control
	bmi	$+b_2
		// 8kb mode
		ora	#0x01
		sta	$_CHR_1_NesBank
		and	#0xfe
b_2:
	// This 4kb
	sta	$_CHR_0_NesBank

	// Reset bits
	lda	#0xf0
	sta	$_Mapper1_value

	// Return
	xba
	rtl

	//	-----------------------------------------------------------------------


Mapper1b__wa000_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		bit	#0x80
		bne	$+b_reset
		lsr	a
		ror	$_Mapper1_value
		bcc	$+b_2
			jsr	$=Mapper1b__wa000_DoStuff2
			bra	$+b_1
b_reset:
			jsr	$=Mapper1b__wa000_ResetBits
			bra	$+b_1
b_2:
		bpl	$+b_3
			sec
b_3:
		rol	a
b_1:
	CoreCall_End

Mapper1b__wa000_ResetBits:
	// Reset shift and return
	xba
	lda	#0xf0
	sta	$_Mapper1_value
	xba
	rtl

Mapper1b__wa000_x:
	stx	$_Mapper1_temp
	bra	$+Mapper1b__wa000
Mapper1b__wa000_y:
	sty	$_Mapper1_temp
	bra	$+Mapper1b__wa000

Mapper1b__wa000_a_i:
	sta	$_Mapper1_temp
	//bra	$+Mapper1b__wa000
Mapper1b__wa000:
	// Do we reset bits? Most likely not so we moved the code up
	bit	$_Mapper1_temp
	bmi	$-Mapper1b__wa000_ResetBits

	// Shift bit
	lsr	$_Mapper1_temp
	ror	$_Mapper1_value
	bcs	$+Mapper1b__wa000_DoStuff
	rtl

Mapper1b__wa000_DoStuff2:
	// Fix A
	bmi	$+b_1
		clc
b_1:
	rol	a

Mapper1b__wa000_DoStuff:
	xba

	// CHR bank 0 (internal, $A000-$BFFF)
	// Bits: PSSxC
	// C = Select 4 KB CHR RAM bank at PPU $0000 (ignored in 8 KB mode)
	// S = Select 8 KB PRG RAM bank
	// P = Select 256 KB PRG ROM bank

	// Load bits
	lda	$_Mapper1_value
	lsr	a
	lsr	a
	lsr	a
	sta	$_IO_Temp

	// Is CHR in 8kb mode?
	and	#0x01
	bit	$_Mapper1_control
	bmi	$+b_2
		// 8kb mode
		ora	#0x01
		sta	$_CHR_1_NesBank
		and	#0xfe
b_2:
	// This 4kb
	sta	$_CHR_0_NesBank

	// Apply P bit
	Mapper1b__ChangePrg256

	// Reset bits
	lda	#0xf0
	sta	$_Mapper1_value

	// Return
	xba
	rtl

	//	-----------------------------------------------------------------------

Mapper1__wc000_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		bit	#0x80
		bne	$+b_reset
		lsr	a
		ror	$_Mapper1_value
		bcc	$+b_2
			jsr	$=Mapper1__wc000_DoStuff2
			bra	$+b_1
b_reset:
			jsr	$=Mapper1__wc000_ResetBits
			bra	$+b_1
b_2:
		bpl	$+b_3
			sec
b_3:
		rol	a
b_1:
	CoreCall_End
	
Mapper1__wc000_ResetBits:
	// Reset shift and return
	xba
	lda	#0xf0
	sta	$_Mapper1_value
	xba
	rtl

Mapper1__wc000_x:
	stx	$_Mapper1_temp
	bra	$+Mapper1__wc000
Mapper1__wc000_y:
	sty	$_Mapper1_temp
	bra	$+Mapper1__wc000

Mapper1__wc000_a_i:
	sta	$_Mapper1_temp
	//bra	$+Mapper1__wc000
Mapper1__wc000:
	// Do we reset bits? Most likely not so we moved the code up
	bit	$_Mapper1_temp
	bmi	$-Mapper1__wc000_ResetBits

	// Shift bit
	lsr	$_Mapper1_temp
	ror	$_Mapper1_value
	bcs	$+Mapper1__wc000_DoStuff
	rtl

Mapper1__wc000_DoStuff2:
	// Fix A
	bmi	$+b_1
		clc
b_1:
	rol	a

Mapper1__wc000_DoStuff:
	xba

	// CHR bank 1 (internal, $C000-$DFFF)
	// Bits: CCCCC
	// C = Select 4 KB CHR bank at PPU $1000 (ignored in 8 KB mode)

	// Load bits
	lda	$_Mapper1_value
	lsr	a
	lsr	a
	lsr	a

	// Is CHR in 8kb mode?
	bit	$_Mapper1_control
	bpl	$+b_2
		// 4kb mode
		sta	$_CHR_1_NesBank
b_2:
	// Nothing in 8kb mode

	// Reset bits
	lda	#0xf0
	sta	$_Mapper1_value

	// Return
	xba
	rtl

	//	-----------------------------------------------------------------------

Mapper1b__wc000_a:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		bit	#0x80
		bne	$+b_reset
		lsr	a
		ror	$_Mapper1_value
		bcc	$+b_2
			jsr	$=Mapper1b__wc000_DoStuff2
			bra	$+b_1
b_reset:
			jsr	$=Mapper1b__wc000_ResetBits
			bra	$+b_1
b_2:
		bpl	$+b_3
			sec
b_3:
		rol	a
b_1:
	CoreCall_End
	
Mapper1b__wc000_ResetBits:
	// Reset shift and return
	xba
	lda	#0xf0
	sta	$_Mapper1_value
	xba
	rtl

Mapper1b__wc000_x:
	stx	$_Mapper1_temp
	bra	$+Mapper1b__wc000
Mapper1b__wc000_y:
	sty	$_Mapper1_temp
	bra	$+Mapper1b__wc000

Mapper1b__wc000_a_i:
	sta	$_Mapper1_temp
	//bra	$+Mapper1b__wc000
Mapper1b__wc000:
	// Do we reset bits? Most likely not so we moved the code up
	bit	$_Mapper1_temp
	bmi	$-Mapper1b__wc000_ResetBits

	// Shift bit
	lsr	$_Mapper1_temp
	ror	$_Mapper1_value
	bcs	$+Mapper1b__wc000_DoStuff
	rtl

Mapper1b__wc000_DoStuff2:
	// Fix A
	bmi	$+b_1
		clc
b_1:
	rol	a

Mapper1b__wc000_DoStuff:
	xba

	// CHR bank 1 (internal, $C000-$DFFF)
	// Bits: PSSxC
	// C = Select 4 KB CHR RAM bank at PPU $1000 (ignored in 8 KB mode)
	// S = Select 8 KB PRG RAM bank (ignored in 8 KB mode)
	// P = Select 256 KB PRG ROM bank (ignored in 8 KB mode)

	// Load bits
	lda	$_Mapper1_value
	lsr	a
	lsr	a
	lsr	a
	sta	$_IO_Temp

	// Is CHR in 8kb mode?
	and	#0x01
	bit	$_Mapper1_control
	bpl	$+b_2
		// 4kb mode
		sta	$_CHR_1_NesBank

		// Apply P bit
		Mapper1b__ChangePrg256
b_2:
	// Nothing in 8kb mode

	// Reset bits
	lda	#0xf0
	sta	$_Mapper1_value

	// Return
	xba
	rtl

	//	-----------------------------------------------------------------------
	
	.mx	0x30

Mapper1__we000_a:
	CoreCall_Begin
	CoreCall_ResetMemoryPrefix
	CoreCall_CopyUpTo	+b_1
		bit	#0x80
		bne	$+b_reset
		lsr	a
		ror	$_Mapper1_value
		bcc	$+b_2
			jsr	$=Mapper1__we000_DoStuff2
			bra	$+b_1
b_reset:
			jsr	$=Mapper1__we000_ResetBits
			bra	$+b_1
b_2:
		bpl	$+b_3
			sec
b_3:
		rol	a
b_1:
	CoreCall_End

Mapper1__we000_ResetBits:
	// Reset shift and return
	xba
	lda	#0xf0
	sta	$_Mapper1_value
	xba
	rtl

Mapper1__we000_x:
	stx	$_Mapper1_temp
	bra	$+Mapper1__we000
Mapper1__we000_y:
	sty	$_Mapper1_temp
	bra	$+Mapper1__we000

Mapper1__we000_a_i:
	sta	$_Mapper1_temp
	//bra	$+Mapper1__we000
Mapper1__we000:
	// Do we reset bits? Most likely not so we moved the code up
	bit	$_Mapper1_temp
	bmi	$-Mapper1__we000_ResetBits
	
	// Shift bit
	lsr	$_Mapper1_temp
	ror	$_Mapper1_value
	bcs	$+Mapper1__we000_DoStuff
	rtl

Mapper1__we000_DoStuff2:
	// Fix A
	bmi	$+b_1
		clc
b_1:
	rol	a

Mapper1__we000_DoStuff:
	phx
	xba

	// PRG bank (internal, $E000-$FFFF)
	// Bits: RPPPP
	// P = Select 16 KB PRG ROM bank (low bit ignored in 32 KB mode)
	// R = PRG RAM chip enable (0: enabled; 1: disabled; ignored on MMC1A)

	// Which PRG mode?
	lda	$_Mapper1_control
	asl	a
	bmi	$+Mapper1__we000_16kb
		// 32kb mode

		// Load bits
		lda	$_Mapper1_value
		lsr	a
		lsr	a
		lsr	a
		and	#0x0e
		ora	$_Mapper1_prg256
		tax

		// Low range banks
		lda	$=RomInfo_BankLut,x
		sta	$_Program_Bank_0+2
		sta	$_Program_Bank_1+2
		stx	$_Program_BankNum_8000
		stx	$_Program_BankNum_a000

		// High range banks
		inx
		lda	$=RomInfo_BankLut,x
		sta	$_Program_Bank_2+2
		sta	$_Program_Bank_3+2
		stx	$_Program_BankNum_c000
		stx	$_Program_BankNum_e000

		// Done
		bra	$+Mapper1__we000_Return

Mapper1__we000_16kb:
	asl	a
	bpl	$+Mapper1__we000_16kb_high
		// 16kb low bank

		// Load bits
		lda	$_Mapper1_value
		lsr	a
		lsr	a
		lsr	a
		and	#0x0f
		ora	$_Mapper1_prg256
		tax

		// Low range banks
		lda	$=RomInfo_BankLut,x
		sta	$_Program_Bank_0+2
		sta	$_Program_Bank_1+2
		stx	$_Program_BankNum_8000
		stx	$_Program_BankNum_a000

		// High range banks
		lda	#0x0f
		ora	$_Mapper1_prg256
		tax
		lda	$=RomInfo_BankLut,x
		sta	$_Program_Bank_2+2
		sta	$_Program_Bank_3+2
		stx	$_Program_BankNum_c000
		stx	$_Program_BankNum_e000

		// Done
		bra	$+Mapper1__we000_Return

Mapper1__we000_16kb_high:
		// 16kb high bank

		// Load bits
		lda	$_Mapper1_value
		lsr	a
		lsr	a
		lsr	a
		and	#0x0f
		ora	$_Mapper1_prg256
		tax

		// High range banks
		lda	$=RomInfo_BankLut,x
		sta	$_Program_Bank_2+2
		sta	$_Program_Bank_3+2
		stx	$_Program_BankNum_c000
		stx	$_Program_BankNum_e000

		// Low range banks
		ldx	$_Mapper1_prg256
		lda	$=RomInfo_BankLut,x
		sta	$_Program_Bank_0+2
		sta	$_Program_Bank_1+2
		stx	$_Program_BankNum_8000
		stx	$_Program_BankNum_a000

Mapper1__we000_Return:
	// Reset bits
	lda	#0xf0
	sta	$_Mapper1_value

	// Reset active bank (TODO: Load the actual current active bank for later optimizations)
	stz	$_Memory_NesBank

	// Return
	xba
	plx
	rtl

	//	-----------------------------------------------------------------------

	.macro	Mapper1b__ChangePrg256
		lda	$_IO_Temp
		and	#0x10
		cmp	$_Mapper1_prg256
		beq	$+b_1__
			jsr	$_Mapper1b__ChangePrg256
b_1__:
	.endm

Mapper1b__ChangePrg256:
	sta	$_Mapper1_prg256
	phx

	.macro	Mapper1b__ChangePrg256_EorBank	bank, range
		lda	$_Program_BankNum_{1}
		eor	#0x10
		tax
		lda	$=RomInfo_BankLut,x
		sta	$_Program_Bank_{0}+2
		stx	$_Program_BankNum_{1}
	.endm

	Mapper1b__ChangePrg256_EorBank	0, 8000
	Mapper1b__ChangePrg256_EorBank	1, a000
	Mapper1b__ChangePrg256_EorBank	2, c000
	Mapper1b__ChangePrg256_EorBank	3, e000

	// Reset active bank
	stz	$_Memory_NesBank

	plx
	rts

	//	-----------------------------------------------------------------------
