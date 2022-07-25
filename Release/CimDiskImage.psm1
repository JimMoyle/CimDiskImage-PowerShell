#Requires -Version 5.1
#Requires -RunAsAdministrator

function Dismount-CimDiskImage {
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
        PS> Dismount-CimDiskImage -DeviceId @('\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862e}\', '\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\')
        .EXAMPLE
        PS> Get-CimDiskImage C:\MyMountPoint | Dismount-CimDiskImage
        .EXAMPLE
        PS> Get-CimInstance -ClassName win32_volume | Where-Object { $_.FileSystem -eq 'cimfs' } | Dismount-CimDiskImage

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
                $removeMountPointResult = mockremovemountpoint
                #Should return True/False

                if (-not ($removeMountPointResult)) {
                    Write-Error "Could not remove mount point to $($volume.Name)"
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

function Get-CimDiskImage {
    <#
        .SYNOPSIS
        Gets information about a mounted cimfs disk image on your system.

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

function Mount-CimDiskImage {
    <#
        .SYNOPSIS
        Mounts a cimfs disk image to your system.

        .DESCRIPTION
        This will mount a cim file to a directory of your choosing allowing you to browse the contents, mounting to a drive letter is not supported.  Remember to use the -Passthru Parameter to get output

        .PARAMETER ImagePath
        Specifies the location of the cim file to be mounted.
        
        .PARAMETER MountPath
        Specifies the local folder to which the cim file will be mounted.  This folder needs to exist prior to attempting to mount a cim file to it.

        .PARAMETER PassThru
        Will output details of the mount operation to the pipeline.  Otherwise there will be no output

        .INPUTS
        This function will take inputs via pipeline by type and property and by position.

        .OUTPUTS
        PSCustomObject containing 'DeviceId', 'FileSystem', 'Path' and 'Guid'

        .EXAMPLE
        PS> Mount-CimDiskImage -ImagePath C:\MyCimFile.cim -MountPath C:\MyMountPath -Passthru
        .EXAMPLE
        PS> Mount-CimDiskImage C:\MyCimFile.cim c:\MyMountPath
        .EXAMPLE
        PS> Get-ChildItem C:\MyCimFile.cim | Mount-CimDiskImage -MountPath C:\MyMountPath -Passthru
        .EXAMPLE
        PS> 'C:\MyCimFile.cim' | Mount-CimDiskImage -MountPath C:\MyMountPath

    #>
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [Alias('FullName')]
        [System.String]$ImagePath,

        [Parameter(
            Position = 1,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$MountPath,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [Switch]$PassThru
    )

    begin {
        Set-StrictMode -Version Latest
        #requires -RunAsAdministrator
    } # begin
    process {
        #CimFS operations need a lot of Win32 API calls to make work, I can't find a lot of native powershell to do what we need.

        #Is the file there
        If (-not (Test-Path $ImagePath)) {
            Write-Error "$ImagePath does not exist"
            return
        }

        #Is the mounting folder there?  Maybe add force param to create folder.
        If (-not (Test-Path $MountPath)) {
            Write-Error "$MountPath does not exist"
            return
        }

        #Let's get the full file information, we'll need it later
        $fileInfo = Get-ChildItem $ImagePath

        #Is it a Cim file?
        If ($fileInfo.Extension -ne '.cim') {
            Write-Error "$ImagePath is not a Cim file"
            return
        }

        #Grab some file information in named variables
        $fileName = $fileInfo.Name
        $folder = $fileInfo.Directory.FullName
        
        #We need to supply a random guid for the mount param (needs to be cast as a ref to interact with the API)
        $guid = (New-Guid).Guid
        [ref]$guidRef = $guid
        
        #Get the method from the Cimfs.dll (don't change formatting)
        $mountSignature = @"
[DllImport( "cimfs.dll", CharSet = CharSet.Unicode )] public static extern long CimMountImage(String imageContainingPath, String imageName, IntPtr mountImageFlags, ref Guid volumeId);
"@
        #Create object
        $CimFSMount = Add-Type -MemberDefinition $mountSignature -Name "CimFSMount" -Namespace Win32Functions -PassThru

        #This function is only here so I can mock it during pester testing.
        function mockmount {
            #Mount the volume image flag needs to be 0
            $CimFSMount::CimMountImage($folder, $fileName, 0, $guidRef)
        }
        $mountResult = mockmount
        If ($mountResult -ne 0) {
            Write-Error "Mounting $ImagePath to volume failed with error code $mountResult"
            return
        }
        
        $volume = Get-CimInstance -ClassName win32_volume | Where-Object { $_.DeviceID -eq "\\?\Volume{$guid}\" }

        #This function is only here so I can mock it during pester testing.
        #Create mount point for volume to folder
        function mockmountpoint { Invoke-CimMethod -InputObject $volume -MethodName AddMountPoint -Arguments @{ Directory = $MountPath } }
        $mountPointResult = mockmountpoint

        #Error codes and messages from https://docs.microsoft.com/previous-versions/windows/desktop/vdswmi/addmountpoint-method-in-class-win32-volume 
        switch ($mountPointResult.ReturnValue) {
            0 { break } #Success no action
            1 { Write-Error "Creating mount point to $MountPath failed with error 'Access Denied'"; break }
            2 { Write-Error "Creating mount point to $MountPath failed with error 'Invalid Argument'"; break }
            3 { Write-Error "Creating mount point to $MountPath failed with error 'Specified Directory Not Empty'"; break }
            4 { Write-Error "Creating mount point to $MountPath failed with error 'Specified Directory Not Found'"; break }
            5 { Write-Error "Creating mount point to $MountPath failed with error 'Volume Mount Points Not Supported'"; break }
            Default { Write-Error "Creating mount point to $MountPath failed with unknown error. Consult https://docs.microsoft.com/previous-versions/windows/desktop/vdswmi/addmountpoint-method-in-class-win32-volume for documentation" }
        }

        If ( $mountPointResult.ReturnValue -ne 0) {
            $volume.DeviceID | Dismount-CimDiskImage
            return
        }

        Write-Verbose "Mounted $ImagePath to $MountPath"

        #Dump out with no object if sucessful as per guidelines
        If (-not ($Passthru)) {
            return
        }

        #This should be all you need to find it again
        $out = [PSCustomObject]@{
            DeviceId   = $volume.DeviceID
            FileSystem = $volume.FileSystem
            Path       = $MountPath
            Guid       = $guid
        }

        Write-Output $out
        
    } # process
    end {} # end
}  #function Mount-CimDiskImage


