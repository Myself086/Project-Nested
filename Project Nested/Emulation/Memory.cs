using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.InteropServices;

namespace Project_Nested.Emulation
{
    class Memory
    {
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 0x1000000)]
        public byte[] mem = new byte[0x1000000];     // 16mb
        public Int16[] io = new Int16[0x10000];
        public byte[] vram = new byte[0x10000];      // Video RAM
        public byte[] oam = new byte[0x400];         // OAM RAM
        public UInt16[] cgram = new UInt16[0x100];   // Palette RAM
        public byte[] aram = new byte[0x10000];      // Audio RAM
        public byte[] aio = new byte[0x100];         // APU I/O

        // Debug memory
        public byte[] dbg = new byte[0x100000];

        // Memory mapping must be accessed using >> 13
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 0x800)]
        public Int32[] map = new Int32[0x800];
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 0x800)]
        public Int32[] unmap = new Int32[0x800];
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 0x800)]
        public Int32[] maptiming = new Int32[0x800];
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 0x800)]
        public Int32[] unmaptiming = new Int32[0x800];

        // ROM identifier
        public const Int32 ROMlowerbound = 0x00002000;
        public const Int32 ROMupperbound = 0x00801fff;
        public Int32 SRAMlowerbound;
        public Int32 SRAMupperbound;
        public Int32 RAMlowerbound;
        public Int32 RAMupperbound;

        public enum RomSize { LoROM, HiROM, ExHiROM }
        public RomSize romSize;

        public bool DebugWriteRom = true;

        // Private data
        Int32 mempointer;
        const Int32 MEM_SEGMENT_SIZE = 0x2000;

        // --------------------------------------------------------------------

        public Memory()
        {
            ResetRam(RomSize.ExHiROM);
        }

        // --------------------------------------------------------------------

        public void WriteROM(byte[] data)
        {
            mem.WriteArray(ROMlowerbound, data, ROMupperbound - ROMlowerbound + 1);
        }

        public void WriteSRAM(byte[] data)
        {
            mem.WriteArray(SRAMlowerbound, data, SRAMupperbound - SRAMlowerbound + 1);
        }

        public byte[] ReadROM()
        {
            return mem.ReadArray(ROMlowerbound, ROMupperbound - ROMlowerbound + 1);
        }

        // --------------------------------------------------------------------

        void ResetSegments()
        {
            Int32 i;
            mempointer = 1;
            for (i = 0; i <= map.GetUpperBound(0); i++)
                map[i] = 0;
            for (i = 0; i <= maptiming.GetUpperBound(0); i++)
                maptiming[i] = 0;
            for (i = 0; i <= unmaptiming.GetUpperBound(0); i++)
                unmaptiming[i] = 0;
            for (i = ROMupperbound + 1; i <= mem.GetUpperBound(0); i++)
                mem[i] = 0;
            // External memories
            for (i = 0; i <= io.GetUpperBound(0); i++)
                io[i] = 0;
            for (i = 0; i <= vram.GetUpperBound(0); i++)
                vram[i] = 0;
            for (i = 0; i <= aram.GetUpperBound(0); i++)
                aram[i] = 0;
            for (i = 0; i <= aio.GetUpperBound(0); i++)
                aio[i] = 0;
        }

        void AddSegment(Int32 FirstSegment, Int32 LastSegment, Int32 Timing)
        {
            Int32 b = LastSegment >> 13;
            for (Int32 a = FirstSegment >> 13; a <= b; a++)
            {
                map[a] = (mempointer << 13) - (a << 13);
                unmap[mempointer] = a << 13;
                maptiming[a] = Timing;
                unmaptiming[mempointer] = Timing;
                mempointer++;
            }
        }

        void CopySegment(Int32 sPaste, Int32 sCopy)
        {
            Int32 mem = (map[sCopy >> 13] + sCopy) >> 13;
            map[sPaste >> 13] = (mem << 13) - sPaste;
            if (mem >= 0)
                unmap[mem] = sPaste;
            maptiming[sPaste >> 13] = maptiming[sCopy >> 13];
            if (mem >= 0)
                unmaptiming[mem] = maptiming[sCopy >> 13];

            //map[sPaste >> 13] = map[sCopy >> 13] - (sPaste) + (sCopy);
            //maptiming[sPaste >> 13] = maptiming[sCopy >> 13];
        }

        public void ResetRam(RomSize romSize)
        {
            this.romSize = romSize;
            // Initialize
            ResetSegments();
            // ROM map
            if (romSize == RomSize.ExHiROM || romSize == RomSize.HiROM)
            {
                // HiROM
                AddSegment(0xc00000, 0xffffff, 0);
                AddSegment(0x400000, 0x7fffff, 0);
                for (Int32 a = 0x0; a <= 0x3f0000; a += 0x10000)
                {
                    CopySegment(0x8000 + a, 0x8000 + a + 0x400000);
                    CopySegment(0xa000 + a, 0xa000 + a + 0x400000);
                    CopySegment(0xc000 + a, 0xc000 + a + 0x400000);
                    CopySegment(0xe000 + a, 0xe000 + a + 0x400000);
                    CopySegment(0x808000 + a, 0x8000 + a + 0xc00000);
                    CopySegment(0x80a000 + a, 0xa000 + a + 0xc00000);
                    CopySegment(0x80c000 + a, 0xc000 + a + 0xc00000);
                    CopySegment(0x80e000 + a, 0xe000 + a + 0xc00000);
                }
            }
            else if (romSize == RomSize.LoROM)
            {
                // LoROM
                for (Int32 a = 0; a <= 0x7f0000; a += 0x10000)
                    AddSegment(0x8000 + a, 0xffff + a, 0);
                for (Int32 a = 0x800000; a <= 0xff0000; a += 0x10000)
                    AddSegment(0x8000 + a, 0xffff + a, 0);
                for (Int32 a = 0x400000; a <= 0x7f0000; a += 0x10000)
                {
                    CopySegment(0x0000 + a, 0x8000 + a - 0x400000);
                    CopySegment(0x2000 + a, 0xa000 + a - 0x400000);
                    CopySegment(0x4000 + a, 0xc000 + a - 0x400000);
                    CopySegment(0x6000 + a, 0xe000 + a - 0x400000);
                }
                for (Int32 a = 0xc00000; a <= 0xff0000; a += 0x10000)
                {
                    CopySegment(0x0000 + a, 0x8000 + a - 0x400000);
                    CopySegment(0x2000 + a, 0xa000 + a - 0x400000);
                    CopySegment(0x4000 + a, 0xc000 + a - 0x400000);
                    CopySegment(0x6000 + a, 0xe000 + a - 0x400000);
                }
            }

            // Fix mempointer
            mempointer = (ROMupperbound + 1) >> 13;
            // Main RAM map
            RAMlowerbound = mempointer << 13;
            AddSegment(0x7e0000, 0x7fffff, 0);
            RAMupperbound = ((mempointer) << 13) - 1;
            // I/O
            map[0x1] = -0x10000;    //-0xe000;     //-0x2000;
            map[0x2] = -0x10000;    //-0xc000;     //-0x4000;
            map[0x3] = -0x10000;    //-0xa000;     //-0x6000;
            // Low mirrored memory
            for (Int32 a = 0; a <= 0x3f0000; a += 0x10000)
            {
                CopySegment(0x0000 + a, 0x7e0000);
                CopySegment(0x2000 + a, 0x002000);
                CopySegment(0x4000 + a, 0x004000);
                CopySegment(0x6000 + a, 0x006000);
                CopySegment(0x800000 + a, 0x7e0000);
                CopySegment(0x802000 + a, 0x002000);
                CopySegment(0x804000 + a, 0x004000);
                CopySegment(0x806000 + a, 0x006000);
            }
            // SRam
            SRAMlowerbound = mempointer << 13;
            int sramSize = 0x400 << HeaderGetSRAMsize();
            if (sramSize > 0x10000)
                sramSize = 0x10000;
            switch (8) //(HeaderGetSRAMsize())
            {
                case 1:
                case 2:
                case 3:    // 0x2000
                    AddSegment(0x700000, 0x701fff, 0);
                    CopySegment(0x702000, 0x700000);
                    CopySegment(0x704000, 0x700000);
                    CopySegment(0x706000, 0x700000);
                    CopySegment(0x708000, 0x700000);
                    CopySegment(0x70a000, 0x700000);
                    CopySegment(0x70c000, 0x700000);
                    CopySegment(0x70e000, 0x700000);
                    SRAMupperbound = SRAMlowerbound - 1 + (1024 << (HeaderGetSRAMsize()));
                    break;
                case 4:     // 0x4000
                    AddSegment(0x700000, 0x703fff, 0);
                    CopySegment(0x704000, 0x700000);
                    CopySegment(0x706000, 0x702000);
                    CopySegment(0x708000, 0x700000);
                    CopySegment(0x70a000, 0x702000);
                    CopySegment(0x70c000, 0x700000);
                    CopySegment(0x70e000, 0x702000);
                    SRAMupperbound = ((mempointer) << 13) - 1;
                    break;
                case 5:     // 0x8000
                    AddSegment(0x700000, 0x707fff, 0);
                    CopySegment(0x708000, 0x700000);
                    CopySegment(0x70a000, 0x702000);
                    CopySegment(0x70c000, 0x704000);
                    CopySegment(0x70e000, 0x706000);
                    SRAMupperbound = ((mempointer) << 13) - 1;
                    break;
                case 10:
                case 9:
                case 8:
                case 7:
                case 6:     // 0x10000
                    {
                        AddSegment(0x700000, 0x700000 + sramSize - 1, 0);
                        SRAMupperbound = ((mempointer) << 13) - 1;
                    }
                    break;
                default:
                    SRAMupperbound = ((mempointer) << 13) - 1;
                    break;
            }
            // HiROM sram
            if (SRAMupperbound > SRAMlowerbound)
            {
                Int32 sramMirrors = (sramSize / 0x2000) - 1;
                if (sramMirrors == -1)
                    sramMirrors = 0;
                Int32 u = 0;
                for (Int32 a = 0; a <= 0x3f0000; a += 0x10000)
                {
                    CopySegment(0x006000 + a, 0x700000 + (sramMirrors & u) * 0x2000);
                    CopySegment(0x806000 + a, 0x700000 + (sramMirrors & u) * 0x2000);
                    u++;
                }
            }
            // Set all ram bytes to 0x55
            for (Int32 i = RAMlowerbound; i <= RAMupperbound; i++)
                mem[i] = 0x55;
        }

        // --------------------------------------------------------------------

        public string HeaderGetTitle()
        {
            return Encoding.UTF8.GetString(this.mem, this.DebugGetMapAddress(0xffc0), 21);
        }

        public Int32 HeaderGetMapper() { return DebugReadOneByte(0xffd6); }
        public Int32 HeaderGetROMsize() { return DebugReadOneByte(0xffd7); }
        public Int32 HeaderGetSRAMsize() { return DebugReadOneByte(0xffd8); }
        public Int32 HeaderGetCountry() { return DebugReadOneByte(0xffd9); }
        public Int32 HeaderGetDeveloperID() { return DebugReadOneByte(0xffda); }
        public Int32 HeaderGetROMversion() { return DebugReadOneByte(0xffdb); }
        public Int32 HeaderGetNCheckSum() { return DebugReadTwoByte(0xffdc); }
        public Int32 HeaderGetCheckSum() { return DebugReadTwoByte(0xffde); }

        // --------------------------------------------------------------------

        public Int32 DebugGetMapAddress(Int32 memaddr)
        {
            return this.map[(memaddr + 0) >> 13] + ((memaddr + 0));
        }

        public byte DebugReadOneByte(Int32 memaddr)
        {
            if (memaddr < 0x1000000)
            {
                memaddr = this.map[(memaddr + 0) >> 13] + ((memaddr + 0));
                if (memaddr < 0)
                    return 0;
                return this.mem[memaddr];
            }
            else if (memaddr < 0x2000000)
            {
                return this.vram[memaddr & 0xffff];
            }
            return 0;
        }

        public Int16 DebugReadTwoByte(Int32 memaddr)
        {
            return (Int16)(DebugReadOneByte(memaddr + 0) + (DebugReadOneByte(memaddr + 1) << 8));
        }

        public byte DebugReadOneByteRawMem(Int32 memaddr)
        {
            return this.mem[memaddr];
        }

        public Int16 DebugReadTwoByteRawMem(Int32 memaddr)
        {
            return (Int16)(this.mem[memaddr++] + (this.mem[memaddr++] << 8));
        }

        public void DebugWriteOneByte(Int32 memaddr, Int32 data)
        {
            if (memaddr < 0x1000000)
            {
                memaddr = this.map[(memaddr + 0) >> 13] + ((memaddr + 0));
                if (memaddr < 0)
                    return;
                this.mem[memaddr] = (byte)data;
            }
            else if (memaddr < 0x1010000)
            {
                // Bank 0x100
                this.vram[memaddr & 0xffff] = (byte)data;
            }
            else if (memaddr < 0x2000000)
            {
                // Bank 0x1f0-0x1ff
                this.dbg[memaddr & 0xfffff] = (byte)data;
            }
        }

        public void DebugWriteTwoByte(Int32 memaddr, Int32 data)
        {
            memaddr = this.map[(memaddr + 0) >> 13] + ((memaddr + 0));
            this.mem[memaddr + 0] = (byte)(data >> 0);
            this.mem[memaddr + 1] = (byte)(data >> 8);
        }

        public byte DebugReadRomByte(Int32 memaddr)
        {
            return this.mem[memaddr + ROMlowerbound];
        }

        // --------------------------------------------------------------------

        public Int32 ReadOneByte(Int32 addr)
        {
            if (addr < 0)
            {
                //return (Int32)(IO.ReadOneByte(addr));
                throw new NotImplementedException();
            }
            else
            {
                return (Int32)(this.mem[addr]);
            }
        }

        public Int32 ReadTwoByte(Int32 addr)
        {
            if (addr < 0)
            {
                //return (Int32)(IO.ReadOneByte(addr++) + (IO.ReadOneByte(addr++) << 8));
                throw new NotImplementedException();
            }
            else
            {
                return (Int32)(this.mem[addr++] + (this.mem[addr++] << 8));
            }
        }

        public Int32 ReadThreeByte(Int32 addr)
        {
            if (addr < 0)
            {
                //return (Int32)(IO.ReadOneByte(addr++) + (IO.ReadOneByte(addr++) << 8) + (IO.ReadOneByte(addr++) << 16));
                throw new NotImplementedException();
            }
            else
            {
                return (Int32)(this.mem[addr++] + (this.mem[addr++] << 8) + (this.mem[addr++] << 16));
            }
        }

        public void WriteOneByte(Int32 addr, Int32 data)
        {
            //if (addr <= ROMlowerbound || (addr <= ROMupperbound && !DebugWriteRom))
            if (addr < 0)
            {
                //IO.WriteOneByte(addr, (byte)(data >> 0));
                throw new NotImplementedException();
            }
            else
            {
                this.mem[addr] = (byte)(data >> 0);
            }
        }

        public void WriteTwoByte(Int32 addr, Int32 data)
        {
            //if (addr <= ROMlowerbound || (addr <= ROMupperbound && !DebugWriteRom))
            if (addr < 0)
            {
                //IO.WriteOneByte(addr++, (byte)(data >> 0));
                //IO.WriteOneByte(addr++, (byte)(data >> 8));
                throw new NotImplementedException();
            }
            else
            {
                this.mem[addr++] = (byte)(data >> 0);
                this.mem[addr++] = (byte)(data >> 8);
            }
        }

        public void WriteThreeByte(Int32 addr, Int32 data)
        {
            //if (addr <= ROMlowerbound || (addr <= ROMupperbound && !DebugWriteRom))
            if (addr < 0)
            {
                //IO.WriteOneByte(addr++, (byte)(data >> 0));
                //IO.WriteOneByte(addr++, (byte)(data >> 8));
                //IO.WriteOneByte(addr++, (byte)(data >> 16));
                throw new NotImplementedException();
            }
            else
            {
                this.mem[addr++] = (byte)(data >> 0);
                this.mem[addr++] = (byte)(data >> 8);
                this.mem[addr++] = (byte)(data >> 16);
            }
        }
    }
}
