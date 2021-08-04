
	.align	0x100

	// 4x 256 bytes of Nes bank to Snes bank translation
RomInfo_BankLut:
RomInfo_BankLut_80:
	.fill	0x100
RomInfo_BankLut_a0:
	.fill	0x100
RomInfo_BankLut_c0:
	.fill	0x100
RomInfo_BankLut_e0:
	.fill	0x100

	// 256 CHR banks; "lo" and "hi" represent page and bank of SNES addresses, always page aligned
RomInfo_ChrBankLut:
RomInfo_ChrBankLut_lo:
	.fill	0x100
RomInfo_ChrBankLut_hi:
	.fill	0x100

	// ---------------------------------------------------------------------------

	// Mapper number in 16-bit
RomInfo_Mapper:
	.data16	0

	// Starting SNES banks for PRG and CHR
RomInfo_StartBankPRG:
	.data8	0x84
RomInfo_StartBankCHR:
	.data8	0xc5

	// Cartridge flags
RomInfo_CartFlags:
	.data16	0x0000
	.def	RomInfo_CartFlags_TruncateRom		0x0001

	// 16 bits of "Memory emulation" flags
RomInfo_MemoryEmulation:
	.data16	0x000f
	.def	RomInfo_MemEmu_Load					0x0001
	.def	RomInfo_MemEmu_Store				0x0002
	.def	RomInfo_MemEmu_AbsBank				0x0004
	.def	RomInfo_MemEmu_AbsCrossBank			0x0008
	// TODO
	.def	RomInfo_MemEmu_IndCrossBank			0x0010

	// Initial bank numbers on reset
RomInfo_PrgBankNumbers:
	.data8	0,0,0,0

	// Which bits of PRG count towards bank boundaries
RomInfo_PrgBankingMask:
	.data16	0
	
	// Maximum range for JMP to count as a branch (negative if unused)
RomInfo_JmpRange:
	.data16	0xffff
RomInfo_JmpRange_x2:
	.data16	0xffff

	// Negative when debugging calls with dummy STA to destination
RomInfo_DebugCalls:
	.data8	0x00

	// Bit 0 and 1 used for screen size
RomInfo_ScreenMode:
	.data8	0x01

	// 32 bytes string for game name
	// 4 bytes for Checksum
	// 4 bytes for CRC32
RomInfo_GameName:
	.fill	32, 0
RomInfo_GameCheckSum:
	.fill	4, 0
RomInfo_GameCRC32:
	.fill	4, 0

	// ROM banks range reserved for allocating statically recompiled code
RomInfo_StaticRecBanks:
	.data8	0xc8, 0xcf

	// Flags for NMI emulation
RomInfo_NmiMode:
	.data16	0x0003
	.def	RomInfo_NmiMode_DetectIdling		0x0001
	.def	RomInfo_NmiMode_AtSnesNmi			0x0002
	.def	RomInfo_NmiMode_NoReturn			0x0004
	.def	RomInfo_NmiMode_InfiniteJmp			0x0008
	// TODO: Replace InfiniteJmp with DetectIdling

RomInfo_Optimize:
	.data16	0x0000
	.def	RomInfo_Optimize_MainThread			0x0001
	.def	RomInfo_Optimize_SecondThread		0x0002
	.def	RomInfo_Optimize_StaticRec			0x0004

	// Negative when using 8 sprites limit
RomInfo_SpriteLimit:
	.data8	0x00

	// Negative when using direct sound
RomInfo_DirectSound:
	.data8	0xff

RomInfo_SpriteZeroOffset:
	.data8	0x08

RomInfo_IrqOffset:
	.data8	0x01

	// Negative when resetting memory
RomInfo_ZeroMemoryReset:
	.data8	0x00

	// Negative when using debug overlay
RomInfo_DebugOverlay:
	.data8	0x00

	// 16 bits of "Stack emulation" flags
RomInfo_StackEmulation:
	.data16	0x000f
	.def	RomInfo_StackEmu_LazyDoubleReturn		0x0001
	.def	RomInfo_StackEmu_StackUnderflow			0x0002
	.def	RomInfo_StackEmu_NativeReturn			0x0004

RomInfo_VramQBufferSize:
	.data16	0x1000

	// Negative when using CHR RAM clone
RomInfo_ChrRamClone:
	.data8	0

RomInfo_CpuSettings:
	.data16	0x0000
	.def	RomInfo_Cpu_RecompilePrgRam				0x0001
	.def	RomInfo_Cpu_IllegalNop					0x0002

	// Defines whether page range is static, 1 bit per range, 8 ranges in total, bit is set when range is static
RomInfo_StaticRanges:
	.data8	0x00

	// ---------------------------------------------------------------------------

	// Version number
	[80ffdB] = 0x03
RomInfo_Title:
	.string0	"Project Nested"
RomInfo_Version:
	.string0	"1.3"
RomInfo_BuildDate:
	.printdate	"yyyy-MM-dd"
	.data8	0

	// ---------------------------------------------------------------------------

	.macro	RomInfo_SummaryMac
		.string	"{0}"
		.data8	0x0d, 0x0a
	.endm

	.macro	RomInfo_DefineMac		Definition, Address, Mask
		.string	"{0}"
		.data8	0
		.data24	=Zero+{1}
		.data16	_Zero+{2}
	.endm

	// Pointer used in Header.asm
RomInfo_Description:

	RomInfo_DefineMac	"public void Tab_Version : smc version 1.3", 0, 0

	RomInfo_DefineMac	"private void Tab_Warning : Settings in RED are for debugging purposes ONLY.", 0, 0

	RomInfo_DefineMac	"private void Tab_Mapping : Memory mapping.", 0, 0

		RomInfo_DefineMac	"private short MapperNum", RomInfo_Mapper, 0

		RomInfo_DefineMac	"private hex byte ScreenMode", RomInfo_ScreenMode, 0

		RomInfo_DefineMac	"private readonly hex byte StartBankPRG", RomInfo_StartBankPRG, 0

		RomInfo_DefineMac	"private readonly hex byte StartBankCHR", RomInfo_StartBankCHR, 0

		RomInfo_DefineMac	"private hex byte[0x100] PrgBankLut_80", RomInfo_BankLut_80, 0
		RomInfo_DefineMac	"private hex byte[0x100] PrgBankLut_a0", RomInfo_BankLut_a0, 0
		RomInfo_DefineMac	"private hex byte[0x100] PrgBankLut_c0", RomInfo_BankLut_c0, 0
		RomInfo_DefineMac	"private hex byte[0x100] PrgBankLut_e0", RomInfo_BankLut_e0, 0

		RomInfo_DefineMac	"private hex byte[0x100] ChrBankLut_lo", RomInfo_ChrBankLut_lo, 0
		RomInfo_DefineMac	"private hex byte[0x100] ChrBankLut_hi", RomInfo_ChrBankLut_hi, 0

	RomInfo_DefineMac	"private void Tab_Feedback : SRM Feedback data structure.", 0, 0

		RomInfo_DefineMac	"private void* FeedbackProfileName", Feedback_ProfileName-Feedback_Start, 0

		RomInfo_DefineMac	"private void* FeedbackEntryPoints", Feedback_EmptyPointer-Feedback_Start, 0

		//RomInfo_DefineMac	"private void* FeedbackLinks", 0, 0

	RomInfo_DefineMac	"public void Tab_MemoryEmulation : Memory emulation accuracy settings.", 0, 0

		//RomInfo_DefineMac	"private hex short MemoryEmulation : Memory emulation", RomInfo_MemoryEmulation, 0

		RomInfo_SummaryMac	"Emulates indirect load more accurately at the cost of performance."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Forced ON for mappers using PRG bank switching."
		RomInfo_DefineMac	"public bool MemoryEmulation.Load : Memory emulation, Load", RomInfo_MemoryEmulation, RomInfo_MemEmu_Load

		RomInfo_SummaryMac	"Emulates indirect store more accurately at the cost of performance."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Forced ON for mappers using SRAM."
		RomInfo_DefineMac	"public bool MemoryEmulation.Store : Memory emulation, Store", RomInfo_MemoryEmulation, RomInfo_MemEmu_Store

		RomInfo_SummaryMac	"Emulates direct load more accurately at the cost of performance."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Forced ON for mappers using PRG bank switching."
		RomInfo_DefineMac	"public bool MemoryEmulation.AbsBank : Memory emulation, Absolute", RomInfo_MemoryEmulation, RomInfo_MemEmu_AbsBank

		RomInfo_SummaryMac	"Emulates direct load crossing bank boundary at a small cost of performance."
		RomInfo_DefineMac	"public bool MemoryEmulation.AbsCrossBank : Memory emulation, Absolute Cross", RomInfo_MemoryEmulation, RomInfo_MemEmu_AbsCrossBank

		RomInfo_SummaryMac	"Clears RAM upon reset, losing all data that would otherwise carry over."
		RomInfo_SummaryMac	"Doesn't lose data from saved files."
		RomInfo_DefineMac	"public bool MemoryEmulation.ZeroMemoryReset : Zero Memory upon reset", RomInfo_ZeroMemoryReset, 0x80

		RomInfo_SummaryMac	"Defines ROM range 0x8000-0x9fff as static."
		RomInfo_SummaryMac	"May improve compatibility."
		RomInfo_DefineMac	"public bool MemoryEmulation.StaticRange_80 : Static range 8000", RomInfo_StaticRanges, 0x10

		RomInfo_SummaryMac	"Defines ROM range 0xa000-0xbfff as static."
		RomInfo_SummaryMac	"May improve compatibility."
		RomInfo_DefineMac	"public bool MemoryEmulation.StaticRange_a0 : Static range a000", RomInfo_StaticRanges, 0x20

		RomInfo_SummaryMac	"Defines ROM range 0xc000-0xdfff as static."
		RomInfo_SummaryMac	"May improve compatibility."
		RomInfo_DefineMac	"public bool MemoryEmulation.StaticRange_c0 : Static range c000", RomInfo_StaticRanges, 0x40

		RomInfo_SummaryMac	"Defines ROM range 0xe000-0xffff as static."
		RomInfo_SummaryMac	"May improve compatibility."
		RomInfo_DefineMac	"public bool MemoryEmulation.StaticRange_e0 : Static range e000", RomInfo_StaticRanges, 0x80

	RomInfo_DefineMac	"public void Tab_Cartridge : Cartridge settings.", 0, 0

		RomInfo_SummaryMac	"Truncates the ROM size to the size that it's supposed to be instead of a power of 2"
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Intended for devices that are unable to load 8mb."
		RomInfo_DefineMac	"public bool Cartridge.TruncateRom : Truncate ROM", RomInfo_CartFlags, RomInfo_CartFlags_TruncateRom

	RomInfo_DefineMac	"public void Tab_Cpu : CPU related rules.", 0, 0

		RomInfo_SummaryMac	"This option is for games that store static code into PRG RAM."
		RomInfo_DefineMac	"public bool Cpu.RecompilePrgRam : Recompile PRG RAM", RomInfo_CpuSettings, RomInfo_Cpu_RecompilePrgRam

		RomInfo_SummaryMac	"Allow recompiling illegal NOP opcodes."
		RomInfo_SummaryMac	"Activating this may break games that derail the disassembler."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Supports the following opcodes:"
		RomInfo_SummaryMac	" 0C"
		RomInfo_SummaryMac	" 14, 1A, 1C"
		RomInfo_SummaryMac	" 34, 3A, 3C"
		RomInfo_SummaryMac	" 54, 5A, 5C"
		RomInfo_SummaryMac	" 74, 7A, 7C"
		RomInfo_SummaryMac	" 80, 82, 89"
		RomInfo_SummaryMac	" C2"
		RomInfo_SummaryMac	" D4, DA, DC"
		RomInfo_SummaryMac	" E2"
		RomInfo_SummaryMac	" F4, FA, FC"
		RomInfo_DefineMac	"public bool Cpu.IllegalNop : Allow illegal NOPs", RomInfo_CpuSettings, RomInfo_Cpu_IllegalNop

	RomInfo_DefineMac	"public void Tab_Stack : Stack related rules.", 0, 0

		RomInfo_SummaryMac	"Use native return addresses instead of originals. Greatly improves performance."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Turn this option OFF to test whether the game has stack emulation issues."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Disabling this option disables other stack options."
		RomInfo_DefineMac	"public bool StackEmulation.NativeReturn : Stack emulation, Native return address", RomInfo_StackEmulation, RomInfo_StackEmu_NativeReturn

		RomInfo_SummaryMac	"Take a more lazy approach when solving double return."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Has no effect on performance but may make or break games."
		RomInfo_DefineMac	"public bool StackEmulation.LazyDoubleReturn : Stack emulation, Lazy double return", RomInfo_StackEmulation, RomInfo_StackEmu_LazyDoubleReturn

		RomInfo_SummaryMac	"Detects when a return address is used as data pointer."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Has no effect on performance but may make or break games."
		RomInfo_DefineMac	"public bool StackEmulation.StackUnderflow : Stack emulation, Stack underflow detection", RomInfo_StackEmulation, RomInfo_StackEmu_StackUnderflow

	RomInfo_DefineMac	"public void Tab_Banks : Bank and range related rules.", 0, 0

		RomInfo_SummaryMac	"PRG banks to start on after a reset."
		RomInfo_DefineMac	"private hex byte[4] PrgBanks : Starting PRG banks", RomInfo_PrgBankNumbers, 0

		RomInfo_DefineMac	"private hex short PrgBankMask : Program bank mask", RomInfo_PrgBankingMask, 0

		RomInfo_SummaryMac	"Maximum distance for a JMP to count as being considered in the same function."
		RomInfo_SummaryMac	"May cause some games to crash."
		RomInfo_SummaryMac	"Use value -1 for unlimited range."
		RomInfo_DefineMac	"public short JumpRange : Jump range", RomInfo_JmpRange, 0
		RomInfo_DefineMac	"private short JumpRange_x2 : Jump range x2", RomInfo_JmpRange_x2, 0

	RomInfo_DefineMac	"private void Tab_Debug : Debug, turn those off for regular play.", 0, 0

		RomInfo_SummaryMac	"Add a dummy STA before each emulated JSR, writing to the original destination address."
		RomInfo_SummaryMac	"Comes at a small cost of performance."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"This effect is ignored when the destination is in RAM or compiled ahead-of-time."
		RomInfo_DefineMac	"global private bool DebugCalls : Debug calls", RomInfo_DebugCalls, 0x00ff

	RomInfo_DefineMac	"private void Tab_Profile : Profile description, do not edit manually.", 0, 0

		RomInfo_SummaryMac	"Used to identify which profile match this game."
		RomInfo_DefineMac	"private char[32] GameName : Game name", RomInfo_GameName, 0
		RomInfo_DefineMac	"private int GameCheckSum : Game CheckSum", RomInfo_GameCheckSum, 0
		RomInfo_DefineMac	"private int GameCRC32 : Game CRC32", RomInfo_GameCRC32, 0

		RomInfo_DefineMac	"private char[20] EmulatorName : Emulator name", Rom_Title, 0

		RomInfo_SummaryMac	"ROM banks range reserved for allocating code compiled ahead-of-time."
		RomInfo_DefineMac	"private hex byte[2] AotCompileBanks : AOT compiler banks", RomInfo_StaticRecBanks, 0

	RomInfo_SummaryMac	"Determines how the emulator handles NES non-maskable interrupt (NMI)."
	RomInfo_DefineMac	"public void Tab_NMI : NMI emulation settings.", 0, 0

		//RomInfo_SummaryMac	"Determines how the emulator handles NES non-maskable interrupt (NMI)."
		//RomInfo_DefineMac	"private hex short NmiMode : NMI mode", RomInfo_NmiMode, 0

		RomInfo_SummaryMac	"Emulates NES NMI during vblank."
		RomInfo_SummaryMac	"This flag has the lowest priority when active with other NMI flags."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"At least 1 NMI flag must be set"
		RomInfo_DefineMac	"public bool NmiMode.AtVblank : NMI mode, at vblank", RomInfo_NmiMode, RomInfo_NmiMode_AtSnesNmi

		RomInfo_SummaryMac	"Emulates NES NMI during idle loops detected by the compiler."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"At least 1 NMI flag must be set"
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Loops that the compiler fails to detect can be marked by adding 2 to the branch opcode itself which normally stops the 6502 completely (illegal opcode)."
		RomInfo_DefineMac	"public bool NmiMode.AutoDetect : NMI mode, auto detect", RomInfo_NmiMode, RomInfo_NmiMode_DetectIdling

	RomInfo_DefineMac	"public void Tab_Timing : Timing settings. There is no cycle count in this version.", 0, 0

		RomInfo_SummaryMac	"Determines how many lines to skip from the top of sprite zero."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Doesn't take empty lines into account."
		RomInfo_DefineMac	"public byte SpriteZeroOffset : Sprite zero hit offset.", RomInfo_SpriteZeroOffset, 0

		RomInfo_SummaryMac	"Determines how many lines to skip after an IRQ hit."
		RomInfo_DefineMac	"public mapper<4> byte IrqOffset : Mapper IRQ hit offset.", RomInfo_IrqOffset, 0

	RomInfo_DefineMac	"public void Tab_Ppu : PPU emulation.", 0, 0

		RomInfo_SummaryMac	"Limit how many sprites can be rendered per scanline to 8."
		RomInfo_SummaryMac	"However, sprite priority had to be backward to achieve this effect."
		RomInfo_DefineMac	"public bool SpriteLimit : Sprite limit per scanline.", RomInfo_SpriteLimit, 0x80

		RomInfo_SummaryMac	"Allows reading CHR RAM."
		RomInfo_SummaryMac	"Comes at a cost of performance and 8kb of RAM."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"This option is ignored for games using CHR ROM."
		RomInfo_DefineMac	"public bool ChrRamClone : Clone CHR RAM", RomInfo_ChrRamClone, 0x80

		RomInfo_SummaryMac	"Determines how many bytes can be queued for graphical update."
		RomInfo_SummaryMac	"The queue is interpreted and emptied every vblank."
		RomInfo_DefineMac	"public hex short VramQBufferSize : Vram queue buffer size.", RomInfo_VramQBufferSize, 0

	RomInfo_DefineMac	"public void Tab_Gui : Graphical user interface settings.", 0, 0

		//RomInfo_DefineMac	"global public bool Gui.Enabled : Shows CPU% and RAM%.", RomInfo_DebugOverlay, 0x80

		RomInfo_SummaryMac	"Shows CPU% and RAM%."
		RomInfo_DefineMac	"global public bool Gui.HardwareUsage : Show hardware usage.", RomInfo_DebugOverlay, 0x80

	// End of description
	RomInfo_SummaryMac	""
	RomInfo_DefineMac	"", Zero, 0

