param(
    [string]$RootPath = "."
)

# 1) Remove all existing .smh and .smt files
Write-Host "Cleaning up old .smh/.smt files..."
Get-ChildItem -Path $RootPath -Include *.smh,*.smt -Recurse -File |
  ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Host "  Deleted $($_.FullName)"
  }

# 2) Strip out any dance-double sections from .sm files
Write-Host "Removing all dance-double sections from .sm files..."
Get-ChildItem -Path $RootPath -Filter *.sm -Recurse -File |
  ForEach-Object {
    $file     = $_.FullName
    $lines    = Get-Content -Path $file -Encoding UTF8
    $outLines = New-Object System.Collections.Generic.List[string]
    $inDouble = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
      $line = $lines[$i]
      if ($line.Trim() -match '^#NOTES:\s*$') {
        # Peek one line ahead
        if ($i + 1 -lt $lines.Count -and $lines[$i + 1].Trim() -eq 'dance-double:') {
          $inDouble = $true
          continue
        }
      }
      if ($inDouble) {
        if ($line.Trim() -eq ';') {
          # end of that dance-double block
          $inDouble = $false
        }
        continue
      }
      $outLines.Add($line)
    }

    # Write back cleaned .sm
    $outLines | Set-Content -Path $file -Encoding UTF8
    Write-Host "  Cleaned doubles in $file"
  }

# 3) Split into .smh (header) and .smt (notes) files
Write-Host "Splitting .sm into .smh/.smt..."
Get-ChildItem -Path $RootPath -Filter *.sm -Recurse -File |
  ForEach-Object {
    $file     = $_
    $baseName = [IO.Path]::GetFileNameWithoutExtension($file.Name)
    $dir      = $file.DirectoryName
    $lines    = Get-Content -Path $file.FullName -Encoding UTF8
    $total    = $lines.Count

    # Find first #NOTES: line via a loop
    $headerEnd = -1
    for ($i = 0; $i -lt $total; $i++) {
      if ($lines[$i].Trim() -match '^#NOTES:') {
        $headerEnd = $i
        break
      }
    }
    if ($headerEnd -lt 0) {
      Write-Warning "  No #NOTES: in $($file.FullName); skipping."
      return
    }

    # Write header .smh
    $headerLines = $lines[0..($headerEnd - 1)]
    $smhPath     = Join-Path $dir "$baseName.smh"
    $headerLines | Set-Content -Path $smhPath -Encoding UTF8
    Write-Host "  Wrote header → $smhPath"

    # Extract each NOTES block into .smt
    $idx = $headerEnd
    while ($idx -lt $total) {
      if ($lines[$idx].Trim() -match '^#NOTES:') {
        $block = New-Object System.Collections.Generic.List[string]
        $j     = $idx
        do {
          $block.Add($lines[$j])
          $j++
        } while ($j -lt $total -and $lines[$j - 1].Trim() -ne ';')

        # Difficulty is on the 4th line of the block
        if ($block.Count -ge 4) {
          $difficulty = $block[3].Trim().TrimEnd(':')
        } else {
          $difficulty = "Unknown"
        }

        $smtPath = Join-Path $dir "$baseName-$difficulty.smt"
        $block    | Set-Content -Path $smtPath -Encoding UTF8
        Write-Host "    Notes [$difficulty] → $smtPath"

        $idx = $j
      } else {
        $idx++
      }
    }
  }

Write-Host "Done."
