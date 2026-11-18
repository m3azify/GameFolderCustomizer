function Create-DesktopIni {
    <#
    .SYNOPSIS
        Creates or updates desktop.ini in a folder with custom icon and blank name.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,

        [Parameter(Mandatory = $true)]
        [string]$IconResource,

        [string[]]$BlankNameResources = @(),

        [switch]$SkipInteractive = $false,

        [ValidateSet('DesktopIni', 'Rename', 'Both')]
        [string]$BlankNameMethod = 'DesktopIni',

        [switch]$EnableLaunch,

        [string]$GameExe = ''
    )

    $folderName = Split-Path $FolderPath -Leaf
    $parentPath = Split-Path $FolderPath -Parent
    $originalPath = $FolderPath

    # Set the System attribute on the folder BEFORE renaming. After a rename to
    # U+00A0, any path ending in that character resolves to the parent drive
    # (Windows trims trailing space-like characters), so the folder cannot be
    # reliably located by path afterwards. Renaming preserves attributes.
    try {
        $preFolderItem = Resolve-GameFolderItem -FolderPath $FolderPath
        if ($preFolderItem -and -not $preFolderItem.Attributes.HasFlag([IO.FileAttributes]::System)) {
            $preFolderItem.Attributes = $preFolderItem.Attributes -bor [IO.FileAttributes]::System
        }
    }
    catch {
        Write-Log "Could not pre-set System attribute on folder: $($_.Exception.Message)" -Level 'Warning'
    }

    # Handle Rename method (U+00A0 non-breaking space, repeated if needed so
    # multiple folders on the same drive can each have a blank-looking name)
    $renameSuccess = $false
    if ($BlankNameMethod -in @('Rename', 'Both')) {
        # If this folder is already blank-named, keep its current name
        $isBlankNamed = ($folderName -replace ([char]0x00A0), '').Length -eq 0
        if ($isBlankNamed) {
            Write-Log "Folder already has a blank name" -Level 'Info'
            $newName = $folderName
            $newPath = $FolderPath
            $renameSuccess = $true
        }
        else {
            $newName = Get-BlankFolderName -ParentPath $parentPath
            if (-not $newName) {
                Write-Log "No unused blank folder name available in $parentPath" -Level 'Error'
                return $false
            }
            $newPath = Join-Path $parentPath $newName

            if ($PSCmdlet.ShouldProcess($FolderPath, "Rename folder to blank name (U+00A0 x$($newName.Length))")) {
                try {
                    # Use .NET MoveTo directly - avoids Invoke-Expression / cmd.exe
                    # string parsing, which is an injection risk for unusual folder names.
                    $dirInfo = Get-Item -LiteralPath $FolderPath -Force
                    $dirInfo.MoveTo($newPath)
                    Write-Log "Renamed folder to blank name (U+00A0 x$($newName.Length)) via .NET" -Level 'Success'
                    $FolderPath = $newPath
                    $folderName = $newName
                    $renameSuccess = $true
                }
                catch {
                    $errMsg = $_.Exception.Message
                    Write-Log "Failed to rename folder: $errMsg" -Level 'Error'
                    if ($BlankNameMethod -eq 'Rename') {
                        return $false
                    }
                    Write-Log "Falling back to DesktopIni method..." -Level 'Warning'
                }
            }
        }
    }

    # Determine if desktop.ini should be created
    $doDesktopIni = $BlankNameMethod -in @('DesktopIni', 'Both') -or ($BlankNameMethod -eq 'Rename' -and $renameSuccess)
    if (-not $doDesktopIni) { return $false }

    $desktopIniPath = Join-Path $FolderPath 'desktop.ini'
    $resourcesToTry = if ($BlankNameMethod -eq 'Rename') { @('') } else { $BlankNameResources }

    # The icon path was discovered before the rename, so it still references the
    # OLD folder name. Rewrite it to point at the renamed folder, otherwise the
    # icon cannot be found and Explorer falls back to the default folder icon.
    $effectiveIcon = Get-RenamedIconPath -IconResource $IconResource -OriginalPath $originalPath -NewPath $FolderPath -WasRenamed:$renameSuccess

    # The launch executable also needs its pre-rename path rewritten
    $effectiveGameExe = ''
    if ($EnableLaunch -and $GameExe) {
        $effectiveGameExe = Get-RenamedIconPath -IconResource $GameExe -OriginalPath $originalPath -NewPath $FolderPath -WasRenamed:$renameSuccess
    }

    foreach ($resource in $resourcesToTry) {
        $iniContent = @(
            '[.ShellClassInfo]',
            "IconFile=$effectiveIcon",
            'IconIndex=0'
        )
        if ($resource) {
            $iniContent += "LocalizedResourceName=$resource"
        }
        if ($effectiveGameExe) {
            # DirectoryClass opts this folder into the custom "Launch Game" verb.
            # Normal folders are unaffected because registration is per-folder.
            $iniContent += 'DirectoryClass=GameFolderCustomizer.GameFolder'
        }
        $iniContent += 'ConfirmFileOp=0'
        $iniContent += 'NoSharing=1'

        if ($effectiveGameExe) {
            $iniContent += ''
            $iniContent += '[GameFolderCustomizer]'
            $iniContent += "GameExe=$effectiveGameExe"
        }

        $iniString = $iniContent -join "`r`n"

        if ($PSCmdlet.ShouldProcess($FolderPath, "Create/Update desktop.ini with custom icon")) {
            try {
                if (Test-Path $desktopIniPath) {
                    $item = Get-Item $desktopIniPath -Force
                    $item.Attributes = 'Normal'
                }
                [System.IO.File]::WriteAllText($desktopIniPath, $iniString, [System.Text.Encoding]::Unicode)

                $item = Get-Item $desktopIniPath -Force
                $item.Attributes = 'Hidden', 'System'

                Write-Log "Applied desktop.ini to: $FolderPath" -Level 'Success'

                # Shell refresh is performed once by the caller, not per folder.

                if ($SkipInteractive) {
                    Write-Log "Skipping interactive verification" -Level 'Info'
                    return $true
                }

                # Interactive verification
                Write-Host ""
                Write-Host "FOLDER: $folderName" -ForegroundColor Yellow
                Write-Host "RESOURCE: $resource" -ForegroundColor Gray
                Write-Host "METHOD: $BlankNameMethod" -ForegroundColor Gray
                Write-Host ""
                Write-Host "Does the folder name appear BLANK (empty)?" -ForegroundColor Cyan
                Write-Host "[Y] Yes - keep this resource" -ForegroundColor Green
                Write-Host "[N] No - try next resource" -ForegroundColor Red
                Write-Host "[S] Skip - use this for all remaining folders" -ForegroundColor Yellow
                Write-Host "[Q] Quit" -ForegroundColor Red

                try {
                    $response = Read-Host "Choice (Y/N/S/Q)"
                }
                catch {
                    Write-Log "Read-Host failed, defaulting to 'N'" -Level 'Warning'
                    $response = 'N'
                }

                if (-not $response) { $response = 'N' }

                switch ($response.ToUpper()) {
                    'Y' { Write-Log "Resource accepted for $folderName" -Level 'Success'; return $true }
                    'N' { Write-Log "Trying next resource..." -Level 'Info'; continue }
                    'S' {
                        Write-Log "Using this resource for all remaining folders" -Level 'Success'
                        $script:BLANK_NAME_RESOURCES = @($resource)
                        return $true
                    }
                    'Q' { Write-Log "User quit. Stopping." -Level 'Warning'; exit 1 }
                    default { Write-Log "Invalid choice, treating as 'No'" -Level 'Warning'; continue }
                }
            }
            catch {
                $errMsg = $_.Exception.Message
                Write-Log "Failed to create desktop.ini for ${FolderPath}: $errMsg" -Level 'Error'
                return $false
            }
        }
    }

    Write-Log "No resource produced a blank name for $FolderPath" -Level 'Error'
    return $false
}