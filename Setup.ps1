# Setup.symlinks

$mapping = @(
   @{
        destination = "$env:LOCALAPPDATA\nvim"
        source = "$PSScriptRoot\nvim"
    },
    @{
        destination = "$env:USERPROFILE\jmelosegui-omp.json"
        source = "$PSScriptRoot\oh-my-posh\jmelosegui-omp.json"
    },
    @{
        destination = "$env:USERPROFILE\AppData\Roaming\Code\User\settings.json"
        source = "$PSScriptRoot\vscode\settings.json"
    },
    @{
        destination = "$env:USERPROFILE\AppData\Roaming\Code\User\keybindings.json"
        source = "$PSScriptRoot\vscode\keybindings.json"
    },
    @{
        destination = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
        source = "$PSScriptRoot\powershell\profile.ps1"
    },
    @{
        destination = "$env:USERPROFILE\Documents\PowerShell\Microsoft.VSCode_profile.ps1"
        source = "$PSScriptRoot\powershell\profile.ps1"
    },
    @{
        destination = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        source = "$PSScriptRoot\powershell\profile.ps1"
    }
)


foreach ($map in $mapping) {
    if (Test-Path $map.destination) {
        Write-Host "Skipping $($map.destination) because it already exists"
    } else {
        Write-Host "Creating symlink from $($map.source) to $($map.destination)"
        New-Item -ItemType SymbolicLink -Path $map.destination -Target $map.source
    }
}

