# 1. Stop Chrome if running
Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue

# 2. Base Chrome user data path
$chromeUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data"

if (-not (Test-Path $chromeUserData)) {
    Write-Host "Chrome User Data folder not found."
    exit
}

# 3. Get all profile folders
$profiles = Get-ChildItem -Path $chromeUserData -Directory | Where-Object {
    $_.Name -eq "Default" -or $_.Name -like "Profile*"
}

foreach ($profile in $profiles) {

    Write-Host "`nProcessing profile: $($profile.Name)"

    $prefPath = Join-Path $profile.FullName "Preferences"
    $securePrefPath = Join-Path $profile.FullName "Secure Preferences"

    # 4. Select target file
    if (Test-Path $prefPath) {
        $targetFile = $prefPath
        Write-Host "Using Preferences file"
    }
    elseif (Test-Path $securePrefPath) {
        $targetFile = $securePrefPath
        Write-Host "Preferences not found, using Secure Preferences"
    }
    else {
        Write-Host "No preferences file found for this profile. Skipping."
        continue
    }

    # 5. Backup file
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "$targetFile.bak_$timestamp"

    Copy-Item $targetFile $backupFile -Force
    Write-Host "Backup created: $backupFile"

    try {
        # 6. Load JSON
        $json = Get-Content $targetFile -Raw | ConvertFrom-Json

        # 7. Ensure session object exists
        if (-not $json.session) {
            $json | Add-Member -MemberType NoteProperty -Name session -Value (@{})
        }

        # 8. Apply settings
        $json.session.restore_on_startup = 4
        $json.session.startup_urls = @("chrome://settings/help")

        # 9. Save changes
        $json | ConvertTo-Json -Depth 100 | Set-Content $targetFile -Encoding UTF8

        Write-Host "Startup page set successfully"
    }
    catch {
        Write-Host "Failed to process profile: $($profile.Name)"
    }
}

Write-Host "`nAll profiles processed."
