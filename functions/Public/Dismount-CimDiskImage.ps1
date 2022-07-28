function Dismount-CimDiskImage {
    <#
        .SYNOPSIS
        Dismounts a cimfs disk image from your system.

        .DESCRIPTION
        When the volume DeviceId is supplied as a parameter it will remove the mount point if it exists and then dismount the cimfs disk image, will only work on cim files.  It will also dismount cimfs images with no pount point.

        .PARAMETER DeviceId
        Specifies the device ID of the volume, an example of which is: \\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\

        .INPUTS
        This function will take inputs via pipeline as string and by property name DeviceId

        .OUTPUTS
        None.

        .EXAMPLE
        PS> Dismount-CimDiskImage -DeviceId '\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\'
        Dismounts a volume by DeviceId
        .EXAMPLE
        PS> Dismount-CimDiskImage -DeviceId @('\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862e}\', '\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\')
        Dismounts a list of multiple volumes by DeviceId
        .EXAMPLE
        PS> Get-CimDiskImage C:\MyMountPoint | Dismount-CimDiskImage
        Dismounts a volume by path
        .EXAMPLE
        PS> Get-CimDiskImage | Dismount-CimDiskImage
        Dismounts all Cimfs volumes
        .EXAMPLE
        PS> Get-CimInstance -ClassName win32_volume | Where-Object { $_.FileSystem -eq 'cimfs' } | Dismount-CimDiskImage
        Dismounts all Cimfs volumes

    #>
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String[]]$DeviceId
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin
    process {
        #CimFS operations need Win32 API calls to make work, I can't find a lot of native powershell to do what we need.

        #loop through multiple DeviceIds
        foreach ($Id in $DeviceId) {
        
            #Grab details of the cimfs volume from the device ID
            $volume = Get-CimInstance -ClassName win32_volume | Where-Object { $_.DeviceID -eq $Id -and $_.FileSystem -eq 'cimfs' }
            if ($null -eq $volume) {
                Write-Error "Cound not find cimfs $Id on this computer"
                return
            }

            #Check if there is a mount point, if there is remove it. It's possible to have a volume attached without a mount point, but unlikely.
            if ($volume.DeviceID -ne $volume.Name) {
                #Get Delete mount point API call from kernel32.dll
                $removeMountPointSignature = @"
[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] public static extern bool DeleteVolumeMountPoint(string mountPoint);
"@

                $mountPointRemove = Add-Type -MemberDefinition $removeMountPointSignature -Name "RemoveVolMntPnt" -Namespace Win32Functions -PassThru

                #Function only present for mocking reasons in Pester
                function mockremovemountpoint { $mountPointRemove::DeleteVolumeMountPoint($volume.Name) }
                $removeMountPointResult = mockremovemountpoint; $remMntPntErr = [ComponentModel.Win32Exception][Runtime.InteropServices.Marshal]::GetLastWin32Error()
                #Should return True/False

                if (-not ($removeMountPointResult)) {
                    $remMntPntErrStr = "Could not remove mount point to {0} Error:'{1}' ErrorCode:{2}" -f $volume.Name, $remMntPntErr.Message, $remMntPntErr.NativeErrorCode
                    Write-Error $remMntPntErrStr
                    return
                }
            }

            #Use CIM (WMI) to dismount volume after the mount point is removed.
            #Function only present for mocking reasons in Pester
            function mockdismount { Invoke-CimMethod -InputObject $volume -MethodName DisMount -Arguments @{ Force = $true } }
            $disMountVolumeResult = mockdismount

            switch ($disMountVolumeResult.ReturnValue) {
                0 { break } #Success no action
                1 { Write-Error "Dismounting volume $($volume.DeviceId) failed with error 'Access Denied'"; break }
                2 { Write-Error "Dismounting volume $($volume.DeviceId) failed with error 'Volume Has Mount Points'"; break }
                3 { Write-Error "Dismounting volume $($volume.DeviceId) failed with error 'Volume Does Not Support The No-Autoremount State'"; break }
                4 { Write-Error "Dismounting volume $($volume.DeviceId) failed with error 'Force Option Required'"; break }
                Default { Write-Error "Dismounting volume $($volume.DeviceId) failed with unknown error. Consult https://docs.microsoft.com/previous-versions/windows/desktop/vdswmi/dismount-method-in-class-win32-volume for documentation" }
            }

            Write-Verbose "Volume $Id Removed"

        }

    } # process
    end {} # end
}  #function Dismount-CimDiskImage