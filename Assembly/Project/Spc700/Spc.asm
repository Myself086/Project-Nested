
//========================================
//       NES Registers
//----------------------------------------
	.def	sq4000          0x40   // 0x4000
	.def	sq4001          0x41   // 0x4001
	.def	sq4002          0x42   // 0x4002
	.def	sq4003          0x43   // 0x4003
	.def	sq4004          0x44   // 0x4004
	.def	sq4005          0x45   // 0x4005
	.def	sq4006          0x46   // 0x4006
	.def	sq4007          0x47   // 0x4007
	.def	tr4008          0x48   // 0x4008
	.def	tr4009          0x49   // 0x4009
	.def	tr400A          0x4A   // 0x400A
	.def	tr400B          0x4b   // 0x400B
	.def	no400C          0x4C   // 0x400C
	.def	no400D          0x4D   // 0x400D
	.def	no400E          0x4E   // 0x400E
	.def	no400F          0x4F   // 0x400F
	.def	pcm_freq        0x50   // 0x4010
	.def	pcm_raw         0x51   // 0x4011
	.def	pcm_addr        0x52   // 0x4012
	.def	pcm_length      0x53   // 0x4013

	.def	sound_ctrl		0x55   // 0x4015

	.def	no4016			0x56   // 0x4016
		// 0x01 = Reset square 0
		// 0x02 = Reset square 1
		// 0x04 = Reset triangle
		// 0x08 = Reset noise
		// 0x10 = Reset DMC
		// 0x20 = Mono
		// 0x40 = Square 0 sweep
		// 0x80 = Square 1 sweep

//========================================
//       SPC Memory
//----------------------------------------

	.def	pulse0duty				0x60
	.def	pulse0dutyold			0x61
	.def	pulse1duty				0x62
	.def	pulse1dutyold			0x63
	.def	puls0_sample			0x64
	.def	puls1_sample			0x65
	.def	puls0_sample_old        0x66
	.def	puls1_sample_old        0x67
	.def	temp1					0x68
	.def	temp2					0x69
	.def	temp3					0x6A
	.def	temp4					0x6B
	.def	temp5					0x6C
	.def	temp6					0x6D
	.def	temp7					0x6E
	.def	temp8					0x6F
	.def	temp9					0x70
	.def	temp10					0x71
	.def	old4003					0x72

	.def	sweeptemp1				0x78
	.def	sweeptemp2				0x79
	.def	sweep_freq_lo			0x7A
	.def	sweep_freq_hi			0x7B

	.def	linear_count_lo			0x7D
	.def	linear_count_hi			0x7E
	.def	timer3count_lo			0x7F
	.def	timer3count_hi			0x80
	.def	sweep1					0x81
	.def	sweep2					0x82
	.def	sweep_freq_lo2			0x83
	.def	sweep_freq_hi2			0x84
	.def	timer3val				0x85
	.def	decay1volume			0x86
	.def	decay1rate				0x87
	.def	decay_status			0x88
	.def	decay2volume			0x89
	.def	decay2rate				0x8A
	.def	decay3volume			0x8B
	.def	decay3rate				0x8C
	.def	temp_add				0x8D

	.def	tri_sample              0x8E

	.def	Spc_NewDataEP			0x90
	.def	Spc_NewDataEP_hi		0x91
	.def	Dmc_DictionaryTop		0x92		// Next free index for Dmc_Dictionary
	.def	Spc_FreeInstrument		0x93

	.def	temp_pointer			0x94		// For convert_dmc_samples, maybe something else some day
	.def	temp_pointer_hi			0x95

	.def	tempYA					0x96		// Used by YA macros
	.def	tempYA_hi				0x97

	.def	temp_sample0			0x98		// Used to convert DMC samples to BRR samples
	.def	temp_sample1			0x99
	.def	temp_sample2			0x9a
	.def	temp_sample3			0x9b
	.def	temp_sample4			0x9c
	.def	temp_sample5			0x9d
	.def	temp_sample6			0x9e
	.def	temp_sample7			0x9f

	.def	instrumentP				0xa0		// Returned by get_instrument_pointer
	.def	instrumentP_hi			0xa1

	.def	Spc_StaticRanges		0xa2		// Copy of RomInfo_StaticRanges

	.def	Spc_HeapStart_TOP		0xbeff		// Spc_HeapStart located at the bottom of this asm file
	.def	Dmc_Dictionary			0xbf00		// Contains: Address-Length pair, instrument number

//========================================

	.macro	AslYA
		movw	tempYA, ya
		addw	ya, tempYA
	.endm

	.macro	LsrYA
		mov	tempYA_hi, y
		lsr	tempYA_hi
		ror	a
		mov	y, tempYA
	.endm

//========================================

start:
        clrp                    // clear direct page flag (DP = 0x0000-0x00FF)
        mov x,#0xF0
        mov SP,x

        mov a,#00110000b
        mov 0xF1,a               // clear all ports, disable timers

        call !reset_dsp         // clear DSP registers
        call !set_directory     // set sample directory

        mov 0xF2,#0x5D           // directory offset
        mov 0xF3,#0x02           // 0x200

        mov 0xF2,#0x05            // ADSR off, GAIN enabled
        mov 0xF3,#0
        mov 0xF2,#0x15            // ADSR off, GAIN enabled
        mov 0xF3,#0
        mov 0xF2,#0x25
        mov 0xF3,#0
        mov 0xF2,#0x35
        mov 0xF3,#0

        mov 0xF2,#0x07            // infinite gain
        mov 0xF3,#0x1F
        mov 0xF2,#0x17            // infinite gain
        mov 0xF3,#0x1F
        mov 0xF2,#0x27
        mov 0xF3,#0x1F
        mov 0xF2,#0x37
        mov 0xF3,#0x1F
        mov 0xF2,#0x47
        mov 0xF3,#0x1F


        mov 0xF2,#0x24            // sample # for triangle
        mov 0xF3,#triangle_sample_num

        mov 0xF2,#0x34
        mov 0xF3,#0x00            // sample # for noise


        mov 0xF2,#0x4C            // key on
        mov 0xF3,#00001111b

        mov 0xF2,#0x0C            // main vol L
        mov 0xF3,#0x7F
        mov 0xF2,#0x1C            // main vol R
        mov 0xF3,#0x7F

        mov 0xF2,#0x6C
        mov 0xF3,#00100000b      // soft reset, mute, and echo disabled

        mov 0xF2,#0x6D				// Echo buffer address
		mov	0xF3,#0x7d

        mov 0xF2,#0x3D            // noise on voice 3
        mov 0xF3,#00001000b

		mov	a, !0xbfff				// Copy static range flags to ZP
		mov	Spc_StaticRanges, a

        call !enable_timer3

		// Zero port 4 for CPU-side optimization
		mov 0xF7,#0

next_xfer:
        mov 0xF4,#0x7D            // move 0x7D to port 0 (SPC ready)
wait:
        call !check_timer3
        call !check_timers
        call !check_timers2

wait2:
        mov x,0xF4
		movw	ya, 0xF5         // Pre-emptively read ready's 2-byte transfer
		cmp	x,0xF4               // Make sure port 0 wasn't in the middle of changing
		bne	wait2

        cmp x,#0xF5              // wait for port 0 to be 0xF5 (Reset)
        beq to_reset
        cmp x,#0xD7              // wait for port 0 to be 0xD7 (CPU ready)
        bne wait
        mov 0xF4,x               // reply to CPU with 0xD7 (begin transfer)

		// Transfer exception for the last 2 bytes
		movw	sound_ctrl, ya   // sound_ctrl and no4016

		// 63.613 cycles per scanline
		// Transfer via HDMA must take no more than 66 cycles per byte
		// Cycles used during transfer: 35 = 3+2 + 3+5+4+3+5 + 2+2+2+4

        mov x,#0
xfer:
		cmp x,0xF4               // wait for port 0 to have current byte #
		bne xfer

		mov a,0xF5               // load data on port 1
		mov 0xF4,x               // reply to CPU on port 0
		mov 0x40+x,a             // store data at 0x40 - 0x53 (even)
		mov a,0xF6               // load data on port 2
		mov 0x41+x,a             // store data at 0x40 - 0x53 (odd)

		inc x
		inc x
		cmp x,#0x14
		bne xfer

		call !update_dmc

		jmp	!square0

to_reset:
		mov	0xF1,#0xB0
		jmp	!0xffc0

//=====================================

spc_communication:
	// TODO

	ret

//=====================================


//-------------------------------------
square0:

        mov a,sound_ctrl
        and a,#00000001b
        bne sq0_enabled
silence:
        mov 0xF2,#0
        mov 0xF3,#0
        mov 0xF2,#1
        mov 0xF3,#0
        jmp !square1

sq0_enabled:



//-------------------------------------
                                // emulate duty cycle (select sample #)
                                // check first the octave sample to be played

        mov a,sq4000            // emulate duty cycle
        and a,#11000000b
		xcn	a

		and	puls0_sample,#0x03
		or	a,puls0_sample
        mov puls0_sample,a
        cmp a,puls0_sample_old
        beq sq1_no_change

sq1_sample_change:

        mov 0xF2,#0x04            // sample # reg
        mov 0xF3,puls0_sample

        mov 0xF2,#0x4C            // key on
        mov 0xF3,#00000001b

sq1_no_change:

        mov puls0_sample_old,puls0_sample
        

        


//        mov puls0_sample,#0
//
//        mov y,a
//
//        mov a,sq4003
//        and a,#00000111b
//        mov x,a
//        mov a,y
////        cmp x,#00000101b
////        beq pitch0
//        cmp x,#00000110b
//        beq pitch0
//        cmp x,#00000111b
//        beq pitch0
//
//        clrc
//        adc a,#4
//        mov puls0_sample,#1
//
//pitch0:
//        mov 0xF2,#0x04            // sample #
//        mov 0xF3,a
//
//        mov 0xF2,#0x4C            // key on
//        mov 0xF3,#00000001b          
//no_change:
//        mov pulse0dutyold,pulse0duty
//        mov puls0_sample_old,puls0_sample

//-------------------------------------
// freq sweep test

//        mov a,0x41
//        and a,#10000000b
//        beq skipsweep0
//        mov a,0x41
//
//        mov sweeptemp1,0x42
//        mov sweeptemp2,0x43
//        and sweeptemp2,#00000111b
//
//        mov a,0x41
//        and a,#00000111b
//        beq skipsweep0
//        mov x,a
//        
//keepshifting0:
//        clrc
//        ror sweeptemp2
//        ror sweeptemp1
//
//        dec x
//        bne keepshifting0
//
//        and 0x43,#00000111b
//
//        mov a,sweeptemp1
//        mov y,sweeptemp2
//
//        addw ya,0x42
//        mov a,0x42
//        mov y,0x43
//
//
//        mov a,0x42
//        clrc
//        rol a
//        push psw
//        clrc
//        adc a,#freqtable & 255
//        rol temp3
//        mov temp1,a
//        pop psw
//        mov a,0x43
//        rol a
//        ror temp3
//        adc a,#freqtable >> 8
//        mov temp2,a
//
//        mov y,#0
//        mov a,[temp1]+y
//        mov 0xF2,#2
//        mov 0xF3,a
//
//        inc y
//        mov a,[temp1]+y
//        mov 0xF2,#3
//        mov 0xF3,a
//
//        jmp !nextsq0
//
//
//skipsweep0:
        
//-------------------------------------

                        // check if sweeps are enabled
        mov a,0x41
        and a,#10000000b
        beq skip00
        mov a,0x41
        and a,#00000111b
        beq skip00

        call !check_timers
        bra nextsq0

skip00:


        mov a,sq4003            // check if freq is 0 or too high
        and a,#00000111b
        bne ok1
        mov a,sq4002
        //cmp a,#8
        //bcc silence
ok1:
        



        and 0x43,#00000111b

        mov a,0x42
        clrc
        rol a
        push psw
        clrc
        adc a,#freqtable&255
        rol temp3
        mov temp1,a
        pop psw
        mov a,0x43
        rol a
        ror temp3
        adc a,#freqtable/256
        mov temp2,a

		mov	x,#0x02
		call !change_pulse

//-----------------------------------------------

nextsq0:

        mov a,sq4000            // check volume decay disable
        and a,#00010000b
        bne decay_disabled

        call !check_timer3

        mov a,no4016
        and a,#00000001b
        beq no_reset

//        mov a,sq4000
//        and a,#00001111b
//        mov x,a
//        mov a,!volume_decay_rates+X
//        mov decay1rate,a
        bra no_reset


volume_decay_rates:
        .db 3
        .db 6
        .db 9
        .db 12
        .db 15
        .db 18
        .db 21
        .db 24
        .db 27
        .db 30
        .db 33
        .db 36
        .db 40
        .db 44
        .db 48
        .db 52
        .db 56

//        mov a,sq4000
//        and a,#00001111b
//        mov x,a
//        mov a,!volume_decay_table+X
//        mov 0xF2,#0x07
//        mov 0xF3,a
//
//        mov 0xF2,#0x08             // envx
//        mov 0xF3,#01111000b
//
//
//        mov 0xF2,#0x04
//        mov 0xF3,puls0_sample
//        mov 0xF2,#0x4C
//        mov 0xF3,#00000001b
//
//        mov a,#0x1F
//        mov 0xF2,#0x08
//        mov 0xF3,a
//
//        bra write_volume

decay_disabled:
        mov 0xF2,#0x07
        mov 0xF3,#0x1F

        mov a,no4016
        and a,#20h
        beq mono

        mov a,sq4000
        and a,#00001111b
        asl a
        asl a
        asl a
//        asl a

        mov 0xF2,#0
        mov 0xF3,a
        mov 0xF2,#1
        mov 0xF3,#0
        bra no_reset


mono:
        mov a,sq4000            // emulate volume, square 0
        and a,#00001111b
        asl a
        asl a
        asl a

write_volume:
        mov 0xF2,#0              // write volume
        mov 0xF3,a
        mov 0xF2,#1
        mov 0xF3,a
//        mov 0xF3,#0

no_reset:



//=====================================

//-------------------------------------
square1:

        mov a,sound_ctrl
        and a,#00000010b
        bne sq1_enabled
silence2:
        mov 0xF2,#0x10
        mov 0xF3,#0
        mov 0xF2,#0x11
        mov 0xF3,#0
        jmp !triangle

sq1_enabled:


//-------------------------------------
                                // emulate duty cycle (select sample #)
                                // check first the octave sample to be played

        mov a,sq4004            // emulate duty cycle
        and a,#11000000b
		xcn	a

		and	puls1_sample,#0x03
		or	a,puls1_sample
        mov puls1_sample,a
        cmp a,puls1_sample_old
        beq sq2_no_change

sq2_sample_change:

        mov 0xF2,#0x14            // sample # reg
        mov 0xF3,puls1_sample

        mov 0xF2,#0x4C            // key on
        mov 0xF3,#00000010b

sq2_no_change:

        mov puls1_sample_old,puls1_sample
        

        


//        mov puls0_sample,#0
//
//        mov y,a
//
//        mov a,sq4003
//        and a,#00000111b
//        mov x,a
//        mov a,y
////        cmp x,#00000101b
////        beq pitch0
//        cmp x,#00000110b
//        beq pitch0
//        cmp x,#00000111b
//        beq pitch0
//
//        clrc
//        adc a,#4
//        mov puls0_sample,#1
//
//pitch0:
//        mov 0xF2,#0x04            // sample #
//        mov 0xF3,a
//
//        mov 0xF2,#0x4C            // key on
//        mov 0xF3,#00000001b          
//no_change:
//        mov pulse0dutyold,pulse0duty
//        mov puls0_sample_old,puls0_sample
//-------------------------------------


                        // check if sweeps are enabled
        mov a,0x45
        and a,#10000000b
        beq skip01
        mov a,0x45
        and a,#00000111b
        beq skip01

        call !check_timers2
        bra nextsq1

skip01:


        mov a,sq4007            // check if freq is 0 or too high
        and a,#00000111b
        bne ok2
        mov a,sq4006
        //cmp a,#8
        //bcc silence2
ok2:


        and 0x47,#00000111b

        mov a,0x46
        clrc
        rol a
        push psw
        clrc
        adc a,#freqtable&255
        rol temp3
        mov temp1,a
        pop psw
        mov a,0x47
        rol a
        ror temp3
        adc a,#freqtable/256
        mov temp2,a

		mov	x,#0x12
		call !change_pulse

//--------------------------------------

nextsq1:

        mov a,sq4004            // check decay disabled
        and a,#00010000b
        bne decay_disabled2

        mov a,no4016
        and a,#00000010b
        beq no_reset2
        bra no_reset2

//        mov a,sq4004
//        and a,#00001111b
//        mov x,a
//        mov a,!volume_decay_table+X
//        mov 0xF2,#0x17
//        mov 0xF3,a
//
//        mov 0xF2,#0x18             // envx
//        mov 0xF3,#01111000b
//
//
//        mov 0xF2,#0x14
//        mov 0xF3,puls0_sample
//        mov 0xF2,#0x4C
//        mov 0xF3,#00000010b
//
//        mov a,#0x1F
//        mov 0xF2,#0x18
//        mov 0xF3,a
//
//        bra write_volume2

decay_disabled2:
        mov 0xF2,#0x17
        mov 0xF3,#0x1F

        mov a,no4016
        and a,#20h
        beq mono2

        mov a,sq4004
        and a,#00001111b
        asl a
        asl a
        asl a
//        asl a

        mov 0xF2,#0x10
        mov 0xF3,#0
        mov 0xF2,#0x11
        mov 0xF3,a
        bra no_reset2
        

mono2:
        mov a,sq4004            // emulate volume, square 0
        and a,#00001111b
        asl a
        asl a
        asl a

write_volume2:
        mov 0xF2,#0x10            // write volume
//        mov 0xF3,#0
        mov 0xF3,a
        mov 0xF2,#0x11
        mov 0xF3,a

no_reset2:
 


//=====================================

//-------------------------------------
triangle:
        mov a,sound_ctrl
        and a,#00000100b        // check triangle bit of 0x4015
        bne tri_enabled

silence3:
        mov 0xF2,#0x20
        mov 0xF3,#0
        mov 0xF2,#0x21
        mov 0xF3,#0
        jmp !noise

tri_enabled:

//        mov a,no4016
//        and a,#00000100b
//        beq silence3

        mov a,tr4008
        beq silence3
        and a,#10000000b
        beq tri_length_enabled
        mov a,tr4008
        and a,#01111111b
        beq silence3

        mov a,no4016
        and a,#20h
        beq mono3

        mov a,pcm_raw
        lsr a
        mov temp_add,a
        mov a,#0x7F

        setc
        sbc a,temp_add

        mov 0xF2,#0x20
        mov 0xF3,a
        mov 0xF2,#0x21
        mov 0xF3,a

 
//        mov 0xF2,#0x20    // set volume
//        mov 0xF3,#0x3F
//        mov 0xF2,#0x21
//        mov 0xF3,#0x3F
	  
	  bra notimer
mono3:

        mov 0xF2,#20h
        mov 0xF3,#7Fh
        mov 0xF2,#21h
        mov 0xF3,#7Fh

        bra notimer

tri_length_enabled:

        mov a,no4016
        and a,#00000100b
        beq notimer
        mov a,tr4008
        and a,#01111111b
        mov y,#3
        mul ya
        mov linear_count_hi,y
        mov linear_count_lo,a

        mov a,0xFF                // clear counter
notimer:	  

        call !check_timer3



        and 0x4B,#00000111b

        mov a,0x4A
        clrc
        rol a
        push psw
        clrc
        adc a,#tritable&255
        rol temp3
        mov temp1,a
        pop psw
        mov a,0x4B
        rol a
        ror temp3
        adc a,#tritable/256
        mov temp2,a

        mov y,#0
        mov a,[temp1]+y
        mov 0xF2,#0x22
        mov 0xF3,a

        inc y
        mov a,[temp1]+y
		and	a,#0x1f
        mov 0xF2,#0x23
        mov 0xF3,a

		// Change sample
		mov a,[temp1]+y
		and	a,#0xe0
		xcn	a
		lsr	a
		adc	a,#triangle_sample_num	// Assume carry clear from LSR
		cmp	a,tri_sample
		beq	triangle_skip1
			mov	tri_sample,a
			mov	0xF2,#0x24			// Sample # reg
			mov	0xF3,a
			mov	0xF2,#0x4C			// Key on
			mov	0xF3,#0x04
triangle_skip1:

//=====================================

//-------------------------------------
noise:
        mov a,sound_ctrl
        and a,#00001000b
        bne noise_enabled

        mov 0xF2,#0x30
        mov 0xF3,#0
        mov 0xF2,#0x31
        mov 0xF3,#0

        bra noise_off

noise_enabled:
        mov a,no400C            // check decay disable
        and a,#00010000b
        bne decay_disabled3

        bra no_reset3

//        mov a,no4016
//        and a,#00001000b
//        beq no_reset3
//
//        mov a,no400C
//        and a,#00001111b
//        mov x,a
//        mov a,!volume_decay_table+X
//        mov 0xF2,#0x37
//        mov 0xF3,a
//
//        mov 0xF2,#0x38
//        mov 0xF3,#01111000b
//
//        mov 0xF2,#0x34
//        mov 0xF3,#0        //puls0_sample
//        mov 0xF2,#0x4C
//        mov 0xF3,#00001000b
//
//        mov a,#0x08
//        mov 0xF2,#0x38
//        mov 0xF3,a
//
//        bra write_volume3

decay_disabled3:
        mov 0xF2,#0x37
        mov 0xF3,#0x1F

        mov a,no4016
        and a,#20h
        beq mono4

        mov a,no400C
        and a,#00001111b
        bra write_volume3

mono4:
        mov a,no400C            // write noise volume
        and a,#00001111b
        asl a
        mov x,a


        mov a,pcm_raw
        lsr a
        lsr a
        mov temp_add,a
        mov a,x
        setc
        sbc a,temp_add
        bcs just_fine
        mov a,#0
just_fine:

//        mov 0xF2,#0x30
//        mov 0xF3,a
//        mov 0xF2,#0x31
//        mov 0xF3,a



//        asl a
//        asl a
//        asl a
write_volume3:
        mov 0xF2,#0x30
        mov 0xF3,a
        mov 0xF2,#0x31
        mov 0xF3,a

no_reset3:
//---------------------------------------
                                // write noise frequency
        mov a,no400E
        and a,#00001111b
        mov x,a
        mov a,!noise_freq_table+X

        mov 0xF2,#0x6C
        mov 0xF3,a


//        mov 0xF2,#0x6C
//        mov a,no400E
//        eor a,#0xFF
//        and a,#00001111b
//        asl a
//        or  a,#00100000b        // set echo disable
//        mov 0xF3,a               // write noise frequency

noise_off:

        jmp !next_xfer


//======================================
// timer notes:
//               linear counter
//               267.094 Timer2 units (15.6ms) for 1/240hz
//               267.094 / 3 = 89.031 (timer value)
//               4-bit counter / 3 is number of .25-frames passed
//                       maxmimum time allowed between checks
//                       before 4-bit overflow: 22.2 milliseconds!
//                       

enable_timer3:
        mov 0xF1,#0                              // disable timers
        mov 0xFC,#89				// 89 * 3 = 267
        mov 0xFB,#22                             // 22.2222 * 3 = 66.66666
        mov 0xFA,#22
        mov a,0xFF                               // clear counters
        mov a,0xFE
        mov a,0xFD
        mov 0xF1,#00000111b              // enable timers
        ret


check_timer3:
        mov a,0xFF               // timer's 4-bit counter
        mov timer3val,a

        mov a,sq4000
        and a,#00010000b
        beq decay1
        jmp !no_decay1
decay1:

        mov a,no4016
        and a,#00000001b
        beq no_decay_reset

        mov a,#00001111b        // reset decay
        mov decay1volume,a
        mov a,#0
        mov decay1rate,a

        mov a,decay_status
        or a,#00000001b
        mov decay_status,a

        bra write_decay_volume

no_decay_reset:

        mov a,decay_status
        and a,#00000001b
        bne no_decay1x
        jmp !no_decay1
no_decay1x:

        mov a,sq4000
        and a,#00001111b
        mov x,a

        mov a,timer3val
        clrc
        adc a,decay1rate
        mov decay1rate,a

        cmp a,!volume_decay_rates+X
        bcc no_decay1

        mov a,#0
        mov decay1rate,a

        mov a,decay1volume
        bne no_decay_end

        mov a,sq4000
        and a,#00100000b        // decay looping enabled?
        beq decay1_end
        mov a,#00010000b        // looped, reset volume
        mov decay1volume,a
        bra no_decay1

decay1_end:
        mov a,decay_status      // disabled!
        and a,#11111110b
        mov decay_status,a
        bra no_decay1

no_decay_end:
        dec decay1volume

write_decay_volume:
        mov a,decay1volume
        asl a
        asl a
        asl a
        mov x,a

        mov a,sound_ctrl
        and a,#00000001b
        beq silenced1

        mov a,sq4001
        and a,#10000000b
        beq okd1y
        mov a,sq4001
        and a,#00000111b
        beq okd1y
        bra ooykd

okd1y:
        mov a,sq4003
        and a,#00000111b
        bne okd1                // check if freq is 0 or too high
        mov a,sq4002
        //cmp a,#8
        //bcc silenced1
        bra okd1
        
ooykd:
        mov a,sweep_freq_lo
        and a,#00000111b
        bne okd1                // check if freq is 0 or too high
        mov a,sweep_freq_hi
        //cmp a,#8
        //bcc silenced1
        bra okd1

silenced1:
        mov x,#0
okd1:
        mov a,no4016
        and a,#20h
        beq monod1

        mov 0xF2,#0
        mov 0xF3,x
        mov 0xF2,#1
        mov 0xF3,#0
        bra no_decay1

monod1:
        mov 0xF2,#0              // write volume
        mov 0xF3,x
        mov 0xF2,#1
        mov 0xF3,x


no_decay1:

        mov a,sq4004
        and a,#00010000b
        beq decay2
        jmp !no_decay2
decay2:

        mov a,no4016
        and a,#00000010b
        beq no_decay_reset2

        mov a,#00001111b        // reset decay
        mov decay2volume,a
        mov a,#0
        mov decay2rate,a

        mov a,decay_status
        or a,#00000010b
        mov decay_status,a

        bra write_decay_volume2

no_decay_reset2:

        mov a,decay_status
        and a,#00000010b
        bne no_decay2x
        jmp !no_decay2
no_decay2x:

        mov a,sq4004
        and a,#00001111b
        mov x,a

        mov a,timer3val
        clrc
        adc a,decay2rate
        mov decay2rate,a

        cmp a,!volume_decay_rates+X
        bcc no_decay2

        mov a,#0
        mov decay2rate,a

        mov a,decay2volume
        bne no_decay_end2

        mov a,sq4004
        and a,#00100000b        // decay looping enabled?
        beq decay2_end
        mov a,#00010000b        // looped, reset volume
        mov decay2volume,a
        bra no_decay2

decay2_end:
        mov a,decay_status      // disabled!
        and a,#11111101b
        mov decay_status,a
        bra no_decay2

no_decay_end2:
        dec decay2volume

write_decay_volume2:
        mov a,decay2volume
        asl a
        asl a
        asl a
        mov x,a

        mov a,sound_ctrl
        and a,#00000010b
        beq silenced2

        mov a,sq4005
        and a,#10000000b
        beq okd2y
        mov a,sq4005
        and a,#00000111b
        beq okd2y
        bra ooykd2

okd2y:
        mov a,sq4007
        and a,#00000111b
        bne okd2                // check if freq is 0 or too high
        mov a,sq4006
        //cmp a,#8
        //bcc silenced2
        bra okd2
        
ooykd2:


        mov a,sweep_freq_lo2
        and a,#00000111b
        bne okd2                // check if freq is 0 or too high
        mov a,sweep_freq_hi2
        //cmp a,#8
        //bcc silenced2
        bra okd2

silenced2:
        mov x,#0
okd2:
        mov a,no4016
        and a,#20h
        beq monod2

        mov 0xF2,#10h
        mov 0xF3,#0
        mov 0xF2,#11h
        mov 0xF3,x
        bra no_decay2

monod2:
        mov 0xF2,#0x10              // write volume
        mov 0xF3,x
        mov 0xF2,#0x11
        mov 0xF3,x


no_decay2:


        mov a,no400C
        and a,#00010000b
        bne no_decay3


        mov a,sound_ctrl
        and a,#00001000b
        beq no_decay3

        mov a,no4016
        and a,#00001000b
        beq no_decay_reset3

        mov a,#00001111b        // reset decay
        mov decay3volume,a
        mov a,#0
        mov decay3rate,a

        mov a,decay_status
        or a,#00001000b
        mov decay_status,a

        bra write_decay_volume3

no_decay_reset3:

        mov a,decay_status
        and a,#00001000b
        beq no_decay3

        mov a,no400C
        and a,#00001111b
        mov x,a

        mov a,timer3val
        clrc
        adc a,decay3rate
        mov decay3rate,a

        cmp a,!volume_decay_rates+X
        bcc no_decay3

        mov a,#0
        mov decay3rate,a

        mov a,decay3volume
        bne no_decay_end3

        mov a,no400C
        and a,#00100000b        // decay looping enabled?
        beq decay3_end
        mov a,#00010000b        // looped, reset volume
        mov decay3volume,a
        bra no_decay3

decay3_end:
        mov a,decay_status      // disabled!
        and a,#11110111b
        mov decay_status,a
        bra no_decay3

no_decay_end3:
        dec decay3volume

        mov a,sound_ctrl
        and a,#00001000b
        bne write_decay_volume3
        mov x,#0
        bra noise_decayed

write_decay_volume3:
        mov a,decay3volume
        asl a
//        asl a
//        asl a
        mov x,a

noise_decayed:
        mov 0xF2,#0x30              // write volume
        mov 0xF3,x
        mov 0xF2,#0x31
        mov 0xF3,x


no_decay3:


        mov a,sound_ctrl
        and a,#00000100b
        beq timer3_complete

        mov a,linear_count_hi
        bne needed
        mov a,linear_count_lo
        beq not_needed
needed:        
        mov a,timer3val

        clrc
        adc a,timer3count_lo
        mov timer3count_lo,a
        mov a,#0
        adc a,timer3count_hi
        mov timer3count_hi,a

        cmp a,linear_count_hi
        bcc timer3_ongoing

        mov a,timer3count_lo
        cmp a,linear_count_lo
        bcs timer3_complete
timer3_ongoing:        

        mov 0xF2,#0x20    // set volume
        mov 0xF3,#0x7F
        mov 0xF2,#0x21
        mov 0xF3,#0x7F

not_needed:
        ret

timer3_complete:
//        mov 0xF1,#0

        mov 0xF2,#0x20
        mov 0xF3,#0
        mov 0xF2,#0x21
        mov 0xF3,#0
        mov linear_count_lo,#0
        mov linear_count_hi,#0

        mov timer3count_lo,#0
        mov timer3count_hi,#0
        ret


        mov a,tr4008
        and a,#0
        ret


silencex1:
        mov 0xF2,#0
        mov 0xF3,#0
        mov 0xF2,#1
        mov 0xF3,#0
        
nonsweep:
        ret

check_timers:
        mov a,sq4001
        and a,#10000000b
        beq nonsweep
        mov a,sq4001
        and a,#00000111b
        beq nonsweep

        mov a,no4016
        and a,#01000000b
        beq nofreqchange

        and no4016,#10111111b   // disable!
        mov a,0xFD               // clear counter

        mov a,sq4002
        mov sweep_freq_lo,a
        mov a,sq4003
        and a,#00000111b
        mov sweep_freq_hi,a

        bne ok1x                // check if freq is 0 or too high
        mov a,sweep_freq_lo
        //cmp a,#8
        //bcc silencex1
ok1x:

        mov a,sweep_freq_hi
        and a,#11111000b
        bne silencex1


        mov a,sweep_freq_lo
        clrc
        rol a
        push psw
        clrc
        adc a,#freqtable&255
        rol temp3
        mov temp1,a
        pop psw
        mov a,sweep_freq_hi
        rol a
        ror temp3
        adc a,#freqtable/256
        mov temp2,a

		mov	x,#0x02
		call !change_pulse


nofreqchange:

        mov a,sq4001
        and a,#01110000b
        lsr a
        lsr a
        lsr a
        lsr a
        mov x,a

        mov a,0xFD
        clrc
        adc a,sweep1
        mov sweep1,a

        cmp a,!sweeptimes+x

        bcc nonsweep

        mov a,#0
        mov sweep1,a
        
        mov a,sweep_freq_lo
        mov sweeptemp1,a
        mov a,sweep_freq_hi
        mov sweeptemp2,a

        mov a,sq4001
        and a,#00000111b
        bne swcont
        ret

swcont:
        clrc
        ror sweeptemp2
        ror sweeptemp1
        dec a
        bne swcont

        mov a,sweeptemp1        // decrease by 1 (sweep channel difference)
        setc
        sbc a,#1
        mov sweeptemp1,a
        mov a,sweeptemp2
        sbc a,#0
        mov sweeptemp2,a


        mov a,sweep_freq_hi
        bne ok3x                // check if freq is 0 or too high
        mov a,sweep_freq_lo
        //cmp a,#8
        //bcc silencex2
ok3x:

        mov a,sweep_freq_hi
        and a,#11111000b
        bne silencex2

        
        mov a,sq4001
        and a,#00001000b
        bne decrease

        mov a,sweep_freq_lo
        clrc
        adc a,sweeptemp1
        mov sweep_freq_lo,a

        mov a,sweep_freq_hi
        adc a,sweeptemp2
        mov sweep_freq_hi,a
        bra swupdate

decrease:
        mov a,sweep_freq_lo
        setc
        sbc a,sweeptemp1
        mov sweep_freq_lo,a

        mov a,sweep_freq_hi
        sbc a,sweeptemp2
        mov sweep_freq_hi,a


swupdate:
        mov a,sweep_freq_hi
        bne ok2x                // check if freq is 0 or too high
        mov a,sweep_freq_lo
        //cmp a,#8
        //bcc silencex2
ok2x:

        mov a,sweep_freq_hi
        and a,#11111000b
        bne silencex2


        mov a,sweep_freq_lo
        clrc
        rol a
        push psw
        clrc
        adc a,#freqtable&255
        rol temp3
        mov temp1,a
        pop psw
        mov a,sweep_freq_hi
        rol a
        ror temp3
        adc a,#freqtable/256
        mov temp2,a

		mov	x,#0x02
		call !change_pulse

swzero:
        ret


silencex2:
        mov 0xF2,#0
        mov 0xF3,#0
        mov 0xF2,#1
        mov 0xF3,#0
        ret



sweeptimes:
        .db 3,6,9,12,15,18,21,24


silencex12:
        mov 0xF2,#0x10
        mov 0xF3,#0
        mov 0xF2,#0x11
        mov 0xF3,#0
        
nonsweepx:
        ret



check_timers2:
        mov a,sq4005
        and a,#10000000b
        beq nonsweepx
        mov a,sq4005
        and a,#00000111b
        beq nonsweepx

        mov a,no4016
        and a,#10000000b
        beq nofreqchangex

        and no4016,#01111111b   // disable!
        mov a,0xFE               // clear counter

        mov a,sq4006
        mov sweep_freq_lo2,a
        mov a,sq4007
        and a,#00000111b
        mov sweep_freq_hi2,a

        bne ok1x2               // check if freq is 0 or too high
        mov a,sweep_freq_lo2
        //cmp a,#8
        //bcc silencex12
ok1x2:

        mov a,sweep_freq_hi2
        and a,#11111000b
        bne silencex12


        mov a,sweep_freq_lo2
        clrc
        rol a
        push psw
        clrc
        adc a,#freqtable&255
        rol temp3
        mov temp1,a
        pop psw
        mov a,sweep_freq_hi2
        rol a
        ror temp3
        adc a,#freqtable/256
        mov temp2,a

		mov	x,#0x12
		call !change_pulse


nofreqchangex:

        mov a,sq4005
        and a,#01110000b
        lsr a
        lsr a
        lsr a
        lsr a
        mov x,a

        mov a,0xFE
        clrc
        adc a,sweep2
        mov sweep2,a

        cmp a,!sweeptimes+x

        bcc nonsweepx

        mov a,#0
        mov sweep2,a
        
        mov a,sweep_freq_lo2
        mov sweeptemp1,a
        mov a,sweep_freq_hi2
        mov sweeptemp2,a

        mov a,sq4005
        and a,#00000111b
        beq swzero2

swcont2:
        clrc
        ror sweeptemp2
        ror sweeptemp1
        dec a
        bne swcont2


        mov a,sweep_freq_hi2
        bne ok3x2               // check if freq is 0 or too high
        mov a,sweep_freq_lo2
        //cmp a,#8
        //bcc silencex22
ok3x2:

        mov a,sweep_freq_hi2
        and a,#11111000b
        bne silencex22

        
        mov a,sq4005
        and a,#00001000b
        bne decrease2

        mov a,sweep_freq_lo2
        clrc
        adc a,sweeptemp1
        mov sweep_freq_lo2,a

        mov a,sweep_freq_hi2
        adc a,sweeptemp2
        mov sweep_freq_hi2,a
        bra swupdate2

decrease2:
        mov a,sweep_freq_lo2
        setc
        sbc a,sweeptemp1
        mov sweep_freq_lo2,a

        mov a,sweep_freq_hi2
        sbc a,sweeptemp2
        mov sweep_freq_hi2,a


swupdate2:
        mov a,sweep_freq_hi2
        bne ok2x2               // check if freq is 0 or too high
        mov a,sweep_freq_lo2
        //cmp a,#8
        //bcc silencex22
ok2x2:

        mov a,sweep_freq_hi2
        and a,#11111000b
        bne silencex22


        mov a,sweep_freq_lo2
        clrc
        rol a
        push psw
        clrc
        adc a,#freqtable&255
        rol temp3
        mov temp1,a
        pop psw
        mov a,sweep_freq_hi2
        rol a
        ror temp3
        adc a,#freqtable/256
        mov temp2,a

		mov	x,#0x12
		call !change_pulse

swzero2:
        ret


silencex22:
        mov 0xF2,#0x10
        mov 0xF3,#0
        mov 0xF2,#0x11
        mov 0xF3,#0
        ret





//======================================
reset_dsp:
        mov y,#0
        mov x,#0
clear:
        mov 0xF2,x
        mov 0xF3,y
        inc x
        mov a,x
        and a,#00001111b
        cmp a,#0x0A
        bne clear
        mov a,x
        and a,#11110000b
        clrc
        adc a,#0x10
        mov x,a
        cmp x,#0x80
        bne clear

        mov a,#0x0C
clear2:
        mov 0xF2,a
        mov 0xF3,y
        clrc
        adc a,#0x10
        cmp a,#0x6C
        bne clear2

        mov a,#0x0D
clear3:
        mov 0xF2,a
        mov 0xF3,y
        clrc
        adc a,#0x10
        cmp a,#0x8D
        bne clear3

        mov a,#0x0F
clear4:
        mov 0xF2,a
        mov 0xF3,y
        clrc
        adc a,#0x10
        cmp a,#0x8F
        bne clear4

                                // clear zero-page
        mov a,#0
        mov x,#0xEF
clear5:
        mov 0x00+x,a
        dec x
        bne clear5
        mov 0x00,a

        ret


//======================================

set_directory:
        //mov a,#pulse0&255     // directory for Pulse 0
        //mov !0x0200,a
        //mov !0x0202,a
        //mov a,#pulse0/256
        //mov !0x0201,a
        //mov !0x0203,a

        //mov a,#pulse1&255     // directory for Pulse 1
        //mov !0x0204,a
        //mov !0x0206,a
        //mov a,#pulse1/256
        //mov !0x0205,a
        //mov !0x0207,a

        //mov a,#pulse2&255     // directory for Pulse 2
        //mov !0x0208,a
        //mov !0x020A,a
        //mov a,#pulse2/256
        //mov !0x0209,a
        //mov !0x020B,a

        //mov a,#pulse3&255     // directory for Pulse 3 (same as pulse1)
        //mov !0x020C,a
        //mov !0x020E,a
        //mov a,#pulse3/256
        //mov !0x020D,a
        //mov !0x020F,a

        //mov a,#triang&255     // directory for Triangle
        //mov !0x0240,a
        //mov !0x0342,a
        //mov a,#triang/256
        //mov !0x0341,a
        //mov !0x0343,a

		mov	x, #0x5f
set_directory_loop:
			mov	a,!set_directory_lut+x
			mov	!0x0200+x,a
			dec	x
			bpl	set_directory_loop

		// Set instrument memory allocation pointers
		mov	Spc_NewDataEP+0, #Spc_HeapStart
		mov	Spc_NewDataEP+1, #Spc_HeapStart/0x100
		mov	Dmc_DictionaryTop, #0
		mov	Spc_FreeInstrument, #0x20			// Not exact first free

        ret

set_directory_lut:
		.data16	_pulse0,_pulse0, _pulse0d,_pulse0d, _pulse0c,_pulse0c, _pulse0b,_pulse0b
		.data16	_pulse1,_pulse1, _pulse1d,_pulse1d, _pulse1c,_pulse1c, _pulse1b,_pulse1b
		.data16	_pulse2,_pulse2, _pulse2d,_pulse2d, _pulse2c,_pulse2c, _pulse2b,_pulse2b
		.data16	_pulse3,_pulse3, _pulse3d,_pulse3d, _pulse3c,_pulse3c, _pulse3b,_pulse3b
		.data16	_tri_samp0,_tri_samp0 _tri_samp1,_tri_samp1 _tri_samp2,_tri_samp2 _tri_samp3,_tri_samp3
		.data16	_tri_samp4,_tri_samp4 _tri_samp5,_tri_samp5 _tri_samp6,_tri_samp6 _tri_samp7,_tri_samp7

		.def	triangle_sample_num		0x10

//======================================

change_pulse:
		// Read frequency
        mov y,#0
        mov a,[temp1]+y
		mov	temp4,a
		mov	0xF5,a
        inc y
        mov a,[temp1]+y
		mov	temp5,a
		
		mov	0xF5,temp1
		mov	0xF6,temp2

		// Which sample are we using?
		mov	a,#0x00
		mov	y,#0x1f
		cmp	y,temp5
		bcc	change_pulse_1
			inc	a
			asl	temp4
			rol	temp5
			cmp	y,temp5
			bcc	change_pulse_1
				inc	a
				asl	temp4
				rol	temp5
				cmp	y,temp5
				bcc	change_pulse_1
					inc	a
					asl	temp4
					rol	temp5

change_pulse_1:
		// Which pulse channel?
		cmp	x,#0x10
		bcs	change_pulse_pulse1
			// Apply sample change
			and	puls0_sample,#0x0c
			or	a,puls0_sample
			mov puls0_sample,a
			cmp a,puls0_sample_old
			beq	change_pulse_rtn
			mov puls0_sample_old,puls0_sample

			mov 0xF2,#0x04            // sample # reg
			mov 0xF3,puls0_sample
			mov 0xF2,#0x4C            // key on
			mov 0xF3,#0x01

			// Apply frequency
			mov 0xF2,x
			mov 0xF3,temp4
			inc	x
			mov 0xF2,x
			mov 0xF3,temp5

			ret

change_pulse_pulse1:
			// Apply sample change
			and	puls1_sample,#0x0c
			or	a,puls1_sample
			mov puls1_sample,a
			cmp a,puls1_sample_old
			beq	change_pulse_rtn
			mov puls1_sample_old,puls1_sample

			mov 0xF2,#0x14            // sample # reg
			mov 0xF3,puls1_sample
			mov 0xF2,#0x4C            // key on
			mov 0xF3,#0x02

change_pulse_rtn:
		// Apply frequency
        mov 0xF2,x
        mov 0xF3,temp4
		inc	x
        mov 0xF2,x
        mov 0xF3,temp5
		ret

//======================================================================
//       DSP value            NES reg    NES decay       SPC decay       
//----------------------------------------------------------------------
//volume_decay_table:    ( no longer used )
//        .db 0x8D                 // 0x00   240Hz .25 sec   260 msec
//        .db 0x8A                 // 0x01   120Hz .5 sec    510 msec
//        .db 0x88                 // 0x02   80Hz .75 sec    770 msec
//        .db 0x87                 // 0x03   60Hz 1 sec      1 second
//        .db 0x86                 // 0x04   48Hz 1.25 sec   1.3 seconds
//        .db 0x85                 // 0x05   40Hz 1.5 sec    1.5 seconds
//        .db 0x85                 // 0x06   34Hz 1.764 sec  1.5 seconds
//        .db 0x84                 // 0x07   30Hz 2 sec      2.0 seconds
//        .db 0x83                 // 0x08   26Hz 2.307 sec  2.6 seconds
//        .db 0x83                 // 0x09   24Hz 2.5 sec    2.6 seconds
//        .db 0x83                 // 0x0A   21Hz 2.857 sec  2.6 seconds
//        .db 0x82                 // 0x0B   20Hz 3 sec      3.1 seconds
//        .db 0x82                 // 0x0C   18Hz 3.333 sec  3.1 seconds
//        .db 0x82                 // 0x0D   17Hz 3.529 sec  3.1 seconds
//        .db 0x81                 // 0x0E   16Hz 3.75 sec   4.1 seconds
//        .db 0x81                 // 0x0F   15Hz 4 sec      4.1 seconds
//======================================================================
//       DSP value            NES reg    NES noise freq  SPC noise freq
//----------------------------------------------------------------------
noise_freq_table:
        .db 00111111b           // 0x0                    32mhz
        .db 00111111b           // 0x1                    32mhz
        .db 00111111b           // 0x2                    32mhz
        .db 00111111b           // 0x3                    32mhz
        .db 00111111b           // 0x4                    32mhz
        .db 00111111b           // 0x5                    32mhz
        .db 00111110b           // 0x6                    16mhz
        .db 00111110b           // 0x7                    16mhz
        .db 00111110b           // 0x8    16744.04mhz     16mhz
        .db 00111110b           // 0x9    14080hz         16mhz
        .db 00111100b           // 0xA    9397.28hz       8.0mhz
        .db 00111011b           // 0xB    7040hz          6.4mhz
        .db 00111001b           // 0xC    4698.64hz       4.0mhz
        .db 00111000b           // 0xD    35200hz         3.2mhz
        .db 00110101b           // 0xE    17600 hz        1.6mhz
        .db 00110010b           // 0xF    880 hz          800hz
//======================================================================

// 1 sample
pulse0: .include "Project/Spc700/Data/pl1a-0.asm"
pulse1: .include "Project/Spc700/Data/pl1a-1.asm"
pulse2: .include "Project/Spc700/Data/pl1a-2.asm"
pulse3: .include "Project/Spc700/Data/pl1a-3.asm"

// 2 samples
pulse0d: .include "Project/Spc700/Data/pl1-0.asm"
pulse1d: .include "Project/Spc700/Data/pl1-1.asm"
pulse2d: .include "Project/Spc700/Data/pl1-2.asm"
pulse3d: .include "Project/Spc700/Data/pl1-3.asm"

// 4 samples
pulse0c: .include "Project/Spc700/Data/pl2-0.asm"
pulse1c: .include "Project/Spc700/Data/pl2-1.asm"
pulse2c: .include "Project/Spc700/Data/pl2-2.asm"
pulse3c: .include "Project/Spc700/Data/pl2-3.asm"

// 8 samples
pulse0b: .include "Project/Spc700/Data/pl3-0.asm"
pulse1b: .include "Project/Spc700/Data/pl3-1.asm"
pulse2b: .include "Project/Spc700/Data/pl3-2.asm"
pulse3b: .include "Project/Spc700/Data/pl3-3.asm"

freqtable: .include "Project/Spc700/Data/snestabl.asm"
tritable: .include "Project/Spc700/Data/tritabl3.asm"



//        .include "Project/Spc700/Data/sq2.asm"
//        .include "Project/Spc700/Data/peeko1.asm"

//        .include "Project/Spc700/Data/puls2y2.asm"
//        .include "Project/Spc700/Data/pl2.asm"


tri_samp0: .include "Project/Spc700/Data/tri6_sl3.asm"
tri_samp1: .include "Project/Spc700/Data/tri6_sl2.asm"
tri_samp2: .include "Project/Spc700/Data/tri6_sl1.asm"
tri_samp3: .include "Project/Spc700/Data/tri6.asm"
tri_samp4: .include "Project/Spc700/Data/tri6_sr1.asm"
tri_samp5: .include "Project/Spc700/Data/tri6_sr2.asm"
tri_samp6: .include "Project/Spc700/Data/tri6_sr3.asm"
tri_samp7: .include "Project/Spc700/Data/tri6_sr4.asm"
