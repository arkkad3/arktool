# ==============================
# FortiClient Installer + VC++ 2015-2022 Prereq (Arch-Aware)
# ==============================

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg)
}

function Download-File {
    param([string]$Url, [string]$OutFile)
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
    Write-Step "Downloading: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
}

function Get-VcRuntimeVersion {
    param([ValidateSet("x64","x86")]$Arch)

    # Preferred runtime detection key for VC++ 2015-2022 【1-fbfa44】【2-be5c98】
    $key = "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\$Arch"
    try {
        $p = Get-ItemProperty -Path $key -ErrorAction Stop
        # 'Installed' is typically 1 when present; 'Version' holds runtime version
        if ($p.Installed -eq 1 -and $p.Version) {
            return [string]$p.Version
        }
    } catch { }
    return $null
}

function Test-VcRedistInstalled {
    param([ValidateSet("x64","x86")]$Arch)

    # 1) Runtime key check (fast + reliable) 【1-fbfa44】【2-be5c98】
    $ver = Get-VcRuntimeVersion -Arch $Arch
    if ($ver) { return $true }

    # 2) Fallback: Uninstall DisplayName check (sometimes delayed) 【1-fbfa44】【3-891a39】
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

# ---- Your URLs (as requested) ----
$VcUrlX64 = "https://download.visualstudio.microsoft.com/download/pr/10912041/cee5d6bca2ddbcd039da727bf4acb48a/vcredist_x64.exe"
$VcUrlX86 = "https://download.visualstudio.microsoft.com/download/pr/10912113/5da66ddebb0ad32ebd4b922fd82e8e25/vcredist_x86.exe"
$VcOutput = Join-Path $env:TEMP "vcredist.exe"

# OS architecture
$is64 = [Environment]::Is64BitOperatingSystem
$targetArch = if ($is64) { "x64" } else { "x86" }
Write-Step "Detected OS architecture: $targetArch"

Write-Step "Checking Microsoft Visual C++ 2015-2022 Redistributable ($targetArch)..."
if (-not (Test-VcRedistInstalled -Arch $targetArch)) {

    Write-Step "VC++ 2015-2022 ($targetArch) not found. Installing prerequisite..."
    $vcUrl = if ($is64) { $VcUrlX64 } else { $VcUrlX86 }
    Download-File -Url $vcUrl -OutFile $VcOutput

    Write-Step "Installing VC++ 2015-2022 ($targetArch)..."
    $p = Start-Process -FilePath $VcOutput -ArgumentList "/install /quiet /norestart" -Wait -PassThru -NoNewWindow

    # VC++ installer commonly uses these success codes; /quiet /norestart parameters are standard ExitCode -notin 0, 3010) {
        throw "VC++ installer failed. ExitCode=$($p.ExitCode)"
    }

    if ($p.ExitCode -eq 3010) {
        Write-Step "VC++ installed successfully, but a reboot is required (ExitCode=3010)."
    }

    # Give registry a moment to update (some environments delay writes)
    Start-Sleep -Seconds 3

    $runtimeVer = Get-VcRuntimeVersion -Arch $targetArch
    if (-not $runtimeVer) {
        throw "VC++ 2015-2022 ($targetArch) install completed but runtime key not detected."
    }

    Write-Step "VC++ prerequisite detected. Runtime Version: $runtimeVer"
} else {
    $runtimeVer = Get-VcRuntimeVersion -Arch $targetArch
    if ($runtimeVer) {
        Write-Step "VC++ 2015-2022 ($targetArch) already installed. Runtime Version: $runtimeVer"
    } else {
        Write-Step "VC++ 2015-2022 ($targetArch) already installed (detected via uninstall entry)."
    }
}
