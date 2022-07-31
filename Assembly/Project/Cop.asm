
	// ---------------------------------------------------------------------------

Cop__Table:
	.fill16	0x100, Cop__Error
	.macro	Cop__Table		ID, Address
		.pushaddr
			.addr	Cop__Table+{0}*2
			.data16	{1}
		.pulladdr
	.endm

	Cop__Table		0x00, Cop__Wait4Interrupt
	Cop__Table		0x01, Cop__Wait4VBlank
	Cop__Table		0x02, Cop__GetScanline			// A = Scanline
	Cop__Table		0x03, Cop__SetScanline			// Scanline = A
	Cop__Table		0x04, Cop__AddScanline			// Scanline += A
	Cop__Table		0x05, Cop__IncScanline			// Scanline++

	// ---------------------------------------------------------------------------

Cop__Error:
	trap
	Exception	"Unknown COP{}{}{}Opcode 0x02 (COP) was executed with an unknown operand.{}{}If you are using a patch, make sure you are using the correct SMC version."

	// ---------------------------------------------------------------------------

Cop__Wait4Interrupt:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		jsr	$=Interpret__Idle
b_1:
	CoreCall_End

	// ---------------------------------------------------------------------------

Cop__Wait4VBlank:
	.vstack		_VSTACK_START
	CoreCall_Begin
	CoreCall_Use	"A8nz"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
b_loop:
		jsr	$=Interpret__Idle
		lda	$_Scanline_HDMA
		bne	$-b_loop
b_1:
	CoreCall_Pull
	CoreCall_End

	// ---------------------------------------------------------------------------

Cop__GetScanline:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		lda	$_Scanline_HDMA
b_1:
	CoreCall_End

	// ---------------------------------------------------------------------------

Cop__SetScanline:
	.vstack		_VSTACK_START
	CoreCall_Begin
	CoreCall_ResetMemoryPrefix
	CoreCall_Use	"A16XYnvzc"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		sta	$_Scanline
		rep	#0x10
		phb
		phd
		call	Hdma__UpdateScrolling
		pld
		plb
		sep	#0x30
b_1:
	CoreCall_Pull
	CoreCall_End

	// ---------------------------------------------------------------------------

Cop__AddScanline:
	.vstack		_VSTACK_START
	CoreCall_Begin
	CoreCall_ResetMemoryPrefix
	CoreCall_Use	"A16XYnvzc"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		clc
		adc	$_Scanline_HDMA
		sta	$_Scanline
		phb
		phd
		call	Hdma__UpdateScrolling
		pld
		plb
b_1:
	CoreCall_Pull
	CoreCall_End

	// ---------------------------------------------------------------------------

Cop__IncScanline:
	.vstack		_VSTACK_START
	CoreCall_Begin
	CoreCall_ResetMemoryPrefix
	CoreCall_Use	"A16XYnvzc"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
		lda	$_Scanline_HDMA
		inc	a
		sta	$_Scanline
		phb
		phd
		call	Hdma__UpdateScrolling
		pld
		plb
b_1:
	CoreCall_Pull
	CoreCall_End

	// ---------------------------------------------------------------------------
