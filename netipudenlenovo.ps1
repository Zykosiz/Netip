Set-ExecutionPolicy Bypass -Scope Process -Force
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 
choco feature enable -n=allowGlobalConfirmation
choco install googlechrome --ignore-checksums
#choco install lenovo-thinkvantage-system-update --ignore-checksums
choco install adobereader --ignore-checksums
# Set temp
$path = "c:\temp\"

# Check if folder not exists, and create it
if (-not(Test-Path $path -PathType Container)) {
    New-Item -path $path -ItemType Directory
}
# URL and Destination
$url = "https://get.teamviewer.com/6nsd5xz"
$dest = "C:\Temp\Netip.exe"
# Download file
Start-BitsTransfer -Source $url -Destination $dest 
Start-Sleep -Seconds 3

Import-Module -Name PSWindowsUpdate
Get-WindowsUpdate
Start-Sleep -Seconds 30
Install-WindowsUpdate -AcceptAll
Start-Sleep -Seconds 5
Restart-Computer -Force

#Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 
#choco feature enable -n=allowGlobalConfirmation
#choco install googlechrome --ignore-checksums
#Invoke-WebRequest "https://get.teamviewer.com/6nsd5xz" -OutFile "C:\Temp\Netip.exe"
#Move-Item -Path "C:\Temp\Netip.exe" -Destination ""$env:userprofile\desktop\netip.exe"" -Force


#Install-PackageProvider -Name NuGet -Force | Out-Null
#Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
#Repair-WinGetPackageManager
#Install-Module -Name PSWindowsUpdate -Force
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
