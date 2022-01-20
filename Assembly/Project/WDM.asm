
	// ---------------------------------------------------------------------------
	// Converter WDM instructions

	.macro	WDM_TestCommunication
		// Returns:
		//  A = exe version in decimal (example: v1.23.45 -> 12345)
		//  Overflow = set when exe is in debug mode
		//  Carry = set
		wdm	#0x00
	.endm

	.macro	WDM_PushByteArray
		// Push a byte[] to a stack on the exe
		// Entries:
		//  A = Address
		//  X = Length
		//  Y = Address bank
		wdm	#0x01
	.endm

	.macro	WDM_PullByteArray
		// Pull a byte[] from a stack on the exe
		// Entries:
		//  A = Address
		//  Y = Address bank
		// Returns:
		//  X = Length
		//  Carry = set when successful
		wdm	#0x02
	.endm

	.macro	WDM_PeekByteArray
		// Peek a byte[] from a stack on the exe
		// Returns:
		//  X = Length
		//  Carry = set when successful
		wdm	#0x03
	.endm

	.macro	WDM_RequestFunction
		// Entries:
		//  A = Address
		//  Y = Address bank
		// Returns:
		//  byte[] = Function code
		//  A = Entry point offset
		//  X = Compile flags
		//  Y = Bank number to allocate in (0 when unspecified)
		//  Carry = set when successful
		wdm	#0x04
	.endm

	.macro	WDM_SetFunctionSnesAddress
		// Sets the SNES address for the previously requested function
		// Entries:
		//  A = Address
		//  Y = Address bank
		wdm	#0x05
	.endm

	// ---------------------------------------------------------------------------
	// Debugger WDM instructions

	.macro	WDM_LoadPreviousEntryPoint
		wdm	#0xff
	.endm
	
	.macro	WDM_StorePreviousEntryPoint
		wdm	#0xfe
	.endm

	.macro	WDM_ExportCallList
		// Entries (all 16-bit):
		//  A = MSB of bank translation lookup tables
		//  X = LSB of known call struct
		//  Y = MSB of AOT known calls
		wdm	#0xfd
	.endm
