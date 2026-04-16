$url = "https://github.com/arkkad3/arktool/raw/refs/heads/Utility/FortiClientVPNInstaller.exe"
$output = "$env:TEMP\FortiClientVPNInstaller.exe"

# Download the EXE
Invoke-WebRequest $url -OutFile $output

# Run the installer
Start-Process $output
