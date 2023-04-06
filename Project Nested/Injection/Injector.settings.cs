using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested.Injection
{
    public class Crc32EventArgs : EventArgs
    {
        public uint Crc32 { get; set; }
    }
    partial class Injector
    {
        #region Rom settings

        public Dictionary<string, Patch> patches = new Dictionary<string, Patch>();
        public event Action PatchesCountChanged;

        List<int> calls = new List<int>();
        public int KnownCallCount => calls.Count;
        public event Action KnownCallCountChanged;

        public List<int> excludedCalls = new List<int>();

        public event EventHandler<Crc32EventArgs> Crc32Mismatched;

        private void LoadSettings()
        {
            _settings.Clear();

            // Settings pointer is expected to be at 0x00ff00 in the file
            int addr = ConvertSnesToFileAddress(OutData.Read24(0x00ff00));

            // Read settings
            while (true)
            {
                string def = OutData.ReadString0(ref addr);
                if (def == string.Empty)
                    break;

                Int32 snesAddr = OutData.Read24(ref addr);
                Int16 mask = OutData.Read16(ref addr);

                // Split summary and definition
                Int32 split = def.LastIndexOf("\r\n");
                string summary = string.Empty;
                if (split > 0)
                {
                    summary = def.Substring(0, split);
                    def = def.Substring(split + 2);
                }

                // Create new setting
                Setting setting = new Setting(this.OutData, def, summary, snesAddr, mask);

                // Add new setting
                if (!setting.IsEnumValue)
                    _settings.Add(setting.Name, setting);
            }
        }

        #endregion
        // --------------------------------------------------------------------
        #region Settings access

        public void ResetSettings()
        {
            ResetSettings(false);
        }

        public void ResetSettings(bool keepCalls)
        {
            patches.Clear();
            PatchesCountChanged?.Invoke();
            if (!keepCalls)
            {
                calls.Clear();
                KnownCallCountChanged?.Invoke();
            }

            unknownSettings.Clear();
            foreach (var item in settings)
                if (item.Value.IsPublic && !item.Value.IsGlobal && item.Value.IsVariable)
                    item.Value.SetValue(item.Value.DefaultValue);
        }

        public Dictionary<string, Setting> GetAllSettingsObject()
        {
            // Return a copy of settings dictionary
            return new Dictionary<string, Setting>(settings);
        }

        public string GetAllSettings(bool skipDefaultValues, bool singleLine)
        {
            StringBuilder sb = new StringBuilder();

            void AppendLine(string str)
            {
                if (!singleLine)
                    sb.AppendLine(str);
                else
                {
                    sb.Append(str);
                    sb.Append(';');
                }
            }

            // Crc32
            AppendLine($"File_CRC32: {this.GetFileCrc32():x8}");
            AppendLine($"ROM_CRC32: {this.GetRomCrc32():x8}");

            // Settings
            foreach (var item in settings)
                if (item.Value.IsPublic && !item.Value.IsGlobal && item.Value.IsVariable)
                    if (!skipDefaultValues || !item.Value.IsDefaultValue())
                        AppendLine(item.Value.ToString());

            // Unknown settings
            foreach (var item in unknownSettings)
                AppendLine(item);

            // Calls
            AppendLine(ConvertCallsToString(this.calls));

            // Patches
            foreach (var item in patches)
                AppendLine(item.Value.ToString());

            return sb.ToString();
        }

        public string GetAllGlobalSettings()
        {
            StringBuilder sb = new StringBuilder();

            foreach (var item in settings)
                if (item.Value.IsGlobal && item.Value.type != SettingType.Void)
                    sb.AppendLine(item.Value.ToString());

            return sb.ToString();
        }

        public int[] GetAllKnownCalls()
        {
            return calls.ToArray();
        }

        public bool KnownCallsContainsInclusively(int addr)
        {
            return calls.Contains(addr);
        }

        public bool KnownCallsContainsExclusively(int addr)
        {
            return calls.Contains(addr) && !excludedCalls.Contains(addr);
        }

        public string ConvertCallsToString(List<int> calls)
        {
            StringBuilder sb = new StringBuilder();

            if (calls.Count > 0)
            {
                sb.Append("Calls: ");
                foreach (var item in calls)
                    sb.Append($"0x{item:x6}, ");
                sb.Length -= 2;
                sb.AppendLine();
            }

            return sb.ToString();
        }

        public string GetSetting(string name)
        {
            Setting setting;
            if (settings.TryGetValue(name, out setting))
                return setting.GetValue();
            return null;
        }

        public string GetSetting(string name, int index)
        {
            Setting setting;
            if (settings.TryGetValue(name, out setting))
                return setting[index];
            return null;
        }

        public void SetAllSettings(string commandLines)
        {
            // Find splits
            List<int> splits = new List<int>();
            bool quote = false;
            splits.Add(-1);
            for (int i = 0; i < commandLines.Length; i++)
            {
                var c = commandLines[i];
                if (c == '\"')
                    quote = !quote;
                else if (c == '\r' || c == '\n' || c == ';')
                    if (!quote)                 // Skip 'new line' if it's within quotation marks
                        splits.Add(i);
            }
            splits.Add(commandLines.Length);

            // Split lines
            var lines = new string[splits.Count - 1];
            for (int i = 0; i < lines.Length; i++)
            {
                var start = splits[i + 0] + 1;
                var end = splits[i + 1] - 1;

                lines[i] = commandLines.Substring(start, end - start + 1);
            }

            SetAllSettings(lines);
        }

        public void SetAllSettings(string[] commandLines)
        {
            foreach (var item in commandLines)
                SetSetting(item);
        }

        public void SetSetting(string commandLine)
        {
            // Trim spaces
            commandLine = commandLine.Trim();

            // What type of line is it?
            if (commandLine.StartsWith("["))
            {
                // Patch
                foreach (var line in commandLine.Split(';'))
                {
                    var patch = new Patch(line);
                    patches[patch.GetAddressString()] = patch;
                }
                PatchesCountChanged?.Invoke();
            }
            else if (commandLine.ToLowerInvariant().StartsWith("calls:"))
            {
                // Calls
                var colon = commandLine.IndexOf(':');
                var addresses = commandLine.Substring(colon + 1).Split(',');
                foreach (var address in addresses)
                {
                    int addr = address.ReadInt();
                    if (!calls.Contains(addr))
                        calls.Add(addr);
                }
                KnownCallCountChanged?.Invoke();
            }
            else if (commandLine.ToUpperInvariant().StartsWith("ROM_CRC32:"))
            {
                var colon = commandLine.IndexOf(':');
                var crc32 = Convert.ToUInt32(commandLine.Substring(colon + 1).Trim(), 16);
                if (crc32 != GetRomCrc32())
                    Crc32Mismatched?.Invoke(this, new Crc32EventArgs() { Crc32 = crc32 });
            }
            else
            {
                // Setting
                int equalSign = commandLine.IndexOf('=');
                if (equalSign >= 0)
                    if (!SetSetting(commandLine.Substring(0, equalSign), commandLine.Substring(equalSign + 1)))
                        unknownSettings.Add(commandLine);
            }
        }

        public bool SetSetting(string name, string value)
        {
            name = name.Trim();

            bool rtn;
            if (rtn = settings.ContainsKey(name))
                settings[name].SetValue(value);
            return rtn;
        }

        public bool SetSetting(string name, int index, string value)
        {
            name = name.Trim();

            bool rtn;
            if (rtn = settings.ContainsKey(name))
                settings[name][index] = value;
            return rtn;
        }

        #endregion
        // --------------------------------------------------------------------
        #region Setting wrapper

        public struct SettingWrapper<T>
        {
            private Dictionary<string, Setting> settings;
            private string varName;
            private Setting varObj => settings[varName];
            private bool mirrored;

            public T this[int index]
            {
                get
                {
                    var value = varObj[index];
                    if (varObj.IsHex)
                        return (T)Convert.ChangeType(value.ReadInt(), typeof(T));
                    return (T)Convert.ChangeType(value, typeof(T));
                }
                set => varObj[index] = value.ToString();
            }

            public T[] Array
            {
                get
                {
                    T[] array = new T[varObj.Length];
                    for (int i = 0; i < varObj.Length; i++)
                        array[i] = this[i];
                    return array;
                }
                set
                {
                    if (!mirrored)
                    {
                        for (int i = 0; i < value.Length; i++)
                            this[i] = value[i];
                    }
                    else
                    {
                        if (value.Length == 0)
                            value = new T[1];
                        for (int i = 0; i < varObj.Length; i++)
                            this[i] = value[i % value.Length];
                    }
                }
            }

            public T Value
            {
                get
                {
                    var value = varObj.GetValue();
                    if (varObj.IsHex)
                        return (T)Convert.ChangeType(value.ReadInt(), typeof(T));
                    return (T)Convert.ChangeType(value, typeof(T));
                }
                set => varObj.SetValue(value.ToString());
            }

            public T[] GetArray() => Array;
            public void SetArray(T[] value) => Array = value;

            public T GetValue() => Value;
            public T GetValueAt(int index) => this[index];
            public void SetValue(T value) => Value = value;
            public void SetValueAt(int index, T value) => this[index] = value;
            public void SetAsDefaultValue() => varObj.SetAsDefaultValue();

            public SettingWrapper(Dictionary<string, Setting> settings, string varName)
            {
                this.settings = settings;
                this.varName = varName;
                this.mirrored = false;
            }

            public SettingWrapper(Dictionary<string, Setting> settings, string varName, bool mirrored)
            {
                this.settings = settings;
                this.varName = varName;
                this.mirrored = mirrored;
            }
        }

        #endregion
    }
}
