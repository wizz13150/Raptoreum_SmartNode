Add-Type -AssemblyName System.Windows.Forms

# Vars
$smartnodecli = $env:raptoreumcli
$raptoreumcli = "E:\Raptoreum\Wallet1.3.17.02\raptoreum-cli.exe -conf=E:\Raptoreum\Wallet\raptoreum.conf"
$serviceName = "RTMService"
$executablePath = "E:\Raptoreum\Wallet1.3.17.02\raptoreum-qt.exe"

# Functions
function Execute-Command {
    param($command, $background, $console)

    if ($background) {
        $job = Start-Job -ScriptBlock {
            param ($command)
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command" -WindowStyle Normal
        } -ArgumentList $command
        $job | Wait-Job
        $console.Clear()
        $timestamp = Get-Date -Format "HH:mm:ss"
        $console.AppendText("[$timestamp] > $command (Executed in a new CMD window) ")
    } else {
        $output = cmd /C $command 2>&1
        $console.Clear()
        $timestamp = Get-Date -Format "HH:mm:ss"
        $console.AppendText("[$timestamp] > $command  `n")
        $console.AppendText(($output | Out-String))
    }
}

function Execute-WalletCommand {
    param($command, $console, $parameters)

    $job = Start-Job -ScriptBlock {
        param ($command, $parameters, $raptoreumcli)
        cmd /C "$raptoreumcli $command $parameters" 2>&1
    } -ArgumentList $command, $parameters, $raptoreumcli
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

    $job = Start-Job -ScriptBlock {
        param ($command, $smartnodecli)
        cmd /C "$smartnodecli smartnode $command" 2>&1
    } -ArgumentList $command, $smartnodecli
    $output = $job | Wait-Job | Receive-Job
    $console.Clear()
    $timestamp = Get-Date -Format "HH:mm:ss"
    $console.AppendText("[$timestamp] > smartnode $command  `n")
    $console.AppendText(($output | Out-String))
}

function SaveFormData {
    $checkedGPUs = ($MinerTab.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] -and $_.Checked } | ForEach-Object { $_.Text.Split(" ")[0].Replace("GPU", "").Replace(":", "") }) -join ","
    $json = @"
{
    "Pool": "$($PoolTextBox.Text)",
    "User": "$($UserTextBox.Text)",
    "Pass": "$($PassTextBox.Text)",
    "Threads": $($ThreadsTrackBar.Value),
    "Platforms": "$($OpenCLPlatformsComboBox.SelectedItem)",
    "OpenCLThreads": "$($OpenCLThreadsTextBox.Text)",
    "CheckedGPUs": "$checkedGPUs"
}
"@
    Set-Content -Path ".\configminer.json" -Value $json -Force
}

function LoadFormData {
    if (Test-Path ".\configminers.json") {
        $json = Get-Content -Path ".\configminer.json" -Raw
        $config = ConvertFrom-Json $json
        $PoolTextBox.Text = $config.Pool
        $UserTextBox.Text = $config.User
        $PassTextBox.Text = $config.Pass
        $ThreadsTrackBar.Value = $config.Threads
        $SelectedThreadsLabel.Text = $config.Threads
        $OpenCLPlatformsComboBox.SelectedItem = $config.Platforms
        $OpenCLThreadsTextBox.Text = $config.OpenCLThreads        
        $checkedGPUs = $config.CheckedGPUs -split ","
        $MinerTab.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] } | ForEach-Object {
            $gpuIndex = $_.Text.Split(" ")[0].Replace("GPU", "")
            if ($checkedGPUs -contains $gpuIndex) {
                $_.Checked = $true
            } else {
                $_.Checked = $false
            }
        }
    } else {
        $PoolTextBox.Text = "stratum+tcp://eu.flockpool.com:4444"
        $UserTextBox.Text = "RMRwCAkSJaWHGPiP1rF5EHuUYDTze2xw6J.wizz"
        $PassTextBox.Text = "tototo"
        $ThreadsTrackBar.Value = "4"
        $SelectedThreadsLabel.Text = "4"
        $OpenCLPlatformsComboBox.SelectedItem = 'all'
        $OpenCLThreadsTextBox.Text = "auto"
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
        [System.Windows.Forms.Button]$button,
        [hashtable]$commandParameters,
        [System.Windows.Forms.TextBox]$console
    )

    $realValues = @{}
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
                        if ($currentType.defaultValue) {
                            $subTextBox.Text = $currentType.defaultValue
                        }
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
                $comboBox.Add_SelectedIndexChanged({
                    $selectedIndex = $comboBox.SelectedIndex
                    if ($currentType.realValue) {
                        $realValues[$name] = $currentType.realValue[$selectedIndex]
                    } else {
                        $realValues[$name] = $currentType.choices[$selectedIndex]
                    }
                })
                $form.Controls.Add($comboBox)
            } else {
                $textBox = New-Object System.Windows.Forms.TextBox
                $textBox.Location = New-Object System.Drawing.Point(10, $y)
                $textBox.Size = New-Object System.Drawing.Size(280, 20)
                if ($currentType.defaultValue) {
                    $textBox.Text = $currentType.defaultValue
                }
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
                        if ($currentType.defaultValue) {
                            $subTextBox.Text = $currentType.defaultValue
                        }
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
                $comboBox.Add_SelectedIndexChanged({
                    $selectedIndex = $comboBox.SelectedIndex
                    if ($types[$name].realValue) {
                        $realValues[$name] = $types[$name].realValue[$selectedIndex]
                    } else {
                        $realValues[$name] = $types[$name].choices[$selectedIndex]
                    }
                })
                $form.Controls.Add($comboBox)
            } else {
                $textBox = New-Object System.Windows.Forms.TextBox
                $textBox.Location = New-Object System.Drawing.Point(10, $y)
                $textBox.Size = New-Object System.Drawing.Size(280, 20)
                if ($currentType.defaultValue) {
                    $subTextBox.Text = $currentType.defaultValue
                }
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
            $requiredValues = @()
            $optionalValues = @()
            for ($i = 0; $i -lt $requiredParameters.Count; $i++) {
                if ($types[$requiredParameters[$i]].type.ToLower() -eq 'boolean') {
                    $comboBox = $form.Controls | Where-Object { $_.GetType() -eq [System.Windows.Forms.ComboBox] -and $_.Location.Y -eq (($_.Location.Y - 20) / 30) * 30 + 20 }
                    if ($comboBox -and $comboBox[$i - $requiredParameters.Count]) {
                        $requiredValues += $comboBox[$i].SelectedItem.ToString()
                    }
                } else {
                    if ($types[$requiredParameters[$i]].type.ToLower() -eq 'choices') {
                        $requiredValues += $realValues[$name]
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
            }
            for ($i = 0; $i -lt $optionalParameters.Count; $i++) {
                if ($types[$optionalParameters[$i]].type.ToLower() -eq 'boolean') {
                    $comboBox = $form.Controls | Where-Object { $_.GetType() -eq [System.Windows.Forms.ComboBox] -and $_.Location.Y -eq (($_.Location.Y - 20) / 30) * 30 + 20 }
                    if ($comboBox -and $comboBox[$i - $requiredParameters.Count]) {
                        $optionalValues += $comboBox[$i - $requiredParameters.Count].SelectedItem.ToString()
                    }
                } else {
                    if ($types[$optionalParameters[$i]].type.ToLower() -eq 'choices') {
                        $optionalValues += $realValues[$name]
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
$WalletTab.Text = "Wallet"
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

$consoleTextBoxgeneral = New-Object System.Windows.Forms.TextBox
$consoleTextBoxgeneral.Location = New-Object System.Drawing.Point(400, 10)
$consoleTextBoxgeneral.Size = New-Object System.Drawing.Size(520, 400)
$consoleTextBoxgeneral.Multiline = $true
$consoleTextBoxgeneral.ScrollBars = 'Vertical'
$consoleTextBoxgeneral.ReadOnly = $true
$consoleTextBoxgeneral.BackColor = [System.Drawing.Color]::Black
$consoleTextBoxgeneral.ForeColor = [System.Drawing.Color]::Green
$consoleTextBoxgeneral.Font = New-Object System.Drawing.Font("Consolas", 9)
$GeneralTab.Controls.Add($consoleTextBoxgeneral)

# General tab buttons
$buttons = @("Get blockchain info", "Smartnode status")
$top = 10
$left = 10
$width = 350
$height = 40
$buttonListGeneral = @()
foreach ($btnText in $buttons) {
    $localButton = New-Object System.Windows.Forms.Button
    $localButton.Location = New-Object System.Drawing.Point($left, $top)
    $localButton.Size = New-Object System.Drawing.Size($width, $height)
    $localButton.Text = $btnText
    $localButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $localButton.BackColor = [System.Drawing.Color]::LightGray
    $localButton.ForeColor = [System.Drawing.Color]::Black
    $localButton.FlatAppearance.BorderSize = 1
    $localButton.FlatAppearance.BorderColor = [System.Drawing.Color]::DarkGray
    $localButton.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10)
    $localButton.Font = New-Object System.Drawing.Font("Consolas", 10)
    switch ($btnText) {
        'Get blockchain info' {
            $localButton.Add_Click({
                Set-ButtonWorking -index 0 -list $buttonListGeneral
                Execute-WalletCommand -command "getblockchaininfo" -console $consoleTextBoxgeneral
                Reset-Button -index 0 -list $buttonListGeneral
            })
        }
        'Smartnode status' {
            $localButton.Add_Click({
                Set-ButtonWorking -index 1 -list $buttonListGeneral
                Execute-SmartnodeCommand -command "status" -console $consoleTextBoxgeneral
                Reset-Button -index 1 -list $buttonListGeneral
            })
        }
    }
    $buttonListGeneral += $localButton    
    foreach ($button in $buttonListGeneral) {
        $GeneralTab.Controls.Add($button)
    }
    $top += 40
}

# Wallet tab buttons
$buttons = @("Install Wallet", "Apply a Bootstrap (admin todo)", "Blockchain", "Control/Evo/Generating/Mining", "Wallet", "Network", "Protx Commands", "Util", "Edit RaptoreumCore Config File")
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
        'Apply a Bootstrap' { 
            $buttonWallet.Add_Click({
                $bootstrapUrl = "https://raw.githubusercontent.com/wizz13150/RaptoreumStuff/main/RTM_Bootstrap.bat"
                $bootstrapPath = "$env:TEMP\RTM_Bootstrap.bat"        
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($bootstrapUrl, $bootstrapPath)        
                Set-ButtonWorking -index 1 -list $buttonListWallet
                Execute-Command -command "cmd /c $bootstrapPath" -background $true -console $consoleTextBoxWallet
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

            Set-ButtonWorking -index 6 -list $buttonListWallet
            # Detect IP
            Write-Host "Commands here"
            $wanIP = Invoke-WebRequest -Uri "http://ipecho.net/plain" -UseBasicParsing | Select-Object -ExpandProperty Content
            $wanIP

            # Detect last 200 transactions !$Null
            $transactions = cmd /C "$raptoreumcli listtransactions * 200 0" 2>&1 | ConvertFrom-Json
            $transactionsForDropDown = @()
            $transactionsForRealValue = @()
            foreach ($transaction in $transactions) {
                if ($transaction.category -eq "send" -and $transaction.amount -eq 1800000) {
                    $txid = $transaction.txid
                    $shortTxid = $txid.Substring(0, 15) + "..." + $txid.Substring($txid.Length - 15)
                    $amount = [math]::Abs($transaction.amount)
                    $transactionsForDropDown += "$shortTxid - $amount RTM"
                    $transactionsForRealValue += $txid
                }
            }
            $transactionsForDropDown

            # Detect addresses with balance > 1 RTM and <= 100 RTM for fee
            $unspent = cmd /C "$raptoreumcli listunspent" 2>&1 | ConvertFrom-Json
            $addressesForDropDown = @()
            $addressesForRealValue = @()
            $counter = 0
            foreach ($entry in $unspent) {
                if ([double]$entry.amount -gt 1 -and [double]$entry.amount -le 100) {
                    $shortAddress = $entry.address.Substring(0, 12) + "..." + $entry.address.Substring($entry.address.Length - 12)
                    $addressesForDropDown += "$shortAddress - $([double]$entry.amount) RTM"
                    $addressesForRealValue += $entry.address
                    $counter++
                }
                if ($counter -eq 30) { break }
            }
            $addressesForDropDown
            Reset-Button -index 6 -list $buttonListWallet
            
            $ProtxQuickSetupItem.Add_Click({
                $command = 'protx quick_setup'
                $commandParameters = @{
                    $command = @{
                        'required' = @('collateralHash', 'collateralIndex', 'ipAndPort')
                        'optional' = @('feeSourceAddress')
                        'types' = @{
                            'collateralHash' = @{
                                'type' = 'choices'
                                'choices' = $transactionsForDropDown
                                'realValue' = $transactionsForRealValue
                            }
                            'collateralIndex' = @{
                                'type' = 'string'
                                'defaultValue' = "0"
                            }
                            'ipAndPort' = @{
                                'type' = 'string'
                                'defaultValue' = "$($wanIP):10226"
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
            $ProtxMenu.Items.Add($ProtxQuickSetupItem)

            # protx register_fund
            $ProtxRegisterFundItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $ProtxRegisterFundItem.Text = "ProTX Register Fund"
            $ProtxRegisterFundItem.Add_Click({
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
                                'choices' = @('valid', 'all', 'wallet')
                                'defaultValue' = 'valid'
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
                Execute-Command -command "notepad `"$env:APPDATA\RaptoreumCore\raptoreum.conf`""
            })
        }
    }
    $buttonListWallet += $buttonWallet
    $WalletTab.Controls.Add($buttonWallet)
    $top += 40
}


# Smartnode tab buttons
$buttons = @("Install Smartnode", "Smartnode Dashboard 9000 Pro Plus", "Get blockchain info", "Smartnode status", "Start daemon (admin todo)", "Stop daemon (admin todo)", "Get daemon status", "Open a Bash (admin todo)", "Update Smartnode (admin todo)", "Edit Smartnode Config File")
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
        'Install Smartnode' {
            $buttonSmartnode.Add_Click({
                $installSmartnodeUrl = "https://raw.githubusercontent.com/wizz13150/Raptoreum_Smartnode/main/SmartNode_Install.bat"
                $installSmartnodePath = "$env:TEMP\rtm_smartnode_installer.bat"        
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($installSmartnodeUrl, $installSmartnodePath)   
                Set-ButtonWorking -index 0 -list $buttonListSmartnode
                Execute-Command -command "cmd /c $installSmartnodePath"  -background $true -console $consoleTextBoxSmartnode
                Reset-Button -index 0 -list $buttonListSmartnode
            })
        }        
        'Smartnode Dashboard 9000 Pro Plus' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 1 -list $buttonListSmartnode
                Execute-Command -command 'powershell.exe -ExecutionPolicy Bypass -File "%USERPROFILE%\dashboard.ps1"' -background $true -console $consoleTextBoxSmartnode
                Reset-Button -index 1 -list $buttonListSmartnode
            })
        }        
        'Get blockchain info' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 2 -list $buttonListSmartnode
                Execute-WalletCommand -command "getblockchaininfo" -console $consoleTextBoxSmartnode
                Reset-Button -index 2 -list $buttonListSmartnode
            })
        }
        'Smartnode status' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 3 -list $buttonListSmartnode
                Execute-SmartnodeCommand -command "status" -console $consoleTextBoxSmartnode
                Reset-Button -index 3 -list $buttonListSmartnode
            })
        }
        'Start daemon' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 4 -list $buttonListSmartnode
                Execute-Command -command "net start $serviceName" -console $consoleTextBoxSmartnode
                Reset-Button -index 4 -list $buttonListSmartnode
            })
        }
        'Stop daemon' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 5 -list $buttonListSmartnode
                Execute-Command -command "net stop $serviceName" -console $consoleTextBoxSmartnode
                Reset-Button -index 5 -list $buttonListSmartnode
            })
        }
        'Get daemon status' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 6 -list $buttonListSmartnode
                Execute-Command -command "sc query $serviceName" -console $consoleTextBoxSmartnode
                Reset-Button -index 6 -list $buttonListSmartnode
            })
        }
        'Open a Bash' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 7 -list $buttonListSmartnode
                Execute-Command -command "start cmd.exe /k type $env:USERPROFILE\RTM-MOTD.txt" -background $true -console $consoleTextBoxSmartnode
                Reset-Button -index 7 -list $buttonListSmartnode
            })
        }
        'Update Smartnode' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 8 -list $buttonListSmartnode
                Execute-Command -command "powershell.exe -ExecutionPolicy Bypass -File $env:USERPROFILE\update.ps1"-background $true -console $consoleTextBoxSmartnode
                Reset-Button -index 8 -list $buttonListSmartnode
            })
        }
        'Edit Smartnode Config File' {
            $buttonSmartnode.Add_Click({
                Set-ButtonWorking -index 9 -list $buttonListSmartnode
                Execute-Command -command "notepad `"$env:APPDATA\RaptoreumSmartnode\raptoreum.conf`"" -console $consoleTextBoxSmartnode
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
                $latestVersion = $response.tag_name
                
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
                $latestVersion = $response.tag_name
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
$MinerTab.Controls.Add($OpenCLThreadsTextBox)

# Get devices
$tempDir = [System.IO.Path]::GetTempPath()
$wildrigPath = "$tempDir" + "wildrig\wildrig.exe"
$WildRigOutput = cmd /C "$wildrigPath --print-devices"
$GPUs = ($WildRigOutput -split "`n")
$GPUInfos = $GPUs | Where-Object { $_ -match '^GPU\s*#\d+:' } | ForEach-Object { $index = ($_ -split ':')[0] -replace "GPU #", ''; $name = ($_ -split '[(:]')[1].Trim(); New-Object PSObject -Property @{ Index = $index; Name = $name } }

# Checkboxes
$initialY = 235
$y = $initialY
$maxPerRow = 2
$checkBoxCount = 0
foreach ($GPUInfo in $GPUInfos) {
    $CheckBox = New-Object System.Windows.Forms.CheckBox
    $CheckBox.Location = New-Object System.Drawing.Point(400, $y)
    $CheckBox.Size = New-Object System.Drawing.Size(180, 20)
    $CheckBox.Text = "GPU$($GPUInfo.Index): $($GPUInfo.Name)"
    $MinerTab.Controls.Add($CheckBox)
    
    $checkBoxCount++
    if ($checkBoxCount % $maxPerRow -eq 0) {
        $y += 25
    }
}

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
                Execute-Command -command "start https://raptoreum.com"
            })
        }
        'Raptoreum Documentation' {
            $Button.Add_Click({
                Execute-Command -command "start https://docs.raptoreum.com"
            })
        }
        'Raptoreum on Twitter' {
            $Button.Add_Click({
                Execute-Command -command "start https://twitter.com/Raptoreum"
            })
        }
        'Raptoreum Discord' {
            $Button.Add_Click({
                Execute-Command -command "start https://discord.gg/RKefY9C"
            })
        }
        'Raptoreum on Reddit' {
            $Button.Add_Click({
                Execute-Command -command "start https://www.reddit.com/r/raptoreum/"
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
