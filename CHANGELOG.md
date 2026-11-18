# Changelog

All notable changes to the Game Folder Customizer project.

## [1.2.1] - 2026-11-18

### Changed (code review / publication hardening)
- Replaced `Invoke-Expression` + `cmd /c ren` with a direct .NET `MoveTo` in the
  rename path, removing a shell-injection risk for unusual folder names.
- Rewrote the Pester suite for **Pester 5.x** (29 tests) and added a GitHub
  Actions workflow that runs them on Windows PowerShell 5.1.
- `Config\DefaultConfig.psd1` is now actually loaded and is the single source
  of truth for system-folder exclusions.
- Replaced the placeholder module GUID with a real one.
- Simplified the folder filter and fixed the icon-score depth calculation and
  UTF-16 `desktop.ini` decoding.
- Shell icon refresh now runs once per run instead of once per folder.
- `AutoCustomize-AtLogon.ps1`, `Revert-Changes.ps1`, and the main entry point
  now import the module manifest (`.psd1`) instead of the `.psm1` directly.
- Moved the interactive `Test-BlankNameResource` diagnostic out of public
  exports and wired it to the config resource list.

### Added
- `LICENSE` (MIT) and `.gitignore`.
- Developer documentation for running tests.

### Removed
- Eleven leftover debug scripts from the original flat-script layout in `Tests/`.

## [1.2.0] - 2026-11-18

### Added
- **Logon auto-customization**: `Scripts\AutoCustomize-AtLogon.ps1` scans the
  drive at logon and customizes only NEW game folders, skipping ones already
  set up. Writes to `%LOCALAPPDATA%\GameFolderCustomizer\autorun.log`.
- `Scripts\Install-AutoRun.ps1` / `Disable-AutoRun.ps1` create/remove a per-user
  Startup shortcut (no administrator rights required).
- `Test-IsFolderCustomized` cmdlet for the idempotency guard.
- `MinimumIconScore` parameter to avoid customizing folders that are not
  clearly games (logon task uses 50 by default).
- `Resolve-GameFolderItem` helper fixes icon search on blank-named folders.

### Fixed
- **Multiple blank folders**: the Rename method previously hardcoded a single
  U+00A0 name, so only one folder per drive could be blank-named. It now picks
  the first unused blank name (U+00A0 repeated), allowing several customized
  game folders on the same drive.

### Verified
- Logon task: first run customizes a new folder; second run skips it; existing
  game folder's desktop.ini is byte-identical before and after.
- Installed Startup shortcut runs end-to-end successfully.

## [1.1.0] - 2026-11-18

### Added
- **Launch game on double-click** (`-LaunchOnDoubleClick`): customized folders
  now launch their game when double-clicked, while **middle-click still opens
  the folder in a new tab**.
  - Uses Microsoft's documented `DirectoryClass` desktop.ini feature with a
    per-user ProgID (`HKCU\Software\Classes\GameFolderCustomizer.GameFolder`).
    Only opted-in folders are affected — ordinary folders are unchanged.
  - New `Register-GameFolderLaunch` cmdlet to register/unregister the verb.
  - New hidden launcher (`Scripts\Launch-Game.vbs` + `Launch-Game.ps1`) that
    reads `GameExe` from the folder's desktop.ini. Falls back to opening the
    folder if no executable is configured.
  - `Remove-GameFolderCustomization -UnregisterVerb` removes the registration.

### Verified
- Double-click (default verb) launches the configured executable.
- Middle-click opens the folder in a new tab without launching the game —
  confirmed with a real GUI middle-click on Windows 11 build 26300.
- 21/21 Pester tests passing.

## [1.0.1] - 2026-11-18

### Fixed
- **Custom icon not showing after rename**: The icon path in `desktop.ini` was
  detected before the folder rename and still referenced the original folder
  name (e.g. `D:\Sin Spire\...`). After renaming to U+00A0 that path became
  invalid, so Explorer showed the default folder icon. The path is now rewritten
  to the renamed folder's location.
- **System attribute not applied after rename**: A path ending in U+00A0 is
  normalized by Windows to the parent drive, so locating the folder by that path
  failed and the `System` attribute was never set. The attribute is now applied
  *before* the rename (renaming preserves attributes), which `desktop.ini`
  requires.
- Removed conflicting `IconResource` key; `desktop.ini` now uses `IconFile` +
  `IconIndex` only.

### Added
- Isolated end-to-end verification of the Rename-method fix.

## [1.0.0] - 2026-11-17

### Added
- Initial release as a PowerShell module
- Three blank name methods: DesktopIni, Rename (Alt+0160), Both
- Custom game icon detection from .exe, .lnk, .ico, .dll files
- Scoring algorithm for icon selection (prefers main executables)
- Interactive verification mode for resource IDs
- -WhatIf support for preview
- -NonInteractive mode for automation
- Revert-Changes.ps1 for removing customizations
- Comprehensive README.md with troubleshooting

### Changed
- Restructured from flat scripts to proper PowerShell module
- Moved test/debug scripts to Tests/ directory
- Moved launcher scripts to Scripts/ directory
- Added module manifest (GameFolderCustomizer.psd1)
- Added Pester test suite

### Known Issues
- `LocalizedResourceName` (DesktopIni method) broken on Windows 11 26H2+ (KB5074109/KB5094126)
- Rename method changes actual folder name (can't be auto-reverted)
- Requires Administrator privileges
- No CI/CD pipeline yet