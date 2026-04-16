$url = "https://github.com/username/repo/releases/download/v1.0/installer.exe"
$output = "$env:TEMP\installer.exe"

Write-Host "Downloading installer..."
Invoke-WebRequest $url -OutFile $output

Write-Host "Installing..."
Start-Process $output -ArgumentList "/silent" -Wait

Write-Host "Done!"
