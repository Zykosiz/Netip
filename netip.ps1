Set-ExecutionPolicy Bypass -Scope Process -Force

Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
Repair-WinGetPackageManager
Install-Module -Name PSWindowsUpdate -Force
winget install Google.Chrome --accept-source-agreements
winget install -e --id Adobe.Acrobat.Reader.64-bit --accept-source-agreements
winget install -e --id Lenovo.SystemUpdate --accept-source-agreements
$DownloadUrl = 'https://get.teamviewer.com/6nsd5xz'
$Filename = $DownloadUrl | Split-Path -Leaf
$DownloadPath = "$env:userprofile\desktop"
$WebClient = New-Object Net.WebClient
$WebClient.DownloadFile($DownloadUrl, $DownloadPath)
Import-Module -Name PSWindowsUpdate
Get-WindowsUpdate
Install-WindowsUpdate Install-WindowsUpdate
Restart-Computer -Force

#Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 
#choco feature enable -n=allowGlobalConfirmation
#choco install googlechrome --ignore-checksums
#Invoke-WebRequest "https://get.teamviewer.com/6nsd5xz" -OutFile "C:\Temp\Netip.exe"
#Move-Item -Path "C:\Temp\Netip.exe" -Destination ""$env:userprofile\desktop\netip.exe"" -Force

