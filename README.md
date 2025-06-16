# MyConfig - Developer Machine Setup

A comprehensive PowerShell-based solution for automating Windows developer machine setup and configuration management.

## Overview

This repository provides an automated, idempotent setup process for configuring Windows development environments. It handles application installation, development drive mapping, and configuration file management through a modular, well-documented PowerShell framework.

## Features

### 🚀 **Automated Application Installation**
- Uses WinGet DSC (Desired State Configuration) for declarative application management
- Automatically installs and configures WinGet if not present
- Supports both installation and removal of applications
- Handles application dependencies and configuration

### 💾 **Development Drive Mapping**
- Creates persistent virtual drive letters for development folders
- Interactive drive selection with free space display
- Automatic folder structure creation (Projects, Trash, Utils)
- Registry-based mappings that survive reboots

### 🔗 **Configuration File Management**
- Symbolic link creation for configuration files
- Automatic backup of existing configurations with timestamps
- Cross-application configuration synchronization
- Environment variable and path expansion support

### 🛠️ **Modular Architecture**
- Clean separation of concerns across multiple PowerShell modules
- Comprehensive error handling and logging
- Full WhatIf support for safe testing
- PowerShell best practices with approved verbs

## Repository Structure

```
MyConfig/
├── Invoke-SetupDevMachine.ps1     # Main orchestrator script
├── scripts/                       # Modular functionality
│   ├── Install-WinGet.ps1         # WinGet installation & configuration
│   ├── Initialize-DevDriveLetters.ps1  # Development drive mapping
│   └── New-Symlinks.ps1           # Symbolic link management
├── config/                        # Configuration files
│   ├── winget.yaml                # Application installation definitions
│   ├── symlinks.yaml              # Symbolic link mappings
│   └── portable-apps.yaml         # Portable application configurations
└── apps/                          # Application configuration files
    └── [various app configs]
```

## Quick Start

### Prerequisites
- Windows 10/11
- PowerShell 5.1 or PowerShell 7+
- Internet connection for downloading applications and modules

### Basic Usage

1. **Clone the repository:**
   ```powershell
   git clone <repository-url>
   cd MyConfig
   ```

2. **Run the setup script:**
   ```powershell
   .\Invoke-SetupDevMachine.ps1
   ```

3. **Preview changes without executing:**
   ```powershell
   .\Invoke-SetupDevMachine.ps1 -WhatIf
   ```

4. **Skip application installation (symlinks only):**
   ```powershell
   .\Invoke-SetupDevMachine.ps1 -SkipWinget
   ```

### Administrative Privileges

Some operations require Administrator privileges:
- Creating symbolic links
- Installing development drive mappings
- Installing certain applications

The script will prompt for elevation when needed or provide clear error messages if insufficient privileges are detected.

## Configuration

### Application Management (`config/winget.yaml`)
Define applications to install, update, or remove using WinGet DSC format. The configuration supports:
- Package installation from various sources
- Version pinning and upgrade policies
- Application-specific configuration settings
- Conditional installation based on system state

### Symbolic Links (`config/symlinks.yaml`)
Configure which configuration files should be symlinked from the repository to their system locations. Features include:
- Environment variable expansion
- Repository-relative path resolution
- Automatic parent directory creation
- Backup of existing files before linking

### Development Drives
The script can create persistent drive letter mappings for organized development workflows:
- **P:** → Projects directory
- **T:** → Temporary/Trash files
- **U:** → Utilities and tools

## Customization

### Adding New Applications
1. Add entries to `config/winget.yaml` following WinGet DSC syntax
2. Place any application-specific configuration files in the `apps/` directory
3. Add symbolic link mappings in `config/symlinks.yaml` if needed

### Extending Functionality
The modular architecture allows easy extension:
1. Create new PowerShell modules in the `scripts/` directory
2. Follow PowerShell best practices with approved verbs
3. Add comprehensive comment-based help documentation
4. Import and call from the main orchestrator script

### Environment-Specific Configurations
- Use environment variables in configuration files for machine-specific paths
- Leverage the interactive drive selection for different storage configurations
- Customize application lists based on development needs

## Safety Features

### Non-Destructive Operations
- **Automatic backups:** Existing files are backed up with timestamps before replacement
- **WhatIf support:** Preview all changes before execution
- **Idempotent design:** Safe to run multiple times
- **Rollback friendly:** Original configurations are preserved

### Error Handling
- Comprehensive error handling with actionable error messages
- Graceful degradation when optional components fail
- Clear logging of all operations and their outcomes
- Validation of prerequisites before execution

## Troubleshooting

### Common Issues

**WinGet Configuration Failures:**
- Ensure Microsoft.WinGet.Client module is installed
- Run PowerShell as Administrator if needed
- Check internet connectivity for package downloads

**Symbolic Link Creation:**
- Requires Administrator privileges on Windows
- Ensure source files exist in the repository
- Check that destination paths are valid

**Drive Mapping Issues:**
- Requires Administrator privileges for registry modification
- May need system restart for full effect
- Ensure selected drive has sufficient space

### Getting Help

Use PowerShell's built-in help system:
```powershell
# Main script help
Get-Help .\Invoke-SetupDevMachine.ps1 -Full

# Individual function help
Get-Help Install-WinGet -Examples
Get-Help Initialize-DevDriveLetters -Detailed
Get-Help New-Symlinks -Parameter ConfigPath
```

## License

This project is licensed under the terms specified in the LICENSE.txt file.
