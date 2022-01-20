using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize.Operations
{
    class OptRemoveCode : OptimizeOperation
    {
        public OptRemoveCode()
        {
            OperationName = "Remove code";
            OperationDescription =
                "Evaluates the changes made by each instruction and identifies which changes are either" +
                " used or changed before used. If all changes are unused, the instruction is removed.";
        }

        public override bool Iterate(OptimizeOperator sender, int iterationID)
        {
            for (int i = 0; i < sender.CodeBlockCount; i++)
            {
                CodeBlock block = sender.GetCodeBlock(i);
                //if (block.HasChangedSince(this.previousIterationID))
                {
                    // Loop backward because we are removing some code
                    //  and also removing chained useless dependencies.
                    // Ends at index 1 because 0 is always label.
                    for (int u = block.Count - 1; u >= 1; u--)
                    {
                        var asm = block[u];
                        var mx = asm.opcode & InstructionSet.mx;
                        var desc = asm.GetDescription();

                        var change = desc.change;

                        if (!change.HasFlag(FlagAndRegs.End) && !sender.IsOpcodeUseful(sender, i, u + 1, change))
                        {
                            // Remove opcode
                            block.RemoveAt(u, iterationID);

                            // Request another iteration after this one
                            this.pendingOperation = true;
                        }
                    }
                }
            }

            return base.Iterate(sender, iterationID);
        }
    }
}
