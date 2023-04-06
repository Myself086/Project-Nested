using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using Project_Nested.Injection;

namespace Project_Nested
{
    public partial class Form1 : Form
    {
        #region Variables

        Injector injector;

        SettingsGUI gui;

        string formTitle;

        string filename;

        string globalSettingsFilename = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) + Path.DirectorySeparatorChar + "GlobalSettings.config";
        string profilePath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) + Path.DirectorySeparatorChar + "Profiles" + Path.DirectorySeparatorChar;

        string profileLoaded;
        ProfileListing profileSelected { get => (ProfileListing)comboGameProfile.SelectedItem; }

        const string NEW_PROFILE = "<New>";
        const string NEW_PROFILE_TEXT = "< New profile >";
        const string NO_PROFILE = "<None>";
        const string NO_PROFILE_TEXT = "< No profile >";

        private class ProfileListing
        {
            public string Title { get; private set; }
            public string FilePath { get; private set; }

            public const int LENGTH_LIMIT = 128;

            public bool IsValid
            {
                get
                {
                    {
                        switch (FilePath)
                        {
                            case null:
                            case NO_PROFILE:
                            case NEW_PROFILE:
                                return false;
                            default: return true;
                        }
                    }
                }
            }

            public ProfileListing(string title, string filePath)
            {
                this.Title = title;
                this.FilePath = filePath;
            }

            public override string ToString()
            {
                return Title;
            }
        }

        #endregion
        // --------------------------------------------------------------------
        #region Constructor and load

        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            // Keep form name with version number
            var version = Assembly.GetEntryAssembly().GetName().Version;
            this.Text += $" v{version.ToString(version.Build > 0 ? 3 : 2)}";
            formTitle = this.Text;

            // Non resizable
            //this.FormBorderStyle = FormBorderStyle.FixedSingle;
            //this.MaximizeBox = false;

            // Set minimum as initial size
            this.MinimumSize = this.Size;

            // Load profile list
            InitProfileList();

            // Disable some GUI objects
            EnableGUI(false);

            // Remove some placeholder texts
            lblMapper.Text = "No file loaded.";
        }

        #endregion
        // --------------------------------------------------------------------
        #region Enable GUI

        private void EnableGUI(bool enable)
        {
            comboGameProfile.Enabled = enable;
            btnSaveProfile.Enabled = enable;
        }

        #endregion
        // --------------------------------------------------------------------
        #region GUI events

        private void btnOpen_Click(object sender, EventArgs e)
        {
            OpenFileDialog fileDialog = new OpenFileDialog();
            fileDialog.Filter = "NES ROM File (*.nes)|*.nes";
            fileDialog.Title = "Select a ROM File";
            fileDialog.InitialDirectory = Properties.Settings.Default.NesPath;

            if (fileDialog.ShowDialog() == DialogResult.OK)
            {
#if !DEBUG
                //try
#endif
                {
                    // Save path
                    Properties.Settings.Default.NesPath = fileDialog.FileName.Substring(0, fileDialog.FileName.LastIndexOf('\\'));
                    Properties.Settings.Default.Save();

                    SaveGlobalSettings();

                    LoadNesFile(fileDialog.FileName);
                }
#if !DEBUG
                /*catch (Exception ex)
                {
                    MessageBox.Show(ex, "Error!");
                }*/
#endif
            }
        }

        private void LoadNesFile(string filename)
        {
            injector = new Injector(File.ReadAllBytes(filename));
            if (injector.IsLoaded(true))
            {
                injector.KnownCallCountChanged += Injector_KnownCallCountChanged;
                Injector_KnownCallCountChanged();

                injector.save = () => btnSave_Click(null, null);
                injector.saveAndPlay = () => btnSaveAndPlay_Click(null, null);

                this.filename = filename;

                SelectProfile(ConvertPathToTitle(filename), true);
                LoadGlobalSettings();

                ShowRomInfo();

                EnableGUI(true);

                // Add file name to form name
                this.Text = $"{formTitle} - {ConvertPathToTitle(filename)}";

                CreateSettingsGUI();

                // Reset scroll position
                //vScrollBar1.Value = 0;
            }
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
#if SYNC_SAVE
            SaveSnesSync();
#else
            SaveSnesAsync();
#endif
        }

#if SYNC_SAVE
        private void btnSaveAndPlay_Click(object sender, EventArgs e)
        {
            var filename = SaveSnesSync();
#else
        private async void btnSaveAndPlay_Click(object sender, EventArgs e)
        {
            var filename = await SaveSnesAsync();
#endif

            if (filename != null)
                Process.Start(filename);
        }

        public async Task<string> SaveSnesAsync()
        {
            CancellationTokenSource ct = new CancellationTokenSource();

            var progress = new FrmSaveProgress(ct);

            var rtn = Task.Run(async () =>
            {
                if (injector == null)
                    return null;

                if (!injector.mapperSupported)
                {
                    MessageBox.Show($"Mapper {injector.ReadMapper()} isn't supported.");
                    return null;
                }

                try
                {
                    var fullFileName = filename + ".smc";

                    injector.GameName.SetValue(profileLoaded != null ? profileLoaded : string.Empty);
                    var data = Task.Run(() =>
                    {
                        var data2 = injector.FinalChanges(ct.Token, progress);
                        return data2;
                    }, ct.Token);
                    await data;
                    File.WriteAllBytes(fullFileName, data.Result);

                    SaveGlobalSettings();

                    return fullFileName;
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Error!");
                }
                return null;
            }, ct.Token);

            progress.ShowDialog();

            await rtn;

            return rtn.Result;
        }

#if SYNC_SAVE
        public string SaveSnesSync()
        {
            if (injector == null)
                return null;

            if (!injector.mapperSupported)
            {
                MessageBox.Show($"Mapper {injector.ReadMapper()} isn't supported.");
                return null;
            }

            //try
            {
                var fullFileName = filename + ".smc";

                injector.GameName.SetValue(profileLoaded != null ? profileLoaded : string.Empty);
                var data = injector.FinalChanges(null, null);
                File.WriteAllBytes(fullFileName, data);

                SaveGlobalSettings();

                MessageBox.Show("Saving done!");

                return fullFileName;
            }
            /*catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Error!");
            }*/
            return null;
        }
#endif

        #endregion
        // --------------------------------------------------------------------
        #region Menu strip / File

        private void openNesToolStripMenuItem_Click(object sender, EventArgs e)
        {
            btnOpen_Click(sender, e);
        }

        private void saveSnesToolStripMenuItem_Click(object sender, EventArgs e)
        {
            btnSave_Click(sender, e);
        }

        private void saveSnesPlayToolStripMenuItem_Click(object sender, EventArgs e)
        {
            btnSaveAndPlay_Click(sender, e);
        }

        private void loadSRMToolStripMenuItem_Click(object sender, EventArgs e)
        {
            btnLoadSrm_Click(sender, e);
        }

        private void reloadBothROMsToolStripMenuItem_Click(object sender, EventArgs e)
        {
            // Reload NES and SNES files
            LoadNesFile(this.filename);

            // Reset lookup tables for optimization
            Optimize.Asm65816Dictionary.Reset();
        }

        private void exitToolStripMenuItem_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        #endregion
        // --------------------------------------------------------------------
        #region Menu strip / Profile

        const string MESSAGE_NO_GAME_LOADED = "No game loaded.";

        private void copySettingsToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (injector != null)
            {
                Clipboard.Clear();
                Clipboard.SetText(injector.GetAllSettings(true, false));
            }
            else
                MessageBox.Show(MESSAGE_NO_GAME_LOADED);
        }

        private void copySettingsSingleLineToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (injector != null)
            {
                Clipboard.Clear();
                Clipboard.SetText(injector.GetAllSettings(true, true));
            }
            else
                MessageBox.Show(MESSAGE_NO_GAME_LOADED);
        }

        private void pasteSettingsToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (injector != null)
            {
                if (Clipboard.ContainsText())
                {
                    void Crc32MismatchCallback(object sender2, Crc32EventArgs e2)
                    {
                        MessageBox.Show(
                            "CRC32 mismatch.\n\n" +
                            "Settings will be loaded but game may have issues or not work.\n\n" +
                            $"Game CRC32: {(sender2 as Injector).GetRomCrc32():x8}\n" +
                            $"Pasting settings for CRC32: {e2.Crc32:x8}\n",
                            "Warning");
                    }

                    injector.Crc32Mismatched += Crc32MismatchCallback;
                    try
                    {
                        bool keepCalls = injector.KnownCallCount > 0
                            && MessageBox.Show("Merge known calls?", "Pasting profile", MessageBoxButtons.YesNo) == DialogResult.Yes;

                        injector.ResetSettings(keepCalls);
                        injector.SetAllSettings(Clipboard.GetText());
                    }
                    catch (Exception ex)
                    {
                        injector.Crc32Mismatched -= Crc32MismatchCallback;
                        throw ex;
                    }
                    injector.Crc32Mismatched -= Crc32MismatchCallback;
                }
            }
            else
                MessageBox.Show(MESSAGE_NO_GAME_LOADED);
        }

        #endregion
        // --------------------------------------------------------------------
        #region Menu strip / Help

        private void sendFeedbackToolStripMenuItem_Click(object sender, EventArgs e)
        {
            Process.Start("https://github.com/Myself086/Project-Nested/issues?page=1&q=is%3Aissue+is%3Aopen");
        }

        private void aboutProjectNestedToolStripMenuItem_Click(object sender, EventArgs e)
        {
            MessageBox.Show(
                "Designed and made by Myself086\n" +
                "Audio by Memblers\n" +
                "\n" +
                "Thanks to the nesdev.com community.\n"
                );
        }

        #endregion
        // --------------------------------------------------------------------
        #region Profile

        private void InitProfileList()
        {
            comboGameProfile.Items.Clear();

            Directory.CreateDirectory(profilePath);
            var files = Directory.GetFiles(profilePath);

            // Create listing for showing that no profile is loaded
            var noProfile = new ProfileListing(NO_PROFILE_TEXT, NO_PROFILE);
            comboGameProfile.Items.Add(noProfile);
            comboGameProfile.SelectedIndex = comboGameProfile.Items.Count - 1;
            //comboGameProfile.Text = noProfile.ToString();

            // Create listing for adding a new profile
            var newProfile = new ProfileListing(NEW_PROFILE_TEXT, NEW_PROFILE);
            comboGameProfile.Items.Add(newProfile);

            // Add existing profiles
            foreach (var item in files)
            {
                if (item.ToLowerInvariant().EndsWith(".txt"))
                {
                    var title = ConvertPathToTitle(item);

                    if (title.Length <= ProfileListing.LENGTH_LIMIT)
                    {
                        var profile = new ProfileListing(title, item);
                        comboGameProfile.Items.Add(profile);
                    }
                }
            }
        }

        private string ConvertPathToTitle(string path)
        {
            int lastSlash = path.LastIndexOf(Path.DirectorySeparatorChar);
            int lastDot = path.LastIndexOf('.');

            if ((lastSlash | lastDot) >= 0)
            {
                return path.Substring(lastSlash + 1, lastDot - lastSlash - 1);
            }
            else
                return null;
        }

        /// <summary>
        /// Select best profile or exact profile.
        /// </summary>
        /// <param name="title"></param>
        /// <param name="autoComplete"></param>
        /// <returns>True if a valid profile was selected.</returns>
        private bool SelectProfile(string title, bool autoComplete)
        {
            // Unload selected profile
            comboGameProfile.SelectedIndex = comboGameProfile.FindStringExact(NO_PROFILE_TEXT);

            if (!autoComplete)
            {
                // Find exact match
                var index = comboGameProfile.FindStringExact(title);
                if (index < 0)
                {
                    // Profile not found, default to < No profile >
                    comboGameProfile.SelectedIndex = comboGameProfile.FindStringExact(NO_PROFILE_TEXT);
                    profileLoaded = NO_PROFILE;
                    return false;
                }
                else
                {
                    comboGameProfile.SelectedIndex = index;
                    profileLoaded = comboGameProfile.Text;
                    return false;
                }
            }
            else
            {
                // Find best matching profile name
                title = title.ToLowerInvariant();
                int bestCharCount = 0;
                int bestProfileIndex = 0;
                string bestProfileName = string.Empty;
                for (int i = 0; i < comboGameProfile.Items.Count; i++)
                {
                    if (comboGameProfile.Items[i] is ProfileListing)
                    {
                        // Read item from list
                        var item = (ProfileListing)comboGameProfile.Items[i];

                        // Is this profile a better match for our game title?
                        if (title.StartsWith(item.Title.ToLowerInvariant()) && bestCharCount < item.Title.Length)
                        {
                            bestCharCount = item.Title.Length;
                            bestProfileIndex = i;
                        }
                    }
                }

                if (bestCharCount > 0)
                {
                    // Select the profile that we found
                    comboGameProfile.SelectedIndex = bestProfileIndex;
                    profileLoaded = comboGameProfile.Text;
                    return true;
                }
                else
                {
                    // Profile not found, default to < No profile >
                    comboGameProfile.SelectedIndex = comboGameProfile.FindStringExact(NO_PROFILE_TEXT);
                    profileLoaded = NO_PROFILE;
                    return false;
                }
            }
        }

        private void UnloadProfile()
        {
            injector.ResetSettings();

            profileLoaded = NO_PROFILE;
        }

        private void LoadProfile(string title)
        {
            // Load all lines and apply changes
            var lines = File.ReadAllText(profilePath + title + ".txt");
            injector.ResetSettings();
            injector.SetAllSettings(lines);

            profileLoaded = title;
        }

        private void SaveProfile(string title, bool safety)
        {
            if (safety && profileSelected.IsValid && title != profileLoaded)
            {
                MessageBox.Show(
                    "Loaded profile doesn't match selected profile.\n\n" +
                    "Please contact the developer if you see this message.");
            }
            else if (injector != null)
            {
                var data = injector.GetAllSettings(false, false);
                File.WriteAllText(profilePath + title + ".txt", data);

                SaveGlobalSettings();
            }
        }

        private void LoadGlobalSettings()
        {
            if (injector != null)
            {
                if (File.Exists(globalSettingsFilename))
                    injector.SetAllSettings(File.ReadAllLines(globalSettingsFilename));
            }
        }

        private void SaveGlobalSettings()
        {
            if (injector != null)
            {
                var data = injector.GetAllGlobalSettings();
                File.WriteAllText(globalSettingsFilename, data);
            }
        }

        private void comboGameProfile_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (injector != null)
            {
                // Change loaded profile
                var selected = (ProfileListing)comboGameProfile.SelectedItem;

                if (selected.FilePath == NEW_PROFILE)
                {
                    // Place the input box just below the combo box
                    var point = this.comboGameProfile.PointToScreen(new Point(0, this.comboGameProfile.Bottom));

                    // Get NES file name
                    var slash = this.filename.LastIndexOf(Path.DirectorySeparatorChar);
                    var dot = this.filename.LastIndexOf('.');
                    if (dot < 0) dot = this.filename.Length;
                    var filename = this.filename.Substring(slash + 1, dot - slash - 1);

                    // Ask user for a profile name
                    var input = Microsoft.VisualBasic.Interaction.InputBox(
                        "Enter profile name.\n" +
                        "\n" +
                        "Profiles are automatically loaded if the profile name matches the beginning of the NES file name.",
                        //
                        "New profile",
                        filename,
                        point.X,
                        point.Y);

                    // Reset selection in case the new profile is invalid
                    comboGameProfile.SelectedIndex = comboGameProfile.FindStringExact(NO_PROFILE_TEXT);

                    // Cancelled?
                    if (input.Length == 0)
                        return;

                    // Limit character count
                    if (input.Length > ProfileListing.LENGTH_LIMIT)
                    {
                        MessageBox.Show("Profile name is too large.\n\n" +
                            $"You have used {input.Length} characters out of {ProfileListing.LENGTH_LIMIT}.");
                        return;
                    }

                    // Reject some characters in the profile name
                    var reject = new string[] { "<", ">", ":", "\"", "\\", "/", "|", "?", "*" };
                    foreach (var rejected in reject)
                    {
                        if (input.Contains(rejected))
                        {
                            MessageBox.Show($"Illegal character: {rejected}\n" +
                                $"Profile wasn't created, try again without this character.");
                            return;
                        }
                    }

                    // Save profile
                    SaveProfile(input, false);

                    // Reload profile list
                    InitProfileList();

                    // Select profile
                    SelectProfile(input, false);
                }
                else if (selected.FilePath == NO_PROFILE)
                {
                    // Do nothing
                }
                else
                {
                    // Load profile
                    LoadProfile(selected.Title);
                }
            }
        }

        private void btnSaveProfile_Click(object sender, EventArgs e)
        {
            if (injector != null)
            {
                if (profileSelected.IsValid)
                    SaveProfile(profileSelected.Title, true);
                else
                {
                    comboGameProfile.SelectedIndex = comboGameProfile.FindStringExact(NEW_PROFILE_TEXT);
                    comboGameProfile_SelectedIndexChanged(null, null);
                }
            }
        }

        private void Injector_KnownCallCountChanged()
        {
            // Display known call count
            if (lblKnownCalls.InvokeRequired)
            {
                Action safeAction = delegate { Injector_KnownCallCountChanged(); };
                lblKnownCalls.Invoke(safeAction);
            }
            else
                lblKnownCalls.Text = $"{injector.GetAllKnownCalls().Length} known calls";
        }

        #endregion
        // --------------------------------------------------------------------
        #region Load Srm file

        private void btnLoadSrm_Click(object sender, EventArgs e)
        {
            OpenFileDialog fileDialog = new OpenFileDialog();
            fileDialog.Filter = "Save RAM File (*.srm)|*.srm";
            fileDialog.Title = "Select SRM Files (multi file select enabled)";
            fileDialog.Multiselect = true;
            fileDialog.InitialDirectory = Properties.Settings.Default.SrmPath;

            if (fileDialog.ShowDialog() == DialogResult.OK)
            {
                // Save path
                Properties.Settings.Default.SrmPath = fileDialog.FileName.Substring(0, fileDialog.FileName.LastIndexOf('\\'));
                Properties.Settings.Default.Save();

                foreach (var file in fileDialog.FileNames)
                {
                    // Read file and find header
                    byte[] data = File.ReadAllBytes(file);
                    SrmFeedbackReader reader = new SrmFeedbackReader(injector, data);

                    // Is this a valid save file?
                    if (reader.IsValid)
                    {
                        var profileName = reader.GetProfileName();

                        // Condition for applying feedback to current profile
                        bool pass = profileName == this.profileLoaded;

                        // Is the profile name valid?
                        if (profileName == NO_PROFILE)
                            profileName = string.Empty;

                        if (profileName == string.Empty)
                        {
                            // Srm file has no profile associated to it
                            if (injector != null)
                                if (MessageBox.Show($"Save file {ConvertPathToTitle(file)} doesn't have a profile associated with it.\n" +
                                    "\n" +
                                    "Use this SRM file for the currently loaded profile?\n" +
                                    "\n" +
                                    "NOTICE: Loading feedback from the wrong game will not help and may cause problems.",
                                    "Unidentified SRM", MessageBoxButtons.YesNo) == DialogResult.Yes)
                                {
                                    pass = true;
                                    profileName = this.profileLoaded;
                                }
                        }

                        // Read feedback
                        var calls = reader.GetFunctionEntryPoints();
                        var callsString = injector.ConvertCallsToString(calls);

                        // Apply feedback
                        if (pass)
                            injector.SetSetting(callsString);

                        // Save to file
                        if (profileName != string.Empty && profileName != NO_PROFILE && profileName != NEW_PROFILE && profileName != null)
                            File.AppendAllText(profilePath + profileName + ".txt", Environment.NewLine + callsString);
                    }
                }
            }
        }

        #endregion
        // --------------------------------------------------------------------
        #region Show Rom information

        private void ShowRomInfo()
        {
            lblMapper.Text = string.Format("Mapper: {0}{1}{2}\n{3} PRG banks\n{4} CHR banks",
                injector.ReadMapper(),
                injector.ReadSubMapper() > 0 ? "." + injector.ReadSubMapper().ToString() : "",
                injector.mapperSupported ? "" : "\nNot supported",
                injector.ReadPrgBanks(),
                injector.ReadChrBanks());
        }

        private void CreateSettingsGUI()
        {
            // Replace GUI on the front panel
            gui?.Dispose();
            panel.AutoScroll = false;
            gui = new SettingsGUI(injector, panel);
            panel.AutoScroll = true;
        }

        #endregion
        // --------------------------------------------------------------------
        #region Web Links

        private void btnPatreon_Click(object sender, EventArgs e)
        {
            Process.Start("https://www.patreon.com/Myself086");
        }

        private void btnCompatibility_Click(object sender, EventArgs e)
        {
            Process.Start("https://docs.google.com/spreadsheets/d/1xKZIyNz1DSI3ZBdMfaTEaa_9b6IEABx-ZPwOb6XqcLQ/edit?usp=sharing");
        }

        #endregion
    }
}
