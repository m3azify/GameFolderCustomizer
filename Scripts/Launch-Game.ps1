<#
.SYNOPSIS
    Launches the game associated with a customized folder.

.DESCRIPTION
    Invoked by the "Launch Game" shell verb registered via DirectoryClass in
    desktop.ini. Reads the GameExe value from the folder's desktop.ini and
    starts it with the correct working directory.

    If no game executable is configured, falls back to opening the folder in
    File Explorer so the folder is always reachable.

.PARAMETER FolderPath
    The folder that was double-clicked (passed as %1 by the shell).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$FolderPath
)

$ErrorActionPreference = 'SilentlyContinue'

function Write-LaunchLog {
    param([string]$Message)
    $logPath = Join-Path $PSScriptRoot 'launch-debug.log'
    if (Test-Path -LiteralPath $logPath) {
        Add-Content -LiteralPath $logPath -Value ("{0} {1}" -f (Get-Date -Format 'o'), $Message)
    }
}

Write-LaunchLog "Launch requested: [$FolderPath]"

function Open-Folder {
    param([string]$Path)
    Write-LaunchLog "Opening folder instead: [$Path]"
    Start-Process -FilePath explorer.exe -ArgumentList ('"' + $Path + '"')
}

$iniPath = Join-Path $FolderPath 'desktop.ini'
if (-not (Test-Path -LiteralPath $iniPath)) {
    Write-LaunchLog "No desktop.ini found"
    Open-Folder -Path $FolderPath
    return
}

$content = [System.IO.File]::ReadAllText($iniPath, [System.Text.Encoding]::Unicode)
if (-not $content) {
    Open-Folder -Path $FolderPath
    return
}

$exe = $null
if ($content -match '(?m)^GameExe=(.+)$') {
    $exe = $matches[1].Trim()
}

if ($exe -and (Test-Path -LiteralPath $exe)) {
    $workingDir = Split-Path -Path $exe -Parent
    Write-LaunchLog "Launching: [$exe] (cwd: [$workingDir])"
    Start-Process -FilePath $exe -WorkingDirectory $workingDir
}
else {
    Write-LaunchLog "No valid GameExe configured"
    Open-Folder -Path $FolderPath
}
