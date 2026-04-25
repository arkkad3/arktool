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

    $files = @(
        Join-Path $profile.FullName "Preferences",
        Join-Path $profile.FullName "Secure Preferences"
    )

    foreach ($file in $files) {

        if (-not (Test-Path $file)) {
            Write-Host "File not found: $file (skipping)"
            continue
        }

        Write-Host "Editing: $file"

        # 4. Backup file
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFile = "$file.bak_$timestamp"

        Copy-Item $file $backupFile -Force
        Write-Host "Backup created: $backupFile"

        try {
            # 5. Load JSON
            $json = Get-Content $file -Raw | ConvertFrom-Json

            # 6. Ensure session object exists
            if (-not $json.session) {
                $json | Add-Member -MemberType NoteProperty -Name session -Value (@{})
            }

            # 7. Apply startup settings
            $json.session.restore_on_startup = 4
            $json.session.startup_urls = @("chrome://settings/help")

            # 8. Save changes
            $json | ConvertTo-Json -Depth 100 | Set-Content $file -Encoding UTF8

            Write-Host "Updated successfully"
        }
        catch {
            Write-Host "Failed to edit: $file"
        }
    }
}

Write-Host "`nAll profiles and files processed."
