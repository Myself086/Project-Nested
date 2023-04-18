
//======================================

	// Use: temp 1-8 (1-6 internally only after the calls were made)
update_dmc:
	bbs	sound_ctrl, 4, +b_1
		mov	0xf2, #0x5c					// Key off
		or	0xf3, #0x10

		ret
b_1:

	// Frequency
	mov	a, pcm_freq
	and	a, #0x0f
	mov	x, a
	mov	a, !dmc_pitch_table_lo+x
	mov	0xf2, #0x42					// Pitch LSB
	mov	0xf3, a
	mov	a, !dmc_pitch_table_hi+x
	mov	0xf2, #0x43					// Pitch MSB
	mov	0xf3, a

	bbc	no4016, 4, +b_return
		clr1	no4016, 4

		mov	0xf2, #0x5c					// Remove key off
		and	0xf3, #0xef

		// Start DMC instrument
		movw	ya, pcm_addr			// pcm_addr and pcm_length
		call	!get_dmc_instrument
		beq	+b_return					// Give up if instrument is null

		// Start playing this instrument
		mov	0xf2, #0x44					// Instrument number
		mov	0xf3, x

		// Apply loop flag
		call	!get_instrument_pointer
		mov	y, #0
		mov	a, [instrumentP]+y
		mov	temp1, a
		inc	y
		mov	a, [instrumentP]+y
		mov	temp2, a					// temp1 = Points to BRR start
		mov	y, #0xff
		mov	a, #0xfe					// YA = -2
		addw	ya, temp1
		movw	temp3, ya				// temp3 = Points to data header
		mov	y, #0
		mov	a, [temp3]+y
		mov	temp5, a
		inc	y
		mov	a, [temp3]+y
		mov	temp6, a					// temp5 = Data length
		mov	y, #0xff
		mov	a, #0xf7					// YA = -9
		addw	ya, temp3
		addw	ya, temp5				// YA now points to the last BRR block header
		movw	temp1, ya
		mov	y, #0
		mov	a, [temp1]+y
		or	a, #0x03					// Set end and loop
		bbs	pcm_freq, 6, +b_2			// Test NES loop flag
			and	a, #0xfd				// Remove SNES loop flag
b_2:
		mov	[temp1]+y, a

		mov	0xf2, #0x4c					// Key on
		mov	0xf3, #0x10

		mov	0xf2, #0x40					// Volume on
		mov	0xf3, #0x7f
		mov	0xf2, #0x41
		mov	0xf3, #0x7f
b_return:
	ret


dmc_pitch_table_lo:
	.fill	16
dmc_pitch_table_hi:
	.fill	16
	.macro	dmc_pitch_table		index, value
		.def	index__		Zero+{0}
		.def	value__		Zero+{1}
		.def	value__		value__*4096/32000*2
		.pushaddr
			.addr	dmc_pitch_table_lo+index__
			.data8	value__
			.addr	dmc_pitch_table_hi+index__
			.data8	value__/0x100
		.pulladdr
	.endm
	dmc_pitch_table		0x0, 4182
	dmc_pitch_table		0x1, 4710
	dmc_pitch_table		0x2, 5264
	dmc_pitch_table		0x3, 5593
	dmc_pitch_table		0x4, 6258
	dmc_pitch_table		0x5, 7046
	dmc_pitch_table		0x6, 7919
	dmc_pitch_table		0x7, 8363
	dmc_pitch_table		0x8, 9420
	dmc_pitch_table		0x9, 11186
	dmc_pitch_table		0xa, 12604
	dmc_pitch_table		0xb, 13983
	dmc_pitch_table		0xc, 16885
	dmc_pitch_table		0xd, 21307
	dmc_pitch_table		0xe, 24858
	dmc_pitch_table		0xf, 33144

//======================================

	// Entry: YA = Address-Length pair
	// Return: X = Instrument, P.z = X
	// Use: temp 1-8 (1-4 internally)
get_dmc_instrument:
	// Is this address range static?
	mov	x, a							// Test A's sign
	bmi	+b_else
		bbs	Spc_StaticRanges, 6, +b_1
		mov	x, #0
		ret
b_else:
		bbs	Spc_StaticRanges, 7, +b_1
		mov	x, #0
		ret
b_1:

	// Search for this instrument
	movw	temp3, ya
	mov	x, #0
	cmp	x, Dmc_DictionaryTop
	beq	+b_1
b_loop:
		// Test address-length pair
		mov	a, !Dmc_Dictionary+1+x
		mov	y, a
		mov	a, !Dmc_Dictionary+0+x
		cmpw	ya, temp3
		bne	+b_2
			// Return instrument
			mov	a, !Dmc_Dictionary+2+x
			mov	x, a
			ret
b_2:

		// Next
		inc	x
		inc	x
		inc	x
		cmp	x, Dmc_DictionaryTop
		bne	-b_loop
b_1:

	// Does not exist, create it if we have available space
	cmp	x, #0xfd
	bcs	+b_fail
		// Are there new instruments available?
		mov	a, Spc_FreeInstrument
		bmi	+b_fail

		// Allocate ((L * 16) + 1) * 9 + 2 bytes
		mov	a, temp4					// Load length
		mov	y, #16
		mul	ya							// (L * 16)
		inc	a							// () + 1
		movw	temp1, ya
		AslYA
		AslYA
		AslYA
		addw	ya, temp1				// () * 9
		inc	a
		inc	a							// + 2
		movw	temp1, ya				// Keep length for later
		call	!spc_malloc
		beq	+b_fail						// Give up if malloc failed
		movw	temp_pointer, ya		// Keep pointer for later

		// Create new instrument
		//movw	ya, temp_pointer
		call	!new_instrument
		beq	+b_fail						// Give up if instrument wasn't created
		push	x						// Keep instrument ID for later

		// List instrument
		mov	a, Dmc_DictionaryTop		// Increment Dmc_DictionaryTop but keep the previous value in X
		mov	x, a
		clrc
		adc	a, #3
		mov	Dmc_DictionaryTop, a
		movw	ya, temp3				// Load address-Length pair
		mov	!Dmc_Dictionary+0+x, a
		mov	a, y
		mov	!Dmc_Dictionary+1+x, a
		pop		a						// Load instrument ID
		push	a
		mov	!Dmc_Dictionary+2+x, a

		// Convert DMC samples
		movw	ya, temp3				// Load address-Length pair
		mov	x, temp1					// Load instrument ID
		call	!convert_dmc_samples

		// Return new instrument
		pop		x
		ret

b_fail:
	mov	x, #0
	ret

//======================================

	// Entry: YA = Address-Length pair, temp_pointer = BRR data pointer, temp1 = Data length
	// Use: temp 1-9, temp_pointer
	// temp1, temp2 = Data length (param)
	// temp3, temp4 = Address-Length pair (early only)
	// temp3, temp4 = Used for actual temp during the loop (late only)
	// temp5, temp6 = End data pointer
	// temp7, temp8 = DMC sample pointer
convert_dmc_samples:
	// Keep address-Length pair for later
	movw	temp3, ya

	// Calculate end pointer
	movw	ya, temp_pointer
	addw	ya, temp1
	movw	temp5, ya

	// Calculate DMC sample address: 0xC000 + (A * 64)
	mov	a, temp3
	mov	y, #64
	mul	ya								// (A * 64)
	mov	temp7, a						// LSB
	mov	a, y
	or	a, #0xc0
	mov	temp8, a						// MSB

	// Write length just before the BRR data
	mov	y, #0
	mov	a, temp1
	mov	[temp_pointer]+y, a
	incw	temp_pointer
	mov	a, temp2
	mov	[temp_pointer]+y, a
	incw	temp_pointer

	// Loop through the data
	mov	x, #0x00						// Sample value
b_loop:
		// Load next DMC sample
		mov	y, #0
		mov	a, [temp7]+y
		incw	temp7

		.macro	convert_sample
			lsr	a
			inc	x
			bcs	+b_1__
				dec	x
				dec	x
b_1__:
			mov	temp_sample{0}, x
		.endm
		convert_sample		0
		convert_sample		1
		convert_sample		2
		convert_sample		3
		convert_sample		4
		convert_sample		5
		convert_sample		6
		convert_sample		7

		// Test shift
		mov	y, temp_sample0
		mov	a, !brr_shift_table+y
		mov	y, temp_sample1
		or	a, !brr_shift_table+y
		mov	y, temp_sample2
		or	a, !brr_shift_table+y
		mov	y, temp_sample3
		or	a, !brr_shift_table+y
		mov	y, temp_sample4
		or	a, !brr_shift_table+y
		mov	y, temp_sample5
		or	a, !brr_shift_table+y
		mov	y, temp_sample6
		or	a, !brr_shift_table+y
		mov	y, temp_sample7
		or	a, !brr_shift_table+y
		beq	+b_1
b_in:
			// Emulate floor and ceiling
			push	a
			and	a, #0x04				// Test overflow
			beq	+b_2
				mov	a, x				// Test X's sign
				bmi	+b_else2
					call	!brr_ceiling
					bra	+b_2
b_else2:
					call	!brr_floor
b_2:
			pop		a
			and	a, #0x03				// 2 shifts max

			// Shift our BRR block
			mov	y, #0					// Shift counter
b_loop2:
				inc	y
				lsr	temp_sample0
				lsr	temp_sample1
				lsr	temp_sample2
				lsr	temp_sample3
				lsr	temp_sample4
				lsr	temp_sample5
				lsr	temp_sample6
				lsr	temp_sample7
				lsr	a
				bne	-b_loop2
			mov	a, y
			xcn	a
b_1:

		// Write BRR header
		clrc
		adc	a, #0x90
		mov	y, #0
		mov	[temp_pointer]+y, a

		// Write BRR block
		push	x
		mov	y, #8
b_loop2:
			// Copy data
			mov	a, !temp_sample0-1+y
			and	a, #0x0f
			mov	x, a
			mov	a, !brr_double_sample+x
			mov	[temp_pointer]+y, a

			// Next
			dec	y
			bne	-b_loop2
		pop		x

		// Interrupt if communication started (TODO)

		// Next
		mov	a, #9
		mov	y, #0
		addw	ya, temp_pointer
		movw	temp_pointer, ya
		cmpw	ya, temp5
		bcs	+b_exit
		jmp	!b_loop
b_exit:

	ret


brr_floor:
	.macro	brr_floor	index
		bbs	temp_sample{0}, 5, +b_1__
			call	!brr_inc_from{0}
b_1__:
	.endm
	brr_floor	0
	brr_floor	1
	brr_floor	2
	brr_floor	3
	brr_floor	4
	brr_floor	5
	brr_floor	6
	brr_floor	7
	ret


brr_ceiling:
	.macro	brr_ceiling	index
		bbc	temp_sample{0}, 5, +b_1__
			call	!brr_dec_from{0}
b_1__:
	.endm
	brr_ceiling	0
	brr_ceiling	1
	brr_ceiling	2
	brr_ceiling	3
	brr_ceiling	4
	brr_ceiling	5
	brr_ceiling	6
	brr_ceiling	7
	ret


brr_dec_from0:
	dec	temp_sample0
brr_dec_from1:
	dec	temp_sample1
brr_dec_from2:
	dec	temp_sample2
brr_dec_from3:
	dec	temp_sample3
brr_dec_from4:
	dec	temp_sample4
brr_dec_from5:
	dec	temp_sample5
brr_dec_from6:
	dec	temp_sample6
brr_dec_from7:
	dec	temp_sample7
	dec	x
	ret


brr_inc_from0:
	inc	temp_sample0
brr_inc_from1:
	inc	temp_sample1
brr_inc_from2:
	inc	temp_sample2
brr_inc_from3:
	inc	temp_sample3
brr_inc_from4:
	inc	temp_sample4
brr_inc_from5:
	inc	temp_sample5
brr_inc_from6:
	inc	temp_sample6
brr_inc_from7:
	inc	temp_sample7
	inc	x
	ret


	// TODO: Reduce the amount of bytes used by this table
brr_shift_table:
	.fill	8, 0x0		//0
	.fill	8, 0x1		//1
	.fill	16, 0x3		//2
	.fill	32, 0x7		//3
	.fill	64, 0xf		//4
	.fill	64, 0xf		//4
	.fill	32, 0x7		//3
	.fill	16, 0x3		//2
	.fill	8, 0x1		//1
	.fill	8, 0x0		//0

brr_double_sample:
	.data8	0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77
	.data8	0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff

//======================================

	// Entry: YA = Pointer
	// Return: X = Non-zero instrument when successful, P.z = X
	// Use: temp 7-8
new_instrument:
	// Get new instrument
	mov	x, Spc_FreeInstrument
	bmi	+b_return						// Give up if no more instrument IDs are available
		// Keep data pointer for later
		movw	temp7, ya
		incw	temp7
		incw	temp7					// +2 to reserve space for a length header

		// Get instrument pointer
		call	!get_instrument_pointer

		// Write instrument sample pointers
		mov	a, temp7
		mov	y, #0
		mov	[instrumentP]+y, a
		mov	y, #2
		mov	[instrumentP]+y, a
		mov	a, temp8
		inc	y
		mov	[instrumentP]+y, a
		mov	y, #1
		mov	[instrumentP]+y, a

		// Return and increment instrument count
		mov	x, Spc_FreeInstrument
		inc	Spc_FreeInstrument
		mov	a, x						// Compare X to 0

b_return:
	ret

//======================================

get_instrument_pointer:
	mov	a, x
	mov	y, #4
	mul	ya
	inc	y
	inc	y
	movw	instrumentP, ya
	ret

//======================================
