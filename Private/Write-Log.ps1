function Write-Log {
    <#
    .SYNOPSIS
        Centralized logging function for GameFolderCustomizer module.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Position = 1)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Debug')]
        [string]$Level = 'Info',

        [Parameter()]
        [string]$LogFile = ''
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    $prefix = switch ($Level) {
        'Info'     { '[INFO]' }
        'Warning'  { '[WARN]' }
        'Error'    { '[ERROR]' }
        'Success'  { '[OK]' }
        'Debug'    { '[DEBUG]' }
    }

    $color = switch ($Level) {
        'Info'     { 'Cyan' }
        'Warning'  { 'Yellow' }
        'Error'    { 'Red' }
        'Success'  { 'Green' }
        'Debug'    { 'Gray' }
    }

    $logEntry = "$timestamp $prefix $Message"

    Write-Host $logEntry -ForegroundColor $color

    if ($LogFile) {
        try {
            Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
        }
        catch {
            # Silently fail on file write errors
        }
    }
}