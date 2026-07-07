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
    # -NoExit keeps the elevated window open after the script finishes
    Start-Process powershell.exe -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

Write-Host "Running with admin privileges." -ForegroundColor Green

# Summary tracker
$summary = [ordered]@{
    "ESET"           = "Not checked"
    "Heimdal"        = "Not checked"
    "Admin Enabled"  = "Not checked"
    "Admin Password" = "Not checked"
}

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
        return "Not installed"
    }

    $results = @()

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
            $results += "$($app.DisplayName): Uninstall command executed"
        }
        catch {
            Write-Host "Failed to uninstall $($app.DisplayName): $_" -ForegroundColor Red
            $results += "$($app.DisplayName): FAILED - $_"
        }
    }

    return ($results -join "; ")
}

# ------------------------------------------------------------------
# 1. ESET
# ------------------------------------------------------------------
$summary["ESET"] = Uninstall-ByDisplayNameMatch -Pattern "ESET" -FriendlyName "ESET Antivirus"

# ------------------------------------------------------------------
# 2. Heimdal
# ------------------------------------------------------------------
$summary["Heimdal"] = Uninstall-ByDisplayNameMatch -Pattern "Heimdal" -FriendlyName "Heimdal Antivirus"

# ------------------------------------------------------------------
# 3. Enable local Administrator account if disabled
# ------------------------------------------------------------------
try {
    # Find the built-in Administrator account by SID suffix -500
    # (locale-safe: the account name itself can be translated on non-English Windows)
    $adminAccount = Get-LocalUser -ErrorAction Stop | Where-Object { $_.SID -like "*-500" }

    if (-not $adminAccount) {
        throw "Could not find an account with RID 500 (built-in Administrator)."
    }

    $realAdminName = $adminAccount.Name
    Write-Host "Built-in Administrator account found: '$realAdminName' (SID: $($adminAccount.SID))" -ForegroundColor Cyan

    if (-not $adminAccount.Enabled) {
        Write-Host "Account is disabled. Enabling..." -ForegroundColor Cyan
        Enable-LocalUser -Name $realAdminName
        # Re-check to confirm it actually took (e.g. GPO could re-disable it)
        Start-Sleep -Milliseconds 500
        $recheck = Get-LocalUser -Name $realAdminName
        if ($recheck.Enabled) {
            Write-Host "Confirmed: account is now enabled." -ForegroundColor Green
            $summary["Admin Enabled"] = "Was disabled - now Enabled ('$realAdminName')"
        } else {
            Write-Host "WARNING: Enable-LocalUser ran but account still shows Disabled. A GPO/local security policy may be re-disabling it." -ForegroundColor Red
            $summary["Admin Enabled"] = "FAILED - still disabled after Enable-LocalUser (check GPO 'Accounts: Administrator account status')"
        }
    } else {
        Write-Host "Account is already enabled." -ForegroundColor Green
        $summary["Admin Enabled"] = "Already enabled ('$realAdminName')"
    }
}
catch {
    Write-Host "Could not query/enable built-in Administrator account: $_" -ForegroundColor Red
    $summary["Admin Enabled"] = "FAILED - $_"
    $realAdminName = "Administrator"  # fallback for password step
}

# ------------------------------------------------------------------
# 4. Set local Administrator password
# ------------------------------------------------------------------
try {
    $securePassword = ConvertTo-SecureString "1234" -AsPlainText -Force
    Set-LocalUser -Name $realAdminName -Password $securePassword
    Write-Host "Password updated for '$realAdminName'." -ForegroundColor Green
    $summary["Admin Password"] = "Set to 1234 ('$realAdminName')"
}
catch {
    Write-Host "Failed to set Administrator password: $_" -ForegroundColor Red
    $summary["Admin Password"] = "FAILED - $_"
}

# ------------------------------------------------------------------
# Final summary
# ------------------------------------------------------------------
Write-Host "`n========== SUMMARY ==========" -ForegroundColor Magenta
foreach ($key in $summary.Keys) {
    Write-Host ("{0,-16}: {1}" -f $key, $summary[$key])
}
Write-Host "==============================" -ForegroundColor Magenta

Write-Host "`nScript complete. Press Enter to close..." -ForegroundColor Green
Read-Host | Out-Null
