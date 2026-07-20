<#
.SYNOPSIS
    Checks the installed Adobe Acrobat Reader DC version against a known
    "latest available" version you specify (matching the installer you've
    hosted on OneDrive), and silently installs/updates only if needed.

.NOTES
    Designed to be called from a Kaseya VSA / Endpoint Manager Agent
    Procedure via an "Execute Shell Command" step:

        powershell.exe -NoProfile -ExecutionPolicy Bypass -File AdobeReaderDC-Check-Update.ps1

    WHY YOU MUST SET $LatestVersion MANUALLY:
    Adobe doesn't publish a stable "always latest" download URL or a
    simple public API for current Reader DC version (that's what Remote
    Update Manager exists to solve, which we're intentionally not using
    here). So this script trusts you to keep two things in sync whenever
    Adobe releases a new version:
      1) Re-download the latest Reader DC installer from
         https://get.adobe.com/reader/enterprise/ and re-upload it to
         OneDrive (same filename/link is fine - just overwrite it)
      2) Update the $LatestVersion value below to match that installer's
         version number (visible in the downloaded filename, e.g.
         "AcroRdrDC2500120432_en_US.exe" -> version "25.001.20432")

    Exit codes (for Kaseya IF LAST SCRIPT EXIT CODE branching):
        0 = success, already up to date, no action taken
        2 = success, install/update performed
        1 = error occurred
#>

# ---------------------------------------------------------------------------
# CONFIG - update these whenever you refresh the installer
# ---------------------------------------------------------------------------
$ReaderInstallerUrl = "https://palawanpawnshop.sharepoint.com/:u:/s/RCBServiceDeskTeam/IQBRYfjeVspiSoxtgn4jjIsBAeAyJGifTgl9RbQ-LO9Dxsw?e=PzBNHU&download=1"
$LatestVersion       = "C2.600.121662"   # <-- update this to match the installer you uploaded
$WorkDir             = "C:\Kaseya\AdobeReader"
$LogPath             = "C:\ProgramData\Kaseya\AdobeReaderUpdate.log"

# ---------------------------------------------------------------------------
function Write-Log {
    param([string]$Message)
    $line = "{0} - {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    New-Item -Path (Split-Path $LogPath) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    Add-Content -Path $LogPath -Value $line
    Write-Output $line
}

function Get-InstalledReaderVersion {
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($path in $uninstallPaths) {
        $hit = Get-ItemProperty $path -ErrorAction SilentlyContinue |
               Where-Object { $_.DisplayName -like "Adobe Acrobat Reader*" -or $_.DisplayName -like "Adobe Acrobat (64-bit)*" } |
               Select-Object -First 1
        if ($hit) { return $hit.DisplayVersion }
    }
    # Fallback: check AcroRd32.exe / Acrobat.exe file version directly
    foreach ($exe in @(
        "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe",
        "C:\Program Files\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe",
        "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
    )) {
        if (Test-Path $exe) { return (Get-Item $exe).VersionInfo.ProductVersion }
    }
    return $null
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
New-Item -Path $WorkDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$installedBefore = Get-InstalledReaderVersion
$exitCode        = 0

Write-Log "Starting Adobe Reader DC check on $env:COMPUTERNAME."
Write-Log "Installed version: $(if ($installedBefore) {$installedBefore} else {'Not installed'}) | Latest available: $LatestVersion"

try {
    if (-not $installedBefore) {
        Write-Log "Reader not found. Installing fresh."
        $needsInstall = $true
    }
    elseif ($installedBefore -ne $LatestVersion) {
        Write-Log "Installed version differs from latest ($installedBefore vs $LatestVersion). Updating."
        $needsInstall = $true
    }
    else {
        Write-Log "Already up to date ($installedBefore). No action taken."
        $needsInstall = $false
    }

    if ($needsInstall) {
        $installerPath = Join-Path $WorkDir "ReaderDCInstaller.exe"
        Write-Log "Downloading installer."
        Invoke-WebRequest -Uri $ReaderInstallerUrl -OutFile $installerPath -UseBasicParsing

        Write-Log "Installing silently."
        # /sAll = fully silent, /rs = suppress reboot, EULA_ACCEPT=YES required for unattended install
        # Running this over an existing install performs an in-place update.
        Start-Process -FilePath $installerPath -ArgumentList "/sAll /rs /msi EULA_ACCEPT=YES" -Wait -NoNewWindow

        $installedAfter = Get-InstalledReaderVersion
        Write-Log "Done. Version now: $installedAfter"
        $exitCode = 2
    }
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    $exitCode = 1
}
finally {
    Remove-Item (Join-Path $WorkDir "ReaderDCInstaller.exe") -Force -ErrorAction SilentlyContinue
}

exit $exitCode
