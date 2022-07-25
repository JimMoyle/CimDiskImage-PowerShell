$ModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'Release'
ls $ModulePath
Publish-Module -Path $ModulePath -NuGetApiKey $Env:APIKEY