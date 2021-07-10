$AllVersions = @(
    "latest"
    "5.10.0"
    "5.9.1"
    "5.8.1"
    "5.7.1"
    "5.6.0"
    "5.5.1"
    "5.4.0"
    "5.3.1"
    "5.2.0"
    "5.1.0"
    "5.0.2"
    "4.9.4"
    "4.8.2"
    "4.7.3"
    "4.6.4"
    "4.5.3"
    "4.4.3"
    "4.3.1"
    "4.1.0"
    "3.5.0"
    "3.4.4"
    "3.3.0"
    "2.8.6"
)

if ($args.Count -eq 0) {
    $Versions = $AllVersions[0]
} else {
    $Versions = $args
}

$VersionTest = Join-Path -Path $PSScriptRoot -ChildPath "version-test.ps1"
$Versions | ForEach-Object {
    $Version = "$_".ToLower()
    & $VersionTest -Version $Version 6> "table-$Version.md" | ForEach-Object {
        $Result = [ordered]@{
            Version = $Version
        }
        $Result += $_
        Write-Output $Result
    }
}
