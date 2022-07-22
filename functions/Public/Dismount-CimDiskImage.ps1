function Dismount-CimDiskImage {
    [CmdletBinding()]

    <#
        .SYNOPSIS
        Dismounts a cimfs disk image from your system.

        .DESCRIPTION
        When the volume DeviceId is supplied as a parameter it will remove the mount point if it exists and then dismount the cimfs disk image, will only work on cim files.

        .PARAMETER DeviceId
        Specifies the device ID of the volume, an example of which is: \\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\

        .INPUTS
        This function will take inputs via pipeline as string and by property name DeviceId

        .OUTPUTS
        None.

        .EXAMPLE
        PS> Dismount-CimDiskImage -DeviceId '\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\'

        .EXAMPLE
        PS> Get-CimDiskImage C:\MyMountPoint | Dismount-CimDiskImage

        .EXAMPLE
        PS> Get-CimInstance -ClassName win32_volume | Where-Object { $_.FileSystem -eq 'cimfs' } | Dismount-CimDiskImage

    #>

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$DeviceId
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin
    process {
        #CimFS operations need Win32 API calls to make work, I can't find a lot of native powershell to do what we need.

        #Grab details of the cimfs volume from the device ID
        $volume = Get-CimInstance -ClassName win32_volume | Where-Object { $_.DeviceID -eq $DeviceId -and $_.FileSystem -eq 'cimfs' }
        if ($null -eq $volume) {
            Write-Error "Cound not find cimfs $DeviceId on this computer"
            return
        }

        #Check if there is a mount point, if there is remove it. It's possible to have a volume attached without a mount point, but unlikely.
        if ($volume.DeviceID -ne $volume.Name) {
            #Get Delete mount point API call from kernel32.dll
            $removeMountPointSignature = @"
[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] public static extern bool DeleteVolumeMountPoint(string mountPoint);
"@

            $mountPointRemove = Add-Type -MemberDefinition $removeMountPointSignature -Name "RemoveVolMntPnt" -Namespace Win32Functions -PassThru

            $removeMountPointResult = $mountPointRemove::DeleteVolumeMountPoint($volume.Name)
            #Should return True/False
            
            if (-not ($removeMountPointResult)) {
                Write-Error "Could not remove mount point to $($volume.Name)"
                return
            }

        }

        #Use CIM(WMI) to dismount volume after the mount point is removed.
        $disMountVolumeResult = Invoke-CimMethod -InputObject $volume -MethodName DisMount -Arguments @{ Force = $true }
        If ($disMountVolumeResult.ReturnValue -ne 0) {
            Write-Error "Could not DisMount volume $($volume.DeviceId)"
            return
        }

        Write-Verbose "Volume $DeviceId Removed"
        
    } # process
    end {} # end
}  #function Dismount-CimDiskImage