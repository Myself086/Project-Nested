
	//                   0           2
	// Heapstack format: _FirstByte, _LastByte

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Memory__Alloc
	// Entry: A = Bank number, X = Length
	// Return: A = Bank number, X = Memory address, Y = HeapStack pointer
Memory__Alloc:
	phb

	.local	_length, _bank, _addr

	stx	$.length

	// Which bank? Only allowing 0x7e-0x7f or 0xc0-0xff (ROM range defined in RomInfo)
	and	#0x00ff
	sta	$.bank
	eor	#0x007e
	lsr	a
	bne	$+Memory__Alloc_Rom

Memory__Alloc_LoopBank:
		// Can we allocate enough memory in this bank?
		lda	$.bank
		ldx	$.length
		call	Memory__CanAlloc
		bcs	$+Memory__Alloc_LoopBank_end

		// Can we allocate enough memory in the other bank?
		lda	$.bank
		eor	#0x0001
		sta	$.bank
		ldx	$.length
		call	Memory__CanAlloc
		bcs	$+Memory__Alloc_LoopBank_end

		// Out of memory
		unlock
		trap
		Exception	"Out of Memory{}{}{}Memory.Alloc attempted to allocate 0x{X:X} bytes but WRAM is full.{}{}Try following step 5 on the exe's main window. This will reduce memory usage and improve performance."
Memory__Alloc_LoopBank_end:

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


Memory__Alloc_Rom:
	// ROM range
	lda	$=RomInfo_StaticRecBanks
	sta	$.bank
Memory__Alloc_LoopRomBanks:
		// Can we allocate enough memory in this bank?
		lda	$.bank
		ldx	$.length
		call	Memory__CanAllocRom
		bcs	$+Memory__Alloc_LoopRomBanks_end
			inc	$.bank
			lda	$.bank
			xba
			cmp	$.bank
			bcc	$-Memory__Alloc_LoopRomBanks
			beq	$-Memory__Alloc_LoopRomBanks
				ldx	$.length
				unlock
				trap
				// TODO: Throw exception on the exe
Memory__Alloc_LoopRomBanks_end:

	// Change bank and clear carry
	sep	#0x20
	lda	$.bank
	pha
	rep	#0x21
	plb

	// Add memory to the top of the heap
	lda	$_Memory_Top-0x8000
	tax
	adc	$.length
	sta	$_Memory_Top-0x8000

	// Return
	lda	$.bank
	plb
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
	Exception	"Memory Trim Failed{}{}{}Memory.Trim attempted to allocate more bytes than its original size.{}0x{X:X} -> 0x{A:X}"

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Memory__CanAlloc
	// Entry: A = Bank number, X = Length
	// Return: Carry = true when memory can be allocated
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
	// Do we have enough space? Return carry==true if so
	cmp	$.temp

	plb
	return

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Memory__CanAllocRom
	// Entry: A = Bank number, X = Length
	// Return: Carry = true when memory can be allocated
Memory__CanAllocRom:
	phb
	// Change bank and set carry for later
	sep	#0x21
	pha
	rep	#0x20
	plb

	.local	_temp
	stx	$.temp

	// Get total space between Top and HeapStack, -0x10 for write overflow
	lda	$_Memory_HeapStack-0x8000
	sbc	$_Memory_Top-0x8000
	sbc	#0x0010
	// Do we have enough space? Return carry==true if so
	cmp	$.temp
	
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
