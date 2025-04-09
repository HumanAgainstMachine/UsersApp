<#
.SYNOPSIS
    UsersApp installation script
.DESCRIPTION
    UsersApp is a PowerShell 7.1+ app composed by LocalUsers module and a separate GUI script.
    This script:
    - install/update PS 7.1+
    - install/update LocalUsers Module
    - install UsersApp

    This script is meant to be luanched with command: irm https://github.com/HumanAgainstMachine/LocalUsers/releases/latest/download/install-GUL.ps1 | iex
#>

# The baseurl where to download everething needed to install UsersApp
$baseUrl = "https://github.com/HumanAgainstMachine/UsersApp/releases/latest/download/"

# Create UsersApp Roaming Folder
$usersAppPath = Join-Path $env:APPDATA "UsersApp"
New-Item -ItemType Directory -Force -Path $usersAppPath | Out-Null

# Run as admin test
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "UsersApp needs to be installed as Administrator. Restarting with elevated privileges..."

    # Download and launch this script as adiministrator
    $thisScriptUrl = $baseUrl + "install-usersapp.ps1"
    $thisScriptPath = Join-Path $usersAppPath "install-usersapp.ps1"

    try {
        Invoke-WebRequest -Uri $thisScriptUrl -OutFile $thisScriptPath
        Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$thisScriptPath`"" -Verb RunAs
        Write-Host "`nRelaunch success" -ForegroundColor Green
    }
    catch {
        Write-Warning "`nRelaunch failed. Try again"
    }
    finally {
        Write-Host "`nPress any key to close..."
        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null        
        exit
    }
}

# install/update PS7.1+
$installedVersion = $PSVersionTable.PSVersion.ToString()

$releasesUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
try {
    $response = Invoke-RestMethod -Uri $releasesUrl -UseBasicParsing
    $latestVersion = $response.tag_name.TrimStart("v")
} catch {
    Write-Error "Failed to check latest version from GitHub."
}

Write-Host "Installed version: $installedVersion"
Write-Host "Latest version: $latestVersion"

# Compare versions and install if needed
if ($installedVersion -ne $latestVersion) {
    Write-Host "Updating PowerShell to version $latestVersion..."

    $scriptPath = "$env:TEMP\install-powershell.ps1"
    Invoke-WebRequest -Uri "https://aka.ms/install-powershell.ps1" -OutFile $scriptPath

    # Run system-wide silent install using MSI
    & $scriptPath -UseMSI -Quiet
    Write-Host "PowerShell $latestVersion installed successfully."
} else {
    Write-Host "PowerShell is already up to date."
}

# Path for PowerShell 7
$ps7Path = "C:\Program Files\PowerShell\7\pwsh.exe"

# Install/Update LocalUsers module
if ($lUsers = Get-Module -ListAvailable -Name LocalUsers) {
    Write-Host "LocalUsers module is already installed. Checking for updates..." -ForegroundColor Green
    
    $currentModule = $lUsers | Sort-Object Version -Descending | Select-Object -First 1
    $onlineModule = Find-Module -Name LocalUsers -Repository PSGallery
    
    if ($onlineModule.Version -gt $currentModule.Version) {
        Write-Host "Updating LocalUsers module from version $($currentModule.Version) to $($onlineModule.Version)..." -ForegroundColor Yellow
        Update-Module -Name LocalUsers -Force
        Write-Host "LocalUsers module has been updated to version $($onlineModule.Version)." -ForegroundColor Green
    } else {
        Write-Host "LocalUsers module is already at the latest version ($($currentModule.Version))." -ForegroundColor Green
    }
} else {
    Write-Host "Installing LocalUsers module from PSGallery..." -ForegroundColor Yellow
    Install-Module -Name LocalUsers -Repository PSGallery -Force -Scope AllUsers
    
    if ($lUsers = Get-Module -ListAvailable -Name LocalUsers) {
        $installedModule = $lUsers | Sort-Object Version -Descending | Select-Object -First 1
        Write-Host "LocalUsers module has been successfully installed (Version: $($installedModule.Version))." -ForegroundColor Green
    } else {
        Write-Host "Failed to install LocalUsers module. Please install manually." -ForegroundColor Red
    }
}

$usersAppUrl = $baseUrl + "UsersApp.ps1"

# Create a script that the shortcut links to in order to prevent the shortcut from being flagged as a virus.
$usersAppLaunchScript = @"
Start-Process pwsh.exe -Verb RunAs -ArgumentList '-Command "irm $usersAppUrl | iex"'
"@

$usersAppLaunchScriptPath = Join-Path $usersAppPath "LaunchUsersApp.ps1"
Set-Content -Path $usersAppLaunchScriptPath -Value $usersAppLaunchScript


# Download icon
$iconUrl = $baseUrl + "UsersApp.ico"
$iconPath = Join-Path $usersAppPath "UsersApp.ico"

try {
    Invoke-WebRequest -Uri $iconUrl -OutFile $iconPath
    Write-Host "Icon downloaded successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to download icon." -ForegroundColor Red
    $iconPath = "$ps7Path,0"  # Fallback to PowerShell icon
}

# Create desktop shortcut for UsersApp
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "UsersApp.lnk"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $ps7Path
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$usersAppLaunchScriptPath`""
$Shortcut.IconLocation = $iconPath
$Shortcut.Description = "Launch UsersApp"
$Shortcut.Save()

# Add "Run as administrator" to the shortcut
$bytes = [System.IO.File]::ReadAllBytes($shortcutPath)
$bytes[0x15] = $bytes[0x15] -bor 0x20
[System.IO.File]::WriteAllBytes($shortcutPath, $bytes)

Write-Host "Installation completed successfully!" -ForegroundColor Green

# Pause before closing
Write-Host "`nPress any key to close..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null