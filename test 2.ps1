Write-Host "1. Install Chrome"
Write-Host "2. Install VS Code"
Write-Host "3. Exit"

$choice = Read-Host "Choose option"

switch ($choice) {

1 { winget install Google.Chrome }

2 { winget install Microsoft.VisualStudioCode }

3 { exit }

}