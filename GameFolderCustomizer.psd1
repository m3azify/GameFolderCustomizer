@{
    RootModule = 'GameFolderCustomizer.psm1'
    ModuleVersion = '1.2.1'
    GUID = 'b1b5a518-e718-4a90-bceb-26c1666360f0'
    Author = 'm3azify'
    CompanyName = 'm3azify'
    Copyright = '(c) 2026. MIT License.'
    Description = 'Customizes game folders on Windows drives - blank names and custom icons via desktop.ini'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Invoke-GameFolderCustomizer',
        'Remove-GameFolderCustomization',
        'Get-GameFolders',
        'Find-GameIcon',
        'Register-GameFolderLaunch',
        'Test-IsFolderCustomized'
    )
    # Test-BlankNameResource is a developer diagnostic and is intentionally not exported
    AliasesToExport = @('Revert-GameFolderCustomization')
    CmdletsToExport = @()
    VariablesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Windows', 'FileExplorer', 'desktop.ini', 'GameFolders', 'Customization')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/m3azify/GameFolderCustomizer'
            ReleaseNotes = 'Blank names, custom icons, launch-on-double-click, and logon auto-customization'
        }
    }
}