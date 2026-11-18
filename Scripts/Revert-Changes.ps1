<#
.SYNOPSIS
    Reverts game folder customizations by removing desktop.ini files.
.DESCRIPTION
    Removes desktop.ini from folders on the target drive, restoring default
    File Explorer appearance (original names and icons).
    NOTE: If you used -BlankNameMethod Rename or Both, the folder names were
    changed to a non-breaking space (U+00A0). This script only removes desktop.ini
    files - it CANNOT restore the original folder names (they are lost).
    You must manually rename those folders back in File Explorer.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$DriveLetter = 'D:',
    [string[]]$ExcludeFolders = @()
)

$modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'GameFolderCustomizer.psd1'
Import-Module $modulePath -Force -ErrorAction Stop

Remove-GameFolderCustomization -DriveLetter $DriveLetter -ExcludeFolders $ExcludeFolders