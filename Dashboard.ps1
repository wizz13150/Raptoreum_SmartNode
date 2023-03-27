#####################################
######## Smartnode Dashboard ########
#####################################

# Define Raptoreum-cli
$raptoreumcli = $env:raptoreumcli

while ($true) {
# Get informations
$blockHeight = cmd /C "$raptoreumcli getblockcount" | ConvertFrom-Json
$mempoolInfo = cmd /C "$raptoreumcli getmempoolinfo" | ConvertFrom-Json
$networkInfo = cmd /C "$raptoreumcli getblockchaininfo" | ConvertFrom-Json
$getnettotals = cmd /C "$raptoreumcli getnettotals" | ConvertFrom-Json
$connectionCount = cmd /C "$raptoreumcli getconnectioncount" | ConvertFrom-Json
$smartnodeTotal = cmd /C "$raptoreumcli smartnodelist status"
$smartnodeList = cmd /C "$raptoreumcli smartnodelist status ENABLED"
$smartnodeStatus = cmd /C "$raptoreumcli smartnode status" | ConvertFrom-Json

Clear-Host
# Display informations
Write-Host -NoNewline "`r----------------------------------" -ForegroundColor Cyan
Write-Host "`nRaptoreum Dashboard Pro 9000 Plus Supreme" -ForegroundColor Yellow
Write-Host "`nMega Championship Edition Collector Deluxe" -ForegroundColor Yellow
Write-Host "`nHyper Turbo Interstellar Ultimate Galaxy" -ForegroundColor Yellow
Write-Host "`nGrandmaster Battlestation of the Multiverse" -ForegroundColor Yellow
Write-Host "`r----------------------------------" -ForegroundColor Cyan
Write-Host "`rChain........................: $($networkInfo.chain)" -ForegroundColor Green
Write-Host "`rLocal block height...........: $blockHeight" -ForegroundColor Green
Write-Host "`rNetwork block height.........: ..." -ForegroundColor Green
Write-Host "`rTotal Smartnodes.............: $($smartnodeTotal.count)" -ForegroundColor Green
Write-Host "`rActive Smartnodes............: $($smartnodeList.count)" -ForegroundColor Green
Write-Host "`r----------------------------------" -ForegroundColor Cyan
Write-Host "`rLocal version................: ..." -ForegroundColor Green
Write-Host "`rAvailable version............: ..." -ForegroundColor Green
Write-Host "`rSmartnode connections........: $($connectionCount)" -ForegroundColor Green
Write-Host "`rTransactions in mempool......: $($mempoolInfo.size)" -ForegroundColor Green
Write-Host "`rMempool size in Mb...........: $([math]::Round($mempoolInfo.bytes / 1MB, 3)) Mb" -ForegroundColor Green
Write-Host "`r----------------------------------" -ForegroundColor Cyan
Write-Host "`rSmartnode status.............: $($smartnodeStatus.status)" -ForegroundColor Green
Write-Host "`rIP address and port..........: $($smartnodeStatus.service)" -ForegroundColor Green
Write-Host "`rSmartnode ProTX..............: $($smartnodeStatus.proTxHash)" -ForegroundColor Green
Write-Host "`rSmartnode BLS Key............: ..." -ForegroundColor Green
Write-Host "`rPayout address...............: $($smartnodeStatus.dmnState.payoutAddress)" -ForegroundColor Green
Write-Host "`rRegistered height............: $($smartnodeStatus.dmnState.registeredHeight)" -ForegroundColor Green
Write-Host "`rCurrent PoSe score...........: $($smartnodeStatus.dmnState.PoSePenalty)" -ForegroundColor Green
Write-Host "`rTime to PoSe Score 0.........: $(($smartnodeStatus.dmnState.PoSePenalty) * 4) min" -ForegroundColor Green
Write-Host "`rPoSe ban height..............: $($smartnodeStatus.dmnState.PoSeBanHeight)" -ForegroundColor Green
Write-Host "`rLast revived height..........: $($smartnodeStatus.dmnState.PoSeRevivedHeight)" -ForegroundColor Green
Write-Host "`r----------------------------------" -ForegroundColor Cyan
Write-Host "`rTotal received...............: $([math]::Round($getnettotals.totalbytesrecv / 1MB)) Mb" -ForegroundColor Green
Write-Host "`rTotal sent...................: $([math]::Round($getnettotals.totalbytessent / 1MB, 0)) Mb" -ForegroundColor Green


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
