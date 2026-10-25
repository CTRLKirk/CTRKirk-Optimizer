[CmdletBinding()]
param(
    [ValidateSet('Standard','Advanced','Auto','Restore','Diagnostics','Preferences','Power','Workbench','Dashboard','Startup','Cleanup','Maintenance','Tools')][string]$Mode = 'Standard',
    [switch]$PreviewOnly,
    [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Testing = $false
$script:Store = @{}
$script:Rows = [System.Collections.Generic.List[object]]::new()
$script:RunDirectory = $null
$script:Journal = $null

function New-Setting($Id, $Label, $Key, $Name, $Value, $Tradeoff, $Advanced = $false) {
    [pscustomobject]@{ Id=$Id; Label=$Label; Key=$Key; Name=$Name; Value=[int]$Value; Kind='DWord'; Tradeoff=$Tradeoff; Advanced=$Advanced }
}

$script:Catalog = @(
    New-Setting 'animations' 'Reduce taskbar animations' 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 0 'Taskbar animations will be reduced. Other visual effects, icons, thumbnails and Explorer layouts stay unchanged.'
    New-Setting 'transparency' 'Disable transparency effects' 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0 'Windows surfaces lose transparency. Appearance changes; a gaming benefit is not guaranteed.'
    New-Setting 'notifications' 'Disable notification toasts' 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications' 'ToastEnabled' 0 'You may miss app alerts, including messages. Keep this unchanged if you rely on alerts.'
    New-Setting 'capture' 'Disable Game DVR capture' 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0 'Game Bar recording/screenshots may stop working. Xbox sign-in and services are not changed by this option.'
    New-Setting 'background-recording' 'Disable background game recording' 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0 'Game capture and recording features may be unavailable. Keep unchanged if you record clips.'
    New-Setting 'edge-startup' 'Disable Edge startup boost' 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'StartupBoostEnabled' 0 'Edge may open more slowly. No browsing data is removed.'
    New-Setting 'edge-background' 'Disable Edge background mode' 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'BackgroundModeEnabled' 0 'Edge extensions/apps may stop working after closing Edge; background notifications may be affected.'
    New-Setting 'web-search' 'Disable web suggestions in Start search' 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1 'Web suggestions/search may disappear. Behavior depends on Windows edition/build.'
    New-Setting 'widgets-button' 'Hide the Widgets taskbar button (per-user)' 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarDa' 0 'Hides the Widgets icon from your taskbar only; the Widgets feature remains installed. Works without administrator rights. Recommended way to turn Widgets off.'
    New-Setting 'widgets' 'Disable Widgets / News feed system policy (fallback)' 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0 'Disables Widgets for all users via policy. Stronger than hiding the button but may be denied on machines where the key is protected; pick N if the per-user option already covers you.'
    New-Setting 'game-mode' 'Enable Windows Game Mode' 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1 'Changes scheduling behavior while gaming. Results vary; this is not an FPS guarantee.'
    New-Setting 'background-apps' 'Restrict background Store apps' 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 1 'May affect app sync, messages and Xbox-related apps. Keep unchanged if you use these features.' $true
    New-Setting 'xbox-auth' 'Disable Xbox authentication service at next start' 'HKLM:\SYSTEM\CurrentControlSet\Services\XblAuthManager' 'Start' 4 'BREAKS Xbox sign-in, Game Bar social or games depending on Xbox. Choose N if you use Xbox friends.' $true
    New-Setting 'xbox-save' 'Disable Xbox game-save service at next start' 'HKLM:\SYSTEM\CurrentControlSet\Services\XblGameSave' 'Start' 4 'Xbox cloud saves and games depending on them may fail. No service is stopped now. Choose N to keep Xbox.' $true
    New-Setting 'xbox-network' 'Disable Xbox networking service at next start' 'HKLM:\SYSTEM\CurrentControlSet\Services\XboxNetApiSvc' 'Start' 4 'May break Xbox multiplayer/party features. Choose N if you use Xbox friends or multiplayer.' $true
)

$script:Catalog += @(
    [pscustomobject]@{ Id='power-balanced'; Label='Use existing Balanced power plan'; Key='Power:'; Name='ActiveScheme'; Value='381b4222-f694-41f0-9685-ff5bb260df2e'; Kind='PowerScheme'; Tradeoff='Balanced adjusts CPU speed to demand. Only switches an existing plan; no sleep, battery or hibernation settings are edited.'; Advanced=$true }
    [pscustomobject]@{ Id='power-performance'; Label='Use existing High Performance power plan'; Key='Power:'; Name='ActiveScheme'; Value='8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'; Kind='PowerScheme'; Tradeoff='May increase heat, fan noise and battery drain, and can worsen thermal throttling. Only available if the OEM exposes this plan. No plan is created.'; Advanced=$true }
)
. (Join-Path $PSScriptRoot 'OptimizerPaths.ps1')
. (Join-Path $PSScriptRoot 'OptimizerFeatures.ps1')

function Write-Event($Event, $Id, $Message) {
    $record = [ordered]@{ Time=(Get-Date).ToString('o'); Event=$Event; Id=$Id; Message=$Message }
    if ($script:RunDirectory) {
        ($record | ConvertTo-Json -Compress) | Add-Content -LiteralPath (Join-Path $script:RunDirectory 'Developer.jsonl') -Encoding UTF8 -ErrorAction Stop
    }
}

function Add-Result($Label, $Status, $Detail) {
    $script:Rows.Add([pscustomobject]@{ Label=$Label; Status=$Status; Detail=$Detail })
    Write-Host ('[{0}] {1}: {2}' -f $Status,$Label,$Detail)
    Write-Event $Status $Label $Detail
}

function Get-ValueState($Setting) {
    if ($script:Testing) {
        if ($script:Store.ContainsKey($Setting.Id)) { return $script:Store[$Setting.Id] }
        return [pscustomobject]@{ Exists=$false; Kind=$null; Value=$null }
    }
    if ($Setting.Kind -eq 'PowerScheme') {
        $output = & "$env:SystemRoot\System32\powercfg.exe" /getactivescheme
        if ($LASTEXITCODE -ne 0) { throw 'Cannot read active power scheme.' }
        $id = [regex]::Match(($output -join ' '),'[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}').Value
        if (-not $id) { throw 'Power scheme output did not contain a valid GUID.' }
        return [pscustomobject]@{ Exists=$true; Kind='PowerScheme'; Value=$id.ToLowerInvariant() }
    }
    $key = Get-Item -LiteralPath $Setting.Key -ErrorAction SilentlyContinue
    if ($null -eq $key) {
        if (Test-Path -LiteralPath $Setting.Key) { throw "Cannot read registry key: $($Setting.Key)" }
        return [pscustomobject]@{ Exists=$false; Kind=$null; Value=$null }
    }
    try {
        if ($key.GetValueNames() -notcontains $Setting.Name) { return [pscustomobject]@{ Exists=$false; Kind=$null; Value=$null } }
        [pscustomobject]@{ Exists=$true; Kind=$key.GetValueKind($Setting.Name).ToString(); Value=$key.GetValue($Setting.Name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) }
    } finally { $key.Close() }
}

function Test-SameState($A, $B) {
    if ([bool]$A.Exists -ne [bool]$B.Exists) { return $false }
    if (-not $A.Exists) { return $true }
    if ($A.Kind -ne $B.Kind) { return $false }
    return (($A.Value | ConvertTo-Json -Compress) -ceq ($B.Value | ConvertTo-Json -Compress))
}

function Get-DesiredState($Setting) {
    [pscustomobject]@{ Exists=$true; Kind=$Setting.Kind; Value=$Setting.Value }
}

function Set-ValueState($Setting, $State) {
    if ($script:Testing) {
        $script:Store[$Setting.Id] = $State
        return
    }
    if ($Setting.Kind -eq 'PowerScheme') {
        $guid = [guid]::Parse([string]$State.Value).ToString()
        if ($guid -notin @(Get-PowerPlans | ForEach-Object { $_.Id })) { throw 'Requested power plan no longer exists; no replacement plan will be created.' }
        Invoke-NativeLogged "$env:SystemRoot\System32\powercfg.exe" @('/setactive',$guid) 'Power plan switch'
        return
    }
    if (-not $State.Exists) {
        $parts = $Setting.Key -split ':\\',2
        $hive = if ($parts[0] -eq 'HKCU') { [Microsoft.Win32.Registry]::CurrentUser } else { [Microsoft.Win32.Registry]::LocalMachine }
        $key = $hive.OpenSubKey($parts[1],$true)
        if ($key) {
            try { $key.DeleteValue($Setting.Name,$false) } finally { $key.Close() }
        }
        return
    }
    if (-not (Test-Path -LiteralPath $Setting.Key)) { New-Item -Path $Setting.Key -Force | Out-Null }
    $parts = $Setting.Key -split ':\\',2
    $hive = if ($parts[0] -eq 'HKCU') { [Microsoft.Win32.Registry]::CurrentUser } else { [Microsoft.Win32.Registry]::LocalMachine }
    $key = $hive.OpenSubKey($parts[1],$true)
    if (-not $key) { throw "Cannot open registry key for writing: $($Setting.Key)" }
    try {
        $value = $State.Value
        switch ($State.Kind) {
            'DWord' { $value = [int]$value }
            'QWord' { $value = [long]$value }
            'Binary' { $value = [byte[]]$value }
            'MultiString' { $value = [string[]]$value }
            'String' { $value = [string]$value }
            'ExpandString' { $value = [string]$value }
            default { throw "Unsupported registry type: $($State.Kind)" }
        }
        $key.SetValue($Setting.Name,$value,[Microsoft.Win32.RegistryValueKind]::$($State.Kind))
    } finally { $key.Close() }
}

function Save-Journal {
    $path = Join-Path $script:RunDirectory 'Snapshot.clixml'
    $temporary = Join-Path $script:RunDirectory 'Snapshot.pending'
    $script:Journal | Export-Clixml -LiteralPath $temporary -Depth 12
    if (Test-Path -LiteralPath $path) { [IO.File]::Replace($temporary,$path,(Join-Path $script:RunDirectory 'Snapshot.previous')) }
    else { [IO.File]::Move($temporary,$path) }
}

function Invoke-Setting($Setting) {
    Write-Event 'ReadBefore' $Setting.Id 'Reading original value before any write'
    if ($Setting.Key -like '*\Services\*' -and -not $script:Testing -and -not (Test-Path -LiteralPath $Setting.Key)) {
        Add-Result $Setting.Label 'Skipped' 'Service is not installed; no key was created.'
        return
    }
    $before = Get-ValueState $Setting
    $after = Get-DesiredState $Setting
    if (Test-SameState $before $after) {
        Add-Result $Setting.Label 'Unchanged' 'Already has the requested value.'
        Write-Event 'Unchanged' $Setting.Id 'Already configured; not added to restoration journal'
        return
    }
    if ($before.Exists -and $before.Kind -ne $Setting.Kind) { throw "Unexpected value type for $($Setting.Id); not changing it." }
    $entry = [pscustomobject]@{ Id=$Setting.Id; Before=$before; After=$after; Status='Pending' }
    $script:Journal.Entries.Add($entry)
    Save-Journal
    Write-Event 'WriteStarting' $Setting.Id 'Original value saved durably; attempting change'
    if (-not (Test-SameState (Get-ValueState $Setting) $before)) { throw "Value changed while planning $($Setting.Id); stopped without overwriting it." }
    Set-ValueState $Setting $after
    if (-not (Test-SameState (Get-ValueState $Setting) $after)) { throw "Read-back verification failed: $($Setting.Id)" }
    $entry.Status = 'Applied'
    Save-Journal
    Write-Event 'Applied' $Setting.Id 'Read-back matches requested value; Windows may require sign-out/restart to honor it'
    Add-Result $Setting.Label 'Applied' 'Saved setting verified by read-back. Effective behavior depends on Windows; some changes need sign-out/restart.'
}

function Assert-Journal($Journal) {
    if ($Journal.Version -ne 1) { throw 'Unsupported snapshot version.' }
    if (-not $script:Testing -and ($Journal.Computer -ne $env:COMPUTERNAME -or $Journal.User -ne [Security.Principal.WindowsIdentity]::GetCurrent().User.Value)) {
        throw 'This snapshot belongs to another computer or Windows account. Restoration blocked.'
    }
    $seen = @{}
    foreach ($entry in $Journal.Entries) {
        $setting = @($script:Catalog | Where-Object Id -EQ $entry.Id)
        if ($setting.Count -ne 1 -or $seen.ContainsKey($entry.Id)) { throw 'Unknown or duplicate snapshot setting. Restoration blocked.' }
        $seen[$entry.Id] = $true
        if (-not (Test-SameState $entry.After (Get-DesiredState $setting[0]))) { throw 'Snapshot desired value is invalid.' }
        if ($entry.Before.Exists -and $entry.Before.Kind -ne $setting[0].Kind) { throw 'Snapshot original type is invalid.' }
        if ($setting[0].Kind -eq 'PowerScheme') {
            if (-not $entry.Before.Exists) { throw 'Power snapshot is missing its original scheme.' }
            $null = [guid]::Parse([string]$entry.Before.Value)
        } elseif ($entry.Before.Exists) { $null = [int]$entry.Before.Value }
        if ($entry.Status -notin @('Pending','Applied','Restored','AlreadyRestored','Conflict','Error')) { throw 'Invalid journal status.' }
    }
}

function Restore-Journal($Journal) {
    Assert-Journal $Journal
    $entries = @($Journal.Entries)
    [array]::Reverse($entries)
    foreach ($entry in $entries) {
        $setting = $script:Catalog | Where-Object Id -EQ $entry.Id
        Write-Event 'RestoreStarting' $entry.Id 'Comparing current value to original and optimizer value'
        $current = Get-ValueState $setting
        if (Test-SameState $current $entry.Before) {
            $entry.Status = 'AlreadyRestored'
            Add-Result $setting.Label 'Unchanged' 'Already matches the saved original value.'
        } elseif (-not (Test-SameState $current $entry.After)) {
            $entry.Status = 'Conflict'
            Add-Result $setting.Label 'Conflict' 'Changed since this run. Left untouched to preserve newer settings.'
        } else {
            Set-ValueState $setting $entry.Before
            if (-not (Test-SameState (Get-ValueState $setting) $entry.Before)) { throw "Restore verification failed: $($entry.Id)" }
            $entry.Status = 'Restored'
            Add-Result $setting.Label 'Restored' 'Saved original value/type restored; originally absent values removed individually.'
        }
        Save-Journal
        Write-Event $entry.Status $entry.Id 'Restore step finished'
    }
}

function Get-Metrics {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        [pscustomobject]@{ AvailableMB=[math]::Round($os.FreePhysicalMemory/1024); Processes=@(Get-Process).Count }
    } catch {
        Write-Event 'MetricsUnavailable' '' $_.Exception.Message
        [pscustomobject]@{ AvailableMB='Unavailable'; Processes='Unavailable' }
    }
}

function Write-Report($Before, $After, $Outcome) {
    $encode = { param($text) [System.Net.WebUtility]::HtmlEncode([string]$text) }
    $body = foreach ($row in $script:Rows) {
        '<tr><td>{0}</td><td>{1}</td><td>{2}</td></tr>' -f (& $encode $row.Label),(& $encode $row.Status),(& $encode $row.Detail)
    }
    $summary = & $encode $Outcome
    $metrics = if ($null -ne $Before -and $null -ne $After) {
        "Available RAM: $($Before.AvailableMB) MB before / $($After.AvailableMB) MB after. Processes: $($Before.Processes) before / $($After.Processes) after."
    } else { 'No performance measurements taken.' }
    @"
<!doctype html><html lang="en"><meta charset="utf-8"><title>CTRLKirk run report</title>
<style>body{font:16px Segoe UI,sans-serif;background:#101827;color:#e9eef7;max-width:1000px;margin:40px auto;padding:24px}h1{color:#7dd3fc}table{width:100%;border-collapse:collapse}td,th{padding:14px;border-bottom:1px solid #40506b;text-align:left}p{line-height:1.6}</style>
<h1>CTRLKirk Optimizer</h1><h2>$summary</h2><p>$metrics</p>
<p>These are momentary system readings, NOT an FPS benchmark or proof of improvement. Only actions listed below were requested. Settings apply/restore never deletes files or weakens security. Cleanup, maintenance and external tools have separate consent and cannot be undone through registry snapshots.</p>
<table><tr><th>Setting</th><th>Result</th><th>Details / tradeoff</th></tr>$($body -join "`n")</table>
<p>Developer.jsonl records each step and errors. Snapshot.clixml stores original values for applied runs. Restore through menu 5; do not edit snapshot files. Only successfully read-back values are marked Applied. A saved value does not prove Windows honors that policy.</p></html>
"@ | Set-Content -LiteralPath (Join-Path $script:RunDirectory 'Report.html') -Encoding UTF8
}

function Get-Plan($Ids) {
    $unknown = @($Ids | Where-Object { $_ -notin $script:Catalog.Id })
    if ($unknown.Count) { throw 'Profile contains unknown settings; refusing to apply it.' }
    $selected = @($script:Catalog | Where-Object { $_.Id -in $Ids })
    if (@($selected | Where-Object Kind -EQ 'PowerScheme').Count -gt 1) { throw 'Choose only one power plan per run.' }
    $selected
}

function Invoke-SelfTests {
    $script:Testing = $true
    $script:RunDirectory = New-FriendlyRunDirectory ([IO.Path]::GetTempPath()) 'CTRLKirk Safety Test'
    $script:Journal = [pscustomobject]@{ Version=1; Computer='Test'; User='Test'; Entries=[System.Collections.Generic.List[object]]::new() }
    $s = $script:Catalog[0]
    $original = [pscustomobject]@{ Exists=$true; Kind='DWord'; Value=7 }
    $script:Store[$s.Id] = $original
    Invoke-Setting $s
    if (-not (Test-Path -LiteralPath (Join-Path $script:RunDirectory 'Snapshot.clixml'))) { throw 'Missing durable snapshot' }
    Restore-Journal $script:Journal
    if (-not (Test-SameState (Get-ValueState $s) $original)) { throw 'Original value not restored' }
    $script:Store.Clear(); $script:Journal.Entries.Clear()
    Invoke-Setting $s
    Restore-Journal $script:Journal
    if ((Get-ValueState $s).Exists) { throw 'Originally absent value not removed' }
    $script:Store.Clear(); $script:Journal.Entries.Clear()
    $script:Store[$s.Id] = Get-DesiredState $s
    Invoke-Setting $s
    if ($script:Journal.Entries.Count -ne 0) { throw 'Already matching value should not be journaled' }
    $script:Store.Clear(); $script:Journal.Entries.Clear()
    Invoke-Setting $s
    $script:Store[$s.Id] = $original
    Restore-Journal $script:Journal
    if ($script:Journal.Entries[0].Status -ne 'Conflict') { throw 'Conflict was not detected' }
    if (-not (Test-SameState (Get-ValueState $s) $original)) { throw 'Conflict overwritten' }
    $script:Store[$s.Id] = Get-DesiredState $s
    $script:Journal.Entries[0].Status = 'Pending'
    Restore-Journal $script:Journal
    if ((Get-ValueState $s).Exists) { throw 'Interrupted write was not recoverable' }
    $loaded = Import-Clixml -LiteralPath (Join-Path $script:RunDirectory 'Snapshot.clixml')
    Assert-Journal $loaded
    $loaded.Entries[0].Id = 'unknown'
    $rejected = $false
    try { Assert-Journal $loaded } catch { $rejected = $true }
    if (-not $rejected) { throw 'Invalid snapshot accepted' }
    if (@(Get-Plan @()).Count -ne 0) { throw 'Empty plan is not empty' }
    $rejected = $false
    try { $null = Get-Plan @('unknown') } catch { $rejected = $true }
    if (-not $rejected) { throw 'Unknown profile option accepted' }
    $script:Store.Clear(); $script:Journal.Entries.Clear()
    $validDirectory = $script:RunDirectory
    $script:RunDirectory = Join-Path $validDirectory 'MissingDirectory'
    $rejected = $false
    try { Invoke-Setting $s } catch { $rejected = $true }
    $script:RunDirectory = $validDirectory
    if (-not $rejected -or (Get-ValueState $s).Exists) { throw 'Logging failure did not stop the write' }
    $blockedSnapshot = Join-Path $validDirectory 'Snapshot.pending'
    New-Item -ItemType Directory -Path $blockedSnapshot | Out-Null
    $rejected = $false
    try { Invoke-Setting $s } catch { $rejected = $true }
    Remove-Item -LiteralPath $blockedSnapshot
    if (-not $rejected -or (Get-ValueState $s).Exists) { throw 'Snapshot failure did not stop the write' }
    $script:Journal.Entries.Clear()
    $script:Testing = $false
    $testKey = 'HKCU:\Software\CTRLKirkOptimizerTest_' + [guid]::NewGuid().ToString('N')
    $testSetting = New-Setting 'registry-test' 'Isolated registry test' $testKey 'SyntheticValue' 0 'Test only'
    New-Item -Path $testKey | Out-Null
    try {
        New-ItemProperty -LiteralPath $testKey -Name 'Unrelated' -Value 99 -PropertyType DWord | Out-Null
        $absent = Get-ValueState $testSetting
        Set-ValueState $testSetting (Get-DesiredState $testSetting)
        if (-not (Test-SameState (Get-ValueState $testSetting) (Get-DesiredState $testSetting))) { throw 'Native registry write failed' }
        Set-ValueState $testSetting $original
        if (-not (Test-SameState (Get-ValueState $testSetting) $original)) { throw 'Native original value restore failed' }
        Set-ValueState $testSetting $absent
        if ((Get-ValueState $testSetting).Exists) { throw 'Native absent-value restore failed' }
        if ((Get-ItemPropertyValue -LiteralPath $testKey -Name 'Unrelated') -ne 99) { throw 'Unrelated value changed' }
    } finally { Remove-Item -LiteralPath $testKey }
    Write-Report $null $null 'Self-tests passed'
    Write-Host "PASS: original values, absent values, no-op, conflicts, interrupted writes, serialization, invalid snapshot, empty plan and native registry writes on a disposable test key. Artifacts: $script:RunDirectory"
}

if ($SelfTest) {
    Invoke-SelfTests
    return
}

$beforeMetrics = $null
$afterMetrics = $null
$outcome = 'Stopped before making changes'
$failed = $false
try {
    $root = Join-Path $PSScriptRoot 'Logs\Safety Runs'
    $script:RunDirectory = New-FriendlyRunDirectory $root 'Safety Run'
    Write-Event 'SessionStarted' '' "Mode=$Mode PreviewOnly=$PreviewOnly"
    Write-Host "Logs and report: $script:RunDirectory"
    $beforeMetrics = Get-Metrics
    if ($Mode -eq 'Workbench') {
        Write-Host 'LAPTOP WORKBENCH'
        Write-Host '[1] Dashboard / measurements [2] Startup and apps [3] Temporary-file cleanup'
        Write-Host '[4] Windows repair / network troubleshooting [5] Laptop power plans [6] Saved preferences [0] Back'
        if ($PreviewOnly) { $outcome = 'Workbench menu preview; no system changes'; return }
        $target = switch (Read-Host 'Choice') { '1' { 'Dashboard' } '2' { 'Startup' } '3' { 'Cleanup' } '4' { 'Maintenance' } '5' { 'Power' } '6' { 'Preferences' } default { '' } }
        if (-not $target) { $outcome = 'Workbench cancelled; no system changes'; return }
        $Mode = $target
        Write-Event 'WorkbenchSelection' '' $Mode
    }
    if ($Mode -in @('Dashboard','Startup','Cleanup','Maintenance','Tools')) {
        Invoke-FeatureMode $Mode ([bool]$PreviewOnly)
        $outcome = "$Mode workflow finished; review individual results"
        return
    }
    if ($Mode -eq 'Diagnostics') {
        Write-Host 'Read-only diagnostics: no registry or system changes.'
        Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer,Model,TotalPhysicalMemory | Format-List | Out-Host
        Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion | Format-Table | Out-Host
        Add-Result 'Safety policy' 'Information' 'Legacy cleanup, registry stress writes, Defender exclusions and security-disabling tweaks are blocked.'
        $outcome = 'Read-only diagnostics complete'
        return
    }
    if ($Mode -eq 'Restore') {
        $snapshots = @(Get-SnapshotRuns @($root,(Join-Path $PSScriptRoot 'SafetyRuns')) | Sort-Object CreationTimeUtc -Descending)
        if (-not $snapshots.Count) { Write-Host 'No new-format snapshots. Legacy .reg backups are NOT safe automatic undo files.'; return }
        for ($i=0; $i -lt $snapshots.Count; $i++) { Write-Host ('[{0}] {1}' -f ($i+1),$snapshots[$i].Name) }
        $answer = Read-Host 'Snapshot number to inspect, or Enter to cancel'
        $number = 0
        if (-not [int]::TryParse($answer,[ref]$number) -or $number -lt 1 -or $number -gt $snapshots.Count) { return }
        $source = Join-Path $snapshots[$number-1].FullName 'Snapshot.clixml'
        $script:Journal = Import-Clixml -LiteralPath $source
        Assert-Journal $script:Journal
        foreach ($entry in $script:Journal.Entries) {
            $setting = $script:Catalog | Where-Object Id -EQ $entry.Id
            Add-Result $setting.Label 'Restore preview' 'Will compare current value and restore original only if safe; newer conflicting values stay untouched.'
        }
        Save-Journal
        if ($PreviewOnly -or (Read-Host 'Type RESTORE to restore ONLY the listed values') -cne 'RESTORE') { $outcome = 'Restore preview only; no system changes'; return }
        $principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
        $restoreIds = @($script:Journal.Entries | ForEach-Object { $_.Id })
        $restorePlan = @($script:Catalog | Where-Object { $_.Id -in $restoreIds })
        if (@($restorePlan | Where-Object { $_.Key -like 'HKLM:*' }).Count -and -not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw 'This restoration needs administrator access. No values restored. Run the BAT as administrator and review again.'
        }
        Restore-Journal $script:Journal
        $outcome = 'Restore finished; inspect each result for conflicts'
        return
    }
    $profileRoot = Join-Path $PSScriptRoot '.devin\profiles'
    $profilePath = $null
    $ids = @()
    $createProfile = $Mode -eq 'Preferences'
    $savedProfile = $false
    if ($Mode -in @('Standard','Advanced','Preferences') -and -not $PreviewOnly) {
        $sourceChoice = Get-PreferenceSource $profileRoot
        if ($sourceChoice.Action -eq 'Cancel' -or ($sourceChoice.Action -eq 'Load' -and -not $sourceChoice.Path)) { $outcome = 'Preference selection cancelled; no system changes'; return }
        $profilePath = $sourceChoice.Path
        $createProfile = $createProfile -or $sourceChoice.Action -eq 'New'
    }
    if ($Mode -eq 'Auto') {
        Write-Host 'AUTO is preview-only. It never bypasses consent or applies settings unattended.'
        if ($PreviewOnly) {
            $profiles = @(Get-SavedPreferences $profileRoot)
            if ($profiles.Count) { $profilePath = $profiles[0].FullName }
        } else { $profilePath = Select-Preference $profileRoot }
    }
    if ($profilePath -or $Mode -eq 'Auto') {
        if ($profilePath) {
            $ids = [string[]](Import-Clixml -LiteralPath $profilePath)
            Add-Result 'Saved preference' 'Loaded' ([IO.Path]::GetFileNameWithoutExtension($profilePath) + ': selected choices loaded; all other settings remain untouched. APPLY is still required outside AUTO.')
        }
    } elseif ($Mode -eq 'Power') {
        $available = @(Get-PowerPlans)
        $available | Format-Table Name,Id | Out-Host
        $state = Get-ValueState ($script:Catalog | Where-Object Id -EQ 'power-balanced')
        Add-Result 'Current power plan' 'Read only' $state.Value
        Write-Host 'OEM/Modern Standby laptops may expose only Balanced. No plans are created or duplicated.'
        Write-Host 'High Performance can increase heat and battery use and may lower sustained performance. Balanced is usually the sensible starting point.'
        $options = @($script:Catalog | Where-Object { $_.Kind -eq 'PowerScheme' -and $_.Value -in $available.Id })
        for ($i=0; $i -lt $options.Count; $i++) { Write-Host "[$($i+1)] $($options[$i].Label) - $($options[$i].Tradeoff)" }
        $number = 0
        if ([int]::TryParse((Read-Host 'Plan number to preview, or Enter to keep current'),[ref]$number) -and $number -gt 0 -and $number -le $options.Count) { $ids = @($options[$number-1].Id) }
    } else {
        Write-Host 'Every option defaults to KEEP UNCHANGED. Only Y selects a change. Enter or N preserves your setting.'
        Write-Host 'No automatic app closing, file cleanup, security weakening, memory purge, power changes or restart.'
        foreach ($setting in $script:Catalog) {
            if ($setting.Kind -eq 'PowerScheme') { continue }
            if ($setting.Advanced -and $Mode -notin @('Advanced','Preferences')) { continue }
            Write-Host "`n$($setting.Label)"
            Write-Host "Tradeoff: $($setting.Tradeoff)"
            $answer = Read-Host 'Change this setting? [y/N]'
            if ($answer -match '^(?i)y(es)?$') { $ids += $setting.Id }
        }
    }
    $plan = @(Get-Plan $ids)
    foreach ($setting in $script:Catalog) {
        if ($setting.Id -notin $ids) { Add-Result $setting.Label 'Kept' 'Not selected; current setting will not be touched.' }
    }
    Write-Host "`nPLAN: $($plan.Count) selected value changes. No settings have been written."
    foreach ($setting in $plan) {
        $state = Get-ValueState $setting
        $description = if ($state.Exists) { "$($state.Kind) value $($state.Value)" } else { 'value absent' }
        Add-Result $setting.Label 'Preview' ("Current: $description. Proposed: $($setting.Value). " + $setting.Tradeoff)
    }
    Write-Event 'PlanReady' '' ($ids -join ',')
    if ($createProfile -and -not $PreviewOnly) {
        if ((Read-Host 'Type SAVE to name and save these choices without applying them, or Enter to skip saving') -ceq 'SAVE') {
            $savedProfile = Save-NamedPreferences $ids $profileRoot
        }
        if ($Mode -eq 'Preferences') {
            $outcome = if ($savedProfile) { 'Named preference saved; no system changes' } else { 'Preference editing cancelled; no system changes' }
            return
        }
    }
    if ($PreviewOnly -or $Mode -eq 'Auto' -or -not $plan.Count) { $outcome = 'Preview complete; no system changes'; return }
    $confirm = Read-Host 'Type APPLY to write this exact plan, SAVE to save a named preference only, or Enter to finish preview'
    if ($confirm -ceq 'SAVE') {
        $savedProfile = Save-NamedPreferences $ids $profileRoot
        $outcome = if ($savedProfile) { 'Named preference saved; no system changes' } else { 'Preview complete; no system changes' }
        return
    }
    if ($confirm -cne 'APPLY') { $outcome = 'Preview complete; no system changes'; return }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (@($plan | Where-Object { $_.Key -like 'HKLM:*' }).Count -and -not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'This plan needs administrator access. No values changed. Close and run the BAT as administrator, then review the plan again.'
    }
    $script:Journal = [pscustomobject]@{ Version=1; Computer=$env:COMPUTERNAME; User=$identity.User.Value; Entries=[System.Collections.Generic.List[object]]::new() }
    Save-Journal
    $hadErrors = $false
    foreach ($setting in $plan) {
        try { Invoke-Setting $setting }
        catch {
            $hadErrors = $true
            foreach ($e in @($script:Journal.Entries | Where-Object { $_.Id -eq $setting.Id -and $_.Status -eq 'Pending' })) { $e.Status = 'Error' }
            Save-Journal
            Write-Event 'SettingError' $setting.Id $_.Exception.Message
            $hint = if ($setting.Key -like 'HKLM:*') { ' This system-wide key needs administrator rights or may be protected by security software.' } else { '' }
            Add-Result $setting.Label 'Error' "Not changed: $($_.Exception.Message)$hint Remaining settings continue; run Restore from menu 5 to undo anything applied before this."
        }
    }
    $outcome = if ($hadErrors) { 'Apply finished with errors; review per-setting results' } else { 'Apply finished; review individual results' }
    if (-not $savedProfile -and (Read-Host 'Save these choices as a named preference for next time? [y/N]') -match '^(?i)y(es)?$') {
        $null = Save-NamedPreferences $ids $profileRoot
    }
} catch {
    $outcome = 'Stopped on error; review Developer.jsonl before proceeding'
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($script:RunDirectory) {
        Write-Event 'Error' '' $_.Exception.ToString()
        Add-Result 'Run stopped' 'Error' 'No further changes attempted. Already-written values have a snapshot; use menu 5 to inspect recovery.'
    }
    $failed = $true
} finally {
    if ($script:RunDirectory) {
        $afterMetrics = Get-Metrics
        Write-Report $beforeMetrics $afterMetrics $outcome
        Write-Event 'SessionFinished' '' $outcome
        Write-Host "`n$outcome"
        Write-Host "User report: $(Join-Path $script:RunDirectory 'Report.html')"
        Write-Host "Developer log: $(Join-Path $script:RunDirectory 'Developer.jsonl')"
    }
}
if ($failed) { exit 1 }
