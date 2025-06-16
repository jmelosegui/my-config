<#
.SYNOPSIS
    Sets up a Windows developer machine with applications and configuration files.

.DESCRIPTION
    This script configures a Windows developer machine by:
    1. Installing applications via winget using a configuration file
    2. Creating symbolic links for configuration files from the repository to their expected system locations
    
    The script uses winget to install applications and creates symbolic links based on a YAML configuration file.
    Existing files are backed up before being replaced with symbolic links.

.PARAMETER SkipWinget
    Skips the winget configuration step. Only symbolic links will be created.

.EXAMPLE
    .\Invoke-SetupDevMachine.ps1
    
    Sets up the machine with winget applications and creates symbolic links.

.EXAMPLE
    .\Invoke-SetupDevMachine.ps1 -SkipWinget
    
    Skips winget installation and only creates symbolic links.

.EXAMPLE
    .\Invoke-SetupDevMachine.ps1 -WhatIf
    
    Shows what changes would be made without actually executing them.

.NOTES
    - Requires PowerShell running as Administrator for creating symbolic links
    - The winget configuration file should be located at: $PSScriptRoot\config\winget.yaml
    - The symbolic links configuration file should be located at: $PSScriptRoot\config\symlinks.yaml
    - Existing files are backed up with a timestamp before being replaced
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param (
    [switch]$SkipWinget
)

function Invoke-SetupDevMachine
{
    


    $ErrorActionPreference = "Stop"

    # configure windows developer machine using winget.
    if (-not $SkipWinget)
    {
        # Check if winget is installed
        if (!(Get-Command winget -ErrorAction SilentlyContinue))
        {
            if ($PSCmdlet.ShouldProcess("Microsoft.WinGet.Client module", "Install WinGet"))
            {
                Write-Host "Winget is not installed. Installing..." -ForegroundColor Yellow
                Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Scope CurrentUser
                Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
                Repair-WinGetPackageManager
                Write-Host "Importing Microsoft.WinGet.Client module..."
                Import-Module -Name Microsoft.WinGet.Client -Force
                Write-Host "Winget has been installed."
            }
        }

        # Ensure Microsoft.WinGet.Client module is available for DSC resources
        Write-Host "Checking Microsoft.WinGet.Client module availability..." -ForegroundColor Yellow
        
        $wingetModule = Get-Module -ListAvailable -Name Microsoft.WinGet.Client | Sort-Object Version -Descending | Select-Object -First 1
        if ($wingetModule)
        {
            Write-Host "Found Microsoft.WinGet.Client version: $($wingetModule.Version)" -ForegroundColor Green
            Import-Module -Name Microsoft.WinGet.Client -Force -Global
            Write-Host "Microsoft.WinGet.Client module imported globally" -ForegroundColor Green
        }
        else
        {
            Write-Warning "Microsoft.WinGet.Client module not found. Installing it first..."
            try 
            {
                Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Scope CurrentUser
                Write-Host "Microsoft.WinGet.Client module installed for current user" -ForegroundColor Green
            }
            catch 
            {
                Write-Error "Failed to install Microsoft.WinGet.Client module: $($_.Exception.Message)"
                Write-Host "Try running PowerShell as Administrator or install manually with:" -ForegroundColor Yellow
                Write-Host "Install-Module -Name Microsoft.WinGet.Client -Scope CurrentUser" -ForegroundColor Yellow
                return
            }
            Import-Module -Name Microsoft.WinGet.Client -Force -Global
        }

        if ($PSCmdlet.ShouldProcess("$PSScriptRoot\config\winget.yaml", "Configure applications with winget"))
        {
            Write-Host "Running WinGet configuration..." -ForegroundColor Cyan
            Write-Host "Available modules in session:" -ForegroundColor Gray
            Get-Module -Name "*winget*" | ForEach-Object { Write-Host "  - $($_.Name) v$($_.Version)" -ForegroundColor Gray }
            
            try 
            {
                winget configure -f "$PSScriptRoot\config\winget.yaml" --accept-configuration-agreements --nowarn
            }
            catch 
            {
                Write-Error "WinGet configuration failed: $($_.Exception.Message)"
                Write-Host "You might need to restart PowerShell as Administrator and run the script again." -ForegroundColor Yellow
            }
        } 
    }

    # TODO: download portable apps

    # Setup.symlinks
    ## Install powershell module powershell-yaml if not installed
    if (-not (Get-Module -ListAvailable -Name powershell-yaml))
    {
        if ($PSCmdlet.ShouldProcess("powershell-yaml module", "Install"))
        {
            Install-Module -Name powershell-yaml -Scope CurrentUser -Force
        }
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
            if ($PSCmdlet.ShouldProcess($destParent, "Create parent directory"))
            {
                Write-Host "Creating parent directory $destParent"
                New-Item -ItemType Directory -Path $destParent -Force | Out-Null
            }
        }

        if (Test-Path $destination)
        {
            # Check if it's already a symlink pointing to the correct source
            $item = Get-Item $destination
            if ($item.LinkType -eq "SymbolicLink" -and $item.Target -eq $source)
            {
                Write-Host "Symlink already exists and points to correct source: $destination" -ForegroundColor Green
            }
            else 
            {
                # Backup existing file/directory and create symlink
                $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                $backupPath = "$destination.backup.$timestamp"
                
                if ($PSCmdlet.ShouldProcess("$destination -> $backupPath, then create symlink to $source", "Backup and create symlink"))
                {
                    Write-Host "Backing up existing item to: $backupPath" -ForegroundColor Yellow
                    Move-Item $destination $backupPath
                    Write-Host "Creating symlink from $source to $destination" -ForegroundColor Cyan
                    New-Item -ItemType SymbolicLink -Path $destination -Target $source
                }
            }
        } 
        else
        {
            if ($PSCmdlet.ShouldProcess("$destination -> $source", "Create symlink"))
            {
                Write-Host "Creating symlink from $source to $destination" -ForegroundColor Cyan
                New-Item -ItemType SymbolicLink -Path $destination -Target $source
            }
        }
    }
}

# Call the function with script parameters
Invoke-SetupDevMachine @PSBoundParameters
