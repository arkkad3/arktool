<#
.SYNOPSIS
    Silently uninstalls 7-Zip (all versions/architectures) from a Windows machine.
.NOTES
    Designed for use as a Kaseya VSA Agent Procedure step (Execute Shell Command / Run Script - PowerShell).
    Exit code 0 = success or already absent. Exit code 1 = failure.
#>

$ErrorActionPreference = "SilentlyContinue"
$logPrefix = "[7Zip-Uninstall]"

function Write-Log {
    param([string]$Message)
    Write-Output "$logPrefix $Message"
}

Write-Log "Starting 7-Zip removal check on $env:COMPUTERNAME"

# --- Step 1: Kill any processes that might lock the installer/files ---
$processesToKill = @("7zFM", "7zG", "7zip", "7z")
foreach ($proc in $processesToKill) {
    $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($running) {
        Write-Log "Killing running process: $proc"
        Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
    }
}

# --- Step 2: Search both registry uninstall hives (32-bit and 64-bit) ---
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$found = @()
foreach ($path in $uninstallPaths) {
    $entries = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "7-Zip*" }
    if ($entries) {
        $found += $entries
    }
}

if (-not $found -or $found.Count -eq 0) {
    Write-Log "7-Zip not found on this machine. Nothing to do."
    exit 0
}

# --- Step 3: Uninstall each found entry (covers edge cases of multiple installs) ---
$allSucceeded = $true

foreach ($entry in $found) {
    $displayName = $entry.DisplayName
    $uninstallString = $entry.UninstallString
    $quietUninstallString = $entry.QuietUninstallString

    Write-Log "Found: $displayName"

    if ([string]::IsNullOrWhiteSpace($uninstallString)) {
        Write-Log "No UninstallString found for $displayName — skipping."
        $allSucceeded = $false
        continue
    }

    try {
        if ($uninstallString -match "msiexec") {
            # MSI-based install — extract the product code and run silent uninstall
            if ($uninstallString -match "(\{[0-9A-Fa-f\-]+\})") {
                $productCode = $matches[1]
                Write-Log "MSI uninstall detected. Product code: $productCode"
                $proc = Start-Process -FilePath "msiexec.exe" `
                    -ArgumentList "/x $productCode /qn /norestart" `
                    -Wait -PassThru -NoNewWindow
                Write-Log "msiexec exit code: $($proc.ExitCode)"
                if ($proc.ExitCode -ne 0) { $allSucceeded = $false }
            } else {
                Write-Log "Could not parse MSI product code from: $uninstallString"
                $allSucceeded = $false
            }
        }
        else {
            # NSIS-based install (standard 7-Zip.org installer) — use /S for silent
            # Strip surrounding quotes from the exe path if present
            $exePath = $uninstallString -replace '^"(.+?)"$', '$1'
            $exePath = $exePath.Trim()

            if (Test-Path $exePath) {
                Write-Log "NSIS uninstall detected. Running: `"$exePath`" /S"
                $proc = Start-Process -FilePath $exePath -ArgumentList "/S" -Wait -PassThru
                Write-Log "Uninstaller exit code: $($proc.ExitCode)"
                if ($proc.ExitCode -ne 0) { $allSucceeded = $false }
            } else {
                Write-Log "Uninstaller executable not found at path: $exePath"
                $allSucceeded = $false
            }
        }
    }
    catch {
        Write-Log "ERROR uninstalling $displayName : $($_.Exception.Message)"
        $allSucceeded = $false
    }
}

# --- Step 4: Verify removal ---
Start-Sleep -Seconds 3
$stillPresent = @()
foreach ($path in $uninstallPaths) {
    $entries = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "7-Zip*" }
    if ($entries) { $stillPresent += $entries }
}

if ($stillPresent.Count -eq 0) {
    Write-Log "SUCCESS: 7-Zip fully removed from $env:COMPUTERNAME"
    exit 0
} else {
    Write-Log "WARNING: 7-Zip entries still present after uninstall attempt: $($stillPresent.DisplayName -join ', ')"
    exit 1
}
