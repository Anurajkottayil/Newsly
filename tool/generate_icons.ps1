Add-Type -AssemblyName System.Drawing

function Create-RoundedRectanglePath {
    param(
        [System.Drawing.RectangleF]$rect,
        [float]$radius
    )
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $radius * 2.0
    $arc = New-Object System.Drawing.RectangleF($rect.X, $rect.Y, $diameter, $diameter)

    # Top-Left
    $path.AddArc($arc, 180, 90)
    # Top-Right
    $arc.X = $rect.Right - $diameter
    $path.AddArc($arc, 270, 90)
    # Bottom-Right
    $arc.Y = $rect.Bottom - $diameter
    $path.AddArc($arc, 0, 90)
    # Bottom-Left
    $arc.X = $rect.Left
    $path.AddArc($arc, 90, 90)
    $path.CloseFigure()
    return $path
}

function Render-NewslyIcon {
    param(
        [int]$size,
        [string]$outputPath,
        [bool]$isForegroundOnly = $false,
        [bool]$isRound = $false
    )

    $bitmap = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

    $scale = $size / 1024.0

    if (-not $isForegroundOnly) {
        if ($isRound) {
            $circlePath = New-Object System.Drawing.Drawing2D.GraphicsPath
            $circlePath.AddEllipse(0, 0, $size, $size)
            $g.SetClip($circlePath)
            
            $bgRect = New-Object System.Drawing.RectangleF(0, 0, $size, $size)
            $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                $bgRect,
                [System.Drawing.ColorTranslator]::FromHtml('#1E3A8A'),
                [System.Drawing.ColorTranslator]::FromHtml('#0F172A'),
                [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
            )
            $g.FillRectangle($bgBrush, $bgRect)
            $bgBrush.Dispose()
            $circlePath.Dispose()
            $g.ResetClip()
        } else {
            # Full square/squircle background
            $bgRect = New-Object System.Drawing.RectangleF(0, 0, $size, $size)
            $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                $bgRect,
                [System.Drawing.ColorTranslator]::FromHtml('#1E3A8A'),
                [System.Drawing.ColorTranslator]::FromHtml('#0F172A'),
                [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
            )
            $g.FillRectangle($bgBrush, $bgRect)
            $bgBrush.Dispose()
        }
    }

    # Emblem Coordinate Base (Scale relative to 1024)
    # If foreground-only, scale down by 0.72 so that it sits cleanly within Android's 66/108 safe zone
    $emblemScale = if ($isForegroundOnly) { $scale * 0.72 } else { $scale }
    $offsetX = if ($isForegroundOnly) { ($size - (1024.0 * $emblemScale)) / 2.0 } else { 0.0 }
    $offsetY = if ($isForegroundOnly) { ($size - (1024.0 * $emblemScale)) / 2.0 } else { 0.0 }

    # Draw Newspaper Body with folded corner
    # Paper bounds: x=292, y=242, w=440, h=540, fold size=90
    $paperLeft = (292.0 * $emblemScale) + $offsetX
    $paperTop = (242.0 * $emblemScale) + $offsetY
    $paperWidth = 440.0 * $emblemScale
    $paperHeight = 540.0 * $emblemScale
    $paperRadius = 36.0 * $emblemScale
    $foldSize = 90.0 * $emblemScale

    # Drop shadow under paper
    if (-not $isForegroundOnly) {
        $shadowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $shadowRect = New-Object System.Drawing.RectangleF(
            $paperLeft,
            $paperTop + (12.0 * $emblemScale),
            $paperWidth,
            $paperHeight
        )
        $shadowPath = Create-RoundedRectanglePath $shadowRect $paperRadius
        $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70, 5, 11, 20))
        $g.FillPath($shadowBrush, $shadowPath)
        $shadowBrush.Dispose()
        $shadowPath.Dispose()
    }

    # Main Paper Path (with top-right chamfer for the fold)
    $paperPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $paperPath.AddArc($paperLeft, $paperTop, $paperRadius * 2, $paperRadius * 2, 180, 90)
    $paperPath.AddLine($paperLeft + $paperRadius, $paperTop, $paperLeft + $paperWidth - $foldSize, $paperTop)
    $paperPath.AddLine($paperLeft + $paperWidth, $paperTop + $foldSize, $paperLeft + $paperWidth, $paperTop + $paperHeight - $paperRadius)
    $paperPath.AddArc($paperLeft + $paperWidth - ($paperRadius * 2), $paperTop + $paperHeight - ($paperRadius * 2), $paperRadius * 2, $paperRadius * 2, 0, 90)
    $paperPath.AddLine($paperLeft + $paperWidth - $paperRadius, $paperTop + $paperHeight, $paperLeft + $paperRadius, $paperTop + $paperHeight)
    $paperPath.AddArc($paperLeft, $paperTop + $paperHeight - ($paperRadius * 2), $paperRadius * 2, $paperRadius * 2, 90, 90)
    $paperPath.CloseFigure()

    $paperBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $g.FillPath($paperBrush, $paperPath)
    $paperBrush.Dispose()
    $paperPath.Dispose()

    # Folded Corner Triangle
    $foldPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $pt1 = New-Object System.Drawing.PointF($paperLeft + $paperWidth - $foldSize, $paperTop)
    $pt2 = New-Object System.Drawing.PointF($paperLeft + $paperWidth - $foldSize, $paperTop + $foldSize)
    $pt3 = New-Object System.Drawing.PointF($paperLeft + $paperWidth, $paperTop + $foldSize)
    $foldPath.AddPolygon(@($pt1, $pt2, $pt3))

    $foldBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#E2E8F0'))
    $g.FillPath($foldBrush, $foldPath)
    $foldBrush.Dispose()
    $foldPath.Dispose()

    # Corner Crease Shadow
    $creasePen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml('#CBD5E1'), (3.0 * $emblemScale))
    $g.DrawLine($creasePen, $pt1, $pt3)
    $creasePen.Dispose()

    # Category Pill: x=344, y=294, w=108, h=28
    $pillRect = New-Object System.Drawing.RectangleF(
        (344.0 * $emblemScale) + $offsetX,
        (294.0 * $emblemScale) + $offsetY,
        108.0 * $emblemScale,
        28.0 * $emblemScale
    )
    $pillPath = Create-RoundedRectanglePath $pillRect (14.0 * $emblemScale)
    $blueBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $pillRect,
        [System.Drawing.ColorTranslator]::FromHtml('#38BDF8'),
        [System.Drawing.ColorTranslator]::FromHtml('#2563EB'),
        [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal
    )
    $g.FillPath($blueBrush, $pillPath)
    $pillPath.Dispose()

    # Media / Image Block: x=344, y=344, w=336, h=172, radius=18
    $mediaRect = New-Object System.Drawing.RectangleF(
        (344.0 * $emblemScale) + $offsetX,
        (344.0 * $emblemScale) + $offsetY,
        336.0 * $emblemScale,
        172.0 * $emblemScale
    )
    $mediaPath = Create-RoundedRectanglePath $mediaRect (18.0 * $emblemScale)
    $mediaBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $mediaRect,
        [System.Drawing.ColorTranslator]::FromHtml('#0284C7'),
        [System.Drawing.ColorTranslator]::FromHtml('#1E40AF'),
        [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
    )
    $g.FillPath($mediaBrush, $mediaPath)
    $mediaBrush.Dispose()

    # Modern horizon line / planet accent inside media block
    $g.SetClip($mediaPath)
    $orbBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(90, 255, 255, 255))
    $g.FillEllipse($orbBrush, [float]((580.0 * $emblemScale) + $offsetX), [float]((370.0 * $emblemScale) + $offsetY), [float](56.0 * $emblemScale), [float](56.0 * $emblemScale))
    $orbBrush.Dispose()
    $g.ResetClip()
    $mediaPath.Dispose()

    # Headline Bar: x=344, y=548, w=280, h=30
    $hRect = New-Object System.Drawing.RectangleF(
        (344.0 * $emblemScale) + $offsetX,
        (548.0 * $emblemScale) + $offsetY,
        280.0 * $emblemScale,
        30.0 * $emblemScale
    )
    $hPath = Create-RoundedRectanglePath $hRect (15.0 * $emblemScale)
    $darkBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#0F172A'))
    $g.FillPath($darkBrush, $hPath)
    $darkBrush.Dispose()
    $hPath.Dispose()

    # Text Line 1: x=344, y=602, w=336, h=20
    $l1Rect = New-Object System.Drawing.RectangleF(
        (344.0 * $emblemScale) + $offsetX,
        (602.0 * $emblemScale) + $offsetY,
        336.0 * $emblemScale,
        20.0 * $emblemScale
    )
    $l1Path = Create-RoundedRectanglePath $l1Rect (10.0 * $emblemScale)
    $l1Brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#64748B'))
    $g.FillPath($l1Brush, $l1Path)
    $l1Brush.Dispose()
    $l1Path.Dispose()

    # Text Line 2: x=344, y=638, w=336, h=20
    $l2Rect = New-Object System.Drawing.RectangleF(
        (344.0 * $emblemScale) + $offsetX,
        (638.0 * $emblemScale) + $offsetY,
        336.0 * $emblemScale,
        20.0 * $emblemScale
    )
    $l2Path = Create-RoundedRectanglePath $l2Rect (10.0 * $emblemScale)
    $l2Brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#94A3B8'))
    $g.FillPath($l2Brush, $l2Path)
    $l2Brush.Dispose()
    $l2Path.Dispose()

    # Text Line 3: x=344, y=674, w=220, h=20
    $l3Rect = New-Object System.Drawing.RectangleF(
        (344.0 * $emblemScale) + $offsetX,
        (674.0 * $emblemScale) + $offsetY,
        220.0 * $emblemScale,
        20.0 * $emblemScale
    )
    $l3Path = Create-RoundedRectanglePath $l3Rect (10.0 * $emblemScale)
    $l3Brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#CBD5E1'))
    $g.FillPath($l3Brush, $l3Path)
    $l3Brush.Dispose()
    $l3Path.Dispose()

    # Bright-Blue Tag Dot: x=650, y=684, r=14
    $dotBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#2563EB'))
    $g.FillEllipse($dotBrush, [float]((640.0 * $emblemScale) + $offsetX), [float]((670.0 * $emblemScale) + $offsetY), [float](28.0 * $emblemScale), [float](28.0 * $emblemScale))
    $dotBrush.Dispose()
    $blueBrush.Dispose()

    # Ensure parent dir exists
    $outDir = [System.IO.Path]::GetDirectoryName($outputPath)
    if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bitmap.Dispose()
}

Write-Output "Generator script loaded."
