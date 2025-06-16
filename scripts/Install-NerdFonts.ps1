function Install-NerdFonts {
    <#
    .SYNOPSIS
        Downloads and installs Nerd Fonts from GitHub releases.
    
    .DESCRIPTION
        This function downloads and installs Nerd Fonts from the official GitHub repository.
        It can install specific fonts or all available fonts. Fonts are installed system-wide
        to ensure compatibility with all applications including packaged apps like Windows Terminal.
        
        The function handles:
        1. Downloading font files from GitHub releases
        2. Installing fonts system-wide (requires admin privileges)
        3. Cleanup of temporary files
        
    .PARAMETER FontNames
        Array of font names to install. Defaults to @("CascadiaCode") for CaskaydiaCove Nerd Font.
        Available fonts include: Agave, AnonymousPro, CascadiaCode, FiraCode, JetBrainsMono, etc.
        
    .PARAMETER Version
        Nerd Fonts version to install. Defaults to latest release.
        
    .EXAMPLE
        Install-NerdFonts
        
        Installs CaskaydiaCove Nerd Font (default).
        
    .EXAMPLE
        Install-NerdFonts -FontNames @("CascadiaCode", "FiraCode")
        
        Installs CaskaydiaCove and FiraCode Nerd Fonts.
        
    .NOTES
        - Requires Administrator privileges to install fonts system-wide
        - Downloads fonts from https://github.com/ryanoasis/nerd-fonts/releases
        - Installs to C:\Windows\Fonts for system-wide availability
        - Existing fonts with the same name will be overwritten
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$FontNames = @("CascadiaCode"),
        
        [Parameter(Mandatory = $false)]
        [string]$Version = "latest"
    )
    
    Write-Host "Installing Nerd Fonts..." -ForegroundColor Cyan
    
    # Check if running as Administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Warning "Administrator privileges required to install fonts system-wide."
        Write-Host "Please run PowerShell as Administrator or fonts may not work in all applications." -ForegroundColor Yellow
        return
    }
    
    # Create temporary directory
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    try {
        # Get latest release info if version is "latest"
        if ($Version -eq "latest") {
            Write-Host "Getting latest Nerd Fonts release info..." -ForegroundColor Yellow
            $apiUrl = "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
            $releaseInfo = Invoke-RestMethod -Uri $apiUrl
            $Version = $releaseInfo.tag_name
        }
        
        Write-Host "Using Nerd Fonts version: $Version" -ForegroundColor Green
        
        $fontsInstalled = @()
        $fontsSkipped = @()
        $fontsError = @()
        
        foreach ($fontName in $FontNames) {
            try {
                Write-Host "Processing font: $fontName" -ForegroundColor Yellow
                
                # Download font
                $fontZip = "$fontName.zip"
                $downloadUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/$Version/$fontZip"
                $zipPath = Join-Path $tempDir $fontZip
                $extractPath = Join-Path $tempDir $fontName
                
                Write-Host "  Downloading $fontZip..." -ForegroundColor Gray
                
                try {
                    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -ErrorAction Stop
                }
                catch {
                    Write-Warning "  Failed to download $fontName`: $($_.Exception.Message)"
                    $fontsError += $fontName
                    continue
                }
                
                # Extract font
                Write-Host "  Extracting fonts..." -ForegroundColor Gray
                Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
                
                # Install fonts
                $fontFiles = Get-ChildItem -Path $extractPath -Filter "*.ttf" | Where-Object { 
                    # Use Windows Compatible versions and exclude Mono versions for better compatibility
                    $_.Name -like "*Windows Compatible*" -and $_.Name -notlike "*Mono*"
                }
                
                if ($fontFiles.Count -eq 0) {
                    # Fallback to any .ttf files if no Windows Compatible versions found
                    $fontFiles = Get-ChildItem -Path $extractPath -Filter "*.ttf" | Where-Object { 
                        $_.Name -notlike "*Mono*" 
                    }
                }
                
                if ($fontFiles.Count -eq 0) {
                    Write-Warning "  No suitable font files found in $fontName"
                    $fontsSkipped += $fontName
                    continue
                }
                
                $installedCount = 0
                foreach ($fontFile in $fontFiles) {
                    if ($PSCmdlet.ShouldProcess($fontFile.Name, "Install font")) {
                        try {
                            # Copy to Windows Fonts directory
                            $destPath = Join-Path "C:\Windows\Fonts" $fontFile.Name
                            Copy-Item -Path $fontFile.FullName -Destination $destPath -Force
                            
                            # Register font in registry
                            $fontName = $fontFile.BaseName
                            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
                            Set-ItemProperty -Path $regPath -Name "$fontName (TrueType)" -Value $fontFile.Name -Force
                            
                            Write-Host "    Installed: $($fontFile.Name)" -ForegroundColor Green
                            $installedCount++
                        }
                        catch {
                            Write-Warning "    Failed to install $($fontFile.Name): $($_.Exception.Message)"
                        }
                    }
                }
                
                if ($installedCount -gt 0) {
                    $fontsInstalled += $fontName
                }
                else {
                    $fontsSkipped += $fontName
                }
            }
            catch {
                Write-Error "Error processing font $fontName`: $($_.Exception.Message)"
                $fontsError += $fontName
            }
        }
        
        # Summary
        Write-Host ""
        Write-Host "Font Installation Summary:" -ForegroundColor Cyan
        if ($fontsInstalled.Count -gt 0) {
            Write-Host "  Successfully installed: $($fontsInstalled -join ', ')" -ForegroundColor Green
        }
        if ($fontsSkipped.Count -gt 0) {
            Write-Host "  Skipped: $($fontsSkipped -join ', ')" -ForegroundColor Yellow
        }
        if ($fontsError.Count -gt 0) {
            Write-Host "  Failed: $($fontsError -join ', ')" -ForegroundColor Red
        }
        
        if ($fontsInstalled.Count -gt 0) {
            Write-Host ""
            Write-Host "✅ Fonts installed successfully!" -ForegroundColor Green
            Write-Host "💡 You may need to restart applications to see the new fonts." -ForegroundColor Cyan
        }
    }
    finally {
        # Cleanup
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
} 