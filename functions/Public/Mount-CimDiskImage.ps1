function Mount-CimDiskImage {
    <#
        .SYNOPSIS
        Mounts a cimfs disk image to your system.

        .DESCRIPTION
        This will mount a cim file to a drive letter or directory of your choosing, allowing you to browse the contents. Remember to use the -Passthru Parameter to get output

        .PARAMETER ImagePath
        Specifies the location of the cim file to be mounted.

        .PARAMETER DriveLetter
        Specifies the Drive letter which the cim file should be mounted to.  It can be in the format 'X:' or 'X:\'

        .PARAMETER MountPath
        Specifies the local folder to which the cim file will be mounted.  This folder needs to exist and be empty  prior to attempting to mount a cim file to it.

        .PARAMETER PassThru
        Will output details of the mount operation to the pipeline.  Otherwise there will be no output

        .INPUTS
        This function will take inputs via pipeline by type and property and by position.

        .OUTPUTS
        PSCustomObject containing 'DeviceId', 'FileSystem', 'Path' and 'Guid'

        .EXAMPLE
        PS> Mount-CimDiskImage -ImagePath C:\MyCimFile.cim -MountPath C:\MyMountPath -Passthru
        Mounts the Cim file to a local directory and sends the result to the pipeline
        .EXAMPLE
        PS> Mount-CimDiskImage C:\MyCimFile.cim C:\MyMountPath
        Mounts the Cim file to a local directory
        .EXAMPLE
        PS> Get-ChildItem C:\MyCimFile.cim | Mount-CimDiskImage -MountPath C:\MyMountPath -Passthru
        Mounts the Cim file to a local directory and sends the result to the pipeline
        .EXAMPLE
        PS> 'C:\MyCimFile.cim' | Mount-CimDiskImage -MountPath C:\MyMountPath

        .LINK
        https://github.com/JimMoyle/CimDiskImage-PowerShell/blob/main/Help/Mount-CimDiskImage.md

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
            ParameterSetName = 'ByLetter',
            Position = 1,
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$DriveLetter,

        [Parameter(
            ParameterSetName = 'ByPath',
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
        #CimFS operations need Win32 API calls to make work, I can't find a lot of native powershell to do what we need.

        #Is the file there
        If (-not (Test-Path $ImagePath)) {
            Write-Error "$ImagePath does not exist"
            return
        }

        switch ($PSCmdlet.ParameterSetName) {
            ByLetter {
                if ($DriveLetter -notmatch "^\w\:\\?$") {
                    Write-Error "$DriveLetter does not seem to be a drive letter. Example X: or X:\"
                    return
                }
                else {
                    $MountPath = $DriveLetter
                }
                break
            }
            ByPath {
                If (-not (Test-Path $MountPath)) {
                    Write-Error "$MountPath does not exist"
                    return
                }
                break
            }
            Default {}
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

        # Make sure the path ends with a single \ as the SetVolumeMountPoint api requires this
        $MountPath = $MountPath.TrimEnd('\') + '\'

        #We need to supply a random guid for the mount param (needs to be cast as a ref to interact with the API)
        $guid = (New-Guid).Guid
        [ref]$guidRef = $guid

        #Get the method from the Cimfs.dll (don't change formatting)
        $mountSignature = @"
[DllImport( "cimfs.dll", CharSet = CharSet.Unicode, SetLastError = true )] public static extern long CimMountImage(String imageContainingPath, String imageName, IntPtr mountImageFlags, ref Guid volumeId);
"@
        #Create object
        $CimFSMount = Add-Type -MemberDefinition $mountSignature -Name "CimFSMount" -Namespace Win32Functions -PassThru

        #This function is only here so I can mock it during pester testing.
        function mockmount {
            #Mount the volume image flag needs to be 0
            $CimFSMount::CimMountImage($folder, $fileName, 0, $guidRef)
        }
        $mountResult = mockmount; $mntErr = [ComponentModel.Win32Exception][Runtime.InteropServices.Marshal]::GetLastWin32Error()
        If ($mountResult -ne 0) {
            $mntErrStr = "Mounting {0} to volume failed with Error:'{1} ErrorCode:{2}'" -f $ImagePath, $mntErr.Message , $mntErr.NativeErrorCode
            Write-Error $mntErrStr
            return
        }

        $volume = Get-CimInstance -ClassName win32_volume | Where-Object { $_.DeviceID -eq "\\?\Volume{$guid}\" }

        $mountPointSignature = @"
[DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] public static extern bool SetVolumeMountPoint(string lpszVolumeMountPoint, string lpszVolumeName);
"@

        $mountPoint = Add-Type -MemberDefinition $mountPointSignature -Name "CimMountPoint" -Namespace Win32Functions -PassThru

        #This function is only here so I can mock it during pester testing.
        function mockmountpoint { $mountPoint::SetVolumeMountPoint($MountPath, $volume.DeviceID) }
        $mpResult = mockmountpoint; $mpError = [ComponentModel.Win32Exception][Runtime.InteropServices.Marshal]::GetLastWin32Error()

        If (-not ($mpResult)) {
            $mpErrStr = "Mounting {0} to {1} failed with Error:'{2}' ErrorCode:{3}" -f $volume.DeviceId, $mountPath , $mpError.Message, $mpError.NativeErrorCode
            Write-Error $mpErrStr
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