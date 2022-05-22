using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Optimize
{
    public struct EmulatorCall
    {
        public string name { private set; get; }
        public int address { private set; get; }
        public OpcodeDescription desc { private set; get; }
        public int id { private set; get; }

        public const string NES_JSR = "Interpret__Jsr";
        public bool IsNesJsr { get => desc.change.HasFlag(FlagAndRegs.Exception) && name == NES_JSR; }
        public const string NES_RTS = "RtsNes";
        public bool IsNesRts { get => desc.change.HasFlag(FlagAndRegs.Exception) && name == NES_RTS; }

        public EmulatorCall(string name, int address, FlagAndRegs usage, FlagAndRegs change, int id)
        {
            this = new EmulatorCall()
            {
                name = name,
                address = address,
                desc = new OpcodeDescription("Call", OperandType.CallEmu, usage, change),
                id = id,
            };
        }

        public static EmulatorCall Unknown()
        {
            return new EmulatorCall()
            {
                name = "???",
                address = 0,
                desc = new OpcodeDescription("JSR", OperandType.Jmp24, FlagAndRegs.None, FlagAndRegs.PC),
                id = 0,
            };
        }
    }
}
