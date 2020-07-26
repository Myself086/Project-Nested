using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested
{
    static class StringExtension
    {
        public static int ReadInt(this string value)
        {
            value = value.Trim();
            if (value.StartsWith("0x"))
            {
                return Convert.ToInt32(value.Substring(2), 16);
            }
            else
                return Convert.ToInt32(value);
        }
    }
}
