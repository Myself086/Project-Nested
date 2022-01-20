using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize.Operations
{
    class OptUnrollLoops : OptimizeOperation
    {
        List<int> completedLoops = new List<int>();
        List<PendingLoop> pendingLoops = new List<PendingLoop>();

        struct PendingLoop
        {
            public int labelNewStart;           // Should be locked before placing in the list
            public int labelNewExit;
            public List<AsmIL65816> blockClone;
            public AsmIL65816 branch;

            public PendingLoop(int labelNewStart, int labelNewExit, List<AsmIL65816> blockClone, AsmIL65816 branch)
            {
                this.labelNewStart = labelNewStart;
                this.labelNewExit = labelNewExit;
                this.blockClone = blockClone;
                this.branch = branch;
            }
        }

        public OptUnrollLoops()
        {
            OperationName = "Unroll loops";
            OperationDescription = "Unrolls loops where time can be saved by taking work off of a loop or not having to count iterations.";
        }

        public override bool Iterate(OptimizeOperator sender, int iterationID)
        {
            bool requestSolveInconsistencies = false;

            if (pendingLoops.Count > 0)
            {
                for (int i = pendingLoops.Count - 1; i >= 0; i--)
                {
                    var loop = pendingLoops[i];
                    var blockIndex = sender.FindBlockByLabel(loop.labelNewStart);

                    // Has our unrolled code changed?
                    var block1 = sender.GetCodeBlock(sender.FindBlockByLabel(loop.labelNewStart) - 1);
                    var top1 = block1.Count - 1;
                    var block2 = loop.blockClone;
                    var top2 = block2.Count - 1;
                    bool pass = true;
                    for (int u = 0; u < block2.Count; u++)
                    {
                        if (block1[top1 - u] != block2[top2 - u])
                        {
                            pass = false;
                            break;
                        }
                    }

                    // If code matched, reroll the loop and ignore it moving forward
                    if (pass)
                    {
                        block1.RemoveRange(block1.Count - block2.Count, block2.Count, iterationID);
                        completedLoops.Add(loop.labelNewStart);

                        // Decrement branch usage
                        foreach (var asm in block2)
                        {
                            var desc = asm.GetDescription();
                            switch (desc.type)
                            {
                                case OperandType.BrLabel:
                                case OperandType.JmpLabel:
                                    sender.DecLabelUsageCount(asm.labelNum);
                                    break;
                            }
                        }
                    }
                    else if (sender.GetLabelUsageCount(loop.labelNewExit) > 0)
                        completedLoops.Add(loop.labelNewStart);

                    // Remove pending loop
                    sender.DecLabelLockCount(this, loop.labelNewStart);
                    pendingLoops.RemoveAt(i);
                }

                sender.SolveInconsistencies();
            }

            for (int i = 0; i < sender.CodeBlockCount; i++)
            {
                CodeBlock block = sender.GetCodeBlock(i);
                //if (block.HasChangedSince(this.previousIterationID))
                {
                    var labelAsm = block[0];
                    for (int u = 1; u < block.Count; u++)
                    {
                        var asm = block[u];
                        var mx = asm.opcode & InstructionSet.mx;

                        if (((int)asm.invariantOpcode & ~0xe0) == ((int)InstructionSet.BPL_Br8 & ~0xe0))    // Quick if conditional branch
                        {
                            // TODO: Find label in upper blocks
                            if (asm.labelNum == labelAsm.labelNum)
                            {
                                // Have we processed this label yet?
                                if (!completedLoops.Contains(asm.labelNum)) //&& !pendingLoops.Contains(asm.labelNum))
                                {
                                    // Unroll once
                                    var newLabel1 = sender.NewLabel();
                                    var block2 = sender.InsertNewCodeBlock(i, newLabel1);
                                    var block2Clone = new List<AsmIL65816>();
                                    i++;

                                    // Change loop branch to the new label
                                    sender.DecLabelUsageCount(asm.labelNum);
                                    asm.labelNum = newLabel1;
                                    sender.IncLabelUsageCount(asm.labelNum);
                                    block[u, iterationID] = asm;

                                    // Swap loop start labels
                                    //if (false)
                                    {
                                        var swap = block[0];
                                        block[0, iterationID] = block2[0];
                                        block2[0, iterationID] = swap;
                                    }

                                    // Copy code
                                    for (int k = 1; k < u; k++)
                                    {
                                        block2.Add(block[k], iterationID);
                                        block2Clone.Add(block[k]);
                                    }

                                    // Add label after the loop
                                    var newLabel2 = sender.NewLabel();
                                    block.Insert(u + 1, new AsmIL65816(InstructionSet.Label, newLabel2), iterationID);
                                    sender.IncLabelUsageCount(newLabel2);
                                    sender.SplitBlock(i, u + 1);

                                    // Add modified condition for looping back, except we exit the loop on opposite condition
                                    var modifiedAsm = asm;
                                    modifiedAsm.opcode ^= (InstructionSet)0x20;     // Reverse condition
                                    modifiedAsm.labelDirectionDown = true;
                                    modifiedAsm.labelNum = newLabel2;
                                    block2.Add(modifiedAsm, iterationID);
                                    block2Clone.Add(modifiedAsm);

                                    // Add this label to pending loops for evaluation later
                                    pendingLoops.Add(new PendingLoop(newLabel1, newLabel2, block2Clone, modifiedAsm));
                                    sender.IncLabelLockCount(this, newLabel1);      // Prevents label from being removed

                                    // Lazy fix for something I'm doing wrong above
                                    //requestSolveInconsistencies = true;
                                }
                            }
                        }
                    }
                }
            }

            this.pendingOperation = pendingLoops.Count > 0;

            if (requestSolveInconsistencies)
                sender.SolveInconsistencies();

            return base.Iterate(sender, iterationID);
        }
    }
}
