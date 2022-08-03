# Get-CimDiskImage        
        
Gets information about mounted cimfs disk image(s) on your system.

## Syntax

```
Get-CimDiskImage 
    [-DeviceId <String>]
    [<CommonParameters>]
```

```
Get-CimDiskImage 
    [[-Path] <String>] 
    [<CommonParameters>]
```

## Description
When the volume DeviceId or Mount Point is supplied, information about that disk will be returned, if no parameters are supplied all cimfs disks will be returned.

## Examples


### EXAMPLE 1:

```
Get-CimDiskImage
```

Returns details about all cimfs volumes currently mounted.

### EXAMPLE 2:

```
Get-CimDiskImage -DeviceId '\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\'
```
Returns the details for the cimfs volume with the sepcified DeviceId


### EXAMPLE 3:

```
Get-CimDiskImage -Path C:\MyMountPoint
```
Returns the details for the cimfs volume with the specified MountPath

### EXAMPLE 4:

```
Get-CimDiskImage -Path X:
```
Returns the details for the cimfs volume with the specified Drive

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
