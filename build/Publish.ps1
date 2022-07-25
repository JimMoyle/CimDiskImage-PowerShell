$ModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'Release'
Publish-Module -Path $ModulePath -NuGetApiKey $Env:APIKEY