# Ensure the script can run with elevated privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Warning "Please run this script as an Administrator!"
  break
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

      # Check if profilePath exists, if not create it
      if (!(Test-Path -Path $profilePath)) {
        New-Item -Path $profilePath -ItemType "directory"
      }

      Invoke-RestMethod https://github.com/tonytech83/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
      Write-Host "The profile @ [$PROFILE] has been created."
      Write-Host "If you want to make any personal changes or customizations, please do so at [$profilePath\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
      Write-Error "Failed to create or update the profile. Error: $_"
    }
  }
  else {
    # PROFILE already exists
    try {
      $backupPath = Join-Path (Split-Path $PROFILE) "oldprofile.ps1"
      Move-Item -Path $PROFILE -Destination $backupPath -Force
      Invoke-RestMethod https://github.com/tonytech83/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
      Write-Host "✅ PowerShell profile at [$PROFILE] has been updated."
      Write-Host "📦 Your old profile has been backed up to [$backupPath]"
      Write-Host "⚠️ NOTE: Please back up any persistent components of your old profile to [$HOME\Documents\PowerShell\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
      Write-Error "❌ Failed to backup and update the profile. Error: $_"
    }
  }

}

function Install-NerdFont {
  param (
    [string]$FontName = "JetBrainsMono",
    [string]$FontDisplayName = "JetBrainsMono NF",
    [string]$Version = "3.2.1"
  )

  # Installed Font Families
  $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

  # Installed Font Families
  $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

  if ($fontFamilies -notcontains "${FontDisplayName}") {
    # Define the URL for the JetBrainsMono Nerd Font zip file
    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${Version}/${FontName}.zip"
      
    # Define the path where the zip file will be downloaded
    $tempZipPath = "$env:TEMP\JetBrainsMono.zip"
      
    # Define the directory where the font files will be extracted
    $extractPath = "$env:TEMP\JetBrainsMono"

    # Define the fonts installation path
    $fontsPath = "$env:SystemRoot\Fonts"

    try {
      # Download the font zip file
      Invoke-WebRequest -Uri $fontUrl -OutFile $tempZipPath
      
      # Add verification that download succeeded
      if (-not (Test-Path -Path $tempZipPath)) {
        throw "Font download failed"
      }

      # Create a directory to extract the fonts
      if (-not (Test-Path -Path $extractPath)) {
        New-Item -ItemType Directory -Path $extractPath | Out-Null
      }

      # Extract the zip file
      Expand-Archive -Path $tempZipPath -DestinationPath $extractPath -Force

      # Get the list of font files from the extracted directory
      $fontFiles = Get-ChildItem -Path $extractPath -Filter "*.ttf"

      # Copy the font files to the Fonts directory
      foreach ($fontFile in $fontFiles) {
        Copy-Item -Path $fontFile.FullName -Destination $fontsPath -Force
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
  else {
    Write-Host "Font ${FontDisplayName} already installed"
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
