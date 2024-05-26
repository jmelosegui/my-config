$ErrorActionPreference = "Stop"

# configure windows developer machine using winget.
winget configure -f "$PSScriptRoot\config\winget.yaml" --nowarn

# TODO: download portable apps

# Setup.symlinks
## Install powershell module powershell-yaml if not installed
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Install-Module -Name powershell-yaml -Scope CurrentUser -Force
}
## Import powershell-yaml module if not imported
if (-not (Get-Module -Name powershell-yaml)) {
    Import-Module -Name powershell-yaml
}

$mapping = Get-Content -Path "$PSScriptRoot\config\symlinks.yaml" -Raw | ConvertFrom-Yaml -Ordered 

foreach ($map in $mapping.symbolicLinks){
    # Expand environment variables and script root variables
    $destination = [Environment]::ExpandEnvironmentVariables($map.destination.Replace('$PSScriptRoot', $PSScriptRoot))
    $source = [Environment]::ExpandEnvironmentVariables($map.source.Replace('$PSScriptRoot', $PSScriptRoot))

    if (Test-Path $destination) {
        Write-Host "Skipping $destination because it already exists"
    } else {
        Write-Host "Creating symlink from $source to $destination"
        New-Item -ItemType SymbolicLink -Path $destination -Target $source
    }
}

