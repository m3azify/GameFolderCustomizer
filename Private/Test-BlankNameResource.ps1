function Test-BlankNameResource {
    <#
    .SYNOPSIS
        Tests which shell32.dll resource ID produces a blank folder name.
    #>
    [CmdletBinding()]
    param(
        [string]$TestFolder = 'D:\__BlankNameTest__'
    )

    $resources = @((Get-DefaultConfig).BlankNameResources)
    if (-not $resources) { $resources = @() }

    Write-Host "Windows version: $([System.Environment]::OSVersion.Version)" -ForegroundColor Cyan
    Write-Host "Testing resource IDs for blank folder name..." -ForegroundColor Cyan

    if (-not (Test-Path $TestFolder)) {
        New-Item -Path $TestFolder -ItemType Directory | Out-Null
        Write-Host "Created test folder: $TestFolder" -ForegroundColor Green
    }

    foreach ($resource in $resources) {
        $iniPath = Join-Path $TestFolder 'desktop.ini'
        $iniContent = "[.ShellClassInfo]`r`nLocalizedResourceName=$resource`r`nConfirmFileOp=0`r`nNoSharing=1"

        if (Test-Path $iniPath) {
            $iniItem = Get-Item $iniPath -Force
            $iniItem.Attributes = 'Normal'
        }
        $folderItem = Get-Item $TestFolder -Force
        $folderItem.Attributes = 'Directory'

        [System.IO.File]::WriteAllText($iniPath, $iniContent, [System.Text.Encoding]::Unicode)
        $item = Get-Item $iniPath -Force
        $item.Attributes = 'Hidden', 'System'

        $folderItem = Get-Item $TestFolder -Force
        $currentAttrs = $folderItem.Attributes
        if (-not $currentAttrs.HasFlag([IO.FileAttributes]::System)) {
            $folderItem.Attributes = $currentAttrs -bor [IO.FileAttributes]::System
        }

        $code = @'
using System;
using System.Runtime.InteropServices;
public class ShellNotify {
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern void SHChangeNotify(int wEventId, int uFlags, IntPtr dwItem1, IntPtr dwItem2);
    public static void Refresh() {
        SHChangeNotify(0x08000000, 0x0000, IntPtr.Zero, IntPtr.Zero);
    }
}
'@
        Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
        [ShellNotify]::Refresh()

        Write-Host ""
        Write-Host "RESOURCE: $resource" -ForegroundColor Yellow
        Write-Host "Check File Explorer (press F5). Does '$(Split-Path $TestFolder -Leaf)' appear BLANK?" -ForegroundColor Cyan
        Write-Host "[Y] Yes - this is the correct resource!" -ForegroundColor Green
        Write-Host "[N] No - try next" -ForegroundColor Red
        Write-Host "[Q] Quit" -ForegroundColor Red

        $response = Read-Host "Choice (Y/N/Q)"

        if ($response.ToUpper() -eq 'Y') {
            Write-Host "SUCCESS! Use this resource ID: $resource" -ForegroundColor Green
            break
        }
        elseif ($response.ToUpper() -eq 'Q') {
            break
        }
    }

    Remove-Item $TestFolder -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Test folder removed." -ForegroundColor Gray
}