function Test-IsFolderCustomized {
    <#
    .SYNOPSIS
        Returns true if a folder already has the GameFolderCustomizer setup.

    .DESCRIPTION
        Used by the logon auto-customize task to skip folders that were already
        processed. A folder counts as customized when its name is the blank
        character (U+00A0) or its desktop.ini declares our DirectoryClass.

    .PARAMETER FolderPath
        Path of the folder to check.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath
    )

    $blankChar = [char]0x00A0
    $leaf = Split-Path -Path $FolderPath -Leaf
    $isBlankNamed = ($leaf -replace ([regex]::Escape([string]$blankChar)), '').Length -eq 0
    if ($isBlankNamed) {
        return $true
    }

    $iniPath = Join-Path $FolderPath 'desktop.ini'
    if (-not (Test-Path -LiteralPath $iniPath)) {
        return $false
    }

    try {
        $content = [System.IO.File]::ReadAllText($iniPath, [System.Text.Encoding]::Unicode)
        return ($content -match 'DirectoryClass=GameFolderCustomizer.GameFolder')
    }
    catch {
        return $false
    }
}
