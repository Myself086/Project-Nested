using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Project_Nested
{
    static class RichTextBoxExtension
    {
        public static void AppendText(this RichTextBox box, string text, Color color)
        {
            box.SelectionStart = box.TextLength;
            box.SelectionLength = 0;

            box.SelectionColor = color;
            box.AppendText(text);
            box.SelectionColor = box.ForeColor;
        }

        public static void SetRichText(this RichTextBox box, string text)
        {
            box.SuspendLayout();
            {
                // Remove text
                box.Text = string.Empty;

                Color c = Color.White;

                var ctxt = text.Split('/');
                for (int i = 0; i < ctxt.Length; i++)
                {
                    // Even numbered index = Raw text
                    // Odd numbered index = Commands
                    if ((i & 1) == 0)
                        box.AppendText(ctxt[i], c);
                    else
                    {
                        var cmd = ctxt[i].ToLowerInvariant();
                        if (cmd.Length == 0)
                            // No command, write single slash
                            box.AppendText(ctxt[i], c);
                        else if (cmd[0] == 'c')
                            // Change color in RGB444 format following the 'c' (ie. "cfff", "c000")
                            c = Color.FromArgb(Convert.ToInt32(string.Format("ff{0}{0}{1}{1}{2}{2}", cmd[1], cmd[2], cmd[3]), 16));
                    }
                }
            }
            box.ResumeLayout();
        }
    }
}
