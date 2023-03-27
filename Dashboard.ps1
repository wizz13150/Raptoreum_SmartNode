#####################################
######## Smartnode Dashboard ########
#####################################

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
$networkHeight = (Invoke-WebRequest -Uri "https://explorer.raptoreum.com/api/getblockcount" -UseBasicParsing).Content
$latest = Invoke-RestMethod -Uri "https://api.github.com/repos/Raptor3um/raptoreum/releases/latest"
$smartnodeVersion = Get-Item "$env:ProgramFiles (x86)\RaptoreumCore\raptoreumd.exe" -ErrorAction SilentlyContinue| Get-ItemProperty | Select-Object -ExpandProperty VersionInfo
$folderSize = Get-ChildItem "$env:APPDATA\RaptoreumSmartnode" -Recurse -Exclude nodetest | Measure-Object -Property Length -Sum
$bls = (Get-Content "$env:APPDATA\RaptoreumSmartnode\raptoreum.conf" | Where-Object { $_ -like "smartnodeblsprivkey=*" }) -replace "smartnodeblsprivkey=", ""

Clear-Host
# Display informations
Write-Host -NoNewline "`r----------------------------------" -ForegroundColor Cyan
Write-Host "`nRaptoreum Dashboard Pro 9000 Plus" -ForegroundColor Yellow
Write-Host "`r----------------------------------" -ForegroundColor Cyan
Write-Host "`rChain........................: $($networkInfo.chain)" -ForegroundColor Green
Write-Host "`rLocal/Network block height...: $blockHeight/$networkHeight" -ForegroundColor Green
Write-Host "`rTotal Smartnodes.............: $($smartnodeTotal.count)" -ForegroundColor Green
Write-Host "`rActive Smartnodes............: $($smartnodeList.count)" -ForegroundColor Green
Write-Host "`r----------------------------------" -ForegroundColor Cyan
Write-Host "`rLocal version................: $($smartnodeVersion.ProductVersion)" -ForegroundColor Green
Write-Host "`rAvailable version............: $($latest.tag_name)" -ForegroundColor Green
Write-Host "`rSmartnode connections........: $($connectionCount)" -ForegroundColor Green
Write-Host "`rSmartnode folder size .......: $([math]::Round($folderSize.sum / 1GB, 2)) Gb" -ForegroundColor Green
Write-Host "`rTransactions in mempool......: $($mempoolInfo.size)" -ForegroundColor Green
Write-Host "`rMempool size in Mb...........: $([math]::Round($mempoolInfo.bytes / 1MB, 3)) Mb" -ForegroundColor Green
Write-Host "`r----------------------------------" -ForegroundColor Cyan
Write-Host "`rSmartnode status.............: $($smartnodeStatus.status)" -ForegroundColor Green
Write-Host "`rEstimated reward per day.....: ..." -ForegroundColor Green
Write-Host "`rIP address and port..........: $($smartnodeStatus.service)" -ForegroundColor Green
Write-Host "`rSmartnode ProTX..............: $($smartnodeStatus.proTxHash)" -ForegroundColor Green
Write-Host "`rSmartnode BLS Key............: Censored"-ForegroundColor Green #$bls" -ForegroundColor Green
Write-Host "`rPayout address...............: $($smartnodeStatus.dmnState.payoutAddress)" -ForegroundColor Green
Write-Host "`rRegistered height............: $($smartnodeStatus.dmnState.registeredHeight)" -ForegroundColor Green
Write-Host "`rCurrent PoSe score...........: $($smartnodeStatus.dmnState.PoSePenalty)" -ForegroundColor Green
Write-Host "`rTime to PoSe Score 0.........: $([math]::Floor((($smartnodeStatus.dmnState.PoSePenalty) * 4) / 60))h $(($smartnodeStatus.dmnState.PoSePenalty) * 4 % 60)min" -ForegroundColor Green
Write-Host "`rPoSe ban height..............: $($smartnodeStatus.dmnState.PoSeBanHeight)" -ForegroundColor Green
Write-Host "`rLast revived height..........: $($smartnodeStatus.dmnState.PoSeRevivedHeight)" -ForegroundColor Green
Write-Host "`r----------------------------------" -ForegroundColor Cyan
Write-Host "`rTotal received...............: $([math]::Round($getnettotals.totalbytesrecv / 1MB)) Mb" -ForegroundColor Green
Write-Host "`rTotal sent...................: $([math]::Round($getnettotals.totalbytessent / 1MB, 0)) Mb" -ForegroundColor Green

Start-Sleep -Seconds 10
"Refreshing..."
}
