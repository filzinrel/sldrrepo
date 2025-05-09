<#
.SYNOPSIS
  Removes the initial `#NOTES:` preamble block from all `.smt` files.

.DESCRIPTION
  Finds each `.smt` file, then deletes every line from the one starting with `#NOTES:` 
  down through the last consecutive “field:” line (i.e. lines ending in a colon),
  leaving the actual measure data intact.
.PARAMETER Root
  The root folder under which to recurse. Defaults to the current directory.
#>
param(
  [string]$Root = "."
)

# Get all .smt files under $Root
Get-ChildItem -Path $Root -Recurse -Filter '*.smt' | ForEach-Object {
  $file = $_.FullName
  $lines = Get-Content $file

  # Find the index of the "#NOTES:" line
  $start = $null
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*#NOTES:') {
      $start = $i
      break
    }
  }

  if ($start -ne $null) {
    # Find the end index: first line after $start that does NOT end with a colon
    $end = $start + 1
    while ($end -lt $lines.Count -and $lines[$end] -match ':\s*$') {
      $end++
    }

    # Build the new content:
    #  - Keep everything before $start
    #  - Then everything from $end onward
    $prefix = if ($start -gt 0) { $lines[0..($start-1)] } else { @() }
    $suffix = if ($end -lt $lines.Count) { $lines[$end..($lines.Count-1)] } else { @() }
    $new    = $prefix + $suffix

    # Overwrite the file if anything changed
    if ($new.Count -lt $lines.Count) {
      Write-Host "Stripping preamble from:" $file
      Set-Content -LiteralPath $file -Value $new
    }
  }
}

Write-Host "Done."
