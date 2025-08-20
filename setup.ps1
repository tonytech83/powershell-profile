function Install-JetBrainsMonoNerdFont {
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

function installTerminalIcons {
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
    Install-Module -Name Terminal-Icons -Repository PSGallery
    Write-Host "Terminal-Icons has been installed successfully."
  }
  catch {
    Write-Error "Failed to install Terminal-Icons. Error: $_"
  }
  
}

# Installation 
Install-WingetPackage -Id "JanDeDobbeleer.OhMyPosh" -Name "OhMyPosh"
Install-WingetPackage -Id "junegunn.fzf" -Name "fzf"
Install-WingetPackage -Id "ajeetdsouza.zoxide" -Name "zoxide"

# install Terminal-Icons
installTerminalIcons

# Install the font as part of full setup. Change the font here!
Install-JetBrainsMonoNerdFont -FontName "JetBrainsMono" -FontDisplayName "JetBrainsMono NF"
