
	// Instruction set in a 16x16 table
	// http://www.masswerk.at/6502/6502_instruction_set.html
	
Opcode__BytesTable:
	//      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
	.data16	2, 2, 2, 0, 0, 2, 2, 0, 1, 2, 1, 0, 0, 3, 3, 0
	.data16	2, 2, 2, 0, 0, 2, 2, 0, 1, 3, 0, 0, 0, 3, 3, 0
	.data16	3, 2, 4, 0, 2, 2, 2, 0, 1, 2, 1, 0, 3, 3, 3, 0
	.data16	2, 2, 2, 0, 0, 2, 2, 0, 1, 3, 0, 0, 0, 3, 3, 0
	.data16	1, 2, 0, 0, 0, 2, 2, 0, 1, 2, 1, 0, 3, 3, 3, 0
	.data16	2, 2, 2, 0, 0, 2, 2, 0, 1, 3, 0, 0, 0, 3, 3, 0
	.data16	1, 2, 1, 0, 0, 2, 2, 0, 1, 2, 1, 0, 3, 3, 3, 0
	.data16	2, 2, 2, 0, 0, 2, 2, 0, 1, 3, 0, 0, 0, 3, 3, 0
	.data16	0, 2, 0, 0, 2, 2, 2, 0, 1, 0, 1, 0, 3, 3, 3, 0
	.data16	2, 2, 2, 0, 2, 2, 2, 0, 1, 3, 1, 0, 0, 3, 0, 0
	.data16	2, 2, 2, 0, 2, 2, 2, 0, 1, 2, 1, 0, 3, 3, 3, 0
	.data16	2, 2, 2, 0, 2, 2, 2, 0, 1, 3, 1, 0, 3, 3, 3, 0
	.data16	2, 2, 0, 0, 2, 2, 2, 0, 1, 2, 1, 0, 3, 3, 3, 0
	.data16	2, 2, 2, 0, 0, 2, 2, 0, 1, 3, 0, 0, 0, 3, 3, 0
	.data16	2, 2, 0, 0, 2, 2, 2, 0, 1, 2, 1, 0, 3, 3, 3, 0
	.data16	2, 2, 2, 0, 0, 2, 2, 0, 1, 3, 0, 0, 0, 3, 3, 0

Opcode__BytesTable_MinusOne:
	//      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
	.data16	1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 2, 2, 0
	.data16	1, 1, 1, 0, 0, 1, 1, 0, 0, 2, 0, 0, 0, 2, 2, 0
	.data16	2, 1, 3, 0, 1, 1, 1, 0, 0, 1, 0, 0, 2, 2, 2, 0
	.data16	1, 1, 1, 0, 0, 1, 1, 0, 0, 2, 0, 0, 0, 2, 2, 0
	.data16	0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 2, 2, 2, 0
	.data16	1, 1, 1, 0, 0, 1, 1, 0, 0, 2, 0, 0, 0, 2, 2, 0
	.data16	0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 2, 2, 2, 0
	.data16	1, 1, 1, 0, 0, 1, 1, 0, 0, 2, 0, 0, 0, 2, 2, 0
	.data16	0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 2, 2, 2, 0
	.data16	1, 1, 1, 0, 1, 1, 1, 0, 0, 2, 0, 0, 0, 2, 0, 0
	.data16	1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0, 2, 2, 2, 0
	.data16	1, 1, 1, 0, 1, 1, 1, 0, 0, 2, 0, 0, 2, 2, 2, 0
	.data16	1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 2, 2, 2, 0
	.data16	1, 1, 1, 0, 0, 1, 1, 0, 0, 2, 0, 0, 0, 2, 2, 0
	.data16	1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 2, 2, 2, 0
	.data16	1, 1, 1, 0, 0, 1, 1, 0, 0, 2, 0, 0, 0, 2, 2, 0

Opcode__BytesTable_OneOrMore:
	//      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
	.data16	2, 2, 2, 1, 1, 2, 2, 1, 1, 2, 1, 1, 1, 3, 3, 1
	.data16	2, 2, 2, 1, 1, 2, 2, 1, 1, 3, 1, 1, 1, 3, 3, 1
	.data16	3, 2, 4, 1, 2, 2, 2, 1, 1, 2, 1, 1, 3, 3, 3, 1
	.data16	2, 2, 2, 1, 1, 2, 2, 1, 1, 3, 1, 1, 1, 3, 3, 1
	.data16	1, 2, 1, 1, 1, 2, 2, 1, 1, 2, 1, 1, 3, 3, 3, 1
	.data16	2, 2, 2, 1, 1, 2, 2, 1, 1, 3, 1, 1, 1, 3, 3, 1
	.data16	1, 2, 1, 1, 1, 2, 2, 1, 1, 2, 1, 1, 3, 3, 3, 1
	.data16	2, 2, 2, 1, 1, 2, 2, 1, 1, 3, 1, 1, 1, 3, 3, 1
	.data16	1, 2, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 3, 3, 3, 1
	.data16	2, 2, 2, 1, 2, 2, 2, 1, 1, 3, 1, 1, 1, 3, 1, 1
	.data16	2, 2, 2, 1, 2, 2, 2, 1, 1, 2, 1, 1, 3, 3, 3, 1
	.data16	2, 2, 2, 1, 2, 2, 2, 1, 1, 3, 1, 1, 3, 3, 3, 1
	.data16	2, 2, 1, 1, 2, 2, 2, 1, 1, 2, 1, 1, 3, 3, 3, 1
	.data16	2, 2, 2, 1, 1, 2, 2, 1, 1, 3, 1, 1, 1, 3, 3, 1
	.data16	2, 2, 1, 1, 2, 2, 2, 1, 1, 2, 1, 1, 3, 3, 3, 1
	.data16	2, 2, 2, 1, 1, 2, 2, 1, 1, 3, 1, 1, 1, 3, 3, 1
	
Opcode__BytesTable65816:
	//      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
	.data16	2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1, 1, 3, 3, 3, 4
	.data16	2, 2, 2, 2, 2, 2, 2, 2, 1, 3, 1, 1, 3, 3, 3, 4
	.data16	3, 2, 4, 2, 2, 2, 2, 2, 1, 2, 1, 1, 3, 3, 3, 4
	.data16	2, 2, 2, 2, 2, 2, 2, 2, 1, 3, 1, 1, 3, 3, 3, 4
	.data16	1, 2, 2, 2, 3, 2, 2, 2, 1, 2, 1, 1, 3, 3, 3, 4
	.data16	2, 2, 2, 2, 3, 2, 2, 2, 1, 3, 1, 1, 4, 3, 3, 4
	.data16	1, 2, 3, 2, 2, 2, 2, 2, 1, 2, 1, 1, 3, 3, 3, 4
	.data16	2, 2, 2, 2, 2, 2, 2, 2, 1, 3, 1, 1, 3, 3, 3, 4
	.data16	2, 2, 3, 2, 2, 2, 2, 2, 1, 2, 1, 1, 3, 3, 3, 4
	.data16	2, 2, 2, 2, 2, 2, 2, 2, 1, 3, 1, 1, 3, 3, 3, 4
	.data16	2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1, 1, 3, 3, 3, 4
	.data16	2, 2, 2, 2, 2, 2, 2, 2, 1, 3, 1, 1, 3, 3, 3, 4
	.data16	2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1, 1, 3, 3, 3, 4
	.data16	2, 2, 2, 2, 2, 2, 2, 2, 1, 3, 1, 1, 3, 3, 3, 4
	.data16	2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1, 1, 3, 3, 3, 4
	.data16	2, 2, 2, 2, 3, 2, 2, 2, 1, 3, 1, 1, 3, 3, 3, 4

false
{
	// Same order of flag as the P register: nvmx dizc
	// High bits = requirement, low bits = change
	// Exception on flags: high I = affects PC register, high D = conditional branch
Opcode__FlagTable65816:
	//      0       1       2       3       4       5       6       7       8       9       a       b       c       d       e       f
	.data16	0xfbff, 0x0082, 0xfbff, 0x0082, 0x0002, 0x0082, 0x0083, 0x0082, 0x00ff, 0x0082, 0x0083, 0x0000, 0x0002, 0x0082, 0x0083, 0x0082
	.data16	0x8c00, 0x0082, 0x0082, 0x0082, 0x0002, 0x0082, 0x0083, 0x0082, 0x0001, 0x0082, 0x0082, 0x0000, 0x0002, 0x0082, 0x0083, 0x0082
	.data16	0xfbff, 0x0082, 0xfbff, 0x0082, 0x00c2, 0x0082, 0x0183, 0x0082, 0x00ff, 0x0082, 0x0183, 0x0082, 0x0002, 0x0082, 0x0183, 0x0082
	.data16	0x8c00, 0x0082, 0x0082, 0x0082, 0x00c2, 0x0082, 0x0183, 0x0082, 0x0001, 0x0082, 0x0082, 0x0082, 0x00c2, 0x0082, 0x0183, 0x0082
	.data16	0xfb00, 0x0082, 0x0000, 0x0082, 0x0000, 0x0082, 0x0083, 0x0082, 0x0000, 0x0082, 0x0083, 0x0000, 0xfb00, 0x0082, 0x0083, 0x0082
	.data16	0x4c00, 0x0082, 0x0082, 0x0082, 0x0000, 0x0082, 0x0083, 0x0082, 0x0000, 0x0082, 0x0000, 0x0082, 0xfb00, 0x0082, 0x0083, 0x0082
	.data16	0xfb00, 0x01c3, 0x0000, 0x01c3, 0x0000, 0x01c3, 0x0183, 0x01c3, 0x0082, 0x01c3, 0x0183, 0xfb00, 0xfb00, 0x01c3, 0x0183, 0x01c3
	.data16	0x4c00, 0x01c3, 0x01c3, 0x01c3, 0x0000, 0x01c3, 0x0183, 0x01c3, 0x0000, 0x01c3, 0x0082, 0x0082, 0xfb00, 0x01c3, 0x0183, 0x01c3
	.data16	0x0400, 0x0000, 0xfbff, 0x0000, 0x0000, 0x0000, 0x0183, 0x0000, 0x0082, 0x00c2, 0x0082, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.data16	0x0d00, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0082, 0x0000, 0x0000, 0x0082, 0x0000, 0x0000, 0x0000, 0x0000
	.data16	0x0082, 0x0082, 0x0082, 0x0082, 0x0082, 0x0082, 0x0000, 0x0082, 0x0082, 0x0082, 0x0082, 0x0082, 0x0082, 0x0082, 0x0082, 0x0082
	.data16	0x0d00, 0x0082, 0x0082, 0x0082, 0x0082, 0x0082, 0x0082, 0x0082, 0x0040, 0x0082, 0x0082, 0x0082, 0x0082, 0x0082, 0x0082, 0x0082
	.data16	0x00c3, 0x00c3, 0x0030, 0x00c3, 0x00c3, 0x00c3, 0x0082, 0x00c3, 0x0082, 0x00c3, 0x0082, 0x0000, 0x00c3, 0x00c3, 0x0082, 0x00c3
	.data16	0x0e00, 0x00c3, 0x00c3, 0x00c3, 0x0000, 0x00c3, 0x0082, 0x00c3, 0x0000, 0x00c3, 0x0000, 0x0000, 0xfb00, 0x00c3, 0x0082, 0x00c3
	.data16	0x00c3, 0x01c3, 0x0030, 0x01c3, 0x00c3, 0x01c3, 0x0082, 0x01c3, 0x0082, 0x01c3, 0x0000, 0x0082, 0x00c3, 0x01c3, 0x0082, 0x01c3
	.data16	0x0e00, 0x01c3, 0x01c3, 0x01c3, 0x0000, 0x01c3, 0x0082, 0x01c3, 0x0000, 0x01c3, 0x0082, 0x0101, 0xfb00, 0x01c3, 0x0082, 0x01c3

	// Order of bits: 000A 0yxa
	// High bits = requirement, low bits = change
Opcode__RegTable65816:	
	//      0       1       2       3       4       5       6       7       8       9       a       b       c       d       e       f
	.data16	0x0000, 0x0301, 0x0000, 0x0101, 0x0100, 0x0101, 0x0000, 0x0101, 0x0000, 0x0101, 0x0101, 0x0000, 0x0100, 0x0101, 0x0000, 0x0101
	.data16	0x0000, 0x0501, 0x0101, 0x0501, 0x0100, 0x0301, 0x0200, 0x0501, 0x0000, 0x0501, 0x0101, 0x1100, 0x0100, 0x0301, 0x0200, 0x0301
	.data16	0x0700, 0x0301, 0x0700, 0x0101, 0x0100, 0x0101, 0x0000, 0x0101, 0x0000, 0x0101, 0x0101, 0x0000, 0x0100, 0x0101, 0x0000, 0x0101
	.data16	0x0000, 0x0501, 0x0101, 0x0501, 0x0300, 0x0301, 0x0200, 0x0501, 0x0000, 0x0501, 0x0101, 0x0011, 0x0300, 0x0301, 0x0200, 0x0301
	.data16	0x0700, 0x0301, 0x0000, 0x0101, 0x1707, 0x0101, 0x0000, 0x0101, 0x0100, 0x0101, 0x0101, 0x0000, 0x0700, 0x0101, 0x0000, 0x0101
	.data16	0x0000, 0x0501, 0x0101, 0x0501, 0x1707, 0x0301, 0x0200, 0x0501, 0x0000, 0x0501, 0x0400, 0x1100, 0x0700, 0x0301, 0x0200, 0x0301
	.data16	0x0700, 0x0301, 0x0000, 0x0101, 0x0000, 0x0101, 0x0000, 0x0101, 0x0001, 0x0101, 0x0101, 0x0700, 0x0700, 0x0101, 0x0000, 0x0101
	.data16	0x0000, 0x0501, 0x0101, 0x0501, 0x0200, 0x0301, 0x0200, 0x0501, 0x0000, 0x0501, 0x0004, 0x0011, 0x0700, 0x0301, 0x0200, 0x0301
	.data16	0x0000, 0x0300, 0x0000, 0x0100, 0x0400, 0x0100, 0x0200, 0x0100, 0x0404, 0x0100, 0x0201, 0x0000, 0x0400, 0x0100, 0x0200, 0x0100
	.data16	0x0000, 0x0500, 0x0100, 0x0500, 0x0600, 0x0300, 0x0600, 0x0500, 0x0401, 0x0500, 0x0200, 0x0204, 0x0000, 0x0300, 0x0200, 0x0300
	.data16	0x0004, 0x0201, 0x0002, 0x0001, 0x0004, 0x0001, 0x0002, 0x0001, 0x0104, 0x0001, 0x0102, 0x0000, 0x0004, 0x0001, 0x0002, 0x0001
	.data16	0x0000, 0x0401, 0x0001, 0x0401, 0x0204, 0x0201, 0x0402, 0x0401, 0x0000, 0x0401, 0x0002, 0x0402, 0x0204, 0x0201, 0x0402, 0x0201
	.data16	0x0400, 0x0300, 0x1000, 0x0100, 0x0400, 0x0100, 0x0000, 0x0101, 0x0404, 0x0100, 0x0202, 0x0000, 0x0400, 0x0100, 0x0000, 0x0100
	.data16	0x0000, 0x0500, 0x0100, 0x0500, 0x0000, 0x0300, 0x0200, 0x0501, 0x0000, 0x0500, 0x0200, 0x0000, 0x0700, 0x0300, 0x0200, 0x0300
	.data16	0x0200, 0x0301, 0x1000, 0x0101, 0x0400, 0x0101, 0x0000, 0x0101, 0x0202, 0x0101, 0x0000, 0x1111, 0x0200, 0x0101, 0x0000, 0x0101
	.data16	0x0000, 0x0501, 0x0101, 0x0501, 0x0000, 0x0301, 0x0200, 0x0501, 0x0000, 0x0501, 0x0002, 0x0000, 0x0700, 0x0301, 0x0200, 0x0301
}

	// Format: ___A _YXA nvmx dizc
	// Exception on flags: I = affects PC register, D = conditional branch
Opcode__AffectChangeTable65816:
	.data16	0x00ff, 0x0182, 0x00ff, 0x0182, 0x0002, 0x0182, 0x0083, 0x0182, 0x00ff, 0x0182, 0x0183, 0x0000, 0x0002, 0x0182, 0x0083, 0x0182
	.data16	0x0000, 0x0182, 0x0182, 0x0182, 0x0002, 0x0182, 0x0083, 0x0182, 0x0001, 0x0182, 0x0182, 0x0000, 0x0002, 0x0182, 0x0083, 0x0182
	.data16	0x00ff, 0x0182, 0x00ff, 0x0182, 0x00c2, 0x0182, 0x0083, 0x0182, 0x00ff, 0x0182, 0x0183, 0x0082, 0x0002, 0x0182, 0x0083, 0x0182
	.data16	0x0000, 0x0182, 0x0182, 0x0182, 0x00c2, 0x0182, 0x0083, 0x0182, 0x0001, 0x0182, 0x0182, 0x1182, 0x00c2, 0x0182, 0x0083, 0x0182
	.data16	0x0000, 0x0182, 0x0000, 0x0182, 0x0700, 0x0182, 0x0083, 0x0182, 0x0000, 0x0182, 0x0183, 0x0000, 0x0000, 0x0182, 0x0083, 0x0182
	.data16	0x0000, 0x0182, 0x0182, 0x0182, 0x0700, 0x0182, 0x0083, 0x0182, 0x0000, 0x0182, 0x0000, 0x0082, 0x0000, 0x0182, 0x0083, 0x0182
	.data16	0x0000, 0x01c3, 0x0000, 0x01c3, 0x0000, 0x01c3, 0x0083, 0x01c3, 0x0182, 0x01c3, 0x0183, 0x0000, 0x0000, 0x01c3, 0x0083, 0x01c3
	.data16	0x0000, 0x01c3, 0x01c3, 0x01c3, 0x0000, 0x01c3, 0x0083, 0x01c3, 0x0000, 0x01c3, 0x0482, 0x1182, 0x0000, 0x01c3, 0x0083, 0x01c3
	.data16	0x0000, 0x0000, 0x00ff, 0x0000, 0x0000, 0x0000, 0x0083, 0x0000, 0x0482, 0x00c2, 0x0182, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.data16	0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0182, 0x0000, 0x0000, 0x0482, 0x0000, 0x0000, 0x0000, 0x0000
	.data16	0x0482, 0x0182, 0x0282, 0x0182, 0x0482, 0x0182, 0x0200, 0x0182, 0x0482, 0x0182, 0x0282, 0x0082, 0x0482, 0x0182, 0x0282, 0x0182
	.data16	0x0000, 0x0182, 0x0182, 0x0182, 0x0482, 0x0182, 0x0282, 0x0182, 0x0040, 0x0182, 0x0282, 0x0282, 0x0482, 0x0182, 0x0282, 0x0182
	.data16	0x00c3, 0x00c3, 0x0030, 0x00c3, 0x00c3, 0x00c3, 0x0082, 0x01c3, 0x0482, 0x00c3, 0x0282, 0x0000, 0x00c3, 0x00c3, 0x0082, 0x00c3
	.data16	0x0000, 0x00c3, 0x00c3, 0x00c3, 0x0000, 0x00c3, 0x0082, 0x01c3, 0x0000, 0x00c3, 0x0000, 0x0000, 0x0000, 0x00c3, 0x0082, 0x00c3
	.data16	0x00c3, 0x01c3, 0x0030, 0x01c3, 0x00c3, 0x01c3, 0x0082, 0x01c3, 0x0282, 0x01c3, 0x0000, 0x1182, 0x00c3, 0x01c3, 0x0082, 0x01c3
	.data16	0x0000, 0x01c3, 0x01c3, 0x01c3, 0x0000, 0x01c3, 0x0082, 0x01c3, 0x0000, 0x01c3, 0x0282, 0x0001, 0x0000, 0x01c3, 0x0082, 0x01c3

	// Format: ___A _YXA nvmx dizc
Opcode__AffectReqTable65816:
	.data16	0x00fb, 0x0300, 0x00fb, 0x0100, 0x0100, 0x0100, 0x0000, 0x0100, 0x0000, 0x0100, 0x0100, 0x0000, 0x0100, 0x0100, 0x0000, 0x0100
	.data16	0x008c, 0x0500, 0x0100, 0x0500, 0x0100, 0x0300, 0x0200, 0x0500, 0x0000, 0x0500, 0x0100, 0x1100, 0x0100, 0x0300, 0x0200, 0x0300
	.data16	0x07fb, 0x0300, 0x07fb, 0x0100, 0x0100, 0x0100, 0x0001, 0x0100, 0x0000, 0x0100, 0x0101, 0x0000, 0x0100, 0x0100, 0x0001, 0x0100
	.data16	0x008c, 0x0500, 0x0100, 0x0500, 0x0300, 0x0300, 0x0201, 0x0500, 0x0000, 0x0500, 0x0100, 0x0000, 0x0300, 0x0300, 0x0201, 0x0300
	.data16	0x07fb, 0x0300, 0x0000, 0x0100, 0x1700, 0x0100, 0x0000, 0x0100, 0x0100, 0x0100, 0x0100, 0x0000, 0x07fb, 0x0100, 0x0000, 0x0100
	.data16	0x004c, 0x0500, 0x0100, 0x0500, 0x1700, 0x0300, 0x0200, 0x0500, 0x0000, 0x0500, 0x0400, 0x1100, 0x07fb, 0x0300, 0x0200, 0x0300
	.data16	0x07fb, 0x0301, 0x0000, 0x0101, 0x0000, 0x0101, 0x0001, 0x0101, 0x0000, 0x0101, 0x0101, 0x07fb, 0x07fb, 0x0101, 0x0001, 0x0101
	.data16	0x004c, 0x0501, 0x0101, 0x0501, 0x0200, 0x0301, 0x0201, 0x0501, 0x0000, 0x0501, 0x0000, 0x0000, 0x07fb, 0x0301, 0x0201, 0x0301
	.data16	0x0004, 0x0300, 0x00fb, 0x0100, 0x0400, 0x0100, 0x0201, 0x0100, 0x0400, 0x0100, 0x0200, 0x0000, 0x0400, 0x0100, 0x0200, 0x0100
	.data16	0x000d, 0x0500, 0x0100, 0x0500, 0x0600, 0x0300, 0x0600, 0x0500, 0x0400, 0x0500, 0x0200, 0x0200, 0x0000, 0x0300, 0x0200, 0x0300
	.data16	0x0000, 0x0200, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0100, 0x0000, 0x0100, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.data16	0x000d, 0x0400, 0x0000, 0x0400, 0x0200, 0x0200, 0x0400, 0x0400, 0x0000, 0x0400, 0x0000, 0x0400, 0x0200, 0x0200, 0x0400, 0x0200
	.data16	0x0400, 0x0300, 0x1000, 0x0100, 0x0400, 0x0100, 0x0000, 0x0100, 0x0400, 0x0100, 0x0200, 0x0000, 0x0400, 0x0100, 0x0000, 0x0100
	.data16	0x000e, 0x0500, 0x0100, 0x0500, 0x0000, 0x0300, 0x0200, 0x0500, 0x0000, 0x0500, 0x0200, 0x0000, 0x07fb, 0x0300, 0x0200, 0x0300
	.data16	0x0200, 0x0301, 0x1000, 0x0101, 0x0400, 0x0101, 0x0000, 0x0101, 0x0200, 0x0101, 0x0000, 0x1100, 0x0200, 0x0101, 0x0000, 0x0101
	.data16	0x000e, 0x0501, 0x0101, 0x0501, 0x0000, 0x0301, 0x0200, 0x0501, 0x0000, 0x0501, 0x0000, 0x0001, 0x07fb, 0x0301, 0x0200, 0x0301

	// Address modes
	.def	Opcode__A_None			0x00
	.def	Opcode__A_Impl			0x02
	.def	Opcode__A_Abs			0x04
	.def	Opcode__A_AbsX			0x06
	.def	Opcode__A_AbsY			0x08
	.def	Opcode__A_Const			0x0a
	.def	Opcode__A_Ind			0x0c
	.def	Opcode__A_XInd			0x0e
	.def	Opcode__A_IndY			0x10
	.def	Opcode__A_Br			0x12
	.def	Opcode__A_Zpg			0x14
	.def	Opcode__A_ZpgX			0x16
	.def	Opcode__A_ZpgY			0x18
	.def	Opcode__A_Jmp			0x1a
	.def	Opcode__A_JmpI			0x1c
	.def	Opcode__A_Jsr			0x1e
	.def	Opcode__A_Brk			0x20
	.def	Opcode__A_Rts			0x22
	.def	Opcode__A_Rti			0x24
	.def	Opcode__A_StaA			0x26
	.def	Opcode__A_StxA			0x28
	.def	Opcode__A_StyA			0x2a
	.def	Opcode__A_Pha			0x2c
	.def	Opcode__A_LdaA			0x2e
	.def	Opcode__A_LdxA			0x30
	.def	Opcode__A_LdyA			0x32
	.def	Opcode__A_Pla			0x34
	.def	Opcode__A_Txs			0x36
	.def	Opcode__A_Cop			0x38
	.def	Opcode__A_StaAbsX		0x3a
	.def	Opcode__A_StaAbsY		0x3c
	.def	Opcode__A_StaXInd		0x3e
	.def	Opcode__A_StaIndY		0x40
	.def	Opcode__A_LdaXInd		0x42
	.def	Opcode__A_LdaIndY		0x44
	.def	Opcode__A_YAbsX			0x46
	.def	Opcode__A_LdaConst		0x48
	.def	Opcode__A_Sei			0x4a
	.def	Opcode__A_Cli			0x4c
	.def	Opcode__A_LdaAbsX		0x4e
	.def	Opcode__A_LdaAbsY		0x50
	.def	Opcode__A_Php			0x52
	.def	Opcode__A_Plp			0x54
	.def	Opcode__A_Brw			0x56
	.def	Opcode__A_RtsNes		0x58
	.def	Opcode__A_Jsl			0x5a

Opcode__AddrMode:
	//      0                 1                   2                  3                4                5                6                7                8                9                    a                b                c                 d                   e                f
	.data16	_Opcode__A_Brk,   _Opcode__A_XInd,    _Opcode__A_Cop,    _Opcode__A_None, _Opcode__A_None, _Opcode__A_Zpg,  _Opcode__A_Zpg,  _Opcode__A_None, _Opcode__A_Php, _Opcode__A_Const,    _Opcode__A_Impl, _Opcode__A_None, _Opcode__A_None,  _Opcode__A_Abs,     _Opcode__A_Abs,  _Opcode__A_None, 
	.data16	_Opcode__A_Br,    _Opcode__A_IndY,    _Opcode__A_Brw,    _Opcode__A_None, _Opcode__A_None, _Opcode__A_ZpgX, _Opcode__A_ZpgX, _Opcode__A_None, _Opcode__A_Impl, _Opcode__A_AbsY,     _Opcode__A_None, _Opcode__A_None, _Opcode__A_None,  _Opcode__A_AbsX,    _Opcode__A_AbsX, _Opcode__A_None, 
	.data16	_Opcode__A_Jsr,   _Opcode__A_XInd,    _Opcode__A_Jsl,    _Opcode__A_None, _Opcode__A_Zpg,  _Opcode__A_Zpg,  _Opcode__A_Zpg,  _Opcode__A_None, _Opcode__A_Plp,  _Opcode__A_Const,    _Opcode__A_Impl, _Opcode__A_None, _Opcode__A_Abs,   _Opcode__A_Abs,     _Opcode__A_Abs,  _Opcode__A_None, 
	.data16	_Opcode__A_Br,    _Opcode__A_IndY,    _Opcode__A_Brw,    _Opcode__A_None, _Opcode__A_None, _Opcode__A_ZpgX, _Opcode__A_ZpgX, _Opcode__A_None, _Opcode__A_Impl, _Opcode__A_AbsY,     _Opcode__A_None, _Opcode__A_None, _Opcode__A_None,  _Opcode__A_AbsX,    _Opcode__A_AbsX, _Opcode__A_None, 
	.data16	_Opcode__A_Rti,   _Opcode__A_XInd,    _Opcode__A_None,   _Opcode__A_None, _Opcode__A_None, _Opcode__A_Zpg,  _Opcode__A_Zpg,  _Opcode__A_None, _Opcode__A_Pha,  _Opcode__A_Const,    _Opcode__A_Impl, _Opcode__A_None, _Opcode__A_Jmp,   _Opcode__A_Abs,     _Opcode__A_Abs,  _Opcode__A_None, 
	.data16	_Opcode__A_Br,    _Opcode__A_IndY,    _Opcode__A_Brw,    _Opcode__A_None, _Opcode__A_None, _Opcode__A_ZpgX, _Opcode__A_ZpgX, _Opcode__A_None, _Opcode__A_Cli,  _Opcode__A_AbsY,     _Opcode__A_None, _Opcode__A_None, _Opcode__A_None,  _Opcode__A_AbsX,    _Opcode__A_AbsX, _Opcode__A_None, 
	.data16	_Opcode__A_Rts,   _Opcode__A_XInd,    _Opcode__A_RtsNes, _Opcode__A_None, _Opcode__A_None, _Opcode__A_Zpg,  _Opcode__A_Zpg,  _Opcode__A_None, _Opcode__A_Pla,  _Opcode__A_Const,    _Opcode__A_Impl, _Opcode__A_None, _Opcode__A_JmpI,  _Opcode__A_Abs,     _Opcode__A_Abs,  _Opcode__A_None, 
	.data16	_Opcode__A_Br,    _Opcode__A_IndY,    _Opcode__A_Brw,    _Opcode__A_None, _Opcode__A_None, _Opcode__A_ZpgX, _Opcode__A_ZpgX, _Opcode__A_None, _Opcode__A_Sei,  _Opcode__A_AbsY,     _Opcode__A_None, _Opcode__A_None, _Opcode__A_None,  _Opcode__A_AbsX,    _Opcode__A_AbsX, _Opcode__A_None, 
	.data16	_Opcode__A_None,  _Opcode__A_StaXInd, _Opcode__A_None,   _Opcode__A_None, _Opcode__A_Zpg,  _Opcode__A_Zpg,  _Opcode__A_Zpg,  _Opcode__A_None, _Opcode__A_Impl, _Opcode__A_None,     _Opcode__A_Impl, _Opcode__A_None, _Opcode__A_StyA,  _Opcode__A_StaA,    _Opcode__A_StxA, _Opcode__A_None, 
	.data16	_Opcode__A_Br,    _Opcode__A_StaIndY, _Opcode__A_Brw,    _Opcode__A_None, _Opcode__A_ZpgX, _Opcode__A_ZpgX, _Opcode__A_ZpgX, _Opcode__A_None, _Opcode__A_Impl, _Opcode__A_StaAbsY,  _Opcode__A_Txs,  _Opcode__A_None, _Opcode__A_None,  _Opcode__A_StaAbsX, _Opcode__A_None, _Opcode__A_None, 
	.data16	_Opcode__A_Const, _Opcode__A_LdaXInd, _Opcode__A_Const,  _Opcode__A_None, _Opcode__A_Zpg,  _Opcode__A_Zpg,  _Opcode__A_Zpg,  _Opcode__A_None, _Opcode__A_Impl, _Opcode__A_LdaConst, _Opcode__A_Impl, _Opcode__A_None, _Opcode__A_LdyA,  _Opcode__A_LdaA,    _Opcode__A_LdxA, _Opcode__A_None, 
	.data16	_Opcode__A_Br,    _Opcode__A_LdaIndY, _Opcode__A_Brw,    _Opcode__A_None, _Opcode__A_ZpgX, _Opcode__A_ZpgX, _Opcode__A_ZpgX, _Opcode__A_None, _Opcode__A_Impl, _Opcode__A_LdaAbsY,  _Opcode__A_Impl, _Opcode__A_None, _Opcode__A_YAbsX, _Opcode__A_LdaAbsX, _Opcode__A_AbsY, _Opcode__A_None, 
	.data16	_Opcode__A_Const, _Opcode__A_XInd,    _Opcode__A_None,   _Opcode__A_None, _Opcode__A_Zpg,  _Opcode__A_Zpg,  _Opcode__A_Zpg,  _Opcode__A_None, _Opcode__A_Impl, _Opcode__A_Const,    _Opcode__A_Impl, _Opcode__A_None, _Opcode__A_Abs,   _Opcode__A_Abs,     _Opcode__A_Abs,  _Opcode__A_None, 
	.data16	_Opcode__A_Br,    _Opcode__A_IndY,    _Opcode__A_Brw,    _Opcode__A_None, _Opcode__A_None, _Opcode__A_ZpgX, _Opcode__A_ZpgX, _Opcode__A_None, _Opcode__A_Impl, _Opcode__A_AbsY,     _Opcode__A_None, _Opcode__A_None, _Opcode__A_None,  _Opcode__A_AbsX,    _Opcode__A_AbsX, _Opcode__A_None, 
	.data16	_Opcode__A_Const, _Opcode__A_XInd,    _Opcode__A_None,   _Opcode__A_None, _Opcode__A_Zpg,  _Opcode__A_Zpg,  _Opcode__A_Zpg,  _Opcode__A_None, _Opcode__A_Impl, _Opcode__A_Const,    _Opcode__A_Impl, _Opcode__A_None, _Opcode__A_Abs,   _Opcode__A_Abs,     _Opcode__A_Abs,  _Opcode__A_None, 
	.data16	_Opcode__A_Br,    _Opcode__A_IndY,    _Opcode__A_Brw,    _Opcode__A_None, _Opcode__A_None, _Opcode__A_ZpgX, _Opcode__A_ZpgX, _Opcode__A_None, _Opcode__A_Impl, _Opcode__A_AbsY,     _Opcode__A_None, _Opcode__A_None, _Opcode__A_None,  _Opcode__A_AbsX,    _Opcode__A_AbsX, _Opcode__A_None, 
	
	// Instruction type
	.def	Opcode__I____			0x00
	.def	Opcode__I_Adc			0x02
	.def	Opcode__I_And			0x04
	.def	Opcode__I_Asl			0x06
	.def	Opcode__I_Bra			0x08
	.def	Opcode__I_Bit			0x0a
	.def	Opcode__I_Brk			0x0c
	.def	Opcode__I_Clc			0x0e
	.def	Opcode__I_Cld			0x10
	.def	Opcode__I_Cli			0x12
	.def	Opcode__I_Clv			0x14
	.def	Opcode__I_Cmp			0x16
	.def	Opcode__I_Cop			0x18
	.def	Opcode__I_Cpx			0x1a
	.def	Opcode__I_Cpy			0x1c
	.def	Opcode__I_Dec			0x1e
	.def	Opcode__I_Dex			0x20
	.def	Opcode__I_Dey			0x22
	.def	Opcode__I_Eor			0x24
	.def	Opcode__I_Inc			0x26
	.def	Opcode__I_Inx			0x28
	.def	Opcode__I_Iny			0x2a
	.def	Opcode__I_Jmp			0x2c
	.def	Opcode__I_Jsr			0x2e
	.def	Opcode__I_Lda			0x30
	.def	Opcode__I_Ldx			0x32
	.def	Opcode__I_Ldy			0x34
	.def	Opcode__I_Lsr			0x36
	.def	Opcode__I_Nop			0x38
	.def	Opcode__I_Ora			0x3a
	.def	Opcode__I_Pha			0x3c
	.def	Opcode__I_Php			0x3e
	.def	Opcode__I_Pla			0x40
	.def	Opcode__I_Plp			0x42
	.def	Opcode__I_Rol			0x44
	.def	Opcode__I_Ror			0x46
	.def	Opcode__I_Rti			0x48
	.def	Opcode__I_Rts			0x4a
	.def	Opcode__I_Sbc			0x4c
	.def	Opcode__I_Sec			0x4e
	.def	Opcode__I_Sed			0x50
	.def	Opcode__I_Sei			0x52
	.def	Opcode__I_Sta			0x54
	.def	Opcode__I_Stx			0x56
	.def	Opcode__I_Sty			0x58
	.def	Opcode__I_Tax			0x5a
	.def	Opcode__I_Tay			0x5c
	.def	Opcode__I_Tsx			0x5e
	.def	Opcode__I_Txa			0x60
	.def	Opcode__I_Txs			0x62
	.def	Opcode__I_Tya			0x64
	.def	Opcode__I_Wdm			0x66

Opcode__Instruction:
	// UNFINISHED AND UNUSED
	//      0               1               2               3               4               5               6               7               8               9               a               b               c               d               e               f
	//.data16	_Opcode__I_Brk, _Opcode__I_Ora, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I_Bra, _Opcode__I_Ora, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I_Jsr, _Opcode__I_And, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I_Bra, _Opcode__I_And, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I_Rti, _Opcode__I_Eor, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I_Bra, _Opcode__I_Eor, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I_Rts, _Opcode__I_Adc, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I_Bra, _Opcode__I_Adc, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I____, _Opcode__I_Sta, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I_Bra, _Opcode__I_Sta, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I_Ldy, _Opcode__I_Lda, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I_Bra, _Opcode__I_Lda, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I_Cpy, _Opcode__I_Cmp, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I_Bra, _Opcode__I_Cmp, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I_Cpx, _Opcode__I_Sbc, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 
	//.data16	_Opcode__I_Bra, _Opcode__I_Sbc, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, _Opcode__I_, 

	// Recompile types
	// 00 = Error
	// 02 = Regular
	// 04 = Branch
	// 06 = Jmp
	// 08 = Jmp indexed
	// 0a = Jsr
	// 0c = Brk
	// 0e = Return
	// 10 = Cop
	// 12 = Push
	// 14 = Pull
	// 16 = Tsx
	// 18 = Brw

Opcode__RecompileType:
	//      0     1     2     3     4     5     6     7     8     9     a     b     c     d     e     f
	.data16	0x0c, 0x02, 0x10, 0x00, 0x00, 0x02, 0x02, 0x00, 0x12, 0x02, 0x02, 0x00, 0x00, 0x02, 0x02, 0x00
	.data16	0x04, 0x02, 0x18, 0x00, 0x00, 0x02, 0x02, 0x00, 0x02, 0x02, 0x00, 0x00, 0x00, 0x02, 0x02, 0x00
	.data16	0x0a, 0x02, 0x02, 0x00, 0x02, 0x02, 0x02, 0x00, 0x14, 0x02, 0x02, 0x00, 0x02, 0x02, 0x02, 0x00
	.data16	0x04, 0x02, 0x18, 0x00, 0x00, 0x02, 0x02, 0x00, 0x02, 0x02, 0x00, 0x00, 0x00, 0x02, 0x02, 0x00
	.data16	0x0e, 0x02, 0x00, 0x00, 0x00, 0x02, 0x02, 0x00, 0x12, 0x02, 0x02, 0x00, 0x06, 0x02, 0x02, 0x00
	.data16	0x04, 0x02, 0x18, 0x00, 0x00, 0x02, 0x02, 0x00, 0x02, 0x02, 0x00, 0x00, 0x00, 0x02, 0x02, 0x00
	.data16	0x0e, 0x02, 0x0e, 0x00, 0x00, 0x02, 0x02, 0x00, 0x14, 0x02, 0x02, 0x00, 0x08, 0x02, 0x02, 0x00
	.data16	0x04, 0x02, 0x18, 0x00, 0x00, 0x02, 0x02, 0x00, 0x02, 0x02, 0x00, 0x00, 0x00, 0x02, 0x02, 0x00
	.data16	0x00, 0x02, 0x00, 0x00, 0x02, 0x02, 0x02, 0x00, 0x02, 0x00, 0x02, 0x00, 0x02, 0x02, 0x02, 0x00
	.data16	0x04, 0x02, 0x18, 0x00, 0x02, 0x02, 0x02, 0x00, 0x02, 0x02, 0x02, 0x00, 0x00, 0x02, 0x00, 0x00
	.data16	0x02, 0x02, 0x02, 0x00, 0x02, 0x02, 0x02, 0x00, 0x02, 0x02, 0x02, 0x00, 0x02, 0x02, 0x02, 0x00
	.data16	0x04, 0x02, 0x18, 0x00, 0x02, 0x02, 0x02, 0x00, 0x02, 0x02, 0x16, 0x00, 0x02, 0x02, 0x02, 0x00
	.data16	0x02, 0x02, 0x00, 0x00, 0x02, 0x02, 0x02, 0x00, 0x02, 0x02, 0x02, 0x00, 0x02, 0x02, 0x02, 0x00
	.data16	0x04, 0x02, 0x18, 0x00, 0x00, 0x02, 0x02, 0x00, 0x02, 0x02, 0x00, 0x00, 0x00, 0x02, 0x02, 0x00
	.data16	0x02, 0x02, 0x00, 0x00, 0x02, 0x02, 0x02, 0x00, 0x02, 0x02, 0x02, 0x00, 0x02, 0x02, 0x02, 0x00
	.data16	0x04, 0x02, 0x18, 0x00, 0x00, 0x02, 0x02, 0x00, 0x02, 0x02, 0x00, 0x00, 0x00, 0x02, 0x02, 0x00

	// 0=None, 1=X, 2=Y
Opcode__IndexRegister:
	//      0     1     2     3     4     5     6     7     8     9     a     b     c     d     e     f
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x00, 0x00, 0x02, 0x00, 0x00, 0x01, 0x01, 0x02, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.data8	0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00

false
{
Opcode__DivideBy2:
	.data16	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
	.data16	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f
	.data16	0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f
	.data16	0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f
	.data16	0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f
	.data16	0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f
	.data16	0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f
	.data16	0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f
	.data16	0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f
	.data16	0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f
	.data16	0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf
	.data16	0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf
	.data16	0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf
	.data16	0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf
	.data16	0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef
	.data16	0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff
}
	
	.def	Opcode_F_UsePull			0x0001
	.def	Opcode_F_UsePush			0x0002
	.def	Opcode_F_PullReturn			0x0004
	.def	Opcode_F_PushUsedLast		0x0008
	.def	Opcode_F_HasReturn			0x0010
	.def	Opcode_F_IndirectJmp		0x0020
	.def	Opcode_F_IgnoresReturn		0x0040
	.def	Opcode_F_StackDepthError	0x8000

Opcode__BlockFlag:
	.fill	0x200, 0xffff

	.def	Opcode__BlockFlag_BitShift		0x0001

	// This validation macro marks opcodes that can be found in waiting loops.
	// Some exceptions are made to addressing modes while recompiling.
	.macro	Opcode__BlockFlag_SetMac		index, value, comment
		.pushaddr
		.addr	Opcode__BlockFlag+{0}*2
		.data16	{1}
		.pulladdr
	.endm
	.macro	Opcode__BlockFlag_ValidateMac	index, comment
		Opcode__BlockFlag_SetMac	{0}, 0x0000
	.endm
	
	Opcode__BlockFlag_ValidateMac	0xa9, "lda #const"
	Opcode__BlockFlag_ValidateMac	0xa2, "ldx #const"
	Opcode__BlockFlag_ValidateMac	0xa0, "ldy #const"
	Opcode__BlockFlag_ValidateMac	0x45, "eor dp"
	Opcode__BlockFlag_ValidateMac	0x4d, "eor addr"
	Opcode__BlockFlag_ValidateMac	0xa5, "lda dp"
	Opcode__BlockFlag_ValidateMac	0xa6, "ldx dp"
	Opcode__BlockFlag_ValidateMac	0xa4, "ldy dp"
	Opcode__BlockFlag_ValidateMac	0xa5, "lda addr"
	Opcode__BlockFlag_ValidateMac	0xa6, "ldx addr"
	Opcode__BlockFlag_ValidateMac	0xa4, "ldy addr"
	Opcode__BlockFlag_ValidateMac	0xc5, "cmp dp"
	Opcode__BlockFlag_ValidateMac	0xe4, "cpx dp"
	Opcode__BlockFlag_ValidateMac	0xc4, "cpy dp"

	// Bit shift wait loop exception
	Opcode__BlockFlag_SetMac		0x06, Opcode__BlockFlag_BitShift, "asl dp"
	Opcode__BlockFlag_SetMac		0x0e, Opcode__BlockFlag_BitShift, "asl addr"
	Opcode__BlockFlag_SetMac		0x46, Opcode__BlockFlag_BitShift, "lsr dp"
	Opcode__BlockFlag_SetMac		0x4e, Opcode__BlockFlag_BitShift, "lsr addr"
