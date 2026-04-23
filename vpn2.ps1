# ==============================
# FortiClient Installer + VC++ 2015-2022 Prereq (Arch-Aware)
# ==============================

$ErrorActionPreference = "Stop"

# FortiClient (your original)
$FortiUrl    = "https://github.com/arkkad3/arktool/raw/refs/heads/Utility/FortiClientVPNInstaller.exe"
$FortiOutput = Join-Path $env:TEMP "FortiClientVPNInstaller.exe"

# VC++ links (as requested)
$VcUrlX64 = "https://download.visualstudio.microsoft.com/download/pr/10912041/cee5d6bca2ddbcd039da727bf4acb48a/vcredist_x64.exe"
$VcUrlX86 = "https://download.visualstudio.microsoft.com/download/pr/10912113/5da66ddebb0ad32ebd4b922fd82e8e25/vcredist_x86.exe"
$VcOutput = Join-Path $env:TEMP "vcredist.exe"

function Write-Step($msg) {
    Write-Host ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg)
}

function Download-File {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$OutFile
    )

    # Ensure TLS 1.2 for older boxes
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

    Write-Step "Downloading: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
}

function Test-VcRedistInstalled {
    param(
        [Parameter(Mandatory=$true)][ValidateSet("x64","x86")] [string]$Arch
    )

    # Detect via Uninstall registry keys (recommended over Win32_Product) 【1-47f6da】【2-b27088】
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $pattern = "Microsoft Visual C\+\+ 2015-2022 Redistributable \($Arch\)"

    $found = Get-ItemProperty $paths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and ($_.DisplayName -like "$pattern*") } |
        Select-Object -First 1

    return [bool]$found
}

# 1) OS Architecture check
$is64 = [Environment]::Is64BitOperatingSystem
$targetArch = if ($is64) { "x64" } else { "x86" }
Write-Step "Detected OS architecture: $targetArch"

# 2) Check if VC++ 2015-2022 is installed for the detected architecture
Write-Step "Checking Microsoft Visual C++ 2015-2022 Redistributable ($targetArch)..."
$vcInstalled = Test-VcRedistInstalled -Arch $targetArch

# 3) Install VC++ if missing
if (-not $vcInstalled) {
    Write-Step "VC++ 2015-2022 ($targetArch) not found. Installing prerequisite..."

    $vcUrl = if ($is64) { $VcUrlX64 } else { $VcUrlX86 }
    Download-File -Url $vcUrl -OutFile $VcOutput

    # Silent install parameters 【3-5b22f2】
    Write-Step "Installing VC++ 2015-2022 ($targetArch)..."
    Start-Process -FilePath $VcOutput -ArgumentList "/install /quiet /norestart" -Wait -NoNewWindow

    # Re-check
    $vcInstalled = Test-VcRedistInstalled -Arch $targetArch
    if (-not $vcInstalled) {
        throw "VC++ 2015-2022 ($targetArch) install did not verify as installed."
    }

    Write-Step "VC++ prerequisite installed successfully."
} else {
    Write-Step "VC++ 2015-2022 ($targetArch) is already installed. Skipping."
}

# 4) Download and install FortiClient
Write-Step "Downloading FortiClient installer..."
Download-File -Url $FortiUrl -OutFile $FortiOutput

Write-Step "Installing FortiClient..."
Start-Process -FilePath $FortiOutput -ArgumentList "/silent" -Wait -NoNewWindow

Write-Step "Done!"
``
