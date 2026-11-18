function Test-AdminRights {
    <#
    .SYNOPSIS
        Checks if the current process has Administrator privileges.
    #>
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}