function Install-PowerShellYaml {
    <#
    .SYNOPSIS
        Installs and imports the PowerShell YAML module for configuration file parsing.
    
    .DESCRIPTION
        This function ensures the powershell-yaml module is available for parsing
        YAML configuration files. It installs the module if not present and
        imports it into the current session.
    
    .EXAMPLE
        Install-PowerShellYaml
        
        Installs and imports the powershell-yaml module.
    
    .EXAMPLE
        Install-PowerShellYaml -WhatIf
        
        Shows what would be installed without actually making changes.
    
    .NOTES
        - Module is installed in CurrentUser scope to avoid requiring Administrator privileges
        - Required for parsing symlinks.yaml configuration files
        - Module is automatically imported after installation
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    Write-Host "Setting up PowerShell YAML module..." -ForegroundColor Cyan
    
    # Install powershell module powershell-yaml if not installed
    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        if ($PSCmdlet.ShouldProcess("powershell-yaml module", "Install")) {
            Install-Module -Name powershell-yaml -Scope CurrentUser -Force
        }
    }
    
    # Import powershell-yaml module if not imported
    if (-not (Get-Module -Name powershell-yaml)) {
        Import-Module -Name powershell-yaml
    }
}

function New-Symlinks {
    <#
    .SYNOPSIS
        Creates symbolic links for configuration files based on a YAML configuration.
    
    .DESCRIPTION
        This function processes a YAML configuration file containing symbolic link
        definitions and creates the specified symbolic links. It:
        1. Parses the YAML configuration file using the powershell-yaml module
        2. Expands environment variables and repository paths in source/destination paths
        3. Creates parent directories for destination paths if they don't exist
        4. Backs up existing files/directories before creating symbolic links
        5. Creates symbolic links pointing from destination to source locations
        
        The function intelligently handles existing files by backing them up with
        timestamps before creating the symbolic links, ensuring no data is lost.
    
    .PARAMETER ConfigPath
        The full path to the YAML configuration file containing symbolic link definitions.
        This file should contain a 'symbolicLinks' section with source and destination mappings.
    
    .PARAMETER RepositoryRoot
        The root path of the repository, used to resolve $PSScriptRoot variables in the
        configuration file. This ensures paths are resolved correctly regardless of
        where the function is called from.
    
    .EXAMPLE
        New-Symlinks -ConfigPath "C:\MyConfig\config\symlinks.yaml" -RepositoryRoot "C:\MyConfig"
        
        Creates symbolic links based on the configuration in symlinks.yaml.
    
    .EXAMPLE
        New-Symlinks -ConfigPath ".\config\symlinks.yaml" -RepositoryRoot $PSScriptRoot -WhatIf
        
        Shows what symbolic links would be created without actually making changes.
    
    .NOTES
        - Requires Administrator privileges on Windows to create symbolic links
        - Existing files are backed up with timestamps before being replaced
        - The powershell-yaml module is automatically installed if not present
        - Environment variables in paths are automatically expanded
        - Symbolic links work for both files and directories
        - Target source files/directories must exist for symbolic links to function properly
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $true)]
        [string]$RepositoryRoot
    )
    
    Write-Host "Setting up symbolic links..." -ForegroundColor Cyan
    
    # Ensure PowerShell YAML module is available
    Install-PowerShellYaml
    
    $mapping = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Yaml -Ordered 

    foreach ($map in $mapping.symbolicLinks) {
        # Expand environment variables and script root variables
        $destination = [Environment]::ExpandEnvironmentVariables($map.destination.Replace('$PSScriptRoot', $RepositoryRoot))
        $source = [Environment]::ExpandEnvironmentVariables($map.source.Replace('$PSScriptRoot', $RepositoryRoot))

        # Create the parent directory of the link if it doesn't already exist
        $destParent = Split-Path $destination -Parent
        if (-not (Test-Path $destParent)) {
            if ($PSCmdlet.ShouldProcess($destParent, "Create parent directory")) {
                Write-Host "Creating parent directory $destParent"
                New-Item -ItemType Directory -Path $destParent -Force | Out-Null
            }
        }

        if (Test-Path $destination) {
            # Check if it's already a symlink pointing to the correct source
            $item = Get-Item $destination
            if ($item.LinkType -eq "SymbolicLink" -and $item.Target -eq $source) {
                Write-Host "Symlink already exists and points to correct source: $destination" -ForegroundColor Green
            }
            else {
                # Backup existing file/directory and create symlink
                $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                $backupPath = "$destination.backup.$timestamp"
                
                if ($PSCmdlet.ShouldProcess("$destination -> $backupPath, then create symlink to $source", "Backup and create symlink")) {
                    Write-Host "Backing up existing item to: $backupPath" -ForegroundColor Yellow
                    Move-Item $destination $backupPath
                    Write-Host "Creating symlink from $source to $destination" -ForegroundColor Cyan
                    New-Item -ItemType SymbolicLink -Path $destination -Target $source
                }
            }
        } 
        else {
            if ($PSCmdlet.ShouldProcess("$destination -> $source", "Create symlink")) {
                Write-Host "Creating symlink from $source to $destination" -ForegroundColor Cyan
                New-Item -ItemType SymbolicLink -Path $destination -Target $source
            }
        }
    }
} 