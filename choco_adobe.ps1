# === Install Adobe Acrobat Reader via Chocolatey ===

# Install Chocolatey if missing
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Install Adobe Acrobat Reader (with settings to retain preferences)
Write-Host "Installing Adobe Acrobat Reader..." -ForegroundColor Green
choco install adobereader --params "/UpdateMode:3 /NoAutoUpdate /DesktopIcon" -y --force

Write-Host "Installation completed!" -ForegroundColor Green
