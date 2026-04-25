# 1. Stop Chrome if running
Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue

# 2. Define possible paths
$basePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default"
$prefPath = Join-Path $basePath "Secure Preferences"
$securePrefPath = Join-Path $basePath "Preferences"

# 3. Choose which file to use
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

# 4. Load JSON
$json = Get-Content $targetFile -Raw | ConvertFrom-Json

# 5. Ensure session object exists
if (-not $json.session) {
    $json | Add-Member -MemberType NoteProperty -Name session -Value (@{})
}

# 6. Apply startup settings
$json.session.restore_on_startup = 4
$json.session.startup_urls = @("chrome://settings/help")

# 7. Save back
$json | ConvertTo-Json -Depth 100 | Set-Content $targetFile -Encoding UTF8

Write-Host "Startup page set to chrome://settings/help"
