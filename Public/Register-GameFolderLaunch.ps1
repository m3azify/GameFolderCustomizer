function Register-GameFolderLaunch {
    <#
    .SYNOPSIS
        Registers (or unregisters) the shell verb that launches a game when its
        customized folder is double-clicked.

    .DESCRIPTION
        Creates a per-user ProgID with CanUseForDirectory and a default "Launch
        Game" verb. Folders opt in via DirectoryClass=<ProgID> in their
        desktop.ini, so ordinary folders are unaffected.

        Writes to HKCU\Software\Classes (no administrator rights required).

    .PARAMETER Unregister
        Remove the ProgID registration.

    .EXAMPLE
        Register-GameFolderLaunch
        Register-GameFolderLaunch -Unregister
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Unregister
    )

    $progId = 'GameFolderCustomizer.GameFolder'
    $key = "HKCU:\Software\Classes\$progId"

    if ($Unregister) {
        if ($PSCmdlet.ShouldProcess($progId, 'Unregister Launch Game shell verb')) {
            if (Test-Path -LiteralPath $key) {
                Remove-Item -LiteralPath $key -Recurse -Force
                Write-Log "Unregistered shell verb ProgID: $progId" -Level 'Success'
            }
            else {
                Write-Log "ProgID $progId was not registered" -Level 'Info'
            }
        }
        return
    }

    $vbsPath = Join-Path $script:ModuleRoot 'Scripts\Launch-Game.vbs'
    if (-not (Test-Path -LiteralPath $vbsPath)) {
        Write-Log "Launcher not found: $vbsPath" -Level 'Error'
        return
    }

    if ($PSCmdlet.ShouldProcess($progId, 'Register Launch Game shell verb')) {
        try {
            if (-not (Test-Path -LiteralPath $key)) {
                New-Item -Path $key -Force | Out-Null
            }
            Set-ItemProperty -LiteralPath $key -Name '(default)' -Value 'Game Folder' -Force
            New-ItemProperty -LiteralPath $key -Name 'CanUseForDirectory' -PropertyType String -Value '' -Force | Out-Null

            $shellKey = Join-Path $key 'Shell'
            if (-not (Test-Path -LiteralPath $shellKey)) {
                New-Item -Path $shellKey -Force | Out-Null
            }
            # Default verb -> double-click launches the game
            Set-ItemProperty -LiteralPath $shellKey -Name '(default)' -Value 'LaunchGame' -Force

            $verbKey = Join-Path $shellKey 'LaunchGame'
            if (-not (Test-Path -LiteralPath $verbKey)) {
                New-Item -Path $verbKey -Force | Out-Null
            }
            Set-ItemProperty -LiteralPath $verbKey -Name '(default)' -Value 'Launch Game' -Force

            $commandKey = Join-Path $verbKey 'command'
            if (-not (Test-Path -LiteralPath $commandKey)) {
                New-Item -Path $commandKey -Force | Out-Null
            }
            $command = 'wscript.exe "' + $vbsPath + '" "%1"'
            Set-ItemProperty -LiteralPath $commandKey -Name '(default)' -Value $command -Force

            Write-Log "Registered shell verb ProgID: $progId" -Level 'Success'
            Write-Log "  Command: $command" -Level 'Debug'
        }
        catch {
            Write-Log "Failed to register shell verb: $($_.Exception.Message)" -Level 'Error'
        }
    }
}
