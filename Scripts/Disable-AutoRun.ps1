<#
.SYNOPSIS
    Removes the per-user logon task installed by Install-AutoRun.ps1.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param()

$startupFolder = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startupFolder 'GameFolderCustomizer.lnk'

if (-not (Test-Path -LiteralPath $shortcutPath)) {
    Write-Host "Logon task was not installed: $shortcutPath" -ForegroundColor Yellow
    return
}

if ($PSCmdlet.ShouldProcess($shortcutPath, 'Remove logon shortcut')) {
    try {
        Remove-Item -LiteralPath $shortcutPath -Force
        Write-Host "Removed logon task: $shortcutPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to remove logon task: $($_.Exception.Message)" -ForegroundColor Red
    }
}
