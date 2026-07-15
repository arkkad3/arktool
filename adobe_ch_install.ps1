Write-Host "=== Adobe Acrobat Reader Installation ===" -ForegroundColor Cyan

# Function to check if Adobe Reader is installed and up-to-date
function Test-AdobeReaderInstalled {
    $installed = winget list --id Adobe.Acrobat.Reader.64-bit -e --accept-source-agreements 2>$null
    if ($installed -match "Adobe Acrobat Reader") {
        Write-Host "Adobe Acrobat Reader is already installed." -ForegroundColor Green
        return $true
    }
    return $false
}

# Check and install/upgrade Chocolatey
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey not found. Installing..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} 
else {
    Write-Host "Chocolatey is installed." -ForegroundColor Green
    # Upgrade Chocolatey if needed
    choco upgrade chocolatey -y --whatif | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Upgrading Chocolatey..." -ForegroundColor Yellow
        choco upgrade chocolatey -y
    }
}

# Adobe Reader Checkpoint
Write-Host "Checking Adobe Acrobat Reader status..." -ForegroundColor Cyan

$readerInstalled = winget list --id Adobe.Acrobat.Reader.64-bit -e --accept-source-agreements 2>$null

if ($readerInstalled -match "Adobe Acrobat Reader") {
    Write-Host "Adobe Acrobat Reader is installed. Checking for updates..." -ForegroundColor Green
    
    # Try to upgrade if newer version available
    $upgradeOutput = choco upgrade adobereader -y --whatif 2>&1
    if ($upgradeOutput -match "can be upgraded") {
        Write-Host "Newer version available. Updating Adobe Acrobat Reader..." -ForegroundColor Yellow
        choco upgrade adobereader --params "/UpdateMode:3 /NoAutoUpdate /DesktopIcon" -y
    } else {
        Write-Host "Adobe Acrobat Reader is already up to date. Skipping installation." -ForegroundColor Green
        # Still proceed to cleanup
    }
} 
else {
    Write-Host "Adobe Acrobat Reader not found. Installing..." -ForegroundColor Yellow
    choco install adobereader --params "/UpdateMode:3 /NoAutoUpdate /DesktopIcon" -y --force
}

Write-Host "Adobe installation process completed!" -ForegroundColor Green

# Housekeeping: Remove Chocolatey
Write-Host "Cleaning up - Removing Chocolatey..." -ForegroundColor Cyan
choco uninstall chocolatey -y --force

Write-Host "All done! Chocolatey has been removed." -ForegroundColor Green
