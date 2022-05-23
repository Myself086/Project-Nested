using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Emulation
{
    class IO
    {
        public bool ignoreError = false;

        public bool irqEnabled = false;

        private Int16[] iomem = new Int16[0x10000];

        private Memory memory;

        public Int32 input1, input2;

        // Hardware mul & div
        public const Int32 WRMPYA = 0x4202;
        public const Int32 WRMPYB = 0x4203;
        public const Int32 WRDIVL = 0x4204;
        public const Int32 WRDIVH = 0x4205;
        public const Int32 WRDIVB = 0x4206;
        public const Int32 RDDIVL = 0x4214;
        public const Int32 RDDIVH = 0x4215;
        public const Int32 RDMPYL = 0x4216;
        public const Int32 RDMPYH = 0x4217;

        delegate byte DelIOr8(Int32 addr);
        delegate void DelIOw8(Int32 addr, byte data);

        DelIOr8[] IOread8 = new DelIOr8[0x10000];
        DelIOw8[] IOwrite8 = new DelIOw8[0x10000];

        public IO(Memory memory)
        {
            this.memory = memory;

            // Default
            for (int i = 0; i < 0x10000; i++)
            {
                IOread8[i] = Error_r8;
                IOwrite8[i] = Error_w8;
            }

            // Ignore uploading to PPU
            for (int i = 0x2100; i <= 0x2133; i++)
                IOwrite8[i] = Ignore_w8;

            // Ignore reading from PPU
            IOread8[0x213b] = Ignore_r8;

            // PPU timing (TODO: Support this for PPUSTATUS emulation)
            IOread8[0x2137] = Ignore_r8;
            IOread8[0x213d] = Ignore_r8;

            // Ignore Audio ports
            for (int i = 0x2140; i <= 0x217f; i++)
            {
                IOwrite8[i] = Ignore_w8;
                IOread8[i] = Ignore_r8;
            }
            // Zero constant from last audio port, used to read 0x2180 as MSB in 16-bit mode
            IOread8[0x217f] = Ignore_r8;

            // WRAM access
            IOread8[0x2180] = IO_2180_r8;
            IOwrite8[0x2180] = IO_2180_w8;
            IOwrite8[0x2181] = IO_2181_w8;
            IOwrite8[0x2182] = IO_2182_w8;
            IOwrite8[0x2183] = IO_2183_w8;

            // Controller input
            IOread8[0x4016] = IO_4016_r8;
            IOread8[0x4017] = IO_4017_r8;
            IOwrite8[0x4016] = IO_4016_w8;
            IOwrite8[0x4017] = Ignore_w8;

            // Interrupt related
            IOwrite8[0x4200] = IO_4200_w8;
            IOwrite8[0x4207] = Ignore_w8;
            IOwrite8[0x4208] = Ignore_w8;
            IOwrite8[0x4209] = Ignore_w8;
            IOwrite8[0x420a] = Ignore_w8;
            IOread8[0x4210] = IO_4210_r8;
            IOread8[0x4211] = IO_4211_r8;
            IOread8[0x4212] = IO_4212_r8;

            // Hardware multiple and divide
            IOwrite8[0x4202] = Regular_w8;
            IOwrite8[0x4203] = IO_4203_w8;
            IOwrite8[0x4204] = Regular_w8;
            IOwrite8[0x4205] = Regular_w8;
            IOwrite8[0x4206] = IO_4206_w8;
            IOread8[0x4214] = Regular_r8;
            IOread8[0x4215] = Regular_r8;
            IOread8[0x4216] = Regular_r8;
            IOread8[0x4217] = Regular_r8;

            // Ignore FastROM
            IOread8[0x420d] = Ignore_r8;
            IOwrite8[0x420d] = Ignore_w8;

            // DMA
            IOwrite8[0x420b] = IO_420b_w8;
            IOwrite8[0x420c] = Ignore_w8;
            for (int i = 0x4300; i <= 0x437b; i++)
            {
                if ((i & 0xc) != 0xc)
                {
                    IOwrite8[i] = Regular_w8;
                    IOread8[i] = Regular_r8;
                }
            }
        }

        public byte ReadOneByte(Int32 addr)
        {
            return IOread8[(UInt16)addr]((UInt16)addr);
        }

        public void WriteOneByte(Int32 addr, byte data)
        {
            IOwrite8[(UInt16)addr]((UInt16)addr, data);
        }

        // --------------------------------------------------------------------

        byte IO_2180_r8(Int32 addr)
        {
            Int32 mem = (UInt16)(iomem[0x2181]) + (iomem[0x2183] << 16) + 0x7e0000;
            addr = memory.map[mem >> 13] + (mem);
            mem++;
            iomem[0x2181] = (Int16)(mem);
            return (byte)memory.ReadOneByte(addr);
        }

        void IO_2180_w8(Int32 addr, byte data)
        {
            Int32 mem = (UInt16)(iomem[0x2181]) + (iomem[0x2183] << 16) + 0x7e0000;
            addr = memory.map[mem >> 13] + (mem);
            mem++;
            iomem[0x2181] = (Int16)(mem);
            memory.WriteOneByte(addr, data);
        }

        void IO_2181_w8(Int32 addr, byte data)
        {
            iomem[0x2181] = (Int16)((iomem[0x2181] & 0xff00) | (data << 0));
        }

        void IO_2182_w8(Int32 addr, byte data)
        {
            iomem[0x2181] = (Int16)((iomem[0x2181] & 0x00ff) | (data << 8));
        }

        void IO_2183_w8(Int32 addr, byte data)
        {
            iomem[addr] = (Int16)(data & 0x1);
        }

        byte IO_4016_r8(Int32 addr)
        {
            byte data = (byte)(iomem[addr]);
            if (data < 16)
                data = (byte)((input1 >> (15 - data)) & 0x01);
            else
                data = 0x01;
            iomem[addr]++;
            return (byte)(data);
        }

        byte IO_4017_r8(Int32 addr)
        {
            byte data = (byte)(iomem[addr]);
            if (data < 16)
                data = (byte)((input2 >> (15 - data)) & 0x01);
            else
                data = 0x01;
            iomem[addr]++;
            return (byte)(data);
        }

        void IO_4016_w8(Int32 addr, byte data)
        {
            data &= 0x01;
            if (iomem[addr - 1] == 0x01 && data == 0x00)
            {
                iomem[addr + 0] = 0;
                iomem[addr + 1] = 0;
            }
            iomem[addr - 1] = (Int16)data;
        }

        void IO_4200_w8(Int32 addr, byte data)
        {
            // NMITIMEN (trimmed version)
            irqEnabled = (data & 0x30) != 0;
        }

        void IO_4203_w8(Int32 addr, byte data)
        {
            // WRMPYB
            // Mul
            UInt16 i = (UInt16)(iomem[WRMPYA] * data);
            iomem[RDMPYL] = (Int16)(i & 0xff);
            iomem[RDMPYH] = (Int16)((i >> 8) & 0xff);
            // Break Div results
            iomem[RDDIVL] = data;
            iomem[RDDIVH] = 0;
        }

        void IO_4206_w8(Int32 addr, byte data)
        {
            // WRDIVB
            // Div
            if (data > 0x7f)
                data = data;
            Int32 Remainder = 0;
            Int32 Quotient = 0xffff;
            if (data != 0)
                Quotient = Math.DivRem((Int32)(iomem[WRDIVL] + (iomem[WRDIVH] << 8)), (Int32)data, out Remainder);
            iomem[RDDIVL] = (byte)(Quotient & 0xff);
            iomem[RDDIVH] = (byte)((Quotient >> 8) & 0xff);
            iomem[RDMPYL] = (byte)(Remainder & 0xff);
            iomem[RDMPYH] = (byte)((Remainder >> 8) & 0xff);
        }

        void IO_420b_w8(Int32 addr, byte data)
        {
            // MDMAEN
            int u = data | iomem[addr];
            iomem[addr] = (Int16)u;
            for (int a = 0; u != 0; a++)
            {
                if ((u & 1) != 0)
                    DoDMA(a);
                u = u >> 1;
            }
        }

        byte IO_4210_r8(Int32 addr)
        {
            // RDNMI (trimmed version)
            iomem[addr] ^= 0x01;
            return (byte)((iomem[addr] & 0x01) | 0x80);
        }

        byte IO_4211_r8(Int32 addr)
        {
            // TIMEUP (trimmed version)
            return 0x80;
        }

        byte IO_4212_r8(Int32 addr)
        {
            // HVBJOY (trimmed version)
            return 0x80;
        }

        // --------------------------------------------------------------------

        public readonly Int16[] ADDRSTEPLIST = { 1, 0, -1, 0 };
        readonly Int16[] XFERUNITLIST =
        {
            // Format is: UnitCount << 8 + (Unit1 << 0) + (Unit2 << 2) + (Unit3 << 4) + (Unit4 << 6)
            // NOTE: High bits are only used for HDMA
            0x0100,     // 0
            0x0244,     // 0, 1
            0x0200,     // 0, 0
            0x0450,     // 0, 0, 1, 1
            0x04e4,     // 0, 1, 2, 3
            0x0444,     // 0, 1, 0, 1
            0x0200,     // 0, 0
            0x0450      // 0, 0, 1, 1
        };

        void DoDMA(int i)
        {
            byte a = 0;
            byte x = 0;
            UInt16 u;
            Int32 mem = 0;
            Int16 addr = (Int16)(0x4300 + (i << 4));
            Int16 addrstep = ADDRSTEPLIST[(iomem[addr + 0] & 0x18) >> 3];
            byte xferunit = (byte)(XFERUNITLIST[(iomem[addr + 0] & 0x07) >> 0]);
            int BBAD = (byte)(iomem[addr + 1]) + 0x2100;                            // B-Bus Address
            UInt16 A1T = (UInt16)(iomem[addr + 2] + (iomem[addr + 3] << 8));        // Address 1 Table
            byte A1B = (byte)(iomem[addr + 4]);                                     // Address 1 Bank
            UInt16 DAS = (UInt16)(iomem[addr + 5] + (iomem[addr + 6] << 8));        // DMA Byte Counter

            if ((iomem[addr + 0] & 0x80) == 0)
            {
                // Transfer direction: CPU to IO
                while (true)
                {
                    // Get xferunit shift and ROL for next transfer
                    x = (byte)(xferunit & 0x3);
                    xferunit = (byte)((xferunit >> 2) | (xferunit << 6));

                    // Read byte
                    mem = A1T + (A1B << 16);
                    mem = memory.map[mem >> 13] + (mem);
                    a = (byte)memory.ReadOneByte(mem);
                    // Write byte
                    IOwrite8[(UInt16)(BBAD + x)]((UInt16)(BBAD + x), a);

                    // Next
                    A1T += (UInt16)addrstep;
                    DAS--;
                    if (DAS == 0)
                        break;
                }
            }
            else
            {
                // Transfer direction: IO to CPU
                while (true)
                {
                    // Get xferunit shift and ROL for next transfer
                    x = (byte)(xferunit & 0x3);
                    xferunit = (byte)((xferunit >> 2) | (xferunit << 6));

                    // Read byte
                    a = IOread8[(UInt16)(BBAD + x)]((UInt16)(BBAD + x));
                    // Write byte
                    mem = A1T + (A1B << 16);
                    mem = memory.map[mem >> 13] + (mem);
                    memory.WriteOneByte(mem, a);

                    // Next
                    A1T += (UInt16)addrstep;
                    DAS--;
                    if (DAS == 0)
                        break;
                }
            }

            iomem[addr + 2] = (byte)(A1T >> 0);
            iomem[addr + 3] = (byte)(A1T >> 8);
            iomem[addr + 5] = (byte)(DAS >> 0);
            iomem[addr + 6] = (byte)(DAS >> 8);

            iomem[0x420b] &= (Int16)(~(1 << i));
        }

        // --------------------------------------------------------------------

        private byte Regular_r8(int addr)
        {
            return (byte)iomem[addr];
        }

        private void Regular_w8(int addr, byte data)
        {
            iomem[addr] = data;
        }

        private byte Ignore_r8(int addr) => 0;
        private void Ignore_w8(int addr, byte data) { }

        private byte Error_r8(int addr)
        {
            if (!ignoreError)
                throw new NotImplementedException();
            return 0;
        }

        private void Error_w8(int addr, byte data)
        {
            if (!ignoreError)
                throw new NotImplementedException();
        }
    }
}
