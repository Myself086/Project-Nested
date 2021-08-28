using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Injection
{
    public class Patch
    {
        // Accepted format for command line
        //  Address format
        //   [04:8123] or [bank:addr] where addr represents an address from the NES perspective and bank based on mapper specification
        //   [10123+] where the address is from a headerless file perspective
        //   [10133] where the address is from a headered file perspective
        //  Data format (hex only)
        //   [] = 00 01 02 ff FF aA
        //   [] = 0x00, 0x01, 0x02
        //   []=0 0 0 0 0 0 0

        public int NesAddress { get; private set; }
        public int NesBank { get; private set; }
        public byte[] Data { get; private set; }
        public int Length { get => Data.Length; }

        public Patch(int nesAddress, int nesBank, byte[] data)
        {
            this.NesAddress = nesAddress;
            this.NesBank = nesBank;
            this.Data = data;
        }

        public Patch(string commandLine)
        {
            // Find brackets and equal sign
            int bracketStart = commandLine.IndexOf('[');
            int bracketEnd = commandLine.IndexOf(']');
            int equalSign = commandLine.IndexOf('=');

            // Split address and data
            string address = commandLine.Substring(bracketStart + 1, bracketEnd - bracketStart - 1);
            string data = commandLine.Substring(equalSign + 1);
            bool header = address.EndsWith("+");
            if (header)
                address = address.Substring(0, address.Length - 1);

            // Read address based on format (format information at the top of this class)
            string[] addressSplit = address.Split(':');
            if (addressSplit.Length > 1)
            {
                this.NesBank = Convert.ToInt32(addressSplit[0], 16);
                this.NesAddress = Convert.ToInt32(addressSplit[1], 16);
            }
            else
            {
                this.NesBank = -1;
                this.NesAddress = Convert.ToInt32(addressSplit[0], 16) + (header ? 0x10 : 0);
            }

            // Read data
            string[] dataSplit = data.Split(new string[] { " ", ",", "0x" }, StringSplitOptions.RemoveEmptyEntries);
            List<byte> dataList = new List<byte>(dataSplit.Length);
            foreach (var item in dataSplit)
                dataList.Add(Convert.ToByte(item, 16));
            this.Data = dataList.ToArray();
        }

        public void Apply(byte[] rom, int prgSize, int prgBanksTotal)
        {
            int addr = NesBank >= 0 ?
                // bank:addr format
                (this.NesAddress % prgSize) + ((this.NesBank % prgBanksTotal) * prgSize) + 0x10 :
                // file address format
                this.NesAddress;

            rom.WriteArray(addr, this.Data, this.Data.Length);
        }

        public int GetNesAddress(int prgSize, int prgBanksTotal, bool end)
        {
            int prgMask = prgSize - 1;

            int addr = end ? this.NesAddress + this.Length - 1 : this.NesAddress;

            int rtn = NesBank >= 0 ?
                // bank:addr format
                (addr | (prgMask ^ 0xffff)) + ((this.NesBank % prgBanksTotal) << 16) :
                // file address format
                ((addr - 0x10) / prgSize * 0x10000) + (((addr - 0x10) | ~prgMask) & 0xffff);

            return rtn;
        }

        public string GetAddressString()
        {
            // Write address based on format (format information at the top of this class)
            if (NesBank >= 0)
                return string.Format("{1:x2}:{0:x4}", NesAddress & 0xffff, NesBank & 0xffff);
            else
                return string.Format("{0:x6}", NesAddress & 0xffffff);
        }

        public override string ToString()
        {
            StringBuilder sb = new StringBuilder();

            sb.AppendFormat("[{0}] = ", GetAddressString());

            foreach (var item in Data)
                sb.Append($"{item:x2} ");
            // Remove last space
            sb.Length--;

            return sb.ToString();
        }
    }
}
