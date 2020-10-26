
	.macro	WDM_LoadPreviousEntryPoint
		wdm	#0xff
	.endm
	
	.macro	WDM_StorePreviousEntryPoint
		wdm	#0xfe
	.endm

	.macro	WDM_ExportCallList_x
		wdm	#0xfd
	.endm
