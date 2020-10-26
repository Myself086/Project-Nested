
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

	// Files with no direct writing
	.include	"Project/Variables.asm"
	.include	"Project/Macros.asm"
	.include	"Project/WDM.asm"
	
	// ---------------------------------------------------------------------------

	// Header
	.include	"Project/Header.asm"

	// ---------------------------------------------------------------------------
	// Bank 80: Various code including start-up

	.addr	0x808000, 0x80feff

	.include	"Project/Chr.asm"
	.include	"Project/IO.asm"
	.include	"Project/Interpret_and_Inline.asm"
	.include	"Project/JMPiList.asm"
	.include	"Project/Cop.asm"
	.def	IO__BANK			0x80
	.def	Interpret__BANK		0x80

	// ---------------------------------------------------------------------------
	// Bank c0: ROM information and various code not depending on ROM DB

	.addr	0xc00000, 0xc07fff
	.include	"Project/RomInfo.asm"

	// Sound
Spc_Code_Start:
	.offsetfrom		0x0400
	.includeSPC	"Project/Spc700/Spc.asm"
	.offsetend
Spc_Code_End:

	.include	"Project/Gui.asm"
	.include	"Project/Gui.StringFormat.asm"
	.include	"Project/Hdma.asm"
	.include	"Project/Sound.asm"

	// Exception data must be at the end of the bank and in the same bank as Gui
ExceptionData_Start:
ExceptionData:

	// ---------------------------------------------------------------------------
	// Bank 81: Recompiler, opcode tables and mappers must be in the same bank

	.addr	0x818000, 0x81fffe

	.include	"Project/Main.asm"
	.include	"Project/Gfx_Interrupt.asm"

	// Recompiler
	.include	"Project/Recompiler.asm"
	.include	"Project/OpcodeTables.asm"
	.include	"Project/Mappers/Mapper1.asm"
	.include	"Project/Mappers/Mapper2.asm"
	.include	"Project/Mappers/Mapper4.asm"

	// Memory management
	.include	"Project/Array.asm"
	.include	"Project/Memory.asm"
	.include	"Project/Dictionary.asm"

	// Static recompiler code
	.include	"Project/Feedback.asm"
	.include	"Project/StaticRec.asm"

	// Low level emulation
	.include	"Project/Interpreter.asm"

	// Trap unsupported mappers
	[0x81ffff] = 0x00

	// ---------------------------------------------------------------------------
	// Bank c1: Unlinked calls recompiled ahead of time

	// Origins: [0] = Original return, [2] = Original destination
	.def	StaticRec_Origins		0xc10000

	// ---------------------------------------------------------------------------
	// Bank 82: Static recompiler call tables (no static data)

	.addr	0xc20000, 0xc2ffff
StaticRec_Tables:
	// 256 arrays containing 16-bit address and 16-bit length
	// Each sub array contains (same format as known calls in RAM):
	// [0] 24-bit for the original address
	// [3] 24-bit new call address
	// [6] 16-bit recompiler flags
	
	// ---------------------------------------------------------------------------

	// Final ROM size
	.finalsize	0x020000

	// ---------------------------------------------------------------------------
}
