<#
.SYNOPSIS
    Recursively merge AVI+OGG or PNG+OGG into MP4s with H.264 baseline video.

.DESCRIPTION
    1. Deletes all existing .mp4 files under the specified root directory.
    2. Recursively finds each .avi/.ogg pair by basename; if AVI exists, merges video+audio.
    3. If AVI is missing but a PNG and OGG exist for that basename, creates a static‐image video.
    4. Regenerates timestamps so both streams start at 0, encodes video to H.264 (Baseline profile, yuv420p),
       audio to AAC at 192 kbps, and stops at the end of the shorter stream to keep AV in sync.

.PARAMETER RootPath
    The root directory to scan. Defaults to the current directory.

.EXAMPLE
    .\Merge-MediaToMp4.ps1 "C:\Media\Songs"
#>
param(
    [string]$RootPath = "."
)

# Ensure ffmpeg is available
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "FFmpeg not found in PATH. Please install FFmpeg and add it to your PATH."
    exit 1
}

# 1) Clean up existing MP4s
Write-Host "Cleaning up existing .mp4 files under '$RootPath'..."
Get-ChildItem -Path $RootPath -Recurse -Filter *.mp4 -File | ForEach-Object {
    try {
        Remove-Item -LiteralPath $_.FullName -Force
        Write-Host "Deleted: $($_.FullName)"
    }
    catch {
        Write-Warning "Failed to delete $($_.FullName): $_"
    }
}

# 2) Process each basename found via AVI or PNG
Get-ChildItem -Path $RootPath -Recurse -Include *.avi,*.png -File |
    Group-Object DirectoryName, BaseName |
    ForEach-Object {
        $dir  = $_.Group[0].DirectoryName
        $base = $_.Group[0].BaseName

        $avi    = Join-Path $dir ("$base.avi")
        $png    = Join-Path $dir ("$base-bg.png")
        $ogg    = Join-Path $dir ("$base.ogg")
        $output = Join-Path $dir ("$base.mp4")
        echo $avi
        echo $png
        echo $ogg

        if ((Test-Path $avi) -and (Test-Path $ogg)) {
            Write-Host "Merging video+audio → '$output'"

            $args = @(
                # regenerate PTS & avoid negative timestamps
                "-fflags", "+genpts",
                "-avoid_negative_ts", "make_zero",
                "-copyts", "-start_at_zero",
                # inputs
                "-i", "$avi",
                "-i", "$ogg",
                # encode video to H.264 Baseline + yuv420p, encode audio to AAC
                "-c:v", "libx264",
                "-profile:v", "baseline",
                "-level", "3.0",
                "-pix_fmt", "yuv420p",
                "-c:a", "aac", "-b:a", "192k",
                # explicit stream mapping
                "-map", "0:v:0",
                "-map", "1:a:0",
                # stop at the end of shorter stream
                "-shortest",
                # output
                "$output"
            )
            & ffmpeg @args 2>&1 | ForEach-Object { Write-Host $_ }
        }
        elseif (-not (Test-Path $avi) -and (Test-Path $png) -and (Test-Path $ogg)) {
            Write-Host "Creating static video from image+audio → '$output'"

            $args = @(
                # loop image, set low frame rate
                "-loop", "1",
                "-framerate", "2",
                "-i", "$png",
                "-i", "$ogg",
                # encode video to H.264 Baseline + yuv420p, encode audio to AAC
                "-c:v", "libx264",
                "-profile:v", "baseline",
                "-level", "3.0",
                "-pix_fmt", "yuv420p",
                "-tune", "stillimage",
                "-c:a", "aac", "-b:a", "192k",
                # explicit mapping
                "-map", "0:v:0",
                "-map", "1:a:0",
                # stop at end of shorter stream
                "-shortest",
                # output
                "$output"
            )
            & ffmpeg @args 2>&1 | ForEach-Object { Write-Host $_ }
        }
        else {
            Write-Warning "Skipping '$base' in '$dir': need either AVI+OGG or PNG+OGG."
        }
        }