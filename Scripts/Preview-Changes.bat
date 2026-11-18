@echo off
:: Game Folder Customizer - Preview Mode (WhatIf)
:: Shows what would be changed WITHOUT making any changes

cd /d "%~dp0\.."

echo ============================================
echo  Game Folder Customizer - PREVIEW MODE
echo ============================================
echo.
echo This shows what WOULD be changed on D: drive
echo NO CHANGES WILL BE MADE
echo.
echo Using -BlankNameMethod Rename (default for admin launcher)
echo.
pause

powershell.exe -ExecutionPolicy Bypass -File "%~dp0\..\Customize-GameFolders.ps1" -WhatIf -BlankNameMethod Rename

echo.
echo ============================================
echo  Preview complete. Press any key to exit...
echo ============================================
pause >nul