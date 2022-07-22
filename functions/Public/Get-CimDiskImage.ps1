function Get-CimDiskImage {
    [CmdletBinding(DefaultParameterSetName = 'DeviceId')]

    Param (
        [Parameter(
            ParameterSetName = 'Path',
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true
        )]
        [Alias('Fullname', 'Name')]
        [System.String]$Path,

        [Parameter(
            ParameterSetName = 'DeviceId',
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true
        )]
        [System.String]$DeviceId
    )

    begin {
        Set-StrictMode -Version Latest
    } # begin
    process {
        #Get All the cimfs volumes
        $volume = Get-CimInstance -ClassName win32_volume | Where-Object { $_.FileSystem -eq 'cimfs' }

        #Filter (or not) based on parameter, param sets used so you can't put both deviceID and path in as params
        switch ($false) {
            ( [String]::IsNullOrEmpty($Path) ) {
                $out = $volume | Where-Object { $_.Name.TrimEnd('\') -eq $Path.TrimEnd('\') }
                Write-Output $out
                break
            }
            ( [String]::IsNullOrEmpty($DeviceId) ) {
                $out = $volume | Where-Object { $_.DeviceId -eq $DeviceId }
                Write-Output $out
                break
            }
            Default {
                Write-Output $volume
            }
        }   
    } # process
    end {} # end
}  #function Get-CimDiskImage