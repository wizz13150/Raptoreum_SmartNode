# URLs for raptoreum explorers. Main and backup one.
$url = @( 'https://explorer.raptoreum.com/', 'https://raptor.mopsus.com/' )
$url_ID = 0
$bootstrapZip = "https://bootstrap.raptoreum.com/bootstraps/bootstrap.zip"
$raptoreumCLI = $env:raptoreumcli
$configDir = "$env:APPDATA\RaptoreumSmartnode"
$serviceName = "RTMService"
$bootstrapZipPath = "$env:APPDATA\bootstrap\bootstrap.zip"

$poseScore = 0
$prevScore = 0
$localHeight = 0

# Add your NODE_PROTX here if you forgot or provided wrong hash during node installation.
#NODE_PROTX=

function Write-CurrentTime {
    Write-Host ('[' + (Get-Date).ToString("HH:mm:ss") + ']') -NoNewline
}

function Get-Number {
  param (
    [string]$InputString
  )
  if ($InputString -match '^[+-]?[0-9]+([.][0-9]+)?$') {
    return $InputString
  } else {
    return "-1"
  }
}

function Read-Value {
  param (
    [string]$FilePath
  )
  Get-Number (Get-Content $FilePath -ErrorAction SilentlyContinue)
}

function tryToKillDaemonGracefullyFirst {
    Write-CurrentTime; Write-Host "  Trying to kill daemon gracefully..." -ForegroundColor Yellow
    $raptoreumdProcess = Get-Process "raptoreumd" -ErrorAction SilentlyContinue
    if ($raptoreumdProcess) {
        cmd /C "$env:raptoreumcli stop" 2>&1
    }
    Start-Sleep -Seconds 10
    $localHeight = Get-Number (cmd /C "$env:raptoreumcli getblockcount" 2>&1)
    if ($localHeight -lt 0) {
        Write-CurrentTime; Write-Host "  Unable to kill daemon gracefully, check and restart RTMService..." -ForegroundColor Yellow
        CheckAndRestart-RTMService
    } else {
        Write-CurrentTime; Write-Host "  Daemon is alive..." -ForegroundColor Green
    }
}

function CheckAndRestart-RTMService {
    $processName = "raptoreumd"
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($process -and $service.Status -eq 'Stopped') {
        Write-CurrentTime; Write-Host "  Process exists and service is stopped. Stopping process and restarting service..." -ForegroundColor Yellow
        Stop-Process $process -ErrorAction SilentlyContinue -Force
        Start-Service $serviceName -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
    } elseif ($service.Status -eq 'Running' -and -not $process) {
        Write-CurrentTime; Write-Host "  Service is running and process does not exist. Restarting service..." -ForegroundColor Yellow
        Restart-Service $serviceName -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
    } elseif ($service.Status -ne 'Running' -and -not $process) {
        Write-CurrentTime; Write-Host "  Service and process are dead. Starting service..." -ForegroundColor Yellow
        Start-Service $serviceName -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
    }
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($process -and $service.Status -eq 'Running') {
        Write-CurrentTime; Write-Host "  Process and service are running successfully..." -ForegroundColor Green
    } else {
        Write-Warning "  Process or service is not running. Please check manually..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
    }
}

function Check-PoSe {
  # Check if the Node PoSe score is changing.
  if (![string]::IsNullOrEmpty($NODE_PROTX)) {
    $poseScore = (Invoke-WebRequest -Uri "$($url[$url_ID])api/protx?command=info&protxhash=$($NODE_PROTX)" -UseBasicParsing).Content | ConvertFrom-Json | Select-Object -ExpandProperty state | Select-Object -ExpandProperty PoSePenalty
    if ((Get-Number $poseScore) -lt 0 -and $poseScore -ne "null") {
      $url_ID = ($url_ID + 1) % 2
      $poseScore = (Invoke-WebRequest -Uri "$($url[$url_ID])api/protx?command=info&protxhash=$($NODE_PROTX)" -UseBasicParsing).Content | ConvertFrom-Json | Select-Object -ExpandProperty state | Select-Object -ExpandProperty PoSePenalty
    }
    if ($poseScore -eq "null") {
      Write-CurrentTime; Write-Host "  Your NODE_PROTX is invalid, please insert your NODE_PROTX hash in the script..." -ForegroundColor Yellow
      Write-CurrentTime; Write-Host "  The script path is: $env:UserProfile\check.ps1 - line 20" -ForegroundColor Yellow
    } elseif ((Get-Number $poseScore) -eq -1) {
      Write-CurrentTime; Write-Host "  Could not get PoSe score for the node. It is possible both explorers are down..." -ForegroundColor Yellow
    }
    $poseScore = Get-Number $poseScore
  } else {
    Write-CurrentTime; Write-Host "  Your NODE_PROTX is empty. Please reinitialize the node again or add it in the script..." -ForegroundColor Yellow
    Write-CurrentTime; Write-Host "  The script is located at $env:UserProfile\check.ps1 - line 20" -ForegroundColor Yellow
  }
  $prevScore = Read-Value -FilePath "$env:UserProfile\pose_score.tmp"
  Set-Content -Path "$env:UserProfile\pose_score.tmp" -Value $poseScore -ErrorAction SilentlyContinue -Force
  # Check if we should restart raptoreumd according to the PoSe score.
  if ($poseScore -gt 0) {
    if ($poseScore -gt $prevScore) {
      Write-CurrentTime; Write-Host "  Score increased from $($prevScore) to $($poseScore). Send kill signal..." -ForegroundColor Yellow
      tryToKillDaemonGracefullyFirst
      Set-Content -Path "$env:UserProfile\was_stuck.tmp" -Value "1" -ErrorAction SilentlyContinue -Force
      # Do not check node height after killing raptoreumd it is sure to be stuck.
      return
    } elseif ($poseScore -lt $prevScore) {
      Write-CurrentTime; Write-Host "  Score decreased from $($prevScore) to $($poseScore). Wait..." -ForegroundColor Yellow
      Remove-Item -Path "$env:UserProfile\was_stuck.tmp" -ErrorAction SilentlyContinue -Force
    }
    # $poseScore -eq $prevScore is gonna force check the node block height.
  }
}

function Check-BlockHeight {
  # Check local block height.
  $networkHeight = Get-Number ((Invoke-WebRequest -Uri "$($url[$url_ID])api/getblockcount" -UseBasicParsing).Content)
  if ($networkHeight -lt 0) {
    $url_ID = ($url_ID + 1) % 2
    $networkHeight = Get-Number ((Invoke-WebRequest -Uri "$($url[$url_ID])api/getblockcount" -UseBasicParsing).Content)
  }
  $prevHeight = Read-Value -FilePath "$env:UserProfile\height.tmp"
  $localHeight = Get-Number (cmd /C "$env:raptoreumcli getblockcount" 2>&1)
  Set-Content -Path "$env:UserProfile\height.tmp" -Value $localHeight -ErrorAction SilentlyContinue -Force
  if ($poseScore -eq $prevScore -or $prevScore -eq -1) {
    Write-CurrentTime; Write-Host "  Node height $($localHeight)/$($networkHeight)..." -ForegroundColor Green
    # Block height did not change. Is it stuck?. Compare with network block height. Allow some slippage.
    if (($networkHeight - $localHeight) -gt 3 -or $networkHeight -eq -1) {
      if ($localHeight -gt $prevHeight) {
        # Node is still syncing?
        Remove-Item -Path "$env:UserProfile\was_stuck.tmp" -ErrorAction SilentlyContinue -Force
        Write-CurrentTime; Write-Host "  Increased from $($prevHeight) -> $($localHeight). Wait..." -ForegroundColor Yellow
      } elseif ($localHeight -gt 0 -and (Read-Value -FilePath "$env:UserProfile\was_stuck.tmp") -lt 0) {
        # Node is behind the network height and it is first attempt at unstucking.
        # If LOCAL_HEIGHT is >0 it means that we were able to read from the cli
        # but the height did not change compared to previous check.
        Set-Content -Path "$env:UserProfile\was_stuck.tmp" -Value "1" -ErrorAction SilentlyContinue -Force
        Write-CurrentTime; Write-Host "  Height difference is more than 3 blocks behind the network. Send kill signal..." -ForegroundColor Yellow
        tryToKillDaemonGracefullyFirst
      } elseif ((Read-Value -FilePath "$env:UserProfile\was_stuck.tmp") -lt 0) {
        # Node was not able to respond. It is probably stuck but try to restart
        # it once before trying to bootstrap or restore it.
        Set-Content -Path "$env:UserProfile\was_stuck.tmp" -Value "1" -ErrorAction SilentlyContinue -Force
        Write-CurrentTime; Write-Host "  Node was unresponsive for the first time. Send kill signal..." -ForegroundColor Yellow
        tryToKillDaemonGracefullyFirst
      } else {
        # Node is most probably very stuck and if trying to sync wrong chain branch.
        # This means simple raptoreumd kill will not help and we need to
        # force unstuck by bootstrapping / resyncing the chain again.
        Write-CurrentTime; Write-Host " Node seems to be hardstuck and is trying to sync forked chain. Try to force unstuck..." -ForegroundColor Yellow
        Write-CurrentTime; Write-Host "  Check-BlockHeight return `$false, better call Saul for some legal advice !.." -ForegroundColor Yellow
        Write-CurrentTime; Write-Host "  Joke, let's just run the 'Reconsider-Block' function first..." -ForegroundColor Yellow
        return $false
      }
    } else {
      Remove-Item -Path "$env:UserProfile\was_stuck.tmp" -ErrorAction SilentlyContinue -Force      
      Write-CurrentTime; Write-Host "  Daemon seems ok..." -ForegroundColor Green
    }
  }
  Write-CurrentTime; Write-Host "  Check-BlockHeight return `$true, it's all good man (Saul goodman, got it ?)..." -ForegroundColor Green
  return $true
}

function Reconsider-Block {
  $prev_stuck = Get-Content -Path "$env:UserProfile\prev_stuck.tmp"
  if (($localHeight -gt 0) -and ($localHeight -gt $prev_stuck)) {
    $reconsider = $localHeight - 10
    $hash = cmd /C "$env:raptoreumcli getblockhash $reconsider" 2>&1
    if ($hash -ne "-1") {
      Write-CurrentTime; Write-Host "  Reconsider chain from 10 blocks before current one $reconsider."
      if ([string]::IsNullOrEmpty((cmd /C "$env:raptoreumcli reconsiderblock $hash" 2>&1))) {
        Set-Content -Path "$env:UserProfile\height.tmp" -Value $reconsider -ErrorAction SilentlyContinue -Force
        Set-Content -Path "$env:UserProfile\prev_stuck.tmp" -Value $localHeight -ErrorAction SilentlyContinue -Force
        Write-CurrentTime; Write-Host "  Reconsider-Block return `$false, better call Saul for some legal advice !.." -ForegroundColor Yellow
        Write-CurrentTime; Write-Host "  Joke, let's just run the 'Bootstrap' function first..." -ForegroundColor Yellow
        return $false
      }
    }
  }
  Write-CurrentTime; Write-Host "  Reconsider-Block return `$true, it's all good man (Saul goodman, got it ?)..." -ForegroundColor Green
  return $true
}

function Bootstrap {
  Write-CurrentTime; Write-Host "  Bootstrap the node chain..." -ForegroundColor Cyan
  Set-Content -Path "$env:USERPROFILE\height.tmp" -Value "0" -ErrorAction SilentlyContinue -Force
  Set-Content -Path "$env:USERPROFILE\prev_stuck.tmp" -Value "0" -ErrorAction SilentlyContinue -Force
  # Stop service and kill raptoreumd.
  Write-CurrentTime; Write-Host "  Kill raptoreumd..." -ForegroundColor Yellow
  Stop-Service -Name $serviceName -ErrorAction SilentlyContinue -Force
  Stop-Process -Name "raptoreumd" -ErrorAction SilentlyContinue -Force
  # Clean
  Write-CurrentTime; Write-Host "  Clean $configDir...."
  Remove-Item -Recurse -Path "$configDir\blocks" -ErrorAction SilentlyContinue -Force
  Remove-Item -Recurse -Path "$configDir\chainstate" -ErrorAction SilentlyContinue -Force
  Remove-Item -Recurse -Path "$configDir\evodb" -ErrorAction SilentlyContinue -Force
  Remove-Item -Recurse -Path "$configDir\llmq" -ErrorAction SilentlyContinue -Force
  Remove-Item -Recurse -Path "$configDir\powcache.dat" -ErrorAction SilentlyContinue -Force
  # Download and prepare bootstrap
  Move-Item -Path "$env:USERPROFILE\check.ps1" -Destination "$env:USERPROFILE\temp.ps1" -Force
  Write-CurrentTime; Write-Host "  Download and prepare bootstrap...." -ForegroundColor Yellow
  if (Test-Path -Path $bootstrapZipPath) {
    Write-CurrentTime; Write-Host "  File bootstrap.zip detected, skip download..." -ForegroundColor Yellow
  } else {
    Start-BitsTransfer -Source $bootstrapZip -Destination "$env:APPDATA\bootstrap\bootstrap.zip" -DisplayName "Downloading bootstrap from $bootstrapZip"
  }
  $zipProgram = ""
  $7zipKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\7zFM.exe"
  if (Test-Path $7zipKey) {
    $zipProgram = (Get-ItemProperty $7zipKey).'Path' + "7z.exe"
  }
  if ($zipProgram) {
    Write-CurrentTime; Write-Host "  7-Zip detected, using 7-Zip to extract the bootstrap. Faster..." -ForegroundColor Cyan
    & "$zipProgram" x "$env:APPDATA\bootstrap\bootstrap.zip" -o"$configDir" -y
  } else {
    Write-CurrentTime; Write-Host "  7-Zip not detected, using 'Expand-Archive' to extract the bootstrap. Slower..." -ForegroundColor Yellow
    Expand-Archive -Path "$env:APPDATA\bootstrap\bootstrap.zip" -DestinationPath $configDir -Force -ErrorAction SilentlyContinue
  }
  Write-CurrentTime; Write-Host "  Bootstrap complete..." -ForegroundColor Green
  Start-Service -Name $serviceName
  Move-Item -Path "$env:USERPROFILE\temp.ps1" -Destination "$env:USERPROFILE\check.ps1" -Force
}

# check if service and deamon are okay
CheckAndRestart-RTMService
# Check pose score according to the explorer data.
Check-PoSe
# PoSe seems fine, did not change or was not able to get the score.
(Check-BlockHeight) -or (Reconsider-Block) -or (Bootstrap)

Start-Sleep -Seconds 6
