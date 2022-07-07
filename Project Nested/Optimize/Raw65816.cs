using Project_Nested.Injection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize
{
    class Raw65816
    {
        public int nesAddress;
        public byte[] data;
        public int baseAddress;
        public int entryPointOffset;
        public int compileFlags;

        public Raw65816(int nesAddress, byte[] data, int baseAddress, int entryPointOffset, int compileFlags)
        {
            this.nesAddress = nesAddress;
            this.data = data;
            this.baseAddress = baseAddress;
            this.entryPointOffset = entryPointOffset;
            this.compileFlags = compileFlags;
        }

        public List<AsmIL65816> ConvertToIL(Injector injector)
        {
            byte ReadData(int index)
            {
                if (data != null)
                    return data[index];
                else
                    return injector.ReadSnesByte(index);
            }

            List<AsmIL65816> code = new List<AsmIL65816>();

            List<int> labels = new List<int>();
            labels.Add(entryPointOffset + baseAddress);

            int mx = 0x300;
            int pc = 0;
            int opcode = 0;
            int operand = 0;

            OpcodeDescription opcodeDesc = new OpcodeDescription();

            void Exceptions()
            {
                // Exceptions
                switch (opcode & 0xff)
                {
                    case 0xc2:      // REP
                        mx &= ~operand << 4;
                        break;
                    case 0xe2:      // SEP
                        mx |= (operand & 0x30) << 4;
                        break;
                    case 0xdc: //InstructionSet.JMP_JmpIndLong:
                        // Hack for indirect JMP
                        mx = 0x300;
                        break;
                }
            }

            // Identify labels
            mx = 0x300;
            for (int i = 0; i < data.Length; i += opcodeDesc.byteCount)
            {
                pc = i + baseAddress;
                opcode = data[i] + mx;
                opcodeDesc = Asm65816Dictionary.GetOpcodeDesc(opcode, 0);
                operand = 0;
                for (int u = 1; u < opcodeDesc.byteCount; u++)
                    operand |= data[i + u] << ((u - 1) * 8);

                var il = new AsmIL65816(opcode, operand);

                // Does this instruction affect PC?
                var target = il.GetCodeTarget(pc);
                if (target >= 0)
                {
                    var labelIndex = labels.IndexOf(target);
                    if (labelIndex < 0)
                        // Add destination label if new
                        labels.Add(target);
                }

                Exceptions();
            }

            // Write code
            mx = 0x300;
            for (int i = 0; i < data.Length; i += opcodeDesc.byteCount)
            {
                pc = i + baseAddress;
                opcode = data[i] + mx;
                opcodeDesc = Asm65816Dictionary.GetOpcodeDesc(opcode, 0);
                operand = 0;
                for (int u = 1; u < opcodeDesc.byteCount; u++)
                    operand |= data[i + u] << ((u - 1) * 8);

                // Do we add a label here?
                {
                    var labelIndex = labels.IndexOf(pc);
                    if (labelIndex >= 0)
                        code.Add(new AsmIL65816(InstructionSet.Label, labelIndex));
                }

                // Does this instruction affect PC?
                var il = new AsmIL65816(opcode, operand);
                var target = il.GetCodeTarget(pc);
                if (target >= 0)
                {
                    var labelIndex = labels.IndexOf(target);
                    // Convert jmp/bra to IL
                    code.Add(new AsmIL65816(opcode | (int)InstructionSet.mod, labelIndex | ((target - pc) & -0x80000000)));
                }
                else if ((opcode & 0xff) == (int)InstructionSet.JSR_Jmp24)
                {
                    // Convert to emulator call
                    var call = Asm65816Dictionary.GetEmuCall(operand);
                    if (call.IsNesJsr)
                    {
                        // Nes call

                        // Retrieve original return&call
                        var originalReturn = code[code.Count - 2];
                        var originalCall = code[code.Count - 1];

                        // Make sure we are reading PEA opcodes
                        if (originalReturn.invariantOpcode == InstructionSet.PEA_Abs &&
                            originalCall.invariantOpcode == InstructionSet.PEA_Abs)
                        {
                            // Remove both PEA
                            code.RemoveRange(code.Count - 2, 2);

                            // Is this JSR followed by a JMP marker?
                            bool asmCondition = data[i + 4] == 0xea && data[i + 5] == 0x6b;
                            // Is this destination known and static?
                            bool rangeCondition = injector != null
                                && injector.IsRangeStatic(originalReturn.operand, originalCall.operand)
                                && injector.KnownCallsContainsExclusively(injector.GetStaticBankDestination(originalReturn.operand, originalCall.operand) * 0x10000 + originalCall.operand);
                            var nesCallOpcode = (asmCondition ?
                                (rangeCondition ? InstructionSet.JMP_Nes_Static : InstructionSet.JMP_Nes) :
                                (rangeCondition ? InstructionSet.JSR_Nes_Static : InstructionSet.JSR_Nes));

                            // Add the Nes call
                            code.Add(new AsmIL65816(nesCallOpcode, (originalReturn.operand & 0xffff) | (originalCall.operand << 16)));
                        }
                        else
                            throw new Exception("Incorrect NES call code structure.");
                    }
                    else if (call.address == 0)
                        // Unknown call
                        code.Add(il);
                    else
                        // Emulator call
                        code.Add(new AsmIL65816(InstructionSet.JSR_Emu, call.id));
                }
                else if ((opcode & 0xff) == (int)InstructionSet.JMP_Jmp24)
                {
                    // Convert to emulator call
                    var call = Asm65816Dictionary.GetEmuCall(operand);
                    if (call.IsNesRts)
                        // Emulator call
                        code.Add(new AsmIL65816(InstructionSet.JMP_Emu, call.id));
                    else
                        // Unknown call
                        code.Add(il);
                }
                else
                    code.Add(il);

                Exceptions();
            }

            // Do we add a label here? Out of bound label exception
            {
                pc = data.Length + baseAddress;
                var labelIndex = labels.IndexOf(pc);
                if (labelIndex >= 0)
                {
                    code.Add(new AsmIL65816(InstructionSet.Label, labelIndex));
                    code.Add(new AsmIL65816(InstructionSet.STP, 0));
                }
            }

            return code;
        }
    }
}
