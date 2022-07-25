$ModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'CimDiskImage'
Publish-Module -Path $ModulePath -NuGetApiKey $Env:APIKEY