# Configuration section
$Config = @{
  FontName             = "JetBrainsMono"
  FontDisplayName      = "JetBrainsMono NF"
  FontVersion          = "3.2.1"
  ProfileUrl           = "https://raw.githubusercontent.com/tonytech83/powershell-profile/refs/heads/main/Microsoft.PowerShell_profile.ps1"
  InstallOhMyPosh      = $true
  InstallFzf           = $true
  InstallZoxide        = $true
  InstallTerminalIcons = $true
}

# Logging function
function Write-Log {
  param(
    [string]$Message,
    [string]$Level = "Info"
  )
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $logMessage = "[$timestamp] [$Level] $Message"
  
  switch ($Level) {
    "Error" { Write-Host $logMessage -ForegroundColor Red }
    "Warning" { Write-Host $logMessage -ForegroundColor Yellow }
    "Success" { Write-Host $logMessage -ForegroundColor Green }
    "Info" { Write-Host $logMessage -ForegroundColor Cyan }
    default { Write-Host $logMessage }
  }
}

# Validation function
function Test-Prerequisites {
  Write-Log "Checking prerequisites..." "Info"
  $issues = @()
  
  # Check if winget is available
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    $issues += "winget is not installed or not in PATH"
  }
  
  # Check internet connectivity (TCP 443 to common endpoints)
  $internetOk = $false
  if (Test-Connection -TargetName "bing.com" -TcpPort 443 -Count 1 -Quiet -ErrorAction Stop -WarningAction SilentlyContinue) {
    $internetOk = $true
  }
  if (-not $internetOk) {
    $issues += "No reliable internet connectivity detected"
  }
  
  if ($issues.Count -gt 0) {
    Write-Log "Prerequisites check failed:" "Warning"
    $issues | ForEach-Object { Write-Log "  - $_" "Warning" }
    # return $false
  }
  
  Write-Log "Prerequisites check passed" "Success"
  # return $true
}

# Ensure the script can run with elevated privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Log "Please run this script as an Administrator!" "Error"
  break
}

# install Nerd Font
function Install-NerdFont {
  param (
    [string]$FontName = $Config.FontName,
    [string]$FontDisplayName = $Config.FontDisplayName,
    [string]$Version = $Config.FontVersion
  )

  Write-Log "Installing Nerd Font: $FontDisplayName..." "Info"

  # Installed Font Families
  $installed = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
  if ($installed -contains $FontDisplayName) {
    Write-Log "Font '$FontDisplayName' already installed" "Info"
    # return $true
  }
  
  # Define the URL for the JetBrainsMono Nerd Font zip file
  $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${Version}/${FontName}.zip"
  
  # Define the path where the zip file will be downloaded
  $tempZipPath = "$env:TEMP\JetBrainsMono.zip"
  
  # Define the directory where the font files will be extracted
  $extractPath = "$env:TEMP\JetBrainsMono"

  # Define the fonts installation path
  $fontsPath = "$env:WINDIR\Fonts"

  try {
    Write-Log "Downloading font from GitHub..." "Info"
    # Download the font zip file
    Invoke-WebRequest -Uri $fontUrl -OutFile $tempZipPath
    if (-not (Test-Path $tempZipPath)) { throw "Font download failed" }

    Write-Log "Extracting font files..." "Info"
    # Create a directory to extract the fonts
    if (-not (Test-Path -Path $extractPath)) {
      New-Item -ItemType Directory -Path $extractPath | Out-Null
    } 

    # Extract the zip file
    Expand-Archive -Path $tempZipPath -DestinationPath $extractPath -Force

    # Get the list of font files from the extracted directory
    $fontFiles = Get-ChildItem -Path $extractPath -Filter "*.ttf"
    if (-not $fontFiles) { throw "No font files found in archive." }

    Write-Log "Installing font files..." "Info"
    foreach ($Font in $fontFiles) {
      # Copy to C:\Windows\Fonts
      Copy-Item $Font $fontsPath
      New-ItemProperty -Name $Font.BaseName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType String -Value $Font.Name -Force | Out-Null
    }
  
    # Clean up
    Remove-Item -Path $tempZipPath -Force
    Remove-Item -Path $extractPath -Recurse -Force

    Write-Log "${FontDisplayName} font has been installed successfully." "Success"
    # return $true
  }
  catch {
    Write-Log "Failed to install ${FontDisplayName}. Error: $_" "Error"
    # return $false
  }
}

# Install PowerShell Profile
function Install-Profile {
  Write-Log "Installing PowerShell Profile..." "Info"
  
  # Profile creation or update
  if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
      # Detect Version of PowerShell & Create Profile directories if they do not exist.
      $profilePath = ""
      if ($PSVersionTable.PSEdition -eq "Core") {
        $profilePath = "$env:userprofile\Documents\Powershell"
      }
      elseif ($PSVersionTable.PSEdition -eq "Desktop") {
        $profilePath = "$env:userprofile\Documents\WindowsPowerShell"
      }

      if (!(Test-Path -Path $profilePath)) {
        New-Item -Path $profilePath -ItemType "directory" | Out-Null
      }

      Invoke-RestMethod $Config.ProfileUrl -OutFile $PROFILE
      Write-Log "The profile @ [$PROFILE] has been created." "Success"
      # return $true
    }
    catch {
      Write-Log "Failed to create or update the profile. Error: $_" "Error"
      # return $false
    }
  }
  else {
    try {
      $backupPath = Join-Path (Split-Path $PROFILE) "oldprofile.ps1"
      Move-Item -Path $PROFILE -Destination $backupPath -Force
      Invoke-RestMethod $Config.ProfileUrl -OutFile $PROFILE
      Write-Log "PowerShell profile at [$PROFILE] has been updated." "Success"
      Write-Log "Your old profile has been backed up to [$backupPath]" "Info"
      # return $true
    }
    catch {
      Write-Log "Failed to backup and update the profile. Error: $_" "Error"
      # return $false
    }
  }
}

# Helper function to install apps via winget
function Install-WingetPackage {
  param (
    [string]$Id,
    [string]$Name
  )
  Write-Log "Installing $Name..." "Info"
  try {
    winget install -e --accept-source-agreements --accept-package-agreements $Id 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
      Write-Log "$Name has been installed successfully." "Success"
      # return $true
    }
    else {
      throw "winget returned exit code $LASTEXITCODE"
    }
  }
  catch {
    Write-Log "Failed to install $Name. Error: $_" "Error"
    # return $false
  }
}

# Install Terminal-Icons
function Install-TerminalIcons {
  Write-Log "Installing Terminal-Icons module..." "Info"
  
  # Ensure TLS 1.2 (mostly for Windows PowerShell 5.1)
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  try {
    Register-PSRepository -Default -ErrorAction Stop
  }
  catch {
    if (-not (Get-PSRepository -ErrorAction SilentlyContinue)) {
      Register-PSRepository -Name PSGallery `
        -SourceLocation 'https://www.powershellgallery.com/api/v2' `
        -ScriptSourceLocation 'https://www.powershellgallery.com/api/v2/script' `
        -PublishLocation 'https://www.powershellgallery.com/api/v2/package/' `
        -ScriptPublishLocation 'https://www.powershellgallery.com/api/v2/package/' `
        -InstallationPolicy Trusted
    }
  }
  
  try {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force
    Write-Log "Terminal-Icons has been installed successfully." "Success"
    # return $true
  }
  catch {
    Write-Log "Failed to install Terminal-Icons. Error: $_" "Error"
    # return $false
  }
}

function Test-Setup {
  Write-Log "Verifying installation..." "Info"
  
  # $installedFonts = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
  $profileExists = Test-Path -Path $PROFILE
  $ohMyPoshInstalled = $null -ne (winget list --name "OhMyPosh" -e 2>$null)

  if ($profileExists -and $ohMyPoshInstalled) {
    Write-Log "Setup completed successfully. Please restart your PowerShell session to apply changes." "Success"
  }
  else {
    Write-Log "Setup completed with errors. Please check the error messages above." "Warning"
    if (-not $profileExists) { Write-Log "  - PowerShell profile not found" "Warning" }
    if (-not $ohMyPoshInstalled) { Write-Log "  - OhMyPosh not installed" "Warning" }
  }
  
  #   if ($profileExists -and $ohMyPoshInstalled -and ($installedFonts -contains $Config.FontDisplayName)) {
  #     Write-Log "Setup completed successfully. Please restart your PowerShell session to apply changes." "Success"
  #     return $true
  #   }
  #   else {
  #     Write-Log "Setup completed with errors. Please check the error messages above." "Warning"
  #     if (-not $profileExists) { Write-Log "  - PowerShell profile not found" "Warning" }
  #     if (-not $ohMyPoshInstalled) { Write-Log "  - OhMyPosh not installed" "Warning" }
  #     # if ($installedFonts -notcontains $Config.FontDisplayName) { Write-Log "  - Font not installed" "Warning" }
  #     return $false
  #   }
}

# Main execution starts here
Write-Log "Starting PowerShell environment setup..." "Info"

if (-not (Test-Prerequisites)) {
  Write-Log "Setup cannot continue due to missing prerequisites." "Error"
  exit 1
}

# Install Nerd Font. Change the font here!
Install-NerdFont -FontName $Config.FontName -FontDisplayName $Config.FontDisplayName

# Install Profile
Install-Profile

# Installation 
if ($Config.InstallOhMyPosh) {
  Install-WingetPackage -Id "JanDeDobbeleer.OhMyPosh" -Name "OhMyPosh"
}

if ($Config.InstallFzf) {
  Install-WingetPackage -Id "junegunn.fzf" -Name "fzf"
}

if ($Config.InstallZoxide) {
  Install-WingetPackage -Id "ajeetdsouza.zoxide" -Name "zoxide"
}

if ($Config.InstallTerminalIcons) {
  Install-TerminalIcons
}

# Final check and message to the user
Test-Setup
