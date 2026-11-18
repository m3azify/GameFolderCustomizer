<#
.SYNOPSIS
    Game Folder Customizer - Main Entry Point
.DESCRIPTION
    Thin wrapper that imports the GameFolderCustomizer module and runs the customization.
    Supports -WhatIf for preview mode.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$DriveLetter = 'D:',

    [Parameter()]
    [ValidateSet('All', 'ExeOnly', 'ShortcutOnly', 'IconOnly')]
    [string]$IconSourcePreference = 'All',

    [Parameter()]
    [switch]$RecurseSubfolders = $false,

    [Parameter()]
    [int]$MaxIconSearchDepth = 3,

    [Parameter()]
    [string[]]$ExcludeFolders = @(),

    [Parameter()]
    [switch]$ForceRefresh = $false,

    [Parameter()]
    [switch]$NonInteractive = $false,

    [Parameter()]
    [ValidateSet('DesktopIni', 'Rename', 'Both')]
    [string]$BlankNameMethod = 'DesktopIni',

    [Parameter()]
    [switch]$LaunchOnDoubleClick,

    [Parameter()]
    [int]$MinimumIconScore = -1
)

# Import the module
$modulePath = Join-Path $PSScriptRoot 'GameFolderCustomizer.psd1'
Import-Module $modulePath -Force -ErrorAction Stop

# Run the customization
Invoke-GameFolderCustomizer `
    -DriveLetter $DriveLetter `
    -IconSourcePreference $IconSourcePreference `
    -MaxIconSearchDepth $MaxIconSearchDepth `
    -ExcludeFolders $ExcludeFolders `
    -ForceRefresh:$ForceRefresh `
    -NonInteractive:$NonInteractive `
    -BlankNameMethod $BlankNameMethod `
    -LaunchOnDoubleClick:$LaunchOnDoubleClick `
    -MinimumIconScore $MinimumIconScore