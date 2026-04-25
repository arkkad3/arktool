# 1. Stop Chrome if running
Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue

# 2. Define paths
$basePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default"
$prefPath = Join-Path $basePath "Secure Preferences"
$securePrefPath = Join-Path $basePath "Preferences"

# 3. Select target file
if (Test-Path $prefPath) {
    $targetFile = $prefPath
    Write-Host "Using Preferences file"
}
elseif (Test-Path $securePrefPath) {
    $targetFile = $securePrefPath
    Write-Host "Preferences not found, using Secure Preferences"
}
else {
    Write-Host "No Chrome preferences file found."
    exit
}

# 4. Create backup (with timestamp)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "$targetFile.bak_$timestamp"

Copy-Item $targetFile $backupFile -Force
Write-Host "Backup created: $backupFile"

# 5. Load JSON
$json = Get-Content $targetFile -Raw | ConvertFrom-Json

# 6. Ensure session object exists
if (-not $json.session) {
    $json | Add-Member -MemberType NoteProperty -Name session -Value (@{})
}

# 7. Apply startup settings
$json.session.restore_on_startup = 4
$json.session.startup_urls = @("chrome://settings/help")

# 8. Save changes
$json | ConvertTo-Json -Depth 100 | Set-Content $targetFile -Encoding UTF8

Write-Host "Startup page set to chrome://settings/help"
