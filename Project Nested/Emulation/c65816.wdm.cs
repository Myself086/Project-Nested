using Project_Nested.Optimize;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Emulation
{
    public partial class c65816
    {
        Stack<byte[]> byteArrays = new Stack<byte[]>();
        Dictionary<int, MakeBinary> funcList = new Dictionary<int, MakeBinary>();
        MakeBinary lastRequestedFunction;

        public List<int> feedback;

        internal void AddFunctionCode(List<MakeBinary> make)
        {
            foreach (var item in make)
                AddFunctionCode(item);
        }

        internal void AddFunctionCode(MakeBinary make)
        {
            funcList[make.nesAddress] = make;
        }

        public void PushByteArray(byte[] data) => byteArrays.Push(data);
        public byte[] PullByteArray()
        {
            if (byteArrays.Count > 0)
                return byteArrays.Pop();
            else
                return null;
        }

        void op___WDM(Int32 i)
        {
            i = memory.ReadOneByte(i);

            switch (i)
            {
                case 0x00:  // WDM_TestCommunication
                    {
                        // Returns:
                        //  A = exe version in decimal (example: v1.23.45 -> 12345)
                        var version = Assembly.GetEntryAssembly().GetName().Version;
                        if (version.Major > 5 || version.Minor > 99 || version.Build > 99)
                            throw new Exception("Version number exceeds 5.99.99");
                        SetRegA(version.Major * 10000 + version.Minor * 100 + version.Build * 1);

                        //  Overflow = set when exe is in debug mode
#if debug
                        setflag_v(-1);
#else
                        setflag_v(0);
#endif

                        //  Carry = set
                        setflag_c(-1);
                    }
                    break;
                case 0x01:  // WDM_PushByteArray
                    {
                        // Entries:
                        //  A = Address
                        //  X = Length
                        //  Y = Address bank
                        int addr = (GetRegA() | (GetRegY() << 16)) & 0xffffff;
                        int length = GetRegX();

                        // Copy data from emulator
                        var data = new byte[length];
                        for (i = 0; i < length; i++)
                        {
                            data[i] = memory.DebugReadOneByte(addr + i);
                        }
                        byteArrays.Push(data);
                    }
                    break;
                case 0x02:  // WDM_PullByteArray
                    {
                        // Entries:
                        //  A = Address
                        //  Y = Address bank
                        int addr = (GetRegA() | (GetRegY() << 16)) & 0xffffff;
                        // Returns:
                        //  X = Length

                        //  Carry = set when successful
                        bool success = byteArrays.Count > 0;
                        setflag_c(success ? -1 : 0);
                        if (success)
                        {
                            // Copy data to exe
                            var data = byteArrays.Pop();
                            var length = data.Length;
                            for (i = 0; i < length; i++)
                            {
                                memory.DebugWriteOneByte(addr + i, data[i]);
                            }
                        }
                    }
                    break;
                case 0x03:  // WDM_PeekByteArray
                    {
                        // Returns:
                        //  X = Length
                        //  Carry = set when successful
                        bool success = byteArrays.Count > 0;
                        setflag_c(success ? -1 : 0);
                        if (success)
                        {
                            var data = byteArrays.Peek();
                            SetRegX(data.Length);
                        }
                    }
                    break;
                case 0x04:  // WDM_RequestFunction
                    {
                        // Entries:
                        //  A = Address
                        //  Y = Address bank
                        int addr = (GetRegA() | (GetRegY() << 16)) & 0xffffff;

                        MakeBinary make;
                        bool success = funcList.TryGetValue(addr, out make);
                        if (success)
                        {
                            lastRequestedFunction = make;
                            // Returns:
                            //  byte[] = Function code
                            byteArrays.Push(make.code);
                            //  A = Entry point offset
                            SetRegA(make.entryPoint);
                            //  X = Compile flags
                            SetRegX(make.compileFlags);
                            //  Y = Bank number to allocate in (0 when unspecified)
                            SetRegY(make.snesBankReservation);
                        }

                        //  Carry = set when successful
                        setflag_c(success ? -1 : 0);
                    }
                    break;
                case 0x05:  // WDM_SetFunctionSnesAddress
                    // Entries:
                    //  A = Address
                    //  Y = Address bank
                    lastRequestedFunction.snesAddress = (GetRegA() | (GetRegY() << 16)) & 0xffffff;
                    break;
                case 0x06:  // WDM_AddFeedback
                    // Entries:
                    //  X = Address
                    //  Y = Address bank
                    if (feedback == null)
                        feedback = new List<int>();
                    feedback.Add((GetRegX() | (GetRegY() << 16)) & 0xffffff);
                    break;

                    // Cases 0xff and descending are reserved for private debugging tools
            }
        }
    }
}
