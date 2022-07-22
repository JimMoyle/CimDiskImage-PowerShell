<# INSERT HEADER ABOVE #>

#Get public and private function definition files.

#Requires -Version 5.1

$Public = @( Get-ChildItem -Path $PSScriptRoot\..\functions\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\..\functions\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($import in @($Public + $Private)) {
    Try {
        Write-Verbose "Importing $($Import.FullName)"
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Function $Public.Basename
<# INSERT FOOTER BELOW #>