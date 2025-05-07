<#
.SYNOPSIS
    Convert folder-of-folders of MP3s into indexed WAVs for Second Life.

.DESCRIPTION
    - Scans each subdirectory under $RootPath.
    - Converts *.mp3 → PCM WAV (44.1 kHz stereo) with FFmpeg.
    - Names outputs as "{ParentFolder}-{Index}.wav".
    - Deletes original MP3 after successful conversion.

.PARAMETER RootPath
    Root directory containing subfolders of MP3s. Defaults to the current folder.
#>
param(
    [string]$RootPath = "."
)

# 1) Verify FFmpeg presence
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "FFmpeg not found. Install from https://ffmpeg.org and add to PATH."
    exit 1
}

# 2) Enumerate each folder under RootPath
Get-ChildItem -Path $RootPath -Directory | ForEach-Object {    # recursive folder scan :contentReference[oaicite:6]{index=6}
    $folder = $_
    $parentName = Split-Path $folder.FullName -Leaf             # extract folder name :contentReference[oaicite:7]{index=7}

    # 3) Find all MP3 files inside this folder
    $mp3List = Get-ChildItem -Path $folder.FullName -Filter *.mp3  # file filtering :contentReference[oaicite:8]{index=8}
    if ($mp3List.Count -eq 0) { return }                           # skip if none

    $index = 1
    foreach ($mp3 in $mp3List) {
        # 4) Build output WAV path
        $wavName = "{0}-{1}.wav" -f $parentName, $index           # indexed naming :contentReference[oaicite:9]{index=9}
        $wavPath = Join-Path $folder.FullName $wavName

        Write-Host "Converting '$($mp3.Name)' → '$wavName'..."

        # 5) Run FFmpeg conversion
        #    - pcm_s16le = 16-bit PCM, -ar 44100 = 44.1kHz, -ac 2 = stereo
        $ffArgs = @(
            "-i",  "`"$($mp3.FullName)`"",
            "-acodec", "pcm_s16le",
            "-ar", "44100",
            "-ac", "2",
            "`"$wavPath`""
        )
        & ffmpeg $ffArgs 2>&1 | Write-Host                     # conversion :contentReference[oaicite:10]{index=10}

        # 6) Delete source if conversion succeeded
        if ($LASTEXITCODE -eq 0) {
            Remove-Item $mp3.FullName -Force                   # cleanup :contentReference[oaicite:11]{index=11}
            Write-Host "Deleted source: $($mp3.Name)"
        }
        else {
            Write-Warning "Conversion failed for $($mp3.Name); source retained."
        }

        $index++
    }
}
