function Refresh-ShellIcons {
    <#
    .SYNOPSIS
        Notifies Windows Explorer to refresh icons and folder names.
    #>
    [CmdletBinding()]
    param(
        [switch]$Force
    )

    if (-not $Force) { return }

    try {
        $code = @'
using System;
using System.Runtime.InteropServices;
public class ShellNotify {
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern void SHChangeNotify(int wEventId, int uFlags, IntPtr dwItem1, IntPtr dwItem2);

    public static void Refresh() {
        SHChangeNotify(0x08000000, 0x0000, IntPtr.Zero, IntPtr.Zero); // SHCNE_ASSOCCHANGED
    }
}
'@
        Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
        [ShellNotify]::Refresh()

        if (Test-Path "$env:SystemRoot\system32\ie4uinit.exe") {
            Start-Process "$env:SystemRoot\system32\ie4uinit.exe" -ArgumentList "-show" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
        }

        Write-Log "Shell icon cache refresh initiated" -Level 'Success'
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Log "Shell refresh failed (non-critical): $errMsg" -Level 'Warning'
    }
}