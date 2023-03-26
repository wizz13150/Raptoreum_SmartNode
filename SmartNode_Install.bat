@echo off
echo.
echo  =================================================================
echo  ^|  (       *             (               )     )  (             ^|
echo  ^|  )\ )  (  `     (      )\ )  *   )  ( /(  ( /(  )\ )          ^|
echo  ^| (()/(  )\))(    )\    (()/(` )  /(  )\()) )\())(()/(   (      ^|
echo  ^|  /(_))((_)()\((((_)(   /(_))( )(_))((_)\ ((_)\  /(_))  )\     ^|
echo  ^| (_))  (_()((_))\ _ )\ (_)) (_(_())  _((_)  ((_)(_))_  ((_)    ^|
echo  ^| / __^| ^|  \/  ^|(_)_\(_)^| _ \^|_   _^| ^| \^| ^| / _ \ ^|   \ ^| __^|   ^|
echo  ^| \__ \ ^| ^|\/^| ^| / _ \  ^|   /  ^| ^|   ^| .` ^|^| (_) ^|^| ^|) ^|^| _^|    ^|
echo  ^| ^|___/ ^|_^|  ^|_^|/_/ \_\ ^|_^|_\  ^|_^|   ^|_^|\_^| \___/ ^|___/ ^|___^|   ^|
echo  ^|                                                               ^|
echo  =================================================================
echo.
:choice
echo [1] Install a Mainnet Smartnode
echo [2] Install a Testnet Smartnode
echo.
echo Enter your choice (1 or 2):
set /p choice=


if %choice%==1 (
    set DOWNLOAD_URL=https://raw.githubusercontent.com/wizz13150/Raptoreum_SmartNode/main/install.ps1
    set FILE_NAME=install.ps1
) else if %choice%==2 (
    set DOWNLOAD_URL=https://raw.githubusercontent.com/wizz13150/Raptoreum_SmartNode/main/install_testnet.ps1
    set FILE_NAME=install_testnet.ps1
) else (
    echo Invalid choice. Please enter 1 or 2...
    echo.
    goto :choice
)

set USER_PROFILE=%USERPROFILE%
set DOWNLOAD_PATH=%USER_PROFILE%\%FILE_NAME%

echo  =================================================================
echo Downloading file from %DOWNLOAD_URL%...
powershell.exe -Command "& { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -UseBasicParsing -OutFile '%DOWNLOAD_PATH%' }"

if exist "%DOWNLOAD_PATH%" (
    echo.
    echo File downloaded successfully!
    echo  =================================================================
    echo Running %FILE_NAME% as Admin...
    powershell.exe -ExecutionPolicy RemoteSigned -Command "Set-Content -Path '%DOWNLOAD_PATH%' -Value (Get-Content -Path '%DOWNLOAD_PATH%' -Encoding utf8) -Encoding utf8; Start-Process cmd.exe -ArgumentList '/c powershell.exe -ExecutionPolicy Bypass -File "%DOWNLOAD_PATH%"' -Verb RunAs
) else (
    echo  =================================================================
    echo Failed to download file.
)
echo  =================================================================
