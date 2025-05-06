<#
.SYNOPSIS
Generates a mapping file of top‐level directories to their corresponding GitHub raw URLs.

.DESCRIPTION
This script scans a given root directory for all immediate subdirectories and writes out lines of the form:
    <DirectoryName>|https://raw.githubusercontent.com/filzinrel/sldrrepo/refs/heads/main/songs/<DirectoryName>/
to the specified output text file.

.PARAMETER RootPath
The folder whose immediate subdirectories you want to list. Defaults to the current directory.

.PARAMETER OutputFile
The path of the text file to create (or overwrite) with the mappings. Defaults to "mapping.txt" in the current directory.

.EXAMPLE
.\Generate-Mapping.ps1 -RootPath "C:\Projects\songs" -OutputFile "C:\Projects\mapping.txt"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$RootPath = ".",

    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "mapping.txt"
)

# Ensure the root path exists
if (-not (Test-Path -Path $RootPath -PathType Container)) {
    Write-Error "Root path '$RootPath' does not exist or is not a directory."
    exit 1
}

# Gather all top‐level directories
$dirs = Get-ChildItem -Path $RootPath -Directory

# Build the mapping lines and write them out
$lines = foreach ($dir in $dirs) {
    $name = $dir.Name
    $url  = "https://raw.githubusercontent.com/filzinrel/sldrrepo/refs/heads/main/songs/$name/"
    "$name|$url"
}

# Output to file (overwriting if it exists)
$lines | Set-Content -Path $OutputFile -Encoding UTF8

Write-Host "Wrote $($lines.Count) entries to '$OutputFile'."
