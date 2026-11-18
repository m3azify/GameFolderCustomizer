@echo off
:: Game Folder Customizer - Run as Administrator
:: Right-click this file and select "Run as administrator"
:: Uses -BlankNameMethod Rename (works on Windows 11 26H2+)

cd /d "%~dp0\.."

echo ============================================
echo  Game Folder Customizer - Admin Launcher
echo ============================================
echo.
echo This will run Customize-GameFolders.ps1 with
echo Administrator privileges on drive D:
echo Using -BlankNameMethod Rename (works on Win11 26H2+)
echo.
echo Press any key to continue, or Ctrl+C to cancel...
pause >nul

:: Check if running as admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ERROR: Not running as Administrator!
    echo Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo.
echo Running Customize-GameFolders.ps1 -BlankNameMethod Rename...
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0\..\Customize-GameFolders.ps1" -BlankNameMethod Rename

echo.
echo ============================================
echo  Done. Press any key to exit...
echo ============================================
pause >nul