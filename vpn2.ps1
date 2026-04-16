$url = "https://github.com/arkkad3/arktool/raw/refs/heads/Utility/FortiClientVPNInstaller.exe"
$output = "$env:TEMP\FortiClientVPNInstaller.exe"

Write-Host "Downloading installer..."
Invoke-WebRequest $url -OutFile $output

Write-Host "Installing..."
Start-Process $output -ArgumentList "/silent" -Wait

Write-Host "Done!"
