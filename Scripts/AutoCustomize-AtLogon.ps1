<#
.SYNOPSIS
    Logon task: customize NEW game folders on a drive, skipping ones already set up.

.DESCRIPTION
    Intended to be launched from the Startup folder by Install-AutoRun.ps1.
    Scans the drive root, skips folders that are already customized (blank
    U+00A0 name or our DirectoryClass in desktop.ini), and applies the standard
    customization only to folders that are new.

    Runs non-interactively and writes a log to
    %LOCALAPPDATA%\GameFolderCustomizer\autorun.log.
#>
[CmdletBinding()]
param(
    [string]$DriveLetter = 'D:',

    [int]$StartupDelaySeconds = 15,

    [ValidateRange(-1, 1000)]
    [int]$MinimumIconScore = 50
)

$ErrorActionPreference = 'Continue'

$projectRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $projectRoot 'GameFolderCustomizer.psd1') -Force -ErrorAction Stop

$logDir = Join-Path $env:LOCALAPPDATA 'GameFolderCustomizer'
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$logFile = Join-Path $logDir 'autorun.log'

function Write-AutoLog {
    param([string]$Message)
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $logFile -Value $line -ErrorAction SilentlyContinue
}

if ($StartupDelaySeconds -gt 0) {
    Start-Sleep -Seconds $StartupDelaySeconds
}

Write-AutoLog "=== Logon auto-customize started (drive $DriveLetter) ==="

try {
    $allFolders = @(Get-GameFolders -RootPath $DriveLetter)

    if ($allFolders.Count -eq 0) {
        Write-AutoLog "No folders found on $DriveLetter. Nothing to do."
        return
    }

    $excluded = @()
    $newFolders = @()
    foreach ($folder in $allFolders) {
        if (Test-IsFolderCustomized -FolderPath $folder.FullName) {
            $excluded += $folder.Name
        }
        else {
            $newFolders += $folder.Name
        }
    }

    Write-AutoLog "Folders found: $($allFolders.Count); already customized: $($excluded.Count); new: $($newFolders.Count)"

    if ($newFolders.Count -eq 0) {
        Write-AutoLog "No new folders to customize. Exiting."
        return
    }

    Write-AutoLog "New folders: $($newFolders -join ', ')"

    Invoke-GameFolderCustomizer `
        -DriveLetter $DriveLetter `
        -NonInteractive `
        -BlankNameMethod Rename `
        -LaunchOnDoubleClick `
        -MinimumIconScore $MinimumIconScore `
        -ExcludeFolders $excluded

    Write-AutoLog "Customization run finished."
}
catch {
    Write-AutoLog "ERROR: $($_.Exception.Message)"
}
finally {
    Write-AutoLog "=== Logon auto-customize ended ==="
}
