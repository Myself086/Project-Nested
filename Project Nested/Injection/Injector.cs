using Project_Nested.Emulation;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Injection
{
    public partial class Injector
    {
        #region ROM data and settings

        // Source Nes ROM
        byte[] SrcData;
        byte[] SrcDataCopy;

        // Output Snes ROM
        byte[] OutData;
        public byte[] GetOutData() { return OutData; }

        public bool mapperSupported { get; private set; }

        Int32 finalRomSize;

        // Emulator ROM, can be edited without cloning but not recommended
        static readonly byte[] NestedEmulator = File.ReadAllBytes(
            Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + Path.DirectorySeparatorChar + "Project_Nested.smc");

        #endregion
        // --------------------------------------------------------------------
        #region ROM settings

        bool settingsLoaded;
        Dictionary<string, Setting> settings { get { if (!settingsLoaded) { LoadSettings(); settingsLoaded = true; } return _settings; } }
        Dictionary<string, Setting> _settings = new Dictionary<string, Setting>();

        SettingWrapper<short> Mapper => new SettingWrapper<short>(settings, "MapperNum");
        SettingWrapper<byte> StartBankPrg => new SettingWrapper<byte>(settings, "StartBankPRG");
        SettingWrapper<byte> StartBankChr => new SettingWrapper<byte>(settings, "StartBankCHR");

        ForcedFlagEnum ForcedFlags;
        SettingWrapper<bool> MemoryEmulationLoad => new SettingWrapper<bool>(settings, "MemoryEmulation.Load");
        SettingWrapper<bool> MemoryEmulationStore => new SettingWrapper<bool>(settings, "MemoryEmulation.Store");
        SettingWrapper<bool> MemoryEmulationAbsBank => new SettingWrapper<bool>(settings, "MemoryEmulation.AbsBank");
        SettingWrapper<bool> MemoryEmulationAbsCrossBank => new SettingWrapper<bool>(settings, "MemoryEmulation.AbsCrossBank");
        public enum ForcedFlagEnum
        {
            IndirectLoad = 0x0001,
            IndirectStore = 0x0002,
            AbsolutePrgBank = 0x0004,
            AbsolutePrgBankCross = 0x0008,
        }

        SettingWrapper<byte> PrgBankNumbers => new SettingWrapper<byte>(settings, "PrgBanks");

        SettingWrapper<int> PrgBankingMask => new SettingWrapper<int>(settings, "PrgBankMask");

        SettingWrapper<short> _JmpRange => new SettingWrapper<short>(settings, "JumpRange");
        SettingWrapper<short> _JmpRange_x2 => new SettingWrapper<short>(settings, "JumpRange_x2");
        short JmpRange { set { _JmpRange.SetValue(value); _JmpRange_x2.SetValue((short)(value * 2)); } }

        SettingWrapper<byte> ScreenMode => new SettingWrapper<byte>(settings, "ScreenMode");

        public SettingWrapper<string> GameName => new SettingWrapper<string>(settings, "GameName");
        SettingWrapper<int> GameCheckSum => new SettingWrapper<int>(settings, "GameCheckSum");
        SettingWrapper<int> GameCRC32 => new SettingWrapper<int>(settings, "GameCRC32");
        public SettingWrapper<string> EmulatorName => new SettingWrapper<string>(settings, "EmulatorName");

        SettingWrapper<byte> AotCompileBanks => new SettingWrapper<byte>(settings, "AotCompileBanks");

        SettingWrapper<byte> PrgBankLut_80 => new SettingWrapper<byte>(settings, "PrgBankLut_80", true);
        SettingWrapper<byte> PrgBankLut_a0 => new SettingWrapper<byte>(settings, "PrgBankLut_a0", true);
        SettingWrapper<byte> PrgBankLut_c0 => new SettingWrapper<byte>(settings, "PrgBankLut_c0", true);
        SettingWrapper<byte> PrgBankLut_e0 => new SettingWrapper<byte>(settings, "PrgBankLut_e0", true);

        SettingWrapper<byte> ChrBankLut_low => new SettingWrapper<byte>(settings, "ChrBankLut_lo", true);
        SettingWrapper<byte> ChrBankLut_high => new SettingWrapper<byte>(settings, "ChrBankLut_hi", true);

        enum PrgBankMirrorMode
        {
            None,               // NROM
            DirectMirror,
            Cascade,
            SramRange,          // Required for emulating mapper 5 in later versions
        }

        #endregion
        // --------------------------------------------------------------------
        #region Constructor

        public Injector(byte[] data)
        {
            // Load emulator
            this.OutData = NestedEmulator;
            Array.Resize(ref this.OutData, 0x800000);
            finalRomSize = OutData.Length;

            this.SrcDataCopy = data;

            // Dummy preparation because I'm too lazy to decouple the "switch (mapper)" part
            WriteNesRom();
        }

        #endregion
        // --------------------------------------------------------------------
        #region Apply patch

        private byte[] WriteNesRom()
        {
            this.SrcData = (byte[])SrcDataCopy.Clone();

            ResetBankManagement();

            // Read mapper, Prg banks, Chr banks
            Int32 mapper = ReadMapper();
            this.Mapper.SetValue((short)mapper);
            Int32 prgBanks = ReadPrgBanks();
            Int32 chrBanks = ReadChrBanks();
            Int32 prgStart = 0x10;
            Int32 chrStart = prgStart + ReadPrgSize();

            // Screen mode
            this.ScreenMode.SetValue(ReadScreenMirrors());

            const Int32 PRG_BANK_SIZE = 0x4000;
            const Int32 CHR_BANK_SIZE = 0x2000;

            void WriteBanks(int prgSize, int chrSize, PrgBankMirrorMode mirrorMode, byte[] startingBanks)
            {
                int prgBanksTotal = prgBanks * (PRG_BANK_SIZE / prgSize);

                // Apply user patches
                foreach (var item in patches)
                    item.Value.Apply(this.SrcData, prgSize, prgBanksTotal);

                AddPrgBanks(prgStart, prgSize, prgBanksTotal, mirrorMode);
                AddChrBanks(prgStart + PRG_BANK_SIZE * prgBanks, CHR_BANK_SIZE * chrBanks, chrSize);
                this.PrgBankingMask.SetValue(-prgSize);
                this.PrgBankNumbers.SetArray(startingBanks);
            }

            // Mapper specific settings
            mapperSupported = true;
            switch (mapper)
            {
                case 0:
                    WriteBanks(0x4000, 0x2000, PrgBankMirrorMode.None, new byte[] { 0, 0, 0, 0 });
                    break;
                case 1:
                    WriteBanks(0x4000, 0x1000, PrgBankMirrorMode.DirectMirror, new byte[] { 0, 0, 0xff, 0xff });
                    this.ForcedFlags = ForcedFlagEnum.AbsolutePrgBank | ForcedFlagEnum.IndirectLoad | ForcedFlagEnum.IndirectStore;
                    break;
                case 2:
                    WriteBanks(0x4000, 0x2000, PrgBankMirrorMode.DirectMirror, new byte[] { 0, 0, 0xff, 0xff });
                    this.ForcedFlags = ForcedFlagEnum.AbsolutePrgBank | ForcedFlagEnum.IndirectLoad | ForcedFlagEnum.IndirectStore;
                    break;
                case 4:
                    WriteBanks(0x2000, 0x400, PrgBankMirrorMode.Cascade, new byte[] { 0, 1, 0xfe, 0xff });
                    this.ForcedFlags = ForcedFlagEnum.AbsolutePrgBank | ForcedFlagEnum.IndirectLoad | ForcedFlagEnum.IndirectStore;
                    break;
                default:
                    mapperSupported = false;
                    break;
            }

            return OutData;
        }

        private void ApplyForcedFlags()
        {
            void Apply(SettingWrapper<bool> setting, ForcedFlagEnum flag)
            {
                if (ForcedFlags.HasFlag(flag))
                    setting.Value = true;
            }

            Apply(MemoryEmulationLoad, ForcedFlagEnum.IndirectLoad);
            Apply(MemoryEmulationStore, ForcedFlagEnum.IndirectStore);
            Apply(MemoryEmulationAbsBank , ForcedFlagEnum.AbsolutePrgBank);
            Apply(MemoryEmulationAbsCrossBank, ForcedFlagEnum.AbsolutePrgBankCross);
        }

        public byte[] ApplyPostChanges()
        {
            // Write NES ROM
            WriteNesRom();

            // Force some flags to be set
            ApplyForcedFlags();

            // Write PRG bank tables now because they are required for the AOT compiler
            WritePrgBankTable();

            // Write CHR bank tables
            WriteChrBankTable();

            // Finish writing the ROM
            return FinalChanges();
        }

        #endregion
        // --------------------------------------------------------------------
        #region Bank management

        // Snes banks
        private byte NewHiRomBank, NewLoRomBank;
        private Int32 NewHiRomBank_FileAddress { get => ((NewHiRomBank & 0x3f) | (((~NewHiRomBank) & 0x80) >> 1)) * 0x10000; }
        private Int32 NewLoRomBank_FileAddress { get => ((NewLoRomBank & 0x3f) | (((~NewLoRomBank) & 0x80) >> 1)) * 0x10000 + 0x8000; }

        // Nes banks
        private List<byte> PrgBanks, ChrBanks_low, ChrBanks_high;
        private PrgBankMirrorMode mirrorMode;

        private void ResetBankManagement()
        {
            NewLoRomBank = StartBankPrg.Value;
            NewHiRomBank = StartBankChr.Value;
            PrgBanks = new List<byte>();
            ChrBanks_low = new List<byte>();
            ChrBanks_high = new List<byte>();
        }

        private void AddPrgBanks(Int32 start, Int32 bankSize, Int32 bankCount, PrgBankMirrorMode mirrorMode)
        {
            this.mirrorMode = mirrorMode;
            switch (mirrorMode)
            {
                case PrgBankMirrorMode.None:
                    AddPrgBank(start, bankSize * bankCount);
                    break;
                case PrgBankMirrorMode.DirectMirror:
                    for (int i = 0; i < bankCount; i++)
                        AddPrgBank(start + bankSize * i, bankSize);
                    break;
                case PrgBankMirrorMode.Cascade:
                    {
                        // Separate each bank
                        List<byte[]> banks = new List<byte[]>();
                        for (int i = 0; i < bankCount; i++)
                            banks.Add(SrcData.ReadArray(start + bankSize * i, bankSize));
                        // Add banks in a cascade pattern
                        List<byte> data = new List<byte>();
                        for (int i = 0; i < bankCount; i++)
                        {
                            int u = i;
                            data.Clear();
                            while (data.Count < 0x8000)
                                data.AddRange(banks[(u++) % banks.Count]);
                            AddPrgBank(data.ToArray());
                        }
                    }
                    break;
                case PrgBankMirrorMode.SramRange:
                    throw new NotImplementedException();
            }
        }

        private void AddPrgBank(Int32 start, Int32 mirroredSize)
        {
            AddPrgBank(SrcData.ReadArray(start, mirroredSize));
        }

        private void AddPrgBank(params byte[] data)
        {
            // Check for boundaries
            switch (NewLoRomBank)
            {
                case 0xc0:
                    NewLoRomBank = 0x01;
                    break;
                case 0x40:
                    throw new IndexOutOfRangeException();
            }
            // Write data
            OutData.WriteArrayMirrored(NewLoRomBank_FileAddress, data, 0x8000);
            // Add reference to this bank
            PrgBanks.Add(NewLoRomBank);
            // Increment bank number
            NewLoRomBank++;
        }

        private void AddChrBanks(Int32 start, Int32 length, Int32 bankSize)
        {
            // TODO: Rebuild this

            int i;
            for (i = 0; i < length; i += 0x2000)
            {
                // Increment bank number
                if (i != 0 && (i & 0x7fff) == 0)
                    NewHiRomBank++;

                // Check for boundaries
                switch (NewHiRomBank)
                {
                    case 0x00:
                        NewHiRomBank = 0x40;
                        break;
                    case 0x7e:
                        throw new IndexOutOfRangeException();
                }

                // Add reference to this bank
                for (int u = 0; u < 0x2000; u += bankSize)
                {
                    ChrBanks_low.Add((byte)(((i + u) >> 8) & 0x7f));
                    ChrBanks_high.Add(NewHiRomBank);
                }
                //ChrBanks_low.Add((byte)((i >> 8) & 0x7f));
                //ChrBanks_high.Add(NewHiRomBank);

                // Copy up to 0x8000 bytes
                OutData.WriteArray(NewHiRomBank_FileAddress + (i & 0x7fff), SrcData.ReadArray(start + i, 0x2000), 0x2000);
            }
            // Cut this bank short
            if ((i & 0x7fff) != 0)
                NewHiRomBank++;
        }

        private void WritePrgBankTable()
        {
            // Write PRG banks, automatically mirrored by PrgBankLut's setter
            switch (mirrorMode)
            {
                case PrgBankMirrorMode.None:
                case PrgBankMirrorMode.DirectMirror:
                    {
                        this.PrgBankLut_80.SetArray(PrgBanks.ToArray());
                        this.PrgBankLut_a0.SetArray(PrgBanks.ToArray());
                        this.PrgBankLut_c0.SetArray(PrgBanks.ToArray());
                        this.PrgBankLut_e0.SetArray(PrgBanks.ToArray());
                    }
                    break;
                case PrgBankMirrorMode.Cascade:
                    {
                        List<byte> data = new List<byte>(PrgBanks);
                        List<byte> ShiftByte() { data.Insert(0, data.Last()); data.RemoveAt(data.Count - 1); return data; }
                        this.PrgBankLut_80.SetArray(PrgBanks.ToArray());
                        this.PrgBankLut_a0.SetArray(ShiftByte().ToArray());
                        this.PrgBankLut_c0.SetArray(ShiftByte().ToArray());
                        this.PrgBankLut_e0.SetArray(ShiftByte().ToArray());
                    }
                    break;
                case PrgBankMirrorMode.SramRange:
                    throw new NotImplementedException();
            }
        }

        private void WriteChrBankTable()
        {
            // Write PRG banks, automatically mirrored by PrgBankLut's setter
            this.ChrBankLut_low.SetArray(ChrBanks_low.ToArray());
            this.ChrBankLut_high.SetArray(ChrBanks_high.ToArray());
        }

        private byte[] FinalChanges()
        {
            // Copy start-up code to its proper location for ROMs using more than 4mb
            Array.Copy(OutData, 0x00ff00, OutData, 0x40ff00, 0x100);

            // Compile known calls
            {
                // Bank range
                this.AotCompileBanks.SetValueAt(0, (byte)(NewHiRomBank + 1));
                this.AotCompileBanks.SetValueAt(1, 0xfe);    // Can't be 0xff due to a compare bug in the assembly code

                // Build SRAM
                byte[] sram = new byte[0x4000];
                {
                    var writeAddr = 0x2000;
                    // Copy SNES ROM title (emulator's name)
                    sram.WriteString(writeAddr + 0, EmulatorName.Value, 20, '\0');
                    // Copy NES ROM title
                    sram.WriteString(writeAddr + 20, GameName.Value, 32, '\0');
                    // TODO: CheckSum and CRC32 (may cause problems with randomizers)
                    sram.Write32(writeAddr + 52, GameCheckSum.Value);
                    sram.Write32(writeAddr + 56, GameCRC32.Value);
                    // Copy known calls
                    var callsPointer = (GetSetting("FeedbackEntryPoints").ReadInt() & 0x1fff) + writeAddr;
                    sram.Write16(callsPointer, (callsPointer & 0x1fff) + 0x6000 + (calls.Count * 3) + 2);
                    for (int i = 0; i < calls.Count; i++)
                        sram.Write24(callsPointer + i * 3 + 2, calls[i]);
                }
                // Call compiler
                c65816 emu = new c65816(OutData, sram);
                emu.InterruptUnusedReset();
                if (emu.Execute())
                {
                    // Get data back
                    OutData.WriteArray(0, emu.memory.ReadROM(), OutData.Length);
                }
            }

            if (NewHiRomBank > 0x80)
            {
                // Find last used HiROM bank
                for (; NewHiRomBank < 0xfe; NewHiRomBank++)
                {
                    if (OutData.Read16(BankToFileAddress(NewHiRomBank) + 0x7ffe) == 0)
                        break;
                }
            }

            // Determine how much space the final ROM needs
            Int32 BankToFileAddress(byte bank) => (((bank & 0xbf) ^ 0x80) + (bank & 0x3f)) / 2 * 0x10000;
            finalRomSize = BankToFileAddress(NewLoRomBank) > BankToFileAddress(NewHiRomBank) ?
                           BankToFileAddress(NewLoRomBank) : BankToFileAddress(NewHiRomBank);

            // Round up to a power of 2 (not necessary but the checksum would get tricky)
            finalRomSize--;
            finalRomSize |= finalRomSize >> 1;
            finalRomSize |= finalRomSize >> 2;
            finalRomSize |= finalRomSize >> 4;
            finalRomSize |= finalRomSize >> 8;
            finalRomSize |= finalRomSize >> 16;
            finalRomSize++;

            // Resize ROM
            byte[] finalData = OutData;
            if (finalRomSize < finalData.Length)
                Array.Resize(ref finalData, finalRomSize);

            // Write ROM size into the header (1024 << n)
            {
                Int32 i = finalRomSize / 1024;
                byte n = 0;
                while (i > 1)
                {
                    i /= 2;
                    n++;
                }
                finalData.Write8(0xffd7, n);
            }

            // Calculate checksum
            {
                // Erase checksum
                finalData.Write32(0xffdc, 0x0000ffff);

                // Do checksum
                Int32 sum = 0;
                for (int i = 0; i < finalRomSize; i++)
                    sum += finalData[i];

                // Write checksum
                finalData.Write16(0xffdc + 0, ~sum);
                finalData.Write16(0xffdc + 2, sum);
            }

            return finalData;
        }

        #endregion
        // --------------------------------------------------------------------
        #region SNES Header reader

        public string ReadEmulatorTitle()
        {
            return OutData.ReadString(0xffc0, 21).Trim();
        }

        public byte[] ReadEmulatorTitleBytes()
        {
            return OutData.ReadArray(0xffc0, 21);
        }

        #endregion
        // --------------------------------------------------------------------
        #region iNES Header reader

        public Int32 ReadMapper()
        {
            // Read mapper bits 0-3
            Int32 mapper = (SrcData[6] >> 4);

            // Verify byte 7 compatibility
            if ((SrcData[7] & 0x0c) != 0x08)
                return mapper;

            // Read mapper bits 4-7
            mapper |= (SrcData[6] >> 4) << 4;

            // Read mapper bits 8-11
            mapper |= (SrcData[8] & 0x0f) << 8;

            return mapper;
        }

        public Int32 ReadPrgSize()
        {
            // Incomplete but unlikely to support massive ROMs
            return SrcData[4] * 16384;
        }

        public Int32 ReadPrgBanks()
        {
            // Incomplete but unlikely to support massive ROMs
            return SrcData[4];
        }

        public Int32 ReadChrSize()
        {
            // Incomplete but unlikely to support massive ROMs
            return SrcData[5] * 8192;
        }

        public Int32 ReadChrBanks()
        {
            // Incomplete but unlikely to support massive ROMs
            return SrcData[5];
        }

        public byte ReadScreenMirrors()
        {
            // 0x01 for horizontal, 0x02 for vertical, 0x03 for 4 screens
            if ((SrcData[6] & 0x08) != 0)
                return 0x03;
            return (byte)(((SrcData[6] & 0x01) + 1) ^ 0x03);
        }

        #endregion
    }
}
