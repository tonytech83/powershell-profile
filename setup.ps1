<#
  Setup script for PowerShell profile. Elevation is applied only to the font
  installation step when needed.
#>
param(
  [switch]$InstallFontOnly,
  [string]$FontName = "JetBrainsMono",
  [string]$FontDisplayName = "JetBrainsMono NF",
  [string]$Version = "3.2.1",
  [switch]$AllUsers
)

# Determine elevation status
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If we're asked to install fonts for all users but we're not elevated,
# relaunch only this script step elevated and exit the current process.
if ($InstallFontOnly -and $AllUsers -and -not $isAdmin) {
  $scriptPath = $PSCommandPath
  if (-not $scriptPath) { $scriptPath = $MyInvocation.MyCommand.Definition }
  $scriptPath = (Resolve-Path -LiteralPath $scriptPath).Path
  $pwshPath = (Get-Process -Id $PID).Path

  $argList = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath,
    '-InstallFontOnly', '-AllUsers',
    '-FontName', $FontName,
    '-FontDisplayName', $FontDisplayName,
    '-Version', $Version
  )
  Start-Process -FilePath $pwshPath -Verb RunAs -ArgumentList $argList | Out-Null
  exit
}

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

# If only the font installation is requested, do just that and exit
if ($InstallFontOnly) {
  Install-JetBrainsMonoNerdFont -FontName $FontName -FontDisplayName $FontDisplayName -Version $Version
  return
}

# Full setup path
# Replace individual try-catch blocks with helper function calls
Install-WingetPackage -Id "JanDeDobbeleer.OhMyPosh" -Name "OhMyPosh"
Install-WingetPackage -Id "junegunn.fzf" -Name "fzf"
Install-WingetPackage -Id "ajeetdsouza.zoxide" -Name "zoxide"

# Install the font as part of full setup
Install-JetBrainsMonoNerdFont -FontName $FontName -FontDisplayName $FontDisplayName -Version $Version