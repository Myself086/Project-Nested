using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Project_Nested.Injection;

namespace Project_Nested
{
    class SrmFeedbackReader
    {
        #region Variables

        byte[] data;

        public bool IsValid { get => data != null; }

        // Base offset for the SRM header
        int header;
        int? profileName;
        int? entryPointsLowerBound;
        int? entryPointsUpperBound;
        int? entryPointsTop;
        int? links;

        #endregion
        // --------------------------------------------------------------------
        #region Constructor

        public SrmFeedbackReader(Injector injector, byte[] data)
        {
            if (injector == null)
                injector = new Injector(null);

            // Find header
            if (injector.IsLoaded(true))
            {
                var title = ExpectedHeader(injector);

                // Get header offset
                this.header = data.FindSequence(title, title.Length);

                if (this.header < 0)
                {
                    this.data = null;
                    return;
                }
                int? ReadOffset(string varName)
                {
                    var temp = injector.GetSetting(varName);
                    if (temp != null)
                        return temp.ReadInt() + this.header;
                    return null;
                }
                this.profileName = ReadOffset("Feedback.ProfileName");
                this.entryPointsLowerBound = ReadOffset("Feedback.EntryPoints.LowerBound");
                this.entryPointsUpperBound = ReadOffset("Feedback.EntryPoints.UpperBound");
                this.entryPointsTop = ReadOffset("Feedback.EntryPoints.Top");
                this.links = ReadOffset("Feedback.Links");

                this.data = data;
            }
        }

        #endregion
        // --------------------------------------------------------------------
        #region Sram header

        public static byte[] ExpectedHeader(Injector injector)
        {
            var title = new List<byte>();

            title.AddRange(injector.ReadEmulatorTitleBytes());
            title.Add(injector.ReadEmulatorVersionByte());

            return title.ToArray();
        }

        #endregion
        // --------------------------------------------------------------------
        #region Address translation

        private int Read16BitAddress(int offset)
        {
            return (offset & -0x2000) | (data.Read16(offset) & 0x1fff);
        }

        #endregion
        // --------------------------------------------------------------------
        #region Getters

        public string GetProfileName()
        {
            if (this.profileName == null)
                return null;

            return data.ReadString(this.profileName.Value, 0x80).Trim(' ', '\t', '\0');
        }

        public List<int> GetFunctionEntryPoints()
        {
            if (this.entryPointsLowerBound == null || this.entryPointsUpperBound == null || this.entryPointsTop == null)
                return null;

            List<int> list = new List<int>();

            {
                // Get bottom/top address
                int bottom = this.entryPointsLowerBound.Value;
                int top = Read16BitAddress(this.entryPointsTop.Value);

                for (int i = bottom; i < top; i += 3)
                {
                    list.Add(data.Read24(i));
                }
            }

            return list;
        }

        public Dictionary<int, int> GetCallLinks()
        {
            if (this.links == null)
                return null;

            throw new NotImplementedException();
        }

        #endregion
    }
}
