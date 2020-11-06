
	.mx	0x00
	.func	Sound__Init
Sound__Init:
	// Disable audio
	stz	$_Sound_Active

	// Change mode and lock thread
	php
	sep	#0x24
	.mx	0x20

	// Are we on EmulSNES? If so, leave
	lda	$0x4210
	eor	$0x4210
	and	#0x0f
	beq	$+Sound__Init_In
		plp
		return
Sound__Init_In:

	// Local variables
	//.local	.index

	// Wait for 0xbbaa
	ldy	#0xbbaa
Sound__Init_WaitForBBAA:
		cpy	$0x2140
		bne	$-Sound__Init_WaitForBBAA

	// Send start address
	ldy	#_Spc_Code_Start
	sty	$0x2142
	// Kick
	lda	#0x01
	sta	$0x2141
	lda	#0xcc
	sta	$0x2140

	// Start at index 0
	ldx	#0x0000
	
	// Wait for kick back from SPC
Sound__Init_WaitForKickBack:
		cmp	$0x2140
		bne	$-Sound__Init_WaitForKickBack

	// Start data transfer
Sound__Init_Transfer:
		// Load and send byte
		lda	$=Spc_Code_Start,x
		sta	$0x2141

		// Send index LSB
		txa
		sta	$0x2140

		// Next index
		inx

		// Wait for feedback
Sound__Init_Transfer_Feedback:
			cmp	$0x2140
			bne	$-Sound__Init_Transfer_Feedback

		// Are we done transferring?
		cpx	#_Spc_Code_End-Spc_Code_Start
		bcc	$-Sound__Init_Transfer

	// Execute SPC code, ignore carry
	adc	#0x02
	ora	#0x01
	ldy	#_Spc_Code_Start
	sty	$0x2142
	stz	$0x2141
	sta	$0x2140

	// Activate audio
	ldx	#0xffff
	stx	$_Sound_Active

	// Copy HDMA pointers for sound
	.local	=back, =front, =side
	lda	#0x7e
	sta	$.back+2
	sta	$.front+2
	sta	$.side+2
	// Lower bytes
	ldx	$_HDMA_Sound_Back
	beq	$+b_trap
	stx	$.back
	ldx	$_HDMA_Sound_Front
	beq	$+b_trap
	stx	$.front
	ldx	$_HDMA_Sound_Side
	beq	$+b_trap
	stx	$.side

	// Change bank
	phb
	phk
	plb

	// Copy base data to each buffer
	ldy	#_Sound__Init_HdmaTable_End-Sound__Init_HdmaTable-1
b_loop:
		lda	$_Sound__Init_HdmaTable,y
		sta	[$.back],y
		sta	[$.front],y
		sta	[$.side],y
		dey
		bpl	$-b_loop

	// Return
	plb
	plp
	return

b_trap:
	unlock
	trap
	Exception	"Audio Initialization Failed{}{}{}HDMA buffers must be initialized before audio."


Sound__Init_HdmaTable:
	.def	Sound__Init_HdmaTable_WaitReady		10
	.macro	Sound__Init_HdmaTable_DataMac
		// Wait for SPC ready
		.data8	.Sound__Init_HdmaTable_WaitReady, 0xd7, 0x00

		// Prepare transferring data (0x17 bytes)
		.data8	0x97

		// Transfer data
		.data8	0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00
		.data8	0x04, 0x00, 0x05, 0x00, 0x06, 0x00, 0x07, 0x00
		.data8	0x08, 0x00, 0x09, 0x00, 0x0a, 0x00, 0x0b, 0x00
		.data8	0x0c, 0x00, 0x0d, 0x00, 0x0e, 0x00, 0x0f, 0x00
		.data8	0x10, 0x00, 0x11, 0x00, 0x12, 0x00, 0x13, 0x00
		.data8	0x14, 0x00, 0x15, 0x00, 0x16, 0x00
	.endm

	// First quarter
	Sound__Init_HdmaTable_DataMac
	// End HDMA
	.data8	0

	// Second quarter
b_1:
	.data8	.Zero+65-23-Sound__Init_HdmaTable_WaitReady, 0x20, 0x00
	Sound__Init_HdmaTable_DataMac
b_2:

	// Third quarter
	.data8	.Zero+66-23-Sound__Init_HdmaTable_WaitReady, 0x20, 0x00
	Sound__Init_HdmaTable_DataMac

	// Fourth quarter
	.data8	.Zero+65-23-Sound__Init_HdmaTable_WaitReady, 0x20, 0x00
	Sound__Init_HdmaTable_DataMac

	// End HDMA
	.data8	0
Sound__Init_HdmaTable_End:

	.def	Sound__Init_HdmaTable_Start		5
	.def	Sound__Init_HdmaTable_Gap		=b_2-b_1

	// ------------------------------------------------------------------------
	// ------------------------------------------------------------------------

	.mx	0x20
	.func	Sound__Update
Sound__Update:
	// Change DP
	phd
	pea	$_HDMA_VSTACK_PAGE
	pld

	sep	#0x30
	.mx	0x30

	// Update sound
	Sound__EmulateLengthCounter
	smx	#0x20
	Sound__UpdateDsp

	// Update HDMA buffer if ready
	lda	$.Sound_Ready
	bne	$+b_1
		lda	$.Sound_ExtraControl
		sta	$.Sound_NesRegs+0x16
		stz	$.Sound_ExtraControl

		dec	$.Sound_Ready
b_1:

	pld
	return

	// ------------------------------------------------------------------------

	.mx	0x30
	.macro	Sound__EmulateLengthCounter
		// Square 0
		lda	#0x01
		bit	$.Sound_NesRegs+0x15
		beq	$+b_1
			ldx	$.Sound_square0_length
			beq	$+b_else
				dec	$.Sound_square0_length
				bra	$+b_1
b_else:
				//lda	#0x01
				trb	$.Sound_NesRegs+0x15
b_1:

		// Square 1
		lda	#0x02
		bit	$.Sound_NesRegs+0x15
		beq	$+b_1
			ldx	$.Sound_square1_length
			beq	$+b_else
				dec	$.Sound_square1_length
				bra	$+b_1
b_else:
				//lda	#0x02
				trb	$.Sound_NesRegs+0x15
b_1:

		// Triangle
		lda	#0x04
		tsb	$.Sound_NesRegs+0x15
		ldx	$.Sound_NesRegs+0x8
		bpl	$+b_1
			ldx	$.Sound_triangle_length
			beq	$+b_else
				dec	$.Sound_triangle_length
				bra	$+b_1
b_else:
				//lda	#0x04
				trb	$.Sound_NesRegs+0x15
b_1:

		// Noise channel
		lda	#0x08
		bit	$.Sound_NesRegs+0x15
		beq	$+b_1
			ldx	$.Sound_noise_length
			beq	$+b_else
				dec	$.Sound_noise_length
				bra	$+b_1
b_else:
				//lda	#0x08
				trb	$.Sound_NesRegs+0x15
b_1:
	.endm

//Sound__EmulateLengthCounter_length_d3_0:
//	.data8 0x06,0x0B,0x15,0x29,0x51,0x1F,0x08,0x0F
//	.data8 0x07,0x0D,0x19,0x31,0x61,0x25,0x09,0x11

//Sound__EmulateLengthCounter_length_d3_1:
//	.data8 0x80,0x02,0x03,0x04,0x05,0x06,0x07,0x08
//	.data8 0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,0x10

Sound__EmulateLengthCounter_length_d3_mixed:
	.fill	8, 0x06
	.fill	8, 0x80
	.fill	8, 0x0B
	.fill	8, 0x02
	.fill	8, 0x15
	.fill	8, 0x03
	.fill	8, 0x29
	.fill	8, 0x04
	.fill	8, 0x51
	.fill	8, 0x05
	.fill	8, 0x1F
	.fill	8, 0x06
	.fill	8, 0x08
	.fill	8, 0x07
	.fill	8, 0x0F
	.fill	8, 0x08
	.fill	8, 0x07
	.fill	8, 0x09
	.fill	8, 0x0D
	.fill	8, 0x0A
	.fill	8, 0x19
	.fill	8, 0x0B
	.fill	8, 0x31
	.fill	8, 0x0C
	.fill	8, 0x61
	.fill	8, 0x0D
	.fill	8, 0x25
	.fill	8, 0x0E
	.fill	8, 0x09
	.fill	8, 0x0F
	.fill	8, 0x11
	.fill	8, 0x10

	// ------------------------------------------------------------------------

	.mx	0x20
	.macro	Sound__UpdateDsp_Mac	Offset
		lda	$.Sound_NesRegs+{0}
		sta	$=Sound__Init_HdmaTable_Start+0x7e0000+{0}*2,x
	.endm
	.macro	Sound__UpdateDsp
		ldx	$.HDMA_Sound_Side
		Sound__UpdateDsp_Mac	0x00
		Sound__UpdateDsp_Mac	0x01
		Sound__UpdateDsp_Mac	0x02
		Sound__UpdateDsp_Mac	0x03
		Sound__UpdateDsp_Mac	0x04
		Sound__UpdateDsp_Mac	0x05
		Sound__UpdateDsp_Mac	0x06
		Sound__UpdateDsp_Mac	0x07
		Sound__UpdateDsp_Mac	0x08
		Sound__UpdateDsp_Mac	0x09
		Sound__UpdateDsp_Mac	0x0a
		Sound__UpdateDsp_Mac	0x0b
		Sound__UpdateDsp_Mac	0x0c
		Sound__UpdateDsp_Mac	0x0d
		Sound__UpdateDsp_Mac	0x0e
		Sound__UpdateDsp_Mac	0x0f
		Sound__UpdateDsp_Mac	0x10
		Sound__UpdateDsp_Mac	0x11
		Sound__UpdateDsp_Mac	0x12
		Sound__UpdateDsp_Mac	0x13
		Sound__UpdateDsp_Mac	0x14
		Sound__UpdateDsp_Mac	0x15
		Sound__UpdateDsp_Mac	0x16
	.endm

	// ------------------------------------------------------------------------
	// OBSOLETE DIRECT TRANSFER PLANS

	// Port usage:
	//  In_0  = Write request with bit 7 as a ready flip-flop
	//  In_1  = Data
	//  In_2  = Streamed data via HDMA for sound sample
	//  In_3  = Scanline number (0 to 238?), updated 1 cycle after In_2
	//  Out_0 = Bit 7 as ready flip-flop, equals to In_0 of most recent request taken
	//  Out_1 = Which channels are active
	//  Out_2 = <Unused>
	//  Out_3 = Always zero for zero memory DMA and JMP ($217F,x)

	// Timing notes for the new APU code (concept)
	// c = Main code
	// q = Wait for scanline or queue
	// s = Copy stream data

	// When streaming is OFF or VBlank, not synchronized to scanline
	//  cccccccccccc
	//  ccccccq

	// When streaming is ON
	//  sccccccccccc
	//  cccccccsqqqq

	// When streaming is ON but the code doesn't take enough time
	//  scccccqqqqqq
	//  sc

	// After receiving queue data and streaming is OFF, not synchronized to scanline
	//  qqqqqqqqqc

	// After receiving queue data and streaming is ON
	//            qq
	//  sqqqqqqqqqqq
	//  sc

	.macro	IO__mac_WriteSound		offset
IO__w40{0}_a:
		php
		// Which pair are we sending this byte to?
		bit	$_Sound_FlipFlop
		bvs	$+IO__w40{0}_a_Flop

			// First communication pair
			bmi	$+IO__w40{0}_a_FlipUp

				// Flip down, wait for up from SPC
IO__w40{0}_a_FlipDown_Loop:
				bit	$0x2141
				bpl	$-IO__w40{0}_a_FlipDown_Loop

				// Send new data with up side
				sta	$0x2141
				xba
				lda	#.Zero+0xc0+0x{0}
				sta	$0x2140
				sta	$_Sound_FlipFlop
				xba

				// Return
				plp
				rtl

				// Flip up, wait for down from SPC
IO__w40{0}_a_FlipUp_Loop:
				bit	$0x2141
				bmi	$-IO__w40{0}_a_FlipUp_Loop

				// Send new data with down side
				sta	$0x2141
				xba
				lda	#.Zero+0x40+0x{0}
				sta	$0x2140
				sta	$_Sound_FlipFlop
				xba

				// Return
				plp
				rtl

IO__w40{0}_a_Flop:
			// Second communication pair
			bmi	$+IO__w40{0}_a_FlopUp

				// Flop down, wait for up from SPC
IO__w40{0}_a_FlopDown_Loop:
				bit	$0x2143
				bpl	$-IO__w40{0}_a_FlopDown_Loop

				// Send new data with up side
				sta	$0x2143
				xba
				lda	#.Zero+0x00+0x{0}
				sta	$0x2142
				sta	$_Sound_FlipFlop
				xba

				// Return
				plp
				rtl

IO__w40{0}_a_FlopUp:
				// Flop up, wait for down from SPC
IO__w40{0}_a_FlopUp_Loop:
				bit	$0x2143
				bmi	$-IO__w40{0}_a_FlipUp_Loop

				// Send new data with down side
				sta	$0x2143
				xba
				lda	#.Zero+0x80+0x{0}
				sta	$0x2142
				sta	$_Sound_FlipFlop
				xba

				// Return
				plp
				rtl
	.endm
