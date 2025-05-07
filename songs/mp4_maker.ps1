<#
.SYNOPSIS
    Merges AVI videos with OGG audio into MP4s.

.DESCRIPTION
    1. Deletes all existing .mp4 files under the specified root directory.
    2. Recursively finds each .avi file and its matching .ogg audio (same basename).
    3. Invokes ffmpeg to mux them into .mp4 files by copying the video and encoding the audio to AAC.

.PARAMETER RootPath
    The root directory to scan. Defaults to the current directory.

.EXAMPLE
    .\Merge-AvOggToMp4.pl1 "C:\Media\MyVideos"
#>
param(
    [string]$RootPath = "."
)

# Ensure ffmpeg is on the PATH
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "FFmpeg not found in PATH. Please install FFmpeg and add it to your PATH."
    exit 1
}

# 1. Remove all existing .mp4 files under the root directory
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

# 2. Recursively find all .avi files and merge with corresponding .ogg
Get-ChildItem -Path $RootPath -Recurse -Filter *.avi -File | ForEach-Object {
    $video = $_.FullName
    $dir   = $_.DirectoryName
    $base  = $_.BaseName
    $audio = Join-Path $dir ("$base.ogg")
    $output= Join-Path $dir ("$base.mp4")

    if (Test-Path $audio) {
        Write-Host "Merging '$video' + '$audio' → '$output'"

        # Build FFmpeg arguments
        $args = @(
            "-i", "$video",
            "-i", "$audio",
            "-c:v", "copy",
            "-c:a", "aac",
            "-b:a", "192k",
            "-map", "0:v:0",
            "-map", "1:a:0",
            "$output"
        )

        # Execute FFmpeg
        & ffmpeg @args 2>&1 | ForEach-Object { Write-Host $_ }
    }
    else {
        Write-Warning "Skipping '$video': no matching '$base.ogg' found"
    }
}
