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

namespace Project_Nested
{
    public partial class FrmPalette : Form
    {
        private Injector _injector;
        internal Injector injector
        {
            get => _injector;
            set
            {
                this._injector = value;

                if (loaded)
                    RenderPalette();
            }
        }

        bool loaded;

        public FrmPalette()
        {
            InitializeComponent();
        }

        private void FrmPalette_Load(object sender, EventArgs e)
        {
            this.loaded = true;
            RenderPalette();
        }

        // --------------------------------------------------------------------

        private void ChangePalette(Bitmap bmp)
        {
            float stepX = bmp.Width / 16;
            float stepY = bmp.Height / 4;

            int[] palette = new int[0x40];
            int index = 0;

            var colorCounts = new Dictionary<Color, int>();

            for (float y = 0; y < bmp.Height; y += stepY)
            {
                for (float x = 0; x < bmp.Width; x += stepX)
                {
                    // Count colors within this cell
                    colorCounts.Clear();
                    for (int yy = 0; yy < (int)stepY; yy++)
                    {
                        for (int xx = 0; xx < (int)stepX; xx++)
                        {
                            var color = bmp.GetPixel((int)x + xx, (int)y + yy);
                            int count;
                            colorCounts.TryGetValue(color, out count);
                            colorCounts[color] = count + 1;
                        }
                    }

                    // Find the most common color within this cell
                    {
                        int highCount = 0;
                        Color color = Color.Black;
                        foreach (var item in colorCounts)
                        {
                            if (highCount < item.Value)
                            {
                                highCount = item.Value;
                                color = item.Key;
                            }
                        }

                        // Convert color to RGB555 and put it in our palette
                        palette[index++] =
                            (color.R >> 3) << 0 |
                            (color.G >> 3) << 5 |
                            (color.B >> 3) << 10;
                    }
                }
            }

            // Write new palette to ROM
            for (int i = 0; i < palette.Length; i++)
                injector.SetSetting("Palette", i, palette[i].ToString());

            // Show new palette to the user
            RenderPalette();
        }

        // --------------------------------------------------------------------

        private Bitmap paletteImage;
        private void RenderPalette()
        {
            if (injector == null)
                return;

            // Get palette data
            int[] palette = new int[0x40];
            for (int i = 0; i < palette.Length; i++)
                palette[i] = injector.GetSetting("Palette", i).ReadInt();

            // Initialize bitmap
            if (paletteImage == null)
                paletteImage = new Bitmap(pictureBox1.Width, pictureBox1.Height);
            float stepX = paletteImage.Width / 16;
            float stepY = paletteImage.Height / 4;

            using (Graphics g = Graphics.FromImage(paletteImage))
            {
                g.Clear(Color.Black);
                int index = 0;
                for (int y = 0; y < 4; y++)
                {
                    for (int x = 0; x < 16; x++)
                    {
                        // Read color from RGB555
                        var colorValue = palette[index++];
                        Color color = Color.FromArgb(
                            (((colorValue >> 0) & 0x1f) * 0x21) >> 2,
                            (((colorValue >> 5) & 0x1f) * 0x21) >> 2,
                            (((colorValue >> 10) & 0x1f) * 0x21) >> 2);

                        // Render border
                        g.DrawRectangle(Pens.Gray, new Rectangle(
                            (int)(x * stepX), (int)(y * stepY),
                            (int)stepX - 1, (int)stepY - 1));

                        // Render color cell
                        g.FillRectangle(new SolidBrush(color), new Rectangle(
                            (int)(x * stepX), (int)(y * stepY),
                            (int)stepX - 2, (int)stepY - 2));
                    }
                }
            }

            // Swap images on the picture box
            var swap = pictureBox1.Image as Bitmap;
            pictureBox1.Image = paletteImage;
            paletteImage = swap;
        }

        // --------------------------------------------------------------------

        private void btnLoad_Click(object sender, EventArgs e)
        {
            OpenFileDialog fileDialog = new OpenFileDialog();
            fileDialog.Filter = "Image file|*.BMP;*.PNG;*.JPG;*.GIF;*.TIFF";
            fileDialog.Title = "Select an image File";

            if (fileDialog.ShowDialog() == DialogResult.OK)
            {
                ChangePalette(Image.FromFile(fileDialog.FileName) as Bitmap);
            }
        }

        private void btnCopy_Click(object sender, EventArgs e)
        {
            Clipboard.Clear();
            Clipboard.SetImage(pictureBox1.Image);
        }

        private void btnPaste_Click(object sender, EventArgs e)
        {
            if (Clipboard.ContainsImage())
                ChangePalette(Clipboard.GetImage() as Bitmap);
            else
                MessageBox.Show("Clipboard must contain an image.");
        }

        private void btnDefault_Click(object sender, EventArgs e)
        {
            for (int i = 0; i < 0x40; i++)
                injector.SetSetting("Palette", i, injector.GetSetting("PaletteDefault", i));

            RenderPalette();
        }
    }
}
