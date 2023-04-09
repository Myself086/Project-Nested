
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
	.data8	0x88
RomInfo_StartBankCHR:
	.data8	0xc8

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
	.def	RomInfo_MemEmu_IndCrossBank			0x0010
	.def	RomInfo_MemEmu_StaticSram			0x0020

	// Initial bank numbers on reset
RomInfo_PrgBankNumbers:
	.data8	0,0,0,0

	// Which bits of memory count towards PRG bank boundaries
RomInfo_PrgBankingMask:
	.data16	0

RomInfo_PrgBankNumMask:
	.data8	0

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

	// String for game name
RomInfo_GameName:
	.fill	128, 0

	// ROM banks range reserved for allocating statically recompiled code
RomInfo_StaticRecBanks:
	.data8	0xc8, 0xcf

	// Flags for NMI emulation
RomInfo_NmiMode:
	.data16	0x0003
	.def	RomInfo_NmiMode_DetectIdling		0x0001
	.def	RomInfo_NmiMode_AtSnesNmi			0x0002
	.def	RomInfo_NmiMode_NoReturn			0x0004

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
	.data16	0x070f
	.def	RomInfo_StackEmu_LazyDoubleReturn		0x0001
	.def	RomInfo_StackEmu_StackUnderflow			0x0002
	.def	RomInfo_StackEmu_NativeReturn			0x0004
	.def	RomInfo_StackEmu_SafeTsx				0x0008
	.def	RomInfo_StackEmu_NativeReturnInterrupt	0x0100
	.def	RomInfo_StackEmu_Page01					0x0200
	.def	RomInfo_StackEmu_PopSlide				0x0400
	.def	RomInfo_StackEmu_NATIVE_MASK			0xff00

RomInfo_StackResetRange:
	.data8	0xff, 0x00

RomInfo_VramQBufferSize:
	.data16	0x0800

	// Negative when using CHR RAM clone
RomInfo_ChrRamClone:
	.data8	0

	// Negative when using improved PPUSTATUS loop detection
RomInfo_ImprovedPpuStatusLoop:
	.data8	0x80

	// Negative when using synchronized PPUSTATUS to SNES
RomInfo_SyncPpuStatusToSnes:
	.data8	0x00

RomInfo_CpuSettings:
	.data16	0x0000
	.def	RomInfo_Cpu_RecompilePrgRam				0x0001
	.def	RomInfo_Cpu_IllegalNop					0x0002
	.def	RomInfo_Cpu_DynamicJsr					0x0004
	.def	RomInfo_Cpu_SafePrgBankChange			0x0008

RomInfo_AutoPlayThreshold:
	.data16	200

	// Defines whether page range is static, 1 bit per range, 8 ranges in total, bit is set when range is static
RomInfo_StaticRanges:
	.data8	0x00

RomInfo_PatchRanges:
	.fill	4
RomInfo_PatchRanges_Length:
	.fill	2
RomInfo_PatchRanges_Active:		// Negative when patch ranges are ignored
	.data8	0x00

RomInfo_InputFlags:
	.data8	0
	.def	RomInfo_Input_Mouse						0x01		// TODO, imagine AVGN playing Top Gun with a Snes mouse
	.def	RomInfo_Input_SuperScope				0x02		// TODO
	.def	RomInfo_Input_CustomControl				0x80		// Must be bit 7

RomInfo_InputMap:
	.data8	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12

RomInfo_ReservedSnesBanks:
	.data8	0x00, 0x00

RomInfo_RomCacheBankCount:
	.data8	4

	// ---------------------------------------------------------------------------

	// Version number
	[80ffdB] = 0x08							// !
	.macro	RomInfo_VersionString
		.string0	"1.8"					// !
	.endm

RomInfo_Title:
	.string0	"Project Nested"
RomInfo_Version:
	RomInfo_VersionString
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

	.macro	RomInfo_DefineMac2		Definition, Address, Mask, Command
		.string	"{0}"
		{3}
		.data24	=Zero+{1}
		.data16	_Zero+{2}
	.endm

	// Pointer used in Header.asm
RomInfo_Description:

	RomInfo_DefineMac2	"public void Tab_Version : smc version ", 0, 0, RomInfo_VersionString

	RomInfo_DefineMac	"private void Tab_Warning : Settings in RED are for debugging purposes ONLY.", 0, 0

	RomInfo_DefineMac	"global public void Tab_Global : Settings in BLUE are global across all games.", 0, 0

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

		RomInfo_DefineMac	"private void* Feedback.EmulatorName", Feedback_EmulatorName-Feedback_Start, 0
		RomInfo_DefineMac	"private void* Feedback.ProfileName", Feedback_ProfileName-Feedback_Start, 0
		RomInfo_DefineMac	"private void* Feedback.EntryPoints.LowerBound", Feedback_Calls_LowerBound-Feedback_Start, 0
		RomInfo_DefineMac	"private void* Feedback.EntryPoints.UpperBound", Feedback_Calls_UpperBound-Feedback_Start, 0
		RomInfo_DefineMac	"private void* Feedback.EntryPoints.Top", Feedback_Calls_Top-Feedback_Start, 0

		//RomInfo_DefineMac	"private void* Feedback.Links", 0, 0

	RomInfo_DefineMac	"private void Tab_Patch : Patch.", 0, 0

		RomInfo_DefineMac	"private hex int Patch.Ranges", RomInfo_PatchRanges, 0
		RomInfo_DefineMac	"private short Patch.Ranges.Length", RomInfo_PatchRanges_Length, 0

	RomInfo_DefineMac	"private void Tab_VirtualCalls : Virtual calls.", 0, 0

		RomInfo_DefineMac	"private func<int,int> Memory.Alloc", Memory__AllocForExe, 0
		RomInfo_DefineMac	"private func<> StaticRec.Main", StaticRec__MainForExe, 0
		RomInfo_DefineMac	"private func<short,short> StaticRec.AddCallLink", StaticRec__AddCallLinkForExe, 0
		RomInfo_DefineMac	"private func<int> Recompiler.Build", Recompiler__BuildForExe, 0

	RomInfo_DefineMac	"public void Tab_MemoryEmulation : Memory emulation accuracy settings.", 0, 0

		//RomInfo_DefineMac	"private hex short MemoryEmulation : Memory emulation", RomInfo_MemoryEmulation, 0

		RomInfo_SummaryMac	"Emulates indirect load more accurately at the cost of performance."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Forced ON for mappers using PRG bank switching."
		RomInfo_DefineMac	"private bool MemoryEmulation.Load : Memory emulation, Load", RomInfo_MemoryEmulation, RomInfo_MemEmu_Load

		RomInfo_SummaryMac	"Emulates indirect store more accurately at the cost of performance."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Forced ON for mappers using SRAM."
		RomInfo_DefineMac	"private bool MemoryEmulation.Store : Memory emulation, Store", RomInfo_MemoryEmulation, RomInfo_MemEmu_Store

		RomInfo_SummaryMac	"Emulates direct load more accurately at the cost of performance."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Forced ON for mappers using PRG bank switching."
		RomInfo_DefineMac	"private bool MemoryEmulation.AbsBank : Memory emulation, Absolute", RomInfo_MemoryEmulation, RomInfo_MemEmu_AbsBank

		RomInfo_SummaryMac	"Emulates direct load crossing bank boundary at a small cost of performance."
		RomInfo_DefineMac	"private bool MemoryEmulation.AbsCrossBank : Memory emulation, Absolute Cross", RomInfo_MemoryEmulation, RomInfo_MemEmu_AbsCrossBank

		RomInfo_SummaryMac	"Emulates indirect load crossing bank boundary at a cost of performance."
		RomInfo_DefineMac	"public bool MemoryEmulation.IndCrossBank : Indirect bank crossing", RomInfo_MemoryEmulation, RomInfo_MemEmu_IndCrossBank

		RomInfo_SummaryMac	"Clears RAM upon reset, losing all data that would otherwise carry over."
		RomInfo_SummaryMac	"Doesn't lose data from saved files."
		RomInfo_DefineMac	"public bool MemoryEmulation.ZeroMemoryReset : Zero Memory upon reset", RomInfo_ZeroMemoryReset, 0x80

		RomInfo_DefineMac	"private readonly hex byte MemoryEmulation.StaticRange : Static range", RomInfo_StaticRanges, 0

		RomInfo_SummaryMac	"Defines RAM range 0x6000-0x7fff as static."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Improves performance slightly since v1.6"
		RomInfo_DefineMac	"public bool MemoryEmulation.StaticRange_60 : Static SRAM", RomInfo_MemoryEmulation, RomInfo_MemEmu_StaticSram

		RomInfo_SummaryMac	"Defines ROM range 0x8000-0x9fff as static."
		RomInfo_SummaryMac	"May improve compatibility."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Improves performance slightly since v1.6"
		RomInfo_DefineMac	"public bool MemoryEmulation.StaticRange_80 : Static range 8000", RomInfo_StaticRanges, 0x10

		RomInfo_SummaryMac	"Defines ROM range 0xa000-0xbfff as static."
		RomInfo_SummaryMac	"May improve compatibility."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Improves performance slightly since v1.6"
		RomInfo_DefineMac	"public bool MemoryEmulation.StaticRange_a0 : Static range a000", RomInfo_StaticRanges, 0x20

		RomInfo_SummaryMac	"Defines ROM range 0xc000-0xdfff as static."
		RomInfo_SummaryMac	"May improve compatibility."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Improves performance slightly since v1.6"
		RomInfo_DefineMac	"public bool MemoryEmulation.StaticRange_c0 : Static range c000", RomInfo_StaticRanges, 0x40

		RomInfo_SummaryMac	"Defines ROM range 0xe000-0xffff as static."
		RomInfo_SummaryMac	"May improve compatibility."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Improves performance slightly since v1.6"
		RomInfo_DefineMac	"public bool MemoryEmulation.StaticRange_e0 : Static range e000", RomInfo_StaticRanges, 0x80

		RomInfo_SummaryMac	"Number of SRAM banks used for ROM cache."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Requires SRAM size over 16KB."
		RomInfo_SummaryMac	"May cause major slowdowns if this value is too low. Max 30."
		RomInfo_SummaryMac	"May cause 'out of memory' errors if this value is too high."
		RomInfo_DefineMac	"public mapper<69> byte MemoryEmulation.RomCacheBankCount : PRG ROM cache bank count", RomInfo_RomCacheBankCount, 0

	RomInfo_DefineMac	"public void Tab_Cartridge : Cartridge settings.", 0, 0

		RomInfo_SummaryMac	"Truncates the ROM size to the size that it's supposed to be instead of a power of 2"
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Intended for devices that are unable to load 8mb."
		RomInfo_DefineMac	"global public bool Cartridge.TruncateRom : Truncate ROM", RomInfo_CartFlags, RomInfo_CartFlags_TruncateRom

		RomInfo_SummaryMac	"Anything above 3 won't be supported by every SNES emulator or flash cart device."
		RomInfo_SummaryMac	"1 = 2kb *"
		RomInfo_SummaryMac	"2 = 4kb *"
		RomInfo_SummaryMac	"3 = 8kb *"
		RomInfo_SummaryMac	"4 = 16kb"
		RomInfo_SummaryMac	"5 = 32kb"
		RomInfo_SummaryMac	"6 = 64kb"
		RomInfo_SummaryMac	"7 = 128kb"
		RomInfo_SummaryMac	"8 = 256kb"
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"* Sizes below 16kb can't be loaded back into the exe."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Anything above 16kb is used as extra memory for code so that 'Out of Memory' errors are less likely to happen."
		RomInfo_DefineMac	"global public byte Cartridge.SramSize : Sram size", Rom_SramSize+0x800000, 0

	RomInfo_DefineMac	"public void Tab_Cpu : CPU related rules.", 0, 0

		RomInfo_SummaryMac	"This option is for games that store static code into PRG RAM."
		RomInfo_DefineMac	"public bool Cpu.RecompilePrgRam : Recompile PRG RAM", RomInfo_CpuSettings, RomInfo_Cpu_RecompilePrgRam

		RomInfo_SummaryMac	"Adds bank checking to any JSR crossing into a dynamic ROM address."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Comes at a cost of performance."
		RomInfo_DefineMac	"public bool Cpu.DynamicJsr : Dynamic JSR", RomInfo_CpuSettings, RomInfo_Cpu_DynamicJsr

		RomInfo_SummaryMac	"Adds open link JMP after a potential bank change."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Comes at a cost of performance."
		RomInfo_DefineMac	"public mapper<7> bool Cpu.SafePrgBankChange : Safe PRG bank change", RomInfo_CpuSettings, RomInfo_Cpu_SafePrgBankChange

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

		RomInfo_SummaryMac	"Opcodes that stop a 6502 CPU are repurposed for patching games more easily."
		RomInfo_SummaryMac	"Patched bytes usually don't need this setting active."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"If you are interested in using them, see the documentation folder on GitHub for more info."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Includes the following opcodes:"
		RomInfo_SummaryMac	" 02, 22, 42, 62"
		RomInfo_SummaryMac	" 12, 32, 52, 72, 92, B2, D2, F2"
		RomInfo_DefineMac	"public bool Cpu.RepurposedOpcodes : Allow repurposed opcodes", RomInfo_PatchRanges_Active, 0x80

		RomInfo_SummaryMac	"Improves performance but may be unstable."
		RomInfo_SummaryMac	"Please report games that behave differently when this is enabled versus disabled."
		RomInfo_DefineMac	"public bool Optimize.Enabled : Enable AOT optimization (beta)", RomInfo_Optimize, RomInfo_Optimize_StaticRec

		RomInfo_DefineMac	"public Button Optimize : Debug AOT optimization", Zero, 0

		RomInfo_DefineMac	"private void* EmuCalls.Table", EmuCalls_Table, 0

		RomInfo_SummaryMac	"Attempts to auto-play the game during conversion to raise the number of 'known calls'."
		RomInfo_SummaryMac	"Attempts won't be made if the number of 'known calls' is equal or greater than the specified amount."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"3 auto-play sessions take place: idle, turbo A+Start, random"
		RomInfo_DefineMac	"public global short EmuCalls.AutoPlayThreshold : Auto-play threshold", RomInfo_AutoPlayThreshold, 0

	RomInfo_DefineMac	"public void Tab_Stack : Stack related rules.", 0, 0

		RomInfo_DefineMac	"private void* StackEmulation", RomInfo_StackEmulation, 0

		RomInfo_SummaryMac	"Use native return addresses instead of originals. Greatly improves performance."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Turn this option OFF to test whether the game has stack emulation issues."
		RomInfo_DefineMac	"public bool StackEmulation.NativeReturn : Stack emulation, Native return address", RomInfo_StackEmulation, RomInfo_StackEmu_NativeReturn

		RomInfo_SummaryMac	"Use native return address for interrupts instead of originals."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Turning this option OFF will provide better accuracy but not 100%."
		RomInfo_DefineMac	"public bool StackEmulation.NativeReturnInterrupt : Stack emulation, Native return from interrupt", RomInfo_StackEmulation, RomInfo_StackEmu_NativeReturnInterrupt

		RomInfo_SummaryMac	"Take a more lazy approach when solving double return."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Has no effect on performance but may make or break games."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"This option is ignored when 'Native return address' is turned off."
		RomInfo_DefineMac	"public bool StackEmulation.LazyDoubleReturn : Stack emulation, Lazy double return", RomInfo_StackEmulation, RomInfo_StackEmu_LazyDoubleReturn

		RomInfo_SummaryMac	"Detects when a return address is used as data pointer."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Has no effect on performance but may make or break games."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"This option is ignored when 'Native return address' is turned off."
		RomInfo_DefineMac	"public bool StackEmulation.StackUnderflow : Stack emulation, Stack underflow detection", RomInfo_StackEmulation, RomInfo_StackEmu_StackUnderflow

		RomInfo_SummaryMac	"Treats TSX as needing a non-native return address."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Has no effect on performance but may make or break games."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"This option is ignored when 'Native return address' is turned off."
		RomInfo_DefineMac	"public bool StackEmulation.SafeTsx : Stack emulation, Safe TSX", RomInfo_StackEmulation, RomInfo_StackEmu_SafeTsx

		RomInfo_SummaryMac	"Ignores waiting for interrupt to end when stack pointer is set by TXS to a range specified here."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Only active when the lowest number is on the left side."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"This option may prevent some games from hanging."
		RomInfo_DefineMac	"public hex byte[2] StackEmulation.StackResetRange : Reset interrupt on stack reset.", RomInfo_StackResetRange, 0

		RomInfo_SummaryMac	"Decides whether to put stack in page 01 or 09."
		RomInfo_SummaryMac	"Can fix some games and break other games."
		RomInfo_DefineMac	"public bool StackEmulation.Page01 : Stack page 01", RomInfo_StackEmulation, RomInfo_StackEmu_Page01

		RomInfo_SummaryMac	"Attempts to fix pop slide when the following code is present:"
		RomInfo_SummaryMac	" TXS"
		RomInfo_SummaryMac	" -- and --"
		RomInfo_SummaryMac	" PLA"
		RomInfo_SummaryMac	" STA $2007"
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"Requires disabling stack page 01."
		RomInfo_DefineMac	"public bool StackEmulation.PopSlide : Pop slide detection", RomInfo_StackEmulation, RomInfo_StackEmu_PopSlide

	RomInfo_DefineMac	"private void Tab_Banks : Bank and range related rules.", 0, 0

		RomInfo_SummaryMac	"PRG banks to start on after a reset."
		RomInfo_DefineMac	"private hex byte[4] PrgBanks : Starting PRG banks", RomInfo_PrgBankNumbers, 0

		RomInfo_DefineMac	"private hex short PrgBankMask : Program bank mask", RomInfo_PrgBankingMask, 0

		RomInfo_DefineMac	"private hex byte PrgBankNumMask : Program bank number mask", RomInfo_PrgBankNumMask, 0

		RomInfo_SummaryMac	"Maximum distance for a JMP to count as being considered in the same function."
		RomInfo_SummaryMac	"May cause some games to crash."
		RomInfo_SummaryMac	"Use value -1 for unlimited range."
		RomInfo_DefineMac	"private short JumpRange : Jump range", RomInfo_JmpRange, 0
		RomInfo_DefineMac	"private short JumpRange_x2 : Jump range x2", RomInfo_JmpRange_x2, 0

	RomInfo_DefineMac	"private void Tab_Debug : Debug, turn those off for regular play.", 0, 0

		RomInfo_SummaryMac	"Add a dummy STA before each emulated JSR, writing to the original destination address."
		RomInfo_SummaryMac	"Comes at a small cost of performance."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"This effect is ignored when the destination is in RAM or compiled ahead-of-time."
		RomInfo_DefineMac	"global private bool DebugCalls : Debug calls", RomInfo_DebugCalls, 0x00ff

	RomInfo_DefineMac	"private void Tab_Profile : Profile description, do not edit manually.", 0, 0

		RomInfo_SummaryMac	"Used to identify which profile match this game."
		RomInfo_DefineMac	"private char[128] GameName : Game name", RomInfo_GameName, 0

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

		RomInfo_SummaryMac	"Detects PPUSTATUS loop based on timing rather than program counter."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"May cause issues with some games."
		RomInfo_DefineMac	"public bool ImprovedPpuStatusLoopDetection : Improved PPUSTATUS loop detection.", RomInfo_ImprovedPpuStatusLoop, 0x80

		RomInfo_SummaryMac	"Synchronized PPUSTATUS to SNES. Works better with 'NMI mode, at vblank' disabled."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"May cause issues with some games."
		RomInfo_DefineMac	"public bool SyncPpuStatusToSnes : Sync PPUSTATUS to SNES.", RomInfo_SyncPpuStatusToSnes, 0x80

		RomInfo_SummaryMac	"Determines how many lines to skip after an IRQ hit."
		RomInfo_DefineMac	"public mapper<4,69> byte IrqOffset : Mapper IRQ hit offset.", RomInfo_IrqOffset, 0

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

		RomInfo_DefineMac	"private global hex short[0x40] Palette", Gfx_PaletteTable, 0
		RomInfo_DefineMac	"private hex short[0x40] PaletteDefault", Gfx_PaletteTable+0x80, 0

		RomInfo_DefineMac	"public Button CustomPalette : Custom palette", Zero, 0

	RomInfo_DefineMac	"public void Tab_Input : Controller input.", 0, 0

		RomInfo_SummaryMac	"Use custom inputs but lowers performance by up to 2%."
		RomInfo_SummaryMac	""
		RomInfo_SummaryMac	"May cause some games to be unplayable."
		RomInfo_DefineMac	"public global bool Input.Enabled : Enable custom input.", RomInfo_InputFlags, RomInfo_Input_CustomControl

		RomInfo_DefineMac	"private global byte[12] Input.Map", RomInfo_InputMap, 0

		RomInfo_DefineMac	"public Button CustomInput : Custom input", Zero, 0

	RomInfo_DefineMac	"public void Tab_Enhancement : SNES enhancement pack settings.", 0, 0

		RomInfo_SummaryMac	"Bank number must be between $c8-$ff or $40-$7d."
		RomInfo_SummaryMac	"Addresses $0000-$7fff within each bank is then free to use."
		RomInfo_SummaryMac	"Low range of fast ROM is $c8 but subject to change. Avoid using $c8-$ce if possible."
		RomInfo_DefineMac	"public hex byte[2] Enhance.ReservedBanks : Reserved SNES banks", RomInfo_ReservedSnesBanks, 0

	RomInfo_DefineMac	"public void Tab_Gui : Graphical user interface settings.", 0, 0

		//RomInfo_DefineMac	"global public bool Gui.Enabled : Shows CPU% and RAM%.", RomInfo_DebugOverlay, 0x80

		RomInfo_SummaryMac	"Shows CPU% and RAM usage."
		RomInfo_DefineMac	"global public bool Gui.HardwareUsage : Show hardware usage.", RomInfo_DebugOverlay, 0x80

	// End of description
	RomInfo_DefineMac	"", Zero, 0

