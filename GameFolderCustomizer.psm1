# GameFolderCustomizer.psm1 - Module Root

# Capture once at module load; functions can rely on this instead of $PSScriptRoot
# (whose value inside a dot-sourced function depends on call-site scoping).
$ModulePath = $PSScriptRoot
$script:ModuleRoot = $PSScriptRoot

# Load private functions
$PrivateFiles = Get-ChildItem -Path (Join-Path $ModulePath 'Private') -Filter '*.ps1' -ErrorAction SilentlyContinue
foreach ($file in $PrivateFiles) {
    try {
        . $file.FullName
    }
    catch {
        Write-Warning "Failed to load private function $($file.Name): $_"
    }
}

# Load public functions
$PublicFiles = Get-ChildItem -Path (Join-Path $ModulePath 'Public') -Filter '*.ps1' -ErrorAction SilentlyContinue
foreach ($file in $PublicFiles) {
    try {
        . $file.FullName
    }
    catch {
        Write-Warning "Failed to load public function $($file.Name): $_"
    }
}

# Export public functions
Export-ModuleMember -Function @(
    'Invoke-GameFolderCustomizer',
    'Remove-GameFolderCustomization',
    'Get-GameFolders',
    'Find-GameIcon',
    'Register-GameFolderLaunch',
    'Test-IsFolderCustomized'
) -Alias 'Revert-GameFolderCustomization'