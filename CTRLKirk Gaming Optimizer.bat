@echo off
setlocal enabledelayedexpansion
goto SAFE_LAUNCH
title CTRLKirk's Gaming Optimizer v10.0
mode con cols=100 lines=45

:: ============================================================================
:: CTRLKIRK'S GAMING OPTIMIZER v10.0
:: Universal Windows 10/11 Performance & Gaming Optimization Tool
:: Built for low-end hardware - every tweak is meant to actually help
:: ============================================================================

color 0A

:: ============================================================================
:: SECTION 1: AUTO-ELEVATION TO ADMINISTRATOR
:: ============================================================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    color 0E
    echo.
    echo [ELEVATION REQUIRED] Requesting Administrator privileges...
    echo.
    set "SELF=%~f0"
    set "SELF=!SELF:'=''!"
    powershell -NoProfile -Command "Start-Process -FilePath '!SELF!' -Verb RunAs"
    exit /b
)

:: ============================================================================
:: SETUP: timestamps, paths, helper temp dir (locale-independent)
:: ============================================================================
set "CKTMP=%TEMP%\CKOptimizer"
if not exist "%CKTMP%" mkdir "%CKTMP%" >nul 2>&1

for /f %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%t"
set "LOGFILE=%~dp0OptimizerLog_%TS%.log"
set "REPORT=%~dp0OptimizationReport_%TS%.txt"
echo Session started: %date% %time% > "%LOGFILE%"
set "BACKUPDIR=%~dp0Backups\Backup_%TS%"
mkdir "%BACKUPDIR%" >nul 2>&1
set "REGBACKUP=%BACKUPDIR%\RegistryBackup.reg"

cls
color 0A
echo.
echo  ================================================================================
echo  CTRLKIRK'S GAMING OPTIMIZER v10.0
echo  Universal Win10/Win11 Performance Tool - Low-End Hardware Edition
echo  ================================================================================
echo.
timeout /t 2 >nul

:: ============================================================================
:: SECTION 2: MODE SELECTION
:: ============================================================================
:MENU
goto SAFE_MENU
cls
color 0A
echo.
echo  ================================================================================
echo  MODE SELECTION
echo  ================================================================================
echo.
color 02
echo   [1] STANDARD MODE      - Safe optimizations, cleanup, RAM tools, network tweaks
echo   [2] AGGRESSIVE MODE    - Standard + system repair + service tweaks + net reset
echo   [3] AUTO MODE          - No questions, applies max-performance defaults
echo.
color 0B
echo   [4] RAM ^& MEMORY TOOLS - Standby list purge, working set trim, priority boost
echo   [5] UNDO / RESTORE     - Revert tweaks, restore registry backups, reset DNS
echo   [6] RECOMMENDED TOOLS  - Install Process Lasso, Quick CPU, HWiNFO, RAMMap
echo.
color 0E
echo   [9] Developer Tools (DEV ONLY)
color 0A
echo   [0] EXIT
echo.
set /p MODE="  Select mode: "

if "%MODE%"=="0" exit
if "%MODE%"=="9" goto DEV_MENU
if "%MODE%"=="4" goto RAM_MENU
if "%MODE%"=="5" goto UNDO_MENU
if "%MODE%"=="6" goto TOOLS_MENU

:: Set mode flags
set "DO_STANDARD=0"
set "DO_AGGRESSIVE=0"
set "DO_AUTO=0"
set "MODETEXT=UNKNOWN"

if "%MODE%"=="1" (
    set "DO_STANDARD=1"
    set "MODETEXT=STANDARD"
)
if "%MODE%"=="2" (
    set "DO_STANDARD=1"
    set "DO_AGGRESSIVE=1"
    set "MODETEXT=AGGRESSIVE"
)
if "%MODE%"=="3" (
    set "DO_STANDARD=1"
    set "DO_AUTO=1"
    set "MODETEXT=AUTO"
)

if "%DO_STANDARD%"=="0" goto MENU

:: ============================================================================
:: SECTION 2b: PREFERENCES - you choose what to keep. Nothing with a tradeoff
:: is applied without your say. AUTO mode uses max-performance defaults.
:: ============================================================================
:PREFERENCES
if "%DO_AUTO%"=="1" (
    set "KEEP_VISUALS=0"
    set "KEEP_NOTIFY=0"
    set "KEEP_GAMEDVR=0"
    set "USER_XBOX=1"
    set "SET_DNS=1"
    set "KEEP_WIDGETS=0"
    set "KEEP_BGAPPS=0"
    set "KEEP_SEC=0"
    set "KEEP_BING=0"
    goto PREFS_DONE
)

cls
color 0B
echo.
echo  ================================================================================
echo  YOUR PREFERENCES - WHAT DO YOU WANT TO KEEP?
echo  ================================================================================
echo.
echo  Some optimizations cost you a feature. Answer each - Y keeps the feature,
echo  N disables it for more performance. Default suggestion shown in [brackets].
echo.

set "A=" & set /p A="  [1] Animations + transparency effects?        (Y=keep / N=off) [N]: "
if /i "%A%"=="Y" (set "KEEP_VISUALS=1") else set "KEEP_VISUALS=0"

set "A=" & set /p A="  [2] Notifications from apps/Windows?          (Y=keep / N=off) [N]: "
if /i "%A%"=="Y" (set "KEEP_NOTIFY=1") else set "KEEP_NOTIFY=0"

set "A=" & set /p A="  [3] Game DVR background recording?            (Y=keep / N=off) [N]: "
if /i "%A%"=="Y" (set "KEEP_GAMEDVR=1") else set "KEEP_GAMEDVR=0"

set "A=" & set /p A="  [4] Xbox app / Game Bar social features?      (Y=keep / N=off) [Y]: "
if /i "%A%"=="N" (set "USER_XBOX=0") else set "USER_XBOX=1"

set "A=" & set /p A="  [5] Set DNS to Cloudflare 1.1.1.1?            (Y=apply / N=skip) [Y]: "
if /i "%A%"=="N" (set "SET_DNS=0") else set "SET_DNS=1"

set "A=" & set /p A="  [6] Widgets / News ^& Interests feed?         (Y=keep / N=off) [N]: "
if /i "%A%"=="Y" (set "KEEP_WIDGETS=1") else set "KEEP_WIDGETS=0"

set "A=" & set /p A="  [7] Store apps running in background?         (Y=keep / N=off) [N]: "
if /i "%A%"=="Y" (set "KEEP_BGAPPS=1") else set "KEEP_BGAPPS=0"

set "A=" & set /p A="  [8] Bing web results inside Start search?     (Y=keep / N=off) [N]: "
if /i "%A%"=="Y" (set "KEEP_BING=1") else set "KEEP_BING=0"

color 0E
set "A=" & set /p A="  [9] Memory Integrity/VBS security features?   (Y=keep / N=off) [Y]: "
if /i "%A%"=="N" (set "KEEP_SEC=0") else set "KEEP_SEC=1"
color 0B

:PREFS_DONE

:: ============================================================================
:: SECTION 3: CONFIRMATION
:: ============================================================================
:RUN_OPTIMIZER
goto SAFE_MENU
cls
color 02
echo.
echo  ================================================================================
echo  READY TO OPTIMIZE - MODE: %MODETEXT%
echo  ================================================================================
echo.
color 0A

echo  This will:
echo   - Force-close background apps (unsaved browser work WILL be lost)
echo   - Enable System Protection and create a Restore Point
echo   - Back up ALL registry keys it touches to Backups\ folder
echo   - Clean temp files, caches, and shader caches (NOT Prefetch)
echo   - Free RAM: trim working sets + purge standby list
echo   - Apply privacy + gaming registry optimizations
echo   - Optimize GPU settings (NVIDIA/AMD/Intel if detected)
echo.
color 0B
echo  YOUR CHOICES:
if "%KEEP_VISUALS%"=="1" (echo   - Visuals/animations:     KEEPING - your choice) else echo   - Visuals/animations:     will be DISABLED for performance
if "%KEEP_NOTIFY%"=="1"   (echo   - Notifications:          KEEPING - your choice) else echo   - Notifications:          will be DISABLED
if "%KEEP_GAMEDVR%"=="1"  (echo   - Game DVR recording:     KEEPING - your choice) else echo   - Game DVR recording:     will be DISABLED
if "%USER_XBOX%"=="1"     (echo   - Xbox/Game Bar services: KEEPING - your choice) else echo   - Xbox/Game Bar services: will be DISABLED (aggressive only)
if "%SET_DNS%"=="1"       (echo   - DNS:                    will be set to Cloudflare 1.1.1.1) else echo   - DNS:                    UNCHANGED (your choice)
if "%KEEP_WIDGETS%"=="1"  (echo   - Widgets/News feed:      KEEPING - your choice) else echo   - Widgets/News feed:      will be DISABLED
if "%KEEP_BGAPPS%"=="1"   (echo   - Background Store apps:  KEEPING - your choice) else echo   - Background Store apps:  will be DISABLED
if "%KEEP_BING%"=="1"     (echo   - Bing in Start search:   KEEPING - your choice) else echo   - Bing in Start search:   will be DISABLED
if "%KEEP_SEC%"=="1"      (echo   - Memory Integrity/VBS:   UNCHANGED - your choice) else echo   - Memory Integrity/VBS:   will be DISABLED (small FPS gain)
color 0A
echo.

if "%DO_AGGRESSIVE%"=="1" (
    color 0E
    echo  AGGRESSIVE MODE ADDITIONS:
    color 0A
    echo   - Run System File Checker and DISM repairs
    echo   - Reset Winsock and TCP/IP stack completely
    echo   - Disable non-essential services
    echo   - Rebuild search index
    echo.
    color 0E
    echo  WARNING: Aggressive mode disables services ^(reversible via menu option 5^)
    color 0A
    echo.
)

color 0E
echo  All changes can be fully reverted via menu option [5] UNDO / RESTORE.
color 0A
echo.

if "%DO_AUTO%"=="0" pause

:: Initialize DEV log (technical) + USER report (friendly)
echo ============================================================================ > "%LOGFILE%"
echo CTRLKIRK'S GAMING OPTIMIZER v10.0 - DEV/TECHNICAL LOG >> "%LOGFILE%"
echo Mode: %MODETEXT% >> "%LOGFILE%"
echo Start Time: %date% %time% >> "%LOGFILE%"
echo Prefs: VISUALS=%KEEP_VISUALS% NOTIFY=%KEEP_NOTIFY% GAMEDVR=%KEEP_GAMEDVR% XBOX=%USER_XBOX% DNS=%SET_DNS% WIDGETS=%KEEP_WIDGETS% BGAPPS=%KEEP_BGAPPS% BING=%KEEP_BING% SEC=%KEEP_SEC% >> "%LOGFILE%"
echo ============================================================================ >> "%LOGFILE%"
echo. >> "%LOGFILE%"

echo ============================================================================ > "%REPORT%"
echo  CTRLKIRK'S GAMING OPTIMIZER v10.0 - YOUR OPTIMIZATION REPORT >> "%REPORT%"
echo  %date% %time%  -  Mode: %MODETEXT% >> "%REPORT%"
echo ============================================================================ >> "%REPORT%"
echo. >> "%REPORT%"
echo  WHAT YOU CHOSE TO KEEP: >> "%REPORT%"
if "%KEEP_VISUALS%"=="1" (echo   [KEPT] Visual effects and animations >> "%REPORT%") else echo   [CHANGED] Visual effects minimized for performance >> "%REPORT%"
if "%KEEP_NOTIFY%"=="1"   (echo   [KEPT] Notifications >> "%REPORT%") else echo   [CHANGED] Notifications disabled >> "%REPORT%"
if "%KEEP_GAMEDVR%"=="1"  (echo   [KEPT] Game DVR background recording >> "%REPORT%") else echo   [CHANGED] Game DVR background recording disabled >> "%REPORT%"
if "%USER_XBOX%"=="1"     (echo   [KEPT] Xbox / Game Bar services >> "%REPORT%") else echo   [CHANGED] Xbox / Game Bar services disabled >> "%REPORT%"
if "%SET_DNS%"=="1"       (echo   [CHANGED] DNS set to Cloudflare 1.1.1.1 >> "%REPORT%") else echo   [KEPT] Your original DNS settings >> "%REPORT%"
if "%KEEP_WIDGETS%"=="1"  (echo   [KEPT] Widgets / News feed >> "%REPORT%") else echo   [CHANGED] Widgets / News feed disabled >> "%REPORT%"
if "%KEEP_BGAPPS%"=="1"   (echo   [KEPT] Background Store apps >> "%REPORT%") else echo   [CHANGED] Background Store apps disabled >> "%REPORT%"
if "%KEEP_BING%"=="1"     (echo   [KEPT] Bing results in Start search >> "%REPORT%") else echo   [CHANGED] Bing results removed from Start search >> "%REPORT%"
if "%KEEP_SEC%"=="1"      (echo   [KEPT] Memory Integrity / VBS security ON >> "%REPORT%") else echo   [CHANGED] Memory Integrity / VBS disabled for FPS >> "%REPORT%"
echo. >> "%REPORT%"
echo  ------------------------------------------------------------------------------ >> "%REPORT%"
echo  DETAILS: >> "%REPORT%"

:: ============================================================================
:: SECTION 4: CLOSE BACKGROUND APPS
:: ============================================================================
cls
color 0E
echo.
echo  ================================================================================
echo  CLOSING BACKGROUND APPLICATIONS
echo  ================================================================================
echo.
echo  Force-closing apps in 5 seconds - unsaved work WILL be lost!
echo  Press CTRL+C now to abort if needed.
timeout /t 5 >nul

echo.
echo  [CLOSING] Terminating background processes...
echo. >> "%LOGFILE%"
echo [CLOSING BACKGROUND APPLICATIONS] >> "%LOGFILE%"

taskkill /F /IM chrome.exe /T 2>nul
taskkill /F /IM firefox.exe /T 2>nul
taskkill /F /IM msedge.exe /T 2>nul
taskkill /F /IM brave.exe /T 2>nul
taskkill /F /IM opera.exe /T 2>nul
taskkill /F /IM discord.exe /T 2>nul
taskkill /F /IM steam.exe /T 2>nul
taskkill /F /IM steamwebhelper.exe /T 2>nul
taskkill /F /IM Teams.exe /T 2>nul
taskkill /F /IM ms-teams.exe /T 2>nul
taskkill /F /IM OneDrive.exe /T 2>nul
taskkill /F /IM Dropbox.exe /T 2>nul
taskkill /F /IM Spotify.exe /T 2>nul
taskkill /F /IM CCXProcess.exe /T 2>nul
taskkill /F /IM AdobeIPCBroker.exe /T 2>nul
taskkill /F /IM EPPCClient.exe /T 2>nul

color 0A
echo  [DONE] Background apps closed
echo.
timeout /t 2 >nul
call :STEPCHK

:: ============================================================================
:: SECTION 5: PRE-OPTIMIZATION SNAPSHOT (CIM - wmic is deprecated/removed)
:: ============================================================================
cls
color 02
echo.
echo  ================================================================================
echo  PRE-OPTIMIZATION SNAPSHOT
echo  ================================================================================
echo.
color 0A
echo  [SCANNING] Capturing system state...
echo.

powershell -NoProfile -Command "(Get-CimInstance Win32_Processor).LoadPercentage" > "%CKTMP%\cpu.txt" 2>nul
powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)" > "%CKTMP%\ram.txt" 2>nul
powershell -NoProfile -Command "(Get-Process).Count" > "%CKTMP%\proc.txt" 2>nul
powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_LogicalDisk -Filter 'DeviceID=''C:''').FreeSpace/1GB,1)" > "%CKTMP%\disk.txt" 2>nul

set /p CPU_BEFORE=<"%CKTMP%\cpu.txt"
set /p RAM_FREE_BEFORE=<"%CKTMP%\ram.txt"
set /p PROC_BEFORE=<"%CKTMP%\proc.txt"
set /p DISK_BEFORE_GB=<"%CKTMP%\disk.txt"
if not defined CPU_BEFORE set "CPU_BEFORE=N/A"
if not defined RAM_FREE_BEFORE set "RAM_FREE_BEFORE=N/A"
if not defined PROC_BEFORE set "PROC_BEFORE=N/A"
if not defined DISK_BEFORE_GB set "DISK_BEFORE_GB=N/A"

color 02
echo    CPU Usage:       %CPU_BEFORE%%%
echo    Free RAM:        %RAM_FREE_BEFORE% MB
echo    Process Count:   %PROC_BEFORE%
echo    C: Free Space:   %DISK_BEFORE_GB% GB
echo.

echo. >> "%LOGFILE%"
echo [PRE-OPTIMIZATION SNAPSHOT] >> "%LOGFILE%"
echo    CPU Usage:       %CPU_BEFORE%%% >> "%LOGFILE%"
echo    Free RAM:        %RAM_FREE_BEFORE% MB >> "%LOGFILE%"
echo    Process Count:   %PROC_BEFORE% >> "%LOGFILE%"
echo    C: Free Space:   %DISK_BEFORE_GB% GB >> "%LOGFILE%"

timeout /t 2 >nul
call :STEPCHK

:: ============================================================================
:: SECTION 6: SYSTEM PROTECTION + RESTORE POINT
:: ============================================================================
cls
color 0A
echo.
echo  ================================================================================
echo  SYSTEM PROTECTION + RESTORE POINT
echo  ================================================================================
echo.

echo  [ENABLING] System Protection on C: drive...
echo. >> "%LOGFILE%"
echo [SYSTEM PROTECTION] >> "%LOGFILE%"

powershell -NoProfile -Command "Enable-ComputerRestore -Drive 'C:\'" 2>>"%LOGFILE%"
if %errorlevel% equ 0 (
    color 02
    echo  [SUCCESS] System Protection enabled
    echo   Enabled successfully >> "%LOGFILE%"
) else (
    color 0E
    echo  [WARNING] May already be enabled - continuing
    echo   Already enabled or error >> "%LOGFILE%"
)
color 0A
echo.

echo  [CREATING] System restore point (limit: 1 per 24 hours by default)...
powershell -NoProfile -Command "Checkpoint-Computer -Description 'CTRLKirk_Optimizer_v10' -RestorePointType 'MODIFY_SETTINGS'" 2>>"%LOGFILE%"
if %errorlevel% equ 0 (
    color 02
    echo  [SUCCESS] Restore point created
    echo   Created successfully >> "%LOGFILE%"
) else (
    color 0E
    echo  [WARNING] Could not create restore point (24h limit?) - continuing
    echo   Failed to create >> "%LOGFILE%"
)
color 0A
echo.
timeout /t 2 >nul
call :STEPCHK

:: ============================================================================
:: SECTION 7: BACKUP (registry + DNS)
:: ============================================================================
cls
color 0A
echo.
echo  ================================================================================
echo  BACKUP - REGISTRY + DNS
echo  ================================================================================
echo.

echo  [BACKING UP] Exporting current settings to:
echo   %BACKUPDIR%
echo. >> "%LOGFILE%"
echo [BACKUP] >> "%LOGFILE%"

reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "%BACKUPDIR%\SystemProfile.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" "%BACKUPDIR%\PriorityControl.reg" /y >nul 2>&1
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion" "%BACKUPDIR%\HKCU_CurrentVersion.reg" /y >nul 2>&1
reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows" "%BACKUPDIR%\HKLM_Policies.reg" /y >nul 2>&1
reg export "HKCU\System\GameConfigStore" "%BACKUPDIR%\GameConfigStore.reg" /y >nul 2>&1
reg export "HKCU\Control Panel\Desktop" "%BACKUPDIR%\Desktop.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "%BACKUPDIR%\GraphicsDrivers.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "%BACKUPDIR%\DeviceGuard.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" "%BACKUPDIR%\Tcpip_Interfaces.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "%BACKUPDIR%\Kernel.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Control\Power" "%BACKUPDIR%\Power.reg" /y >nul 2>&1
reg export "HKCU\Control Panel\Desktop\WindowMetrics" "%BACKUPDIR%\WindowMetrics.reg" /y >nul 2>&1

:: Back up current DNS config so it can be restored
powershell -NoProfile -Command "Get-DnsClientServerAddress -AddressFamily IPv4 | Out-File '%BACKUPDIR%\DNS_Backup.txt'" 2>nul

color 02
echo  [SUCCESS] Backup complete
echo   Status: Backup created successfully >> "%LOGFILE%"
echo.
timeout /t 2 >nul
call :STEPCHK

:: ============================================================================
:: SECTION 8: DEEP SYSTEM CLEANUP (no Prefetch - deleting it HURTS performance)
:: ============================================================================
cls
color 0A
echo.
echo  ================================================================================
echo  DEEP SYSTEM CLEANUP
echo  ================================================================================
echo.
echo  [CLEANING] Removing temporary files and caches...
echo. >> "%LOGFILE%"
echo [DEEP SYSTEM CLEANUP] >> "%LOGFILE%"

echo   - Cleaning temp folders...
del /f /s /q "%TEMP%\*" 2>nul
del /f /s /q "C:\Windows\Temp\*" 2>nul

echo   - Cleaning Windows Update cache...
net stop wuauserv >nul 2>&1
del /f /s /q "C:\Windows\SoftwareDistribution\Download\*" 2>nul
net start wuauserv >nul 2>&1

echo   - Cleaning browser caches...
rd /s /q "%LocalAppData%\Google\Chrome\User Data\Default\Cache" 2>nul
rd /s /q "%LocalAppData%\Google\Chrome\User Data\Default\Code Cache" 2>nul
rd /s /q "%LocalAppData%\Microsoft\Edge\User Data\Default\Cache" 2>nul
rd /s /q "%LocalAppData%\Microsoft\Edge\User Data\Default\Code Cache" 2>nul
rd /s /q "%LocalAppData%\BraveSoftware\Brave-Browser\User Data\Default\Cache" 2>nul

echo   - Cleaning GPU shader caches (games will recompile on first run)...
rd /s /q "%LocalAppData%\NVIDIA\DXCache" 2>nul
rd /s /q "%LocalAppData%\NVIDIA\GLCache" 2>nul
rd /s /q "%LocalAppData%\AMD\DxCache" 2>nul
rd /s /q "%LocalAppData%\AMD\GLCache" 2>nul
rd /s /q "%LocalAppData%\AMD\VkCache" 2>nul
rd /s /q "%LocalAppData%\Intel\ShaderCache" 2>nul
rd /s /q "%LocalAppData%\D3DSCache" 2>nul

echo   - Clearing Windows thumbnail + icon caches...
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db" 2>nul
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\iconcache_*.db" 2>nul

echo   - Emptying Recycle Bin...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" 2>nul

echo   - Cleaning crash dumps and error reports...
del /f /s /q "C:\Windows\Minidump\*" 2>nul
del /f /s /q "%LocalAppData%\CrashDumps\*" 2>nul
del /f /s /q "%ProgramData%\Microsoft\Windows\WER\ReportArchive\*" 2>nul
del /f /s /q "%ProgramData%\Microsoft\Windows\WER\ReportQueue\*" 2>nul

echo   - Cleaning Delivery Optimization cache...
del /f /s /q "C:\Windows\SoftwareDistribution\DeliveryOptimization\*" 2>nul
rd /s /q "C:\Windows\SoftwareDistribution\DeliveryOptimization" 2>nul

color 02
echo.
echo  [DONE] System cleanup complete
echo   Status: Cleanup completed successfully >> "%LOGFILE%"
call :RPT "Temp files, caches, crash dumps and Recycle Bin cleaned"
echo.
timeout /t 2 >nul
call :STEPCHK

:: ============================================================================
:: SECTION 9: RAM CLEANUP (built into every run - huge for low-end machines)
:: ============================================================================
cls
color 0B
echo.
echo  ================================================================================
echo  MEMORY OPTIMIZATION
echo  ================================================================================
echo.
echo  [FREEING] Trimming working sets + purging standby list...
echo. >> "%LOGFILE%"
echo [MEMORY OPTIMIZATION] >> "%LOGFILE%"

call :BUILD_RAM_SCRIPT
powershell.exe -NoProfile -Command "try { & (Join-Path $env:CKTMP 'ck_ram_v2.ps1') -Mode All 2>&1 | Tee-Object -FilePath $env:LOGFILE -Append } catch { Add-Content -LiteralPath $env:LOGFILE -Value $_.Exception.Message; Write-Host $_.Exception.Message; exit 1 }"
echo   PowerShell result: %errorlevel% >> "%LOGFILE%"

color 02
echo.
echo  [DONE] Memory optimized
echo   Status: Working sets trimmed + standby list purged >> "%LOGFILE%"
call :RPT "RAM freed - apps forced to release memory + standby cache cleared"
echo.
timeout /t 2 >nul
call :STEPCHK

:: ============================================================================
:: SECTION 10: SEARCH INDEX REBUILD (AGGRESSIVE ONLY)
:: ============================================================================
if "%DO_AGGRESSIVE%"=="1" (
    cls
    color 0E
    echo.
    echo  ================================================================================
    echo  SEARCH INDEX REBUILD - AGGRESSIVE MODE
    echo  ================================================================================
    echo.
    echo  [REBUILDING] Deleting and rebuilding search index...
    echo. >> "%LOGFILE%"
    echo [SEARCH INDEX REBUILD] >> "%LOGFILE%"
    color 0A
    sc stop "WSearch" >nul 2>&1
    timeout /t 3 >nul
    rd /s /q "C:\ProgramData\Microsoft\Search\Data" 2>nul
    sc start "WSearch" >nul 2>&1
    color 02
    echo  [DONE] Search index will rebuild automatically
    echo   Status: Index rebuild initiated >> "%LOGFILE%"
    echo.
    timeout /t 2 >nul
)
call :STEPCHK

:: ============================================================================
:: SECTION 11: SYSTEM REPAIR (AGGRESSIVE ONLY)
:: ============================================================================
if "%DO_AGGRESSIVE%"=="1" (
    cls
    color 0E
    echo.
    echo  ================================================================================
    echo  SYSTEM REPAIR - AGGRESSIVE MODE
    echo  ================================================================================
    echo.
    echo  [REPAIRING] Running System File Checker...
    echo  This may take 10-30 minutes.
    echo. >> "%LOGFILE%"
    echo [SYSTEM REPAIR - SFC AND DISM] >> "%LOGFILE%"
    color 0A
    sfc /scannow
    echo.
    color 0E
    echo  [REPAIRING] Running DISM RestoreHealth...
    echo.
    color 0A
    DISM /Online /Cleanup-Image /RestoreHealth
    color 02
    echo.
    echo  [DONE] System repair complete
    echo   Status: Repair completed >> "%LOGFILE%"
    echo.
    timeout /t 2 >nul
)
call :STEPCHK

:: ============================================================================
:: SECTION 12: DISABLE NON-ESSENTIAL SERVICES (AGGRESSIVE ONLY, reversible)
:: ============================================================================
if "%DO_AGGRESSIVE%"=="1" (
    cls
    color 0E
    echo.
    echo  ================================================================================
    echo  SERVICE OPTIMIZATION - AGGRESSIVE MODE
    echo  ================================================================================
    echo.
    echo  [DISABLING] Non-essential services (reversible via UNDO menu)...
    echo. >> "%LOGFILE%"
    echo [SERVICE OPTIMIZATION] >> "%LOGFILE%"
    color 0A

    :: Log service state first so undo is accurate
    :: Xbox services only disabled if user said they don't use Xbox/Game Bar
    set "SVCLIST=SysMain Fax DiagTrack dmwappushservice MapsBroker RetailDemo WMPNetworkSvc WpcMonSvc RemoteRegistry SCardSvr SCPolicySvc TrkWks lfsvc WerSvc diagnosticshub.standardcollector.service"
    if "%USER_XBOX%"=="0" (
        set "SVCLIST=%SVCLIST% XblGameSave XboxGipSvc XblAuthManager XboxNetApiSvc XboxGameMonitoring"
        echo  [NOTE] Xbox services will be disabled (you don't use Xbox/Game Bar)
        call :RPT "Xbox services disabled - Game Bar/Xbox app social will not work"
    ) else (
        echo  [NOTE] Xbox services kept ON (you use Game Bar/Xbox features)
        call :RPT "Xbox services left running - Game Bar + friends still work"
    )
    echo Service,OriginalStartType > "%BACKUPDIR%\Services_Backup.csv"
    for %%s in (%SVCLIST%) do (
        set "SVCSTART=demand"
        for /f "tokens=4" %%t in ('sc qc %%s 2^>nul ^| findstr /i "START_TYPE"') do (
            if "%%t"=="AUTO_START" set "SVCSTART=auto"
            if "%%t"=="DEMAND_START" set "SVCSTART=demand"
            if "%%t"=="DISABLED" set "SVCSTART=disabled"
            if "%%t"=="BOOT_START" set "SVCSTART=boot"
            if "%%t"=="SYSTEM_START" set "SVCSTART=system"
        )
        echo %%s,!SVCSTART! >> "%BACKUPDIR%\Services_Backup.csv"
        sc config %%s start= disabled >nul 2>&1
        if !errorlevel! equ 0 (
            echo   - %%s disabled
            echo     %%s disabled >> "%LOGFILE%"
        )
    )

    color 02
    echo.
    echo  [DONE] Non-essential services disabled
    echo   Status: Services optimized >> "%LOGFILE%"
    echo.

    :: Deeper virtualization overhead removal (aggressive only):
    :: VBS off + hypervisor off = measurable CPU/FPS gain on weak hardware.
    :: Reversible via UNDO menu option 7.
    if "%KEEP_SEC%"=="0" (
        echo  [DISABLING] Virtualization-Based Security + hypervisor launch...
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 0 /f >nul
        bcdedit /set hypervisorlaunchtype off >nul 2>&1
        echo   Status: VBS + hypervisor launch disabled (restart required) >> "%LOGFILE%"
        call :RPT "VBS + hypervisor disabled - real CPU gain, restart needed"
    ) else (
        echo  [SKIPPED] VBS kept ON per your security preference
        echo   Status: VBS kept ON by user preference >> "%LOGFILE%"
    )
    echo.
    timeout /t 2 >nul
)
call :STEPCHK

:: ============================================================================
:: SECTION 13: NETWORK OPTIMIZATION
:: ============================================================================
cls
color 0A
echo.
echo  ================================================================================
echo  NETWORK OPTIMIZATION
echo  ================================================================================
echo.
echo  [OPTIMIZING] Applying gaming network tweaks...
echo. >> "%LOGFILE%"
echo [NETWORK OPTIMIZATION] >> "%LOGFILE%"

ipconfig /flushdns >nul 2>&1
echo   - DNS cache flushed

:: TCP global tweaks (modern Win10/11 - no chimney, it was removed years ago)
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global ecncapability=disabled >nul 2>&1
netsh int tcp set global timestamps=disabled >nul 2>&1
netsh int tcp set supplemental internet congestionprovider=cubic >nul 2>&1
echo   - TCP parameters optimized

:: Winsock + TCP/IP reset = AGGRESSIVE only (requires restart to take effect)
if "%DO_AGGRESSIVE%"=="1" (
    netsh winsock reset >nul 2>&1
    netsh int ip reset >nul 2>&1
    echo   - Winsock + TCP/IP stack reset ^(restart required^)
    echo   Winsock/IP stack reset >> "%LOGFILE%"
)

:: Set Cloudflare DNS via PowerShell (handles multi-word adapter names)
if "%SET_DNS%"=="1" (
    echo   - Setting Cloudflare DNS (1.1.1.1 / 1.0.0.1)...
    powershell -NoProfile -Command "Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ('1.1.1.1','1.0.0.1') -ErrorAction SilentlyContinue }" 2>>"%LOGFILE%"
    echo   Cloudflare DNS applied >> "%LOGFILE%"
    call :RPT "DNS set to Cloudflare (faster game/server lookups for most people)"
) else (
    echo   - DNS change skipped (you chose to keep your DNS)
    echo   DNS skipped by user preference >> "%LOGFILE%"
    call :RPT "Your DNS settings left untouched"
)

:: Disable QoS bandwidth reservation
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d 0 /f >nul

:: Disable Nagle's algorithm on active adapters (lower in-game latency)
for /f %%g in ('powershell -NoProfile -Command "(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Up'}).InterfaceGuid"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%g" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%g" /v "TCPNoDelay" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%g" /v "TcpDelAckTicks" /t REG_DWORD /d 0 /f >nul 2>&1
)
echo   - Nagle's algorithm disabled on active adapters

color 02
echo.
echo  [DONE] Network optimizations applied
echo   Status: Network tweaks completed >> "%LOGFILE%"
call :RPT "Network tuned for gaming - latency tweaks + TCP optimizations"
echo.
timeout /t 2 >nul
call :STEPCHK

:: ============================================================================
:: SECTION 14: CORE ISOLATION (Memory Integrity OFF = small FPS gain)
:: ============================================================================
cls
color 0A
echo.
echo  ================================================================================
echo  CORE ISOLATION
echo  ================================================================================
echo.
echo. >> "%LOGFILE%"
echo [CORE ISOLATION] >> "%LOGFILE%"

if "%KEEP_SEC%"=="0" (
    echo  [DISABLING] Memory Integrity (HVCI) - frees a few %% performance...
    echo  NOTE: This is a Windows security feature. Reversible via UNDO menu.
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 0 /f >nul
    color 02
    echo  [DONE] Memory Integrity disabled (restart required to take effect)
    echo   Status: HVCI disabled >> "%LOGFILE%"
    call :RPT "Memory Integrity disabled - small performance gain, restart needed"
) else (
    echo  [SKIPPED] You chose to keep Memory Integrity on (good security choice)
    echo   Status: HVCI kept ON by user preference >> "%LOGFILE%"
    call :RPT "Memory Integrity left ON - your security stays at full strength"
)
echo.
timeout /t 2 >nul
call :STEPCHK

:: ============================================================================
:: SECTION 15: PRIVACY LOCK-DOWN
:: ============================================================================
cls
color 0A
echo.
echo  ================================================================================
echo  PRIVACY LOCK-DOWN
echo  ================================================================================
echo.
echo  [SECURING] Disabling telemetry and privacy features...
echo. >> "%LOGFILE%"
echo [PRIVACY LOCK-DOWN] >> "%LOGFILE%"

:: Keep Activity History ON - required for Quick Access pinning
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 1 /f >nul

:: Disable Advertising ID
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul

:: Disable Telemetry (min level honored on all editions; Enterprise can reach 0)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul

:: Disable Feedback
reg add "HKCU\Software\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d 0 /f >nul

:: Disable Location Tracking
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f >nul

:: General Privacy Settings
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f >nul

:: Speech, Inking, Typing
reg add "HKCU\Software\Microsoft\Personalization\Settings" /v "AcceptedPrivacyPolicy" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore" /v "HarvestContacts" /t REG_DWORD /d 0 /f >nul

:: Diagnostics
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" /v "ShowedToastAtLevel" /t REG_DWORD /d 1 /f >nul

:: Disable telemetry/customer-experience scheduled tasks (safe - they only phone home)
schtasks /change /tn "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /disable >nul 2>&1
schtasks /change /tn "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /disable >nul 2>&1
schtasks /change /tn "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /disable >nul 2>&1
schtasks /change /tn "Microsoft\Windows\Application Experience\ProgramDataUpdater" /disable >nul 2>&1
schtasks /change /tn "Microsoft\Windows\Autochk\Proxy" /disable >nul 2>&1
schtasks /change /tn "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /disable >nul 2>&1

color 02
echo.
echo  [DONE] Privacy features locked down (incl. telemetry scheduled tasks)
echo   Status: Privacy lock-down completed >> "%LOGFILE%"
call :RPT "Telemetry, ad tracking, and background phone-home tasks shut off"
echo.
timeout /t 2 >nul
call :STEPCHK

:: ============================================================================
:: SECTION 16: WINDOWS SETTINGS OPTIMIZATION
:: ============================================================================
cls
color 0A
echo.
echo  ================================================================================
echo  WINDOWS SETTINGS OPTIMIZATION
echo  ================================================================================
echo.
echo  [CONFIGURING] Windows settings for performance...
echo. >> "%LOGFILE%"
echo [WINDOWS SETTINGS OPTIMIZATION] >> "%LOGFILE%"

:: Disable Notifications (only if user didn't keep them)
if "%KEEP_NOTIFY%"=="0" (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d 0 /f >nul
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" /t REG_DWORD /d 0 /f >nul
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" /t REG_DWORD /d 0 /f >nul
    echo   Notifications disabled >> "%LOGFILE%"
    call :RPT "Notifications disabled - quieter + fewer interruptions"
) else (
    echo   Notifications kept by user preference >> "%LOGFILE%"
    call :RPT "Notifications kept ON as you chose"
)

:: Disable Transparency + Animations (only if user didn't keep visuals)
if "%KEEP_VISUALS%"=="0" (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f >nul
    reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f >nul
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f >nul
    echo   Transparency/animations disabled >> "%LOGFILE%"
) else (
    echo   Visuals kept by user preference >> "%LOGFILE%"
)

:: Windows Update - notify before download (2), no forced restarts mid-game
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "AllowAutoWindowsUpdateDownloadOverMeteredNetwork" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /t REG_DWORD /d 1 /f >nul

:: Disable Delivery Optimization P2P
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization" /v "SystemSettingsDownloadMode" /t REG_DWORD /d 0 /f >nul

:: Disable background app permission (frees RAM/CPU on low-end machines)
if "%KEEP_BGAPPS%"=="0" (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f >nul
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d 0 /f >nul
    echo   Background apps disabled >> "%LOGFILE%"
    call :RPT "Background Store apps blocked - they can no longer eat RAM/CPU while gaming"
) else (
    echo   Background apps kept by user preference >> "%LOGFILE%"
)

:: Disable Game DVR captures + background recording (real FPS win on weak GPUs)
:: NOTE: Game Bar overlay, party chat, and Xbox friends still work - only
:: the background DVR capture/recording is disabled. Press Win+G as usual.
if "%KEEP_GAMEDVR%"=="0" (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul
    reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f >nul
    echo   Game DVR disabled >> "%LOGFILE%"
    call :RPT "Game DVR background recording off - Game Bar itself still works (Win+G)"
) else (
    echo   Game DVR kept by user preference >> "%LOGFILE%"
)

:: Disable Widgets + News & Interests feed (frees RAM + network polling)
if "%KEEP_WIDGETS%"=="0" (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f >nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f >nul
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d 2 /f >nul
    echo   Widgets/news feed disabled >> "%LOGFILE%"
    call :RPT "Widgets + News feed disabled - less RAM and network polling"
) else (
    echo   Widgets kept by user preference >> "%LOGFILE%"
)

:: Disable Edge startup boost + background mode (silent RAM hog)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "StartupBoostEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "BackgroundModeEnabled" /t REG_DWORD /d 0 /f >nul

:: Enable Storage Sense so Windows auto-cleans temp files on low disk
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" /v "AllowStorageSenseGlobal" /t REG_DWORD /d 1 /f >nul

:: UI responsiveness: instant menus, no startup delay, fast app-kill on shutdown
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f >nul
reg add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "1000" /f >nul
reg add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "2000" /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "2000" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d 0 /f >nul

:: Kill Bing search inside Start menu (frees CPU + network polling)
if "%KEEP_BING%"=="0" (
    reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f >nul
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f >nul
    echo   Bing search-in-Start disabled >> "%LOGFILE%"
) else (
    echo   Bing search-in-Start kept by user preference >> "%LOGFILE%"
)

:: Disable Cortana (dead weight on Win10)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul

:: Disable CPU power throttling (laptops throttle to save battery - kills FPS)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d 1 /f >nul

:: Allow per-app timer resolution requests (helps frame pacing, Win11 24H2+)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "GlobalTimerResolutionRequests" /t REG_DWORD /d 1 /f >nul

:: USB selective suspend OFF while plugged in (stops mouse/headset lag spikes)
powercfg /setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
powercfg /setactive scheme_current >nul 2>&1

:: NTFS: stop tracking last-access timestamps (small but free disk win)
fsutil behavior set disablelastaccess 1 >nul 2>&1

:: Power plan: try Ultimate Performance, fall back to High performance
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
if !errorlevel! neq 0 powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
:: Never sleep/dim while plugged in, disable hibernation file (frees disk)
powercfg /change standby-timeout-ac 0 >nul 2>&1
powercfg /change monitor-timeout-ac 20 >nul 2>&1
powercfg /h off >nul 2>&1

color 02
echo  [DONE] Windows settings optimized
echo   Status: Settings configured >> "%LOGFILE%"
echo.
timeout /t 2 >nul
call :STEPCHK

:: ============================================================================
:: SECTION 17: VISUAL EFFECTS OPTIMIZATION
:: ============================================================================
cls
color 0A
echo.
echo  ================================================================================
echo  VISUAL EFFECTS OPTIMIZATION
echo  ================================================================================
echo.
echo  [CONFIGURING] Best performance with select features kept...
echo. >> "%LOGFILE%"
echo [VISUAL EFFECTS OPTIMIZATION] >> "%LOGFILE%"

if "%KEEP_VISUALS%"=="0" (
    :: Custom = best performance base, but keep font smoothing + show thumbnails
    :: (you still SEE icons/thumbnails - only the fancy effects are removed)
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 2 /f >nul
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t REG_DWORD /d 0 /f >nul
    reg add "HKCU\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d "1" /f >nul
    reg add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d "2" /f >nul
    reg add "HKCU\Control Panel\Desktop" /v "FontSmoothingType" /t REG_DWORD /d 2 /f >nul
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewAlphaSelect" /t REG_DWORD /d 0 /f >nul
    color 02
    echo  [DONE] Visual effects optimized (thumbnails + font smoothing kept)
    echo   Status: Visual effects configured >> "%LOGFILE%"
    call :RPT "Visual effects minimized - you still see icons/thumbnails, just no fancy animations"
) else (
    color 0A
    echo  [SKIPPED] You chose to keep visual effects on
    echo   Status: Skipped by user preference >> "%LOGFILE%"
    call :RPT "Visual effects left ON as you chose"
)
echo.
timeout /t 2 >nul
call :STEPCHK

:: ============================================================================
:: SECTION 18: SSD OPTIMIZATION
:: ============================================================================
cls
color 0A
echo.
echo  ================================================================================
echo  SSD OPTIMIZATION
echo  ================================================================================
echo.
echo  [CHECKING] Verifying TRIM is enabled...
echo. >> "%LOGFILE%"
echo [SSD OPTIMIZATION] >> "%LOGFILE%"

powershell -NoProfile -Command "if ((Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name DisableDeleteNotify -ErrorAction SilentlyContinue).DisableDeleteNotify -ne 0) { exit 1 } else { exit 0 }" >nul 2>&1
fsutil behavior query DisableDeleteNotify > "%CKTMP%\trim.txt" 2>&1
findstr /c:"= 0" "%CKTMP%\trim.txt" >nul
if %errorlevel% equ 0 (
    color 02
    echo    [OK] TRIM is enabled
    echo    Status: TRIM enabled >> "%LOGFILE%"
) else (
    color 0E
    echo    [WARNING] TRIM appears disabled - enabling...
    fsutil behavior set DisableDeleteNotify 0 >nul 2>&1
    color 02
    echo    [OK] TRIM has been enabled
    echo    Status: TRIM enabled >> "%LOGFILE%"
)

echo   - Queuing SSD retrim...
defrag C: /L /U >nul 2>&1

color 0A
echo.
timeout /t 2 >nul
call :STEPCHK

:: ============================================================================
:: SECTION 19: GAMING REGISTRY OPTIMIZATIONS
:: ============================================================================
cls
color 0A
echo.
echo  ================================================================================
echo  GAMING REGISTRY OPTIMIZATIONS
echo  ================================================================================
echo.
echo  [OPTIMIZING] Applying gaming registry tweaks...
echo. >> "%LOGFILE%"
echo [GAMING REGISTRY OPTIMIZATIONS] >> "%LOGFILE%"

:: Game Mode ON
reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f >nul

:: Optimizations for windowed games (Win11 feature, harmless on Win10)
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 2 /f >nul
reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 1 /f >nul

:: Hardware GPU Scheduling ON (requires restart)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f >nul

:: Give GPU driver 10s before Windows resets it (stops "driver crashed" on weak GPUs)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "TdrDelay" /t REG_DWORD /d 10 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "TdrDdiDelay" /t REG_DWORD /d 10 /f >nul

:: Win32PrioritySeparation - 0x26 = short variable quantums, foreground boost
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul

:: System Responsiveness 0 = reserve nothing for background while gaming
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f >nul

:: Network Throttling Index disabled
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 4294967295 /f >nul

:: Games task profile tuning
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul

:: Disable fullscreen optimizations compat helper popups
reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d 1 /f >nul

color 02
echo.
echo  [DONE] Gaming optimizations applied
echo   Status: Registry tweaks completed >> "%LOGFILE%"
call :RPT "Game Mode, GPU scheduling, priority tweaks applied - games get first dibs on resources"
echo.
timeout /t 2 >nul
call :STEPCHK

:: ============================================================================
:: SECTION 20: GPU DETECTION + OPTIMIZATION (CIM, not wmic)
:: ============================================================================
cls
color 0A
echo.
echo  ================================================================================
echo  GPU OPTIMIZATION
echo  ================================================================================
echo.
echo. >> "%LOGFILE%"
echo [GPU OPTIMIZATION] >> "%LOGFILE%"

powershell -NoProfile -Command "(Get-CimInstance Win32_VideoController).Name -join ';'" > "%CKTMP%\gpu.txt" 2>nul
set /p GPU_NAMES=<"%CKTMP%\gpu.txt"
echo  Detected GPUs: %GPU_NAMES%
echo   GPUs: %GPU_NAMES% >> "%LOGFILE%"
echo.

findstr /i "nvidia" "%CKTMP%\gpu.txt" >nul
if !errorlevel! equ 0 (
    echo  [DETECTED] NVIDIA GPU found - applying tweaks
    echo   NVIDIA detected >> "%LOGFILE%"
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "PowerMizerEnable" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "PowerMizerLevel" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "PerfLevelSrc" /t REG_DWORD /d 8738 /f >nul 2>&1
)

findstr /i "amd radeon" "%CKTMP%\gpu.txt" >nul
if !errorlevel! equ 0 (
    echo  [DETECTED] AMD GPU found - applying tweaks
    echo   AMD detected >> "%LOGFILE%"
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "KMD_DeLagEnabled" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "EnableUlps" /t REG_DWORD /d 0 /f >nul 2>&1
)

findstr /i "intel" "%CKTMP%\gpu.txt" >nul
if !errorlevel! equ 0 (
    echo  [DETECTED] Intel GPU found - applying tweaks
    echo   Intel detected >> "%LOGFILE%"
    :: Dedicated video memory reporting helps some older games on iGPU
    reg add "HKLM\SOFTWARE\Intel\GMM" /v "DedicatedSegmentSize" /t REG_DWORD /d 512 /f >nul 2>&1
)

findstr /i "nvidia amd radeon intel" "%CKTMP%\gpu.txt" >nul
if !errorlevel! neq 0 (
    echo  [NOT DETECTED] No known GPU vendor found - skipping
    echo   No GPU vendor detected >> "%LOGFILE%"
)

color 02
echo  [DONE] GPU optimization complete
call :RPT "GPU-specific tweaks applied: %GPU_NAMES%"
echo.
timeout /t 2 >nul
call :STEPCHK

:: ============================================================================
:: SECTION 21: POST-OPTIMIZATION SNAPSHOT
:: ============================================================================
cls
color 02
echo.
echo  ================================================================================
echo  OPTIMIZATION COMPLETE
echo  ================================================================================
echo.
color 0A

powershell -NoProfile -Command "(Get-CimInstance Win32_Processor).LoadPercentage" > "%CKTMP%\cpu.txt" 2>nul
powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)" > "%CKTMP%\ram.txt" 2>nul
powershell -NoProfile -Command "(Get-Process).Count" > "%CKTMP%\proc.txt" 2>nul
set /p CPU_AFTER=<"%CKTMP%\cpu.txt"
set /p RAM_FREE_AFTER=<"%CKTMP%\ram.txt"
set /p PROC_AFTER=<"%CKTMP%\proc.txt"
if not defined CPU_AFTER set "CPU_AFTER=N/A"
if not defined RAM_FREE_AFTER set "RAM_FREE_AFTER=N/A"
if not defined PROC_AFTER set "PROC_AFTER=N/A"

echo  System State (Before -^> After):
echo     - CPU Usage:      %CPU_BEFORE%%% -^> %CPU_AFTER%%%
echo     - Free RAM:       %RAM_FREE_BEFORE% MB -^> %RAM_FREE_AFTER% MB
echo     - Process Count:  %PROC_BEFORE% -^> %PROC_AFTER%
echo.
echo  Your report:     %REPORT%
echo  Dev log:         %LOGFILE%
echo  Backup saved to: %BACKUPDIR%
echo.

:: ---- Friendly user report: before/after + wrap-up ----
echo. >> "%REPORT%"
echo  ------------------------------------------------------------------------------ >> "%REPORT%"
echo  YOUR SYSTEM: BEFORE -^> AFTER >> "%REPORT%"
echo. >> "%REPORT%"
echo   CPU Usage:      %CPU_BEFORE%%% -^> %CPU_AFTER%%% >> "%REPORT%"
echo   Free RAM:       %RAM_FREE_BEFORE% MB -^> %RAM_FREE_AFTER% MB >> "%REPORT%"
echo   Processes:      %PROC_BEFORE% -^> %PROC_AFTER% >> "%REPORT%"
echo. >> "%REPORT%"
echo  ------------------------------------------------------------------------------ >> "%REPORT%"
echo  WHAT'S DIFFERENT NOW: >> "%REPORT%"
echo   - Less stuff running in the background stealing your CPU and RAM >> "%REPORT%"
echo   - Games get priority over background apps >> "%REPORT%"
echo   - A safety net exists: restore point + full registry backup in: >> "%REPORT%"
echo     %BACKUPDIR% >> "%REPORT%"
echo   - Changed your mind? Run this tool again and pick [5] UNDO / RESTORE >> "%REPORT%"
echo     to put everything back exactly how it was. >> "%REPORT%"
echo. >> "%REPORT%"
echo  TIP: Some changes need a restart to fully apply (GPU scheduling, >> "%REPORT%"
echo  security features, services). Restart when convenient. >> "%REPORT%"
echo ============================================================================ >> "%REPORT%"
echo  Made with love by CTRLKirk - subscribe for more tools! >> "%REPORT%"
echo ============================================================================ >> "%REPORT%"

echo. >> "%LOGFILE%"
echo [POST-OPTIMIZATION SUMMARY] >> "%LOGFILE%"
echo    CPU Usage:       %CPU_BEFORE%%% -^> %CPU_AFTER%%% >> "%LOGFILE%"
echo    Free RAM:        %RAM_FREE_BEFORE% MB -^> %RAM_FREE_AFTER% MB >> "%LOGFILE%"
echo    Process Count:   %PROC_BEFORE% -^> %PROC_AFTER% >> "%LOGFILE%"
echo. >> "%LOGFILE%"
echo ============================================================================ >> "%LOGFILE%"
echo END OF LOG - CTRLKIRK OPTIMIZER v10.0 >> "%LOGFILE%"
echo ============================================================================ >> "%LOGFILE%"

timeout /t 4 >nul
goto REST_POINT

:: ============================================================================
:: FINAL RESTART PROMPT - explicit R/1 only, no accidental reboots
:: ============================================================================
:REST_POINT
cls
color 0A
echo.
echo  ================================================================================
echo  OPTIMIZATION COMPLETE!
echo  ================================================================================
echo.
echo  Your system has been optimized for peak gaming performance.
echo.
color 0E
echo  Like the tool? Subscribe to CTRLKirk for more!
echo.
color 0C
echo  A RESTART IS RECOMMENDED TO APPLY ALL CHANGES.
echo.
color 0A
echo  [R] RESTART PC NOW (in 60 seconds - time to save work)
echo  [0] EXIT TO DESKTOP
echo.
set /p FINAL="  Choose an option: "

if /i "%FINAL%"=="R" goto DO_RESTART
if "%FINAL%"=="1" goto DO_RESTART
if "%FINAL%"=="0" exit
goto REST_POINT

:DO_RESTART
shutdown /r /t 60 /c "CTRLKirk Optimizer: Restarting in 60s to apply tweaks. Run 'shutdown /a' to abort."
echo.
echo  Restart scheduled in 60 seconds. Type "shutdown /a" in a command prompt to cancel.
echo.
pause
exit

:: ============================================================================
:: RAM & MEMORY TOOLS MENU
:: ============================================================================
:RAM_MENU
cls
color 0B
echo.
echo  ================================================================================
echo  RAM ^& MEMORY TOOLS
echo  ================================================================================
echo.
echo   [1] Show top RAM-eating processes
echo   [2] Clear cached RAM - manual troubleshooting, may slow reloads
echo   [3] Trim all process working sets (forces apps to release RAM)
echo   [4] Full memory cleanup ^(2 + 3^)
echo   [5] Set a game/process to HIGH priority
echo   [6] Restart Explorer (frees shell RAM, fixes glitches)
echo   [7] List startup apps (see what launches at boot)
echo   [8] Inspect memory compression - read-only
echo   [0] Back to Main Menu
echo.
choice /c 123456780 /n /m "Select tool: "
if errorlevel 255 exit /b 1
set "RAMCH=!errorlevel!"
if "!RAMCH!"=="9" set "RAMCH=0"
echo RAM menu option !RAMCH! at %date% %time% >> "%LOGFILE%"

if "%RAMCH%"=="0" goto MENU
if "%RAMCH%"=="1" goto RAM_TOP
if "%RAMCH%"=="2" goto RAM_STANDBY
if "%RAMCH%"=="3" goto RAM_TRIM
if "%RAMCH%"=="4" goto RAM_FULL
if "%RAMCH%"=="5" goto RAM_PRIORITY
if "%RAMCH%"=="6" goto RAM_EXPLORER
if "%RAMCH%"=="7" goto RAM_STARTUP
if "%RAMCH%"=="8" goto RAM_MEMCOMPRESS
goto RAM_MENU

:RAM_TOP
cls
echo.
echo  TOP 15 MEMORY CONSUMERS:
echo  ================================================================================
powershell -NoProfile -Command "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 Name, Id, @{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB)}}, @{N='CPU_s';E={[math]::Round($_.CPU,1)}} | Format-Table -AutoSize"
pause
goto RAM_MENU

:RAM_STANDBY
call :SAFE_RAM_CONSENT
if errorlevel 1 goto RAM_MENU
cls
call :BUILD_RAM_SCRIPT
echo.
echo  Purging standby memory list (frees cached RAM)...
powershell.exe -NoProfile -Command "try { & (Join-Path $env:CKTMP 'ck_ram_v2.ps1') -Mode Standby 2>&1 | Tee-Object -FilePath $env:LOGFILE -Append } catch { Add-Content -LiteralPath $env:LOGFILE -Value $_.Exception.Message; Write-Host $_.Exception.Message; exit 1 }"
echo.
pause
goto RAM_MENU

:RAM_TRIM
call :SAFE_RAM_CONSENT
if errorlevel 1 goto RAM_MENU
cls
call :BUILD_RAM_SCRIPT
echo.
echo  Trimming working sets on all processes...
powershell.exe -NoProfile -Command "try { & (Join-Path $env:CKTMP 'ck_ram_v2.ps1') -Mode Trim 2>&1 | Tee-Object -FilePath $env:LOGFILE -Append } catch { Add-Content -LiteralPath $env:LOGFILE -Value $_.Exception.Message; Write-Host $_.Exception.Message; exit 1 }"
echo.
pause
goto RAM_MENU

:RAM_FULL
call :SAFE_RAM_CONSENT
if errorlevel 1 goto RAM_MENU
cls
call :BUILD_RAM_SCRIPT
echo.
echo  Full memory cleanup: working sets + standby + modified list...
powershell.exe -NoProfile -Command "try { & (Join-Path $env:CKTMP 'ck_ram_v2.ps1') -Mode All 2>&1 | Tee-Object -FilePath $env:LOGFILE -Append } catch { Add-Content -LiteralPath $env:LOGFILE -Value $_.Exception.Message; Write-Host $_.Exception.Message; exit 1 }"
echo.
pause
goto RAM_MENU

:RAM_PRIORITY
cls
echo.
echo  SET GAME/PROCESS TO HIGH PRIORITY
echo  ================================================================================
echo.
powershell -NoProfile -Command "Get-Process | Where-Object {$_.MainWindowTitle -ne ''} | Sort-Object WorkingSet64 -Descending | Select-Object -First 20 Name, @{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB)}} | Format-Table -AutoSize"
echo.
echo High priority can make other apps less responsive. Restart the app to reset it.
powershell.exe -NoProfile -Command "$name = Read-Host 'Exact process name, no .exe; Enter cancels'; if ([string]::IsNullOrWhiteSpace($name)) { exit }; try { $p = @(Get-Process -ErrorAction Stop | Where-Object ProcessName -EQ $name); if (-not $p.Count) { throw 'No exact process match found' }; foreach ($item in $p) { $item.PriorityClass = 'High' }; Write-Host 'Priority changed. Restart the app to reset it.'; Add-Content -LiteralPath $env:LOGFILE -Value 'Manual priority change succeeded' } catch { Write-Host $_.Exception.Message; Add-Content -LiteralPath $env:LOGFILE -Value $_.Exception.Message; exit 1 }"
echo.
echo  NOTE: Priority resets when the process restarts.
echo  TIP: For permanent per-game priority, use the game's own launch options
echo       or Process Lasso (free) instead.
echo.
pause
goto RAM_MENU

:RAM_EXPLORER
cls
echo.
echo Restarting Explorer closes folder windows and can interrupt file operations.
choice /c NY /n /m "Continue? N cancels, Y restarts Explorer: "
if errorlevel 2 goto SAFE_EXPLORER_CONFIRMED
goto RAM_MENU
:SAFE_EXPLORER_CONFIRMED
echo Explorer restart requested %date% %time% >> "%LOGFILE%"
echo  Restarting Windows Explorer (taskbar will flash)...
taskkill /F /IM explorer.exe >> "%LOGFILE%" 2>&1
timeout /t 2 >nul
start explorer.exe
echo  Explorer restarted.
pause
goto RAM_MENU

:RAM_STARTUP
cls
echo.
echo  STARTUP APPS (launch at every boot):
echo  ================================================================================
powershell -NoProfile -Command "Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location | Format-Table -AutoSize -Wrap"
echo.
echo  Disable unwanted ones in Task Manager -^> Startup tab (Ctrl+Shift+Esc).
pause
goto RAM_MENU

:RAM_MEMCOMPRESS
echo Memory compression is left unchanged. Disabling it can increase paging and make performance worse.
powershell.exe -NoProfile -Command "try { Get-MMAgent -ErrorAction Stop | Select-Object MemoryCompression | Format-List } catch { Write-Host $_.Exception.Message }"
echo This is read-only until a supported snapshot and restore path is implemented.
pause
goto RAM_MENU
cls
echo.
echo  MEMORY COMPRESSION TOGGLE
echo  ================================================================================
echo.
echo  ON  (default): Windows compresses unused RAM - uses less RAM, costs CPU.
echo  OFF (fast CPU, enough RAM): saves CPU cycles, but Windows pages to disk more.
echo.
echo  Rule of thumb: weak CPU + 8GB+ RAM = turn OFF.  Little RAM (4-6GB) = leave ON.
echo.
powershell -NoProfile -Command "$mc = Get-MMAgent; Write-Output ('Memory compression is currently: ' + $(if($mc.MemoryCompression){'ON'}else{'OFF'}))"
echo.
set /p MC="  Turn compression OFF? (Y/N, 0 to cancel): "
if /i "%MC%"=="Y" (
    powershell -NoProfile -Command "Disable-MMAgent -MemoryCompression"
    echo  Memory compression OFF. Restart required.
)
if /i "%MC%"=="N" (
    powershell -NoProfile -Command "Enable-MMAgent -MemoryCompression"
    echo  Memory compression ON. Restart required.
)
pause
goto RAM_MENU

:: ============================================================================
:: UNDO / RESTORE MENU
:: ============================================================================
:UNDO_MENU
goto SAFE_RESTORE
cls
color 0E
echo.
echo  ================================================================================
echo  UNDO / RESTORE - REVERT CHANGES
echo  ================================================================================
echo.
echo   [1] Restore latest registry backup (revert all registry tweaks)
echo   [2] Choose a specific backup folder to restore
echo   [3] Reset DNS back to automatic (DHCP)
echo   [4] Re-enable all disabled services
echo   [5] Re-enable Memory Integrity (HVCI security feature)
echo   [6] Restore Windows default visual effects + notifications
echo   [7] Re-enable Virtualization Security + Hypervisor (VBS)
echo   [0] Back to Main Menu
echo.
set /p UNDO="  Select undo option: "

if "%UNDO%"=="0" goto MENU
if "%UNDO%"=="1" goto UNDO_LATEST
if "%UNDO%"=="2" goto UNDO_PICK
if "%UNDO%"=="3" goto UNDO_DNS
if "%UNDO%"=="4" goto UNDO_SVC
if "%UNDO%"=="5" goto UNDO_HVCI
if "%UNDO%"=="6" goto UNDO_VISUAL
if "%UNDO%"=="7" goto UNDO_VBS
goto UNDO_MENU

:UNDO_LATEST
cls
echo  [RESTORING] Finding most recent backup...
set "LATESTBACKUP="
for /f "delims=" %%d in ('dir /b /ad /o-n "%~dp0Backups\Backup_*" 2^>nul') do (
    if not defined LATESTBACKUP set "LATESTBACKUP=%%d"
)
if not defined LATESTBACKUP (
    echo  No backups found!
    pause
    goto UNDO_MENU
)
echo  Restoring: %LATESTBACKUP%
call :IMPORT_BACKUP "%~dp0Backups\%LATESTBACKUP%"
call :REVERT_EXTRAS
pause
goto UNDO_MENU

:UNDO_PICK
cls
echo  Available backups:
echo  ================================================================================
dir /b /ad /o-n "%~dp0Backups\Backup_*" 2>nul
echo.
set /p PICKDIR="  Type the backup folder name exactly (or 0 to cancel): "
if "%PICKDIR%"=="0" goto UNDO_MENU
if not exist "%~dp0Backups\%PICKDIR%" (
    echo  Folder not found.
    pause
    goto UNDO_MENU
)
call :IMPORT_BACKUP "%~dp0Backups\%PICKDIR%"
call :REVERT_EXTRAS
pause
goto UNDO_MENU

:UNDO_DNS
cls
echo  [RESETTING] DNS back to automatic (DHCP)...
powershell -NoProfile -Command "Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses -ErrorAction SilentlyContinue }"
ipconfig /flushdns >nul 2>&1
echo  DNS reset to automatic.
pause
goto UNDO_MENU

:UNDO_SVC
cls
echo  [RESTORING] Re-enabling services to defaults...
:: Restore from backup CSV if present, otherwise use Windows defaults
set "SVCRESTORED=0"
for /f "delims=" %%d in ('dir /b /ad /o-n "%~dp0Backups\Backup_*" 2^>nul') do (
    if !SVCRESTORED!==0 if exist "%~dp0Backups\%%d\Services_Backup.csv" (
        echo  Restoring from %~dp0Backups\%%d\Services_Backup.csv
        for /f "skip=1 tokens=1,2 delims=," %%a in ('type "%~dp0Backups\%%d\Services_Backup.csv"') do (
            if "%%b"=="auto" sc config %%a start= auto >nul 2>&1
            if "%%b"=="demand" sc config %%a start= demand >nul 2>&1
            if "%%b"=="boot" sc config %%a start= boot >nul 2>&1
            if "%%b"=="system" sc config %%a start= system >nul 2>&1
            echo   - %%a restored to %%b
        )
        set "SVCRESTORED=1"
    )
)
if !SVCRESTORED!==0 (
    echo  No service backup found - applying Windows defaults...
    sc config SysMain start= auto >nul 2>&1
    sc config DiagTrack start= auto >nul 2>&1
    sc config Fax start= demand >nul 2>&1
    sc config dmwappushservice start= demand >nul 2>&1
    sc config MapsBroker start= delayed-auto >nul 2>&1
    sc config RetailDemo start= demand >nul 2>&1
    sc config WMPNetworkSvc start= demand >nul 2>&1
    sc config WpcMonSvc start= demand >nul 2>&1
    sc config RemoteRegistry start= demand >nul 2>&1
    sc config SCardSvr start= demand >nul 2>&1
    sc config SCPolicySvc start= demand >nul 2>&1
    sc config TrkWks start= demand >nul 2>&1
    sc config lfsvc start= demand >nul 2>&1
    sc config WerSvc start= demand >nul 2>&1
    sc config diagnosticshub.standardcollector.service start= demand >nul 2>&1
    echo  Defaults applied.
)
pause
goto UNDO_MENU

:UNDO_HVCI
cls
echo  [RE-ENABLING] Memory Integrity (HVCI)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 1 /f >nul
echo  Memory Integrity re-enabled. Restart required.
pause
goto UNDO_MENU

:UNDO_VISUAL
cls
echo  [RESTORING] Windows default visuals...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "1" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 1 /f >nul
echo  Defaults restored. Sign out/in or restart to fully apply.
pause
goto UNDO_MENU

:UNDO_VBS
cls
echo  [RE-ENABLING] Virtualization-Based Security + Hypervisor launch...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 1 /f >nul
bcdedit /set hypervisorlaunchtype auto >nul 2>&1
echo  VBS + hypervisor re-enabled. Restart required.
pause
goto UNDO_MENU

:: ============================================================================
:: HELPER: import a whole backup folder of .reg files
:: ============================================================================
:IMPORT_BACKUP
echo  Importing registry files from: %~1
for %%f in ("%~1\*.reg") do (
    echo   - %%~nxf
    reg import "%%f" >nul 2>&1
)
echo  Registry restore complete. Restart recommended.
goto :eof

:: ============================================================================
:: HELPER: removes keys/values the optimizer CREATED (they wouldn't exist in
:: the backup, so importing alone can't remove them). This is what makes the
:: revert a true "back to how it was".
:: ============================================================================
:REVERT_EXTRAS
echo.
echo  [REVERTING] Removing optimizer-created policy keys...
:: Whole keys we created - delete entirely
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /f >nul 2>&1
:: Values we added inside pre-existing keys - delete just the value
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "GlobalTimerResolutionRequests" /f >nul 2>&1
:: Restore default service shutdown timeout (we set 2000, default is 5000)
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "5000" /f >nul 2>&1
:: Re-enable the telemetry scheduled tasks we disabled
schtasks /change /tn "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /enable >nul 2>&1
schtasks /change /tn "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /enable >nul 2>&1
schtasks /change /tn "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /enable >nul 2>&1
schtasks /change /tn "Microsoft\Windows\Application Experience\ProgramDataUpdater" /enable >nul 2>&1
schtasks /change /tn "Microsoft\Windows\Autochk\Proxy" /enable >nul 2>&1
schtasks /change /tn "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /enable >nul 2>&1
echo  [DONE] Optimizer-created keys removed. Restart recommended.
echo   NOTE: power plan and memory compression (if toggled) reset via their menus.
goto :eof

:: ============================================================================
:: HELPER: step-through pause (dev mode only)
:: ============================================================================
:: ============================================================================
:: HELPER: append a friendly line to the user report
:: ============================================================================
:RPT
echo   %~1 >> "%REPORT%"
goto :eof

:STEPCHK
if "%DO_STEP%"=="1" (
    color 0E
    echo.
    echo  [STEP MODE] Section complete. Press any key for next section...
    pause >nul
    color 0A
)
goto :eof

:: ============================================================================
:: HELPER: build the PowerShell RAM script (EmptyWorkingSet + standby purge)
:: ============================================================================
:BUILD_RAM_SCRIPT
if exist "%CKTMP%\ck_ram_v2.ps1" goto :eof
(
echo param^([string]$Mode = 'All'^)
echo $ErrorActionPreference = 'Stop'
echo $src = @'
echo using System;
echo using System.Runtime.InteropServices;
echo public class CKMem {
echo     [DllImport^("ntdll.dll"^)]
echo     public static extern int NtSetSystemInformation^(int cls, IntPtr info, int len^);
echo     [DllImport^("psapi.dll"^)]
echo     public static extern bool EmptyWorkingSet^(IntPtr h^);
echo     public static int MemCmd^(int cmd^) {
echo         IntPtr p = Marshal.AllocHGlobal^(4^);
echo         Marshal.WriteInt32^(p, cmd^);
echo         int r = NtSetSystemInformation^(80, p, 4^);
echo         Marshal.FreeHGlobal^(p^);
echo         return r;
echo     }
echo }
echo '@
echo Add-Type -TypeDefinition $src -Language CSharp
echo.
echo if ^($Mode -eq 'Trim' -or $Mode -eq 'All'^) {
echo     $trimmed = 0
echo     foreach ^($p in Get-Process^) {
echo         if ^($p.Id -gt 4^) {
echo             try { if ^([CKMem]::EmptyWorkingSet^($p.Handle^)^) { $trimmed++ } } catch {}
echo         }
echo     }
echo     Write-Output "Asked $trimmed apps to release memory they can reload later. Apps may briefly slow down while reloading it."
echo }
echo.
echo if ^($Mode -eq 'Standby' -or $Mode -eq 'All'^) {
echo     $r1 = [CKMem]::MemCmd^(3^)
echo     $r2 = [CKMem]::MemCmd^(4^)
echo     $r3 = [CKMem]::MemCmd^(5^)
echo     $h1 = '{0:X8}' -f $r1
echo     $h2 = '{0:X8}' -f $r2
echo     $h3 = '{0:X8}' -f $r3
echo     Add-Content -LiteralPath $env:LOGFILE -Value "RAM result codes: modified=$h1 standby=$h2 lowPriority=$h3"
echo     if ^($r1 -eq 0^) { Write-Output "Windows accepted the request to write pending memory data to disk." } else { Write-Output "Windows did not allow the pending-data flush. That step was not completed." }
echo     if ^($r2 -eq 0^) { Write-Output "Cached file data was cleared from spare RAM. Windows will rebuild this cache as needed." } else { Write-Output "Windows did not allow clearing cached RAM. That step was not completed; technical details are in the log." }
echo     if ^($r3 -ne 0^) { Write-Output "The extra low-priority cache cleanup was not completed." }
echo }
echo.
echo $os = Get-CimInstance Win32_OperatingSystem
echo $freeMB = [math]::Round^($os.FreePhysicalMemory/1024^)
echo $totalMB = [math]::Round^($os.TotalVisibleMemorySize/1024^)
echo Write-Output "Free RAM now: $freeMB MB / $totalMB MB total"
) > "%CKTMP%\ck_ram_v2.ps1"
goto :eof

:: ============================================================================
:: DEVELOPER TOOLS MENU
:: ============================================================================
:DEV_MENU
goto SAFE_DIAGNOSTICS
cls
color 0E
echo.
echo  ================================================================================
echo  DEVELOPER TOOLS - READ CAREFULLY
echo  ================================================================================
echo.
echo   [A] Step-Through Mode (pauses after every section, then runs Aggressive)
echo   [B] Registry Junk Cleanup (MRU lists, recent docs, run history)
echo   [C] Network Stress Test (50x Loop)
echo   [D] Add Defender exclusion for a game folder (careful!)
echo   [L] Open latest optimizer log
echo   [R] Create Manual Restore Point
echo   [0] Back to Main Menu
echo.
set /p DEV_CHOICE="  Select tool: "

if "%DEV_CHOICE%"=="0" goto MENU
if /i "%DEV_CHOICE%"=="A" (
    set "DO_STEP=1"
    set "DO_STANDARD=1"
    set "DO_AGGRESSIVE=1"
    set "DO_AUTO=0"
    set "MODETEXT=DEV-STEP"
    echo.
    echo  DEV STEP-THROUGH MODE: Aggressive run, pauses after every section.
    echo  You will still get the preference questions first.
    pause
    goto PREFERENCES
)
if /i "%DEV_CHOICE%"=="B" goto DEV_REGCLEAN
if /i "%DEV_CHOICE%"=="C" goto STRESS_TEST
if /i "%DEV_CHOICE%"=="D" goto DEV_EXCLUDE
if /i "%DEV_CHOICE%"=="L" goto DEV_LOG
if /i "%DEV_CHOICE%"=="R" goto DEV_RESTORE
goto DEV_MENU

:DEV_EXCLUDE
cls
color 0C
echo  ================================================================================
echo  DEFENDER EXCLUSION - READ THIS
echo  ================================================================================
echo.
echo  Excluding a folder from Windows Defender real-time scanning gives a real
echo  performance boost on weak CPUs (no scanning of game files on every read).
echo.
echo  RISK: Anything malicious placed in that folder will NOT be scanned.
echo  Only exclude YOUR OWN game folders (e.g. D:\Games, Steam library folder).
echo.
color 0E
set /p EXPATH="  Full folder path to exclude (or 0 to cancel): "
if "%EXPATH%"=="0" goto DEV_MENU
if not exist "%EXPATH%" (
    echo  Folder does not exist.
    pause
    goto DEV_MENU
)
powershell -NoProfile -Command "Add-MpPreference -ExclusionPath '%EXPATH%' -ErrorAction Stop; Write-Output 'Exclusion added.'" 2>&1
if !errorlevel! neq 0 echo  Failed - Defender may not be active or path invalid.
pause
goto DEV_MENU

:DEV_LOG
cls
set "LATESTLOG="
for /f "delims=" %%f in ('dir /b /o-n "%~dp0OptimizerLog_*.log" 2^>nul') do (
    if not defined LATESTLOG set "LATESTLOG=%%f"
)
if defined LATESTLOG (
    start "" notepad "%~dp0%LATESTLOG%"
) else (
    echo  No optimizer logs found.
)
pause
goto DEV_MENU

:DEV_REGCLEAN
cls
echo  [CLEANING] Registry junk (MRU, recent docs, run history)...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery" /f >nul 2>&1
echo  Done - Explorer MRU/history cleared. Explorer restart recommended.
pause
goto DEV_MENU

:DEV_RESTORE
cls
echo  Creating manual restore point...
powershell -NoProfile -Command "Checkpoint-Computer -Description 'CTRLKirk_Manual' -RestorePointType 'MODIFY_SETTINGS'"
pause
goto DEV_MENU

:STRESS_TEST
cls
color 0E
echo.
echo  ================================================================================
echo  50x STRESS TEST LOOP
echo  ================================================================================
echo.
echo  WARNING: This will apply registry tweaks 50 times in rapid succession.
echo.
set /p CONFIRM="  Type YES to continue: "
if /i not "%CONFIRM%"=="YES" goto DEV_MENU

for /L %%i in (1,1,50) do (
    color 0A
    echo  [LOOP %%i/50] Applying tweaks...
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
)
echo.
echo  Stress test complete.
pause
goto DEV_MENU

:: ============================================================================
:: RECOMMENDED TOOLS MENU - installs proven third-party optimizers via winget
:: ============================================================================
:TOOLS_MENU
goto SAFE_TOOLS
echo Tools menu opened: %date% %time% >> "%LOGFILE%"
cls
color 0B
echo.
echo  ================================================================================
echo  RECOMMENDED TOOLS FOR LOW-END HARDWARE
echo  ================================================================================
echo.
echo  These are legit, widely-used tools that do what batch scripts can't:
echo.
echo   [1] Process Lasso  - Optional process scheduling tools. Results vary.
echo                        Default configuration is a safer starting point.
echo   [2] Quick CPU      - Advanced CPU/power controls. Not a guaranteed boost.
echo                        Aggressive settings may increase heat and battery use.
echo   [3] HWiNFO         - Shows temps/clocks/throttling. Find out WHY it's slow
echo                        (thermal throttle = cooling problem, not software).
echo   [4] RAMMap         - Microsoft's own memory tool. GUI view of RAM +
echo                        Empty menu does what this script's RAM tools do.
echo   [5] Install ALL of the above
echo   [0] Back to Main Menu
echo.

where winget >nul 2>&1
if %errorlevel% neq 0 (
    color 0E
    echo  NOTE: winget not found. Only RAMMap can be fetched automatically
    echo  Direct Microsoft download. Others will open their download pages.
    color 0B
    echo.
)

choice /c 123450 /n /m "Select tool: "
set "TOOLCH=!errorlevel!"
if "!TOOLCH!"=="6" set "TOOLCH=0"
echo Tools menu option !TOOLCH! at %date% %time% >> "%LOGFILE%"

if "%TOOLCH%"=="0" goto MENU
if "%TOOLCH%"=="1" goto TOOL_LASSO
if "%TOOLCH%"=="2" goto TOOL_QUICKCPU
if "%TOOLCH%"=="3" goto TOOL_HWINFO
if "%TOOLCH%"=="4" goto TOOL_RAMMAP
if "%TOOLCH%"=="5" goto TOOL_ALL
goto TOOLS_MENU

:TOOL_LASSO
cls
echo  [INSTALLING] Process Lasso (Bitsum)...
echo  What it does: keeps your game's process at high priority and stops
echo  background apps from stealing CPU mid-game. Free version is enough.
echo.
powershell.exe -NoProfile -Command "& winget install -e --id Bitsum.ProcessLasso --accept-source-agreements --accept-package-agreements 2>&1 | Tee-Object -FilePath $env:LOGFILE -Append; $code = $LASTEXITCODE; Add-Content -LiteralPath $env:LOGFILE -Value ('Process Lasso installer exit: ' + $code); exit $code"
if !errorlevel! neq 0 (
    echo  winget install failed or unavailable - opening download page instead.
    echo  Download: https://bitsum.com/download-process-lasso/
    start "" "https://bitsum.com/download-process-lasso/"
)
pause
goto TOOLS_MENU

:TOOL_QUICKCPU
cls
echo  [INSTALLING] Quick CPU (CoderBag)...
echo  What it does: disables CPU core parking and lets you set minimum CPU
echo  frequency - laptops often park cores to save power, hurting gaming.
echo.
powershell.exe -NoProfile -Command "& winget install -e --id CoderBag.QuickCPUx64 --accept-source-agreements --accept-package-agreements 2>&1 | Tee-Object -FilePath $env:LOGFILE -Append; $code = $LASTEXITCODE; Add-Content -LiteralPath $env:LOGFILE -Value ('Quick CPU installer exit: ' + $code); exit $code"
if !errorlevel! neq 0 (
    echo  winget install failed or unavailable - opening download page instead.
    echo  Download: https://coderbag.com/product/quickcpu
    start "" "https://coderbag.com/product/quickcpu"
)
pause
goto TOOLS_MENU

:TOOL_HWINFO
cls
echo  [INSTALLING] HWiNFO (REALiX)...
echo  What it does: hardware monitoring - CPU/GPU temps, clock speeds, and
echo  thermal throttling flags. If your laptop is thermally throttling, no
echo  software tweak will help - clean the fans / repaste / use a cooling pad.
echo.
powershell.exe -NoProfile -Command "& winget install -e --id REALiX.HWiNFO --accept-source-agreements --accept-package-agreements 2>&1 | Tee-Object -FilePath $env:LOGFILE -Append; $code = $LASTEXITCODE; Add-Content -LiteralPath $env:LOGFILE -Value ('HWiNFO installer exit: ' + $code); exit $code"
if !errorlevel! neq 0 (
    echo  winget install failed or unavailable - opening download page instead.
    echo  Download: https://www.hwinfo.com/download/
    start "" "https://www.hwinfo.com/download/"
)
pause
goto TOOLS_MENU

:TOOL_RAMMAP
cls
echo  [DOWNLOADING] RAMMap (Microsoft Sysinternals, official live download)...
if not exist "%~dp0Tools" mkdir "%~dp0Tools" >nul 2>&1
call :SAFE_RAMMAP_DOWNLOAD
if not errorlevel 1 (
    echo  [DONE] Verified Microsoft signature: %~dp0Tools\RAMMap64.exe
    echo.
    echo  TIP: In RAMMap, the "Empty" menu does the same standby-list purge as
    echo  this script's RAM tools - plus a nice GUI breakdown of your memory.
) else (
    echo  Download failed - get it from https://learn.microsoft.com/sysinternals
)
pause
goto TOOLS_MENU

:TOOL_ALL
cls
echo  Installing all recommended tools...
echo.
call :TOOL_LASSO_NP
call :TOOL_QUICKCPU_NP
call :TOOL_HWINFO_NP
echo  Downloading RAMMap...
if not exist "%~dp0Tools" mkdir "%~dp0Tools" >nul 2>&1
call :SAFE_RAMMAP_DOWNLOAD
echo.
echo Installation attempts finished. Review individual results and the session log.
pause
goto TOOLS_MENU

:TOOL_LASSO_NP
echo  - Process Lasso...
powershell.exe -NoProfile -Command "& winget install -e --id Bitsum.ProcessLasso --accept-source-agreements --accept-package-agreements 2>&1 | Tee-Object -FilePath $env:LOGFILE -Append; $code = $LASTEXITCODE; Add-Content -LiteralPath $env:LOGFILE -Value ('Process Lasso installer exit: ' + $code); exit $code"
if !errorlevel! neq 0 echo    winget failed - get it from https://bitsum.com
goto :eof

:TOOL_QUICKCPU_NP
echo  - Quick CPU...
powershell.exe -NoProfile -Command "& winget install -e --id CoderBag.QuickCPUx64 --accept-source-agreements --accept-package-agreements 2>&1 | Tee-Object -FilePath $env:LOGFILE -Append; $code = $LASTEXITCODE; Add-Content -LiteralPath $env:LOGFILE -Value ('Quick CPU installer exit: ' + $code); exit $code"
if !errorlevel! neq 0 echo    winget failed - get it from https://coderbag.com/product/quickcpu
goto :eof

:TOOL_HWINFO_NP
echo  - HWiNFO...
powershell.exe -NoProfile -Command "& winget install -e --id REALiX.HWiNFO --accept-source-agreements --accept-package-agreements 2>&1 | Tee-Object -FilePath $env:LOGFILE -Append; $code = $LASTEXITCODE; Add-Content -LiteralPath $env:LOGFILE -Value ('HWiNFO installer exit: ' + $code); exit $code"
if !errorlevel! neq 0 echo    winget failed - get it from https://www.hwinfo.com/download/
goto :eof

:SAFE_LAUNCH
title CTRLKirk Optimizer - Laptop Toolkit
set "CK_ROOT=%~dp0"
set "LOGFILE="
set "CKTMP="
for /f "tokens=1,* delims=|" %%a in ('powershell.exe -NoProfile -File "%~dp0OptimizerPaths.ps1" -InitializeLauncher') do (
    if "%%a"=="LOG" set "LOGFILE=%%b"
    if "%%a"=="TEMP" set "CKTMP=%%b"
)
if not defined LOGFILE (
    echo Unable to initialize logs. No changes made.
    pause
    exit /b 1
)
if not defined CKTMP (
    echo Unable to initialize temporary workspace. No changes made.
    pause
    exit /b 1
)
if not exist "%~dp0OptimizerSafety.ps1" (
    echo Safety engine missing. No optimization will run.
    pause
    exit /b 1
)

:SAFE_MENU
cls
color 0B
echo ================================================================================
echo CTRLKirk Optimizer - reviewed settings, preserve by default
 echo ================================================================================
echo [1] Standard - choose settings, preview, then explicit APPLY
echo [2] Advanced - adds optional background-app and Xbox service changes
echo [3] AUTO - preview previously selected options ONLY, never unattended apply
echo [4] RAM and Memory Tools - manual tools; no automatic cleanup
echo [5] Restore - inspect new-format snapshots and restore individual values
echo [6] Recommended Tools - detect, inspect, install or launch
echo [7] Laptop Workbench - dashboard, startup, cleanup, repair, power, preferences
echo [8] Security inventory / optional Defender scan
echo [9] Developer - read-only diagnostics
echo [0] Exit
echo.
echo Security and Explorer layout stay unchanged. All feature tradeoffs are opt-in.
echo Legacy registry backups cannot be safely restored automatically.
choice /c 1234567890 /n /m "Select an option: "
if errorlevel 255 exit /b 1
set "CK_CHOICE=!errorlevel!"
echo Main menu selection !CK_CHOICE! at %date% %time% >> "%LOGFILE%"
if "!CK_CHOICE!"=="10" exit /b 0
if "!CK_CHOICE!"=="9" goto SAFE_DIAGNOSTICS
if "!CK_CHOICE!"=="8" goto SAFE_SECURITY
if "!CK_CHOICE!"=="7" goto SAFE_WORKBENCH
if "!CK_CHOICE!"=="6" goto SAFE_TOOLS
if "!CK_CHOICE!"=="5" goto SAFE_RESTORE
if "!CK_CHOICE!"=="4" goto RAM_MENU
if "!CK_CHOICE!"=="3" goto SAFE_AUTO
if "!CK_CHOICE!"=="2" goto SAFE_ADVANCED
if "!CK_CHOICE!"=="1" goto SAFE_STANDARD
goto SAFE_MENU

:SAFE_STANDARD
set "CK_ENGINE_MODE=Standard"
goto SAFE_ENGINE
:SAFE_ADVANCED
set "CK_ENGINE_MODE=Advanced"
goto SAFE_ENGINE
:SAFE_AUTO
set "CK_ENGINE_MODE=Auto"
goto SAFE_ENGINE
:SAFE_RESTORE
set "CK_ENGINE_MODE=Restore"
goto SAFE_ENGINE
:SAFE_DIAGNOSTICS
set "CK_ENGINE_MODE=Diagnostics"
goto SAFE_ENGINE

:SAFE_WORKBENCH
set "CK_ENGINE_MODE=Workbench"
goto SAFE_ENGINE
:SAFE_TOOLS
set "CK_ENGINE_MODE=Tools"
goto SAFE_ENGINE
:SAFE_SECURITY
echo Security inventory requested %date% %time% >> "%LOGFILE%"
powershell.exe -NoProfile -File "%~dp0MalwareScanner\Scanner.ps1"
echo Security inventory returned !errorlevel! >> "%LOGFILE%"
pause
goto SAFE_MENU

:SAFE_ENGINE
echo Starting safety engine mode %CK_ENGINE_MODE% at %date% %time% >> "%LOGFILE%"
powershell.exe -NoProfile -File "%~dp0OptimizerSafety.ps1" -Mode %CK_ENGINE_MODE%
set "CK_RESULT=!errorlevel!"
echo Safety engine returned !CK_RESULT! at %date% %time% >> "%LOGFILE%"
if not "!CK_RESULT!"=="0" echo Safety engine stopped with an error. Review the latest SafetyRuns folder and session log.
if "%CK_ENGINE_MODE%"=="Tools" goto SAFE_MENU
echo.
pause
goto SAFE_MENU

:SAFE_RAM_CONSENT
echo Cached RAM is reusable already. Clearing it is not a guaranteed speed boost.
echo Apps may reload data from disk and temporarily slow down. This is not an undoable setting.
echo No documents are deleted, but avoid running this during important work.
choice /c NY /n /m "Continue with this manual memory operation? N cancels, Y continues: "
if errorlevel 2 exit /b 0
exit /b 1

:SAFE_RAMMAP_DOWNLOAD
powershell.exe -NoProfile -Command "$ErrorActionPreference = 'Stop'; try { $out = Join-Path $env:CK_ROOT 'Tools\RAMMap64.exe'; if (Test-Path -LiteralPath $out) { $candidate = $out } else { $candidate = Join-Path $env:CKTMP 'RAMMap.download'; Invoke-WebRequest -Uri 'https://live.sysinternals.com/RAMMap64.exe' -OutFile $candidate -UseBasicParsing }; $signature = Get-AuthenticodeSignature -LiteralPath $candidate; if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') { throw 'RAMMap signature validation failed; file will not be installed or launched.' }; if ($candidate -ne $out) { Move-Item -LiteralPath $candidate -Destination $out }; Add-Content -LiteralPath $env:LOGFILE -Value 'RAMMap Microsoft signature verified. Not launched.'; Write-Host 'RAMMap verified; not launched.' } catch { Add-Content -LiteralPath $env:LOGFILE -Value $_.Exception.Message; Write-Host $_.Exception.Message; exit 1 }"
exit /b !errorlevel!
