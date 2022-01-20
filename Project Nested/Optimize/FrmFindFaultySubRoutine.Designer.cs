namespace Project_Nested.Optimize
{
    partial class FrmFindFaultySubRoutine
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
            this.btnNext = new System.Windows.Forms.Button();
            this.lblProgress = new System.Windows.Forms.Label();
            this.btnResultYes = new System.Windows.Forms.Button();
            this.btnResultNo = new System.Windows.Forms.Button();
            this.btnCopyList = new System.Windows.Forms.Button();
            this.SuspendLayout();
            // 
            // btnNext
            // 
            this.btnNext.Location = new System.Drawing.Point(12, 97);
            this.btnNext.Name = "btnNext";
            this.btnNext.Size = new System.Drawing.Size(75, 23);
            this.btnNext.TabIndex = 0;
            this.btnNext.Text = "Next";
            this.btnNext.UseVisualStyleBackColor = true;
            this.btnNext.Click += new System.EventHandler(this.btnNext_Click);
            // 
            // lblProgress
            // 
            this.lblProgress.AutoSize = true;
            this.lblProgress.Location = new System.Drawing.Point(9, 9);
            this.lblProgress.Name = "lblProgress";
            this.lblProgress.Size = new System.Drawing.Size(48, 13);
            this.lblProgress.TabIndex = 1;
            this.lblProgress.Text = "Progress";
            // 
            // btnResultYes
            // 
            this.btnResultYes.Location = new System.Drawing.Point(147, 97);
            this.btnResultYes.Name = "btnResultYes";
            this.btnResultYes.Size = new System.Drawing.Size(75, 23);
            this.btnResultYes.TabIndex = 2;
            this.btnResultYes.Text = "Working";
            this.btnResultYes.UseVisualStyleBackColor = true;
            this.btnResultYes.Click += new System.EventHandler(this.btnResultYes_Click);
            // 
            // btnResultNo
            // 
            this.btnResultNo.Location = new System.Drawing.Point(147, 126);
            this.btnResultNo.Name = "btnResultNo";
            this.btnResultNo.Size = new System.Drawing.Size(75, 23);
            this.btnResultNo.TabIndex = 3;
            this.btnResultNo.Text = "Broken";
            this.btnResultNo.UseVisualStyleBackColor = true;
            this.btnResultNo.Click += new System.EventHandler(this.btnResultNo_Click);
            // 
            // btnCopyList
            // 
            this.btnCopyList.Location = new System.Drawing.Point(12, 126);
            this.btnCopyList.Name = "btnCopyList";
            this.btnCopyList.Size = new System.Drawing.Size(75, 23);
            this.btnCopyList.TabIndex = 4;
            this.btnCopyList.Text = "Copy list";
            this.btnCopyList.UseVisualStyleBackColor = true;
            this.btnCopyList.Click += new System.EventHandler(this.btnCopyList_Click);
            // 
            // FrmFindFaultySubRoutine
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(234, 161);
            this.Controls.Add(this.btnCopyList);
            this.Controls.Add(this.btnResultNo);
            this.Controls.Add(this.btnResultYes);
            this.Controls.Add(this.lblProgress);
            this.Controls.Add(this.btnNext);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "FrmFindFaultySubRoutine";
            this.Text = "Find faulty sub-routine";
            this.Load += new System.EventHandler(this.FrmFindFaultySubRoutine_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button btnNext;
        private System.Windows.Forms.Label lblProgress;
        private System.Windows.Forms.Button btnResultYes;
        private System.Windows.Forms.Button btnResultNo;
        private System.Windows.Forms.Button btnCopyList;
    }
}