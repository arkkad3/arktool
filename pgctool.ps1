Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==== GLOBALS ====
$logFile = "$env:USERPROFILE\installer_log.txt"
$presetFile = "$env:USERPROFILE\installer_preset.json"

# ==== LOGGING ====
function Write-Log($msg) {
    $time = Get-Date -Format "HH:mm:ss"
    $entry = "[$time] $msg"
    $entry | Out-File -Append -FilePath $logFile
    if ($logBox) {
        $logBox.Invoke([action]{ $logBox.AppendText("$entry`r`n") })
    }
}

# ==== ASYNC RUN ====
function Run-Async($scriptBlock) {
    Start-Job -ScriptBlock $scriptBlock | Out-Null
}

# ==== INSTALL ====
function Install-App($id, $name) {
    Write-Log "Installing $name..."
    try {
        Start-Process "winget" -ArgumentList "install --id=$id -e -h" -Wait
        Write-Log "$name installed"
    } catch {
        Write-Log "$name failed"
    }
}

# ==== DEBLOAT ====
function Debloat-Windows {
    Write-Log "Debloating Windows..."
    Get-AppxPackage *xbox* | Remove-AppxPackage
    Get-AppxPackage *bing* | Remove-AppxPackage
    Write-Log "Debloat complete"
}

# ==== PRESET SAVE/LOAD ====
function Save-Preset {
    $data = @{
        Chrome = $cbChrome.Checked
        Office = $cbOffice.Checked
        Thunderbird = $cbThunder.Checked
        CPP = $cbCPP.Checked
        MySQL = $cbMySQL.Checked
    } | ConvertTo-Json

    $data | Out-File $presetFile
    Write-Log "Preset saved"
}

function Load-Preset {
    if (Test-Path $presetFile) {
        $data = Get-Content $presetFile | ConvertFrom-Json
        $cbChrome.Checked = $data.Chrome
        $cbOffice.Checked = $data.Office
        $cbThunder.Checked = $data.Thunderbird
        $cbCPP.Checked = $data.CPP
        $cbMySQL.Checked = $data.MySQL
        Write-Log "Preset loaded"
    }
}

# ==== UI ====
$form = New-Object System.Windows.Forms.Form
$form.Text = "One Tap Pro ELITE"
$form.Size = New-Object System.Drawing.Size(520,620)
$form.BackColor = "#1e1e1e"

# Tabs
$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Size = New-Object System.Drawing.Size(480,460)
$tabs.Location = New-Object System.Drawing.Point(10,10)

# Helper checkbox
function New-Checkbox($text,$y,$parent){
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $text
    $cb.ForeColor = "White"
    $cb.Location = New-Object System.Drawing.Point(20,$y)
    $parent.Controls.Add($cb)
    return $cb
}

# ==== INSTALL TAB ====
$tabInstall = New-Object System.Windows.Forms.TabPage
$tabInstall.Text = "Install"
$tabInstall.BackColor = "#2d2d30"

$cbChrome  = New-Checkbox "Google Chrome" 20 $tabInstall
$cbOffice  = New-Checkbox "Microsoft 365" 50 $tabInstall
$cbThunder = New-Checkbox "Thunderbird" 80 $tabInstall
$cbCPP     = New-Checkbox "C++ Redistributable" 110 $tabInstall
$cbMySQL   = New-Checkbox "MySQL Server" 140 $tabInstall

# ==== DEBLOAT TAB ====
$tabDebloat = New-Object System.Windows.Forms.TabPage
$tabDebloat.Text = "Debloat"
$tabDebloat.BackColor = "#2d2d30"

$btnDebloat = New-Object System.Windows.Forms.Button
$btnDebloat.Text = "Run Debloat"
$btnDebloat.Location = New-Object System.Drawing.Point(20,20)
$btnDebloat.Add_Click({
    Run-Async { Debloat-Windows }
})
$tabDebloat.Controls.Add($btnDebloat)

# ==== LOG TAB ====
$tabLogs = New-Object System.Windows.Forms.TabPage
$tabLogs.Text = "Logs"
$tabLogs.BackColor = "#2d2d30"

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.Size = New-Object System.Drawing.Size(440,360)
$logBox.BackColor = "Black"
$logBox.ForeColor = "Lime"
$logBox.Location = New-Object System.Drawing.Point(10,10)
$tabLogs.Controls.Add($logBox)

# ==== PRESET TAB ====
$tabPreset = New-Object System.Windows.Forms.TabPage
$tabPreset.Text = "Presets"
$tabPreset.BackColor = "#2d2d30"

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "Save Preset"
$btnSave.Location = New-Object System.Drawing.Point(20,20)
$btnSave.Add_Click({ Save-Preset })

$btnLoad = New-Object System.Windows.Forms.Button
$btnLoad.Text = "Load Preset"
$btnLoad.Location = New-Object System.Drawing.Point(150,20)
$btnLoad.Add_Click({ Load-Preset })

$tabPreset.Controls.Add($btnSave)
$tabPreset.Controls.Add($btnLoad)

# Add tabs
$tabs.TabPages.AddRange(@($tabInstall,$tabDebloat,$tabLogs,$tabPreset))
$form.Controls.Add($tabs)

# ==== PROGRESS ====
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Size = New-Object System.Drawing.Size(460,20)
$progress.Location = New-Object System.Drawing.Point(20,480)

$form.Controls.Add($progress)

# ==== RUN BUTTON ====
$runBtn = New-Object System.Windows.Forms.Button
$runBtn.Text = "Run Selected"
$runBtn.Size = New-Object System.Drawing.Size(200,40)
$runBtn.Location = New-Object System.Drawing.Point(150,510)

$runBtn.Add_Click({
    $tasks = @()

    if ($cbChrome.Checked) { $tasks += { Install-App "Google.Chrome" "Chrome" } }
    if ($cbOffice.Checked) { $tasks += { Install-App "Microsoft.Office" "Office" } }
    if ($cbThunder.Checked){ $tasks += { Install-App "Mozilla.Thunderbird" "Thunderbird" } }
    if ($cbCPP.Checked)    { $tasks += { Install-App "Microsoft.VCRedist.2015+.x64" "CPP" } }
    if ($cbMySQL.Checked)  { $tasks += { Install-App "Oracle.MySQL" "MySQL" } }

    $total = $tasks.Count
    $i = 0

    foreach ($task in $tasks) {
        $i++
        Write-Log "Running task $i of $total"
        Run-Async $task
        $progress.Value = [int](($i/$total)*100)
        Start-Sleep -Seconds 1
    }

    Write-Log "All tasks queued"
})

$form.Controls.Add($runBtn)

$form.Topmost = $true
[void]$form.ShowDialog()
