Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "One Tap Installer"
$form.Size = New-Object System.Drawing.Size(400,500)
$form.StartPosition = "CenterScreen"

# Function to create buttons
function New-Button($text, $y, $action) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Size = New-Object System.Drawing.Size(300,40)
    $btn.Location = New-Object System.Drawing.Point(50,$y)
    $btn.Add_Click($action)
    $form.Controls.Add($btn)
}

# Install Functions
function Install-MySQLConnector {
    Start-Process "winget" -ArgumentList "install MySQL.MySQLConnectorNet -h" -Wait
}

function Install-MySQLServer {
    Start-Process "winget" -ArgumentList "install Oracle.MySQL -h" -Wait
}

function Install-CPP {
    Start-Process "winget" -ArgumentList "install Microsoft.VCRedist.2015+.x64 -h" -Wait
}

function Install-Chrome {
    Start-Process "winget" -ArgumentList "install Google.Chrome -h" -Wait
}

function Install-Office {
    Start-Process "winget" -ArgumentList "install Microsoft.Office -h" -Wait
}

function Install-Thunderbird {
    Start-Process "winget" -ArgumentList "install Mozilla.Thunderbird -h" -Wait
}

# Buttons
New-Button "Install MySQL Connector" 30 { Install-MySQLConnector }
New-Button "Install MySQL Server" 80 { Install-MySQLServer }
New-Button "Install C++ Redistributable" 130 { Install-CPP }
New-Button "Install Google Chrome" 180 { Install-Chrome }
New-Button "Install Microsoft 365" 230 { Install-Office }
New-Button "Install Thunderbird" 280 { Install-Thunderbird }

# Reserved Buttons (for future use)
New-Button "Additional Tool 1" 340 { [System.Windows.Forms.MessageBox]::Show("Coming soon") }
New-Button "Additional Tool 2" 390 { [System.Windows.Forms.MessageBox]::Show("Coming soon") }

# Run Form
$form.Topmost = $true
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
