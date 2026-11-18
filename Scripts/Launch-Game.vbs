' Hidden launcher for the "Launch Game" shell verb.
' Avoids the PowerShell console window flashing when a folder is double-clicked.
' Usage: wscript.exe "Launch-Game.vbs" "<folder path>"

Option Explicit

Dim objShell, objFSO, scriptPath, psCmd, folderPath

If WScript.Arguments.Count < 1 Then
    WScript.Quit 1
End If

folderPath = WScript.Arguments(0)

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

scriptPath = objFSO.BuildPath(objFSO.GetParentFolderName(WScript.ScriptFullName), "Launch-Game.ps1")

psCmd = "powershell.exe -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & scriptPath & """ """ & folderPath & """"

' Window style 0 = hidden, do not wait for completion
objShell.Run psCmd, 0, False
