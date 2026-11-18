function Get-GameFolders {
    <#
    .SYNOPSIS
        Gets game folders from the target drive.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,

        [string[]]$ExcludeFolders = @()
    )

    if (-not (Test-Path $RootPath)) {
        Write-Log "Drive $RootPath not found or not accessible" -Level 'Error'
        return @()
    }

    $config = Get-DefaultConfig
    $systemFolders = @($config.SystemFolders) + $ExcludeFolders

    $folders = Get-ChildItem -LiteralPath $RootPath -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $systemFolders -notcontains $_.Name } |
        Where-Object { -not $_.Attributes.HasFlag([IO.FileAttributes]::Hidden) }

    return $folders
}