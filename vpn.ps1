$url = "https://raw.githubusercontent.com/username/repo/main/installer.exe"
$output = "$env:TEMP\installer.exe"

# Download the EXE
Invoke-WebRequest $url -OutFile $output

# Run the installer
Start-Process $output
