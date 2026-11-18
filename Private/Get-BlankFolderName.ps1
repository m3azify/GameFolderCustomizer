function Get-BlankFolderName {
    <#
    .SYNOPSIS
        Finds an unused blank-looking folder name in a parent directory.

    .DESCRIPTION
        A single U+00A0 (non-breaking space) renders as a blank name, but only
        one folder per directory can have that exact name. Repeating the
        character produces distinct names that all render blank, allowing
        multiple customized folders on the same drive.

    .PARAMETER ParentPath
        Directory in which to find an unused name.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ParentPath
    )

    $blankChar = [char]0x00A0
    $parent = Get-Item -LiteralPath $ParentPath -Force
    if (-not $parent) { return $null }

    $usedNames = @()
    try {
        $usedNames = @($parent.EnumerateFileSystemInfos() | ForEach-Object { $_.Name })
    }
    catch {
        Write-Log "Could not enumerate $ParentPath for blank names: $($_.Exception.Message)" -Level 'Debug'
    }

    # 1..20 blank characters is plenty and stays well within path limits
    for ($count = 1; $count -le 20; $count++) {
        $candidate = [string]::new($blankChar, $count)
        if ($usedNames -notcontains $candidate) {
            return $candidate
        }
    }

    return $null
}
