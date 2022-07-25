$buildFolder = '.\build'
$releaseFolder = '.\CimDiskImage'

#Get public and private function definition files.

$fileName = (Get-ChildItem ($buildFolder + '\*.psm1')).Name
$manifestFileInfo = Get-ChildItem ($buildFolder + '\*.psd1')
$manifest = $manifestFileInfo.Name

$defaultVersion = [version]::New((Get-Date -Format yyMM),1)
$currentVersion = [version](Test-ModuleManifest -Path $manifestFileInfo.FullName).Version
if ($defaultVersion -le $currentVersion){
    $currentVersion = [version]::New($currentVersion.Major,($currentVersion.Minor + 1))
}
else{
    $currentVersion = $defaultVersion
}

Update-ModuleManifest -Path $manifestFileInfo.FullName -ModuleVersion $currentVersion

$releaseFile = Join-Path $releaseFolder $fileName

Set-Content -Value '#Requires -Version 5.1' -Path $releaseFile
Add-Content -Value '#Requires -RunAsAdministrator' -Path $releaseFile
Add-Content -Value '' -Path $releaseFile

$Public = @( Get-ChildItem -Path $PSScriptRoot\..\functions\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\..\functions\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($import in @($Public + $Private)) {
    Try {
        Write-Verbose "Importing $($Import.FullName)"
        $function = Get-Content $import
        Add-Content -Value $function -Path $releaseFile
        Add-Content -Value '' -Path $releaseFile
    }
    Catch {
        Write-Error -Message "Failed to write function $($import.fullname): $_"
    }
}
Add-Content -Value '' -Path $releaseFile

$copyResult = Copy-Item $manifestFileInfo.FullName (Join-Path $releaseFolder $manifest) -Force -PassThru

Update-ModuleManifest -Path $copyResult.FullName -FunctionsToExport $Public.Basename