param (
    $Version
)


$NuGet = $null
if (!$Version -or $Version -ieq "local") {
    $NuGet ="nuget"
    $Version = & $NuGet | Select-Object -First 1 | Select-String '^NuGet Version: (\d+\.\d+\.\d+)(\.\d+)?$'
    $Version = $Version.Matches[0].Groups[1].Value
}

if ($Version -ieq "latest") {
    $Version = $Version.ToLower()
} elseif ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version [$Version] is invalid, must be X.Y.Z"    
}


Remove-Item -LiteralPath $Version -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Name $Version -ItemType Directory -Force | Out-Null
Set-Location -Path $Version

if (!$NuGet) {
    $global:ProgressPreference = 'SilentlyContinue'
    $v = if ($Version -ceq "latest") { "latest" } else { "v$Version" }
    $url = "https://dist.nuget.org/win-x86-commandline/$v/nuget.exe"
    Invoke-WebRequest -Uri $url -OutFile "nuget.exe"
    $NuGet = Join-Path -Path "." -ChildPath "nuget"
    $Version = & $NuGet | Select-Object -First 1 | Select-String '^NuGet Version: (\d+\.\d+\.\d+)(\.\d+)?$'
    $Version = $Version.Matches[0].Groups[1].Value

    if ($Version -notmatch '^\d+\.\d+\.\d+$') {
        throw "Version [$Version] is invalid, must be X.Y.Z"    
    } else {
        Set-Content -Path "version.txt" -Value "$Version"
    }
}


# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_pipelines#one-at-a-time-processing
# Must use pipe to process the output objects one-at-a-time as they are the same object.
# `$a = @{} | Get-CartesianProduct X @(1,2)` is an array containing same object (@{}) twice.
filter Get-CartesianProduct($name, $values) {
    $obj = $_
    $values | ForEach-Object { $obj[$name] = $_; $obj }
}

filter Get-KeyCode {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]$Key
    )
    switch ($Key) {
        'ExcludeVersion' { 'X' }
        Default { "$Key"[0] }
    }
}

filter Get-ValueCode {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]$Value
    )
    switch ($Value) {
        $false { 'N' }
        $true { 'Y' }
        Default { "$Value"[0] }
    }
}

$Params = [ordered]@{
    ExcludeVersion = $false, $true
    ConfigMode = $false, $true
    SaveMode  = $false, $true
}

$expr = '[ordered]@{}'
foreach ($name in $Params.Keys) {
    $expr += "|Get-CartesianProduct $name `$Params.$name"
}

$initialized = $false

Invoke-Expression $expr | ForEach-Object {
    $WorkingDirectory = ($_.GetEnumerator() | ForEach-Object { 
        "$(Get-KeyCode $_.Key)$(Get-ValueCode $_.Value)" }) -join '-'

    $UnitTest = Join-Path -Path $PSScriptRoot -ChildPath "unit-test.ps1"
    $Result = & $UnitTest -WorkingDirectory $WorkingDirectory -NuGet $NuGet @_ 6> "$WorkingDirectory.log"

    if (!$initialized) {
        Write-Host "| $((($_.Keys | Get-KeyCode) + (1..$Result.Count)) -join ' | ') |"
        Write-Host ('|---' * ($_.Count + $Result.Count) + '|')
        $initialized = $true
    }

    $Result = $_ + $Result
    Write-Output $Result
    Write-Host "| $(($Result.Values | Get-ValueCode) -join ' | ') |"
}
