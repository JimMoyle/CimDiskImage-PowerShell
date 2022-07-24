Describe 'Get-CimDiskImage' {
    BeforeAll {
        . .\functions\Public\Get-CimDiskImage.ps1

        $guid = 'ce263706-b0e8-43fa-9ab8-aae9874ceb9a'
        $deviceId = "\\?\Volume{$guid}\"
        $path = 'TestDrive:\MyMountPoint'
        $volume = [PSCustomObject]@{
            Name       = $path
            DeviceId   = $deviceId
            FileSystem = 'cimfs'
        }

        Mock -CommandName Get-CimInstance -MockWith { $volume }
    }
    Context 'Input' {

        It 'Runs With no Params' {
            Get-CimDiskImage -ErrorAction Stop | Select-Object -ExpandProperty DeviceId | Should -Be $deviceId
        }
        It 'Takes Path Parameter Input' {
            Get-CimDiskImage -Path $path -ErrorAction Stop | Select-Object -ExpandProperty DeviceId | Should -Be $deviceId
        }

        It 'Takes DeviceId Parameter Input' {
            Get-CimDiskImage -DeviceId $deviceId -ErrorAction Stop | Select-Object -ExpandProperty DeviceId | Should -Be $deviceId
        }

        It 'Takes Positional Input' {
            Get-CimDiskImage $path -ErrorAction Stop | Select-Object -ExpandProperty DeviceId | Should -Be $deviceId
        }

        It 'Takes Pipeline Input by type' {
            $path   | Get-CimDiskImage -ErrorAction Stop | Select-Object -ExpandProperty DeviceId | Should -Be $deviceId
        }

        It 'Takes Pipeline Input by PropertyName' {
            $pipe = [PSCustomObject]@{
                Path = $path
            }
            $pipe | Get-CimDiskImage -ErrorAction Stop | Select-Object -ExpandProperty DeviceId | Should -Be $deviceId
        }

        It 'Takes Pipeline Input by PropertyName' {
            $pipe = [PSCustomObject]@{
                DeviceId = $deviceId
            }
            $pipe | Get-CimDiskImage -ErrorAction Stop | Select-Object -ExpandProperty DeviceId | Should -Be $deviceId
        }

        It 'Takes Pipeline Input by PropertyName Alias Name' {
            $pipe = [PSCustomObject]@{
                Name = $path
            }
            $pipe | Get-CimDiskImage -ErrorAction Stop | Select-Object -ExpandProperty DeviceId | Should -Be $deviceId
        }

        It 'Takes Pipeline Input by PropertyName Alias FullName' {
            $pipe = [PSCustomObject]@{
                FullName = $path
            }
            $pipe | Get-CimDiskImage -ErrorAction Stop | Select-Object -ExpandProperty DeviceId | Should -Be $deviceId
        }
    }
    Context 'Logic' {
        It 'Runs through switch' {
            Get-CimDiskImage -ErrorAction Stop | Select-Object -ExpandProperty DeviceId | Should -Be $deviceId
        }

    }
    Context 'Output' {
        It 'Gives DeviceId' {
            Get-CimDiskImage -ErrorAction Stop | Select-Object -ExpandProperty DeviceId | Should -Be $deviceId
        }
    }
}