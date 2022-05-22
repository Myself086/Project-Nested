using Project_Nested.Emulation;
using Project_Nested.Injection;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Project_Nested.Optimize
{
    public partial class FrmOptimize : Form
    {
        #region Variables

        private c65816 emu;

        private Injector _injector;
        internal Injector injector
        {
            get => _injector;
            set
            {
                this._injector = value;

                UpdateSubRoutineList(null);

                // Auto-select first sub-routine
                if (listSubRoutines.Items.Count > 0)
                    listSubRoutines.SelectedItem = 0;
            }
        }

        Task taskText;
        CancellationTokenSource ctText;

        string newTextBefore;
        string newTextAfter;
        string newProcessTime;

        OptimizeOperator completedOperator;
        OptimizeOperator completedOperatorOld;

        const string SELECT_ALL = "All";
        bool selectAll = true;

        #endregion
        // --------------------------------------------------------------------
        #region Constructor

        public FrmOptimize()
        {
            InitializeComponent();
        }

        private void FrmOptimize_Load(object sender, EventArgs e)
        {
            // Dummy optimizer
            OptimizeOperator op = new OptimizeOperator();
            listOptimizations.Items.AddRange(op.operationNames.ToArray());
            // Check every optimization operator
            for (int i = 0; i < listOptimizations.Items.Count; i++)
                listOptimizations.SetItemCheckState(i, CheckState.Checked);

#if !DEBUG
            // Remove debug buttons in release mode
            btnBreak.Visible = false;
            checkIgnoreError.Visible = false;
            txtAfter.Height = txtBefore.Height;
#endif

            if (false)
            {
                Clipboard.Clear();
                Clipboard.SetText(Asm65816Dictionary.GenerateEnum());
            }
        }

        #endregion
        // --------------------------------------------------------------------
        #region Destructor

        private void FrmOptimize_FormClosed(object sender, FormClosedEventArgs e)
        {
            // Cancel remaining tasks
            ctText?.Cancel();
        }

        #endregion
        // --------------------------------------------------------------------
        #region Debug

        private void btnBreak_Click(object sender, EventArgs e)
        {
            var item = ((string)listSubRoutines.SelectedItem).ReadNesAddress();

            // Update textboxes
            listSubRoutines_LastSelectedItem = item;
            UpdateTextboxes(item, true);
        }

        #endregion
        // --------------------------------------------------------------------
        #region List interaction

        private void listOptimizations_SelectedIndexChanged(object sender, EventArgs e)
        {
            // ?
        }

        int listSubRoutines_LastSelectedItem;
        private void listSubRoutines_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (!((string)listSubRoutines.SelectedItem == SELECT_ALL))
            {
                var item = ((string)listSubRoutines.SelectedItem).ReadNesAddress();

                // Update textboxes if necessary
                if (listSubRoutines_LastSelectedItem != item)
                {
                    listSubRoutines_LastSelectedItem = item;
                    UpdateTextboxes(item, false);
                }
            }
        }

        private void listSubRoutines_ItemCheck(object sender, ItemCheckEventArgs e)
        {
            if (listSubRoutines.Items[e.Index].ToString() == SELECT_ALL)
            {
                selectAll = !listSubRoutines.GetItemChecked(e.Index);
                for (int i = 1; i < listSubRoutines.Items.Count; i++)
                    listSubRoutines.SetItemChecked(i, selectAll);
            }
            else
            {
                var item = ((string)listSubRoutines.Items[e.Index]).ReadNesAddress();
                if (e.NewValue == CheckState.Checked)
                    injector.excludedCalls.Remove(item);
                else
                    injector.excludedCalls.Add(item);
            }
        }

        private void textBox1_TextChanged(object sender, EventArgs e)
        {
            UpdateSubRoutineList((sender as TextBox).Text);
        }

        private void UpdateSubRoutineList(string filter)
        {
            if (filter == string.Empty)
                filter = null;

            // Reset list
            listSubRoutines.Items.Clear();

            // Add "All" checkbox
            listSubRoutines.Items.Add(SELECT_ALL, selectAll);

            // Populate sub-routine list
            var calls = injector.GetAllKnownCalls();
            foreach (var item in calls)
            {
                var name = item.ToString("x6");
                if (filter == null || name.Contains(filter))
                    listSubRoutines.Items.Add(name, !injector.excludedCalls.Contains(item));
            }

            // Initialize emulator
            if (emu == null)
            {
                injector.MergeRoms();
                emu = injector.NewEmulator(null);
            }
        }

        #endregion
        // --------------------------------------------------------------------
        #region Update textboxes

        private void UpdateTextboxes(int nesAddr, bool breakOn)
        {
            // Cancel previous task
            ctText?.Cancel();

            // Remove current text
            lock (this)
            {
                txtBefore.Text = txtAfter.Text = "Please wait...";

                dropdownLeft.Items.Clear();
                dropdownRight.Items.Clear();
            }

            // Recompile code (same thread in debug mode)
#if DEBUG
            if (checkIgnoreError.Checked)
            {
                try
                {
                    GenerateText(null, nesAddr, breakOn, true);
                }
                catch (Exception ex)
                {
                    // Ignore
                }
            }
            else
                GenerateText(null, nesAddr, breakOn, false);
#else
            var ct = (ctText = new CancellationTokenSource());
            var task = Task.Run(() => GenerateText(ct.Token, nesAddr, breakOn, false), ct.Token);
#endif
        }

        private void GenerateText(CancellationToken? ct, int nesAddr, bool breakOn, bool ignoreError)
        {
            // Wait for tick update, happens 64 times per second
            var tick = Environment.TickCount;
            while (tick == Environment.TickCount) ;
            tick = Environment.TickCount;

            // Number of times we could process this sub-routine
            var processCount = 0;

            // Process this sub-routine until TickCount changes enough
            while (Environment.TickCount - tick < 35)
            {
                ct?.ThrowIfCancellationRequested();

                // Recompile code from 6502 to 65816, this is the recompiler used by the SNES
                Raw65816 code;
                lock (emu)
                    code = injector.RecompilerBuild(emu, nesAddr);

                ct?.ThrowIfCancellationRequested();

                // Convert code to IL
                var il = code.ConvertToIL(injector);

                // Disassemble 'before' code
                {
                    string text = AsmIL65816.DisassembleList(il);

                    lock (this)
                    {
                        ct?.ThrowIfCancellationRequested();
                        newTextBefore = text;
                    }
                }

                // Optimize code
                var op = new OptimizeOperator(null, code, injector);
                if (ignoreError)
                    lock (this)
                        completedOperator = op;
                if (breakOn)
                    lock (this)
                        op.SetBreakPoint(selectedBreakOn.Item1, selectedBreakOn.Item2);
                op.Optimize(ct, true);
                il = op.GetCode();

                // Disassemble 'after' code
                {
                    string text = AsmIL65816.DisassembleList(il);

                    lock (this)
                    {
                        ct?.ThrowIfCancellationRequested();
                        //newTextAfter = text;
                        completedOperator = op;
                    }
                }

                processCount++;
            }

            // Calculate process time
            lock (this)
            {
                ct?.ThrowIfCancellationRequested();
                var tickDiff = Environment.TickCount - tick;
                newProcessTime = $"Process time: {tickDiff / processCount / 1000f:0.000} sec.";
            }
        }

        private void timer1_Tick(object sender, EventArgs e)
        {
            string TakeSafeString(ref string str)
            {
                string rtn = null;
                lock (this)
                {
                    rtn = str;
                    str = null;
                }
                return rtn;
            }

            OptimizeOperator TakeSafeOperator()
            {
                lock (this)
                {
                    if (completedOperatorOld != completedOperator)
                    {
                        completedOperatorOld = completedOperator;
                        return completedOperator;
                    }
                    else
                        return null;
                }
            }

            var textBefore = TakeSafeString(ref newTextBefore);
            if (textBefore != null)
                txtBefore.SetRichText(textBefore);

            var textAfter = TakeSafeString(ref newTextAfter);
            if (textAfter != null)
                txtAfter.SetRichText(textAfter);

            var op = TakeSafeOperator();
            if (op != null)
            {
                dropdownLeft.Items.Clear();
                dropdownRight.Items.Clear();

                var list = new List<string>();
                if (op.record != null)
                {
                    for (int i = 0; i < op.record.Count; i++)
                    {
                        var obj = op.record[i];

                        list.Add($"{i} - {obj.Item1}");
                    }
                }

                dropdownLeft.Items.AddRange(list.ToArray());
                dropdownRight.Items.AddRange(list.ToArray());
                dropdownLeft.SelectedIndex = 0;
                dropdownRight.SelectedIndex = list.Count - 1;
            }
            if (newProcessTime != null)
            {
                lblProcessTime.Text = newProcessTime;
                newProcessTime = null;
            }
        }

        #endregion
        // --------------------------------------------------------------------
        #region Combo boxes

        private void dropdownLeft_SelectedIndexChanged(object sender, EventArgs e)
        {
            var combo = sender as ComboBox;
            string text = AsmIL65816.DisassembleList(completedOperator.record[combo.SelectedIndex].Item2);
            lock (this)
                newTextBefore = text;
        }

        Tuple<int, string> selectedBreakOn;
        private void dropdownRight_SelectedIndexChanged(object sender, EventArgs e)
        {
            var combo = sender as ComboBox;
            string text = AsmIL65816.DisassembleList(completedOperator.record[combo.SelectedIndex].Item2);
            lock (this)
            {
                newTextAfter = text;

                selectedBreakOn = new Tuple<int, string>(combo.SelectedIndex, completedOperator.record[combo.SelectedIndex].Item1);
            }
        }

        #endregion
        // --------------------------------------------------------------------
        #region Debug

        private void btnFindFaultySubRoutine_Click(object sender, EventArgs e)
        {
            var form = new FrmFindFaultySubRoutine();
            form.injector = this.injector;
            form.Show((Control)sender);
        }

        #endregion
    }
}
