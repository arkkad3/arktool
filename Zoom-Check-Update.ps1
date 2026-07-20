<#
.SYNOPSIS
    Checks the installed Zoom client version and silently updates it if
    a newer version is available. Does nothing if already current.

.NOTES
    Designed to be called from a Kaseya VSA / Endpoint Manager Agent
    Procedure via an "Execute Shell Command" or "Run Script" step:

        powershell.exe -NoProfile -ExecutionPolicy Bypass -File Zoom-Check-Update.ps1

    Requires: Windows PowerShell 5.1+, outbound internet access to zoom.us.
    Run in SYSTEM context (Kaseya default) so it can query/install the
    machine-wide Zoom MSI.

    Exit codes (useful for Kaseya IF LAST SCRIPT EXIT CODE branching):
        0 = success, no action needed (already up to date)
        2 = success, Zoom was installed/updated
        1 = error occurred
#>

# ---------------------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------------------
$ZoomMsiUrl = "https://zoom.us/client/latest/ZoomInstallerFull.msi?archType=x64"
$LogPath    = "C:\ProgramData\Kaseya\ZoomUpdate.log"

# ---------------------------------------------------------------------------
function Write-Log {
    param([string]$Message)
    $line = "{0} - {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    New-Item -Path (Split-Path $LogPath) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    Add-Content -Path $LogPath -Value $line
    Write-Output $line
}

function Get-InstalledZoomVersion {
    # Checks both machine-wide (HKLM) and per-user Zoom install locations,
    # since Zoom historically defaults to a per-user install.
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $uninstallPaths) {
        $hit = Get-ItemProperty $path -ErrorAction SilentlyContinue |
               Where-Object { $_.DisplayName -like "Zoom*" } |
               Select-Object -First 1
        if ($hit) { return $hit.DisplayVersion }
    }

    # Fallback: check the Zoom.exe file version directly (per-user AppData install)
    $exePath = "$env:APPDATA\Zoom\bin\Zoom.exe"
    if (Test-Path $exePath) {
        return (Get-Item $exePath).VersionInfo.ProductVersion
    }

    return $null   # Zoom not installed
}

function Get-LatestZoomVersion {
    param([string]$MsiPath)

    # Read the ProductVersion property straight out of the downloaded MSI
    # using the Windows Installer COM object - no install needed to check.
    $installer = New-Object -ComObject WindowsInstaller.Installer
    $db = $installer.GetType().InvokeMember(
        "OpenDatabase", "InvokeMethod", $null, $installer, @($MsiPath, 0)
    )
    $view = $db.GetType().InvokeMember(
        "OpenView", "InvokeMethod", $null, $db,
        @("SELECT Value FROM Property WHERE Property = 'ProductVersion'")
    )
    $view.GetType().InvokeMember("Execute", "InvokeMethod", $null, $view, $null) | Out-Null
    $record = $view.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view, $null)
    return $record.GetType().InvokeMember("StringData", "GetProperty", $null, $record, @(1))
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
$installedBefore = Get-InstalledZoomVersion
$tempMsi         = Join-Path $env:TEMP "ZoomInstallerFull.msi"
$exitCode        = 0

Write-Log "Starting Zoom check on $env:COMPUTERNAME. Installed version: $(if ($installedBefore) {$installedBefore} else {'Not installed'})"

try {
    # Always pull the latest installer so we can read its true version
    Invoke-WebRequest -Uri $ZoomMsiUrl -OutFile $tempMsi -UseBasicParsing
    $latestVersion = Get-LatestZoomVersion -MsiPath $tempMsi
    Write-Log "Latest available version: $latestVersion"

    if (-not $installedBefore) {
        Write-Log "Zoom not found - installing fresh (silent)."
        Start-Process msiexec.exe -ArgumentList "/i `"$tempMsi`" /qn /norestart ALLUSERS=1" -Wait -NoNewWindow
        $installedAfter = Get-InstalledZoomVersion
        Write-Log "Install complete. Version now: $installedAfter"
        $exitCode = 2
    }
    elseif ($installedBefore -ne $latestVersion) {
        Write-Log "Zoom outdated ($installedBefore -> $latestVersion). Installing silently."
        Start-Process msiexec.exe -ArgumentList "/i `"$tempMsi`" /qn /norestart ALLUSERS=1" -Wait -NoNewWindow
        $installedAfter = Get-InstalledZoomVersion
        Write-Log "Update complete. Version now: $installedAfter"
        $exitCode = 2
    }
    else {
        Write-Log "Zoom already up to date ($installedBefore). No action taken."
        $exitCode = 0
    }
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    $exitCode = 1
}
finally {
    Remove-Item $tempMsi -Force -ErrorAction SilentlyContinue
}

exit $exitCode
