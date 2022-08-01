$paramInvokePester = @{
    Path = 'tests'
    #Output = 'Detailed'
    CodeCoverage = (Get-ChildItem functions -Recurse -File).FullName
    #TagFilter = 'Now'
}

Invoke-Pester @paramInvokePester