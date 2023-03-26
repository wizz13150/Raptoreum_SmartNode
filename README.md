NOT OFFICIAL, NOT RELATED TO THE RAPTOREUM CORE TEAM

# Raptoreum SmartNode for Windows
Transcript of [dk808/Raptoreum_SmartNode](https://github.com/dk808/Raptoreum_SmartNode) for Windows. Do the same job.

Download or Copy "[SmartNode_Install.bat](https://github.com/wizz13150/Raptoreum_SmartNode/blob/main/SmartNode_Install.bat)" and run it.

It will install Raptoreum binaries, 7-Zip, NSSM, LogrotateWin, configure basic firewall settings, create a daemon service (RTMService) to control raptoreumd process, and also create scheduled tasks that will check on daemon and Smartnode's health every 20 minutes and backup the chain every month. It also has a bootstrap option for quick syncing.

2 shortcuts will be created on the desktop to open a bash with the SmartNode, and to update the Smartnode.

This script use custom paths. You can install and run a standard QT wallet (Not recommended!!), the Smartnode will run in a parallel environment :
```
"C:\Program Files (x86)\RaptoreumCore" instead of "C:\Program Files\RaptoreumCore" for binaries
```
```
"%appdata%\RaptoreumSmartnode" instead of "%appdata%\RaptoreumCore" for the smartnode
```
The only way to kill raptoreumd.exe after installation is to stop the windows service "RTMservice".

Please check dk808's [Wiki](https://github.com/dk808/Raptoreum_SmartNode/wiki) for a detailed guide of the original script.

> ℹ Note: This has only been tested on a VM using Windows. USE AT OWN RISK.<br><br>

<br>

***

## Installation
- To install a Raptoreum Smartnode on Windows, open CMD or Powershell and run the following command :
```
powershell -ExecutionPolicy Bypass -c "Invoke-WebRequest -Uri https://raw.githubusercontent.com/wizz13150/Raptoreum_Smartnode/main/SmartNode_Install.bat -OutFile %USERPROFILE%\Downloads\SmartNode_Install.bat; %USERPROFILE%\Downloads\SmartNode_Install.bat"
```

- Or you can download the Batch file in the [Releases Section](https://github.com/wizz13150/Raptoreum_SmartNode/releases)


![image](https://user-images.githubusercontent.com/22177081/227794280-233f529c-b8c1-4fe0-9ec5-8fc0f7c42809.png)


> ℹ Info: Script will run as admin. Script will ask for BLS PrivKey(operatorSecret) and ProtXHash(txid) that you get from the protx quick_setup/bls generate command. So have it ready. This will also create a script to update binaries.

<br>

***

## Video of a Smartnode installation

Lil outdated, but mostly the same ('protx quick_setup' already done) :

https://user-images.githubusercontent.com/22177081/226721832-e33d81f6-2c47-4779-9d0e-96fd77e21e1c.mp4
***


__Do not forget to open port 10226 (or 10229 for testnet)__

__Always encrypt your wallet with a strong password__
> ℹ Info: You could ask support questions in [Raptoreum's Discord](https://discord.gg/wqgcxT3Mgh)
