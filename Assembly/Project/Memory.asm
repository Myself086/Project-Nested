
	//                   0           2
	// Heapstack format: _FirstByte, _LastByte

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Memory__TryAlloc
	// Entry: A = Bank number, X = Length
	// Return: A = Bank number (positive), X = Memory address, Y = HeapStack pointer
	// Return2: A = Negative, X = Length
Memory__TryAlloc:
	phb

	.local	_length
	.local	_bank, _addr

	stx	$.length

	// Which bank? Only allowing 0x7e-0x7f or cart banks.
	and	#0x00ff
	sta	$.bank
	eor	#0x007e
	lsr	a
	bne	$+b_cart

b_loop:
		// Can we allocate enough memory in this bank?
		lda	$.bank
		ldx	$.length
		call	Memory__CanAlloc
		bcs	$+b_1

		// Can we allocate enough memory in the other bank?
		lda	$.bank
		eor	#0x0001
		sta	$.bank
		ldx	$.length
		call	Memory__CanAlloc
		bcs	$+b_1

		// WRAM banks are full
		bra	$+b_oom
b_1:

	// Change bank and set carry
	sep	#0x21
	lda	$.bank
	pha
	rep	#0x20
	plb

	// Push new memory block to HeapStack, assume carry set from sep
	lda	$_Memory_HeapStack
	sbc	#4
	tay
	sta	$_Memory_HeapStack

	// Add memory to the top of the heap
	lda	$_Memory_Top
	sta	$.addr
	clc
	adc	$.length
	sta	$_Memory_Top

	// Write address range to HeapStack
	dec	a
	sta	$0x0002,y
	ldx	$.addr
	txa
	sta	$0x0000,y

	// Return
	lda	$.bank
	plb
	return

	.unlocal	_bank, _addr


b_oom:	// Out Of Memory, not Out Of Mana
	lda	#0xffff
	ldx	$.length
	plb
	return


b_cart:
	// Cart range (ROM or SRAM)
	ldx	$_Memory__CartBanks
	beq	$-b_oom
	.local	_bankCount, =listP
	lda	$=Memory__CartBanks_CONSTBANK-1,x
	and	#0x00ff
	beq	$-b_oom
	sta	$.bankCount
	ldy	#_Memory__CartBanks_CONSTBANK/0x100
	sty	$.listP+1
	stx	$.listP
b_loop:
		// Can we allocte enough memory in this bank?
		lda	[$.listP]
		//and	#0x00ff
		ldx	$.length
		call	Memory__CanAllocCart
		bcs	$+b_1
			inc	$.listP
			dec	$.bankCount
			bne	$-b_loop
			bra	$-b_oom
b_1:

	// Change bank and clear carry
	sep	#0x30
	lda	[$.listP]
	tay
	pha
	rep	#0x31
	plb

	// Add memory to the top of the heap
	lda	$_Memory_Top-0x8000
	tax
	adc	$.length
	sta	$_Memory_Top-0x8000

	// Return
	tya
	plb
	return

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Memory__AllocMax
	// Return: A = Bank number, X = Memory address, Y = HeapStack pointer
Memory__AllocMax:
	.local	_bank7e

	// How many bytes are available in bank 0x7e?
	lda	#0x007e
	ldx	#0
	call	Memory__CanAlloc
	bcs	$+b_1
		// Can't alloc
		lda	#0
b_1:
	sta	$.bank7e

	// How many bytes are available in bank 0x7f?
	lda	#0x007f
	ldx	#0
	call	Memory__CanAlloc
	bcs	$+b_1
		// Can't alloc
		lda	#0
b_1:

	// Which bank has the most amount of bytes available?
	cmp	$.bank7e
	bcs	$+b_else
		// 0x7e
		ldx	$.bank7e
		lda	#0x007e
		bra	$+b_1
b_else:
		// 0x7f
		tax
		lda	#0x007f
b_1:

	.unlocal	_bank7e

	call	Memory__AllocInBank
	return

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Memory__AllocInBank
	// Entry: A = Bank number, X = Length
	// Return: A = Bank number, X = Memory address, Y = HeapStack pointer
	// Note: Unlike Memory__Alloc, this one will throw an error if the bank is full
Memory__AllocInBank:
	// Keep current bank number
	.local	_bank, _length
	sta	$.bank
	stx	$.length

	call	Memory__Alloc

	// Trap if bank is different
	cmp	$.bank
	bne	$+b_trap

	return

b_trap:
	ldx	$.length
	unlock
	trap
	Exception	"Out Of Bank Memory{}{}{}Memory.AllocInBank attempted to allocate 0x{X:X} bytes of memory in bank 0x{a:X} but it was full.{}{}This error should not be happening under normal circumstances."

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Memory__Alloc
	// Entry: A = Bank number, X = Length
	// Return: A = Bank number, X = Memory address, Y = HeapStack pointer
Memory__Alloc:
	call	Memory__TryAlloc
	ora	#0
	bmi	$+b_trap

	return

b_trap:
	unlock
	trap
	Exception	"Out of Memory{}{}{}Memory.Alloc attempted to allocate 0x{X:X} bytes but RAM is full.{}{}Try following step 5 on the exe's main window. This will reduce memory usage and improve performance."

	// ---------------------------------------------------------------------------

	.mx	0x00
	// Entry: int length
	// Return: int address
Memory__AllocForExe:
	FromExeInit16

	lda	#0x00ff
	ldx	$0x0000
	call	Memory__Alloc
	stx	$0x0000
	sta	$0x0002

	stp

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Memory__Trim	=StackPointer, _Length
Memory__Trim:
	phb
	// Change bank and set carry for later
	sep	#0x21
	lda	$.StackPointer+2
	pha
	rep	#0x20
	plb

	// Get current length
	ldy	#0x0002
	lda	($.StackPointer),y
	sbc	($.StackPointer)
	inc	a

	// Are we allowed to trim this memory range?
	cmp	$.Length
	bcc	$+b_trap

	// Is this memory range on top of the heap?
	lda	($.StackPointer),y
	inc	a
	cmp	$_Memory_Top
	bne	$+Memory__Trim_SkipTrimTop
		// Trim top of the heap as well
		lda	($.StackPointer)
		clc
		adc	$.Length
		sta	$_Memory_Top

		// Is the new size 0?
		lda	$.Length
		bne	$+Memory__Trim_SkipDelete
		// Is this memory range at the top of the stack?
		lda	$_Memory_HeapStack
		cmp	$.StackPointer
		bne	$+Memory__Trim_SkipDelete
			// Remove from stack and return
			clc
			adc	#4
			sta	$_Memory_HeapStack
			plb
			return
Memory__Trim_SkipDelete:
Memory__Trim_SkipTrimTop:

	// Write new size
	lda	($.StackPointer)
	clc
	adc	$.Length
	dec	a
	sta	($.StackPointer),y
	
	plb
	return

b_trap:
	ldx	$.Length
	unlock
	trap
	Exception	"Memory Trim Failed{}{}{}Memory.Trim attempted to allocate more bytes than its original size.{}0x{A:X} -> 0x{X:X}"

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Memory__CanAlloc
	// Entry: A = Bank number, X = Length
	// Return: A = Bytes available, Carry = true when memory can be allocated
Memory__CanAlloc:
	phb
	// Change bank and set carry for later
	sep	#0x21
	pha
	rep	#0x20
	plb

	.local	_temp
	stx	$.temp

	// Get total space between Top and HeapStack, -0x10 for stack allocation
	lda	$_Memory_HeapStack
	sbc	$_Memory_Top
	sbc	#0x0010
	bcc	$+b_return
	// Do we have enough space? Return carry==true if so
	cmp	$.temp

b_return:
	plb
	return

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Memory__CanAllocCart
	// Entry: A.lo = Bank number, X = Length
	// Return: A = Bytes available, Carry = true when memory can be allocated
Memory__CanAllocCart:
	// Is this bank valid?
	bit	#0x00ff
	bne	$+b_1
		clc
		return
b_1:

	phb
	// Change bank and set carry for later
	sep	#0x21
	pha
	rep	#0x20
	plb

	.local	_temp
	stx	$.temp

	// Get total space between Top and HeapStack, -0x10 for stack allocation
	lda	$_Memory_HeapStack-0x8000
	sbc	$_Memory_Top-0x8000
	sbc	#0x0010
	bcc	$+b_return
	// Do we have enough space? Return carry==true if so
	cmp	$.temp

b_return:
	plb
	return

	// ---------------------------------------------------------------------------
	
	.mx	0x00
	.func	Memory__Zero
	// Entry (same as Memory__Alloc's return): A = Bank number, X = Memory address, Y = HeapStack pointer
Memory__Zero:
	phb
	// Change bank and set carry for later
	sep	#0x21
	pha
	rep	#0x20
	plb

	// Do we have the correct address?
	txa
	cmp	$0x0000,y
	bne	$+b_trap

	// Get array length
	.local	_length
	lda	$0x0002,y
	sbc	$0x0000,y
	inc	a
	sta	$.length

	// Do we have less than 2 bytes?
	lsr	a
	bne	$+b_over1byte
		// Do we even have a byte?
		bcc	$+b_return
			// Clear single byte and return
			lda	#0xff00
			and	$0x0000,x
			sta	$0x0000,x
			bra	$+b_return
b_over1byte:

	// Do we have an odd number of bytes?
	bcc	$+b_notOdd
		// Clear first byte
		stz	$0x0000,x
		inx
b_notOdd:

	// Store number of iterations into Y and start looping
	tay
b_loop:
		// Clear 2 bytes
		stz	$0x0000,x

		// Next
		inx
		inx
		dey
		bne	$-b_loop

b_return:
	plb
	return

b_trap:
	unlock
	trap
	Exception	"Zero Memory Failed{}{}{}Memory.Zero attempted to clear the wrong array."

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Memory__TakeSramBank
	// Return: A = SRAM bank or null, P.z = A
Memory__TakeSramBank:
	phb

	ldx	$_Memory__CartBanks
	beq	$+b_returnNull
	.local	_bankCount, =listP
	lda	$=Memory__CartBanks_CONSTBANK-1,x
	and	#0x00ff
	beq	$+b_returnNull
	sta	$.bankCount
	ldy	#_Memory__CartBanks_CONSTBANK/0x100
	sty	$.listP+1
	stx	$.listP
b_loop:
		// Is this bank empty?
		smx	#0x20
		lda	[$.listP]
		pha
		smx	#0x00
		plb
		lda	$_Memory_Top-0x8000
		cmp	$_Memory_Bottom-0x8000
		bne	$+b_1
			// Remove this bank from Memory__CartBanks and return it to caller
			smx	#0x20
			lda	[$.listP]
			xba
			lda	#0
			sta	[$.listP]
			smx	#0x00

			plb
			xba							// Must be at the end to affect P.z
			return
b_1:

		// Next
		inc	$.listP
		dec	$.bankCount
		bne	$-b_loop

b_returnNull:
	plb
	lda	#0
	return

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Memory__FormatSram
Memory__FormatSram:
	php

	rep	#0x30
	.mx	0x00

	// Is SRAM present at bank b1?
	lda	$0xb07ffe		// First test for mirror
	tay
	lda	$0xb17ffe
	tax
	eor	#0x55aa
	sta	$0xb17ffe		// Change last bytes of bank b1
	cmp	$0xb17ffe
	beq	$+b_1
		unlock
		trap
		Exception	"SRAM is missing{}{}{}SRAM on your SNES emulator or flash cart device was not found. Make sure your SNES emulator or device is up to date.{}{}You can adjust the amount of SRAM on the exe's main window. Some SRAM sizes are not supported by some SNES emulators or devices."
b_1:

	// Test for minimum SRAM requirement for feedback: 16kb
	tya
	eor	$0xb07ffe		// Second test for mirror
	smx	#0x20
	beq	$+b_else
		// Deactivate SRM feedback
		lda	#0
		bra	$+b_1
b_else:
		// Activate SRM feedback
		lda	#0x80
b_1:
	sta	$_Feedback_Active
	smx	#0x00

	// Test SRAM size
	.local	_bankCount
	lda	#2
	sta	$.bankCount
	// Write unique value to test banks, both bytes must be different to account for open bus
	lda	#8
	sta	$0xa17ffe
	dec	a
	sta	$0xb97ffe
	dec	a
	sta	$0xb57ffe
	dec	a
	sta	$0xb37ffe
	dec	a
	sta	$0xb17ffe
	// Look for valid banks
	inc	a
	cmp	$0xb37ffe
	bne	$+b_1
		asl	$.bankCount
		inc	a
		cmp	$0xb57ffe
		bne	$+b_1
			asl	$.bankCount
			inc	a
			cmp	$0xb97ffe
			bne	$+b_1
				asl	$.bankCount
				inc	a
				cmp	$0xa17ffe
				bne	$+b_1
					asl	$.bankCount
b_1:

	// Restore last bytes of bank b1
	txa
	sta	$0xb17ffe

	// Allocate some memory for a list of banks
	ldx	$.bankCount
	dex
	cpx	#2
	bcs	$+b_1
		ldx	#1
b_1:
	lda	#_Memory__CartBanks_CONSTBANK/0x10000
	call	Memory__AllocInBank
	// Return: A = Bank number, X = Memory address, Y = HeapStack pointer
	.local	=list
	xba
	sta	$.list+1
	stx	$.list
	inx
	stx	$_Memory__CartBanks
	// Write length
	lda	$.bankCount
	dec	a
	dec	a
	smx	#0x20
	sta	[$.list]

	// Copy expected valid bank numbers
	inc16dp	list
	tax
	dex
	bmi	$+b_1
b_loop:
		lda	$=Memory__FormatSram_BankOrder,x
		txy
		sta	[$.list],y
		dex
		bpl	$-b_loop
b_1:

	smx	#0x00

	// Format SRAM
	ldx	$.bankCount
	dex
	dex
	dex
	bmi	$+b_1
b_loop:
		// Change bank
		lda	$=Memory__FormatSram_BankOrder,x
		sta	$.DP_ZeroBank

		// Write bottom and top addresses
		lda	#0x6000
		ldy	#_Memory_Bottom-0x8000
		sta	[$.DP_Zero],y
		ldy	#_Memory_Top-0x8000
		sta	[$.DP_Zero],y
		lda	#_Memory_HeapStack-0x8000-4
		ldy	#_Memory_HeapStack-0x8000
		sta	[$.DP_Zero],y

		// Next
		dex
		bpl	$-b_loop
b_1:

	// Calculate SRAM size in kilobytes
	lda	$.bankCount
	cmp	#3
	bcs	$+b_else
		// Between 0 and 8 kilobytes
		lda	$=Rom_SramSize
		and	#0x00ff
		cmp	#5
		bcc	$+b_else2
			// Size 5 or greater but assume 8 or 16 kilobytes
			lda	#16
			// Is feedback active?
			bit	$_Feedback_Active-1
			bmi	$+b_3
				lsr	a
b_3:
			tay
			bra	$+b_1
b_else2:
			// Size 0 to 3
			tax
			lda	$=Memory__FormatSram_SizeKb,x
			and	#0x00ff
			tay
			bra	$+b_1
b_else:
		// 16+ kilobytes
		asl	a
		asl	a
		asl	a
		ldy	#16
b_1:
	sta	$_Sram_SizeTotalKb
	sty	$_Sram_SizeNonDynamicKb

	plp
	return

Memory__FormatSram_BankOrder:
	.data8	0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf
	.data8	0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf

Memory__FormatSram_SizeKb:
	.data8	0, 2, 4, 8, 16

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Memory__FormatRom
Memory__FormatRom:
	.local	_thisBank, _lastBank, _bankCount
	lda	$=RomInfo_StaticRecBanks
	ora	#0x4040
	smx	#0x20
	sta	$.thisBank
	stz	$.thisBank+1
	xba
	sta	$.lastBank
	stz	$.lastBank+1
	smx	#0x00
	stz	$.bankCount

	// Allocate memory for our bank list
	ldx	#0x0090
	lda	#_Memory__CartBanks_CONSTBANK/0x10000
	call	Memory__AllocInBank
	// Return: A = Bank number, X = Memory address, Y = HeapStack pointer
	.local	=list
	xba
	sta	$.list+1
	inx
	stx	$.list
	stx	$_Memory__CartBanks

	stz	$.DP_Zero

b_loop:
		// Is this bank reserved?
		lda	$.thisBank
		smx	#0x20
		cmp	$=RomInfo_ReservedSnesBanks+0			// Low bound
		bcc	$+b_in
		cmp	$=RomInfo_ReservedSnesBanks+1			// High bound
		bcc	$+b_1
		beq	$+b_1
b_in:
			smx	#0x00

			// Set bank and add it to list
			sta	$.DP_ZeroBank
			ldy	$.bankCount
			sta	[$.list],y
			iny
			sty	$.bankCount

			// Write bottom and top addresses
			lda	#0x0000
			ldy	#_Memory_Bottom-0x8000
			sta	[$.DP_Zero],y
			ldy	#_Memory_Top-0x8000
			sta	[$.DP_Zero],y
			lda	#_Memory_HeapStack-0x8000-4
			ldy	#_Memory_HeapStack-0x8000
			sta	[$.DP_Zero],y
b_1:
		rep	#0x20

b_loop_next:
		// Are we done?
		lda	$.thisBank
		cmp	$.lastBank
		beq	$+b_loop_exit
		// Next bank
		inc	a
		ora	#0x0040
		sta	$.thisBank
		eor	#0x007e
		lsr	a
		beq	$-b_loop_next	// Skip banks 0x7e and 0x7f
		bra	$-b_loop
b_loop_exit:

	// Set number of banks
	dec	$.list
	smx	#0x20
	lda	$.bankCount
	sta	[$.list]

	// Activate SRM feedback (not necessary here but just in case this becomes an issue)
	lda	#0x80
	sta	$_Feedback_Active
	smx	#0x00

	return

	// ---------------------------------------------------------------------------
