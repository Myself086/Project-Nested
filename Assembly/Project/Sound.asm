
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

	.func	Sound__Update
Sound__Update:
	php

	// Change DP
	phd
	pea	$_HDMA_VSTACK_PAGE
	pld

	sep	#0x30
	.mx	0x30
	//lda	$.Sound_Active
	//bpl	$+b_1

	// Update sound
	call	Sound__EmulateLengthCounter
	call	Sound__BackupRegs
	call	Sound__UpdateDsp

	// Update HDMA buffer if ready
	lda	$.Sound_Ready
	bne	$+b_1
		lda	$.Sound_NesRegs+0x16
		sta	$.Sound_CopyRegs+0x16
		stz	$.Sound_NesRegs+0x16

		dec	$.Sound_Ready
b_1:

	pld
	plp
	return

	// ------------------------------------------------------------------------

	.mx	0x30
	.func	Sound__DetectChanges
Sound__DetectChanges:

	lda	$_Sound_NesRegs+0x0
	and	#0x20
	bne	$+Sound__DetectChanges_DedayDisabled0

		lda $_Sound_NesRegs+0x3
		beq $+Sound__DetectChanges_Plus0
			sta $_Sound_CopyRegs+0x3
			stz	$_Sound_NesRegs+0x3

			lda	#0x41
			tsb	$_Sound_CopyRegs+0x16
			bra $+Sound__DetectChanges_EndSquare0

Sound__DetectChanges_Plus0:
			lda	#0x41
			trb	$_Sound_CopyRegs+0x16
			bra $+Sound__DetectChanges_EndSquare0

Sound__DetectChanges_DedayDisabled0:
		lda	$_Sound_NesRegs+0x3
		sta	$_Sound_CopyRegs+0x3

Sound__DetectChanges_EndSquare0:

	lda	$_Sound_NesRegs+0x4
	and	#0x20
	bne $+Sound__DetectChanges_DecayDisabled1

		lda $_Sound_NesRegs+0x7
		beq $+Sound__DetectChanges_Plus1
			sta	$_Sound_CopyRegs+0x7
			stz	$_Sound_NesRegs+0x7

			lda	#0x82
			tsb	$_Sound_CopyRegs+0x16
			bra $+Sound__DetectChanges_EndSquare1

Sound__DetectChanges_Plus1:
			lda	#0x82
			trb	$_Sound_CopyRegs+0x16
			bra $+Sound__DetectChanges_EndSquare1

Sound__DetectChanges_DecayDisabled1:
		lda	$_Sound_NesRegs+0x7
		sta	$_Sound_CopyRegs+0x7

Sound__DetectChanges_EndSquare1:

	// Triangle wave
	lda	$_Sound_NesRegs+0x8
	bmi	$+Sound__DetectChanges_LinearTri

		lda	$_Sound_NesRegs+0xb
		beq	$+Sound__DetectChanges_Plus2

			sta	$_Sound_CopyRegs+0xb
			stz	$_Sound_NesRegs+0xb

			lda	#0x04
			tsb	$_Sound_CopyRegs+0x16
			bra	$+Sound__DetectChanges_EndTri

Sound__DetectChanges_Plus2:
			lda	#0x04
			trb	$_Sound_CopyRegs+0x16
			bra	$+Sound__DetectChanges_EndTri

Sound__DetectChanges_LinearTri:
		lda	$_Sound_NesRegs+0xb
		sta	$_Sound_CopyRegs+0xb

Sound__DetectChanges_EndTri:
	
	lda	$_Sound_NesRegs+0xc
	and	#0x20
	bne	$+Sound__DetectChanges_Disabled2

		lda	$_Sound_NesRegs+0xf
		beq	$+Sound__DetectChanges_Plus3

			sta	$_Sound_CopyRegs+0xf
			stz	$_Sound_NesRegs+0xf

			lda	#0x08
			tsb	$_Sound_CopyRegs+0x16
			bra	$+Sound__DetectChanges_EndNoise

Sound__DetectChanges_Plus3:
			lda	#0x08
			trb	$_Sound_CopyRegs+0x16
			bra	$+Sound__DetectChanges_EndNoise

Sound__DetectChanges_Disabled2:
		lda	$_Sound_NesRegs+0xf
		sta	$_Sound_CopyRegs+0xf

Sound__DetectChanges_EndNoise:

	// Check freq for sweeps
	lda	$_Sound_NesRegs+0x1
	bpl	$+Sound__DetectChanges_Sqsw1

		//lda	$_Sound_NesRegs+0x1
		and	#0x07
		beq	$+Sound__DetectChanges_Sqsw1x

			lda	$_Sound_NesRegs+0x2
			beq	$+Sound__DetectChanges_Sqsw1

				sta	$_Sound_CopyRegs+0x2
				stz	$_Sound_NesRegs+0x2

				lda	#0x40
				tsb	$_Sound_CopyRegs+0x16
				bra	$+Sound__DetectChanges_Plus4

Sound__DetectChanges_Sqsw1:
				lda	$_Sound_NesRegs+0x2
				sta	$_Sound_CopyRegs+0x2

Sound__DetectChanges_Plus4:
			bra $+Sound__DetectChanges_NextCheck

Sound__DetectChanges_Sqsw1x:
		lda	#0x40
		trb	$_Sound_CopyRegs+0x16
		bra	$-Sound__DetectChanges_Sqsw1

Sound__DetectChanges_NextCheck:
	
	// Check freq for sweeps
	lda	$_Sound_NesRegs+0x5
	bpl	$+Sound__DetectChanges_Sqsw12
		
		//lda	$_Sound_NesRegs+0x5
		and	#0x07
		beq	$+Sound__DetectChanges_Sqsw1x2

			lda	$_Sound_NesRegs+0x6
			beq	$+Sound__DetectChanges_Sqsw12

				sta	$_Sound_CopyRegs+0x6
				stz	$_Sound_NesRegs+0x6

				lda	#0x80
				tsb	$_Sound_CopyRegs+0x16
				bra	$+Sound__DetectChanges_Plus5

Sound__DetectChanges_Sqsw12:
				lda	$_Sound_NesRegs+0x6
				sta	$_Sound_CopyRegs+0x6

Sound__DetectChanges_Plus5:
			bra $+Sound__DetectChanges_NextCheck2

Sound__DetectChanges_Sqsw1x2:
		lda	#0x80
		trb	$_Sound_CopyRegs+0x16
		bra	$-Sound__DetectChanges_Sqsw12

Sound__DetectChanges_NextCheck2:

	// Return
	return

	// ------------------------------------------------------------------------

	.mx	0x30
	.func	Sound__EmulateLengthCounter
Sound__EmulateLengthCounter:
	// Clear upper bits of A
	//tdc
	//xba

	//stz	$_Sound_CopyRegs+0x15

	// TODO: Finish moving code

	// Square 0
//	lda	$_Sound_CopyRegs+0x16
//	and	#0x01
//	beq $+Sound__EmulateLengthCounter_Sq0NotChanged
//		ldx	$_Sound_CopyRegs+0x3
//		lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
//		sta	$_Sound_square0_length
//Sound__EmulateLengthCounter_Sq0NotChanged:

	//lda	#0x01
	//tsb	$_Sound_CopyRegs+0x15

	//lda	$_Sound_NesRegs+0x0
	//and	#0x20
	lda	#0x01
	bit	$.Sound_CopyRegs+0x15
	beq	$+Sound__EmulateLengthCounter_sq0_counter_disabled

		ldx	$.Sound_square0_length
		beq	$+Sound__EmulateLengthCounter_blahsq
			dec	$.Sound_square0_length
			bra	$+Sound__EmulateLengthCounter_Plus0

Sound__EmulateLengthCounter_blahsq:
			//lda	#0x01
			trb	$.Sound_CopyRegs+0x15
			//lda	#0x40
			//trb	$_Sound_CopyRegs+0x16

Sound__EmulateLengthCounter_Plus0:
Sound__EmulateLengthCounter_sq0_counter_disabled:

	// Square 1
//	lda	$_Sound_CopyRegs+0x16
//	and	#0x02
//	beq $+Sound__EmulateLengthCounter_sq1_not_changed
//		ldx	$_Sound_CopyRegs+0x7
//		lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
//		sta	$_Sound_square1_length
//Sound__EmulateLengthCounter_sq1_not_changed:
	
	//lda	#0x02
	//tsb	$_Sound_CopyRegs+0x15

	//lda	$_Sound_NesRegs+0x4
	//and	#0x20
	lda	#0x02
	bit	$.Sound_CopyRegs+0x15
	beq	$+Sound__EmulateLengthCounter_sq1_counter_disabled

		ldx	$.Sound_square1_length
		beq	$+Sound__EmulateLengthCounter_sqblah
			dec	$.Sound_square1_length
			bra	$+Sound__EmulateLengthCounter_Plus1

Sound__EmulateLengthCounter_sqblah:
			//lda	#0x02
			trb	$.Sound_CopyRegs+0x15
			//lda	#0x80
			//trb	$_Sound_CopyRegs+0x16

Sound__EmulateLengthCounter_Plus1:
Sound__EmulateLengthCounter_sq1_counter_disabled:

//	lda	$_Sound_CopyRegs+0x16
//	and	#0x04
//	beq	$+Sound__EmulateLengthCounter_tri_not_changed
//		//lda	$_Sound_NesRegs+0x8
//		//bmi	$+Sound__EmulateLengthCounter_LinearTri
//			ldx	$_Sound_CopyRegs+0xb
//			lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
//			sta	$_Sound_triangle_length
//			bra	$+Sound__EmulateLengthCounter_tri_not_changed
//
//Sound__EmulateLengthCounter_LinearTri:
//			//stz	$_Sound_NesRegs+0x8
//			lda	$_Sound_NesRegs+0x8
//			and	#0x7f
//			beq	$+Sound__EmulateLengthCounter_tri_not_changed
//				adc	#0x01
//				sta	$_Sound_triangle_length
//				lda	#0x04
//				trb	$_Sound_CopyRegs+0x16
//Sound__EmulateLengthCounter_tri_not_changed:

	lda	#0x04
	tsb	$.Sound_CopyRegs+0x15

	ldx	$.Sound_NesRegs+0x8
	bpl	$+Sound__EmulateLengthCounter_tri_counter_disabled

		ldx	$.Sound_triangle_length
		beq	$+Sound__EmulateLengthCounter_blah
			dec	$.Sound_triangle_length
			bra	$+Sound__EmulateLengthCounter_Plus2
Sound__EmulateLengthCounter_blah:
			//lda	#0x04
			trb	$.Sound_CopyRegs+0x15

Sound__EmulateLengthCounter_Plus2:
Sound__EmulateLengthCounter_tri_counter_disabled:

	// Noise channel
//	lda	$.Sound_CopyRegs+0x16
//	and	#0x08
//	beq	$+Sound__EmulateLengthCounter_unchanged
//		ldx	$.Sound_CopyRegs+0xf
//		lda	$=Sound__EmulateLengthCounter_length_d3_mixed,x
//		sta	$.Sound_noise_length
//Sound__EmulateLengthCounter_unchanged:

	//lda	#0x08
	//tsb	$_Sound_CopyRegs+0x15

	//lda	$_Sound_NesRegs+0xc
	//and	#0x20
	lda	#0x08
	bit	$.Sound_CopyRegs+0x15
	beq	$+Sound__EmulateLengthCounter_noise_counter_disabled

		ldx	$.Sound_noise_length
		beq	$+Sound__EmulateLengthCounter_pleh
			dec	$.Sound_noise_length
			bra	$+Sound__EmulateLengthCounter_Plus3

Sound__EmulateLengthCounter_pleh:
			//lda	#0x08
			trb	$.Sound_CopyRegs+0x15

Sound__EmulateLengthCounter_Plus3:
Sound__EmulateLengthCounter_noise_counter_disabled:

	//lda	$_Sound_CopyRegs+0x15
	//and	$_Sound_NesRegs+0x15
	//sta	$_Sound_CopyRegs+0x15

	return

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

	.mx	0x30
	.func	Sound__BackupRegs
Sound__BackupRegs:
	lda $.Sound_NesRegs+0x0
	sta $.Sound_CopyRegs+0x0
	lda $.Sound_NesRegs+0x1
	sta $.Sound_CopyRegs+0x1
	
	lda $.Sound_NesRegs+0x4
	sta $.Sound_CopyRegs+0x4
	lda $.Sound_NesRegs+0x5
	sta $.Sound_CopyRegs+0x5
	
	lda $.Sound_NesRegs+0x8
	sta $.Sound_CopyRegs+0x8
	lda $.Sound_NesRegs+0x9
	sta $.Sound_CopyRegs+0x9
	lda $.Sound_NesRegs+0xa
	sta $.Sound_CopyRegs+0xa
	
	lda $.Sound_NesRegs+0xc
	sta $.Sound_CopyRegs+0xc
	lda $.Sound_NesRegs+0xd
	sta $.Sound_CopyRegs+0xd
	lda $.Sound_NesRegs+0xe
	sta $.Sound_CopyRegs+0xe
	
	lda $.Sound_NesRegs+0x11
	sta $.Sound_CopyRegs+0x11

	// DEBUG ONLY
	lda	$0x002141
	sta	$=Sound_DebugAPU+0
	lda	$0x002142
	sta	$=Sound_DebugAPU+1

	return

	// ------------------------------------------------------------------------

	.mx	0x20
	.func	Sound__UpdateDsp
Sound__UpdateDsp:
	rep	#0x10
	.macro	Sound__UpdateDsp_Mac	Offset
		lda	$.Sound_CopyRegs+{0}
		sta	$=Sound__Init_HdmaTable_Start+0x7e0000+{0}*2,x
	.endm
	//ldx	$.HDMA_Sound_Back
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

	sep	#0x10
	return

	// OLD
.false
{
	stz	$_Sound_TestCounter0
	stz	$_Sound_TestCounter1

	// Wait for SPC ready
	lda	#0x7d
Sound__UpdateDsp_Wait0:
		inc	$_Sound_TestCounter0
		cmp	$0x2140
		bne	$-Sound__UpdateDsp_Wait0

	// Tell SPC that CPU is ready
	lda	#0xd7
	sta	$0x2140

Sound__UpdateDsp_Wait1:
		inc	$_Sound_TestCounter1
		// Wait for reply
		cmp	$0x2140
		bne	$-Sound__UpdateDsp_Wait1

	// Clear port 0
	ldx	#0x00
Sound__UpdateDsp_Xfer:
		// Send data to port 1
		lda	$_Sound_CopyRegs,x
		sta	$0x2141
		stx	$0x2140

Sound__UpdateDsp_Wait2:
			// Wait for reply on port 0
			cpx	$0x2140
			bne	$-Sound__UpdateDsp_Wait2

		inx
		cpx	#0x17
		bne	$-Sound__UpdateDsp_Xfer

	return
}

	// ------------------------------------------------------------------------

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
