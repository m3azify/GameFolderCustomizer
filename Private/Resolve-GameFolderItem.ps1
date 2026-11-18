function Resolve-GameFolderItem {
    <#
    .SYNOPSIS
        Resolves a folder path to its real DirectoryInfo object.

    .DESCRIPTION
        Windows trims trailing space-like characters from paths. A folder whose
        name is U+00A0 (non-breaking space) therefore resolves by path to its
        parent (e.g. 'D:\<U+00A0>' resolves to 'D:\'). This helper retrieves the
        actual DirectoryInfo by enumerating the parent instead.

    .PARAMETER FolderPath
        Path that may end in a U+00A0 folder name.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath
    )

    $blankChar = [char]0x00A0
    $leaf = Split-Path -Path $FolderPath -Leaf

    # Any name made entirely of U+00A0 characters is a blank name
    $isBlankNamed = ($leaf -replace ([regex]::Escape([string]$blankChar)), '').Length -eq 0
    if (-not $isBlankNamed) {
        return Get-Item -LiteralPath $FolderPath -Force
    }

    $parentPath = Split-Path -Path $FolderPath -Parent
    $parent = Get-Item -LiteralPath $parentPath -Force
    if (-not $parent) { return $null }

    try {
        $match = @($parent.EnumerateFileSystemInfos()) |
            Where-Object { $_.Name -eq $leaf } |
            Select-Object -First 1
        if ($match) { return $match }
    }
    catch {
        Write-Log "Could not enumerate parent for blank-named folder: $($_.Exception.Message)" -Level 'Debug'
    }

    return Get-Item -LiteralPath $FolderPath -Force
}
