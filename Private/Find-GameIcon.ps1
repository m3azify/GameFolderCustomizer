function Find-GameIcon {
    <#
    .SYNOPSIS
        Finds the best game icon in a folder.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,

        [ValidateSet('All', 'ExeOnly', 'ShortcutOnly', 'IconOnly')]
        [string]$Preference = 'All',

        [int]$MaxDepth = 3,

        [int]$MinimumScore = -1
    )

    $searchPatterns = switch ($Preference) {
        'ExeOnly'      { @('*.exe') }
        'ShortcutOnly' { @('*.lnk') }
        'IconOnly'     { @('*.ico') }
        default        { @('*.exe', '*.lnk', '*.ico', '*.dll') }
    }

    # Resolve the real folder object. Paths ending in U+00A0 would otherwise
    # resolve to the parent drive, causing a scan of the whole drive.
    $folderItem = Resolve-GameFolderItem -FolderPath $FolderPath
    if (-not $folderItem) { return $null }

    $bestIcon = $null
    $bestScore = -1

    foreach ($pattern in $searchPatterns) {
        $files = @(Get-FilesByPattern -Directory $folderItem -Pattern $pattern -MaxDepth $MaxDepth)
        foreach ($file in $files) {
            $score = Calculate-IconScore -File $file -Pattern $pattern -BasePath $folderItem.FullName
            if ($score -gt $bestScore) {
                $bestScore = $score
                $bestIcon = $file.FullName
            }
        }
    }

    if ($bestScore -lt $MinimumScore) {
        $bestIcon = $null
    }

    # Check existing desktop.ini
    $desktopIni = Join-Path $folderItem.FullName 'desktop.ini'
    if (Test-Path -LiteralPath $desktopIni) {
        $existingIcon = Get-DesktopIniIcon -Path $desktopIni
        if ($existingIcon -and $bestScore -lt 50) {
            return $existingIcon
        }
    }

    return $bestIcon
}

function Get-FilesByPattern {
    <#
    .SYNOPSIS
        Enumerates files matching a pattern up to a maximum depth.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IO.DirectoryInfo]$Directory,

        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [int]$MaxDepth = 3,

        [int]$CurrentDepth = 0
    )

    if ($CurrentDepth -gt $MaxDepth) { return }

    try {
        foreach ($file in $Directory.EnumerateFiles($Pattern)) {
            $file
        }
    }
    catch {
        # Access denied on some subfolders - skip
    }

    if ($CurrentDepth -eq $MaxDepth) { return }

    try {
        foreach ($subDir in $Directory.EnumerateDirectories()) {
            Get-FilesByPattern -Directory $subDir -Pattern $Pattern -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
        }
    }
    catch {
        # Access denied on some subfolders - skip
    }
}

function Calculate-IconScore {
    param(
        [System.IO.FileInfo]$File,
        [string]$Pattern,
        [string]$BasePath = ''
    )

    $score = 0
    $name = $File.BaseName.ToLower()

    if ($Pattern -eq '*.exe') {
        $score += 100
        if ($name -match '^(game|launcher|play|start|main|app)$') { $score += 50 }
        if ($name -match '(uninstall|crash|report|setup|install|update|patch|config|settings)') { $score -= 30 }
    }

    if ($Pattern -eq '*.lnk') {
        $score += 80
        try {
            $shell = New-Object -ComObject Shell.Application
            $shortcut = $shell.NameSpace($File.DirectoryName).ParseName($File.Name).GetLink
            if ($shortcut.TargetPath -and (Test-Path $shortcut.TargetPath)) {
                $targetName = [IO.Path]::GetFileNameWithoutExtension($shortcut.TargetPath).ToLower()
                if ($targetName -match '^(game|launcher|play|start|main|app)$') { $score += 40 }
            }
        }
        catch { }
    }

    if ($Pattern -eq '*.ico') { $score += 60 }
    if ($Pattern -eq '*.dll') { $score += 30 }

    # Depth relative to the game folder root, computed from the file's directory
    if ($BasePath -and $File.DirectoryName.StartsWith($BasePath, [StringComparison]::OrdinalIgnoreCase)) {
        $relative = $File.DirectoryName.Substring($BasePath.Length).Trim('\')
        $depth = if ($relative) { $relative.Split('\').Count } else { 0 }
    }
    else {
        $depth = 0
    }
    $score -= $depth * 10

    if ($File.Length -gt 10MB) { $score += 10 }
    elseif ($File.Length -lt 100KB) { $score -= 20 }

    return $score
}

function Get-DesktopIniIcon {
    param([string]$Path)

    if (-not (Test-Path $Path)) { return $null }

    # desktop.ini is written as UTF-16LE; reading it as ANSI mangles non-ASCII paths
    $content = Get-Content -LiteralPath $Path -Encoding Unicode -ErrorAction SilentlyContinue
    if (-not $content) { return $null }

    foreach ($line in $content) {
        if ($line -match '^IconResource\s*=\s*(.+)$') {
            $parts = $matches[1].Split(',')
            $iconPath = $parts[0].Trim()
            if (Test-Path $iconPath) { return $iconPath }
        }
        elseif ($line -match '^IconFile\s*=\s*(.+)$') {
            $iconPath = $matches[1].Trim()
            if (Test-Path $iconPath) { return $iconPath }
        }
    }

    return $null
}

function Resolve-IconPath {
    param([string]$IconPath)

    if ($IconPath -match '\.lnk$') {
        try {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($IconPath)
            $target = $shortcut.TargetPath
            if ($target -and (Test-Path $target)) {
                return Resolve-IconPath -IconPath $target
            }
        }
        catch { }
    }

    if ($IconPath -match '\.(exe|dll)$') { return $IconPath }
    if ($IconPath -match '\.ico$') { return $IconPath }

    return $IconPath
}