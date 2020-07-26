using Project_Nested.Injection;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Project_Nested
{
    public partial class FrmPatches : Form
    {
        public Injector _injector;
        public Injector injector
        {
            get => _injector;
            set
            {
                _injector = value;

                StringBuilder sb = new StringBuilder();
                foreach (var item in injector.patches)
                    sb.AppendLine(item.Value.ToString());
                textBox1.Text = sb.ToString();
            }
        }

        public FrmPatches()
        {
            InitializeComponent();
        }

        private void FrmPatches_Load(object sender, EventArgs e)
        {
            this.MinimumSize = this.Size;
        }

        private void btnOk_Click(object sender, EventArgs e)
        {
            var lines = textBox1.Text.Split(new char[] { '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries);
            var lineNum = 0;
            List<Patch> patchList = new List<Patch>();

            try
            {
                // Read patches from the textbox
                for (lineNum = 0; lineNum < lines.Length; lineNum++)
                    patchList.Add(new Patch(lines[lineNum]));

                // Replace existing patches
                injector.patches.Clear();
                foreach (var patch in patchList)
                    injector.patches[patch.GetAddressString()] = patch;

                this.Close();
            }
            catch (Exception)
            {
                MessageBox.Show($"Error on line {lineNum + 1}");
            }
        }

        private void btnCancel_Click(object sender, EventArgs e)
        {
            this.Close();
        }
    }
}
