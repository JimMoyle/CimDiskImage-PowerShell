# Mount-CimDiskImage        
        
Mounts a cimfs disk image to your system. 

## Syntax

```
Mount-CimDiskImage  
    [-ImagePath] <String> 
    [-DriveLetter] <String> 
    [-PassThru]
    [<CommonParameters>]
```

```
Mount-CimDiskImage  
    [-ImagePath] <String> 
    [-MountPath] <String> 
    [-PassThru]
    [<CommonParameters>]
```

## Description
This will mount a cim file to a drive letter or directory of your choosing, allowing you to browse the contents. Remember to use the -Passthru Parameter to get output

## Examples

### EXAMPLE 1:

```
Mount-CimDiskImage -ImagePath C:\MyCimFile.cim -MountPath C:\MyMountPath -Passthru
```
Mounts the Cim file to a local directory

### EXAMPLE 2:

```
Mount-CimDiskImage C:\MyCimFile.cim -MountPath C:\MyMountPath
```
Mounts the Cim file to a local directory


### EXAMPLE 3:

```
Mount-CimDiskImage C:\MyCimFile.cim -MountPath C:\MyMountPath
```
Mounts the Cim file to a local directory

### EXAMPLE 4:

```
Get-CimDiskImage -Path X:
```
Returns the details for the cimfs volume with the spcified Drive

### EXAMPLE 5:

```
Mount-CimDiskImage C:\MyCimFile.cim -DriveLetter X: | Get-CimDiskImage
```
Returns the details for the cimfs volume which has just been mounted

## Parameters

### -Path

Specifies the mount point of the volume, an example of which is: C:\MyMountPoint or a drive like X:

|  | |
|---|---|
| Type:    | String |
| Aliases: | Fullname, Name |
| Position: | 0 |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |

### -DeviceId

Specifies the device ID of the volume, an example of which is: \\\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\


|  | |
|---|---|
| Type:    | String |
| Position: | Named |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
