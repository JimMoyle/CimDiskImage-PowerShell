function Mount-CimDiskImage {
    [CmdletBinding()]

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