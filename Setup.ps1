# Setup.symlinks

$mapping = @(
   @{
        destination = "$env:LOCALAPPDATA\nvim"
        source = "$PWD\nvim"
    },
    @{
        destination = "$env:USERPROFILE\jmelosegui-omp.json"
        source = "$PWD\oh-my-posh\jmelosegui-omp.json"
    },
    @{
        destination = "$env:USERPROFILE\AppData\Roaming\Code\User\settings.json"
        source = "$PWD\vscode\settings.json"
    },
    @{
        destination = "$env:USERPROFILE\AppData\Roaming\Code\User\keybindings.json"
        source = "$PWD\vscode\keybindings.json"
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

# Override the default profile for PowerShell 5.x
Get-Content "$PWD\powershell\profile.ps1" | Set-Content $env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
# Override the default profile for PowerShell within VSCode
Get-Content "$PWD\powershell\profile.ps1" | Set-Content $env:USERPROFILE\Documents\PowerShell\Microsoft.VSCode_profile.ps1
# Override the default profile for PowerShell 6.x
Get-Content "$PWD\powershell\profile.ps1" | Set-Content $env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
