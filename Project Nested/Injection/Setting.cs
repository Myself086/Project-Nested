using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Project_Nested.Injection
{
    public enum SettingType
    {
        Unknown = 0, Void, VoidStar, Bool, Byte, Short, Pointer, Int, Char, Func, Button
    }

    public class Setting
    {
        public string Name { get; private set; }    // Internal name for coders
        public string Title { get; private set; }   // External name for users
        public string TitleWithPrivacy { get => (IsPublic ? "" : "(private)") + Title; }
        public string Definition { get; private set; }
        public string Summary { get; private set; }
        public bool IsGlobal { get; private set; }
        public bool IsPublic { get; private set; }
        public bool IsVariable { get; private set; } = true;
        public bool IsEnumValue { get; private set; }
        public bool IsResizable { get; private set; }
        public bool IsHex { get; private set; }

        private string DefaultValue;

        private List<int> validMappers;
        public bool IsValidMapper(int mapper) => validMappers == null || validMappers.Contains(mapper);

        public int FileAddress { get; private set; }
        public int SnesAddress { get; private set; }
        public SettingType type { get; private set; }
        public int Length { get; private set; } = 1;
        public short Mask { get; private set; }
        public bool safe { get; private set; } = true;

        public List<Setting> EnumList { get; private set; }
        public bool isEnum { get => EnumList != null; }

        public delegate void OnChange(Setting sender);
        public event OnChange Changed;

        private byte[] data;

        public Setting(byte[] data, string definition, string summary, int snesAddr, int mask)
        {
            this.data = data;
            this.SnesAddress = snesAddr;
            try
            {
                this.FileAddress = Injector.ConvertSnesToFileAddress(snesAddr);
            }
            catch (Exception)
            {
                this.FileAddress = int.MinValue;
            }
            this.Mask = (Int16)mask;
            Constructor(definition, summary);
        }

        private void Constructor(string def, string summary)
        {
            this.Definition = def;
            this.Summary = summary.Length > 0 ? summary : "No summary.";
            // Read definition
            {
                string[] parts = def.Split(':');
                string[] symbols = parts[0].Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
                foreach (var item in symbols)
                {
                    var e = item;

                    // Identify whether this symbol has []
                    {
                        var bracketStart = item.IndexOf('[');
                        var bracketEnd = item.IndexOf(']');
                        if ((bracketStart | bracketEnd) >= 0)
                        {
                            this.Length = e.Substring(bracketStart + 1, bracketEnd - bracketStart - 1).ReadInt();
                            e = e.Substring(0, bracketStart);
                        }
                    }

                    // Identify whether this symbol has <>
                    string lesserGreater = null;
                    {
                        var bracketStart = item.IndexOf('<');
                        var bracketEnd = item.IndexOf('>');
                        if ((bracketStart | bracketEnd) >= 0)
                        {
                            lesserGreater = e.Substring(bracketStart + 1, bracketEnd - bracketStart - 1);
                            e = e.Substring(0, bracketStart);
                        }
                    }

                    switch (e.ToLowerInvariant())
                    {
                        case "global":
                            this.IsGlobal = true;
                            break;
                        case "private":
                            this.IsPublic = false;
                            break;
                        case "public":
                            this.IsPublic = true;
                            break;
                        case "resizable":
                            this.IsResizable = true;
                            break;
                        case "hex":
                            this.IsHex = true;
                            break;
                        case "unsafe":
                            this.safe = false;
                            break;
                        case "void":
                            this.type = SettingType.Void;
                            this.IsVariable = false;
                            break;
                        case "void*":
                            this.type = SettingType.VoidStar;
                            this.Length = 1;
                            break;
                        case "bool":
                            this.type = SettingType.Bool;
                            break;
                        case "byte":
                            this.type = SettingType.Byte;
                            break;
                        case "short":
                            this.type = SettingType.Short;
                            break;
                        case "int":
                            this.type = SettingType.Int;
                            break;
                        case "char":
                            this.type = SettingType.Char;
                            break;
                        case "enum":
                            this.EnumList = new List<Setting>();
                            break;
                        case "readonly":
                            this.IsVariable = false;
                            break;
                        case "value":
                            this.IsEnumValue = true;
                            break;
                        case "mapper":
                            if (lesserGreater != null)
                            {
                                var mappers = lesserGreater.Split(',');
                                this.validMappers = new List<int>(mappers.Length);
                                foreach (var mapper in mappers)
                                {
                                    this.validMappers.Add(mapper.ReadInt());
                                }
                            }
                            break;
                        case "func":
                            if (lesserGreater != null)
                            {
                                this.type = SettingType.Func;
                                this.Length = 1;
                            }
                            this.IsVariable = false;
                            break;
                        case "button":
                            this.type = SettingType.Button;
                            this.IsVariable = false;
                            break;
                        default:
                            // Change name only if this is the last symbol
                            if (item == symbols.Last())
                            {
                                this.Name = e;
                                this.Title = e;     // Default title as variable name, can be changed below
                            }
                            break;
                    }
                }

                // Set title if we have one, otherwise it was set to the variable's internal name
                if (parts.Length > 1)
                    this.Title = parts[1];

                // Set default value
                SetAsDefaultValue();
            }
        }

        private void AttemptWrite()
        {
            if (!IsVariable)
                throw new AccessViolationException($"Setting {this.Title} is read only.");
        }

        public bool TrySetValue(string value)
        {
            try { SetValue(value); }
            catch { return false; }
            return true;
        }

        public string this[int index]
        {
            get
            {
                if ((uint)index >= this.Length && this.type != SettingType.VoidStar)
                    //throw new IndexOutOfRangeException();
                    return null;

                switch (type)
                {
                    default:
                    case SettingType.Void:
                        return null;
                    case SettingType.VoidStar:
                    case SettingType.Func:
                        return $"0x{SnesAddress:x}";
                    case SettingType.Bool:
                        return (data.ReadBool(FileAddress + index / 8, (short)(Mask << (index & 0x7)))).ToString();
                    case SettingType.Byte:
                        return string.Format(IsHex ? "0x{0:x2}" : "{0}", data.Read8(FileAddress + index * 1));
                    case SettingType.Short:
                        return string.Format(IsHex ? "0x{0:x4}" : "{0}", data.Read16(FileAddress + index * 2));
                    case SettingType.Pointer:
                        return string.Format("0x{0:x6}", data.Read8(FileAddress + index * 3));
                    case SettingType.Int:
                        return string.Format(IsHex ? "0x{0:x8}" : "{0}", data.Read32(FileAddress + index * 4));
                    case SettingType.Char:
                        return ((char)(data.Read8(FileAddress + index * 1))).ToString();
                }
            }
            set
            {
                if ((uint)index >= this.Length)
                    //throw new IndexOutOfRangeException();
                    return;

                AttemptWrite();

                switch (type)
                {
                    default:
                    case SettingType.Void:
                        throw new InvalidOperationException($"Setting {this.Title} is read only.");
                    case SettingType.Bool:
                        data.WriteBool(FileAddress + index / 8, (short)(Mask << (index & 0x7)), Convert.ToBoolean(value));
                        break;
                    case SettingType.Byte:
                        data.Write8(FileAddress + index * 1, value.ReadInt());
                        break;
                    case SettingType.Short:
                        data.Write16(FileAddress + index * 2, value.ReadInt());
                        break;
                    case SettingType.Pointer:
                        data.Write24(FileAddress + index * 3, value.ReadInt());
                        break;
                    case SettingType.Int:
                        data.Write32(FileAddress + index * 4, value.ReadInt());
                        break;
                    case SettingType.Char:
                        data.Write8(FileAddress + index * 1, Convert.ToByte(value[0]));
                        break;
                }

                Changed?.Invoke(this);
            }
        }

        public void SetAsDefaultValue() => DefaultValue = ToValueString();
        public bool IsDefaultValue() => DefaultValue == ToValueString();

        public void SetValue(string value)
        {
            if (value.IndexOf('{') >= 0)
                SetValues(value);
            else if (type == SettingType.Char)
            {
                AttemptWrite();

                if (Length >= 0)
                    data.WriteString(FileAddress, value, Length, '\0');
                else
                    data.WriteString(FileAddress, value, value.Length, '\0');
            }
            else
                this[0] = value;
        }

        public void SetValues(string values)
        {
            // Remove { } if present
            var start = values.IndexOf('{');
            var end = values.IndexOf('}');
            if ((start | end) >= 0)
                values = values.Substring(start + 1, end - start - 1);

            // Split elements
            var elements = values.Split(',');

            // Array size must match unless the array is marked as "unsafe"
            if (this.safe && elements.Length != this.Length)
                throw new Exception($"Array size mismatch for setting \"{this.Name}\".\n" +
                    $"{this.Length} elements expected.");

            // Store each element
            for (int i = 0; i < elements.Length; i++)
                this[i] = elements[i];
        }

        public string GetValue()
        {
            if (type == SettingType.Char)
            {
                if (Length >= 0)
                    return data.ReadString(FileAddress, Length);
                else
                    return data.ReadString0(FileAddress);
            }
            return this[0];
        }

        public string GetValues()
        {
            if (type == SettingType.Char)
            {
                return GetValue();
            }
            else
            {
                if (this.Length <= 0)
                    return string.Empty;

                StringBuilder sb = new StringBuilder();

                int length = this.Length;
                for (int i = 0; i < length; i++)
                {
                    sb.Append(this[i].ToString());
                    sb.Append(", ");
                }
                // Remove last comma
                sb.Length -= 2;

                return sb.ToString();
            }
        }

        public void AddEventAndTrigger(OnChange action)
        {
            Changed += action;
            action?.Invoke(this);
        }

        public override string ToString() => Name + " = " + ToValueString();
        public string ToValueString()
        {
            if (Length == 1)
                return GetValue();
            else if (type == SettingType.Char)
                return "\"" + GetValue() + "\"";
            else
            {
                return "{ " + GetValues() + " }";
            }
        }
    }
}
