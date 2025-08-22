# Ensure the script can run with elevated privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Warning "Please run this script as an Administrator!"
  break
}

function Install-NerdFont {
  param (
    [string]$FontName = "JetBrainsMono",
    [string]$FontDisplayName = "JetBrainsMono NF",
    [string]$Version = "3.2.1"
  )

  # Installed Font Families
  $installed = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
  if ($installed -contains $FontDisplayName) {
    Write-Host "Font '$FontDisplayName' already installed"
    return
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
    # Download the font zip file
    Invoke-WebRequest -Uri $fontUrl -OutFile $tempZipPath
    if (-not (Test-Path $tempZipPath)) { throw "Font download failed" }

    # Create a directory to extract the fonts
    if (-not (Test-Path -Path $extractPath)) {
      New-Item -ItemType Directory -Path $extractPath | Out-Null
    } 

    # Extract the zip file
    Expand-Archive -Path $tempZipPath -DestinationPath $extractPath -Force

    # Get the list of font files from the extracted directory
    $fontFiles = Get-ChildItem -Path $extractPath -Filter "*.ttf"
    if (-not $fontFiles) { throw "No font files found in archive." }

    foreach ($Font in $fontFiles) {
      # Copy to C:\Windows\Fonts
      Copy-Item $Font $fontsPath
      New-ItemProperty -Name $Font.BaseName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType String -Value $Font.Name -Force | Out-Null
    }
  
    # Clean up
    Remove-Item -Path $tempZipPath -Force
    Remove-Item -Path $extractPath -Recurse -Force

    Write-Output "${FontDisplayName} font has been installed successfully."
  }
  catch {
    Write-Error "Failed to install ${FontDisplayName}. Error: $_"
    return
  }

}

function Install-Profile {
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

      Invoke-RestMethod https://raw.githubusercontent.com/tonytech83/powershell-profile/refs/heads/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
      Write-Host "The profile @ [$PROFILE] has been created."
    }
    catch {
      Write-Error "Failed to create or update the profile. Error: $_"
    }
  }
  else {
    try {
      $backupPath = Join-Path (Split-Path $PROFILE) "oldprofile.ps1"
      Move-Item -Path $PROFILE -Destination $backupPath -Force
      Invoke-RestMethod https://raw.githubusercontent.com/tonytech83/powershell-profile/refs/heads/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
      Write-Host "PowerShell profile at [$PROFILE] has been updated."
      Write-Host "Your old profile has been backed up to [$backupPath]"
    }
    catch {
      Write-Error "Failed to backup and update the profile. Error: $_"
    }
  }
}

# Helper function to install apps via winget
function Install-WingetPackage {
  param (
    [string]$Id,
    [string]$Name
  )
  try {
    winget install -e --accept-source-agreements --accept-package-agreements $Id
    Write-Host "$Name has been installed successfully."
  }
  catch {
    Write-Error "Failed to install $Name. Error: $_"
  }
}

function Install-TerminalIcons {
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
    Write-Host "Terminal-Icons has been installed successfully."
  }
  catch {
    Write-Error "Failed to install Terminal-Icons. Error: $_"
  }
  
}

# Install Nerd Font. Change the font here!
Install-NerdFont -FontName "JetBrainsMono" -FontDisplayName "JetBrainsMono NF"

# Install Profile
Install-Profile

# Installation 
Install-WingetPackage -Id "JanDeDobbeleer.OhMyPosh" -Name "OhMyPosh"
Install-WingetPackage -Id "junegunn.fzf" -Name "fzf"
Install-WingetPackage -Id "ajeetdsouza.zoxide" -Name "zoxide"
Install-TerminalIcons
