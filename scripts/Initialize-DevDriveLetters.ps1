function Initialize-DevDriveLetters {
    <#
    .SYNOPSIS
        Creates development drive letter mappings for quick access to development folders.
    
    .DESCRIPTION
        This function sets up virtual drive letter mappings to standardize development
        folder access across different machines. It:
        1. Checks if drive mappings already exist to avoid duplicates
        2. Prompts user to select which drive to use for development folders
        3. Creates the development folder structure (Projects, Trash, Utils)
        4. Generates and imports registry entries to create persistent drive mappings
        
        The function creates these drive letter mappings:
        - P: -> [SelectedDrive]:\dev\Projects (for development projects)
        - T: -> [SelectedDrive]:\dev\Trash (for temporary files)
        - U: -> [SelectedDrive]:\dev\Utils (for utility tools and scripts)
    
    .EXAMPLE
        Initialize-DevDriveLetters
        
        Interactively sets up development drive mappings after prompting for drive selection.
    
    .EXAMPLE
        Initialize-DevDriveLetters -WhatIf
        
        Shows what drive mappings would be created without actually making changes.
    
    .NOTES
        - Requires Administrator privileges to create registry drive mappings
        - Drive mappings persist across reboots unlike subst command
        - Applications may need to be restarted to see new drive letters
        - Uses DOS device namespace for reliable drive letter creation
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    Write-Host "Setting up development drive mappings..." -ForegroundColor Cyan
    
    # Check if drive mappings already exist
    $existingMappings = @()
    @("P:", "T:", "U:") | ForEach-Object {
        if (Get-PSDrive -Name $_.TrimEnd(':') -ErrorAction SilentlyContinue) {
            $existingMappings += $_
        }
    }
    
    if ($existingMappings.Count -gt 0) {
        Write-Host "Development drive mappings already exist: $($existingMappings -join ', ')" -ForegroundColor Green
        return
    }
    
    # Get available drives
    $availableDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name.Length -eq 1 } | Sort-Object Name
    
    # Prompt user for dev drive selection
    Write-Host "Available drives for development folders:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $availableDrives.Count; $i++) {
        $drive = $availableDrives[$i]
        $freeSpace = [math]::Round($drive.Free / 1GB, 1)
        Write-Host "  [$($i + 1)] $($drive.Name):\ ($freeSpace GB free)" -ForegroundColor White
    }
    
    do {
        $selection = Read-Host "Select drive for development folders (1-$($availableDrives.Count))"
        $selectionIndex = $selection -as [int]
    } while ($selectionIndex -lt 1 -or $selectionIndex -gt $availableDrives.Count)
    
    $selectedDrive = $availableDrives[$selectionIndex - 1].Name
    Write-Host "Selected drive: $selectedDrive" -ForegroundColor Green
    
    # Create development folder structure
    $devFolders = @{
        "Projects" = "$($selectedDrive):\dev\Projects"
        "Trash" = "$($selectedDrive):\dev\Trash" 
        "Utils" = "$($selectedDrive):\dev\Utils"
    }
    
    foreach ($folder in $devFolders.Values) {
        if ($PSCmdlet.ShouldProcess($folder, "Create development folder")) {
            if (-not (Test-Path $folder)) {
                Write-Host "Creating folder: $folder" -ForegroundColor Yellow
                New-Item -ItemType Directory -Path $folder -Force | Out-Null
            } else {
                Write-Host "Folder already exists: $folder" -ForegroundColor Green
            }
        }
    }
    
    # Generate registry content dynamically
    $regContent = @"
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\DOS Devices]
"P:"="\\??\\$($selectedDrive):\\dev\\Projects"
"T:"="\\??\\$($selectedDrive):\\dev\\Trash"
"U:"="\\??\\$($selectedDrive):\\dev\\Utils"
"@
    
    # Create temporary reg file and import it
    if ($PSCmdlet.ShouldProcess("Development drive letter mappings", "Create registry mappings")) {
        $tempRegFile = Join-Path $env:TEMP "DevDriveLetters.reg"
        
        try {
            Write-Host "Creating development drive mappings..." -ForegroundColor Yellow
            $regContent | Out-File -FilePath $tempRegFile -Encoding ASCII
            
            # Import registry file (requires admin privileges)
            Start-Process "reg" -ArgumentList "import", "`"$tempRegFile`"" -Wait -WindowStyle Hidden
            
            Write-Host "Development drive letters created successfully!" -ForegroundColor Green
            Write-Host "  P: -> $($devFolders.Projects)" -ForegroundColor Cyan
            Write-Host "  T: -> $($devFolders.Trash)" -ForegroundColor Cyan  
            Write-Host "  U: -> $($devFolders.Utils)" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "To ensure all applications recognize the new drive letters:" -ForegroundColor Yellow
            Write-Host "  - Some applications may need to be restarted" -ForegroundColor Yellow  
            Write-Host "  - File Explorer should show them immediately or after refresh" -ForegroundColor Yellow
            Write-Host "  - A system reboot guarantees all services recognize them" -ForegroundColor Yellow
            
            # Prompt user for action (only if not running WhatIf)
            if (-not $WhatIfPreference) {
                Write-Host ""
                $choice = Read-Host "Would you like to restart your computer now for full effect? (y/N)"
                if ($choice -match '^[Yy]') {
                    if ($PSCmdlet.ShouldProcess("Computer", "Restart")) {
                        Write-Host "Restarting computer in 10 seconds... (Press Ctrl+C to cancel)" -ForegroundColor Red
                        Start-Sleep -Seconds 3
                        Write-Host "Restarting now..." -ForegroundColor Red
                        Restart-Computer -Force
                    }
                } else {
                    Write-Host "Drive letters have been created. You can restart later if needed." -ForegroundColor Green
                }
            } else {
                Write-Host ""
                Write-Host "Note: After creating drive letters, you may want to restart your computer." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Error "Failed to create drive mappings: $($_.Exception.Message)"
            Write-Host "This operation requires Administrator privileges." -ForegroundColor Yellow
        }
        finally {
            # Clean up temp file
            if (Test-Path $tempRegFile) {
                Remove-Item $tempRegFile -Force
            }
        }
    }
} 