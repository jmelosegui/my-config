<#
.SYNOPSIS
    Sets up a Windows developer machine with applications and configuration files.

.DESCRIPTION
    This script configures a Windows developer machine by:
    1. Installing applications via winget using a configuration file
    2. Installing Nerd Fonts for terminal and development use
    3. Creating symbolic links for configuration files from the repository to their expected system locations
    4. Setting up development drive mappings
    
    The script uses winget to install applications, downloads and installs fonts from GitHub,
    and creates symbolic links based on a YAML configuration file.
    Existing files are backed up before being replaced with symbolic links.

.PARAMETER SkipWinget
    Skips the winget configuration step. Only fonts, symbolic links, and drive mappings will be created.

.PARAMETER SkipFonts
    Skips the Nerd Fonts installation step. Useful if fonts are already installed or not needed.

.EXAMPLE
    .\Invoke-SetupDevMachine.ps1
    
    Sets up the machine with winget applications and creates symbolic links.

.EXAMPLE
    .\Invoke-SetupDevMachine.ps1 -SkipWinget
    
    Skips winget installation and only installs fonts, creates symbolic links, and sets up drive mappings.

.EXAMPLE
    .\Invoke-SetupDevMachine.ps1 -SkipFonts
    
    Skips font installation and only installs applications, creates symbolic links, and sets up drive mappings.

.EXAMPLE
    .\Invoke-SetupDevMachine.ps1 -SkipWinget -SkipFonts
    
    Skips both winget and font installation, only creates symbolic links and sets up drive mappings.

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
    [switch]$SkipWinget,
    [switch]$SkipFonts
)

# Import modular scripts
. "$PSScriptRoot/scripts/Install-WinGet.ps1"
. "$PSScriptRoot/scripts/Initialize-DevDriveLetters.ps1" 
. "$PSScriptRoot/scripts/New-Symlinks.ps1"
. "$PSScriptRoot/scripts/Install-NerdFonts.ps1"

function Invoke-SetupDevMachine
{

    $ErrorActionPreference = "Stop"

    # Configure Windows developer machine using winget
    if (-not $SkipWinget) {
        Install-WinGet
        Invoke-WinGetConfiguration -ConfigPath "$PSScriptRoot\config\winget.yaml"
    }
    
    # Install Nerd Fonts (CaskaydiaCove for terminal/VSCode)
    if (-not $SkipFonts) {
        Install-NerdFonts -FontNames @("CascadiaCode")
    }

    # Initialize development drive mappings
    Initialize-DevDriveLetters

    # TODO: download portable apps

    # Create symbolic links
    New-Symlinks -ConfigPath "$PSScriptRoot\config\symlinks.yaml" -RepositoryRoot $PSScriptRoot
}

# Call the function with script parameters
Invoke-SetupDevMachine @PSBoundParameters
