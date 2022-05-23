using Project_Nested.Emulation;
using Project_Nested.Injection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested
{
    class EmulatorPool
    {
        public byte[] romData;

        bool initStaticRec;

        // This stack is thread safe
        Stack<c65816> emuList = new Stack<c65816>();

        public EmulatorPool(byte[] romData, bool initStaticRec)
        {
            this.romData = (byte[])romData.Clone();
            this.initStaticRec = initStaticRec;
        }

        public c65816 PullEmu()
        {
            // Safely pull emulator from stack
            lock (emuList)
            {
                if (emuList.Count > 0)
                    return emuList.Pop();
            }

            // Stack is empty, create a new emulator
            return NewEmulator();
        }

        public void PushEmu(c65816 emu)
        {
            // Safely push emulator to stack
            lock (emuList)
            {
                emuList.Push(emu);
            }
        }

        public c65816 NewEmulator()
        {
            var emu = new c65816(romData, null);
            if (initStaticRec)
                emu.ExecuteInit(null);
            return emu;
        }
    }
}
