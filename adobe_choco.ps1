# === Adobe Acrobat Reader Installation===

Write-Host "=== Adobe Acrobat Reader Installation ===" -ForegroundColor Cyan

# Check if Chocolatey is installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey not found. Installing..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} 
else {
    Write-Host "Chocolatey is already installed." -ForegroundColor Green
    
    # Check for Chocolatey upgrade
    Write-Host "Checking for Chocolatey updates..." -ForegroundColor Cyan
    $upgradeResult = choco upgrade chocolatey -y --whatif | Out-String
    
    if ($upgradeResult -match "can be upgraded") {
        Write-Host "Newer version of Chocolatey available. Upgrading..." -ForegroundColor Yellow
        choco upgrade chocolatey -y
    } else {
        Write-Host "Chocolatey is up to date." -ForegroundColor Green
    }
}

# Install Adobe Acrobat Reader
Write-Host "Installing Adobe Acrobat Reader..." -ForegroundColor Green
choco install adobereader --params "/UpdateMode:3 /NoAutoUpdate /DesktopIcon" -y --force

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Adobe Acrobat Reader installed successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠️ Adobe installation may have issues (already installed or error)." -ForegroundColor Yellow
}

# Housekeeping: Uninstall Chocolatey
Write-Host "Performing housekeeping - Removing Chocolatey..." -ForegroundColor Cyan
choco uninstall chocolatey -y --force

Write-Host "✅ All done! Chocolatey has been cleaned up." -ForegroundColor Green
