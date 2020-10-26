
	.pushaddr
		.addr	=MapperTable+2*2
		.data16	_Mapper2__Main
	.pulladdr

	.mx	0x00

Mapper2__Main:
	// Load current bank address
	ldx	#_Mapper2__Main/0x10000
	stx	$.DP_ZeroBank

	// Apply bit mask
	and	#0x8000
	
	IOPort_Compare	0x8000, bne, Mapper2__8000

	IOPort_CompareEnd

	.mx	0x30

	//	-----------------------------------------------------------------------

Mapper2__Error:
	rtl

	//	-----------------------------------------------------------------------

	// Bank select
Mapper2__8000:
	iIOPort_InterfaceSwitch		Mapper2__Error
		case	iIOPort_sty
			php
			phx
			tyx
			bra	$+b_in
		case	iIOPort_stx
			php
			phx
			bra	$+b_in
		case	iIOPort_sta
		case	iIOPort_stax
		case	iIOPort_stay
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

			// Return
			xba
			plx
			plp
			rtl

