function Get-RenamedIconPath {
    <#
    .SYNOPSIS
        Rewrites an icon path so it points at a folder after it has been renamed.

    .DESCRIPTION
        Icon paths are discovered before a folder is renamed to the blank
        character (U+00A0). If the path starts with the original folder path,
        replace that prefix with the new path. Otherwise return it unchanged.

    .PARAMETER IconResource
        The icon path discovered before the rename.

    .PARAMETER OriginalPath
        The folder path before the rename.

    .PARAMETER NewPath
        The folder path after the rename.

    .PARAMETER WasRenamed
        Whether the folder was actually renamed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$IconResource,

        [Parameter(Mandatory = $true)]
        [string]$OriginalPath,

        [Parameter(Mandatory = $true)]
        [string]$NewPath,

        [switch]$WasRenamed
    )

    if (-not $WasRenamed) { return $IconResource }
    if (-not $IconResource.StartsWith($OriginalPath, [StringComparison]::OrdinalIgnoreCase)) {
        return $IconResource
    }

    $result = $NewPath + $IconResource.Substring($OriginalPath.Length)
    Write-Log "Updated icon path after rename: $result" -Level 'Debug'
    return $result
}
