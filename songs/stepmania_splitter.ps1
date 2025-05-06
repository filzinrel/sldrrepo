param(
    [string]$RootPath = "."
)

# Find every .sm under the root
Get-ChildItem -Path $RootPath -Filter *.sm -Recurse -File | ForEach-Object {
    $file      = $_
    $baseName  = [IO.Path]::GetFileNameWithoutExtension($file.Name)
    $dir       = $file.DirectoryName

    Write-Host "Processing $($file.FullName)"

    # Read all lines
    $lines = Get-Content -Path $file.FullName -Encoding UTF8
    $total = $lines.Count

    # 1) Locate the first #NOTES: line
    $headerEnd = -1
    for ($i = 0; $i -lt $total; $i++) {
        if ($lines[$i] -match '^\s*#NOTES:') {
            $headerEnd = $i
            break
        }
    }

    if ($headerEnd -lt 0) {
        Write-Warning "  → No #NOTES: found, skipping."
        return
    }

    # 2) Write header file
    $headerLines = $lines[0..($headerEnd - 1)]
    $smhPath     = Join-Path $dir "$baseName.smh"
    $headerLines | Set-Content -Path $smhPath -Encoding UTF8
    Write-Host "  → Header saved to $smhPath"

    # 3) Extract each NOTES block
    $idx = $headerEnd
    while ($idx -lt $total) {
        # Start of a block?
        if ($lines[$idx] -match '^\s*#NOTES:') {
            $block = [System.Collections.Generic.List[string]]::new()
            $j = $idx

            # Collect until the lone semicolon
            while ($j -lt $total) {
                $block.Add($lines[$j])
                if ($lines[$j].Trim() -eq ';') {
                    break
                }
                $j++
            }

            # Determine difficulty: 4th line after #NOTES:
            if ($block.Count -ge 4) {
                $diffLine   = $block[3].Trim()
                $difficulty = $diffLine.TrimEnd(':')
            }
            else {
                $difficulty = "Unknown"
            }

            # Write out .smt file
            $smtPath = Join-Path $dir "$baseName-$difficulty.smt"
            $block | Set-Content -Path $smtPath -Encoding UTF8
            Write-Host "  → Notes block [$difficulty] → $smtPath"

            # Advance past this block
            $idx = $j + 1
        }
        else {
            $idx++
        }
    }
}
