@echo off
:: Game Folder Customizer - Both Method (Try DesktopIni, fallback to Rename)
:: Right-click this file and select "Run as administrator"

cd /d "%~dp0\.."

echo ============================================
echo  Game Folder Customizer - BOTH METHOD
echo ============================================
echo.
echo This will run Customize-GameFolders.ps1 with
echo Administrator privileges on drive D:
echo Using -BlankNameMethod Both (tries DesktopIni, falls back to Rename)
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
echo Running Customize-GameFolders.ps1 -BlankNameMethod Both...
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0\..\Customize-GameFolders.ps1" -BlankNameMethod Both

echo.
echo ============================================
echo  Done. Press any key to exit...
echo ============================================
pause >nul