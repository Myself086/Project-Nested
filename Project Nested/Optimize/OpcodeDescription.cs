using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize
{
    public struct OpcodeDescription
    {
        public string name;
        public OperandType type;

        public FlagAndRegs usage;
        public FlagAndRegs change;

        public int byteCount;

        //public bool m { get => (usage & 0x20) != 0; }
        //public bool x { get => (usage & 0x10) != 0; }

        public OpcodeDescription(string name, OperandType type, FlagAndRegs usage, FlagAndRegs change)
        {
            this = new OpcodeDescription()
            {
                name = name,
                type = type,
                usage = usage,
                change = change,
            };
            ApplyTypeAttributes();
        }

        public OpcodeDescription(OpcodeDescription desc, int mxMask)
        {
            this = desc;
            mxMask ^= 0x30;

            // Adjust name and a few other things for 16-bit mode
            switch (mxMask & (int)usage & 0x30)
            {
                case 0x10:
                    if (type == OperandType.ConstM)
                        type = OperandType.Const16;
                    name += "x";
                    break;
                case 0x20:
                    if (type == OperandType.ConstX)
                        type = OperandType.Const16;
                    name += "m";
                    break;
                case 0x30:
                    if (type == OperandType.ConstM || type == OperandType.ConstX)
                        type = OperandType.Const16;
                    name += "mx";
                    break;
            }

            // If either variable length constant were unchanged, assume 8-bit constant instead
            if (type == OperandType.ConstM || type == OperandType.ConstX)
                type = OperandType.Const8;

            ApplyTypeAttributes();
        }

        private void ApplyTypeAttributes()
        {
            // Fix 'usage' and 'change' flags based on operand type
            switch (type)
            {
                case OperandType.Unknown:
                default:
                    throw new NotImplementedException();
                case OperandType.None:
                case OperandType.Const8:
                case OperandType.Const16:
                case OperandType.ConstM:
                case OperandType.ConstX:
                case OperandType.Abs:
                case OperandType.Long:
                case OperandType.Br8:
                case OperandType.Br16:
                case OperandType.Jmp16:
                case OperandType.JmpInd:
                case OperandType.JmpIndLong:
                case OperandType.Break:
                case OperandType.Move:
                case OperandType.Label:
                case OperandType.JmpLabel:
                case OperandType.BrLabel:
                case OperandType.CallEmu:        // This one has its own flags based on operand
                    // No adjustement needed here
                    break;
                case OperandType.Dp:
                case OperandType.DpInd:
                case OperandType.DpIndLong:
                    usage |= FlagAndRegs.DP;
                    break;
                case OperandType.DpX:
                case OperandType.DpXInd:
                    usage |= FlagAndRegs.X | FlagAndRegs.Index | FlagAndRegs.DP;
                    break;
                case OperandType.AbsX:
                case OperandType.LongX:
                    usage |= FlagAndRegs.X | FlagAndRegs.Index;
                    break;
                case OperandType.DpY:
                case OperandType.DpIndY:
                case OperandType.DpIndLongY:
                    usage |= FlagAndRegs.Y | FlagAndRegs.Index | FlagAndRegs.DP;
                    break;
                case OperandType.AbsY:
                case OperandType.JmpIndX:
                    // Y index
                    usage |= FlagAndRegs.Y | FlagAndRegs.Index;
                    break;
                case OperandType.Sr:
                    // SP index
                    usage |= FlagAndRegs.SP;
                    break;
                case OperandType.SrIndY:
                    // SP and Y index
                    usage |= FlagAndRegs.SP | FlagAndRegs.Y | FlagAndRegs.Index;
                    break;
                case OperandType.Return:
                    usage |= FlagAndRegs.A | FlagAndRegs.X | FlagAndRegs.Y | FlagAndRegs.DP |
                            FlagAndRegs.Negative | FlagAndRegs.Overflow | FlagAndRegs.Zero | FlagAndRegs.Carry;
                    break;
                case OperandType.CallNes:
                case OperandType.Jmp24:
                    // Unknown JML or JSL destination causes every register to be assumed used and changed
                    {
                        var flags = FlagAndRegs.A | FlagAndRegs.X | FlagAndRegs.Y | FlagAndRegs.DB |
                            FlagAndRegs.Negative | FlagAndRegs.Overflow | FlagAndRegs.Zero | FlagAndRegs.Carry |
                            FlagAndRegs.IoTemp8 | FlagAndRegs.IoTemp16 | FlagAndRegs.NesBankRange;
                        usage |= flags;
                        change |= flags | FlagAndRegs.Ah;
                    }
                    break;
                case OperandType.CallUseA:
                    usage |= FlagAndRegs.A;
                    break;
                case OperandType.CallUseX:
                    usage |= FlagAndRegs.X;
                    break;
                case OperandType.CallUseY:
                    usage |= FlagAndRegs.Y;
                    break;
                case OperandType.CallUseAX:
                    usage |= FlagAndRegs.A | FlagAndRegs.X;
                    break;
                case OperandType.CallUseAY:
                    usage |= FlagAndRegs.A | FlagAndRegs.Y;
                    break;
            }

            // Byte count
            switch (type)
            {
                default:
                case OperandType.Unknown:
                case OperandType.ConstM:
                case OperandType.ConstX:
                case OperandType.Label:
                    byteCount = 0;
                    break;
                case OperandType.None:
                case OperandType.Return:
                    byteCount = 1;
                    break;
                case OperandType.Const8:
                case OperandType.Dp:
                case OperandType.DpX:
                case OperandType.DpY:
                case OperandType.DpInd:
                case OperandType.DpXInd:
                case OperandType.DpIndY:
                case OperandType.DpIndLong:
                case OperandType.DpIndLongY:
                case OperandType.Sr:
                case OperandType.SrIndY:
                case OperandType.Br8:
                case OperandType.Break:
                    byteCount = 2;
                    break;
                case OperandType.Const16:
                case OperandType.Abs:
                case OperandType.AbsX:
                case OperandType.AbsY:
                case OperandType.Br16:
                case OperandType.Jmp16:     // Sometimes can be changed into BRA to save 1 byte
                case OperandType.JmpInd:
                case OperandType.JmpIndX:
                case OperandType.JmpIndLong:
                case OperandType.Move:
                case OperandType.JmpLabel:
                    byteCount = 3;
                    break;
                case OperandType.Long:
                case OperandType.LongX:
                case OperandType.Jmp24:
                case OperandType.CallUseA:
                case OperandType.CallUseX:
                case OperandType.CallUseY:
                case OperandType.CallUseAX:
                case OperandType.CallUseAY:
                    byteCount = 4;
                    break;
                case OperandType.BrLabel:   // BrLabel can be 3 or 5 but we use the worst scenario for quick estimations
                    byteCount = 5;
                    break;
            }
        }
    }
    public enum OperandType
    {
        Unknown = 0,
        None,
        Const8, Const16,                    // Constant
        ConstM, ConstX,                     // Constant based on MX flags
        Dp, DpX, DpY, DpInd, DpXInd, DpIndY,// Direct page (8-bit address operand)
        DpIndLong, DpIndLongY,              //  "
        Abs, AbsX, AbsY,                    // Absolute (16-bit address operand)
        Long, LongX,                        // Absolute long (24-bit address operand)
        Sr, SrIndY,                         // Stack related
        Br8, Br16,                          // Branch
        Jmp16, Jmp24,                       // Jump
        JmpInd, JmpIndX, JmpIndLong,        // Indirect jump
        Break,                              // Break and cop
        Move,                               // Move positive/negative
        Return,

        // Intermediate language
        Label, JmpLabel, BrLabel,
        FlagUsage, FlagChange,
        CallUseA, CallUseX, CallUseY, CallUseAX, CallUseAY,
        CallNes, CallEmu,
    }
    public enum FlagAndRegs
    {
        None = 0,
        Carry = 0x01,
        Zero = 0x02,
        Interrupt = 0x04,
        Decimal = 0x08,
        Index = 0x10,
        Memory = 0x20,
        Overflow = 0x40,
        Negative = 0x80,

        A = 0x0100,
        X = 0x0200,
        Y = 0x0400,
        Ah = 0x0800,            // High bits of A, only set for opcodes capable of touching those bits in 8-bit mode
                                //  except for cases where mx flag consistency matters (ie. TAX and TAY)

        SP = 0x1000,
        PC = 0x2000,            // Only used by OpcodeDescription.change
        DB = 0x4000,
        DP = 0x8000,

        P = 0x10000,            // Push-pull P only

        Exception = 0x20000,    // Opcodes that need to be converted to IL before optimizing

        Write = 0x40000,        // Only used by OpcodeDescription.change

        Marker = 0x80000,       // Only used by OpcodeDescription.change

        NesBankRange = 0x100000,// Only used by OpcodeDescription.change

        IoTemp8 = 0x200000,
        IoTemp16 = 0x400000,

        CanInline = 0x800000,   // Only used by OpcodeDescription.change

        End = -0x80000000,      // Only used by OpcodeDescription.change

        FlagMask = 0xff,        // Used by P
        CompareMask = 0xffff,   // Valid flags for comparing register usage
    }
}
