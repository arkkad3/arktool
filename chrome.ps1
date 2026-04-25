$prefPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Preferences"

# Make sure Chrome is closed before running this
if (Test-Path $prefPath) {
    $json = Get-Content $prefPath -Raw | ConvertFrom-Json

    # Ensure session object exists
    if (-not $json.session) {
        $json | Add-Member -MemberType NoteProperty -Name session -Value (@{})
    }

    # Set startup behavior:
    # 4 = Open specific pages
    $json.session.restore_on_startup = 4
    $json.session.startup_urls = @("chrome://settings/help")

    # Save changes
    $json | ConvertTo-Json -Depth 100 | Set-Content $prefPath -Encoding UTF8

    Write-Host "Startup page successfully set to chrome://settings/help"
} else {
    Write-Host "Chrome Preferences file not found."
}
