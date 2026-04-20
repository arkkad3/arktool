<#
.NOTES
Template derived from the structure/patterns in winutil.ps1 (WinUtil)
Keeps the same UI lifecycle: XAML -> $sync binding -> config-driven UI -> event handlers -> ShowDialog
#>  # 【1-cfc562】【2-57bff3】

param(
  [string]$Config,
  [switch]$Run,
  [switch]$Noui,
  [switch]$Offline
)

#region --- Parameters (same intent/shape) ---
if ($Config) { $PARAM_CONFIG = $Config }
$PARAM_RUN = $false
if ($Run) { $PARAM_RUN = $true }

$PARAM_NOUI = $false
if ($Noui) { $PARAM_NOUI = $true }

$PARAM_OFFLINE = $false
if ($Offline) { $PARAM_OFFLINE = $true }
#endregion  # 【1-cfc562】【2-57bff3】

#region --- Admin check (keep consistent behavior) ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Output "This tool needs to be run as Administrator."
  exit 1
}
#endregion  # 【1-cfc562】【2-57bff3】

#region --- Assemblies (WPF + WinForms) ---
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
#endregion  # 【1-cfc562】【2-57bff3】

#region --- Shared sync state (same pattern) ---
$sync = [Hashtable]::Synchronized(@{})
$sync.version = "TEMPLATE-1.0"
$sync.ProcessRunning = $false

# selections like the original
$sync.selectedApps     = [System.Collections.Generic.List[string]]::new()
$sync.selectedTweaks   = [System.Collections.Generic.List[string]]::new()
$sync.selectedToggles  = [System.Collections.Generic.List[string]]::new()
$sync.selectedFeatures = [System.Collections.Generic.List[string]]::new()

$sync.currentTab = "Install"
$sync.configs = @{}
#endregion  # 【1-cfc562】【2-57bff3】

#region --- Config placeholders (keep schema; swap in your full JSON if desired) ---
# Option A: keep as PSObjects/Hashtables
$sync.configs.appnavigation = @{
  # keys should match your XAML button names for Invoke-WPFButton routing
  "WPFInstall" = @{
    Content="Install/Upgrade Applications"; Category="____Actions"; Type="Button"; Order="1"
    Description="Install or upgrade selected applications"
  }
  "WPFUninstall" = @{
    Content="Uninstall Applications"; Category="____Actions"; Type="Button"; Order="2"
    Description="Uninstall selected applications"
  }
}

$sync.configs.applications = @{
  # minimal example; add more entries using same shape as winutil
  "WPFInstall7zip" = @{
    category="Utilities"; choco="7zip"; content="7-Zip"; description="Sample app entry"
    link="https://www.7-zip.org/"; winget="7zip.7zip"; foss=$true
  }
}

$sync.configs.tweaks = @{
  "WPFTweaksExample" = @{
    Content="Example Tweak"; Description="Template tweak example"
    category="Essential Tweaks"; panel="1"
    registry=@(
      @{ Path="HKCU:\Software\MyCompany\Example"; Name="Enabled"; Value="0"; Type="DWord"; OriginalValue="" }
    )
  }
}

$sync.configs.feature = @{
  "WPFFeatureExample" = @{
    Content="Example Feature"; Description="Template feature example"
    category="Features"; panel="1"; feature=@("NetFx3"); InvokeScript=@(); link=""
  }
}

$sync.configs.themes = @{
  shared = @{
    FontFamily="Arial"; FontSize="12"
    HeaderFontFamily="Consolas, Monaco"; HeaderFontSize="16"
  }
  Light = @{
    MainBackgroundColor="#F7F7F7"; MainForegroundColor="#232629"
  }
  Dark  = @{
    MainBackgroundColor="#232629"; MainForegroundColor="#F7F7F7"
  }
}
#endregion  # 【1-cfc562】【2-57bff3】

#region --- REQUIRED: Your existing XAML (UI remains) ---
# IMPORTANT:
# 1) Paste your existing $inputXML content here (from your working winutil)
# 2) Do not change Name="..." of controls used in code (SearchBar, ThemeButton, etc.)
# 3) Keep the same layout/UI so it looks identical
$inputXML = @'
<!-- PASTE YOUR EXISTING XAML HERE (UNCHANGED UI) -->
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinUtil Template" Height="700" Width="1100">
  <Grid>
    <TextBlock Text="Replace this XAML with your existing WinUtil UI (unchanged)." 
               VerticalAlignment="Center" HorizontalAlignment="Center"/>
  </Grid>
</Window>
'@
#endregion  # 【1-cfc562】【2-57bff3】

#region --- Helpers (XAML load + named element binding) ---
function Import-WpfWindow {
  param([Parameter(Mandatory)][string]$Xaml)

  $Xaml = $Xaml -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
  [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
  [xml]$xml = $Xaml
  $reader = New-Object System.Xml.XmlNodeReader $xml
  return [Windows.Markup.XamlReader]::Load($reader)
}  # 【1-cfc562】【2-57bff3】

function Bind-WpfNamedElements {
  param([Parameter(Mandatory)]$Form, [Parameter(Mandatory)][string]$Xaml)
  [xml]$xml = $Xaml
  $xml.SelectNodes("//*[@Name]") | ForEach-Object {
    $name = $_.Name
    $sync[$name] = $Form.FindName($name)
  }
}  # 【1-cfc562】【2-57bff3】
#endregion

#region --- UI builders (stubs; keep UI logic pattern) ---
function Initialize-WPFUI {
  [OutputType([void])]
  param([Parameter(Mandatory)][string]$TargetGridName)
  # Stub: keep same signature so your old calls still work
  # In your full version, this initializes visual containers or virtualization, etc. 【1-cfc562】【2-57bff3】
}

function Invoke-WPFUIElements {
  param(
    [Parameter(Mandatory)]$configVariable,
    [Parameter(Mandatory)][string]$targetGridName,
    [int]$columncount = 1
  )

  # Template stub:
  # - In your full winutil, this creates controls based on configVariable entries and adds them to target grid.
  # - Here we keep the hook so UI remains driven by config.
  # TODO: paste your actual Invoke-WPFUIElements implementation here to fully preserve behavior. 【1-cfc562】【2-57bff3】
}
#endregion

#region --- Search helpers (stubs matching original intent) ---
function Find-AppsByNameOrDescription {
  param([string]$SearchString)
  # Template stub: in full script, hide app entries not matching SearchString 【1-cfc562】【2-57bff3】
}

function Find-TweaksByNameOrDescription {
  param([string]$SearchString)
  # Template stub: in full script, hide tweak entries not matching SearchString 【1-cfc562】【2-57bff3】
}
#endregion

#region --- Theme / Popup hooks (stubs) ---
function Invoke-WPFPopup {
  param(
    [hashtable]$PopupActionTable,
    [ValidateSet("Show","Hide","Toggle")][string]$Action,
    [string[]]$Popups
  )
  # Template stub: keep signature; wire your existing popup logic here 【1-cfc562】【2-57bff3】
}

function Invoke-WinutilThemeChange {
  param([ValidateSet("Auto","Dark","Light")][string]$theme)
  # Template stub: in your full script, apply theme values to UI using $sync.configs.themes 【1-cfc562】【2-57bff3】
}
#endregion

#region --- Button router (keep same pattern) ---
function Invoke-WPFButton {
  param([string]$Name)
  switch ($Name) {
    "WPFInstall"   { Invoke-ActionInstall }
    "WPFUninstall" { Invoke-ActionUninstall }
    default { Write-Debug "No handler for button: $Name" }
  }
}  # 【1-cfc562】【2-57bff3】
#endregion

#region --- Actions (safe placeholders) ---
function Invoke-ActionInstall {
  if ($sync.ProcessRunning) { return }
  $sync.ProcessRunning = $true
  try {
    # TODO: plug in your install logic (winget/choco) here
    Write-Host "INSTALL action triggered (template). Selected apps: $($sync.selectedApps.Count)"
  } finally {
    $sync.ProcessRunning = $false
  }
}

function Invoke-ActionUninstall {
  if ($sync.ProcessRunning) { return }
  $sync.ProcessRunning = $true
  try {
    # TODO: plug in uninstall logic here
    Write-Host "UNINSTALL action triggered (template). Selected apps: $($sync.selectedApps.Count)"
  } finally {
    $sync.ProcessRunning = $false
  }
}
#endregion

#region --- Main execution ---
if ($PARAM_NOUI) {
  Write-Host "No-UI mode enabled."
  if ($PARAM_CONFIG -and $PARAM_RUN) {
    Write-Host "Template: would run config-driven tasks here."
  }
  exit 0
}  # 【1-cfc562】【2-57bff3】

# Load XAML -> Form
$sync.Form = Import-WpfWindow -Xaml $inputXML
Bind-WpfNamedElements -Form $sync.Form -Xaml $inputXML

# Apply theme at startup (same idea)
Invoke-WinutilThemeChange -theme "Auto"  # or $sync.preferences.theme in full script 【1-cfc562】【2-57bff3】

# Build panels (keep the call sites, UI remains config-driven)
Invoke-WPFUIElements -configVariable $sync.configs.appnavigation -targetGridName "appscategory" -columncount 1
Initialize-WPFUI -TargetGridName "appscategory"
Initialize-WPFUI -TargetGridName "appspanel"
Invoke-WPFUIElements -configVariable $sync.configs.tweaks  -targetGridName "tweakspanel"   -columncount 2
Invoke-WPFUIElements -configVariable $sync.configs.feature -targetGridName "featurespanel" -columncount 2  # 【1-cfc562】【2-57bff3】

# Wire common click handlers if those controls exist in your XAML
if ($sync.ThemeButton) {
  $sync.ThemeButton.Add_Click({
    Invoke-WPFPopup -PopupActionTable @{ "Settings"="Hide"; "Theme"="Toggle"; "FontScaling"="Hide" }
  })
}  # 【1-cfc562】【2-57bff3】

# Search debounce behavior (same idea as original)
if ($sync.SearchBar) {
  $searchBarTimer = New-Object System.Windows.Threading.DispatcherTimer
  $searchBarTimer.Interval = [TimeSpan]::FromMilliseconds(300)
  $searchBarTimer.IsEnabled = $false

  $searchBarTimer.add_Tick({
    $searchBarTimer.Stop()
    switch ($sync.currentTab) {
      "Install" { Find-AppsByNameOrDescription   -SearchString $sync.SearchBar.Text }
      "Tweaks"  { Find-TweaksByNameOrDescription -SearchString $sync.SearchBar.Text }
    }
  })  # 【1-cfc562】【2-57bff3】

  $sync.SearchBar.Add_TextChanged({
    if ($searchBarTimer.IsEnabled) { $searchBarTimer.Stop() }
    $searchBarTimer.Start()
  })  # 【1-cfc562】【2-57bff3】
}

# Generic hook: bind all toggle buttons by name to Invoke-WPFButton (same pattern concept)
foreach ($k in @($sync.Keys)) {
  if ($sync[$k] -and $sync[$k].GetType().Name -eq "ToggleButton") {
    $sync[$k].Add_Click({
      $sender = $args[0]
      Invoke-WPFButton $sender.Name
    })
  }
}  # 【1-cfc562】【2-57bff3】

# Show UI
$sync.Form.ShowDialog() | Out-Null
#endregion
``
