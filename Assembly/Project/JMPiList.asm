
	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	JMPi__Init
JMPi__Init:
	// Reset empty pointer
	lda	#_JMPi_EmptyPointer+2+JMPi_Inc
	sta	$=JMPi_EmptyPointer

	// Create dummy node
	lda	#0xff20
	sta	$=JMPi_EmptyPointer+2+0
	lda	#0x0000
	sta	$=JMPi_EmptyPointer+2+2
	sta	$=JMPi_EmptyPointer+2+3
	lda	#_JMPi_EmptyPointer+2
	sta	$=JMPi_EmptyPointer+2+5

	// Reset pointers to our dummy node
	//lda	#_JMPi_EmptyPointer+2
	ldx	#0x01fe
b_loop:
		sta	$=JMPi_Start,x
		dex
		dex
		bpl	$-b_loop

	return

	// ---------------------------------------------------------------------------

	.mx	0x00
	.func	JMPi__Add	=originalCall, =newAddr
JMPi__Add:
	.local	_nodeAddr

	// Reserve another node
	lda	$=JMPi_EmptyPointer
	sta	$.nodeAddr
	clc
	adc	#_JMPi_Inc

	// Do we have enough space for the new node?
	cmp	#_JMPi_ArrayTop+1
	trapcs
	Exception	"Indirect JMP List Full{}{}{}The list of known destinations for indirect JMP is full.{}{}Nothing can be done about it until a later version implements dynamic memory allocation for this list."

	// Write address back
	sta	$=JMPi_EmptyPointer

	// Get base array offset
	lda	$.originalCall
	and	#0x00ff
	asl	a
	tax

	// Replace base pointer to the new node
	lda	$=JMPi_Start,x
	tay
	lda	$.nodeAddr
	sta	$=JMPi_Start,x

	// Link new node to old node
	tax
	tya
	sta	$=JMPi_Bank+5,x

	// Write data to the new node
	lda	$.originalCall+1
	sta	$=JMPi_Bank+0,x
	lda	$.newAddr+0
	sta	$=JMPi_Bank+2,x
	lda	$.newAddr+1
	sta	$=JMPi_Bank+3,x

	return

	// ---------------------------------------------------------------------------
