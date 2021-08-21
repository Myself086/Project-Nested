
	// ROM title
	.addr	0x80ffc0
Rom_Title:
	.def	Rom_Title	Rom_Title&0x7fffff
	// Rom title is also used to identify feedback data
	.string	"Nested Emulator      "

	.def	Rom_Version	0x00ffdb
	// Version number in RomInfo.asm
	//[80ffdB] = 

	// ROM mapper: fast HiROM
	[80ffd5] = 0x31

	// ROM size 8mb
	[80ffd7] = 0x0d

	.def	Rom_SramSize	0x00ffd8
	// SRAM size 256kb
	[80ffd8] = 0x08

	// CPU execution vectors
	.addr	0x80ffe4
	.data16	_Start__Cop
	.data16	_Start__Brk
	.data16	_Start__Abort
	.data16	_Start__Nmi
	.data16	_Start__UnusedReset
	.data16	_Start__Irq
	.data16	0, 0
	.data16	_Start__Lock, _Start__Lock, _Start__Lock, _Start__Lock
	.data16 _Start__Reset
	.data16	_Start__Lock
	
	// ---------------------------------------------------------------------------

	.addr	0x80ff00, 0x80ffbf

	// This pointer must be found at 0x00ff00 (file address)
	.data24		=RomInfo_Description

	// ---------------------------------------------------------------------------

	.mx	0x20

Start__Abort:
Start__Brk:
Start__Cop:
Start__Lock:
	jmp	$=Start__Lock_1
Start__Lock_1:
	rep	#0x34
	//unlock

	// Load call address
	lda	$2,s
	tax
	dex
	dex
	lda	$4,s

	trap
	Exception	"CPU Derailed{}{}{}The CPU executed a BRK opcode at 0x{a:X}{X:X}, this opcode is not used in the program's code. It was executed arbitrarily.{}{}This is likely due to a stack error."


	// Reset code
	.func	Start__Reset
Start__Reset:
	.vstack		_VSTACK_START
	clc
	xce
	sep	#0x35
	rep	#0x18
	.mx	0x20

	// Set stack and keep it in X for Main
	ldx	#_STACK_TOP
	txs

	// Change bank
	phk
	plb

	// Fast ROM
	rol	$0x420d

	// Run static recompiler if ROM is writable
	lda	$_Start__Reset_DummyWrite+1
	inc	$_Start__Reset_DummyWrite+1
Start__Reset_DummyWrite:
	eor	#0
	bne	$+Start__UnusedReset

	jmp	$=Main


	// Called by static recompiler
Start__UnusedReset:
	clc
	xce
	rep	#0x38
	.mx	0x00

	ldx	#_STACK_TOP
	txs

	lda	#_VSTACK_PAGE
	tcd

	// Is this running live or through the injector?
	bcc	$+Start__UnusedReset_Live
		// Injector mode
		call	StaticRec__Main
		stp
Start__UnusedReset_Live:
	// Live mode
	call	StaticRec__Main
	sep	#0x20
	.mx	0x20
	lda	#0
	sta	$=RomInfo_DebugCalls
	jmp	$=Main


	// Called by NMI (TODO)
Start__Nmi:
	jmp	$=Start__Nmi_1
Start__Nmi_1:
	unlock
	trap
	Exception	"Unused NMI{}{}{}SNES NMI is unused for this program. It was either activated by accident or wrongly edited by ROM hacking."

	// Called by IRQ
Start__Irq:
	jmp	$=Start__Irq_Fast
