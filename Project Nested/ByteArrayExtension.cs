using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested
{
    static class ByteArrayExtension
    {
        #region Custom binary writer

        public static void Write8(this byte[] data, Int32 addr, Int32 value)
        {
            data[addr++] = (byte)(value >> 0);
        }

        public static void Write16(this byte[] data, Int32 addr, Int32 value)
        {
            data[addr++] = (byte)(value >> 0);
            data[addr++] = (byte)(value >> 8);
        }

        public static void Write24(this byte[] data, Int32 addr, Int32 value)
        {
            data[addr++] = (byte)(value >> 0);
            data[addr++] = (byte)(value >> 8);
            data[addr++] = (byte)(value >> 16);
        }

        public static void Write32(this byte[] data, Int32 addr, Int32 value)
        {
            data[addr++] = (byte)(value >> 0);
            data[addr++] = (byte)(value >> 8);
            data[addr++] = (byte)(value >> 16);
            data[addr++] = (byte)(value >> 24);
        }

        public static void WriteArrayMirrored(this byte[] data, Int32 addr, byte[] value, Int32 length)
        {
            if (value.Length > 0)
                for (int i = 0; i < length; i += value.Length)
                    data.WriteArray(addr + i, value, length - i);
        }

        public static void WriteArray(this byte[] data, Int32 addr, byte[] value, Int32 length) => WriteArray(data, ref addr, value, length);
        public static void WriteArray(this byte[] data, ref Int32 addr, byte[] value, Int32 length)
        {
            length = value.Length < length ? value.Length : length;
            Array.Copy(value, 0, data, addr, value.Length < length ? value.Length : length);
            addr += length;
        }

        public static void WriteString(this byte[] data, Int32 addr, string value, Int32 length)
        {
            data.WriteArray(addr, Encoding.ASCII.GetBytes(value), length);
        }

        public static void WriteString(this byte[] data, Int32 addr, string value, Int32 length, char fill)
        {
            var bytes = Encoding.ASCII.GetBytes(value);
            data.WriteArray(addr, bytes, length);
            // Fill unused bytes
            for (int i = bytes.Length; i < length; i++)
                data.Write8(addr + i, fill);
        }

        public static void WriteBool(this byte[] data, Int32 addr, short bitmask, bool value)
        {
            data.Write16(addr, (data.Read16(addr) & ~bitmask) | (value ? bitmask : 0));
        }

        public static void WriteBool8(this byte[] data, Int32 addr, bool value)
        {
            data.Write8(addr, value ? -1 : 0);
        }

        public static void WriteBool16(this byte[] data, Int32 addr, bool value)
        {
            data.Write16(addr, value ? -1 : 0);
        }

        #endregion
        // --------------------------------------------------------------------
        #region Custom binary reader

        public static byte Read8(this byte[] data, Int32 addr) => data.Read8(ref addr);
        public static byte Read8(this byte[] data, ref Int32 addr)
        {
            return (byte)
                (data[addr++] << 0);
        }

        public static short Read16(this byte[] data, Int32 addr) => data.Read16(ref addr);
        public static short Read16(this byte[] data, ref Int32 addr)
        {
            return (short)(
                (data[addr++] << 0) |
                (data[addr++] << 8));
        }

        public static Int32 Read24(this byte[] data, Int32 addr) => data.Read24(ref addr);
        public static Int32 Read24(this byte[] data, ref Int32 addr)
        {
            return
                (data[addr++] << 0) |
                (data[addr++] << 8) |
                (data[addr++] << 16);
        }

        public static Int32 Read32(this byte[] data, Int32 addr) => data.Read32(ref addr);
        public static Int32 Read32(this byte[] data, ref Int32 addr)
        {
            return
                (data[addr++] << 0) |
                (data[addr++] << 8) |
                (data[addr++] << 16) |
                (data[addr++] << 24);
        }

        public static byte[] ReadArray(this byte[] data, Int32 addr, Int32 length) => data.ReadArray(ref addr, length);
        public static byte[] ReadArray(this byte[] data, ref Int32 addr, Int32 length)
        {
            var rtn = new byte[length];
            Array.Copy(data, addr, rtn, 0, length);
            return rtn;
        }

        public static string ReadString(this byte[] data, Int32 addr, Int32 length) => data.ReadString(ref addr, length);
        public static string ReadString(this byte[] data, ref Int32 addr, Int32 length)
        {
            Int32 addrStart = addr;
            addr += length;
            return Encoding.ASCII.GetString(data, addrStart, addr - addrStart);
        }

        public static string ReadString0(this byte[] data, Int32 addr) => data.ReadString0(ref addr);
        public static string ReadString0(this byte[] data, ref Int32 addr)
        {
            Int32 addrStart = addr;
            while (data[addr++] != 0)
                ;
            return Encoding.ASCII.GetString(data, addrStart, addr - addrStart - 1);
        }

        public static bool ReadBool(this byte[] data, Int32 addr, short bitmask)
        {
            return (data.Read16(ref addr) & bitmask) != 0;
        }

        #endregion
        // --------------------------------------------------------------------
        #region Sequence finder

        public static int FindSequence(this byte[] data, byte[] find)
        {
            return FindSequence(data, find, find.Length);
        }

        public static int FindSequence(this byte[] data, byte[] find, int length)
        {
            // Populate increment table
            int[] incTable = new int[0x100];
            {
                // Default increment to the length of bytes to find
                for (int i = 0; i < incTable.Length; i++)
                    incTable[i] = length;
                // Mark bytes that we care about
                for (int i = 0; i < length; i++)
                    incTable[find[i]] = length - i - 1;
            }

            // Start searching data
            int inc = 1;
            for (int i = length - 1; i < data.Length; i += inc)
            {
                // Read the increment value of our current byte
                inc = incTable[data[i]];

                // Have we found the correct ending character?
                if (inc == 0)
                {
                    {
                        // Compare whole find buffer
                        for (int u = 0; u < length; u++)
                        {
                            if (data[u + i - length + 1] != find[u])
                                goto next;
                        }
                        // Match found, return its index
                        return i - length + 1;
                    }
                    next:
                    inc = 1;
                }
            }

            return -1;
        }

        #endregion
    }
}
