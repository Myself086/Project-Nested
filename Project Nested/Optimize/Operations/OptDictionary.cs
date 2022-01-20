using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize.Operations
{
    class OptDictionary : OptimizeOperation
    {
        public OptDictionary()
        {
            OperationName = "Dictionary";
            OperationDescription = "Replaces sequences of code that can use 65816 exclusive instructions" +
                " or generate code that is more likely to be picked up by other operations.";
        }

        public override bool Iterate(OptimizeOperator sender, int iterationID)
        {
            for (int i = 0; i < sender.CodeBlockCount; i++)
            {
                CodeBlock block = sender.GetCodeBlock(i);
                if (block.HasChangedSince(this.previousIterationID))
                {
                    for (int u = block.Count - 1; u >= 0; u--)
                    {
                        var asm = block[u];
                        var mx = asm.opcode & InstructionSet.mx;

                        switch (asm.opcode)
                        {
                            case InstructionSet.SBC_Const | InstructionSet.mx:
                                if (asm.operand == 1 && block[u - 1].opcode == (InstructionSet.SEC | mx))
                                {
                                    // Entry: SEC + SBC #1
                                    // Return: DEC A
                                    // NOTE: Inconsistent flag VC
                                    if (!sender.IsOpcodeUseful(sender, i, u + 1, FlagAndRegs.Overflow | FlagAndRegs.Carry))
                                    {
                                        block[u + 0, iterationID] = new AsmIL65816(InstructionSet.DEC | mx, 0);
                                        block.RemoveAt(u - 1, iterationID);
                                    }
                                }
                                break;
                            case InstructionSet.PLA | InstructionSet.mx:
                                if (block[u + 1].opcode == (InstructionSet.TAX | mx))
                                {
                                    // Entry: PLA + TAX
                                    // Return: PLX + TXA
                                    block[u + 0, iterationID] = new AsmIL65816(InstructionSet.PLX | mx, 0);
                                    block[u + 1, iterationID] = new AsmIL65816(InstructionSet.TXA | mx, 0);
                                }
                                else if (block[u + 1].opcode == (InstructionSet.TAY | mx))
                                {
                                    // Entry: PLA + TAY
                                    // Return: PLY + TYA
                                    block[u + 0, iterationID] = new AsmIL65816(InstructionSet.PLY | mx, 0);
                                    block[u + 1, iterationID] = new AsmIL65816(InstructionSet.TYA | mx, 0);
                                }
                                else if (block[u + 1].opcode == (InstructionSet.PHA | mx))
                                {
                                    // Entry: PLA + PHA
                                    // Return: LDA 1,S
                                    block.RemoveAt(u, iterationID);
                                    block[u + 0, iterationID] = new AsmIL65816(InstructionSet.LDA_Sr | mx, 1);
                                }
                                break;
                            case InstructionSet.TXA | InstructionSet.mx:
                                if (block[u + 1].opcode == (InstructionSet.PHA | mx))
                                {
                                    // Entry: TXA + PHA
                                    // Return: TXA + PHX
                                    block[u + 1, iterationID] = new AsmIL65816(InstructionSet.PHX | mx, 0);
                                }
                                break;
                            case InstructionSet.TYA | InstructionSet.mx:
                                if (block[u + 1].opcode == (InstructionSet.PHA | mx))
                                {
                                    // Entry: TYA + PHA
                                    // Return: TYA + PHY
                                    block[u + 1, iterationID] = new AsmIL65816(InstructionSet.PHY | mx, 0);
                                }
                                break;
                        }
                    }
                }
            }

            return base.Iterate(sender, iterationID);
        }
    }
}
