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
    public partial class FrmControllerInput : Form
    {
        List<ComboBox> comboInput;

        private Injector injector;

        string[] buttonNames = new string[]
        {
            "--", "A", "B", "Select", "Start", "↑", "↓", "←", "→", "1", "2", "3", "4"
        };

        internal FrmControllerInput(Injector injector)
        {
            this.injector = injector;
            InitializeComponent();
        }

        private void FrmControllerInput_Load(object sender, EventArgs e)
        {
            comboInput = new List<ComboBox>()
            {
                comboInput1, comboInput2, comboInput3, comboInput4,
                comboInput5, comboInput6, comboInput7, comboInput8,
                comboInput9, comboInput10, comboInput11, comboInput12,
            };

            for (int i = 0; i < comboInput.Count; i++)
            {
                var combo = comboInput[i];

                // Populate list for the combo box
                combo.Items.AddRange(buttonNames);

                // Change selected item
                var index = injector.GetSetting("Input.Map", i).ReadInt();
                combo.SelectedIndex = index < buttonNames.Length ? index : 0;

                // Bind event
                BindSelectedIndexEvent(combo, i);
            }
        }

        private void BindSelectedIndexEvent(ComboBox combo, int boxIndex)
        {
            combo.SelectedIndexChanged += (sender, e) =>
            {
                injector.SetSetting("Input.Map", boxIndex, combo.SelectedIndex.ToString());
            };
        }
    }
}
