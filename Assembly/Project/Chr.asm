
	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Chr__LoadInitialBank
Chr__LoadInitialBank:
	// Ingore this if we are using CHR RAM
	lda	$=RomInfo_ChrBankLut_lo
	ora	$=RomInfo_ChrBankLut_hi
	bne	$+b_1
		return
b_1:

	sep	#0x20
	.mx	0x20

	.macro	Chr__LoadInitialBank_Mac	VramAddress
		// Set Vram address
		stz	$0x2115
		ldy	#_Zero+{0}
		sty	$0x2116

		// Set the DMA
		ldy	#0x1800
		sty	$0x4300
		stz	$0x4302
		lda	$=RomInfo_ChrBankLut_lo
		sta	$0x4303
		lda	$=RomInfo_ChrBankLut_hi
		sta	$0x4304
		ldy	#0x2000
		sty	$0x4305
		lda	#0x01
		sta	$0x420b
	.endm

	Chr__LoadInitialBank_Mac	0x0000
	Chr__LoadInitialBank_Mac	0x4000
	Chr__LoadInitialBank_Mac	0x6000

	rep	#0x20
	.mx	0x00

	return

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Chr__Initialize
Chr__Initialize:
	// Are we using CHR RAM?
	lda	$=RomInfo_ChrBankLut
	ora	$=RomInfo_ChrBankLut+0x100
	bne	$+b_1
		// Are we cloning CHR RAM?
		lda	$=RomInfo_ChrRamClone-1
		bpl	$+b_2
			// Allocate memory for the CHR RAM clone
			lda	#_ChrRam_CONSTBANK/0x10000
			ldx	#0x2000
			call	Memory__AllocInBank
			// Return: A = Bank number, X = Memory address, Y = HeapStack pointer
			txa
			smx	#0x30
			ora	#0
			trapne
			xba
			sta	$_ChrRam_Page

			// Copy "read" code to RAM
			ldx	#.ChrRam_Read_End-ChrRam_Read
b_loop:
				lda	$=IO__r2007_ChrRamReadCode,x
				sta	$_ChrRam_Read,x
				// Next
				dex
				bpl	$-b_loop

			// Copy "write" code to RAM
			ldx	#.ChrRam_Write_End-ChrRam_Write
b_loop:
				lda	$=IO__r2007_ChrRamWriteCode,x
				sta	$_ChrRam_Write,x
				// Next
				dex
				bpl	$-b_loop

			smx	#0x00
b_2:
		return
b_1:

	// Load list of CHR bank sizes
	.local	=list, .vramPage
	ldx	$_Mapper_x2
	lda	$=Chr__Initialize_Switch,x
	sta	$.list

	sep	#0x21
	.mx	0x20
	lda	#.Chr__Initialize_Switch/0x10000
	sta	$.list+2

	.local	.chrPageSize
	lda	$=RomInfo_ChrBankLut_lo+1
	sbc	$=RomInfo_ChrBankLut_lo+0
	bne	$+b_1
		// Default size in case they both point to the same page
		lda	#0x20
b_1:
	sta	$.chrPageSize

	ldy	#0
	stz	$.vramPage
b_loop:
		// Store VRAM address
		lda	$.vramPage
		sta	$_CHR_0_VramPage,y

		// Store default banks (using software division)
		//lda	$.vramPage
		ldx	#0xffff
		sec
b_loop2:
			inx
			sbc	$.chrPageSize
			bcs	$-b_loop2
		txa
		sta	$_CHR_SetsActive_0,y
		sta	$_CHR_SetsActive_1,y
		sta	$_CHR_SetsActive_2,y

		// Store VRAM size
		lda	[$.list],y
		sta	$_CHR_0_PageLength,y

		// Is this mapper supporting CHR changes? If not, exit out of this loop
		beq	$+b_exit

		// Move VRAM address to next available page
		clc
		adc	$.vramPage
		sta	$.vramPage

		// Next
		iny
		cmp	#0x20
		bcc	$-b_loop
b_exit:

	// Erorr out if we have too many banks
	cpy	#9
	trapcs
	Exception	"Too Many CHR Ranges{}{}{}Chr.Initialize attempted to allocate too many CHR ranges for bank switching."

	// Store number of CHR banks for this mapper
	tya
	sta	$_CHR_BanksInUse
	asl	a
	sta	$_CHR_BanksInUse_x2

	// Return
	rep	#0x30
	.mx	0x00
	return

Chr__Initialize_Switch:
	switch	0x100, Chr__Initialize_Switch_Default, Chr__Initialize_Switch_Default
Chr__Initialize_Switch_Default:
		case	0
			.data8	0x20
		case	1
			.data8	0x10, 0x10
		case	4
			.data8	0x08, 0x08, 0x04, 0x04, 0x04, 0x04
		case	69
			.data8	0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04

	// ---------------------------------------------------------------------------
