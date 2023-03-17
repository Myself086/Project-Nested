
Main_ClearZero:
	.data8	0x00
Main_ClearTileAttribute:
	.data8	0x10

	.mx	0x00	
Main:
	phk
	plb

	.mx	0x20

	// Change DP
	pea	$0x2100
	pld

	// Force blank screen
	lda	#0x80
	sta	$0x00

	// Disable HDMA
	stz	$0x420c

	// Initialize PPU (thanks to soniccd123)
	ldy	#0
	sty	$0x01
	//stz	$0x02
	stz	$0x03
	sty	$0x05
	//stz	$0x06
	sty	$0x07
	//stz	$0x08
	sty	$0x09
	//stz	$0x0A
	sty	$0x0B
	//stz	$0x0C
	sty	$0x0D
	//stz	$0x0E
	sty	$0x0F
	//stz	$0x10
	sty	$0x11
	//stz	$0x12
	stz	$0x13
	sty	$0x15
	//stz	$0x16
	stz	$0x17
	sty	$0x1A
	//stz	$0x1B
	sty	$0x1C
	//stz	$0x1D
	sty	$0x1E
	//stz	$0x1F
	sty	$0x20
	//stz	$0x21
	sty	$0x23
	//stz	$0x24
	sty	$0x25
	//stz	$0x26
	sty	$0x27
	//stz	$0x28
	sty	$0x29
	//stz	$0x2A
	sty	$0x2B
	//stz	$0x2C
	sty	$0x2D
	//stz	$0x2E
	sty	$0x30
	//stz	$0x31
	sty	$0x32
	//stz	$0x33

	// Preload top half of page 0x4300 into MSB of A
	lda	#0x43
	xba

	.macro	Main_ClearMemory	channel, params, b_bus, a_bus, length
		// params -> 0
		// b_bus  -> 1
		// a_bus  -> 2-4
		// length -> 5-6
		.def	channel__	{0}
		.def	params__	{1}
		.def	b_bus__		{2}
		.def	a_bus__		{3}
		.def	length__	{4}
		lda	#.Zero+0x4307+channel__*0x10
		tcs
		// 7 6
		pea	$_Zero+length__/0x100
		// 5 4
		pea	$_Zero+length__*0x100+a_bus__/0x10000
		// 3 2
		pea	$_Zero+a_bus__
		// 1 0
		pea	$_Zero+params__+b_bus__*0x100
	.endm

	// Keep current stack pointer in X (already in X)
	//tsx

	// Clear NES memory
	lda	$=RomInfo_ZeroMemoryReset
	bpl	$+b_1
		stz	$0x81
		stz	$0x82
		stz	$0x83
		Main_ClearMemory	0, 0x08, 0x80, Main_ClearZero, 0x800
		lda	#0x01
		sta	$0x420b
b_1:

	// Clear memory from 0x0800 to last clear address, whatever it is set to in Variables.asm
	ldy	#0x0008
	stz	$0x81
	sty	$0x82
	Main_ClearMemory	3, 0x08, 0x80, Main_ClearZero, Wram_Clear_LastAddress-0x800+1
	sty	$0x420b

	// Clear the second half of WRAM
	ldy	#0x0100
	stz	$0x81
	sty	$0x82
	Main_ClearMemory	0, 0x08, 0x80, Main_ClearZero, 0

	// Clear the second half of VRAM
	ldy	#0x0080
	sty	$0x15
	stz	$0x17
	Main_ClearMemory	7, 0x08, 0x19, Main_ClearZero, 0x8000
	sty	$0x420b

	// Clear nametable tiles attributes
	ldy	#0x2000
	sty	$0x16
	Main_ClearMemory	1, 0x08, 0x19, Main_ClearTileAttribute, 0x1000
	lda	#0x02
	sta	$0x420b

	// Clear BG1 and BG3 tiles
	ldy	#0x2000
	stz	$0x15
	sty	$0x16
	Main_ClearMemory	1, 0x08, 0x18, Main_ClearZero, 0x2000

	// Clear palette memory
	Main_ClearMemory	2, 0x08, 0x22, Main_ClearZero, 0x200

	// Clear OAM
	stz	$0x02
	stz	$0x03
	Main_ClearMemory	3, 0x08, 0x04, Main_ClearZero, 0x220

	// Finish transfer
	lda	#0x0f
	sta	$0x420b

	// Restore stack pointer
	txs

	// Change DP to 0x4300
	lda	#0x00
	tcd

	// Clear unused DMA bytes
	ldy	#0x0000
	sty	$0x07
	sty	$0x09
	stz	$0x0b
	stz	$0x1b
	stz	$0x2b
	stz	$0x3b
	stz	$0x4b
	stz	$0x5b
	stz	$0x6b
	stz	$0x7b
	sty	$0x15
	sty	$0x25
	sty	$0x35
	sty	$0x45
	sty	$0x55
	sty	$0x65
	sty	$0x75
	stz	$0x17
	stz	$0x27
	stz	$0x37
	stz	$0x47
	stz	$0x57
	stz	$0x67
	stz	$0x77

	// Set up addition lookup table
	ldx	#_Addition
	stx	$0x2181
	stz	$0x2183
	lda	#0x00
b_loop:
		sta	$0x2180
		inc	a
		bne	$-b_loop

	// Clear assumed palette
	lda	#0xff
	ldx	#0x001f
b_loop:
		sta	$_PaletteNes,x
		dex
		bpl	$-b_loop

	//lda	#0xfe
	//sta	$_PaletteNes+0x00
	//sta	$_PaletteNes+0x10
	
	// 8-bit A and 16-bit X/Y
	smx	#0x20

	// BG mode 1, BG3 top priority
	lda	#0x09
	sta	$0x2105
	// BG1 screen base at the end of Vram and chars at the beginning
	lda	$=RomInfo_ScreenMode
	and	#0x03
	ora	#0x20
	sta	$_IO_BG_MIRRORS
	sta	$0x2107
	stz	$0x210b

	// Nes PPU increment by 1
	inc	$_IO_PPUADDR_INC
	dec	$_IO_PPUADDR_INC_QUEUED

	// Disable backgrounds and sprites until the game decides to enable them
	stz	$0x212c

	// Sprite size 8x8 and 64x64, the latter is used for adjusting sprite limit per scanline
	lda	#0x40
	sta	$0x2101

	.vstack		_VSTACK_START

	rep	#0x30
	.mx	0x00
	lda	#_VSTACK_PAGE
	tcd

	call	Main__InitMemory
	call	StaticRec__InitMemory
	call	Main__InitEmulation
	call	Gfx__Restart
	call	Chr__Initialize
	call	Gui__Init
	call	Sound__Init
	call	Recompiler__InitMapper

	sep	#0x20
	.mx	0x20

	// Prepare Wram access for VramQ
	ldx	#_Vram_Queue
	stz	$0x2183
	stx	$0x2181
	// Queue initializer for VramQ
	lda	#.VramQ_Init
	sta	$0x2180
	// Queue nametable remap
	call	Gfx__LoadNameTableRemaps

	// SETINI, 239 lines instead of 224 for better compatibility
	lda	#0x04
	sta	$0x2133

	// Disable mosaic
	stz	$0x2106

	// Windows
	// Window mask settings, window 0 "disables outside" for BG1 and Sprites
	lda	#0x03
	sta	$0x2123
	stz	$0x2124
	sta	$0x2125
	// Window 0 left/right, used to hide 8 pixels on the left side of the screen
	ldx	#0xff08
	stx	$0x2126
	// Window 1 left/right, unused
	stx	$0x2128
	// Window mask logic, unused
	stz	$0x212a
	stz	$0x212b
	// Window area main/sub screen disable, set during vblank
	stz	$0x212e
	stz	$0x212f

	// Reset scrolling
	stz	$0x210d
	stz	$0x210d
	stz	$0x210e
	stz	$0x210e

	// Enable automatic joypad reading?
	lda	$=RomInfo_InputFlags
	asl	a
	rol	a
	and	#1
	// Enable IRQ on scanline 240
	ldx	#240
	stx	$0x4209
	ora	#0x20
	sta	$0x4200

	// Enable BG3 in case an error happens, normally this is set by HDMA
	lda	#0x04
	sta	$0x212C

	// Late format SRAM in case something needs to be reported to the user
	call	Memory__FormatSram
	call	Feedback__Init
	call	JMPi__Init

	// Prepare indirect IO JMP
	lda	#0x5c
	sta	$_InterpretIO_Action_JMP

	// Prepare indirect load/store
	.macro	Main_SetIndirectOpcode		OpcodeName
		lda	#.Interpret__{0}IndirectY_Page/0x100
		sta	$_IndirectY_{0}_Action+1
		lda	#.Interpret__{0}IndirectX_Page/0x100
		sta	$_IndirectX_{0}_Action+1
	.endm
	Main_SetIndirectOpcode	Ora
	Main_SetIndirectOpcode	And
	Main_SetIndirectOpcode	Eor
	Main_SetIndirectOpcode	Adc
	Main_SetIndirectOpcode	Sta
	Main_SetIndirectOpcode	Lda
	Main_SetIndirectOpcode	Cmp
	Main_SetIndirectOpcode	Sbc

	// Change mode
	rep	#0x30
	.mx	0x00

	// Prepare indirect JMP
	lda	#_JMPiU_Start/0x100
	sta	$_JMPiU_Action+1

	// Call from reset vector's address at 0xFFFC
	.local	=temp
	lda	$_Program_Bank_3+1
	sta	$.temp+1
	and	#0xff00
	beq	$+b_TrapBank
	lda	#0xfffc
	sta	$.temp
	lda	[$.temp]
	bpl	$+b_TrapBit15
	.unlocal	=temp
	Recompiler__CallFunction	"//"

	// Prepare reset address
	.local	=reset
	lda	[$.Recompiler_FunctionList+3],y
	sta	$.reset
	iny
	lda	[$.Recompiler_FunctionList+3],y
	sta	$.reset+1

	// Prepare registers
	lda	#0x0000
	tcd
	ldx	#0x01ff
	txs
	sep	#0x30
	.mx	0x30
	lda	#0xe0
	sta	$_Memory_NesBank
	lda	$_Program_Bank_3+2
	pha
	plb
	unlock

	// Call function
	jmp	[$_reset]

b_TrapBank:
	unlock
	trap
	Exception	"No Game{}{}{}Don't open this SMC file, use the EXE file to convert a NES game into a SNES game. Instructions on how to convert the game can be found on the EXE's main window."

b_TrapBit15:
	unlock
	trap
	Exception	"Bad Reset Vector{}{}{}This game's reset vector points outside of the normal ROM range. It was pointing to 0x{A:X} but should point to 0x8000-0xFFFF."

	// ---------------------------------------------------------------------------
	
	.mx	0x00
	.func	Main__InitEmulation
Main__InitEmulation:
	// Set bank base addresses
	lda	#0x8000
	sta	$_Program_Bank_0
	lda	#0xa000
	sta	$_Program_Bank_1
	lda	#0xc000
	sta	$_Program_Bank_2
	lda	#0xe000
	sta	$_Program_Bank_3

	// Set mapper
	lda	$=RomInfo_Mapper
	asl	a
	sta	$_Mapper_x2

	// Set ROM bank numbers and translate bank numbers for Snes
	sep	#0x30
	.mx	0x30
	lda	$=RomInfo_PrgBankNumbers+0
	tax
	stx	$_Program_BankNum_8000
	lda	$=RomInfo_BankLut_80,x
	sta	$_Program_Bank_0+2
	lda	$=RomInfo_PrgBankNumbers+1
	tax
	stx	$_Program_BankNum_a000
	lda	$=RomInfo_BankLut_a0,x
	sta	$_Program_Bank_1+2
	lda	$=RomInfo_PrgBankNumbers+2
	tax
	stx	$_Program_BankNum_c000
	lda	$=RomInfo_BankLut_c0,x
	sta	$_Program_Bank_2+2
	lda	$=RomInfo_PrgBankNumbers+3
	tax
	stx	$_Program_BankNum_e000
	lda	$=RomInfo_BankLut_e0,x
	sta	$_Program_Bank_3+2

	// Set bank number for PRG RAM
	lda	#0xb0
	sta	$_Program_Bank_Sram+2
	rep	#0x30
	.mx	0x00

	// Reset emulated ROM
	call	Recompiler__Reset

	return

	// ---------------------------------------------------------------------------
	
	.mx	0x00
	.func	Main__InitMemory
Main__InitMemory:
	// Heap start 7e
	lda	#_Memory_HeapStart_7e
	clc
	adc	$=RomInfo_VramQBufferSize
	trapcs
	Exception	"VramQ Too Large{}{}{}VramQ buffer can only be so large, please select a smaller size."
	and	#0xff00
	sta	$=Memory_Bottom+0x7e0000
	sta	$=Memory_Top+0x7e0000

	// Clear last byte of VramQ
	tax
	lda	#0x0000
	dex
	dex
	sta	$0x7e0000,x
	lda	#0x7e00
	sta	$_Vram_Queue_Top+1
	stx	$_Vram_Queue_Top
	sta	$_Vram_Queue_Top_2+1
	stx	$_Vram_Queue_Top_2

	// Heap start 7f
	lda	#_Memory_HeapStart_7f
	sta	$=Memory_Bottom+0x7f0000
	sta	$=Memory_Top+0x7f0000

	// Heap stack
	lda	#_Memory_HeapStackStart
	sta	$=Memory_HeapStack+0x7e0000
	sta	$=Memory_HeapStack+0x7f0000

	return

	// ---------------------------------------------------------------------------

