# CimDiskImage-PowerShell

PowerShell module to Mount, Dismount and discover CimFS disk images.

Use Import-Module CimDiskImage to use this module.

Cim files are read only disk images. You can read more about [CimFS](https://docs.microsoft.com/windows/win32/api/_cimfs/) on the Microsoft docs site.

This module uses the CimFS driver to mount and ummount the Cim image files.

Mounting a Cim file to a drive letter is not currently supported.  The Cim disk image must be mounted to an existing empty folder.

https://stackoverflow.com/questions/31908564/easy-way-to-add-copy-to-clipboard-to-github-markdown