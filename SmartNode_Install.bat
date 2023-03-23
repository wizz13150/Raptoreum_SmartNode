@echo off

set DOWNLOAD_URL=https://raw.githubusercontent.com/wizz13150/Raptoreum_SmartNode/main/install.ps1
set USER_PROFILE=%USERPROFILE%
set DOWNLOAD_PATH=%USER_PROFILE%\install.ps1

echo Downloading file from %DOWNLOAD_URL%...
powershell.exe -Command "& { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -UseBasicParsing -OutFile '%DOWNLOAD_PATH%' }"

if exist "%DOWNLOAD_PATH%" (
  	echo File downloaded successfully!
  	echo Running install.ps1 as Admin...
	powershell.exe -ExecutionPolicy RemoteSigned -Command "Set-Content -Path '%DOWNLOAD_PATH%' -Value (Get-Content -Path '%DOWNLOAD_PATH%' -Encoding utf8) -Encoding utf8; Start-Process cmd.exe -ArgumentList '/c powershell.exe -ExecutionPolicy Bypass -File "%DOWNLOAD_PATH%"' -Verb RunAs
) else (
  echo Failed to download file.
)
