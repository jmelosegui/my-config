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

function Compare-WinGetVersion {
    <#
    .SYNOPSIS
        Compares two WinGet version strings.

    .DESCRIPTION
        Splits both versions on the usual separators and compares them part by part,
        numerically when both parts are numbers and as text otherwise. Missing trailing
        parts count as zero, so "1.2" and "1.2.0" are equal.

        Returns -1 when Left is older than Right, 0 when they are equivalent and
        1 when Left is newer than Right.

    .PARAMETER Left
        The first version string to compare.

    .PARAMETER Right
        The second version string to compare.

    .EXAMPLE
        Compare-WinGetVersion -Left "0.12.5" -Right "0.12.4"

        Returns 1 because the left version is newer.

    .NOTES
        - WinGet versions are not always semantic versions, so the comparison is tolerant
          of extra parts and non numeric segments
    #>

    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Left,

        [Parameter(Mandatory = $true)]
        [string]$Right
    )

    $leftParts = $Left.Trim() -split '[.\-_+]'
    $rightParts = $Right.Trim() -split '[.\-_+]'
    $partCount = [Math]::Max($leftParts.Count, $rightParts.Count)

    for ($i = 0; $i -lt $partCount; $i++) {
        $leftPart = if ($i -lt $leftParts.Count) { $leftParts[$i] } else { '0' }
        $rightPart = if ($i -lt $rightParts.Count) { $rightParts[$i] } else { '0' }

        $leftNumber = [long]0
        $rightNumber = [long]0
        if ([long]::TryParse($leftPart, [ref]$leftNumber) -and [long]::TryParse($rightPart, [ref]$rightNumber)) {
            if ($leftNumber -ne $rightNumber) {
                return [Math]::Sign($leftNumber.CompareTo($rightNumber))
            }
        }
        else {
            $comparison = [string]::Compare($leftPart, $rightPart, [StringComparison]::OrdinalIgnoreCase)
            if ($comparison -ne 0) {
                return [Math]::Sign($comparison)
            }
        }
    }

    return 0
}

function Get-WinGetConfigurationPin {
    <#
    .SYNOPSIS
        Lists the packages that are pinned to a specific version in a WinGet configuration file.

    .DESCRIPTION
        Reads a WinGet DSC configuration file and returns one object per resource that
        declares both a package id and a version, together with the line the version is
        declared on. The line number allows callers to rewrite the file without touching
        anything else in it.

    .PARAMETER ConfigPath
        The full path to the WinGet configuration YAML file to inspect.

    .EXAMPLE
        Get-WinGetConfigurationPin -ConfigPath "C:\MyConfig\config\winget.yaml"

        Lists every pinned package id with its target version.

    .NOTES
        - Resources without a version are ignored, they are "install if not present" entries
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    $lines = @(Get-Content -Path $ConfigPath)

    # Locate the first line of every resource so each one can be scanned in isolation
    $resourceStarts = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*-\s+resource:') {
            $resourceStarts += $i
        }
    }

    for ($block = 0; $block -lt $resourceStarts.Count; $block++) {
        $start = $resourceStarts[$block]
        $end = if ($block + 1 -lt $resourceStarts.Count) { $resourceStarts[$block + 1] - 1 } else { $lines.Count - 1 }

        $settingsIndent = -1
        $packageId = $null
        $version = $null
        $versionLine = -1

        for ($i = $start; $i -le $end; $i++) {
            $line = $lines[$i]
            if ($line -notmatch '\S') { continue }

            $indent = $line.Length - $line.TrimStart().Length

            # Skip ahead until the settings block, the resource level keys are not interesting
            if ($settingsIndent -lt 0) {
                if ($line -match '^\s*settings:\s*$') { $settingsIndent = $indent }
                continue
            }

            # A key at or above the settings indentation means the block is over
            if ($indent -le $settingsIndent) { break }

            if ($line -match '^\s*id:\s*(.+?)\s*$') {
                $packageId = $Matches[1].Trim('"', "'")
            }
            elseif ($line -match '^\s*version:\s*(.+?)\s*$') {
                $version = $Matches[1].Trim('"', "'")
                $versionLine = $i
            }
        }

        if ($packageId -and $version) {
            [PSCustomObject]@{
                PackageId = $packageId
                Version   = $version
                LineIndex = $versionLine
            }
        }
    }
}

function Get-WinGetVersionDrift {
    <#
    .SYNOPSIS
        Finds packages whose installed version is newer than the version pinned in the configuration.

    .DESCRIPTION
        Compares the version pinned for each package in a WinGet configuration file against
        the version currently installed on the machine and returns the packages that are
        installed at a newer version.

        Applying the configuration for those packages would downgrade them, which winget
        implements as an uninstall followed by an install of the older version. Callers are
        expected to leave those packages alone and let the user update the pin instead.

    .PARAMETER ConfigPath
        The full path to the WinGet configuration YAML file to inspect.

    .EXAMPLE
        Get-WinGetVersionDrift -ConfigPath "C:\MyConfig\config\winget.yaml"

        Returns the packages that are installed at a newer version than the configuration pins.

    .NOTES
        - Requires the Microsoft.WinGet.Client module, use Install-WinGet first
        - Packages that are not installed or report an unknown version are ignored
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    $pins = @(Get-WinGetConfigurationPin -ConfigPath $ConfigPath)
    if ($pins.Count -eq 0) { return }

    $installedVersions = @{}
    try {
        foreach ($package in Get-WinGetPackage) {
            if ($package.Id -and -not $installedVersions.ContainsKey($package.Id)) {
                $installedVersions[$package.Id] = $package.InstalledVersion
            }
        }
    }
    catch {
        Write-Warning "Could not list installed packages, skipping the version check: $($_.Exception.Message)"
        return
    }

    foreach ($pin in $pins) {
        if (-not $installedVersions.ContainsKey($pin.PackageId)) { continue }

        $installedVersion = $installedVersions[$pin.PackageId]
        if ([string]::IsNullOrWhiteSpace($installedVersion) -or $installedVersion -eq 'Unknown') { continue }

        if ((Compare-WinGetVersion -Left $installedVersion -Right $pin.Version) -gt 0) {
            [PSCustomObject]@{
                PackageId        = $pin.PackageId
                PinnedVersion    = $pin.Version
                InstalledVersion = $installedVersion
                LineIndex        = $pin.LineIndex
            }
        }
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
        - Packages installed at a version newer than the one pinned in the configuration are
          reported as a warning and left untouched, they are never downgraded
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    $configName = Split-Path $ConfigPath -Leaf

    # Packages that are ahead of the configuration would be uninstalled and reinstalled at the
    # older version, so drop their pin for this run and let the user decide what to do
    $drift = @(Get-WinGetVersionDrift -ConfigPath $ConfigPath)
    foreach ($package in $drift) {
        Write-Warning "$($package.PackageId) is installed at $($package.InstalledVersion) but $configName pins $($package.PinnedVersion). Leaving it alone, update the pin to $($package.InstalledVersion) to track the installed version."
    }

    if ($PSCmdlet.ShouldProcess($ConfigPath, "Configure applications with winget")) {
        Write-Host "Running WinGet configuration..." -ForegroundColor Cyan
        Write-Host "Available modules in session:" -ForegroundColor Gray
        Get-Module -Name "*winget*" | ForEach-Object { Write-Host "  - $($_.Name) v$($_.Version)" -ForegroundColor Gray }

        $effectiveConfigPath = $ConfigPath
        if ($drift.Count -gt 0) {
            $lines = @(Get-Content -Path $ConfigPath)
            $skip = $drift.LineIndex
            $kept = for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($skip -notcontains $i) { $lines[$i] }
            }

            $effectiveConfigPath = Join-Path ([System.IO.Path]::GetTempPath()) "winget-configuration-$([Guid]::NewGuid().ToString('N')).yaml"
            [System.IO.File]::WriteAllLines($effectiveConfigPath, [string[]]$kept)
            Write-Host "Applying $configName without the pin for: $($drift.PackageId -join ', ')" -ForegroundColor Yellow
        }

        try {
            winget configure -f $effectiveConfigPath --accept-configuration-agreements --nowarn
        }
        catch {
            Write-Error "WinGet configuration failed: $($_.Exception.Message)"
            Write-Host "You might need to restart PowerShell as Administrator and run the script again." -ForegroundColor Yellow
        }
        finally {
            if ($effectiveConfigPath -ne $ConfigPath) {
                Remove-Item -Path $effectiveConfigPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}