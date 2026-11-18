function Remove-GameFolderCustomization {
    <#
    .SYNOPSIS
        Removes desktop.ini files from game folders.
    .DESCRIPTION
        Reverts game folder customizations by removing desktop.ini files.
        Note: Does NOT restore renamed folders (Rename method).
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$DriveLetter = 'D:',
        [string[]]$ExcludeFolders = @(),

        [switch]$UnregisterVerb
    )

    if ($UnregisterVerb) {
        Register-GameFolderLaunch -Unregister
    }

    Write-Log "Reverting customizations on $DriveLetter..." -Level 'Info'

    $folders = Get-GameFolders -RootPath $DriveLetter -ExcludeFolders $ExcludeFolders

    $count = 0
    foreach ($folder in $folders) {
        $ini = Join-Path $folder.FullName 'desktop.ini'
        if (Test-Path $ini) {
            if ($PSCmdlet.ShouldProcess($folder.FullName, "Remove desktop.ini")) {
                try {
                    $item = Get-Item $ini -Force
                    $item.Attributes = 'Normal'
                    Remove-Item $ini -Force
                    Write-Log "Removed: $($folder.Name)" -Level 'Success'
                    $count++
                }
                catch {
                    $errMsg = $_.Exception.Message
                    Write-Log "Failed: $($folder.Name) - $errMsg" -Level 'Error'
                }
            }
        }
    }

    Write-Log "Reverted $count folder(s). Run 'ie4uinit.exe -show' to refresh." -Level 'Info'
    Write-Log "NOTE: Renamed folders (Rename/Both method) are NOT restored. Manual rename needed." -Level 'Warning'
}

# Alias for backward compatibility
try {
    Set-Alias -Name 'Revert-GameFolderCustomization' -Value 'Remove-GameFolderCustomization' -Scope Global -ErrorAction SilentlyContinue -WhatIf:$false
}
catch {
    # Silently ignore alias creation failures (e.g., during WhatIf)
}