
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
