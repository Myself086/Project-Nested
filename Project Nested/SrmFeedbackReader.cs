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
        int? entryPoints;
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
                var title = injector.ReadEmulatorTitleBytes();

                // Get header offset
                this.header = data.FindSequence(title, 16);

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
                this.profileName = ReadOffset("FeedbackProfileName");
                this.entryPoints = ReadOffset("FeedbackEntryPoints");
                this.links = ReadOffset("FeedbackLinks");

                this.data = data;
            }
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

            return data.ReadString(this.profileName.Value, 0x20).Trim(' ', '\t', '\0');
        }

        public List<int> GetFunctionEntryPoints()
        {
            if (this.entryPoints == null)
                return null;

            List<int> list = new List<int>();

            {
                // Get end address (last element +1)
                int end = Read16BitAddress(this.entryPoints.Value);

                for (int i = this.entryPoints.Value + 2; i < end; i += 3)
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
