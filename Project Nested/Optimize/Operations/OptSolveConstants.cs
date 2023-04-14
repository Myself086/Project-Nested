using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize.Operations
{
    class OptSolveConstants : OptimizeOperation
    {
        public OptSolveConstants()
        {
            OperationName = "Solve constants";
            OperationDescription = "Identifies and solves constants.";
        }

        public override bool Iterate(OptimizeOperator sender, int iterationID)
        {
            bool requestSolveInconsistencies = false;

            for (int i = 0; i < sender.CodeBlockCount; i++)
            {
                CodeBlock block = sender.GetCodeBlock(i);
                if (block.HasChangedSince(this.previousIterationID))
                {
                    // Value of each register
                    ValueRange16 regA = ValueRange16.Unk;
                    ValueRange16 regX = new ValueRange16(ValueRange8.Unk, 0);
                    ValueRange16 regY = new ValueRange16(ValueRange8.Unk, 0);
                    ValueRange8 flagN = ValueRange8.Unk;
                    ValueRange8 flagV = ValueRange8.Unk;
                    ValueRange8 flagZ = ValueRange8.Unk;
                    ValueRange8 flagC = ValueRange8.Unk;

                    bool removed = false;
                    for (int u = 0; u < block.Count; u++)
                    {
                        redo:
                        var asm = block[u];
                        var mx = asm.opcode & InstructionSet.mx;
                        var desc = asm.GetDescription();
                        var m = (mx & InstructionSet.m) == 0;   // Set if 16-bit
                        var x = (mx & InstructionSet.x) == 0;   // Set if 16-bit

                        void FlagNZ_M(ValueRange16 value)
                        {
                            if ((mx & InstructionSet.m) != 0)
                            {
                                // 8-bit
                                flagN = value.lo.GetNegativeFlag();
                                flagZ = value.lo;
                            }
                            else
                            {
                                // 16-bit
                                flagN = value.hi.GetNegativeFlag();
                                flagZ = value.lo.top | value.hi.top;
                            }
                        }
                        void FlagNZ_X(ValueRange16 value)
                        {
                            if ((mx & InstructionSet.x) != 0)
                            {
                                // 8-bit
                                flagN = value.lo.GetNegativeFlag();
                                flagZ = value.lo;
                            }
                            else
                            {
                                // 16-bit
                                flagN = value.hi.GetNegativeFlag();
                                flagZ = value.lo.top | value.hi.top;
                            }
                        }
                        void WriteLdaConst() { if (regA.IsKnown(m)) WriteConst(regA, InstructionSet.LDA_Const | mx, m); }
                        void WriteLdxConst() { if (regX.IsKnown(x)) WriteConst(regX, InstructionSet.LDX_Const | mx, x); }
                        void WriteLdyConst() { if (regY.IsKnown(x)) WriteConst(regY, InstructionSet.LDY_Const | mx, x); }
                        void WriteConst(ValueRange16 value, InstructionSet opcode, bool word)
                        {
                            if (!word)
                            {
                                if (value.lo.IsKnown())
                                    block[u, iterationID] = new AsmIL65816(opcode, value.lo);
                            }
                            else
                            {
                                if (value.IsKnown())
                                    block[u, iterationID] = new AsmIL65816(opcode, value.lo | (value.hi << 8));
                            }
                        }
                        void ChangeOpcode(InstructionSet value) { asm.opcode = value | mx; block[u, iterationID] = asm; }
                        void SolveBranch(bool value)
                        {
                            if (value)
                            {
                                asm.opcode = InstructionSet.BRA_Label | mx;
                                block[u, iterationID] = asm;
                                requestSolveInconsistencies = true;
                            }
                            else
                            {
                                sender.DecLabelUsageCount(asm.labelNum);
                                block.RemoveAt(u, iterationID);
                                removed = true;
                            }
                        }

                        // Is this line using X index?
                        if (desc.usage.HasFlag(FlagAndRegs.X) && regX.IsKnown(x))
                        {
                            var newOpcode = Asm65816Dictionary.GetRemoveIndexX(asm.opcode);
                            if (newOpcode >= 0)
                            {
                                block[u, iterationID] = new AsmIL65816(newOpcode, asm.operand + regX.GetValue(x));
                                goto redo;
                            }
                        }

                        // Is this line using Y index?
                        if (desc.usage.HasFlag(FlagAndRegs.Y) && regY.IsKnown(x))
                        {
                            var newOpcode = Asm65816Dictionary.GetRemoveIndexZeroY(asm.opcode);
                            if (newOpcode >= 0)
                            {
                                block[u, iterationID] = new AsmIL65816(newOpcode, asm.operand + regY.GetValue(x));
                                goto redo;
                            }
                        }
                        else if (desc.usage.HasFlag(FlagAndRegs.Y) && regY.IsKnown(x))
                        {
                            var newOpcode = Asm65816Dictionary.GetRemoveIndexY(asm.opcode);
                            if (newOpcode >= 0)
                            {
                                block[u, iterationID] = new AsmIL65816(newOpcode, asm.operand + regY.GetValue(x));
                                goto redo;
                            }
                        }

                        switch (asm.invariantOpcode)
                        {
                            case InstructionSet.CLC: if (flagC == 0) ChangeOpcode(InstructionSet.NOP); flagC = 0; break;
                            case InstructionSet.SEC: if (flagC == 1) ChangeOpcode(InstructionSet.NOP); flagC = 1; break;
                            case InstructionSet.LSR: flagC = regA.lo.GetLowestBit(); FlagNZ_M(regA.Sr(m)); break;
                            case InstructionSet.TDC: regA.lo = regA.hi = 0; FlagNZ_M(regA); break;
                            case InstructionSet.LDA_Const: FlagNZ_M(regA.SetValue(asm.operand, m)); break;
                            case InstructionSet.LDX_Const: FlagNZ_X(regX.SetValue(asm.operand, x)); break;
                            case InstructionSet.LDY_Const: FlagNZ_X(regY.SetValue(asm.operand, x)); break;
                            case InstructionSet.STA_Dp: if (regA.GetValue(m) == 0) ChangeOpcode(InstructionSet.STZ_Dp); break;
                            case InstructionSet.STA_Abs: if (regA.GetValue(m) == 0) ChangeOpcode(InstructionSet.STZ_Abs); break;
                            case InstructionSet.STA_DpX: if (regA.GetValue(m) == 0) ChangeOpcode(InstructionSet.STZ_DpX); break;
                            case InstructionSet.STA_AbsX: if (regA.GetValue(m) == 0) ChangeOpcode(InstructionSet.STZ_AbsX); break;
                            case InstructionSet.STX_Dp: if (regX.GetValue(x) == 0) ChangeOpcode(InstructionSet.STZ_Dp); break;
                            case InstructionSet.STX_Abs: if (regX.GetValue(x) == 0) ChangeOpcode(InstructionSet.STZ_Abs); break;
                            case InstructionSet.STY_Dp: if (regY.GetValue(x) == 0) ChangeOpcode(InstructionSet.STZ_Dp); break;
                            case InstructionSet.STY_Abs: if (regY.GetValue(x) == 0) ChangeOpcode(InstructionSet.STZ_Abs); break;
                            case InstructionSet.STY_DpX: if (regY.GetValue(x) == 0) ChangeOpcode(InstructionSet.STZ_DpX); break;
                            case InstructionSet.DEC: FlagNZ_M(regA.Sub(1, m)); WriteLdaConst(); break;
                            case InstructionSet.DEX: FlagNZ_X(regX.Sub(1, x)); WriteLdxConst(); break;
                            case InstructionSet.DEY: FlagNZ_X(regY.Sub(1, x)); WriteLdyConst(); break;
                            case InstructionSet.INC: FlagNZ_M(regA.Add(1, m)); WriteLdaConst(); break;
                            case InstructionSet.INX: FlagNZ_X(regX.Add(1, x)); WriteLdxConst(); break;
                            case InstructionSet.INY: FlagNZ_X(regY.Add(1, x)); WriteLdyConst(); break;
                            case InstructionSet.TAX: if (m == x) { FlagNZ_X(regX.SetValue(regA, x)); WriteLdxConst(); } else goto default; break;
                            case InstructionSet.TXA: if (m == x) { FlagNZ_X(regA.SetValue(regX, x)); WriteLdaConst(); } else goto default; break;
                            case InstructionSet.TAY: if (m == x) { FlagNZ_X(regY.SetValue(regA, x)); WriteLdyConst(); } else goto default; break;
                            case InstructionSet.TYA: if (m == x) { FlagNZ_X(regA.SetValue(regY, x)); WriteLdaConst(); } else goto default; break;
                            case InstructionSet.TXY: if (true) { FlagNZ_X(regY.SetValue(regX, x)); WriteLdyConst(); } else goto default; break;
                            case InstructionSet.TYX: if (true) { FlagNZ_X(regX.SetValue(regY, x)); WriteLdxConst(); } else goto default; break;
                            case InstructionSet.BPL_Br8: if (flagN >= 0) SolveBranch((flagN & 0x80) == 0); flagN = 0x80; break;
                            case InstructionSet.BMI_Br8: if (flagN >= 0) SolveBranch((flagN & 0x80) != 0); flagN = 0; break;
                            case InstructionSet.BVC_Br8: if (flagV >= 0) SolveBranch(flagV == 0); flagV = 0xff; break;
                            case InstructionSet.BVS_Br8: if (flagV >= 0) SolveBranch(flagV != 0); flagV = 0; break;
                            case InstructionSet.BCC_Br8: if (flagC >= 0) SolveBranch((flagC & 1) == 0); flagC = 1; break;
                            case InstructionSet.BCS_Br8: if (flagC >= 0) SolveBranch((flagC & 1) != 0); flagC = 0; break;
                            case InstructionSet.BEQ_Br8: if (flagZ >= 0) SolveBranch(flagZ == 0); flagZ = 1; break;
                            case InstructionSet.BNE_Br8: if (flagZ >= 0) SolveBranch(flagZ != 0); flagZ = 0; break;
                            default:
                                {
                                    // Set changed registers and flags to unknown
                                    if (desc.change.HasFlag(FlagAndRegs.A)) regA.lo = ValueRange8.Unk;
                                    if (desc.change.HasFlag(FlagAndRegs.Ah)) regA.hi = ValueRange8.Unk;
                                    if (desc.change.HasFlag(FlagAndRegs.X)) regX = ValueRange16.Unk;
                                    if (desc.change.HasFlag(FlagAndRegs.Y)) regY = ValueRange16.Unk;
                                    if (desc.change.HasFlag(FlagAndRegs.Negative)) flagN = ValueRange8.Unk;
                                    if (desc.change.HasFlag(FlagAndRegs.Overflow)) flagV = ValueRange8.Unk;
                                    if (desc.change.HasFlag(FlagAndRegs.Zero)) flagZ = ValueRange8.Unk;
                                    if (desc.change.HasFlag(FlagAndRegs.Carry)) flagC = ValueRange8.Unk;
                                }
                                break;
                        }

                        if (removed)
                        {
                            u--;
                            removed = false;
                        }
                    }
                }
            }

            if (requestSolveInconsistencies)
                sender.SolveInconsistencies();

            return base.Iterate(sender, iterationID);
        }

        struct ValueRange16
        {
            public ValueRange8 lo, hi;

            public static readonly ValueRange16 Unk = new ValueRange16(ValueRange8.Unk, ValueRange8.Unk);

            public ValueRange16(ValueRange8 lo, ValueRange8 hi) => this = new ValueRange16() { lo = lo, hi = hi };

            public ValueRange16 SetValue(ValueRange16 value, bool word)
            {
                lo = value.lo;
                if (word)
                    hi = value.hi;
                return this;
            }

            public ValueRange16 SetValue(int value, bool word)
            {
                lo = value;
                if (word)
                    hi = value >> 8;
                return this;
            }

            public int GetValue(bool word)
            {
                if (!word)
                    return lo.IsKnown() ? lo.value : -1;
                else
                    return IsKnown() ? lo | (hi << 8) : -1;
            }

            public bool IsKnown() => lo.IsKnown() && hi.IsKnown();
            public bool IsKnown(bool word) => lo.IsKnown() && (!word || hi.IsKnown());

            public ValueRange16 Add(int value, bool word)
            {
                if (!word)
                {
                    lo.Add(value);
                }
                else
                {
                    // TODO
                    this = ValueRange16.Unk;
                }

                return this;
            }

            public ValueRange16 Sub(int value, bool word)
            {
                if (!word)
                {
                    lo.Sub(value);
                }
                else
                {
                    // TODO
                    this = ValueRange16.Unk;
                }

                return this;
            }

            public ValueRange16 Sr(bool word)
            {
                if (!word)
                    lo.Sr();
                else
                {
                    var bit8 = hi.GetLowestBit();
                    hi.Sr();
                    lo.Ror(bit8);
                }

                return this;
            }

            public ValueRange16 Sl(bool word)
            {
                if (!word)
                    lo.Sl();
                else
                {
                    var bit7 = lo.GetHighestBit();
                    lo.Sl();
                    hi.Rol(bit7);
                }

                return this;
            }
        }

        struct ValueRange8
        {
            public int value;
            public int top { get => value < 0 ? (value & 0xff00) >> 8 : value; }
            public int bottom { get => value < 0 ? (value & 0x00ff) >> 0 : value; }

            public static implicit operator ValueRange8(int a) => new ValueRange8(a);
            public static implicit operator int(ValueRange8 a) => a.value;

            public static readonly ValueRange8 Unk = new ValueRange8(0, 255);

            public ValueRange8(int value) => this = new ValueRange8() { value = value & 0xff };
            public ValueRange8(int bottom, int top)
            {
                this.value = bottom & 0xff;
                if (bottom != top)
                    SetRange(bottom, top);
            }

            public void SetRange(int bottom, int top)
            {
                if (bottom < 0) bottom = 0;
                if (bottom > 255) bottom = 255;
                if (top < 0) top = 0;
                if (top > 255) top = 255;

                this.value = (-1 << 16) | (bottom << 0) | (top << 8);
                if (bottom == top)
                    this.value = bottom;
            }

            public bool IsKnown() => value >= 0;

            public void Dec() => Add(-1);
            public void Sub(int a) => Add(-a & 0xff);
            public void Inc() => Add(1);
            public void Add(int a)
            {
                if (this.IsKnown())
                    value = (value + a) & 0xff;
                else
                {
                    int top = this.top + a;
                    int bottom = this.bottom + a;

                    // Overflow?
                    if (((top ^ bottom) & ~0xff) != 0)
                        SetRange(0, 255);
                }
            }

            public ValueRange8 Sr() => Sl(-1);
            public ValueRange8 Sr(int a) => Sl(-a);
            public ValueRange8 Sl() => Sr(1);
            public ValueRange8 Sl(int a)
            {
                if (this.IsKnown())
                {
                    if (a < 0)
                        value >>= -a;
                    else if (a > 0)
                        value <<= a;
                }
                else if (a < 0)
                {
                    // Shift right
                    int top = this.top >> -a;
                    int bottom = this.bottom >> -a;

                    SetRange(bottom, top);
                }
                else if (a > 0)
                {
                    // Shift left
                    int top = this.top << a;
                    int bottom = this.bottom << a;

                    SetRange(bottom, top);
                }
                return this;
            }

            public ValueRange8 Rol(ValueRange8 carry)
            {
#if DEBUG
                if (carry.top > 1)
                    throw new OverflowException();
#endif

                if (this.IsKnown())
                {
                    if (carry.IsKnown())
                        value <<= 1 | (carry >> 0);
                    else
                        SetRange(value << 1, (value << 1) | 1);
                }
                else
                {
                    SetRange((bottom << 1) | carry.bottom, (top << 1) | carry.top);
                }
                return this;
            }

            public ValueRange8 Ror(ValueRange8 carry)
            {
#if DEBUG
                if (carry.top > 1)
                    throw new OverflowException();
#endif

                if (this.IsKnown())
                {
                    if (carry.IsKnown())
                        value >>= 1 | (carry << 7);
                    else
                        SetRange(value >> 1, (value >> 1) | 0x128);
                }
                else
                {
                    SetRange((bottom >> 1) | carry.bottom << 7, (top >> 1) | carry.top << 7);
                }
                return this;
            }

            public ValueRange8 And(int a)
            {
                if (this.IsKnown())
                    return value & a;
                else
                {
                    // TODO: Proper AND range
                    return new ValueRange8(0, a);
                }
            }

            public ValueRange8 Or(int a)
            {
                if (this.IsKnown())
                    return value | a;
                else
                {
                    // TODO: Proper OR range
                    return new ValueRange8(a, 255);
                }
            }

            public ValueRange8 Xor(int a)
            {
                if (this.IsKnown())
                    return value ^ a;
                else
                {
                    // TODO: Proper XOR range
                    return new ValueRange8(0, 255);
                }
            }

            public ValueRange8 GetNegativeFlag()
            {
                if (this.IsKnown())
                    return new ValueRange8(value);
                else
                {
                    int top = this.top;
                    int bottom = this.bottom;

                    int difference = (bottom ^ top) & 0x80;

                    if (difference != 0)
                        return ValueRange8.Unk;
                    else
                        return new ValueRange8(bottom);
                }
            }

            public ValueRange8 GetZeroFlag()
            {
                if (this.IsKnown())
                    return new ValueRange8(value);
                else
                {
                    int top = this.top;
                    int bottom = this.bottom;

                    if (bottom == 0)
                        return ValueRange8.Unk;     // Unknown
                    else
                        return new ValueRange8(1);  // Always non-zero
                }
            }

            /// <summary>
            /// Performs an addition to determine carry flag
            /// </summary>
            /// <param name="other"></param>
            /// <returns></returns>
            public ValueRange8 GetCarryFlag(ValueRange8 other)
            {
                int top = this.top + other.top;
                int bottom = this.bottom + other.bottom;

                int difference = (bottom ^ top) & 0x100;

                if (difference != 0)
                    return new ValueRange8(0, 1);
                else
                    return new ValueRange8(bottom >> 8);
            }

            public ValueRange8 GetLowestBit()
            {
                if (this.IsKnown())
                    return new ValueRange8(value & 1);
                else
                    return new ValueRange8(0, 1);
            }

            public ValueRange8 GetHighestBit()
            {
                if (this.IsKnown())
                    return new ValueRange8((value & 0x80) >> 7);
                else
                {
                    return new ValueRange8((bottom & 0x80) >> 7, (top & 0x80) >> 7);
                }
            }
        }
    }
}
