param (
    $WorkingDirectory = "packages",
    $NuGet = "nuget",
    [switch]$ExcludeVersion,
    [switch]$ConfigMode,
    [switch]$SaveMode
)


function Test-NuGet-Package-Nuspec {
    param (
        $Path,
        $Package,
        $Version
    )
    
    $nuspec = Join-Path -Path $Path -ChildPath "$Package.nuspec"

    if (Test-Path -Path $nuspec -PathType Leaf) {} else {
        return "$Package.nuspec not exist!"
    }

    $meta = Select-Xml -Path $nuspec -XPath "/ns:package/ns:metadata" `
                -Namespace @{ns = "http://schemas.microsoft.com/packaging/2013/05/nuspec.xsd"}
    $meta = $meta.Node
    
    if ($null -eq $meta.id) {
        return "nuspec format error, /package/metadata/id not exist!"
    }
    if ("$Package" -ne $meta.id) {
        return "package id error, expected: $Package, actual: $($meta.id)."
    }
    if ($null -eq $meta.version) {
        return "nuspec format error, /package/metadata/version not exist!"
    }
    if ("$Version" -ne $meta.version) {
        return "package version error, expected: $Version, actual: $($meta.version)."
    }
    return $null
}

function Test-NuGet-Package {
    param (
        $Path,
        $Package,
        $Version,
        [switch]$ExcludeVersion,
        [switch]$CheckNupkg,
        [switch]$CheckNuspec
    )

    $name = if ($ExcludeVersion) { "$Package" } else { "$Package.$Version" }
    $base = Join-Path -Path $Path -ChildPath $name

    if (Test-Path -Path $base -PathType Container) {

    } else {
        return "$name not exist!"
    }

    if ($CheckNupkg) {
        $nupkg = Join-Path -Path $base -ChildPath "$name.nupkg"
        if (Test-Path -Path $nupkg -PathType Leaf) {

        } else {
            return "$name.nupkg not exist!"
        }

        $unzip = Join-Path -Path $base -ChildPath "$Package"

        $global:ProgressPreference = 'SilentlyContinue'
        Rename-Item -Path $nupkg -NewName "$name.nupkg.zip"
        Expand-Archive -Path "$nupkg.zip" -DestinationPath $unzip

        $msg = Test-NuGet-Package-Nuspec -Path $unzip -Package $Package -Version $Version

        Rename-Item -Path "$nupkg.zip" -NewName "$name.nupkg"
        Remove-Item -Path $unzip -Recurse
        if ($null -ne $msg) {
            return "nupkg's " + $msg
        }
    }
    if ($CheckNuspec) {
        $msg = Test-NuGet-Package-Nuspec -Path $base -Package $Package -Version $Version
        if ($null -ne $msg) {
            return $msg
        }
    }
    return $null
}


function Invoke-NuGet($Version) {
    $cmd = ,"install"
    if ($null -eq $Version) {
        $cmd += $PackagesConfig
    } else {
        $cmd += "Newtonsoft.Json", "-Version", $Version
    }
    if ($ExcludeVersion) {
        $cmd += "-ExcludeVersion"
    }
    $cmd += "-DirectDownload", "-ForceEnglishOutput",
            "-OutputDirectory", $WorkingDirectory,
            "-PackageSaveMode", $(if ($SaveMode) { "nuspec" } else { "nupkg" })
    Write-Host "RUN: $NuGet $cmd"
    $r = & $NuGet @cmd
    $r | Write-Host
    return $r
}

function Invoke-Test($Version) {

    $r = Test-NuGet-Package -Path $WorkingDirectory `
                            -Package Newtonsoft.Json -Version $Version `
                            -ExcludeVersion: $ExcludeVersion `
                            -CheckNuspec: $SaveMode -CheckNupkg: $(!$SaveMode)
    if ($null -ne $r) {
        Write-Host "TEST: ERROR - $r"
        return $false
    } else {
        Write-Host "TEST: PASS"
        return $true
    }
}


$Result = [ordered]@{
    FirstTimeInstallSuccess = $false
    SecondTimeInstallNoop = $false
    InstallNewerVersionSuccess = $false
    InstallOlderVersionSuccess = $false
}

Remove-Item -LiteralPath $WorkingDirectory -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Name $WorkingDirectory -ItemType Directory -Force | Out-Null

if (! $ConfigMode) {

Write-Host "TEST: First Time Install One Package - PASS?"
if (Invoke-NuGet 12.0.3 | Select-String -Pattern "Successfully installed .*") {
    $Result.FirstTimeInstallSuccess = Invoke-Test 12.0.3
} else {
    Write-Host "TEST: FAILED"
}


Write-Host "TEST: Second Time Install Same Package - NOOP?"
if (Invoke-NuGet 12.0.3 | Select-String -Pattern "Package .* is already installed") {
    $Result.SecondTimeInstallNoop = Invoke-Test 12.0.3
} else {
    Write-Host "TEST: FAILED"
}


Write-Host "TEST: Install Newer Version Package - PASS?"
if (Invoke-NuGet 13.0.1 | Select-String -Pattern "Successfully installed .*") {
    $Result.InstallNewerVersionSuccess = Invoke-Test 13.0.1
} else {
    Write-Host "TEST: FAILED"
}


Write-Host "TEST: Install Older Version Package - PASS?"
if (Invoke-NuGet 12.0.1 | Select-String -Pattern "Successfully installed .*") {
    $Result.InstallOlderVersionSuccess = Invoke-Test 12.0.1
} else {
    Write-Host "TEST: FAILED"
}

} else {

$PackagesConfig = Join-Path -Path $WorkingDirectory -ChildPath "packages.config"


Write-Output @'
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="Newtonsoft.Json" version="12.0.3" />
</packages>
'@ | Out-File -Encoding Utf8 -FilePath $PackagesConfig


Write-Host "TEST: First Time Install One Package - PASS?"
if (Invoke-NuGet | Select-String -Pattern "Added package .* to folder") {
    $Result.FirstTimeInstallSuccess = Invoke-Test 12.0.3
} else {
    Write-Host "TEST: FAILED"
}


Write-Host "TEST: Second Time Install Same Package - NOOP?"
if (Invoke-NuGet | Select-String -Pattern "All packages listed in .*packages.config are already installed") {
    $Result.SecondTimeInstallNoop = Invoke-Test 12.0.3
} else {
    Write-Host "TEST: FAILED"
}


Write-Output @'
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="Newtonsoft.Json" version="13.0.1" />
</packages>
'@ | Out-File -Encoding Utf8 -FilePath $PackagesConfig

Write-Host "TEST: Install Newer Version Package - PASS?"
if (Invoke-NuGet | Select-String -Pattern "Added package .* to folder") {
    $Result.InstallNewerVersionSuccess = Invoke-Test 13.0.1
} else {
    Write-Host "TEST: FAILED"
}


Write-Output @'
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="Newtonsoft.Json" version="12.0.1" />
</packages>
'@ | Out-File -Encoding Utf8 -FilePath $PackagesConfig

Write-Host "TEST: Install Older Version Package - PASS?"
if (Invoke-NuGet | Select-String -Pattern "Added package .* to folder") {
    $Result.InstallOlderVersionSuccess = Invoke-Test 12.0.1
} else {
    Write-Host "TEST: FAILED"
}

}

Write-Output $Result
