using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize.Operations
{
    class OptRemoveLabels : OptimizeOperation
    {
        public OptRemoveLabels()
        {
            OperationName = "Remove labels";
            OperationDescription = "Removes unused labels and merges blocks together.";
        }

        public override bool Iterate(OptimizeOperator sender, int iterationID)
        {
            // Looping blocks backward because they can be removed during the loop
            for (int i = sender.CodeBlockCount - 1; i >= 0; i--)
            {
                CodeBlock block = sender.GetCodeBlock(i);

                // Read first line in the list, assuming it's always a label
                var label = block[0];
                var labelNum = label.labelNum;

                // Get usage count for this label
                var count = sender.GetLabelUsageCount(labelNum);

                if (count == 0)
                {
                    // Remove label
                    sender.RemoveLabel(labelNum);
                    block.RemoveAt(0, iterationID);

                    // Merge with previous block
                    var block2 = sender.GetCodeBlock(i - 1);
                    if (block2 != null)
                    {
                        for (int u = 0; u < block.Count; u++)
                            block2.Add(block[u], iterationID);

                        // Remove block
                        sender.RemoveBlock(i);
                    }
                }
            }

            return base.Iterate(sender, iterationID);
        }
    }
}
