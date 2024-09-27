#################################################################################################################################
###                                                                                                                           ###
###                                     _______                       _______               __                                ###                                          
###                                    |_     _|.-----..-----..--.--.|_     _|.-----..----.|  |--.                            ###  
###                                      |   |  |  _  ||     ||  |  |  |   |  |  -__||  __||     |                            ###  
###                                      |___|  |_____||__|__||___  |  |___|  |_____||____||__|__|                            ###
###                                                           |_____|                                                         ###
###                                                                                                                           ###
###                                                     PowerShell template profile                                           ###
###                                                                                                                           ###
#################################################################################################################################


#opt-out of telemetry before doing anything, only if PowerShell is run as admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
        [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
    }

# Prediction History with list view of predictions
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

# Find out if the current user identity is elevated (has admin rights)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Compute file hashes - useful for checking successful downloads 
function md5 { Get-FileHash -Algorithm MD5 $args }
function sha1 { Get-FileHash -Algorithm SHA1 $args }
function sha256 { Get-FileHash -Algorithm SHA256 $args }

# Quick shortcut to start notepad
function n { notepad $args }

# # Drive shortcuts
function HKLM: { Set-Location HKLM: }
function HKCU: { Set-Location HKCU: }
function Env: { Set-Location Env: }

# Creates drive shortcut for Work Folders, if current user account is using it
if (Test-Path "$env:USERPROFILE\Work Folders") {
        New-PSDrive -Name Work -PSProvider FileSystem -Root "$env:USERPROFILE\Work Folders" -Description "Work Folders"
        function Work: { Set-Location Work: }
}

# Set up command prompt and window title. Use UNIX-style convention for identifying 
# whether user is elevated (root) or not. Window title shows current version of PowerShell
# and appends [ADMIN] if appropriate for easy taskbar identification
function prompt { 
        if ($isAdmin) {
                "[" + (Get-Location) + "] # " 
        }
        else {
                "[" + (Get-Location) + "] $ "
        }
}

$Host.UI.RawUI.WindowTitle = "PowerShell {0}" -f $PSVersionTable.PSVersion.ToString()
if ($isAdmin) {
        $Host.UI.RawUI.WindowTitle += " [ADMIN]"
}

# Bitcoin price
function Get-BitcoinPrice {
        # Fetch JSON data from the Coindesk API
        $json_data = Invoke-RestMethod -Uri "https://api.coindesk.com/v1/bpi/currentprice.json"
    
        # Extract the USD rate
        $usd_rate = $json_data.bpi.USD.rate
    
        # Define the icon
        $icon = ""

        # Define the color code for the icon
        $color = "`e[38;2;247;147;26m"  # RGB for #f7931a

        # Reset color code to default
        $reset = "`e[0m"
    
        # Output the icon in color followed by the USD rate
        Write-Output "$color$icon$reset $usd_rate"
    }
    
# Run the function
Get-BitcoinPrice 

# Update Powershell
function Update-PowerShell {    
        try {
            Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan
            $updateNeeded = $false
            $currentVersion = $PSVersionTable.PSVersion.ToString()
            $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
            $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
            $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
            if ($currentVersion -lt $latestVersion) {
                $updateNeeded = $true
            }
    
            if ($updateNeeded) {
                Write-Host "Updating PowerShell..." -ForegroundColor Yellow
                winget upgrade "Microsoft.PowerShell" --accept-source-agreements --accept-package-agreements
                Write-Host "PowerShell has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
            } else {
                Write-Host "Your PowerShell is up to date." -ForegroundColor Green
            }
        } catch {
            Write-Error "Failed to update PowerShell. Error: $_"
        }
}
Update-PowerShell

# Does the the rough equivalent of dir /s /b. For example, dirs *.png is dir /s /b *.png
function dirs {
        if ($args.Count -gt 0) {
                Get-ChildItem -Recurse -Include "$args" | Foreach-Object FullName
        }
        else {
                Get-ChildItem -Recurse | Foreach-Object FullName
        }
}

# Simple function to start a new elevated process. If arguments are supplied then 
# a single command is started with admin rights; if not then a new admin instance
# of PowerShell is started.
function admin {
        if ($args.Count -gt 0) {   
                $argList = "& '" + $args + "'"
                Start-Process "$psHome\pwsh.exe" -Verb runAs -ArgumentList $argList
        }
        else {
                Start-Process "C:\Program Files\PowerShell\7\pwsh.exe" -Verb runAs
        }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command
# with elevated rights. 
Set-Alias -Name su -Value admin
Set-Alias -Name sudo -Value admin
Set-Alias -Name clr -Value clear

# Make it easy to edit this profile once it's installed
function Edit-Profile {
        if ($host.Name -match "ise") {
                $psISE.CurrentPowerShellTab.Files.Add($profile.CurrentUserAllHosts)
        }
        else {
                notepad $profile.CurrentUserAllHosts
        }
}

# We don't need these any more; they were just temporary variables to get to $isAdmin. 
# Delete them to prevent cluttering up the user profile. 
Remove-Variable identity
Remove-Variable principal

# Quick shortcut to start Remoute Desktop Connection Manager
function rdcman {
        C:\Tools\RDCMan\RDCMan.exe       
}

# Quick shortcut to start btop4win
function htop {
        C:\Tools\btop4win\btop4win.exe
}

function disk_clean {              
        #Remove the temp files in AppData\Local\Temp
        Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue

        #Disk Clean up Tool
        cleanmgr /sagerun:1 /VeryLowDisk /AUTOCLEAN | Out-Null
}
function net_cls {
        ipconfig /release & ipconfig /renew & ipconfig /flushdns        
}

# Check the status of some familiar websites
function online {
        $siteList = @(
                "https://www.google.com",
                "https://www.abv.bg",
                "https://www.cars.bg",
                "https://www.office.com",
                "https://www.myworkday.com/aes/d/home.htmld",
                "https://www.yahoo.com",
                "https://www.youtube.com",
                "https://www.gmail.com"
        )

        $results = $siteList | ForEach-Object {
                $site = $_
                try {
                        $response = Invoke-WebRequest -Uri $site -UseBasicParsing -TimeoutSec 10
                        $status = if ($response.StatusCode -eq 200) { "OK" } else { "Failed" }
                }
                catch {
                        $status = "Failed"
                }

                [PSCustomObject]@{
                        Site   = $site
                        Status = $status
                }
        }

        $results | ForEach-Object {
                $color = if ($_.Status -eq "OK") { "Green" } else { "Red" }
                $statusDisplay = if ($_.Status -eq "OK") { "   OK   " } else { " Failed " }
                Write-Host ("[") -NoNewline
                Write-Host $statusDisplay -ForegroundColor $color -NoNewline
                Write-Host ("] ") -NoNewline
                Write-Host $_.Site
        }

        Write-Host "--------------------------------------"
}

# Get local network settings and external IP address
function myip {
        # Get network adapter configuration
        $netConfig = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        
        if ($netConfig) {
            # Get local network information
            $ip = $netConfig.IPAddress | Where-Object { $_ -match '\d+\.\d+\.\d+\.\d+' }
            $mask = $netConfig.IPSubnet | Where-Object { $_ -match '\d+\.\d+\.\d+\.\d+' }
            $gateway = $netConfig.DefaultIPGateway | Select-Object -First 1
            $dns = $netConfig.DNSServerSearchOrder
            $domain = $netConfig.DNSDomain
    
            # Get external IP address
            try {
                $pub_ip = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json").ip
            }
            catch {
                $pub_ip = "Unable to retrieve"
            }
    
            # Display network information
            Write-Host
            Write-Host "Local Network Information:" -ForegroundColor DarkCyan
            Write-Host "IPv4 Address:         $($ip -join ', ')"
            Write-Host "IPv4 Subnet Mask:     $($mask -join ', ')"
            Write-Host "IPv4 Default Gateway: $gateway"
            Write-Host "IPv4 DNS Server(s):   $($dns -join ', ')"
            Write-Host "Domain:               $domain"
            Write-Host
            Write-Host "External Network Information:" -ForegroundColor Red
            Write-Host "IPv4 Address:         $pub_ip"
            Write-Host
        }
        else {
            Write-Host "No network adapter configuration found." -ForegroundColor Yellow
        }
    }
    
    

function get-help {
        $border = [string]::new([char]0x2501, 120)
        $commands = @{
            "admin"          = "Start a new elevated process or command with admin rights"
            "df"             = "Get information about all volumes on device"
            "disk_clean"     = "Remove temp files in AppData\Local\Temp"
            "htop"           = "Quick shortcut to start btop4win"
            "ll"             = "List only files under current directory"
            "ls"             = "List all files and directories under current directory"
            "myip"           = "Get local network settings and external IP address"
            "net_cls"        = "Total reset of all network settings for current Ethernet adapter"
            "pgrep"          = "Get information for process (e.g., pgrep brave)"
            "pkill"          = "Kill process by name (e.g., pkill brave)"
            "reload-profile" = "Reload PowerShell profile"
            "rdcman"         = "Quick shortcut to start Remote Desktop Connection Manager"
            "touch"          = "Create a new file (e.g., touch example.txt)"
            "uptime"         = "Get device uptime"
        }
        
        $maxCommandLength = ($commands.Keys | Measure-Object -Maximum Length).Maximum
        $leftPadding = 4
        $rightPadding = 2
        
        Write-Host "`n$border`n"
        Write-Host "Available Commands:" -ForegroundColor Cyan
        Write-Host
    
        foreach ($command in $commands.Keys | Sort-Object) {
            $paddedCommand = $command.PadRight($maxCommandLength + $leftPadding)
            $boldCommand = "$([char]27)[1m$paddedCommand$([char]27)[0m"  # ANSI escape code for bold
            $description = $commands[$command]
            
            Write-Host ("  {0}" -f $boldCommand) -NoNewline -ForegroundColor Yellow
            Write-Host (": {0}" -f $description)
        }
        
        Write-Host "`n$border`n"
    }


function ll { Get-ChildItem -Path $pwd -File }

# Not in use
# function g { cd $HOME\Documents\Github }
function gcom {
        git add .
        git commit -m "$args"
}
function lazyg {
        git add .
        git commit -m "$args"
        git push
}
function uptime {
        $currentdate = Get-Date
        $bootuptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
        $uptime = $CurrentDate - $bootuptime
        Write-Host
        Write-Host "Meanmachine uptime:" -ForegroundColor DarkCyan
        Write-Host $($uptime.days)"days" $($uptime.Hours)"hours" $($uptime.Minutes)"minutes"
        Write-Host
}
function reload-profile {
        & $profile
}
function find-file($name) {
        ls -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | foreach {
                $place_path = $_.directory
                echo "${place_path}\${_}"
        }
}
function unzip ($file) {
        echo("Extracting", $file, "to", $pwd)
        $fullFile = Get-ChildItem -Path $pwd -Filter .\cove.zip | ForEach-Object { $_.FullName }
        Expand-Archive -Path $fullFile -DestinationPath $pwd
}
function grep($regex, $dir) {
        if ( $dir ) {
                ls $dir | select-string $regex
                return
        }
        $input | select-string $regex
}
function touch($file) {
        "" | Out-File $file -Encoding ASCII
}
function df {
        get-volume
}
function sed($file, $find, $replace) {
        (Get-Content $file).replace("$find", $replace) | Set-Content $file
}
function which($name) {
        Get-Command $name | Select-Object -ExpandProperty Definition
}
function export($name, $value) {
        set-item -force -path "env:$name" -value $value;
}
function pkill($name) {
        ps $name -ErrorAction SilentlyContinue | kill
}
function pgrep($name) {
        ps $name
}

# Enchanced PowerShell Expirience
Set-PSReadLineOption -Colors @{
        Command   = 'Yellow'
        Parameter = 'Green'
        String    = 'DarkCyan'
}


## Final Line to set prompt
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\tiwahu.omp.json" | Invoke-Expression # <--
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\my-star.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\my_illusi0n.omp.json" | Invoke-Expression # good one
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\my_di4am0nd.omp.json" | Invoke-Expression

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\my_theme.omp.json" | Invoke-Expression


# Add icons
Import-Module -Name Terminal-Icons

# Added `z` instead `cd`
Invoke-Expression (& { (zoxide init powershell | Out-String) })


