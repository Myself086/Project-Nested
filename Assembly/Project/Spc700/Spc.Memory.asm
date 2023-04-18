
//======================================

	// Entry: YA = Length
	// Return: YA = Pointer, null if failed, P.z = YA
	// Use: temp 5-8
spc_malloc:
	// Keep length for later
	movw	temp7, ya

	// Copy pointer to be returned later
	movw	ya, Spc_NewDataEP
	movw	temp5, ya

	// Reserve length of data requested
	//movw	ya, Spc_NewDataEP
	addw	ya, temp7

	// Are we overflowing?
	cmp	y, #Spc_HeapStart_TOP/0x100
	bcs	+b_1
		// Acknowledge memory allocation
		movw	Spc_NewDataEP, ya

		// Return data pointer
		movw	ya, temp5
		ret
b_1:
		// Return null
		mov	a, #0
		mov	y, a
		ret

//======================================
