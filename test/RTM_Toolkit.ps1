#################################################
############# RAPTOREUM Windows Tools ###########
##################### V 1.0 #####################
#################################################


Add-Type -AssemblyName System.Windows.Forms

# Vars
$global:smartnodeFolder = "$env:AppData\RaptoreumSmartnode"
$global:raptoreumFolder = "$env:AppData\RaptoreumCore"
$global:smartnodecli = $env:traptoreumcli
$global:raptoreumcli = "$env:ProgramFiles\RaptoreumCore\daemon\raptoreum-cli.exe"
$global:serviceName = "RTMService"
if ($global:raptoreumcli -match "-testnet") {$port = "10229";$collateral="60000"} else {$port = "10226";$collateral="1800000"}

# Functions
function Execute-Command {
    param($command, $background = $false, $console, $admin = $false, $hidden = "Normal")

    if ($background) {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command" -WindowStyle $hidden
        $console.Clear()
        $timestamp = Get-Date -Format "HH:mm:ss"
        $console.AppendText("[$timestamp] > $buttonName (Executed in a new CMD window) ")
    } else {
        if ($admin) {
            $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command" -WindowStyle $hidden -PassThru -Verb RunAs
            $process.WaitForExit()
        } else {
            $output = cmd /C $command 2>&1
            $console.Clear()
            $timestamp = Get-Date -Format "HH:mm:ss"
            $console.AppendText("[$timestamp] > $command`n")
            $console.AppendText(($output | Out-String))
        }
    }
}

function Execute-WalletCommand {
    param($command, $console, $parameters)

    $job = Start-Job -ScriptBlock {
        param ($command, $parameters, $global:raptoreumcli)
        cmd /C "`"$global:raptoreumcli`" $command $parameters" 2>&1
    } -ArgumentList $command, $parameters, $global:raptoreumcli
    $output = $job | Wait-Job | Receive-Job
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
    param($command, $console, $parameters)
    write-host "smartnodecli: $global:smartnodecli"
    $job = Start-Job -ScriptBlock {
        param ($command, $global:smartnodecli)
        cmd /C "$global:smartnodecli $command" 2>&1
    } -ArgumentList $command, $global:smartnodecli
    $output = $job | Wait-Job | Receive-Job
    $console.Clear()
    $timestamp = Get-Date -Format "HH:mm:ss"
    $console.AppendText("[$timestamp] > smartnode $command  `n")
    $console.AppendText(($output | Out-String))
}

function SaveFormData {
    $checkedGPUs = ($MinerTab.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] -and $_.Checked } | ForEach-Object { $_.Text.Split(" ")[0].Replace("GPU", "").Replace(":", "") }) -join ","
    $textBox1TextEscaped = $textBox1.Text.Replace('\', '\\')
    $textBox2TextEscaped = $textBox2.Text.Replace('\', '\\')
    $json = @"
{
    "Pool": "$($PoolTextBox.Text)",
    "User": "$($UserTextBox.Text)",
    "Pass": "$($PassTextBox.Text)",
    "Threads": "$($ThreadsTrackBar.Value)",
    "Platforms": "$($OpenCLPlatformsComboBox.SelectedItem)",
    "OpenCLThreads": "$($OpenCLThreadsTextBox.Text)",
    "CheckedGPUs": "$checkedGPUs",
    "CheckBox1": "$($checkBox1.Checked.ToString().ToLower())",
    "CheckBox2": "$($checkBox2.Checked.ToString().ToLower())",
    "TextBox1": "$textBox1TextEscaped",
    "TextBox2": "$textBox2TextEscaped"
}
"@
    Set-Content -Path ".\config.json" -Value $json -Force
}

function LoadFormData {
    if (Test-Path ".\config.json") {
        $json = Get-Content -Path ".\config.json" -Raw
        $config = ConvertFrom-Json $json
        $PoolTextBox.Text = $config.Pool
        $UserTextBox.Text = $config.User
        $PassTextBox.Text = $config.Pass
        $ThreadsTrackBar.Value = $config.Threads
        $SelectedThreadsLabel.Text = $config.Threads
        $OpenCLPlatformsComboBox.SelectedItem = $config.Platforms
        $OpenCLThreadsTextBox.Text = $config.OpenCLThreads        
        $checkedGPUs = $config.CheckedGPUs -split ","
        foreach ($checkBox in $checkBoxes) {
            $gpuIndex = $checkBox.Text.Split(" ")[0].Replace("GPU", "").Replace(":", "")
            if ($gpuIndex -in $checkedGPUs) {
                $checkBox.Checked = $true
            } else {$checkBox.Checked = $false}
        }
        if ($config.CheckBox1 -eq "true") {
            $checkBox1.Checked = $true
        } else {$checkBox1.Checked = $false}
        if ($config.CheckBox2 -eq "true") {
            $checkBox2.Checked = $true
        } else {$checkBox2.Checked = $false}
        $textBox1.Text = $config.TextBox1
        $textBox2.Text = $config.TextBox2
    } else {
        $PoolTextBox.Text = "stratum+tcp://eu.flockpool.com:4444"
        $UserTextBox.Text = "RMRwCAkSJaWHGPiP1rF5EHuUYDTze2xw6J.wizz"
        $PassTextBox.Text = "tototo"
        $ThreadsTrackBar.Value = "4"
        $SelectedThreadsLabel.Text = "4"
        $OpenCLPlatformsComboBox.SelectedItem = 'all'
        $OpenCLThreadsTextBox.Text = "auto"
        $checkBox1.Checked = $false
        $checkBox2.Checked = $false
    }
    Change-Vars
}

function Change-Vars {
    if ($checkBox1.Checked -eq $true) {
        $global:smartnodecli = $env:traptoreumcli
        $global:serviceName = "RTMServiceTestnet"
        Write-Host "checkBox1 checked, using 'RTMServiceTestnet' as service name"
    } else {
        $global:smartnodecli = $env:raptoreumcli
        $global:serviceName = "RTMService"
        Write-Host "checkBox1 unchecked, using 'RTMService' as service name"
    }
    if ($checkBox2.Checked -eq $true) {
        $global:raptoreumcli = $global:raptoreumcli + " -testnet"
        Write-Host "checkBox2 checked, using '-testnet' as param for RaptoreumCore"
    } else {
        if ($global:raptoreumcli -like "* -testnet") {
            $global:raptoreumcli = $global:raptoreumcli -replace " -testnet", ""
            Write-Host "checkBox2 unchecked, NOT using '-testnet' as param for RaptoreumCore"
        }
    }
}

function Set-ButtonWorking {
    param($index, $list)
    $global:oldText = $list[$index].Text
    $list[$index].Text = "Working..."
}

function Reset-Button {
    param($index, $list)
    $list[$index].Text = $global:oldText
}

function Show-CommandParametersForm {
    param(
        [string]$command, 
        [hashtable]$commandParameters,
        [System.Windows.Forms.TextBox]$console
    )
    $parameterValues = @{}
    if ($commandParameters.ContainsKey($command)) {
        $parameters = $commandParameters[$command]
        $requiredParameters = $parameters['required']
        $optionalParameters = $parameters['optional']        
        $types = $parameters['types']
        $totalParameters = $requiredParameters.Count + $optionalParameters.Count
        $form = New-Object System.Windows.Forms.Form
        $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($icoPath)
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
        $x = 0
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
            if ($currentType.type.ToLower() -eq 'boolean') {
                $comboBox = New-Object System.Windows.Forms.ComboBox
                $comboBox.Location = New-Object System.Drawing.Point(10, $y)
                $comboBox.Size = New-Object System.Drawing.Size(280, 20)
                $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
                $comboBox.Items.AddRange(@('true', 'false'))
                $comboBox.SelectedItem = $currentType.defaultValue
                if ($currentType.defaultValue) {
                    $parameterValues[$paramName] = $currentType.defaultValue
                }
                $form.Controls.Add($comboBox)
                if ($currentType.defaultValue) {
                    $parameterValues[$paramName] = $currentType.defaultValue
                }
            } else {
                $textBox = New-Object System.Windows.Forms.TextBox
                $textBox.Location = New-Object System.Drawing.Point(10, $y)
                $textBox.Size = New-Object System.Drawing.Size(280, 20)
                $form.Controls.Add($textBox)
                $textBox.Tag = $paramName
                $textBox.Text = $types[$paramName].defaultValue
                $textBox.Add_TextChanged({
                    $textBoxParamName = $this.Tag
                    Write-Host "Textbox TextChanged for $textBoxParamName"
                    $parameterValues[$textBoxParamName] = $this.Text
                })
                $x++
            }
            $y += 30
        }
        for ($i = 0; $i -lt $optionalParameters.Count; $i++) {
            $paramName = $optionalParameters[$i]
            $currentType = $types[$paramName]
            $label = New-Object System.Windows.Forms.Label
            $label.Location = New-Object System.Drawing.Point(10, $y)
            $label.Size = New-Object System.Drawing.Size(280, 20)
            if ($currentType.type.ToLower() -eq 'boolean') {
                $label.Text = $paramName + ' (Optional, ' + $currentType.type + ', Default:' + $currentType.defaultValue + '):'
            } else {
                $label.Text = $paramName + ' (Optional, ' + $currentType.type + '):'
            }
            $form.Controls.Add($label)
            $y += 20
            if ($currentType.type.ToLower() -eq 'boolean') {
                $comboBox = New-Object System.Windows.Forms.ComboBox
                $comboBox.Location = New-Object System.Drawing.Point(10, $y)
                $comboBox.Size = New-Object System.Drawing.Size(280, 20)
                $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
                $comboBox.Items.AddRange(@('true', 'false'))
                $comboBox.SelectedItem = $currentType.defaultValue
                if ($currentType.defaultValue) {
                    $parameterValues[$paramName] = $currentType.defaultValue
                }
                $form.Controls.Add($comboBox)
            } else {
                $textBox = New-Object System.Windows.Forms.TextBox
                $textBox.Location = New-Object System.Drawing.Point(10, $y)
                $textBox.Size = New-Object System.Drawing.Size(280, 20)
                $form.Controls.Add($textBox)
                $textBox.Tag = $paramName 
                $textBox.Text = $types[$paramName].defaultValue
                $textBox.Add_TextChanged({
                    $textBoxParamName = $this.Tag
                    Write-Host "Textbox TextChanged for $textBoxParamName"
                    $parameterValues[$textBoxParamName] = $this.Text
                })
                $x++
            }
            $y += 30
        }
        if ($requiredParameters.Count -eq 0) {
            $baseHeight = 180
        } else {
            $baseHeight = 150
        }

        $heightAdjustment = 50 * ($totalParameters - 1)
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
            Execute-WalletCommand -command "help $command" -console $consoleTextBoxWallet
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
            $values = @()
            foreach ($paramName in ($requiredParameters + $optionalParameters)) {
                #if ($paramName) {
                $values += '"' + $parameterValues[$paramName] + '"'
                #} else {
                    #$values += '""'
                #}
            }                        
            $commandString = "$command " + ($values -join ' ')
            if ($printWithoutRunningCheckbox.Checked) {
                Print-Command -command $commandString -console $consoleTextBoxWallet
            } else {
                Execute-WalletCommand -command $commandString -buttonName $command -console $consoleTextBoxWallet
            }            
        }        
    }
}


### UI ###

# Icon
$icoPath = ".\icon.ico"
if (!(Test-Path -Path $icoPath)) {
    Invoke-WebRequest -Uri "https://github.com/wizz13150/Raptoreum_SmartNode/blob/main/test/icon.ico" -OutFile $icoPath
}

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Raptoreum Tools"
$Form.Size = New-Object System.Drawing.Size(975, 490)
$Form.StartPosition = "CenterScreen"
$Form.Icon = $icoPath

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
$consoleTextBoxSmartnode.Location = New-Object System.Drawing.Point(400, 50)
$consoleTextBoxSmartnode.Size = New-Object System.Drawing.Size(520, 360)
$consoleTextBoxSmartnode.Multiline = $true
$consoleTextBoxSmartnode.ScrollBars = 'Vertical'
$consoleTextBoxSmartnode.ReadOnly = $true
$consoleTextBoxSmartnode.BackColor = [System.Drawing.Color]::Black
$consoleTextBoxSmartnode.ForeColor = [System.Drawing.Color]::Green
$consoleTextBoxSmartnode.Font = New-Object System.Drawing.Font("Consolas", 9)
$SmartnodeTab.Controls.Add($consoleTextBoxSmartnode)

$consoleTextBoxWallet = New-Object System.Windows.Forms.TextBox
$consoleTextBoxWallet.Location = New-Object System.Drawing.Point(400, 50)
$consoleTextBoxWallet.Size = New-Object System.Drawing.Size(520, 360)
$consoleTextBoxWallet.Multiline = $true
$consoleTextBoxWallet.ScrollBars = 'Vertical'
$consoleTextBoxWallet.ReadOnly = $true
$consoleTextBoxWallet.BackColor = [System.Drawing.Color]::Black
$consoleTextBoxWallet.ForeColor = [System.Drawing.Color]::Green
$consoleTextBoxWallet.Font = New-Object System.Drawing.Font("Consolas", 9)
$WalletTab.Controls.Add($consoleTextBoxWallet)


# General tab
$labelGeneral = New-Object System.Windows.Forms.Label
$labelGeneral.Location = New-Object System.Drawing.Point(10, 10)
$labelGeneral.Size = New-Object System.Drawing.Size(300, 25)
$labelGeneral.Text = "Variables"
$labelGeneral.Font = New-Object System.Drawing.Font("Arial", 15, [System.Drawing.FontStyle]::Bold)

$label1 = New-Object System.Windows.Forms.Label
$label1.Location = New-Object System.Drawing.Point(10, 40)
$label1.Size = New-Object System.Drawing.Size(300, 20)
$label1.Text = "Run in Testnet mode :"

$checkBox1 = New-Object System.Windows.Forms.CheckBox
$checkBox1.Location = New-Object System.Drawing.Point(10, 60)
$checkBox1.Size = New-Object System.Drawing.Size(300, 20)
$checkBox1.Text = "My Smartnode is running in Testnet mode"
$checkBox1.Add_Click({
    SaveFormData
    if ($checkBox1.Checked) {
        $global:smartnodecli = $env:traptoreumcli
        $global:serviceName = "RTMServiceTestnet"
    } else {
        $global:smartnodecli = $env:raptoreumcli
        $global:serviceName = "RTMService"
    }
})

$checkBox2 = New-Object System.Windows.Forms.CheckBox
$checkBox2.Location = New-Object System.Drawing.Point(10, 90)
$checkBox2.Size = New-Object System.Drawing.Size(300, 20)
$checkBox2.Text = "My RaptoreumCore is running in Testnet mode"
$checkBox2.Add_Click({
    SaveFormData
    if ($checkBox2.Checked) {
        $global:raptoreumcli = $global:raptoreumcli + " -testnet"
    } else {
        if ($global:raptoreumcli -like "* -testnet") {
            $global:raptoreumcli = $global:raptoreumcli -replace " -testnet", ""
        }
    }
})

$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(10, 130)
$label2.Size = New-Object System.Drawing.Size(300, 30)
$label2.Text = "Folder for the Smartnode :`n(If empty, please select a folder to use commands)"

$textBox1 = New-Object System.Windows.Forms.TextBox
$textBox1.Location = New-Object System.Drawing.Point(10, 160)
$textBox1.Size = New-Object System.Drawing.Size(260, 20)
if ($global:smartnodeFolder) {
    $textBox1.Text = $global:smartnodeFolder
}
$textBox1.add_TextChanged({
    SaveFormData
})

$button1 = New-Object System.Windows.Forms.Button
$button1.Location = New-Object System.Drawing.Point(280, 160)
$button1.Size = New-Object System.Drawing.Size(75, 23)
$button1.Text = "Browse..."
$button1.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.InitialDirectory = $env:USERPROFILE
    $openFileDialog.Filter = "All files (*.*)|*.*"
    if ($openFileDialog.ShowDialog() -eq "OK") {
        $textBox1.Text = $openFileDialog.FileName
        $global:raptoreumcli = "`"$($textBox1.Text)`" -conf=H:\Raptoreum\Wallet\raptoreum.conf"
        if ($checkBox2.Checked) {
            $global:raptoreumcli += " -testnet"
        }
    }
    SaveFormData
})

$label3 = New-Object System.Windows.Forms.Label
$label3.Location = New-Object System.Drawing.Point(10, 200)
$label3.Size = New-Object System.Drawing.Size(300, 30)
$label3.Text = "Folder for RaptoreumCore:`n(If empty, please select a folder to use commands)"

$textBox2 = New-Object System.Windows.Forms.TextBox
$textBox2.Location = New-Object System.Drawing.Point(10, 230)
$textBox2.Size = New-Object System.Drawing.Size(260, 20)
if ($global:raptoreumFolder) {
    $textBox2.Text = $global:raptoreumFolder
}
$textBox2.add_TextChanged({
    SaveFormData
})

$button2 = New-Object System.Windows.Forms.Button
$button2.Location = New-Object System.Drawing.Point(280, 230)
$button2.Size = New-Object System.Drawing.Size(75, 23)
$button2.Text = "Browse..."
$button2.Add_Click({    
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowserDialog.SelectedPath = $env:USERPROFILE
    if ($folderBrowserDialog.ShowDialog() -eq "OK") {
        $textBox2.Text = $folderBrowserDialog.SelectedPath
    }
    SaveFormData
})

# Add components to the General tab
$GeneralTab.Controls.Add($labelGeneral)
$GeneralTab.Controls.Add($label1)
$GeneralTab.Controls.Add($checkBox1)
$GeneralTab.Controls.Add($checkBox2)
$GeneralTab.Controls.Add($label2)
$GeneralTab.Controls.Add($textBox1)
$GeneralTab.Controls.Add($button1)
$GeneralTab.Controls.Add($label3)
$GeneralTab.Controls.Add($textBox2)
$GeneralTab.Controls.Add($button2)



# Wallet tab buttons
$buttons = @("Install Wallet", "Apply a Bootstrap (admin)", "Blockchain", "Control/Evo/Generating/Mining", "Wallet", "Network", "Protx Commands", "Util", "Edit RaptoreumCore Config File")
$top = 10
$left = 10
$width = 350
$height = 40
$buttonListWallet = @()
foreach ($btnText in $buttons) {
    $buttonWallet = New-Object System.Windows.Forms.Button
    $buttonWallet.Location = New-Object System.Drawing.Point($left, $top)
    $buttonWallet.Size = New-Object System.Drawing.Size($width, $height)
    $buttonWallet.Text = $btnText
    $buttonWallet.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $buttonWallet.BackColor = [System.Drawing.Color]::LightGray
    $buttonWallet.ForeColor = [System.Drawing.Color]::Black
    $buttonWallet.FlatAppearance.BorderSize = 1
    $buttonWallet.FlatAppearance.BorderColor = [System.Drawing.Color]::DarkGray
    $buttonWallet.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10)
    $buttonWallet.Font = New-Object System.Drawing.Font("Consolas", 10)
    switch ($btnText) {
        'Install Wallet' {
            $buttonWallet.Add_Click({
                $installWalletUrl = "https://github.com/Raptor3um/raptoreum/releases/download/1.3.17.02/raptoreumcore-1.3.17-win64-setup.exe"
                $installWalletPath = "$env:TEMP\raptoreumcore-win64-setup.exe"                
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($installWalletUrl, $installWalletPath)
                Set-ButtonWorking -index 0 -list $buttonListWallet
                Execute-Command -command "$installWalletPath" -background $true -console $consoleTextBoxWallet
                Reset-Button -index 0 -list $buttonListWallet
            })
        }
        'Apply a Bootstrap (admin)' { 
            $buttonWallet.Add_Click({
                $bootstrapUrl = "https://raw.githubusercontent.com/wizz13150/RaptoreumStuff/main/RTM_Bootstrap.bat"
                $bootstrapPath = "$env:TEMP\RTM_Bootstrap.bat"        
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($bootstrapUrl, $bootstrapPath)        
                Set-ButtonWorking -index 1 -list $buttonListWallet
                Execute-Command -command "cmd /c $bootstrapPath" -console $consoleTextBoxWallet -admin $true
                Reset-Button -index 1 -list $buttonListWallet
            })
        }
        ###########################################
################## Blockchain BUTTON #####################
        ###########################################
        'Blockchain' {
        $buttonWallet.Add_Click({
            $BlockchainMenu = New-Object System.Windows.Forms.ContextMenuStrip
            # Limit menu height
            $dummyMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $dummyMenuItem.Text = "Dummy"
            $BlockchainMenu.Items.Add($dummyMenuItem)
            $maxVisibleItems = 25
            $menuItemHeight = $dummyMenuItem.GetPreferredSize([System.Drawing.Size]::Empty).Height
            $maxHeight = $maxVisibleItems * $menuItemHeight
            $BlockchainMenu.MaximumSize = New-Object System.Drawing.Size(0, $maxHeight)
            $BlockchainMenu.Items.Remove($dummyMenuItem)

            # getaddressbalance
            $GetAddressBalanceItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetAddressBalanceItem.Text = "Get address balance"
            $GetAddressBalanceItem.Add_Click({
                $command = 'getaddressbalance'
                $commandParameters = @{
                    $command = @{
                        'optional' = @('MinConf', 'AddLocked')
                        'types' = @{
                            'MinConf' = @{
                                'type' = 'int'
                            }
                            'AddLocked' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 2 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 2 -list $buttonListWallet
            })
            $BlockchainMenu.Items.Add($GetAddressBalanceItem)

            # getaddressdeltas
            $GetAddressDeltasItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetAddressDeltasItem.Text = "Get address deltas"
            $GetAddressDeltasItem.Add_Click({
                $command = 'getaddressdeltas'
                $commandParameters = @{
                    $command = @{
                        'optional' = @('MinConf', 'AddLocked')
                        'types' = @{
                            'MinConf' = @{
                                'type' = 'int'
                            }
                            'AddLocked' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 2 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 2 -list $buttonListWallet
            })
            $BlockchainMenu.Items.Add($GetAddressDeltasItem)

            # getaddressmempool
            $GetAddressMempoolItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetAddressMempoolItem.Text = "Get address mempool"
            $GetAddressMempoolItem.Add_Click({
                $command = 'getaddressmempool'
                $commandParameters = @{
                    $command = @{
                        'optional' = @('AddLocked')
                        'types' = @{
                            'AddLocked' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 2 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 2 -list $buttonListWallet
            })
            $BlockchainMenu.Items.Add($GetAddressMempoolItem)

            # getaddresstxids
            $GetAddressTxidsItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetAddressTxidsItem.Text = "Get address txids"
            $GetAddressTxidsItem.Add_Click({
                $command = 'getaddresstxids'
                $commandParameters = @{
                    $command = @{
                        'optional' = @('MinConf', 'AddLocked')
                        'types' = @{
                            'MinConf' = @{
                                'type' = 'int'
                            }
                            'AddLocked' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 2 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 2 -list $buttonListWallet
            })
            $BlockchainMenu.Items.Add($GetAddressTxidsItem)

            # getaddressutxos
            $GetAddressUtxosItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetAddressUtxosItem.Text = "Get address utxos"
            $GetAddressUtxosItem.Add_Click({
                $command = 'getaddressutxos'
                $commandParameters = @{
                    $command = @{
                        'optional' = @('MinConf', 'AddLocked')
                        'types' = @{
                            'MinConf' = @{
                                'type' = 'int'
                            }
                            'AddLocked' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 2 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 2 -list $buttonListWallet
            })
            $BlockchainMenu.Items.Add($GetAddressUtxosItem)

            # getblockchaininfo
            $GetBlockchainInfoItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetBlockchainInfoItem.Text = "Get blockchain info"
            $GetBlockchainInfoItem.Add_Click({
                $command = 'getblockchaininfo'
                Set-ButtonWorking -index 2 -list $buttonListWallet
                Execute-WalletCommand -command $command -buttonName 'Get blockchain info' -console $consoleTextBoxWallet
                Reset-Button -index 2 -list $buttonListWallet
            })
            $BlockchainMenu.Items.Add($GetBlockchainInfoItem)

            # getblockcount
            $GetBlockCountItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetBlockCountItem.Text = "Get block count"
            $GetBlockCountItem.Add_Click({
                $command = 'getblockcount'
                Set-ButtonWorking -index 2 -list $buttonListWallet
                Execute-WalletCommand -command $command -buttonName 'Get block count' -console $consoleTextBoxWallet
                Reset-Button -index 2 -list $buttonListWallet
            })
            $BlockchainMenu.Items.Add($GetBlockCountItem)

            # getblockhash
            $GetBlockHashItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetBlockHashItem.Text = "Get block hash"
            $GetBlockHashItem.Add_Click({
                $command = 'getblockhash'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Height')
                        'types' = @{
                            'Height' = @{
                                'type' = 'int'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 2 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 2 -list $buttonListWallet
            })
            $BlockchainMenu.Items.Add($GetBlockHashItem)

            # getblockheader
            $GetBlockHeaderItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetBlockHeaderItem.Text = "Get block header"
            $GetBlockHeaderItem.Add_Click({
                $command = 'getblockheader'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Hash')
                        'optional' = @('Verbose')
                        'types' = @{
                            'Hash' = @{
                                'type' = 'string'
                            }
                            'Verbose' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 2 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 2 -list $buttonListWallet
            })
            $BlockchainMenu.Items.Add($GetBlockHeaderItem)

            # getblockcount
            $GetBlockCountItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetBlockCountItem.Text = "Get block count"
            $GetBlockCountItem.Add_Click({
                $command = 'getblockcount'
                $commandParameters = @{}
                Set-ButtonWorking -index 2 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 2 -list $buttonListWallet
            })
            $BlockchainMenu.Items.Add($GetBlockCountItem)
            
            $BlockchainMenu.Show($buttonWallet, $buttonWallet.PointToClient([System.Windows.Forms.Cursor]::Position))
            $buttonWallet.ContextMenuStrip = $BlockchainMenu
            })
        }
        ###########################################
########## Control/Evo/Generating/Mining BUTTON ###########
        ###########################################
        'Control/Evo/Generating/Mining' {
        $buttonWallet.Add_Click({
            $ControlMenu = New-Object System.Windows.Forms.ContextMenuStrip
            # Limit menu height
            $dummyMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $dummyMenuItem.Text = "Dummy"
            $ControlMenu.Items.Add($dummyMenuItem)
            $maxVisibleItems = 25
            $menuItemHeight = $dummyMenuItem.GetPreferredSize([System.Drawing.Size]::Empty).Height
            $maxHeight = $maxVisibleItems * $menuItemHeight
            $ControlMenu.MaximumSize = New-Object System.Drawing.Size(0, $maxHeight)
            $ControlMenu.Items.Remove($dummyMenuItem)

            # protx quick_setup
            $ProtxQuickSetupItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ProtxQuickSetupItem.Text = "ProTX Quick Setup"
            $ProtxQuickSetupItem.Add_Click({
                $command = 'protx quick_setup'
                $commandParameters = @{
                    $command = @{
                        'required' = @('collateralHash', 'collateralIndex', 'ipAndPort')
                        'optional' = @('feeSourceAddress')
                        'types' = @{
                            'collateralHash' = @{
                                'type' = 'string'
                            }
                            'collateralIndex' = @{
                                'type' = 'int'
                            }
                            'ipAndPort' = @{
                                'type' = 'string'
                            }
                            'feeSourceAddress' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 3 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 3 -list $buttonListWallet
            })
            $ControlMenu.Items.Add($ProtxQuickSetupItem)

            $ControlMenu.Show($buttonWallet, $buttonWallet.PointToClient([System.Windows.Forms.Cursor]::Position))
            $buttonWallet.ContextMenuStrip = $ControlMenu
            })
        }
        ###########################################
################## Protx Commands BUTTON ###################
        ###########################################
        'Protx Commands' {
        $buttonWallet.Add_Click({
            $ProtxMenu = New-Object System.Windows.Forms.ContextMenuStrip
            # Limit menu height
            $dummyMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $dummyMenuItem.Text = "Dummy"
            $ProtxMenu.Items.Add($dummyMenuItem)
            $maxVisibleItems = 25
            $menuItemHeight = $dummyMenuItem.GetPreferredSize([System.Drawing.Size]::Empty).Height
            $maxHeight = $maxVisibleItems * $menuItemHeight
            $ProtxMenu.MaximumSize = New-Object System.Drawing.Size(0, $maxHeight)
            $ProtxMenu.Items.Remove($dummyMenuItem)

            # protx quick_setup
            $ProtxQuickSetupItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ProtxQuickSetupItem.Text = "ProTX Quick Setup"            
            $ProtxQuickSetupItem.Add_Click({
                Set-ButtonWorking -index 6 -list $buttonListWallet
                # Detect IP
                $wanIP = Invoke-WebRequest -Uri "http://ipecho.net/plain" -UseBasicParsing | Select-Object -ExpandProperty Content
                $command = 'protx quick_setup'
                $commandParameters = @{
                    $command = @{
                        'required' = @('collateralHash', 'collateralIndex', 'ipAndPort')
                        'optional' = @('feeSourceAddress')
                        'types' = [ordered]@{
                            'collateralHash' = @{
                                'type' = 'string'
                            }
                            'collateralIndex' = @{
                                'type' = 'string'
                                'defaultValue' = "0"
                            }
                            'ipAndPort' = @{
                                'type' = 'string'
                                'defaultValue' = "$($wanIP):$($port)"
                            }
                            'feeSourceAddress' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 6 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 6 -list $buttonListWallet
            })
            $ProtxMenu.Items.Add($ProtxQuickSetupItem)

            # protx register_fund
            $ProtxRegisterFundItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ProtxRegisterFundItem.Text = "ProTX Register Fund"
            $ProtxRegisterFundItem.Add_Click({
                Set-ButtonWorking -index 6 -list $buttonListWallet
                # Detect IP
                $wanIP = Invoke-WebRequest -Uri "http://ipecho.net/plain" -UseBasicParsing | Select-Object -ExpandProperty Content
                # Detect addresses for fee
                $unspent = cmd /C "$global:raptoreumcli listunspent" 2>&1 | ConvertFrom-Json
                $addressesForDropDown = @()
                $addressesForRealValue = @()
                $counter = 0
                foreach ($entry in $unspent) {
                    if ([double]$entry.amount -gt 1 -and [double]$entry.amount -lt $collateral) {
                        $shortAddress = $entry.address.Substring(0, 10) + "..." + $entry.address.Substring($entry.address.Length - 10)
                        $addressesForDropDown += "$shortAddress - $([double]$entry.amount) RTM"
                        $addressesForRealValue += $($entry.address)
                        $counter++
                    }
                    # first 50 only
                    if ($counter -eq 50) { break }
                }
                $addressesForDropDown
                Reset-Button -index 6 -list $buttonListWallet

                $command = 'protx register_fund'
                $commandParameters = @{
                    $command = @{
                        'required' = @('collateralAddress', 'ipAndPort', 'ownerKeyAddr', 'votingKeyAddr', 'operatorPubKey', 'operatorPayoutAddress')
                        'optional' = @('feeSourceAddress')
                        'types' = @{
                            'collateralAddress' = @{
                                'type' = 'string'
                            }
                            'ipAndPort' = @{
                                'type' = 'string'
                                'defaultValue' = "$($wanIP):$($port)"
                            }
                            'ownerKeyAddr' = @{
                                'type' = 'string'
                            }
                            'votingKeyAddr' = @{
                                'type' = 'string'
                            }
                            'operatorPubKey' = @{
                                'type' = 'string'
                            }
                            'operatorPayoutAddress' = @{
                                'type' = 'string'
                            }
                            'feeSourceAddress' = @{
                                'type' = 'choices'
                                'choices' = $addressesForDropDown
                                'realValue' = $addressesForRealValue
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 6 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 6 -list $buttonListWallet
            })
            $ProtxMenu.Items.Add($ProtxRegisterFundItem)

            # protx register_prepare
            $ProtxRegisterPrepareItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ProtxRegisterPrepareItem.Text = "ProTX Register Prepare"
            $ProtxRegisterPrepareItem.Add_Click({
                $command = 'protx register_prepare'
                $commandParameters = @{
                    $command = @{
                        'required' = @('collateralHash', 'collateralIndex', 'ipAndPort', 'ownerKeyAddr', 'votingKeyAddr', 'operatorPubKey', 'operatorPayoutAddress')
                        'optional' = @('feeSourceAddress')
                        'types' = @{
                            'collateralHash' = @{
                                'type' = 'string'
                            }
                            'collateralIndex' = @{
                                'type' = 'int'
                            }
                            'ipAndPort' = @{
                                'type' = 'string'
                            }
                            'ownerKeyAddr' = @{
                                'type' = 'string'
                            }
                            'votingKeyAddr' = @{
                                'type' = 'string'
                            }
                            'operatorPubKey' = @{
                                'type' = 'string'
                            }
                            'operatorPayoutAddress' = @{
                                'type' = 'string'
                            }
                            'feeSourceAddress' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 6 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 6 -list $buttonListWallet
            })
            $ProtxMenu.Items.Add($ProtxRegisterPrepareItem)

            # protx register_submit
            $ProtxRegisterSubmitItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ProtxRegisterSubmitItem.Text = "ProTX Register Submit"
            $ProtxRegisterSubmitItem.Add_Click({
                $command = 'protx register_submit'
                $commandParameters = @{
                    $command = @{
                        'required' = @('tx', 'sig')
                        'optional' = @()
                        'types' = @{
                            'tx' = @{
                                'type' = 'string'
                            }
                            'sig' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 6 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 6 -list $buttonListWallet
            })
            $ProtxMenu.Items.Add($ProtxRegisterSubmitItem)

            # protx list
            $ProtxListItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ProtxListItem.Text = "ProTX List"
            $ProtxListItem.Add_Click({
                $command = 'protx list'
                $commandParameters = @{
                    $command = @{
                        'required' = @('type')
                        'optional' = @('detailed', 'height')
                        'types' = @{
                            'type' = @{
                                'type' = 'choices'
                                'choices' = @('valid', 'registered', 'wallet')
                                'defaultValue' = 'registered'
                            }
                            'detailed' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                            'height' = @{
                                'type' = 'int'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 6 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 6 -list $buttonListWallet
            })
            $ProtxMenu.Items.Add($ProtxListItem)

            # protx info
            $ProtxInfoItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ProtxInfoItem.Text = "ProTX Info"
            $ProtxInfoItem.Add_Click({
                $command = 'protx info'
                $commandParameters = @{
                    $command = @{
                        'required' = @('proTxHash')
                        'optional' = @()
                        'types' = @{
                            'proTxHash' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 6 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 6 -list $buttonListWallet
            })
            $ProtxMenu.Items.Add($ProtxInfoItem)

            # protx update_service
            $ProtxUpdateServiceItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ProtxUpdateServiceItem.Text = "ProTX Update Service"
            $ProtxUpdateServiceItem.Add_Click({
                # Detect IP
                $wanIP = Invoke-WebRequest -Uri "http://ipecho.net/plain" -UseBasicParsing | Select-Object -ExpandProperty Content
                $command = 'protx update_service'
                $commandParameters = @{
                    $command = @{
                        'required' = @('proTxHash', 'ipAndPort', 'operatorPubKey', 'operatorPayoutAddress')
                        'optional' = @('feeSourceAddress')
                        'types' = @{
                            'proTxHash' = @{
                                'type' = 'string'
                            }
                            'ipAndPort' = @{
                                'type' = 'string'
                                'defaultValue' = "$($wanIP):$($port)"
                            }
                            'operatorPubKey' = @{
                                'type' = 'string'
                            }
                            'operatorPayoutAddress' = @{
                                'type' = 'string'
                            }
                            'feeSourceAddress' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 6 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 6 -list $buttonListWallet
            })
            $ProtxMenu.Items.Add($ProtxUpdateServiceItem)

            # protx update_registrar
            $ProtxUpdateRegistrarItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ProtxUpdateRegistrarItem.Text = "ProTX Update Registrar"
            $ProtxUpdateRegistrarItem.Add_Click({
                $command = 'protx update_registrar'
                $commandParameters = @{
                    $command = @{
                        'required' = @('proTxHash', 'operatorPubKey', 'votingAddress', 'payoutAddress')
                        'optional' = @('feeSourceAddress')
                        'types' = @{
                            'proTxHash' = @{
                                'type' = 'string'
                            }
                            'operatorPubKey' = @{
                                'type' = 'string'
                            }
                            'votingAddress' = @{
                                'type' = 'string'
                            }
                            'payoutAddress' = @{
                                'type' = 'string'
                            }
                            'feeSourceAddress' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 6 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 6 -list $buttonListWallet
            })
            $ProtxMenu.Items.Add($ProtxUpdateRegistrarItem)

            # protx revoke
            $ProtxRevokeItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ProtxRevokeItem.Text = "ProTX Revoke"
            $ProtxRevokeItem.Add_Click({
                $command = 'protx revoke'
                $commandParameters = @{
                    $command = @{
                        'required' = @('proTxHash', 'reason')
                        'optional' = @('feeSourceAddress')
                        'types' = @{
                            'proTxHash' = @{
                                'type' = 'string'
                            }
                            'reason' = @{
                                'type' = 'int'
                            }
                            'feeSourceAddress' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 6 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 6 -list $buttonListWallet
            })
            $ProtxMenu.Items.Add($ProtxRevokeItem)

            # protx diff
            $ProtxDiffItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ProtxDiffItem.Text = "ProTX Diff"
            $ProtxDiffItem.Add_Click({
                $command = 'protx diff'
                $commandParameters = @{
                    $command = @{
                        'required' = @('baseBlockHeight', 'blockHeight')
                        'optional' = @()
                        'types' = @{
                            'baseBlockHeight' = @{
                                'type' = 'int'
                            }
                            'blockHeight' = @{
                                'type' = 'int'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 6 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 6 -list $buttonListWallet
            })
            $ProtxMenu.Items.Add($ProtxDiffItem)
            
            $ProtxMenu.Show($buttonWallet, $buttonWallet.PointToClient([System.Windows.Forms.Cursor]::Position))
            $buttonWallet.ContextMenuStrip = $ProtxMenu
            })
        }
        ###########################################
###################### WALLET BUTTON ######################
        ###########################################
        'Wallet' {
        $buttonWallet.Add_Click({
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
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
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
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
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
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
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
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
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
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
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
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
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
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
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
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
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
                                'type' = 'subparameters'
                                'subparameters' = @{
                                    'Maturity' = @{
                                        'type' = 'int'
                                    }
                                }
                            }
                            'FutureLockTime' = @{
                                'type' = 'subparameters'
                                'subparameters' = @{
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
                                'type' = 'choices'
                                'choices' = @('UNSET', 'ECONOMICAL', 'CONSERVATIVE')
                                'defaultValue' = 'UNSET'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
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
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($AbandonTransactionItem)

            # abortrescan
            $AbortRescanItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $AbortRescanItem.Text = "Abort rescan"
            $AbortRescanItem.Add_Click({
                $command = 'abortrescan'
                $commandParameters = @{}
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
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
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($AddMultisigAddressItem)

            # dumpprivkey 
            $DumpPrivKeyItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $DumpPrivKeyItem.Text = "Dump private key"
            $DumpPrivKeyItem.Add_Click({
                $command = 'dumpprivkey'
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
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($DumpPrivKeyItem)

            # dumpwallet 
            $DumpWalletItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $DumpWalletItem.Text = "Dump wallet"
            $DumpWalletItem.Add_Click({
                $command = 'dumpwallet'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Filename')
                        'optional' = @()
                        'types' = @{
                            'Filename' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($DumpWalletItem)

            # encryptwallet 
            $EncryptWalletItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $EncryptWalletItem.Text = "Encrypt wallet"
            $EncryptWalletItem.Add_Click({
                $command = 'encryptwallet'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Passphrase')
                        'optional' = @()
                        'types' = @{
                            'Passphrase' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($EncryptWalletItem)

            # getaccount 
            $GetAccountItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetAccountItem.Text = "Get account (deprecated)"
            $GetAccountItem.Add_Click({
                $command = 'getaccount'
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
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($GetAccountItem)

            # getaccountaddress 
            $GetAccountAddressItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetAccountAddressItem.Text = "Get account address (deprecated)"
            $GetAccountAddressItem.Add_Click({
                $command = 'getaccountaddress'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Account')
                        'optional' = @()
                        'types' = @{
                            'Account' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($GetAccountAddressItem)

            # getaddressbyaccount 
            $GetAddressByAccountItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetAddressByAccountItem.Text = "Get address by account (deprecated)"
            $GetAddressByAccountItem.Add_Click({
                $command = 'getaddressbyaccount'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Account')
                        'optional' = @()
                        'types' = @{
                            'Account' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($GetAddressByAccountItem)

            # getaddressesbylabel 
            $GetAddressesByLabelItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetAddressesByLabelItem.Text = "Get addresses by label"
            $GetAddressesByLabelItem.Add_Click({
                $command = 'getaddressesbylabel'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Label')
                        'optional' = @()
                        'types' = @{
                            'Label' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($GetAddressesByLabelItem)

            # getrawchangeaddress
            $GetRawChangeAddressItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetRawChangeAddressItem.Text = "Get raw change address"
            $GetRawChangeAddressItem.Add_Click({
                $command = 'getrawchangeaddress'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @()
                        'types' = @{}
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($GetRawChangeAddressItem)

            # getreceivedbyaccount 
            $GetReceivedByAccountItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetReceivedByAccountItem.Text = "Get received by account (deprecated)"
            $GetReceivedByAccountItem.Add_Click({
                $command = 'getreceivedbyaccount'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Account', 'MinConf')
                        'optional' = @()
                        'types' = @{
                            'Account' = @{
                                'type' = 'string'
                            }
                            'MinConf' = @{
                                'type' = 'int'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($GetReceivedByAccountItem)

            # getreceivedbyaddress 
            $GetReceivedByAddressItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetReceivedByAddressItem.Text = "Get received by address"
            $GetReceivedByAddressItem.Add_Click({
                $command = 'getreceivedbyaddress'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Address', 'MinConf')
                        'optional' = @('AddLocked')
                        'types' = @{
                            'Address' = @{
                                'type' = 'string'
                            }
                            'MinConf' = @{
                                'type' = 'int'
                            }
                            'AddLocked' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($GetReceivedByAddressItem)

            # getunconfirmedbalance
            $GetUnconfirmedBalanceItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $GetUnconfirmedBalanceItem.Text = "Get unconfirmed balance"
            $GetUnconfirmedBalanceItem.Add_Click({
                $command = 'getunconfirmedbalance'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @()
                        'types' = @{}
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($GetUnconfirmedBalanceItem)

            # importelectrumwallet 
            $ImportElectrumWalletItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ImportElectrumWalletItem.Text = "Import Electrum wallet"
            $ImportElectrumWalletItem.Add_Click({
                $command = 'importelectrumwallet'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Filename', 'Index')
                        'optional' = @()
                        'types' = @{
                            'Filename' = @{
                                'type' = 'string'
                            }
                            'Index' = @{
                                'type' = 'int'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ImportElectrumWalletItem)

            # importmulti 
            $ImportMultiItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ImportMultiItem.Text = "Import multi"
            $ImportMultiItem.Add_Click({
                $command = 'importmulti'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Requests')
                        'optional' = @('Options')
                        'types' = @{
                            'Requests' = @{
                                'type' = 'array'
                            }
                            'Options' = @{
                                'type' = 'subparameters'
                                'subparameters' = @{
                                    'Rescan' = @{
                                        'type' = 'boolean'
                                        'defaultValue' = 'true'
                                    }
                                }
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ImportMultiItem)

            # importprivkey 
            $ImportPrivKeyItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ImportPrivKeyItem.Text = "Import private key"
            $ImportPrivKeyItem.Add_Click({
                $command = 'importprivkey'
                $commandParameters = @{
                    $command = @{
                        'required' = @('PrivKey')
                        'optional' = @('Label', 'Rescan')
                        'types' = @{
                            'PrivKey' = @{
                                'type' = 'string'
                            }
                            'Label' = @{
                                'type' = 'string'
                            }
                            'Rescan' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ImportPrivKeyItem)

            # importprunedfunds
            $ImportPrunedFundsItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ImportPrunedFundsItem.Text = "Import pruned funds"
            $ImportPrunedFundsItem.Add_Click({
                $command = 'importprunedfunds'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @()
                        'types' = @{}
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ImportPrunedFundsItem)

            # importpubkey 
            $ImportPubKeyItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ImportPubKeyItem.Text = "Import public key"
            $ImportPubKeyItem.Add_Click({
                $command = 'importpubkey'
                $commandParameters = @{
                    $command = @{
                        'required' = @('PubKey')
                        'optional' = @('Label', 'Rescan')
                        'types' = @{
                            'PubKey' = @{
                                'type' = 'string'
                            }
                            'Label' = @{
                                'type' = 'string'
                            }
                            'Rescan' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ImportPubKeyItem)

            # importwallet 
            $ImportWalletItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ImportWalletItem.Text = "Import wallet"
            $ImportWalletItem.Add_Click({
                $command = 'importwallet'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Filename')
                        'optional' = @()
                        'types' = @{
                            'Filename' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ImportWalletItem)

            # keepass 
            $KeepassItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $KeepassItem.Text = "Keepass"
            $KeepassItem.Add_Click({
                $command = 'keepass'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Command')
                        'optional' = @()
                        'types' = @{
                            'Command' = @{
                                'type' = 'choices'
                                'choices' = @('genkey', 'init', 'setpassphrase')
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($KeepassItem)

            # keypoolrefill 
            $KeypoolRefillItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $KeypoolRefillItem.Text = "Keypool refill"
            $KeypoolRefillItem.Add_Click({
                $command = 'keypoolrefill'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @('NewSize')
                        'types' = @{
                            'NewSize' = @{
                                'type' = 'int'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($KeypoolRefillItem)

            # listaddressbalances 
            $ListAddressBalancesItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ListAddressBalancesItem.Text = "List address balances"
            $ListAddressBalancesItem.Add_Click({
                $command = 'listaddressbalances'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @('MinAmount')
                        'types' = @{
                            'MinAmount' = @{
                                'type' = 'decimal'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ListAddressBalancesItem)

            # listaddressgroupings
            $ListAddressGroupingsItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ListAddressGroupingsItem.Text = "List address groupings"
            $ListAddressGroupingsItem.Add_Click({
                $command = 'listaddressgroupings'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @()
                        'types' = @{
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ListAddressGroupingsItem)

            # listlabels 
            $ListLabelsItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ListLabelsItem.Text = "List labels"
            $ListLabelsItem.Add_Click({
                $command = 'listlabels'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @('Purpose')
                        'types' = @{
                            'Purpose' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ListLabelsItem)

            # listlockunspent
            $ListLockUnspentItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ListLockUnspentItem.Text = "List lock unspent"
            $ListLockUnspentItem.Add_Click({
                $command = 'listlockunspent'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @()
                        'types' = @{
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ListLockUnspentItem)

            # listreceivedbyaddress 
            $ListReceivedByAddressItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ListReceivedByAddressItem.Text = "List received by address"
            $ListReceivedByAddressItem.Add_Click({
                $command = 'listreceivedbyaddress'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @('MinConf', 'AddLocked', 'IncludeEmpty', 'IncludeWatchonly', 'AddressFilter')
                        'types' = @{
                            'MinConf' = @{
                                'type' = 'int'
                            }
                            'AddLocked' = @{
                                'type' = 'boolean'
                            }
                            'IncludeEmpty' = @{
                                'type' = 'boolean'
                            }
                            'IncludeWatchonly' = @{
                                'type' = 'boolean'
                            }
                            'AddressFilter' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ListReceivedByAddressItem)

            # listsinceblock 
            $ListsinceblockItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ListsinceblockItem.Text = "Listsinceblock"
            $ListsinceblockItem.Add_Click({
                $command = 'listsinceblock'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @('BlockHash', 'TargetConfirmations', 'IncludeWatchonly', 'IncludeRemoved')
                        'types' = @{
                            'BlockHash' = @{
                                'type' = 'string'
                            }
                            'TargetConfirmations' = @{
                                'type' = 'int'
                            }
                            'IncludeWatchonly' = @{
                                'type' = 'boolean'
                            }
                            'IncludeRemoved' = @{
                                'type' = 'boolean'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ListsinceblockItem)

            # listtransactions 
            $ListTransactionsItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ListTransactionsItem.Text = "List transactions"
            $ListTransactionsItem.Add_Click({
                $command = 'listtransactions'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @('Label', 'Count', 'Skip', 'IncludeWatchonly')
                        'types' = @{
                            'Label' = @{
                                'type' = 'string'
                            }
                            'Count' = @{
                                'type' = 'int'
                            }
                            'Skip' = @{
                                'type' = 'int'
                            }
                            'IncludeWatchonly' = @{
                                'type' = 'boolean'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ListTransactionsItem)

            # listunspent 
            $ListUnspentItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ListUnspentItem.Text = "List unspent"
            $ListUnspentItem.Add_Click({
                $command = 'listunspent'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @('MinConf', 'MaxConf', 'Addresses', 'IncludeUnsafe', 'QueryOptions')
                        'types' = @{
                            'MinConf' = @{
                                'type' = 'int'
                            }
                            'MaxConf' = @{
                                'type' = 'int'
                            }
                            'Addresses' = @{
                                'type' = 'array'
                            }
                            'IncludeUnsafe' = @{
                                'type' = 'boolean'
                            }
                            'QueryOptions' = @{
                                'type' = 'subparameters'
                                'subparameters' = @{
                                    'MinimumAmount' = @{
                                        'type' = 'decimal'
                                    }
                                    'MaximumAmount' = @{
                                        'type' = 'decimal'
                                    }
                                    'MinimumSumAmount' = @{
                                        'type' = 'decimal'
                                    }
                                }
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ListUnspentItem)

            # listwallets
            $ListWalletsItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ListWalletsItem.Text = "List wallets"
            $ListWalletsItem.Add_Click({
                $command = 'listwallets'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @()
                        'types' = @{}
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($ListWalletsItem)

            # loadwallet 
            $LoadWalletItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $LoadWalletItem.Text = "Load wallet"
            $LoadWalletItem.Add_Click({
                $command = 'loadwallet'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Filename')
                        'optional' = @()
                        'types' = @{
                            'Filename' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($LoadWalletItem)

            # lockunspent 
            $LockUnspentItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $LockUnspentItem.Text = "Lock unspent"
            $LockUnspentItem.Add_Click({
                $command = 'lockunspent'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Unlock', '[TxidVout]')
                        'optional' = @()
                        'types' = @{
                            'Unlock' = @{
                                'type' = 'boolean'
                            }
                            '[TxidVout]' = @{
                                'type' = 'array'
                                'subtype' = @{
                                    'txid' = @{
                                        'type' = 'string'
                                    }
                                    'vout' = @{
                                        'type' = 'int'
                                    }
                                }
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($LockUnspentItem)

            # move 
            $MoveItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $MoveItem.Text = "Move"
            $MoveItem.Add_Click({
                $command = 'move'
                $commandParameters = @{
                    $command = @{
                        'required' = @('FromAccount', 'ToAccount', 'Amount', 'MinConf', 'Comment')
                        'optional' = @()
                        'types' = @{
                            'FromAccount' = @{
                                'type' = 'string'
                            }
                            'ToAccount' = @{
                                'type' = 'string'
                            }
                            'Amount' = @{
                                'type' = 'decimal'
                            }
                            'MinConf' = @{
                                'type' = 'int'
                            }
                            'Comment' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($MoveItem)

            # removeaddress 
            $RemoveAddressItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $RemoveAddressItem.Text = "Remove address"
            $RemoveAddressItem.Add_Click({
                $command = 'removeaddress'
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
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($RemoveAddressItem)

            # removeprunedfunds 
            $RemovePrunedFundsItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $RemovePrunedFundsItem.Text = "Remove pruned funds"
            $RemovePrunedFundsItem.Add_Click({
                $command = 'removeprunedfunds'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Txid')
                        'optional' = @()
                        'types' = @{
                            'Txid' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($RemovePrunedFundsItem)

            # rescanblockchain 
            $RescanBlockchainItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $RescanBlockchainItem.Text = "Rescan blockchain"
            $RescanBlockchainItem.Add_Click({
                $command = 'rescanblockchain'
                $commandParameters = @{
                    $command = @{
                        'required' = @()
                        'optional' = @('StartHeight', 'StopHeight')
                        'types' = @{
                            'StartHeight' = @{
                                'type' = 'int'
                            }
                            'StopHeight' = @{
                                'type' = 'int'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($RescanBlockchainItem)

            # sendfrom 
            $SendFromItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $SendFromItem.Text = "Send from"
            $SendFromItem.Add_Click({
                $command = 'sendfrom'
                $commandParameters = @{
                    $command = @{
                        'required' = @('FromAccount', 'ToAddress', 'Amount', 'MinConf', 'Comment', 'CommentTo')
                        'optional' = @('SubtractFeeFromAmount', 'UseCJ', 'ConfTarget', 'EstimateMode')
                        'types' = @{
                            'FromAccount' = @{
                                'type' = 'string'
                            }
                            'ToAddress' = @{
                                'type' = 'string'
                            }
                            'Amount' = @{
                                'type' = 'decimal'
                            }
                            'MinConf' = @{
                                'type' = 'int'
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
                                'type' = 'choices'
                                'choices' = @('UNSET', 'ECONOMICAL', 'CONSERVATIVE')
                                'defaultValue' = 'UNSET'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($SendFromItem)

            # sendmany 
            $SendManyItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $SendManyItem.Text = "Send many"
            $SendManyItem.Add_Click({
                $command = 'sendmany'
                $commandParameters = @{
                    $command = @{
                        'required' = @('FromAccount', 'Addresses', 'MinConf', 'Comment')
                        'optional' = @('AddLocked', 'SubtractFeeFromAmount', 'UseCJ', 'ConfTarget', 'EstimateMode')
                        'types' = @{
                            'FromAccount' = @{
                                'type' = 'string'
                            }
                            'Addresses' = @{
                                'type' = 'array'
                                'arrayType' = @{
                                    'type' = 'object'
                                    'objectProperties' = @{
                                        'Address' = @{
                                            'type' = 'string'
                                        }
                                        'Amount' = @{
                                            'type' = 'decimal'
                                        }
                                    }
                                }
                            }
                            'MinConf' = @{
                                'type' = 'int'
                            }
                            'Comment' = @{
                                'type' = 'string'
                            }
                            'AddLocked' = @{
                                'type' = 'boolean'
                                'defaultValue' = 'false'
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
                                'type' = 'choices'
                                'choices' = @('UNSET', 'ECONOMICAL', 'CONSERVATIVE')
                                'defaultValue' = 'UNSET'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($SendManyItem)

            # setaccount 
            $SetAccountItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $SetAccountItem.Text = "Set account (deprecated)"
            $SetAccountItem.Add_Click({
                $command = 'setaccount'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Address', 'Account')
                        'types' = @{
                            'Address' = @{
                                'type' = 'string'
                            }
                            'Account' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($SetAccountItem)

            # setcoinjoinamount 
            $SetCoinJoinAmountItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $SetCoinJoinAmountItem.Text = "Set coinjoin amount"
            $SetCoinJoinAmountItem.Add_Click({
                $command = 'setcoinjoinamount'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Amount')
                        'types' = @{
                            'Amount' = @{
                                'type' = 'decimal'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($SetCoinJoinAmountItem)

            # setcoinjoinrounds 
            $SetCoinJoinRoundsItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $SetCoinJoinRoundsItem.Text = "Set coinjoin rounds"
            $SetCoinJoinRoundsItem.Add_Click({
                $command = 'setcoinjoinrounds'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Rounds')
                        'types' = @{
                            'Rounds' = @{
                                'type' = 'int'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($SetCoinJoinRoundsItem)

            # settxfee 
            $SetTxFeeItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $SetTxFeeItem.Text = "Set transaction fee"
            $SetTxFeeItem.Add_Click({
                $command = 'settxfee'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Amount')
                        'types' = @{
                            'Amount' = @{
                                'type' = 'decimal'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($SetTxFeeItem)

            # signmessage 
            $SignMessageItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $SignMessageItem.Text = "Sign message"
            $SignMessageItem.Add_Click({
                $command = 'signmessage'
                $commandParameters = @{
                    $command = @{
                        'required' = @('Address', 'Message')
                        'types' = @{
                            'Address' = @{
                                'type' = 'string'
                            }
                            'Message' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($SignMessageItem)

            # signrawtransactionwithwallet 
            $SignRawTransactionWithWalletItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $SignRawTransactionWithWalletItem.Text = "Sign raw transaction with wallet"
            $SignRawTransactionWithWalletItem.Add_Click({
                $command = 'signrawtransactionwithwallet'
                $commandParameters = @{
                    $command = @{
                        'required' = @('HexString')
                        'optional' = @('Inputs', 'SigHashType')
                        'types' = @{
                            'HexString' = @{
                                'type' = 'string'
                            }
                            'Inputs' = @{
                                'type' = 'array'
                                'subtype' = @{
                                    'txid' = @{
                                        'type' = 'string'
                                    }
                                    'vout' = @{
                                        'type' = 'int'
                                    }
                                    'scriptPubKey' = @{
                                        'type' = 'string'
                                    }
                                    'redeemScript' = @{
                                        'type' = 'string'
                                    }
                                }
                            }
                            'SigHashType' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($SignRawTransactionWithWalletItem)

            # unloadwallet 
            $UnloadWalletItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $UnloadWalletItem.Text = "Unload wallet"
            $UnloadWalletItem.Add_Click({
                $command = 'unloadwallet'
                $commandParameters = @{
                    $command = @{
                        'optional' = @('WalletName')
                        'types' = @{
                            'WalletName' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($UnloadWalletItem)

            # upgradetohd 
            $UpgradeToHDItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $UpgradeToHDItem.Text = "Upgrade to HD"
            $UpgradeToHDItem.Add_Click({
                $command = 'upgradetohd'
                $commandParameters = @{
                    $command = @{
                        'optional' = @('Mnemonic', 'MnemonicPassphrase', 'WalletPassphrase')
                        'types' = @{
                            'Mnemonic' = @{
                                'type' = 'string'
                            }
                            'MnemonicPassphrase' = @{
                                'type' = 'string'
                            }
                            'WalletPassphrase' = @{
                                'type' = 'string'
                            }
                        }
                    }
                }
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($UpgradeToHDItem)

            # walletlock
            $WalletLockItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $WalletLockItem.Text = "Wallet lock"
            $WalletLockItem.Add_Click({
                $command = 'walletlock'
                $commandParameters = @{}
                Set-ButtonWorking -index 4 -list $buttonListWallet
                Show-CommandParametersForm -command $command -commandParameters $commandParameters -console $consoleTextBoxWallet
                Reset-Button -index 4 -list $buttonListWallet
            })
            $WalletMenu.Items.Add($WalletLockItem)
            
            $WalletMenu.Show($buttonWallet, $buttonWallet.PointToClient([System.Windows.Forms.Cursor]::Position))
            $buttonWallet.ContextMenuStrip = $WalletMenu
            })
        }
        'Edit RaptoreumCore Config File' {
            $buttonWallet.Add_Click({
                Set-ButtonWorking -index 4 -list $buttonListWallet
                if ($checkBox2.Checked -eq $true) {$rtmconf = "nodetest\raptoreum_testnet.conf"} else {$rtmconf = "raptoreum.conf"}
                Execute-Command -command "notepad `"$global:raptoreumFolder\$rtmconf`"" -console $consoleTextBoxWallet -background $true -hidden "Hidden"
                Reset-Button -index 4 -list $buttonListWallet
            })
        }
    }
    $buttonListWallet += $buttonWallet
    $WalletTab.Controls.Add($buttonWallet)
    $top += 40
}


# Smartnode tab buttons
$buttons = @("Install a Smartnode", "Smartnode Dashboard 9000 Pro Plus", "Get blockchain info", "Smartnode status", "Start daemon (admin)", "Stop daemon (admin)", "Get daemon status", "Open a Smartnode Bash (admin)", "Update Smartnode (admin)", "Edit Smartnode Config File")
$top = 10
$left = 10
$width = 350
$height = 40
$buttonListSmartnode = @()
foreach ($btnText in $buttons) {
    $buttonSmartnode = New-Object System.Windows.Forms.Button
    $buttonSmartnode.Location = New-Object System.Drawing.Point($left, $top)
    $buttonSmartnode.Size = New-Object System.Drawing.Size($width, $height)
    $buttonSmartnode.Text = $btnText
    $buttonSmartnode.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $buttonSmartnode.BackColor = [System.Drawing.Color]::LightGray
    $buttonSmartnode.ForeColor = [System.Drawing.Color]::Black
    $buttonSmartnode.FlatAppearance.BorderSize = 1
    $buttonSmartnode.FlatAppearance.BorderColor = [System.Drawing.Color]::DarkGray
    $buttonSmartnode.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10)
    $buttonSmartnode.Font = New-Object System.Drawing.Font("Consolas", 10)
    switch ($btnText) {
        'Install a Smartnode' {
            $buttonSmartnode.Add_Click({
                $installSmartnodeUrl = "https://raw.githubusercontent.com/wizz13150/Raptoreum_Smartnode/main/SmartNode_Install.bat"
                $installSmartnodePath = "$env:TEMP\rtm_smartnode_installer.bat"        
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($installSmartnodeUrl, $installSmartnodePath)   
                Set-ButtonWorking -index 0 -list $buttonListSmartnode
                Execute-Command -command "$installSmartnodePath" -background $true -console $consoleTextBoxSmartnode -hidden "Normal"
                Reset-Button -index 0 -list $buttonListSmartnode
            })
        }        
        'Smartnode Dashboard 9000 Pro Plus' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 1 -list $buttonListSmartnode
                if ($checkBox1.Checked -eq $true) {$dashboard = "dashboard_testnet.ps1"
                    Execute-Command -command 'powershell.exe -ExecutionPolicy Bypass -File "%USERPROFILE%\dashboard_testnet.ps1"' -console $consoleTextBoxSmartnode -background $true -hidden "Normal"
                } else {
                    Execute-Command -command 'powershell.exe -ExecutionPolicy Bypass -File "%USERPROFILE%\dashboard.ps1"' -console $consoleTextBoxSmartnode -background $true -hidden "Normal"
                }
                Reset-Button -index 1 -list $buttonListSmartnode
            })
        }        
        'Get blockchain info' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 2 -list $buttonListSmartnode
                Execute-SmartnodeCommand -command "getblockchaininfo" -console $consoleTextBoxSmartnode
                Reset-Button -index 2 -list $buttonListSmartnode
            })
        }
        'Smartnode status' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 3 -list $buttonListSmartnode
                Execute-SmartnodeCommand -command "smartnode status" -console $consoleTextBoxSmartnode
                Reset-Button -index 3 -list $buttonListSmartnode
            })
        }
        'Start daemon (admin)' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 4 -list $buttonListSmartnode
                Change-Vars
                Execute-Command -command "net start $global:serviceName" -console $consoleTextBoxSmartnode -admin $true
                Reset-Button -index 4 -list $buttonListSmartnode
            })
        }
        'Stop daemon (admin)' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 5 -list $buttonListSmartnode
                Change-Vars
                Execute-Command -command "net stop $global:serviceName" -console $consoleTextBoxSmartnode -admin $true
                Reset-Button -index 5 -list $buttonListSmartnode
            })
        }
        'Get daemon status' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 6 -list $buttonListSmartnode
                Change-Vars
                Write-Host "global:serviceName when clicking: $global:serviceName"
                Execute-Command -command "sc query $global:serviceName" -console $consoleTextBoxSmartnode
                Reset-Button -index 6 -list $buttonListSmartnode
            })
        }
        'Open a Smartnode Bash (admin)' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 7 -list $buttonListSmartnode
                if ($global:raptoreumcli -match "-testnet") {$MOTD = "RTM-MOTD_testnet.txt"} else {$MOTD = "RTM-MOTD.txt"}
                Execute-Command -command "start cmd.exe /k type $env:USERPROFILE\$MOTD" -console $consoleTextBoxSmartnode -admin $true
                Reset-Button -index 7 -list $buttonListSmartnode
            })
        }
        'Update Smartnode (admin)' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 8 -list $buttonListSmartnode
                if ($checkBox1.Checked -eq $true) {$update = "update_testnet.ps1"} else {$update = "update.ps1"}
                Execute-Command -command "powershell.exe -ExecutionPolicy Bypass -File $env:USERPROFILE\$update" -console $consoleTextBoxSmartnode -admin $true
                Reset-Button -index 8 -list $buttonListSmartnode
            })
        }
        'Edit Smartnode Config File' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 9 -list $buttonListSmartnode
                if ($checkBox1.Checked -eq $true) {$conf = "nodetest\raptoreum_testnet.conf"} else {$conf = "raptoreum.conf"}
                Execute-Command -command "notepad `"$global:smartnodeFolder\$conf`"" -console $consoleTextBoxSmartnode -background $true -hidden "Hidden"
                Reset-Button -index 9 -list $buttonListSmartnode
            })
        }
    }
    $buttonListSmartnode += $buttonSmartnode
    $SmartnodeTab.Controls.Add($buttonSmartnode)
    $top += 40
}


# Miner tab buttons
$buttons = @("Download RaptorWings", "Download XMRig    (cpu)", "Download CPuminer (cpu)", "Download WildRig  (gpu)", "Launch RaptorWings", "Launch XMRig    (cpu)", "Launch CPuminer (cpu)", "Launch WildRig  (gpu)")
$top = 10
$left = 10
$width = 350
$height = 40
$buttonListMiner = @()
$separatorDrawn = $false
foreach ($btnText in $buttons) {
    # Ajouter de l'espace pour le séparateur et dessiner une ligne
    if (($btnText -eq "Launch RaptorWings") -and (-not $separatorDrawn)) {
        $top = [int]$top + 40 # Ajouter de l'espace pour le séparateur
        $separator = New-Object System.Windows.Forms.Label
        $separator.Location = New-Object System.Drawing.Point($left, 190 )
        $separator.Size = New-Object System.Drawing.Size($width, 2)
        $separator.BackColor = [System.Drawing.Color]::DarkGray
        $MinerTab.Controls.Add($separator)
        $separatorDrawn = $true
    }
    
    $buttonMiner = New-Object System.Windows.Forms.Button
    $buttonMiner.Location = New-Object System.Drawing.Point($left, $top)
    $buttonMiner.Size = New-Object System.Drawing.Size($width, $height)
    $buttonMiner.Text = $btnText
    $buttonMiner.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $buttonMiner.BackColor = [System.Drawing.Color]::LightGray
    $buttonMiner.ForeColor = [System.Drawing.Color]::Black
    $buttonMiner.FlatAppearance.BorderSize = 1
    $buttonMiner.FlatAppearance.BorderColor = [System.Drawing.Color]::DarkGray
    $buttonMiner.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10)
    $buttonMiner.Font = New-Object System.Drawing.Font("Consolas", 10)
    switch ($btnText) {
        'Download RaptorWings' {
            $buttonMiner.Add_Click({
                Set-ButtonWorking -index 0 -list $buttonListMiner
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
                Reset-Button -index 0 -list $buttonListMiner
            })
        }
        'Download XMRig    (cpu)' {
            $buttonMiner.Add_Click({
                Set-ButtonWorking -index 1 -list $buttonListMiner
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
                Reset-Button -index 1 -list $buttonListMiner
            })
        }
        'Download CPuminer (cpu)' {
            $buttonMiner.Add_Click({
                Set-ButtonWorking -index 2 -list $buttonListMiner
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
                Reset-Button -index 2 -list $buttonListMiner
            })
        }
        'Download WildRig  (gpu)' {
            $buttonMiner.Add_Click({
                Set-ButtonWorking -index 3 -list $buttonListMiner
                $tempDir = [System.IO.Path]::GetTempPath()
                $wildrigZip = "$tempDir" + "wildrig.zip"
                $wildrigFolder = "$tempDir" + "wildrig"
                $uri = "https://api.github.com/repos/andru-kun/wildrig-multi/releases/latest"
                $response = Invoke-RestMethod -Uri $uri
                $wildrigDownloadUrl = $response.assets | Where-Object { $_.name -match "wildrig-multi-windows" } | Select-Object -ExpandProperty browser_download_url
                if ($wildrigDownloadUrl -eq $null) {
                    [System.Windows.Forms.MessageBox]::Show("An error occurred while retrieving the download link for WildRig.", "Download WildRig", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    return
                }
                try {
                    Invoke-WebRequest -Uri $wildrigDownloadUrl -OutFile $wildrigZip
                    & "C:\Program Files\7-Zip\7z.exe" x -y $wildrigZip -o"$wildrigFolder"
                    [System.Windows.Forms.MessageBox]::Show("WildRig downloaded and extracted successfully to $wildrigFolder.", "Download WildRig", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show("An error occurred while downloading or extracting WildRig.`r`nError message: $($Error[0].Exception.Message)", "Download WildRig", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
                Reset-Button -index 3 -list $buttonListMiner
            })
        }
        'Launch RaptorWings' {
            $buttonMiner.Add_Click({
                $tempDir = [System.IO.Path]::GetTempPath()
                $raptorwingsExePath = "$tempDir" + "raptorwings\RaptorWings.exe"
                Start-Process $raptorwingsExePath -WindowStyle Normal
            })
        }
        'Launch XMRig    (cpu)' {
            $buttonMiner.Add_Click({
                SaveFormData
                $tempDir = [System.IO.Path]::GetTempPath()
                $uri = "https://api.github.com/repos/xmrig/xmrig/releases/latest"
                $response = Invoke-RestMethod -Uri $uri
                $pool = $PoolTextBox.Text
                $user = $UserTextBox.Text
                $pass = $PassTextBox.Text
                $threads = $ThreadsTrackBar.Value
                $dir = "$tempDir" + "xmrig"
                $xmrigPath = "$dir\xmrig-$($($response.tag_name).Substring(1))\xmrig.exe"        
                if (Test-Path $xmrigPath) {
                    Start-Process -FilePath $xmrigPath -ArgumentList "-a gr -o $pool -u $user -p $pass -t $threads" -WindowStyle Normal -Verb RunAs
                } else {
                    [System.Windows.MessageBox]::Show("XMRig executable not found. Please ensure it is downloaded and placed in the correct directory.", "XMRig not found", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
                }
            })
        }
        'Launch CPuminer (cpu)' {
            $buttonMiner.Add_Click({
                SaveFormData
                $tempDir = [System.IO.Path]::GetTempPath()
                $uri = "https://api.github.com/repos/WyvernTKC/cpuminer-gr-avx2/releases/latest"
                $response = Invoke-RestMethod -Uri $uri
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
                    Start-Process $cpuminerBatPath -WindowStyle Normal -Verb RunAs
                } else {
                    [System.Windows.Forms.MessageBox]::Show("Unable to find cpuminer.bat.Please Download cpuminer first.", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            })
        }
        'Launch WildRig  (gpu)' {
            $buttonMiner.Add_Click({
                SaveFormData
                $tempDir = [System.IO.Path]::GetTempPath()
                $pool = $PoolTextBox.Text
                $user = $UserTextBox.Text
                $pass = $PassTextBox.Text
                $wildrigPath = "$tempDir" + "wildrig\wildrig.exe"
                if (Test-Path $wildrigPath) {
                    Start-Process -FilePath $wildrigPath -ArgumentList "--algo ghostrider --url $pool --user $user --pass $pass" -WindowStyle Normal -Verb RunAs
                } else {
                    [System.Windows.MessageBox]::Show("WildRig executable not found. Please ensure it is downloaded and placed in the correct directory.", "WildRig not found", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
                }
            })
        }
    }
    $buttonListMiner += $buttonMiner
    $MinerTab.Controls.Add($buttonMiner)
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
$SaveButton.Location = New-Object System.Drawing.Point(690, 180)
$SaveButton.Size = New-Object System.Drawing.Size(120, 40)
$SaveButton.Text = "Save settings"
$SaveButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
$SaveButton.BackColor = [System.Drawing.Color]::White
$SaveButton.Font = New-Object System.Drawing.Font("Consolas", 10)
$SaveButton.Add_Click({ SaveFormData })
$MinerTab.Controls.Add($SaveButton)

# Wildrig parameters Label
$WildrigParametersLabel = New-Object System.Windows.Forms.Label
$WildrigParametersLabel.Location = New-Object System.Drawing.Point(400, 145)
$WildrigParametersLabel.Size = New-Object System.Drawing.Size(200, 20)
$WildrigParametersLabel.Text = "Wildrig parameters:"
$MinerTab.Controls.Add($WildrigParametersLabel)

# OpenCL Platforms Label and ComboBox
$OpenCLPlatformsLabel = New-Object System.Windows.Forms.Label
$OpenCLPlatformsLabel.Location = New-Object System.Drawing.Point(400, 175)
$OpenCLPlatformsLabel.Size = New-Object System.Drawing.Size(120, 20)
$OpenCLPlatformsLabel.Text = "OpenCL Platforms:"
$MinerTab.Controls.Add($OpenCLPlatformsLabel)

$OpenCLPlatformsComboBox = New-Object System.Windows.Forms.ComboBox
$OpenCLPlatformsComboBox.Location = New-Object System.Drawing.Point(520, 175)
$OpenCLPlatformsComboBox.Size = New-Object System.Drawing.Size(120, 21)
$OpenCLPlatformsComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$OpenCLPlatformsComboBox.Items.AddRange(@('all', 'nvidia', 'amd'))
$OpenCLPlatformsComboBox.SelectedItem = 'all'
$OpenCLPlatformsComboBox.add_SelectedIndexChanged({
    SaveFormData
})
$MinerTab.Controls.Add($OpenCLPlatformsComboBox)

# OpenCL Threads Label and TextBox
$OpenCLThreadsLabel = New-Object System.Windows.Forms.Label
$OpenCLThreadsLabel.Location = New-Object System.Drawing.Point(400, 205)
$OpenCLThreadsLabel.Size = New-Object System.Drawing.Size(120, 20)
$OpenCLThreadsLabel.Text = "OpenCL Threads:"
$MinerTab.Controls.Add($OpenCLThreadsLabel)

$OpenCLThreadsTextBox = New-Object System.Windows.Forms.TextBox
$OpenCLThreadsTextBox.Location = New-Object System.Drawing.Point(520, 205)
$OpenCLThreadsTextBox.Size = New-Object System.Drawing.Size(120, 20)
$OpenCLThreadsTextBox.Text = "auto"
$OpenCLThreadsTextBox.add_TextChanged({
    SaveFormData
})
$MinerTab.Controls.Add($OpenCLThreadsTextBox)

# Get devices
$tempDir = [System.IO.Path]::GetTempPath()
$wildrigPath = "$tempDir" + "wildrig\wildrig.exe"
$WildRigOutput = cmd /C "$wildrigPath --print-devices"
$GPUs = ($WildRigOutput -split "`n")
$GPUInfos = $GPUs | Where-Object { $_ -match '^GPU\s*#\d+:' } | ForEach-Object { $index = ($_ -split ':')[0] -replace "GPU #", ''; $gpuname = ($_ -split '[(:]')[1].Trim(); New-Object PSObject -Property @{ Index = $index; Name = $gpuname } }

# Checkboxes
$initialY = 235
$y = $initialY
$maxPerRow = 2
$checkBoxCount = 0
$checkBoxes = New-Object System.Collections.Generic.List[System.Object]
foreach ($GPUInfo in $GPUInfos) {
    $CheckBox = New-Object System.Windows.Forms.CheckBox
    $CheckBox.Location = New-Object System.Drawing.Point(400, $y)
    $CheckBox.Size = New-Object System.Drawing.Size(180, 20)
    $CheckBox.Text = "GPU$($GPUInfo.Index): $($GPUInfo.Name)"
    $CheckBox.add_CheckStateChanged({
        SaveFormData
    })
    $checkBoxes.Add($CheckBox)
    $MinerTab.Controls.Add($CheckBox)
    
    $checkBoxCount++
    if ($checkBoxCount % $maxPerRow -eq 0) {
        $y += 25
    }
}

# Help tab buttons
$buttons = @("Raptoreum Website", "Raptoreum Documentation", "Raptoreum on Twitter", "Raptoreum Discord", "Raptoreum on Reddit", "Raptoreum on Telegram", "Raptoreum on GitHub", "Raptoreum Explorer", "Raptoreum Mining Pools", "Raptoreum Merchandise Store")
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
                Start-Process "https://raptoreum.com"
            })
        }
        'Raptoreum Documentation' {
            $Button.Add_Click({
                Start-Process "https://docs.raptoreum.com"
            })
        }
        'Raptoreum on Twitter' {
            $Button.Add_Click({
                Start-Process "https://twitter.com/Raptoreum"
            })
        }
        'Raptoreum Discord' {
            $Button.Add_Click({
                Start-Process "https://discord.gg/RKefY9C"
            })
        }
        'Raptoreum on Reddit' {
            $Button.Add_Click({
                Start-Process "https://www.reddit.com/r/raptoreum/"
            })
        }
        'Raptoreum on Telegram' {
            $Button.Add_Click({
                Start-Process "https://t.me/RaptoreumOfficial"
            })
        }
        'Raptoreum on GitHub' {
            $Button.Add_Click({
                Start-Process "https://github.com/Raptor3um/raptoreum"
            })
        }
        'Raptoreum Explorer' {
            $Button.Add_Click({
                Start-Process "https://explorer.raptoreum.com"
            })
        }
        'Raptoreum Mining Pools' {
            $Button.Add_Click({
                Start-Process "https://miningpoolstats.stream/raptoreum"
            })
        }
        'Raptoreum Merchandise Store' {
            $Button.Add_Click({
                Start-Process "https://raptoreum.myshopify.com/"
            })
        }
    }
    $HelpTab.Controls.Add($Button)
    $top += 40
}

# Creation PictureBox
$PictureBox = New-Object System.Windows.Forms.PictureBox
$PictureBox.Location = New-Object System.Drawing.Point(380, 40)
$PictureBox.Size = New-Object System.Drawing.Size(550, 336)
$filePath = ".\RTMLand.png"
if (!(Test-Path -Path $filePath)) {
    Invoke-WebRequest -Uri "https://github.com/wizz13150/Raptoreum_SmartNode/raw/main/test/RTMLand.png" -OutFile $filePath
}
$PictureBox.Image = [System.Drawing.Image]::FromFile(".\RTMLand.png")
# Stretch the image to fit the PictureBox
#$PictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
$HelpTab.Controls.Add($PictureBox)



# Load last settings
LoadFormData

Write-Host "global:smartnodeFolder: $global:smartnodeFolder"
Write-Host "global:raptoreumFolder: $global:raptoreumFolder"
Write-Host "global:smartnodecli: $global:smartnodecli"
Write-Host "global:raptoreumcli: $global:raptoreumcli"
Write-Host "global:serviceName: $global:serviceName"

$Form.Controls.Add($TabControl)
$Form.Add_Shown({$Form.Activate()})
[void]$Form.ShowDialog()
