$pesterConfig = New-PesterConfiguration
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = 'functions'
$pesterConfig.CodeCoverage.RecursePaths = $true
$pesterConfig.Run.Path = 'tests'
$pesterConfig.Output.Verbosity = 'Detailed'

Invoke-Pester -Configuration $pesterConfig