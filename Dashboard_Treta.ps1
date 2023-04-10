Add-Type -AssemblyName System.Windows.Forms

# Vars
$smartnodecli = $env:raptoreumcli
$raptoreumcli = ""
$serviceName = "RTMService"
$executablePath = "C:\Program Files (x86)\RaptoreumCore\raptoreum-qt.exe"

# Functions
function Execute-Command {
    param($command, $buttonName, $background, $console)

    if ($background) {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command" -WindowStyle Normal
        $console.Clear()
        $timestamp = Get-Date -Format "HH:mm:ss"
        $console.AppendText("[$timestamp] > $buttonName (Executed in a new CMD window) ")
    } else {
        $output = cmd /C $command 2>&1
        $console.Clear()
        $timestamp = Get-Date -Format "HH:mm:ss"
        $console.AppendText("[$timestamp] > $buttonName ")
        $console.AppendText(($output | Out-String))
    }
}

function Execute-WalletCommand {
    param($command, $buttonName, $console)

    $output = cmd /C "$smartnodecli $command" 2>&1
    $console.Clear()
    $timestamp = Get-Date -Format "HH:mm:ss"
    $console.AppendText("[$timestamp] > $buttonName ")
    $console.AppendText(($output | Out-String))
}

function Execute-SmartnodeCommand {
    param($command, $buttonName, $console)

    $output = cmd /C "$smartnodecli smartnode $command" 2>&1
    $console.Clear()
    $timestamp = Get-Date -Format "HH:mm:ss"
    $console.AppendText("[$timestamp] > $buttonName ")
    $console.AppendText(($output | Out-String))
}

# UI
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Raptoreum Tools"
$Form.Size = New-Object System.Drawing.Size(975, 490)
$Form.StartPosition = "CenterScreen"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($executablePath)

$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = New-Object System.Drawing.Point(10, 10)
$TabControl.Size = New-Object System.Drawing.Size(935, 440)
$Form.Controls.Add($TabControl)

$GeneralTab = New-Object System.Windows.Forms.TabPage
$GeneralTab.Text = "General"
$TabControl.Controls.Add($GeneralTab)

$WalletTab = New-Object System.Windows.Forms.TabPage
$WalletTab.Text = "Wallet"
$TabControl.Controls.Add($WalletTab)

$SmartnodeTab = New-Object System.Windows.Forms.TabPage
$SmartnodeTab.Text = "Smartnode"
$TabControl.Controls.Add($SmartnodeTab)

$MinerTab = New-Object System.Windows.Forms.TabPage
$MinerTab.Text = "Miner"
$TabControl.Controls.Add($MinerTab)

$HelpTab = New-Object System.Windows.Forms.TabPage
$HelpTab.Text = "Help"
$TabControl.Controls.Add($HelpTab)

<#
$consoleTextBoxGeneral = New-Object System.Windows.Forms.TextBox
$consoleTextBoxGeneral.Location = New-Object System.Drawing.Point(400, 10)
$consoleTextBoxGeneral.Size = New-Object System.Drawing.Size(520, 400)
$consoleTextBoxGeneral.Multiline = $true
$consoleTextBoxGeneral.ScrollBars = 'Vertical'
$consoleTextBoxGeneral.ReadOnly = $true
$consoleTextBoxGeneral.BackColor = [System.Drawing.Color]::Black
$consoleTextBoxGeneral.ForeColor = [System.Drawing.Color]::Green
$consoleTextBoxGeneral.Font = New-Object System.Drawing.Font("Consolas", 9)
$GeneralTab.Controls.Add($consoleTextBoxGeneral)
#>

$consoleTextBoxSmartnode = New-Object System.Windows.Forms.TextBox
$consoleTextBoxSmartnode.Location = New-Object System.Drawing.Point(400, 10)
$consoleTextBoxSmartnode.Size = New-Object System.Drawing.Size(520, 400)
$consoleTextBoxSmartnode.Multiline = $true
$consoleTextBoxSmartnode.ScrollBars = 'Vertical'
$consoleTextBoxSmartnode.ReadOnly = $true
$consoleTextBoxSmartnode.BackColor = [System.Drawing.Color]::Black
$consoleTextBoxSmartnode.ForeColor = [System.Drawing.Color]::Green
$consoleTextBoxSmartnode.Font = New-Object System.Drawing.Font("Consolas", 9)
$SmartnodeTab.Controls.Add($consoleTextBoxSmartnode)

$consoleTextBoxWallet = New-Object System.Windows.Forms.TextBox
$consoleTextBoxWallet.Location = New-Object System.Drawing.Point(400, 10)
$consoleTextBoxWallet.Size = New-Object System.Drawing.Size(520, 400)
$consoleTextBoxWallet.Multiline = $true
$consoleTextBoxWallet.ScrollBars = 'Vertical'
$consoleTextBoxWallet.ReadOnly = $true
$consoleTextBoxWallet.BackColor = [System.Drawing.Color]::Black
$consoleTextBoxWallet.ForeColor = [System.Drawing.Color]::Green
$consoleTextBoxWallet.Font = New-Object System.Drawing.Font("Consolas", 9)
$WalletTab.Controls.Add($consoleTextBoxWallet)

<#
$consoleTextBoxMiner = New-Object System.Windows.Forms.TextBox
$consoleTextBoxMiner.Location = New-Object System.Drawing.Point(400, 10)
$consoleTextBoxMiner.Size = New-Object System.Drawing.Size(520, 400)
$consoleTextBoxMiner.Multiline = $true
$consoleTextBoxMiner.ScrollBars = 'Vertical'
$consoleTextBoxMiner.ReadOnly = $true
$consoleTextBoxMiner.BackColor = [System.Drawing.Color]::Black
$consoleTextBoxMiner.ForeColor = [System.Drawing.Color]::Green
$consoleTextBoxMiner.Font = New-Object System.Drawing.Font("Consolas", 9)
$MinerTab.Controls.Add($consoleTextBoxMiner)
#>

# General buttons
$buttons = @("Get blockchain info", "Smartnode status")
$top = 10
$left = 10
$width = 350
$height = 40

foreach ($btnText in $buttons) {
    $Button = New-Object System.Windows.Forms.Button
    $Button.Location = New-Object System.Drawing.Point($left, $top)
    $Button.Size = New-Object System.Drawing.Size($width, $height)
    $Button.Text = $btnText
    $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $Button.BackColor = [System.Drawing.Color]::LightGray
    $Button.ForeColor = [System.Drawing.Color]::Black
    $Button.FlatAppearance.BorderSize = 1
    $Button.FlatAppearance.BorderColor = [System.Drawing.Color]::DarkGray
    $Button.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10)
    $Button.Font = New-Object System.Drawing.Font("Consolas", 10)

    switch ($btnText) {
        'Get blockchain info' {
            $Button.Add_Click({
                Execute-WalletCommand -command "getblockchaininfo" -buttonName "Get blockchain info"
            })
        }
        'Smartnode status' {
            $Button.Add_Click({
                Execute-SmartnodeCommand -command "status" -buttonName "Smartnode status"
            })
        }
    }
    $GeneralTab.Controls.Add($Button)
    $top += 40
}

# Wallet tab buttons
$buttons = @("Install Wallet", "Apply a Bootstrap", "Blockchain", "Wallet", "Network", "Mining", "Util", "Evo", "Control", "Rawtransactions", "Zmq")
$top = 10
$left = 10
$width = 350
$height = 40

foreach ($btnText in $buttons) {
    $Button = New-Object System.Windows.Forms.Button
    $Button.Location = New-Object System.Drawing.Point($left, $top)
    $Button.Size = New-Object System.Drawing.Size($width, $height)
    $Button.Text = $btnText
    $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $Button.BackColor = [System.Drawing.Color]::LightGray
    $Button.ForeColor = [System.Drawing.Color]::Black
    $Button.FlatAppearance.BorderSize = 1
    $Button.FlatAppearance.BorderColor = [System.Drawing.Color]::DarkGray
    $Button.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10)
    $Button.Font = New-Object System.Drawing.Font("Consolas", 10)

    switch ($btnText) {
        'Install Wallet' {
            $Button.Add_Click({
                $installWalletUrl = "https://github.com/Raptor3um/raptoreum/releases/download/1.3.17.02/raptoreumcore-1.3.17-win64-setup.exe"
                $installWalletPath = "$env:TEMP\raptoreumcore-win64-setup.exe"                
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($installWalletUrl, $installWalletPath)                
                Execute-Command -command "$installWalletPath"  -background $true -console $consoleTextBoxWallet
            })
        }
        'Apply a Bootstrap' {
            $Button.Add_Click({
                $bootstrapUrl = "https://raw.githubusercontent.com/wizz13150/RaptoreumStuff/main/RTM_Bootstrap.bat"
                $bootstrapPath = "$env:TEMP\RTM_Bootstrap.bat"
        
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($bootstrapUrl, $bootstrapPath)
        
                Execute-Command -command "cmd /c $bootstrapPath"  -background $true -console $consoleTextBoxSmartnode
            })
        }
        'Wallet' {
            $Button.Add_Click({
                $WalletMenu = New-Object System.Windows.Forms.ContextMenuStrip
                
                $NewWalletItem = New-Object System.Windows.Forms.ToolStripMenuItem
                $NewWalletItem.Text = "Generate a new address"
                $NewWalletItem.Add_Click({
                    Execute-WalletCommand -command "getnewaddress" -buttonName "Generate a new address" -console $consoleTextBoxWallet
                })
                $WalletMenu.Items.Add($NewWalletItem)
                
                $ListWalletItem = New-Object System.Windows.Forms.ToolStripMenuItem
                $ListWalletItem.Text = "List wallets"
                $ListWalletItem.Add_Click({
                    Execute-WalletCommand -command "listreceivedbyaddress" -buttonName "List wallets" -console $consoleTextBoxWallet
                })
                $WalletMenu.Items.Add($ListWalletItem)
                
                $SendCoinsItem = New-Object System.Windows.Forms.ToolStripMenuItem
                $SendCoinsItem.Text = "Send coins"
                $SendCoinsItem.Add_Click({
                    $form = New-Object System.Windows.Forms.Form
                    $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($executablePath)
                    $form.Text = "Send coins"
                    $form.Width = 315
                    $form.Height = 290
                    $form.StartPosition = "CenterScreen"
    
                    $recipientLabel = New-Object System.Windows.Forms.Label
                    $recipientLabel.Location = New-Object System.Drawing.Point(10, 20)
                    $recipientLabel.Size = New-Object System.Drawing.Size(280, 20)
                    $recipientLabel.Text = "Recipient Address:"
                    $form.Controls.Add($recipientLabel)
    
                    $recipientTextBox = New-Object System.Windows.Forms.TextBox
                    $recipientTextBox.Location = New-Object System.Drawing.Point(10, 50)
                    $recipientTextBox.Size = New-Object System.Drawing.Size(280, 20)
                    $form.Controls.Add($recipientTextBox)
    
                    $amountLabel = New-Object System.Windows.Forms.Label
                    $amountLabel.Location = New-Object System.Drawing.Point(10, 80)
                    $amountLabel.Size = New-Object System.Drawing.Size(280, 20)
                    $amountLabel.Text = "Amount:"
                    $form.Controls.Add($amountLabel)
    
                    $amountTextBox = New-Object System.Windows.Forms.TextBox
                    $amountTextBox.Location = New-Object System.Drawing.Point(10, 110)
                    $amountTextBox.Size = New-Object System.Drawing.Size(280, 20)
                    $form.Controls.Add($amountTextBox)
    
                    $commentLabel = New-Object System.Windows.Forms.Label
                    $commentLabel.Location = New-Object System.Drawing.Point(10, 140)
                    $commentLabel.Size = New-Object System.Drawing.Size(280, 20)
                    $commentLabel.Text = "Optional Comment:"
                    $form.Controls.Add($commentLabel)
    
                    $commentTextBox = New-Object System.Windows.Forms.TextBox
                    $commentTextBox.Location = New-Object System.Drawing.Point(10, 170)
                    $commentTextBox.Size = New-Object System.Drawing.Size(280, 20)
                    $form.Controls.Add($commentTextBox)
    
                    $okButton = New-Object System.Windows.Forms.Button
                    $okButton.Location = New-Object System.Drawing.Point(80, 210)
                    $okButton.Size = New-Object System.Drawing.Size(60, 30)
                    $okButton.Text = "OK"
                    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
                    $form.Controls.Add($okButton)
    
                    $cancelButton = New-Object System.Windows.Forms.Button
                    $cancelButton.Location = New-Object System.Drawing.Point(160, 210)
                    $cancelButton.Size = New-Object System.Drawing.Size(60, 30)
                    $cancelButton.Text = "Cancel"
                    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
                    $form.Controls.Add($cancelButton)
    
                    $form.AcceptButton = $okButton
                    $form.CancelButton = $cancelButton
    
                    $result = $form.ShowDialog()
    
                    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                        $recipient = $recipientTextBox.Text
                        $amount = $amountTextBox.Text
                        $comment = $commentTextBox.Text
                        Execute-WalletCommand -command "sendtoaddress $recipient $amount '$comment'" -buttonName "Send coins" -console $consoleTextBoxWallet
                    }
                })
                $WalletMenu.Items.Add($SendCoinsItem)

                $WalletMenu.Show($Button, $Button.PointToClient([System.Windows.Forms.Cursor]::Position))
                $Button.ContextMenuStrip = $WalletMenu
            })
        }

    }
    $WalletTab.Controls.Add($Button)
    $top += 40
}

# Smartnode tab buttons
$buttons = @("Install Smartnode","Get blockchain info", "Smartnode status", "Start daemon", "Stop daemon", "Get daemon status", "Open a Bash", "Update Smartnode", "Edit Smartnode Config File")
$top = 10
$left = 10
$width = 350
$height = 40

foreach ($btnText in $buttons) {
    $Button = New-Object System.Windows.Forms.Button
    $Button.Location = New-Object System.Drawing.Point($left, $top)
    $Button.Size = New-Object System.Drawing.Size($width, $height)
    $Button.Text = $btnText
    $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $Button.BackColor = [System.Drawing.Color]::LightGray
    $Button.ForeColor = [System.Drawing.Color]::Black
    $Button.FlatAppearance.BorderSize = 1
    $Button.FlatAppearance.BorderColor = [System.Drawing.Color]::DarkGray
    $Button.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10)
    $Button.Font = New-Object System.Drawing.Font("Consolas", 10)

    switch ($btnText) {
        'Install Smartnode' {
            $Button.Add_Click({
                $installSmartnodeUrl = "https://raw.githubusercontent.com/wizz13150/Raptoreum_Smartnode/main/SmartNode_Install.bat"
                $installSmartnodePath = "$env:TEMP\rtm_smartnode_installer.bat"
        
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($installSmartnodeUrl, $installSmartnodePath)
        
                Execute-Command -command "cmd /c $installSmartnodePath"  -background $true -console $consoleTextBoxSmartnode
            })
        }
        'Get blockchain info' {
            $Button.Add_Click({
                Execute-WalletCommand -command "getblockchaininfo" -buttonName "Get blockchain info" -console $consoleTextBoxSmartnode
            })
        }
        'Smartnode status' {
            $Button.Add_Click({
                Execute-SmartnodeCommand -command "status" -buttonName "Smartnode status" -console $consoleTextBoxSmartnode
            })
        }
        'Start daemon' {
            $Button.Add_Click({
                Execute-Command -command "net start $serviceName" -buttonName "Start daemon" -console $consoleTextBoxSmartnode
            })
        }
        'Stop daemon' {
            $Button.Add_Click({
                Execute-Command -command "net stop $serviceName" -buttonName "Stop daemon" -console $consoleTextBoxSmartnode
            })
        }
        'Get daemon status' {
            $Button.Add_Click({
                Execute-Command -command "sc query $serviceName" -buttonName "Get daemon status" -console $consoleTextBoxSmartnode
            })
        }
        'Open a Bash' {
            $Button.Add_Click({
                Execute-Command -command "start cmd.exe /k type $env:USERPROFILE\RTM-MOTD.txt" -buttonName 'Open a Bash' -background $true -console $consoleTextBoxSmartnode
            })
        }
        'Update Smartnode' {
            $Button.Add_Click({
                Execute-Command -command "powershell.exe -ExecutionPolicy Bypass -File $env:USERPROFILE\update.ps1" -buttonName 'Update Smartnode' -background $true -console $consoleTextBoxSmartnode
            })
        }
        'Edit Smartnode Config File' {
            $Button.Add_Click({
                Execute-Command -command "notepad `"$env:APPDATA\RaptoreumSmartnode\raptoreum.conf`"" -buttonName "Edit Smartnode Config File" -console $consoleTextBoxSmartnode
            })
        }
    }
    $SmartnodeTab.Controls.Add($Button)
    $top += 40
}


# Miner tab buttons
$buttons = @("Download XMRig", "Download CPuminer", "Use XMRig", "Use CPuminer")
$top = 10
$left = 10
$width = 120
$height = 40

foreach ($btnText in $buttons) {
    $Button = New-Object System.Windows.Forms.Button
    $Button.Location = New-Object System.Drawing.Point($left, $top)
    $Button.Size = New-Object System.Drawing.Size($width, $height)
    $Button.Text = $btnText
    $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $Button.BackColor = [System.Drawing.Color]::LightGray
    $Button.ForeColor = [System.Drawing.Color]::Black
    $Button.FlatAppearance.BorderSize = 1
    $Button.FlatAppearance.BorderColor = [System.Drawing.Color]::DarkGray
    $Button.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10)
    $Button.Font = New-Object System.Drawing.Font("Consolas", 10)

    switch ($btnText) {
        'Download XMRig' {
            $Button.Add_Click({
                $tempDir = [System.IO.Path]::GetTempPath()
                $xmrigZip = "$tempDir\xmrig.zip"
                $xmrigFolder = "$tempDir\xmrig"
                $uri = "https://api.github.com/repos/xmrig/xmrig/releases/latest"
                $response = Invoke-RestMethod -Uri $uri
                $latestVersion = $response.tag_name
                $xmrigDownloadUrl = "https://github.com/xmrig/xmrig/releases/tag/$latestVersion"
                if ($xmrigDownloadUrl -eq $null) {
                    [System.Windows.Forms.MessageBox]::Show("An error occurred while retrieving the download link for XMRig.", "XMRig Download", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    return
                }
                try {
                    Invoke-WebRequest -Uri $xmrigDownloadUrl -OutFile $xmrigZip
                    Expand-Archive -LiteralPath $xmrigZip -DestinationPath $xmrigFolder -Force
                    [System.Windows.Forms.MessageBox]::Show("XMRig downloaded and extracted successfully to $xmrigFolder.", "XMRig Download", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show("An error occurred while downloading or extracting XMRig.`r`nError message: $($Error[0].Exception.Message)", "XMRig Download", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            })
        }
        'Download CPuminer' {
            $Button.Add_Click({
                $tempDir = [System.IO.Path]::GetTempPath()
                $cpuminerZip = "$tempDir\cpuminer.zip"
                $cpuminerFolder = "$tempDir\cpuminer"
                $uri = "https://api.github.com/repos/WyvernTKC/cpuminer-gr-avx2/releases/latest"
                $response = Invoke-RestMethod -Uri $uri
                $latestVersion = $response.tag_name
                $cpuminerDownloadUrl = "https://github.com/WyvernTKC/cpuminer-gr-avx2/releases/tag/$latestVersion"
                if ($cpuminerDownloadUrl -eq $null) {
                    [System.Windows.Forms.MessageBox]::Show("An error occurred while retrieving the download link for CPUMiner.", "CPUMiner Download", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    return
                }
                try {
                    Invoke-WebRequest -Uri $cpuminerDownloadUrl -OutFile $cpuminerZip
                    Expand-Archive -LiteralPath $cpuminerZip -DestinationPath $cpuminerFolder -Force
                    [System.Windows.Forms.MessageBox]::Show("CPUMiner downloaded and extracted successfully to $cpuminerFolder.", "CPUMiner Download", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show("An error occurred while downloading or extracting CPUMiner.`r`nError message: $($Error[0].Exception.Message)", "CPUMiner Download", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            })
        }
        'Use XMRig' {
            $Button.Add_Click({
                # Ajoutez ici le code pour utiliser XMRig
                $pool = $PoolTextBox.Text
                $user = $UserTextBox.Text
                $pass = $PassTextBox.Text
                $threads = $ThreadsTextBox.Text
                Execute-Command -command "$tempDir\xmrig\xmrig.exe -o $pool -u $user -p $pass -t $threads" -buttonName "XMRig Run"
            })
        }
        'Use CPuminer' {
            $Button.Add_Click({
                # Ajoutez ici le code pour utiliser CPuminer
                $pool = $PoolTextBox.Text
                $user = $UserTextBox.Text
                $pass = $PassTextBox.Text
                $threads = $ThreadsTextBox.Text
                Execute-Command -command "$tempDir\cpuminer\cpuminer.exe -o $pool -u $user -p $pass -t $threads" -buttonName "CPuminer Run"
            })
        }
    }
    $MinerTab.Controls.Add($Button)
    $top += 40
}

# Ajoutez les champs de formulaire et le bouton pour lancer le mineur
$PoolLabel = New-Object System.Windows.Forms.Label
$PoolLabel.Location = New-Object System.Drawing.Point(200, 10)
$PoolLabel.Size = New-Object System.Drawing.Size(50, 20)
$PoolLabel.Text = "Pool:"
$MinerTab.Controls.Add($PoolLabel)

$PoolTextBox = New-Object System.Windows.Forms.TextBox
$PoolTextBox.Location = New-Object System.Drawing.Point(260, 10)
$PoolTextBox.Size = New-Object System.Drawing.Size(200, 20)
$MinerTab.Controls.Add($PoolTextBox)

$UserLabel = New-Object System.Windows.Forms.Label
$UserLabel.Location = New-Object System.Drawing.Point(200, 40)
$UserLabel.Size = New-Object System.Drawing.Size(50, 20)
$UserLabel.Text = "User:"
$MinerTab.Controls.Add($UserLabel)

$UserTextBox = New-Object System.Windows.Forms.TextBox
$UserTextBox.Location = New-Object System.Drawing.Point(260, 40)
$UserTextBox.Size = New-Object System.Drawing.Size(200, 20)
$MinerTab.Controls.Add($UserTextBox)

$PassLabel = New-Object System.Windows.Forms.Label
$PassLabel.Location = New-Object System.Drawing.Point(200, 70)
$PassLabel.Size = New-Object System.Drawing.Size(50, 20)
$PassLabel.Text = "Pass:"
$MinerTab.Controls.Add($PassLabel)

$PassTextBox = New-Object System.Windows.Forms.TextBox
$PassTextBox.Location = New-Object System.Drawing.Point(260, 70)
$PassTextBox.Size = New-Object System.Drawing.Size(200, 20)
$MinerTab.Controls.Add($PassTextBox)

$ThreadsLabel = New-Object System.Windows.Forms.Label
$ThreadsLabel.Location = New-Object System.Drawing.Point(200, 100)
$ThreadsLabel.Size = New-Object System.Drawing.Size(50, 20)
$ThreadsLabel.Text = "Threads:"
$MinerTab.Controls.Add($ThreadsLabel)

$ThreadsTextBox = New-Object System.Windows.Forms.TextBox
$ThreadsTextBox.Location = New-Object System.Drawing.Point(260, 100)
$ThreadsTextBox.Size = New-Object System.Drawing.Size(200, 20)
$MinerTab.Controls.Add($ThreadsTextBox)

$ConsoleTextBox = New-Object System.Windows.Forms.TextBox
$ConsoleTextBox.Location = New-Object System.Drawing.Point(10, 150)
$ConsoleTextBox.Size = New-Object System.Drawing.Size(650, 300)
$ConsoleTextBox.Multiline = $true
$ConsoleTextBox.ReadOnly = $true
$ConsoleTextBox.BackColor = [System.Drawing.Color]::White
$ConsoleTextBox.ForeColor = [System.Drawing.Color]::Black
$ConsoleTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$MinerTab.Controls.Add($ConsoleTextBox)

$LaunchButton = New-Object System.Windows.Forms.Button
$LaunchButton.Location = New-Object System.Drawing.Point(480, 10)
$LaunchButton.Size = New-Object System.Drawing.Size(180, 120)
$LaunchButton.Text = "Launch Miner"
$LaunchButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
$LaunchButton.BackColor = [System.Drawing.Color]::LightGray
$LaunchButton.Font = New-Object System.Drawing.Font("Consolas", 10)
$MinerTab.Controls.Add($LaunchButton)


# Help tab buttons
$buttons = @("Raptoreum Website", "Raptoreum Documentation", "Raptoreum on Twitter", "Raptoreum Discord", "Raptoreum on Reddit")
$top = 10
$left = 10
$width = 350
$height = 40

foreach ($btnText in $buttons) {
    $Button = New-Object System.Windows.Forms.Button
    $Button.Location = New-Object System.Drawing.Point($left, $top)
    $Button.Size = New-Object System.Drawing.Size($width, $height)
    $Button.Text = $btnText
    $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $Button.BackColor = [System.Drawing.Color]::LightGray
    $Button.ForeColor = [System.Drawing.Color]::Black
    $Button.FlatAppearance.BorderSize = 1
    $Button.FlatAppearance.BorderColor = [System.Drawing.Color]::DarkGray
    $Button.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10)
    $Button.Font = New-Object System.Drawing.Font("Consolas", 10)

    switch ($btnText) {
        'Raptoreum Website' {
            $Button.Add_Click({
                Execute-Command -command "start https://raptoreum.com" -buttonName "Raptoreum Website"
            })
        }
        'Raptoreum Documentation' {
            $Button.Add_Click({
                Execute-Command -command "start https://docs.raptoreum.com" -buttonName "Raptoreum Documentation"
            })
        }
        'Raptoreum on Twitter' {
            $Button.Add_Click({
                Execute-Command -command "start https://twitter.com/Raptoreum" -buttonName "Raptoreum on Twitter"
            })
        }
        'Raptoreum Discord' {
            $Button.Add_Click({
                Execute-Command -command "start https://discord.gg/RKefY9C" -buttonName "Raptoreum Discord"
            })
        }
        'Raptoreum on Reddit' {
            $Button.Add_Click({
                Execute-Command -command "start https://www.reddit.com/r/raptoreum/" -buttonName "Raptoreum on Reddit"
            })
        }
    }
    $HelpTab.Controls.Add($Button)
    $top += 40
}

$Form.Controls.Add($TabControl)
$Form.Add_Shown({$Form.Activate()})
[void]$Form.ShowDialog()
