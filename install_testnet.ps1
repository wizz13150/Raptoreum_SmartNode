#####################################
### Smartnode Installation Script ###
####### for Windows 10 & 11 #########
################ (: #################

# Admin control
function IsAdministrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
if (-not (IsAdministrator)) {
    Write-Host "$((Get-Date).ToString(`"yyyy-MM-dd HH:mm:ss`"))  Please run this script with administrative privileges..." -ForegroundColor Cyan
    pause
    exit
}

# Script vars
$bootstrapZip = "https://bootstrap.raptoreum.com/testnet-bootstraps/rip01-testnet-no-index-bootstrap.zip"                       #Official testnet bootstrap
#$bootstrapZip = "https://github.com/wizz13150/Raptoreum_SmartNode/releases/download/Raptoreum_SmartNode/bootstrap-testnet.zip" #wizz's bootstrap
$configDir = "$env:APPDATA\RaptoreumSmartnode"
$coinPath = "$env:ProgramFiles (x86)\RaptoreumCore"
$testnetfolder = "rip01-testnet"
$configPath = "$configDir\$testnetfolder\raptoreum_testnet.conf"
$bootstrapZipPath = "$env:APPDATA\bootstrap\rip01-testnet-no-index-bootstrap.zip"
$serviceName = "RTMServiceTestnet"


Write-Host "================================================================================" -ForegroundColor Yellow 
Write-Host " RTM Smartnode Setup for Testnet" -ForegroundColor Yellow 
Write-Host "================================================================================" -ForegroundColor Yellow 
Write-Host ""
Write-Host " July 2021, created and updated by dk808 from AltTank" -ForegroundColor Cyan 
Write-Host " With Smartnode healthcheck by Delgon" -ForegroundColor Cyan
Write-Host " March 2023, adapted to Windows by Wizz" -ForegroundColor Cyan
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Yellow
Write-Host " Remember to always encrypt your wallet with a strong password !" -ForegroundColor Yellow 
Write-Host "================================================================================" -ForegroundColor Yellow
Write-Host " Testnet Node setup starting, press [CTRL-C] to cancel..." -ForegroundColor Cyan 
Start-Sleep -Seconds 1


function KeepWindows-Up {
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    powercfg -change -standby-timeout-ac 0
    powercfg -change -standby-timeout-dc 0
    powercfg -change -disk-timeout-ac 0
    powercfg -change -disk-timeout-dc 0
    powercfg -h off
}

function Write-CurrentTime {
    Write-Host ('[' + (Get-Date).ToString("HH:mm:ss") + ']') -NoNewline
}

function Wipe-Clean {
    Write-CurrentTime; Write-Host "  Removing any previous instance of a testnet Smartnode (with this script)..." -ForegroundColor Yellow
    Stop-Service -Name $serviceName -ErrorAction SilentlyContinue -Force
    if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
        sc.exe delete $serviceName | Out-Null
    }
    Remove-Item -Path $configDir\$testnetfolder -Recurse -ErrorAction SilentlyContinue -Force
    Remove-Item -Path $coinPath -Recurse -ErrorAction SilentlyContinue -Force
    [Environment]::SetEnvironmentVariable("traptoreumcli", "$null", "Machine")

    $files = @(
        "$env:USERPROFILE\update_testnet.ps1", "$env:USERPROFILE\check_testnet.ps1",
        "$env:USERPROFILE\check_testnet.bat", "$env:USERPROFILE\chainbackup_testnet.ps1",
        "$env:USERPROFILE\chainbackup_testnet.bat", "$env:USERPROFILE\RTM-MOTD_testnet.txt",
        "$env:USERPROFILE\SmartNodeBash_testnet.bat", "$env:USERPROFILE\rtmdebuglogrotate_testnet.conf",
        "$env:UserProfile\height_testnet.tmp", "$env:UserProfile\prev_stuck_testnet.tmp",
        "$env:UserProfile\was_stuck_testnet.tmp", "$env:UserProfile\pose_score_testnet.tmp"
    ) 
    foreach ($file in $files) {
        if (Test-Path $file) {
            Remove-Item -Path $file -ErrorAction SilentlyContinue -Force
        }
    }
}

$global:CLI = ""
function Environment-Variable {
    Write-CurrentTime; Write-Host "  Set %traptoreumcli% as Environment Variable..." -ForegroundColor Cyan
    # Env vars
    $envPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $newPath = "C:\Program Files (x86)\RaptoreumCore"
    if (-not ($envPath.Contains($newPath))) {
        [Environment]::SetEnvironmentVariable("Path", "$envPath;$newPath", "Machine")
    }
    $global:CLI = "`"$coinPath\raptoreum-cli.exe`" -testnet -datadir=`"$configDir`" -conf=`"$configDir\$testnetfolder\raptoreum_testnet.conf`""
    [Environment]::SetEnvironmentVariable("traptoreumcli", "$CLI", "Machine")
}

function Install-7Zip {
    $7zipKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\7zFM.exe"
    if (Test-Path $7zipKey) {
        Write-CurrentTime; Write-Host "  7-Zip is already installed..." -ForegroundColor Yellow
    } else {
        $7zipInstallerUrl = "https://www.7-zip.org/a/7z1900-x64.msi"
        $7zipInstallerPath = "$env:USERPROFILE\7z_installer.msi"
        Write-CurrentTime; Write-Host "  Downloading 7-Zip installer..." -ForegroundColor Cyan
        Start-BitsTransfer -Source $7zipInstallerUrl -Destination $7zipInstallerPath -DisplayName "Downloading 7-Zip installer from $7zipInstallerUrl"
        Write-CurrentTime; Write-Host "  Installing 7-Zip..." -ForegroundColor Yellow
        $msiArguments = @{
        FilePath     = "msiexec.exe"
        ArgumentList = "/i `"$7zipInstallerPath`" /qn"
        Wait         = $true
        Verb         = "RunAs"
    }
    Start-Process @msiArguments
    Remove-Item $7zipInstallerPath -Force
    Write-CurrentTime; Write-Host "  7-Zip installed successfully..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 1
}

function Extract-Bootstrap {
    Write-CurrentTime; Write-Host "  Extracting bootstrap from: $bootstrapZipPath..." -ForegroundColor Yellow
    Write-CurrentTime; Write-Host "  Extracting bootstrap to  : $configDir\$testnetfolder..." -ForegroundColor Yellow
    $zipProgram = ""
    $7zipKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\7zFM.exe"
    if (Test-Path $7zipKey) {
        $zipProgram = (Get-ItemProperty $7zipKey).'Path' + "7z.exe"
    }
    if ($zipProgram) {
        Write-CurrentTime; Write-Host "  7-Zip detected, using 7-Zip to extract the bootstrap. Faster..." -ForegroundColor Cyan
        & "$zipProgram" x $bootstrapZipPath -o"$configDir" -y
    } else {
        Write-CurrentTime; Write-Host "  7-Zip not detected, using 'Expand-Archive' to extract the bootstrap. Slower..." -ForegroundColor Cyan
        Expand-Archive -Path $bootstrapZipPath -DestinationPath "$configDir" -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 1
}

function Install-NSSM {
    $NSSM_URL = "https://nssm.cc/release/nssm-2.24.zip"
    $NSSM_ZipFile = "$env:TEMP\nssm.zip"
    Write-CurrentTime; Write-Host "  Downloading NSSM..." -ForegroundColor Cyan
    Start-BitsTransfer -Source $NSSM_URL -Destination $NSSM_ZipFile -DisplayName "Downloading NSSM from $NSSM_URL"
    Write-CurrentTime; Write-Host "  Extracting NSSM to $env:UserProfile..." -ForegroundColor Yellow
    Expand-Archive -Path $NSSM_ZipFile -DestinationPath $env:UserProfile -ErrorAction SilentlyContinue -Force
    Write-CurrentTime; Write-Host "  Removing NSSM Zip..." -ForegroundColor Yellow
    Remove-Item -Path $NSSM_ZipFile -ErrorAction SilentlyContinue -Force
    Start-Sleep -Seconds 1
}

function Install-LogrotateWin {
    Write-CurrentTime; Write-Host "  Installing LogrotateWin..." -ForegroundColor Cyan
    $LogrotateWinUrl = "https://sourceforge.net/projects/logrotatewin/files/latest/download"
    $LogrotateWinPath = "$env:TEMP\logrotatewin.zip"
    $LogrotateWinExtractPath = "$env:UserProfile\LogrotateWin"
    $LogrotateWinInstaller = "$LogrotateWinExtractPath\logrotateSetup.exe"
    $LogrotateWinExtracted = Test-Path -Path "$LogrotateWinExtractPath\Logrotate.exe"
    if ($LogrotateWinExtracted) 
    {
        Write-CurrentTime; Write-Host "  LogrotateWin already installed..." -ForegroundColor Yellow
    } else {
        Write-CurrentTime; Write-Host "  Downloading and installing LogrotateWin ..." -ForegroundColor Cyan
        Start-BitsTransfer -Source $LogrotateWinUrl -Destination $LogrotateWinPath -DisplayName "Downloading LogrotateWin from $LogrotateWinUrl"
        Write-CurrentTime; Write-Host "  Extracting LogrotateWin to $LogrotateWinExtractPath" -ForegroundColor Yellow
        Expand-Archive -Path $LogrotateWinPath -DestinationPath $LogrotateWinExtractPath -ErrorAction SilentlyContinue -Force
        .$LogrotateWinInstaller /s /v"INSTALLDIR=$LogrotateWinExtractPath" /V"AgreeToLicense=yes" /V"/qn"
        Write-CurrentTime; Write-Host "  LogrotateWin installed successfully..." -ForegroundColor Yellow
        Write-CurrentTime; Write-Host "  Removing LogrotateWin Zip..." -ForegroundColor Yellow
        Remove-Item -Path $LogrotateWinPath -ErrorAction SilentlyContinue -Force
    }
    Start-Sleep -Seconds 1
}


function Create-Shortcuts {
    # Create SmartNodeBash.lnk
    $ShortcutPath = [Environment]::GetFolderPath("Desktop") + "\SmartNodeBash_testnet.lnk"
    Write-CurrentTime; Write-Host "  Creating a desktop shortcut for SmartNodeBash_testnet.bat..." -ForegroundColor Cyan
    $TargetPath = "powershell.exe"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetPath
    $Command = "-Command `"Start-Process cmd.exe -ArgumentList '/c `"$env:USERPROFILE\SmartNodeBash_testnet.bat`"' -Verb RunAs`""
    $Shortcut.Arguments = $Command
    $Shortcut.IconLocation = "$coinPath\raptoreum-qt.exe"
    $Shortcut.WorkingDirectory = [Environment]::GetFolderPath("Desktop")
    $Shortcut.Save()
    Write-CurrentTime; Write-Host "  $ShortcutPath created successfully..." -ForegroundColor Yellow
    # Create UpdateSmartnode.lnk
    $UpdateShortcutPath = [Environment]::GetFolderPath("Desktop") + "\UpdateSmartnode_testnet.lnk"
    Write-CurrentTime; Write-Host "  Creating a desktop shortcut for Update_testnet.bat..." -ForegroundColor Cyan
    $UpdateTargetPath = "powershell.exe"
    $UpdateShortcut = $WScriptShell.CreateShortcut($UpdateShortcutPath)
    $UpdateShortcut.TargetPath = $UpdateTargetPath
    $UpdateCommand = "-Command `"Start-Process cmd.exe -ArgumentList '/c `"$env:USERPROFILE\update_testnet.bat`"' -Verb RunAs`""
    $UpdateShortcut.Arguments = $UpdateCommand
    $UpdateShortcut.IconLocation = "$coinPath\raptoreum-qt.exe"
    $UpdateShortcut.WorkingDirectory = [Environment]::GetFolderPath("Desktop")
    $UpdateShortcut.Save()
    Write-CurrentTime; Write-Host "  $UpdateShortcutPath created successfully..." -ForegroundColor Yellow
    # Create Dashboard_testnet.lnk
    $DashboardShortcutPath = [Environment]::GetFolderPath("Desktop") + "\Dashboard_testnet.lnk"
    Write-CurrentTime; Write-Host "  Creating a desktop shortcut for Dashboard_testnet.bat..." -ForegroundColor Cyan
    $DashboardTargetPath = "cmd.exe"
    $DashboardShortcut = $WScriptShell.CreateShortcut($DashboardShortcutPath)
    $DashboardShortcut.TargetPath = $DashboardTargetPath
    $DashboardCommand = "/c `"$env:USERPROFILE\Dashboard_testnet.bat`""
    $DashboardShortcut.Arguments = $DashboardCommand
    $DashboardShortcut.IconLocation = "$coinPath\raptoreum-qt.exe"
    $DashboardShortcut.WorkingDirectory = [Environment]::GetFolderPath("Desktop")
    $DashboardShortcut.Save()
    Write-CurrentTime; Write-Host "  $DashboardShortcutPath created successfully..." -ForegroundColor Yellow
}


$global:sshPort = ""
function Get-SSHPort {
    Write-CurrentTime; Write-Host "  Detecting SSH port being used..." -ForegroundColor Yellow
    $sshdConfigPath = "$env:ProgramData\ssh\sshd_config"
    if (Test-Path $sshdConfigPath) {
        $content = Get-Content $sshdConfigPath
        $portLine = $content | Where-Object { $_ -match "^Port\s+\d+" }    
        if ($portLine -ne $null) {
            $global:sshPort = $portLine -replace "^Port\s+", ""
            Write-CurrentTime; Write-Host "  SSH Port: $($global:sshPort)" -ForegroundColor Yellow
        } else {
            $global:sshPort = 22
            Write-CurrentTime; Write-Host "  No port found in the configuration file. Default SSH port is $($global:sshPort)." -ForegroundColor Yellow
        }
    } else {
        $global:sshPort = 22
        Write-CurrentTime; Write-Host "  OpenSSH server configuration file not found. Default SSH port is $($global:sshPort)." -ForegroundColor Yellow
    }
    do {
        $useSSH = Read-Host -Prompt "Detected SSH port is $($global:sshPort), is this correct? (y/n) "
        if ($useSSH -eq "n") {
            $global:sshPort = Read-Host -Prompt "Enter SSH port "
        }
    } while ($useSSH -ne "y" -and $useSSH -ne "n" -and $useSSH -ne "")
    Start-Sleep -Seconds 1
}

$global:wanIP = ""
function Confirm-IP {
    Write-CurrentTime; Write-Host "  Detecting IP address being used..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    $global:wanIP = Invoke-WebRequest -Uri "http://ipecho.net/plain" -UseBasicParsing | Select-Object -ExpandProperty Content
    do {
        $useDetectedIP = Read-Host -Prompt "Detected IP address is $($global:wanIP), is this correct? (y/n) "
        if ($useDetectedIP -eq "n") {
            $global:wanIP = Read-Host -Prompt "Enter IP address "
        }
    } while ($useDetectedIP -ne "y" -and $useDetectedIP -ne "n" -and $useDetectedIP -ne "")
    Start-Sleep -Seconds 1
}

$global:smartnodeblsprivkey = ""
function Create-Conf {
    # If $QuickSetup is provided, just ask about BLS key.
    param(
        [string]$QuickSetup
    )
    if (-not [string]::IsNullOrEmpty($QuickSetup)) {
        do {
            $global:smartnodeblsprivkey = Read-Host -Prompt "Enter your SmartNode BLS Privkey (operatorSecret)"
            if ($global:smartnodeblsprivkey.Length -ne 64) {
                Write-Host "  The BLS must be exactly 64 characters long, please check your BLS..." -ForegroundColor Yellow
            }
        } until ($global:smartnodeblsprivkey.Length -eq 64)
        return
    }
    if (Test-Path $configPath) {
        Write-CurrentTime; Write-Host "  Existing conf file found backing up to Raptoreum_testnet.old ..." -ForegroundColor Yellow
        Move-Item -Path $configPath -Destination "$configDir\$testnetfolder\Raptoreum_testnet.old" -Force
    }
    $rpcUser = -join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_})
    $password = -join ((65..90) + (97..122) | Get-Random -Count 20 | % {[char]$_})
    Write-CurrentTime; Write-Host "  Creating Conf File..." -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir | Out-Null
        if (-not (Test-Path "$configDir\$testnetfolder")) {            
            New-Item -ItemType Directory -Path "$configDir\$testnetfolder" | Out-Null
        }
    }
    $configContent = @"
[test]
rpcuser=$rpcUser
rpcpassword=$password
rpcallowip=127.0.0.1
rpcbind=127.0.0.1
port=10230
server=1
testnet=1
listen=1
txindex=1
smartnodeblsprivkey=$global:smartnodeblsprivkey
externalip=$global:wanIP
maxconnections=125
dbcache=1024
onlynet=ipv4
addnode=lbdn.raptoreum.com
"@
    if (Test-Path $configPath) {
    $configContent | Set-Content -Path $configPath -ErrorAction SilentlyContinue -Force
    } else {
        New-Item -ItemType File -Path $configPath -Value $configContent -ErrorAction SilentlyContinue -Force  | Out-Null
    }
    Write-Host "$configPath created..."
    Start-Sleep -Seconds 1
}

function Install-Bins {
    Write-CurrentTime; Write-Host "  Installing latest binaries..." -ForegroundColor Cyan
    $uri = "https://api.github.com/repos/Raptor3um/raptoreum/releases/latest"
    $response = Invoke-RestMethod -Uri $uri
    $latestVersion = $response.tag_name
    $walletUrl = "https://github.com/Raptor3um/raptoreum/releases/download/$latestVersion-testnet/raptoreum-win-$latestVersion-testnet.zip"
    # Fetch the latest release using GitHub
    $process = Get-Process "raptoreumd" -ErrorAction SilentlyContinue
    if ($process) {
        Write-CurrentTime; Write-Host "  Raptoreum process detected, stopping..." -ForegroundColor Yellow
        $confirmation = ""
        do {
            $confirmation = Read-Host "Do you want to stop RTMService ? (y/n) "
            if ($confirmation -eq "y") {
                Stop-Service RTMService -ErrorAction SilentlyContinue -Force
                Write-CurrentTime; Write-Host "  RTMService has been stopped..." -ForegroundColor Yellow
            } elseif ($confirmation -eq "n") {
                Write-CurrentTime; Write-Host "  RTMService was not stopped, we can't install binaries..." -ForegroundColor Yellow
                return
            } else {
                Write-CurrentTime; Write-Host "  Please enter 'y' or 'n'..." -ForegroundColor Yellow
            }
        } while ($confirmation -ne "y" -and $confirmation -ne "n")
        if (-not (Test-Path $coinPath)) {
            New-Item -Path $coinPath -ItemType Directory | Out-Null
        }
        Write-CurrentTime; Write-Host "  Downloading latest binaries ($latestVersion)..." -ForegroundColor Yellow
        Start-BitsTransfer -Source $walletUrl -Destination "$coinPath\raptoreum.zip" -DisplayName "Downloading binaries from $walletUrl"
        Write-CurrentTime; Write-Host "  Unzipping..." -ForegroundColor Yellow
        Expand-Archive -Path "$coinPath\raptoreum.zip" -DestinationPath $coinPath -ErrorAction SilentlyContinue -Force
        Write-CurrentTime; Write-Host "  Removing..." -ForegroundColor Yellow
        Remove-Item -Path "$coinPath\raptoreum.zip" -Recurse -ErrorAction SilentlyContinue -Force
    } else {
        if (-not (Test-Path $coinPath)) {
            New-Item -Path $coinPath -ItemType Directory| Out-Null
        }
        Write-CurrentTime; Write-Host "  Downloading latest binaries ($latestVersion)..." -ForegroundColor Yellow
        Start-BitsTransfer -Source $walletUrl -Destination "$coinPath\raptoreum.zip" -DisplayName "Downloading binaries from $walletUrl"
        Write-CurrentTime; Write-Host "  Unzipping..." -ForegroundColor Yellow
        Expand-Archive -Path "$coinPath\raptoreum.zip" -DestinationPath $coinPath -ErrorAction SilentlyContinue -Force
        Write-CurrentTime; Write-Host "  Removing..." -ForegroundColor Yellow
        Remove-Item -Path "$coinPath\raptoreum.zip" -Recurse -ErrorAction SilentlyContinue -Force
    }
    Start-Sleep -Seconds 1
}

$global:bootstrapAns = ""
function Bootstrap-Chain {
        # If $QuickSetup is provided, just ask about bootstrap.
    param(
        [string]$QuickSetup
    )
    if (-not [string]::IsNullOrEmpty($QuickSetup)) {
        do {
            $prompt = Read-Host -Prompt "Would you like to bootstrap the chain? (y/n) "
            if ($prompt -eq "y" -or $prompt -eq "") {
                $global:bootstrapAns = 1
            }
        } while ($prompt -ne "y" -and $prompt -ne "n" -and $prompt -ne "")
        return
    }
    if ($global:bootstrapAns -eq "1") {
            if (-not (Test-Path -Path "$env:APPDATA\bootstrap")) {
                New-Item -ItemType Directory -Path "$env:APPDATA\bootstrap" -ErrorAction SilentlyContinue -Force | Out-Null
            }
            Write-CurrentTime; Write-Host "  Downloading the bootstrap, please be patient..." -ForegroundColor Cyan
            Start-BitsTransfer -Source $bootstrapZip -Destination "$env:APPDATA\bootstrap\" -DisplayName "Downloading bootstrap from $bootstrapZip"
            Extract-Bootstrap
    }
    Start-Sleep -Seconds 1
}

function Chain-Backup {
    Write-CurrentTime; Write-Host "  Creating bootstrap script..." -ForegroundColor Cyan
    $chainBackupScript = @"
`$bootstrapZipPath = "$bootstrapZipPath"
`$configDir = "$configDir"
Write-Host "(`$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))  Creating blockchain backup (bootstrap)..." -ForegroundColor Yellow
Move-Item -Path "`$env:USERPROFILE\check_testnet.ps1" -Destination "`$env:USERPROFILE\temp.ps1" -ErrorAction SilentlyContinue -Force
Stop-Service -Name $serviceName -ErrorAction SilentlyContinue -Force
Start-Sleep -Seconds 2
# Check if the wallet process is running and kill it if it is
`$walletProcess = Get-Process -Name "raptoreumd" -ErrorAction SilentlyContinue
if (`$walletProcess) {
    Write-Host "(`$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))  Stopping the running Raptoreum process..." -ForegroundColor Yellow
    Stop-Process `$walletProcess.Id -Force
} else {
    Write-Host "(`$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))  No Raptoreum process detected..." -ForegroundColor Green
}
Start-Sleep -Seconds 2
Remove-Item -Path `$bootstrapZipPath -ErrorAction SilentlyContinue
`$zipProgram = ""
`$7zipKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\7zFM.exe"
if (Test-Path `$7zipKey) {
    `$zipProgram = (Get-ItemProperty `$7zipKey).'Path' + "7z.exe"
}
if (`$zipProgram) {
    Write-Host "(`$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))  7-Zip detected, using 7-Zip to compress the bootstrap. Faster..." -ForegroundColor Cyan
    & "`$zipProgram" a -tzip `$bootstrapZipPath "`$configDir\`$testnetfolder\blocks" "`$configDir\`$testnetfolder\chainstate" "`$configDir\`$testnetfolder\evodb" "`$configDir\`$testnetfolder\llmq" "`$configDir\`$testnetfolder\powcache.dat"
} else {
    Write-Host "(`$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))  7-Zip not detected, using 'Expand-Archive' to compress the bootstrap. Slower..." -ForegroundColor Cyan
    Compress-Archive -Path "`$configDir\`$testnetfolder\blocks", "`$configDir\`$testnetfolder\chainstate", "`$configDir\`$testnetfolder\evodb", "`$configDir\`$testnetfolder\llmq", "`$configDir\`$testnetfolder\powcache.dat" -DestinationPath `$bootstrapZipPath
}
Write-Host "(`$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))  Bootstrap created" -ForegroundColor Green
Start-Service -Name $serviceName -ErrorAction SilentlyContinue
Move-Item -Path "`$env:USERPROFILE\temp.ps1" -Destination "`$env:USERPROFILE\check_testnet.ps1" -ErrorAction SilentlyContinue -Force
Start-Sleep -Seconds 10
"@
    Set-Content -Path "$env:USERPROFILE\chainbackup_testnet.ps1" -Value $chainBackupScript
    Write-CurrentTime; Write-Host "  Script created: $env:USERPROFILE\chainbackup_testnet.ps1..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

function Update-Script {
    Write-CurrentTime; Write-Host "  Creating a script to update binaries for future updates..." -ForegroundColor Cyan
    $updateScript = @"
# Admin control
function IsAdministrator {
    `$user = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal `$user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
if (-not (IsAdministrator)) {
    Write-Host "`$((Get-Date).ToString(`"yyyy-MM-dd HH:mm:ss`"))  Please run this script with administrative privileges..." -ForegroundColor Cyan
    pause
    exit
}
`$coinPath = "`$env:ProgramFiles (x86)\RaptoreumCore"
#Show versions
`$FilePath = "`$coinPath\raptoreumd.exe"
`$fileVersionInfo = Get-Item `$FilePath -ErrorAction SilentlyContinue| Get-ItemProperty | Select-Object -ExpandProperty VersionInfo
`$fileVerion = `$fileVersionInfo.ProductVersion
`$uri = "https://api.github.com/repos/Raptor3um/raptoreum/releases/latest"
`$response = Invoke-RestMethod -Uri `$uri
`$latestVersion = `$response.tag_name
if (Test-Path `$coinPath) {
    if (`$fileVerion -ne `$latestVersion) {
            Write-Host "Your Smartnode version is            : `$fileVerion" -ForegroundColor Yellow
    } 
    else {
        Write-Host "Your Smartnode version is            : `$fileVerion" -ForegroundColor Green
    }
}
else {
    Write-Host "Your Smartnode version is            : Not found" -ForegroundColor Yellow
}
Write-Host "Last RaptoreumCore version available : `$latestVersion" -ForegroundColor Green
Write-Host "Download link: https://github.com/Raptor3um/raptoreum/releases/tag/`$latestVersion" -ForegroundColor Yellow
# Confirm update
`$confirmUpdate = Read-Host " Do you really want to update your SmartNode ? (y/n)"
if (`$confirmUpdate.ToLower() -eq "y") {
    Write-Host "Stopping $serviceName..." -ForegroundColor Yellow
    Stop-Service -Name $serviceName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    # Check if the wallet process is running and kill it if it is
    `$walletProcess = Get-Process "raptoreumd" -ErrorAction SilentlyContinue
    if (`$walletProcess) {
        Write-Host "Stopping the running raptoreumd process..." -ForegroundColor Yellow
        Stop-Process "raptoreumd" -Force
    } else {
        Write-Host "No Raptoreum process detected..." -ForegroundColor Yellow
    }
    Write-Host "Deleting existing RaptoreumSmartnode binaries..." -ForegroundColor Yellow
    `$files = @("raptoreum-cli.exe", "raptoreum-qt.exe", "raptoreum-tx.exe", "raptoreumd.exe", "checksum.txt")
    `$filesExist = `$false
    foreach (`$file in `$files) {
        if (Test-Path `$file) {
            `$filesExist = `$true
            break
        }
    }
    if (`$filesExist) {
        foreach (`$file in `$files) {
            if (Test-Path `$file) {
                Remove-Item `$file -Force -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host "Installing latest binaries..." -ForegroundColor Yellow
    `$uri = "https://api.github.com/repos/Raptor3um/raptoreum/releases/latest"
    `$response = Invoke-RestMethod -Uri `$uri
    `$latestVersion = `$response.tag_name
    `$walletUrl = "https://github.com/Raptor3um/raptoreum/releases/download/`$latestVersion/raptoreum-win-`$latestVersion.zip"
    Write-Host "Downloading..." -ForegroundColor Yellow
    Start-BitsTransfer -Source `$walletUrl -Destination "`$coinPath\raptoreum.zip" -DisplayName "Downloading binaries from `$walletUrl"
    Write-Host "Unzipping..." -ForegroundColor Yellow
    Expand-Archive -Path "`$coinPath\raptoreum.zip" -DestinationPath `$coinPath -ErrorAction SilentlyContinue -Force
    Write-Host "Starting $serviceName..." -ForegroundColor Yellow
    Start-Service -Name $serviceName -ErrorAction SilentlyContinue
    Write-Host "Binaries updated to v`$latestVersion successfully..." -ForegroundColor Green
} else {
Write-Host "Skipping update..." -ForegroundColor Yellow
}
pause
"@
    $updateBatch = @"
@echo off
powershell.exe -ExecutionPolicy Bypass -File "%USERPROFILE%\update_testnet.ps1"
"@
    Set-Content -Path "$env:USERPROFILE\update_testnet.bat" -Value $updateBatch
    Set-Content -Path "$env:USERPROFILE\update_testnet.ps1" -Value $updateScript
    Write-CurrentTime; Write-Host "  Script created: `%USERPROFILE%\update_testnet.bat..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

function Dashboard-Script {
    Write-CurrentTime; Write-Host "  Creating the Dashboard script..." -ForegroundColor Cyan
    $dashboard = @"
function Get-DataColor(`$condition, `$trueColor = 'Green', `$falseColor = 'Yellow') {
    if (`$condition) { return `$trueColor } else { return `$falseColor }
}
function Display-Information(`$message, `$value, `$color = 'Green') {
    Write-Host "`$message : `$value" -ForegroundColor `$color
}
`$first = `$true
while (`$true) {
    if (`$first) {        
        Write-Host "----------------------------------" -ForegroundColor Cyan
        Write-Host "Raptoreum Dashboard Pro 9000 Plus" -ForegroundColor Yellow
        Write-Host "----------------------------------" -ForegroundColor cyan
        Write-Host 'Gathering informations... ' -ForegroundColor Green
        Write-Host 'This will take a few seconds...' -ForegroundColor Green
        Write-Host 'Please, be patient...' -ForegroundColor Green
    }
    # Get informations
    `$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    `$blockHeight = cmd /C "`$env:traptoreumcli getblockcount" | ConvertFrom-Json
    if (`$first) {Write-Host "Retrieved blockHeight............."  -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$mempoolInfo = cmd /C "`$env:traptoreumcli getmempoolinfo" | ConvertFrom-Json
    if (`$first) {Write-Host "Retrieved getmempoolinfo.........." -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$getnettotals = cmd /C "`$env:traptoreumcli getnettotals" | ConvertFrom-Json
    if (`$first) {Write-Host "Retrieved getnettotals............" -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$connectionCount = cmd /C "`$env:traptoreumcli getconnectioncount" | ConvertFrom-Json
    if (`$first) {Write-Host "Retrieved getconnectioncount......" -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$smartnodeTotal = cmd /C "`$env:traptoreumcli smartnodelist status"
    if (`$first) {Write-Host "Retrieved smartnodelist status...." -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$smartnodeList = `$smartnodeTotal | Where-Object { `$_ -like "*ENABLED*" }
    if (`$first) {Write-Host "Retrieved enabled smartnodes......" -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$smartnodeStatus = cmd /C "`$env:traptoreumcli smartnode status" | ConvertFrom-Json
    if (`$first) {Write-Host "Retrieved smartnode status........" -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$networkHeight = (Invoke-WebRequest -Uri "https://testnet.raptoreum.com/api/getblockcount" -UseBasicParsing -ErrorAction SilentlyContinue).Content
    if (`$first) {Write-Host "Retrieved getblockcount..........." -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$smartnodeVersion = Get-Item "`$env:ProgramFiles (x86)\RaptoreumCore\raptoreumd.exe" -ErrorAction SilentlyContinue| Get-ItemProperty | Select-Object -ExpandProperty VersionInfo
    if (`$first) {Write-Host "Retrieved smartnode version......." -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$folderSize = Get-ChildItem "`$env:APPDATA\RaptoreumSmartnode\`$testnetfolder" -Recurse | Measure-Object -Property Length -Sum
    if (`$first) {Write-Host "Retrieved smartnode folder size..." -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$systemStabilityIndex = Get-WmiObject -Class Win32_ReliabilityStabilityMetrics | Select-Object -ExpandProperty SystemStabilityIndex -First 1
    if (`$first) {Write-Host "Retrieved system stability index.." -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$os = Get-CimInstance -ClassName Win32_OperatingSystem
    `$cpuUsage = (Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Processor | Where-Object { `$_.Name -eq "_Total" }).PercentProcessorTime
    `$drive = Get-Volume -DriveLetter (Split-Path -Qualifier `$env:APPDATA\RaptoreumSmartnode)[0]
    `$ostime = Get-WmiObject -Class Win32_OperatingSystem
    `$uptime = (Get-Date) - `$ostime.ConvertToDateTime(`$ostime.LastBootUpTime)
    if (`$first) {Write-Host "Retrieved computer infos.........." -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$lastPaidBlockHash = cmd /C "`$env:traptoreumcli getblockhash `$(`$smartnodeStatus.dmnState.lastPaidHeight)"
    if (`$first) {Write-Host "Retrieved last paid block hash...." -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$lastPaidBlock = cmd /C "`$env:traptoreumcli getblock `$lastPaidBlockHash" | ConvertFrom-Json
    if (`$first) {Write-Host "Retrieved last paid block........." -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    if (`$lastPaidBlock.tx -ne `$null -and `$lastPaidBlock.tx.Count -gt 0) {
        `$smartnodeRewardTx = cmd /C "`$env:traptoreumcli getrawtransaction `$(`$lastPaidBlock.tx[0]) 1" | ConvertFrom-Json
    } else {
        `$smartnodeRewardTx = `$null
    }
    if (`$first) {Write-Host "Retrieved smartnode reward........" -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$latest = Invoke-RestMethod -Uri "https://api.github.com/repos/Raptor3um/raptoreum/releases/latest" -ErrorAction SilentlyContinue
    if (`$first) {Write-Host "Retrieved latest version.........." -NoNewline -ForegroundColor cyan; Write-Host "√" -ForegroundColor Green}
    `$first = `$false
    `$stopwatch.Stop()

    # Display informations
    Clear-Host
    Write-Host "----------------------------------" -ForegroundColor Cyan
    Write-Host "Raptoreum Dashboard Pro 9000 Plus" -ForegroundColor Yellow
    Write-Host "----------------------------------" -ForegroundColor Cyan
    Display-Information 'Local/Network block height...' "`$blockHeight/`$networkHeight" -Color `$(Get-DataColor ([Math]::Abs(`$blockHeight - `$networkHeight) -lt 3))
    Display-Information 'Active/Total Smartnodes......' "`$(`$smartnodeList.count)/`$(`$smartnodeTotal.count) (`$(((`$smartnodeList.count / `$smartnodeTotal.count) * 100).ToString("F1"))%)"
    Display-Information 'Mempool (tx/size)............' "`$(`$mempoolInfo.size) tx / `$([math]::Round(`$mempoolInfo.bytes / 1MB, 3)) Mb"
    Display-Information 'Local/Available version......' "`$(`$smartnodeVersion.ProductVersion) / `$(`$latest.tag_name)" -Color `$(Get-DataColor (`$smartnodeVersion.ProductVersion -eq `$latest.tag_name))
    Write-Host "----------------------------------" -ForegroundColor Cyan
    Display-Information 'Smartnode status.............' "`$(`$smartnodeStatus.status)" -Color `$(Get-DataColor (`$smartnodeStatus.status -match 'Ready'))
    Display-Information 'Smartnode connections........' "`$(`$connectionCount)" -Color `$(Get-DataColor (`$connectionCount -gt 8))
    Display-Information 'Smartnode folder size .......' "`$([math]::Round(`$folderSize.sum / 1GB, 2)) Gb"
    if (`$smartnodeList -eq `$null -or `$smartnodeList.count -eq 0) {
        Display-Information 'Estimated reward per day.....' "N/A"
    } else {
        Display-Information 'Estimated reward per day.....' "`$([Math]::Round((1440 / `$smartnodeList.count) * 1000, 2)) RTM (+ fees)"
    }
    if (`$lastPaidBlock -ne `$null) {
        `$lastPaidTime = [DateTimeOffset]::FromUnixTimeSeconds(`$lastPaidBlock.time).ToLocalTime().DateTime
        `$timeElapsedDisplay = "{0}d {1}h {2}m" -f `$((Get-Date) - `$lastPaidTime).Days, `$((Get-Date) - `$lastPaidTime).Hours, `$((Get-Date) - `$lastPaidTime).Minutes
        Display-Information 'Since last payment...........' "`$timeElapsedDisplay"}else{Display-Information 'Since last payment............: N/A'
    }
    Display-Information 'IP address and port..........' `$(`$smartnodeStatus.service)
    Display-Information 'Smartnode ProTX..............' ((Get-Content "`$env:USERPROFILE\check_testnet.ps1" | Where-Object { `$_ -like "*NODE_PROTX =*" }) -replace ".*NODE_PROTX\s*=\s*", "" -replace '^"|"`$', '')
    Display-Information 'Smartnode BLS Key............' ((Get-Content "`$env:APPDATA\RaptoreumSmartnode\`$testnetfolder\raptoreum_testnet.conf" | Where-Object { `$_ -like "smartnodeblsprivkey=*" }) -replace "smartnodeblsprivkey=", "")
    Display-Information 'Payout address...............' `$(`$smartnodeStatus.dmnState.payoutAddress)
    Display-Information 'Registered height............' `$(`$smartnodeStatus.dmnState.registeredHeight)
    Display-Information 'PoSe score (Time to 0).......' "`$(`$smartnodeStatus.dmnState.PoSePenalty) (`$([math]::Floor((`$smartnodeStatus.dmnState.PoSePenalty) * 2 / 60))h `$(`$smartnodeStatus.dmnState.PoSePenalty * 2 % 60)min)" -Color `$(Get-DataColor (`$smartnodeStatus.dmnState.PoSePenalty -eq 0))
    Display-Information 'PoSe ban/revived height......' "`$(`$smartnodeStatus.dmnState.PoSeBanHeight) / `$(`$smartnodeStatus.dmnState.PoSeRevivedHeight)"
    Write-Host "----------------------------------" -ForegroundColor Cyan
    Display-Information 'System stability index.......' "`$([Math]::Round(`$systemStabilityIndex,1))/10" -Color `$(Get-DataColor (`$systemStabilityIndex -eq 10))
    Display-Information 'System uptime................' `$("{0}d {1}h {2}m" -f `$uptime.Days, `$uptime.Hours, `$uptime.Minutes)
    Display-Information 'CPU usage....................' "`$cpuUsage %" -Color `$(Get-DataColor (`$cpuUsage -lt 90))
    Display-Information 'RAM usage....................' "`$([math]::Round((`$os.TotalVisibleMemorySize - `$os.FreePhysicalMemory) / 1024 / 1024, 2))/`$([math]::Round(`$os.TotalVisibleMemorySize / 1024 / 1024, 2)) GB (`$([math]::Round(((`$os.TotalVisibleMemorySize - `$os.FreePhysicalMemory) / `$os.TotalVisibleMemorySize * 100), 0))% used)" -Color `$(Get-DataColor (((`$os.TotalVisibleMemorySize - `$os.FreePhysicalMemory) / `$os.TotalVisibleMemorySize * 100) -lt 90))
    Display-Information 'Disk usage (Free/Total)......' "`$([math]::Round((`$drive.SizeRemaining / 1GB), 2))/`$([math]::Round((`$drive.Size / 1GB), 2)) GB (`$([math]::Round((1 - (`$drive.SizeRemaining / `$drive.Size)) * 100, 0))% used)" -Color `$(Get-DataColor ((1 - (`$drive.SizeRemaining / `$drive.Size)) * 100 -lt 90))
    Display-Information 'Total received...............' "`$([math]::Round(`$getnettotals.totalbytesrecv / 1MB)) Mb"
    Display-Information 'Total sent...................' "`$([math]::Round(`$getnettotals.totalbytessent / 1MB, 0)) Mb"
    Write-Host "Loaded in `$(`$stopwatch.Elapsed.Seconds) sec"

    # Countdown to refresh
    `$spinner = @('|', '/', '-', '\')
    `$spinnerPos = 0
    `$endTime = (Get-Date).AddSeconds(30)
    while ((Get-Date) -lt `$endTime) {
        `$remainingSeconds = [math]::Ceiling((`$endTime - (Get-Date)).TotalSeconds)
        Write-Host -NoNewline "`r`$(`$spinner[`$spinnerPos % 4]) Refresh in `$("{0:00}" -f `$remainingSeconds)" -BackgroundColor White -ForegroundColor Black
        `$spinnerPos++
        Start-Sleep -Seconds 1
    } Write-Host -NoNewline "`r * Refreshing..."
}
"@
    $dashboardBatch = @"
@echo off
powershell.exe -ExecutionPolicy Bypass -File "%USERPROFILE%\dashboard_testnet.ps1"
"@
    Set-Content -Path "$env:USERPROFILE\dashboard_testnet.ps1" -Value $dashboard -Encoding UTF8 -ErrorAction SilentlyContinue -Force
    Set-Content -Path "$env:USERPROFILE\dashboard_testnet.bat" -Value $dashboardBatch -ErrorAction SilentlyContinue -Force
    Write-CurrentTime; Write-Host "  Script created: `%USERPROFILE%\dashboard_testnet.ps1..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

function Create-Service {
    if (-not (Get-Service -Name $serviceName -ErrorAction SilentlyContinue)) {
        Install-NSSM
        $ExecutablePath = "$coinPath\raptoreumd.exe"
        $Arguments = "-testnet -datadir=$configDir -conf=$configPath"
        $NSSM_exe = "$env:UserProfile\nssm-2.24\win64\nssm.exe"
        Write-CurrentTime; Write-Host "  Creating $serviceName with NSSM..." -ForegroundColor Cyan
        & $NSSM_exe install $serviceName $ExecutablePath $Arguments | Out-Null
        Write-CurrentTime; Write-Host "  Setting $serviceName to start automatically..." -ForegroundColor Yellow
        & $NSSM_exe set $serviceName Start SERVICE_AUTO_START | Out-Null
        Write-CurrentTime; Write-Host "  $serviceName has been created successfully." -ForegroundColor Yellow
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if (-not $Null -eq $service) {
            Write-CurrentTime; Write-Host "  Starting daemon service & syncing chain please be patient this will take few moment (10s)..." -ForegroundColor Cyan
            Start-Service $serviceName -ErrorAction Continue
            Start-Sleep -Seconds 10
            Write-CurrentTime; Write-Host "  Getting blockchain info (%traptoreumclites% getblockchaininfo)..." -ForegroundColor Yellow
            cmd /C "$global:CLI getblockchaininfo" 2>&1
            Write-CurrentTime; Write-Host "  Getting smartnode status (%traptoreumcli% smartnode status)..." -ForegroundColor Yellow
            cmd /C "$global:CLI smartnode status" 2>&1
        } else {
            Write-CurrentTime; Write-Host "  Something is not right, the daemon did not start. Will exit out so try and run the script again..." -ForegroundColor Red
            pause
            exit
        }
        Write-CurrentTime; Write-Host "  $serviceName has been created and started successfully..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 1
}

$global:securityAns = ""
function Basic-Security {
    # If $QuickSetup is provided, just ask about basic security.
    param(
        [string]$QuickSetup
    )    
    if (-not [string]::IsNullOrEmpty($QuickSetup)) {
        do {
            $result = Read-Host -Prompt "Would you like to setup basic firewall? (y/n) "
            if ($result -eq "y" -or $result -eq "") {
                $global:securityAns = 1
                $validInput = $true
            } elseif ($result -eq "n") {
                $validInput = $true
            } else {
                Write-Host "  Please enter 'y', 'n' or leave empty for 'y'..." -ForegroundColor Yellow
                $validInput = $false
            }
        } while (-not $validInput)
        return
    }
    if ($global:securityAns -eq "1") {
        Write-CurrentTime; Write-Host "  Configuring firewall..." -ForegroundColor Cyan
        # Allow SSH and RTM ports
        New-NetFirewallRule -DisplayName "Allow SSH" -Direction Inbound -LocalPort $global:sshPort -Protocol TCP -Action Allow | Out-Null
        New-NetFirewallRule -DisplayName "Allow Testnet RTM" -Direction Inbound -LocalPort "10230" -Protocol TCP -Action Allow | Out-Null
        #New-NetFirewallRule -DisplayName "Allow Raptoreumd" -Direction Inbound -Program "C:\program files (x86)\raptoreumcore\raptoreumd.exe" -Action Allow -Protocol TCP -LocalPort 10230 | Out-Null
        #Set-NetFirewallRule -Name "Allow Raptoreumd" -Profile Any | Out-Null
        Write-CurrentTime; Write-Host "  Firewall configured successfully." -ForegroundColor Yellow
    } else {
        Write-CurrentTime; Write-Host "  Skipping basic security..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 1
}

$global:protxHash = ""
function Schedule-Jobs {
    # If $QuickSetup is provided, just ask about ProTx Hash.
    param (
        [string]$QuickSetup
    )
    $checkScriptPath = "$env:USERPROFILE\check_testnet.bat"
    $chainbackupScriptPath = "$env:USERPROFILE\chainbackup_testnet.bat"
    if (-not [string]::IsNullOrEmpty($QuickSetup)) {
        do {
            $global:protxHash = Read-Host -Prompt "Please enter your protx hash for this SmartNode (txid)"
            if ($global:protxHash.Length -ne 64) {
                Write-Host "  The proTX must be 64 characters long, please check your proTX..." -ForegroundColor Yellow
            }
        } until ($global:protxHash.Length -eq 64)
        return
    }
    $checkUrl = "https://raw.githubusercontent.com/wizz13150/Raptoreum_SmartNode/main/check_testnet.ps1"
    Start-BitsTransfer -Source $checkUrl -Destination "$env:USERPROFILE\check_testnet.ps1" -DisplayName "Downloading file from $checkUrl"
    # Replace NODE_PROTX value in check_testnet.ps1
    (Get-Content "$env:USERPROFILE\check_testnet.ps1").Replace('#NODE_PROTX=', "`$NODE_PROTX = `"$global:protxHash`"") | Set-Content "$env:USERPROFILE\check_testnet.ps1"
    # Create scheduled tasks
    Write-CurrentTime; Write-Host "  Creating scheduled tasks..." -ForegroundColor cyan
    $checkTaskName = "RTMCheck_testnet"
    $chainBackupTaskName = "RTMChainBackup_testnet"
    Unregister-ScheduledTask -TaskName $checkTaskName -Confirm:$false -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $chainBackupTaskName -Confirm:$false -ErrorAction SilentlyContinue
    # Create trigger for Check task (every 20 minutes)
    $checkTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddMinutes(20) -RepetitionInterval (New-TimeSpan -Minutes 20)
    # Create trigger for ChainBackup task (weekly)
    $chainBackupTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Wednesday -WeeksInterval 1 -At 03:00
    $checkLog = "$env:USERPROFILE\check-testnet.log"
    $bootstrapLog = "$env:USERPROFILE\bootstrap-testnet.log"
    $checkAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-Command `"Start-Process cmd.exe -ArgumentList '/c `"$checkScriptPath`"' -Verb RunAs`" > `"$checkLog`""
    $chainBackupAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-Command `"Start-Process cmd.exe -ArgumentList '/c `"$chainbackupScriptPath`"' -Verb RunAs`" > `"$bootstrapLog`""
    $User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $Principal = New-ScheduledTaskPrincipal -UserID $User -LogonType S4U -RunLevel Highest
    # Timeout before next task
    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 18)
    Register-ScheduledTask -TaskName $checkTaskName -Trigger $checkTrigger -Action $checkAction -Principal $Principal -Settings $settings | Out-Null
    Register-ScheduledTask -TaskName $chainBackupTaskName -Trigger $chainBackupTrigger -Action $chainBackupAction -Principal $Principal -Settings $settings | Out-Null
    Write-CurrentTime; Write-Host "  Scheduled tasks successfully created..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

function Log-Rotate {
    Install-LogrotateWin
    $logrotateConfig = @"
# Debug.log configuration
$configDir\debug.log {
    compress
    copytruncate
    missingok
    daily
    rotate 7
}
# Bootstrap.log configuration
$env:USERPROFILE\bootstrap_testnet.log {
    size 1000k
    copytruncate
    missingok
    rotate 0
}
# Check.log configuration
$env:USERPROFILE\check_testnet.log {
    size 1000k
    compress
    copytruncate
    missingok
    rotate 3
}
"@
    Write-CurrentTime; Write-Host "  Configuring logrotate function for debug log..." -ForegroundColor Yellow
    $logrotateConfigPath = "$env:USERPROFILE\LogrotateWin\Content\rtmdebuglogrotate_testnet.conf"
    if (Test-Path $logrotateConfigPath) {
        Write-CurrentTime; Write-Host "  Existing log rotate conf found, backing up to ~/rtmdebuglogrotate.old ..." -ForegroundColor Yellow
        Move-Item $logrotateConfigPath "$env:USERPROFILE\LogrotateWin\Content\rtmdebuglogrotate_testnet.old" -ErrorAction SilentlyContinue -Force
    }
    $logrotateConfig | Out-File -FilePath $logrotateConfigPath -Encoding utf8 -Force
    Start-Sleep -Seconds 1
}

function Create-MOTD {
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host " COURTESY OF DK808 FROM ALTTANK ARMY" -ForegroundColor Cyan
    Write-Host " Smartnode healthcheck by Delgon" -ForegroundColor Cyan
    Write-Host " Adapted to Windows by Wizz" -ForegroundColor Cyan
    Write-Host "" 
    Write-Host " Commands to manage $serviceName(deamon) with cmd :" -ForegroundColor Yellow
    Write-Host "   TO START -  Net Start $serviceName" -ForegroundColor Cyan
    Write-Host "   TO STOP  -  Net Stop $serviceName" -ForegroundColor Cyan
    Write-Host "   STATUS   -  SC Query $serviceName" -ForegroundColor Cyan
    Write-Host " In the event server reboots, the daemon service will auto-start"
    Write-Host ""
    Write-Host ' To use raptoreum-cli with cmd, simply start a command with %traptoreumcli% :' -ForegroundColor Yellow
    Write-Host '   E.g     %traptoreumcli% getblockchaininfo' -ForegroundColor Cyan
    Write-Host '   E.g     %traptoreumcli% smartnode status' -ForegroundColor Cyan
    Write-Host ""
    Write-Host " To manage the Smartnode, launch 'SmartnodeBash_testnet' on the desktop" -ForegroundColor Yellow
    Write-Host " To update the Smartnode, launch 'UpdateSmartnode_testnet' on the desktop" -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host ' Remember to always encrypt your wallet with a strong password !' -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor Yellow

    $MOTD = @"
================================================================================
  SMARTNODE BASH for Testnet
================================================================================
  COURTESY OF DK808 FROM ALTTANK ARMY
  Smartnode healthcheck by Delgon
  Adapted to Windows by Wizz

  Commands to manage $serviceName(deamon) with cmd :
    TO START -  Net Start $serviceName
    TO STOP  -  Net Stop $serviceName
    STATUS   -  SC Query $serviceName
  In the event server reboots, the daemon service will auto-start

  To use raptoreum-cli with cmd, simply start a command with %traptoreumcli% :
    E.g:   %traptoreumcli% getblockchaininfo
    E.g:   %traptoreumcli% smartnode status

  To update the Smartnode, launch 'UpdateSmartnode_testnet' on the desktop
================================================================================
  Remember to always encrypt your wallet with a strong password !
================================================================================
"@
    $bash = @"
@echo off
start cmd.exe /k "type %USERPROFILE%\RTM-MOTD_testnet.txt"
"@
    $checkBash = @"
@echo off
powershell.exe -ExecutionPolicy RemoteSigned -File %USERPROFILE%\check_testnet.ps1"
"@
    $backupBash = @"
@echo off
powershell.exe -ExecutionPolicy RemoteSigned -File %USERPROFILE%\chainbackup_testnet.ps1"
"@
    $backupPath = "$env:USERPROFILE\chainbackup_testnet.bat"
    Set-Content -Path $backupPath -Value $backupBash -ErrorAction SilentlyContinue -Force
    $batchPath = "$env:USERPROFILE\check_testnet.bat"
    Set-Content -Path $batchPath -Value $checkBash -ErrorAction SilentlyContinue -Force
    $MOTDPath = "$env:USERPROFILE\RTM-MOTD_testnet.txt"
    Set-Content -Path $MOTDPath -Value $MOTD -ErrorAction SilentlyContinue -Force
    $bashPath = "$env:USERPROFILE\SmartNodeBash_testnet.bat"
    Set-Content -Path $bashPath -Value $bash -ErrorAction SilentlyContinue -Force
}

# Clean the environment from possibly previous setup.
Wipe-Clean
Environment-Variable
KeepWindows-Up

# Ask about things first for quick setup.
Get-SSHPort
Confirm-IP
Create-Conf -QuickSetup $true
Basic-Security -QuickSetup $true
Bootstrap-Chain -QuickSetup $true
Schedule-Jobs -QuickSetup $true

# Run functions
Install-7Zip
Install-Bins
Create-Conf
Bootstrap-Chain
Chain-Backup
Basic-Security
Create-Service
Schedule-Jobs
Log-Rotate
Update-Script
Dashboard-Script
Create-Shortcuts
Create-MOTD

pause
