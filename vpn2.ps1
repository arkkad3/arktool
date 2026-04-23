# ==========================================================
# FortiClient Installer + VC++ 2015-2022 Prerequisite (Sequential)
# ==========================================================
# Runs:
#  1) Detect OS arch (x64/x86)
#  2) Verify VC++ 2015-2022 exists (Runtime registry key + fallback uninstall key)
#  3) If missing -> download/install correct VC++ (silent)
#  4) Download/install FortiClient (silent)
# ==========================================================

$ErrorActionPreference = "Stop"

# --------------------------
# URLs (as you provided)
# --------------------------
$FortiUrl    = "https://github.com/arkkad3/arktool/raw/refs/heads/Utility/FortiClientVPNInstaller.exe"

$VcUrlX64    = "https://download.visualstudio.microsoft.com/download/pr/10912041/cee5d6bca2ddbcd039da727bf4acb48a/vcredist_x64.exe"
$VcUrlX86    = "https://download.visualstudio.microsoft.com/download/pr/10912113/5da66ddebb0ad32ebd4b922fd82e8e25/vcredist_x86.exe"

# Temp paths
$FortiOutput = Join-Path $env:TEMP "FortiClientVPNInstaller.exe"
$VcOutput    = Join-Path $env:TEMP "vcredist.exe"

# --------------------------
# Helpers
# --------------------------
function Write-Step($msg) {
    Write-Host ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg)
}

function Ensure-Tls12 {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
}

function Download-File {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$OutFile
    )
    Ensure-Tls12
    Write-Step "Downloading: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
}

function Get-VcRuntimeVersion {
    param([Parameter(Mandatory=$true)][ValidateSet("x64","x86")] [string]$Arch)

    # Reliable VC++ 2015-2022 detection uses this runtime key 【1-9772ff】【2-d932cc】
    $key = "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\$Arch"
    try {
        $p = Get-ItemProperty -Path $key -ErrorAction Stop
        if ($p.Installed -eq 1 -and $p.Version) {
            return [string]$p.Version
        }
    } catch { }
    return $null
}

function Test-VcRedistInstalled {
    param([Parameter(Mandatory=$true)][ValidateSet("x64","x86")] [string]$Arch)

    # 1) Check runtime key first (preferred) 【1-9772ff】【2-d932cc】
    if (Get-VcRuntimeVersion -Arch $Arch) { return $true }

    # 2) Fallback: Uninstall list DisplayName check 【3-5f0476】【1-9772ff】
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $pattern = "Microsoft Visual C++ 2015-2022 Redistributable ($Arch)"
    $found = Get-ItemProperty $paths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and ($_.DisplayName -like "$pattern*") } |
        Select-Object -First 1

    return [bool]$found
}

function Install-VcRedistIfMissing {
    param([Parameter(Mandatory=$true)][ValidateSet("x64","x86")] [string]$Arch)

    Write-Step "Checking VC++ 2015-2022 ($Arch)..."
    if (Test-VcRedistInstalled -Arch $Arch) {
        $ver = Get-VcRuntimeVersion -Arch $Arch
        if ($ver) {
            Write-Step "VC++ 2015-2022 ($Arch) is already installed. Runtime Version: $ver"
        } else {
            Write-Step "VC++ 2015-2022 ($Arch) is already installed (detected via uninstall entry)."
        }
        return
    }

    Write-Step "VC++ 2015-2022 ($Arch) not found. Installing prerequisite..."

    $vcUrl = if ($Arch -eq "x64") { $VcUrlX64 } else { $VcUrlX86 }
    Download-File -Url $vcUrl -OutFile $VcOutput

    Write-Step "Running VC++ installer silently..."
    # Silent parameters: /install /quiet /norestart 【4-caa6fe】
    $p = Start-Process -FilePath $VcOutput -ArgumentList "/install /quiet /norestart" -Wait -PassThru -NoNewWindow

    # 0 = success; 3010 = success but reboot required (common) 【4-caa6fe】
    if ($p.ExitCode -notin 0, 3010) {
        throw "VC++ installer failed. ExitCode=$($p.ExitCode)"
    }

    if ($p.ExitCode -eq 3010) {
        Write-Step "VC++ installed successfully, but a reboot is required (ExitCode=3010)."
    }

    # Give registry a moment to update
    Start-Sleep -Seconds 3

    $runtimeVer = Get-VcRuntimeVersion -Arch $Arch
    if (-not $runtimeVer) {
        throw "VC++ 2015-2022 ($Arch) install completed but runtime key not detected."
    }

    Write-Step "VC++ prerequisite installed and detected. Runtime Version: $runtimeVer"
}

function Install-FortiClient {
    Write-Step "Downloading FortiClient installer..."
    Download-File -Url $FortiUrl -OutFile $FortiOutput

    Write-Step "Installing FortiClient silently..."
    Start-Process -FilePath $FortiOutput -ArgumentList "/silent" -Wait -NoNewWindow

    Write-Step "FortiClient installation completed."
}

# --------------------------
# MAIN (Sequential)
# --------------------------
try {
    $is64 = [Environment]::Is64BitOperatingSystem
    $osArch = if ($is64) { "x64" } else { "x86" }
    Write-Step "Detected OS architecture: $osArch"

    # Install VC++ matching OS architecture
    Install-VcRedistIfMissing -Arch $osArch

    # OPTIONAL (common enterprise practice):
    # On x64 OS, you may also want x86 VC++ because many apps are 32-bit.
    # Uncomment if your environment requires it:
    # if ($is64) { Install-VcRedistIfMissing -Arch "x86" }

    # Install FortiClient
    Install-FortiClient

    Write-Step "DONE!"
}
catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    throw
}
