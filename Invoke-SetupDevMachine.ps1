function Invoke-SetupDevMachine
{
    param (
        [switch]$SkipWinget
    )

    $ErrorActionPreference = "Stop"

    # configure windows developer machine using winget.
    if (-not $SkipWinget)
    {
        # Check if winget is installed
        if (!(Get-Command winget -ErrorAction SilentlyContinue))
        {
            Write-Error "Winget is not installed. Please install the App Installer from the Microsoft Store."
            return
        }

        winget configure -f "$PSScriptRoot\config\winget.yaml" --accept-configuration-agreements --nowarn 
    }

    # TODO: download portable apps

    # Setup.symlinks
    ## Install powershell module powershell-yaml if not installed
    if (-not (Get-Module -ListAvailable -Name powershell-yaml))
    {
        Install-Module -Name powershell-yaml -Scope CurrentUser -Force
    }
    ## Import powershell-yaml module if not imported
    if (-not (Get-Module -Name powershell-yaml))
    {
        Import-Module -Name powershell-yaml
    }

    $mapping = Get-Content -Path "$PSScriptRoot\config\symlinks.yaml" -Raw | ConvertFrom-Yaml -Ordered 

    foreach ($map in $mapping.symbolicLinks)
    {
        # Expand environment variables and script root variables
        $destination = [Environment]::ExpandEnvironmentVariables($map.destination.Replace('$PSScriptRoot', $PSScriptRoot))
        $source = [Environment]::ExpandEnvironmentVariables($map.source.Replace('$PSScriptRoot', $PSScriptRoot))

        # Create the parent directory of the link if it doesn't already exist
        $destParent = Split-Path $destination -Parent
        if (-not (Test-Path $destParent))
        {
            Write-Host "Creating parent directory $destParent"
            New-Item -ItemType Directory -Path $destParent -Force | Out-Null
        }

        if (Test-Path $destination)
        {
            Write-Host "Skipping $destination because it already exists"
        } else
        {
            Write-Host "Creating symlink from $source to $destination"
            New-Item -ItemType SymbolicLink -Path $destination -Target $source
        }
    }
}
