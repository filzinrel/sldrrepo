<#
.SYNOPSIS
  Remove URL-unsafe characters from file and directory names under a given root.

.DESCRIPTION
  - First renames files (so folders remain reachable).
  - Then renames directories from deepest to shallowest.
  - Strips out **any** character not in `[A–Za–z0–9._-]` (i.e. removes spaces, apostrophes, tildes, punctuation, etc.).
.PARAMETER Root
  The root folder under which to clean names. Defaults to the current directory.
#>
param(
    [string]$Root = "."
)

# Regex matching any URL-unsafe character (we allow only letters, digits, dot, underscore, dash)
$unsafePattern = '[^A-Za-z0-9._-]'

Write-Host "Cleaning FILE names under '$Root'..."
Get-ChildItem -Path $Root -Recurse -File |
  Where-Object { $_.Name -match $unsafePattern } |
  ForEach-Object {
    $oldPath = $_.FullName
    $newName = ($_.Name) -replace $unsafePattern, ''
    $newPath = Join-Path $_.DirectoryName $newName

    if (-not (Test-Path $newPath)) {
        Write-Host "Renaming file:"
        Write-Host "  $oldPath"
        Write-Host "→ $newPath"
        Rename-Item -LiteralPath $oldPath -NewName $newName
    }
    else {
        Write-Warning "Skipping (target exists): $newPath"
    }
  }

Write-Host "Cleaning DIRECTORY names under '$Root'..."
Get-ChildItem -Path $Root -Recurse -Directory |
  # sort by depth so children rename before parents
  Sort-Object { $_.FullName.Split([IO.Path]::DirectorySeparatorChar).Count } -Descending |
  Where-Object { $_.Name -match $unsafePattern } |
  ForEach-Object {
    $oldPath = $_.FullName
    $parent  = $_.Parent.FullName
    $newName = ($_.Name) -replace $unsafePattern, ''
    $newPath = Join-Path $parent $newName

    if (-not (Test-Path $newPath)) {
        Write-Host "Renaming directory:"
        Write-Host "  $oldPath"
        Write-Host "→ $newPath"
        Rename-Item -LiteralPath $oldPath -NewName $newName
    }
    else {
        Write-Warning "Skipping (target exists): $newPath"
    }
  }

Write-Host "Done. All URL-unsafe chars removed."
