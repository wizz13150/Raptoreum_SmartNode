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
$BOOTSTRAP_ZIP = "https://bootstrap.raptoreum.com/bootstraps/bootstrap.zip"
$CONFIG_DIR = "$env:APPDATA\RaptoreumSmartnode"
$COIN_PATH = "$env:ProgramFiles (x86)\RaptoreumCore"
$configPath = Join-Path $CONFIG_DIR "raptoreum.conf"
$bootstrapZipPath = Join-Path $env:APPDATA "\bootstrap\bootstrap.zip"


Write-Host "===========================================================" -ForegroundColor Yellow 
Write-Host " RTM Smartnode Setup" -ForegroundColor Yellow 
Write-Host "===========================================================" -ForegroundColor Yellow 
Write-Host ""
Write-Host " July 2021, created and updated by dk808 from AltTank" -ForegroundColor Cyan 
Write-Host " With Smartnode healthcheck by Delgon" -ForegroundColor Cyan
Write-Host " March 2023, adapted to Windows by Wizz" -ForegroundColor Cyan
Write-Host ""
Write-Host "================================================================================================" -ForegroundColor Yellow
Write-Host " Remember to always encrypt your wallet with a strong password !" -ForegroundColor Yellow 
Write-Host "================================================================================================" -ForegroundColor Yellow
Write-Host " Node setup starting, press [CTRL-C] to cancel..." -ForegroundColor Cyan 
Start-Sleep -Seconds 1

# Because windows.. Disable sleep & cie.. Always up
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -change -standby-timeout-ac 0
powercfg -change -standby-timeout-dc 0
powercfg -change -disk-timeout-ac 0
powercfg -change -disk-timeout-dc 0
powercfg -h off

function Write-CurrentTime {
    Write-Host ('[' + (Get-Date).ToString("HH:mm:ss") + ']') -NoNewline
}

function Wipe-Clean {
    Write-CurrentTime; Write-Host "  Removing any previous instance of Smartnode (with this script)..." -ForegroundColor Yellow
    Stop-Service -Name "RTMService" -ErrorAction SilentlyContinue -Force
    if (Get-Service -Name "RTMService" -ErrorAction SilentlyContinue) {
        sc.exe delete "RTMService" | Out-Null
    }
    Get-ChildItem -Path "$CONFIG_DIR\*" -Exclude "nodetest" -ErrorAction SilentlyContinue | Remove-Item -Recurse -ErrorAction SilentlyContinue -Force
    [Environment]::SetEnvironmentVariable("raptoreumcli", "$null", "Machine")
}
$files = @(
    "$env:USERPROFILE\update.ps1", "$env:USERPROFILE\check.ps1",
    "$env:USERPROFILE\check.bat", "$env:USERPROFILE\chainbackup.ps1",
    "$env:USERPROFILE\chainbackup.bat", "$env:USERPROFILE\RTM-MOTD.txt",
    "$env:USERPROFILE\SmartNodeBash.bat", "$env:USERPROFILE\rtmdebuglogrotate.conf",
    "$env:UserProfile\height.tmp", "$env:UserProfile\prev_stuck.tmp",
    "$env:UserProfile\was_stuck.tmp", "$env:UserProfile\pose_score.tmp"
)
foreach ($file in $files) {
    if (Test-Path $file) {
        Remove-Item -Path $file -ErrorAction SilentlyContinue -Force
    }
}

$global:CLI = ""
function Environment-Variable {
    Write-CurrentTime; Write-Host "  Set %raptoreumcli% as environment variable..." -ForegroundColor Cyan
    # Env vars
    $envPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $newPath = "C:\Program Files (x86)\RaptoreumCore"
    if (-not ($envPath.Contains($newPath))) {
        [Environment]::SetEnvironmentVariable("Path", "$envPath;$newPath", "Machine")
    }
    $global:CLI = "`"$((Join-Path $COIN_PATH "raptoreum-cli.exe"))`" -datadir=`"$CONFIG_DIR`" -conf=`"$CONFIG_DIR\raptoreum.conf`""
    [Environment]::SetEnvironmentVariable("raptoreumcli", "$CLI", "Machine")
}

function Install-7Zip {
    $7zipKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\7zFM.exe"
    if (Test-Path $7zipKey) {
        Write-CurrentTime; Write-Host "  7-Zip is already installed..." -ForegroundColor Yellow
    } else {
        $7zipInstallerUrl = "https://www.7-zip.org/a/7z1900-x64.msi"
        $7zipInstallerPath = Join-Path $env:USERPROFILE "7z_installer.msi"
        Write-CurrentTime; Write-Host "  Downloading 7-Zip installer..." -ForegroundColor Cyan
        Start-BitsTransfer -Source $7zipInstallerUrl -Destination $7zipInstallerPath -DisplayName "Downloading 7-Zip installer from $7zipInstallerUrl"
        Write-CurrentTime; Write-Host "  Installing 7-Zip..." -ForegroundColor Yellow
        $msiArguments = @{
        FilePath     = "msiexec.exe"
        ArgumentList = "/i `"$7zipInstallerPath`" /qn"
        Wait         = $true
        Verb         = "RunAs"
    }
    Start-Process @msiArguments -ErrorAction SilentlyContinue
    Remove-Item $7zipInstallerPath -ErrorAction SilentlyContinue -Force
    Write-CurrentTime; Write-Host "  7-Zip installed successfully..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 1
}

function Check-BootstrapZipChecksum {
    Write-CurrentTime; Write-Host "  Checksum verification of bootstrap.zip, please be patient..." -ForegroundColor Cyan
    Write-CurrentTime; Write-Host "  Source: https://checksums.raptoreum.com/checksums/bootstrap-checksums.txt" -ForegroundColor Yellow
    $uri = "https://api.github.com/repos/Raptor3um/raptoreum/releases/latest"
    $response = Invoke-RestMethod -Uri $uri
    $latestVersion = $response.tag_name
    $checksumsUrl = "https://checksums.raptoreum.com/checksums/bootstrap-checksums.txt"
    $checksums = Invoke-WebRequest -Uri $checksumsUrl -UseBasicParsing
    $remoteChecksum = ($checksums.Content.Split("`n") | Select-String -Pattern "v$latestVersion/no-index/bootstrap.zip").ToString().Split(" ")[0].Trim()
    Write-CurrentTime; Write-Host "  Checksum: $remoteChecksum" -ForegroundColor Yellow
    $localChecksum = (Get-FileHash -Path $($bootstrapZipPath) -Algorithm SHA256 | Select-Object -ExpandProperty Hash).ToLower()
    if ($localChecksum -eq $remoteChecksum) {
        Write-CurrentTime; Write-Host "  Checksum verification successful. The bootstrap is authentic." -ForegroundColor Cyan
        Write-CurrentTime; Write-Host "  Local Checksum  : $($localChecksum)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host "  Online Checksum : $($remoteChecksum)" -ForegroundColor Yellow
    } else {
        Write-CurrentTime; Write-Host "  Checksum verification failed. The bootstrap may have been modified, consider to delete it. Or the script may be outdated." -ForegroundColor Yellow
        Write-CurrentTime; Write-Host "  Local Checksum  : $($localChecksum)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host "  Online Checksum : $($remoteChecksum)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host "  Stopping the script..." -ForegroundColor Red
        pause
        exit
    }
}

function Extract-Bootstrap {
    Write-CurrentTime; Write-Host "  Extracting bootstrap from: $bootstrapZipPath..." -ForegroundColor Yellow
    Write-CurrentTime; Write-Host "  Extracting bootstrap to  : $CONFIG_DIR..." -ForegroundColor Yellow
    $zipProgram = ""
    $7zipKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\7zFM.exe"
    if (Test-Path $7zipKey) {
        $zipProgram = (Get-ItemProperty $7zipKey).'Path' + "7z.exe"
    }
    if ($zipProgram) {
        Write-CurrentTime; Write-Host "  7-Zip detected, using 7-Zip to extract the bootstrap. Faster..." -ForegroundColor Cyan
        & "$zipProgram" x $bootstrapZipPath -o"$CONFIG_DIR" -y
    } else {
        Write-CurrentTime; Write-Host "  7-Zip not detected, using 'Expand-Archive' to extract the bootstrap. Slower..." -ForegroundColor Cyan
        Expand-Archive -Path $bootstrapZipPath -DestinationPath $CONFIG_DIR -ErrorAction SilentlyContinue -Force
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
    $LogrotateWinUrl = "https://sourceforge.net/projects/logrotatewin/files/latest/download"
    $LogrotateWinPath = "$env:TEMP\logrotatewin.zip"
    $LogrotateWinExtractPath = "$env:UserProfile\LogrotateWin"
    $LogrotateWinExtracted = Test-Path -Path "$LogrotateWinExtractPath\LogrotateWin.exe"
    if ($LogrotateWinExtracted) {
        Write-CurrentTime; Write-Host "  LogrotateWin already installed..." -ForegroundColor Yellow
    } else {
        Write-CurrentTime; Write-Host "  Downloading and installing LogrotateWin ..." -ForegroundColor Cyan
        Start-BitsTransfer -Source $LogrotateWinUrl -Destination $LogrotateWinPath -DisplayName "Downloading LogrotateWin from $LogrotateWinUrl"
        Write-CurrentTime; Write-Host "  Extracting LogrotateWin to $LogrotateWinExtractPath" -ForegroundColor Yellow
        Expand-Archive -Path $LogrotateWinPath -DestinationPath $LogrotateWinExtractPath -ErrorAction SilentlyContinue -Force
        Write-CurrentTime; Write-Host "  LogrotateWin installed successfully..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 1
}

function Create-Shortcuts {
    # Create SmartNodeBash.lnk
    $ShortcutPath = [Environment]::GetFolderPath("Desktop") + "\SmartNodeBash.lnk"
    Write-CurrentTime; Write-Host "  Creating a desktop shortcut..." -ForegroundColor Cyan
    $TargetPath = "cmd.exe"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetPath
    $Command = " /c `"$env:USERPROFILE\SmartNodeBash.bat`""
    $Shortcut.Arguments = $Command
    $Shortcut.IconLocation = "cmd.exe"
    $Shortcut.WorkingDirectory = [Environment]::GetFolderPath("Desktop")
    $Shortcut.Save()
    Write-CurrentTime; Write-Host "  $ShortcutPath created successfully..." -ForegroundColor Yellow
    # Create UpdateSmartnode.lnk
    $UpdateShortcutPath = [Environment]::GetFolderPath("Desktop") + "\UpdateSmartnode.lnk"
    Write-CurrentTime; Write-Host "  Creating a desktop shortcut for Update.bat..." -ForegroundColor Cyan
    $UpdateTargetPath = "powershell.exe"
    $UpdateShortcut = $WScriptShell.CreateShortcut($UpdateShortcutPath)
    $UpdateShortcut.TargetPath = $UpdateTargetPath
    $UpdateCommand = "-Command `"Start-Process cmd.exe -ArgumentList '/c `"$env:USERPROFILE\update.bat`"' -Verb RunAs`""
    $UpdateShortcut.Arguments = $UpdateCommand
    $UpdateShortcut.IconLocation = "cmd.exe"
    $UpdateShortcut.WorkingDirectory = [Environment]::GetFolderPath("Desktop")
    $UpdateShortcut.Save()
    Write-CurrentTime; Write-Host "  $UpdateShortcutPath created successfully..." -ForegroundColor Yellow
}

$global:SSHPORT = ""
function Get-SSHPort {
    Write-CurrentTime; Write-Host "  Detecting SSH port being used..." -ForegroundColor Yellow
    $sshdConfigPath = "$env:ProgramData\ssh\sshd_config"
    if (Test-Path $sshdConfigPath) {
        $content = Get-Content $sshdConfigPath
        $portLine = $content | Where-Object { $_ -match "^Port\s+\d+" }    
        if ($portLine -ne $null) {
            $global:SSHPORT = $portLine -replace "^Port\s+", ""
            Write-CurrentTime; Write-Host "  SSH Port: $($global:SSHPORT)" -ForegroundColor Yellow
        } else {
            $global:SSHPORT = 22
            Write-CurrentTime; Write-Host "  No port found in the configuration file. Default SSH port is $($global:SSHPORT)." -ForegroundColor Yellow
        }
    } else {
        $global:SSHPORT = 22
        Write-CurrentTime; Write-Host "  OpenSSH server configuration file not found. Default SSH port is $($global:SSHPORT)." -ForegroundColor Yellow
    }
    do {
        $useSSH = Read-Host -Prompt "Detected SSH port is $($global:SSHPORT), is this correct? (y/n) "
        if ($useSSH -eq "n") {
            $global:SSHPORT = Read-Host -Prompt "Enter SSH port "
        }
    } while ($useSSH -ne "y" -and $useSSH -ne "n" -and $useSSH -ne "")
    Start-Sleep -Seconds 1
}

$global:WANIP = ""
function Confirm-IP {
    Write-CurrentTime; Write-Host "  Detecting IP address being used..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    $global:WANIP = Invoke-WebRequest -Uri "http://ipecho.net/plain" -UseBasicParsing | Select-Object -ExpandProperty Content
    $useDetectedIP = Read-Host -Prompt "Detected IP address is $($global:WANIP), is this correct? (y/n) "
    if ($useDetectedIP -eq "n") {
        $global:WANIP = Read-Host -Prompt "Enter IP address "
    }
    Start-Sleep -Seconds 1
}

$global:smartnodeblsprivkey = ""
function Create-Conf {
    # If $QuickSetup is provided, just ask about BLS key.
    param(
        [string]$QuickSetup
    )
    # Force user to provide BLS key.
    if (-not [string]::IsNullOrEmpty($QuickSetup)) {
        while ([string]::IsNullOrEmpty($global:smartnodeblsprivkey)) {
            $global:smartnodeblsprivkey = Read-Host -Prompt "Enter your SmartNode BLS Privkey "
        }
        return
    }
    if (Test-Path $configPath) {
        Write-CurrentTime; Write-Host "  Existing conf file found backing up to Raptoreum.old ..." -ForegroundColor Yellow
        Move-Item -Path $configPath -Destination "$CONFIG_DIR\Raptoreum.old" -ErrorAction SilentlyContinue -Force
    }
    $RPCUSER = -join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_})
    $PASSWORD = -join ((65..90) + (97..122) | Get-Random -Count 20 | % {[char]$_})
    Write-CurrentTime; Write-Host "  Creating Conf File..." -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    if (-not (Test-Path $CONFIG_DIR)) {
        New-Item -ItemType Directory -Path $CONFIG_DIR | Out-Null
    }
    $configContent = @"
rpcuser=$RPCUSER
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
rpcbind=127.0.0.1
port=10226
server=1
listen=1
txindex=1
smartnodeblsprivkey=$global:smartnodeblsprivkey
externalip=$global:WANIP
maxconnections=125
dbcache=1024
onlynet=ipv4
addnode=lbdn.raptoreum.com
"@
    $configContent | Set-Content -Path $configPath
    Write-Host "$configPath created..."
    Start-Sleep -Seconds 1
}

function Install-Bins {
    Write-CurrentTime; Write-Host "  Installing latest binaries..." -ForegroundColor Cyan
    $uri = "https://api.github.com/repos/Raptor3um/raptoreum/releases/latest"
    $response = Invoke-RestMethod -Uri $uri
    $latestVersion = $response.tag_name
    $walletUrl = "https://github.com/Raptor3um/raptoreum/releases/download/$latestVersion/raptoreum-win-$latestVersion.zip"
    # Fetch the latest release using GitHub
    $process = Get-Process "raptoreumd" -ErrorAction SilentlyContinue
    if ($process) {
        Write-CurrentTime; Write-Host "  Raptoreum process detected..." -ForegroundColor Yellow
        $confirmation = ""
        do {
            $confirmation = Read-Host "Do you want to stop the process '$process' ? (y/n) "
            if ($confirmation -eq "y") {
                Stop-Process $process -ErrorAction SilentlyContinue -Force
                Write-CurrentTime; Write-Host "  Process has been stopped..." -ForegroundColor Yellow
            } elseif ($confirmation -eq "n") {
                Write-CurrentTime; Write-Host "  Process was not stopped, we can't install binaries..." -ForegroundColor Yellow
                return
            } else {
                Write-CurrentTime; Write-Host "  Please enter 'y' or 'n'..." -ForegroundColor Yellow
            }
        } while ($confirmation -ne "y" -and $confirmation -ne "n")
        if (-not (Test-Path $COIN_PATH)) {
            New-Item -Path $COIN_PATH -ItemType Directory | Out-Null
        }
        Write-CurrentTime; Write-Host "  Downloading latest binaries ($latestVersion)..." -ForegroundColor Yellow
        Start-BitsTransfer -Source $walletUrl -Destination "$COIN_PATH\raptoreum.zip" -DisplayName "Downloading binaries from $walletUrl"
        Write-CurrentTime; Write-Host "  Unzipping..." -ForegroundColor Yellow
        Expand-Archive -Path (Join-Path $COIN_PATH "raptoreum.zip") -DestinationPath $COIN_PATH -ErrorAction SilentlyContinue -Force
        Write-CurrentTime; Write-Host "  Removing..." -ForegroundColor Yellow
        Remove-Item -Path (Join-Path $COIN_PATH "raptoreum.zip") -Recurse -ErrorAction SilentlyContinue -Force
    } else {
        if (-not (Test-Path $COIN_PATH)) {
            New-Item -Path $COIN_PATH -ItemType Directory -ErrorAction SilentlyContinue -Force | Out-Null
        }
        Write-CurrentTime; Write-Host "  Downloading latest binaries ($latestVersion)..." -ForegroundColor Yellow
        Start-BitsTransfer -Source $walletUrl -Destination "$COIN_PATH\raptoreum.zip" -DisplayName "Downloading binaries from $walletUrl"
        Write-CurrentTime; Write-Host "  Unzipping..." -ForegroundColor Yellow
        Expand-Archive -Path (Join-Path $COIN_PATH "raptoreum.zip") -DestinationPath $COIN_PATH -ErrorAction SilentlyContinue -Force
        Write-CurrentTime; Write-Host "  Removing..." -ForegroundColor Yellow
        Remove-Item -Path (Join-Path $COIN_PATH "raptoreum.zip") -Recurse -ErrorAction SilentlyContinue -Force
    }
    Start-Sleep -Seconds 1
}

$global:BOOTSTRAP_ANS = ""
function Bootstrap-Chain {
        # If $QuickSetup is provided, just ask about bootstrap.
    param(
        [string]$QuickSetup
    )
    if (-not [string]::IsNullOrEmpty($QuickSetup)) {
        do {
            $prompt = Read-Host -Prompt "Would you like to bootstrap the chain? (y/n) "
            if ($prompt -eq "y" -or $prompt -eq "") {
                $global:BOOTSTRAP_ANS = 1
                $validInput = $true
            } elseif ($prompt -eq "n") {
                $validInput = $true
            } else {
                Write-Host "  Please enter 'y', 'n' or leave empty for 'y'..." -ForegroundColor Yellow
                $validInput = $false
            }
        } while (-not $validInput)
        return
    }
    if ($global:BOOTSTRAP_ANS -eq "1") {
        $localFile = Get-Item $bootstrapZipPath -ErrorAction SilentlyContinue
        $remoteFile = Invoke-WebRequest -Uri $BOOTSTRAP_ZIP -Method Head -UseBasicParsing
        $remoteLastModified = [datetime]::ParseExact($remoteFile.Headers.'Last-Modified', 'ddd, dd MMM yyyy HH:mm:ss \G\M\T', [System.Globalization.CultureInfo]::InvariantCulture)
        $remoteSize = $remoteFile.Headers.'Content-Length'
        if ($localFile.LastWriteTime -ge $remoteLastModified -and $localFile.Length -eq $remoteSize) {
            Write-CurrentTime; Write-Host "  The bootstrap.zip file is up to date." -ForegroundColor Yellow
            Write-CurrentTime; Write-Host "  Local Bootstrap    : Size: $(("{0:N2}" -f ($localFile.Length / 1GB))) GB, Date: $($localFile.LastWriteTime)" -ForegroundColor Yellow
            Write-CurrentTime; Write-Host "  Online Bootstrap   : Size: $(("{0:N2}" -f ($remoteSize / 1GB))) GB, Date: $($remoteLastModified)" -ForegroundColor Yellow
            Check-BootstrapZipChecksum
            Extract-Bootstrap
        } 
        else {
            Write-CurrentTime; Write-Host "  Your bootstrap is not up to date or incomplete." -ForegroundColor Yellow
            Write-CurrentTime; Write-Host "  Local Bootstrap    : Size: $(("{0:N2}" -f ($localFile.Length / 1GB))) GB, Date: $($localFile.LastWriteTime)" -ForegroundColor Yellow
            Write-CurrentTime; Write-Host "  Online Bootstrap   : Size: $(("{0:N2}" -f ($remoteSize / 1GB))) GB, Date: $($remoteLastModified)" -ForegroundColor Yellow
            if (-not (Test-Path -Path "$env:APPDATA\bootstrap")) {
                New-Item -ItemType Directory -Path "$env:APPDATA\bootstrap" -ErrorAction SilentlyContinue -Force | Out-Null
            }
            Write-CurrentTime; Write-Host "  Downloading the bootstrap, please be patient..." -ForegroundColor Cyan
            Start-BitsTransfer -Source $BOOTSTRAP_ZIP -Destination "$env:APPDATA\bootstrap\" -DisplayName "Downloading bootstrap from $BOOTSTRAP_ZIP"
            Check-BootstrapZipChecksum
            Extract-Bootstrap
        }
    }
    Start-Sleep -Seconds 1
}

function Chain-Backup {
    Write-CurrentTime; Write-Host "  Creating bootstrap script..." -ForegroundColor Cyan
    $chainBackupScript = @"
`$bootstrapZipPath = $bootstrapZipPath
`$CONFIG_DIR = "`$env:APPDATA\RaptoreumSmartNode"
Move-Item -Path "`$env:USERPROFILE\check.ps1" -Destination "`$env:USERPROFILE\temp.ps1" -ErrorAction SilentlyContinue -Force
Write-Host "Stopping RTMService..." -ForegroundColor Yellow
Stop-Service -Name "RTMService" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
# Check if the wallet process is running and kill it if it is
`$walletProcess = Get-Process -Name "raptoreumd.exe" -ErrorAction SilentlyContinue
if (`$walletProcess) {
    Write-Host " Stopping the running Raptoreum process..." -ForegroundColor Yellow
    Stop-Process `$walletProcess.Id -Force
} else {
    Write-Host " No Raptoreum process detected..." -ForegroundColor Yellow
}
Start-Sleep -Seconds 2
Write-Host "Deleting the existing bootstrap..." -ForegroundColor Yellow
Remove-Item -Path `$bootstrapZipPath -ErrorAction SilentlyContinue -Force
Compress-Archive -Path "`$CONFIG_DIR\blocks", "`$CONFIG_DIR\chainstate", "`$CONFIG_DIR\evodb", "`$CONFIG_DIR\llmq" -DestinationPath `$bootstrapZipPath
Write-Host "(`$((((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")))))  Bootstrap created" -ForegroundColor Green
Start-Service -Name "RTMService" -ErrorAction SilentlyContinue
Move-Item -Path "`$env:USERPROFILE\temp.ps1" -Destination "`$env:USERPROFILE\check.ps1" -ErrorAction SilentlyContinue -Force
"@
    Set-Content -Path "$env:USERPROFILE\chainbackup.ps1" -Value $chainBackupScript -ErrorAction SilentlyContinue -Force
    Write-CurrentTime; Write-Host "  Script created: $env:USERPROFILE\chainbackup.ps1..." -ForegroundColor Yellow
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
    Write-Host "Please run this script with administrative privileges..." -ForegroundColor Cyan
    pause
    exit
}
`$COIN_PATH = "`$env:ProgramFiles (x86)\RaptoreumCore"
#Show versions
`$FilePath = Join-Path `$COIN_PATH "raptoreumd.exe"
`$fileVersionInfo = Get-Item `$FilePath -ErrorAction SilentlyContinue| Get-ItemProperty | Select-Object -ExpandProperty VersionInfo
`$fileVerion = `$fileVersionInfo.ProductVersion
`$uri = "https://api.github.com/repos/Raptor3um/raptoreum/releases/latest"
`$response = Invoke-RestMethod -Uri `$uri
`$latestVersion = `$response.tag_name
if (Test-Path `$COIN_PATH) {
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
    Write-Host "Stopping RTMService..." -ForegroundColor Yellow
    Stop-Service -Name "RTMService" -ErrorAction SilentlyContinue
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
    Start-BitsTransfer -Source `$walletUrl -Destination (Join-Path `$COIN_PATH "raptoreum.zip") -DisplayName "Downloading binaries from `$walletUrl"
    Write-Host "Unzipping..." -ForegroundColor Yellow
    Expand-Archive -Path (Join-Path `$COIN_PATH "raptoreum.zip") -DestinationPath `$COIN_PATH -ErrorAction SilentlyContinue -Force
    Write-Host "Starting RTMService..." -ForegroundColor Yellow
    Start-Service -Name "RTMService" -ErrorAction SilentlyContinue
    Write-Host "Binaries updated to v`$latestVersion successfully..." -ForegroundColor Green
} else {
Write-Host "Skipping update..." -ForegroundColor Yellow
}
pause
"@
    $updateBatch = @"
@echo off
powershell.exe -ExecutionPolicy Bypass -File "%USERPROFILE%\update.ps1"
"@
    Set-Content -Path "$env:USERPROFILE\update.bat" -Value $updateBatch -ErrorAction SilentlyContinue -Force
    Set-Content -Path "$env:USERPROFILE\update.ps1" -Value $updateScript -ErrorAction SilentlyContinue -Force
    Write-CurrentTime; Write-Host "  Script created: `%USERPROFILE%\update.bat..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

function Create-Service {
    if (-not (Get-Service -Name "RTMService" -ErrorAction SilentlyContinue)) {
        Install-NSSM
        $ServiceName = "RTMService"
        $ExecutablePath = Join-Path $COIN_PATH "raptoreumd.exe"
        $Arguments = "-datadir=$CONFIG_DIR -conf=$configPath"
        $NSSM_exe = Join-Path $env:UserProfile "nssm-2.24\win64\nssm.exe"
        Write-CurrentTime; Write-Host "  Creating RTMService with NSSM..." -ForegroundColor Cyan
        & $NSSM_exe install $ServiceName $ExecutablePath $Arguments | Out-Null
        Write-CurrentTime; Write-Host "  Setting RTMService to start automatically..." -ForegroundColor Yellow
        & $NSSM_exe set $ServiceName Start SERVICE_AUTO_START | Out-Null
        Write-CurrentTime; Write-Host "  RTMService has been created successfully." -ForegroundColor Yellow
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if (-not $Null -eq $service) {
            Write-CurrentTime; Write-Host "  Starting daemon service & syncing chain please be patient this will take few moment (20s)..." -ForegroundColor Cyan
            Start-Service $ServiceName -ErrorAction Continue
            Start-Sleep -Seconds 20
            Write-CurrentTime; Write-Host "  Getting blockchain info (%raptoreumcli% getblockchaininfo)..." -ForegroundColor Yellow
            cmd /C "$global:CLI getblockchaininfo" 2>&1
            Write-CurrentTime; Write-Host "  Getting smartnode status (%raptoreumcli% smartnode status)..." -ForegroundColor Yellow
            cmd /C "$global:CLI smartnode status" 2>&1
        } else {
            Write-CurrentTime; Write-Host "  Something is not right, the daemon did not start. Will exit out so try and run the script again..." -ForegroundColor Red
            pause
            exit
        }
        Write-CurrentTime; Write-Host "  RTMService has been created and started successfully..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 1
}

$global:SECURITY_ANS = ""
function Basic-Security {
    # If $QuickSetup is provided, just ask about basic security.
    param(
        [string]$QuickSetup
    )    
    if (-not [string]::IsNullOrEmpty($QuickSetup)) {
        do {
            $result = Read-Host -Prompt "Would you like to setup basic firewall? (y/n) "
            if ($result -eq "y" -or $result -eq "") {
                $global:SECURITY_ANS = 1
                $validInput = $true
            } elseif ($result -eq "n") {
                $validInput = $true
            } else {
                Write-Host "  Please enter 'y', 'n'..." -ForegroundColor Yellow
                $validInput = $false
            }
        } while (-not $validInput)
        return
    }
    if ($global:SECURITY_ANS -eq "1") {
        Write-CurrentTime; Write-Host "  Configuring firewall..." -ForegroundColor Cyan
        New-NetFirewallRule -DisplayName "Allow SSH" -Direction Inbound -LocalPort $global:SSHPORT -Protocol TCP -Action Allow | Out-Null
        New-NetFirewallRule -DisplayName "Allow RTM" -Direction Inbound -LocalPort $global:PORT -Protocol TCP -Action Allow | Out-Null
        Write-CurrentTime; Write-Host "  Firewall configured successfully." -ForegroundColor Yellow
    } else {
        Write-CurrentTime; Write-Host "  Skipping basic security..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 1
}

$global:PROTX_HASH = ""
function Schedule-Jobs {
    # If $QuickSetup is provided, just ask about ProTx Hash.
    param (
        [string]$QuickSetup
    )
    $CHECK_SCRIPT_PATH = "$env:USERPROFILE\check.bat"
    $CHAINBACKUP_SCRIPT_PATH = "$env:USERPROFILE\chainbackup.bat"
    if (-not [string]::IsNullOrEmpty($QuickSetup)) {
        $global:PROTX_HASH = Read-Host -Prompt "Please enter your protx hash for this SmartNode "
        return
    }
    $checkUrl = "https://raw.githubusercontent.com/wizz13150/Raptoreum_SmartNode/main/check.ps1"
    Start-BitsTransfer -Source $checkUrl -Destination "$env:USERPROFILE\check.ps1" -DisplayName "Downloading file from $checkUrl"
    # Replace NODE_PROTX value in check.ps1
    (Get-Content "$env:USERPROFILE\check.ps1").Replace('#NODE_PROTX=', "`$NODE_PROTX = `"$global:PROTX_HASH`"") | Set-Content "$env:USERPROFILE\check.ps1"
    # Create scheduled tasks
    Write-CurrentTime; Write-Host "  Creating scheduled tasks..." -ForegroundColor cyan
    $checkTaskName = "RTMCheck"
    $chainBackupTaskName = "RTMChainBackup"
    Unregister-ScheduledTask -TaskName $checkTaskName -Confirm:$false -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $chainBackupTaskName -Confirm:$false -ErrorAction SilentlyContinue
    # Create trigger for Check task (every 15 minutes)
    $checkTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddMinutes(15) -RepetitionInterval (New-TimeSpan -Minutes 15)
    # Create trigger for ChainBackup task (monthly)
    $chainBackupTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Wednesday -WeeksInterval 4 -At 03:00
    $checkLog = "$env:USERPROFILE\check.log"
    $bootstrapLog = "$env:USERPROFILE\bootstrap.log"
    $checkAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-Command `"Start-Process cmd.exe -ArgumentList '/c `"$CHECK_SCRIPT_PATH`"' -Verb RunAs`""" > `"$checkLog`""
    $chainBackupAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-Command `"Start-Process cmd.exe -ArgumentList '/c `"$CHAINBACKUP_SCRIPT_PATH`"' -Verb RunAs`""" > `"$bootstrapLog`""
    $User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $Principal = New-ScheduledTaskPrincipal -UserID $User -LogonType S4U -RunLevel Highest
    Register-ScheduledTask -TaskName $checkTaskName -Trigger $checkTrigger -Action $checkAction -Principal $Principal | Out-Null
    Register-ScheduledTask -TaskName $chainBackupTaskName -Trigger $chainBackupTrigger -Action $chainBackupAction -Principal $Principal | Out-Null
    #Register-ScheduledTask -TaskName $checkTaskName -Trigger $checkTrigger -Action $checkAction -User "System" -RunLevel Highest | Out-Null
    #Register-ScheduledTask -TaskName $chainBackupTaskName -Trigger $chainBackupTrigger -Action $chainBackupAction -User "System" -RunLevel Highest | Out-Null
    Write-CurrentTime; Write-Host "  Scheduled tasks successfully created..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

function Log-Rotate {
    if (-not (Test-Path "$env:ProgramFiles\LogrotateWin\LogrotateWin.exe")) {
        Write-CurrentTime; Write-Host "  Installing LogrotateWin..." -ForegroundColor Cyan
        Install-LogrotateWin
    }
    $logrotateConfig = @"
# Debug.log configuration
$CONFIG_DIR\debug.log {
    compress
    copytruncate
    missingok
    daily
    rotate 7
}
# Bootstrap.log configuration
$env:USERPROFILE\bootstrap.log {
    size 1000k
    copytruncate
    missingok
    rotate 0
}
# Check.log configuration
$env:USERPROFILE\check.log {
    size 1000k
    compress
    copytruncate
    missingok
    rotate 3
}
"@
    Write-CurrentTime; Write-Host "  Configuring logrotate function for debug log..." -ForegroundColor Yellow
    $logrotateConfigPath = (Join-Path $env:USERPROFILE "rtmdebuglogrotate.conf")
    if (Test-Path $logrotateConfigPath) {
        Write-CurrentTime; Write-Host "  Existing log rotate conf found, backing up to ~/rtmdebuglogrotate.old ..." -ForegroundColor Yellow
        Move-Item $logrotateConfigPath "$env:USERPROFILE\rtmdebuglogrotate.old" -ErrorAction SilentlyContinue -Force
    }
    $logrotateConfig | Out-File -FilePath $logrotateConfigPath -Encoding utf8 -Force
    Start-Sleep -Seconds 1
}

function Create-MOTD {
    Write-Host "================================================================================================" -ForegroundColor Yellow
    Write-Host " COURTESY OF DK808 FROM ALTTANK ARMY" -ForegroundColor Cyan
    Write-Host " Smartnode healthcheck by Delgon" -ForegroundColor Cyan
    Write-Host " adapted to Windows by Wizz" -ForegroundColor Cyan
    Write-Host "" 
    Write-Host " Commands to manage RTMService(deamon) with cmd :" -ForegroundColor Yellow
    Write-Host "   TO START -  Net Start RTMService" -ForegroundColor Cyan
    Write-Host "   TO STOP  -  Net Stop RTMService" -ForegroundColor Cyan
    Write-Host "   STATUS   -  SC Query RTMService" -ForegroundColor Cyan
    Write-Host " In the event server reboots, the daemon service will auto-start"
    Write-Host ""
    Write-Host ' To use raptoreum-cli with cmd, simply start a command with %raptoreumcli% :' -ForegroundColor Yellow
    Write-Host '   E.g     %raptoreumcli% getblockchaininfo' -ForegroundColor Cyan
    Write-Host '   E.g     %raptoreumcli% smartnode status' -ForegroundColor Cyan
    Write-Host ""
    Write-Host " To manage the Smartnode, launch 'SmartnodeBash' on the desktop" -ForegroundColor Yellow
    Write-Host " To update the Smartnode, launch 'UpdateSmartnode' on the desktop" -ForegroundColor Yellow
    Write-Host "================================================================================================" -ForegroundColor Yellow
    Write-Host ' Remember to always encrypt your wallet with a strong password !' -ForegroundColor Green
    Write-Host "================================================================================================" -ForegroundColor Yellow

    $MOTD = @"
================================================================================================
  SMARTNODE BASH
================================================================================================
  COURTESY OF DK808 FROM ALTTANK ARMY
  Smartnode healthcheck by Delgon
  March 2023, adapted to Windows by Wizz

  Commands to manage RTMService(deamon) with cmd :
    TO START -  Net Start RTMService
    TO STOP  -  Net Stop RTMService
    STATUS   -  SC Query RTMService
  In the event server reboots, the daemon service will auto-start

  To use raptoreum-cli with cmd, simply start a command with %raptoreumcli% :
    E.g:   %raptoreumcli% getblockchaininfo
    E.g:   %raptoreumcli% smartnode status

  To update the Smartnode, launch 'UpdateSmartnode' on the desktop
================================================================================================
  Remember to always encrypt your wallet with a strong password !
================================================================================================
"@
    $BASH = @"
@echo off
type "%USERPROFILE%\RTM-MOTD.txt" > "%TEMP%\texte.txt"
start cmd.exe /k "type %TEMP%\texte.txt & del %TEMP%\texte.txt"
"@
    $CHECKBATCH = @"
@echo off
powershell.exe -ExecutionPolicy RemoteSigned -File %USERPROFILE%\check.ps1"
"@
    $BACKUPBATCH = @"
@echo off
powershell.exe -ExecutionPolicy RemoteSigned -File %USERPROFILE%\chainbackup.ps1"
"@
    $BACKUPPath = Join-Path $env:USERPROFILE "chainbackup.bat"
    Set-Content -Path $BACKUPPath -Value $BACKUPBATCH -ErrorAction SilentlyContinue -Force
    $BATCHPath = Join-Path $env:USERPROFILE "check.bat"
    Set-Content -Path $BATCHPath -Value $CHECKBATCH -ErrorAction SilentlyContinue -Force
    $MOTDPath = Join-Path $env:USERPROFILE "RTM-MOTD.txt"
    Set-Content -Path $MOTDPath -Value $MOTD -ErrorAction SilentlyContinue -Force
    $BASHPATH = Join-Path $env:USERPROFILE "SmartNodeBash.bat"
    Set-Content -Path $BASHPATH -Value $BASH -ErrorAction SilentlyContinue -Force
}

# Clean the environment from possibly previous setup et set env var for cli
Wipe-Clean
Environment-Variable

# Ask about things first for quick setup
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
Create-Shortcuts
Create-MOTD

pause