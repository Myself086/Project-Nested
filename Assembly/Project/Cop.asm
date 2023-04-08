
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

	Cop__Table		0x06, Cop__QuickAddScanline		// Scanline += A; Read note below and where A < 128
	Cop__Table		0x07, Cop__QuickIncScanline		// Scanline++;    Read note below
	Cop__Table		0x08, Cop__EndQuickScanline		//                Read note below
	// QuickScanline note: Only updates scroll values, must use Cop__EndQuickScanline at the end to synchronize every HDMA back to normal. Cannot cross nametable vertically.

	Cop__Table		0x09, Cop__GetVBlankStatus		// P.z = Non-zero when ready, P.n = 0, A = Awaiting VBlank count
	Cop__Table		0x0a, Cop__TestVBlankStatus		// P.z = Non-zero when ready, P.n = 0

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

Cop__QuickAddScanline:
	CoreCall_Begin
	CoreCall_Use	"A16Xnvzc"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
b_loop:
		jsr	$=Hdma__QuickScanline
b_1:
	CoreCall_Pull
	CoreCall_End

	// ---------------------------------------------------------------------------

Cop__QuickIncScanline:
	CoreCall_Begin
	CoreCall_Use	"A16Xnvzc"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
b_loop:
		lda	#1
		jsr	$=Hdma__QuickScanline
b_1:
	CoreCall_Pull
	CoreCall_End

	// ---------------------------------------------------------------------------

Cop__EndQuickScanline:
	CoreCall_Begin
	CoreCall_Use	"A16XYnvzc"
	CoreCall_Push
	CoreCall_CopyUpTo	+b_1
b_loop:
		lda	#1
		jsr	$=Hdma__EndQuickScanline
b_1:
	CoreCall_Pull
	CoreCall_End

	// ---------------------------------------------------------------------------

Cop__GetVBlankStatus:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		lda	$_Nmi_Count
b_1:
	CoreCall_End

	// ---------------------------------------------------------------------------

Cop__TestVBlankStatus:
	CoreCall_Begin
	CoreCall_CopyUpTo	+b_1
		xba
		lda	$_Nmi_Count
		php
		xba
		plp
b_1:
	CoreCall_End

	// ---------------------------------------------------------------------------
