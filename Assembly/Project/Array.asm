
	//               0         3      6     9
	// Array format: =current, =base, =top, _increment

	// ---------------------------------------------------------------------------

Array__Resize_Error:
		unlock
		trap
		Exception	"Array resize fail{}{}{}Array can't be sized down below their current amount of data used."

	.mx	0x00
	.func	Array__Resize
	// Entry: X = List Pointer, Y = New size
	// Return: X = List Pointer
Array__Resize:
	.local	_listPointer
	.local	_bytesUsed
	.local	_newSize
	.local	=originalData
	.local	=newData

	stx	$.listPointer
	sty	$.newSize
	lda	$0x0000,x
	sec
	sbc	$0x0003,x
	clc
	adc	$0x0009,x
	sta	$.bytesUsed

	// Are we resizing to a smaller size than required for our data?
	cpy	$.bytesUsed
	bcc	$-Array__Resize_Error

	// Keep original data pointer
	lda	$0x0003,x
	sta	$.originalData+0
	lda	$0x0004,x
	sta	$.originalData+1

	// Allocate memory
	tyx
	lda	#0x007e
	call	Memory__Alloc
	// Return: A = Bank number, X = Memory address, Y = HeapStack pointer

	// Keep local pointer
	smx	#0x20
	sta	$.newData+2
	stx	$.newData+0

	// Set bank number
	ldy	$.listPointer
	sta	$0x0008,y
	sta	$0x0005,y
	sta	$0x0002,y
	smx	#0x00
	// Set base address
	txa
	sta	$0x0003,y
	// Set current address
	clc
	adc	$.bytesUsed
	sec
	sbc	$0x0009,y
	sta	$0x0000,y
	// Set top address
	lda	$0x0003,y
	clc
	adc	$.newSize
	dec	a
	sta	$0x0006,y

	// Copy bytes over
	lda	$.bytesUsed
	dec	a
	and	#0xfffe
	tay
b_loop:
		lda	[$.originalData],y
		sta	[$.newData],y
		dey
		dey
		bpl	$-b_loop

	// TODO: Deallocate old memory

	ldx	$.listPointer

	return

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Array__Insert
	// Entry: X = List Pointer

Array__Insert_Resize:
		// Double the size of the array
		lda	$0x0006,x
		sec
		sbc	$0x0003,x
		inc	a
		asl	a
		tay
		call	Array__Resize

Array__Insert:
	.local	=p

	// Increment
	lda	$0x0009,x
	tay
	clc
	adc	$0x0000,x
	sta	$0x0000,x
	sta	$.p

	// Can we increment one more time?
	adc	$0x0009,x
	cmp	$0x0006,x

	// Is array full?
	bcs	$-Array__Insert_Resize

	// Change mode
	sep	#0x20
	.mx	0x20

	// Zero out the next element
	lda	$0x0002,x
	sta	$.p+2
	lda	#0x00
Array__Insert_loop1:
	dey
	sta	[$.p],y
	bne	$-Array__Insert_loop1

	// Return
	rep	#0x30
	return

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	Array__InsertAt
	// Entry: X = List Pointer, Y = Insert at

Array__InsertAt_Resize:
		// Double the size of the array
		lda	$0x0006,x
		sec
		sbc	$0x0003,x
		inc	a
		asl	a
		tay
		call	Array__Resize
		bra	$+b_in

Array__InsertAt:
	.local	=p, _at, _listPointer, _inc, _x, _bytes, _tempElement

	// Save some params
	tya
	clc
	adc	$0x0003,x
	sta	$.at
	stx	$.listPointer

b_in:
	// Increment
	lda	$0x0009,x
	sta	$.inc
	tay
	clc
	adc	$0x0000,x
	sta	$.p

	// Can we increment two more times?
	adc	$.inc
	adc	$.inc
	cmp	$0x0006,x

	// Is array full?
	bcs	$-Array__InsertAt_Resize

	// Keep bank number
	phb

	// Move new bytes up by one element, assume carry clear from last compare
	lda	$0x0000,x
	tax
	adc	$.inc
	tay
	sty	$.tempElement
	lda	$.inc
	dec	a
	// Mvn
	.data8	0x54, 0x7e, 0x7e

	// Move bytes
	// How many bytes to move?
	ldx	$.listPointer
	lda	$0x0000,x
	sec
	sbc	$.at
	sta	$.bytes
	// Destination and source
	lda	$.p
	dec	a
	tay
	sec
	sbc	$.inc
	tax
	// Mvp
	lda	$.bytes
	dec	a
	.data8	0x44, 0x7e, 0x7e

	// Move new element
	// Source
	ldx	$.tempElement
	// Destination
	ldy	$.at
	// Mvn and plb
	lda	$.inc
	dec	a
	.data8	0x54, 0x7e, 0x7e
	plb

	// Copy new current pointer
	ldx	$.listPointer
	lda	$.p
	sta	$0x0000,x

	// Change mode
	sep	#0x20
	.mx	0x20

	// Zero out the next element
	ldy	$.inc
	lda	$0x0002,x
	sta	$.p+2
	lda	#0x00
Array__InsertAt_loop1:
	dey
	sta	[$.p],y
	bne	$-Array__InsertAt_loop1

	// Return
	rep	#0x30
	return

	// ---------------------------------------------------------------------------
	
	.mx	0x00
	.func	Array__InsertIfDifferentBase
	// Entry: X = List Pointer, Y = Compare length
	// Return: A = Index offset
Array__InsertIfDifferentBase:
	ldy	$0x0009,x

	// Function override
	.pushaddr
	call	Array__InsertIfDifferent
	.pulladdr

	.func	Array__InsertIfDifferent
Array__InsertIfDifferent:
	.local	_listPointer

	// Keep list pointer
	stx	$.listPointer

	// Find match
	call	Array__Find

	tay
	bpl	$+Array__InsertIfDifferent__SkipNew
		ldx	$.listPointer

		// Keep index of new element
		.local	_index
		lda	$0x0000,x
		sec
		sbc	$0x0003,x
		sta	$.index

		// Accept insert
		call	Array__Insert

		lda	$.index
		return
Array__InsertIfDifferent__SkipNew:

	return
	
	// ---------------------------------------------------------------------------

Array__Find_IncError:
		unlock
		trap
		Exception	"Find length too large{}{}{}Array.Find attempted to search for a larger sequence of bytes than programmed for."

	.mx	0x00
	.func	Array__Find
	// Entry: X = List Pointer, Y = Compare length
	// Return: A = 16-bit index of element, or negative (0xffff) if not found, P.n = Set when not found
Array__Find:
	lda	#0
	//bra	$+Array__Find2
	FakeCall	Array__Find2

	.mx	0x00
	.func	Array__Find2
	// Entry: A = Compare start offset, X = List Pointer, Y = Compare length
	// Return: A = 16-bit index of element, or negative (0xffff) if not found, P.n = Set when not found
Array__Find2:
	.local	=pCurrent
	.local	=pThis
	.local	_listPointer
	.local	_inc
	.local	_cmpLength
	.local	_offset
	
	// Save compare length (optimized into Y register only)
	//sty	$.cmpLength

	// Keep list pointer
	stx	$.listPointer
	
	// Keep current and base address (optimized by merging 2x 24-bit copy)
	sta	$.offset
	clc
	adc	$0x0000,x
	sta	$.pCurrent
	lda	$0x0002,x
	sta	$.pCurrent+2

	// Keep base address + offset
	lda	$0x0004,x
	sta	$.pThis+1
	lda	$.offset
	clc
	adc	$.pThis
	sta	$.pThis

	// Keep increment
	lda	$0x0009,x
	sta	$.inc

	// Error out if cmpLength is too high
	cpy	#0x0009
	bcs	$-Array__Find_IncError

	// Which increment? Supports up to 8 at the moment
	// Assume carry clear from "asl a"
	tya
	asl	a
	tax
	jsr	($_Array__Find_calling,x)

	// Is it new?
	lda	$.pCurrent
	eor	$.pThis
	beq	$+Array__Find_NotFound

		ldx	$.listPointer
		lda	$.pThis
		sec
		sbc	$.offset
		sec
		sbc	$0x0003,x
		return

Array__Find_NotFound:
	dec	a
	return
	
	
Array__Find_loop0:
	bra	$-Array__Find_loop0

Array__Find_calling:
	.data16	_Array__Find_loop0
	.data16	_Array__Find_loop1
	.data16	_Array__Find_loop2
	.data16	_Array__Find_loop3
	.data16	_Array__Find_loop4
	.data16	_Array__Find_loop5
	.data16	_Array__Find_loop6
	.data16	_Array__Find_loop7
	.data16	_Array__Find_loop8
	
Array__Find_loop1:
	ldx	$.inc
	lda	[$.pCurrent]
	tay
	bra	$+Array__Find_loop1_QuickStart
Array__Find_loop1_reset:
Array__Find_loop1_inc:
	txa
	adc	$.pThis
	sta	$.pThis
Array__Find_loop1_0:
	tya
Array__Find_loop1_QuickStart:
	eor	[$.pThis]
	and	#0x00ff
	bne	$-Array__Find_loop1_inc
	// Return
	rts
	
Array__Find_loop2:
	ldx	$.inc
	lda	[$.pCurrent]
	tay
	bra	$+Array__Find_loop2_QuickStart
Array__Find_loop2_reset:
Array__Find_loop2_inc:
	txa
	adc	$.pThis
	sta	$.pThis
Array__Find_loop2_0:
	tya
Array__Find_loop2_QuickStart:
	eor	[$.pThis]
	bne	$-Array__Find_loop2_inc
	// Return
	rts
	
Array__Find_loop3:
	lda	[$.pCurrent]
	tax
	ldy	#0x0001
	bra	$+Array__Find_loop3_QuickStart
Array__Find_loop3_reset:
	ldy	#0x0001
Array__Find_loop3_inc:
	lda	$.inc
	adc	$.pThis
	sta	$.pThis
Array__Find_loop3_0:
	txa
Array__Find_loop3_QuickStart:
	eor	[$.pThis]
	bne	$-Array__Find_loop3_inc
	lda	[$.pCurrent],y
	eor	[$.pThis],y
	bne	$-Array__Find_loop3_inc
	// Return
	rts
	
Array__Find_loop4:
	lda	[$.pCurrent]
	tax
	ldy	#0x0002
	bra	$+Array__Find_loop4_QuickStart
Array__Find_loop4_reset:
	ldy	#0x0002
Array__Find_loop4_inc:
	lda	$.inc
	adc	$.pThis
	sta	$.pThis
Array__Find_loop4_0:
	txa
Array__Find_loop4_QuickStart:
	eor	[$.pThis]
	bne	$-Array__Find_loop4_inc
	lda	[$.pCurrent],y
	eor	[$.pThis],y
	bne	$-Array__Find_loop4_inc
	// Return
	rts
	
Array__Find_loop5:
	lda	[$.pCurrent]
	tax
	ldy	#0x0002
	bra	$+Array__Find_loop5_QuickStart
Array__Find_loop5_reset:
	ldy	#0x0002
Array__Find_loop5_inc:
	lda	$.inc
	adc	$.pThis
	sta	$.pThis
Array__Find_loop5_0:
	txa
Array__Find_loop5_QuickStart:
	eor	[$.pThis]
	bne	$-Array__Find_loop5_inc
	lda	[$.pCurrent],y
	eor	[$.pThis],y
	bne	$-Array__Find_loop5_inc
	iny
	lda	[$.pCurrent],y
	eor	[$.pThis],y
	bne	$-Array__Find_loop5_reset
	// Return
	rts
	
Array__Find_loop6:
	lda	[$.pCurrent]
	tax
	ldy	#0x0002
	bra	$+Array__Find_loop6_QuickStart
Array__Find_loop6_reset:
	ldy	#0x0002
Array__Find_loop6_inc:
	lda	$.inc
	adc	$.pThis
	sta	$.pThis
Array__Find_loop6_0:
	txa
Array__Find_loop6_QuickStart:
	eor	[$.pThis]
	bne	$-Array__Find_loop6_inc
	lda	[$.pCurrent],y
	eor	[$.pThis],y
	bne	$-Array__Find_loop6_inc
	ldy	#0x0004
	lda	[$.pCurrent],y
	eor	[$.pThis],y
	bne	$-Array__Find_loop6_reset
	// Return
	rts
	
Array__Find_loop7:
	lda	[$.pCurrent]
	tax
	ldy	#0x0002
	bra	$+Array__Find_loop7_QuickStart
Array__Find_loop7_reset:
	ldy	#0x0002
Array__Find_loop7_inc:
	lda	$.inc
	adc	$.pThis
	sta	$.pThis
Array__Find_loop7_0:
	txa
Array__Find_loop7_QuickStart:
	eor	[$.pThis]
	bne	$-Array__Find_loop7_inc
	lda	[$.pCurrent],y
	eor	[$.pThis],y
	bne	$-Array__Find_loop7_inc
	ldy	#0x0004
	lda	[$.pCurrent],y
	eor	[$.pThis],y
	bne	$-Array__Find_loop7_reset
	iny
	lda	[$.pCurrent],y
	eor	[$.pThis],y
	bne	$-Array__Find_loop7_reset
	// Return
	rts
	
Array__Find_loop8:
	lda	[$.pCurrent]
	tax
	ldy	#0x0002
	bra	$+Array__Find_loop8_QuickStart
Array__Find_loop8_reset:
	ldy	#0x0002
Array__Find_loop8_inc:
	lda	$.inc
	adc	$.pThis
	sta	$.pThis
Array__Find_loop8_0:
	txa
Array__Find_loop8_QuickStart:
	eor	[$.pThis]
	bne	$-Array__Find_loop8_inc
	lda	[$.pCurrent],y
	eor	[$.pThis],y
	bne	$-Array__Find_loop8_inc
	ldy	#0x0004
	lda	[$.pCurrent],y
	eor	[$.pThis],y
	bne	$-Array__Find_loop8_reset
	ldy	#0x0006
	lda	[$.pCurrent],y
	eor	[$.pThis],y
	bne	$-Array__Find_loop8_reset
	// Return
	rts

	// ---------------------------------------------------------------------------

Array__FindLow_IncError:
		unlock
		trap
		Exception	"Find length too large{}{}{}Array.Find attempted to search for a larger sequence of bytes than programmed for."

	.mx	0x00
	.func	Array__FindLow
	// Entry: X = List Pointer, Y = Compare length
	// Return: A = 16-bit index of element, or negative (0xf000) if not found
Array__FindLow:
	.local	=pCurrent
	.local	=pThis
	.local	_listPointer
	.local	_inc
	.local	_cmpLength
	
	// Save compare length (optimized into Y register only)
	//sty	$.cmpLength

	// Keep list pointer
	stx	$.listPointer
	
	// Keep current and base address (optimized by merging 2x 24-bit copy)
	lda	$0x0000,x
	sta	$.pCurrent
	lda	$0x0002,x
	sta	$.pCurrent+2

	// Keep base address
	//lda	$0x0003,x
	//sta	$.pThis
	lda	$0x0004,x
	sta	$.pThis+1

	// Keep increment
	lda	$0x0009,x
	sta	$.inc

	// Error out if cmpLength is too high
	cpy	#0x0009
	bcs	$-Array__FindLow_IncError

	// Which increment? Supports up to 8 at the moment
	// Assume carry clear from "asl a"
	tya
	asl	a
	tax
	jsr	($_Array__FindLow_calling,x)
	
	// Is it new?
	lda	$.pCurrent
	eor	$.pThis
	beq	$+Array__FindLow_NotFound

		ldx	$.listPointer
		lda	$.pThis
		sec
		sbc	$0x0003,x
		return

Array__FindLow_NotFound:
	dec	a
	return
	
	
Array__FindLow_loop0:
	bra	$-Array__FindLow_loop0

Array__FindLow_calling:
	.data16	_Array__FindLow_loop0
	.data16	_Array__FindLow_loop1
	.data16	_Array__FindLow_loop2
	.data16	_Array__FindLow_loop0
	.data16	_Array__FindLow_loop0
	.data16	_Array__FindLow_loop0
	.data16	_Array__FindLow_loop0
	.data16	_Array__FindLow_loop0
	.data16	_Array__FindLow_loop0
	
Array__FindLow_loop1:
	ldx	$.inc
	lda	[$.pCurrent]
	and	#0x00ff
	tay
	bra	$+Array__FindLow_loop1_QuickStart
Array__FindLow_loop1_reset:
Array__FindLow_loop1_inc:
	txa
	adc	$.pThis
	sta	$.pThis
Array__FindLow_loop1_0:
	tya
Array__FindLow_loop1_QuickStart:
	sep	#0x20
	cmp	[$.pThis]
	ror	a
	rep	#0x31
	bpl	$-Array__FindLow_loop1_inc
	// Return
	rts
	
Array__FindLow_loop2:
	ldx	$.inc
	lda	[$.pCurrent]
	tay
	bra	$+Array__FindLow_loop2_QuickStart
Array__FindLow_loop2_reset:
Array__FindLow_loop2_inc:
	txa
	clc
	adc	$.pThis
	sta	$.pThis
Array__FindLow_loop2_0:
	tya
Array__FindLow_loop2_QuickStart:
	cmp	[$.pThis]
	bcc	$-Array__FindLow_loop2_inc
	// Return
	rts
	
	// ---------------------------------------------------------------------------
	
	.mx	0x00
	.func	Array__Clear
	// Entry: X = List Pointer
Array__Clear:
	.local	_p, .p_b

	// Copy base address to current address, change to 8-bit midway
	lda	$0x0003,x
	sta	$0x0000,x
	sta	$.p
	// Continue in 8-bit mode
	sep	#0x20
	.mx	0x20
	lda	$0x0005,x
	sta	$0x0002,x
	sta	$.p+2
	
	// Zero out first element
	lda	#0x00
	ldy	$0x0009,x
Array__Insert_loop1:
	dey
	sta	[$.p],y
	bne	$-Array__Insert_loop1
	
	rep	#0x30
	.mx	0x00

	return

	// ---------------------------------------------------------------------------

Array__Sort_Error:
		unlock
		trap
		Exception	"Sort length too large{}{}{}Array.Sort attempted to sort for a larger sequence of bytes than programmed for."

	.mx	0x00
	.func	Array__SortBase
	// Entry: X = List Pointer, Y = Compare length
Array__SortBase:
	ldy	$0x0009,x

	// Function override
	.pushaddr
	call	Array__Sort
	.pulladdr

	.func	Array__Sort
Array__Sort:
	.local	_compareLength
	.local	_inc, _incX2
	.local	_firstP
	.local	_lastP
	.local	_swapC

	// Keep length
	sty	$.compareLength
	// TODO: Support other base length than 2
	cpy	#2
	bne	$-Array__Sort_Error

	// Keep pointers
	lda	$0x0003,x
	sta	$.firstP
	lda	$0x0009,x
	sta	$.inc
	asl	a
	sta	$.incX2
	lda	$0x0000,x
	sec
	sbc	$.inc
	sta	$.lastP

	// Does this array contain at least 2 elements?
	dec	a
	cmp	$.firstP
	bcs	$+Array__Sort_in
	return
Array__Sort_in:
	
	// Change bank
	phb
	lda	$0x0001,x
	pha
	plb
	plb
	
	.local	_bestFirstIndex, _bestLastIndex
	.local	_bestFirstValue, _bestLastValue
	.local	_index
Array__Sort_loop1:
		// Reset first and last values, also keep loop index in X
		ldx	$.firstP
		stx	$.bestLastIndex
		stx	$.bestFirstIndex
		lda	$0x0000,x
		sta	$.bestLastValue
		sta	$.bestFirstValue

		// Start Looking for better first and last
Array__Sort_loop1_loop:
			// Load value at this index
			lda	$0x0000,x

			// Is it lower than first value?
			cmp	$.bestFirstValue
			bcs	$+Array__Sort_loop1_loop_skipFirst
				sta	$.bestFirstValue
				stx	$.bestFirstIndex
Array__Sort_loop1_loop_skipFirst:

			// Is it greater than last value?
			cmp	$.bestLastValue
			bcc	$+Array__Sort_loop1_loop_skipLast
				sta	$.bestLastValue
				stx	$.bestLastIndex
				// Optimization for adc
				clc
Array__Sort_loop1_loop_skipLast:
			
			// Increment index
			txa
			adc	$.inc
			tax

			// Have we gone over limit? Optimized '>' because carry is assumed clear
			sbc	$.lastP
			// Next
			bcc	$-Array__Sort_loop1_loop

Array__Sort_loop1_next:
		// Is there an index conflict?
		lda	$.bestLastIndex
		cmp	$.firstP
		beq	$+Array__Sort_loop1_inConflict
		lda	$.bestFirstIndex
		cmp	$.lastP
		bne	$+Array__Sort_loop1_skipConflict
Array__Sort_loop1_inConflict:
			// Swap first and last
			lda	$.bestFirstIndex
			ldy	$.bestLastIndex
			ldx	$.incX2
			jsr	($_Array__Sort_SwapTable,x)

			// Redo this range
			jmp	$_Array__Sort_loop1
Array__Sort_loop1_skipConflict:

		// Swap with first
		lda	$.bestFirstIndex
		cmp	$.firstP
		beq	$+Array__Sort_loop1_skipSwapFirst
		ldy	$.firstP
		ldx	$.incX2
		jsr	($_Array__Sort_SwapTable,x)
Array__Sort_loop1_skipSwapFirst:

		// Swap with last
		lda	$.bestLastIndex
		cmp	$.lastP
		beq	$+Array__Sort_loop1_skipSwapLast
		ldy	$.lastP
		ldx	$.incX2
		jsr	($_Array__Sort_SwapTable,x)
Array__Sort_loop1_skipSwapLast:

		// Decrement last pointer
		lda	$.lastP
		sec
		sbc	$.inc
		sta	$.lastP

		// Increment first pointer
		ldx	$.inc
		txa
		clc
		adc	$.firstP
		sta	$.firstP

		// Next if first >= last
		cmp	$.lastP
		bcs	$+Array__Sort_loop1_exit
		jmp	$_Array__Sort_loop1
Array__Sort_loop1_exit:
	
Array__Sort_return:
	// Return
	plb
	return


	// Swap 0 to 8 bytes
Array__Sort_SwapTable:
	.data16	_Array__Sort_Swap0,
	.data16	_Array__Sort_Swap1, _Array__Sort_Swap2, _Array__Sort_Swap3, _Array__Sort_Swap4, 
	.data16	_Array__Sort_Swap5, _Array__Sort_Swap6, _Array__Sort_Swap7, _Array__Sort_Swap8, 
	
	// Entry: A = swapA, X = Free, Y = swapB

Array__Sort_Swap8:
	tax
	phd
	// Swap
	lda	$0x0000,x
	tcd
	lda	$0x0000,y
	sta	$0x0000,x
	tdc
	sta	$0x0000,y
	lda	$0x0002,x
	tcd
	lda	$0x0002,y
	sta	$0x0002,x
	tdc
	sta	$0x0002,y
	lda	$0x0004,x
	tcd
	lda	$0x0004,y
	sta	$0x0004,x
	tdc
	sta	$0x0004,y
	lda	$0x0006,x
	tcd
	lda	$0x0006,y
	sta	$0x0006,x
	tdc
	sta	$0x0006,y
	// Return
	pld
Array__Sort_Swap0:
	rts

Array__Sort_Swap6:
	tax
	phd
	// Swap
	lda	$0x0000,x
	tcd
	lda	$0x0000,y
	sta	$0x0000,x
	tdc
	sta	$0x0000,y
	lda	$0x0002,x
	tcd
	lda	$0x0002,y
	sta	$0x0002,x
	tdc
	sta	$0x0002,y
	lda	$0x0004,x
	tcd
	lda	$0x0004,y
	sta	$0x0004,x
	tdc
	sta	$0x0004,y
	// Return
	pld
	rts

Array__Sort_Swap4:
	tax
	phd
	// Swap
	lda	$0x0000,x
	tcd
	lda	$0x0000,y
	sta	$0x0000,x
	tdc
	sta	$0x0000,y
	lda	$0x0002,x
	tcd
	lda	$0x0002,y
	sta	$0x0002,x
	tdc
	sta	$0x0002,y
	// Return
	pld
	rts

Array__Sort_Swap2:
	tax
	// Swap
	lda	$0x0000,x
	sta	$.swapC
	lda	$0x0000,y
	sta	$0x0000,x
	lda	$.swapC
	sta	$0x0000,y
	// Return
	rts

Array__Sort_Swap7:
	tax
	phd
	// Swap
	lda	$0x0001,x
	tcd
	lda	$0x0001,y
	sta	$0x0001,x
	tdc
	sta	$0x0001,y
	lda	$0x0003,x
	tcd
	lda	$0x0003,y
	sta	$0x0003,x
	tdc
	sta	$0x0003,y
	lda	$0x0005,x
	tcd
	lda	$0x0005,y
	sta	$0x0005,x
	tdc
	sta	$0x0005,y
	// Swap 8-bit
	sep	#0x20
	.mx	0x20
	lda	$0x0000,x
	xba
	lda	$0x0000,y
	sta	$0x0000,x
	xba
	sta	$0x0000,y
	// Return
	rep	#0x20
	.mx	0x00
	pld
	rts

Array__Sort_Swap5:
	tax
	phd
	// Swap
	lda	$0x0001,x
	tcd
	lda	$0x0001,y
	sta	$0x0001,x
	tdc
	sta	$0x0001,y
	lda	$0x0003,x
	tcd
	lda	$0x0003,y
	sta	$0x0003,x
	tdc
	sta	$0x0003,y
	// Swap 8-bit
	sep	#0x20
	.mx	0x20
	lda	$0x0000,x
	xba
	lda	$0x0000,y
	sta	$0x0000,x
	xba
	sta	$0x0000,y
	// Return
	rep	#0x20
	.mx	0x00
	pld
	rts

Array__Sort_Swap3:
	tax
	// Swap
	lda	$0x0001,x
	sta	$.swapC
	lda	$0x0001,y
	sta	$0x0001,x
	lda	$.swapC
	sta	$0x0001,y
	// Swap 8-bit
	sep	#0x20
	.mx	0x20
	lda	$0x0000,x
	xba
	lda	$0x0000,y
	sta	$0x0000,x
	xba
	sta	$0x0000,y
	// Return
	rep	#0x20
	.mx	0x00
	rts

Array__Sort_Swap1:
	tax
	sep	#0x20
	.mx	0x20
	// Swap (23.3 cycles)
	lda	$0x0000,x
	xba
	lda	$0x0000,y
	sta	$0x0000,x
	xba
	sta	$0x0000,y
	// Return
	rep	#0x20
	.mx	0x00
	rts

	// ---------------------------------------------------------------------------

Array__DeleteDuplicates_Error:
		unlock
		trap
		Exception	"Delete length too large{}{}{}Array.DeleteDuplicates attempted to search for a larger sequence of bytes than programmed for."

	.mx	0x00
	.func	Array__DeleteDuplicates
	// Entry: X = List Pointer
Array__DeleteDuplicates:
	.local	_firstP, _lastP, _oobP, _length
	.local	_currentP
	.local	_temp

	// Keep list pointer for later
	.local	_listPointer
	stx	$.listPointer

	// Load first and last pointers
	lda	$0x0003,x
	sta	$.firstP
	sta	$.currentP
	lda	$0x0000,x
	sta	$.oobP
	sec
	sbc	$0x0009,x
	sta	$.lastP

	// Load length
	ldy	$0x0009,x
	sty	$.length
	// Support up to 8 bytes compare
	cpy	#9
	bcs	$-Array__DeleteDuplicates_Error

	// Change bank and clear carry
	sep	#0x20
	phb
	lda	$0x0002,x
	pha
	plb
	rep	#0x21

	// Which increment? Supports up to 8 at the moment
	tya
	asl	a
	tax
	jsr	($_Array__DeleteDuplicates_calling,x)

	// Restore bank
	plb

	// Change the current top end of this array list
	lda	$.oobP
	sta	($.listPointer)

	// Return
	return


Array__DeleteDuplicates_calling:
	.data16	_Array__DeleteDuplicates_loop0
	.data16	_Array__DeleteDuplicates_loop1
	.data16	_Array__DeleteDuplicates_loop2
	.data16	_Array__DeleteDuplicates_loop3
	.data16	_Array__DeleteDuplicates_loop4
	.data16	_Array__DeleteDuplicates_loop5
	.data16	_Array__DeleteDuplicates_loop6
	.data16	_Array__DeleteDuplicates_loop7
	.data16	_Array__DeleteDuplicates_loop8


Array__DeleteDuplicates_loop1:
Array__DeleteDuplicates_loop2:
Array__DeleteDuplicates_loop4:
Array__DeleteDuplicates_loop5:
Array__DeleteDuplicates_loop6:
Array__DeleteDuplicates_loop7:
Array__DeleteDuplicates_loop8:
Array__DeleteDuplicates_loop0:
	bra	$-Array__DeleteDuplicates_loop0


	// X = Left element, Y = Right element
Array__DeleteDuplicates_loop3:
	// Load lower bytes of current element
	ldy	$.currentP
	tyx
	lda	$0x0000,x
	// Start second loop
	bra	$+Array__DeleteDuplicates_loop3_loop

Array__DeleteDuplicates_loop3_next:
	// Load next element
	inx
	inx
	inx
	cpx	$.oobP
	bcs	$-Array__DeleteDuplicates_loop3_loopEnd
	txy
	// Load lower bytes of current element
	lda	$0x0000,y
	// Start second loop
	bra	$+Array__DeleteDuplicates_loop3_loop

Array__DeleteDuplicates_loop3_loopReloadA:
		lda	$0x0000,x
		
Array__DeleteDuplicates_loop3_loop:
		// Next
		iny
		iny
		iny
Array__DeleteDuplicates_loop3_loopRedo:
		cpy	$.oobP
		bcs	$-Array__DeleteDuplicates_loop3_next

Array__DeleteDuplicates_loop3_loopCmp:
		// Compare lower bytes of both elements
		cmp	$0x0000,y
		bne	$-Array__DeleteDuplicates_loop3_loop
		lda	$0x0001,x
		cmp	$0x0001,y
		bne	$-Array__DeleteDuplicates_loop3_loopReloadA

		// Write "Top element" into "Right element"
		stx	$.temp
		ldx	$.lastP
		lda	$0x0000,x
		sta	$0x0000,y
		lda	$0x0001,x
		sta	$0x0001,y

		// Decrement top by 1 element
		stx	$.oobP
		dex
		dex
		dex
		stx	$.lastP

		// Continue on the same index
		ldx	$.temp
		lda	$0x0000,x
		bra	$-Array__DeleteDuplicates_loop3_loopRedo

Array__DeleteDuplicates_loop3_loopEnd:
	rts


	// ---------------------------------------------------------------------------

