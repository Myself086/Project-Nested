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
            this.comboGameProfile = new System.Windows.Forms.ComboBox();
            this.lblGameProfile = new System.Windows.Forms.Label();
            this.btnSaveProfile = new System.Windows.Forms.Button();
            this.lblInstructions = new System.Windows.Forms.Label();
            this.lblKnownCalls = new System.Windows.Forms.Label();
            this.btnPatreon = new System.Windows.Forms.Button();
            this.btnCompatibility = new System.Windows.Forms.Button();
            this.btnSaveAndPlay = new System.Windows.Forms.Button();
            this.menuStrip1 = new System.Windows.Forms.MenuStrip();
            this.fileToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.openNesToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.saveSnesToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.saveSnesPlayToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripMenuItem2 = new System.Windows.Forms.ToolStripSeparator();
            this.loadSRMToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripMenuItem3 = new System.Windows.Forms.ToolStripSeparator();
            this.reloadBothROMsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripMenuItem4 = new System.Windows.Forms.ToolStripSeparator();
            this.exitToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.profileToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.copySettingsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.copySettingsSingleLineToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.pasteSettingsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.helpToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.sendFeedbackToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripMenuItem1 = new System.Windows.Forms.ToolStripSeparator();
            this.aboutProjectNestedToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.groupBox1.SuspendLayout();
            this.menuStrip1.SuspendLayout();
            this.SuspendLayout();
            // 
            // btnOpen
            // 
            this.btnOpen.Location = new System.Drawing.Point(12, 114);
            this.btnOpen.Name = "btnOpen";
            this.btnOpen.Size = new System.Drawing.Size(75, 23);
            this.btnOpen.TabIndex = 0;
            this.btnOpen.Text = "Open Nes";
            this.btnOpen.UseVisualStyleBackColor = true;
            this.btnOpen.Click += new System.EventHandler(this.btnOpen_Click);
            // 
            // btnSave
            // 
            this.btnSave.Location = new System.Drawing.Point(12, 143);
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
            this.lblMapper.Location = new System.Drawing.Point(12, 198);
            this.lblMapper.Name = "lblMapper";
            this.lblMapper.Size = new System.Drawing.Size(74, 52);
            this.lblMapper.TabIndex = 3;
            this.lblMapper.Text = "Mapper: -1\r\nNot supported\r\n0 PRG banks\r\n0 CHR banks";
            // 
            // groupBox1
            // 
            this.groupBox1.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.groupBox1.Controls.Add(this.panel);
            this.groupBox1.Location = new System.Drawing.Point(93, 126);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(391, 301);
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
            this.panel.Size = new System.Drawing.Size(391, 282);
            this.panel.TabIndex = 10;
            // 
            // btnLoadSrm
            // 
            this.btnLoadSrm.Location = new System.Drawing.Point(12, 253);
            this.btnLoadSrm.Name = "btnLoadSrm";
            this.btnLoadSrm.Size = new System.Drawing.Size(75, 23);
            this.btnLoadSrm.TabIndex = 3;
            this.btnLoadSrm.Text = "Load SRM";
            this.btnLoadSrm.UseVisualStyleBackColor = true;
            this.btnLoadSrm.Click += new System.EventHandler(this.btnLoadSrm_Click);
            // 
            // comboGameProfile
            // 
            this.comboGameProfile.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.comboGameProfile.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.comboGameProfile.FormattingEnabled = true;
            this.comboGameProfile.Location = new System.Drawing.Point(177, 107);
            this.comboGameProfile.Name = "comboGameProfile";
            this.comboGameProfile.Size = new System.Drawing.Size(226, 21);
            this.comboGameProfile.TabIndex = 8;
            this.comboGameProfile.SelectedIndexChanged += new System.EventHandler(this.comboGameProfile_SelectedIndexChanged);
            // 
            // lblGameProfile
            // 
            this.lblGameProfile.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.lblGameProfile.AutoSize = true;
            this.lblGameProfile.Location = new System.Drawing.Point(102, 110);
            this.lblGameProfile.Name = "lblGameProfile";
            this.lblGameProfile.Size = new System.Drawing.Size(69, 13);
            this.lblGameProfile.TabIndex = 7;
            this.lblGameProfile.Text = "Game profile:";
            this.lblGameProfile.TextAlign = System.Drawing.ContentAlignment.TopRight;
            // 
            // btnSaveProfile
            // 
            this.btnSaveProfile.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnSaveProfile.Location = new System.Drawing.Point(409, 105);
            this.btnSaveProfile.Name = "btnSaveProfile";
            this.btnSaveProfile.Size = new System.Drawing.Size(75, 23);
            this.btnSaveProfile.TabIndex = 9;
            this.btnSaveProfile.Text = "Save profile";
            this.btnSaveProfile.UseVisualStyleBackColor = true;
            this.btnSaveProfile.Click += new System.EventHandler(this.btnSaveProfile_Click);
            // 
            // lblInstructions
            // 
            this.lblInstructions.AutoSize = true;
            this.lblInstructions.Location = new System.Drawing.Point(12, 24);
            this.lblInstructions.Name = "lblInstructions";
            this.lblInstructions.Size = new System.Drawing.Size(453, 78);
            this.lblInstructions.TabIndex = 9;
            this.lblInstructions.Text = resources.GetString("lblInstructions.Text");
            // 
            // lblKnownCalls
            // 
            this.lblKnownCalls.AutoSize = true;
            this.lblKnownCalls.Location = new System.Drawing.Point(9, 279);
            this.lblKnownCalls.Name = "lblKnownCalls";
            this.lblKnownCalls.Size = new System.Drawing.Size(72, 13);
            this.lblKnownCalls.TabIndex = 10;
            this.lblKnownCalls.Text = "0 known calls";
            // 
            // btnPatreon
            // 
            this.btnPatreon.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.btnPatreon.Location = new System.Drawing.Point(12, 404);
            this.btnPatreon.Name = "btnPatreon";
            this.btnPatreon.Size = new System.Drawing.Size(75, 23);
            this.btnPatreon.TabIndex = 6;
            this.btnPatreon.Text = "Patreon";
            this.btnPatreon.UseVisualStyleBackColor = true;
            this.btnPatreon.Click += new System.EventHandler(this.btnPatreon_Click);
            // 
            // btnCompatibility
            // 
            this.btnCompatibility.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.btnCompatibility.Location = new System.Drawing.Point(12, 375);
            this.btnCompatibility.Name = "btnCompatibility";
            this.btnCompatibility.Size = new System.Drawing.Size(75, 23);
            this.btnCompatibility.TabIndex = 5;
            this.btnCompatibility.Text = "Compatibility";
            this.btnCompatibility.UseVisualStyleBackColor = true;
            this.btnCompatibility.Click += new System.EventHandler(this.btnCompatibility_Click);
            // 
            // btnSaveAndPlay
            // 
            this.btnSaveAndPlay.Location = new System.Drawing.Point(12, 172);
            this.btnSaveAndPlay.Name = "btnSaveAndPlay";
            this.btnSaveAndPlay.Size = new System.Drawing.Size(75, 23);
            this.btnSaveAndPlay.TabIndex = 2;
            this.btnSaveAndPlay.Text = "Save && Play";
            this.btnSaveAndPlay.UseVisualStyleBackColor = true;
            this.btnSaveAndPlay.Click += new System.EventHandler(this.btnSaveAndPlay_Click);
            // 
            // menuStrip1
            // 
            this.menuStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.fileToolStripMenuItem,
            this.profileToolStripMenuItem,
            this.helpToolStripMenuItem});
            this.menuStrip1.Location = new System.Drawing.Point(0, 0);
            this.menuStrip1.Name = "menuStrip1";
            this.menuStrip1.Size = new System.Drawing.Size(496, 24);
            this.menuStrip1.TabIndex = 11;
            this.menuStrip1.Text = "menuStrip1";
            // 
            // fileToolStripMenuItem
            // 
            this.fileToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.openNesToolStripMenuItem,
            this.saveSnesToolStripMenuItem,
            this.saveSnesPlayToolStripMenuItem,
            this.toolStripMenuItem2,
            this.loadSRMToolStripMenuItem,
            this.toolStripMenuItem3,
            this.reloadBothROMsToolStripMenuItem,
            this.toolStripMenuItem4,
            this.exitToolStripMenuItem});
            this.fileToolStripMenuItem.Name = "fileToolStripMenuItem";
            this.fileToolStripMenuItem.Size = new System.Drawing.Size(37, 20);
            this.fileToolStripMenuItem.Text = "File";
            // 
            // openNesToolStripMenuItem
            // 
            this.openNesToolStripMenuItem.Name = "openNesToolStripMenuItem";
            this.openNesToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F1;
            this.openNesToolStripMenuItem.Size = new System.Drawing.Size(192, 22);
            this.openNesToolStripMenuItem.Text = "Open Nes";
            this.openNesToolStripMenuItem.Click += new System.EventHandler(this.openNesToolStripMenuItem_Click);
            // 
            // saveSnesToolStripMenuItem
            // 
            this.saveSnesToolStripMenuItem.Name = "saveSnesToolStripMenuItem";
            this.saveSnesToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F2;
            this.saveSnesToolStripMenuItem.Size = new System.Drawing.Size(192, 22);
            this.saveSnesToolStripMenuItem.Text = "Save Snes";
            this.saveSnesToolStripMenuItem.Click += new System.EventHandler(this.saveSnesToolStripMenuItem_Click);
            // 
            // saveSnesPlayToolStripMenuItem
            // 
            this.saveSnesPlayToolStripMenuItem.Name = "saveSnesPlayToolStripMenuItem";
            this.saveSnesPlayToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F3;
            this.saveSnesPlayToolStripMenuItem.Size = new System.Drawing.Size(192, 22);
            this.saveSnesPlayToolStripMenuItem.Text = "Save Snes & Play";
            this.saveSnesPlayToolStripMenuItem.Click += new System.EventHandler(this.saveSnesPlayToolStripMenuItem_Click);
            // 
            // toolStripMenuItem2
            // 
            this.toolStripMenuItem2.Name = "toolStripMenuItem2";
            this.toolStripMenuItem2.Size = new System.Drawing.Size(189, 6);
            // 
            // loadSRMToolStripMenuItem
            // 
            this.loadSRMToolStripMenuItem.Name = "loadSRMToolStripMenuItem";
            this.loadSRMToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F4;
            this.loadSRMToolStripMenuItem.Size = new System.Drawing.Size(192, 22);
            this.loadSRMToolStripMenuItem.Text = "Load Srm";
            this.loadSRMToolStripMenuItem.Click += new System.EventHandler(this.loadSRMToolStripMenuItem_Click);
            // 
            // toolStripMenuItem3
            // 
            this.toolStripMenuItem3.Name = "toolStripMenuItem3";
            this.toolStripMenuItem3.Size = new System.Drawing.Size(189, 6);
            // 
            // reloadBothROMsToolStripMenuItem
            // 
            this.reloadBothROMsToolStripMenuItem.Name = "reloadBothROMsToolStripMenuItem";
            this.reloadBothROMsToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F5;
            this.reloadBothROMsToolStripMenuItem.Size = new System.Drawing.Size(192, 22);
            this.reloadBothROMsToolStripMenuItem.Text = "Reload Both ROMs";
            this.reloadBothROMsToolStripMenuItem.Click += new System.EventHandler(this.reloadBothROMsToolStripMenuItem_Click);
            // 
            // toolStripMenuItem4
            // 
            this.toolStripMenuItem4.Name = "toolStripMenuItem4";
            this.toolStripMenuItem4.Size = new System.Drawing.Size(189, 6);
            // 
            // exitToolStripMenuItem
            // 
            this.exitToolStripMenuItem.Name = "exitToolStripMenuItem";
            this.exitToolStripMenuItem.Size = new System.Drawing.Size(192, 22);
            this.exitToolStripMenuItem.Text = "Exit";
            this.exitToolStripMenuItem.Click += new System.EventHandler(this.exitToolStripMenuItem_Click);
            // 
            // profileToolStripMenuItem
            // 
            this.profileToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.copySettingsToolStripMenuItem,
            this.copySettingsSingleLineToolStripMenuItem,
            this.pasteSettingsToolStripMenuItem});
            this.profileToolStripMenuItem.Name = "profileToolStripMenuItem";
            this.profileToolStripMenuItem.Size = new System.Drawing.Size(53, 20);
            this.profileToolStripMenuItem.Text = "Profile";
            // 
            // copySettingsToolStripMenuItem
            // 
            this.copySettingsToolStripMenuItem.Name = "copySettingsToolStripMenuItem";
            this.copySettingsToolStripMenuItem.ShortcutKeys = ((System.Windows.Forms.Keys)(((System.Windows.Forms.Keys.Control | System.Windows.Forms.Keys.Shift) 
            | System.Windows.Forms.Keys.C)));
            this.copySettingsToolStripMenuItem.Size = new System.Drawing.Size(252, 22);
            this.copySettingsToolStripMenuItem.Text = "Copy Settings";
            this.copySettingsToolStripMenuItem.Click += new System.EventHandler(this.copySettingsToolStripMenuItem_Click);
            // 
            // copySettingsSingleLineToolStripMenuItem
            // 
            this.copySettingsSingleLineToolStripMenuItem.Name = "copySettingsSingleLineToolStripMenuItem";
            this.copySettingsSingleLineToolStripMenuItem.ShortcutKeys = ((System.Windows.Forms.Keys)(((System.Windows.Forms.Keys.Control | System.Windows.Forms.Keys.Shift) 
            | System.Windows.Forms.Keys.X)));
            this.copySettingsSingleLineToolStripMenuItem.Size = new System.Drawing.Size(288, 22);
            this.copySettingsSingleLineToolStripMenuItem.Text = "Copy Settings - Single Line";
            this.copySettingsSingleLineToolStripMenuItem.Click += new System.EventHandler(this.copySettingsSingleLineToolStripMenuItem_Click);
            // 
            // pasteSettingsToolStripMenuItem
            // 
            this.pasteSettingsToolStripMenuItem.Name = "pasteSettingsToolStripMenuItem";
            this.pasteSettingsToolStripMenuItem.ShortcutKeys = ((System.Windows.Forms.Keys)(((System.Windows.Forms.Keys.Control | System.Windows.Forms.Keys.Shift) 
            | System.Windows.Forms.Keys.V)));
            this.pasteSettingsToolStripMenuItem.Size = new System.Drawing.Size(288, 22);
            this.pasteSettingsToolStripMenuItem.Text = "Paste Settings";
            this.pasteSettingsToolStripMenuItem.Click += new System.EventHandler(this.pasteSettingsToolStripMenuItem_Click);
            // 
            // helpToolStripMenuItem
            // 
            this.helpToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.sendFeedbackToolStripMenuItem,
            this.toolStripMenuItem1,
            this.aboutProjectNestedToolStripMenuItem});
            this.helpToolStripMenuItem.Name = "helpToolStripMenuItem";
            this.helpToolStripMenuItem.Size = new System.Drawing.Size(44, 20);
            this.helpToolStripMenuItem.Text = "Help";
            // 
            // sendFeedbackToolStripMenuItem
            // 
            this.sendFeedbackToolStripMenuItem.Name = "sendFeedbackToolStripMenuItem";
            this.sendFeedbackToolStripMenuItem.Size = new System.Drawing.Size(187, 22);
            this.sendFeedbackToolStripMenuItem.Text = "Send Feedback";
            this.sendFeedbackToolStripMenuItem.Click += new System.EventHandler(this.sendFeedbackToolStripMenuItem_Click);
            // 
            // toolStripMenuItem1
            // 
            this.toolStripMenuItem1.Name = "toolStripMenuItem1";
            this.toolStripMenuItem1.Size = new System.Drawing.Size(184, 6);
            // 
            // aboutProjectNestedToolStripMenuItem
            // 
            this.aboutProjectNestedToolStripMenuItem.Name = "aboutProjectNestedToolStripMenuItem";
            this.aboutProjectNestedToolStripMenuItem.Size = new System.Drawing.Size(187, 22);
            this.aboutProjectNestedToolStripMenuItem.Text = "About Project Nested";
            this.aboutProjectNestedToolStripMenuItem.Click += new System.EventHandler(this.aboutProjectNestedToolStripMenuItem_Click);
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(496, 439);
            this.Controls.Add(this.btnCompatibility);
            this.Controls.Add(this.btnPatreon);
            this.Controls.Add(this.lblKnownCalls);
            this.Controls.Add(this.btnSaveProfile);
            this.Controls.Add(this.lblGameProfile);
            this.Controls.Add(this.comboGameProfile);
            this.Controls.Add(this.btnLoadSrm);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.lblMapper);
            this.Controls.Add(this.btnSaveAndPlay);
            this.Controls.Add(this.btnSave);
            this.Controls.Add(this.btnOpen);
            this.Controls.Add(this.lblInstructions);
            this.Controls.Add(this.menuStrip1);
            this.KeyPreview = true;
            this.MainMenuStrip = this.menuStrip1;
            this.Name = "Form1";
            this.Text = "Project Nested";
            this.Load += new System.EventHandler(this.Form1_Load);
            this.groupBox1.ResumeLayout(false);
            this.menuStrip1.ResumeLayout(false);
            this.menuStrip1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button btnOpen;
        private System.Windows.Forms.Button btnSave;
        private System.Windows.Forms.Label lblMapper;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.Button btnLoadSrm;
        private System.Windows.Forms.ComboBox comboGameProfile;
        private System.Windows.Forms.Label lblGameProfile;
        private System.Windows.Forms.Button btnSaveProfile;
        private System.Windows.Forms.Label lblInstructions;
        private System.Windows.Forms.Panel panel;
        private System.Windows.Forms.Label lblKnownCalls;
        private System.Windows.Forms.Button btnPatreon;
        private System.Windows.Forms.Button btnCompatibility;
        private System.Windows.Forms.Button btnSaveAndPlay;
        private System.Windows.Forms.MenuStrip menuStrip1;
        private System.Windows.Forms.ToolStripMenuItem fileToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem openNesToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem saveSnesToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem saveSnesPlayToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem profileToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem copySettingsToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem copySettingsSingleLineToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem pasteSettingsToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem helpToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem sendFeedbackToolStripMenuItem;
        private System.Windows.Forms.ToolStripSeparator toolStripMenuItem1;
        private System.Windows.Forms.ToolStripMenuItem aboutProjectNestedToolStripMenuItem;
        private System.Windows.Forms.ToolStripSeparator toolStripMenuItem2;
        private System.Windows.Forms.ToolStripMenuItem loadSRMToolStripMenuItem;
        private System.Windows.Forms.ToolStripSeparator toolStripMenuItem3;
        private System.Windows.Forms.ToolStripMenuItem reloadBothROMsToolStripMenuItem;
        private System.Windows.Forms.ToolStripSeparator toolStripMenuItem4;
        private System.Windows.Forms.ToolStripMenuItem exitToolStripMenuItem;
    }
}

