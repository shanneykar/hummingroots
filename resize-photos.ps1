<#
    resize-photos.ps1  (v2)
    Crops and resizes the six chapter photographs to 900x1125 (4:5) JPEG.

    Uses only .NET, so nothing needs installing. Windows PowerShell 5.1 or
    PowerShell 7 on Windows.

    USAGE
      1. Put your images in photos\raw\ named to match the targets:
           01-reading   02-money   03-person
           04-protection   05-sickness   06-apothecary
         Any extension (.png .jpg .jpeg .webp .bmp .tif).
      2. From the repo root:
           .\resize-photos.ps1
      3. Check photos\, then delete photos\raw\ before committing.

    Re-encoding drops all EXIF, so phone GPS and generator metadata never
    reach the live site.

    v2 fix: GDI+ resolves relative paths against the .NET process directory,
    not PowerShell's location, which produced "A generic error occurred in
    GDI+" on save. Paths are now absolute, and the JPEG is encoded to memory
    and written with File.WriteAllBytes so GDI+ never touches the filesystem.
#>

[CmdletBinding()]
param(
    [string]$Source      = "photos\raw",
    [string]$Destination = "photos",
    [int]$Width          = 900,
    [int]$Height         = 1125,
    [int]$Quality        = 82
)

Add-Type -AssemblyName System.Drawing

# --- resolve everything to absolute paths up front ----------------------
$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
[System.Environment]::CurrentDirectory = $root

function Resolve-Abs([string]$p) {
    if ([System.IO.Path]::IsPathRooted($p)) { return [System.IO.Path]::GetFullPath($p) }
    return [System.IO.Path]::GetFullPath((Join-Path $root $p))
}

$srcDir = Resolve-Abs $Source
$dstDir = Resolve-Abs $Destination

Write-Host "  source      $srcDir"
Write-Host "  destination $dstDir"
Write-Host ""

if (-not (Test-Path -LiteralPath $srcDir)) {
    Write-Error "No folder at '$srcDir'. Create it and put your images inside."
    return
}
if (-not (Test-Path -LiteralPath $dstDir)) {
    New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
}

# --- JPEG encoder -------------------------------------------------------
$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
         Where-Object { $_.MimeType -eq 'image/jpeg' }
if (-not $codec) { Write-Error "No JPEG encoder available."; return }

$encParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
                          [System.Drawing.Imaging.Encoder]::Quality, [int64]$Quality)

$files = Get-ChildItem -LiteralPath $srcDir -File |
         Where-Object { $_.Extension -match '^\.(png|jpe?g|webp|bmp|tiff?)$' }

if (-not $files -or @($files).Count -eq 0) {
    Write-Warning "Nothing to process in '$srcDir'."
    return
}

$done = 0; $failed = 0

foreach ($file in $files) {
    $src = $null; $canvas = $null; $g = $null; $inStream = $null; $outStream = $null
    $outPath = [System.IO.Path]::Combine($dstDir, $file.BaseName + '.jpg')

    if ($outPath -eq $file.FullName) {
        Write-Warning "  $($file.Name) skipped: source and destination are the same file."
        $failed++
        continue
    }

    try {
        # read fully into memory so the source file is never left locked
        $bytes    = [System.IO.File]::ReadAllBytes($file.FullName)
        $inStream = New-Object System.IO.MemoryStream(,$bytes)
        $src      = [System.Drawing.Image]::FromStream($inStream)

        $ow = $src.Width; $oh = $src.Height

        # honour the camera rotation flag, then let it be discarded
        if ($src.PropertyIdList -contains 274) {
            switch ($src.GetPropertyItem(274).Value[0]) {
                3 { $src.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
                6 { $src.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone)  }
                8 { $src.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
            }
        }

        # scale to COVER the target, then centre-crop the overflow
        $scale = [Math]::Max($Width / $src.Width, $Height / $src.Height)
        $w = [int][Math]::Round($src.Width  * $scale)
        $h = [int][Math]::Round($src.Height * $scale)
        $x = [int][Math]::Round(($Width  - $w) / 2)
        $y = [int][Math]::Round(($Height - $h) / 2)

        $canvas = New-Object System.Drawing.Bitmap($Width, $Height,
                      [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $canvas.SetResolution(72, 72)

        $g = [System.Drawing.Graphics]::FromImage($canvas)
        $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $g.Clear([System.Drawing.Color]::White)
        $g.DrawImage($src, $x, $y, $w, $h)
        $g.Dispose(); $g = $null

        # encode to memory, then write the bytes ourselves -- GDI+ never sees a path
        $outStream = New-Object System.IO.MemoryStream
        $canvas.Save($outStream, $codec, $encParams)
        [System.IO.File]::WriteAllBytes($outPath, $outStream.ToArray())

        $kb = [Math]::Round((Get-Item -LiteralPath $outPath).Length / 1KB)
        Write-Host ("  {0,-22} {1}x{2}  ->  {3}x{4}   {5} KB" -f `
                    $file.Name, $ow, $oh, $Width, $Height, $kb)
        if ($kb -gt 150) { Write-Warning "    over 150 KB - rerun with -Quality 75" }
        $done++
    }
    catch {
        $failed++
        Write-Warning "  $($file.Name) failed: $($_.Exception.Message)"
        if ($_.Exception.InnerException) {
            Write-Warning "    inner: $($_.Exception.InnerException.Message)"
        }
    }
    finally {
        if ($g)         { $g.Dispose() }
        if ($canvas)    { $canvas.Dispose() }
        if ($src)       { $src.Dispose() }
        if ($inStream)  { $inStream.Dispose() }
        if ($outStream) { $outStream.Dispose() }
    }
}

Write-Host ""
if ($failed -eq 0) {
    Write-Host "$done image(s) written to $dstDir" -ForegroundColor Green
    Write-Host "Check them, then delete photos\raw\ before committing." -ForegroundColor Green
} else {
    Write-Host "$done written, $failed failed." -ForegroundColor Yellow
}
