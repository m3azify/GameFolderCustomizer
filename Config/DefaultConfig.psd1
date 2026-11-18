@{
    # Default configuration for GameFolderCustomizer
    DriveLetter = 'D:'
    IconSourcePreference = 'All'
    MaxIconSearchDepth = 3
    ExcludeFolders = @('System Volume Information', '$RECYCLE.BIN', 'Recovery', 'Documents and Settings', 'PerfLogs')
    ForceRefresh = $false
    BlankNameMethod = 'Rename'
    NonInteractive = $false

    # Blank name resource IDs for DesktopIni method (shell32.dll)
    BlankNameResources = @(
        '@%SystemRoot%\system32\shell32.dll,-21781',
        '@%SystemRoot%\system32\shell32.dll,-21769',
        '@%SystemRoot%\system32\shell32.dll,-21796',
        '@%SystemRoot%\system32\shell32.dll,-21814',
        '@%SystemRoot%\system32\shell32.dll,-21815',
        '@%SystemRoot%\system32\shell32.dll,-21816'
    )

    # Icon search patterns
    IconExtensions = @('.exe', '.lnk', '.ico', '.dll')

    # System folders (always excluded)
    SystemFolders = @(
        'System Volume Information', '$RECYCLE.BIN', 'Recovery',
        'Documents and Settings', 'PerfLogs', 'Windows',
        'Program Files', 'Program Files (x86)', 'ProgramData',
        'Users', 'Boot', 'EFI'
    )
}