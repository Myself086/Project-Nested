using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize
{
    class CodeBlock
    {
        List<AsmIL65816> code;
        public int iterationID;

        public CodeBlock(List<AsmIL65816> code)
        {
            this.code = code;
        }

        public bool HasChangedSince(int sinceIterationID) => this.iterationID >= sinceIterationID;
        public bool HasChangedOn(int sinceIterationID) => this.iterationID == sinceIterationID;

        public static List<CodeBlock> SplitCode(List<AsmIL65816> code)
        {
            var blocks = new List<CodeBlock>();

            // Split code into blocks
            List<AsmIL65816> list = new List<AsmIL65816>();
            foreach (var item in code)
            {
                if (item.opcode == InstructionSet.Label)
                {
                    // Add list to the blocks
                    if (list.Count > 0)
                        blocks.Add(new CodeBlock(list));
                    // Make a new list
                    list = new List<AsmIL65816>();
                }
                // Add line of code to the list
                list.Add(item);
            }
            // Add final list to the blocks, whether it's empty or not
            blocks.Add(new CodeBlock(list));

            return blocks;
        }

        public static List<AsmIL65816> ConvertToList(List<CodeBlock> blocks) => ConvertToList(blocks, null);
        public static List<AsmIL65816> ConvertToList(List<CodeBlock> blocks, List<int> labelUsageCount)
        {
            var list = new List<AsmIL65816>();

            foreach (var block in blocks)
            {
                var label = block[0];
                if (labelUsageCount != null && label.opcode == InstructionSet.Label)
                {
                    label.labelLinkCount = labelUsageCount[label.labelNum];

                    var index = list.Count;
                    list.AddRange(block.code);
                    list[index] = label;
                }
                else
                    list.AddRange(block.code);
            }

            return list;
        }

        // --------------------------------------------------------------------

        public int Count { get => code.Count; }

        public AsmIL65816 this[int index]
        {
            get => Read(index);
        }

        public AsmIL65816 this[int index, int iterationID]
        {
            get => Read(index);
            set => Write(index, value, iterationID);
        }

        public AsmIL65816 Read(int index)
        {
            if ((uint)index < code.Count)
                return code[index];
            else
                return new AsmIL65816();
        }

        public void Write(int index, AsmIL65816 asm, int iterationID)
        {
            code[index] = asm;
            this.iterationID = iterationID;
        }

        public void Add(AsmIL65816 asm, int iterationID)
        {
            code.Add(asm);
            this.iterationID = iterationID;
        }

        public void AddRange(int index, IEnumerable<AsmIL65816> asm, int iterationID)
        {
            code.AddRange(asm);
            this.iterationID = iterationID;
        }

        public void Insert(int index, AsmIL65816 asm, int iterationID)
        {
            code.Insert(index, asm);
            this.iterationID = iterationID;
        }

        public void InsertRange(int index, IEnumerable<AsmIL65816> asm, int iterationID)
        {
            code.InsertRange(index, asm);
            this.iterationID = iterationID;
        }

        public void RemoveAt(int index, int iterationID)
        {
            code.RemoveAt(index);
            this.iterationID = iterationID;
        }

        public void RemoveRange(int index, int count, int iterationID)
        {
            code.RemoveRange(index, count);
            this.iterationID = iterationID;
        }

        public int Find(AsmIL65816 asm)
        {
            return code.FindIndex(e => e.opcode == asm.opcode && e.operand == e.operand);
        }

        public CodeBlock Split(int index, int iterationID)
        {
            this.iterationID = iterationID;

            var rtn = new List<AsmIL65816>(code.GetRange(index, code.Count - index));

            code.RemoveRange(index, code.Count - index);

            return new CodeBlock(rtn);
        }
    }
}
