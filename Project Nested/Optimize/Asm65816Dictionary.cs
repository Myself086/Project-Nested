using Project_Nested.Injection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize
{
    static class Asm65816Dictionary
    {
        static OpcodeDescription[] _opcodes;
        static OpcodeDescription[] opcodes { get => Init(ref _opcodes, InitOpcodes); }

        static int[] _removeIndexX;
        static int[] removeIndexX { get => Init(ref _removeIndexX, InitRemoveIndexX); }

        static int[] _removeIndexY;
        static int[] removeIndexY { get => Init(ref _removeIndexY, InitRemoveIndexY); }

        static int[] _removeIndexZeroY;
        static int[] removeIndexZeroY { get => Init(ref _removeIndexZeroY, InitRemoveIndexZeroY); }

        static List<EmulatorCall> _emuCalls;
        static List<EmulatorCall> emuCalls { get => Init(ref _emuCalls, Injector.InitEmulatorCallList); }

        static object locker = new object();

        static T Init<T>(ref T obj, Func<T> func)
        {
            if (obj == null)            // Init only when the object is null
                lock (locker)           // Thread safety during initialization
                    if (obj == null)    // Check if the object is null again in case another thread was stuck on the lock
                        obj = func();   // Initialize
            return obj;
        }

        public static void Reset()
        {
            _emuCalls = null;
        }

        static OpcodeDescription[] InitOpcodes()
        {
            var opcodes = new OpcodeDescription[0x1000];

            string name;
            FlagAndRegs usage;
            FlagAndRegs change;

            // ADC
            name = "ADC";
            usage = FlagAndRegs.A | FlagAndRegs.Memory | FlagAndRegs.Carry;
            change = FlagAndRegs.A | FlagAndRegs.Negative | FlagAndRegs.Overflow | FlagAndRegs.Zero | FlagAndRegs.Carry;
            DefineOpcode(0x61, new OpcodeDescription(name, OperandType.DpXInd, usage, change));
            DefineOpcode(0x63, new OpcodeDescription(name, OperandType.Sr, usage, change));
            DefineOpcode(0x65, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0x67, new OpcodeDescription(name, OperandType.DpIndLong, usage, change));
            DefineOpcode(0x69, new OpcodeDescription(name, OperandType.ConstM, usage, change));
            DefineOpcode(0x6D, new OpcodeDescription(name, OperandType.Abs, usage, change));
            DefineOpcode(0x6F, new OpcodeDescription(name, OperandType.Long, usage, change));
            DefineOpcode(0x71, new OpcodeDescription(name, OperandType.DpIndY, usage, change));
            DefineOpcode(0x72, new OpcodeDescription(name, OperandType.DpInd, usage, change));
            DefineOpcode(0x73, new OpcodeDescription(name, OperandType.SrIndY, usage, change));
            DefineOpcode(0x75, new OpcodeDescription(name, OperandType.DpX, usage, change));
            DefineOpcode(0x77, new OpcodeDescription(name, OperandType.DpIndLongY, usage, change));
            DefineOpcode(0x79, new OpcodeDescription(name, OperandType.AbsY, usage, change));
            DefineOpcode(0x7D, new OpcodeDescription(name, OperandType.AbsX, usage, change));
            DefineOpcode(0x7F, new OpcodeDescription(name, OperandType.LongX, usage, change));
            // AND
            name = "AND";
            usage = FlagAndRegs.A | FlagAndRegs.Memory;
            change = FlagAndRegs.A | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0x21, new OpcodeDescription(name, OperandType.DpXInd, usage, change));
            DefineOpcode(0x23, new OpcodeDescription(name, OperandType.Sr, usage, change));
            DefineOpcode(0x25, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0x27, new OpcodeDescription(name, OperandType.DpIndLong, usage, change));
            DefineOpcode(0x29, new OpcodeDescription(name, OperandType.ConstM, usage, change));
            DefineOpcode(0x2D, new OpcodeDescription(name, OperandType.Abs, usage, change));
            DefineOpcode(0x2F, new OpcodeDescription(name, OperandType.Long, usage, change));
            DefineOpcode(0x31, new OpcodeDescription(name, OperandType.DpIndY, usage, change));
            DefineOpcode(0x32, new OpcodeDescription(name, OperandType.DpInd, usage, change));
            DefineOpcode(0x33, new OpcodeDescription(name, OperandType.SrIndY, usage, change));
            DefineOpcode(0x35, new OpcodeDescription(name, OperandType.DpX, usage, change));
            DefineOpcode(0x37, new OpcodeDescription(name, OperandType.DpIndLongY, usage, change));
            DefineOpcode(0x39, new OpcodeDescription(name, OperandType.AbsY, usage, change));
            DefineOpcode(0x3D, new OpcodeDescription(name, OperandType.AbsX, usage, change));
            DefineOpcode(0x3F, new OpcodeDescription(name, OperandType.LongX, usage, change));
            // ASL
            name = "ASL";
            usage = FlagAndRegs.Memory;
            change = FlagAndRegs.Negative | FlagAndRegs.Zero | FlagAndRegs.Carry;
            DefineOpcode(0x06, new OpcodeDescription(name, OperandType.Dp, usage, change | FlagAndRegs.Write));
            DefineOpcode(0x0A, new OpcodeDescription(name, OperandType.None, usage | FlagAndRegs.A, change | FlagAndRegs.A));
            DefineOpcode(0x0E, new OpcodeDescription(name, OperandType.Abs, usage, change | FlagAndRegs.Write));
            DefineOpcode(0x16, new OpcodeDescription(name, OperandType.DpX, usage, change | FlagAndRegs.Write));
            DefineOpcode(0x1E, new OpcodeDescription(name, OperandType.AbsX, usage, change | FlagAndRegs.Write));
            // Branches
            {
                usage = FlagAndRegs.None;
                change = FlagAndRegs.PC;
                DefineOpcode(0x90, new OpcodeDescription("BCC", OperandType.Br8, FlagAndRegs.Carry, change));
                DefineOpcode(0xB0, new OpcodeDescription("BCS", OperandType.Br8, FlagAndRegs.Carry, change));
                DefineOpcode(0xF0, new OpcodeDescription("BEQ", OperandType.Br8, FlagAndRegs.Zero, change));
                DefineOpcode(0xD0, new OpcodeDescription("BNE", OperandType.Br8, FlagAndRegs.Zero, change));
                DefineOpcode(0x30, new OpcodeDescription("BMI", OperandType.Br8, FlagAndRegs.Negative, change));
                DefineOpcode(0x10, new OpcodeDescription("BPL", OperandType.Br8, FlagAndRegs.Negative, change));
                DefineOpcode(0x50, new OpcodeDescription("BVC", OperandType.Br8, FlagAndRegs.Overflow, change));
                DefineOpcode(0x70, new OpcodeDescription("BVS", OperandType.Br8, FlagAndRegs.Overflow, change));
                DefineOpcode(0x80, new OpcodeDescription("BRA", OperandType.Br8, FlagAndRegs.None, change | FlagAndRegs.End));
                DefineOpcode(0x82, new OpcodeDescription("BRL", OperandType.Br16, FlagAndRegs.None, change | FlagAndRegs.End));
            }
            // BIT
            name = "BIT";
            usage = FlagAndRegs.A | FlagAndRegs.Memory;
            change = FlagAndRegs.Negative | FlagAndRegs.Overflow | FlagAndRegs.Zero;
            DefineOpcode(0x24, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0x2C, new OpcodeDescription(name, OperandType.Abs, usage, change));
            DefineOpcode(0x34, new OpcodeDescription(name, OperandType.DpX, usage, change));
            DefineOpcode(0x3C, new OpcodeDescription(name, OperandType.AbsX, usage, change));
            DefineOpcode(0x89, new OpcodeDescription(name, OperandType.ConstM, usage, FlagAndRegs.Zero));
            // BRK
            DefineOpcode(0x00, new OpcodeDescription("BRK", OperandType.Break, FlagAndRegs.None, FlagAndRegs.PC | FlagAndRegs.End));
            // CLC
            DefineOpcode(0x18, new OpcodeDescription("CLC", OperandType.None, FlagAndRegs.None, FlagAndRegs.Carry));
            // CLD
            DefineOpcode(0xD8, new OpcodeDescription("CLD", OperandType.None, FlagAndRegs.None, FlagAndRegs.Decimal));
            // CLI
            DefineOpcode(0x58, new OpcodeDescription("CLI", OperandType.None, FlagAndRegs.None, FlagAndRegs.Interrupt));
            // CLV
            DefineOpcode(0xB8, new OpcodeDescription("CLV", OperandType.None, FlagAndRegs.None, FlagAndRegs.Overflow));
            // CMP
            name = "CMP";
            usage = FlagAndRegs.A | FlagAndRegs.Memory;
            change = FlagAndRegs.Negative | FlagAndRegs.Overflow | FlagAndRegs.Zero | FlagAndRegs.Carry;
            DefineOpcode(0xC1, new OpcodeDescription(name, OperandType.DpXInd, usage, change));
            DefineOpcode(0xC3, new OpcodeDescription(name, OperandType.Sr, usage, change));
            DefineOpcode(0xC5, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0xC7, new OpcodeDescription(name, OperandType.DpIndLong, usage, change));
            DefineOpcode(0xC9, new OpcodeDescription(name, OperandType.ConstM, usage, change));
            DefineOpcode(0xCD, new OpcodeDescription(name, OperandType.Abs, usage, change));
            DefineOpcode(0xCF, new OpcodeDescription(name, OperandType.Long, usage, change));
            DefineOpcode(0xD1, new OpcodeDescription(name, OperandType.DpIndY, usage, change));
            DefineOpcode(0xD2, new OpcodeDescription(name, OperandType.DpInd, usage, change));
            DefineOpcode(0xD3, new OpcodeDescription(name, OperandType.SrIndY, usage, change));
            DefineOpcode(0xD5, new OpcodeDescription(name, OperandType.DpX, usage, change));
            DefineOpcode(0xD7, new OpcodeDescription(name, OperandType.DpIndLongY, usage, change));
            DefineOpcode(0xD9, new OpcodeDescription(name, OperandType.AbsY, usage, change));
            DefineOpcode(0xDD, new OpcodeDescription(name, OperandType.AbsX, usage, change));
            DefineOpcode(0xDF, new OpcodeDescription(name, OperandType.LongX, usage, change));
            // COP
            DefineOpcode(0x02, new OpcodeDescription("COP", OperandType.Break, FlagAndRegs.None, FlagAndRegs.PC | FlagAndRegs.End));
            // CPX
            name = "CPX";
            usage = FlagAndRegs.X | FlagAndRegs.Index;
            change = FlagAndRegs.Negative | FlagAndRegs.Overflow | FlagAndRegs.Zero | FlagAndRegs.Carry;
            DefineOpcode(0xE0, new OpcodeDescription(name, OperandType.ConstX, usage, change));
            DefineOpcode(0xE4, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0xEC, new OpcodeDescription(name, OperandType.Abs, usage, change));
            // CPY
            name = "CPY";
            usage = FlagAndRegs.Y | FlagAndRegs.Index;
            change = FlagAndRegs.Negative | FlagAndRegs.Overflow | FlagAndRegs.Zero | FlagAndRegs.Carry;
            DefineOpcode(0xC0, new OpcodeDescription(name, OperandType.ConstX, usage, change));
            DefineOpcode(0xC4, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0xCC, new OpcodeDescription(name, OperandType.Abs, usage, change));
            // DEC
            name = "DEC";
            usage = FlagAndRegs.Memory;
            change = FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0x3A, new OpcodeDescription(name, OperandType.None, usage | FlagAndRegs.A, change | FlagAndRegs.A));
            DefineOpcode(0xC6, new OpcodeDescription(name, OperandType.Dp, usage, change | FlagAndRegs.Write));
            DefineOpcode(0xCE, new OpcodeDescription(name, OperandType.Abs, usage, change | FlagAndRegs.Write));
            DefineOpcode(0xD6, new OpcodeDescription(name, OperandType.DpX, usage, change | FlagAndRegs.Write));
            DefineOpcode(0xDE, new OpcodeDescription(name, OperandType.AbsX, usage, change | FlagAndRegs.Write));
            // DEX
            name = "DEX";
            usage = FlagAndRegs.X | FlagAndRegs.Index;
            change = FlagAndRegs.X | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0xCA, new OpcodeDescription(name, OperandType.None, usage, change));
            // DEY
            name = "DEY";
            usage = FlagAndRegs.Y | FlagAndRegs.Index;
            change = FlagAndRegs.Y | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0x88, new OpcodeDescription(name, OperandType.None, usage, change));
            // EOR
            name = "EOR";
            usage = FlagAndRegs.A | FlagAndRegs.Memory;
            change = FlagAndRegs.A | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0x41, new OpcodeDescription(name, OperandType.DpXInd, usage, change));
            DefineOpcode(0x43, new OpcodeDescription(name, OperandType.Sr, usage, change));
            DefineOpcode(0x45, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0x47, new OpcodeDescription(name, OperandType.DpIndLong, usage, change));
            DefineOpcode(0x49, new OpcodeDescription(name, OperandType.ConstM, usage, change));
            DefineOpcode(0x4D, new OpcodeDescription(name, OperandType.Abs, usage, change));
            DefineOpcode(0x4F, new OpcodeDescription(name, OperandType.Long, usage, change));
            DefineOpcode(0x51, new OpcodeDescription(name, OperandType.DpIndY, usage, change));
            DefineOpcode(0x52, new OpcodeDescription(name, OperandType.DpInd, usage, change));
            DefineOpcode(0x53, new OpcodeDescription(name, OperandType.SrIndY, usage, change));
            DefineOpcode(0x55, new OpcodeDescription(name, OperandType.DpX, usage, change));
            DefineOpcode(0x57, new OpcodeDescription(name, OperandType.DpIndLongY, usage, change));
            DefineOpcode(0x59, new OpcodeDescription(name, OperandType.AbsY, usage, change));
            DefineOpcode(0x5D, new OpcodeDescription(name, OperandType.AbsX, usage, change));
            DefineOpcode(0x5F, new OpcodeDescription(name, OperandType.LongX, usage, change));
            // INC
            name = "INC";
            usage = FlagAndRegs.Memory;
            change = FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0x1A, new OpcodeDescription(name, OperandType.None, usage | FlagAndRegs.A, change | FlagAndRegs.A));
            DefineOpcode(0xE6, new OpcodeDescription(name, OperandType.Dp, usage, change | FlagAndRegs.Write));
            DefineOpcode(0xEE, new OpcodeDescription(name, OperandType.Abs, usage, change | FlagAndRegs.Write));
            DefineOpcode(0xF6, new OpcodeDescription(name, OperandType.DpX, usage, change | FlagAndRegs.Write));
            DefineOpcode(0xFE, new OpcodeDescription(name, OperandType.AbsX, usage, change | FlagAndRegs.Write));
            // INX
            name = "INX";
            usage = FlagAndRegs.X | FlagAndRegs.Index;
            change = FlagAndRegs.X | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0xE8, new OpcodeDescription(name, OperandType.None, usage, change));
            // INY
            name = "INY";
            usage = FlagAndRegs.Y | FlagAndRegs.Index;
            change = FlagAndRegs.Y | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0xC8, new OpcodeDescription(name, OperandType.None, usage, change));
            // JMP
            name = "JMP";
            usage = FlagAndRegs.None;
            change = FlagAndRegs.PC | FlagAndRegs.End;
            DefineOpcode(0x4C, new OpcodeDescription(name, OperandType.Jmp16, usage, change));
            DefineOpcode(0x5C, new OpcodeDescription(name, OperandType.Jmp24, usage, change));
            DefineOpcode(0x6C, new OpcodeDescription(name, OperandType.JmpInd, usage, change));
            DefineOpcode(0x7C, new OpcodeDescription(name, OperandType.JmpIndX, usage, change));
            DefineOpcode(0xDC, new OpcodeDescription(name, OperandType.JmpIndLong, usage, change));
            // JSR (NOTE: SP is used here but assumed to be untouched for the next instruction)
            name = "JSR";
            usage = FlagAndRegs.None;
            change = FlagAndRegs.PC;
            DefineOpcode(0x20, new OpcodeDescription(name, OperandType.Jmp16, usage, change));
            DefineOpcode(0x22, new OpcodeDescription(name, OperandType.Jmp24, usage, change));
            DefineOpcode(0xFC, new OpcodeDescription(name, OperandType.JmpIndX, usage, change));
            // LDA
            name = "LDA";
            usage = FlagAndRegs.Memory;
            change = FlagAndRegs.A | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0xA1, new OpcodeDescription(name, OperandType.DpXInd, usage, change));
            DefineOpcode(0xA3, new OpcodeDescription(name, OperandType.Sr, usage, change));
            DefineOpcode(0xA5, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0xA7, new OpcodeDescription(name, OperandType.DpIndLong, usage, change));
            DefineOpcode(0xA9, new OpcodeDescription(name, OperandType.ConstM, usage, change));
            DefineOpcode(0xAD, new OpcodeDescription(name, OperandType.Abs, usage, change));
            DefineOpcode(0xAF, new OpcodeDescription(name, OperandType.Long, usage, change));
            DefineOpcode(0xB1, new OpcodeDescription(name, OperandType.DpIndY, usage, change));
            DefineOpcode(0xB2, new OpcodeDescription(name, OperandType.DpInd, usage, change));
            DefineOpcode(0xB3, new OpcodeDescription(name, OperandType.SrIndY, usage, change));
            DefineOpcode(0xB5, new OpcodeDescription(name, OperandType.DpX, usage, change));
            DefineOpcode(0xB7, new OpcodeDescription(name, OperandType.DpIndLongY, usage, change));
            DefineOpcode(0xB9, new OpcodeDescription(name, OperandType.AbsY, usage, change));
            DefineOpcode(0xBD, new OpcodeDescription(name, OperandType.AbsX, usage, change));
            DefineOpcode(0xBF, new OpcodeDescription(name, OperandType.LongX, usage, change));
            // LDX
            name = "LDX";
            usage = FlagAndRegs.Index;
            change = FlagAndRegs.X | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0xA2, new OpcodeDescription(name, OperandType.ConstX, usage, change));
            DefineOpcode(0xA6, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0xAE, new OpcodeDescription(name, OperandType.Abs, usage, change));
            DefineOpcode(0xB6, new OpcodeDescription(name, OperandType.DpY, usage, change));
            DefineOpcode(0xBE, new OpcodeDescription(name, OperandType.AbsY, usage, change));
            // LDY
            name = "LDY";
            usage = FlagAndRegs.Index;
            change = FlagAndRegs.Y | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0xA0, new OpcodeDescription(name, OperandType.ConstX, usage, change));
            DefineOpcode(0xA4, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0xAC, new OpcodeDescription(name, OperandType.Abs, usage, change));
            DefineOpcode(0xB4, new OpcodeDescription(name, OperandType.DpX, usage, change));
            DefineOpcode(0xBC, new OpcodeDescription(name, OperandType.AbsX, usage, change));
            // LSR
            name = "LSR";
            usage = FlagAndRegs.Memory;
            change = FlagAndRegs.Negative | FlagAndRegs.Zero | FlagAndRegs.Carry;
            DefineOpcode(0x46, new OpcodeDescription(name, OperandType.Dp, usage, change | FlagAndRegs.Write));
            DefineOpcode(0x4A, new OpcodeDescription(name, OperandType.None, usage | FlagAndRegs.A, change | FlagAndRegs.A));
            DefineOpcode(0x4E, new OpcodeDescription(name, OperandType.Abs, usage, change | FlagAndRegs.Write));
            DefineOpcode(0x56, new OpcodeDescription(name, OperandType.DpX, usage, change | FlagAndRegs.Write));
            DefineOpcode(0x5E, new OpcodeDescription(name, OperandType.AbsX, usage, change | FlagAndRegs.Write));
            // MVN
            name = "MVN";
            usage = FlagAndRegs.A | FlagAndRegs.Ah | FlagAndRegs.X | FlagAndRegs.Y | FlagAndRegs.Index;
            change = FlagAndRegs.A | FlagAndRegs.Ah | FlagAndRegs.X | FlagAndRegs.Y | FlagAndRegs.Index | FlagAndRegs.DB | FlagAndRegs.Write;
            DefineOpcode(0x54, new OpcodeDescription(name, OperandType.Move, usage, change));
            // MVP
            name = "MVP";
            usage = FlagAndRegs.A | FlagAndRegs.Ah | FlagAndRegs.X | FlagAndRegs.Y | FlagAndRegs.Index;
            change = FlagAndRegs.A | FlagAndRegs.Ah | FlagAndRegs.X | FlagAndRegs.Y | FlagAndRegs.Index | FlagAndRegs.DB | FlagAndRegs.Write;
            DefineOpcode(0x44, new OpcodeDescription(name, OperandType.Move, usage, change));
            // NOP
            DefineOpcode(0xEA, new OpcodeDescription("NOP", OperandType.None, FlagAndRegs.None, FlagAndRegs.None));
            // ORA
            name = "ORA";
            usage = FlagAndRegs.A | FlagAndRegs.Memory;
            change = FlagAndRegs.A | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0x01, new OpcodeDescription(name, OperandType.DpXInd, usage, change));
            DefineOpcode(0x03, new OpcodeDescription(name, OperandType.Sr, usage, change));
            DefineOpcode(0x05, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0x07, new OpcodeDescription(name, OperandType.DpIndLong, usage, change));
            DefineOpcode(0x09, new OpcodeDescription(name, OperandType.ConstM, usage, change));
            DefineOpcode(0x0D, new OpcodeDescription(name, OperandType.Abs, usage, change));
            DefineOpcode(0x0F, new OpcodeDescription(name, OperandType.Long, usage, change));
            DefineOpcode(0x11, new OpcodeDescription(name, OperandType.DpIndY, usage, change));
            DefineOpcode(0x12, new OpcodeDescription(name, OperandType.DpInd, usage, change));
            DefineOpcode(0x13, new OpcodeDescription(name, OperandType.SrIndY, usage, change));
            DefineOpcode(0x15, new OpcodeDescription(name, OperandType.DpX, usage, change));
            DefineOpcode(0x17, new OpcodeDescription(name, OperandType.DpIndLongY, usage, change));
            DefineOpcode(0x19, new OpcodeDescription(name, OperandType.AbsY, usage, change));
            DefineOpcode(0x1D, new OpcodeDescription(name, OperandType.AbsX, usage, change));
            DefineOpcode(0x1F, new OpcodeDescription(name, OperandType.LongX, usage, change));
            // PEA
            DefineOpcode(0xF4, new OpcodeDescription("PEA", OperandType.Abs, FlagAndRegs.SP, FlagAndRegs.SP | FlagAndRegs.Write));
            // PEI
            DefineOpcode(0xD4, new OpcodeDescription("PEI", OperandType.Dp, FlagAndRegs.SP | FlagAndRegs.DP, FlagAndRegs.SP | FlagAndRegs.Write));
            // PER
            DefineOpcode(0x62, new OpcodeDescription("PER", OperandType.Br16, FlagAndRegs.SP, FlagAndRegs.SP | FlagAndRegs.Write));
            // PHA
            DefineOpcode(0x48, new OpcodeDescription("PHA", OperandType.None, FlagAndRegs.SP | FlagAndRegs.A, FlagAndRegs.SP | FlagAndRegs.Write));
            // PHB
            DefineOpcode(0x8B, new OpcodeDescription("PHB", OperandType.None, FlagAndRegs.SP | FlagAndRegs.DB, FlagAndRegs.SP | FlagAndRegs.Write));
            // PHD
            DefineOpcode(0x0B, new OpcodeDescription("PHD", OperandType.None, FlagAndRegs.SP | FlagAndRegs.DP, FlagAndRegs.SP | FlagAndRegs.Write));
            // PHK
            DefineOpcode(0x4B, new OpcodeDescription("PHK", OperandType.None, FlagAndRegs.SP, FlagAndRegs.SP | FlagAndRegs.Write));
            // PHP
            DefineOpcode(0x08, new OpcodeDescription("PHP", OperandType.None, FlagAndRegs.SP | FlagAndRegs.P | FlagAndRegs.FlagMask, FlagAndRegs.SP | FlagAndRegs.Write));
            // PHX
            DefineOpcode(0xDA, new OpcodeDescription("PHX", OperandType.None, FlagAndRegs.SP | FlagAndRegs.X, FlagAndRegs.SP | FlagAndRegs.Write));
            // PHY
            DefineOpcode(0x5A, new OpcodeDescription("PHY", OperandType.None, FlagAndRegs.SP | FlagAndRegs.Y, FlagAndRegs.SP | FlagAndRegs.Write));
            // Pulls
            {
                name = null;
                usage = FlagAndRegs.SP;
                change = FlagAndRegs.SP | FlagAndRegs.Negative | FlagAndRegs.Zero;
                DefineOpcode(0x68, new OpcodeDescription("PLA", OperandType.None, usage, change | FlagAndRegs.A));
                DefineOpcode(0xAB, new OpcodeDescription("PLB", OperandType.None, usage, change | FlagAndRegs.DB));
                DefineOpcode(0x2B, new OpcodeDescription("PLD", OperandType.None, usage, change | FlagAndRegs.DP));
                DefineOpcode(0x28, new OpcodeDescription("PLP", OperandType.None, usage, change | FlagAndRegs.P | FlagAndRegs.FlagMask));
                DefineOpcode(0xFA, new OpcodeDescription("PLX", OperandType.None, usage, change | FlagAndRegs.X));
                DefineOpcode(0x7A, new OpcodeDescription("PLY", OperandType.None, usage, change | FlagAndRegs.Y));
            }
            // REP
            DefineOpcode(0xC2, new OpcodeDescription("REP", OperandType.Const8, FlagAndRegs.None, FlagAndRegs.Exception));
            // ROL
            name = "ROL";
            usage = FlagAndRegs.Carry | FlagAndRegs.Memory;
            change = FlagAndRegs.Negative | FlagAndRegs.Zero | FlagAndRegs.Carry;
            DefineOpcode(0x26, new OpcodeDescription(name, OperandType.Dp, usage, change | FlagAndRegs.Write));
            DefineOpcode(0x2A, new OpcodeDescription(name, OperandType.None, usage | FlagAndRegs.A, change | FlagAndRegs.A));
            DefineOpcode(0x2E, new OpcodeDescription(name, OperandType.Abs, usage, change | FlagAndRegs.Write));
            DefineOpcode(0x36, new OpcodeDescription(name, OperandType.DpX, usage, change | FlagAndRegs.Write));
            DefineOpcode(0x3E, new OpcodeDescription(name, OperandType.AbsX, usage, change | FlagAndRegs.Write));
            // ROR
            name = "ROR";
            usage = FlagAndRegs.Carry | FlagAndRegs.Memory;
            change = FlagAndRegs.Negative | FlagAndRegs.Zero | FlagAndRegs.Carry;
            DefineOpcode(0x66, new OpcodeDescription(name, OperandType.Dp, usage, change | FlagAndRegs.Write));
            DefineOpcode(0x6A, new OpcodeDescription(name, OperandType.None, usage | FlagAndRegs.A, change | FlagAndRegs.A));
            DefineOpcode(0x6E, new OpcodeDescription(name, OperandType.Abs, usage, change | FlagAndRegs.Write));
            DefineOpcode(0x76, new OpcodeDescription(name, OperandType.DpX, usage, change | FlagAndRegs.Write));
            DefineOpcode(0x7E, new OpcodeDescription(name, OperandType.AbsX, usage, change | FlagAndRegs.Write));
            // RTI
            name = "RTI";
            usage = FlagAndRegs.SP;
            change = FlagAndRegs.SP | FlagAndRegs.P | FlagAndRegs.End;
            DefineOpcode(0x40, new OpcodeDescription(name, OperandType.Return, usage, change));
            // RTL
            name = "RTL";
            usage = FlagAndRegs.SP;
            change = FlagAndRegs.End;
            DefineOpcode(0x6B, new OpcodeDescription(name, OperandType.Return, usage, change));
            // RTS
            name = "RTS";
            usage = FlagAndRegs.SP;
            change = FlagAndRegs.End;
            DefineOpcode(0x60, new OpcodeDescription(name, OperandType.Return, usage, change));
            // SBC
            name = "SBC";
            usage = FlagAndRegs.A | FlagAndRegs.Memory | FlagAndRegs.Carry;
            change = FlagAndRegs.A | FlagAndRegs.Negative | FlagAndRegs.Overflow | FlagAndRegs.Zero | FlagAndRegs.Carry;
            DefineOpcode(0xE1, new OpcodeDescription(name, OperandType.DpXInd, usage, change));
            DefineOpcode(0xE3, new OpcodeDescription(name, OperandType.Sr, usage, change));
            DefineOpcode(0xE5, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0xE7, new OpcodeDescription(name, OperandType.DpIndLong, usage, change));
            DefineOpcode(0xE9, new OpcodeDescription(name, OperandType.ConstM, usage, change));
            DefineOpcode(0xED, new OpcodeDescription(name, OperandType.Abs, usage, change));
            DefineOpcode(0xEF, new OpcodeDescription(name, OperandType.Long, usage, change));
            DefineOpcode(0xF1, new OpcodeDescription(name, OperandType.DpIndY, usage, change));
            DefineOpcode(0xF2, new OpcodeDescription(name, OperandType.DpInd, usage, change));
            DefineOpcode(0xF3, new OpcodeDescription(name, OperandType.SrIndY, usage, change));
            DefineOpcode(0xF5, new OpcodeDescription(name, OperandType.DpX, usage, change));
            DefineOpcode(0xF7, new OpcodeDescription(name, OperandType.DpIndLongY, usage, change));
            DefineOpcode(0xF9, new OpcodeDescription(name, OperandType.AbsY, usage, change));
            DefineOpcode(0xFD, new OpcodeDescription(name, OperandType.AbsX, usage, change));
            DefineOpcode(0xFF, new OpcodeDescription(name, OperandType.LongX, usage, change));
            // SEC
            DefineOpcode(0x38, new OpcodeDescription("SEC", OperandType.None, FlagAndRegs.None, FlagAndRegs.Carry));
            // SED
            DefineOpcode(0xF8, new OpcodeDescription("SED", OperandType.None, FlagAndRegs.None, FlagAndRegs.Decimal));
            // SEI
            DefineOpcode(0x78, new OpcodeDescription("SEI", OperandType.None, FlagAndRegs.None, FlagAndRegs.Interrupt));
            // SEP
            DefineOpcode(0xE2, new OpcodeDescription("SEP", OperandType.Const8, FlagAndRegs.None, FlagAndRegs.Exception));
            // STA
            name = "STA";
            usage = FlagAndRegs.A | FlagAndRegs.Memory;
            change = FlagAndRegs.Write;
            DefineOpcode(0x81, new OpcodeDescription(name, OperandType.DpXInd, usage, change));
            DefineOpcode(0x83, new OpcodeDescription(name, OperandType.Sr, usage, change));
            DefineOpcode(0x85, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0x87, new OpcodeDescription(name, OperandType.DpIndLong, usage, change));
            DefineOpcode(0x8D, new OpcodeDescription(name, OperandType.Abs, usage, change));
            DefineOpcode(0x8F, new OpcodeDescription(name, OperandType.Long, usage, change));
            DefineOpcode(0x91, new OpcodeDescription(name, OperandType.DpIndY, usage, change));
            DefineOpcode(0x92, new OpcodeDescription(name, OperandType.DpInd, usage, change));
            DefineOpcode(0x93, new OpcodeDescription(name, OperandType.SrIndY, usage, change));
            DefineOpcode(0x95, new OpcodeDescription(name, OperandType.DpX, usage, change));
            DefineOpcode(0x97, new OpcodeDescription(name, OperandType.DpIndLongY, usage, change));
            DefineOpcode(0x99, new OpcodeDescription(name, OperandType.AbsY, usage, change));
            DefineOpcode(0x9D, new OpcodeDescription(name, OperandType.AbsX, usage, change));
            DefineOpcode(0x9F, new OpcodeDescription(name, OperandType.LongX, usage, change));
            // STP
            name = "STP";
            usage = FlagAndRegs.None;
            change = FlagAndRegs.End;
            DefineOpcode(0xDB, new OpcodeDescription(name, OperandType.None, usage, change));
            // STX
            name = "STX";
            usage = FlagAndRegs.X | FlagAndRegs.Index;
            change = FlagAndRegs.Write;
            DefineOpcode(0x86, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0x8E, new OpcodeDescription(name, OperandType.Abs, usage, change));
            DefineOpcode(0x96, new OpcodeDescription(name, OperandType.DpY, usage, change));
            // STY
            name = "STY";
            usage = FlagAndRegs.Y | FlagAndRegs.Index;
            change = FlagAndRegs.Write;
            DefineOpcode(0x84, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0x8C, new OpcodeDescription(name, OperandType.Abs, usage, change));
            DefineOpcode(0x94, new OpcodeDescription(name, OperandType.DpX, usage, change));
            // STZ
            name = "STZ";
            usage = FlagAndRegs.Memory;
            change = FlagAndRegs.Write;
            DefineOpcode(0x64, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0x74, new OpcodeDescription(name, OperandType.DpX, usage, change));
            DefineOpcode(0x9C, new OpcodeDescription(name, OperandType.Abs, usage, change));
            DefineOpcode(0x9E, new OpcodeDescription(name, OperandType.AbsX, usage, change));
            // TAX
            name = "TAX";
            usage = FlagAndRegs.A | FlagAndRegs.Memory | FlagAndRegs.Index;
            change = FlagAndRegs.X | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0xAA, new OpcodeDescription(name, OperandType.None, usage, change));
            // TAY
            name = "TAY";
            usage = FlagAndRegs.A | FlagAndRegs.Memory | FlagAndRegs.Index;
            change = FlagAndRegs.Y | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0xA8, new OpcodeDescription(name, OperandType.None, usage, change));
            // TCD
            name = "TCD";
            usage = FlagAndRegs.A | FlagAndRegs.Ah;
            change = FlagAndRegs.DP | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0x5B, new OpcodeDescription(name, OperandType.None, usage, change));
            // TCS
            name = "TCS";
            usage = FlagAndRegs.A | FlagAndRegs.Ah;
            change = FlagAndRegs.SP | FlagAndRegs.InlineUnableSrc;
            DefineOpcode(0x1B, new OpcodeDescription(name, OperandType.None, usage, change));
            // TDC
            name = "TDC";
            usage = FlagAndRegs.DP;
            change = FlagAndRegs.A | FlagAndRegs.Ah | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0x7B, new OpcodeDescription(name, OperandType.None, usage, change));
            // TRB
            name = "TRB";
            usage = FlagAndRegs.A | FlagAndRegs.Memory;
            change = FlagAndRegs.Zero | FlagAndRegs.Write;
            DefineOpcode(0x14, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0x1C, new OpcodeDescription(name, OperandType.Abs, usage, change));
            // TSB
            name = "TSB";
            usage = FlagAndRegs.A | FlagAndRegs.Memory;
            change = FlagAndRegs.Zero | FlagAndRegs.Write;
            DefineOpcode(0x04, new OpcodeDescription(name, OperandType.Dp, usage, change));
            DefineOpcode(0x0C, new OpcodeDescription(name, OperandType.Abs, usage, change));
            // TSC
            name = "TSC";
            usage = FlagAndRegs.SP;
            change = FlagAndRegs.A | FlagAndRegs.Ah | FlagAndRegs.Negative | FlagAndRegs.Zero | FlagAndRegs.InlineUnableSrc;
            DefineOpcode(0x3B, new OpcodeDescription(name, OperandType.None, usage, change));
            // TSX
            name = "TSX";
            usage = FlagAndRegs.SP | FlagAndRegs.Index;
            change = FlagAndRegs.X | FlagAndRegs.Negative | FlagAndRegs.Zero | FlagAndRegs.InlineUnableSrc;
            DefineOpcode(0xBA, new OpcodeDescription(name, OperandType.None, usage, change));
            // TXA
            name = "TXA";
            usage = FlagAndRegs.X | FlagAndRegs.Memory | FlagAndRegs.Index;
            change = FlagAndRegs.A | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0x8A, new OpcodeDescription(name, OperandType.None, usage, change));
            // TXS
            name = "TXS";
            usage = FlagAndRegs.X | FlagAndRegs.Index;
            change = FlagAndRegs.SP | FlagAndRegs.InlineUnableSrc;
            DefineOpcode(0x9A, new OpcodeDescription(name, OperandType.None, usage, change));
            // TXY
            name = "TXY";
            usage = FlagAndRegs.X | FlagAndRegs.Index;
            change = FlagAndRegs.Y | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0x9B, new OpcodeDescription(name, OperandType.None, usage, change));
            // TYA
            name = "TYA";
            usage = FlagAndRegs.Y | FlagAndRegs.Memory | FlagAndRegs.Index;
            change = FlagAndRegs.A | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0x98, new OpcodeDescription(name, OperandType.None, usage, change));
            // TYX
            name = "TYX";
            usage = FlagAndRegs.Y | FlagAndRegs.Index;
            change = FlagAndRegs.X | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0xBB, new OpcodeDescription(name, OperandType.None, usage, change));
            // WAI
            name = "WAI";
            usage = FlagAndRegs.None;
            change = FlagAndRegs.Exception;
            DefineOpcode(0xCB, new OpcodeDescription(name, OperandType.None, usage, change));
            // WDM
            name = "WDM";
            usage = FlagAndRegs.None;
            change = FlagAndRegs.Exception;
            DefineOpcode(0x42, new OpcodeDescription(name, OperandType.Const8, usage, change));
            // XBA
            name = "XBA";
            usage = FlagAndRegs.A | FlagAndRegs.Ah;
            change = FlagAndRegs.A | FlagAndRegs.Ah | FlagAndRegs.Negative | FlagAndRegs.Zero;
            DefineOpcode(0xEB, new OpcodeDescription(name, OperandType.None, usage, change));
            // XCE
            name = "XCE";
            usage = FlagAndRegs.Carry | FlagAndRegs.Memory | FlagAndRegs.Index;
            change = FlagAndRegs.Carry | FlagAndRegs.Memory | FlagAndRegs.Index;
            DefineOpcode(0xFB, new OpcodeDescription(name, OperandType.None, usage, change));

            // Intermediate language starts here ...

            // Label
            name = "";
            usage = FlagAndRegs.None;
            change = FlagAndRegs.Marker;
            DefineOpcode((int)InstructionSet.Label, new OpcodeDescription(name, OperandType.Label, usage, change));
            // JMP label
            name = "JMP";
            usage = FlagAndRegs.None;
            change = FlagAndRegs.PC | FlagAndRegs.End;
            DefineOpcode((int)InstructionSet.JMP_Label, new OpcodeDescription(name, OperandType.JmpLabel, usage, change));
            // Branch Label
            {
                usage = FlagAndRegs.None;
                change = FlagAndRegs.PC;
                DefineOpcode((int)InstructionSet.BCC_Label, new OpcodeDescription("BCC", OperandType.BrLabel, FlagAndRegs.Carry, change));
                DefineOpcode((int)InstructionSet.BCS_Label, new OpcodeDescription("BCS", OperandType.BrLabel, FlagAndRegs.Carry, change));
                DefineOpcode((int)InstructionSet.BEQ_Label, new OpcodeDescription("BEQ", OperandType.BrLabel, FlagAndRegs.Zero, change));
                DefineOpcode((int)InstructionSet.BNE_Label, new OpcodeDescription("BNE", OperandType.BrLabel, FlagAndRegs.Zero, change));
                DefineOpcode((int)InstructionSet.BMI_Label, new OpcodeDescription("BMI", OperandType.BrLabel, FlagAndRegs.Negative, change));
                DefineOpcode((int)InstructionSet.BPL_Label, new OpcodeDescription("BPL", OperandType.BrLabel, FlagAndRegs.Negative, change));
                DefineOpcode((int)InstructionSet.BVC_Label, new OpcodeDescription("BVC", OperandType.BrLabel, FlagAndRegs.Overflow, change));
                DefineOpcode((int)InstructionSet.BVS_Label, new OpcodeDescription("BVS", OperandType.BrLabel, FlagAndRegs.Overflow, change));
                DefineOpcode((int)InstructionSet.BRA_Label, new OpcodeDescription("BRA", OperandType.BrLabel, FlagAndRegs.None, change | FlagAndRegs.End));
            }
            // Jsr to emulator
            usage = FlagAndRegs.None;
            change = FlagAndRegs.PC;
            DefineOpcode((int)InstructionSet.JSR_Emu, new OpcodeDescription("JSR", OperandType.CallEmu, usage, change));
            DefineOpcode((int)InstructionSet.JMP_Emu, new OpcodeDescription("JMP", OperandType.JumpEmu, usage, change | FlagAndRegs.End));
            // JsrNes
            usage = FlagAndRegs.None;
            change = FlagAndRegs.PC | FlagAndRegs.InlineUnableSrc;
            DefineOpcode((int)InstructionSet.JSR_Nes, new OpcodeDescription("JSR", OperandType.CallNes, usage, change));
            DefineOpcode((int)InstructionSet.JMP_Nes, new OpcodeDescription("JMP", OperandType.CallNes, usage, change | FlagAndRegs.End));
            DefineOpcode((int)InstructionSet.JSR_Nes_Static, new OpcodeDescription("JSR!", OperandType.CallNes, usage, change | FlagAndRegs.CanInlineDest));
            DefineOpcode((int)InstructionSet.JMP_Nes_Static, new OpcodeDescription("JMP!", OperandType.CallNes, usage, change | FlagAndRegs.End | FlagAndRegs.CanInlineDest));

            // Return marker
            DefineOpcode((int)InstructionSet.ReturnMarker, new OpcodeDescription(".returnmark", OperandType.None, FlagAndRegs.None, FlagAndRegs.None));

            return opcodes;

            void DefineOpcode(int index, OpcodeDescription desc)
            {
                // Fix name
                if (desc.name == null)
                    desc.name = string.Empty;

                if (index < 0x100)
                {
                    if (opcodes[index + 0x000].name != null)
                        throw new Exception("Opcode already defined.");

                    // Regular opcodes
                    opcodes[index + 0x000] = new OpcodeDescription(desc, 0x00);
                    opcodes[index + 0x100] = new OpcodeDescription(desc, 0x10);
                    opcodes[index + 0x200] = new OpcodeDescription(desc, 0x20);
                    opcodes[index + 0x300] = new OpcodeDescription(desc, 0x30);
                }
                else if ((index >> 8) == 0x4)   // 0x400-0x4ff
                {
                    if (opcodes[index + 0x000].name != null)
                        throw new Exception("Opcode already defined.");

                    // Modified opcodes
                    opcodes[index + 0x000] = new OpcodeDescription(desc, 0x00);
                    opcodes[index + 0x100] = new OpcodeDescription(desc, 0x10);
                    opcodes[index + 0x200] = new OpcodeDescription(desc, 0x20);
                    opcodes[index + 0x300] = new OpcodeDescription(desc, 0x30);
                }
                else if (index >= 0x800)
                {
                    // Intermediate language (IL) opcodes
                    opcodes[index] = desc;
                }
                else
                {
                    throw new NotImplementedException();
                }
            }
        }

        static int[] InitRemoveIndexX()
        {
            return CreateIndexRemovalTable(new Dictionary<OperandType, OperandType>()
            {
                [OperandType.AbsX] = OperandType.Abs,
                [OperandType.DpX] = OperandType.Dp,
                [OperandType.DpXInd] = OperandType.DpInd,
                [OperandType.LongX] = OperandType.Long,
            });
        }

        static int[] InitRemoveIndexY()
        {
            return CreateIndexRemovalTable(new Dictionary<OperandType, OperandType>()
            {
                [OperandType.AbsY] = OperandType.Abs,
                [OperandType.DpY] = OperandType.Dp,
            });
        }

        static int[] InitRemoveIndexZeroY()
        {
            return CreateIndexRemovalTable(new Dictionary<OperandType, OperandType>()
            {
                [OperandType.AbsY] = OperandType.Abs,
                [OperandType.DpIndLongY] = OperandType.DpIndLong,
                [OperandType.DpIndY] = OperandType.DpInd,
                [OperandType.DpY] = OperandType.Dp,
            });
        }

        static int[] CreateIndexRemovalTable(Dictionary<OperandType, OperandType> replace)
        {
            var table = new int[0x400];

            for (int i = 0; i < table.Length; i++)
            {
                var mx = i & (int)InstructionSet.mx;
                var oldDesc = GetOpcodeDesc(i, 0);
                var newDesc = oldDesc;

                table[i] = replace.TryGetValue(oldDesc.type, out newDesc.type) ? FindOpcodeIndex(newDesc, i) : -1;
            }

            return table;
        }

        /// <summary>
        /// Generates enum InstructionSet for regular 65816 instructions only
        /// </summary>
        /// <returns></returns>
        public static string GenerateEnum()
        {
            StringBuilder sb = new StringBuilder();

            for (int i = 0x300; i < 0x400; i++)
            {
                var desc = GetOpcodeDesc(i, 0);

                string type = desc.type.ToString();

                sb.AppendLine($"{desc.name}_{type} = 0x{i & 0xff:x2},");
            }

            return sb.ToString();
        }

        public static int FindOpcodeIndex(OpcodeDescription desc, int mx)
        {
            mx = mx & ~0xff;
            for (int u = 0; u < 255; u++)
            {
                var index = mx | u;
                var opcode = opcodes[index];
                if (opcode.type == desc.type && opcode.name == desc.name)
                {
                    return index;
                }
            }
            return -1;
        }

        public static OpcodeDescription GetOpcodeDesc(InstructionSet index, int operand) => GetOpcodeDesc((int)index, operand);
        public static OpcodeDescription GetOpcodeDesc(int index, int operand)
        {
            var rtn = (uint)index < opcodes.Length ? opcodes[index] : new OpcodeDescription();
            if (rtn.type == OperandType.CallEmu)
            {
                var desc = GetEmuCallByID(operand).desc;
                desc.usage |= rtn.usage;
                desc.change |= rtn.change;
                return desc;
            }
            else if (rtn.type == OperandType.JumpEmu)
            {
                var desc = GetEmuCallByID(operand).desc;
                desc.usage |= rtn.usage;
                desc.change |= rtn.change;
                desc.name = "JMP";
                desc.type = OperandType.JumpEmu;
                return desc;
            }
            else
                return rtn;
        }

        public static int GetRemoveIndexX(InstructionSet index) => GetRemoveIndexX((int)index);
        public static int GetRemoveIndexX(int index) => (uint)index < removeIndexX.Length ? removeIndexX[index] : -1;

        public static int GetRemoveIndexY(InstructionSet index) => GetRemoveIndexY((int)index);
        public static int GetRemoveIndexY(int index) => (uint)index < removeIndexY.Length ? removeIndexY[index] : -1;

        public static int GetRemoveIndexZeroY(InstructionSet index) => GetRemoveIndexZeroY((int)index);
        public static int GetRemoveIndexZeroY(int index) => (uint)index < removeIndexZeroY.Length ? removeIndexZeroY[index] : -1;

        public static EmulatorCall GetEmuCall(int snesAddr) => emuCalls.Find(e => e.address == snesAddr);
        public static EmulatorCall GetEmuCallByID(int id) => ((uint)id < emuCalls.Count ? emuCalls[id] : new EmulatorCall());
        public static EmulatorCall GetEmuCall(string name) => emuCalls.Find(e => e.name == name);
    }
}
