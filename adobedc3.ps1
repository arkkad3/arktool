$temp = "$env:TEMP\AcroRdrDC.exe"

Invoke-WebRequest `
-Uri "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/latest/AcroRdrDCx64.exe" `
-OutFile $temp

Start-Process $temp -ArgumentList "/sAll /rs /msi EULA_ACCEPT=YES" -Wait

Remove-Item $temp -Force
