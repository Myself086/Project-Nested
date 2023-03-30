using Project_Nested.Emulation;
using Project_Nested.Optimize;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Project_Nested.Injection
{
    partial class Injector
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

        Int32 prgBankSize;
        Int32 chrBankSize;
        Int32 prgBanksTotal;
        Int32 chrBanksTotal;

        public Action save, saveAndPlay;

        #endregion
        // --------------------------------------------------------------------
        #region ROM settings

        bool settingsLoaded;
        Dictionary<string, Setting> settings { get { if (!settingsLoaded) { LoadSettings(); settingsLoaded = true; } return _settings; } }
        Dictionary<string, Setting> _settings = new Dictionary<string, Setting>();
        List<string> unknownSettings = new List<string>();

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

        SettingWrapper<bool> TruncateRom => new SettingWrapper<bool>(settings, "Cartridge.TruncateRom");

        SettingWrapper<byte> PrgBankNumbers => new SettingWrapper<byte>(settings, "PrgBanks");

        SettingWrapper<int> PrgBankingMask => new SettingWrapper<int>(settings, "PrgBankMask");
        SettingWrapper<byte> PrgBankNumMask => new SettingWrapper<byte>(settings, "PrgBankNumMask");

        SettingWrapper<short> _JmpRange => new SettingWrapper<short>(settings, "JumpRange");
        SettingWrapper<short> _JmpRange_x2 => new SettingWrapper<short>(settings, "JumpRange_x2");
        short JmpRange { set { _JmpRange.SetValue(value); _JmpRange_x2.SetValue((short)(value * 2)); } }

        SettingWrapper<byte> ScreenMode => new SettingWrapper<byte>(settings, "ScreenMode");

        public SettingWrapper<string> GameName => new SettingWrapper<string>(settings, "GameName");
        public SettingWrapper<string> EmulatorName => new SettingWrapper<string>(settings, "EmulatorName");

        SettingWrapper<byte> AotCompileBanks => new SettingWrapper<byte>(settings, "AotCompileBanks");

        SettingWrapper<byte> PrgBankLut_80 => new SettingWrapper<byte>(settings, "PrgBankLut_80", true);
        SettingWrapper<byte> PrgBankLut_a0 => new SettingWrapper<byte>(settings, "PrgBankLut_a0", true);
        SettingWrapper<byte> PrgBankLut_c0 => new SettingWrapper<byte>(settings, "PrgBankLut_c0", true);
        SettingWrapper<byte> PrgBankLut_e0 => new SettingWrapper<byte>(settings, "PrgBankLut_e0", true);

        SettingWrapper<byte> ChrBankLut_low => new SettingWrapper<byte>(settings, "ChrBankLut_lo", true);
        SettingWrapper<byte> ChrBankLut_high => new SettingWrapper<byte>(settings, "ChrBankLut_hi", true);

        SettingWrapper<byte> StaticRange => new SettingWrapper<byte>(settings, "MemoryEmulation.StaticRange");
        SettingWrapper<bool> StaticRange_80 => new SettingWrapper<bool>(settings, "MemoryEmulation.StaticRange_80");
        SettingWrapper<bool> StaticRange_a0 => new SettingWrapper<bool>(settings, "MemoryEmulation.StaticRange_a0");
        SettingWrapper<bool> StaticRange_c0 => new SettingWrapper<bool>(settings, "MemoryEmulation.StaticRange_c0");
        SettingWrapper<bool> StaticRange_e0 => new SettingWrapper<bool>(settings, "MemoryEmulation.StaticRange_e0");

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
            try
            {
                this.OutData = File.ReadAllBytes(
                    Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + Path.DirectorySeparatorChar + "Project_Nested.smc");
            }
            catch (Exception)
            {
                return;
            }

            Array.Resize(ref this.OutData, 0x800000);
            finalRomSize = OutData.Length;

            // Copy start-up code to its proper location for ROMs using more than 4mb
            Array.Copy(OutData, 0x00ff00, OutData, 0x40ff00, 0x100);

            this.SrcDataCopy = data;

            // Dummy preparation because I'm too lazy to decouple the "switch (mapper)" part
            if (data != null)
                WriteNesRom(true);
        }

        #endregion
        // --------------------------------------------------------------------
        #region Apply patch

        private byte[] WriteNesRom(bool initialChanges)
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

            // Is file size matching iNES header?
            int expectedSize = prgBanks * PRG_BANK_SIZE + chrBanks * CHR_BANK_SIZE + 0x10;
            if (this.SrcData.Length < expectedSize)
                Array.Resize(ref this.SrcData, expectedSize);

            void WriteBanks(int prgSize, int chrSize, PrgBankMirrorMode mirrorMode, byte[] startingBanks)
            {
                this.prgBankSize = prgSize;
                this.chrBankSize = chrSize;

                this.prgBanksTotal = prgBanks * PRG_BANK_SIZE / prgSize;
                this.chrBanksTotal = chrBanks * CHR_BANK_SIZE / chrSize;

                // Apply user patches
                foreach (var item in patches)
                    item.Value.Apply(this.SrcData, prgSize, prgBanksTotal);

                AddPrgBanks(prgStart, prgSize, prgBanksTotal, mirrorMode);
                AddChrBanks(prgStart + PRG_BANK_SIZE * prgBanks, CHR_BANK_SIZE * chrBanks, chrSize);
                this.PrgBankingMask.SetValue(-prgSize);
                this.PrgBankNumMask.SetValue((byte)(this.prgBanksTotal.RoundToPowerOf2() - 1));
                this.PrgBankNumbers.SetArray(startingBanks);
            }

            void SetInitialBooleans(params SettingWrapper<bool>[] bools)
            {
                if (initialChanges)
                    foreach (var item in bools)
                    {
                        item.SetValue(true);
                        item.SetAsDefaultValue();
                    }
            }

            void ClearInitialBooleans(params SettingWrapper<bool>[] bools)
            {
                if (initialChanges)
                    foreach (var item in bools)
                    {
                        item.SetValue(false);
                        item.SetAsDefaultValue();
                    }
            }

            // Mapper specific settings
            mapperSupported = true;
            switch (mapper)
            {
                case 0:
                    WriteBanks(0x4000, 0x2000, PrgBankMirrorMode.None, new byte[] { 0, 0, 0, 0 });
                    SetInitialBooleans(StaticRange_80, StaticRange_a0, StaticRange_c0, StaticRange_e0);
                    break;
                case 1:
                    WriteBanks(0x4000, 0x1000, PrgBankMirrorMode.DirectMirror, new byte[] { 0, 0, 0xff, 0xff });
                    this.ForcedFlags = ForcedFlagEnum.AbsolutePrgBank | ForcedFlagEnum.IndirectLoad | ForcedFlagEnum.IndirectStore;
                    break;
                case 2:
                    WriteBanks(0x4000, 0x2000, PrgBankMirrorMode.DirectMirror, new byte[] { 0, 0, 0xff, 0xff });
                    this.ForcedFlags = ForcedFlagEnum.AbsolutePrgBank | ForcedFlagEnum.IndirectLoad | ForcedFlagEnum.IndirectStore;
                    SetInitialBooleans(StaticRange_c0, StaticRange_e0);
                    break;
                case 3:
                    WriteBanks(0x4000, 0x2000, PrgBankMirrorMode.None, new byte[] { 0, 0, 0, 0 });
                    SetInitialBooleans(StaticRange_80, StaticRange_a0, StaticRange_c0, StaticRange_e0);
                    break;
                case 4:
                    WriteBanks(0x2000, 0x400, PrgBankMirrorMode.Cascade, new byte[] { 0, 1, 0xfe, 0xff });
                    this.ForcedFlags = ForcedFlagEnum.AbsolutePrgBank | ForcedFlagEnum.IndirectLoad | ForcedFlagEnum.IndirectStore;
                    SetInitialBooleans(StaticRange_e0);
                    break;
                case 7:
                    WriteBanks(0x8000, 0x2000, PrgBankMirrorMode.DirectMirror, new byte[] { 0, 0, 0, 0 });
                    this.ForcedFlags = ForcedFlagEnum.AbsolutePrgBank | ForcedFlagEnum.IndirectLoad | ForcedFlagEnum.IndirectStore;
                    break;
                case 69:
                    WriteBanks(0x2000, 0x400, PrgBankMirrorMode.Cascade, new byte[] { 0, 1, 2, 0xff });
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
            Apply(MemoryEmulationAbsBank, ForcedFlagEnum.AbsolutePrgBank);
            Apply(MemoryEmulationAbsCrossBank, ForcedFlagEnum.AbsolutePrgBankCross);
        }

        private void CopyStaticData()
        {
            byte[] GetBankData(int bankNum, int rangeStart)
            {
                // Convert bank number to file address
                int fileAddress = ConvertSnesBankToFileAddress(bankNum) * 0x10000 + rangeStart;

                return OutData.ReadArray(fileAddress, 0x2000);
            }

            // Prepare all of our static data, or null if non-static
            byte[][] StaticRangeData = new byte[4][];
            if (StaticRange_80.Value) StaticRangeData[0] = GetBankData(PrgBankLut_80[PrgBankNumbers[0]], 0x8000);
            if (StaticRange_a0.Value) StaticRangeData[1] = GetBankData(PrgBankLut_a0[PrgBankNumbers[1]], 0xa000);
            if (StaticRange_c0.Value) StaticRangeData[2] = GetBankData(PrgBankLut_c0[PrgBankNumbers[2]], 0xc000);
            if (StaticRange_e0.Value) StaticRangeData[3] = GetBankData(PrgBankLut_e0[PrgBankNumbers[3]], 0xe000);

            // Copy static data to every bank
            void CopyData(byte bank)
            {
                for (int i = 0; i < 4; i++)
                {
                    if (StaticRangeData[i] != null)
                    {
                        int fileAddress = ConvertSnesBankToFileAddress(bank) * 0x10000 + 0x8000 + i * 0x2000;

                        OutData.WriteArray(fileAddress, StaticRangeData[i], 0x2000);
                    }
                }
            }

            foreach (var bank in PrgBanks)
                CopyData(bank);

            // Force mirrors to the PRG RAM bank (0xb0)
            var startbank = StartBankPrg.Value;
            foreach (var bank in new byte[] { 0x80, 0x90, 0xb0 })
                if (startbank <= bank) CopyData(bank);
        }

        public void MergeRoms()
        {
            // Write NES ROM
            WriteNesRom(false);

            // Force some flags to be set
            ApplyForcedFlags();

            // Write PRG bank tables now because they are required for the AOT compiler
            WritePrgBankTable();

            // Write CHR bank tables
            WriteChrBankTable();

            // Copy static ROM ranges to every bank
            CopyStaticData();
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

        private void AddPrgBank(byte[] data)
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

#if SYNC_SAVE
        public byte[] FinalChanges(CancellationToken? ct, IProgress<Tuple<string, int, int>> progress)
#else
        public async Task<byte[]> FinalChanges(CancellationToken? ct, IProgress<Tuple<string, int, int>> progress)
#endif
        {
            MergeRoms();

            progress?.Report(new Tuple<string, int, int>("Compiling", 0, 0));

            c65816 emu;

            // Clone OutData so it can be restored to a state prior to these changes
            var oldOutData = (byte[])this.OutData.Clone();

            // Rom makeup, HiROM vs ExHiROM (required for SD2SNES ExHiROM)
            OutData[0x00ffd5] = 0x31;
            OutData[0x40ffd5] = 0x35;

            // Apply game genie codes
            if (patches.Count != null)
            {
                var baseAddresses = new List<int>();

                for (int i = 0; i < PrgBanks.Count; i++)
                {
                    var item = PrgBanks[i];
                    baseAddresses.Add(((item & 0x3f) | (((~item) & 0x80) >> 1)) * 0x10000);
                }

                foreach (var item in patches)
                    item.Value.ApplyGameGenie(OutData, baseAddresses);
            }

            // Auto-play
            if (calls.Count < GetSetting("EmuCalls.AutoPlayThreshold").ReadInt())
            {
                var autoplay = new AutoPlay(this, progress);
#if SYNC_SAVE
                calls = autoplay.PlaySync();
#else
                calls = await autoplay.PlayAsync(ct);
#endif
                KnownCallCountChanged?.Invoke();
            }

            // Compile known calls
            {
                // Bank range
                this.AotCompileBanks.SetValueAt(0, (byte)(NewHiRomBank));
                this.AotCompileBanks.SetValueAt(1, 0xff);

                // Build SRAM
                byte[] sram = new byte[0x4000];
                {
                    var writeAddr = 0x2000;
                    // Copy SNES ROM title (emulator's name)
                    var header = SrmFeedbackReader.ExpectedHeader(this);
                    sram.WriteArray(writeAddr + GetSetting("Feedback.EmulatorName").ReadInt(), header, header.Length);
                    // Copy NES ROM title
                    sram.WriteString(writeAddr + GetSetting("Feedback.ProfileName").ReadInt(), GameName.Value, 128, '\0');
                    // Copy known calls
                    var callsPointer = (writeAddr + GetSetting("Feedback.EntryPoints.Top").ReadInt());
                    var callsTable = (writeAddr + GetSetting("Feedback.EntryPoints.LowerBound").ReadInt());
                    var callsCount = calls.Count;
                    {
                        // Prevent overflow
                        var max = ((writeAddr + GetSetting("Feedback.EntryPoints.UpperBound").ReadInt()) - callsTable) / 3;
                        callsCount = callsCount < max ?
                                     callsCount : max;
                    }
                    // Write top address
                    sram.Write16(callsPointer, (callsTable & 0x1fff) + 0x6000 + (callsCount * 3));
                    // Write calls table
                    for (int i = 0; i < callsCount; i++)
                        sram.Write24(callsTable + i * 3, calls[i]);
                }

#if DEBUG
                // Save SRAM file for external debugging
                File.WriteAllBytes(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + Path.DirectorySeparatorChar + "Compile.srm", sram);
#endif

                // Initialize emulator
                emu = NewEmulator(sram);

                // Patch ranges
                {
                    var patchRanges = GetPatchRangeData();
                    var addr = AddData(emu, patchRanges);
                    SetSetting("Patch.Ranges", addr.ToString());
                    SetSetting("Patch.Ranges.Length", (patchRanges.Length * 4).ToString());
                }

                OptimizeGroup optGroup = null;
                if (Convert.ToBoolean(GetSetting("Optimize.Enabled")))
                {
                    optGroup = new OptimizeGroup(this, calls.Where(e => !excludedCalls.Contains(e)).ToList(),
                        StaticRange.Value, Convert.ToBoolean(settings["StackEmulation.NativeReturn"].GetValue()), progress);
#if SYNC_SAVE
                    optGroup.OptimizeAllSync();
#else
                    await optGroup.OptimizeAllAsync(ct);
#endif
                    IfCancel();
                }

                // Call compiler
                optGroup?.WriteLinks(emu);
                StaticRecompiler(emu);
                optGroup?.FixLinks(emu);
                if (optGroup != null)
                    emu.memory.ReadROM(OutData);
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

            if (!TruncateRom.Value)
                finalRomSize = finalRomSize.RoundToPowerOf2();

            // ROM size must be at least 2MB for properly mirroring PRG RAM to NES LoROM banks
            if (finalRomSize < 0x200000)
                finalRomSize = 0x200000;

            // Write ROM size into the header (1024 << n)
            {
                Int32 i = finalRomSize / 1024;
                byte n = 0;
                while (i > 1)
                {
                    i /= 2;
                    n++;
                }
                OutData.Write8(0x00ffd7, n);
                OutData.Write8(0x40ffd7, n);
            }

            // Erase clone header for ExHiROM
            if (finalRomSize > 0x400000)
                OutData.WriteArray(0x00ffc0, new byte[0x40], 0x40);

            // Calculate checksum
            {
                Int32 checksumAddress = finalRomSize <= 0x400000 ? 0x00ffdc : 0x40ffdc;

                // Erase checksum
                OutData.Write32(checksumAddress, 0x0000ffff);

                // Do checksum
                Int32 sum = CalculateChecksum(OutData, finalRomSize);

                // Write checksum
                OutData.Write16(checksumAddress + 0, ~sum);
                OutData.Write16(checksumAddress + 2, sum);
            }

            // Resize ROM into a new array
            var rtn = OutData;
            if (finalRomSize < OutData.Length)
                Array.Resize(ref rtn, finalRomSize);
            else
                rtn = (byte[])rtn.Clone();

            // Restore old OutData before returning the final ROM
            Array.Copy(oldOutData, OutData, OutData.Length);
            progress?.Report(new Tuple<string, int, int>(null, 0, 0));
            return rtn;

            void IfCancel()
            {
                if (ct.HasValue && ct.Value.IsCancellationRequested)
                {
                    // Restore old OutData when task is cancelled
                    Array.Copy(oldOutData, OutData, OutData.Length);
                    ct?.ThrowIfCancellationRequested();
                }
            }
        }

        private int CalculateChecksum(byte[] data, int fileSize)
        {
            Int32 mirroredSize = fileSize.RoundToPowerOf2();

            int sum = 0;
            for (int i = 0; i < mirroredSize;)
            {
                // Get highest cleared bit compared to fileSize
                Int32 highBit = ~i & fileSize;
                while ((highBit & (highBit - 1)) != 0)
                    highBit &= highBit - 1;
                if (highBit == 0)
                    highBit = fileSize & ~(fileSize - 1);

                // Get mirror offsets
                Int32 topOffset = ~(highBit - 1) & fileSize;
                Int32 bottomOffset = topOffset & ~highBit;

                // Count bytes
                for (int u = bottomOffset; u < topOffset; u++)
                    sum += data[u];

                // Next
                i += topOffset - bottomOffset;
            }

            return sum;
        }

        int ConvertSnesBankToFileAddress(int bankNum)
        {
            return (((bankNum ^ 0x80) & 0x80) >> 1) |
                    (bankNum & 0x3f);
        }

        #endregion
        // --------------------------------------------------------------------
        #region Patch ranges

        private int[] GetPatchRangeData()
        {
            var list = new List<Tuple<int, int>>();

            // Create list
            foreach (var item in patches)
            {
                var addrStart = item.Value.GetNesAddress(this.prgBankSize, this.prgBanksTotal, false);
                var addrEnd = item.Value.GetNesAddress(this.prgBankSize, this.prgBanksTotal, true);

                if (addrStart >= 0)
                    list.Add(new Tuple<int, int>(addrStart, addrEnd));
            }

            // Sort list
            list.Sort((a, b) => a.Item1.CompareTo(b.Item1));

            // Merge ranges
            for (int i = list.Count - 1; i >= 1; i--)
            {
                var left = list[i - 1];
                var right = list[i - 0];

                if (left.Item2 > right.Item1)
                {
                    // Merge into 'left' range
                    var start = left.Item1 < right.Item1 ? left.Item1 : right.Item1;
                    var end = left.Item2 > right.Item2 ? left.Item2 : right.Item2;
                    list[i - 1] = new Tuple<int, int>(start, end);

                    // Remove 'right' range
                    list.RemoveAt(i);

                    // Test this again
                    i++;
                }
            }

            // Sort list again (shouldn't be necessary)
            list.Sort((a, b) => a.Item1.CompareTo(b.Item1));

            // Return as int[]
            var rtn = new List<int>();
            foreach (var item in list)
            {
                rtn.Add(item.Item1);
                rtn.Add(item.Item2);
            }

            return rtn.ToArray();
        }

        #endregion
        // --------------------------------------------------------------------
        #region Convert address

        public static int ConvertSnesToFileAddress(int addr)
        {
            if ((addr & 0xfe0000) == 0x7e0000 || (addr & 0x408000) == 0)
                throw new ArgumentOutOfRangeException();

            return ((~addr & 0x800000) >> 1) | (addr & 0x3fffff);
        }

        #endregion
        // --------------------------------------------------------------------
        #region Add Data

        private int AddData(c65816 emu, byte[] data)
        {
            int addr = Malloc(emu, data.Length);
            int snesAddr = ConvertSnesToFileAddress(addr);

            for (int i = 0; i < data.Length; i++)
                OutData.Write32(snesAddr + i, data[i]);

            return addr;
        }

        private int AddData(c65816 emu, int[] data)
        {
            int addr = Malloc(emu, data.Length * 4);
            int snesAddr = ConvertSnesToFileAddress(addr);

            for (int i = 0; i < data.Length; i++)
                OutData.Write32(snesAddr + i * 4, data[i]);

            return addr;
        }

        #endregion
        // --------------------------------------------------------------------
        #region Virtual calls

        public c65816 NewEmulator(byte[] sram)
        {
            var emu = new c65816(OutData, sram);
            emu.ExecuteInit(null);
            emu.memory.ReadROM(OutData);
            return emu;
        }

        public c65816 NewEmulatorNoInit(byte[] sram)
        {
            var emu = new c65816(OutData, sram);
            return emu;
        }

        private void StaticRecompiler(c65816 emu)
        {
            emu.SetRegPC(GetSetting("StaticRec.Main").ReadInt());
            emu.Execute(OutData);
        }

        private int Malloc(c65816 emu, int length)
        {
            emu.memory.DebugWriteTwoByte(0, length);
            emu.SetRegPC(GetSetting("Memory.Alloc").ReadInt());
            emu.Execute(OutData);
            return emu.memory.DebugReadThreeByte(0);
        }

        public Raw65816 RecompilerBuild(c65816 emu, int nesAddr)
        {
            emu.memory.DebugWriteFourByte(0, nesAddr);
            emu.SetRegPC(GetSetting("Recompiler.Build").ReadInt());
            emu.Execute();
            return new Raw65816(
                nesAddr,
                emu.PullByteArray(),
                emu.memory.DebugReadThreeByte(0),
                emu.memory.DebugReadThreeByte(4),
                emu.memory.DebugReadTwoByte(8));
        }

        internal int AddCallLinks(c65816 emu, List<LinkOrigin> links)
        {
            if (links.Count == 0)
                return emu.memory.DebugReadThreeByte(0);

            int? baseAddress = null;
            emu.memory.WriteROM(OutData);
            foreach (var link in links)
            {
                emu.memory.DebugWriteFourByte(0, link.wholeData);
                emu.SetRegPC(GetSetting("StaticRec.AddCallLink").ReadInt());
                emu.Execute();

                if (baseAddress == null)
                    baseAddress = emu.memory.DebugReadThreeByte(0);
            }
            emu.memory.ReadROM(OutData);

            return baseAddress.Value;
        }

        #endregion
        // --------------------------------------------------------------------
        #region Range test

        public bool IsRangeStatic(int src, int dest)
        {
            // Also exists in assembly form as DynamicJsr__IsRangeStatic

            // Are source and destination in the same range?
            if (((src ^ dest) & PrgBankingMask.Value) == 0)
                return true;        // Same range

            // Return whether range is static
            return ((StaticRange.Value >> (dest >> 13)) & 1) != 0;
        }

        public int GetStaticBankDestination(int src, int dest)
        {
            if (IsRangeStatic(src, dest) && (ushort)dest >= 0x8000)
            {
                if (src == dest)
                    return (src >> 16) & 0xff;
                else
                    return PrgBankNumbers[(dest >> 13) - 4];
            }
            else
                return -1;
        }

        #endregion
        // --------------------------------------------------------------------
        #region Emulator calls

        public static List<EmulatorCall> InitEmulatorCallList()
        {
            var injector = new Injector(null);

            var list = new List<EmulatorCall>();

            var addr = ConvertSnesToFileAddress(injector.GetSetting("EmuCalls.Table").ReadInt());

            // ID 0 should be invalid
            list.Add(EmulatorCall.Unknown());

            while (true)
            {
                var name = injector.OutData.ReadString0(ref addr);
                if (name == string.Empty)
                    break;

                var snesAddr = injector.OutData.Read24(ref addr);
                var usage = injector.OutData.Read32(ref addr);
                var change = injector.OutData.Read32(ref addr);

                list.Add(new EmulatorCall(name, snesAddr, (FlagAndRegs)usage, (FlagAndRegs)change, list.Count));
            }

            return list;
        }

        #endregion
        // --------------------------------------------------------------------
        #region SNES Rom access

        public byte ReadSnesByte(int snesAddr)
        {
            var addr = ConvertSnesToFileAddress(snesAddr);

            return OutData[addr];
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

        public byte ReadEmulatorVersionByte()
        {
            return OutData.Read8(0xffdb);
        }

        #endregion
        // --------------------------------------------------------------------
        #region iNES Header reader

        public Int32 ReadMapper()
        {
            // Read mapper bits 0-3
            Int32 mapper = (SrcData[6] >> 4);

            // Read mapper bits 4-7
            mapper |= (SrcData[7] >> 4) << 4;

            // Verify byte 7 compatibility
            if ((SrcData[7] & 0x0c) != 0x08)
                return mapper;

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
        // --------------------------------------------------------------------
        #region NES ROM Crc32

        public uint GetCrc32() => CRC32.Crc32(0, SrcDataCopy, SrcDataCopy.Length);

        #endregion
        // --------------------------------------------------------------------
        #region Validation error

        public bool IsLoaded(bool showWarning)
        {
            bool rtn = OutData != null;
            if (!rtn & showWarning)
                System.Windows.Forms.MessageBox.Show("Project_Nested.smc could not be loaded, please make sure it is present in the same folder.", "Error!");
            return rtn;
        }

        #endregion
    }
}
