using Project_Nested.Injection;
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

        Raw65816 rawCode;
        List<CodeBlock> code;

        public int nesAddress { get => rawCode.nesAddress; }
        public int compileFlags { get => rawCode.compileFlags; }

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

        bool? isInlineAble;                     // Cached answer for IsInlineAble()
        bool returnAddressRequired;             // Cached answer for IsReturnAddressRequired()
        List<CallLocation> inlineCandidates;    // Cached answer for GetInlineCandidates()
        int? byteCount;                         // Cached answer for CountBytes()

        List<int> inlineExcluded = new List<int>();

        public struct CallLocation
        {
            public int block, line, callDestination;

            public CallLocation(int block, int line, int callDestination)
            {
                this.block = block;
                this.line = line;
                this.callDestination = callDestination;
            }
        }

        Injector injector;

        public OptimizeOperator()
        {
            Constructor(null);
        }

        /*public OptimizeOperator(string[] operations, List<CodeBlock> code)
        {
            this.code = code;

            Constructor(operations);
        }*/

        public OptimizeOperator(string[] operations, Raw65816 rawCode, Injector injector)
        {
            this.injector = injector;

            // Convert code to IL
            code = CodeBlock.SplitCode(rawCode.ConvertToIL(injector));

            this.rawCode = rawCode;

            Constructor(operations);
        }

        private void Constructor(string[] operations)
        {
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

        public void Optimize(CancellationToken? ct, bool keepRecord)
        {
            ResetCache();

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
        }

        public void MarkReturns(OptimizeGroup sender, byte nesBank)
        {
            ResetCache();

            for (int i = 0; i < this.CodeBlockCount; i++)
            {
                CodeBlock block = this.GetCodeBlock(i);
                for (int u = block.Count - 1; u >= 0; u--)
                {
                    var asm = block[u];
                    if (asm.opcode == InstructionSet.JSR_Nes || asm.opcode == InstructionSet.JSR_Nes_Static)
                    {
                        var rtn = asm.originalReturn | (nesBank << 16);
                        if (sender == null || sender.AddReturnMarker(rtn))
                            block.Insert(u + 1, new AsmIL65816(InstructionSet.ReturnMarker, rtn), iterationID);
                    }
                }
            }
        }

        public void Inline(CallLocation call, OptimizeOperator target)
        {
            // Get code block that we need to work with
            var block = GetCodeBlock(call.block);

            // Get call code, the actual line will be removed but accessible through this variable
            var callCode = block[call.line];

            // Do we need a return address?
            bool pushReturn;
            if (callCode.opcode == InstructionSet.JMP_Nes_Static)
                pushReturn = false;
            else if (callCode.opcode == InstructionSet.JSR_Nes_Static)
                pushReturn = target.IsReturnAddressRequired();
            else
                throw new InvalidOperationException("Attempted to inline from an invalid source.");

            // Pushing native return isn't supported for inline
            if (pushReturn && (target.rawCode.compileFlags & 0x4) == 0)
            {
                inlineExcluded.Add(call.callDestination);
                return;
            }

            // Remove call
            block.RemoveAt(call.line, iterationID);

            // Add return label
            var returnLabel = NewLabel();
            block.Insert(call.line, new AsmIL65816(InstructionSet.Label, returnLabel), iterationID);
            if (pushReturn)
                block.InsertRange(call.line + 1,
                    new AsmIL65816[]
                    {
                        // Fix stack (TODO: Add new IL opcode PLZ)
                        new AsmIL65816(InstructionSet.PHP | InstructionSet.mx),
                        new AsmIL65816(InstructionSet.STA_Sr | InstructionSet.mx, 2),
                        new AsmIL65816(InstructionSet.PLA | InstructionSet.mx),
                        new AsmIL65816(InstructionSet.STA_Sr | InstructionSet.mx, 2),
                        new AsmIL65816(InstructionSet.PLA | InstructionSet.mx),
                        new AsmIL65816(InstructionSet.PLP | InstructionSet.mx),
                    },
                    iterationID);

            // Push return address if required
            if (pushReturn)
            {
                block.Insert(call.line, new AsmIL65816(InstructionSet.PEA_Abs | InstructionSet.mx, callCode.originalReturn), iterationID);
                call.line++;
            }

            // Get target's code
            var targetCode = target.GetCode();

            // Label translation dictionary
            var labelDict = new Dictionary<int, int>();         // <target's label number, new label number>
            int TranslateLabel(int labelNum)
            {
                if (labelDict.TryGetValue(labelNum, out int rtn))
                    return rtn;
                else
                {
                    rtn = NewLabel();
                    labelDict.Add(labelNum, rtn);
                    return rtn;
                }
            }

            // Fix target's code
            for (int i = targetCode.Count - 1; i >= 0; i--)     // Reversed because we are removing some lines
            {
                var asm = targetCode[i];
                var desc = asm.GetDescription();

                switch (asm.invariantOpcode)
                {
                    case InstructionSet.BCC_Br8:
                    case InstructionSet.BCS_Br8:
                    case InstructionSet.BEQ_Br8:
                    case InstructionSet.BMI_Br8:
                    case InstructionSet.BNE_Br8:
                    case InstructionSet.BPL_Br8:
                    case InstructionSet.BRA_Br8:
                    case InstructionSet.BVC_Br8:
                    case InstructionSet.BVS_Br8:
                    case InstructionSet.JMP_Jmp16:
                        if (!asm.opcode.HasFlag(InstructionSet.mod))
                            throw new Exception("Attempting to read unmodified opcode");
                        goto case InstructionSet.Label;
                    case InstructionSet.Label:
                        targetCode[i] = new AsmIL65816(asm.opcode, TranslateLabel(asm.labelNum));
                        break;
                    case InstructionSet.JMP_Emu:
                        {
                            var emuCall = Asm65816Dictionary.GetEmuCallByID(asm.operand);
                            if (emuCall.IsNesRts)
                                goto case InstructionSet.RTL;
                        }
                        break;
                    //case InstructionSet.RTI:
                    //case InstructionSet.RTS:
                    case InstructionSet.RTL:
                        targetCode[i] = new AsmIL65816(InstructionSet.BRA_Label, returnLabel);
                        break;
                    case InstructionSet.ReturnMarker:
                        // Remove this line
                        targetCode.RemoveAt(i);
                        break;
                }
            }

            // Finish inserting code
            block.InsertRange(call.line, targetCode, iterationID);
            SolveInconsistencies();

            // Reset cache before returning
            ResetCache();
        }

        // --------------------------------------------------------------------

        public void ExcludeInlineCandidate(int target)
        {
            inlineExcluded.Add(target);
            var list = GetInlineCandidates();
            list.RemoveAt(list.FindIndex(e => e.callDestination == target));
        }

        // --------------------------------------------------------------------

        private void ResetCache()
        {
            // Reset inline eligibility
            this.isInlineAble = null;
            this.inlineCandidates = null;
            this.byteCount = null;
        }

        public void BuildCache()
        {
            IsInlineAble();
            IsReturnAddressRequired();
            GetInlineCandidates();
            CountBytes();
        }

        public bool IsInlineAble()
        {
            if (isInlineAble != null)
                return isInlineAble.Value;

            for (int i = 0; i < this.CodeBlockCount; i++)
            {
                CodeBlock block = this.GetCodeBlock(i);
                {
                    for (int u = 1; u < block.Count; u++)
                    {
                        var asm = block[u];
                        var desc = asm.GetDescription();

                        if (desc.change.HasFlag(FlagAndRegs.InlineUnableSrc))
                            return (isInlineAble = false).Value;
                    }
                }
            }

            return (isInlineAble = IsReturnConsistent(out returnAddressRequired)).Value;
        }

        public bool IsReturnAddressRequired()
        {
            // TODO: Rebuild this
            return IsInlineAble() && returnAddressRequired;
        }

        public List<CallLocation> GetInlineCandidates()
        {
            if (inlineCandidates != null)
                return inlineCandidates;
            inlineCandidates = new List<CallLocation>();

            for (int i = 0; i < this.CodeBlockCount; i++)
            {
                CodeBlock block = this.GetCodeBlock(i);
                {
                    for (int u = 1; u < block.Count; u++)
                    {
                        var asm = block[u];
                        var desc = asm.GetDescription();

                        if (desc.change.HasFlag(FlagAndRegs.CanInlineDest))
                        {
                            var destination = asm.originalCall + (injector.GetStaticBankDestination(rawCode.nesAddress, asm.originalCall) << 16);
                            if (!inlineExcluded.Contains(destination))
                                inlineCandidates.Add(new CallLocation(i, u, destination));
                        }
                    }
                }
            }

            return inlineCandidates;
        }

        public int CountBytes()
        {
            if (this.byteCount != null)
                return this.byteCount.Value;

            int byteCount = 0;

            for (int i = 0; i < this.CodeBlockCount; i++)
            {
                CodeBlock block = this.GetCodeBlock(i);
                for (int u = 0; u < block.Count; u++)
                {
                    var asm = block[u];
                    var desc = asm.GetDescription();

                    byteCount += desc.byteCount;
                }
            }

            return (this.byteCount = byteCount).Value;
        }

        // --------------------------------------------------------------------

        public List<AsmIL65816> GetCode() => CodeBlock.ConvertToList(code);

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
                for (int i = 0; i < labelToBlock.Count; i++)
                    labelToBlock[i] = -1;

                for (int i = 0; i < code.Count; i++)
                {
                    var block = code[i];
                    labelToBlock[block[0].labelNum] = i;
                }

                // Check for error
                if (labelToBlock[label] < 0)
                    throw new Exception($"Can't find label {label} in sub-routine 0x{nesAddress:x6}");
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

                    // Split block
                    if (asm.opcode == InstructionSet.Label)
                    {
                        SplitBlock(i, u);
                        Log("Found inconsistent label placement.");
                        break;
                    }

                    // Remove dead code at the end of a block
                    /*var nextU = u + 1;
                    var desc = asm.GetDescription();
                    if (desc.change.HasFlag(FlagAndRegs.End) && nextU < block.Count)
                    {
                        block.RemoveRange(nextU, block.Count - nextU, iterationID);
                        Log("Found dead code at the end of a block.");
                    }*/
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

        private bool IsReturnConsistent(out bool outReturnAddressRequired)
        {
            const int DEFAULT_STACK_DEPTH = 0x00010000;
            int[] stackDepthByLabel = new int[0x10000];     // Not optimal size
            Queue<int> unsolvedLabels = new Queue<int>();

            // Mark entry label
            UpdateLabel(0, DEFAULT_STACK_DEPTH);

            void UpdateLabel(int label, int stackDepth)
            {
                var value = stackDepthByLabel[label];
                var result = value | stackDepth;
                if (result != value)
                {
                    stackDepthByLabel[label] = result;
                    if (!unsolvedLabels.Contains(label))
                        unsolvedLabels.Enqueue(label);
                }
            }

            bool returnAddressRequired = outReturnAddressRequired = false;

            while (unsolvedLabels.Count > 0)
            {
                int label = unsolvedLabels.Dequeue();
                var stackDepth = stackDepthByLabel[label];

                var blockNum = FindBlockByLabel(label);
                var block = GetCodeBlock(blockNum);

                void Pull()
                {
                    if ((stackDepth & 0xffff) != 0)
                        returnAddressRequired = true;
                }

                bool ValidPush()
                {
                    return ((stackDepth & 0x1ffff) == 0);
                }

                for (int u = 1; u < block.Count; u++)
                {
                    var asm = block[u];
                    var mx = asm.opcode & InstructionSet.mx;

                    switch (asm.invariantOpcode)
                    {
                        case InstructionSet.TSX:
                        case InstructionSet.TXS:
                            // Code should not be reachable
                            return false;
                        case InstructionSet.PEA_Abs:
                        case InstructionSet.PEI_Dp:
                        case InstructionSet.PER_Br16:
                        case InstructionSet.PHD:
                            stackDepth <<= 2;
                            if (!ValidPush()) return false;
                            break;
                        case InstructionSet.PHB:
                        case InstructionSet.PHK:
                        case InstructionSet.PHP:
                            stackDepth <<= 1;
                            if (!ValidPush()) return false;
                            break;
                        case InstructionSet.PHA:
                            stackDepth <<= ((int)mx & 0x20) != 0 ? 1 : 2;
                            if (!ValidPush()) return false;
                            break;
                        case InstructionSet.PHX:
                        case InstructionSet.PHY:
                            stackDepth <<= ((int)mx & 0x10) != 0 ? 1 : 2;
                            if (!ValidPush()) return false;
                            break;
                        case InstructionSet.PLD:
                            stackDepth >>= 2;
                            Pull();
                            break;
                        case InstructionSet.PLB:
                        case InstructionSet.PLP:
                            stackDepth >>= 1;
                            Pull();
                            break;
                        case InstructionSet.PLA:
                            stackDepth >>= ((int)mx & 0x20) != 0 ? 1 : 2;
                            Pull();
                            break;
                        case InstructionSet.PLX:
                        case InstructionSet.PLY:
                            stackDepth >>= ((int)mx & 0x10) != 0 ? 1 : 2;
                            Pull();
                            break;
                        case InstructionSet.BCC_Br8:
                        case InstructionSet.BCS_Br8:
                        case InstructionSet.BEQ_Br8:
                        case InstructionSet.BMI_Br8:
                        case InstructionSet.BNE_Br8:
                        case InstructionSet.BPL_Br8:
                        case InstructionSet.BRA_Br8:
                        case InstructionSet.BVC_Br8:
                        case InstructionSet.BVS_Br8:
                        case InstructionSet.JMP_Jmp16:
                            if (!asm.opcode.HasFlag(InstructionSet.mod))
                                throw new Exception("Attempting to read unmodified opcode");
                            UpdateLabel(asm.labelNum, stackDepth);
                            break;
                        case InstructionSet.JMP_Emu:
                            {
                                var call = Asm65816Dictionary.GetEmuCallByID(asm.operand);
                                if (call.IsNesRts)
                                    goto case InstructionSet.RTL;
                            }
                            break;
                        //case InstructionSet.RTI:
                        //case InstructionSet.RTS:
                        case InstructionSet.RTL:
                            if (stackDepth != DEFAULT_STACK_DEPTH)
                                return false;
                            break;
                        case InstructionSet.JMP_JmpIndLong:
                            {
                                var call = Asm65816Dictionary.GetEmuCall("JMPi");
                                if (call.address == asm.operand)
                                    returnAddressRequired = true;
                            }
                            break;
                        case InstructionSet.JMP_Nes:
                            returnAddressRequired = true;
                            break;
                    }
                }

                // Is this block continuing to the next block?
                {
                    var asm = block[block.Count - 1];
                    var desc = asm.GetDescription();
                    if (!desc.change.HasFlag(FlagAndRegs.End))
                    {
                        var asmNext = GetLineOfCode(blockNum + 1, 0);
                        if (asmNext.opcode == InstructionSet.Label)
                            UpdateLabel(asmNext.labelNum, stackDepth);
                    }
                }
            }

            outReturnAddressRequired = returnAddressRequired;

            return true;
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
