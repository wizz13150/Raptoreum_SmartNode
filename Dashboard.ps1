#####################################
######## Smartnode Dashboard ########
#####################################

# Define Raptoreum-cli
$raptoreumcli = $env:raptoreumcli

while ($true) {
# cli commands to run parallel
$commands = @(
    { param($raptoreumcli) cmd /C "$raptoreumcli getblockcount" | ConvertFrom-Json },
    { param($raptoreumcli) cmd /C "$raptoreumcli getmempoolinfo" | ConvertFrom-Json },
    { param($raptoreumcli) cmd /C "$raptoreumcli getblockchaininfo" | ConvertFrom-Json },
    { param($raptoreumcli) cmd /C "$raptoreumcli getwalletinfo" | ConvertFrom-Json },
    { param($raptoreumcli) cmd /C "$raptoreumcli getconnectioncount" | ConvertFrom-Json },
    { param($raptoreumcli) cmd /C "$raptoreumcli listaddressbalances" },
    { param($raptoreumcli) cmd /C "$raptoreumcli smartnodelist status ENABLED" },
    { param($raptoreumcli) cmd /C "$raptoreumcli smartnode status" | ConvertFrom-Json }
)
# Start parallel jobs
$jobs = $commands | ForEach-Object {
    Start-Job -ScriptBlock $_ -ArgumentList $raptoreumcli
}
$jobs | Wait-Job
$results = $jobs | Receive-Job
$jobs | Remove-Job
# Get informations back to vars
$blockHeight = $results[0]
$mempoolInfo = $results[1]
$networkInfo = $results[2]
$walletInfo = $results[3]
$connectionCount = $results[4]
$listAddress = $results[5]
$smartnodeList = $results[6]
$smartnodeStatus = $results[7]

Clear-Host
# Display informations
Write-Host -NoNewline "`r----------------------------------" -ForegroundColor Cyan
Write-Host "`nRaptoreum Dashboard Pro 9000 Plus" -ForegroundColor Yellow
Write-Host "`r----------------------------------" -ForegroundColor Cyan
Write-Host "`rChain........................: $($networkInfo.chain)" -ForegroundColor Green
Write-Host "`rCurrent block height.........: $blockHeight" -ForegroundColor Green
Write-Host "`rActive Smartnodes............: $($smartnodeList.count)" -ForegroundColor Green
Write-Host "`r----------------------------------" -ForegroundColor Cyan
Write-Host "`rSmartnode addresses..........: $($listAddress.count)" -ForegroundColor Green
Write-Host "`rSmartnode transactions.......: $($walletInfo.txcount)" -ForegroundColor Green
Write-Host "`rSmartnode connections........: $($connectionCount)" -ForegroundColor Green
Write-Host "`rMempool size.................: $($mempoolInfo.size)" -ForegroundColor Green
Write-Host "`r----------------------------------" -ForegroundColor Cyan
Write-Host "`rSmartnode status.............: $($smartnodeStatus.status)" -ForegroundColor Green
Write-Host "`rIP address and port..........: $($smartnodeStatus.addr)" -ForegroundColor Green
Write-Host "`rPayee........................: $($smartnodeStatus.payee)" -ForegroundColor Green
Write-Host "`r----------------------------------" -ForegroundColor Cyan

# Countdown to refresh
$seconds = 10
$t = New-TimeSpan -Seconds 10
$origpos = $host.UI.RawUI.CursorPosition
$spinner =@('|', '/', '-', '\')
$spinnerPos = 0
$remain = $t
$d =( get-date) + $t
$remain = ($d - (get-date))
while ($remain.TotalSeconds -gt 0){
  Write-Host (" {0} " -f $spinner[$spinnerPos%4]) -BackgroundColor White -ForegroundColor Black -NoNewline
  write-host (" {0}s " -f $remain.Seconds)
  $host.UI.RawUI.CursorPosition = $origpos
  $spinnerPos += 1
  Start-Sleep -seconds 1
  $remain = ($d - (get-date))
}
$host.UI.RawUI.CursorPosition = $origpos
Write-Host " * "  -BackgroundColor White -ForegroundColor Black -NoNewline
"Refreshing..."
}
