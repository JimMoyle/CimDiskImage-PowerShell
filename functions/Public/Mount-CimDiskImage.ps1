function Mount-CimDiskImage {
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

        #Mount the volume image flag needs to be 0
        $mountResult = $CimFSMount::CimMountImage($folder, $fileName, 0, $guidRef)
        If ($mountResult -ne 0) {
            Write-Error "Mounting $ImagePath to volume failed with error code $mountResult"
            return
        }

        $volume = Get-CimInstance -ClassName win32_volume | Where-Object { $_.DeviceID -eq "\\?\Volume{$guid}\" }

        #Create mount point for volume to folder
        $mountPointResult = Invoke-CimMethod -InputObject $volume -MethodName AddMountPoint -Arguments @{ Directory = $MountPath }
        If ( $mountPointResult.ReturnValue -ne 0) {
            Write-Error "Creating mount point to $MountPath failed with error code $mountResult"
            #TODO Insert Dismount here
            return
        }

        Write-Verbose "Mounted $ImagePath to $MountPath"

        #Dump out with no object if sucessful as per guidelines
        If (-not ($Passthru)) {
            return
        }

        #This should be all you need to find it again
        #Maybe casting guid to type uneccessary, but it might help with future pipelines
        $out = [PSCustomObject]@{
            DeviceId   = $volume.DeviceID
            FileSystem = $volume.FileSystem
            Path       = $MountPath
            Guid       = [guid]$guid
        }

        Write-Output $out
        
    } # process
    end {} # end
}  #function Mount-CimDiskImage