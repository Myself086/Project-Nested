using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize
{
    public struct AsmIL65816
    {
        public InstructionSet opcode;   // Anything above 255 is reserved for intermediate language
        public InstructionSet invariantOpcode { get => opcode & ~(InstructionSet.mx | InstructionSet.mod); }

        public int operand;

        // Used by labels only
        public int labelNum { get => operand & 0xffff; set => operand = (operand & ~0xffff) | (value & 0xffff); }
        public int labelLinkCount { get => (operand & 0x7fff0000) >> 16; set => operand = (operand & ~0x7fff0000) | ((value & 0x7fff) << 16); }
        public bool labelDirectionUp { get => operand < 0; set => operand = (operand & 0x7ffffff) | (value ? -0x80000000 : 0); }
        public bool labelDirectionDown { get => operand >= 0; set => operand = (operand & 0x7ffffff) | (!value ? -0x80000000 : 0); }

        // Used by Jsr Nes only
        public int originalReturn { get => operand & 0xffff; }
        public int originalCall { get => (operand >> 16) & 0xffff; }

        public AsmIL65816(int opcode, int operand)
        {
            this.opcode = (InstructionSet)opcode;
            this.operand = operand;
        }

        public AsmIL65816(InstructionSet opcode)
        {
            this.opcode = opcode;
            this.operand = 0;
        }

        public AsmIL65816(InstructionSet opcode, int operand)
        {
            this.opcode = opcode;
            this.operand = operand;
        }

        public OpcodeDescription GetDescription() => Asm65816Dictionary.GetOpcodeDesc(opcode, operand);

        public EmulatorCall GetEmulatorCall()
        {
            if (opcode == InstructionSet.JSR_Emu || opcode == InstructionSet.JMP_Emu)
                return Asm65816Dictionary.GetEmuCallByID(operand);
            else
                return Asm65816Dictionary.GetEmuCallByID(0);
        }

        public int GetCodeTarget(int pc)
        {
            var desc = GetDescription();

            switch (desc.type)
            {
                default:
                    return -1;
                case OperandType.Br8:
                    return pc + 2 + (sbyte)operand;
                case OperandType.Br16:
                    return (pc & 0xff0000) | ((pc + 3 + (short)operand) & 0xffff);
                case OperandType.Jmp16:
                    return (pc & 0xff0000) + (ushort)operand;
                case OperandType.Jmp24:
                    return -1;          // Only line changing between GetCodeTarget and GetCodeTargetLong
            }
        }

        public int GetCodeTargetLong(int pc)
        {
            var desc = GetDescription();

            switch (desc.type)
            {
                default:
                    return -1;
                case OperandType.Br8:
                    return pc + 2 + (sbyte)operand;
                case OperandType.Br16:
                    return (pc & 0xff0000) | ((pc + 3 + (short)operand) & 0xffff);
                case OperandType.Jmp16:
                    return (pc & 0xff0000) + (ushort)operand;
                case OperandType.Jmp24:
                    return operand;     // Only line changing between GetCodeTarget and GetCodeTargetLong
            }
        }

        public static string DisassembleList(List<AsmIL65816> code)
        {
            StringBuilder sb = new StringBuilder();

            foreach (var line in code)
                sb.AppendLine(line.ToString());

            return sb.ToString();
        }

        public override string ToString()
        {
            const string COLOR_DEFAULT = "/cFFF/";      // White
            const string COLOR_ERROR = "/cFAC/";        // Pink
            const string COLOR_JUMP = "/cF91/";         // Orange
            const string COLOR_CALL = "/cF3F/";         // Purple
            const string COLOR_CALL_EMU = "/cF9F/";     // Light purple
            const string COLOR_RETURN = "/cF22/";       // Red
            const string COLOR_LABEL = "/cFD1/";        // Yellow
            const string COLOR_REG_USAGE = "/c1EF/";    // Cyan (I wanted green but some users are color blind, Cyan+Red are always distinguishable)
            const string COLOR_REG_CHANGE = "/cF22/";   // Red
            const string COLOR_COMMENT = "/c1F1/";      // Green

            var desc = GetDescription();

            if (desc.name == null)
                desc.name = $"?({opcode})";

            switch (desc.type)
            {
                default:
                    return AddSuffix($"{COLOR_ERROR}\t{desc.name}\t${operand:x8}?");
                case OperandType.Unknown:
                    return AddSuffix($"{COLOR_ERROR}\t{desc.name}\t${operand:x8}");
                case OperandType.Const8:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t#${operand:x2}");
                case OperandType.Const16:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t#${operand:x4}");
                case OperandType.Dp:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t${operand:x2}");
                case OperandType.Abs:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t${operand:x4}");
                case OperandType.Long:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t${operand:x6}");
                case OperandType.Br8:
                    {
                        var value = (SByte)operand;
                        return AddSuffix((value < 0) ?
                            $"{COLOR_JUMP}\t{desc.name}{COLOR_DEFAULT}▲\t{COLOR_DEFAULT}-${-value:x2}" :
                            $"{COLOR_JUMP}\t{desc.name}{COLOR_DEFAULT}▼\t{COLOR_DEFAULT}+${value:x2}");
                    }
                case OperandType.Br16:
                    {
                        var value = (Int16)operand;
                        return AddSuffix((value < 0) ?
                            $"{COLOR_JUMP}\t{desc.name}{COLOR_DEFAULT}▲\t{COLOR_DEFAULT}-${-value:x4}" :
                            $"{COLOR_JUMP}\t{desc.name}{COLOR_DEFAULT}▼\t{COLOR_DEFAULT}+${value:x4}");
                    }
                case OperandType.Jmp16:
                    return AddSuffix($"{COLOR_JUMP}\t{desc.name}\t${operand:x4}");
                case OperandType.Jmp24:
                case OperandType.CallUseA:
                case OperandType.CallUseX:
                case OperandType.CallUseY:
                case OperandType.CallUseAX:
                case OperandType.CallUseAY:
                    return AddSuffix($"{COLOR_JUMP}\t{desc.name}\t{COLOR_CALL}${operand:x6}");
                case OperandType.FlagUsage:
                case OperandType.FlagChange:
                case OperandType.None:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}");
                case OperandType.ConstM:
                    return AddSuffix($"{COLOR_DEFAULT}???\tConstM");
                case OperandType.ConstX:
                    return AddSuffix($"{COLOR_DEFAULT}???\tConstX");
                case OperandType.DpX:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t${operand:x2},X");
                case OperandType.DpY:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t${operand:x2},Y");
                case OperandType.DpInd:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t(${operand:x2})");
                case OperandType.DpXInd:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t(${operand:x2},X)");
                case OperandType.DpIndY:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t(${operand:x2}),Y");
                case OperandType.DpIndLong:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t[${operand:x2}]");
                case OperandType.DpIndLongY:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t[${operand:x2}],Y");
                case OperandType.AbsX:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t${operand:x4},X");
                case OperandType.AbsY:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t${operand:x4},Y");
                case OperandType.LongX:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t${operand:x6},X");
                case OperandType.Sr:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t${operand:x2},S");
                case OperandType.SrIndY:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t(${operand:x2},S),Y");
                case OperandType.JmpInd:
                    return AddSuffix($"{COLOR_JUMP}\t{desc.name}\t(${operand:x4})");
                case OperandType.JmpIndX:
                    return AddSuffix($"{COLOR_JUMP}\t{desc.name}\t(${operand:x4}),X");
                case OperandType.JmpIndLong:
                    return AddSuffix($"{COLOR_JUMP}\t{desc.name}\t[${operand:x4}]");
                case OperandType.Break:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t${operand:x2}");
                case OperandType.Move:
                    return AddSuffix($"{COLOR_DEFAULT}\t{desc.name}\t${(operand >> 8) & 0xff:x2}, ${(operand >> 0) & 0xff:x2}");
                case OperandType.Label:
                    return AddSuffix(labelNum == 0 ? $"{COLOR_LABEL}EntryPoint{COLOR_DEFAULT}:" : $"{COLOR_LABEL}b_{labelNum}{COLOR_DEFAULT}:" +
                        (labelLinkCount > 0 ? $"  \t{COLOR_COMMENT}; {labelLinkCount} links" : ""));
                case OperandType.JmpLabel:
                case OperandType.BrLabel:
                    return AddSuffix($"{COLOR_JUMP}\t{desc.name}{COLOR_DEFAULT}{(operand < 0 ? "▲" : "▼")}{COLOR_LABEL}\tb_{operand & 0xffff}");
                case OperandType.Return:
                    return AddSuffix($"{COLOR_RETURN}\t{desc.name}");
                case OperandType.CallNes:
                    return AddSuffix($"{COLOR_JUMP}\t{desc.name}\t{COLOR_CALL}${originalReturn:x4} -> ${originalCall:x4}");
                case OperandType.CallEmu:
                case OperandType.JumpEmu:
                    return AddSuffix($"{COLOR_JUMP}\t{desc.name}\t{COLOR_CALL_EMU}{GetEmulatorCall().name}");
            }

            // return MakeString(null, $"", $"");

            string AddSuffix(string text)
            {
                // Find cursor position at the end of this text
                const int TAB = 6;
                var x = 0;
                for (int i = 0; i < text.Length; i++)
                {
                    var chr = text[i];
                    switch (chr)
                    {
                        case '\t':
                            // Move to the next multiple of TAB
                            x = (x / TAB) * TAB + TAB;
                            break;
                        case '\n':
                            // New line (unlikely to be used but it's here)
                            x = 0;
                            break;
                        case '/':
                            // Slash command, only empty commands produce a character
                            i++;
                            if (text[i] == '/')
                                x++;        // Empty command produces a single slash
                            else
                                for (; i < text.Length; i++)
                                    if (text[i] == '/')
                                        break;
                            break;
                        default:
                            // Random character
                            x++;
                            break;
                    }
                }

                StringBuilder sb = new StringBuilder(text);

                const int REG_START = 28;
                if (x < REG_START)
                    sb.Append(' ', REG_START - x);

                // Append register usage: AXYnvzc
                var use = desc.usage;
                var chg = desc.change;
                sb.Append($"{COLOR_REG_USAGE}");
                sb.Append(use.HasFlag(FlagAndRegs.A) ? 'A' : ' ');
                sb.Append(use.HasFlag(FlagAndRegs.X) ? 'X' : ' ');
                sb.Append(use.HasFlag(FlagAndRegs.Y) ? 'Y' : ' ');
                sb.Append(use.HasFlag(FlagAndRegs.Negative) ? 'n' : ' ');
                sb.Append(use.HasFlag(FlagAndRegs.Overflow) ? 'v' : ' ');
                sb.Append(use.HasFlag(FlagAndRegs.Zero) ? 'z' : ' ');
                sb.Append(use.HasFlag(FlagAndRegs.Carry) ? 'c' : ' ');
                sb.Append($"{COLOR_REG_CHANGE}");
                sb.Append(chg.HasFlag(FlagAndRegs.A) ? 'A' : ' ');
                sb.Append(chg.HasFlag(FlagAndRegs.X) ? 'X' : ' ');
                sb.Append(chg.HasFlag(FlagAndRegs.Y) ? 'Y' : ' ');
                sb.Append(chg.HasFlag(FlagAndRegs.Negative) ? 'n' : ' ');
                sb.Append(chg.HasFlag(FlagAndRegs.Overflow) ? 'v' : ' ');
                sb.Append(chg.HasFlag(FlagAndRegs.Zero) ? 'z' : ' ');
                sb.Append(chg.HasFlag(FlagAndRegs.Carry) ? 'c' : ' ');

                return sb.ToString();
            }
        }

        public static bool operator ==(AsmIL65816 a, AsmIL65816 b) => a.opcode == b.opcode && a.operand == b.operand;
        public static bool operator !=(AsmIL65816 a, AsmIL65816 b) => a.opcode != b.opcode || a.operand != b.operand;

        public override bool Equals(object obj)
        {
            if (obj is AsmIL65816 other)
                return this.opcode == other.opcode && this.operand == other.operand;
            else
                return false;
        }
    }
}
