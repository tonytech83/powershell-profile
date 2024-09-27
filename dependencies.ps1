function Install-JetBrainsMonoNerdFont {
  param (
    [string]$FontName = "JetBrainsMono",
    [string]$FontDisplayName = "JetBrainsMono NF",
    [string]$Version = "3.2.1"
  )

  # Installed Font Families
  $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

  if ($fontFamilies -notcontains "${FontDisplayNmae}") {
    # Define the URL for the JetBrainsMono Nerd Font zip file
    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${Version}/${FontName}.zip"
      
    # Define the path where the zip file will be downloaded
    $tempZipPath = "$env:TEMP\JetBrainsMono.zip"
      
    # Define the directory where the font files will be extracted
    $extractPath = "$env:TEMP\JetBrainsMono"

    # Define the fonts installation path
    $fontsPath = "$env:SystemRoot\Fonts"

    # Download the font zip file
    Invoke-WebRequest -Uri $fontUrl -OutFile $tempZipPath

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
  else {
    Write-Host "Font ${FontDisplayName} already installed"
  }
}

# Install OhMyPosh
try {
  winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
}
catch {
  Write-Error "Failed to install Oh My Posh. Error: $_"
}

# Terminal Icons Install
try {
  Install-Module -Name Terminal-Icons -Repository PSGallery -Force
}
catch {
  Write-Error "Failed to install Terminal Icons module. Error: $_"
}

# zoxide Install
try {
  winget install -e --id ajeetdsouza.zoxide
  Write-Host "zoxide installed successfully."
}
catch {
  Write-Error "Failed to install zoxide. Error: $_"
}

# Run the function to install the font
Install-JetBrainsMonoNerdFont
