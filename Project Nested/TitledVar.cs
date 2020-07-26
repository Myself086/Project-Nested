using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Project_Nested
{
    struct TitledVar<T>
    {
        public string title { private set; get; }
        public T value { private set; get; }

        public TitledVar(string title, T value)
        {
            this.title = title;
            this.value = value;
        }

        public TitledVar(KeyValuePair<string, T> valuePair)
        {
            this.title = valuePair.Key;
            this.value = valuePair.Value;
        }

        public override string ToString()
        {
            return title;
        }
    }
}
