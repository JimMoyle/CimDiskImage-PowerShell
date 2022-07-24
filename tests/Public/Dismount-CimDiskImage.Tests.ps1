Describe 'Dismount-CimDiskImage' {
    BeforeAll {
        . .\functions\Public\Dismount-CimDiskImage.ps1

        $guid = 'ce263706-b0e8-43fa-9ab8-aae9874ceb9a'
        $deviceId = "\\?\Volume{$guid}\"
        $path = 'TestDrive:\MyMountPoint'
        $volume = [PSCustomObject]@{
            Name       = $path
            DeviceId   = $deviceId
            FileSystem = 'cimfs'
        }
        $volumeNoMount = [PSCustomObject]@{
            Name       = $deviceId
            DeviceId   = $deviceId
            FileSystem = 'cimfs'
        }
        function mockdismount {}

        Mock -CommandName Get-CimInstance -MockWith { $volumeNoMount }
        Mock -CommandName mockdismount -MockWith { [PSCustomObject]@{ ReturnValue = 0 } }
    }


    Context 'Input' {

        It 'Takes Parameter Input' {
            Dismount-CimDiskImage -DeviceId $deviceId | Should -BeNullOrEmpty
        }

        It 'Takes Positional Input' {
            Dismount-CimDiskImage $deviceId | Should -BeNullOrEmpty
        }

        It 'Takes Pipeline Input by type' {
            $deviceId  | Dismount-CimDiskImage | Should -BeNullOrEmpty
        }

        It 'Takes Pipeline Input by PropertyName' {
            $pipe = [PSCustomObject]@{
                DeviceId = $deviceId
            }
            $pipe | Dismount-CimDiskImage  | Should -BeNullOrEmpty
        }
    }

    Context 'Logic' {

    }

    Context 'Output' {

    }
}