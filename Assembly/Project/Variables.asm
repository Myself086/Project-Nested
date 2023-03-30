
	// Dummy constant to bypass an assembler bug
	.def	Zero						0x00

	// ---------------------------------------------------------------------------
	// Page summary (LoROM banks; 00-3f, 80-bf)
	
	//*00 = NES RAM range
	// 01 = "
	//*02 = "
	//*03 = "
	//*04 = "
	//*05 = "
	//*06 = "
	//*07 = "
	// 08 = Extended RAM for SNES ports and some mappers (ie. mapper 5 later)
	// 09 = "
	// 0a = various small variables and small arrays
	// 0b = stack compare for emulating original return addresses
	// 0c = stack low bits for emulating original return addresses
	// 0d = stack high bits for emulating original return addresses
	// 0e = SNES sprites (Requires even page alignment)
	// 0f = "
	// 10 = " + mapper memory + custom input + <unused> + IRQ stack
	//*11 = HDMA pointers + CHR banks + sound
	// 12 = NES palette (with some unused memory, reserved for 4bpp hacks?)
	// 13 = Function pointer lookup table for indirect JMP
	// 14 = "
	// 15 = "
	// 16 = Function pointer lookup table for non-native return (must directly follow indirect JMP table)
	// 17 = "
	// 18 = "
	// 19 = "
	// 1a = "
	// 1b = "
	//*1c = NES sprite remap when reading from pages outside of WRAM
	//*1d = IRQ data (stack moved before HDMA pointers)
	//*1e = Main thread
	// 1f = Addition table, with open bus mirror in page 20 (TODO: Verify if it works with HDMA active)
	// * Pages that may use DP register for faster access (page 01 is possible but unpractical)
	// IMPORTANT FOR FUTURE COMPATIBILITY: Anything from pages 0A to 1F is subject to change.

	// ---------------------------------------------------------------------------

	.macro	DefineGlobalVariable	name, length
{0}:
		.def	{0}_LENGTH	{1}
		.fill	{0}_LENGTH
	.endm

	// ---------------------------------------------------------------------------
	// Pointers and various variables

	// Structure (4 bytes): 24-bit address for accessing each 8kb bank, 8-bit unused
	.def	Program_Bank				0x0a00
	.def	Program_Bank_Ram			0x0a00
	.def	Program_Bank_Out			0x0a20
	.def	Program_Bank_In				0x0a40
	.def	Program_Bank_Sram			0x0a60
	.def	Program_Bank_0				0x0a80
	.def	Program_Bank_1				0x0aa0
	.def	Program_Bank_2				0x0ac0
	.def	Program_Bank_3				0x0ae0

	// Structure (3 bytes): 8-bit zero, 8-bit original bank number, 8-bit zero
	// NOTE: Addresses point directly to the 8-bit original bank
	.def	Program_BankNum				0x0a05
	.def	Program_BankNum_0000		0x0a05
	.def	Program_BankNum_2000		0x0a25
	.def	Program_BankNum_4000		0x0a45
	.def	Program_BankNum_6000		0x0a65
	.def	Program_BankNum_8000		0x0a85
	.def	Program_BankNum_a000		0x0aa5
	.def	Program_BankNum_c000		0x0ac5
	.def	Program_BankNum_e000		0x0ae5

	// From here, memory is segmented in chunks of 25 bytes between each memory mapping structure above


	.addr	0x0a07, 0x0a1f
	// 25/25

	// Unused
StackPointer_6502:
	.fill	2
StackPointer_65816:
	.fill	2

	// Interrupt flag value is reversed: true = 0x00, false = 0xff
InterruptFlag_6502:
	.fill	1

Vram_Queue_Write:
	.fill	2
Vram_Queue_PpuAddr:
	.fill	2

	// Bit 0 only, other bits must remain unused, CHR bank swap between 0x0000 and 0x1000
IO_MapperChrBankSwap:
	.fill	1

	// Value at ports 2000 and 2001 is 8-bit but is read as 16-bit during HDMA updates, upper bits must remain 0x00
IO_2000:
	.fill	2
IO_2001:
	.fill	2
IO_2000_EarlyValue:
	.fill	2
IO_2001_EarlyValue:
	.fill	1

IO_2007r:
	.fill	1

IO_BG_MIRRORS:
	.fill	2

	DefineGlobalVariable	Feedback_Active			1		// Negative when active
	DefineGlobalVariable	Sram_SizeTotalKb		2		// Total amount of SRAM in kilobytes
	DefineGlobalVariable	Sram_SizeNonDynamicKb	2		// Amount of SRAM used for non-dynamic memory allocation


	.addr	0x0a27, 0x0a3f
	// 25/25

	// IO_4014_SpriteSize contains flags for how the sprite transfer was handled
	//  bit 7: set = 8x16, clear = 8x8
	//  bit 0: set when off screen sprites for 8x8 are already written (limit only)
	DefineGlobalVariable	IO_4014_SpriteSize			1
	DefineGlobalVariable	IO_4014_UsedSpriteOffset	1		// Top used sprite offset divided by 2 (exception for 0)

IO_PPUADDR:
	.fill	2
IO_PPUADDR_INC:
	.fill	2
IO_PPUADDR_INC_QUEUED:
	.fill	1

IO_SCROLL_X:
	.fill	2
IO_SCROLL_Y:
	.fill	2

	// These following scroll values are based on: https://wiki.nesdev.com/w/index.php/PPU_scrolling
	// The 15 bit registers t and v are composed this way during rendering:
	//  _yyy NnYY YYYX XXXX
	//  X = coarse X scroll
	//  Y = coarse Y scroll
	//  n = nametable select X
	//  N = nametable select Y
	//  y = fine Y scroll
	//
	// My interpretation of t to SNES scrolling
	//  PPU_SCROLL_X = ____ __Nn XXXX Xxxx
	//  PPU_SCROLL_Y = ____ ___N YYYY Yxxx
	//
	//             bits: 7  6  5  4  3  2  1  0
	// $2000 write:	    __ __ __ __ __ __ y8 x8
	// $2005 write 1:   x7 x6 x5 x4 x3 x2 x1 x0
	// $2005 write 2:   y7 y6 y5 y4 y3 y2 y1 y0
	// $2006 write 1:   __ __ y1 y0 y8 x8 y7 y6 (resets y2)
	// $2006 write 2:   y5 y4 y3 x7 x6 x5 x4 x3 (and copy t to v)
PPU_SCROLL_X:
	.fill	2
PPU_SCROLL_Y:
	.fill	2


	// Performance counter out of 57640 cycles per frame
Idle_CycleCounter:
	.fill	2
Idle_Average:
	.fill	2
Idle_FrameCount:
	.fill	2
Idle_CyclesTotal:
	.fill	4


	.addr	0x0a47, 0x0a5f
	// 25/25

QuickScanline_AdjustCount:
	.fill	1

Recompile_PrgRamTopRange:
	.fill	2

	// Identifying when to send sprite 0 hit
Sprite0Line:
	.fill	2

	// Fast access mapper number
Mapper_x2:
	.fill	2


	// Indirect memory access meant for indirect IO but every indirect opcode needs its own action pointer
IndirectX_Ora_Action:
	.fill	2
IndirectX_And_Action:
	.fill	2
IndirectX_Eor_Action:
	.fill	2
IndirectX_Adc_Action:
	.fill	2
IndirectX_Cmp_Action:
	.fill	2
IndirectX_Sbc_Action:
	.fill	2
IndirectX_Lda_Action:
	.fill	2
IndirectX_Sta_Action:
	.fill	2


	// Side stack for the recompiler: equals zero when available, non-zero when busy and contains the previous stack to be restored
SideStack_Available:
	.fill	2


	.addr	0x0a67, 0x0a7f
	// 25/25

NMI_NesBank:
	.fill	2
NMI_SnesPointer:
	.fill	3

IRQ_NesBank:
	.fill	2
IRQ_SnesPointer:
	.fill	3

	// Code for reading CHR RAM
ChrRam_Read:
	.fill	8
ChrRam_Read_End:
	// Code for writing CHR RAM
ChrRam_Write:
	.fill	7
ChrRam_Write_End:


	.addr	0x0a87, 0x0a9f
	// 23/25

	// Page in bank 0x7e
ChrRam_Page:
	.fill	1
	.def	ChrRam_CONSTBANK		0x7e0000

	// Data copied from APU's memory
Sound_DebugAPU:
	.fill	2

	// Long jump for the following 24-bit pointer
InterpretIO_Action_JMP:
	.fill	1
	// 24-bit code pointer for indirect IO access (TODO: Thread safety)
InterpretIO_Action:
	.fill	3

	// Indirect memory access meant for indirect IO but every indirect opcode needs its own action pointer
IndirectY_Ora_Action:
	.fill	2
IndirectY_And_Action:
	.fill	2
IndirectY_Eor_Action:
	.fill	2
IndirectY_Adc_Action:
	.fill	2
IndirectY_Cmp_Action:
	.fill	2
IndirectY_Sbc_Action:
	.fill	2

	// Pointer+1 to list of banks that can be used as extra heap
Memory__CartBanks:
	.fill	2
	.def	Memory__CartBanks_CONSTBANK		0x7f0000

	// Pointer+2 to list of banks that can be used as ROM cache
RomCache_DescListPointer:
	.fill	2
	.def	RomCache_Desc_CONSTBANK			0x7f0000


	.addr	0x0aa7, 0x0abf
	// 25/25

NmiReturn_Busy:		// Negative when data below is in use, must be followed by any NmiReturn data due to 16-bit STZ
	.fill	1
NmiReturn_NesBank:
	.fill	1
NmiReturn_IOTemp16:
	.fill	2
NmiReturn_IOTemp:
	.fill	1
NmiReturn_JMPiU:
	.fill	2
NmiReturn_ReturnAddress:
	.fill	3
NmiReturn_ReturnAddress2:
	.fill	3
NmiReturn_A:
	.fill	2
NmiReturn_X:
	.fill	2
NmiReturn_Y:
	.fill	2
NmiReturn_DB:		// DB must be above P, they are copied together
	.fill	1
NmiReturn_P:
	.fill	1
NmiReturn_DP:
	.fill	2
NmiReturn_Stack:
	.fill	2


	.addr	0x0ac7, 0x0adf
	// 24/25

	// 16 bytes of nametable remap from NES to SNES (must be at least 0x20 bytes deep into the page to avoid page crossing penalty)
NameTable_Remap_Main:
	.fill	16

NameTable_ActiveMap:
	.fill	8


	.addr	0x0ae7, 0x0afd
	// 16/23

	// 16 bytes of nametable remap from NES to SNES (must be at least 0x20 bytes deep into the page to avoid page crossing penalty)
NameTable_Remap_Irq:
	.fill	16

	// Indirect JMP list, initially in SRAM if available
	DefineGlobalVariable	JMPi_EmptyPointer			3
	DefineGlobalVariable	JMPi_CurrentPoolTop			3
	.def	JMPi_InitialPoolBottomValue	0xb17000
	.def	JMPi_InitialPoolTopValue	0xb18000
	.def	JMPi_PoolSize				0x001000


	.def	Breakpoint					0x7e0afe

	// ---------------------------------------------------------------------------
	// Stack return emulation

	.def	StackEmu_Compare			0x0b00
	.def	StackEmu_LowBits			0x0c00
	.def	StackEmu_HighBits			0x0d00
	
	// ---------------------------------------------------------------------------
	// Snes sprites

	// NOTE: Requires even page alignment

	// 0x220 bytes
	.def	Sprites_Buffer				0x0e00

	// 0x20 bytes for counting sprite limit (overlaps extra attribute bits on purpose)
	.def	Sprites_CountdownPer8Lines	0x1000

	// ---------------------------------------------------------------------------
	// Mapper

	// 0x20 bytes of mapper memory
	.def	Mapper_Memory				0x1020

	// ---------------------------------------------------------------------------
	// Custom input

	.addr	0x1040, 0x10df

	// Input remap
	DefineGlobalVariable	Input_Remap, 48		// 2 dummy bytes 24 valid bytes and 22 zeros
	DefineGlobalVariable	Input_OffsetA, 1
	DefineGlobalVariable	Input_OffsetB, 1

	// ---------------------------------------------------------------------------
	// HDMA pointers, CHR banks and sound (Must all be in the same page because we are using DP shortcuts)

	.addr	0x1101, 0x11ff

	.macro	HDMA_Struct_Mac		name, channelNum
		// Front = Ehat is currently shown on screen
		// Back = What is currently being written, with index added
		// BackBase = Base address of our back buffer
		// Side = Either ready to swap or already swapped
{0}:
{0}_Front:
		.fill	2
{0}_Back:
		.fill	2
{0}_BackBase:
		.fill	2
{0}_Side:
		.fill	2
	.endm

	.def	HDMA_BUFFER_BANK			0x7e0000

	HDMA_Struct_Mac		HDMA_Scroll, 6
	HDMA_Struct_Mac		HDMA_CHR, 5
	HDMA_Struct_Mac		HDMA_SpriteCHR, 4
	HDMA_Struct_Mac		HDMA_LayersEnabled, 3
	HDMA_Struct_Mac		HDMA_Sound, 1

	// Ready, upper byte non-zero when Front and Side are ready to be swapped
HDMA_SideBufferReady:
	.fill	2


	.macro	CHR_Struct_Mac		name, size
CHR_0_{0}:
		.fill	{1}
CHR_1_{0}:
		.fill	{1}
CHR_2_{0}:
		.fill	{1}
CHR_3_{0}:
		.fill	{1}
CHR_4_{0}:
		.fill	{1}
CHR_5_{0}:
		.fill	{1}
CHR_6_{0}:
		.fill	{1}
CHR_7_{0}:
		.fill	{1}
	.endm

	// NesBank = CHR Bank understood by the mapper
	// VramPage = (const) Where this CHR range is in Vram
	// PageLength = (const) How much space this CHR range takes in Vram
	CHR_Struct_Mac	NesBank, 1
	CHR_Struct_Mac	VramPage, 1
	CHR_Struct_Mac	PageLength, 1

	// Sets of CHR banks requested by this frame
CHR_SetsRequest_0:
	.fill	8
CHR_SetsRequest_1:
	.fill	8
CHR_SetsRequest_2:
	.fill	8

	// Records which CHR NesBanks are in use for the following VRAM addresses: 0x0000-0x1fff, 0x4000-0x5fff, 0x6000-0x7fff
CHR_SetsActive_0:
	.fill	8
CHR_SetsActive_1:
	.fill	8
CHR_SetsActive_2:
	.fill	8

	// Scanline is current virtual scanline and Scanline_HDMA is the last line affected by HDMA
Scanline:
	.fill	2
Scanline_HDMA:
	.fill	2

	// IRQ interrupt line, 0 if unused
Scanline_IRQ:
	.fill	1

	// Offset of where the next request is written
CHR_SetsRequest_Index:
	.fill	2

	// (const) Number of CHR banks that can be used at once for this mapper (CHR set)
	// x2 variant can be loaded in 16-bit mode
CHR_BanksInUse:
	.fill	1
CHR_BanksInUse_x2:
	.fill	2

	// Scanline update is busy, avoiding recursive calls from IRQ
Scanline_Busy:
	.fill	1

	// CHR/HDMA local variables during updates
HDMA_VSTACK_START:
	.fill	16
	.def	HDMA_VSTACK_PAGE			Zero+HDMA_VSTACK_START&0xff00


	// Reserve 0x18 bytes for original sound registers
Sound_NesRegs:
	.fill	0x18

	// Extra control bits
	.def	Sound_ExtraControl		Sound_NesRegs+0x16

	// Sound is active when this variable is -1
Sound_Active:
	.fill	2

	// Sound emulation variables
Sound_square0_length:
	.fill	1
Sound_square1_length:
	.fill	1
Sound_triangle_length:
	.fill	1
Sound_noise_length:
	.fill	1

	// Update number when updating HDMA, 0 to 3
Sound_UpdateNumber:
	.fill	1
	// Temporary update number to reach
Sound_UpdateNumberNew:
	.fill	1

	// Low byte non-zero when sound buffers are ready to be swapped
Sound_Ready:
	.fill	2

	// Pointer for verifying whether VramQ overflowed (duplicate)
Vram_Queue_Top_2:
	.fill	3

	// ---------------------------------------------------------------------------
	// Palette

	// Nes Palettes (0x100 bytes)
	.def	PaletteNes					0x1200

	// ---------------------------------------------------------------------------
	// Quick access to JMPi and RtsNes linked list pointers

	// 0x300 bytes
	.def	JMPi_Start					0x1300

	// 0x600 bytes
	.def	RtsNes_Start				0x1600		// Must directly follow indirect JMP table

	// ---------------------------------------------------------------------------
	// NES sprite remap when reading from pages outside of WRAM

	// 0x100 bytes
	.def	NesSpriteRemap				0x1c00

	// ---------------------------------------------------------------------------
	// Shared DP variables range per thread

	// 2 bytes followed by a Zero (from DP_Zero), used to speed up XBA + AND #0x00ff
	.def	DP_Temp						0x1e00

	// 4 bytes total with its 4th byte being for dummy writes in 16-bit mode
	.def	DP_Zero						0x1e02
	.def	DP_ZeroBank					0x1e04

	// ---------------------------------------------------------------------------
	// IRQ thread

	.addr	0x1d06, 0x1d7f

Nmi_Count:
	.fill	2
	.def	Nmi_Count_TOP		0x0003

Vblank_Busy:
	.fill	2

	// Debug wait-state and code pointer for resuming execution
Debug_WaitState:
	.fill	2
Debug_CodePointer:
	.fill	3

	// Blue screen wait-state for testing main thread
BlueScreen_WaitState:
	.fill	2

	// Blue screen CPU register
	// Note: DB, P and PC must follow each other in this respective order
BlueScreen_A:
	.fill	2
BlueScreen_X:
	.fill	2
BlueScreen_Y:
	.fill	2
BlueScreen_S:
	.fill	2
BlueScreen_DP:
	.fill	2
BlueScreen_DB:
	.fill	1
BlueScreen_P:
	.fill	1
BlueScreen_PC:
	.fill	3

	// Pointer for verifying whether VramQ overflowed
Vram_Queue_Top:
	.fill	3

	// 1 bit per paired line of tiles (16 pixels tall), bit 15 unused
Debug_RefreshReq:
	.fill	2

	// 1 bit set when scanning, 0 if not scanning
Debug_RefreshScan:
	.fill	2

	// Reading ROM data for debug, contains bank number only
Debug_ReadBank:
	.fill	3

	// Tile attribute for printing text
Debug_TileAttribute:
	.fill	2

	// Copy of Idle_CycleCounter for rendering
Debug_LastIdleCycles:
	.fill	2

Debug_LastMemoryUsage:
	.fill	2

	.fill	7
TrapTest_Stack:
	.fill	1

TrapTest_A:
	.fill	2

TrapTest_S:
	.fill	2

IRQ_VSTACK_START:
	.def	IRQ_VSTACK_PAGE				0x1d00
	//.def	IRQ_VSTACK_START
	//.def	IRQ_STACK					0x1dff

	// ---------------------------------------------------------------------------
	// Main thread

	// Define recompiler lists (11 bytes per list)
	.def	Recompiler_BranchSrcList	0x1e06
	.def	Recompiler_BranchDestList	0x1e11
	.def	Recompiler_FunctionList		0x1e1c

	// StaticRec table fast access
	.def	Recompiler_StaticRec_Table	0x1e27

	// Stack pointers for main thread
	.def		VSTACK_PAGE		0x1e00
	.def		VSTACK_START	0x1e2a
	.def		VSTACK_TOP		0x1ebf
	.def		SIDE_STACK_TOP	0x1eff
	.def		INIT_STACK_TOP	0x09ff
	.vstack		_VSTACK_START
	.vstacktop	_VSTACK_TOP

	// ---------------------------------------------------------------------------
	// Addition lookup table

	.def	Addition					0x1f00

	// ---------------------------------------------------------------------------
	// Unused DMA bytes

	// DMA byte map (x = used, _ = unused, ! = variable, 0 = always zero, - = linked bytes)
	//            0 1 2 3 4 5 6 7 8 9 a b
	// Channel 0: x x x x x x x !-!-0-! _
	// Channel 1: x x x x x !-! ! x x x _
	// Channel 2: x x x x x !-! ! x x x _ <- Unused HDMA channel
	// Channel 3: x x x x x !-! ! x x x _
	// Channel 4: x x x x x _ _ _ x x x _
	// Channel 5: x x x x x !-!-! x x x _
	// Channel 6: x x x x x !-! _ x x x _
	// Channel 7: x x x x x !-! _ x x x _ <- Unused HDMA channel

	// 16-bit Used to store temporary read/write value for IO ports (directly before zero)
	.def	IO_Temp16					0x4307
	// Always zero
	.def	IO_TempZero					0x4309
	// 8-bit Used to store temporary read/write value for IO ports (directly after zero)
	.def	IO_Temp						0x430a

	// Identifying loops accessing $2002 (LastReturn must be followed by CallCount)
	.def	IO_2002_LastReturn			0x4315		16-bit
	.def	IO_2002_CallCount			0x4317		8-bit
	.def	IO_2002_SnesScanline		0x4335		16-bit

	// VRAM increment during VramQueue
	.def	Vram_Queue_PpuAddrInc		0x4325		16-bit
	// Port 0x2005-0x2006's high/low access, only uses bit 7 (low = 0, high = 1)
	.def	IO_HILO						0x4327

	// $2002's last value
	.def	IO_2002						0x4337

	// Indirect JMP first destination
	EmuCallAt	JMPiU_Action, "JMPi", "?", "?"
	.def	JMPiU_Action				0x4355

	// Defines which memory range is represented by register DB, shares a byte with IndirectY_Lda_Action
	.def	Memory_NesBank				0x4365
	// Indirect load/store, indirect 16-bit JMP destinations
	.def	IndirectY_Lda_Action		0x4365
	.def	IndirectY_Sta_Action		0x4375

	// ---------------------------------------------------------------------------
	// ---------------------------------------------------------------------------
	// SRAM feedback for statically recompiling known calls

	.addr	0xb16000, 0xb16fff
Feedback_Start:
	DefineGlobalVariable	Feedback_EmulatorName		21
	DefineGlobalVariable	Feedback_EmulatorVersion	1
	DefineGlobalVariable	Feedback_ProfileName		128
	DefineGlobalVariable	Feedback_Calls_Write		2
	DefineGlobalVariable	Feedback_Calls_Top			2
Feedback_Calls_LowerBound:
	.def	Feedback_Calls_UpperBound					0xb16fff

	// Incremental step constant
	.def	Feedback_Inc				0x0003

	// ---------------------------------------------------------------------------
	// ---------------------------------------------------------------------------
	// Managed arrays

	// Branch source data structure:
	//  [0] = 16-bit address of source branch
	.def	BranchSrc_Start				0x7e2000
	.def	BranchSrc_End				0x7e27ff
	.def	BranchSrc_ELength			0x000002

	// Branch destination data structure:
	//	[0] = 16-bit address in currently available banks
	//	[2] = 16-bit address of the last byte in that range
	//	[4] = 16-bit address of the recompiled address (0xffff when invalid)
	//  [6] = 16-bit stack depth
	.def	BranchDest_Start			0x7e2800
	.def	BranchDest_End				0x7e2fff
	.def	BranchDest_ELength			0x000008

	// Known calls data structure:
	//	[0] = 24-bit original address
	//	[3] = 24-bit recompiled address
	//	[6] = 16-bit recompiler flags
	.def	KnownCalls_Start			0x7e3000
	.def	KnownCalls_End				0x7e4fff
	.def	KnownCalls_ELength			0x000008
	
	// ---------------------------------------------------------------------------
	// PPU data

	// PPU's Name tables (0x1000 bytes)
	.def	Nes_Nametables				0x7e5000

	// ---------------------------------------------------------------------------
	// Debug nametable

	// 0x800 bytes
	.def	Debug_NameTable				0x7e6000

	// ---------------------------------------------------------------------------
	// Quick find function pointer

	// 0x200 bytes
	.def	QuickFunction				0x7e6800

	// ---------------------------------------------------------------------------
	// Delayed VRAM access

	// Dynamic size but static pointer, see RomInfo_VramQBufferSize
	.def	Vram_Queue					Memory_HeapStart_7e

	// ---------------------------------------------------------------------------
	// WRAM clear, last address to be zeroed

	.def	Wram_Clear_LastAddress		Memory_HeapStart_7e-1

	// ---------------------------------------------------------------------------
	// Memory allocation constants

	// Constant values for Memory_Bottom of each bank
	.def	Memory_HeapStart_7e			0x6a00
	.def	Memory_HeapStart_7f			0x0000

	// Constant for the initial HeapStack value (full stack pointer)
	.def	Memory_HeapStackStart		0xfffa

	// ---------------------------------------------------------------------------
	// Memory allocation addresses

	// HeapStack is where the next free word is for the heap stack, see Memory.asm for more information
	.def	Memory_HeapStack			0xfffa
	// Bottom is a constant based on how much memory was statically allocated
	.def	Memory_Bottom				0xfffc
	// Top is the current top of the heap
	.def	Memory_Top					0xfffe

