
Add-Type -AssemblyName System.Drawing
$out = 'E:\developpement\Phytia\_data\icons'
New-Item -ItemType Directory -Force -Path $out | Out-Null

function New-Icon([int]$size, [string]$path) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::FromArgb(255, 23, 86, 56))
  $s = $size / 1024.0

  $b  = New-Object System.Drawing.PointF((300 * $s), (760 * $s))
  $t  = New-Object System.Drawing.PointF((720 * $s), (300 * $s))
  $c1 = New-Object System.Drawing.PointF((573 * $s), (757 * $s))
  $c2 = New-Object System.Drawing.PointF((741 * $s), (573 * $s))
  $c3 = New-Object System.Drawing.PointF((447 * $s), (303 * $s))
  $c4 = New-Object System.Drawing.PointF((279 * $s), (487 * $s))

  $leaf = New-Object System.Drawing.Drawing2D.GraphicsPath
  $leaf.AddBezier($b, $c1, $c2, $t)
  $leaf.AddBezier($t, $c3, $c4, $b)
  $leaf.CloseFigure()
  $g.FillPath([System.Drawing.Brushes]::White, $leaf)

  if ($size -ge 72) {
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 23, 86, 56), [float](16 * $s))
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($pen, $b, $t)
    $pen.Dispose()
  }

  $g.Dispose()
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

New-Icon 1024 (Join-Path $out 'icon-1024.png')
New-Icon 256  (Join-Path $out 'icon-256.png')
New-Icon 192  (Join-Path $out 'icon-192.png')
New-Icon 144  (Join-Path $out 'icon-144.png')
New-Icon 96   (Join-Path $out 'icon-96.png')
New-Icon 72   (Join-Path $out 'icon-72.png')
New-Icon 48   (Join-Path $out 'icon-48.png')

$png = [System.IO.File]::ReadAllBytes((Join-Path $out 'icon-256.png'))
$ms = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($ms)
$bw.Write([UInt16]0); $bw.Write([UInt16]1); $bw.Write([UInt16]1)
$bw.Write([Byte]0); $bw.Write([Byte]0); $bw.Write([Byte]0); $bw.Write([Byte]0)
$bw.Write([UInt16]1); $bw.Write([UInt16]32)
$bw.Write([UInt32]$png.Length); $bw.Write([UInt32]22)
$bw.Write($png)
$bw.Flush()
[System.IO.File]::WriteAllBytes((Join-Path $out 'app_icon.ico'), $ms.ToArray())
$bw.Dispose(); $ms.Dispose()
Get-ChildItem $out | Select-Object Name, Length | Format-Table -AutoSize
