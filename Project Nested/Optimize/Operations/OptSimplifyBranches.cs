using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize.Operations
{
    class OptSimplifyBranches : OptimizeOperation
    {
        public OptSimplifyBranches()
        {
            OperationName = "Simplify branches";
            OperationDescription = "Removes unnecessary branches and jumps.";
        }

        public override bool Iterate(OptimizeOperator sender, int iterationID)
        {
            for (int i = 0; i < sender.CodeBlockCount; i++)
            {
                CodeBlock block = sender.GetCodeBlock(i);
                if (block.HasChangedSince(this.previousIterationID))
                {
                    for (int u = 0; u < block.Count; u++)
                    {
                        var asm = block[u];
                        var mx = asm.opcode & InstructionSet.mx;

                        switch (asm.invariantOpcode)
                        {
                            case InstructionSet.BCC_Br8:
                            case InstructionSet.BCS_Br8:
                            case InstructionSet.BEQ_Br8:
                            case InstructionSet.BNE_Br8:
                            case InstructionSet.BVC_Br8:
                            case InstructionSet.BVS_Br8:
                            case InstructionSet.BPL_Br8:
                            case InstructionSet.BMI_Br8:
                                // Are we branching over a JMP?
                                if (u == block.Count - 2 &&
                                    block[u + 1].invariantOpcode == (InstructionSet.JMP_Jmp16) &&
                                    sender.FindBlockByLabel(asm.labelNum) == i + 1)
                                {
                                    // Merge branche+jump into a single branch
                                    sender.DecLabelUsageCount(block[u + 0].labelNum);
                                    var newAsm = new AsmIL65816((int)block[u + 0].opcode ^ 0x20, block[u + 1].operand);
                                    block.RemoveAt(u, iterationID);
                                    block[u, iterationID] = newAsm;
                                }
                                break;
                            case InstructionSet.BRA_Br8:
                                break;
                            case InstructionSet.JMP_Jmp16:
                                break;
                        }
                    }
                }

                // Is the last opcode jumping to the next block?
                if (i < sender.CodeBlockCount - 1)
                {
                    var asm = block[block.Count - 1];
                    var desc = asm.GetDescription();
                    switch (desc.type)
                    {
                        case OperandType.BrLabel:
                        case OperandType.JmpLabel:
                            {
                                var block2 = sender.GetCodeBlock(i + 1);
                                if (block2[0].labelNum == asm.labelNum)
                                {
                                    // Remove branch/jump
                                    sender.DecLabelUsageCount(asm.labelNum);
                                    block.RemoveAt(block.Count - 1, iterationID);
                                }
                            }
                            break;
                    }
                }
            }

            return base.Iterate(sender, iterationID);
        }
    }
}
