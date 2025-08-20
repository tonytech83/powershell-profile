<#
  Ensure the script runs with administrative privileges. If not elevated,
  relaunches itself with UAC prompt so the user can enter admin credentials.
#>
param(
  [switch]$__Elevated
)

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
  if (-not $__Elevated) {
    Write-Host "Re-launching with administrative privileges..." -ForegroundColor Yellow

    $scriptPath = $PSCommandPath
    if (-not $scriptPath) { $scriptPath = $MyInvocation.MyCommand.Definition }
    $scriptPath = (Resolve-Path -LiteralPath $scriptPath).Path

    # Use the same pwsh binary as the current process
    $pwshPath = (Get-Process -Id $PID).Path
    $workingDir = (Get-Location).Path

    # Preserve and quote incoming args
    $escapedArgs = @()
    foreach ($a in $args) { $escapedArgs += '"' + ($a -replace '"', '\"') + '"' }
    $argString = ("-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -__Elevated " + ($escapedArgs -join ' ')).Trim()

    try {
      Start-Process -FilePath $pwshPath -WorkingDirectory $workingDir -Verb RunAs -ArgumentList $argString | Out-Null
      exit
    }
    catch {
      Write-Error "Admin elevation was cancelled or failed. $_"
      exit 1
    }
  }
  else {
    Write-Error "Script is still not elevated after relaunch. Please run PowerShell as Administrator and re-run the script."
    exit 1
  }
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

# Replace individual try-catch blocks with helper function calls
Install-WingetPackage -Id "JanDeDobbeleer.OhMyPosh" -Name "OhMyPosh"
Install-WingetPackage -Id "junegunn.fzf" -Name "fzf"
Install-WingetPackage -Id "ajeetdsouza.zoxide" -Name "zoxide"

# Run the function to install the font
Install-JetBrainsMonoNerdFont -FontName "JetBrainsMono" -FontDisplayName "JetBrainsMono NF"