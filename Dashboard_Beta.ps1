Add-Type -AssemblyName System.Windows.Forms
 
$traptoreumcli = $env:raptoreumcli
$serviceName = "RTMService"
$executablePath = "C:\Program Files (x86)\RaptoreumCore\raptoreum-qt.exe"

function Execute-Command {
    param($command, $buttonName, $background)
    
    if ($background) {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command" -WindowStyle Normal
        $consoleTextBox.AppendText("`n> $buttonName (Executed in a new CMD window)")
    } else {
        $output = cmd /C $command 2>&1
        $consoleTextBox.AppendText("`n> $buttonName ")
        $consoleTextBox.AppendText(($output | Out-String))
    }
}
 
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Raptoreum Smartnode Tools"
$Form.Size = New-Object System.Drawing.Size(975, 490)
$Form.StartPosition = "CenterScreen"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($executablePath)
 
$consoleTextBox = New-Object System.Windows.Forms.TextBox
$consoleTextBox.Location = New-Object System.Drawing.Point(400, 10)
$consoleTextBox.Size = New-Object System.Drawing.Size(550, 430)
$consoleTextBox.Multiline = $true
$consoleTextBox.ScrollBars = 'Vertical'
$consoleTextBox.ReadOnly = $true
$consoleTextBox.BackColor = [System.Drawing.Color]::Black
$consoleTextBox.ForeColor = [System.Drawing.Color]::Green
$consoleTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Form.Controls.Add($consoleTextBox)
 
$buttons = @("Dashboard", "Get blockchain info", "Smartnode status", "Start daemon", "Stop daemon", "Get daemon status", "Open a Bash", "Update Smartnode" ) 
$top = 10
$left = 10
$width = 350
$height = 45
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
    $Button.Add_Click({
        switch ($this.Text) {
            'Dashboard' { Execute-Command -command 'powershell.exe -ExecutionPolicy Bypass -File "%USERPROFILE%\dashboard.ps1"' -buttonName 'Dashboard' -background $true }
            'Get blockchain info' { Execute-Command -command "$traptoreumcli getblockchaininfo" -buttonName 'Get blockchain info' }
            'Smartnode status' { Execute-Command -command "$traptoreumcli smartnode status" -buttonName 'Smartnode status' }
            'Start daemon' { Execute-Command -command "net start $serviceName" -buttonName 'Start daemon' }
            'Stop daemon' { Execute-Command -command "net stop $serviceName" -buttonName 'Stop daemon' }
            'Get daemon status' { Execute-Command -command "sc query $serviceName" -buttonName 'Get daemon status' }
            'Open a Bash' { Execute-Command -command "start cmd.exe /k type $env:USERPROFILE\RTM-MOTD.txt" -buttonName 'Open a Bash' -background $true }
            'Update Smartnode' { Execute-Command -command "powershell.exe -ExecutionPolicy Bypass -File $env:USERPROFILE\update.ps1" -buttonName 'Update Smartnode' -background $true }
        }
    })
    $Form.Controls.Add($Button)
    $top += $height + 10
}
$Form.ShowDialog()
