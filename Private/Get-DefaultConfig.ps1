function Get-DefaultConfig {
    <#
    .SYNOPSIS
        Loads and caches Config\DefaultConfig.psd1.
    .DESCRIPTION
        Provides a single source of truth for system-folder exclusions and
        other defaults. The result is cached in module scope for the session.
    #>
    [CmdletBinding()]
    param()

    if ($script:DefaultConfig) { return $script:DefaultConfig }

    $configPath = Join-Path $script:ModuleRoot 'Config\DefaultConfig.psd1'
    if (-not (Test-Path -LiteralPath $configPath)) {
        Write-Log "Default config not found: $configPath" -Level 'Warning'
        return @{}
    }

    try {
        $script:DefaultConfig = Import-PowerShellDataFile -LiteralPath $configPath -ErrorAction Stop
        return $script:DefaultConfig
    }
    catch {
        Write-Log "Failed to load default config: $($_.Exception.Message)" -Level 'Warning'
        return @{}
    }
}
