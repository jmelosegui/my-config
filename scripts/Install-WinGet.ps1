function Install-WinGet {
    <#
    .SYNOPSIS
        Installs and configures WinGet package manager and its PowerShell module.
    
    .DESCRIPTION
        This function ensures WinGet is properly installed and configured by:
        1. Checking if WinGet command is available
        2. Installing Microsoft.WinGet.Client PowerShell module if needed
        3. Bootstrapping WinGet using Repair-WinGetPackageManager
        4. Importing the module globally for DSC resource availability
        
        The function handles both scenarios where WinGet is completely missing
        or where only the PowerShell module needs to be installed.
    
    .EXAMPLE
        Install-WinGet
        
        Installs WinGet and its PowerShell module if not already present.
    
    .EXAMPLE
        Install-WinGet -WhatIf
        
        Shows what would be installed without actually making changes.
    
    .NOTES
        - Requires internet connection to download modules
        - Module is installed in CurrentUser scope to avoid requiring Administrator privileges
        - The Microsoft.WinGet.Client module is required for WinGet DSC resources
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    Write-Host "Configuring WinGet..." -ForegroundColor Cyan
    
    # Check if winget is installed
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess("Microsoft.WinGet.Client module", "Install WinGet")) {
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
    if ($wingetModule) {
        Write-Host "Found Microsoft.WinGet.Client version: $($wingetModule.Version)" -ForegroundColor Green
        Import-Module -Name Microsoft.WinGet.Client -Force -Global
        Write-Host "Microsoft.WinGet.Client module imported globally" -ForegroundColor Green
    }
    else {
        Write-Warning "Microsoft.WinGet.Client module not found. Installing it first..."
        try {
            Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Scope CurrentUser
            Write-Host "Microsoft.WinGet.Client module installed for current user" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install Microsoft.WinGet.Client module: $($_.Exception.Message)"
            Write-Host "Try running PowerShell as Administrator or install manually with:" -ForegroundColor Yellow
            Write-Host "Install-Module -Name Microsoft.WinGet.Client -Scope CurrentUser" -ForegroundColor Yellow
            return
        }
        Import-Module -Name Microsoft.WinGet.Client -Force -Global
    }
}

function Invoke-WinGetConfiguration {
    <#
    .SYNOPSIS
        Executes a WinGet configuration file to install and configure applications.
    
    .DESCRIPTION
        This function runs a WinGet DSC configuration file that contains a list of
        applications and their configuration settings. It handles the execution
        of the configuration file with proper error handling and logging.
    
    .PARAMETER ConfigPath
        The full path to the WinGet configuration YAML file to execute.
    
    .EXAMPLE
        Invoke-WinGetConfiguration -ConfigPath "C:\MyConfig\config\winget.yaml"
        
        Runs the WinGet configuration from the specified YAML file.
    
    .EXAMPLE
        Invoke-WinGetConfiguration -ConfigPath ".\config\winget.yaml" -WhatIf
        
        Shows what applications would be installed without actually executing.
    
    .NOTES
        - Requires WinGet and Microsoft.WinGet.Client module to be installed
        - The configuration file must be a valid WinGet DSC YAML format
        - Some applications may require Administrator privileges to install
        - Use Install-WinGet function first to ensure WinGet is properly configured
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    if ($PSCmdlet.ShouldProcess($ConfigPath, "Configure applications with winget")) {
        Write-Host "Running WinGet configuration..." -ForegroundColor Cyan
        Write-Host "Available modules in session:" -ForegroundColor Gray
        Get-Module -Name "*winget*" | ForEach-Object { Write-Host "  - $($_.Name) v$($_.Version)" -ForegroundColor Gray }
        
        try {
            winget configure -f $ConfigPath --accept-configuration-agreements --nowarn
        }
        catch {
            Write-Error "WinGet configuration failed: $($_.Exception.Message)"
            Write-Host "You might need to restart PowerShell as Administrator and run the script again." -ForegroundColor Yellow
        }
    }
} 