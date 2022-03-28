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

namespace Project_Nested.Optimize
{
    public partial class FrmFindFaultySubRoutine : Form
    {
        #region Variables

        internal Injector injector;

        List<int> calls;

        List<int> excludedCalls = new List<int>();

        List<int> discarded = new List<int>();

        bool awaiting = false;

        struct Fraction<T>
        {
            public T numerator, denominator;
            public Fraction(T numerator, T denominator) => this = new Fraction<T>() { numerator = numerator, denominator = denominator };
        }
        Fraction<int> fraction = new Fraction<int>(0, 1);

        #endregion
        // --------------------------------------------------------------------
        #region Constructor

        public FrmFindFaultySubRoutine()
        {
            InitializeComponent();
        }

        private void FrmFindFaultySubRoutine_Load(object sender, EventArgs e)
        {
            calls = injector.GetAllKnownCalls().ToList();
            UpdateUI();
        }

        #endregion
        // --------------------------------------------------------------------
        #region User interaction

        private void btnCopyList_Click(object sender, EventArgs e)
        {
            StringBuilder sb = new StringBuilder();

            foreach (var item in calls)
                sb.AppendLine($"0x{item:x6}");

            Clipboard.Clear();
            Clipboard.SetText(sb.ToString());
        }

        private void btnNext_Click(object sender, EventArgs e)
        {
            // Update fraction
            UpdateExcludedCalls();

            // Save with currently excluded calls
            injector.excludedCalls.Clear();
            injector.excludedCalls.AddRange(excludedCalls);
            injector.saveAndPlay();

            awaiting = true;
            UpdateUI();
        }

        private void btnResultYes_Click(object sender, EventArgs e)
        {
            // Increment fraction
            if (fraction.denominator == 1)
                fraction.denominator = 2;

            // Discard non-excluded calls
            discarded.AddRange(calls.FindAll(item => !excludedCalls.Contains(item)));
            calls.RemoveAll(item => !excludedCalls.Contains(item));
            excludedCalls.Clear();

            awaiting = false;
            UpdateUI();
        }

        private void btnResultNo_Click(object sender, EventArgs e)
        {
            if (fraction.denominator == 1)
            {
                MessageBox.Show("Not an optimization issue.");
                this.Close();
            }
            else
                fraction.denominator = 2;

            // Reset numerator
            fraction.numerator = 0;

            // Discard excluded calls
            calls.RemoveAll(item => excludedCalls.Contains(item));
            discarded.AddRange(excludedCalls);
            excludedCalls.Clear();

            awaiting = false;
            UpdateUI();
        }

        #endregion
        // --------------------------------------------------------------------
        #region Change exclusion

        private void UpdateExcludedCalls()
        {
            excludedCalls.Clear();

            var start = (fraction.numerator + 0) * calls.Count / fraction.denominator;
            var end = (fraction.numerator + 1) * calls.Count / fraction.denominator;

            excludedCalls.AddRange(calls.GetRange(start, end - start));
        }

        #endregion
        // --------------------------------------------------------------------
        #region Update progress

        private void UpdateUI()
        {
            lblProgress.Text = $"Progress: {discarded.Count} / {calls.Count + discarded.Count}\n" +
                $"Testing {calls.Count - excludedCalls.Count}";
                //$"Test fraction: {fraction.numerator} / {fraction.denominator}";

            btnNext.Enabled = !awaiting;
            btnResultYes.Enabled = awaiting;
            btnResultNo.Enabled = awaiting;
        }

        #endregion
    }
}
