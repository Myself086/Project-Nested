
	.pushaddr
		.addr	=MapperTable+1*2
		.data16	_Mapper1__Main

		.addr	=Mapper_Memory
Mapper1_temp:
		.fill	1
Mapper1_value:
		.fill	1
Mapper1_control:
		.fill	1
Mapper1_chrbank0:
		.fill	1
Mapper1_chrbank1:
		.fill	1
Mapper1_prgbank:
		.fill	1
	.pulladdr

	.mx	0x00

Mapper1__Main:
	// Load current bank address
	ldx	#_Mapper1__Main/0x10000
	stx	$.DP_ZeroBank

	// Is it 0xe000?
	cmp	#0xe000
	bcc	$+Mapper1__Main_SkipE000
		ldx	#_Mapper1__e000
		jmp	$=Recompiler__GetIOAccess_ReturnMapper
Mapper1__Main_SkipE000:

	// Is it 0xc000?
	cmp	#0xc000
	bcc	$+Mapper1__Main_SkipC000
		ldx	#_Mapper1__c000
		jmp	$=Recompiler__GetIOAccess_ReturnMapper
Mapper1__Main_SkipC000:

	// Is it 0xa000?
	cmp	#0xa000
	bcc	$+Mapper1__Main_SkipA000
		ldx	#_Mapper1__a000
		jmp	$=Recompiler__GetIOAccess_ReturnMapper
Mapper1__Main_SkipA000:

	// Is it 0x8000?
	cmp	#0x8000
	bcc	$+Mapper1__Main_Skip8000
		ldx	#_Mapper1__8000
		jmp	$=Recompiler__GetIOAccess_ReturnMapper
Mapper1__Main_Skip8000:

	// Nothing was found
	jmp	$=Recompiler__GetIOAccess_DefaultMapper

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
		tax

		// Snes side banks
		lda	$=RomInfo_BankLut,x
		sta	$_Program_Bank_0+2
		sta	$_Program_Bank_1+2
		lda	$=RomInfo_BankLut+1,x
		sta	$_Program_Bank_2+2
		sta	$_Program_Bank_3+2

		// Nes side banks
		stx	$_Program_BankNum_8000
		stx	$_Program_BankNum_a000
		inx
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
		tax

		// Snes side banks
		lda	$=RomInfo_BankLut,x
		sta	$_Program_Bank_0+2
		sta	$_Program_Bank_1+2
		lda	$=RomInfo_BankLut+0xf
		sta	$_Program_Bank_2+2
		sta	$_Program_Bank_3+2

		// Nes side banks
		stx	$_Program_BankNum_8000
		stx	$_Program_BankNum_a000
		lda	#0x0f
		sta	$_Program_BankNum_c000
		sta	$_Program_BankNum_e000

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
		tax

		// Snes side banks
		lda	$=RomInfo_BankLut,x
		sta	$_Program_Bank_2+2
		sta	$_Program_Bank_3+2
		lda	$=RomInfo_BankLut+0x0
		sta	$_Program_Bank_0+2
		sta	$_Program_Bank_1+2

		// Nes side banks
		stx	$_Program_BankNum_c000
		stx	$_Program_BankNum_e000
		stz	$_Program_BankNum_8000
		stz	$_Program_BankNum_a000

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
