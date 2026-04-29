<#
Enterprise Outlook Local Data Export Script
Purpose:
 - Detect Outlook profile
 - Export Contacts
 - Export Calendar
 - Discover PST files
 - Compress output
 - Upload to central share
 - Create logs
 - Silent / zero-touch mode

Recommended Deployment:
 - Intune (Run as logged-in user)
 - SCCM
 - GPO Logon Script

IMPORTANT:
 - Run in user context (not SYSTEM) so Outlook profile is accessible
 - Outlook desktop app must be installed
#>

#region CONFIGURATION
$CentralShare = "\\FileServer01\MigrationBackup"
$LocalRoot    = "$env:ProgramData\MigrationTemp"
$DateTag      = Get-Date -Format "yyyyMMdd_HHmmss"
$UserName     = $env:USERNAME
$ComputerName = $env:COMPUTERNAME
$WorkFolder   = Join-Path $LocalRoot $UserName
$RunFolder    = Join-Path $WorkFolder $DateTag
$LogFile      = Join-Path $RunFolder "migration.log"
$ZipFile      = Join-Path $WorkFolder "$UserName-$ComputerName-$DateTag.zip"
$UploadFolder = Join-Path $CentralShare $UserName
#endregion

#region FUNCTIONS
function Write-Log {
    param([string]$Message)
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$stamp | $Message" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

function Ensure-Folder {
    param([string]$Path)
    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Release-ComObject {
    param($obj)
    try {
        if ($null -ne $obj) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($obj)
        }
    } catch {}
}

function Safe-Value {
    param($v)
    if ($null -eq $v) { return "" }
    return ($v.ToString().Replace('"','""'))
}
#endregion

#region PREP
Ensure-Folder $RunFolder
Write-Log "==== Migration Export Started ===="
Write-Log "User: $UserName"
Write-Log "Computer: $ComputerName"
#endregion

#region OUTLOOK CHECK
try {
    $Outlook = New-Object -ComObject Outlook.Application
    $Namespace = $Outlook.GetNamespace("MAPI")
    Write-Log "Outlook COM initialized successfully."
}
catch {
    Write-Log "ERROR: Outlook COM not available. $_"
    exit 1
}
#endregion

#region EXPORT CONTACTS
try {
    $ContactsFolder = $Namespace.GetDefaultFolder(10) # olFolderContacts
    $ContactsCsv = Join-Path $RunFolder "Contacts.csv"

    '"FullName","Email1","Company","Mobile","BusinessPhone"' | Out-File $ContactsCsv -Encoding utf8

    foreach ($item in $ContactsFolder.Items) {
        try {
            if ($item -and $item.Class -eq 40) { # Contact item
                $line = '"' + (Safe-Value $item.FullName) + '","' +
                              (Safe-Value $item.Email1Address) + '","' +
                              (Safe-Value $item.CompanyName) + '","' +
                              (Safe-Value $item.MobileTelephoneNumber) + '","' +
                              (Safe-Value $item.BusinessTelephoneNumber) + '"'
                Add-Content $ContactsCsv $line -Encoding utf8
            }
        } catch {}
    }

    Write-Log "Contacts exported."
}
catch {
    Write-Log "ERROR exporting Contacts: $_"
}
#endregion

#region EXPORT CALENDAR
try {
    $CalendarFolder = $Namespace.GetDefaultFolder(9) # olFolderCalendar
    $CalendarCsv = Join-Path $RunFolder "Calendar.csv"

    '"Subject","Start","End","Location","Organizer"' | Out-File $CalendarCsv -Encoding utf8

    foreach ($appt in $CalendarFolder.Items) {
        try {
            if ($appt) {
                $line = '"' + (Safe-Value $appt.Subject) + '","' +
                              (Safe-Value $appt.Start) + '","' +
                              (Safe-Value $appt.End) + '","' +
                              (Safe-Value $appt.Location) + '","' +
                              (Safe-Value $appt.Organizer) + '"'
                Add-Content $CalendarCsv $line -Encoding utf8
            }
        } catch {}
    }

    Write-Log "Calendar exported."
}
catch {
    Write-Log "ERROR exporting Calendar: $_"
}
#endregion

#region DISCOVER PST FILES
try {
    $PstReport = Join-Path $RunFolder "PST_Discovery.csv"
    '"Path","SizeMB","LastWriteTime"' | Out-File $PstReport -Encoding utf8

    $SearchPaths = @(
        "$env:USERPROFILE\Documents",
        "$env:LOCALAPPDATA\Microsoft\Outlook",
        "$env:USERPROFILE\AppData\Local\Microsoft\Outlook"
    )

    foreach ($path in $SearchPaths) {
        if (Test-Path $path) {
            Get-ChildItem -Path $path -Filter *.pst -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                $line = '"' + $_.FullName + '","' +
                              [math]::Round($_.Length/1MB,2) + '","' +
                              $_.LastWriteTime + '"'
                Add-Content $PstReport $line -Encoding utf8
            }
        }
    }

    Write-Log "PST discovery complete."
}
catch {
    Write-Log "ERROR during PST discovery: $_"
}
#endregion

#region COMPRESS
try {
    if (Test-Path $ZipFile) { Remove-Item $ZipFile -Force }
    Compress-Archive -Path "$RunFolder\*" -DestinationPath $ZipFile -Force
    Write-Log "Compressed to $ZipFile"
}
catch {
    Write-Log "ERROR compressing output: $_"
}
#endregion

#region UPLOAD
try {
    Ensure-Folder $UploadFolder
    Copy-Item $ZipFile -Destination $UploadFolder -Force
    Write-Log "Uploaded to $UploadFolder"
}
catch {
    Write-Log "ERROR uploading to share: $_"
}
#endregion

#region CLEANUP
Release-ComObject $ContactsFolder
Release-ComObject $CalendarFolder
Release-ComObject $Namespace
Release-ComObject $Outlook

Write-Log "==== Migration Export Finished ===="
#endregion
