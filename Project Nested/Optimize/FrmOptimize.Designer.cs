namespace Project_Nested.Optimize
{
    partial class FrmOptimize
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            this.listOptimizations = new System.Windows.Forms.CheckedListBox();
            this.listSubRoutines = new System.Windows.Forms.CheckedListBox();
            this.txtAfter = new System.Windows.Forms.RichTextBox();
            this.txtBefore = new System.Windows.Forms.RichTextBox();
            this.timer1 = new System.Windows.Forms.Timer(this.components);
            this.dropdownLeft = new System.Windows.Forms.ComboBox();
            this.dropdownRight = new System.Windows.Forms.ComboBox();
            this.checkIgnoreError = new System.Windows.Forms.CheckBox();
            this.lblProcessTime = new System.Windows.Forms.Label();
            this.lblFind = new System.Windows.Forms.Label();
            this.textBox1 = new System.Windows.Forms.TextBox();
            this.btnBreak = new System.Windows.Forms.Button();
            this.btnFindFaultySubRoutine = new System.Windows.Forms.Button();
            this.SuspendLayout();
            // 
            // listOptimizations
            // 
            this.listOptimizations.BackColor = System.Drawing.Color.Black;
            this.listOptimizations.Enabled = false;
            this.listOptimizations.ForeColor = System.Drawing.Color.White;
            this.listOptimizations.FormattingEnabled = true;
            this.listOptimizations.Location = new System.Drawing.Point(12, -1);
            this.listOptimizations.Name = "listOptimizations";
            this.listOptimizations.Size = new System.Drawing.Size(120, 184);
            this.listOptimizations.TabIndex = 2;
            this.listOptimizations.Visible = false;
            this.listOptimizations.SelectedIndexChanged += new System.EventHandler(this.listOptimizations_SelectedIndexChanged);
            // 
            // listSubRoutines
            // 
            this.listSubRoutines.BackColor = System.Drawing.Color.Black;
            this.listSubRoutines.Font = new System.Drawing.Font("Courier New", 9.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.listSubRoutines.ForeColor = System.Drawing.Color.White;
            this.listSubRoutines.FormattingEnabled = true;
            this.listSubRoutines.Location = new System.Drawing.Point(12, 12);
            this.listSubRoutines.Name = "listSubRoutines";
            this.listSubRoutines.Size = new System.Drawing.Size(120, 327);
            this.listSubRoutines.TabIndex = 2;
            this.listSubRoutines.ItemCheck += new System.Windows.Forms.ItemCheckEventHandler(this.listSubRoutines_ItemCheck);
            this.listSubRoutines.SelectedIndexChanged += new System.EventHandler(this.listSubRoutines_SelectedIndexChanged);
            // 
            // txtAfter
            // 
            this.txtAfter.BackColor = System.Drawing.Color.Black;
            this.txtAfter.Font = new System.Drawing.Font("Courier New", 9.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.txtAfter.ForeColor = System.Drawing.Color.White;
            this.txtAfter.Location = new System.Drawing.Point(508, 39);
            this.txtAfter.Name = "txtAfter";
            this.txtAfter.Size = new System.Drawing.Size(364, 340);
            this.txtAfter.TabIndex = 1;
            this.txtAfter.Text = "";
            // 
            // txtBefore
            // 
            this.txtBefore.BackColor = System.Drawing.Color.Black;
            this.txtBefore.Font = new System.Drawing.Font("Courier New", 9.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.txtBefore.ForeColor = System.Drawing.Color.White;
            this.txtBefore.Location = new System.Drawing.Point(138, 39);
            this.txtBefore.Name = "txtBefore";
            this.txtBefore.Size = new System.Drawing.Size(364, 363);
            this.txtBefore.TabIndex = 1;
            this.txtBefore.Text = "";
            // 
            // timer1
            // 
            this.timer1.Enabled = true;
            this.timer1.Tick += new System.EventHandler(this.timer1_Tick);
            // 
            // dropdownLeft
            // 
            this.dropdownLeft.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.dropdownLeft.FormattingEnabled = true;
            this.dropdownLeft.Location = new System.Drawing.Point(138, 12);
            this.dropdownLeft.Name = "dropdownLeft";
            this.dropdownLeft.Size = new System.Drawing.Size(364, 21);
            this.dropdownLeft.TabIndex = 3;
            this.dropdownLeft.SelectedIndexChanged += new System.EventHandler(this.dropdownLeft_SelectedIndexChanged);
            // 
            // dropdownRight
            // 
            this.dropdownRight.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.dropdownRight.FormattingEnabled = true;
            this.dropdownRight.Location = new System.Drawing.Point(508, 12);
            this.dropdownRight.Name = "dropdownRight";
            this.dropdownRight.Size = new System.Drawing.Size(364, 21);
            this.dropdownRight.TabIndex = 3;
            this.dropdownRight.SelectedIndexChanged += new System.EventHandler(this.dropdownRight_SelectedIndexChanged);
            // 
            // checkIgnoreError
            // 
            this.checkIgnoreError.AutoSize = true;
            this.checkIgnoreError.Location = new System.Drawing.Point(792, 385);
            this.checkIgnoreError.Name = "checkIgnoreError";
            this.checkIgnoreError.Size = new System.Drawing.Size(80, 17);
            this.checkIgnoreError.TabIndex = 4;
            this.checkIgnoreError.Text = "Ignore error";
            this.checkIgnoreError.UseVisualStyleBackColor = true;
            // 
            // lblProcessTime
            // 
            this.lblProcessTime.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.lblProcessTime.AutoSize = true;
            this.lblProcessTime.Location = new System.Drawing.Point(12, 363);
            this.lblProcessTime.Name = "lblProcessTime";
            this.lblProcessTime.Size = new System.Drawing.Size(67, 13);
            this.lblProcessTime.TabIndex = 5;
            this.lblProcessTime.Text = "Process time";
            this.lblProcessTime.TextAlign = System.Drawing.ContentAlignment.TopRight;
            // 
            // lblFind
            // 
            this.lblFind.AutoSize = true;
            this.lblFind.Location = new System.Drawing.Point(12, 344);
            this.lblFind.Name = "lblFind";
            this.lblFind.Size = new System.Drawing.Size(27, 13);
            this.lblFind.TabIndex = 6;
            this.lblFind.Text = "Find";
            // 
            // textBox1
            // 
            this.textBox1.Location = new System.Drawing.Point(45, 340);
            this.textBox1.MaxLength = 6;
            this.textBox1.Name = "textBox1";
            this.textBox1.Size = new System.Drawing.Size(87, 20);
            this.textBox1.TabIndex = 7;
            this.textBox1.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.textBox1.TextChanged += new System.EventHandler(this.textBox1_TextChanged);
            // 
            // btnBreak
            // 
            this.btnBreak.Location = new System.Drawing.Point(508, 381);
            this.btnBreak.Name = "btnBreak";
            this.btnBreak.Size = new System.Drawing.Size(75, 23);
            this.btnBreak.TabIndex = 8;
            this.btnBreak.Text = "Break";
            this.btnBreak.UseVisualStyleBackColor = true;
            this.btnBreak.Click += new System.EventHandler(this.btnBreak_Click);
            // 
            // btnFindFaultySubRoutine
            // 
            this.btnFindFaultySubRoutine.Location = new System.Drawing.Point(12, 379);
            this.btnFindFaultySubRoutine.Name = "btnFindFaultySubRoutine";
            this.btnFindFaultySubRoutine.Size = new System.Drawing.Size(120, 23);
            this.btnFindFaultySubRoutine.TabIndex = 9;
            this.btnFindFaultySubRoutine.Text = "Find faulty sub-routine";
            this.btnFindFaultySubRoutine.UseVisualStyleBackColor = true;
            this.btnFindFaultySubRoutine.Click += new System.EventHandler(this.btnFindFaultySubRoutine_Click);
            // 
            // FrmOptimize
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(884, 411);
            this.Controls.Add(this.btnFindFaultySubRoutine);
            this.Controls.Add(this.btnBreak);
            this.Controls.Add(this.textBox1);
            this.Controls.Add(this.lblFind);
            this.Controls.Add(this.lblProcessTime);
            this.Controls.Add(this.checkIgnoreError);
            this.Controls.Add(this.dropdownRight);
            this.Controls.Add(this.dropdownLeft);
            this.Controls.Add(this.listSubRoutines);
            this.Controls.Add(this.listOptimizations);
            this.Controls.Add(this.txtAfter);
            this.Controls.Add(this.txtBefore);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.Name = "FrmOptimize";
            this.Text = "Debug AOT optimization";
            this.FormClosed += new System.Windows.Forms.FormClosedEventHandler(this.FrmOptimize_FormClosed);
            this.Load += new System.EventHandler(this.FrmOptimize_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion
        private System.Windows.Forms.CheckedListBox listOptimizations;
        private System.Windows.Forms.CheckedListBox listSubRoutines;
        private System.Windows.Forms.RichTextBox txtAfter;
        private System.Windows.Forms.RichTextBox txtBefore;
        private System.Windows.Forms.Timer timer1;
        private System.Windows.Forms.ComboBox dropdownLeft;
        private System.Windows.Forms.ComboBox dropdownRight;
        private System.Windows.Forms.CheckBox checkIgnoreError;
        private System.Windows.Forms.Label lblProcessTime;
        private System.Windows.Forms.Label lblFind;
        private System.Windows.Forms.TextBox textBox1;
        private System.Windows.Forms.Button btnBreak;
        private System.Windows.Forms.Button btnFindFaultySubRoutine;
    }
}