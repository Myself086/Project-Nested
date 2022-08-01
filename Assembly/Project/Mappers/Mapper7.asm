
	.pushaddr
		.addr	=MapperTable+7*2
		.data16	_Mapper7__Main
	.pulladdr

	.mx	0x00

Mapper7__Main:
	// Load current bank address
	ldx	#_Mapper7__Main/0x10000
	stx	$.DP_ZeroBank

	// Apply bit mask
	and	#0x8000
	
	IOPort_Compare	0x8000, bne, Mapper7__8000

	IOPort_CompareEnd

	.mx	0x30

	//	-----------------------------------------------------------------------

Mapper7__Error:
	rtl

	//	-----------------------------------------------------------------------

	// Bank select
Mapper7__8000:
	iIOPort_InterfaceSwitch		Mapper7__Error
		case	iIOPort_sty
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
			php
			phx
			tyx
			bra	$+b_in
		case	iIOPort_stx
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
			php
			phx
			bra	$+b_in
		case	iIOPort_sta
		case	iIOPort_stax
		case	iIOPort_stay
			CoreCall_Begin
			CoreCall_ResetMemoryPrefix
			CoreCall_Continue
		case	iIOPort_stai
			php
			phx
			tax
			//bra	$+b_in
b_in:
			xba

			// Reset active bank
			stz	$_Memory_NesBank

			// Translate bank number
			lda	$=RomInfo_BankLut_80,x

			// Change bank
			sta	$_Program_Bank_0+2
			stx	$_Program_BankNum_8000
			sta	$_Program_Bank_1+2
			stx	$_Program_BankNum_a000
			sta	$_Program_Bank_2+2
			stx	$_Program_BankNum_c000
			sta	$_Program_Bank_3+2
			stx	$_Program_BankNum_e000

			// Return
			xba
			plx
			plp
			rtl

