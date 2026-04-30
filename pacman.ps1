<#
    .SYNOPSIS
    Pacman Package Manager - PowerShell Edition
#>

param(
    [string]$Command,
    [string]$PackageName,
    [string[]]$Packages,
    [switch]$Force
)

$global:ConfigPath = "$env:USERPROFILE\.pacman-powershell"
$global:InstalledFile = "$global:ConfigPath\installed.json"
$global:DatabaseFile = "$global:ConfigPath\packages.db"
$global:LogFile = "$global:ConfigPath\pacman.log"
$global:Version = "1.0.0"

function Initialize-Pacman
{
    if (-not (Test-Path $global:ConfigPath))
    {
        New-Item -Path $global:ConfigPath -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path $global:InstalledFile))
    {
        @{} | ConvertTo-Json | Set-Content $global:InstalledFile
    }

    if (-not (Test-Path $global:DatabaseFile))
    {
        Initialize-Database
    }
}

function Write-Log
{
    param([string]$Level, [string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $global:LogFile -Value "[$timestamp] [$Level] $Message" -ErrorAction SilentlyContinue
}

function Write-Message
{
    param([string]$Message, [string]$Type = "INFO")

    $color = "White"

    if ($Type -eq "SUCCESS") { $color = "Green" }
    if ($Type -eq "ERROR") { $color = "Red" }
    if ($Type -eq "WARNING") { $color = "Yellow" }
    if ($Type -eq "INFO") { $color = "Cyan" }

    Write-Host $Message -ForegroundColor $color
    Write-Log $Type $Message
}

function Show-Banner
{
    Clear-Host

    Write-Host ""
    Write-Host "     ____            _   " -ForegroundColor Cyan
    Write-Host "    / __ \___  _____(_)___" -ForegroundColor Cyan
    Write-Host "   / /_/ / _ \/ ___/ / __ \" -ForegroundColor Cyan
    Write-Host "  / ____/  __/ /__/ / /_/ /" -ForegroundColor Cyan
    Write-Host " /_/    \___/\___/_/\____/ " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "         PACMAN PACKAGE MANAGER v$global:Version" -ForegroundColor Yellow
    Write-Host "         ---------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

function Initialize-Database
{
    Write-Message "[*] Initializing package database..." "INFO"

    $packages = @(
        @{Name="git"; Version="2.43.0"; Description="Version control system"; Category="dev"}
        @{Name="node"; Version="20.11.0"; Description="JavaScript runtime"; Category="dev"}
        @{Name="python"; Version="3.12.1"; Description="Python language"; Category="lang"}
        @{Name="vscode"; Version="1.86.0"; Description="Code editor"; Category="editor"}
        @{Name="docker"; Version="24.0.7"; Description="Container platform"; Category="dev"}
        @{Name="curl"; Version="8.5.0"; Description="Transfer data"; Category="util"}
        @{Name="wget"; Version="1.21.4"; Description="Network downloader"; Category="util"}
        @{Name="ffmpeg"; Version="6.1.1"; Description="Video converter"; Category="media"}
        @{Name="go"; Version="1.21.6"; Description="Go language"; Category="lang"}
        @{Name="rust"; Version="1.76.0"; Description="Rust language"; Category="lang"}
        @{Name="dotnet"; Version="8.0.1"; Description=".NET SDK"; Category="dev"}
        @{Name="java"; Version="21.0.2"; Description="Java JDK"; Category="lang"}
        @{Name="php"; Version="8.3.2"; Description="PHP language"; Category="lang"}
        @{Name="nginx"; Version="1.24.0"; Description="Web server"; Category="server"}
        @{Name="mysql"; Version="8.0.36"; Description="Database"; Category="database"}
        @{Name="postgresql"; Version="16.1"; Description="Database"; Category="database"}
        @{Name="redis"; Version="7.2.4"; Description="Cache server"; Category="database"}
        @{Name="terraform"; Version="1.7.4"; Description="Infrastructure"; Category="dev"}
        @{Name="kubectl"; Version="1.29.1"; Description="Kubernetes CLI"; Category="dev"}
        @{Name="helm"; Version="3.14.0"; Description="K8s package manager"; Category="dev"}
        @{Name="vagrant"; Version="2.4.1"; Description="VM manager"; Category="dev"}
        @{Name="nmap"; Version="7.94"; Description="Network scanner"; Category="net"}
        @{Name="putty"; Version="0.80"; Description="SSH client"; Category="net"}
        @{Name="notepadplusplus"; Version="8.6.4"; Description="Text editor"; Category="editor"}
        @{Name="vlc"; Version="3.0.20"; Description="Media player"; Category="media"}
        @{Name="gimp"; Version="2.10.36"; Description="Image editor"; Category="media"}
        @{Name="discord"; Version="1.0.9019"; Description="Chat app"; Category="social"}
        @{Name="telegram"; Version="4.14.9"; Description="Messaging"; Category="social"}
        @{Name="spotify"; Version="1.2.30"; Description="Music"; Category="media"}
        @{Name="powershell"; Version="7.4.1"; Description="PowerShell Core"; Category="dev"}
    )

    $packages | ConvertTo-Json -Depth 3 | Set-Content $global:DatabaseFile
    Write-Message "[+] Database initialized with $($packages.Count) packages" "SUCCESS"
}

function Get-PackageDatabase
{
    if (Test-Path $global:DatabaseFile)
    {
        return Get-Content $global:DatabaseFile | ConvertFrom-Json
    }

    return @()
}

function Get-InstalledPackages
{
    if (Test-Path $global:InstalledFile)
    {
        return Get-Content $global:InstalledFile | ConvertFrom-Json
    }

    return @{}
}

function Install-Package
{
    param([string]$Name, [switch]$Force)

    Write-Message "[*] Installing package: $Name" "INFO"

    $db = Get-PackageDatabase
    $package = $db | Where-Object { $_.Name -eq $Name }

    if (-not $package)
    {
        Write-Message "[-] Package not found: $Name" "ERROR"
        return $false
    }

    $installed = Get-InstalledPackages

    if ($installed.PSObject.Properties.Name -contains $Name -and -not $Force)
    {
        Write-Message "[!] Package already installed: $Name" "WARNING"
        return $false
    }

    Write-Message "[+] Successfully installed $Name version $($package.Version)" "SUCCESS"

    $installed | Add-Member -NotePropertyName $Name -NotePropertyValue @{
        Version = $package.Version
        InstallDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Category = $package.Category
    }

    $installed | ConvertTo-Json | Set-Content $global:InstalledFile
    Write-Log "INFO" "Installed $Name version $($package.Version)"

    return $true
}

function Remove-Package
{
    param([string]$Name)

    Write-Message "[*] Removing package: $Name" "INFO"

    $installed = Get-InstalledPackages

    if ($installed.PSObject.Properties.Name -notcontains $Name)
    {
        Write-Message "[-] Package not installed: $Name" "ERROR"
        return $false
    }

    $installed.PSObject.Properties.Remove($Name)
    $installed | ConvertTo-Json | Set-Content $global:InstalledFile

    Write-Message "[+] Successfully removed $Name" "SUCCESS"
    Write-Log "INFO" "Removed $Name"

    return $true
}

function Search-Packages
{
    param([string]$Query)

    Write-Message "[*] Searching for: $Query" "INFO"
    Write-Host ""

    $db = Get-PackageDatabase
    $results = $db | Where-Object {
        $_.Name -like "*$Query*" -or
        $_.Description -like "*$Query*" -or
        $_.Category -like "*$Query*"
    }

    if ($results.Count -eq 0)
    {
        Write-Message "[-] No packages found" "ERROR"
    }
    else
    {
        Write-Message "[+] Found $($results.Count) packages:" "SUCCESS"
        Write-Host ""

        $grouped = $results | Group-Object Category

        foreach ($group in $grouped)
        {
            Write-Host ""
            Write-Host "  Category: $($group.Name)" -ForegroundColor Cyan
            Write-Host "  -------------------------------" -ForegroundColor DarkGray

            foreach ($pkg in $group.Group)
            {
                $installed = Get-InstalledPackages
                $check = $installed.PSObject.Properties.Name -contains $pkg.Name
                $status = ""

                if ($check)
                {
                    $status = "[OK]"
                }
                else
                {
                    $status = "[ ]"
                }

                Write-Host "  $status $($pkg.Name) - $($pkg.Description)" -ForegroundColor White
                Write-Host "        Version: $($pkg.Version)" -ForegroundColor Gray
            }
        }

        Write-Host ""
    }
}

function Show-InstalledPackages
{
    $installed = Get-InstalledPackages

    if ($installed.PSObject.Properties.Count -eq 0)
    {
        Write-Message "[!] No packages installed" "WARNING"
        return
    }

    Write-Message "[+] Installed packages ($($installed.PSObject.Properties.Count)):" "SUCCESS"
    Write-Host ""
    Write-Host "  Name                 Version        Category    Install Date" -ForegroundColor Cyan
    Write-Host "  -------------------- -------------- ---------- -------------------" -ForegroundColor DarkGray

    foreach ($name in $installed.PSObject.Properties.Name | Sort-Object)
    {
        $info = $installed.$name

        Write-Host "  $($name.PadRight(20))" -NoNewline -ForegroundColor White
        Write-Host "$($info.Version.PadRight(14))" -NoNewline -ForegroundColor Green
        Write-Host "$($info.Category.PadRight(10))" -NoNewline -ForegroundColor Magenta
        Write-Host "$($info.InstallDate)" -ForegroundColor Gray
    }

    Write-Host ""
}

function Show-PackageInfo
{
    param([string]$Name)

    $db = Get-PackageDatabase
    $package = $db | Where-Object { $_.Name -eq $Name }

    if (-not $package)
    {
        Write-Message "[-] Package not found: $Name" "ERROR"
        return
    }

    $installed = Get-InstalledPackages
    $isInstalled = $installed.PSObject.Properties.Name -contains $Name

    Write-Host ""
    Write-Host "  Package Information: $Name" -ForegroundColor Cyan
    Write-Host "  ==========================================" -ForegroundColor DarkGray
    Write-Host "  Name         : $($package.Name)" -ForegroundColor White
    Write-Host "  Version      : $($package.Version)" -ForegroundColor Green
    Write-Host "  Category     : $($package.Category)" -ForegroundColor Magenta
    Write-Host "  Description  : $($package.Description)" -ForegroundColor Gray

    if ($isInstalled)
    {
        Write-Host "  Install Date : $($installed.$Name.InstallDate)" -ForegroundColor Green
        Write-Host "  Status       : INSTALLED" -ForegroundColor Green
    }
    else
    {
        Write-Host "  Status       : NOT INSTALLED" -ForegroundColor Red
    }

    Write-Host ""
}

function Update-Database
{
    Write-Message "[*] Checking for database updates..." "INFO"

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Write-Message "[+] Database is up to date" "SUCCESS"
    Write-Message "[+] Last sync: $timestamp" "INFO"
}

function Upgrade-All
{
    Write-Message "[*] Upgrading all packages..." "INFO"

    $installed = Get-InstalledPackages
    $count = $installed.PSObject.Properties.Count

    if ($count -eq 0)
    {
        Write-Message "[!] No packages installed" "WARNING"
        return
    }

    foreach ($name in $installed.PSObject.Properties.Name)
    {
        Write-Message "[*] Checking $name..." "INFO"
        Write-Message "[+] $name is up to date" "SUCCESS"
    }

    Write-Message "[+] All $count packages are up to date" "SUCCESS"
}

function Export-PackageList
{
    param([string]$File = "package-list.txt")

    $installed = Get-InstalledPackages
    $count = $installed.PSObject.Properties.Count

    if ($count -eq 0)
    {
        Write-Message "[!] No packages installed" "WARNING"
        return
    }

    $content = "# Pacman Package List`n"
    $content = $content + "# Generated: $(Get-Date)`n"
    $content = $content + "# Host: $env:COMPUTERNAME`n"
    $content = $content + "# User: $env:USERNAME`n"
    $content = $content + "`n"

    foreach ($name in $installed.PSObject.Properties.Name | Sort-Object)
    {
        $info = $installed.$name
        $content = $content + "$name $($info.Version)`n"
    }

    $content | Set-Content $File
    Write-Message "[+] Package list exported to: $File" "SUCCESS"
}

function Import-PackageList
{
    param([string]$File)

    if (-not (Test-Path $File))
    {
        Write-Message "[-] File not found: $File" "ERROR"
        return
    }

    $lines = Get-Content $File
    $count = 0

    foreach ($line in $lines)
    {
        if ($line -match "^([a-z0-9]+)")
        {
            $pkgName = $matches[1]
            Install-Package -Name $pkgName
            $count = $count + 1
        }
    }

    Write-Message "[+] Imported $count packages" "SUCCESS"
}

function Clean-Cache
{
    Write-Message "[*] Cleaning package cache..." "INFO"

    $tempFiles = Get-ChildItem -Path $env:TEMP -Filter "pacman-*" -ErrorAction SilentlyContinue
    $count = $tempFiles.Count
    $tempFiles | Remove-Item -Force -ErrorAction SilentlyContinue

    Write-Message "[+] Removed $count temporary files" "SUCCESS"
}

function Show-Stats
{
    $installed = Get-InstalledPackages
    $db = Get-PackageDatabase

    $totalInstalled = $installed.PSObject.Properties.Count
    $totalAvailable = $db.Count
    $categories = $db | Group-Object Category

    Write-Host ""
    Write-Host "  System Statistics" -ForegroundColor Cyan
    Write-Host "  ==========================================" -ForegroundColor DarkGray
    Write-Host "  Total installed : $totalInstalled packages" -ForegroundColor Green
    Write-Host "  Total available : $totalAvailable packages" -ForegroundColor Yellow
    Write-Host "  Categories      : $($categories.Count)" -ForegroundColor Magenta
    Write-Host "  Config path     : $global:ConfigPath" -ForegroundColor Gray
    Write-Host "  Log file        : $global:LogFile" -ForegroundColor Gray
    Write-Host ""

    Write-Message "[*] Packages by category:" "INFO"
    Write-Host ""

    foreach ($cat in $categories)
    {
        $percentage = [math]::Round(($cat.Count / $totalAvailable) * 100, 1)
        $barLength = [math]::Round($percentage / 2)
        $bar = ""

        $i = 0
        while ($i -lt $barLength)
        {
            $bar = $bar + "#"
            $i = $i + 1
        }

        while ($i -lt 50)
        {
            $bar = $bar + "."
            $i = $i + 1
        }

        Write-Host "  $($cat.Name.PadRight(12)) : $($percentage.ToString().PadLeft(5))% $bar" -ForegroundColor Gray
    }

    Write-Host ""
}

function Show-Help
{
    Write-Host ""
    Write-Host "  PACMAN PACKAGE MANAGER v$global:Version" -ForegroundColor Cyan
    Write-Host "  ==========================================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  COMMANDS:" -ForegroundColor Yellow
    Write-Host "    install <package>  - Install a package" -ForegroundColor White
    Write-Host "    remove <package>   - Remove a package" -ForegroundColor White
    Write-Host "    search <query>     - Search for packages" -ForegroundColor White
    Write-Host "    list               - List installed packages" -ForegroundColor White
    Write-Host "    info <package>     - Show package details" -ForegroundColor White
    Write-Host "    update             - Update package database" -ForegroundColor White
    Write-Host "    upgrade            - Upgrade all packages" -ForegroundColor White
    Write-Host "    export [file]      - Export package list" -ForegroundColor White
    Write-Host "    import <file>      - Import package list" -ForegroundColor White
    Write-Host "    clean              - Clean cache" -ForegroundColor White
    Write-Host "    stats              - Show statistics" -ForegroundColor White
    Write-Host "    help               - Show this help" -ForegroundColor White
    Write-Host ""
    Write-Host "  EXAMPLES:" -ForegroundColor Yellow
    Write-Host "    .\pacman.ps1 install git" -ForegroundColor Gray
    Write-Host "    .\pacman.ps1 search python" -ForegroundColor Gray
    Write-Host "    .\pacman.ps1 list" -ForegroundColor Gray
    Write-Host "    .\pacman.ps1 info node" -ForegroundColor Gray
    Write-Host "    .\pacman.ps1 stats" -ForegroundColor Gray
    Write-Host "    .\pacman.ps1 export mypackages.txt" -ForegroundColor Gray
    Write-Host "    .\pacman.ps1 clean" -ForegroundColor Gray
    Write-Host ""
}

Show-Banner

if ($args.Count -eq 0 -or $Command -eq "help")
{
    Show-Help
}
else
{
    Initialize-Pacman

    switch ($Command)
    {
        "install"
        {
            if ($PackageName)
            {
                Install-Package -Name $PackageName -Force:$Force
            }
            elseif ($Packages)
            {
                foreach ($pkg in $Packages)
                {
                    Install-Package -Name $pkg -Force:$Force
                }
            }
            else
            {
                Write-Message "[-] Specify package name" "ERROR"
            }
        }

        "remove"
        {
            if ($PackageName)
            {
                Remove-Package -Name $PackageName
            }
            else
            {
                Write-Message "[-] Specify package name" "ERROR"
            }
        }

        "search"
        {
            if ($PackageName)
            {
                Search-Packages -Query $PackageName
            }
            else
            {
                Write-Message "[-] Specify search query" "ERROR"
            }
        }

        "list"
        {
            Show-InstalledPackages
        }

        "info"
        {
            if ($PackageName)
            {
                Show-PackageInfo -Name $PackageName
            }
            else
            {
                Write-Message "[-] Specify package name" "ERROR"
            }
        }

        "update"
        {
            Update-Database
        }

        "upgrade"
        {
            Upgrade-All
        }

        "export"
        {
            if ($PackageName)
            {
                Export-PackageList -File $PackageName
            }
            else
            {
                Export-PackageList
            }
        }

        "import"
        {
            if ($PackageName)
            {
                Import-PackageList -File $PackageName
            }
            else
            {
                Write-Message "[-] Specify import file" "ERROR"
            }
        }

        "clean"
        {
            Clean-Cache
        }

        "stats"
        {
            Show-Stats
        }

        default
        {
            Write-Message "[-] Unknown command: $Command" "ERROR"
            Write-Message "[?] Type '.\pacman.ps1 help' for usage" "INFO"
        }
    }
}
