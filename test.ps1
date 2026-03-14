Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "My Windows Tool"
$form.Size = New-Object System.Drawing.Size(400,300)

$button = New-Object System.Windows.Forms.Button
$button.Text = "Run Optimization"
$button.Size = New-Object System.Drawing.Size(150,40)
$button.Location = New-Object System.Drawing.Point(120,100)

$button.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Optimization Started!")
})

$form.Controls.Add($button)
$form.ShowDialog()
