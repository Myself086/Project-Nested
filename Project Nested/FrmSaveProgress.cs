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

namespace Project_Nested
{
    public partial class FrmSaveProgress : Form, IProgress<Tuple<string, int, int>>
    {
        string progressName;
        int progressMin;
        int progressMax;

        bool progressChanged;
        bool done;

        CancellationTokenSource cancellationToken;

        // --------------------------------------------------------------------

        public FrmSaveProgress(CancellationTokenSource cancellationToken)
        {
            this.cancellationToken = cancellationToken;
            InitializeComponent();
        }

        // --------------------------------------------------------------------

        public void Report(Tuple<string, int, int> value)
        {
            if (value.Item1 == null)
                done = true;
            else
            {
                lock (this)
                {
                    progressName = value.Item1;
                    progressMin = value.Item2;
                    progressMax = value.Item3;

                    progressChanged = true;
                }
            }
        }

        private void timer1_Tick(object sender, EventArgs e)
        {
            if (done)
                this.Close();

            if (progressChanged)
            {
                lock (this)
                {
                    if (progressMax > 0)
                    {
                        label1.Text = $"{progressName}: {progressMin}/{progressMax}";
                        progressBar1.Maximum = progressMax;
                        progressBar1.Value = progressMin;
                    }
                    else
                    {
                        label1.Text = $"{progressName}";
                        progressBar1.Maximum = 1;
                        progressBar1.Value = 0;
                    }

                    progressChanged = false;
                }
            }
        }

        private void FrmSaveProgress_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (!done)
                cancellationToken.Cancel();
        }
    }
}
