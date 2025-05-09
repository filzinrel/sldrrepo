# Generate-SongIndex.ps1

param(
    # Path to the parent folder containing all song subdirectories
    [string]$SongsRoot = ".",
    # Output JSON file
    [string]$OutFile   = "songs.json"
)

# Difficulties in order
$difficulties = 'Beginner','Easy','Medium','Hard','Challenge'

# Collect all song entries
$songEntries = @()

# For each subdirectory
Get-ChildItem -Path $SongsRoot -Directory | ForEach-Object {
    $dir = $_.FullName

    # Find the .smh file
    $smh = Get-ChildItem -Path $dir -Filter '*.smh' | Select-Object -First 1
    if (-not $smh) { return }  # skip if none

    # Read header lines
    $lines = Get-Content $smh.FullName

    # Helper to extract header value
        # Helper to extract header value
    function Get-HeaderValue {
        param($key)

        # Option 1: string concatenation (simplest)
        $pattern = '^#' + $key + ':(.*?);'

        # Option 2: explicit ${} interpolation
        # $pattern = "^#${key}:(.*?);"

        # Find the first matching line and return the captured group
        $lines |
          Where-Object { $_ -match $pattern } |
          ForEach-Object { $Matches[1] } |
          Select-Object -First 1
    }


        # Parse required fields
    $title  = Get-HeaderValue 'TITLE'
    $artist = Get-HeaderValue 'ARTIST'

    # DISPLAYBPM: truncate at colon if present
    $bpmRaw = Get-HeaderValue 'DISPLAYBPM'
    if ($bpmRaw -like '*:*') {
      $bpmRaw = $bpmRaw.Split(':')[0]
    }
    $bpm = [double]$bpmRaw

    $banner = Get-HeaderValue 'BANNER'
    
    # Likewise for sample times
    $ssRaw     = Get-HeaderValue 'SAMPLESTART'
    $ssClean   = $ssRaw -replace ':','.'
    $sampleStart  = [double]$ssClean

    $slRaw     = Get-HeaderValue 'SAMPLELENGTH'
    $slClean   = $slRaw -replace ':','.'
    $sampleLength = [double]$slClean

    $music = Get-HeaderValue 'MUSIC'


    # Build difficulties array by testing for .smt files
    $songBase = [IO.Path]::GetFileNameWithoutExtension($smh.Name)
    $diffs = @()
    foreach ($d in $difficulties) {
        $smtPath = Join-Path $dir "$songBase-$d.smt"
        if (Test-Path $smtPath) {
            $diffs += $d
        }
    }

    # Assemble entry
    $songEntries += [PSCustomObject]@{
        name         = $title
        artist       = $artist
        bpm          = $bpm
        banner       = $banner
        sampleStart  = $sampleStart
        sampleLength = $sampleLength
        music        = $music
        difficulties = $diffs
    }
}

# Output JSON
$songEntries | ConvertTo-Json -Depth 3 | Set-Content -Path $OutFile -Encoding UTF8

Write-Host "Generated $OutFile with $($songEntries.Count) songs."
