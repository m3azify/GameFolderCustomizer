# Pester 5.x tests for GameFolderCustomizer
# Run with: Invoke-Pester -Path .\Tests\GameFolderCustomizer.Tests.ps1

BeforeAll {
    $modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'GameFolderCustomizer.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop
}

Describe 'Module' {
    It 'Should export Invoke-GameFolderCustomizer' {
        Get-Command Invoke-GameFolderCustomizer -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Remove-GameFolderCustomization' {
        Get-Command Remove-GameFolderCustomization -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should have Revert-GameFolderCustomization alias' {
        Get-Alias Revert-GameFolderCustomization -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Get-GameFolders' {
        Get-Command Get-GameFolders -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Find-GameIcon' {
        Get-Command Find-GameIcon -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Register-GameFolderLaunch' {
        Get-Command Register-GameFolderLaunch -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Test-IsFolderCustomized' {
        Get-Command Test-IsFolderCustomized -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should not export the developer diagnostic' {
        Get-Command Test-BlankNameResource -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }
}

Describe 'Get-DefaultConfig' {
    It 'Should load the config file' {
        $config = InModuleScope GameFolderCustomizer { Get-DefaultConfig }
        $config.SystemFolders | Should -Contain '$RECYCLE.BIN'
        $config.DriveLetter | Should -Be 'D:'
    }
}

Describe 'Register-GameFolderLaunch' {
    It 'Should not throw with -WhatIf' {
        { Register-GameFolderLaunch -WhatIf } | Should -Not -Throw
    }
    It 'Should not throw with -Unregister -WhatIf' {
        { Register-GameFolderLaunch -Unregister -WhatIf } | Should -Not -Throw
    }
}

Describe 'Create-DesktopIni launch support' {
    BeforeAll {
        $script:LaunchTestRoot = Join-Path $PSScriptRoot '_LaunchPesterTest'
        $script:LaunchTestFolder = Join-Path $script:LaunchTestRoot 'Test Game'
    }

    BeforeEach {
        if (Test-Path -LiteralPath $script:LaunchTestRoot) {
            Get-ChildItem -LiteralPath $script:LaunchTestRoot -Force -Recurse -ErrorAction SilentlyContinue |
                ForEach-Object { try { $_.Attributes = [IO.FileAttributes]::Normal } catch {} }
            Remove-Item -LiteralPath $script:LaunchTestRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
        New-Item -ItemType Directory -Path $script:LaunchTestFolder -Force | Out-Null
    }

    AfterEach {
        if (Test-Path -LiteralPath $script:LaunchTestRoot) {
            Get-ChildItem -LiteralPath $script:LaunchTestRoot -Force -Recurse -ErrorAction SilentlyContinue |
                ForEach-Object { try { $_.Attributes = [IO.FileAttributes]::Normal } catch {} }
            Remove-Item -LiteralPath $script:LaunchTestRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Should write DirectoryClass and GameExe when launch is enabled' {
        $exe = Join-Path $script:LaunchTestFolder 'TestGame.exe'
        [System.IO.File]::WriteAllBytes($exe, [byte[]](0..10))
        $global:LaunchTestData = @{ Folder = $script:LaunchTestFolder; Exe = $exe }
        InModuleScope GameFolderCustomizer {
            Create-DesktopIni -FolderPath $global:LaunchTestData.Folder -IconResource $global:LaunchTestData.Exe -SkipInteractive -BlankNameMethod DesktopIni -BlankNameResources @('') -EnableLaunch -GameExe $global:LaunchTestData.Exe | Out-Null
        }
        $ini = [System.IO.File]::ReadAllText((Join-Path $script:LaunchTestFolder 'desktop.ini'), [System.Text.Encoding]::Unicode)
        $ini | Should -Match 'DirectoryClass=GameFolderCustomizer.GameFolder'
        $ini | Should -Match 'GameExe='
    }

    It 'Should omit launch keys when launch is disabled' {
        $exe = Join-Path $script:LaunchTestFolder 'TestGame.exe'
        [System.IO.File]::WriteAllBytes($exe, [byte[]](0..10))
        $global:LaunchTestData = @{ Folder = $script:LaunchTestFolder; Exe = $exe }
        InModuleScope GameFolderCustomizer {
            Create-DesktopIni -FolderPath $global:LaunchTestData.Folder -IconResource $global:LaunchTestData.Exe -SkipInteractive -BlankNameMethod DesktopIni -BlankNameResources @('') | Out-Null
        }
        $ini = [System.IO.File]::ReadAllText((Join-Path $script:LaunchTestFolder 'desktop.ini'), [System.Text.Encoding]::Unicode)
        $ini | Should -Not -Match 'DirectoryClass'
        $ini | Should -Not -Match 'GameExe'
    }
}

Describe 'Write-Log' {
    It 'Should not throw on valid input' {
        InModuleScope GameFolderCustomizer {
            { Write-Log -Message "Test message" -Level 'Info' } | Should -Not -Throw
        }
    }
    It 'Should accept all valid log levels' {
        InModuleScope GameFolderCustomizer {
            foreach ($level in @('Info', 'Warning', 'Error', 'Success', 'Debug')) {
                { Write-Log -Message "Test" -Level $level } | Should -Not -Throw
            }
        }
    }
}

Describe 'Get-GameFolders' {
    It 'Should return empty array for non-existent path' {
        $result = Get-GameFolders -RootPath 'Z:\NonExistentDrive\'
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Resolve-IconPath' {
    It 'Should return exe paths unchanged' {
        InModuleScope GameFolderCustomizer {
            $result = Resolve-IconPath -IconPath 'C:\test\game.exe'
            $result | Should -Be 'C:\test\game.exe'
        }
    }
    It 'Should return ico paths unchanged' {
        InModuleScope GameFolderCustomizer {
            $result = Resolve-IconPath -IconPath 'C:\test\icon.ico'
            $result | Should -Be 'C:\test\icon.ico'
        }
    }
}

Describe 'Calculate-IconScore' {
    It 'Should score main executables higher' {
        InModuleScope GameFolderCustomizer {
            $mockFile = [System.IO.FileInfo]::new('C:\test\game.exe')
            $score = Calculate-IconScore -File $mockFile -Pattern '*.exe'
            $score | Should -BeGreaterThan 100
        }
    }
    It 'Should penalize uninstallers' {
        InModuleScope GameFolderCustomizer {
            $mockFile = [System.IO.FileInfo]::new('C:\test\uninstall.exe')
            $score = Calculate-IconScore -File $mockFile -Pattern '*.exe'
            $score | Should -BeLessThan 100
        }
    }
}

Describe 'Test-IsFolderCustomized' {
    BeforeAll {
        $script:GuardTestRoot = Join-Path $PSScriptRoot '_CustomizedGuardTest'
    }

    BeforeEach {
        if (Test-Path -LiteralPath $script:GuardTestRoot) {
            Get-ChildItem -LiteralPath $script:GuardTestRoot -Force -Recurse -ErrorAction SilentlyContinue |
                ForEach-Object { try { $_.Attributes = [IO.FileAttributes]::Normal } catch {} }
            Remove-Item -LiteralPath $script:GuardTestRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
        New-Item -ItemType Directory -Path $script:GuardTestRoot -Force | Out-Null
    }

    AfterEach {
        if (Test-Path -LiteralPath $script:GuardTestRoot) {
            Get-ChildItem -LiteralPath $script:GuardTestRoot -Force -Recurse -ErrorAction SilentlyContinue |
                ForEach-Object { try { $_.Attributes = [IO.FileAttributes]::Normal } catch {} }
            Remove-Item -LiteralPath $script:GuardTestRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Should return false for a plain folder' {
        $plain = Join-Path $script:GuardTestRoot 'Plain'
        New-Item -ItemType Directory -Path $plain -Force | Out-Null
        $global:GuardTestPath = $plain
        $result = InModuleScope GameFolderCustomizer { Test-IsFolderCustomized -FolderPath $global:GuardTestPath }
        $result | Should -BeFalse
    }

    It 'Should return true when desktop.ini has DirectoryClass' {
        $custom = Join-Path $script:GuardTestRoot 'Custom'
        New-Item -ItemType Directory -Path $custom -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $custom 'desktop.ini'), '[.ShellClassInfo]' + "`r`n" + 'DirectoryClass=GameFolderCustomizer.GameFolder', [Text.Encoding]::Unicode)
        $global:GuardTestPath = $custom
        $result = InModuleScope GameFolderCustomizer { Test-IsFolderCustomized -FolderPath $global:GuardTestPath }
        $result | Should -BeTrue
    }

    It 'Should return true for a blank-named folder' {
        $blank = ([char]0x00A0).ToString()
        $blankFolder = Join-Path $script:GuardTestRoot $blank
        New-Item -ItemType Directory -Path $blankFolder -Force | Out-Null
        $global:GuardTestPath = $blankFolder
        $result = InModuleScope GameFolderCustomizer { Test-IsFolderCustomized -FolderPath $global:GuardTestPath }
        $result | Should -BeTrue
    }
}

Describe 'Resolve-GameFolderItem' {
    It 'Should resolve a normal path' {
        $global:ResolveTestPath = 'C:\Windows'
        $result = InModuleScope GameFolderCustomizer { Resolve-GameFolderItem -FolderPath $global:ResolveTestPath }
        $result.FullName | Should -Be 'C:\Windows'
    }
}

Describe 'Get-BlankFolderName' {
    It 'Should return distinct blank names for successive calls' {
        $testRoot = Join-Path $PSScriptRoot '_BlankNameTest'
        if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
        New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
        $global:BlankNameTestRoot = $testRoot
        $names = InModuleScope GameFolderCustomizer {
            $first = Get-BlankFolderName -ParentPath $global:BlankNameTestRoot
            # Use MoveTo - New-Item with a trailing U+00A0 path resolves to the parent
            $tmp = Join-Path $global:BlankNameTestRoot 'tmp'
            New-Item -ItemType Directory -Path $tmp -Force | Out-Null
            (Get-Item -LiteralPath $tmp).MoveTo((Join-Path $global:BlankNameTestRoot $first))
            $second = Get-BlankFolderName -ParentPath $global:BlankNameTestRoot
            @($first, $second)
        }
        $names[0].Length | Should -Be 1
        $names[1].Length | Should -Be 2
        $names[0] | Should -Not -Be $names[1]

        # Clean up the blank-named folder via its DirectoryInfo object;
        # recursive Remove-Item on a U+00A0 name causes a stack overflow.
        $rootItem = Get-Item -LiteralPath $testRoot
        foreach ($child in @($rootItem.EnumerateFileSystemInfos())) {
            $child.Attributes = [IO.FileAttributes]::Normal -bor [IO.FileAttributes]::Directory
            $child.Delete($true)
        }
        $rootItem.Delete($true)
    }
}

Describe 'Find-GameIcon minimum score' {
    It 'Should reject candidates below MinimumScore' {
        $testRoot = Join-Path $PSScriptRoot '_IconScoreTest'
        if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
        New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $testRoot 'tiny.exe'), [byte[]](0..10))
        $global:IconScoreTestPath = $testRoot
        $result = InModuleScope GameFolderCustomizer {
            Find-GameIcon -FolderPath $global:IconScoreTestPath -Preference ExeOnly -MinimumScore 500
        }
        $result | Should -BeNullOrEmpty
        Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Get-RenamedIconPath' {
    It 'Should rewrite the icon path when folder was renamed' {
        InModuleScope GameFolderCustomizer {
            $result = Get-RenamedIconPath `
                -IconResource 'D:\Sin Spire\Game\game.exe' `
                -OriginalPath 'D:\Sin Spire' `
                -NewPath ('D:\' + [char]0x00A0) `
                -WasRenamed
            $result | Should -Be ('D:\' + [char]0x00A0 + '\Game\game.exe')
        }
    }
    It 'Should leave the icon path unchanged when no rename occurred' {
        InModuleScope GameFolderCustomizer {
            $result = Get-RenamedIconPath `
                -IconResource 'D:\Sin Spire\Game\game.exe' `
                -OriginalPath 'D:\Sin Spire' `
                -NewPath 'D:\Other'
            $result | Should -Be 'D:\Sin Spire\Game\game.exe'
        }
    }
    It 'Should leave unrelated icon paths unchanged' {
        InModuleScope GameFolderCustomizer {
            $result = Get-RenamedIconPath `
                -IconResource 'C:\Icons\game.ico' `
                -OriginalPath 'D:\Sin Spire' `
                -NewPath ('D:\' + [char]0x00A0) `
                -WasRenamed
            $result | Should -Be 'C:\Icons\game.ico'
        }
    }
}
