# Режет высокий скриншот на фрагменты: crop.ps1 -Src file.png -Tile 1100 [-Width 1440]
# Сохраняет рядом: file-01.png, file-02.png ... Пустой хвост (однотонный) отбрасывается.
param([string]$Src, [int]$Tile = 1100, [int]$Width = 0)
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Bitmap]::FromFile((Resolve-Path $Src))
$w = if ($Width -gt 0) { [Math]::Min($Width, $img.Width) } else { $img.Width }
# Найти последнюю непустую строку (отличную от цвета нижнего пикселя)
$bg = $img.GetPixel(5, $img.Height - 1)
$last = $img.Height - 1
for ($y = $img.Height - 1; $y -gt 0; $y -= 4) {
  $diff = $false
  for ($x = 0; $x -lt $w; $x += 24) { if ($img.GetPixel($x, $y) -ne $bg) { $diff = $true; break } }
  if ($diff) { $last = $y; break }
}
$h = [Math]::Min($img.Height, $last + 40)
$base = [IO.Path]::Combine([IO.Path]::GetDirectoryName((Resolve-Path $Src)), [IO.Path]::GetFileNameWithoutExtension($Src))
$i = 1
for ($top = 0; $top -lt $h; $top += $Tile) {
  $th = [Math]::Min($Tile, $h - $top)
  $rect = New-Object System.Drawing.Rectangle 0, $top, $w, $th
  $part = $img.Clone($rect, $img.PixelFormat)
  $out = "{0}-{1:D2}.png" -f $base, $i
  $part.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
  $part.Dispose()
  Write-Output $out
  $i++
}
$img.Dispose()
