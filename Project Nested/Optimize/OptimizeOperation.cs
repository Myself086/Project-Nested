using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize
{
    class OptimizeOperation
    {
        public string OperationName { protected set; get; } =  "Unnamed operation";
        public string OperationDescription { protected set; get; } = "(No description)";

        /// <summary>
        /// Each change produces an iterationID
        /// </summary>
        public int previousIterationID = -1;

        /// <summary>
        /// Each object is given an optimizeID by the operator
        /// </summary>
        public int optimizeID;

        /// <summary>
        /// True when an operation is pending, forcing the operator to continue even if nothing happens with every other operations.
        /// This value is set to false by the operator before calling Iterate().
        /// </summary>
        public bool pendingOperation;

        /// <summary>
        /// Returns whether changes have been made
        /// </summary>
        /// <param name="iterationID"></param>
        /// <returns></returns>
        public virtual bool Iterate(OptimizeOperator op, int iterationID)
        {
            previousIterationID = iterationID;

            // Default code for detecting changes
            for (int i = 0; i < op.CodeBlockCount; i++)
            {
                if (op.GetCodeBlock(i).HasChangedOn(iterationID))
                    return true;
            }

            return false;
        }
    }
}
