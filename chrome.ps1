$chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Preferences"

$json = Get-Content $chromePath -Raw | ConvertFrom-Json

# Set startup behavior to open specific pages
$json.session.startup_urls = @("chrome://settings/help")
$json.session.restore_on_startup = 4

# Save back
$json | ConvertTo-Json -Depth 100 | Set-Content $chromePath
