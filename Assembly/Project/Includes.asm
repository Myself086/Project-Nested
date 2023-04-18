
.fix "Stuff"

.outfile	"Nothing.smc"

Game "Empty                ", 0x00, 0x00
.else
{
	.nowrite
}

Game "Empty                ", 0x00, 0x00
{
	.outfile	"Project_Nested.smc"

	// ---------------------------------------------------------------------------

	// Macro for crossing half-bank boundary
	.macro	Include_CrossOver	top
temp__:
		.if temp__&0xffff < 0x8000
		{
			.def	temp__		temp__&0xff0000|0x8000
		}
		.def		temp__		temp__&0xbfffff
		.addr		temp__		temp__&0xff0000|{0}
		.vstack		_VSTACK_START
	.endm

	// ---------------------------------------------------------------------------

	// Files with no direct writing
	.include	"Project/Variables.asm"
	.include	"Project/Macros.asm"
	.include	"Project/WDM.asm"
	
	// ---------------------------------------------------------------------------

	// Header
	.include	"Project/Header.asm"

	// ---------------------------------------------------------------------------
	// Bank c0: ROM information and various code not depending on ROM DB

	.addr	0xc00000, 0xc0feff

	.include	"Project/RomInfo.asm"

	.include	"Project/Gui.asm"
	.include	"Project/Gui.StringFormat.asm"
	.include	"Project/EmuCalls.asm"

BankEnd_c0:

	// ---------------------------------------------------------------------------
	// Bank 80

	Include_CrossOver	0xfeff

	// Interpret_Indirect.asm is first in the bank because it starts with a page alignment
	// Must be in the same bank as Interpret_and_Inline.asm and can't be bank 0x00 nor HiROM banks
	.include	"Project/Interpret_Indirect.asm"
	.include	"Project/Interpret_and_Inline.asm"
	.def	Interpret__BANK		0x80

	.include	"Project/IO.4014.asm"

BankEnd_80:

	// ---------------------------------------------------------------------------
	// Bank c1

	.addr	0xc10000, 0xc1fffe

	.include	"Project/Chr.asm"

	.include	"Project/IO.asm"

	// Memory management
	.include	"Project/Array.asm"
	.include	"Project/Memory.asm"
	.include	"Project/Dictionary.asm"

	.include	"Project/DynamicJsr.asm"

	.include	"Project/JMPiList.asm"

	.include	"Project/Feedback.asm"

	.include	"Project/Cop.asm"
	.include	"Project/Hdma.asm"
	.include	"Project/Sound.asm"
	.include	"Project/Patch.asm"

	// Low level emulation
	.include	"Project/Interpreter.asm"

BankEnd_c1:

	// ---------------------------------------------------------------------------
	// Bank 81

	Include_CrossOver	0xfffe

	.include	"Project/Main.asm"
	.include	"Project/Gfx_Interrupt.asm"

	// Recompiler, opcode tables and mappers must be in the same bank
	.include	"Project/Recompiler.asm"
	.include	"Project/OpcodeTables.asm"
	.include	"Project/Mappers/Mapper1.asm"
	.include	"Project/Mappers/Mapper2.asm"
	.include	"Project/Mappers/Mapper3.asm"
	.include	"Project/Mappers/Mapper4.asm"
	.include	"Project/Mappers/Mapper7.asm"
	.include	"Project/Mappers/Mapper69.asm"

	// Static recompiler must be in LoROM bank
	.include	"Project/StaticRec.asm"

	// Trap unsupported mappers
	[0x81ffff] = 0x00

BankEnd_81:

	// ---------------------------------------------------------------------------
	// Bank c2

	.addr	0xc20000, 0xc2ffff

	.include	"Project/RomCache.asm"
	.include	"Project/SelfMod.asm"

	// Sound
Spc_Code_Start:
	.fix "Sound"
	.offsetfrom		0x0400
	.includeSPC	"Project/Spc700/Spc.asm"
	.includeSPC	"Project/Spc700/Spc.Memory.asm"
	.includeSPC	"Project/Spc700/Dmc.asm"
Spc_HeapStart:
	.offsetend
	.fix "Stuff"
Spc_Code_End:

BankEnd_c2:

	// ---------------------------------------------------------------------------
	// Bank 82

	Include_CrossOver	0xffff

	// Nothing here yet

BankEnd_82:

	// ---------------------------------------------------------------------------
	// Bank c3-c4: Unrolled indirect JMP and non-native return

	.addr	0xc30000, 0xc4ffff
JMPiU_Start:
	.include	"Project/JMPiUnrolled.asm"

	// ---------------------------------------------------------------------------
	// Bank c5: Static recompiler call tables (no static data)

	.addr	0xc50000, 0xc5ffff
StaticRec_Tables:
	// 256 arrays containing 16-bit address and 16-bit length
	// Each sub array contains (same format as known calls in RAM):
	// [0] 24-bit for the original address
	// [3] 24-bit new call address
	// [6] 16-bit recompiler flags

	// ---------------------------------------------------------------------------
	// Bank c6-c7: Unlinked calls recompiled ahead of time (no static data)

	// Origins: [0] = Original return, [2] = Original destination
	.def	StaticRec_Origins		0xc60000
	// OriginsB: [0] = SNES return, [3] = Temporary validation
	.def	StaticRec_OriginsB		0xc70000

	// ---------------------------------------------------------------------------

	// Final ROM size
	.finalsize	0x050000

	// ---------------------------------------------------------------------------
}
