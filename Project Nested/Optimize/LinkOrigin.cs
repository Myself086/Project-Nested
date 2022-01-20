using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize
{
    struct LinkOrigin
    {
        public ushort rtn { private set; get; }
        public ushort call { private set; get; }
        public int wholeData { get => rtn | (call << 16); }

        public LinkOrigin(int originalReturn, int originalCall)
        {
            this.rtn = (ushort)originalReturn;
            this.call = (ushort)originalCall;
        }

        public static bool operator ==(LinkOrigin a, LinkOrigin b) => a.wholeData == b.wholeData;
        public static bool operator !=(LinkOrigin a, LinkOrigin b) => a.wholeData != b.wholeData;

        public override bool Equals(object obj)
        {
            if (obj is LinkOrigin other)
                return this.wholeData == other.wholeData;
            else
                return false;
        }
    }
}
