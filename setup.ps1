function Install-JetBrainsMonoNerdFont {
  param (
    [string]$FontName = "JetBrainsMono",
    [string]$FontDisplayName = "JetBrainsMono NF",
    [string]$Version = "3.2.1"
  )

  # Installed Font Families
  $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

  if ($fontFamilies -notcontains "${FontDisplayName}") {
    # Define the URL for the JetBrainsMono Nerd Font zip file
    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${Version}/${FontName}.zip"
      
    # Define the path where the zip file will be downloaded
    $tempZipPath = "$env:TEMP\JetBrainsMono.zip"
      
    # Define the directory where the font files will be extracted
    $extractPath = "$env:TEMP\JetBrainsMono"

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
      $fontFiles = Get-ChildItem -Path $extractPath -Recurse -Filter "*.ttf"

      if (-not $fontFiles -or $fontFiles.Count -eq 0) {
        throw "No .ttf files found in the downloaded archive"
      }

      # Determine elevation status
      $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
      $principal = New-Object Security.Principal.WindowsPrincipal $identity
      $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

      if ($isAdmin) {
        # Install for all users (requires admin)
        $fontsPath = "$env:SystemRoot\Fonts"
        foreach ($fontFile in $fontFiles) {
          Copy-Item -Path $fontFile.FullName -Destination $fontsPath -Force
        }
      }
      else {
        # Install per-user without elevation using Fonts shell folder
        $shell = New-Object -ComObject Shell.Application
        $fontsFolder = $shell.NameSpace(0x14) # CSIDL_FONTS
        foreach ($fontFile in $fontFiles) {
          $null = $fontsFolder.CopyHere($fontFile.FullName, 16)
        }
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
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  Register-PSResourceRepository -PSGallery -Trusted

  Install-Module -Name Terminal-Icons -Repository PSGallery
}

function installOhMyPosh {
  winget install --id JanDeDobbeleer.OhMyPosh --source winget --scope User --accept-package-agreements --accept-source-agreements
}

# Full setup path
# Replace individual try-catch blocks with helper function calls
# Install-WingetPackage -Id "JanDeDobbeleer.OhMyPosh" -Name "OhMyPosh"
Install-WingetPackage -Id "junegunn.fzf" -Name "fzf"
Install-WingetPackage -Id "ajeetdsouza.zoxide" -Name "zoxide"

# Install installOhMyPosh
installOhMyPosh

# install Terminal-Icons
installTerminalIcons

# Install the font as part of full setup
Install-JetBrainsMonoNerdFont -FontName $FontName -FontDisplayName $FontDisplayName -Version $Version