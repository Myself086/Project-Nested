using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Project_Nested.Emulation
{
    partial class c65816
    {
        public Memory memory = new Memory();

        Int32 r_A, r_AA;     // AA is used to preserve the higher bits of A during 8-bit mode
        Int32 r_X;
        Int32 r_Y;
        Int32 r_S;
        Int32 r_PC;          // Real value not stored completely, mask 0xff0000 will be correct
        Int32 r_ePC;         // ePC is an emulator short-cut for PC
        Int32 r_PCtiming;    // Timing of the current memory of PC
        Int32 r_DP;          // Direct Page
        Int32 r_DB;          // Data Bank
        Int32 r_DBstart;     // Data Bank at sub-routine start
        Int32 r_FLAGS;       // Different mapping than the real CPU
        Int32 r_FLAGSstart;  // Flags at sub-routine start
        // Bits in r_FLAGS: #CNV_ZZZZ-ZZZZ_ZZZZ ZZZZ_ZZMX-WIDE_PR##
        // M and X are locked for opcode settings shortcut

        // Interrupt vectors
        public Int32 VECTOR_COP_65816 = 0xffe4;
        public Int32 VECTOR_BRK_65816 = 0xffe6;
        public Int32 VECTOR_NMI_65816 = 0xffea;
        public Int32 VECTOR_IRQ_65816 = 0xffee;
        public Int32 VECTOR_COP_6502 = 0xfff4;
        public Int32 VECTOR_BRK_6502 = 0xfffe;
        public Int32 VECTOR_NMI_6502 = 0xfffa;
        public Int32 VECTOR_IRQ_6502 = 0xfffe;
        public Int32 VECTOR_RESET = 0xfffc;
        public Int32 VECTOR_UNUSED_RESET = 0xffec;

        delegate Int32 DelAddrmode();
        delegate void DelOpcode(Int32 i);

        struct InstructionSet
        {
            public DelOpcode CallOpcode;
            public DelAddrmode CallAddrmode;
            public Int16 OpcodeFlags;       // Describes behaviors of this opcode, see OPF below
        }
        const Int16 OPF_MASK_PCCHANGE = 0xf;
        const Int16 OPF_PC_BRANCH = 0x2;
        const Int16 OPF_PC_JUMP = 0x4;
        const Int16 OPF_PC_RETURN = 0x8;
        const Int16 OPF_MX_CHANGE = 0x10;
        const Int16 OPF_MFLAG_PCREADTWO = 0x20;         // Read one more byte from PC when m=0
        const Int16 OPF_XFLAG_PCREADTWO = 0x40;         // Read one more byte from PC when x=0
        const Int16 OPF_STACK = 0x100;
        const Int16 OPF_STACKTRACE = 0x200;

        InstructionSet[] Opcode = new InstructionSet[0x400];

        public c65816()
        {
            Init();
        }

        public c65816(byte[] rom, byte[] sram)
        {
            memory.WriteROM(rom);
            memory.ResetRam(Memory.RomSize.ExHiROM);
            memory.WriteSRAM(sram);
            Init();
        }

        private void Init()
        {
            // ADC
            DefCode(0x61, addr__dp_x, op___ADC, op__mADC, op___ADC, op__mADC, 0);
            DefCode(0x63, addr_sr, op___ADC, op__mADC, op___ADC, op__mADC, 0);
            DefCode(0x65, addr_dp, op___ADC, op__mADC, op___ADC, op__mADC, 0);
            DefCode(0x67, addr___dp, op___ADC, op__mADC, op___ADC, op__mADC, 0);
            DefCode(0x69, addr_const_one, op___ADC, op__mADC, op___ADC, op__mADC, OPF_MFLAG_PCREADTWO);
            DefCode(0x6D, addr_addr, op___ADC, op__mADC, op___ADC, op__mADC, 0);
            DefCode(0x6F, addr_long, op___ADC, op__mADC, op___ADC, op__mADC, 0);
            DefCode(0x71, addr__dp_y, op___ADC, op__mADC, op___ADC, op__mADC, 0);
            DefCode(0x72, addr__dp, op___ADC, op__mADC, op___ADC, op__mADC, 0);
            DefCode(0x73, addr__sr_y, op___ADC, op__mADC, op___ADC, op__mADC, 0);
            DefCode(0x75, addr_dp_x, op___ADC, op__mADC, op___ADC, op__mADC, 0);
            DefCode(0x77, addr___dp_y, op___ADC, op__mADC, op___ADC, op__mADC, 0);
            DefCode(0x79, addr_addr_y, op___ADC, op__mADC, op___ADC, op__mADC, 0);
            DefCode(0x7D, addr_addr_x, op___ADC, op__mADC, op___ADC, op__mADC, 0);
            DefCode(0x7F, addr_long_x, op___ADC, op__mADC, op___ADC, op__mADC, 0);
            // AND
            DefCode(0x21, addr__dp_x, op___AND, op__mAND, op___AND, op__mAND, 0);
            DefCode(0x23, addr_sr, op___AND, op__mAND, op___AND, op__mAND, 0);
            DefCode(0x25, addr_dp, op___AND, op__mAND, op___AND, op__mAND, 0);
            DefCode(0x27, addr___dp, op___AND, op__mAND, op___AND, op__mAND, 0);
            DefCode(0x29, addr_const_one, op___AND, op__mAND, op___AND, op__mAND, OPF_MFLAG_PCREADTWO);
            DefCode(0x2D, addr_addr, op___AND, op__mAND, op___AND, op__mAND, 0);
            DefCode(0x2F, addr_long, op___AND, op__mAND, op___AND, op__mAND, 0);
            DefCode(0x31, addr__dp_y, op___AND, op__mAND, op___AND, op__mAND, 0);
            DefCode(0x32, addr__dp, op___AND, op__mAND, op___AND, op__mAND, 0);
            DefCode(0x33, addr__sr_y, op___AND, op__mAND, op___AND, op__mAND, 0);
            DefCode(0x35, addr_dp_x, op___AND, op__mAND, op___AND, op__mAND, 0);
            DefCode(0x37, addr___dp_y, op___AND, op__mAND, op___AND, op__mAND, 0);
            DefCode(0x39, addr_addr_y, op___AND, op__mAND, op___AND, op__mAND, 0);
            DefCode(0x3D, addr_addr_x, op___AND, op__mAND, op___AND, op__mAND, 0);
            DefCode(0x3F, addr_long_x, op___AND, op__mAND, op___AND, op__mAND, 0);
            // ASL
            DefCode(0x06, addr_dp, op___ASL, op__mASL, op___ASL, op__mASL, 0);
            DefCode(0x0A, addr_internal_1, op___SLA, op__mSLA, op___SLA, op__mSLA, 0);
            DefCode(0x0E, addr_addr, op___ASL, op__mASL, op___ASL, op__mASL, 0);
            DefCode(0x16, addr_dp_x, op___ASL, op__mASL, op___ASL, op__mASL, 0);
            DefCode(0x1E, addr_addr_x, op___ASL, op__mASL, op___ASL, op__mASL, 0);
            // BCC
            DefCode(0x90, addr_const_one, op___BCC, op___BCC, op___BCC, op___BCC, OPF_PC_BRANCH);
            // BCS
            DefCode(0xB0, addr_const_one, op___BCS, op___BCS, op___BCS, op___BCS, OPF_PC_BRANCH);
            // BEQ
            DefCode(0xF0, addr_const_one, op___BEQ, op___BEQ, op___BEQ, op___BEQ, OPF_PC_BRANCH);
            // BIT
            DefCode(0x24, addr_dp, op___BIT, op__mBIT, op___BIT, op__mBIT, 0);
            DefCode(0x2C, addr_addr, op___BIT, op__mBIT, op___BIT, op__mBIT, 0);
            DefCode(0x34, addr_dp_x, op___BIT, op__mBIT, op___BIT, op__mBIT, 0);
            DefCode(0x3C, addr_addr_x, op___BIT, op__mBIT, op___BIT, op__mBIT, 0);
            DefCode(0x89, addr_const_one, op___BII, op__mBII, op___BII, op__mBII, OPF_MFLAG_PCREADTWO);
            // BMI
            DefCode(0x30, addr_const_one, op___BMI, op___BMI, op___BMI, op___BMI, OPF_PC_BRANCH);
            // BNE
            DefCode(0xD0, addr_const_one, op___BNE, op___BNE, op___BNE, op___BNE, OPF_PC_BRANCH);
            // BPL
            DefCode(0x10, addr_const_one, op___BPL, op___BPL, op___BPL, op___BPL, OPF_PC_BRANCH);
            // BRA
            DefCode(0x80, addr_const_one, op___BRA, op___BRA, op___BRA, op___BRA, OPF_PC_BRANCH);
            // BRK
            DefCode(0x00, addr_const_one, op___BRK, op___BRK, op___BRK, op___BRK, OPF_PC_JUMP);
            // BRL
            DefCode(0x82, addr_const_two, op___BRL, op___BRL, op___BRL, op___BRL, OPF_PC_BRANCH);
            // BVC
            DefCode(0x50, addr_const_one, op___BVC, op___BVC, op___BVC, op___BVC, OPF_PC_BRANCH);
            // BVS
            DefCode(0x70, addr_const_one, op___BVS, op___BVS, op___BVS, op___BVS, OPF_PC_BRANCH);
            // CLC
            DefCode(0x18, addr_internal_1, op___CLC, op___CLC, op___CLC, op___CLC, 0);
            // CLD
            DefCode(0xD8, addr_internal_1, op___CLD, op___CLD, op___CLD, op___CLD, 0);
            // CLI
            DefCode(0x58, addr_internal_1, op___CLI, op___CLI, op___CLI, op___CLI, 0);
            // CLV
            DefCode(0xB8, addr_internal_1, op___CLV, op___CLV, op___CLV, op___CLV, 0);
            // CMP
            DefCode(0xC1, addr__dp_x, op___CMP, op__mCMP, op___CMP, op__mCMP, 0);
            DefCode(0xC3, addr_sr, op___CMP, op__mCMP, op___CMP, op__mCMP, 0);
            DefCode(0xC5, addr_dp, op___CMP, op__mCMP, op___CMP, op__mCMP, 0);
            DefCode(0xC7, addr___dp, op___CMP, op__mCMP, op___CMP, op__mCMP, 0);
            DefCode(0xC9, addr_const_one, op___CMP, op__mCMP, op___CMP, op__mCMP, OPF_MFLAG_PCREADTWO);
            DefCode(0xCD, addr_addr, op___CMP, op__mCMP, op___CMP, op__mCMP, 0);
            DefCode(0xCF, addr_long, op___CMP, op__mCMP, op___CMP, op__mCMP, 0);
            DefCode(0xD1, addr__dp_y, op___CMP, op__mCMP, op___CMP, op__mCMP, 0);
            DefCode(0xD2, addr__dp, op___CMP, op__mCMP, op___CMP, op__mCMP, 0);
            DefCode(0xD3, addr__sr_y, op___CMP, op__mCMP, op___CMP, op__mCMP, 0);
            DefCode(0xD5, addr_dp_x, op___CMP, op__mCMP, op___CMP, op__mCMP, 0);
            DefCode(0xD7, addr___dp_y, op___CMP, op__mCMP, op___CMP, op__mCMP, 0);
            DefCode(0xD9, addr_addr_y, op___CMP, op__mCMP, op___CMP, op__mCMP, 0);
            DefCode(0xDD, addr_addr_x, op___CMP, op__mCMP, op___CMP, op__mCMP, 0);
            DefCode(0xDF, addr_long_x, op___CMP, op__mCMP, op___CMP, op__mCMP, 0);
            // COP
            DefCode(0x02, addr_const_one, op___COP, op___COP, op___COP, op___COP, OPF_PC_JUMP);
            // CPX
            DefCode(0xE0, addr_const_one, op___CPX, op___CPX, op__xCPX, op__xCPX, OPF_XFLAG_PCREADTWO);
            DefCode(0xE4, addr_dp, op___CPX, op___CPX, op__xCPX, op__xCPX, 0);
            DefCode(0xEC, addr_addr, op___CPX, op___CPX, op__xCPX, op__xCPX, 0);
            // CPY
            DefCode(0xC0, addr_const_one, op___CPY, op___CPY, op__xCPY, op__xCPY, OPF_XFLAG_PCREADTWO);
            DefCode(0xC4, addr_dp, op___CPY, op___CPY, op__xCPY, op__xCPY, 0);
            DefCode(0xCC, addr_addr, op___CPY, op___CPY, op__xCPY, op__xCPY, 0);
            // DEC
            DefCode(0x3A, addr_internal_1, op___DEC, op__mDEC, op___DEC, op__mDEC, 0);
            DefCode(0xC6, addr_dp, op___DEM, op__mDEM, op___DEM, op__mDEM, 0);
            DefCode(0xCE, addr_addr, op___DEM, op__mDEM, op___DEM, op__mDEM, 0);
            DefCode(0xD6, addr_dp_x, op___DEM, op__mDEM, op___DEM, op__mDEM, 0);
            DefCode(0xDE, addr_addr_x, op___DEM, op__mDEM, op___DEM, op__mDEM, 0);
            // DEX
            DefCode(0xCA, addr_internal_1, op___DEX, op___DEX, op__xDEX, op__xDEX, 0);
            // DEY
            DefCode(0x88, addr_internal_1, op___DEY, op___DEY, op__xDEY, op__xDEY, 0);
            // EOR
            DefCode(0x41, addr__dp_x, op___EOR, op__mEOR, op___EOR, op__mEOR, 0);
            DefCode(0x43, addr_sr, op___EOR, op__mEOR, op___EOR, op__mEOR, 0);
            DefCode(0x45, addr_dp, op___EOR, op__mEOR, op___EOR, op__mEOR, 0);
            DefCode(0x47, addr___dp, op___EOR, op__mEOR, op___EOR, op__mEOR, 0);
            DefCode(0x49, addr_const_one, op___EOR, op__mEOR, op___EOR, op__mEOR, OPF_MFLAG_PCREADTWO);
            DefCode(0x4D, addr_addr, op___EOR, op__mEOR, op___EOR, op__mEOR, 0);
            DefCode(0x4F, addr_long, op___EOR, op__mEOR, op___EOR, op__mEOR, 0);
            DefCode(0x51, addr__dp_y, op___EOR, op__mEOR, op___EOR, op__mEOR, 0);
            DefCode(0x52, addr__dp, op___EOR, op__mEOR, op___EOR, op__mEOR, 0);
            DefCode(0x53, addr__sr_y, op___EOR, op__mEOR, op___EOR, op__mEOR, 0);
            DefCode(0x55, addr_dp_x, op___EOR, op__mEOR, op___EOR, op__mEOR, 0);
            DefCode(0x57, addr___dp_y, op___EOR, op__mEOR, op___EOR, op__mEOR, 0);
            DefCode(0x59, addr_addr_y, op___EOR, op__mEOR, op___EOR, op__mEOR, 0);
            DefCode(0x5D, addr_addr_x, op___EOR, op__mEOR, op___EOR, op__mEOR, 0);
            DefCode(0x5F, addr_long_x, op___EOR, op__mEOR, op___EOR, op__mEOR, 0);
            // INC
            DefCode(0x1A, addr_internal_1, op___INC, op__mINC, op___INC, op__mINC, 0);
            DefCode(0xE6, addr_dp, op___INM, op__mINM, op___INM, op__mINM, 0);
            DefCode(0xEE, addr_addr, op___INM, op__mINM, op___INM, op__mINM, 0);
            DefCode(0xF6, addr_dp_x, op___INM, op__mINM, op___INM, op__mINM, 0);
            DefCode(0xFE, addr_addr_x, op___INM, op__mINM, op___INM, op__mINM, 0);
            // INX
            DefCode(0xE8, addr_internal_1, op___INX, op___INX, op__xINX, op__xINX, 0);
            // INY
            DefCode(0xC8, addr_internal_1, op___INY, op___INY, op__xINY, op__xINY, 0);
            // JMP
            DefCode(0x4C, addr_const_two, op__bJMP, op__bJMP, op__bJMP, op__bJMP, OPF_PC_JUMP);
            DefCode(0x5C, addr_const_three, op___JML, op___JML, op___JML, op___JML, OPF_PC_JUMP);
            DefCode(0x6C, addr_addr_j, op___JMP, op___JMP, op___JMP, op___JMP, OPF_PC_JUMP);
            DefCode(0x7C, addr_addr_x_j, op___JMP, op___JMP, op___JMP, op___JMP, OPF_PC_JUMP);
            DefCode(0xDC, addr_addr_j, op___JMLI, op___JMLI, op___JMLI, op___JMLI, OPF_PC_JUMP);
            // JSR
            DefCode(0x20, addr_const_two, op___JSR, op___JSR, op___JSR, op___JSR, OPF_PC_JUMP);
            DefCode(0x22, addr_const_three, op___JSL, op___JSL, op___JSL, op___JSL, OPF_PC_JUMP);
            DefCode(0xFC, addr_addr_x_j, op___JSR, op___JSR, op___JSR, op___JSR, OPF_PC_JUMP);
            // LDA
            DefCode(0xA1, addr__dp_x, op___LDA, op__mLDA, op___LDA, op__mLDA, 0);
            DefCode(0xA3, addr_sr, op___LDA, op__mLDA, op___LDA, op__mLDA, 0);
            DefCode(0xA5, addr_dp, op___LDA, op__mLDA, op___LDA, op__mLDA, 0);
            DefCode(0xA7, addr___dp, op___LDA, op__mLDA, op___LDA, op__mLDA, 0);
            DefCode(0xA9, addr_const_one, op___LDA, op__mLDA, op___LDA, op__mLDA, OPF_MFLAG_PCREADTWO);
            DefCode(0xAD, addr_addr, op___LDA, op__mLDA, op___LDA, op__mLDA, 0);
            DefCode(0xAF, addr_long, op___LDA, op__mLDA, op___LDA, op__mLDA, 0);
            DefCode(0xB1, addr__dp_y, op___LDA, op__mLDA, op___LDA, op__mLDA, 0);
            DefCode(0xB2, addr__dp, op___LDA, op__mLDA, op___LDA, op__mLDA, 0);
            DefCode(0xB3, addr__sr_y, op___LDA, op__mLDA, op___LDA, op__mLDA, 0);
            DefCode(0xB5, addr_dp_x, op___LDA, op__mLDA, op___LDA, op__mLDA, 0);
            DefCode(0xB7, addr___dp_y, op___LDA, op__mLDA, op___LDA, op__mLDA, 0);
            DefCode(0xB9, addr_addr_y, op___LDA, op__mLDA, op___LDA, op__mLDA, 0);
            DefCode(0xBD, addr_addr_x, op___LDA, op__mLDA, op___LDA, op__mLDA, 0);
            DefCode(0xBF, addr_long_x, op___LDA, op__mLDA, op___LDA, op__mLDA, 0);
            // LDX
            DefCode(0xA2, addr_const_one, op___LDX, op___LDX, op__xLDX, op__xLDX, OPF_XFLAG_PCREADTWO);
            DefCode(0xA6, addr_dp, op___LDX, op___LDX, op__xLDX, op__xLDX, 0);
            DefCode(0xAE, addr_addr, op___LDX, op___LDX, op__xLDX, op__xLDX, 0);
            DefCode(0xB6, addr_dp_y, op___LDX, op___LDX, op__xLDX, op__xLDX, 0);
            DefCode(0xBE, addr_addr_y, op___LDX, op___LDX, op__xLDX, op__xLDX, 0);
            // LDY
            DefCode(0xA0, addr_const_one, op___LDY, op___LDY, op__xLDY, op__xLDY, OPF_XFLAG_PCREADTWO);
            DefCode(0xA4, addr_dp, op___LDY, op___LDY, op__xLDY, op__xLDY, 0);
            DefCode(0xAC, addr_addr, op___LDY, op___LDY, op__xLDY, op__xLDY, 0);
            DefCode(0xB4, addr_dp_x, op___LDY, op___LDY, op__xLDY, op__xLDY, 0);
            DefCode(0xBC, addr_addr_x, op___LDY, op___LDY, op__xLDY, op__xLDY, 0);
            // LSR
            DefCode(0x46, addr_dp, op___LSR, op__mLSR, op___LSR, op__mLSR, 0);
            DefCode(0x4A, addr_internal_1, op___SRA, op__mSRA, op___SRA, op__mSRA, 0);
            DefCode(0x4E, addr_addr, op___LSR, op__mLSR, op___LSR, op__mLSR, 0);
            DefCode(0x56, addr_dp_x, op___LSR, op__mLSR, op___LSR, op__mLSR, 0);
            DefCode(0x5E, addr_addr_x, op___LSR, op__mLSR, op___LSR, op__mLSR, 0);
            // MVN
            DefCode(0x54, addr_const_two, op___MVN, op___MVN, op___MVN, op___MVN, 0);
            // MVP
            DefCode(0x44, addr_const_two, op___MVP, op___MVP, op___MVP, op___MVP, 0);
            // NOP
            DefCode(0xEA, addr_internal_1, op___NOP, op___NOP, op___NOP, op___NOP, 0);
            // ORA
            DefCode(0x01, addr__dp_x, op___ORA, op__mORA, op___ORA, op__mORA, 0);
            DefCode(0x03, addr_sr, op___ORA, op__mORA, op___ORA, op__mORA, 0);
            DefCode(0x05, addr_dp, op___ORA, op__mORA, op___ORA, op__mORA, 0);
            DefCode(0x07, addr___dp, op___ORA, op__mORA, op___ORA, op__mORA, 0);
            DefCode(0x09, addr_const_one, op___ORA, op__mORA, op___ORA, op__mORA, OPF_MFLAG_PCREADTWO);
            DefCode(0x0D, addr_addr, op___ORA, op__mORA, op___ORA, op__mORA, 0);
            DefCode(0x0F, addr_long, op___ORA, op__mORA, op___ORA, op__mORA, 0);
            DefCode(0x11, addr__dp_y, op___ORA, op__mORA, op___ORA, op__mORA, 0);
            DefCode(0x12, addr__dp, op___ORA, op__mORA, op___ORA, op__mORA, 0);
            DefCode(0x13, addr__sr_y, op___ORA, op__mORA, op___ORA, op__mORA, 0);
            DefCode(0x15, addr_dp_x, op___ORA, op__mORA, op___ORA, op__mORA, 0);
            DefCode(0x17, addr___dp_y, op___ORA, op__mORA, op___ORA, op__mORA, 0);
            DefCode(0x19, addr_addr_y, op___ORA, op__mORA, op___ORA, op__mORA, 0);
            DefCode(0x1D, addr_addr_x, op___ORA, op__mORA, op___ORA, op__mORA, 0);
            DefCode(0x1F, addr_long_x, op___ORA, op__mORA, op___ORA, op__mORA, 0);
            // PEA
            DefCode(0xF4, addr_const_two, op___PEA, op___PEA, op___PEA, op___PEA, 0);
            // PEI
            DefCode(0xD4, addr_dp, op___PEI, op___PEI, op___PEI, op___PEI, 0);
            // PER
            DefCode(0x62, addr_const_two, op___PER, op___PER, op___PER, op___PER, 0);
            // PHA
            DefCode(0x48, addr_internal_1, op___PHA, op__mPHA, op___PHA, op__mPHA, 0);
            // PHB
            DefCode(0x8B, addr_internal_1, op___PHB, op___PHB, op___PHB, op___PHB, 0);
            // PHD
            DefCode(0x0B, addr_internal_1, op___PHD, op___PHD, op___PHD, op___PHD, 0);
            // PHK
            DefCode(0x4B, addr_internal_1, op___PHK, op___PHK, op___PHK, op___PHK, 0);
            // PHP
            DefCode(0x08, addr_internal_1, op___PHP, op___PHP, op___PHP, op___PHP, 0);
            // PHX
            DefCode(0xDA, addr_internal_1, op___PHX, op___PHX, op__xPHX, op__xPHX, 0);
            // PHY
            DefCode(0x5A, addr_internal_1, op___PHY, op___PHY, op__xPHY, op__xPHY, 0);
            // PLA
            DefCode(0x68, addr_internal_2, op___PLA, op__mPLA, op___PLA, op__mPLA, 0);
            // PLB
            DefCode(0xAB, addr_internal_2, op___PLB, op___PLB, op___PLB, op___PLB, 0);
            // PLD
            DefCode(0x2B, addr_internal_2, op___PLD, op___PLD, op___PLD, op___PLD, 0);
            // PLP
            DefCode(0x28, addr_internal_2, op___PLP, op___PLP, op___PLP, op___PLP, OPF_MX_CHANGE);
            // PLX
            DefCode(0xFA, addr_internal_2, op___PLX, op___PLX, op__xPLX, op__xPLX, 0);
            // PLY
            DefCode(0x7A, addr_internal_2, op___PLY, op___PLY, op__xPLY, op__xPLY, 0);
            // REP
            DefCode(0xC2, addr_const_one, op___REP, op___REP, op___REP, op___REP, OPF_MX_CHANGE);
            // ROL
            DefCode(0x26, addr_dp, op___ROL, op__mROL, op___ROL, op__mROL, 0);
            DefCode(0x2A, addr_internal_1, op___RLA, op__mRLA, op___RLA, op__mRLA, 0);
            DefCode(0x2E, addr_addr, op___ROL, op__mROL, op___ROL, op__mROL, 0);
            DefCode(0x36, addr_dp_x, op___ROL, op__mROL, op___ROL, op__mROL, 0);
            DefCode(0x3E, addr_addr_x, op___ROL, op__mROL, op___ROL, op__mROL, 0);
            // ROR
            DefCode(0x66, addr_dp, op___ROR, op__mROR, op___ROR, op__mROR, 0);
            DefCode(0x6A, addr_internal_1, op___RRA, op__mRRA, op___RRA, op__mRRA, 0);
            DefCode(0x6E, addr_addr, op___ROR, op__mROR, op___ROR, op__mROR, 0);
            DefCode(0x76, addr_dp_x, op___ROR, op__mROR, op___ROR, op__mROR, 0);
            DefCode(0x7E, addr_addr_x, op___ROR, op__mROR, op___ROR, op__mROR, 0);
            // RTI
            DefCode(0x40, addr_internal_2, op___RTI, op___RTI, op___RTI, op___RTI, OPF_PC_RETURN);
            // RTL
            DefCode(0x6B, addr_internal_2, op___RTL, op___RTL, op___RTL, op___RTL, OPF_PC_RETURN);
            // RTS
            DefCode(0x60, addr_internal_2, op___RTS, op___RTS, op___RTS, op___RTS, OPF_PC_RETURN);
            // SBC
            DefCode(0xE1, addr__dp_x, op___SBC, op__mSBC, op___SBC, op__mSBC, 0);
            DefCode(0xE3, addr_sr, op___SBC, op__mSBC, op___SBC, op__mSBC, 0);
            DefCode(0xE5, addr_dp, op___SBC, op__mSBC, op___SBC, op__mSBC, 0);
            DefCode(0xE7, addr___dp, op___SBC, op__mSBC, op___SBC, op__mSBC, 0);
            DefCode(0xE9, addr_const_one, op___SBC, op__mSBC, op___SBC, op__mSBC, OPF_MFLAG_PCREADTWO);
            DefCode(0xED, addr_addr, op___SBC, op__mSBC, op___SBC, op__mSBC, 0);
            DefCode(0xEF, addr_long, op___SBC, op__mSBC, op___SBC, op__mSBC, 0);
            DefCode(0xF1, addr__dp_y, op___SBC, op__mSBC, op___SBC, op__mSBC, 0);
            DefCode(0xF2, addr__dp, op___SBC, op__mSBC, op___SBC, op__mSBC, 0);
            DefCode(0xF3, addr__sr_y, op___SBC, op__mSBC, op___SBC, op__mSBC, 0);
            DefCode(0xF5, addr_dp_x, op___SBC, op__mSBC, op___SBC, op__mSBC, 0);
            DefCode(0xF7, addr___dp_y, op___SBC, op__mSBC, op___SBC, op__mSBC, 0);
            DefCode(0xF9, addr_addr_y, op___SBC, op__mSBC, op___SBC, op__mSBC, 0);
            DefCode(0xFD, addr_addr_x, op___SBC, op__mSBC, op___SBC, op__mSBC, 0);
            DefCode(0xFF, addr_long_x, op___SBC, op__mSBC, op___SBC, op__mSBC, 0);
            // SEC
            DefCode(0x38, addr_internal_1, op___SEC, op___SEC, op___SEC, op___SEC, 0);
            // SED
            DefCode(0xF8, addr_internal_1, op___SED, op___SED, op___SED, op___SED, 0);
            // SEI
            DefCode(0x78, addr_internal_1, op___SEI, op___SEI, op___SEI, op___SEI, 0);
            // SEP
            DefCode(0xE2, addr_const_one, op___SEP, op___SEP, op___SEP, op___SEP, OPF_MX_CHANGE);
            // STA
            DefCode(0x81, addr__dp_x, op___STA, op__mSTA, op___STA, op__mSTA, 0);
            DefCode(0x83, addr_sr, op___STA, op__mSTA, op___STA, op__mSTA, 0);
            DefCode(0x85, addr_dp, op___STA, op__mSTA, op___STA, op__mSTA, 0);
            DefCode(0x87, addr___dp, op___STA, op__mSTA, op___STA, op__mSTA, 0);
            DefCode(0x8D, addr_addr, op___STA, op__mSTA, op___STA, op__mSTA, 0);
            DefCode(0x8F, addr_long, op___STA, op__mSTA, op___STA, op__mSTA, 0);
            DefCode(0x91, addr__dp_y, op___STA, op__mSTA, op___STA, op__mSTA, 0);
            DefCode(0x92, addr__dp, op___STA, op__mSTA, op___STA, op__mSTA, 0);
            DefCode(0x93, addr__sr_y, op___STA, op__mSTA, op___STA, op__mSTA, 0);
            DefCode(0x95, addr_dp_x, op___STA, op__mSTA, op___STA, op__mSTA, 0);
            DefCode(0x97, addr___dp_y, op___STA, op__mSTA, op___STA, op__mSTA, 0);
            DefCode(0x99, addr_addr_y, op___STA, op__mSTA, op___STA, op__mSTA, 0);
            DefCode(0x9D, addr_addr_x, op___STA, op__mSTA, op___STA, op__mSTA, 0);
            DefCode(0x9F, addr_long_x, op___STA, op__mSTA, op___STA, op__mSTA, 0);
            // STP
            DefCode(0xDB, addr_internal_2, op___STP, op___STP, op___STP, op___STP, 0);
            // STX
            DefCode(0x86, addr_dp, op___STX, op___STX, op__xSTX, op__xSTX, 0);
            DefCode(0x8E, addr_addr, op___STX, op___STX, op__xSTX, op__xSTX, 0);
            DefCode(0x96, addr_dp_y, op___STX, op___STX, op__xSTX, op__xSTX, 0);
            // STY
            DefCode(0x84, addr_dp, op___STY, op___STY, op__xSTY, op__xSTY, 0);
            DefCode(0x8C, addr_addr, op___STY, op___STY, op__xSTY, op__xSTY, 0);
            DefCode(0x94, addr_dp_x, op___STY, op___STY, op__xSTY, op__xSTY, 0);
            // STZ
            DefCode(0x64, addr_dp, op___STZ, op__mSTZ, op___STZ, op__mSTZ, 0);
            DefCode(0x74, addr_dp_x, op___STZ, op__mSTZ, op___STZ, op__mSTZ, 0);
            DefCode(0x9C, addr_addr, op___STZ, op__mSTZ, op___STZ, op__mSTZ, 0);
            DefCode(0x9E, addr_addr_x, op___STZ, op__mSTZ, op___STZ, op__mSTZ, 0);
            // TAX
            DefCode(0xAA, addr_internal_1, op___TAX, op___TAX, op__xTAX, op__xTAX, 0);
            // TAY
            DefCode(0xA8, addr_internal_1, op___TAY, op___TAY, op__xTAY, op__xTAY, 0);
            // TCD
            DefCode(0x5B, addr_internal_1, op___TCD, op__mTCD, op___TCD, op__mTCD, 0);
            // TCS
            DefCode(0x1B, addr_internal_1, op___TCS, op__mTCS, op___TCS, op__mTCS, 0);
            // TDC
            DefCode(0x7B, addr_internal_1, op___TDC, op__mTDC, op___TDC, op__mTDC, 0);
            // TRB
            DefCode(0x14, addr_dp, op___TRB, op__mTRB, op___TRB, op__mTRB, 0);
            DefCode(0x1C, addr_addr, op___TRB, op__mTRB, op___TRB, op__mTRB, 0);
            // TSB
            DefCode(0x04, addr_dp, op___TSB, op__mTSB, op___TSB, op__mTSB, 0);
            DefCode(0x0C, addr_addr, op___TSB, op__mTSB, op___TSB, op__mTSB, 0);
            // TSC
            DefCode(0x3B, addr_internal_1, op___TSC, op__mTSC, op___TSC, op__mTSC, 0);
            // TSX
            DefCode(0xBA, addr_internal_1, op___TSX, op___TSX, op__xTSX, op__xTSX, 0);
            // TXA
            DefCode(0x8A, addr_internal_1, op___TXA, op__mTXA, op___TXA, op__mTXA, 0);
            // TXS
            DefCode(0x9A, addr_internal_1, op___TXS, op___TXS, op__xTXS, op__xTXS, 0);
            // TXY
            DefCode(0x9B, addr_internal_1, op___TXY, op___TXY, op__xTXY, op__xTXY, 0);
            // TYA
            DefCode(0x98, addr_internal_1, op___TYA, op__mTYA, op___TYA, op__mTYA, 0);
            // TYX
            DefCode(0xBB, addr_internal_1, op___TYX, op___TYX, op__xTYX, op__xTYX, 0);
            // WAI
            DefCode(0xCB, addr_internal_2, op___WAI, op___WAI, op___WAI, op___WAI, 0);
            // WDM
            DefCode(0x42, addr_const_one, op___WDM, op___WDM, op___WDM, op___WDM, 0);
            // XBA
            DefCode(0xEB, addr_internal_2, op___XBA, op__mXBA, op___XBA, op__mXBA, 0);
            // XCE
            DefCode(0xFB, addr_internal_1, op___XCE, op___XCE, op___XCE, op___XCE, 0);
        }

        void DefCode(byte opnum, DelAddrmode addrmode, DelOpcode op_, DelOpcode op_m, DelOpcode op_x, DelOpcode op_mx, Int16 flags)
        {
            for (Int16 i = 0; i <= 0x300; i += 0x100)
            {
                Opcode[opnum + i].OpcodeFlags = flags;
                Opcode[opnum + i].CallAddrmode = addrmode;
            }
            if ((flags & OPF_MFLAG_PCREADTWO) != 0)
            {
                Opcode[opnum + 0x000].CallAddrmode = addr_const_two;
                Opcode[opnum + 0x100].CallAddrmode = addr_const_two;
            }
            if ((flags & OPF_XFLAG_PCREADTWO) != 0)
            {
                Opcode[opnum + 0x000].CallAddrmode = addr_const_two;
                Opcode[opnum + 0x200].CallAddrmode = addr_const_two;
            }
            Opcode[opnum + 0x000].CallOpcode = op_;
            Opcode[opnum + 0x100].CallOpcode = op_x;
            Opcode[opnum + 0x200].CallOpcode = op_m;
            Opcode[opnum + 0x300].CallOpcode = op_mx;
        }

        // Hard Reset
        public void InterruptReset()
        {
            setflag_d(0);
            setflag_w(0);
            setflag_e(-1);
            setflag_i(-1);
            setflag_m(-1);
            setflag_x(-1);
            r_AA = (UInt16)(r_AA + (r_A & 0xff00));
            r_A &= 0xff;
            r_X &= 0xff;
            r_Y &= 0xff;
            Int32 i = VECTOR_RESET;
            i = memory.map[(i + 0) >> 13] + ((i + 0));
            JumpPC(memory.ReadTwoByte(i));
            r_PCtiming = memory.maptiming[(r_PC + 0) >> 13];
            r_S = 0x1ff;
            r_DB = 0;
            r_DP = 0;
        }

        public void InterruptUnusedReset()
        {
            setflag_d(0);
            setflag_w(0);
            setflag_e(-1);
            setflag_i(-1);
            setflag_m(-1);
            setflag_x(-1);
            r_AA = (UInt16)(r_AA + (r_A & 0xff00));
            r_A &= 0xff;
            r_X &= 0xff;
            r_Y &= 0xff;
            Int32 i = VECTOR_UNUSED_RESET;
            i = memory.map[(i + 0) >> 13] + ((i + 0));
            JumpPC(memory.ReadTwoByte(i));
            r_PCtiming = memory.maptiming[(r_PC + 0) >> 13];
            r_S = 0x1ff;
            r_DB = 0;
            r_DP = 0;
        }

        public void InterruptIRQ()
        {
            if (getflag_i()) return;
            if (!getflag_r()) return;
            setflag_w(0);
            //setflag_r(0);
            if (getflag_e())
                CallInterrupt6502(VECTOR_IRQ_6502);
            else
                CallInterrupt65816(VECTOR_IRQ_65816);
        }

        public void InterruptNMI()
        {
            setflag_w(0);
            if (getflag_e())
                CallInterrupt6502(VECTOR_NMI_6502);
            else
                CallInterrupt65816(VECTOR_NMI_65816);
        }

        void CallInterrupt6502(Int32 i)
        {
            Int32 j = memory.map[(i + 0) >> 13] + ((i + 0));
            j = memory.ReadTwoByte(j);
            Int32 u = memory.map[(r_PC + 0) >> 13] + ((r_PC + 0));          // Get ram map value of previous jump
            u = r_ePC - u;                                                  // Get difference between last call and ePC
            u += r_PC;                                                      // Recover current PC value
            PushTwo(u);
            JumpPC(j);
            // Interrupt related changes
            PushOne(GetRegP16());
            setflag_d(0);
            setflag_w(0);
            setflag_i(-1);
        }
        void CallInterrupt65816(Int32 i)
        {
            Int32 j = memory.map[(i + 0) >> 13] + ((i + 0));
            j = memory.ReadTwoByte(j);
            Int32 u = memory.map[(r_PC + 0) >> 13] + ((r_PC + 0));          // Get ram map value of previous jump
            u = r_ePC - u;                                                  // Get difference between last call and ePC
            u += r_PC;                                                      // Recover current PC value
            PushThree(u);
            JumpPC(j);
            // Interrupt related changes
            PushOne(GetRegP16());
            setflag_d(0);
            setflag_w(0);
            setflag_i(-1);
        }

        void JumpPC(Int32 NewPC)
        {
            // Used for direct jumps and calls (JMP, JSR) but does not deal with regular branches and returns
            r_ePC = memory.map[(NewPC + 0) >> 13] + ((NewPC + 0));
            r_PC = NewPC;
            r_DBstart = r_DB;
            r_FLAGSstart = r_FLAGS;
            r_PCtiming = memory.maptiming[(r_PC + 0) >> 13];
        }

        void JumpPCx(Int32 NewPC)
        {
            // Used for returns (RTS, RTI)
            r_ePC = memory.map[(NewPC + 0) >> 13] + ((NewPC + 0));
            r_PC = NewPC;
            r_DBstart = r_DB;
            r_FLAGSstart = r_FLAGS;
        }

        void JumpPCx(Int32 NewPC, Int32 NewePC)
        {
            // Used for returns (RTS, RTI)
            r_ePC = memory.map[(NewePC + 0) >> 13] + ((NewePC + 0));
            r_PC = NewPC;
            r_DBstart = r_DB;
            r_FLAGSstart = r_FLAGS;
        }

        public void ExecuteOneStep()
        {
            UInt16 op;

            setflag_p(0);       // Reset the Pause flag
            if (!getflag_w())
            {
                op = (UInt16)(memory.mem[r_ePC++] | (r_FLAGS & 0x300));
                var mem = Opcode[op].CallAddrmode();
                Opcode[op].CallOpcode(mem);
            }
        }

        public bool Execute(byte[] romData)
        {
            memory.WriteROM(romData);
            var rtn = Execute();
            memory.ReadROM(romData);
            return rtn;
        }

        public bool Execute()
        {
            UInt16 op;
            DelOpcode callOpcode = null;
            DelAddrmode callAddrmode;
            int lastPC = -1;

            setflag_p(0);       // Reset the Pause flag
            setflag_w(0);       // Reset the Wait flag

            //#if !DEBUG
            try
            //#endif
            {
                if (getflag_p())    // Pause flag indicates that emulation is pausing
                    return false;
                while (!getflag_w())
                {
                    lastPC = r_ePC;

                    op = (UInt16)(memory.mem[r_ePC++] | (r_FLAGS & 0x300));
                    callAddrmode = Opcode[op].CallAddrmode;
                    callOpcode = Opcode[op].CallOpcode;
                    var addr = callAddrmode();
                    callOpcode(addr);

                    if (lastPC == r_ePC)
                    {
                        bool rtn = callOpcode == op___STP;
                        if (!rtn)
                        {
                            throw new Exception("Emulation has stopped with an unknown exception.");
                        }
                        return rtn;
                    }
                }
            }
            //#if !DEBUG
            catch (Exception ex)
            {
                System.Windows.Forms.MessageBox.Show($"Error during 65816 emulation.\n\n{ex}\n\n" +
                    $"A = {GetRegA():x4}\n" +
                    $"X = {GetRegX():x4}\n" +
                    $"Y = {GetRegY():x4}\n" +
                    $"\n" +
                    $"DB = {GetRegDB():x2}\n" +
                    $"DP = {GetRegDP():x4}\n" +
                    $"\n" +
                    $"mx = {GetFlag_MX():x2}\n" +
                    $"\n" +
                    $"PC = {GetRegPC():x6}\n" +
                    $"PC base = {r_PC:x6}") ;
            }
            //#endif
            return false;
        }

        // --------------------------------------------------------------------
        #region Address modes

        Int32 addr_none() { return 0; }
        Int32 addr_internal_1() { return 0; }
        Int32 addr_internal_2() { return 0; }
        Int32 addr__dp_x()       // (dp,X)
        {
            Int32 i = r_DP + memory.mem[r_ePC++];
            i += r_X;
            i &= 0xffff;
            i = memory.mem[memory.map[(i + 0) >> 13] + ((i + 0))] +
                (memory.mem[memory.map[(i + 1) >> 13] + ((i + 1))] << 8);   // +(r_DB << 16);
            i += (r_DB << 16);
            return memory.map[i >> 13] + (i);
            //cycles+=5;
        }
        Int32 addr_sr()          // sr,S
        {
            Int32 i = r_S + memory.mem[r_ePC++];
            return memory.map[i >> 13] + (i);
            //cycles+=3;
        }
        Int32 addr_dp()          // dp
        {
            Int32 i = r_DP + memory.mem[r_ePC++];
            return memory.map[i >> 13] + (i);
            //cycles+=2
        }
        Int32 addr___dp()        // [dp]
        {
            Int32 i = r_DP + memory.mem[r_ePC++];
            i = memory.mem[memory.map[(i + 0) >> 13] + ((i + 0))] +
                (memory.mem[memory.map[(i + 1) >> 13] + ((i + 1))] << 8) +
                (memory.mem[memory.map[(i + 2) >> 13] + ((i + 2))] << 16);
            return memory.map[i >> 13] + (i);
            //cycles+=;
        }
        Int32 addr_const_one()
        {
            return r_ePC++;
        }
        Int32 addr_const_two()
        {
            r_ePC += 2;
            return r_ePC - 2;
        }
        Int32 addr_const_three()
        {
            r_ePC += 3;
            return r_ePC - 3;
        }
        Int32 addr_addr()        // addr
        {
            Int32 i = memory.mem[r_ePC++] + (memory.mem[r_ePC++] << 8) + (r_DB << 16);
            return memory.map[i >> 13] + (i);
        }
        Int32 addr_addr_j()
        {
            Int32 i = memory.mem[r_ePC++] + (memory.mem[r_ePC++] << 8) + (0);
            return memory.map[i >> 13] + (i);
        }
        Int32 addr_long()        // long
        {
            Int32 i = memory.mem[r_ePC++] + (memory.mem[r_ePC++] << 8) + (memory.mem[r_ePC++] << 16);
            return memory.map[i >> 13] + (i);
        }
        Int32 addr__dp_y()       // (dp),Y
        {
            Int32 i = r_DP + memory.mem[r_ePC++];
            i = memory.mem[memory.map[(i + 0) >> 13] + ((i + 0))] +
                (memory.mem[memory.map[(i + 1) >> 13] + ((i + 1))] << 8);// +(r_DB << 16);
            i += r_Y;
            i &= 0xffff;
            i += (r_DB << 16);
            return memory.map[i >> 13] + (i);
        }
        Int32 addr__dp()         // (dp)
        {
            Int32 i = r_DP + memory.mem[r_ePC++];
            i = memory.mem[memory.map[(i + 0) >> 13] + ((i + 0))] +
                (memory.mem[memory.map[(i + 1) >> 13] + ((i + 1))] << 8);// +(r_DB << 16);
            i += (r_DB << 16);
            return memory.map[i >> 13] + (i);
        }
        Int32 addr__sr_y()       // (sr,S),Y
        {
            Int32 i = r_S + memory.mem[r_ePC++];
            i &= 0xffff;
            i = memory.mem[memory.map[(i + 0) >> 13] + ((i + 0))] +
                (memory.mem[memory.map[(i + 1) >> 13] + ((i + 1))] << 8);// +(r_DB << 16);
            i += r_Y;
            i &= 0xffff;
            i += (r_DB << 16);
            return memory.map[i >> 13] + (i);
        }
        Int32 addr_dp_x()        // dp,X
        {
            Int32 i = r_DP + r_X + memory.mem[r_ePC++];
            i &= 0xffff;
            return memory.map[i >> 13] + (i);
        }
        Int32 addr_dp_y()        // dp,Y
        {
            Int32 i = r_DP + r_Y + memory.mem[r_ePC++];
            i &= 0xffff;
            return memory.map[i >> 13] + (i);
        }
        Int32 addr___dp_y()      // [dp],Y
        {
            Int32 i = r_DP + memory.mem[r_ePC++];
            byte b = (memory.mem[memory.map[(i + 2) >> 13] + ((i + 2))]);
            i = memory.mem[memory.map[(i + 0) >> 13] + ((i + 0))] +
                (memory.mem[memory.map[(i + 1) >> 13] + ((i + 1))] << 8);
            i += r_Y;
            i += (b << 16);
            return memory.map[i >> 13] + (i);
        }
        Int32 addr_addr_y()      // addr,Y
        {
            Int32 i = memory.mem[r_ePC++] + (memory.mem[r_ePC++] << 8);
            i += r_Y;
            i &= 0xffff;
            i += (r_DB << 16);
            return memory.map[i >> 13] + (i);
        }
        Int32 addr_addr_x()      // addr,X
        {
            Int32 i = memory.mem[r_ePC++] + (memory.mem[r_ePC++] << 8);
            i += r_X;
            i &= 0xffff;
            i += (r_DB << 16);
            return memory.map[i >> 13] + (i);
        }
        Int32 addr_addr_x_j()
        {
            Int32 i = memory.mem[r_ePC++] + (memory.mem[r_ePC++] << 8);
            i += r_X;
            i &= 0xffff;
            i += (r_PC & 0xff0000);
            return memory.map[i >> 13] + (i);
        }
        Int32 addr_long_x()      //  long,X
        {
            Int32 i = memory.mem[r_ePC++] + (memory.mem[r_ePC++] << 8);
            i += r_X;
            i += (memory.mem[r_ePC++] << 16);
            i &= 0xffffff;
            return memory.map[i >> 13] + (i);
        }
        Int32 addr__addr()
        {
            Int32 i = memory.mem[r_ePC++] + (memory.mem[r_ePC++] << 8) + (r_DB << 16);
            i = memory.mem[memory.map[(i + 0) >> 13] + ((i + 0))] +
                (memory.mem[memory.map[(i + 1) >> 13] + ((i + 1))] << 8);// +(r_DB << 16);
            i += (r_DB << 16);
            return memory.map[i >> 13] + (i);
        }

        #endregion
        // --------------------------------------------------------------------
        #region Stack related

        void PushOne(Int32 i) { r_S -= 1; memory.WriteOneByte(memory.map[((r_S & 0xffff) + 1) >> 13] + ((r_S + 1)), i); }
        void PushTwo(Int32 i) { r_S -= 2; memory.WriteTwoByte(memory.map[((r_S & 0xffff) + 1) >> 13] + ((r_S + 1)), i); }
        void PushThree(Int32 i) { r_S -= 3; memory.WriteThreeByte(memory.map[((r_S & 0xffff) + 1) >> 13] + ((r_S + 1)), i); }
        Int32 PullOne() { Int32 i = memory.ReadOneByte(memory.map[((r_S & 0xffff) + 1) >> 13] + ((r_S + 1))); r_S += 1; return i; }
        Int32 PullTwo() { Int32 i = memory.ReadTwoByte(memory.map[((r_S & 0xffff) + 1) >> 13] + ((r_S + 1))); r_S += 2; return i; }
        Int32 PullThree() { Int32 i = memory.ReadThreeByte(memory.map[((r_S & 0xffff) + 1) >> 13] + ((r_S + 1))); r_S += 3; return i; }

        #endregion
        // --------------------------------------------------------------------
        #region Affect flags

        int overflow;

        public void setflag_c(Int32 n) { Int32 m = 0x40000000; r_FLAGS = (r_FLAGS & ~m) | ((n << 14) & m); }
        public void setflag_z(Int32 n) { Int32 m = 0x03FFFC00; r_FLAGS = (r_FLAGS & ~m) | ((n << 10) & m); }
        //public  void setflag_v(Int32 n) { Int32 m = 0x10000000; r_FLAGS = (r_FLAGS & ~m) | ((n << 12) & m); } // Act the same as C
        public void setflag_v(Int32 n) { overflow = n; }
        public void setflag_n(Int32 n) { Int32 m = 0x20000000; r_FLAGS = (r_FLAGS & ~m) | ((n << 14) & m); }
        public void setflag_w(Int32 n) { Int32 m = 0x00000080; r_FLAGS = (r_FLAGS & ~m) | ((n << 0) & m); }
        public void setflag_i(Int32 n) { Int32 m = 0x00000040; r_FLAGS = (r_FLAGS & ~m) | ((n << 0) & m); }
        public void setflag_d(Int32 n) { Int32 m = 0x00000020; r_FLAGS = (r_FLAGS & ~m) | ((n << 0) & m); }
        public void setflag_e(Int32 n) { Int32 m = 0x00000010; r_FLAGS = (r_FLAGS & ~m) | ((n << 0) & m); }
        public void setflag_m(Int32 n) { Int32 m = 0x00000200; r_FLAGS = (r_FLAGS & ~m) | ((n << 0) & m); }
        public void setflag_x(Int32 n) { Int32 m = 0x00000100; r_FLAGS = (r_FLAGS & ~m) | ((n << 0) & m); }
        // void setflag_nv(Int32 n) { Int32 m = 0x30000000; r_FLAGS = (r_FLAGS & ~m) | (((n << 10) | (n << 14)) & m); }
        void setflag_nv(Int32 n) { Int32 m = 0x30000000; r_FLAGS = (r_FLAGS & ~m) | (((n << 10) | (n << 14)) & m); setflag_v(n & 0x4000); }
        void setflag_nz(Int32 n) { Int32 m = 0x23FFFC00; r_FLAGS = (r_FLAGS & ~m) | (((n << 10) | (n << 14)) & m); }
        void setflag_nzc(Int32 n) { Int32 m = 0x63FFFC00; r_FLAGS = (r_FLAGS & ~m) | (((n << 10) | (n << 14)) & m); }
        // void setflag_nvz(Int32 n) { Int32 m = 0x33FFFC00; r_FLAGS = (r_FLAGS & ~m) | (((n << 10) | (n << 14)) & m); }
        // void setflag_nvzc(Int32 n) { Int32 m = 0x73FFFC00; r_FLAGS = (r_FLAGS & ~m) | (((n << 10) | (n << 14)) & m); }
        public void setflag_r(Int32 n) { Int32 m = 0x00000004; r_FLAGS = (r_FLAGS & ~m) | ((n << 0) & m); }  // Interrupt Request
        public void setflag_p(Int32 n) { Int32 m = 0x00000008; r_FLAGS = (r_FLAGS & ~m) | ((n << 0) & m); }

        public bool getflag_c() { return 0 != (r_FLAGS & 0x40000000); }
        public bool getflag_z() { return 0 == (r_FLAGS & 0x03FFFC00); }
        //public  bool getflag_v() { return 0 != (r_FLAGS & 0x10000000); }
        public bool getflag_v() { return 0 != overflow; }
        public bool getflag_n() { return 0 != (r_FLAGS & 0x20000000); }
        public bool getflag_w() { return 0 != (r_FLAGS & 0x00000080); }
        public bool getflag_i() { return 0 != (r_FLAGS & 0x00000040); }
        public bool getflag_d() { return 0 != (r_FLAGS & 0x00000020); }
        public bool getflag_e() { return 0 != (r_FLAGS & 0x00000010); }
        public bool getflag_m() { return 0 != (r_FLAGS & 0x00000200); }
        public bool getflag_x() { return 0 != (r_FLAGS & 0x00000100); }
        public bool getflag_r() { return 0 != (r_FLAGS & 0x00000004); }
        public bool getflag_p() { return 0 != (r_FLAGS & 0x00000008); }
        bool getflag_pw() { return 0 != (r_FLAGS & 0x00000088); }

        public byte GetFlag_MX() { return (byte)((r_FLAGS & 0x300) >> 4); }  // Used by Tracker class

        #endregion
        // --------------------------------------------------------------------
        #region Get/set registers

        public UInt16 GetRegA() { return (UInt16)(r_A + r_AA); }
        public UInt16 GetRegX() { return (UInt16)r_X; }
        public UInt16 GetRegY() { return (UInt16)r_Y; }
        public Int32 GetRegPC()
        {
            Int32 u = memory.map[(r_PC + 0) >> 13] + ((r_PC + 0));          // Get ram map value of previous jump
            u = r_ePC - u + r_PC;                                           // Get difference between last call and ePC
            return u;
        }
        public Int32 GetRegPClastjump() { return r_PC; }
        public byte GetRegDB() { return (byte)r_DB; }
        public UInt16 GetRegDP() { return (UInt16)r_DP; }
        public UInt16 GetRegS() { return (UInt16)r_S; }
        public Int32 GetRegFlagsLastjump() { return r_FLAGSstart; }
        public UInt16 GetRegP16()
        {
            UInt16 i = 0;   // Flag order (9 bits): envmxdizc
            if (getflag_c()) i += 0x01;     // Carry
            if (getflag_z()) i += 0x02;     // Zero
            if (getflag_i()) i += 0x04;     // Interrupt
            if (getflag_d()) i += 0x08;     // Decimal
            if (getflag_x()) i += 0x10;     // Extended
            if (getflag_m()) i += 0x20;     // Memory
            if (getflag_v()) i += 0x40;     // Overflow
            if (getflag_n()) i += 0x80;     // Negative
            if (getflag_e()) i += 0x100;    // Emulation
            if (getflag_w()) i += 0x200;    // Wait (From WAI opcode)
            if (getflag_r()) i += 0x400;    // Request (IRQ)
            return i;
        }

        public void SetRegA(Int32 i)
        {
            if (getflag_m())
            {
                r_A = (UInt16)(i & 0x00ff);
                r_AA = (UInt16)(i & 0xff00);
            }
            else
                r_A = (UInt16)i;
        }
        public void SetRegX(Int32 i)
        {
            r_X = (UInt16)i;
            if (getflag_x())
                r_X &= 0xff;
        }
        public void SetRegY(Int32 i)
        {
            r_Y = (UInt16)i;
            if (getflag_x())
                r_Y &= 0xff;
        }
        public void SetRegPC(Int32 i)
        {
            JumpPC(i);
        }
        public void SetRegDB(Int32 i) { r_DB = (byte)i; }
        public void SetRegDP(Int32 i) { r_DP = (UInt16)i; }
        public void SetRegS(Int32 i) { r_S = (UInt16)i; }

        public void SetRegP16(Int32 i)
        {
            r_FLAGS = (UInt16)(r_FLAGS & 0x9F);
            r_A = (UInt16)(r_A + r_AA);
            r_AA = 0;
            if ((i & 0x01) != 0) setflag_c(-1);
            if ((i & 0x02) == 0) setflag_z(-1);
            if ((i & 0x04) != 0) setflag_i(-1);
            if ((i & 0x08) != 0) setflag_d(-1);
            if ((i & 0x10) != 0)
            {
                r_X &= 0xff;
                r_Y &= 0xff;
                setflag_x(-1);
            }
            if ((i & 0x20) != 0)
            {
                if (!getflag_m())
                {
                    r_AA = (UInt16)(r_A & 0xff00);
                    r_A = (UInt16)(r_A & 0x00ff);
                }
                setflag_m(-1);
            }
            if ((i & 0x40) != 0)
                setflag_v(-1);
            else
                setflag_v(0);
            if ((i & 0x80) != 0) setflag_n(-1);
            if ((i & 0x100) != 0) setflag_e(-1);
            if ((i & 0x200) != 0) setflag_w(-1);
            if ((i & 0x400) != 0) setflag_r(-1);
            if ((i & 0x800) != 0) setflag_p(-1);
        }

        public void SetRegP8(Int32 i)
        {
            r_A = (UInt16)(r_A + r_AA);
            r_AA = 0;
            r_FLAGS = (UInt16)(r_FLAGS & 0x9F);

            if ((i & 0x01) != 0) setflag_c(-1);
            if ((i & 0x02) == 0) setflag_z(-1);
            if ((i & 0x08) != 0) setflag_d(-1);
            if ((i & 0x10) != 0)
            {
                r_X &= 0xff;
                r_Y &= 0xff;
                setflag_x(-1);
            }
            if ((i & 0x20) != 0)
            {
                if (!getflag_m())
                {
                    r_AA = (UInt16)(r_A & 0xff00);
                    r_A = (UInt16)(r_A & 0x00ff);
                }
                setflag_m(-1);
            }
            if ((i & 0x40) != 0)
                setflag_v(-1);
            else
                setflag_v(0);
            if ((i & 0x80) != 0) setflag_n(-1);
            if ((i & 0x04) != 0) setflag_i(-1);
        }

        #endregion
        // --------------------------------------------------------------------
        #region Opcodes

        void op___ADC(Int32 i)
        {
            i = memory.ReadTwoByte(i);
            if (!getflag_d())
            {
                // Binary mode
                i += r_A + (r_FLAGS >> 30);
                i &= 0x1ffff;
                r_A = (UInt16)i;
            }
            else
            {
                // Decimal mode
                i = i + (r_FLAGS >> 30);
                Int32 a = r_A;
                Int32 d = 0;

                // Digit 0
                d += ((i & 0x000f) + (a & 0x000f));
                if (d >= 0x000a)
                    d += 0x0006;
                // Digit 1
                d += ((i & 0x00f0) + (a & 0x00f0));
                if (d >= 0x00a0)
                    d += 0x0060;
                // Digit 2
                d += ((i & 0x0f00) + (a & 0x0f00));
                if (d >= 0x0a00)
                    d += 0x0600;
                // Digit 3
                d += ((i & 0xf000) + (a & 0xf000));
                if (d >= 0xa000)
                    d += 0x6000;
                r_A = (UInt16)d;
                i = (d | (d >> 4)) & 0x17fff;
            }
            setflag_nzc(i);
        }
        void op__mADC(Int32 i)
        {
            i = memory.ReadOneByte(i);
            if (!getflag_d())
            {
                i += r_A + (r_FLAGS >> 30);
                i &= 0x1ff;
                r_A = (UInt16)(i & 0xff);
            }
            else
            {
                // Decimal mode
                i = i + (r_FLAGS >> 30);
                Int32 a = r_A;
                Int32 d = 0;

                // Digit 0
                d += ((i & 0x000f) + (a & 0x000f));
                if (d >= 0x000a)
                    d += 0x0006;
                // Digit 1
                d += ((i & 0x00f0) + (a & 0x00f0));
                if (d >= 0x00a0)
                    d += 0x0060;
                r_A = (UInt16)d;
                i = (d | (d >> 4)) & 0x17f;
            }
            setflag_nzc(i << 8);
        }

        void op___AND(Int32 i)
        {
            i = memory.ReadTwoByte(i);
            i &= r_A;
            r_A = (UInt16)i;
            setflag_nz(i);
        }
        void op__mAND(Int32 i)
        {
            i = memory.ReadOneByte(i);
            i &= r_A;
            r_A = (UInt16)(i & 0xff);
            setflag_nz(i << 8);
        }

        void op___SLA(Int32 i)  // ASL A
        {
            i = r_A << 1;
            r_A = (UInt16)i;
            setflag_nzc(i);
        }
        void op__mSLA(Int32 i)  // ASL A
        {
            i = r_A << 1;
            r_A = (UInt16)(i & 0xff);
            setflag_nzc(i << 8);
        }

        void op___ASL(Int32 i)
        {
            Int32 m = memory.ReadTwoByte(i);
            m = m << 1;
            memory.WriteTwoByte(i, m);
            setflag_nzc(m);
        }
        void op__mASL(Int32 i)
        {
            Int32 m = memory.ReadOneByte(i);
            m = m << 1;
            memory.WriteOneByte(i, m);
            setflag_nzc(m << 8);
        }

        void op___BIT(Int32 i)
        {
            i = memory.ReadTwoByte(i);
            setflag_nv(i);
            i = r_A & i;
            setflag_z(i);
        }
        void op__mBIT(Int32 i)
        {
            i = memory.ReadOneByte(i);
            setflag_nv(i << 8);
            i = r_A & i;
            setflag_z(i << 8);
        }

        void op___BII(Int32 i)  // BIT #const
        {
            i = memory.ReadTwoByte(i);
            i = r_A & i;
            setflag_z(i);
        }
        void op__mBII(Int32 i)  // BIT #const
        {
            i = memory.ReadOneByte(i);
            i = r_A & i;
            setflag_z(i << 8);
        }

        // Conditional branch
        void op___BCC(Int32 i) { i = memory.ReadOneByte(i); if (getflag_c() == false) { r_ePC += (Int32)((sbyte)(i)); } }
        void op___BCS(Int32 i) { i = memory.ReadOneByte(i); if (getflag_c() == true) { r_ePC += (Int32)((sbyte)(i)); } }
        void op___BNE(Int32 i) { i = memory.ReadOneByte(i); if (getflag_z() == false) { r_ePC += (Int32)((sbyte)(i)); } }
        void op___BEQ(Int32 i) { i = memory.ReadOneByte(i); if (getflag_z() == true) { r_ePC += (Int32)((sbyte)(i)); } }
        void op___BPL(Int32 i) { i = memory.ReadOneByte(i); if (getflag_n() == false) { r_ePC += (Int32)((sbyte)(i)); } }
        void op___BMI(Int32 i) { i = memory.ReadOneByte(i); if (getflag_n() == true) { r_ePC += (Int32)((sbyte)(i)); } }
        void op___BVC(Int32 i) { i = memory.ReadOneByte(i); if (getflag_v() == false) { r_ePC += (Int32)((sbyte)(i)); } }
        void op___BVS(Int32 i) { i = memory.ReadOneByte(i); if (getflag_v() == true) { r_ePC += (Int32)((sbyte)(i)); } }

        // Branch always
        void op___BRA(Int32 i) { r_ePC += (Int32)((sbyte)(memory.ReadOneByte(i))); }
        void op___BRL(Int32 i)
        {
            Int32 pc = GetRegPC();
            Int32 bank = pc & 0xff0000;
            pc += (Int32)((Int16)(memory.ReadTwoByte(i)));
            pc = pc & 0xffff | bank;
            SetRegPC(pc);
        }

        // Break
        void op___BRK(Int32 i)
        {
            if (getflag_e())
                CallInterrupt6502(VECTOR_BRK_6502);
            else
                CallInterrupt65816(VECTOR_BRK_65816);
        }

        void op___CLC(Int32 i) { setflag_c(0); }
        void op___CLD(Int32 i) { setflag_d(0); }
        void op___CLI(Int32 i) { setflag_i(0); InterruptIRQ(); }
        void op___CLV(Int32 i) { setflag_v(0); }

        void op___COP(Int32 i)
        {
            if (getflag_e())
                CallInterrupt6502(VECTOR_COP_6502);
            else
                CallInterrupt65816(VECTOR_COP_65816);
        }

        void op___CMP(Int32 i)
        {
            i = memory.ReadTwoByte(i);
            i = r_A + (i ^ 0xffff) + 1;
            setflag_nzc(i);
        }
        void op__mCMP(Int32 i)
        {
            i = memory.ReadOneByte(i);
            i = r_A + (i ^ 0xff) + 1;
            setflag_nzc(i << 8);
        }

        void op___CPX(Int32 i)
        {
            i = memory.ReadTwoByte(i);
            i = r_X + (i ^ 0xffff) + 1;
            setflag_nzc(i);
        }
        void op__xCPX(Int32 i)
        {
            i = memory.ReadOneByte(i);
            i = r_X + (i ^ 0xff) + 1;
            setflag_nzc(i << 8);
        }

        void op___CPY(Int32 i)
        {
            i = memory.ReadTwoByte(i);
            i = r_Y + (i ^ 0xffff) + 1;
            setflag_nzc(i);
        }
        void op__xCPY(Int32 i)
        {
            i = memory.ReadOneByte(i);
            i = r_Y + (i ^ 0xff) + 1;
            setflag_nzc(i << 8);
        }

        void op___DEC(Int32 i)
        {
            r_A--;
            r_A &= 0xffff;
            setflag_nz(r_A);
        }
        void op__mDEC(Int32 i)
        {
            r_A--;
            r_A &= 0xff;
            setflag_nz(r_A << 8);
        }

        void op___DEM(Int32 i)
        {
            Int32 m = memory.ReadTwoByte(i);
            m = (UInt16)((m - 1) & 0xffff);
            memory.WriteTwoByte(i, m);
            setflag_nz(m);
        }
        void op__mDEM(Int32 i)
        {
            Int32 m = memory.ReadOneByte(i);
            m = (UInt16)((m - 1) & 0xff);
            memory.WriteOneByte(i, m);
            setflag_nz(m << 8);
        }

        void op___DEX(Int32 i)
        {
            r_X--;
            r_X &= 0xffff;
            setflag_nz(r_X);
        }
        void op__xDEX(Int32 i)
        {
            r_X--;
            r_X &= 0xff;
            setflag_nz(r_X << 8);
        }

        void op___DEY(Int32 i)
        {
            r_Y--;
            r_Y &= 0xffff;
            setflag_nz(r_Y);
        }
        void op__xDEY(Int32 i)
        {
            r_Y--;
            r_Y &= 0xff;
            setflag_nz(r_Y << 8);
        }

        void op___EOR(Int32 i)
        {
            i = memory.ReadTwoByte(i);
            i ^= r_A;
            r_A = (UInt16)i;
            setflag_nz(i);
        }
        void op__mEOR(Int32 i)
        {
            i = memory.ReadOneByte(i);
            i ^= r_A;
            r_A = (UInt16)(i & 0xff);
            setflag_nz(i << 8);
        }

        void op___INC(Int32 i)
        {
            r_A++;
            r_A &= 0xffff;
            setflag_nz(r_A);
        }
        void op__mINC(Int32 i)
        {
            r_A++;
            r_A &= 0xff;
            setflag_nz(r_A << 8);
        }

        void op___INM(Int32 i)
        {
            Int32 m = memory.ReadTwoByte(i);
            m = (UInt16)((m + 1) & 0xffff);
            memory.WriteTwoByte(i, m);
            setflag_nz(m);
        }
        void op__mINM(Int32 i)
        {
            Int32 m = memory.ReadOneByte(i);
            m = (UInt16)((m + 1) & 0xff);
            memory.WriteOneByte(i, m);
            setflag_nz(m << 8);
        }

        void op___INX(Int32 i)
        {
            r_X++;
            r_X &= 0xffff;
            setflag_nz(r_X);
        }
        void op__xINX(Int32 i)
        {
            r_X++;
            r_X &= 0xff;
            setflag_nz(r_X << 8);
        }

        void op___INY(Int32 i)
        {
            r_Y++;
            r_Y &= 0xffff;
            setflag_nz(r_Y);
        }
        void op__xINY(Int32 i)
        {
            r_Y++;
            r_Y &= 0xff;
            setflag_nz(r_Y << 8);
        }

        void op___JMP(Int32 i)
        {
            i = memory.ReadTwoByte(i);
            i = (r_PC & 0xff0000) | i;
            JumpPC(i);
        }
        void op__bJMP(Int32 i)
        {
            // This jump (0x4C) has different settings for the disassembler
            // It only differs from _JMP for its dbg version
            i = memory.ReadTwoByte(i);
            i = (r_PC & 0xff0000) | i;
            JumpPC(i);
        }
        void op___JML(Int32 i)
        {
            i = memory.ReadThreeByte(i);
            JumpPC(i);
        }
        void op___JMLI(Int32 i)
        {
            i = memory.ReadThreeByte(i);
            JumpPC(i);
        }

        void op___JSR(Int32 i)
        {
            i = memory.ReadTwoByte(i);
            i = (r_PC & 0xff0000) | i;                                      // Convert to 24-bit pointer for new PC
            Int32 u = memory.map[(r_PC + 0) >> 13] + ((r_PC + 0));          // Get ram map value of previous jump
            u = r_ePC - u;                                                  // Get difference between last call and ePC
            u += r_PC;                                                      // Recover current PC value
            PushTwo(u - 1);
            JumpPC(i);
        }
        void op___JSL(Int32 i)
        {
            i = memory.ReadThreeByte(i);
            Int32 u = memory.map[(r_PC + 0) >> 13] + ((r_PC + 0));          // Get ram map value of previous jump
            u = r_ePC - u;                                                  // Get difference between last call and ePC
            u += r_PC;                                                      // Recover current PC value
            PushThree(u - 1);
            JumpPC(i);
        }

        void op___LDA(Int32 i)
        {
            i = memory.ReadTwoByte(i);
            r_A = (UInt16)i;
            setflag_nz(i);
        }
        void op__mLDA(Int32 i)
        {
            i = memory.ReadOneByte(i);
            r_A = (UInt16)i;
            setflag_nz(i << 8);
        }

        void op___LDX(Int32 i)
        {
            i = memory.ReadTwoByte(i);
            r_X = (UInt16)i;
            setflag_nz(i);
        }
        void op__xLDX(Int32 i)
        {
            i = memory.ReadOneByte(i);
            r_X = (UInt16)i;
            setflag_nz(i << 8);
        }

        void op___LDY(Int32 i)
        {
            i = memory.ReadTwoByte(i);
            r_Y = (UInt16)i;
            setflag_nz(i);
        }
        void op__xLDY(Int32 i)
        {
            i = memory.ReadOneByte(i);
            r_Y = (UInt16)i;
            setflag_nz(i << 8);
        }

        void op___SRA(Int32 i)  // LSR A
        {
            i = (Int32)r_A & 0xffff;
            i = ((i & 0x1) << 16) | (i >> 1);
            r_A = (UInt16)i;
            setflag_nzc(i);
        }
        void op__mSRA(Int32 i)  // LSR A
        {
            i = (Int32)r_A & 0xff;
            i = ((i & 0x1) << 8) | (i >> 1);
            r_A = (UInt16)(i & 0xff);
            setflag_nzc(i << 8);
        }

        void op___LSR(Int32 i)
        {
            Int32 m = memory.ReadTwoByte(i);
            m = ((m & 0x1) << 16) | (m >> 1);
            m = (Int32)m & 0x1ffff;
            memory.WriteTwoByte(i, m);
            setflag_nzc(m);
        }
        void op__mLSR(Int32 i)
        {
            Int32 m = memory.ReadOneByte(i);
            m = ((m & 0x1) << 8) | (m >> 1);
            m = (Int32)m & 0x1ff;
            memory.WriteOneByte(i, m);
            setflag_nzc(m << 8);
        }

        void op___MVN(Int32 i)
        {
            Int32 y = r_Y + (memory.ReadOneByte(i++) << 16);
            Int32 x = r_X + (memory.ReadOneByte(i++) << 16);
            r_DB = y >> 16;
            Int32 yy, xx;
            Int32 a;
            for (a = r_A + (r_AA & 0xff00); a >= 0; a--)
            {
                xx = memory.map[(x + 0) >> 13] + ((x + 0));
                yy = memory.map[(y + 0) >> 13] + ((y + 0));
                memory.WriteOneByte(yy, memory.ReadOneByte(xx));
                x++;
                y++;
            }
            r_A = (UInt16)a;
            if (r_A != 0xffff)
                r_ePC -= 3;
            if (getflag_m())
            {
                r_AA = r_A & 0xff00;
                r_A = r_A & 0x00ff;
            }
            if (getflag_x())
            {
                // 8-bit
                r_X = (byte)x;
                r_Y = (byte)y;
            }
            else
            {
                // 16-bit
                r_X = (UInt16)x;
                r_Y = (UInt16)y;
            }
        }
        void op___MVP(Int32 i)
        {
            Int32 y = r_Y + (memory.ReadOneByte(i++) << 16);
            Int32 x = r_X + (memory.ReadOneByte(i++) << 16);
            r_DB = y >> 16;
            Int32 yy, xx;
            Int32 a;
            for (a = r_A + (r_AA & 0xff00); a >= 0; a--)
            {
                xx = memory.map[(x + 0) >> 13] + ((x + 0));
                yy = memory.map[(y + 0) >> 13] + ((y + 0));
                memory.WriteOneByte(yy, memory.ReadOneByte(xx));
                x--;
                y--;
            }
            r_A = (UInt16)a;
            if (r_A != 0xffff)
                r_ePC -= 3;
            if (getflag_m())
            {
                r_AA = r_A & 0xff00;
                r_A = r_A & 0x00ff;
            }
            if (getflag_x())
            {
                // 8-bit
                r_X = (byte)x;
                r_Y = (byte)y;
            }
            else
            {
                // 16-bit
                r_X = (UInt16)x;
                r_Y = (UInt16)y;
            }
        }

        void op___NOP(Int32 i) { /* Nothing happens! */ }

        void op___ORA(Int32 i)
        {
            i = memory.ReadTwoByte(i);
            i |= r_A;
            r_A = (UInt16)i;
            setflag_nz(i);
        }
        void op__mORA(Int32 i)
        {
            i = memory.ReadOneByte(i);
            i |= r_A;
            r_A = (UInt16)(i & 0xff);
            setflag_nz(i << 8);
        }

        void op___PEA(Int32 i) { i = memory.ReadTwoByte(i); PushTwo(i); }
        void op___PEI(Int32 i) { i = memory.ReadTwoByte(i); PushTwo(i); }
        void op___PER(Int32 i) { i = memory.ReadTwoByte(i); PushTwo(i + GetRegPC()); }
        void op___PHA(Int32 i) { PushTwo(r_A); }
        void op__mPHA(Int32 i) { PushOne(r_A); }
        void op___PHB(Int32 i) { PushOne(r_DB); }
        void op___PHD(Int32 i) { PushTwo(r_DP); }
        void op___PHK(Int32 i) { PushOne(r_PC >> 16); }
        void op___PHP(Int32 i) { PushOne(GetRegP16()); }
        void op___PHX(Int32 i) { PushTwo(r_X); }
        void op__xPHX(Int32 i) { PushOne(r_X); }
        void op___PHY(Int32 i) { PushTwo(r_Y); }
        void op__xPHY(Int32 i) { PushOne(r_Y); }

        void op___PLA(Int32 i) { i = PullTwo(); r_A = (UInt16)i; setflag_nz(i); }
        void op__mPLA(Int32 i) { i = PullOne(); r_A = (UInt16)i; setflag_nz(i << 8); }
        void op___PLB(Int32 i) { i = PullOne(); r_DB = (UInt16)i; setflag_nz(i << 8); }
        void op___PLD(Int32 i) { i = PullTwo(); r_DP = (UInt16)i; setflag_nz(i); }
        void op___PLP(Int32 i) { i = PullOne(); SetRegP8(i); InterruptIRQ(); }
        void op___PLX(Int32 i) { i = PullTwo(); r_X = (UInt16)i; setflag_nz(i); }
        void op__xPLX(Int32 i) { i = PullOne(); r_X = (UInt16)i; setflag_nz(i << 8); }
        void op___PLY(Int32 i) { i = PullTwo(); r_Y = (UInt16)i; setflag_nz(i); }
        void op__xPLY(Int32 i) { i = PullOne(); r_Y = (UInt16)i; setflag_nz(i << 8); }

        void op___REP(Int32 i)
        {
            i = memory.ReadOneByte(i);
            if ((i & 0x10) != 0) setflag_x(0);
            if ((i & 0x20) != 0)
            {
                if (getflag_m())
                    r_A = (UInt16)((r_A & 0x00ff) + (r_AA & 0xff00));
                r_AA = 0;
                setflag_m(0);
            }
            if ((i & 0xcf) != 0)
            {
                if ((i & 0x01) != 0) setflag_c(0);
                if ((i & 0x02) != 0) setflag_z(-1); // z exception
                if ((i & 0x08) != 0) setflag_d(0);
                if ((i & 0x40) != 0) setflag_v(0);
                if ((i & 0x80) != 0) setflag_n(0);
                if ((i & 0x04) != 0)
                {
                    setflag_i(0);
                    InterruptIRQ();
                }
            }
        }

        void op___SEP(Int32 i)
        {
            i = memory.ReadOneByte(i);
            if ((i & 0x10) != 0)
            {
                r_X &= 0xff;
                r_Y &= 0xff;
                setflag_x(-1);
            }
            if ((i & 0x20) != 0)
            {
                if (!getflag_m())
                {
                    r_AA = (UInt16)(r_A & 0xff00);
                    r_A = (UInt16)(r_A & 0x00ff);
                }
                setflag_m(-1);
            }
            if ((i & 0xcf) != 0)
            {
                if ((i & 0x01) != 0) setflag_c(-1);
                if ((i & 0x02) != 0) setflag_z(0);  // z exception
                if ((i & 0x04) != 0) setflag_i(-1);
                if ((i & 0x08) != 0) setflag_d(-1);
                if ((i & 0x40) != 0) setflag_v(-1);
                if ((i & 0x80) != 0) setflag_n(-1);
            }
        }

        void op___RLA(Int32 i)  // ROL A
        {
            i = (r_A << 1) + (r_FLAGS >> 30);
            r_A = (UInt16)i;
            setflag_nzc(i);
        }
        void op__mRLA(Int32 i)  // ROL A
        {
            i = (r_A << 1) + (r_FLAGS >> 30);
            r_A = (UInt16)(i & 0xff);
            setflag_nzc(i << 8);
        }

        void op___ROL(Int32 i)
        {
            Int32 m = memory.ReadTwoByte(i);
            m = (m << 1) + (r_FLAGS >> 30);
            memory.WriteTwoByte(i, m);
            setflag_nzc(m);
        }
        void op__mROL(Int32 i)
        {
            Int32 m = memory.ReadOneByte(i);
            m = (m << 1) + (r_FLAGS >> 30);
            memory.WriteOneByte(i, m);
            setflag_nzc(m << 8);
        }

        void op___RRA(Int32 i)  // ROR A
        {
            i = ((r_A & 0xffff) + (r_A << 17) + ((r_FLAGS >> 14) & 0x10000)) >> 1;
            i &= 0x1ffff;
            r_A = (UInt16)i;
            setflag_nzc(i);
        }
        void op__mRRA(Int32 i)  // ROR A
        {
            i = ((r_A & 0xff) + (r_A << 9) + ((r_FLAGS >> 22) & 0x100)) >> 1;
            i &= 0x1ff;
            r_A = (UInt16)(i & 0xff);
            setflag_nzc(i << 8);
        }

        void op___ROR(Int32 i)
        {
            Int32 m = memory.ReadTwoByte(i);
            m = ((m & 0xffff) + (m << 17) + ((r_FLAGS >> 14) & 0x10000)) >> 1;
            m &= 0x1ffff;
            memory.WriteTwoByte(i, m);
            setflag_nzc(m);
        }
        void op__mROR(Int32 i)
        {
            Int32 m = memory.ReadOneByte(i);
            m = ((m & 0xff) + (m << 9) + ((r_FLAGS >> 22) & 0x100)) >> 1;
            m &= 0x1ff;
            memory.WriteOneByte(i, m);
            setflag_nzc(m << 8);
        }

        void op___RTI(Int32 i)
        {
            SetRegP8(PullOne());
            if (getflag_e())
            {
                i = PullTwo();
                i = (r_PC & 0xff0000) | i;
            }
            else
            {
                i = PullThree();
            }
            JumpPCx(i);
            InterruptIRQ();
        }
        void op___RTS(Int32 i)
        {
            i = PullTwo() + 1;
            i = (r_PC & 0xff0000) | i;                                      // Convert to 24-bit pointer for new ePC
            JumpPCx(i);
        }
        void op___RTL(Int32 i)
        {
            i = PullThree() + 1;
            JumpPCx(i);
            //r_ePC = memory.map[(i + 0) >> 13] + ((i + 0));                // Get ram map value of return
            //r_PC = u;
        }

        void op___SBC(Int32 i)
        {
            i = memory.ReadTwoByte(i);
            if (!getflag_d())
            {
                i = r_A + (i ^ 0xffff) + (r_FLAGS >> 30);
                i &= 0x1ffff;
                r_A = (UInt16)i;
            }
            else
            {
                // Decimal mode
                i = i + (1 ^ (r_FLAGS >> 30));
                Int32 a = r_A;
                Int32 d = 0;

                // Digit 0
                d += (-(i & 0x000f) + (a & 0x000f));
                if (d < 0)
                    d += 0xa;
                // Digit 1
                d += (-(i & 0x00f0) + (a & 0x00f0));
                if (d < 0)
                    d += 0xa0;
                // Digit 2
                d += (-(i & 0x0f00) + (a & 0x0f00));
                if (d < 0)
                    d += 0xa00;
                // Digit 3
                d += (-(i & 0xf000) + (a & 0xf000));
                if (d < 0)
                    d += 0xa000;
                r_A = (UInt16)d;
                i = (d | (d >> 4)) & 0x17fff;
            }
            setflag_nzc(i);
        }
        void op__mSBC(Int32 i)
        {
            i = memory.ReadOneByte(i);
            if (!getflag_d())
            {
                i = r_A + (i ^ 0xff) + (r_FLAGS >> 30);
                i &= 0x1ff;
                r_A = (UInt16)(i & 0xff);
            }
            else
            {
                // Decimal mode
                i = i + (1 ^ (r_FLAGS >> 30));
                Int32 a = r_A;
                Int32 d = 0;

                // Digit 0
                d += (-(i & 0x000f) + (a & 0x000f));
                if (d < 0)
                    d += 0xa;
                // Digit 1
                d += (-(i & 0x00f0) + (a & 0x00f0));
                if (d < 0)
                    d += 0xa0;
                r_A = (UInt16)d;
                i = (d | (d >> 4)) & 0x17f;
            }
            setflag_nzc(i << 8);
        }

        void op___SEC(Int32 i) { setflag_c(-1); }
        void op___SED(Int32 i) { setflag_d(-1); }
        void op___SEI(Int32 i) { setflag_i(-1); }

        void op___STA(Int32 i) { memory.WriteTwoByte(i, r_A); }
        void op__mSTA(Int32 i) { memory.WriteOneByte(i, r_A); }
        void op___STX(Int32 i) { memory.WriteTwoByte(i, r_X); }
        void op__xSTX(Int32 i) { memory.WriteOneByte(i, r_X); }
        void op___STY(Int32 i) { memory.WriteTwoByte(i, r_Y); }
        void op__xSTY(Int32 i) { memory.WriteOneByte(i, r_Y); }
        void op___STZ(Int32 i) { memory.WriteTwoByte(i, 0); }
        void op__mSTZ(Int32 i) { memory.WriteOneByte(i, 0); }

        void op___STP(Int32 i) { r_ePC--; setflag_w(-1); }

        void op___TAX(Int32 i)
        {
            i = r_A + r_AA;
            r_X = (UInt16)i;
            setflag_nz(i);
        }
        void op__xTAX(Int32 i)
        {
            i = r_A;
            r_X = (UInt16)(i & 0xff);
            setflag_nz(i << 8);
        }

        void op___TAY(Int32 i)
        {
            i = r_A + r_AA;
            r_Y = (UInt16)i;
            setflag_nz(i);
        }
        void op__xTAY(Int32 i)
        {
            i = r_A;
            r_Y = (UInt16)(i & 0xff);
            setflag_nz(i << 8);
        }

        void op___TCD(Int32 i)
        {
            i = r_A + r_AA;
            r_DP = (UInt16)i;
            setflag_nz(i);
        }
        void op__mTCD(Int32 i)
        {
            i = r_A + r_AA;
            r_DP = (UInt16)i;
            setflag_nz(i);
        }

        void op___TCS(Int32 i)
        {
            i = r_A + r_AA;
            r_S = (UInt16)i;
            //setflag_nz(i);
        }
        void op__mTCS(Int32 i)
        {
            i = r_A + r_AA;
            r_S = (UInt16)i;
            //setflag_nz(i);
        }

        void op___TDC(Int32 i)
        {
            i = r_DP;
            r_A = (UInt16)i;
            setflag_nz(i);
        }
        void op__mTDC(Int32 i)
        {
            i = r_DP;
            r_A = (UInt16)(i & 0xff);
            r_AA = (UInt16)(i & 0xff00);
            setflag_nz(i);
        }

        void op___TRB(Int32 i)
        {
            Int32 m = memory.ReadTwoByte(i);
            Int32 u = r_A & m;
            m &= ~r_A;
            memory.WriteTwoByte(i, m);
            setflag_z(u);
        }
        void op__mTRB(Int32 i)
        {
            Int32 m = memory.ReadOneByte(i);
            Int32 u = r_A & m;
            m &= ~r_A;
            memory.WriteOneByte(i, m);
            setflag_z(u);
        }

        void op___TSB(Int32 i)
        {
            Int32 m = memory.ReadTwoByte(i);
            Int32 u = r_A & m;
            m |= r_A;
            memory.WriteTwoByte(i, m);
            setflag_z(u);
        }
        void op__mTSB(Int32 i)
        {
            Int32 m = memory.ReadOneByte(i);
            Int32 u = r_A & m;
            m |= r_A;
            memory.WriteOneByte(i, m);
            setflag_z(u);
        }

        void op___TSC(Int32 i)
        {
            i = r_S;
            r_A = (UInt16)i;
            setflag_nz(i);
        }
        void op__mTSC(Int32 i)
        {
            i = r_S;
            r_A = (UInt16)(i & 0xff);
            r_AA = (UInt16)(i & 0xff00);
            setflag_nz(i);
        }

        void op___TSX(Int32 i)
        {
            i = r_S;
            r_X = (UInt16)i;
            setflag_nz(i);
        }
        void op__xTSX(Int32 i)
        {
            i = r_S;
            r_X = (UInt16)(i & 0xff);
            setflag_nz(i << 8);
        }

        void op___TXA(Int32 i)
        {
            i = r_X;
            r_A = (UInt16)i;
            setflag_nz(i);
        }
        void op__mTXA(Int32 i)
        {
            i = r_X;
            r_A = (UInt16)(i & 0xff);
            //r_AA = (UInt16)(i & 0xff00);
            setflag_nz(r_A << 8); //
        }

        void op___TXS(Int32 i)
        {
            i = r_X;
            r_S = (UInt16)i;
            //setflag_nz(i);
        }
        void op__xTXS(Int32 i)
        {
            i = r_X;
            r_S = (UInt16)(i & 0xff);
            //setflag_nz(i << 8);
        }

        void op___TXY(Int32 i)
        {
            i = r_X;
            r_Y = (UInt16)i;
            setflag_nz(i);
        }
        void op__xTXY(Int32 i)
        {
            i = r_X;
            r_Y = (UInt16)(i & 0xff);
            setflag_nz(i << 8);
        }

        void op___TYA(Int32 i)
        {
            i = r_Y;
            r_A = (UInt16)i;
            setflag_nz(i);
        }
        void op__mTYA(Int32 i)
        {
            i = r_Y;
            r_A = (UInt16)(i & 0xff);
            //r_AA = (UInt16)(i & 0xff00);
            setflag_nz(r_A << 8); //
        }

        void op___TYX(Int32 i)
        {
            i = r_Y;
            r_X = (UInt16)i;
            setflag_nz(i);
        }
        void op__xTYX(Int32 i)
        {
            i = r_Y;
            r_X = (UInt16)(i & 0xff);
            setflag_nz(i << 8);
        }

        void op___WAI(Int32 i)
        {
            setflag_w(-1);
        }

        void op___WDM(Int32 i)
        {
            i = memory.ReadOneByte(i);
            // TODO: Will be used for injector feedback and optimization
        }

        void op___XBA(Int32 i)
        {
            i = (r_A << 8) + (r_A >> 8);
            i &= 0xffff;
            r_A = (UInt16)i;
            setflag_nz(i);
        }
        void op__mXBA(Int32 i)
        {
            i = r_AA >> 8;
            r_AA = (UInt16)(r_A << 8);
            r_A = (UInt16)(i & 0xff);
            setflag_nz(i << 8);
        }

        void op___XCE(Int32 i)
        {
            // TODO: Full support of e=1
            bool c = getflag_c();
            bool e = getflag_e();
            if (c)
                setflag_e(-1);
            else
                setflag_e(0);
            if (e)
                setflag_c(-1);
            else
                setflag_c(0);
        }

        #endregion
    }
}
