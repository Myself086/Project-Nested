
	.pushaddr
		Mapper_Main		3, Mapper3__Main
	.pulladdr

	.mx	0x00

Mapper3__Main:
	// Load current bank address
	ldx	#_Mapper3__Main/0x10000
	stx	$.DP_ZeroBank

	// Apply bit mask
	and	#0x8000
	
	IOPort_Compare	0x8000, bne, Mapper3__8000

	IOPort_CompareEnd

	.mx	0x30

	//	-----------------------------------------------------------------------

Mapper3__Error:
	rtl

	//	-----------------------------------------------------------------------

	// Bank select
Mapper3__8000:
	iIOPort_InterfaceSwitch		Mapper3__Error
		case	iIOPort_sty
			CoreCall_Begin
			CoreCall_CopyUpTo	+b_1
				sty	$_CHR_0_NesBank
b_1:
			CoreCall_End
		case	iIOPort_stx
			CoreCall_Begin
			CoreCall_CopyUpTo	+b_1
				stx	$_CHR_0_NesBank
b_1:
			CoreCall_End
		case	iIOPort_sta
		case	iIOPort_stax
		case	iIOPort_stay
			CoreCall_Begin
			CoreCall_CopyUpTo	+b_1
				sta	$_CHR_0_NesBank
b_1:
			CoreCall_End
		case	iIOPort_stai
			php
			pha
			//bra	$+b_in
b_in:

			sta	$_CHR_0_NesBank

			// Return
			pla
			plp
			rtl

