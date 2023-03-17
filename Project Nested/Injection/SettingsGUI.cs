using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Project_Nested.Injection;

namespace Project_Nested.Injection
{
    class SettingsGUI : IDisposable
    {
        #region Variables

        private int X;
        private int Y;

        const int TABULATION = 24;

        Injector injector;

        private List<Control> controls = new List<Control>();
        private Control box;

        ToolTip tip = new ToolTip();

        #endregion
        // --------------------------------------------------------------------
        #region Constructor

        public SettingsGUI(Injector injector, Control box)
        {
            this.box = box;
            this.injector = injector;

            var settings = injector.GetAllSettingsObject();

            // Coordinate within the box
            X = 6;
            Y = 19;

            // Code from: https://stackoverflow.com/questions/1339524/how-do-i-add-a-tooltip-to-a-control
            {
                // Set up the delays for the ToolTip.
                tip.AutoPopDelay = 120000;
                tip.InitialDelay = 200;
                tip.ReshowDelay = 500;
                // Force the ToolTip text to be displayed whether or not the form is active.
                tip.ShowAlways = true;
            }

            // Get mapper number
            int mapper = injector.ReadMapper();

            // Exe side settings interface
            {
                CreateButtonPatchList();
            }

            // SNES side settings interface
            foreach (var item in settings)
            {
                var setting = item.Value;

#if !DEBUG
                if (setting.IsPublic)
#endif
                {
                    if (setting.IsValidMapper(mapper))
                    {
                        switch (setting.type)
                        {
                            default:
                                CreateLabel(setting, true);
                                break;
                            case SettingType.Void:
                                CreateLabel(setting, false);
                                break;
                            case SettingType.VoidStar:
                                CreateTextbox(setting, false);
                                break;
                            case SettingType.Bool:
                                CreateCheckbox(setting);
                                break;
                            case SettingType.Byte:
                            case SettingType.Short:
                            case SettingType.Pointer:
                            case SettingType.Int:
                            case SettingType.Char:
                                CreateTextbox(setting, true);
                                break;
                            case SettingType.Button:
                                CreateButton(setting);
                                break;
                        }
                    }
                }
            }
        }

        #endregion
        // --------------------------------------------------------------------
        #region Add user interface

        private void AddControl(Control control)
        {
            box.Controls.Add(control);
            controls.Add(control);
        }

        private Control AddNonDefaultIndicator(bool visible)
        {
            Label label = new Label();
            label.Location = new Point(X, Y);
            label.Text = "*";
            label.Font = new Font(label.Font, FontStyle.Bold);
            label.AutoSize = true;
            label.Visible = visible;
            tip.SetToolTip(label, "This setting was changed compared to its default value.");
            AddControl(label);

            return label;
        }

        private void CreateLabel(Setting setting, bool tab)
        {
            // Label
            Label label = new Label();
            label.Location = new Point(tab ? X + TABULATION : X, Y);
            label.Text = setting.TitleWithPrivacy;
            label.ForeColor = GetSettingDefaultColor(setting);
            label.AutoSize = true;
            tip.SetToolTip(label, setting.Summary);
            AddControl(label);

            // Increment Y
            Y += 23;
        }

        private void CreateCheckbox(Setting setting)
        {
            bool busy = false;

            var nonDefaultIndicator = setting.IsGlobal ? null : AddNonDefaultIndicator(!setting.IsDefaultValue());

            // Checkbox
            CheckBox box = new CheckBox();
            box.Location = new Point(X + TABULATION, Y);
            box.Text = setting.TitleWithPrivacy;
            box.ForeColor = GetSettingDefaultColor(setting);
            box.AutoSize = true;
            box.Checked = Convert.ToBoolean(setting.GetValue());
            box.CheckedChanged += (sender, e) =>
            {
                if (!busy)
                {
                    busy = true;

                    setting.SetValue(box.Checked.ToString());

                    if (nonDefaultIndicator != null)
                        nonDefaultIndicator.Visible = !setting.IsDefaultValue();

                    busy = false;
                }
            };
            tip.SetToolTip(box, setting.Summary);
            AddControl(box);

            setting.Changed += (sender) =>
            {
                if (!busy && !box.InvokeRequired)
                    box.Checked = Convert.ToBoolean(sender.GetValue());
            };

            // Increment Y
            Y += 23;
        }

        private void CreateTextbox(Setting setting, bool enabled)
        {
            bool busy = false;

            var nonDefaultIndicator = setting.IsGlobal ? null : AddNonDefaultIndicator(!setting.IsDefaultValue());

            // Label
            Label label = new Label();
            label.Location = new Point(X + TABULATION, Y);
            label.Text = setting.TitleWithPrivacy;
            label.ForeColor = GetSettingDefaultColor(setting);
            label.AutoSize = true;
            tip.SetToolTip(label, setting.Summary);
            AddControl(label);

            // Textbox
            TextBox textbox = new TextBox();
            textbox.Width = 120;
            textbox.Location = new Point(box.Width - textbox.Width - X, Y);
            textbox.Text = setting.GetValues();
            textbox.Anchor = AnchorStyles.Top | AnchorStyles.Right;
            textbox.Enabled = enabled;
            textbox.TextChanged += (sender, e) =>
            {
                if (!busy)
                {
                    busy = true;

                    textbox.ForeColor = Color.FromKnownColor(KnownColor.WindowText);
                    textbox.BackColor = Color.FromKnownColor(KnownColor.Window);
                    try
                    {
                        setting.SetValues(textbox.Text);

                        if (nonDefaultIndicator != null)
                            nonDefaultIndicator.Visible = !setting.IsDefaultValue();
                    }
                    catch (Exception)
                    {
                        // Reverse front and back colors when an error happens
                        textbox.ForeColor = Color.FromKnownColor(KnownColor.Window);
                        textbox.BackColor = Color.FromKnownColor(KnownColor.WindowText);
                    }

                    busy = false;
                }
            };
            tip.SetToolTip(textbox, setting.Summary);
            AddControl(textbox);

            setting.Changed += (sender) =>
            {
                if (!busy && !textbox.InvokeRequired)
                    textbox.Text = sender.GetValues();
            };

            // Increment Y
            Y += 26;
        }

        private void CreateButtonPatchList()
        {
            const string EDIT_PATCH_TEXT = "{0} active patches, {1} bytes changed.";

            // Button
            Button button = new Button();
            button.Location = new Point(X + TABULATION, Y);
            button.Text = "Patches && Game Genie";
            button.AutoSize = true;
            //tip.SetToolTip(label, setting.Summary);
            AddControl(button);

            // Label
            Label label = new Label();
            label.Location = new Point(button.Right + 6, Y + 5);
            UpdateLabel();
            label.AutoSize = true;
            //tip.SetToolTip(label, setting.Summary);
            AddControl(label);

            void UpdateLabel()
            {
                if (!label.IsDisposed)
                    label.Text = string.Format(EDIT_PATCH_TEXT, injector.patches.Count, injector.patches.Sum(f => f.Value.Data != null ? f.Value.Data.Length : 1));
            }
            injector.PatchesCountChanged += UpdateLabel;

            button.Click += (sender, e) =>
            {
                var form = new FrmPatches();
                form.Show((Control)sender);

                form.injector = this.injector;

                form.FormClosed += (sender2, e2) =>
                {
                    // Update label
                    UpdateLabel();
                };
            };

            // Increment Y
            Y += 29;
        }

        private void CreateButton(Setting setting)
        {
            // Button
            Button button = new Button();
            button.Location = new Point(X + TABULATION, Y);
            button.Text = setting.TitleWithPrivacy;
            button.Width = TextRenderer.MeasureText(button.Text, button.Font).Width + 16;
            button.AutoSize = true;
            tip.SetToolTip(button, setting.Summary);
            AddControl(button);

            button.Click += (sender, e) =>
            {
                switch (setting.Name)
                {
                    case "Optimize":
                        {
                            var form = new Optimize.FrmOptimize();
                            form.Show((Control)sender);
                            form.injector = injector;
                        }
                        break;
                    case "CustomPalette":
                        {
                            var form = new FrmPalette();
                            form.Show((Control)sender);
                            form.injector = injector;
                        }
                        break;
                    case "CustomInput":
                        if (Convert.ToBoolean(injector.GetSetting("Input.Enabled")))
                        {
                            var form = new FrmControllerInput(injector);
                            form.Show((Control)sender);
                        }
                        else
                            MessageBox.Show("You must enable custom input.");
                        break;
                    default:
                        MessageBox.Show($"Unknown button behavior for \"{setting.Name}\".");
                        break;
                }
            };

            // Increment Y
            Y += 29;
        }

        #endregion
        // --------------------------------------------------------------------
        #region User interface color

        private Color GetSettingDefaultColor(Setting setting)
        {
            if (!setting.IsPublic)
                return Color.Red;
            if (setting.IsGlobal)
                return Color.Blue;
            return SystemColors.ControlText;
        }

        #endregion
        // --------------------------------------------------------------------
        #region IDisposable Support

        private bool disposedValue = false; // To detect redundant calls

        protected virtual void Dispose(bool disposing)
        {
            if (!disposedValue)
            {
                if (disposing)
                {
                    // dispose managed state (managed objects).
                    foreach (var item in controls)
                    {
                        box.Controls.Remove(item);
                        item.Dispose();
                    }
                }

                // free unmanaged resources (unmanaged objects) and override a finalizer below.

                // set large fields to null.
                controls = null;

                disposedValue = true;
            }
        }

        // This code added to correctly implement the disposable pattern.
        public void Dispose()
        {
            // Do not change this code. Put cleanup code in Dispose(bool disposing) above.
            Dispose(true);
        }

        #endregion
    }
}
