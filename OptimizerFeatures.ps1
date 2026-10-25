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

function Invoke-FeatureMode($Feature, [bool]$Preview) {
    switch ($Feature) {
        'Dashboard' { Show-Dashboard }
        'Startup' { Show-StartupTools $Preview }
        'Cleanup' { Show-CleanupTools $Preview }
        'Maintenance' { Show-MaintenanceTools $Preview }
        'Tools' { Show-RecommendedTools $Preview }
    }
}
