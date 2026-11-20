using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class IconGenerator
{
    private static GraphicsPath CreateRoundedRectanglePath(RectangleF rect, float radius)
    {
        GraphicsPath path = new GraphicsPath();
        float diameter = radius * 2.0f;
        RectangleF arc = new RectangleF(rect.X, rect.Y, diameter, diameter);

        // Top-Left
        path.AddArc(arc, 180, 90);
        // Top-Right
        arc.X = rect.Right - diameter;
        path.AddArc(arc, 270, 90);
        // Bottom-Right
        arc.Y = rect.Bottom - diameter;
        path.AddArc(arc, 0, 90);
        // Bottom-Left
        arc.X = rect.Left;
        path.AddArc(arc, 90, 90);
        path.CloseFigure();
        return path;
    }

    public static void Render(int size, string outputPath, bool isForegroundOnly = false, bool isRound = false)
    {
        using (Bitmap bitmap = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bitmap))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.CompositingQuality = CompositingQuality.HighQuality;

            float scale = size / 1024.0f;

            if (!isForegroundOnly)
            {
                RectangleF bgRect = new RectangleF(0, 0, size, size);
                if (isRound)
                {
                    using (GraphicsPath circlePath = new GraphicsPath())
                    {
                        circlePath.AddEllipse(0, 0, size, size);
                        g.SetClip(circlePath);

                        using (LinearGradientBrush bgBrush = new LinearGradientBrush(
                            bgRect,
                            ColorTranslator.FromHtml("#1E3A8A"),
                            ColorTranslator.FromHtml("#0F172A"),
                            LinearGradientMode.ForwardDiagonal))
                        {
                            g.FillRectangle(bgBrush, bgRect);
                        }
                        g.ResetClip();
                    }
                }
                else
                {
                    using (LinearGradientBrush bgBrush = new LinearGradientBrush(
                        bgRect,
                        ColorTranslator.FromHtml("#1E3A8A"),
                        ColorTranslator.FromHtml("#0F172A"),
                        LinearGradientMode.ForwardDiagonal))
                    {
                        g.FillRectangle(bgBrush, bgRect);
                    }
                }
            }

            // Emblem Coordinate Base (1024 coordinate system)
            // If foreground-only (Android adaptive icon), scale down so it fits safely within the 66% (675px) circle
            float emblemScale = isForegroundOnly ? scale * 0.70f : scale;
            float offsetX = isForegroundOnly ? (size - (1024.0f * emblemScale)) / 2.0f : 0.0f;
            float offsetY = isForegroundOnly ? (size - (1024.0f * emblemScale)) / 2.0f : 0.0f;

            float paperLeft = (292.0f * emblemScale) + offsetX;
            float paperTop = (242.0f * emblemScale) + offsetY;
            float paperWidth = 440.0f * emblemScale;
            float paperHeight = 540.0f * emblemScale;
            float paperRadius = 36.0f * emblemScale;
            float foldSize = 90.0f * emblemScale;

            // Drop shadow
            if (!isForegroundOnly)
            {
                RectangleF shadowRect = new RectangleF(paperLeft, paperTop + (12.0f * emblemScale), paperWidth, paperHeight);
                using (GraphicsPath shadowPath = CreateRoundedRectanglePath(shadowRect, paperRadius))
                using (SolidBrush shadowBrush = new SolidBrush(Color.FromArgb(60, 5, 11, 20)))
                {
                    g.FillPath(shadowBrush, shadowPath);
                }
            }

            // Main Paper Path
            using (GraphicsPath paperPath = new GraphicsPath())
            {
                paperPath.AddArc(paperLeft, paperTop, paperRadius * 2, paperRadius * 2, 180, 90);
                paperPath.AddLine(paperLeft + paperRadius, paperTop, paperLeft + paperWidth - foldSize, paperTop);
                paperPath.AddLine(paperLeft + paperWidth, paperTop + foldSize, paperLeft + paperWidth, paperTop + paperHeight - paperRadius);
                paperPath.AddArc(paperLeft + paperWidth - (paperRadius * 2), paperTop + paperHeight - (paperRadius * 2), paperRadius * 2, paperRadius * 2, 0, 90);
                paperPath.AddLine(paperLeft + paperWidth - paperRadius, paperTop + paperHeight, paperLeft + paperRadius, paperTop + paperHeight);
                paperPath.AddArc(paperLeft, paperTop + paperHeight - (paperRadius * 2), paperRadius * 2, paperRadius * 2, 90, 90);
                paperPath.CloseFigure();

                using (SolidBrush paperBrush = new SolidBrush(Color.White))
                {
                    g.FillPath(paperBrush, paperPath);
                }
            }

            // Folded Corner Triangle
            PointF pt1 = new PointF(paperLeft + paperWidth - foldSize, paperTop);
            PointF pt2 = new PointF(paperLeft + paperWidth - foldSize, paperTop + foldSize);
            PointF pt3 = new PointF(paperLeft + paperWidth, paperTop + foldSize);
            using (GraphicsPath foldPath = new GraphicsPath())
            {
                foldPath.AddPolygon(new PointF[] { pt1, pt2, pt3 });
                using (SolidBrush foldBrush = new SolidBrush(ColorTranslator.FromHtml("#E2E8F0")))
                {
                    g.FillPath(foldBrush, foldPath);
                }
            }
            using (Pen creasePen = new Pen(ColorTranslator.FromHtml("#CBD5E1"), 2.5f * emblemScale))
            {
                g.DrawLine(creasePen, pt1, pt3);
            }

            // Category Pill: x=344, y=294, w=108, h=28
            RectangleF pillRect = new RectangleF(
                (344.0f * emblemScale) + offsetX,
                (294.0f * emblemScale) + offsetY,
                108.0f * emblemScale,
                28.0f * emblemScale);
            using (GraphicsPath pillPath = CreateRoundedRectanglePath(pillRect, 14.0f * emblemScale))
            using (LinearGradientBrush blueBrush = new LinearGradientBrush(
                pillRect,
                ColorTranslator.FromHtml("#38BDF8"),
                ColorTranslator.FromHtml("#2563EB"),
                LinearGradientMode.Horizontal))
            {
                g.FillPath(blueBrush, pillPath);
            }

            // Media / Image Block: x=344, y=344, w=336, h=172
            RectangleF mediaRect = new RectangleF(
                (344.0f * emblemScale) + offsetX,
                (344.0f * emblemScale) + offsetY,
                336.0f * emblemScale,
                172.0f * emblemScale);
            using (GraphicsPath mediaPath = CreateRoundedRectanglePath(mediaRect, 18.0f * emblemScale))
            using (LinearGradientBrush mediaBrush = new LinearGradientBrush(
                mediaRect,
                ColorTranslator.FromHtml("#0284C7"),
                ColorTranslator.FromHtml("#1E40AF"),
                LinearGradientMode.ForwardDiagonal))
            {
                g.FillPath(mediaBrush, mediaPath);

                // Planet/orb inside media block
                g.SetClip(mediaPath);
                using (SolidBrush orbBrush = new SolidBrush(Color.FromArgb(90, 255, 255, 255)))
                {
                    g.FillEllipse(orbBrush,
                        (580.0f * emblemScale) + offsetX,
                        (370.0f * emblemScale) + offsetY,
                        56.0f * emblemScale,
                        56.0f * emblemScale);
                }
                g.ResetClip();
            }

            // Headline Bar: x=344, y=548, w=280, h=30
            RectangleF hRect = new RectangleF(
                (344.0f * emblemScale) + offsetX,
                (548.0f * emblemScale) + offsetY,
                280.0f * emblemScale,
                30.0f * emblemScale);
            using (GraphicsPath hPath = CreateRoundedRectanglePath(hRect, 15.0f * emblemScale))
            using (SolidBrush darkBrush = new SolidBrush(ColorTranslator.FromHtml("#0F172A")))
            {
                g.FillPath(darkBrush, hPath);
            }

            // Text Line 1: x=344, y=602, w=336, h=20
            RectangleF l1Rect = new RectangleF(
                (344.0f * emblemScale) + offsetX,
                (602.0f * emblemScale) + offsetY,
                336.0f * emblemScale,
                20.0f * emblemScale);
            using (GraphicsPath l1Path = CreateRoundedRectanglePath(l1Rect, 10.0f * emblemScale))
            using (SolidBrush l1Brush = new SolidBrush(ColorTranslator.FromHtml("#64748B")))
            {
                g.FillPath(l1Brush, l1Path);
            }

            // Text Line 2: x=344, y=638, w=336, h=20
            RectangleF l2Rect = new RectangleF(
                (344.0f * emblemScale) + offsetX,
                (638.0f * emblemScale) + offsetY,
                336.0f * emblemScale,
                20.0f * emblemScale);
            using (GraphicsPath l2Path = CreateRoundedRectanglePath(l2Rect, 10.0f * emblemScale))
            using (SolidBrush l2Brush = new SolidBrush(ColorTranslator.FromHtml("#94A3B8")))
            {
                g.FillPath(l2Brush, l2Path);
            }

            // Text Line 3: x=344, y=674, w=220, h=20
            RectangleF l3Rect = new RectangleF(
                (344.0f * emblemScale) + offsetX,
                (674.0f * emblemScale) + offsetY,
                220.0f * emblemScale,
                20.0f * emblemScale);
            using (GraphicsPath l3Path = CreateRoundedRectanglePath(l3Rect, 10.0f * emblemScale))
            using (SolidBrush l3Brush = new SolidBrush(ColorTranslator.FromHtml("#CBD5E1")))
            {
                g.FillPath(l3Brush, l3Path);
            }

            // Bright-Blue Tag Dot: x=640, y=670, d=28
            using (SolidBrush dotBrush = new SolidBrush(ColorTranslator.FromHtml("#2563EB")))
            {
                g.FillEllipse(dotBrush,
                    (640.0f * emblemScale) + offsetX,
                    (670.0f * emblemScale) + offsetY,
                    28.0f * emblemScale,
                    28.0f * emblemScale);
            }

            string outDir = Path.GetDirectoryName(outputPath);
            if (!string.IsNullOrEmpty(outDir) && !Directory.Exists(outDir))
            {
                Directory.CreateDirectory(outDir);
            }

            bitmap.Save(outputPath, ImageFormat.Png);
        }
    }

    public static void RenderSplash(int size, string outputPath, float scaleFactor = 1.0f)
    {
        using (Bitmap bitmap = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bitmap))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.CompositingQuality = CompositingQuality.HighQuality;

            float iconSize = size * scaleFactor;
            float offset = (size - iconSize) / 2.0f;
            RectangleF bgRect = new RectangleF(offset, offset, iconSize, iconSize);
            float radius = iconSize * 0.22f;

            using (GraphicsPath squirclePath = CreateRoundedRectanglePath(bgRect, radius))
            {
                g.SetClip(squirclePath);
                using (LinearGradientBrush bgBrush = new LinearGradientBrush(
                    bgRect,
                    ColorTranslator.FromHtml("#1E3A8A"),
                    ColorTranslator.FromHtml("#0F172A"),
                    LinearGradientMode.ForwardDiagonal))
                {
                    g.FillRectangle(bgBrush, bgRect);
                }
                g.ResetClip();
            }

            // Emblem Coordinate Base (1024 coordinate system)
            float emblemScale = iconSize / 1024.0f;
            float offsetX = offset;
            float offsetY = offset;

            float paperLeft = (292.0f * emblemScale) + offsetX;
            float paperTop = (242.0f * emblemScale) + offsetY;
            float paperWidth = 440.0f * emblemScale;
            float paperHeight = 540.0f * emblemScale;
            float paperRadius = 36.0f * emblemScale;
            float foldSize = 90.0f * emblemScale;

            // Drop shadow
            RectangleF shadowRect = new RectangleF(paperLeft, paperTop + (12.0f * emblemScale), paperWidth, paperHeight);
            using (GraphicsPath shadowPath = CreateRoundedRectanglePath(shadowRect, paperRadius))
            using (SolidBrush shadowBrush = new SolidBrush(Color.FromArgb(60, 5, 11, 20)))
            {
                g.FillPath(shadowBrush, shadowPath);
            }

            // Main Paper Path
            using (GraphicsPath paperPath = new GraphicsPath())
            {
                paperPath.AddArc(paperLeft, paperTop, paperRadius * 2, paperRadius * 2, 180, 90);
                paperPath.AddLine(paperLeft + paperRadius, paperTop, paperLeft + paperWidth - foldSize, paperTop);
                paperPath.AddLine(paperLeft + paperWidth, paperTop + foldSize, paperLeft + paperWidth, paperTop + paperHeight - paperRadius);
                paperPath.AddArc(paperLeft + paperWidth - (paperRadius * 2), paperTop + paperHeight - (paperRadius * 2), paperRadius * 2, paperRadius * 2, 0, 90);
                paperPath.AddLine(paperLeft + paperWidth - paperRadius, paperTop + paperHeight, paperLeft + paperRadius, paperTop + paperHeight);
                paperPath.AddArc(paperLeft, paperTop + paperHeight - (paperRadius * 2), paperRadius * 2, paperRadius * 2, 90, 90);
                paperPath.CloseFigure();

                using (SolidBrush paperBrush = new SolidBrush(Color.White))
                {
                    g.FillPath(paperBrush, paperPath);
                }
            }

            // Folded Corner Triangle
            PointF pt1 = new PointF(paperLeft + paperWidth - foldSize, paperTop);
            PointF pt2 = new PointF(paperLeft + paperWidth - foldSize, paperTop + foldSize);
            PointF pt3 = new PointF(paperLeft + paperWidth, paperTop + foldSize);
            using (GraphicsPath foldPath = new GraphicsPath())
            {
                foldPath.AddPolygon(new PointF[] { pt1, pt2, pt3 });
                using (SolidBrush foldBrush = new SolidBrush(ColorTranslator.FromHtml("#E2E8F0")))
                {
                    g.FillPath(foldBrush, foldPath);
                }
            }
            using (Pen creasePen = new Pen(ColorTranslator.FromHtml("#CBD5E1"), 2.5f * emblemScale))
            {
                g.DrawLine(creasePen, pt1, pt3);
            }

            // Category Pill: x=344, y=294, w=108, h=28
            RectangleF pillRect = new RectangleF(
                (344.0f * emblemScale) + offsetX,
                (294.0f * emblemScale) + offsetY,
                108.0f * emblemScale,
                28.0f * emblemScale);
            using (GraphicsPath pillPath = CreateRoundedRectanglePath(pillRect, 14.0f * emblemScale))
            using (LinearGradientBrush blueBrush = new LinearGradientBrush(
                pillRect,
                ColorTranslator.FromHtml("#38BDF8"),
                ColorTranslator.FromHtml("#2563EB"),
                LinearGradientMode.Horizontal))
            {
                g.FillPath(blueBrush, pillPath);
            }

            // Media / Image Block: x=344, y=344, w=336, h=172
            RectangleF mediaRect = new RectangleF(
                (344.0f * emblemScale) + offsetX,
                (344.0f * emblemScale) + offsetY,
                336.0f * emblemScale,
                172.0f * emblemScale);
            using (GraphicsPath mediaPath = CreateRoundedRectanglePath(mediaRect, 18.0f * emblemScale))
            using (LinearGradientBrush mediaBrush = new LinearGradientBrush(
                mediaRect,
                ColorTranslator.FromHtml("#0284C7"),
                ColorTranslator.FromHtml("#1E40AF"),
                LinearGradientMode.ForwardDiagonal))
            {
                g.FillPath(mediaBrush, mediaPath);

                // Planet/orb inside media block
                g.SetClip(mediaPath);
                using (SolidBrush orbBrush = new SolidBrush(Color.FromArgb(90, 255, 255, 255)))
                {
                    g.FillEllipse(orbBrush,
                        (580.0f * emblemScale) + offsetX,
                        (370.0f * emblemScale) + offsetY,
                        56.0f * emblemScale,
                        56.0f * emblemScale);
                }
                g.ResetClip();
            }

            // Headline Bar: x=344, y=548, w=280, h=30
            RectangleF hRect = new RectangleF(
                (344.0f * emblemScale) + offsetX,
                (548.0f * emblemScale) + offsetY,
                280.0f * emblemScale,
                30.0f * emblemScale);
            using (GraphicsPath hPath = CreateRoundedRectanglePath(hRect, 15.0f * emblemScale))
            using (SolidBrush darkBrush = new SolidBrush(ColorTranslator.FromHtml("#0F172A")))
            {
                g.FillPath(darkBrush, hPath);
            }

            // Text Line 1: x=344, y=602, w=336, h=20
            RectangleF l1Rect = new RectangleF(
                (344.0f * emblemScale) + offsetX,
                (602.0f * emblemScale) + offsetY,
                336.0f * emblemScale,
                20.0f * emblemScale);
            using (GraphicsPath l1Path = CreateRoundedRectanglePath(l1Rect, 10.0f * emblemScale))
            using (SolidBrush l1Brush = new SolidBrush(ColorTranslator.FromHtml("#64748B")))
            {
                g.FillPath(l1Brush, l1Path);
            }

            // Text Line 2: x=344, y=638, w=336, h=20
            RectangleF l2Rect = new RectangleF(
                (344.0f * emblemScale) + offsetX,
                (638.0f * emblemScale) + offsetY,
                336.0f * emblemScale,
                20.0f * emblemScale);
            using (GraphicsPath l2Path = CreateRoundedRectanglePath(l2Rect, 10.0f * emblemScale))
            using (SolidBrush l2Brush = new SolidBrush(ColorTranslator.FromHtml("#94A3B8")))
            {
                g.FillPath(l2Brush, l2Path);
            }

            // Text Line 3: x=344, y=674, w=220, h=20
            RectangleF l3Rect = new RectangleF(
                (344.0f * emblemScale) + offsetX,
                (674.0f * emblemScale) + offsetY,
                220.0f * emblemScale,
                20.0f * emblemScale);
            using (GraphicsPath l3Path = CreateRoundedRectanglePath(l3Rect, 10.0f * emblemScale))
            using (SolidBrush l3Brush = new SolidBrush(ColorTranslator.FromHtml("#CBD5E1")))
            {
                g.FillPath(l3Brush, l3Path);
            }

            // Bright-Blue Tag Dot: x=640, y=670, d=28
            using (SolidBrush dotBrush = new SolidBrush(ColorTranslator.FromHtml("#2563EB")))
            {
                g.FillEllipse(dotBrush,
                    (640.0f * emblemScale) + offsetX,
                    (670.0f * emblemScale) + offsetY,
                    28.0f * emblemScale,
                    28.0f * emblemScale);
            }

            string outDir = Path.GetDirectoryName(outputPath);
            if (!string.IsNullOrEmpty(outDir) && !Directory.Exists(outDir))
            {
                Directory.CreateDirectory(outDir);
            }

            bitmap.Save(outputPath, ImageFormat.Png);
        }
    }
}
