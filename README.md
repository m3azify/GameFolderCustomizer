# Game Folder Customizer

Automatically customizes game folders on a drive (default `D:`):
- **Blank folder names** in File Explorer
- **Custom icons** from game executables, shortcuts, or `.ico` files

## Project Structure

```
GameFolderCustomizer/
├── GameFolderCustomizer.psd1   # Module manifest
├── GameFolderCustomizer.psm1   # Module root
├── Customize-GameFolders.ps1   # Main entry point
├── Config/                     # Default configuration
├── Private/                    # Internal functions
├── Public/                     # Exported cmdlets
├── Scripts/                    # Launcher & utility scripts
├── Tests/                      # Pester 5 tests
├── .github/workflows/          # CI (Pester on Windows)
├── README.md
├── CHANGELOG.md
├── LICENSE                     # MIT
└── .gitignore
```

The `Config\DefaultConfig.psd1` file is loaded at module import and is the
single source of truth for system-folder exclusions and other defaults.

## How It Works

Uses Windows' standard `desktop.ini` mechanism for icons, with two methods for blank names:

| Method | Blank Name | Keeps Actual Name | Works on Win11 26H2+ |
|--------|------------|-------------------|---------------------|
| **DesktopIni** (default) | `LocalizedResourceName` | ✅ Yes | ❌ Broken since KB5074109 |
| **Rename** | Alt+0160 (U+00A0) | ❌ No (renames folder) | ✅ Works |
| **Both** | Rename + fallback | ❌ No | ✅ Works |

**Important:** Windows 11 25H2/26H2 (build 26200+) broke `LocalizedResourceName` in `desktop.ini` (KB5074109, KB5094126). The only reliable way to get a blank name on these builds is the **Rename** method, which changes the actual folder name to a non-breaking space (Alt+0160 / U+00A0).

No game files are modified. Only `desktop.ini` (hidden system file) is created/updated in each folder.

## Requirements

- Windows 10/11
- PowerShell 5.1+ (built into Windows)
- **Administrator rights** (required for some folders)

## Usage

### Quick Start (Run as Administrator)

1. Right-click `Scripts\Run-As-Admin.bat` → **Run as administrator**
2. Or open PowerShell as Admin and run:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\Customize-GameFolders.ps1
   ```

### Preview Changes First (Safe)
```powershell
.\Customize-GameFolders.ps1 -WhatIf
```

### Custom Options
```powershell
# Different drive
.\Customize-GameFolders.ps1 -DriveLetter E:

# Use Rename method for blank names (works on Win11 26H2+)
.\Customize-GameFolders.ps1 -BlankNameMethod Rename

# Try DesktopIni first, fall back to Rename
.\Customize-GameFolders.ps1 -BlankNameMethod Both

# Only use .exe files for icons (skip shortcuts/.ico)
.\Customize-GameFolders.ps1 -IconSourcePreference ExeOnly

# Deeper search for icons (default: 3 levels)
.\Customize-GameFolders.ps1 -MaxIconSearchDepth 5

# Exclude additional folders
.\Customize-GameFolders.ps1 -ExcludeFolders @('MyBackups', 'OldGames')

# Force shell icon cache refresh
.\Customize-GameFolders.ps1 -ForceRefresh

# Launch the game on double-click (middle-click still opens the folder in a new tab)
.\Customize-GameFolders.ps1 -BlankNameMethod Rename -LaunchOnDoubleClick
```

## Launch Game on Double-Click

Use `-LaunchOnDoubleClick` to make a customized folder launch its game when you
**double-click** it. **Middle-click still opens the folder in a new tab**, and
right-click → **Open** works normally.

This uses Microsoft's documented `DirectoryClass` desktop.ini feature with a
per-user ProgID (`HKCU\Software\Classes\GameFolderCustomizer.GameFolder`).
Only folders you customize are affected — ordinary folders keep their normal
behavior. No administrator rights are required for the verb registration.

```powershell
# Register/unregister the shell verb manually
Register-GameFolderLaunch
Register-GameFolderLaunch -Unregister
```

To remove everything, including the verb:
```powershell
Remove-GameFolderCustomization -UnregisterVerb
```

> **Note:** The launcher scripts must stay at `Scripts\Launch-Game.vbs` and
> `Scripts\Launch-Game.ps1` — the registered verb points to them. If you move
> the project, re-run `Register-GameFolderLaunch` after moving.

## Start Automatically at Logon

The current customization (blank names, icons, launch verb) is already
persistent — nothing has to run at startup for it to keep working. A logon task
is only needed if you add new games later and want them customized
automatically.

```powershell
# Install a per-user logon task (no admin rights needed)
.\Scripts\Install-AutoRun.ps1

# Remove it
.\Scripts\Disable-AutoRun.ps1
```

This creates a shortcut in your Startup folder that runs
`AutoCustomize-AtLogon.ps1` hidden at every logon. The task:

- waits 15 seconds for Explorer to settle,
- scans `D:\`,
- **skips folders already customized** (blank name or our `DirectoryClass`),
- customizes only new folders with a clear game icon (score ≥ 50),
- logs to `%LOCALAPPDATA%\GameFolderCustomizer\autorun.log`.

The existing game folder is never touched. To verify the log after a reboot:

```powershell
Get-Content "$env:LOCALAPPDATA\GameFolderCustomizer\autorun.log" -Tail 20
```

> **Note:** Multiple blank-named folders are supported — the script uses
> U+00A0 repeated (1 character, then 2, etc.) so each folder gets a distinct
> name that still renders blank.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-DriveLetter` | `D:` | Target drive letter |
| `-IconSourcePreference` | `All` | `All` / `ExeOnly` / `ShortcutOnly` / `IconOnly` |
| `-MaxIconSearchDepth` | `3` | Recursion depth for icon search |
| `-ExcludeFolders` | System folders | Additional folder names to skip |
| `-ForceRefresh` | `false` | Force shell icon cache refresh |
| `-BlankNameMethod` | `DesktopIni` | `DesktopIni` / `Rename` / `Both` |
| `-WhatIf` | (switch) | Preview changes without applying |
| `-NonInteractive` | `false` | Skip interactive prompts (auto-accept) |
| `-LaunchOnDoubleClick` | `false` | Double-click launches the game; middle-click opens a new tab |

## Blank Name Methods

| Method | Description |
|--------|-------------|
| `DesktopIni` | Uses `LocalizedResourceName` in `desktop.ini`. **Broken on Win11 26H2+** (KB5074109/KB5094126). Keeps actual folder name unchanged. |
| `Rename` | Renames folder to non-breaking space (U+00A0, Alt+0160). **Works on all versions**. Changes actual folder name. |
| `Both` | Tries `DesktopIni` first (interactive verification), falls back to `Rename` if name not blank. |

**Recommendation for Windows 11 25H2/26H2 (build 26200+):** Use `-BlankNameMethod Rename` or `-BlankNameMethod Both`.

## Icon Detection Logic

The script searches each folder for icons and scores them:

1. **Main executable** (`.exe`) — highest priority
   - Bonus for names like `game.exe`, `launcher.exe`, `play.exe`
   - Penalty for `uninstall`, `crash`, `setup`, `update`, etc.
2. **Shortcuts** (`.lnk`) — resolves to target `.exe`
3. **Icon files** (`.ico`) — direct icon files
4. **DLLs** (`.dll`) — may contain icon resources

Folders with **no clear icon candidate are skipped** (ambiguity protection).

## System Folders Excluded Automatically

- `System Volume Information`
- `$RECYCLE.BIN`
- `Recovery`
- `Windows`
- `Program Files` / `Program Files (x86)`
- `ProgramData`
- `Users`
- `Boot`, `EFI`
- `PerfLogs`

## After Running

Changes appear in File Explorer within seconds. If not:
1. Press `F5` to refresh
2. Run `ie4uinit.exe -show` (Win+R → type → Enter)
3. Restart Explorer: Task Manager → Windows Explorer → Restart

## Revert Changes

**For Rename method:** The folder name is permanently changed. To restore:
```powershell
# You'll need to rename the folder back manually in File Explorer
# (Select the "blank" folder, press F2, type the original name)
```

**For DesktopIni method:** Delete the `desktop.ini` file:
```powershell
# For a specific folder
Remove-Item "D:\GameFolder\desktop.ini" -Force

# For all folders on D:
Get-ChildItem D:\ -Directory | ForEach-Object { Remove-Item "$($_.FullName)\desktop.ini" -Force -ErrorAction SilentlyContinue }
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Access denied" | Run PowerShell as Administrator |
| Names not blank (DesktopIni) | Use `-BlankNameMethod Rename` or `Both` |
| Wrong icon | Delete `desktop.ini` and re-run with `-IconSourcePreference ExeOnly` |
| Icon not updating | Use `-ForceRefresh` flag, or press F5 in File Explorer |
| Folder renamed but no icon | Ensure `-BlankNameMethod Rename` or `Both` (both create desktop.ini for icon) |
| **Default folder icon after rename** | Re-run the script with `-BlankNameMethod Rename`. Older versions wrote a `desktop.ini` icon path pointing at the *pre-rename* folder name, which becomes invalid after the rename. v1.0.1+ rewrites this path automatically. |

## Development / Testing

Tests use **Pester 5.x** (29 tests). Run them with:

```powershell
Install-Module Pester -MinimumVersion 5.7.0 -Scope CurrentUser
Invoke-Pester -Path .\Tests\GameFolderCustomizer.Tests.ps1
```

A GitHub Actions workflow (`.github/workflows/tests.yml`) runs the same suite on
every push and pull request using Windows PowerShell 5.1.

To validate the module manifest:

```powershell
Test-ModuleManifest -Path .\GameFolderCustomizer.psd1
```

## License

MIT — see [LICENSE](LICENSE).