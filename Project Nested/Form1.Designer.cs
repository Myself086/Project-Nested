namespace Project_Nested
{
    partial class Form1
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Form1));
            this.btnOpen = new System.Windows.Forms.Button();
            this.btnSave = new System.Windows.Forms.Button();
            this.lblMapper = new System.Windows.Forms.Label();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.panel = new System.Windows.Forms.Panel();
            this.btnLoadSrm = new System.Windows.Forms.Button();
            this.btnSettingsText = new System.Windows.Forms.Button();
            this.comboGameProfile = new System.Windows.Forms.ComboBox();
            this.lblGameProfile = new System.Windows.Forms.Label();
            this.btnSaveProfile = new System.Windows.Forms.Button();
            this.lblInstructions = new System.Windows.Forms.Label();
            this.lblKnownCalls = new System.Windows.Forms.Label();
            this.btnCredits = new System.Windows.Forms.Button();
            this.btnPatreon = new System.Windows.Forms.Button();
            this.btnCompatibility = new System.Windows.Forms.Button();
            this.groupBox1.SuspendLayout();
            this.SuspendLayout();
            // 
            // btnOpen
            // 
            this.btnOpen.Location = new System.Drawing.Point(12, 111);
            this.btnOpen.Name = "btnOpen";
            this.btnOpen.Size = new System.Drawing.Size(75, 23);
            this.btnOpen.TabIndex = 0;
            this.btnOpen.Text = "Open Nes";
            this.btnOpen.UseVisualStyleBackColor = true;
            this.btnOpen.Click += new System.EventHandler(this.btnOpen_Click);
            // 
            // btnSave
            // 
            this.btnSave.Location = new System.Drawing.Point(12, 140);
            this.btnSave.Name = "btnSave";
            this.btnSave.Size = new System.Drawing.Size(75, 23);
            this.btnSave.TabIndex = 1;
            this.btnSave.Text = "Save Snes";
            this.btnSave.UseVisualStyleBackColor = true;
            this.btnSave.Click += new System.EventHandler(this.btnSave_Click);
            // 
            // lblMapper
            // 
            this.lblMapper.AutoSize = true;
            this.lblMapper.Location = new System.Drawing.Point(9, 168);
            this.lblMapper.Name = "lblMapper";
            this.lblMapper.Size = new System.Drawing.Size(74, 65);
            this.lblMapper.TabIndex = 3;
            this.lblMapper.Text = "Mapper: -1\r\nNot supported\r\n\r\n0 PRG banks\r\n0 CHR banks";
            // 
            // groupBox1
            // 
            this.groupBox1.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.groupBox1.Controls.Add(this.panel);
            this.groupBox1.Location = new System.Drawing.Point(93, 111);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(391, 316);
            this.groupBox1.TabIndex = 4;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Advanced settings";
            // 
            // panel
            // 
            this.panel.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.panel.AutoScroll = true;
            this.panel.Location = new System.Drawing.Point(0, 19);
            this.panel.Name = "panel";
            this.panel.Size = new System.Drawing.Size(391, 297);
            this.panel.TabIndex = 0;
            // 
            // btnLoadSrm
            // 
            this.btnLoadSrm.Location = new System.Drawing.Point(12, 245);
            this.btnLoadSrm.Name = "btnLoadSrm";
            this.btnLoadSrm.Size = new System.Drawing.Size(75, 23);
            this.btnLoadSrm.TabIndex = 2;
            this.btnLoadSrm.Text = "Load SRM";
            this.btnLoadSrm.UseVisualStyleBackColor = true;
            this.btnLoadSrm.Click += new System.EventHandler(this.btnLoadSrm_Click);
            // 
            // btnSettingsText
            // 
            this.btnSettingsText.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.btnSettingsText.Location = new System.Drawing.Point(12, 317);
            this.btnSettingsText.Name = "btnSettingsText";
            this.btnSettingsText.Size = new System.Drawing.Size(75, 23);
            this.btnSettingsText.TabIndex = 3;
            this.btnSettingsText.Text = "Settings text";
            this.btnSettingsText.UseVisualStyleBackColor = true;
            this.btnSettingsText.Click += new System.EventHandler(this.btnSettingsText_Click);
            // 
            // comboGameProfile
            // 
            this.comboGameProfile.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.comboGameProfile.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.comboGameProfile.FormattingEnabled = true;
            this.comboGameProfile.Location = new System.Drawing.Point(279, 92);
            this.comboGameProfile.Name = "comboGameProfile";
            this.comboGameProfile.Size = new System.Drawing.Size(121, 21);
            this.comboGameProfile.TabIndex = 6;
            this.comboGameProfile.SelectedIndexChanged += new System.EventHandler(this.comboGameProfile_SelectedIndexChanged);
            // 
            // lblGameProfile
            // 
            this.lblGameProfile.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.lblGameProfile.AutoSize = true;
            this.lblGameProfile.Location = new System.Drawing.Point(204, 95);
            this.lblGameProfile.Name = "lblGameProfile";
            this.lblGameProfile.Size = new System.Drawing.Size(69, 13);
            this.lblGameProfile.TabIndex = 7;
            this.lblGameProfile.Text = "Game profile:";
            this.lblGameProfile.TextAlign = System.Drawing.ContentAlignment.TopRight;
            // 
            // btnSaveProfile
            // 
            this.btnSaveProfile.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnSaveProfile.Location = new System.Drawing.Point(406, 90);
            this.btnSaveProfile.Name = "btnSaveProfile";
            this.btnSaveProfile.Size = new System.Drawing.Size(75, 23);
            this.btnSaveProfile.TabIndex = 8;
            this.btnSaveProfile.Text = "Save profile";
            this.btnSaveProfile.UseVisualStyleBackColor = true;
            this.btnSaveProfile.Click += new System.EventHandler(this.btnSaveProfile_Click);
            // 
            // lblInstructions
            // 
            this.lblInstructions.AutoSize = true;
            this.lblInstructions.Location = new System.Drawing.Point(12, 9);
            this.lblInstructions.Name = "lblInstructions";
            this.lblInstructions.Size = new System.Drawing.Size(453, 78);
            this.lblInstructions.TabIndex = 9;
            this.lblInstructions.Text = resources.GetString("lblInstructions.Text");
            // 
            // lblKnownCalls
            // 
            this.lblKnownCalls.AutoSize = true;
            this.lblKnownCalls.Location = new System.Drawing.Point(9, 271);
            this.lblKnownCalls.Name = "lblKnownCalls";
            this.lblKnownCalls.Size = new System.Drawing.Size(72, 13);
            this.lblKnownCalls.TabIndex = 10;
            this.lblKnownCalls.Text = "0 known calls";
            // 
            // btnCredits
            // 
            this.btnCredits.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.btnCredits.Location = new System.Drawing.Point(12, 404);
            this.btnCredits.Name = "btnCredits";
            this.btnCredits.Size = new System.Drawing.Size(75, 23);
            this.btnCredits.TabIndex = 6;
            this.btnCredits.Text = "Credits";
            this.btnCredits.UseVisualStyleBackColor = true;
            this.btnCredits.Click += new System.EventHandler(this.btnCredits_Click);
            // 
            // btnPatreon
            // 
            this.btnPatreon.Location = new System.Drawing.Point(12, 375);
            this.btnPatreon.Name = "btnPatreon";
            this.btnPatreon.Size = new System.Drawing.Size(75, 23);
            this.btnPatreon.TabIndex = 5;
            this.btnPatreon.Text = "Patreon";
            this.btnPatreon.UseVisualStyleBackColor = true;
            this.btnPatreon.Click += new System.EventHandler(this.btnPatreon_Click);
            // 
            // btnCompatibility
            // 
            this.btnCompatibility.Location = new System.Drawing.Point(12, 346);
            this.btnCompatibility.Name = "btnCompatibility";
            this.btnCompatibility.Size = new System.Drawing.Size(75, 23);
            this.btnCompatibility.TabIndex = 4;
            this.btnCompatibility.Text = "Compatibility";
            this.btnCompatibility.UseVisualStyleBackColor = true;
            this.btnCompatibility.Click += new System.EventHandler(this.btnCompatibility_Click);
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(496, 439);
            this.Controls.Add(this.btnCompatibility);
            this.Controls.Add(this.btnPatreon);
            this.Controls.Add(this.btnCredits);
            this.Controls.Add(this.lblKnownCalls);
            this.Controls.Add(this.btnSaveProfile);
            this.Controls.Add(this.lblGameProfile);
            this.Controls.Add(this.comboGameProfile);
            this.Controls.Add(this.btnSettingsText);
            this.Controls.Add(this.btnLoadSrm);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.lblMapper);
            this.Controls.Add(this.btnSave);
            this.Controls.Add(this.btnOpen);
            this.Controls.Add(this.lblInstructions);
            this.Name = "Form1";
            this.Text = "Project Nested";
            this.Load += new System.EventHandler(this.Form1_Load);
            this.groupBox1.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button btnOpen;
        private System.Windows.Forms.Button btnSave;
        private System.Windows.Forms.Label lblMapper;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.Button btnLoadSrm;
        private System.Windows.Forms.Button btnSettingsText;
        private System.Windows.Forms.ComboBox comboGameProfile;
        private System.Windows.Forms.Label lblGameProfile;
        private System.Windows.Forms.Button btnSaveProfile;
        private System.Windows.Forms.Label lblInstructions;
        private System.Windows.Forms.Panel panel;
        private System.Windows.Forms.Label lblKnownCalls;
        private System.Windows.Forms.Button btnCredits;
        private System.Windows.Forms.Button btnPatreon;
        private System.Windows.Forms.Button btnCompatibility;
    }
}

