function Invoke-GameFolderCustomizer {
    <#
    .SYNOPSIS
        Customizes game folders on a drive with blank names and custom icons.
    .DESCRIPTION
        Processes folders on a drive, identifies game icons from executable files,
        shortcuts, or icon files, and applies customizations via desktop.ini.
    .PARAMETER DriveLetter
        The drive letter to process (default: D:)
    .PARAMETER IconSourcePreference
        Icon source preference: All, ExeOnly, ShortcutOnly, IconOnly
    .PARAMETER MaxIconSearchDepth
        Maximum recursion depth for icon search (default: 3)
    .PARAMETER ExcludeFolders
        Additional folders to exclude
    .PARAMETER ForceRefresh
        Force shell icon cache refresh
    .PARAMETER NonInteractive
        Skip interactive prompts
    .PARAMETER BlankNameMethod
        Method for blank names: DesktopIni, Rename, or Both
    .PARAMETER LaunchOnDoubleClick
        Make double-clicking a customized folder launch its game. Middle-click
        still opens the folder in a new tab.
    .PARAMETER MinimumIconScore
        Reject icon candidates scoring below this value. Used by the logon task
        to avoid customizing folders that are not clearly games.
    .PARAMETER WhatIf
        Preview changes without applying
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$DriveLetter = 'D:',
        [ValidateSet('All', 'ExeOnly', 'ShortcutOnly', 'IconOnly')]
        [string]$IconSourcePreference = 'All',
        [int]$MaxIconSearchDepth = 3,
        [string[]]$ExcludeFolders = @(),
        [switch]$ForceRefresh,
        [switch]$NonInteractive,
        [ValidateSet('DesktopIni', 'Rename', 'Both')]
        [string]$BlankNameMethod = 'DesktopIni',
        [switch]$LaunchOnDoubleClick,
        [int]$MinimumIconScore = -1
    )

    Write-Log "=== Game Folder Customizer Started ===" -Level 'Info'
    Write-Log "Target drive: $DriveLetter" -Level 'Info'
    Write-Log "Icon source preference: $IconSourcePreference" -Level 'Info'
    Write-Log "Max search depth: $MaxIconSearchDepth" -Level 'Info'
    Write-Log "Blank name method: $BlankNameMethod" -Level 'Info'
    Write-Log "Launch on double-click: $LaunchOnDoubleClick" -Level 'Info'
    Write-Log "Minimum icon score: $MinimumIconScore" -Level 'Info'

    if ($LaunchOnDoubleClick) {
        Register-GameFolderLaunch
    }

    if (-not (Test-AdminRights)) {
        Write-Log "WARNING: Not running as Administrator. Some folders may be inaccessible." -Level 'Warning'
    }

    $gameFolders = Get-GameFolders -RootPath $DriveLetter -ExcludeFolders $ExcludeFolders

    if ($gameFolders.Count -eq 0) {
        Write-Log "No game folders found on $DriveLetter" -Level 'Warning'
        return
    }

    Write-Log "Found $($gameFolders.Count) folder(s) to process" -Level 'Info'

    $successCount = 0
    $skipCount = 0
    $errorCount = 0

    foreach ($folder in $gameFolders) {
        try {
            $iconPath = Find-GameIcon -FolderPath $folder.FullName -Preference $IconSourcePreference -MaxDepth $MaxIconSearchDepth -MinimumScore $MinimumIconScore

            if (-not $iconPath) {
                Write-Log "  No suitable icon found for $($folder.Name), skipping" -Level 'Warning'
                $skipCount++
                continue
            }

            $resolvedIcon = Resolve-IconPath -IconPath $iconPath
            Write-Log "  Found icon: $resolvedIcon" -Level 'Debug'

            # Determine the executable to launch on double-click
            $gameExe = ''
            if ($LaunchOnDoubleClick) {
                $candidate = $resolvedIcon
                if ($candidate -notmatch '\.exe$') {
                    $exePath = Find-GameIcon -FolderPath $folder.FullName -Preference ExeOnly -MaxDepth $MaxIconSearchDepth -MinimumScore $MinimumIconScore
                    if ($exePath) { $candidate = Resolve-IconPath -IconPath $exePath }
                }
                if ($candidate -match '\.exe$' -and (Test-Path -LiteralPath $candidate)) {
                    $gameExe = $candidate
                    Write-Log "  Launch target: $gameExe" -Level 'Debug'
                }
                else {
                    Write-Log "  No launchable exe for $($folder.Name); icon only" -Level 'Warning'
                }
            }

            $result = Create-DesktopIni -FolderPath $folder.FullName -IconResource $resolvedIcon -SkipInteractive:$NonInteractive -BlankNameMethod $BlankNameMethod -EnableLaunch:([bool]$gameExe) -GameExe $gameExe

            if ($result) { $successCount++ } else { $skipCount++ }
        }
        catch {
            $errMsg = $_.Exception.Message
            Write-Log "Error processing $($folder.Name): $errMsg" -Level 'Error'
            $errorCount++
        }
    }

    Write-Log "=== Summary ===" -Level 'Info'
    Write-Log "Processed: $($gameFolders.Count)" -Level 'Info'
    Write-Log "Successful: $successCount" -Level 'Success'
    Write-Log "Skipped (no icon): $skipCount" -Level 'Warning'
    Write-Log "Errors: $errorCount" -Level 'Error'

    Refresh-ShellIcons -Force

    Write-Log "Done. Changes may take a moment to appear in File Explorer." -Level 'Info'
}