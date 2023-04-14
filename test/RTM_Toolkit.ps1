Add-Type -AssemblyName System.Windows.Forms

# Vars
$smartnodecli = $env:raptoreumcli
$raptoreumcli = "E:\Raptoreum\Wallet1.3.17.02\raptoreum-cli.exe -conf=E:\Raptoreum\Wallet\raptoreum.conf"
$serviceName = "RTMService"
$executablePath = "E:\Raptoreum\Wallet1.3.17.02\raptoreum-qt.exe"

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
        $console.AppendText("[$timestamp] > $command  `n")
        $console.AppendText(($output | Out-String))
    }
}

function Execute-WalletCommand {
    param($command, $buttonName, $console, $parameters)

    $output = cmd /C "$raptoreumcli $command $parameters" 2>&1
    $console.Clear()
    $timestamp = Get-Date -Format "HH:mm:ss"
    $console.AppendText("[$timestamp] > $command $parameters `n")
    $console.AppendText(($output | Out-String))
}

function Print-Command {
    param($command, $console, $parameters)

    $console.Clear()
    $timestamp = Get-Date -Format "HH:mm:ss"
    $console.AppendText("[$timestamp] > $command $parameters `n")
}

function Execute-SmartnodeCommand {
    param($command, $buttonName, $console)

    $output = cmd /C "$smartnodecli smartnode $command" 2>&1
    $console.Clear()
    $timestamp = Get-Date -Format "HH:mm:ss"
    $console.AppendText("[$timestamp] > smartnode $command  `n")
    $console.AppendText(($output | Out-String))
}

function SaveFormData {
    $config = @{
        Pool     = $PoolTextBox.Text
        User     = $UserTextBox.Text
        Pass     = $PassTextBox.Text
        Threads = $ThreadsTrackBar.Value
    }
    $json = ConvertTo-Json $config
    Set-Content -Path "configminers.json" -Value $json
}

function LoadFormData {
    if (Test-Path "configminers.json") {
        $json = Get-Content -Path "configminers.json" -Raw
        $config = ConvertFrom-Json $json
        $PoolTextBox.Text = $config.Pool
        $UserTextBox.Text = $config.User
        $PassTextBox.Text = $config.Pass
        $ThreadsTrackBar.Value = $config.threads
        $SelectedThreadsLabel.Text = $config.Threads
    } else {
        $PoolTextBox.Text = "stratum+tcp://eu.flockpool.com:4444"
        $UserTextBox.Text = "RMRwCAkSJaWHGPiP1rF5EHuUYDTze2xw6J.wizz"
        $PassTextBox.Text = "tototo"
        $ThreadsTrackBar.Value = "4"
        $SelectedThreadsLabel.Text = "4"
    }
}

function Show-CommandParametersForm {
    param(
        [string]$command,
        [hashtable]$commandParameters,
        [System.Windows.Forms.TextBox]$console
    )

    if ($commandParameters.ContainsKey($command)) {
        $parameters = $commandParameters[$command]
        $requiredParameters = $parameters['required']
        $optionalParameters = $parameters['optional']
        $types = $parameters['types']
        $totalParameters = $requiredParameters.Count + $optionalParameters.Count
        $form = New-Object System.Windows.Forms.Form
        $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($executablePath)
        $form.Text = $command
        $form.Width = 315
        $form.StartPosition = "CenterScreen"
        $y = 10
        if ($requiredParameters.Count -eq 0) {
            $messageLabel = New-Object System.Windows.Forms.Label
            $messageLabel.Location = New-Object System.Drawing.Point(10, $y)
            $messageLabel.Size = New-Object System.Drawing.Size(280, 20)
            $messageLabel.Text = "No Required parameter, you can directly click OK"
            $form.Controls.Add($messageLabel)
            $y += 30
        }
        for ($i = 0; $i -lt $requiredParameters.Count; $i++) {
            $paramName = $requiredParameters[$i]
            $currentType = $types[$paramName]
            $label = New-Object System.Windows.Forms.Label
            $label.Location = New-Object System.Drawing.Point(10, $y)
            $label.Size = New-Object System.Drawing.Size(280, 20)
            if ($currentType.type.ToLower() -eq 'boolean') {
                $label.Text = $paramName + ' (Required, ' + $currentType.type + ', Default:' + $currentType.defaultValue + '):'
            } else {
                $label.Text = $paramName + ' (Required, ' + $currentType.type + '):'
            }
            $form.Controls.Add($label)
            $y += 20
            if ($currentType.type.ToLower() -eq 'subparameters') {
                $subparameters = $currentType.subparameters
                $subParamValues = @{}
                foreach ($subParamName in $subparameters.Keys) {
                    $subParamType = $subparameters[$subParamName]
                    $subLabel = New-Object System.Windows.Forms.Label
                    $subLabel.Location = New-Object System.Drawing.Point(30, $y)
                    $subLabel.Size = New-Object System.Drawing.Size(260, 20)
                    $subLabel.Text = $subParamName + ' (' + $subParamType.type + '):'
                    $form.Controls.Add($subLabel)
                    $y += 20
                    if ($subParamType.type.ToLower() -eq 'boolean') {
                        $subComboBox = New-Object System.Windows.Forms.ComboBox
                        $subComboBox.Location = New-Object System.Drawing.Point(30, $y)
                        $subComboBox.Size = New-Object System.Drawing.Size(260, 20)
                        $subComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
                        $subComboBox.Items.AddRange(@('true', 'false'))
                        $subComboBox.SelectedItem = $subParamType.defaultValue
                        $form.Controls.Add($subComboBox)
                        $subParamValues.Add($subParamName, $subComboBox)
                    } else {
                        $subTextBox = New-Object System.Windows.Forms.TextBox
                        $subTextBox.Location = New-Object System.Drawing.Point(30, $y)
                        $subTextBox.Size = New-Object System.Drawing.Size(260, 20)
                        $form.Controls.Add($subTextBox)
                        $subParamValues.Add($subParamName, $subTextBox)
                    }
                    $y += 10
                }
                $currentType.subParamControls = $subParamValues
            } elseif ($currentType.type.ToLower() -eq 'boolean') {
                $comboBox = New-Object System.Windows.Forms.ComboBox
                $comboBox.Location = New-Object System.Drawing.Point(10, $y)
                $comboBox.Size = New-Object System.Drawing.Size(280, 20)
                $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
                $comboBox.Items.AddRange(@('true', 'false'))
                $comboBox.SelectedItem = $currentType.defaultValue
                $form.Controls.Add($comboBox)
            } elseif ($currentType.type.ToLower() -eq 'choices') {
                $comboBox = New-Object System.Windows.Forms.ComboBox
                $comboBox.Location = New-Object System.Drawing.Point(10, $y)
                $comboBox.Size = New-Object System.Drawing.Size(280, 20)
                $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
                foreach ($choice in $currentType.choices) {
                    $comboBox.Items.Add($choice)
                }
                if ($currentType.defaultValue) {
                    $comboBox.SelectedItem = $currentType.defaultValue
                }
                $form.Controls.Add($comboBox)
            } else {
                $textBox = New-Object System.Windows.Forms.TextBox
                $textBox.Location = New-Object System.Drawing.Point(10, $y)
                $textBox.Size = New-Object System.Drawing.Size(280, 20)
                $form.Controls.Add($textBox)
            }
            $y += 30
        }
        for ($i = 0; $i -lt $optionalParameters.Count; $i++) {
            $paramName = $optionalParameters[$i]
            $currentType = $types[$paramName]
            $label = New-Object System.Windows.Forms.Label
            $label.Location = New-Object System.Drawing.Point(10, $y)
            $label.Size = New-Object System.Drawing.Size(280, 20)
            if ($currentType -eq 'boolean') {
                $label.Text = $paramName + ' (Optional, ' + $currentType.type + ', Default:' + $currentType.defaultValue + '):'
            } else {
                $label.Text = $paramName + ' (Optional, ' + $currentType.type + '):'
            }
            $form.Controls.Add($label)
            $y += 20
            if ($currentType.type.ToLower() -eq 'subparameters') {
                $subparameters = $currentType.subparameters
                $subParamValues = @{}
                foreach ($subParamName in $subparameters.Keys) {
                    $subParamType = $subparameters[$subParamName]
                    $subLabel = New-Object System.Windows.Forms.Label
                    $subLabel.Location = New-Object System.Drawing.Point(30, $y)
                    $subLabel.Size = New-Object System.Drawing.Size(260, 20)
                    $subLabel.Text = $subParamName + ' (' + $subParamType.type + '):'
                    $form.Controls.Add($subLabel)
                    $y += 20
                    if ($subParamType.type.ToLower() -eq 'boolean') {
                        $subComboBox = New-Object System.Windows.Forms.ComboBox
                        $subComboBox.Location = New-Object System.Drawing.Point(30, $y)
                        $subComboBox.Size = New-Object System.Drawing.Size(260, 20)
                        $subComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
                        $subComboBox.Items.AddRange(@('true', 'false'))
                        $subComboBox.SelectedItem = $subParamType.defaultValue
                        $form.Controls.Add($subComboBox)
                        $subParamValues.Add($subParamName, $subComboBox)
                    } else {
                        $subTextBox = New-Object System.Windows.Forms.TextBox
                        $subTextBox.Location = New-Object System.Drawing.Point(30, $y)
                        $subTextBox.Size = New-Object System.Drawing.Size(260, 20)
                        $form.Controls.Add($subTextBox)
                        $subParamValues.Add($subParamName, $subTextBox)
                    }
                    $y += 10
                }
                $currentType.subParamControls = $subParamValues
            } elseif ($currentType -is [hashtable] -and $currentType.type.ToLower() -eq 'boolean') {
                $comboBox = New-Object System.Windows.Forms.ComboBox
                $comboBox.Location = New-Object System.Drawing.Point(10, $y)
                $comboBox.Size = New-Object System.Drawing.Size(280, 20)
                $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
                $comboBox.Items.AddRange(@('true', 'false'))
                $comboBox.SelectedItem = $currentType.defaultValue
                $form.Controls.Add($comboBox)
            } elseif ($currentType.type.ToLower() -eq 'choices') {
                $comboBox = New-Object System.Windows.Forms.ComboBox
                $comboBox.Location = New-Object System.Drawing.Point(10, $y)
                $comboBox.Size = New-Object System.Drawing.Size(280, 20)
                $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
                foreach ($choice in $currentType.choices) {
                    $comboBox.Items.Add($choice)
                }
                if ($currentType.defaultValue) {
                    $comboBox.SelectedItem = $currentType.defaultValue
                }
                $form.Controls.Add($comboBox)
            } else {
                $textBox = New-Object System.Windows.Forms.TextBox
                $textBox.Location = New-Object System.Drawing.Point(10, $y)
                $textBox.Size = New-Object System.Drawing.Size(280, 20)
                $form.Controls.Add($textBox)
            }
            $y += 30
        }
        if ($requiredParameters.Count -eq 0) {
            $baseHeight = 180
        } else {
            $baseHeight = 150
        }

        $heightAdjustment = 50 * ($totalParameters- 1)
        foreach ($subParamName in $subparameters.Keys) {
            $heightAdjustment += 60
        }
        $form.Height = $baseHeight + $heightAdjustment

        $form.AcceptButton = $okButton
        $form.CancelButton = $cancelButton

        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Text = 'OK'
        $okButton.Location = New-Object System.Drawing.Point(10, $y)
        $okButton.Size = New-Object System.Drawing.Size(75, 25)
        $okButton.Add_Click({
            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Close()
        })
        $form.Controls.Add($okButton)

        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Text = 'Cancel'
        $cancelButton.Location = New-Object System.Drawing.Point(95, $y)
        $cancelButton.Size = New-Object System.Drawing.Size(75, 25)
        $cancelButton.Add_Click({
            $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $form.Close()
        })
        $form.Controls.Add($cancelButton)

        $helpButton = New-Object System.Windows.Forms.Button
        $helpButton.Text = 'Print Help'
        $helpButton.Location = New-Object System.Drawing.Point(180, $y)
        $helpButton.Size = New-Object System.Drawing.Size(75, 25)
        $helpButton.Add_Click({
            Execute-WalletCommand -command "help $command" -buttonName $command -console $consoleTextBoxWallet
            $form.Close()
        })
        $form.Controls.Add($helpButton)

        $y += 30
        $printWithoutRunningCheckbox = New-Object System.Windows.Forms.CheckBox
        $printWithoutRunningCheckbox.Text = "Show the Raw Command, without running it"
        $printWithoutRunningCheckbox.Location = New-Object System.Drawing.Point(10, $y)
        $printWithoutRunningCheckbox.Size = New-Object System.Drawing.Size(300, 20)
        $form.Controls.Add($printWithoutRunningCheckbox)

        $form.AcceptButton = $okButton
        $form.CancelButton = $cancelButton
        $formResult = $form.ShowDialog()

        if ($formResult  -eq [System.Windows.Forms.DialogResult]::OK -or !$formResult ) {
            $requiredValues = @()
            $optionalValues = @()
            for ($i = 0; $i -lt $requiredParameters.Count; $i++) {
                if ($types[$requiredParameters[$i]].type.ToLower() -eq 'boolean') {
                    $comboBox = $form.Controls | Where-Object { $_.GetType() -eq [System.Windows.Forms.ComboBox] -and $_.Location.Y -eq (($_.Location.Y - 20) / 30) * 30 + 20 }
                    if ($comboBox -and $comboBox[$i - $requiredParameters.Count]) {
                        $requiredValues += $comboBox[$i].SelectedItem.ToString()
                    }
                } else {
                    $textBox = $form.Controls | Where-Object { $_.GetType() -eq [System.Windows.Forms.TextBox] -and $_.Location.Y -eq (($_.Location.Y - 20) / 30) * 30 + 20 }
                    if ($types[$requiredParameters[$i]].type.ToLower() -eq 'string' -and $textBox[$i].Text -eq '') {
                        $requiredValues += '""'
                    }
                    elseif ($types[$requiredParameters[$i]].type.ToLower() -ne 'string' -and $textBox[$i].Text -eq '') {
                        continue
                    }
                    else {
                        $requiredValues += $textBox[$i].Text
                    }
                }
            }
            for ($i = 0; $i -lt $optionalParameters.Count; $i++) {
                if ($types[$optionalParameters[$i]].type.ToLower() -eq 'boolean') {
                    $comboBox = $form.Controls | Where-Object { $_.GetType() -eq [System.Windows.Forms.ComboBox] -and $_.Location.Y -eq (($_.Location.Y - 20) / 30) * 30 + 20 }
                    if ($comboBox -and $comboBox[$i - $requiredParameters.Count]) {
                        $optionalValues += $comboBox[$i - $requiredParameters.Count].SelectedItem.ToString()
                    }
                } else {
                    $textBox = $form.Controls | Where-Object { $_.GetType() -eq [System.Windows.Forms.TextBox] -and $_.Location.Y -eq (($_.Location.Y - 20) / 30) * 30 + 20 }
                    if ($types[$optionalParameters[$i]].type.ToLower() -eq 'string' -and $textBox[$i + $requiredParameters.Count].Text -eq '') {
                        $optionalValues += '""'
                    }
                    elseif ($types[$optionalParameters[$i]].type.ToLower() -ne 'string' -and $textBox[$i + $requiredParameters.Count].Text -eq '') {
                        continue
                    }
                    else {
                        $textBox = $form.Controls | Where-Object { $_.GetType() -eq [System.Windows.Forms.TextBox] -and $_.Location.Y -eq (($_.Location.Y - 20) / 30) * 30 + 20 }
                        if ($textBox[$i + $requiredParameters.Count].Text -ne '' -or $types[$optionalParameters[$i]].type.ToLower() -eq 'string') {
                            $optionalValues += $textBox[$i + $requiredParameters.Count].Text
                        }
                    }
                }
                $parameters = $requiredValues + $optionalValues
                if ($requiredValues.Count -eq 0) {
                    if ($printWithoutRunningCheckbox.Checked) {
                        Print-Command -command $command -console $consoleTextBoxWallet
                    } else {
                        Execute-WalletCommand -command $command -buttonName $command -console $consoleTextBoxWallet
                    }
                } else {
                    $commandString = "$command " + ($parameters -join ' ')
                    if ($printWithoutRunningCheckbox.Checked) {
                        Print-Command -command $commandString -console $consoleTextBoxWallet
                    } else {
                        Execute-WalletCommand -command $commandString -buttonName $command -console $consoleTextBoxWallet
                    }
                }
            }
        }
    }
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
$GeneralTab.Text = "General (todo)"
$TabControl.Controls.Add($GeneralTab)

$WalletTab = New-Object System.Windows.Forms.TabPage
$WalletTab.Text = "Wallet (todo)"
$TabControl.Controls.Add($WalletTab)

$SmartnodeTab = New-Object System.Windows.Forms.TabPage
$SmartnodeTab.Text = "Smartnode"
$TabControl.Controls.Add($SmartnodeTab)

$MinerTab = New-Object System.Windows.Forms.TabPage
$MinerTab.Text = "Mining"
$TabControl.Controls.Add($MinerTab)

$HelpTab = New-Object System.Windows.Forms.TabPage
$HelpTab.Text = "Help & Community"
$TabControl.Controls.Add($HelpTab)

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

# General buttons
$buttons = @("Button 1", "Button 2")
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
$buttons = @("Install Wallet", "Apply a Bootstrap (admin todo)", "Blockchain", "Wallet", "Network", "Mining", "Util", "Evo", "Control", "Rawtransactions", "Zmq")
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
            # Limit menu height
            $dummyMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $dummyMenuItem.Text = "Dummy"
            $walletMenu.Items.Add($dummyMenuItem)
            $maxVisibleItems = 25
            $menuItemHeight = $dummyMenuItem.GetPreferredSize([System.Drawing.Size]::Empty).Height
            $maxHeight = $maxVisibleItems * $menuItemHeight
            $walletMenu.MaximumSize = New-Object System.Drawing.Size(0, $maxHeight)
            $walletMenu.Items.Remove($dummyMenuItem)
            
            # backupwallet
            $BackupWalletItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $BackupWalletItem.Text = "Backup wallet"
            $BackupWalletItem.Add_Click({
                $command = 'backupwallet'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Destination')
                        'optional' = @()
                        'types' = @{
                            'Destination' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -buttonName 'Backup wallet' -console $consoleTextBoxWallet
            })
            $WalletMenu.Items.Add($BackupWalletItem)

            # createwallet
            $CreateWalletItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $CreateWalletItem.Text = "Create wallet"
            $CreateWalletItem.Add_Click({
                $command = 'createwallet'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Wallet Name')
                        'optional' = @()
                        'types' = @{
                            'Wallet Name' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -buttonName 'Create wallet' -console $consoleTextBoxWallet
            })
            $WalletMenu.Items.Add($CreateWalletItem)

            # getaddressinfo
            $GetAddressInfoItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetAddressInfoItem.Text = "Get address info"
            $GetAddressInfoItem.Add_Click({
                $command = 'getaddressinfo'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Address')
                        'optional' = @()
                        'types' = @{
                            'Address' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -buttonName 'Get address info' -console $consoleTextBoxWallet
            })
            $WalletMenu.Items.Add($GetAddressInfoItem)

            # getbalance
            $GetBalanceItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetBalanceItem.Text = "Get balance"
            $GetBalanceItem.Add_Click({
                $command = 'getbalance'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @('Dummy', 'Min Confirmations', 'Add Locked', 'Include Watch Only')
                        'types' = @{
                            'Dummy' = @{
                                'type' = 'string'
                                'defaultValue' = '*'
                            }
                            'Min Confirmations' = @{
                                'type' = 'int'
                                'defaultValue' = 1
                            }
                            'Add Locked' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                            'Include Watch Only' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                        }
                    }
                }
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -buttonName 'Get balance' -console $consoleTextBoxWallet
            })
            $WalletMenu.Items.Add($GetBalanceItem)

            # getnewaddress
            $GetNewAddressItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetNewAddressItem.Text = "Get new address"
            $GetNewAddressItem.Add_Click({
                $command = 'getnewaddress'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @('Label')
                        'types' = @{
                            'Label' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -buttonName 'Get new address' -console $consoleTextBoxWallet
            })
            $WalletMenu.Items.Add($GetNewAddressItem)

            # gettransaction
            $GetTransactionItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetTransactionItem.Text = "Get transaction"
            $GetTransactionItem.Add_Click({
                $command = 'gettransaction'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Txid')
                        'optional' = @('Include Watch Only')
                        'types' = @{
                            'Txid' = @{
                                'type' = 'string'
                            }
                            'Include Watch Only' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                        }
                    }
                }
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -buttonName 'Get transaction' -console $consoleTextBoxWallet
            })
            $WalletMenu.Items.Add($GetTransactionItem)

            # getwalletinfo
            $GetWalletInfoItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetWalletInfoItem.Text = "Get wallet info"
            $GetWalletInfoItem.Add_Click({
                $command = 'getwalletinfo'
                $commandParameters = @{
                    $command = @{}
                }
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -buttonName 'Get wallet info' -console $consoleTextBoxWallet
            })
            $WalletMenu.Items.Add($GetWalletInfoItem)

            # importaddress
            $ImportAddressItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ImportAddressItem.Text = "Import address"
            $ImportAddressItem.Add_Click({
                $command = 'importaddress'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Address')
                        'optional' = @('Label', 'Rescan', 'P2SH')
                        'types' = @{
                            'Address' = @{
                                'type' = 'string'
                            }
                            'Label' = @{
                                'type' = 'string'
                            }
                            'Rescan' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'true'
                            }
                            'P2SH' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                        }
                    }
                }
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -buttonName 'Import address' -console $consoleTextBoxWallet
            })
            $WalletMenu.Items.Add($ImportAddressItem)

            # sendtoaddress
            $SendToAddressItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $SendToAddressItem.Text = "Send to address"
            $SendToAddressItem.Add_Click({
                $command = 'sendtoaddress'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Address', 'Amount')
                        'optional' = @('FutureMaturity', 'FutureLockTime', 'Comment', 'CommentTo', 'SubtractFeeFromAmount', 'UseCJ', 'ConfTarget', 'EstimateMode')
                        'types' = @{
                            'Address' = @{
                                'type' = 'string'
                            }
                            'Amount' = @{
                                'type' = 'decimal'
                            }
                            'FutureMaturity' = @{
                                'type' = 'subparameters' # Change the type here
                                'subparameters' = @{      # Add the subparameters here
                                    'Maturity' = @{
                                        'type' = 'int'
                                    }
                                }
                            }
                            'FutureLockTime' = @{
                                'type' = 'subparameters' # Change the type here
                                'subparameters' = @{      # Add the subparameters here
                                    'LockTime' = @{
                                        'type' = 'int'
                                    }
                                }
                            }
                            'Comment' = @{
                                'type' = 'string'
                            }
                            'CommentTo' = @{
                                'type' = 'string'
                            }
                            'SubtractFeeFromAmount' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                            'UseCJ' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                            'ConfTarget' = @{
                                'type' = 'int'
                            }
                            'EstimateMode' = @{
                                'type' = 'choices' # Change the type here
                                'choices' = @('UNSET', 'ECONOMICAL', 'CONSERVATIVE') # Add the predefined choices here
                                'defaultValue' = 'UNSET'
                            }
                        }
                    }
                }
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -buttonName 'Send to address' -console $consoleTextBoxWallet
            })
            $WalletMenu.Items.Add($SendToAddressItem)

            ### Separator ###
            $separator = New-Object System.Windows.Forms.ToolStripSeparator
            $WalletMenu.Items.Add($separator)

            # abandontransaction
            $AbandonTransactionItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $AbandonTransactionItem.Text = "Abandon transaction"
            $AbandonTransactionItem.Add_Click({
                $command = 'abandontransaction'
                $commandParameters = @{
                    $command = @{
                        'required' = @('TxID')
                        'optional' = @()
                        'types' = @{
                            'TxID' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -buttonName 'Abandon transaction' -console $consoleTextBoxWallet
            })
            $WalletMenu.Items.Add($AbandonTransactionItem)

            # abortrescan
            $AbortRescanItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $AbortRescanItem.Text = "Abort rescan"
            $AbortRescanItem.Add_Click({
                $command = 'abortrescan'
                $commandParameters = @{}
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -buttonName 'Abort rescan' -console $consoleTextBoxWallet
            })
            $WalletMenu.Items.Add($AbortRescanItem)

            # addmultisigaddress
            $AddMultisigAddressItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $AddMultisigAddressItem.Text = "Add multisig address"
            $AddMultisigAddressItem.Add_Click({
                $command = 'addmultisigaddress'
                $commandParameters = @{
                    $command = @{
                        'required' = @('NRequired', 'Keys')
                        'optional' = @('Label')
                        'types' = @{
                            'NRequired' = @{
                                'type' = 'int'
                            }
                            'Keys' = @{
                                'type' = 'array'
                            }
                            'Label' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -buttonName 'Add multisig address' -console $consoleTextBoxWallet
            })
            $WalletMenu.Items.Add($AddMultisigAddressItem)

            # backupwallet
            $BackupWalletItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $BackupWalletItem.Text = "Backup wallet"
            $BackupWalletItem.Add_Click({
                $command = 'backupwallet'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Destination')
                        'optional' = @()
                        'types' = @{
                            'Destination' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -buttonName 'Backup wallet' -console $consoleTextBoxWallet
            })
            $WalletMenu.Items.Add($BackupWalletItem)


            
            $WalletMenu.Show($Button, $Button.PointToClient([System.Windows.Forms.Cursor]::Position))
            $Button.ContextMenuStrip = $WalletMenu
            })
        }
    }
    $WalletTab.Controls.Add($Button)
    $top += 40
}


# Smartnode tab buttons
$buttons = @("Install Smartnode", "Smartnode Dashboard 9000 Pro Plus", "Get blockchain info", "Smartnode status", "Start daemon (admin todo)", "Stop daemon (admin todo)", "Get daemon status", "Open a Bash (admin todo)", "Update Smartnode (admin todo)", "Edit Smartnode Config File")
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
        'Smartnode Dashboard 9000 Pro Plus' {
            $Button.Add_Click({
                Execute-Command -command 'powershell.exe -ExecutionPolicy Bypass -File "%USERPROFILE%\dashboard.ps1"' -buttonName 'Smartnode Dashboard 9000 Pro Plus' -background $true -console $consoleTextBoxSmartnode
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
$buttons = @("Download RaptorWings", "Download XMRig", "Download CPuminer", "Launch RaptorWings", "Launch XMRig", "Launch CPuminer")
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
        'Download RaptorWings' {
            $Button.Add_Click({
                $tempDir = [System.IO.Path]::GetTempPath()
                $raptorwingsZip = "$tempDir" + "raptorwings.zip"
                $raptorwingsFolder = "$tempDir" + "raptorwings"
                $uri = "https://api.github.com/repos/Raptor3um/RaptorWings/releases/latest"
                $response = Invoke-RestMethod -Uri $uri
                $latestVersion = $response.tag_name
                $fileVersion = $response.tag_name -replace '\.', '-'
                $raptorwingsDownloadUrl = "https://github.com/Raptor3um/RaptorWings/releases/download/$latestVersion/Raptorwings_$fileVersion.zip"
                if ($raptorwingsDownloadUrl -eq $null) {
                    [System.Windows.Forms.MessageBox]::Show("An error occurred while retrieving the download link for RaptorWings.", "Download RaptorWings", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    return
                }
                try {
                    Invoke-WebRequest -Uri $raptorwingsDownloadUrl -OutFile $raptorwingsZip
                    Expand-Archive -LiteralPath $raptorwingsZip -DestinationPath $raptorwingsFolder -Force
                    [System.Windows.Forms.MessageBox]::Show("RaptorWings downloaded and extracted successfully to $raptorwingsFolder.", "Download RaptorWings", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show("An error occurred while downloading or extracting RaptorWings.`r`nError message: $($Error[0].Exception.Message)", "Download RaptorWings", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            })
        }
        'Download XMRig' {
            $Button.Add_Click({
                $tempDir = [System.IO.Path]::GetTempPath()
                $xmrigZip = "$tempDir" + "xmrig.zip"
                $xmrigFolder = "$tempDir" + "xmrig"
                $uri = "https://api.github.com/repos/xmrig/xmrig/releases/latest"
                $response = Invoke-RestMethod -Uri $uri
                $latestVersion = $response.tag_name
                $xmrigDownloadUrl = "https://github.com/xmrig/xmrig/releases/download/$latestVersion/xmrig-$($($response.tag_name).Substring(1))-msvc-win64.zip"
                if ($xmrigDownloadUrl -eq $null) {
                    [System.Windows.Forms.MessageBox]::Show("An error occurred while retrieving the download link for XMRig.", "Download XMRig", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    return
                }
                try {
                    Invoke-WebRequest -Uri $xmrigDownloadUrl -OutFile $xmrigZip
                    Expand-Archive -LiteralPath $xmrigZip -DestinationPath $xmrigFolder -Force
                    [System.Windows.Forms.MessageBox]::Show("XMRig downloaded and extracted successfully to $xmrigFolder.", "Download XMRig", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show("An error occurred while downloading or extracting XMRig.`r`nError message: $($Error[0].Exception.Message)", "Download XMRig", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            })
        }
        'Download CPuminer' {
            $Button.Add_Click({
                $tempDir = [System.IO.Path]::GetTempPath()
                $cpuminerZip = "$tempDir" + "cpuminer.zip"
                $cpuminerFolder = "$tempDir" + "cpuminer"
                $uri = "https://api.github.com/repos/WyvernTKC/cpuminer-gr-avx2/releases/latest"
                $response = Invoke-RestMethod -Uri $uri
                $latestVersion = $response.tag_name
                $cpuminerDownloadUrl = "https://github.com/WyvernTKC/cpuminer-gr-avx2/releases/download/$latestVersion/cpuminer-gr-$latestVersion-x86_64_windows.7z"
                if ($cpuminerDownloadUrl -eq $null) {
                    [System.Windows.Forms.MessageBox]::Show("An error occurred while retrieving the download link for CPUMiner.", "CPUMiner Download", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    return
                }
                try {
                    # Install 7-zip to extract cpuminer
                    [System.Windows.Forms.MessageBox]::Show("We need to download and install 7-Zip for cpuminer", "7-Zip Download", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                    $7zipKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\7zFM.exe"
                    if (!(Test-Path $7zipKey)) {
                        $7zipInstallerUrl = "https://www.7-zip.org/a/7z1900-x64.msi"
                        $7zipInstallerPath = "$env:USERPROFILE\7z_installer.msi"
                        Invoke-WebRequest -Uri $7zipInstallerUrl -OutFile $7zipInstallerPath
                        $msiArguments = @{
                            FilePath     = "msiexec.exe"
                            ArgumentList = "/i `"$7zipInstallerPath`" /qn"
                            Wait         = $true
                            Verb         = "RunAs"
                        }
                        Start-Process @msiArguments -ErrorAction SilentlyContinue
                        Remove-Item $7zipInstallerPath -ErrorAction SilentlyContinue -Force
                    }
                    # cpuminer
                    Invoke-WebRequest -Uri $cpuminerDownloadUrl -OutFile $cpuminerZip
                    & "C:\Program Files\7-Zip\7z.exe" x -y "$cpuminerZip" -o"$cpuminerFolder"
                    [System.Windows.Forms.MessageBox]::Show("CPUMiner downloaded and extracted successfully to $cpuminerFolder.", "CPUMiner Download", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show("An error occurred while downloading or extracting CPUMiner.`r`nError message: $($Error[0].Exception.Message)", "CPUMiner Download", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            })
        }
        'Launch RaptorWings' {
            $Button.Add_Click({
                $tempDir = [System.IO.Path]::GetTempPath()
                $raptorwingsExePath = "$tempDir" + "raptorwings\RaptorWings.exe"
                Start-Process $raptorwingsExePath -WindowStyle Normal
            })
        }
        'Launch XMRig' {
            $Button.Add_Click({
                SaveFormData
                $tempDir = [System.IO.Path]::GetTempPath()
                $uri = "https://api.github.com/repos/xmrig/xmrig/releases/latest"
                $response = Invoke-RestMethod -Uri $uri
                $latestVersion = $response.tag_name
                $pool = $PoolTextBox.Text
                $user = $UserTextBox.Text
                $pass = $PassTextBox.Text
                $threads = $ThreadsTrackBar.Value
                $dir = "$tempDir" + "xmrig"
                $xmrigPath = "$dir\xmrig-$($($response.tag_name).Substring(1))\xmrig.exe"        
                if (Test-Path $xmrigPath) {
                    Start-Process -FilePath $xmrigPath -ArgumentList "-a gr -o $pool -u $user -p $pass -t $threads" -WindowStyle Normal
                } else {
                    [System.Windows.MessageBox]::Show("XMRig executable not found. Please ensure it is downloaded and placed in the correct directory.", "XMRig not found", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
                }
            })
        }
        'Launch CPuminer' {
            $Button.Add_Click({
                SaveFormData
                $tempDir = [System.IO.Path]::GetTempPath()
                $uri = "https://api.github.com/repos/WyvernTKC/cpuminer-gr-avx2/releases/latest"
                $response = Invoke-RestMethod -Uri $uri
                $latestVersion = $response.tag_name
                $pool = $PoolTextBox.Text
                $user = $UserTextBox.Text
                $pass = $PassTextBox.Text
                $threads = $ThreadsTrackBar.Value
                $dir = "$tempDir" + "cpuminer"
                $cpuminerConfigPath = "$dir\cpuminer-gr-$($response.tag_name)-x86_64_windows\config.json"
                $cpuminerBatPath = "$dir\cpuminer-gr-$($response.tag_name)-x86_64_windows\cpuminer.bat"
                if (Test-Path $cpuminerBatPath) {
                    # Change config.json
                    $config = Get-Content $cpuminerConfigPath | ConvertFrom-Json
                    $config.url = $pool
                    $config.user = $user
                    $config.pass = $pass
                    $config.threads = $threads
                    $config | ConvertTo-Json -Depth 20 | Set-Content $cpuminerConfigPath
                    Start-Process $cpuminerBatPath
                } else {
                    [System.Windows.Forms.MessageBox]::Show("Unable to find cpuminer.bat.Please Download cpuminer first.", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            })
        }
    }
    $MinerTab.Controls.Add($Button)
    $top += 40
}

# Miner Forms
$PoolLabel = New-Object System.Windows.Forms.Label
$PoolLabel.Location = New-Object System.Drawing.Point(400, 10)
$PoolLabel.Size = New-Object System.Drawing.Size(50, 20)
$PoolLabel.Text = "Pool:"
$MinerTab.Controls.Add($PoolLabel)

$PoolTextBox = New-Object System.Windows.Forms.TextBox
$PoolTextBox.Location = New-Object System.Drawing.Point(460, 10)
$PoolTextBox.Size = New-Object System.Drawing.Size(350, 20)
$MinerTab.Controls.Add($PoolTextBox)

$UserLabel = New-Object System.Windows.Forms.Label
$UserLabel.Location = New-Object System.Drawing.Point(400, 40)
$UserLabel.Size = New-Object System.Drawing.Size(50, 20)
$UserLabel.Text = "User:"
$MinerTab.Controls.Add($UserLabel)

$UserTextBox = New-Object System.Windows.Forms.TextBox
$UserTextBox.Location = New-Object System.Drawing.Point(460, 40)
$UserTextBox.Size = New-Object System.Drawing.Size(350, 20)
$MinerTab.Controls.Add($UserTextBox)

$PassLabel = New-Object System.Windows.Forms.Label
$PassLabel.Location = New-Object System.Drawing.Point(400, 70)
$PassLabel.Size = New-Object System.Drawing.Size(50, 20)
$PassLabel.Text = "Pass:"
$MinerTab.Controls.Add($PassLabel)

$PassTextBox = New-Object System.Windows.Forms.TextBox
$PassTextBox.Location = New-Object System.Drawing.Point(460, 70)
$PassTextBox.Size = New-Object System.Drawing.Size(200, 20)
$PassTextBox.Add_TextChanged({
    if ($PassTextBox.Text.Length -lt 6) {
        $PassTextBox.ForeColor = [System.Drawing.Color]::Red
    } else {
        $PassTextBox.ForeColor = [System.Drawing.Color]::Black
    }
})
$MinerTab.Controls.Add($PassTextBox)

$ThreadsLabel = New-Object System.Windows.Forms.Label
$ThreadsLabel.Location = New-Object System.Drawing.Point(400, 100)
$ThreadsLabel.Size = New-Object System.Drawing.Size(50, 20)
$ThreadsLabel.Text = "Threads:"
$MinerTab.Controls.Add($ThreadsLabel)

$maxThreads = [System.Environment]::ProcessorCount
$ThreadsTrackBar = New-Object System.Windows.Forms.TrackBar
$ThreadsTrackBar.Location = New-Object System.Drawing.Point(460, 100)
$ThreadsTrackBar.Size = New-Object System.Drawing.Size(200, 45)
$ThreadsTrackBar.Minimum = 1
$ThreadsTrackBar.Maximum = $maxThreads
$ThreadsTrackBar.TickFrequency = 1
$ThreadsTrackBar.Value = $maxThreads
$MinerTab.Controls.Add($ThreadsTrackBar)
$SelectedThreadsLabel = New-Object System.Windows.Forms.Label
$SelectedThreadsLabel.Location = New-Object System.Drawing.Point(670, 100)
$SelectedThreadsLabel.Size = New-Object System.Drawing.Size(50, 20)
$SelectedThreadsLabel.Text = "$($ThreadsTrackBar.Value)"
$MinerTab.Controls.Add($SelectedThreadsLabel)
$ThreadsTrackBar.Add_Scroll({
    $SelectedThreadsLabel.Text = $ThreadsTrackBar.Value.ToString()
})
$ThreadsTrackBar.add_ValueChanged({
    SaveFormData
})

$SaveButton = New-Object System.Windows.Forms.Button
$SaveButton.Location = New-Object System.Drawing.Point(690, 130)
$SaveButton.Size = New-Object System.Drawing.Size(120, 40)
$SaveButton.Text = "Save"
$SaveButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
$SaveButton.BackColor = [System.Drawing.Color]::LightGray
$SaveButton.Font = New-Object System.Drawing.Font("Consolas", 10)
$SaveButton.Add_Click({ SaveFormData })
$MinerTab.Controls.Add($SaveButton)


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
# Load miner settings from config file
LoadFormData

$Form.Controls.Add($TabControl)
$Form.Add_Shown({$Form.Activate()})
[void]$Form.ShowDialog()
