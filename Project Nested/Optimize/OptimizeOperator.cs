using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Project_Nested.Optimize
{
    class OptimizeOperator
    {
        List<OptimizeOperation> opList = new List<OptimizeOperation>();

        public List<string> operationNames = new List<string>();

        List<CodeBlock> code;

        List<int> labelUsageCount;
        List<List<object>> labelLocks;
        List<int> labelToBlock;     // Convert label number to block number
        Stack<int> unusedLabelNums;
        int initialLabelCount;      // Used to avoid recycling original labels

        public List<Tuple<string, List<AsmIL65816>>> record;

        // Each operation making changes will increment iterationID
        //  iterationID 0 is reserved for "Original"
        public int iterationID { get; private set; } = 1;
        public const int iterationID_MaxValue = 0x1000;
        public bool TimeOut { get => iterationID >= iterationID_MaxValue; }

        public List<string> debugLog;

        int breakOnIteration;
        string breakOnOperation;

        public OptimizeOperator(string[] operations, List<AsmIL65816> code)
        {
            if (code != null)
                this.code = CodeBlock.SplitCode(code);

            void AddOp<T>(bool forced) where T : OptimizeOperation, new()
            {
                T op = new T();
                if (forced || operations == null || operations.Contains(op.OperationName))
                {
                    op.optimizeID = opList.Count;
                    opList.Add(op);

                    // Add to operation names
                    if (!forced)
                        operationNames.Add(op.OperationName);
                }
            }

            // Add operations to the list
            {
                AddOp<Operations.OptSimplifyBranches>(false);
                AddOp<Operations.OptRemoveLabels>(true);
            }
            AddOp<Operations.OptSolveConstants>(false);
            AddOp<Operations.OptUnrollLoops>(false);
            AddOp<Operations.OptDictionary>(false);
            AddOp<Operations.OptRemoveCode>(false);     // Must be last

            // Reverse list because indexes are looped backward
            opList.Reverse();
        }

        // --------------------------------------------------------------------

        public List<AsmIL65816> Optimize(CancellationToken? ct, bool keepRecord)
        {
            // Create a record of changes if requested
            if (keepRecord)
            {
                // Only allocate new records if one didn't exist because the task could've been previously cancelled
                if (record == null)
                {
                    record = new List<Tuple<string, List<AsmIL65816>>>();
                    record.Add(new Tuple<string, List<AsmIL65816>>("Original", CodeBlock.ConvertToList(code, labelUsageCount)));
                }
            }

            // Loop from top to bottom because objects can be removed
            int index = opList.Count - 1;       // Count-1
            int lastChangedIndex = -1;          // 0-1, auto cancels on loop entry if opList is empty

            while ((index != lastChangedIndex || opList.Find((e) => e.pendingOperation) != null))
            {
                // Cancel?
                ct?.ThrowIfCancellationRequested();

#if DEBUG
                if (iterationID == breakOnIteration && opList[index].OperationName == breakOnOperation)
                    Debugger.Break();
#endif

                // Call operation
                opList[index].pendingOperation = false;
                if (opList[index].Iterate(this, iterationID))
                {
                    // Operation produced changes
                    lastChangedIndex = index;
                    iterationID++;
                    if (keepRecord)
                        record.Add(new Tuple<string, List<AsmIL65816>>(opList[index].OperationName, CodeBlock.ConvertToList(code, labelUsageCount)));

                    // Time out?
                    if (TimeOut)
                        break;
                }

                // Next
                index--;
                if (index < 0)
                {
                    // Loop back to the top
                    index = opList.Count - 1;

                    // Is lastChangedIndex valid? If so, exit the loop
                    //  lastChangedIndex can only be invalid when the top operation is removed
                    //  or after the first cycle doesn't result in any changes
                    if ((uint)lastChangedIndex >= opList.Count)
                        break;
                }
            }

            return CodeBlock.ConvertToList(code);
        }

        public void SetBreakPoint(int iterationID, string operationName)
        {
            this.breakOnIteration = iterationID;
            this.breakOnOperation = operationName;
        }

        public int CodeBlockCount { get => code.Count; }

        public CodeBlock GetCodeBlock(int index) => (uint)index < code.Count ? code[index] : null;

        public CodeBlock InsertNewCodeBlock(int index, int newLabel)
        {
            var list = new List<AsmIL65816>() { new AsmIL65816(InstructionSet.Label, newLabel) };
            var block = new CodeBlock(list);
            code.Insert(index, block);
            block.iterationID = this.iterationID;

            return block;
        }

        public AsmIL65816 GetLineOfCode(int block, int line)
        {
            var b = GetCodeBlock(block);
            return b == null ? new AsmIL65816() : b[line];
        }

        public int FindBlockByLabel(int label)
        {
            if (labelToBlock == null)
                CountLabelUsage();

            // Load cached label's block
            var b = labelToBlock[label];
            // Verify label's block
            var asm = GetLineOfCode(b, 0);
            if (asm.labelNum == label && asm.opcode == InstructionSet.Label)
                return b;
            else
            {
                // Redo the whole cache
                CacheBlockLabels();
                return FindBlockByLabel(label);
            }

            void CacheBlockLabels()
            {
                for (int i = 0; i < code.Count; i++)
                {
                    var block = code[i];
                    labelToBlock[block[0].labelNum] = i;
                }
            }

            // Old, slower code
            for (int i = 0; i < code.Count; i++)
            {
                var block = code[i];
                if (block[0].labelNum == label && block[0].opcode == InstructionSet.Label)
                    return i;
            }

            // Label not found
            return -1;
        }

        public void SplitBlock(int block, int line)
        {
            if (GetLineOfCode(block, line).opcode != InstructionSet.Label)
                throw new Exception("Attempted to split code but a label is missing.");

            var b = GetCodeBlock(block);
            code.Insert(block + 1, b.Split(line, iterationID));
            code[block + 0].iterationID = iterationID;
            code[block + 1].iterationID = iterationID;
        }

        public void RemoveBlock(int i)
        {
            // Label must be removed within the block before removing the block
            if (code[i][0].opcode != InstructionSet.Label)
                code.RemoveAt(i);
            else
                throw new Exception("Attempted to remove block without removing its label.");
        }

        public void RemoveOperation(OptimizeOperation op)
        {
            opList.Remove(op);
        }

        private void CountLabelUsage()
        {
            labelUsageCount = new List<int>(new int[code.Count]);
            labelLocks = new List<List<object>>(new List<object>[code.Count]);
            labelToBlock = new List<int>(new int[code.Count]);
            initialLabelCount = code.Count;
            unusedLabelNums = new Stack<int>();

            // Add 1 to sub-routine's entry point
            labelUsageCount[0]++;

            foreach (var block in code)
            {
                for (int i = 0; i < block.Count; i++)
                {
                    var asm = block[i];
                    var desc = asm.GetDescription();
                    switch (desc.type)
                    {
                        case OperandType.BrLabel:
                        case OperandType.JmpLabel:
                            labelUsageCount[asm.labelNum]++;
                            break;
                    }
                }
            }
        }

        public int GetLabelUsageCount(int label)
        {
            if (labelUsageCount == null)
                CountLabelUsage();

            return (uint)label < labelUsageCount.Count ? labelUsageCount[label] : -1;
        }

        public int NewLabel()
        {
            if (labelUsageCount == null)
                CountLabelUsage();

            if (unusedLabelNums.Count > 0)
            {
                var label = unusedLabelNums.Pop();
                labelUsageCount[label] = 0;
                return label;
            }
            else
            {
                var label = labelUsageCount.Count;
                if (label > 0xffff)
                    throw new Exception("OptimizeOperator allocated too many labels.");
                labelUsageCount.Add(0);
                labelLocks.Add(null);
                labelToBlock.Add(0);
                return label;
            }
        }

        public void RemoveLabel(int label)
        {
            if (labelUsageCount == null)
                CountLabelUsage();

            if (GetLabelUsageCount(label) == 0)
            {
                labelUsageCount[label] = -1;    // Mark as undefined
                if (label >= initialLabelCount)
                    unusedLabelNums.Push(label);
            }
            else
                throw new Exception("Attempted to remove a used or undefined label.");
        }

        public int DecLabelUsageCount(int label)
        {
            if (labelUsageCount == null)
                CountLabelUsage();

            return --labelUsageCount[label];
        }

        public int IncLabelUsageCount(int label)
        {
            if (labelUsageCount == null)
                CountLabelUsage();

            return ++labelUsageCount[label];
        }

        public void DecLabelLockCount(object sender, int label)
        {
            if (labelLocks == null)
                CountLabelUsage();

            if (labelLocks[label] == null)
                return;

            if (labelLocks[label].Remove(sender))
                DecLabelUsageCount(label);
        }

        public void IncLabelLockCount(object sender, int label)
        {
            if (labelLocks == null)
                CountLabelUsage();

            if (labelLocks[label] == null)
                labelLocks[label] = new List<object>();
            labelLocks[label].Add(sender);

            IncLabelUsageCount(label);
        }

        // --------------------------------------------------------------------

        public void SolveInconsistencies()
        {
            // Reset label usage counts
            unusedLabelNums.Clear();        // TODO: Restore this list
            for (int i = 1; i < labelUsageCount.Count; i++)
                labelUsageCount[i] = 0;

            // Restore entry point
            labelUsageCount[0] = 1;

            // Restore locks
            for (int i = 0; i < labelLocks.Count; i++)
            {
                var locks = labelLocks;
                if (locks[i] != null)
                    labelUsageCount[i] += locks[i].Count;
            }

            // Split blocks containing more than 1 label
            for (int i = 0; i < CodeBlockCount; i++)
            {
                CodeBlock block = GetCodeBlock(i);

                // Is block starting with label? Throw error if not, this should never happen and must be fixed
                if (block[0].opcode != InstructionSet.Label)
                    throw new Exception("Label missing at the beginning of a block.");

                for (int u = 1; u < block.Count; u++)
                {
                    var asm = block[u];
                    var desc = asm.GetDescription();

                    // Split block
                    if (asm.opcode == InstructionSet.Label)
                    {
                        SplitBlock(i, u);
                        Log("Found inconsistent label placement.");
                        break;
                    }

                    // Remove dead code at the end of a block
                    var nextU = u + 1;
                    if (desc.change.HasFlag(FlagAndRegs.End) && nextU < block.Count)
                    {
                        block.RemoveRange(nextU, block.Count - nextU, iterationID);
                        Log("Found dead code at the end of a block.");
                    }
                }
            }

            // List which labels need to be tested
            var labelsToTest = new Stack<int>();
            for (int i = 0; i < labelUsageCount.Count; i++)
            {
                if (labelUsageCount[i] > 0)
                    labelsToTest.Push(i);
            }

            // Find live blocks
            var validBlocks = new bool[code.Count];
            //var validLabels = new bool[code.Count];
            while (labelsToTest.Count > 0)
            {
                var label = labelsToTest.Pop();

                for (int i = FindBlockByLabel(label); i < CodeBlockCount; i++)
                {
                    CodeBlock block = GetCodeBlock(i);

                    // Validate this block
                    if (validBlocks[i])
                        // Already valid
                        break;
                    else
                    {
                        validBlocks[i] = true;

                        // Validate every label destinations
                        for (int u = 1; u < block.Count; u++)
                        {
                            var asm = block[u];
                            var desc = asm.GetDescription();

                            switch (desc.type)
                            {
                                case OperandType.BrLabel:
                                case OperandType.JmpLabel:
                                    if (IncLabelUsageCount(asm.labelNum) == 1)
                                        labelsToTest.Push(asm.labelNum);
                                    break;
                            }
                        }
                    }

                    // Can we keep moving forward?
                    {
                        var lastAsm = block[block.Count - 1];
                        var desc = lastAsm.GetDescription();

                        if (desc.change.HasFlag(FlagAndRegs.End))
                            break;
                    }
                }
            }

            // Remove dead blocks, reversed loop because we are removing elements
            for (int i = CodeBlockCount - 1; i >= 0; i--)
            {
                if (!validBlocks[i])
                {
                    code.RemoveAt(i);
                    Log("Removed dead code block.");
                }
            }
        }

        // --------------------------------------------------------------------

        // This list belongs to IsOpcodeUseful but is being recycled
        List<Tuple<int, int>> branchesTaken;

        public bool IsOpcodeUseful(OptimizeOperator sender, int block, int line, FlagAndRegs change)
        {
            if (branchesTaken == null)
                branchesTaken = new List<Tuple<int, int>>();
            branchesTaken.Clear();

            return IsOpcodeUsefulRecursive(sender, block, line, change);
        }

        private bool IsOpcodeUsefulRecursive(OptimizeOperator sender, int block, int line, FlagAndRegs change)
        {
            const FlagAndRegs INELIGIBLE_CHANGE =
                FlagAndRegs.PC | FlagAndRegs.DB | FlagAndRegs.SP |
                FlagAndRegs.Interrupt | FlagAndRegs.Decimal | FlagAndRegs.Memory | FlagAndRegs.Index |
                FlagAndRegs.Exception | FlagAndRegs.End | FlagAndRegs.Marker | FlagAndRegs.Write;

            if ((change & INELIGIBLE_CHANGE) != 0) //(change.HasFlag(INELIGIBLE_CHANGE))
                return true;

            change &= FlagAndRegs.CompareMask;

            ThrowIfBlockOutOfRange();

            NextBlockIfLineOverflows();

            while (true)
            {
                var asm = sender.GetLineOfCode(block, line);
                var desc = asm.GetDescription();

                // P related exception (TODO: Add modified PHP and PLP)
                if (desc.change.HasFlag(FlagAndRegs.P))
                {
                    // Apply proper flag usage/change
                    switch (desc.type)
                    {
                        case OperandType.FlagUsage: desc.usage |= (FlagAndRegs)asm.operand; break;
                        case OperandType.FlagChange: desc.change |= (FlagAndRegs)asm.operand; break;
                    }
                }

                // XBA exception
                if (asm.invariantOpcode == InstructionSet.XBA)
                {
                    // Swap A and Ah
                    var newChange = change & ~(FlagAndRegs.A | FlagAndRegs.Ah);
                    if (change.HasFlag(FlagAndRegs.A)) newChange |= FlagAndRegs.Ah;
                    if (change.HasFlag(FlagAndRegs.Ah)) newChange |= FlagAndRegs.A;
                    change = newChange;
                }

                // Are there used changes from this opcode?
                if ((change & desc.usage) != 0)
                    return true;

                // Remove unused changes
                change &= ~desc.change;

                // Are there any changes left?
                if (change == FlagAndRegs.None)
                    return false;

                // Is this opcode changing PC? Was this branch taken already?
                if ((desc.type == OperandType.JmpLabel || desc.type == OperandType.BrLabel) &&
                    desc.change.HasFlag(FlagAndRegs.PC) && !branchesTaken.Contains(new Tuple<int, int>(block, line)))
                {
                    // Add to list of branch taken so we don't take it again
                    branchesTaken.Add(new Tuple<int, int>(block, line));

                    // Do a recursive call
                    if (IsOpcodeUsefulRecursive(sender, sender.FindBlockByLabel(asm.labelNum), 0, change))
                        // If something was found from the recursive call, return true immediately
                        return true;
                }

                // Is this opcode ending execution?
                if (desc.change.HasFlag(FlagAndRegs.End))
                    return true;

                // Next line
                line++;

                // Next block
                NextBlockIfLineOverflows();
            }

            void NextBlockIfLineOverflows()
            {
                ThrowIfBlockOutOfRange();

                var b = sender.GetCodeBlock(block);
                if (line >= b.Count)
                {
                    block++;
                    line = 1;   // Skip label on index 0

                    // Redo in case this block is empty
                    NextBlockIfLineOverflows();
                }
            }

            void ThrowIfBlockOutOfRange()
            {
                if ((uint)block >= sender.CodeBlockCount)
                    throw new IndexOutOfRangeException("'IsOpcodeUseful' attempted to read a code block out of range.");
            }
        }

        // --------------------------------------------------------------------

        public void Log(string text)
        {
            if (debugLog != null)
                debugLog.Add($"{iterationID} - {text}");
        }
    }
}
