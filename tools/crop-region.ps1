# Вырезает область из скриншота: crop-region.ps1 -Src file.png -Top 4800 -Height 900 -Label scale [-Left 0 -Width 0]
param([string]$Src, [int]$Top, [int]$Height = 900, [string]$Label = 'part', [int]$Left = 0, [int]$Width = 0)
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Bitmap]::FromFile((Resolve-Path $Src))
$w = if ($Width -gt 0) { $Width } else { $img.Width - $Left }
$h = [Math]::Min($Height, $img.Height - $Top)
$part = $img.Clone((New-Object System.Drawing.Rectangle $Left, $Top, $w, $h), $img.PixelFormat)
$out = [IO.Path]::Combine([IO.Path]::GetDirectoryName((Resolve-Path $Src)), [IO.Path]::GetFileNameWithoutExtension($Src) + "-$Label.png")
$part.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$part.Dispose(); $img.Dispose()
Write-Output $out
