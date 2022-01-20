
	// ---------------------------------------------------------------------------

	.macro	EmuCalls_SetFlag	flagNames, contains, setbit
		.ifnamecontains		"{0}", "{1}"
		{
			.def	temp__		temp__|{2}
		}
	.endm

	.macro	EmuCalls_Flags		flagNames
		// ---- ----  _Tt! *W?P  DBKS HYXA  nvmx dizc
		// Notes:
		//  nvmxdizc = Register P bits
		//  YXA = Register A, X and Y
		//  H = A.hi
		//  S = SP
		//  K = PC
		//  B = DB
		//  D = DP
		//  P = The whole P register, usually reserved by PHP and PLP
		//  W = Write
		//  ? = Exception
		//  * = Marker
		//  ! = Nes bank range
		//  t = IOTemp
		//  T = IOTemp16
		//  _ = Can inline
		//  - = Unused or undefined
		.def	temp__		0

		EmuCalls_SetFlag	"{0}", "c", 0x000001
		EmuCalls_SetFlag	"{0}", "z", 0x000002
		EmuCalls_SetFlag	"{0}", "i", 0x000004
		EmuCalls_SetFlag	"{0}", "d", 0x000008
		EmuCalls_SetFlag	"{0}", "x", 0x000010
		EmuCalls_SetFlag	"{0}", "m", 0x000020
		EmuCalls_SetFlag	"{0}", "v", 0x000040
		EmuCalls_SetFlag	"{0}", "n", 0x000080
		EmuCalls_SetFlag	"{0}", "A", 0x000100
		EmuCalls_SetFlag	"{0}", "X", 0x000200
		EmuCalls_SetFlag	"{0}", "Y", 0x000400
		EmuCalls_SetFlag	"{0}", "H", 0x000800
		EmuCalls_SetFlag	"{0}", "S", 0x001000
		EmuCalls_SetFlag	"{0}", "K", 0x002000
		EmuCalls_SetFlag	"{0}", "B", 0x004000
		EmuCalls_SetFlag	"{0}", "D", 0x008000
		EmuCalls_SetFlag	"{0}", "P", 0x010000
		EmuCalls_SetFlag	"{0}", "?", 0x020000
		EmuCalls_SetFlag	"{0}", "W", 0x040000
		EmuCalls_SetFlag	"{0}", "*", 0x080000
		EmuCalls_SetFlag	"{0}", "!", 0x100000
		EmuCalls_SetFlag	"{0}", "t", 0x200000
		EmuCalls_SetFlag	"{0}", "T", 0x400000
		EmuCalls_SetFlag	"{0}", "_", 0x800000

		.data32	temp__
	.endm

	.macro	EmuCalls		name, usage, change
this__:
		.pushaddr
			.addr	EmuCalls_Table_WritePointer
			.string0			"{0}"
			.data24				this__
			EmuCalls_Flags		"{1}"
			EmuCalls_Flags		"{2}"
EmuCalls_Table_WritePointer:	// Set address for next element
		.pulladdr
	.endm

EmuCalls_Table:
	.addrlow	EmuCalls_Table_WritePointer
	.data8		0
	.def		EmuCalls_Table_WritePointer		EmuCalls_Table

	// ---------------------------------------------------------------------------
