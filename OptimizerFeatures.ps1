function Invoke-NativeLogged($Executable, [string[]]$Arguments, $Label) {
    Write-Event 'CommandStarting' $Label (($Executable | Split-Path -Leaf) + ' ' + ($Arguments -join ' '))
    $previous = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $Executable @Arguments 2>&1 | ForEach-Object {
            $line = $_.ToString()
            Write-Host $line
            Write-Event 'CommandOutput' $Label $line
        }
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previous }
    Write-Event 'CommandFinished' $Label "Exit code: $code"
    if ($code -notin @(0,3010)) { throw "$Label failed with exit code $code. Review command output; no success is assumed." }
    if ($code -eq 3010) { Add-Result $Label 'Restart needed' 'Command requested a restart; no automatic restart will occur.' }
}

function Save-Preferences($Ids, $Path) {
    $null = Get-Plan $Ids
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $pending = $Path + '.pending'
    Export-Clixml -InputObject ([string[]]$Ids) -LiteralPath $pending
    if (Test-Path -LiteralPath $Path) { [IO.File]::Replace($pending,$Path,($Path + '.previous')) }
    else { [IO.File]::Move($pending,$Path) }
    Add-Result 'Preferences' 'Saved' 'Selected option IDs saved. LOAD requires a fresh preview and APPLY; AUTO remains preview-only.'
}

function Get-PreferencePath($Root, [string]$Name) {
    $name = $Name.Trim()
    if ($name -notmatch '^[\p{L}\p{N}][\p{L}\p{N} _-]{0,47}$' -or $name -match '^(?i)(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$') {
        throw 'Use a preference name of 1-48 letters/numbers, spaces, hyphens or underscores. Reserved Windows names are not allowed.'
    }
    Join-Path $Root ($name + '.clixml')
}

function Get-SavedPreferences($Root) {
    if (Test-Path -LiteralPath $Root) {
        Get-ChildItem -LiteralPath $Root -Filter '*.clixml' -File | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0 } | Sort-Object BaseName
    }
}

function Select-Preference($Root) {
    $profiles = @(Get-SavedPreferences $Root)
    if (-not $profiles.Count) { Write-Host 'No saved preferences yet. Create one or answer manually.'; return $null }
    for ($i=0; $i -lt $profiles.Count; $i++) { Write-Host "[$($i+1)] $($profiles[$i].BaseName)" }
    $number = 0
    if (-not [int]::TryParse((Read-Host 'Preference number, or Enter to cancel'),[ref]$number) -or $number -lt 1 -or $number -gt $profiles.Count) { return $null }
    return $profiles[$number-1].FullName
}

function Get-PreferenceSource($Root) {
    Write-Host '[1] Load a saved preference  [2] Create a new named preference'
    Write-Host '[3] Answer questions manually this time (default)  [0] Cancel'
    switch (Read-Host 'How would you like to choose your settings?') {
        '1' { return [pscustomobject]@{ Action='Load'; Path=(Select-Preference $Root) } }
        '2' { return [pscustomobject]@{ Action='New'; Path=$null } }
        '0' { return [pscustomobject]@{ Action='Cancel'; Path=$null } }
        default { return [pscustomobject]@{ Action='Manual'; Path=$null } }
    }
}

function Save-NamedPreferences($Ids, $Root) {
    $name = Read-Host 'Name this preference, for example Gaming or Everyday Laptop; Enter cancels'
    if ([string]::IsNullOrWhiteSpace($name)) { return $false }
    $path = Get-PreferencePath $Root $name
    if ((Test-Path -LiteralPath $path) -and (Read-Host 'That name already exists. Type REPLACE to replace it, or Enter to keep the existing preference') -cne 'REPLACE') { return $false }
    Save-Preferences $Ids $path
    Write-Host "Saved preference: $([IO.Path]::GetFileNameWithoutExtension($path))"
    return $true
}

function Get-PowerPlans {
    $output = & "$env:SystemRoot\System32\powercfg.exe" /list
    if ($LASTEXITCODE -ne 0) { throw 'Unable to list existing power plans.' }
    foreach ($line in $output) {
        $match = [regex]::Match($line,'([0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12})\s+\((.*?)\)')
        if ($match.Success) { [pscustomobject]@{ Id=$match.Groups[1].Value.ToLowerInvariant(); Name=$match.Groups[2].Value } }
    }
}

function Get-LaptopSnapshot {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = @(Get-CimInstance Win32_Processor)
    [pscustomobject]@{ Time=(Get-Date).ToString('o'); TotalRAMMB=[math]::Round($os.TotalVisibleMemorySize/1024); AvailableRAMMB=[math]::Round($os.FreePhysicalMemory/1024); ProcessCount=@(Get-Process).Count; CPULoadPercent=($cpu | Measure-Object LoadPercentage -Average).Average; CPU=($cpu.Name -join '; '); Windows=$os.Caption; ActivePowerScheme=(Get-ValueState ($script:Catalog | Where-Object Id -EQ 'power-balanced')).Value }
}

function Show-Dashboard {
    $sample = Get-LaptopSnapshot
    Add-Result 'Laptop snapshot' 'Measured' ("CPU load {0}%; RAM available {1}/{2} MB; {3} processes. These are instant readings, not a benchmark." -f $sample.CPULoadPercent,$sample.AvailableRAMMB,$sample.TotalRAMMB,$sample.ProcessCount)
    Add-Result 'Hardware / Windows' 'Information' ($sample.CPU + ' / ' + $sample.Windows)
    $sample | Export-Clixml -LiteralPath (Join-Path $script:RunDirectory 'Measurements.clixml')
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 12 ProcessName,Id,@{N='WorkingSetMB';E={[math]::Round($_.WorkingSet64/1MB)}},@{N='PrivateMB';E={[math]::Round($_.PrivateMemorySize64/1MB)}} | Format-Table -AutoSize | Out-Host
    foreach ($disk in @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3')) {
        Add-Result ('Disk ' + $disk.DeviceID) 'Measured' ('{0:N1} GB available of {1:N1} GB' -f ($disk.FreeSpace/1GB),($disk.Size/1GB))
    }
    Add-Result 'Thermals' 'Information' 'Windows does not expose reliable CPU/GPU temperatures on every laptop. Use HWiNFO sensors and compare clocks/thermal flags during the SAME workload.'
    Add-Result 'Measurement comparison' 'Information' 'Each dashboard stores Measurements.clixml. Compare equivalent workloads and power conditions; more available RAM alone does not establish an improvement.'
}

function Show-StartupTools([bool]$Preview) {
    $startup = @(Get-CimInstance Win32_StartupCommand)
    foreach ($item in $startup) { Add-Result $item.Name 'Startup entry' ([string]$item.Location) }
    if (-not $startup.Count) { Add-Result 'Startup inventory' 'Information' 'No entries returned by Win32_StartupCommand. This is not an exhaustive persistence scan.' }
    Add-Result 'Startup choices' 'Information' 'Disabling a startup app may remove syncing, tray controls or notifications. Use Windows startup controls to make individual choices; those external changes are not captured by optimizer snapshots.'
    if ($Preview) { return }
    Write-Host '[1] Open Windows startup settings  [2] List apps / request graceful close  [0] Back'
    switch (Read-Host 'Choice') {
        '1' { Start-Process 'ms-settings:startupapps'; Add-Result 'Startup settings' 'Opened' 'Windows settings opened; no entries changed by the optimizer.' }
        '2' {
            $session = (Get-Process -Id $PID).SessionId
            $apps = @(Get-Process | Where-Object { $_.SessionId -eq $session -and $_.MainWindowHandle -ne 0 -and $_.Id -ne $PID -and $_.ProcessName -notin @('explorer','taskmgr','WindowsTerminal','powershell','pwsh','cmd') })
            $apps | Select-Object ProcessName,Id,@{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB)}} | Format-Table -AutoSize | Out-Host
            $number = 0
            if (-not [int]::TryParse((Read-Host 'PID of an app to request close, or Enter to cancel'),[ref]$number)) { return }
            $selected = @($apps | Where-Object Id -EQ $number)
            if ($selected.Count -ne 1) { throw 'Select one PID from the displayed list.' }
            $started = $selected[0].StartTime
            if ((Read-Host 'Save your work. The app may prompt you; it will NOT be force-killed. Type CLOSE to continue') -cne 'CLOSE') { return }
            $current = Get-Process -Id $number
            if ($current.StartTime -ne $started) { throw 'Process changed since selection. No close requested.' }
            Write-Event 'CloseRequested' $current.ProcessName 'User explicitly requested graceful close'
            $accepted = $current.CloseMainWindow()
            Add-Result $current.ProcessName 'Close request' "Request accepted: $accepted. This does not prove the app closed; save prompts may still be open."
        }
    }
}

function Get-CleanupCandidates($Root, [datetime]$Cutoff) {
    $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    if ($fullRoot.StartsWith('\\')) { throw 'Network temporary folders are not cleaned automatically.' }
    if ($fullRoot -eq [IO.Path]::GetPathRoot($fullRoot).TrimEnd('\') -or $fullRoot -eq $env:USERPROFILE -or $fullRoot -eq $env:SystemRoot) { throw 'Unsafe temporary-directory root; cleanup refused.' }
    $protected = @($PSScriptRoot,$env:USERPROFILE,$env:SystemRoot,(Join-Path $env:USERPROFILE 'Downloads'))
    foreach ($name in @('DesktopDirectory','MyDocuments','MyMusic','MyPictures','MyVideos')) { $protected += [Environment]::GetFolderPath($name) }
    foreach ($path in $protected) {
        if (-not $path) { continue }
        $path = [IO.Path]::GetFullPath($path).TrimEnd('\')
        if ($fullRoot -eq $path -or $path.StartsWith($fullRoot + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Configured TEMP includes a protected personal/system/project folder; cleanup refused.' }
        if ($path -ne $env:USERPROFILE -and $fullRoot.StartsWith($path + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Configured TEMP is inside a protected personal/project folder; cleanup refused.' }
    }
    if (([IO.File]::GetAttributes($fullRoot) -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Temporary directory is a link; cleanup refused.' }
    $pending = [System.Collections.Generic.Stack[string]]::new()
    $pending.Push($fullRoot)
    $seen = 0
    while ($pending.Count) {
        $directory = $pending.Pop()
        try { $items = @(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop) }
        catch { Write-Event 'CleanupEnumerationSkipped' '' $_.Exception.Message; continue }
        foreach ($item in $items) {
            if (++$seen -gt 50000) { throw 'Cleanup scan exceeded 50,000 items. No deletion started. Use Windows Storage settings for a larger cleanup.' }
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
            if ($item.PSIsContainer) { $pending.Push($item.FullName); continue }
            if ($item.LastWriteTimeUtc -ge $Cutoff -or $item.LastAccessTimeUtc -ge $Cutoff) { continue }
            [pscustomobject]@{ Path=$item.FullName; Root=$fullRoot; Bytes=[long]$item.Length; ModifiedTicks=$item.LastWriteTimeUtc.Ticks; AccessTicks=$item.LastAccessTimeUtc.Ticks }
        }
    }
}

function Test-CleanupCandidate($Item) {
    $root = [IO.Path]::GetFullPath($Item.Root).TrimEnd('\')
    $path = [IO.Path]::GetFullPath($Item.Path)
    if (-not $path.StartsWith($root + '\',[StringComparison]::OrdinalIgnoreCase)) { return $false }
    $cursor = [IO.Path]::GetDirectoryName($path)
    while ($cursor.Length -ge $root.Length) {
        if (([IO.File]::GetAttributes($cursor) -band [IO.FileAttributes]::ReparsePoint) -ne 0) { return $false }
        if ($cursor -eq $root) { break }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
    $file = Get-Item -LiteralPath $path -Force -ErrorAction Stop
    return (-not $file.PSIsContainer -and ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0 -and $file.Length -eq $Item.Bytes -and $file.LastWriteTimeUtc.Ticks -eq $Item.ModifiedTicks -and $file.LastAccessTimeUtc.Ticks -eq $Item.AccessTicks)
}

function Remove-CleanupPlan($Items) {
    $deleted = 0; $skipped = 0; $bytes = 0L
    foreach ($item in $Items) {
        try {
            if (-not (Test-CleanupCandidate $item)) { throw 'File changed or path is no longer eligible.' }
            Write-Event 'DeleteStarting' '' $item.Path
            Remove-Item -LiteralPath $item.Path -ErrorAction Stop
            $deleted++; $bytes += $item.Bytes
            Write-Event 'Deleted' '' $item.Path
        } catch { $skipped++; Write-Event 'DeleteSkipped' '' ($item.Path + ': ' + $_.Exception.Message) }
    }
    Add-Result 'Temporary-file cleanup' 'Finished' ("Deleted $deleted files; skipped $skipped locked/changed/ineligible files. Approximate logical size: {0:N1} MB. This is not guaranteed physical space recovered." -f ($bytes/1MB))
}

function Show-CleanupTools([bool]$Preview) {
    $items = @(Get-CleanupCandidates ([IO.Path]::GetTempPath()) ([datetime]::UtcNow.AddDays(-7)))
    $items | Export-Csv -LiteralPath (Join-Path $script:RunDirectory 'CleanupPreview.csv') -NoTypeInformation -Encoding UTF8
    $bytes = ($items | Measure-Object Bytes -Sum).Sum
    Add-Result 'Cleanup preview' 'Preview' ("$($items.Count) files in YOUR temporary folder older than seven days by modified/access times; {0:N1} MB. Full list: CleanupPreview.csv. Nothing deleted yet." -f ($bytes/1MB))
    Add-Result 'Cleanup tradeoff' 'Warning' 'Deletion is permanent, not sent to Recycle Bin, and cannot be undone by snapshots. Old temp files can still matter to apps or contain files you placed there. No browser/shader cache, logs, dumps or personal folders are targeted separately.'
    if ($Preview -or -not $items.Count) { return }
    $principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Add-Result 'Cleanup execution' 'Blocked' 'Run the BAT normally, not as administrator, for user-temp deletion. Preview remains available elevated.'
        return
    }
    if ((Read-Host "Inspect CleanupPreview.csv first. Type DELETE $($items.Count) to delete ONLY these files, or Enter to cancel") -ceq "DELETE $($items.Count)") { Remove-CleanupPlan $items }
    else { Add-Result 'Cleanup execution' 'Cancelled' 'No files deleted.' }
}

function Show-MaintenanceTools([bool]$Preview) {
    Add-Result 'Maintenance' 'Information' 'Repairs and network troubleshooting are NOT routine FPS optimizations. No commands run until separately selected and confirmed.'
    Write-Host '[1] Check component health and verify system files (no repair)'
    Write-Host '[2] Repair Windows (DISM RestoreHealth, then SFC)'
    Write-Host '[3] Inspect active network adapters/DNS'
    Write-Host '[4] Flush DNS cache only'
    Write-Host '[0] Back'
    if ($Preview) { return }
    switch (Read-Host 'Choice') {
        '1' {
            if ((Read-Host 'May take a while and creates Windows diagnostic logs. Type CHECK to continue') -cne 'CHECK') { return }
            Invoke-NativeLogged "$env:SystemRoot\System32\Dism.exe" @('/Online','/Cleanup-Image','/CheckHealth') 'DISM health check'
            Invoke-NativeLogged "$env:SystemRoot\System32\sfc.exe" @('/verifyonly') 'SFC verification'
            Add-Result 'Windows verification' 'Finished' 'Commands finished. Inspect their output for health findings; exit zero alone does not mean no corruption.'
        }
        '2' {
            if ((Read-Host 'Requires admin. Changes Windows components, may use Windows Update/network and take a long time. NOT reversible via snapshots. Save work. Type REPAIR to continue') -cne 'REPAIR') { return }
            Invoke-NativeLogged "$env:SystemRoot\System32\Dism.exe" @('/Online','/Cleanup-Image','/RestoreHealth') 'DISM repair'
            Invoke-NativeLogged "$env:SystemRoot\System32\sfc.exe" @('/scannow') 'SFC repair'
            Add-Result 'Windows repair' 'Finished' 'Commands finished; inspect their findings. No reboot is scheduled.'
        }
        '3' {
            Get-NetAdapter | Select-Object Name,Status,LinkSpeed | Format-Table | Out-Host
            Get-DnsClientServerAddress | Select-Object InterfaceAlias,AddressFamily,ServerAddresses | Format-Table -Wrap | Out-Host
            Add-Result 'Network inspection' 'Read only' 'Adapters and DNS shown locally. No DNS server, Winsock, IP or TCP settings changed.'
        }
        '4' {
            if ((Read-Host 'Temporary DNS cache only; next lookups may be slower. Type FLUSH to continue') -cne 'FLUSH') { return }
            Invoke-NativeLogged "$env:SystemRoot\System32\ipconfig.exe" @('/flushdns') 'DNS cache flush'
            Add-Result 'DNS cache' 'Finished' 'Cache flush command completed. DNS servers and network configuration left unchanged.'
        }
    }
}

function Get-RecommendedTools {
    @(
        [pscustomobject]@{ Name='Process Lasso'; Id='Bitsum.ProcessLasso'; Pattern='Process Lasso'; Advice='Optional scheduling controls; default settings first. Priority changes can hurt other apps.'; Paths=@("$env:ProgramFiles\Process Lasso\ProcessLasso.exe") }
        [pscustomobject]@{ Name='Quick CPU'; Id='CoderBag.QuickCPUx64'; Pattern='Quick CPU'; Advice='CPU/power controls can increase heat, drain battery or worsen throttling. Do not blindly unpark all cores.'; Paths=@("$env:ProgramFiles\Quick CPU\QuickCPU.exe") }
        [pscustomobject]@{ Name='HWiNFO'; Id='REALiX.HWiNFO'; Pattern='HWiNFO'; Advice='Use sensors to observe clocks, temperatures and throttling while gaming; no tuning is applied automatically.'; Paths=@("$env:ProgramFiles\HWiNFO64\HWiNFO64.exe","$env:ProgramFiles\HWiNFO\HWiNFO64.exe") }
        [pscustomobject]@{ Name='RAMMap'; Id='Microsoft.Sysinternals.RAMMap'; Pattern='RAMMap'; Advice='Microsoft memory diagnostics. Cached memory is normally useful; clearing it is troubleshooting, not a guaranteed boost.'; Paths=@((Join-Path $PSScriptRoot 'Tools\RAMMap64.exe')) }
    )
}

function Show-RecommendedTools([bool]$Preview) {
    Write-Host 'RECOMMENDED TOOLS - inspect, install or launch; no automatic tuning'
    $tools = @(Get-RecommendedTools)
    $installed = @()
    foreach ($root in @('HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')) {
        foreach ($key in @(Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue)) {
            $entry = Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction SilentlyContinue
            if ($null -ne $entry -and $entry.PSObject.Properties['DisplayName']) { $installed += [string]$entry.DisplayName }
        }
    }
    for ($i=0; $i -lt $tools.Count; $i++) {
        $tool = $tools[$i]
        $present = @($installed | Where-Object { $_ -like ('*' + $tool.Pattern + '*') }).Count -gt 0 -or @($tool.Paths | Where-Object { Test-Path -LiteralPath $_ }).Count -gt 0
        Add-Result ("[$($i+1)] " + $tool.Name) 'Inventory' ("Detected locally: $present. " + $tool.Advice)
    }
    if ($Preview) { return }
    $number = 0
    Write-Host 'Select a tool number, or 0/Enter to return.'
    if (-not [int]::TryParse((Read-Host 'Choice'),[ref]$number) -or $number -lt 1 -or $number -gt $tools.Count) { return }
    $selected = $tools[$number-1]
    $action = Read-Host 'Type DETAILS for winget versions, INSTALL for an explicit install, or LAUNCH to open a signed local executable. Enter cancels'
    if ($action -ceq 'LAUNCH') {
        $paths = @($selected.Paths | Where-Object { Test-Path -LiteralPath $_ })
        if (-not $paths.Count) { Add-Result $selected.Name 'Not launched' 'No executable found at known paths. Open it from Start if installed elsewhere.'; return }
        $signature = Get-AuthenticodeSignature -LiteralPath $paths[0]
        if ($signature.Status -ne 'Valid') { throw 'Executable signature did not validate; launch refused.' }
        Write-Host "Signer: $($signature.SignerCertificate.Subject)"
        if ((Read-Host 'Type OPEN to launch this external application; its changes are not tracked by optimizer snapshots') -ceq 'OPEN') {
            Start-Process -FilePath $paths[0]
            Add-Result $selected.Name 'Launched' 'External application opened. No tuning settings supplied by the optimizer.'
        }
        return
    }
    if ($action -notin @('DETAILS','INSTALL')) { return }
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) { Add-Result $selected.Name 'Unavailable' 'winget not found. Install/update Microsoft App Installer through Microsoft Store, or use the vendor installer manually.'; return }
    Invoke-NativeLogged $winget.Source @('show','--id',$selected.Id,'--exact','--source','winget','--versions') ($selected.Name + ' available versions')
    if ($action -cne 'INSTALL') { return }
    $version = Read-Host 'Exact version to install from that list; prefer a release at least seven days old. Enter cancels'
    if ([string]::IsNullOrWhiteSpace($version)) { return }
    if ($version -notmatch '^[0-9][0-9A-Za-z.\-+_]{0,60}$') { throw 'Invalid version string.' }
    if ((Read-Host "Type INSTALL to install $($selected.Name) $version. winget/vendor agreements may prompt. External installs are not reverted by snapshots") -cne 'INSTALL') { return }
    Invoke-NativeLogged $winget.Source @('install','--id',$selected.Id,'--exact','--version',$version,'--source','winget','--interactive') ($selected.Name + ' installation')
    Add-Result $selected.Name 'Installer finished' 'Installer reported success. No optimization settings were applied; use the vendor uninstaller if needed.'
}

function Show-SystemHealth {
    Write-Host 'SYSTEM HEALTH CHECK - read only, no changes made'
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize/1MB,1)
    $freeRAM = [math]::Round($os.FreePhysicalMemory/1MB,1)
    $commitUsed = [math]::Round(($os.TotalVirtualMemorySize - $os.FreeVirtualMemory)/1MB,1)
    $commitLimit = [math]::Round($os.TotalVirtualMemorySize/1MB,1)
    Add-Result 'Memory pressure' 'Measured' ("{0} GB RAM free of {1} GB; commit charge {2} GB of {3} GB limit. Commit above physical RAM means Windows is paging to disk - the usual cause of stutter on games." -f $freeRAM,$totalRAM,$commitUsed,$commitLimit)
    if ($commitUsed -gt $totalRAM) { Add-Result 'Commit verdict' 'Warning' 'Committed memory exceeds physical RAM - Windows MUST page. A restart clears accumulated commit; otherwise reduce resident apps or expect stutter under load.' }
    try {
        $pf = Get-CimInstance Win32_PageFileUsage -ErrorAction Stop
        if ($pf) { Add-Result 'Pagefile' 'Measured' ("{0} MB allocated, {1} MB in use. Heavy pagefile use with low free RAM indicates memory pressure." -f $pf.AllocatedBaseSize,$pf.CurrentUsage) }
    } catch { Add-Result 'Pagefile' 'Unavailable' $_.Exception.Message }
    try {
        $faults = (Get-Counter '\Memory\Page Faults/sec' -ErrorAction Stop).CounterSamples[0].CookedValue
        $pages = (Get-Counter '\Memory\Pages/sec' -ErrorAction Stop).CounterSamples[0].CookedValue
        Add-Result 'Paging activity' 'Measured' ("{0:N0} page faults/sec, {1:N0} hard page reads/sec. Sustained values in the thousands mean active disk thrashing." -f $faults,$pages)
        if ($pages -gt 1000) { Add-Result 'Paging verdict' 'Warning' 'Windows is actively moving memory to/from disk. Closing memory-heavy apps before gaming will help more than any setting.' }
    } catch { Add-Result 'Paging activity' 'Unavailable' $_.Exception.Message }
    $cpu = @(Get-CimInstance Win32_Processor)
    $cpuLoad = ($cpu | Measure-Object LoadPercentage -Average).Average
    Add-Result 'CPU' 'Measured' ("{0}; {1} logical processors; current load {2}%. Sustained single-core spikes matter more for games than total load." -f ($cpu.Name -join '; '),[Environment]::ProcessorCount,$cpuLoad)
    try {
        $snap1 = @{}; Get-Process | ForEach-Object { $snap1[$_.Id] = $_.CPU }
        Start-Sleep -Seconds 2
        $rows = foreach ($p in Get-Process) {
            if ($snap1.ContainsKey($p.Id) -and $null -ne $p.CPU) { [pscustomobject]@{ Name=$p.ProcessName; Pct=[math]::Round(($p.CPU - $snap1[$p.Id])/2*100/[Environment]::ProcessorCount,1); MB=[math]::Round($p.WorkingSet64/1MB) } }
        }
        Add-Result 'Top CPU right now' 'Measured' (($rows | Sort-Object Pct -Descending | Select-Object -First 8 | ForEach-Object { "{0} {1}% ({2} MB)" -f $_.Name,$_.Pct,$_.MB }) -join '; ')
    } catch { Add-Result 'CPU sample' 'Unavailable' $_.Exception.Message }
    Get-Process | Sort-Object PrivateMemorySize64 -Descending | Select-Object -First 12 ProcessName,Id,@{N='Commit_MB';E={[math]::Round($_.PrivateMemorySize64/1MB)}},@{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB)}} | Format-Table -AutoSize | Out-Host
    foreach ($gpu in @(Get-CimInstance Win32_VideoController | Where-Object { $_.AdapterRAM -gt 0 })) {
        Add-Result ('GPU: ' + $gpu.Name) 'Information' ("Driver {0}; reported VRAM {1:N1} GB. Games above this VRAM will stutter regardless of CPU/RAM." -f $gpu.DriverVersion,[math]::Round($gpu.AdapterRAM/1GB,1))
    }
    foreach ($disk in @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3')) {
        Add-Result ('Disk ' + $disk.DeviceID.TrimEnd(':')) 'Measured' ('{0:N1} GB available of {1:N1} GB. Under ~10% free can slow writes and updates.' -f ($disk.FreeSpace/1GB),($disk.Size/1GB))
    }
    $scheme = (& "$env:SystemRoot\System32\powercfg.exe" /getactivescheme | Out-String).Trim()
    Add-Result 'Active power plan' 'Information' $scheme
    Add-Result 'Before gaming checklist' 'Information' 'Close browsers/Discord/overlays you are not using, keep the game on settings matching your GPU VRAM, and compare this check before and during a session. A second run during gameplay shows what the game itself is costing.'
}

$script:CacheDirNames = @('Cache','Code Cache','GPUCache','ShaderCache','GrShaderCache','GraphiteDawnCache')

function Get-ExistingDirs($Patterns) {
    $dirs = @()
    foreach ($pattern in @($Patterns)) {
        foreach ($match in @(Get-Item -Path $pattern -ErrorAction SilentlyContinue)) {
            if ($match.PSIsContainer -and ($match.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) { $dirs += $match.FullName }
        }
    }
    $dirs | Sort-Object -Unique
}

function Get-AppCacheDirs($AppRoot) {
    $dirs = @()
    if (-not (Test-Path -LiteralPath $AppRoot)) { return $dirs }
    foreach ($name in $script:CacheDirNames) {
        $candidate = Join-Path $AppRoot $name
        if (Test-Path -LiteralPath $candidate) { $dirs += $candidate }
    }
    foreach ($sub in @(Get-ChildItem -LiteralPath $AppRoot -Directory -Force -ErrorAction SilentlyContinue | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0 })) {
        foreach ($name in $script:CacheDirNames) {
            $candidate = Join-Path $sub.FullName $name
            if (Test-Path -LiteralPath $candidate) { $dirs += $candidate }
        }
    }
    $dirs
}

function Get-SteamCacheRoots {
    $libraries = @()
    $steamPath = (Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction SilentlyContinue).SteamPath
    if ($steamPath) {
        $libraries += $steamPath
        $vdf = Join-Path $steamPath 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($line in @(Get-Content -LiteralPath $vdf -ErrorAction SilentlyContinue)) {
                $m = [regex]::Match($line,'"path"\s+"([^"]+)"')
                if ($m.Success) { $libraries += ($m.Groups[1].Value -replace '\\\\','\') }
            }
        }
    }
    foreach ($fallback in @("$env:ProgramFiles (x86)\Steam","${env:ProgramFiles(x86)}\Steam","D:\Steam","E:\Steam","$env:ProgramFiles\Steam")) { $libraries += $fallback }
    $roots = @()
    foreach ($library in ($libraries | Sort-Object -Unique)) {
        if (-not (Test-Path -LiteralPath ([IO.Path]::GetPathRoot($library)) -ErrorAction SilentlyContinue)) { continue }
        $steamapps = Join-Path $library 'steamapps'
        if (-not (Test-Path -LiteralPath $steamapps)) { continue }
        foreach ($sub in @('downloading','temp','shadercache')) {
            $candidate = Join-Path $steamapps $sub
            if (Test-Path -LiteralPath $candidate) { $roots += $candidate }
        }
        foreach ($gameDir in @(Get-ChildItem -LiteralPath (Join-Path $steamapps 'common') -Directory -ErrorAction SilentlyContinue)) {
            foreach ($sub in @('shadercache','cache')) {
                $candidate = Join-Path $gameDir.FullName $sub
                if (Test-Path -LiteralPath $candidate) { $roots += $candidate }
            }
        }
    }
    $roots
}

function Get-CacheTargets {
    $targets = [System.Collections.Generic.List[object]]::new()
    $add = {
        param($Id,$Label,$Roots,$Admin,$Note,$Kind='Files')
        $targets.Add([pscustomobject]@{ Id=$Id; Label=$Label; Roots=@($Roots); Admin=[bool]$Admin; Note=$Note; Kind=$Kind })
    }
    & $add 'user-temp' 'User temporary files (%TEMP%)' @($env:TEMP) $false 'App installer/update leftovers. Files in use are skipped; a running installer may need its temp files.'
    & $add 'pip-cache' 'pip download cache' @(Get-ExistingDirs @("$env:LOCALAPPDATA\pip\cache")) $false 'Python package downloads; pip re-downloads when needed.'
    & $add 'nvidia-ota' 'NVIDIA App driver download cache' @(Get-ExistingDirs @('C:\ProgramData\NVIDIA Corporation\NVIDIA App\UpdateFramework\ota-artifacts')) $true 'Downloaded driver installer packages only; the installed driver is unaffected. Needs admin.'
    & $add 'fivem' 'FiveM downloaded game data' @(Get-ExistingDirs @("$env:LOCALAPPDATA\FiveM")) $false 'Game data re-downloads on next launch. ONLY clean if you no longer play FiveM.'
    & $add 'steam' 'Steam download/temp/shader caches' @(Get-SteamCacheRoots) $false 'Re-downloads as needed. Shader caches regenerate but may cause one-time shader stutter on first launch of each game.'
    $browserRoots = @()
    foreach ($spec in @(
        @{ Root="$env:LOCALAPPDATA\Google\Chrome\User Data" },
        @{ Root="$env:LOCALAPPDATA\Microsoft\Edge\User Data" },
        @{ Root="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data" },
        @{ Root="$env:LOCALAPPDATA\Vivaldi\User Data" },
        @{ Root="$env:APPDATA\Opera Software" },
        @{ Root="$env:APPDATA\discord" },
        @{ Root="$env:APPDATA\discordcanary" },
        @{ Root="$env:APPDATA\Slack" }
    )) { $browserRoots += @(Get-AppCacheDirs $spec.Root) }
    & $add 'browser-cache' 'Browser/app caches (Chrome, Edge, Brave, Vivaldi, Opera, Discord, Slack)' $browserRoots $false 'Cache folders only - cookies, logins, passwords and history are never touched.'
    & $add 'windows-temp' 'Windows temporary files' @(Get-ExistingDirs @("$env:WINDIR\Temp")) $true 'System temp files; in-use files are skipped. Needs admin.'
    & $add 'wu-download' 'Windows Update download cache' @(Get-ExistingDirs @("$env:WINDIR\SoftwareDistribution\Download")) $true 'Downloaded update packages; re-downloads if needed. Needs admin.'
    & $add 'recycle-bin' 'Recycle Bin' @() $false 'Permanently deletes everything in the Recycle Bin - no undo.' 'RecycleBin'
    $targets
}

function Measure-CacheRoots($Roots) {
    $bytes = 0L; $files = 0
    foreach ($root in @($Roots)) {
        foreach ($file in @(Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) { $bytes += $file.Length; $files++ }
        }
    }
    [pscustomobject]@{ Bytes=$bytes; Files=$files }
}

function Remove-CacheFiles($Roots, $AuditPath) {
    $deleted = 0; $skipped = 0; $bytes = 0L
    foreach ($root in @($Roots)) {
        $prefix = $root.TrimEnd('\') + '\'
        foreach ($file in @(Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or -not $file.FullName.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { $skipped++; continue }
            try {
                $length = $file.Length
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
                $deleted++; $bytes += $length
                [IO.File]::AppendAllText($AuditPath,"DELETED`t$length`t$($file.FullName)`r`n")
            } catch {
                $skipped++
                [IO.File]::AppendAllText($AuditPath,"SKIPPED`t0`t$($file.FullName)`t$($_.Exception.Message)`r`n")
            }
        }
        Get-ChildItem -LiteralPath $root -Recurse -Directory -Force -ErrorAction SilentlyContinue |
            Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
                if (($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0 -and -not @(Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue).Count) {
                    try { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop } catch {}
                }
            }
    }
    [pscustomobject]@{ Deleted=$deleted; Skipped=$skipped; Bytes=$bytes }
}

function Show-CacheCleaner([bool]$Preview) {
    if ($Preview) {
        Add-Result 'Safe cache cleaner' 'Information' 'Scan-first cleaner for regenerable caches: temp files, pip/NVIDIA/Steam caches, browser cache folders (never cookies/logins), Windows Update downloads, Recycle Bin and an optional AppData deep scan. Nothing deletes without a size preview and typed consent.'
        return
    }
    Write-Host 'SAFE CACHE CLEANER - regenerable caches and junk only; scan first, delete second'
    Write-Host '[1] Scan and clean caches  [2] Deep scan AppData (read only, top 20 folders)  [0] Back'
    switch (Read-Host 'Choice') {
        '2' { Show-CacheDeepScan; return }
        '1' { }
        default { return }
    }
    $targets = @(Get-CacheTargets | Where-Object { $_.Roots.Count -gt 0 -or $_.Kind -eq 'RecycleBin' })
    if (-not $targets.Count) { Add-Result 'Cache cleaner' 'Information' 'No known cache folders found on this system.'; return }
    $principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    $elevated = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $before = @{}; foreach ($disk in @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3')) { $before[$disk.DeviceID] = $disk.FreeSpace }
    Write-Host 'Scanning sizes - large folders can take a moment...'
    $scan = @()
    $totalBytes = 0L
    for ($i=0; $i -lt $targets.Count; $i++) {
        $t = $targets[$i]
        if ($t.Kind -eq 'RecycleBin') {
            $scan += [pscustomobject]@{ Index=$i+1; Target=$t; Size='unknown'; Note=$t.Note; Admin=$false }
            continue
        }
        if ($t.Admin -and -not $elevated) {
            $scan += [pscustomobject]@{ Index=$i+1; Target=$t; Size='SKIPPED (needs admin)'; Note=$t.Note; Admin=$true }
            continue
        }
        $measure = Measure-CacheRoots $t.Roots
        $totalBytes += $measure.Bytes
        $sizeText = '{0:N1} MB in {1} files' -f ($measure.Bytes/1MB),$measure.Files
        if ($measure.Files -eq 0) { $sizeText = 'empty' }
        $scan += [pscustomobject]@{ Index=$i+1; Target=$t; Size=$sizeText; Note=$t.Note; Admin=$t.Admin }
    }
    Write-Host ''
    foreach ($row in $scan) { Write-Host ("[{0}] {1} - {2} {3}" -f $row.Index,$row.Target.Label,$row.Size,$(if($row.Admin){'[admin]'}else{''})) }
    Write-Host ("`nTOTAL reclaimable: {0:N1} MB (Recycle Bin size unknown)." -f ($totalBytes/1MB))
    foreach ($row in $scan) { if ($row.Target.Note) { Write-Host "  $($row.Target.Label): $($row.Target.Note)" } }
    $auditPath = Join-Path $script:RunDirectory ('CacheCleaner-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
    [IO.File]::WriteAllText($auditPath,"CTRLKirk cache cleaner audit log - $((Get-Date).ToString('o'))`r`n")
    $choice = Read-Host 'Type DELETE ALL to clean every listed category, a category number for just that one, or Enter to cancel'
    $selected = @()
    if ($choice -ceq 'DELETE ALL') {
        $selected = @($scan | Where-Object { $_.Size -ne 'SKIPPED (needs admin)' })
        if (@($selected | Where-Object { $_.Target.Id -eq 'fivem' }).Count) {
            if ((Read-Host 'FiveM data will be permanently deleted and re-downloaded on next launch. Type FIVEM to include it, or Enter to skip it') -cne 'FIVEM') {
                $selected = @($selected | Where-Object { $_.Target.Id -ne 'fivem' })
            }
        }
    } else {
        $number = 0
        if ([int]::TryParse($choice,[ref]$number)) { $selected = @($scan | Where-Object { $_.Index -eq $number -and $_.Size -ne 'SKIPPED (needs admin)' }) }
    }
    if (-not $selected.Count) { Add-Result 'Cache cleaner' 'Cancelled' 'No categories selected; nothing deleted.'; return }
    foreach ($row in $selected) {
        $t = $row.Target
        if ($t.Kind -eq 'RecycleBin') {
            if ((Read-Host 'This permanently deletes ALL Recycle Bin contents with no undo. Type EMPTY BIN to continue') -cne 'EMPTY BIN') { continue }
            try {
                Clear-RecycleBin -Force -ErrorAction Stop
                [IO.File]::AppendAllText($auditPath,"EMPTIED`t0`tRecycle Bin`r`n")
                Add-Result $t.Label 'Finished' 'Recycle Bin emptied.'
            } catch { Add-Result $t.Label 'Error' $_.Exception.Message }
            continue
        }
        $result = Remove-CacheFiles $t.Roots $auditPath
        $reclaimed = '{0:N1} MB' -f ($result.Bytes/1MB)
        [IO.File]::AppendAllText($auditPath,"SUMMARY`t$($result.Bytes)`t$($result.Deleted) files deleted, $($result.Skipped) skipped`t$($t.Label)`r`n")
        Add-Result $t.Label 'Finished' ("Deleted {0} files ({1}); {2} locked/changed files skipped. Every deletion is logged in the audit file." -f $result.Deleted,$reclaimed,$result.Skipped)
    }
    foreach ($disk in @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3')) {
        $delta = $disk.FreeSpace - $before[$disk.DeviceID]
        Add-Result ('Free space ' + $disk.DeviceID.TrimEnd(':')) 'Measured' ('{0:N1} GB free now ({1:N1} MB change during this run; other activity also affects this)' -f ($disk.FreeSpace/1GB),($delta/1MB))
    }
    Add-Result 'Cache cleaner audit' 'Saved' $auditPath
}

function Show-CacheDeepScan {
    Write-Host 'DEEP SCAN - read only size ranking of AppData folders; nothing is deleted'
    Write-Host 'This walks every file under Local and Roaming AppData and can take several minutes.'
    if ((Read-Host 'Type SCAN to begin') -cne 'SCAN') { return }
    $rows = @()
    foreach ($base in @(@{Path=$env:LOCALAPPDATA;Tag='Local'},@{Path=$env:APPDATA;Tag='Roaming'})) {
        foreach ($dir in @(Get-ChildItem -LiteralPath $base.Path -Directory -Force -ErrorAction SilentlyContinue | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0 })) {
            $bytes = 0L
            foreach ($file in @(Get-ChildItem -LiteralPath $dir.FullName -Recurse -File -Force -ErrorAction SilentlyContinue)) {
                if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) { $bytes += $file.Length }
            }
            $rows += [pscustomobject]@{ Location=$base.Tag; Folder=$dir.Name; Path=$dir.FullName; MB=[math]::Round($bytes/1MB,1) }
        }
    }
    $top = @($rows | Sort-Object MB -Descending | Select-Object -First 20)
    $top | Format-Table Location,Folder,MB -AutoSize | Out-Host
    $csv = Join-Path $script:RunDirectory 'CacheDeepScan.csv'
    $top | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
    Add-Result 'Deep scan' 'Finished' ("Top {0} AppData folders by size saved to CacheDeepScan.csv. This is a read-only ranking - review before uninstalling or moving anything; large folders are not automatically junk." -f $top.Count)
}

function Invoke-FeatureMode($Feature, [bool]$Preview) {
    switch ($Feature) {
        'Dashboard' { Show-Dashboard }
        'Startup' { Show-StartupTools $Preview }
        'Cleanup' { Show-CleanupTools $Preview }
        'Maintenance' { Show-MaintenanceTools $Preview }
        'Tools' { Show-RecommendedTools $Preview }
        'Health' { Show-SystemHealth }
        'CacheCleaner' { Show-CacheCleaner $Preview }
    }
}
