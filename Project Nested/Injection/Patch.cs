using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Injection
{
    public enum PatchTypeEnum
    {
        NesAddr,
        FileAddrPlus,
        FileAddr,
        GameGenie6,
        GameGenie8,
    }
    public class Patch
    {
        // Accepted format for command line
        //  Address format
        //   [04:8123] or [bank:addr] where addr represents an address from the NES perspective and bank based on mapper specification
        //   [10123+] where the address is from a headerless file perspective
        //   [10133] where the address is from a headered file perspective
        //   [APZLGITY] game genie code
        //  Data format (hex only)
        //   [] = 00 01 02 ff FF aA
        //   [] = 0x00, 0x01, 0x02
        //   []=0 0 0 0 0 0 0

        private const string GAME_GENIE_NUMERALS = "APZLGITYEOXUKSVN";

        public PatchTypeEnum PatchType { get; private set; }
        public int NesAddress { get; private set; }
        public int NesBank { get; private set; }
        public byte[] Data { get; private set; }
        public int Length { get => Data != null ? Data.Length : 0; }
        public byte[] Compare { get; private set; }
        public int CompareLength { get => Compare != null ? Compare.Length : 0; }

        public Patch(int nesAddress, int nesBank, byte[] data, byte[] compare, PatchTypeEnum PatchType)
        {
            this.PatchType = PatchType;
            this.NesAddress = nesAddress;
            this.NesBank = nesBank;
            this.Data = data;
            this.Compare = compare;
        }

        public Patch(string commandLine)
        {
            // Find brackets and equal sign
            int bracketStart = commandLine.IndexOf('[');
            int bracketEnd = commandLine.IndexOf(']');
            int equalSign = commandLine.IndexOf('=');

            if (bracketEnd < 0) bracketEnd = commandLine.Length;

            // Split address and data
            string address = commandLine.Substring(bracketStart + 1, bracketEnd - bracketStart - 1).Trim();
            string data = commandLine.Substring(equalSign + 1);
            bool header = address.EndsWith("+");
            if (header)
                address = address.Substring(0, address.Length - 1);

            // Read address based on format (format information at the top of this class)
            string[] addressSplit = address.Split(':');
            var gameGenie = ConvertGameGenieToHex(address);
            if (gameGenie != null && address.Length == 6)
            {
                this.PatchType = PatchTypeEnum.GameGenie6;
                this.NesAddress = gameGenie.Value << 8;
            }
            else if (gameGenie != null && address.Length == 8)
            {
                this.PatchType = PatchTypeEnum.GameGenie8;
                this.NesAddress = gameGenie.Value << 0;
            }
            else if (addressSplit.Length > 1)
            {
                this.PatchType = PatchTypeEnum.NesAddr;
                this.NesBank = Convert.ToInt32(addressSplit[0], 16);
                this.NesAddress = Convert.ToInt32(addressSplit[1], 16);
            }
            else
            {
                this.PatchType = header ? PatchTypeEnum.FileAddrPlus : PatchTypeEnum.FileAddr;
                this.NesBank = -1;
                this.NesAddress = Convert.ToInt32(addressSplit[0], 16);
            }

            // Read data
            if (equalSign >= 0 && gameGenie == null)
            {
                // Split compare and data
                var cmpData = data.Split('?');
                string compare = null;
                if (cmpData.Length > 2)
                    throw new Exception("Too many question marks");
                else if (cmpData.Length == 2)
                {
                    compare = cmpData[0];
                    data = cmpData[1];
                }

                byte[] ReadBytes(string str)
                {
                    if (str == null)
                        return null;

                    string[] split = str.Split(new string[] { " ", ",", "0x" }, StringSplitOptions.RemoveEmptyEntries);
                    List<byte> list = new List<byte>(split.Length);
                    foreach (var item in split)
                        list.Add(Convert.ToByte(item, 16));
                    return list.ToArray();
                }

                this.Data = ReadBytes(data);
                this.Compare = ReadBytes(compare);
            }
        }

        private int? ConvertGameGenieToHex(string str)
        {
            int rtn = 0;

            str = str.ToUpperInvariant();

            foreach (var chr in str)
            {
                var numeral = GAME_GENIE_NUMERALS.IndexOf(chr);

                // If numeral is invalid, this isn't a game genie cheat
                if (numeral < 0)
                    return null;

                rtn = (rtn << 4) | numeral;
            }

            return rtn;
        }

        public void Apply(byte[] rom, int prgSize, int prgBanksTotal)
        {
            int addr;
            switch (PatchType)
            {
                default: throw new NotImplementedException();
                case PatchTypeEnum.NesAddr:
                    if (NesAddress < 0x8000)
                        return;
                    addr = (this.NesAddress % prgSize) + ((this.NesBank % prgBanksTotal) * prgSize) + 0x10;
                    break;
                case PatchTypeEnum.FileAddrPlus:
                    addr = this.NesAddress + 0x10;
                    break;
                case PatchTypeEnum.FileAddr:
                    addr = this.NesAddress;
                    break;
                case PatchTypeEnum.GameGenie8:
                case PatchTypeEnum.GameGenie6:
                    // Not applied here
                    return;
            }

            bool CompareData()
            {
                if (Compare == null)
                    return true;

                for (int i = 0; i < Compare.Length; i++)
                {
                    if (rom[addr + i] != Compare[i])
                        return false;
                }
                return true;
            }

            if (CompareData())
                rom.WriteArray(addr, this.Data, this.Data.Length);
        }

        public void ApplyGameGenie(byte[] snesRom, List<int> baseAddresses)
        {
            int Nibble(int index) => this.NesAddress >> ((7 - index) * 4);

            switch (PatchType)
            {
                // Code from http://tuxnes.sourceforge.net/gamegenie.html
                case PatchTypeEnum.GameGenie6:
                    {
                        var address = 0x8000 +
                            ((Nibble(3) & 7) << 12)
                            | ((Nibble(5) & 7) << 8) | ((Nibble(4) & 8) << 8)
                            | ((Nibble(2) & 7) << 4) | ((Nibble(1) & 8) << 4)
                            | (Nibble(4) & 7) | (Nibble(3) & 8);
                        var data =
                            ((Nibble(1) & 7) << 4) | ((Nibble(0) & 8) << 4)
                            | (Nibble(0) & 7) | (Nibble(5) & 8);

                        foreach (var item in baseAddresses)
                            snesRom[item + address] = (byte)data;
                    }
                    break;
                case PatchTypeEnum.GameGenie8:
                    {
                        var address = 0x8000 +
                            ((Nibble(3) & 7) << 12)
                            | ((Nibble(5) & 7) << 8) | ((Nibble(4) & 8) << 8)
                            | ((Nibble(2) & 7) << 4) | ((Nibble(1) & 8) << 4)
                            | (Nibble(4) & 7) | (Nibble(3) & 8);

                        var data =
                            ((Nibble(1) & 7) << 4) | ((Nibble(0) & 8) << 4)
                            | (Nibble(0) & 7) | (Nibble(7) & 8);

                        var compare =
                            ((Nibble(7) & 7) << 4) | ((Nibble(6) & 8) << 4)
                            | (Nibble(6) & 7) | (Nibble(5) & 8);

                        foreach (var item in baseAddresses)
                            if (snesRom[item + address] == compare)
                                snesRom[item + address] = (byte)data;
                    }
                    break;
            }
        }

        public int GetNesAddress(int prgSize, int prgBanksTotal, bool end)
        {
            int prgMask = prgSize - 1;
            int addr = end ? this.NesAddress + this.Length - 1 : this.NesAddress;
            int rtn;

            switch (PatchType)
            {
                default: throw new NotImplementedException();
                case PatchTypeEnum.NesAddr:
                    if (NesAddress < 0x8000)
                        prgMask = 0xffff;
                    rtn = (addr | (prgMask ^ 0xffff)) + ((this.NesBank % prgBanksTotal) << 16);
                    break;
                case PatchTypeEnum.FileAddrPlus:
                    rtn = (addr / prgSize * 0x10000) + ((addr | ~prgMask) & 0xffff);
                    break;
                case PatchTypeEnum.FileAddr:
                    rtn = ((addr - 0x10) / prgSize * 0x10000) + (((addr - 0x10) | ~prgMask) & 0xffff);
                    break;
                case PatchTypeEnum.GameGenie6:
                case PatchTypeEnum.GameGenie8:
                    // Not applied here
                    return -1;
            }

            return rtn;
        }

        public string GetAddressString()
        {
            // Write address based on format (format information at the top of this class)
            switch (PatchType)
            {
                default: throw new NotImplementedException();
                case PatchTypeEnum.NesAddr:
                    return string.Format("{1:x2}:{0:x4}", NesAddress & 0xffff, NesBank & 0xffff);
                case PatchTypeEnum.FileAddrPlus:
                    return string.Format("{0:x6}+", NesAddress & 0xffffff);
                case PatchTypeEnum.FileAddr:
                    return string.Format("{0:x6}", NesAddress & 0xffffff);
                case PatchTypeEnum.GameGenie6:
                    return string.Format("{0:x6}", ConvertIntToGameGenie(NesAddress, 6));
                case PatchTypeEnum.GameGenie8:
                    return string.Format("{0:x8}", ConvertIntToGameGenie(NesAddress, 8));
            }
        }

        private string ConvertIntToGameGenie(int code, int size)
        {
            StringBuilder sb = new StringBuilder();

            code = code >> ((8 - size) * 4);

            for (int i = size - 1; i >= 0; i--)
            {
                sb.Append(GAME_GENIE_NUMERALS[(code >> (i * 4)) & 0xf]);
            }

            return sb.ToString();
        }

        public override string ToString()
        {
            StringBuilder sb = new StringBuilder();

            sb.AppendFormat("[{0}]", GetAddressString());

            if (Data != null)
            {
                sb.Append(" = ");

                if (Compare != null && Compare.Length > 0)
                {
                    foreach (var item in Compare)
                        sb.Append($"{item:x2} ");
                    sb.Append("? ");
                }

                foreach (var item in Data)
                    sb.Append($"{item:x2} ");
                // Remove last space
                sb.Length--;
            }

            return sb.ToString();
        }
    }
}
