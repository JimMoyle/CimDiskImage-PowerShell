function Get-CimDiskImage {
    <#
        .SYNOPSIS
        Gets information about mounted cimfs disk image(s) on your system.

        .DESCRIPTION
        When the volume DeviceId or Mount Point is supplied information about that disk will be returned, if no parameters are supplied all cimfs disks will be returned.

        .PARAMETER DeviceId
        Specifies the device ID of the volume, an example of which is: \\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\

        .PARAMETER Path
        Specifies the mount point of the volume, an example of which is: C:\MyMountPoint

        .INPUTS
        This function will take inputs via pipeline as string and by property name DeviceId

        .OUTPUTS
        Microsoft.Management.Infrastructure.CimInstance#root/cimv2/Win32_Volume

        .EXAMPLE
        PS> Get-CimDiskImage -DeviceId '\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\'
        .EXAMPLE
        PS> Get-CimDiskImage -Path C:\MyMountPoint
        .EXAMPLE
        PS> Get-CimDiskImage

    #>
    [CmdletBinding(DefaultParameterSetName = 'DeviceId')]

    Param (
        [Parameter(
            ParameterSetName = 'Path',
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true
        )]
        [Alias('Fullname', 'Name')]
        [System.String]$Path,

        [Parameter(
            ParameterSetName = 'DeviceId',
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$DeviceId
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin
    process {
        #Get All the cimfs volumes
        $volume = Get-CimInstance -ClassName win32_volume | Where-Object { $_.FileSystem -eq 'cimfs' }

        #Filter (or not) based on parameter, param sets used so you can't put both deviceID and path in as params
        switch ($false) {
            ( [String]::IsNullOrEmpty($Path) ) {
                $out = $volume | Where-Object { $_.Name.TrimEnd('\') -eq $Path.TrimEnd('\') }
                Write-Output $out
                break
            }
            ( [String]::IsNullOrEmpty($DeviceId) ) {
                $out = $volume | Where-Object { $_.DeviceId -eq $DeviceId }
                Write-Output $out
                break
            }
            Default {
                Write-Output $volume
            }
        }
    } # process
    end {} # end
}  #function Get-CimDiskImage