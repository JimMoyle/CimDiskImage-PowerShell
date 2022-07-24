Describe 'Dismount-CimDiskImage' {
    BeforeAll {
        . .\functions\Public\Dismount-CimDiskImage.ps1

        $guid = 'ce263706-b0e8-43fa-9ab8-aae9874ceb9a'
        $deviceId = "\\?\Volume{$guid}\"

        $volumeNoMount = [PSCustomObject]@{
            Name       = $deviceId
            DeviceId   = $deviceId
            FileSystem = 'cimfs'
        }
        function mockdismount {}
        function mockremovemountpoint {}

        Mock -CommandName Get-CimInstance -MockWith { $volumeNoMount }
        Mock -CommandName mockdismount -MockWith { [PSCustomObject]@{ ReturnValue = 0 } }
        Mock -CommandName mockremovemountpoint -MockWith { $true }
    }


    Context 'Input' {

        It 'Takes Parameter Input' {
            Dismount-CimDiskImage -DeviceId $deviceId -ErrorAction Stop | Should -BeNullOrEmpty
        }

        It 'Takes Positional Input' {
            Dismount-CimDiskImage $deviceId -ErrorAction Stop | Should -BeNullOrEmpty
        }

        It 'Takes Pipeline Input by type' {
            $deviceId  | Dismount-CimDiskImage -ErrorAction Stop | Should -BeNullOrEmpty
        }

        It 'Takes Pipeline Input by PropertyName' {
            $pipe = [PSCustomObject]@{
                DeviceId = $deviceId
            }
            $pipe | Dismount-CimDiskImage -ErrorAction Stop | Should -BeNullOrEmpty
        }
    }

    Context 'Logic' {

        BeforeAll {
            $path = 'TestDrive:\MyMountPoint'
            $volume = [PSCustomObject]@{
                Name       = $path
                DeviceId   = $deviceId
                FileSystem = 'cimfs'
            }
            Mock -CommandName Get-CimInstance -MockWith { $volume }
        }

        BeforeEach {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
            $pesterVar = $null
        }

        It 'Should dismount volume and remove mount point' {
            Dismount-CimDiskImage $deviceId -ErrorAction Stop | Should -BeNullOrEmpty
        }

        It 'Errors when cimfs volume is not found' {
            $volumeNtfs = [PSCustomObject]@{
                Name       = $path
                DeviceId   = $deviceId
                FileSystem = 'NTFS'
            }
            Mock -CommandName Get-CimInstance -MockWith { $volumeNtfs }
            Dismount-CimDiskImage $deviceId -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "Cound not find cimfs*"
        }

        It 'Errors when mountpoint removal fails' {
            Mock -CommandName mockremovemountpoint -MockWith { $false}
            Dismount-CimDiskImage $deviceId -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "Could not remove mount point to*"
        }

        It 'Errors when volume dismount fails with Access denied' -Tag 'Now' {
            Mock -CommandName mockdismount -MockWith { [PSCustomObject]@{ ReturnValue = 1 } }
            Dismount-CimDiskImage $deviceId -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "*Access Denied*"
        }

        It 'Errors when volume dismount fails with Volume Has Mount Points' -Tag 'Now' {
            Mock -CommandName mockdismount -MockWith { [PSCustomObject]@{ ReturnValue = 2 } }
            Dismount-CimDiskImage $deviceId -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "*Volume Has Mount Points*"
        }

        It 'Errors when volume dismount fails with Volume Does Not Support The No-Autoremount State' -Tag 'Now' {
            Mock -CommandName mockdismount -MockWith { [PSCustomObject]@{ ReturnValue = 3 } }
            Dismount-CimDiskImage $deviceId -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "*Volume Does Not Support The No-Autoremount State*"
        }

        It 'Errors when volume dismount fails with Force Option Required' -Tag 'Now' {
            Mock -CommandName mockdismount -MockWith { [PSCustomObject]@{ ReturnValue = 4 } }
            Dismount-CimDiskImage $deviceId -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "*Force Option Required*"
        }

        It 'Errors when volume dismount fails with unknown error' -Tag 'Now' {
            Mock -CommandName mockdismount -MockWith { [PSCustomObject]@{ ReturnValue = 5 } }
            Dismount-CimDiskImage $deviceId -ErrorVariable pesterVar -ErrorAction SilentlyContinue
            $pesterVar[0] | Should -BeLike "*unknown error*"
        }
    }

    Context 'Output' {
        It 'Should not have output' {
            Dismount-CimDiskImage $deviceId -ErrorAction Stop | Should -BeNullOrEmpty
        }
    }
}