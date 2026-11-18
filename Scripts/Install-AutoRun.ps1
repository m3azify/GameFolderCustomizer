<#
.SYNOPSIS
    Installs a per-user logon task that auto-customizes new game folders.

.DESCRIPTION
    Creates a shortcut in the user's Startup folder that runs
    AutoCustomize-AtLogon.ps1 hidden at every logon. No administrator rights
    are required, and nothing is written outside the current user profile.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param()

$projectRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $projectRoot 'Scripts\AutoCustomize-AtLogon.ps1'
if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "AutoCustomize-AtLogon.ps1 not found at $scriptPath"
}

$startupFolder = [Environment]::GetFolderPath('Startup')
if (-not (Test-Path -LiteralPath $startupFolder)) {
    throw "Startup folder not found: $startupFolder"
}

$shortcutPath = Join-Path $startupFolder 'GameFolderCustomizer.lnk'
$powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$arguments = '-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $scriptPath + '"'

if ($PSCmdlet.ShouldProcess($shortcutPath, 'Create logon shortcut')) {
    try {
        $ws = New-Object -ComObject WScript.Shell
        $shortcut = $ws.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $powershell
        $shortcut.Arguments = $arguments
        $shortcut.WorkingDirectory = $projectRoot
        $shortcut.Description = 'GameFolderCustomizer - customize new game folders at logon'
        $shortcut.Save()

        Write-Host "Installed logon task: $shortcutPath" -ForegroundColor Green
        Write-Host "  Runs: $powershell" -ForegroundColor Gray
        Write-Host "  Args: $arguments" -ForegroundColor Gray
    }
    catch {
        Write-Host "Failed to install logon task: $($_.Exception.Message)" -ForegroundColor Red
    }
}
