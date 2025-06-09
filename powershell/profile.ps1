Import-Module -Name Terminal-Icons
oh-my-posh init pwsh --config "$env:USERPROFILE\jmelosegui-omp.json" | Invoke-Expression

Function func_query_vg_ado
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$project,
        [Parameter(Mandatory=$true)]
        [string]$variableName
    )
    $jqCommand = '.[] | { name, variables: (.variables | to_entries[] | select(.key | test("' + $variableName + '"; "i")) | { key: .key, value: .value }) }'
    az pipelines variable-group list -o json --project $project | jq $jqCommand 
}
Set-Alias -Name adoq -Value func_query_vg_ado

Function func_gitprune
{ 
    git fetch -p
    git branch --v | Where-Object { $_ -match "\[gone\]" } | ForEach-Object { -split $_ | Select-Object -First 1 } | ForEach-Object { git branch -D $_ } 
}
Set-Alias -Name gitprune -Value func_gitprune

Function func_getip
{ 
    Invoke-WebRequest -uri 'https://api.ipify.org?format=json' | ConvertFrom-Json | Select-Object -expandproperty ip | ForEach-Object { Write-Host $_; Set-Clipboard $_} 
}
Set-Alias -Name ip -Value func_getip

Set-Alias -Name k kubectl
Set-Alias -Name d docker
Set-Alias which where.exe

Function func_tfplan
{ 
    terraform plan -no-color > .\.logs\plan.txt 
}
Set-Alias -Name tfplan -Value func_tfplan

Function func_tfapply
{ 
    terraform apply -auto-approve -no-color > .\.logs\apply.txt 
}
Set-Alias -Name tfapply -Value func_tfapply

function func_get_hash
{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline = $true)]
        [string]$Value,
        [Parameter(Mandatory=$false)]
        [ValidateSet('SHA1','SHA256','SHA384','SHA512','MD5')]
        [string]$Algorithm = 'SHA1',
        [Parameter(Mandatory=$false)]
        [switch]$ToLower
    )

    $ms = New-Object IO.MemoryStream
    $writer = New-Object System.IO.StreamWriter($ms)
    $writer.write($value)
    $writer.Flush()
    $ms.Position = 0
    $result = Get-FileHash -InputStream $ms -Algorithm $Algorithm | Select-Object -ExpandProperty Hash

    if($ToLower)
    {
        return $result.ToLower()
    }
    
    return $result
}
Set-Alias -Name Get-Hash -Value func_get_hash

function func_deflate
{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline = $true)]
        [ValidateScript({            
                if( -Not (Test-Path $_ -PathType leaf) )
                {
                    throw "File does not exist"
                }
                return $true
            })]
        [string]$Path
    )
    $ErrorActionPreference = 'Stop'    
    $fs = New-Object IO.FileStream((Resolve-Path $Path), [IO.FileMode]::Open, [IO.FileAccess]::Read)
    $fs.Position = 2
    $cs = New-Object IO.Compression.DeflateStream($fs, [IO.Compression.CompressionMode]::Decompress)
    $sr = New-Object IO.StreamReader($cs)
    return $sr.ReadToEnd()
}
Set-Alias -Name deflate -Value func_deflate

function func_ConvertTo-Base64
{
    param(
        [Parameter(Mandatory=$true , ValueFromPipeline = $true)]
        [string]$value
    )
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($value)
    $base64content = [System.Convert]::ToBase64String($bytes)
    return $base64content
}
Set-Alias -Name ConvertTo-Base64 -Value func_ConvertTo-Base64

function func_ConvertFrom-Base64
{
    param(
        [Parameter(Mandatory=$true , ValueFromPipeline = $true)]
        [string]$base64Value
    )
    $bytes = [System.Convert]::FromBase64String($base64Value)
    $result = [System.Text.Encoding]::UTF8.GetString($bytes)
    return $result
}
Set-Alias -Name ConvertFrom-Base64 -Value func_ConvertFrom-Base64

$path = @(
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\Extensions\Microsoft\Azure Storage Emulator",
    "C:\Program Files\Neovim\bin\",
    "P:\DevOps\DbDeploy\DbDeploy.Console\bin\Debug\net48",
    "P:\Personales\git-console\GitConsole\bin\Release\net7.0\win-x64",
    "U:\azcopy",
    "U:\hashicorp\vault",
    "U:\helm",
    "U:\jq",
    "U:\mongo",
    "U:\netcoredbg-win64\",
    "U:\node",
    "U:\nuget",
    "U:\nvm",
    "U:\postgresql-15.4-1-windows-x64-binaries\pgsql\bin",
    "U:\terraform",
    "C:\Program Files\MuseScore 3\bin",
    "U:\ffmpeg-5.0-essentials_build\bin"
)

$env:Path += ';' + $($path -join ';')

function Get-ProgramFiles32()
{
    if ($null -ne ${env:ProgramFiles(x86)})
    {
        return ${env:ProgramFiles(x86)}
    }
    return $env:ProgramFiles
}

function Get-VsInstallLocation()
{
    $programFiles = Get-ProgramFiles32
    $vswhere = "$programFiles\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere)
    {
        $vsinstallpath = (. "$vswhere" -latest -property installationPath -format value -nologo | Out-String).Trim()
        return $vsinstallpath
    }
    return $null;
}

if ($host.Name -eq 'ConsoleHost')
{
    Import-Module PSReadLine
}

# Visual Studio Developer PowerShell
$vsInstallPath = Get-VsInstallLocation
if ($null -ne $vsInstallPath)
{
    Import-Module "$vsInstallPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    Enter-VsDevShell -SkipAutomaticLocation -InstallPath $vsinstallpath | Out-Null
}

$PSReadLineOptions = @{
    PredictionSource = "History"
    #PredictionViewStyle =  "ListView"
    EditMode = "Windows"
    HistoryNoDuplicates = $true
}

try
{
    Set-PSReadLineOption @PSReadLineOptions    
} 
catch
{
    # Ignore errors
}

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# This is an example of a macro that you might use to execute a command.
# This will add the command to history.
Set-PSReadLineKeyHandler -Key 'Ctrl+Shift+b' `
    -BriefDescription BuildCurrentDirectory `
    -LongDescription "Build the current directory" `
    -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet build")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key Backspace `
    -BriefDescription SmartBackspace `
    -LongDescription "Delete previous character or matching quotes/parens/braces" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -gt 0)
    {
        $toMatch = $null
        if ($cursor -lt $line.Length)
        {
            switch ($line[$cursor])
            {
                <#case#> '"' { $toMatch = '"'; break }
                <#case#> "'" { $toMatch = "'"; break }
                <#case#> ')' { $toMatch = '('; break }
                <#case#> ']' { $toMatch = '['; break }
                <#case#> '}' { $toMatch = '{'; break }
            }
        }

        if ($toMatch -ne $null -and $line[$cursor-1] -eq $toMatch)
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
        } else
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
        }
    }
}

# Sometimes you want to get a property of invoke a member on what you've entered so far
# but you need parens to do that.  This binding will help by putting parens around the current selection,
# or if nothing is selected, the whole line.
Set-PSReadLineKeyHandler -Key 'Alt+(' `
    -BriefDescription ParenthesizeSelection `
    -LongDescription "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis" `
    -ScriptBlock {
    param($key, $arg)

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($selectionStart -ne -1)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    } else
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }
}


# dotnet suggest shell start
if (Get-Command "dotnet-suggest" -errorAction SilentlyContinue)
{
    $availableToComplete = (dotnet-suggest list) | Out-String
    $availableToCompleteArray = $availableToComplete.Split([Environment]::NewLine, [System.StringSplitOptions]::RemoveEmptyEntries)

    Register-ArgumentCompleter -Native -CommandName $availableToCompleteArray -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        $fullpath = (Get-Command $commandAst.CommandElements[0]).Source

        $arguments = $commandAst.Extent.ToString().Replace('"', '\"')
        dotnet-suggest get -e $fullpath --position $cursorPosition -- "$arguments" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }    
} else
{
    "Unable to provide System.CommandLine tab completion support unless the [dotnet-suggest] tool is first installed."
    "See the following for tool installation: https://www.nuget.org/packages/dotnet-suggest"
}

$env:DOTNET_SUGGEST_SCRIPT_VERSION = "1.0.2"
# dotnet suggest script end

# kubernetes Autocompleter

# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# powershell completion for kubectl                              -*- shell-script -*-

function __k_debug
{
    if ($env:BASH_COMP_DEBUG_FILE)
    {
        "$args" | Out-File -Append -FilePath "$env:BASH_COMP_DEBUG_FILE"
    }
}

filter __k_escapeStringWithSpecialChars
{
    $_ -replace '\s|#|@|\$|;|,|''|\{|\}|\(|\)|"|`|\||<|>|&','`$&'
}

Register-ArgumentCompleter -CommandName 'k' -ScriptBlock {
    param(
        $WordToComplete,
        $CommandAst,
        $CursorPosition
    )

    # Get the current command line and convert into a string
    $Command = $CommandAst.CommandElements
    $Command = "$Command"

    __k_debug ""
    __k_debug "========= starting completion logic =========="
    __k_debug "WordToComplete: $WordToComplete Command: $Command CursorPosition: $CursorPosition"

    # The user could have moved the cursor backwards on the command-line.
    # We need to trigger completion from the $CursorPosition location, so we need
    # to truncate the command-line ($Command) up to the $CursorPosition location.
    # Make sure the $Command is longer then the $CursorPosition before we truncate.
    # This happens because the $Command does not include the last space.
    if ($Command.Length -gt $CursorPosition)
    {
        $Command=$Command.Substring(0,$CursorPosition)
    }
    __k_debug "Truncated command: $Command"

    $ShellCompDirectiveError=1
    $ShellCompDirectiveNoSpace=2
    $ShellCompDirectiveNoFileComp=4
    $ShellCompDirectiveFilterFileExt=8
    $ShellCompDirectiveFilterDirs=16

    # Prepare the command to request completions for the program.
    # Split the command at the first space to separate the program and arguments.
    $Program,$Arguments = $Command.Split(" ",2)
    $RequestComp="$Program __complete $Arguments"
    __k_debug "RequestComp: $RequestComp"

    # we cannot use $WordToComplete because it
    # has the wrong values if the cursor was moved
    # so use the last argument
    if ($WordToComplete -ne "" )
    {
        $WordToComplete = $Arguments.Split(" ")[-1]
    }
    __k_debug "New WordToComplete: $WordToComplete"


    # Check for flag with equal sign
    $IsEqualFlag = ($WordToComplete -Like "--*=*" )
    if ( $IsEqualFlag )
    {
        __k_debug "Completing equal sign flag"
        # Remove the flag part
        $Flag,$WordToComplete = $WordToComplete.Split("=",2)
    }

    if ( $WordToComplete -eq "" -And ( -Not $IsEqualFlag ))
    {
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __k_debug "Adding extra empty parameter"
        # We need to use `"`" to pass an empty argument a "" or '' does not work!!!
        $RequestComp="$RequestComp" + ' `"`"'
    }

    __k_debug "Calling $RequestComp"
    #call the command store the output in $out and redirect stderr and stdout to null
    # $Out is an array contains each line per element
    Invoke-Expression -OutVariable out "$RequestComp" 2>&1 | Out-Null


    # get directive from last line
    [int]$Directive = $Out[-1].TrimStart(':')
    if ($Directive -eq "")
    {
        # There is no directive specified
        $Directive = 0
    }
    __k_debug "The completion directive is: $Directive"

    # remove directive (last element) from out
    $Out = $Out | Where-Object { $_ -ne $Out[-1] }
    __k_debug "The completions are: $Out"

    if (($Directive -band $ShellCompDirectiveError) -ne 0 )
    {
        # Error code.  No completion.
        __k_debug "Received error from custom completion go code"
        return
    }

    $Longest = 0
    $Values = $Out | ForEach-Object {
        #Split the output in name and description
        $Name, $Description = $_.Split("`t",2)
        __k_debug "Name: $Name Description: $Description"

        # Look for the longest completion so that we can format things nicely
        if ($Longest -lt $Name.Length)
        {
            $Longest = $Name.Length
        }

        # Set the description to a one space string if there is none set.
        # This is needed because the CompletionResult does not accept an empty string as argument
        if (-Not $Description)
        {
            $Description = " "
        }
        @{Name="$Name";Description="$Description"}
    }


    $Space = " "
    if (($Directive -band $ShellCompDirectiveNoSpace) -ne 0 )
    {
        # remove the space here
        __k_debug "ShellCompDirectiveNoSpace is called"
        $Space = ""
    }

    if ((($Directive -band $ShellCompDirectiveFilterFileExt) -ne 0 ) -or
       (($Directive -band $ShellCompDirectiveFilterDirs) -ne 0 ))
    {
        __k_debug "ShellCompDirectiveFilterFileExt ShellCompDirectiveFilterDirs are not supported"

        # return here to prevent the completion of the extensions
        return
    }

    $Values = $Values | Where-Object {
        # filter the result
        $_.Name -like "$WordToComplete*"

        # Join the flag back if we have an equal sign flag
        if ( $IsEqualFlag )
        {
            __k_debug "Join the equal sign flag back to the completion value"
            $_.Name = $Flag + "=" + $_.Name
        }
    }

    if (($Directive -band $ShellCompDirectiveNoFileComp) -ne 0 )
    {
        __k_debug "ShellCompDirectiveNoFileComp is called"

        if ($Values.Length -eq 0)
        {
            # Just print an empty string here so the
            # shell does not start to complete paths.
            # We cannot use CompletionResult here because
            # it does not accept an empty string as argument.
            ""
            return
        }
    }

    # Get the current mode
    $Mode = (Get-PSReadLineKeyHandler | Where-Object {$_.Key -eq "Tab" }).Function
    __k_debug "Mode: $Mode"

    $Values | ForEach-Object {

        # store temporary because switch will overwrite $_
        $comp = $_

        # PowerShell supports three different completion modes
        # - TabCompleteNext (default windows style - on each key press the next option is displayed)
        # - Complete (works like bash)
        # - MenuComplete (works like zsh)
        # You set the mode with Set-PSReadLineKeyHandler -Key Tab -Function <mode>

        # CompletionResult Arguments:
        # 1) CompletionText text to be used as the auto completion result
        # 2) ListItemText   text to be displayed in the suggestion list
        # 3) ResultType     type of completion result
        # 4) ToolTip        text for the tooltip with details about the object

        switch ($Mode)
        {

            # bash like
            "Complete"
            {

                if ($Values.Length -eq 1)
                {
                    __k_debug "Only one completion left"

                    # insert space after value
                    [System.Management.Automation.CompletionResult]::new($($comp.Name | __k_escapeStringWithSpecialChars) + $Space, "$($comp.Name)", 'ParameterValue', "$($comp.Description)")

                } else
                {
                    # Add the proper number of spaces to align the descriptions
                    while($comp.Name.Length -lt $Longest)
                    {
                        $comp.Name = $comp.Name + " "
                    }

                    # Check for empty description and only add parentheses if needed
                    if ($($comp.Description) -eq " " )
                    {
                        $Description = ""
                    } else
                    {
                        $Description = "  ($($comp.Description))"
                    }

                    [System.Management.Automation.CompletionResult]::new("$($comp.Name)$Description", "$($comp.Name)$Description", 'ParameterValue', "$($comp.Description)")
                }
            }

            # zsh like
            "MenuComplete"
            {
                # insert space after value
                # MenuComplete will automatically show the ToolTip of
                # the highlighted value at the bottom of the suggestions.
                [System.Management.Automation.CompletionResult]::new($($comp.Name | __k_escapeStringWithSpecialChars) + $Space, "$($comp.Name)", 'ParameterValue', "$($comp.Description)")
            }

            # TabCompleteNext and in case we get something unknown
            Default
            {
                # Like MenuComplete but we don't want to add a space here because
                # the user need to press space anyway to get the completion.
                # Description will not be shown because that's not possible with TabCompleteNext
                [System.Management.Automation.CompletionResult]::new($($comp.Name | __k_escapeStringWithSpecialChars), "$($comp.Name)", 'ParameterValue', "$($comp.Description)")
            }
        }

    }
}

