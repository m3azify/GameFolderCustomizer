@echo off
:: Game Folder Customizer - Blank names + icons + launch-on-double-click
:: Right-click this file and select "Run as administrator"

cd /d "%~dp0\.."

echo ============================================
echo  Game Folder Customizer - With Game Launch
echo ============================================
echo.
echo Double-click a customized folder -^> launches its game
echo Middle-click the folder -^> opens it in a new tab
echo Using -BlankNameMethod Rename (Win11 26H2+)
echo.
echo Press any key to continue, or Ctrl+C to cancel...
pause >nul

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ERROR: Not running as Administrator!
    pause
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -File "%~dp0\..\Customize-GameFolders.ps1" -BlankNameMethod Rename -LaunchOnDoubleClick

echo.
echo Done. Press any key to exit...
pause >nul
