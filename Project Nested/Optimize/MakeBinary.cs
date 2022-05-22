using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize
{
    class MakeBinary
    {
        public int nesAddress;
        public int snesAddress;
        public int entryPoint;
        public int compileFlags;

        public byte[] code;
        public int[] jumpSource;
        public int[] staticCallSource;
        public Dictionary<int, int> labels;
        public Dictionary<int, int> returnMarkers;      // <NES address, code offset>

        public const byte NO_SNES_BANK_RESERVATION = 0;
        public byte snesBankReservation = NO_SNES_BANK_RESERVATION;

        // --------------------------------------------------------------------

        public MakeBinary(OptimizeGroup sender, int nesAddress, List<CodeBlock> code, int compileFlags, bool nativeReturn)
        {
            ConvertToBinary(sender, nesAddress, CodeBlock.ConvertToList(code), compileFlags, nativeReturn);
        }

        public MakeBinary(OptimizeGroup sender, int nesAddress, List<AsmIL65816> code, int compileFlags, bool nativeReturn)
        {
            ConvertToBinary(sender, nesAddress, code, compileFlags, nativeReturn);
        }

        // --------------------------------------------------------------------

        private void ConvertToBinary(OptimizeGroup sender, int nesAddress, List<AsmIL65816> code, int compileFlags, bool nativeReturn)
        {
            const bool USE_DIRECT_LINKS = false;    // TODO: Direct links

            List<byte> newCode = new List<byte>();

            var labels = new Dictionary<int, int>();
            var returnMarkers = new Dictionary<int, int>();
            var branchSource = new List<Tuple<int, int>>();

            var jumpSource = new List<int>();
            var staticCallSource = new List<int>();

            int mx = 0x300;

            void AddCode(InstructionSet opcode, int operand, int byteCount)
            {
                if (byteCount == 0)
                    throw new Exception("Attempted to write 0 byte during code conversion to binary.");

                newCode.Add((byte)opcode);
                for (int i = 1; i < byteCount; i++)
                {
                    newCode.Add((byte)operand);
                    operand >>= 8;
                }
            }

            void AddCodeAt(int index, InstructionSet opcode, int operand, int byteCount)
            {
                if (byteCount == 0)
                    throw new Exception("Attempted to write 0 byte during code conversion to binary.");

                newCode.Insert(index, (byte)opcode);
                for (int i = 1; i < byteCount; i++)
                {
                    newCode.Insert(index + i, (byte)operand);
                    operand >>= 8;
                }
            }

            foreach (var asm in code)
            {
                var desc = asm.GetDescription();

                if (asm.opcode >= InstructionSet.il)        // Intermediate
                {
                    int AddLinkOrigin() => sender.AddLinkOrigin(new LinkOrigin(asm.originalReturn, asm.originalCall, nesAddress >> 16));

                    switch (asm.opcode)
                    {
                        case InstructionSet.Label:
                            labels.Add(asm.labelNum, newCode.Count);
                            break;
                        case InstructionSet.ReturnMarker:
                            returnMarkers.Add(asm.operand, newCode.Count - 1);
                            break;
                        case InstructionSet.JSR_Nes:
                            if (nativeReturn)
                            {
                                var originIndex = AddLinkOrigin();
                                AddCode(InstructionSet.JSR_Jmp24, 0x7f0000 + originIndex * 4, 4); // Dynamic link address
                            }
                            else
                            {
                                AddCode(InstructionSet.PEA_Abs, asm.originalReturn, 3);
                                var originIndex = AddLinkOrigin();
                                AddCode(InstructionSet.JMP_Jmp24, 0x7f0000 + originIndex * 4, 4); // Dynamic link address
                            }
                            break;
                        case InstructionSet.JMP_Nes:
                            {
                                var originIndex = AddLinkOrigin();
                                AddCode(InstructionSet.JMP_Jmp24, 0x7f0000 + originIndex * 4, 4); // Dynamic link address
                            }
                            AddCode(InstructionSet.NOP, 0, 1);
                            AddCode(InstructionSet.RTL, 0, 1);
                            break;
                        case InstructionSet.JSR_Nes_Static:
                            if (!USE_DIRECT_LINKS)
                                goto case InstructionSet.JSR_Nes;

                            if (nativeReturn)
                            {
                                staticCallSource.Add(newCode.Count + 1);
                                AddCode(InstructionSet.JSR_Jmp24, asm.originalCall, 4);
                            }
                            else
                            {
                                AddCode(InstructionSet.PEA_Abs, asm.originalReturn, 3);
                                staticCallSource.Add(newCode.Count + 1);
                                AddCode(InstructionSet.JMP_Jmp24, asm.originalCall, 4);
                            }
                            break;
                        case InstructionSet.JMP_Nes_Static:
                            if (!USE_DIRECT_LINKS)
                                goto case InstructionSet.JMP_Nes;

                            staticCallSource.Add(newCode.Count + 1);
                            AddCode(InstructionSet.JMP_Jmp24, asm.originalCall, 4);
                            break;
                        case InstructionSet.JMP_Emu:
                            AddCode(InstructionSet.JMP_Jmp24, Asm65816Dictionary.GetEmuCallByID(asm.operand).address, 4);
                            break;
                        case InstructionSet.JSR_Emu:
                            AddCode(InstructionSet.JSR_Jmp24, Asm65816Dictionary.GetEmuCallByID(asm.operand).address, 4);
                            break;
                        default:
                            throw new Exception("Undefined intermediate opcode during code conversion to binary.");
                    }

                }
                else if (asm.opcode >= InstructionSet.mod)  // Modified
                {
                    void WriteAnonymousBranch(InstructionSet opcode)
                    {
                        newCode.Add((byte)opcode);
                        branchSource.Add(new Tuple<int, int>(newCode.Count, asm.labelNum));
                        newCode.Add(0xfe);  // Trigger error on the emulator if this branch isn't resolved
                    }

                    switch (asm.opcode & ~InstructionSet.mx)
                    {
                        case InstructionSet.JMP_Label: // Use BRA instead
                        case InstructionSet.BRA_Label: WriteAnonymousBranch(InstructionSet.BRA_Br8); break;
                        case InstructionSet.BCC_Label: WriteAnonymousBranch(InstructionSet.BCC_Br8); break;
                        case InstructionSet.BCS_Label: WriteAnonymousBranch(InstructionSet.BCS_Br8); break;
                        case InstructionSet.BEQ_Label: WriteAnonymousBranch(InstructionSet.BEQ_Br8); break;
                        case InstructionSet.BNE_Label: WriteAnonymousBranch(InstructionSet.BNE_Br8); break;
                        case InstructionSet.BVC_Label: WriteAnonymousBranch(InstructionSet.BVC_Br8); break;
                        case InstructionSet.BVS_Label: WriteAnonymousBranch(InstructionSet.BVS_Br8); break;
                        case InstructionSet.BPL_Label: WriteAnonymousBranch(InstructionSet.BPL_Br8); break;
                        case InstructionSet.BMI_Label: WriteAnonymousBranch(InstructionSet.BMI_Br8); break;
                        case InstructionSet.PHP_Usage: newCode.Add((byte)InstructionSet.PHP); break;
                        case InstructionSet.PLP_Change: newCode.Add((byte)InstructionSet.PLP); break;
                        default:
                            throw new Exception("Undefined modified opcode during code conversion to binary.");
                    }
                }
                else                                        // Regular with mx
                {
                    if ((int)(asm.opcode & InstructionSet.mx) != mx)
                        throw new Exception("Wrong MX flag during code conversion to binary.");

                    // Exceptions
                    switch (asm.invariantOpcode)
                    {
                        case InstructionSet.REP_Const:
                            mx &= ((~asm.operand) & 0x30) << 4;
                            break;
                        case InstructionSet.SEP_Const:
                            mx |= (asm.operand & 0x30) << 4;
                            break;
                        case InstructionSet.JMP_JmpIndLong:
                            // Hack for indirect JMP
                            mx = 0x300;
                            break;
                    }

                    // Write code
                    AddCode(asm.opcode, asm.operand, desc.byteCount);
                }
            }

            // Fix branches
            var done = false;
            while(!done)
            {
                void MoveLabels(int startIndex, int byteCount)
                {
                    for (int i = 0; i < labels.Count; i++)
                    {
                        var item = labels.ElementAt(i);
                        if (item.Value > startIndex)
                            labels[item.Key] = item.Value + byteCount;
                    }
                    for (int i = 0; i < branchSource.Count; i++)
                    {
                        var item = branchSource[i];
                        if (item.Item1 > startIndex)
                            branchSource[i] = new Tuple<int, int>(item.Item1 + byteCount, item.Item2);
                    }
                    for (int i = 0; i < staticCallSource.Count; i++)
                    {
                        var item = staticCallSource[i];
                        if (item > startIndex)
                            staticCallSource[i] += byteCount;
                    }
                    for (int i = 0; i < jumpSource.Count; i++)
                    {
                        var item = jumpSource[i];
                        if (item > startIndex)
                            jumpSource[i] += byteCount;
                    }
                    for (int i = 0; i < returnMarkers.Count; i++)
                    {
                        var item = returnMarkers.ElementAt(i);
                        if (item.Value > startIndex)
                            returnMarkers[item.Key] = item.Value + byteCount;
                    }
                    done = false;
                }

                done = true;
                for (int i = branchSource.Count - 1; i >= 0; i--)
                {
                    var item = branchSource[i];
                    var srcOffset = item.Item1;
                    var destLabel = item.Item2;

                    var destOffset = labels[destLabel];
                    var branchDistance = destOffset - (srcOffset + 1);

                    if ((sbyte)branchDistance != branchDistance)
                    {
                        var opcode = (InstructionSet)newCode[srcOffset - 1];
                        switch (opcode)
                        {
                            case InstructionSet.BRA_Br8:
                                // Replace with jump
                                newCode.RemoveRange(srcOffset - 1, 2);
                                AddCodeAt(srcOffset - 1, InstructionSet.JMP_Jmp16, destLabel, 3);
                                branchSource.RemoveAt(i);
                                MoveLabels(srcOffset, 1);
                                jumpSource.Add(srcOffset);
                                break;
                            case InstructionSet.BCC_Br8:
                            case InstructionSet.BCS_Br8:
                            case InstructionSet.BEQ_Br8:
                            case InstructionSet.BNE_Br8:
                            case InstructionSet.BVC_Br8:
                            case InstructionSet.BVS_Br8:
                            case InstructionSet.BPL_Br8:
                            case InstructionSet.BMI_Br8:
                                // Replace with branch+jump
                                newCode.RemoveRange(srcOffset - 1, 2);
                                AddCodeAt(srcOffset - 1, (InstructionSet)((int)opcode ^ 0x20), 0x03, 2);
                                AddCodeAt(srcOffset - 1 + 2, InstructionSet.JMP_Jmp16, destLabel, 3);
                                branchSource.RemoveAt(i);
                                MoveLabels(srcOffset, 3);
                                jumpSource.Add(srcOffset - 1 + 3);
                                break;
                            default:
                                throw new Exception("Incorrect branch source during code conversion to binary.");
                        }
                    }
                    else
                    {
                        // Write distance
                        newCode[srcOffset] = (byte)branchDistance;
                    }
                }
            }

            this.nesAddress = nesAddress;
            this.entryPoint = labels[0];
            this.compileFlags = compileFlags;

            this.code = newCode.ToArray();
            this.jumpSource = jumpSource.ToArray();
            this.staticCallSource = staticCallSource.ToArray();
            this.labels = labels;
            this.returnMarkers = returnMarkers;
        }
    }
}
