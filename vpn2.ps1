# ==========================================================
# FortiClient Installer + VC++ 2015-2022 Prerequisite (Sequential)
# ==========================================================
$ErrorActionPreference = "Stop"

# --------------------------
# URLs (as provided)
# --------------------------
$FortiUrl = "https://github.com/arkkad3/arktool/raw/refs/heads/Utility/FortiClientVPNInstaller.exe"

$VcUrlX64 = "https://download.visualstudio.microsoft.com/download/pr/6f02464a-5e9b-486d-a506-c99a17db9a83/8995548DFFFCDE7C49987029C764355612BA6850EE09A7B6F0FDDC85BDC5C280/VC_redist.x64.exe"
$VcUrlX86 = "https://download.visualstudio.microsoft.com/download/pr/7a47a870-bdd8-4301-9619-349e12b16c5d/E7267C1BDF9237C0B4A28CF027C382B97AA909934F84F1C92D3FB9F04173B33E/VC_redist.x86.exe"

# Temp paths
$FortiOutput = Join-Path $env:TEMP "FortiClientVPNInstaller.exe"
$VcOutput    = Join-Path $env:TEMP "vcredist.exe"

# --------------------------
# Helpers
# --------------------------
function Write-Step([string]$msg) {
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
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("x64","x86")]
        [string]$Arch
    )

    # Reliable detection for VC++ 2015-2022 uses this runtime key 【1-dee9b5】【2-fdd9a7】
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
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("x64","x86")]
        [string]$Arch
    )

    # 1) Preferred: runtime key 【1-dee9b5】【2-fdd9a7】
    if (Get-VcRuntimeVersion -Arch $Arch) { return $true }

    # 2) Fallback: uninstall entry display name 【3-cd83aa】【1-dee9b5】
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
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("x64","x86")]
        [string]$Arch
    )

    Write-Step "Checking VC++ 2015-2022 ($Arch)..."
    if (Test-VcRedistInstalled -Arch $Arch) {
        $ver = Get-VcRuntimeVersion -Arch $Arch
        if ($ver) {
            Write-Step "VC++ 2015-2022 ($Arch) already installed. Runtime Version: $ver"
        } else {
            Write-Step "VC++ 2015-2022 ($Arch) already installed (detected via uninstall entry)."
        }
        return
    }

    Write-Step "VC++ 2015-2022 ($Arch) not found. Installing prerequisite..."
    $vcUrl = if ($Arch -eq "x64") { $VcUrlX64 } else { $VcUrlX86 }

    Download-File -Url $vcUrl -OutFile $VcOutput

    Write-Step "Running VC++ installer silently..."
    # Silent parameters are standard for vc_redist 【4-fc8a9c】
    $p = Start-Process -FilePath $VcOutput -ArgumentList "/install /quiet /norestart" -Wait -PassThru -NoNewWindow

    # 0 = success; 3010 = success but reboot required 【4-fc8a9c】
    if ($p.ExitCode -notin 0, 3010) {
        throw "VC++ installer failed. ExitCode=$($p.ExitCode)"
    }

    if ($p.ExitCode -eq 3010) {
        Write-Step "VC++ installed successfully but reboot is required (ExitCode=3010)."
    }

    Start-Sleep -Seconds 3

    $runtimeVer = Get-VcRuntimeVersion -Arch $Arch
    if (-not $runtimeVer) {
        throw "VC++ 2015-2022 ($Arch) install completed but runtime key not detected."
    }

    Write-Step "VC++ installed and detected. Runtime Version: $runtimeVer"
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

    # Optional: On x64 OS, install x86 VC++ too (many apps are 32-bit)
    # Uncomment if you need it:
    # if ($is64) { Install-VcRedistIfMissing -Arch "x86" }

    # Install FortiClient
    Install-FortiClient

    Write-Step "DONE!"
}
catch {
    Write-Host ""
    Write-Host ("ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
    throw
}
