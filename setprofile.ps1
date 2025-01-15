# Get the PowerShell profile directory path
$profilePath = Split-Path -Path $PROFILE

# Create profile directory if it doesn't exist
if (-not (Test-Path $profilePath)) {
  New-Item -ItemType Directory -Path $profilePath -Force
  Write-Host "Created profile directory: $profilePath"
} catch {
  Write-Error "Failed to create folder: $_"
  exit 1
}


# Copy profile with confirmation and backup
try {
  Copy-Item ".\Microsoft.PowerShell_profile.ps1" -Destination $profilePath
  Write-Host "Successfully copied PowerShell profile to: $profilePath"
} catch {
  Write-Error "Failed to copy profile: $_"
  exit 1
}