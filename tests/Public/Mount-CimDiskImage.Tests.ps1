

Describe -Name 'Mount-CimDiskImage' {
    BeforeAll {
        . .\functions\Public\Mount-CimDiskImage.ps1

        $guid = 'ce263706-b0e8-43fa-9ab8-aae9874ceb9a'
        $deviceId = "\\?\Volume{$guid}\"

        $realFile = 'Testdrive:\real.cim'
        $realMount = 'Testdrive:\Realmount'

        New-Item $realfile -ItemType file
        New-Item $realMount -ItemType directory

        function mockmount {}
        function mockmountpoint {}
        function Dismount-CimDiskImage {}

        #Mock Test-Path { $true }
        Mock -CommandName mockmount -MockWith { 0 }
        Mock -CommandName New-Guid -MockWith { [guid]$guid }
        Mock -CommandName Dismount-CimDiskImage {}
        Mock -CommandName Get-ChildItem -Mockwith {
            [PSCustomObject]@{
                Extension = '.cim'
                Name      = $realfile
                Directory = [PSCustomObject]@{
                    FullName = $realMount
                }
            }
        }
        Mock -CommandName Get-CimInstance -MockWith {          
            [PSCustomObject]@{
                DeviceId   = $deviceId
                FileSystem = 'cimfs'
            }
        }
        Mock -CommandName mockmountpoint -MockWith {
            [PSCustomObject]@{
                ReturnValue = 0
            }
        }
    }
    Context 'Input' {
        It 'Takes Parameter Input' {
            Mount-CimDiskImage -ImagePath $realFile -MountPath $realMount -ErrorAction Stop | Should -BeNullOrEmpty
        }

        It 'Takes Positional Input' {
            Mount-CimDiskImage $realFile $realMount -ErrorAction Stop | Should -BeNullOrEmpty
        }

        It 'Takes Pipeline Input by type' {
            $realFile  | Mount-CimDiskImage -MountPath $realMount -ErrorAction Stop | Should -BeNullOrEmpty
        }

        It 'Takes Pipeline Input by PropertyName' {
            $pipe = [PSCustomObject]@{
                ImagePath = $realFile
                MountPath = $realMount
                Passthru  = $false
            }
            $pipe | Mount-CimDiskImage -ErrorAction Stop | Should -BeNullOrEmpty
        }

        It 'Takes Pipeline Input by PropertyName Alias' {
            $pipe = [PSCustomObject]@{
                FullName  = $realFile
                MountPath = $realMount
                Passthru  = $false
            }
            $pipe | Mount-CimDiskImage -ErrorAction Stop | Should -BeNullOrEmpty
        }
    
    }
    Context 'Logic' {
        BeforeEach {
            $pesterVar = $null
        }

        It 'Errors when file is not found' {
            Mount-CimDiskImage TestDrive:\notExist.cim $realMount -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "* does not exist"
        }

        It 'Errors when Mount Folder is not found' {
            Mount-CimDiskImage $realFile 'Testdrive:\Notexist' -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "* does not exist"
        }

        It 'Errors when file is not cim' {
            Mock -CommandName Get-ChildItem -Mockwith {
                [PSCustomObject]@{
                    Extension = '.vhdx'
                    Name      = $realfile
                    Directory = [PSCustomObject]@{
                        FullName = $realMount
                    }
                }
            }
            Mount-CimDiskImage $realFile $realMount -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "* is not a Cim file"
        }

        It 'Errors when Mounting Fails' {
            Mock -CommandName mockmount -MockWith { 1 }
            Mount-CimDiskImage $realFile $realMount -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "Mounting * to volume failed with error code *"
        }

        It 'Errors Correctly when Creating MountPoint Fails with Access Denied' {
            Mock -CommandName mockmountpoint -MockWith { [PSCustomObject]@{ ReturnValue = 1 } }
            Mount-CimDiskImage $realFile $realMount -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "*Access Denied*"
        }

        It 'Errors Correctly when Creating MountPoint Fails with Invalid Argument' {
            Mock -CommandName mockmountpoint -MockWith { [PSCustomObject]@{ ReturnValue = 2 } }
            Mount-CimDiskImage $realFile $realMount -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "*Invalid Argument*"
        }

        It 'Errors Correctly when Creating MountPoint Fails with Specified Directory Not Empty' {
            Mock -CommandName mockmountpoint -MockWith { [PSCustomObject]@{ ReturnValue = 3 } }
            Mount-CimDiskImage $realFile $realMount -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "*Specified Directory Not Empty*"
        }

        It 'Errors Correctly when Creating MountPoint Fails with Specified Directory Not Found' {
            Mock -CommandName mockmountpoint -MockWith { [PSCustomObject]@{ ReturnValue = 4 } }
            Mount-CimDiskImage $realFile $realMount -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "*Specified Directory Not Found*"
        }

        It 'Errors Correctly when Creating MountPoint Fails with Volume Mount Points Not Supported' {
            Mock -CommandName mockmountpoint -MockWith { [PSCustomObject]@{ ReturnValue = 5 } }
            Mount-CimDiskImage $realFile $realMount -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "*Volume Mount Points Not Supported*"
        }
        It 'Errors Correctly when Creating MountPoint Fails with Unknown Error' {
            Mock -CommandName mockmountpoint -MockWith { [PSCustomObject]@{ ReturnValue = 6 } }
            Mount-CimDiskImage $realFile $realMount -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "*Unknown Error*"
        }
        
        
    }

    Context 'Output' {

        It 'Outputs DeviceId' {
            $pipe = [PSCustomObject]@{
                FullName  = $realFile
                MountPath = $realMount
                Passthru  = $true
            }
            $pipe | Mount-CimDiskImage -ErrorAction Stop | Select-Object -ExpandProperty DeviceId | Should -Be $deviceId
        }

        It 'Outputs FileSystem' {
            $pipe = [PSCustomObject]@{
                FullName  = $realFile
                MountPath = $realMount
                Passthru  = $true
            }
            $pipe | Mount-CimDiskImage -ErrorAction Stop | Select-Object -ExpandProperty FileSystem | Should -Be 'cimfs'
        }

        It 'Outputs MountPath' {
            $pipe = [PSCustomObject]@{
                FullName  = $realFile
                MountPath = $realMount
                Passthru  = $true
            }
            $pipe | Mount-CimDiskImage -ErrorAction Stop | Select-Object -ExpandProperty Path | Should -Be $pipe.MountPath
        }

        It 'Outputs Guid' {
            $pipe = [PSCustomObject]@{
                FullName  = $realFile
                MountPath = $realMount
                Passthru  = $true
            }
            $pipe | Mount-CimDiskImage -ErrorAction Stop | Select-Object -ExpandProperty Guid | Should -Be $guid
        }

    }
}