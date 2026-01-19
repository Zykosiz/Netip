# Choco Install Chrome and Adobe Reader
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 
choco feature enable -n=allowGlobalConfirmation
choco install googlechrome --ignore-checksums
choco install adobereader --ignore-checksums

# Set temp for folder check
$path = "c:\temp\"

# Check if folder not exists, and create it
if (-not(Test-Path $path -PathType Container)) {
    New-Item -path $path -ItemType Directory
}
# Download file
$ProgressPreference = 'SilentlyContinue'
curl "https://customdesignservice.teamviewer.com/download/windows/v15/6kyy3pe/TeamViewerQS.exe?sv=2023-11-03&se=2026-01-20T07%3A48%3A01Z&sr=b&sp=r&sig=2yy7%2BQsHlwYPf%2FiAl5TGY5JPIqwS3BptGL4lVBivba4%3D&1768808882084" -OutFile "C:\temp\netip.exe"
Start-Sleep -Seconds 5
# Move to current Desktop
Move-Item -Path "C:\Temp\Netip.exe" -Destination "$env:userprofile\Desktop\Netip Support.exe"
$ProgressPreference = 'Continue'
Start-Sleep -Seconds 5
# Check if Lenovo PC and install updates 
$manufacturer = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property Manufacturer
If ($manufacturer -like '*Lenovo*') {
choco install lenovo-thinkvantage-system-update --ignore-checksums
Install-Module -Name LSUClient  -Force
Import-Module -Name LSUClient
$updates = Get-LSUpdate | Where-Object { $_.Installer.Unattended }
$updates | Save-LSUpdate -Verbose
$updates | Install-LSUpdate -Verbose
} Else {
    Write-Host "This is not a Lenovo PC"
    Start-Sleep -Seconds 20
}
# Choco disable Globalallow
choco feature disable -n=allowGlobalConfirmation
#Error hide
$ErrorActionPreference= 'silentlycontinue'
# UNPIN ALL TASKBAR ICONS
# Remove Widgets
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\" -Name "AllowNewsAndInterests" -Value "0"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh\" -Name "AllowNewsAndInterests" -Value "0"

New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\" -Name "AllowNewsAndInterests" -Value "0"
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh\" -Name "AllowNewsAndInterests" -Value "0"


# Remove all files inside the Taskbar APPDATA folder
  Remove-Item -Path "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*" -Force -Recurse -ErrorAction SilentlyContinue

# Remove the Taskband Registry Key to delete taskbar data for recent apps.
  Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Force -Recurse -ErrorAction SilentlyContinue

#Start-Stop the File Explorer to refresh the taskbar.
  Stop-Process -ProcessName explorer -Force
  Start-Process explorer
<##Windows Update
Install-PackageProvider NuGet -Force
#Set-PackageSource -Name 'NuGet' -Trusted
Install-Module -Name PSWindowsUpdate -Force
Import-Module -Name PSWindowsUpdate
Get-WindowsUpdate
Start-Sleep -Seconds 30
Install-WindowsUpdate -AcceptAll -AutoReboot
Start-Sleep -Seconds 5#>
#Restart-Computer -Force


#Install-PackageProvider -Name NuGet -Force | Out-Null
#Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
#Repair-WinGetPackageManager

#winget source reset --force
#winget settings --enable InstallerHashOverride
#winget install Google.Chrome --accept-source-agreements --ignore-security-hash
#winget install -e --id Adobe.Acrobat.Reader.64-bit --accept-source-agreements
#winget install -e --id Lenovo.SystemUpdate --accept-source-agreements


#Install-Module -Name LSUClient
#Import-Module -Name LSUClient
#$updates = Get-LSUpdate | Where-Object { $_.Installer.Unattended }
#$updates | Save-LSUpdate -Verbose
#$updates | Install-LSUpdate -Verbose
#Start-Sleep -Seconds 15
