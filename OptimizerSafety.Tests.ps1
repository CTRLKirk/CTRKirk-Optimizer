Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True($Condition, $Message) {
    if (-not $Condition) { throw $Message }
}

function Invoke-PreviewProcess($Mode, $Answers) {
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $info.Arguments = '-NoProfile -File "' + (Join-Path $PSScriptRoot 'OptimizerSafety.ps1') + '" -Mode ' + $Mode + ' -PreviewOnly'
    $info.UseShellExecute = $false
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $process = [Diagnostics.Process]::Start($info)
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    foreach ($answer in $Answers) { $process.StandardInput.WriteLine($answer) }
    $process.StandardInput.Close()
    if (-not $process.WaitForExit(90000)) {
        $process.Kill()
        throw "Preview test timed out: $Mode"
    }
    $output = $stdout.Result
    $errors = $stderr.Result
    Assert-True ($process.ExitCode -eq 0) "Preview failed: $Mode $errors $output"
    Assert-True ([string]::IsNullOrEmpty($errors)) "Unexpected preview stderr: $errors"
    return $output
}

. (Join-Path $PSScriptRoot 'OptimizerSafety.ps1') -SelfTest
$before = @{}
foreach ($setting in $script:Catalog) { $before[$setting.Id] = Get-ValueState $setting }

$standard = Invoke-PreviewProcess 'Standard' (@('N') * 20)
Assert-True ($standard -match 'PLAN: 0 selected') 'Decline-all standard preview did not preserve everything'
$advanced = Invoke-PreviewProcess 'Advanced' (@('Y') * 30)
$nonPowerCount = @($script:Catalog | Where-Object { $_.Kind -ne 'PowerScheme' }).Count
Assert-True ($advanced -match "PLAN: $nonPowerCount selected") 'Advanced select-all preview did not include every option'
Assert-True ($advanced -match 'Preview complete; no system changes') 'Advanced preview tried to apply'
$blank = Invoke-PreviewProcess 'Advanced' (@('') * 20)
Assert-True ($blank -match 'PLAN: 0 selected') 'Blank answers did not preserve everything'
$invalid = Invoke-PreviewProcess 'Standard' (@('not-a-choice') * 20)
Assert-True ($invalid -match 'PLAN: 0 selected') 'Invalid answers were treated as consent'
$auto = Invoke-PreviewProcess 'Auto' @()
Assert-True ($auto -match 'AUTO is preview-only') 'AUTO bypassed preview mode'
$powerPreview = Invoke-PreviewProcess 'Power' @('')
Assert-True ($powerPreview -match 'Preview complete; no system changes') 'Power preview did not remain read-only'
$preferencesPreview = Invoke-PreviewProcess 'Preferences' (@('N') * 20)
Assert-True ($preferencesPreview -match 'PLAN: 0 selected') 'Preference preview changed defaults'
$toolsPreview = Invoke-PreviewProcess 'Tools' @()
Assert-True ($toolsPreview -match 'Detected locally:') 'Tool inventory failed'
$startupPreview = Invoke-PreviewProcess 'Startup' @()
Assert-True ($startupPreview -match 'Startup choices') 'Startup inspection failed'
$dashboardPreview = Invoke-PreviewProcess 'Dashboard' @()
Assert-True ($dashboardPreview -match 'Laptop snapshot') 'Dashboard measurements failed'
$workbenchPreview = Invoke-PreviewProcess 'Workbench' @()
Assert-True ($workbenchPreview -match 'Workbench menu preview') 'Workbench preview changed state'
foreach ($setting in $script:Catalog) {
    Assert-True (Test-SameState (Get-ValueState $setting) $before[$setting.Id]) "Preview changed a real setting: $($setting.Id)"
}

$batch = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'CTRLKirk Gaming Optimizer.bat') -Raw
Assert-True ($batch -match '(?m)^goto SAFE_LAUNCH\r?$') 'Launcher safety entry missing'
foreach ($label in @('MENU','RUN_OPTIMIZER','UNDO_MENU','DEV_MENU')) {
    Assert-True ($batch -match (':' + $label + '\r?\ngoto SAFE_')) "Legacy entry is not guarded: $label"
}
$labels = @([regex]::Matches($batch,'(?m)^:([A-Za-z_][A-Za-z_0-9]*)\r?$') | ForEach-Object { $_.Groups[1].Value })
Assert-True (@($labels | Group-Object | Where-Object Count -GT 1).Count -eq 0) 'Duplicate batch labels'
foreach ($match in [regex]::Matches($batch,'(?im)\b(?:goto|call)\s+:?(SAFE_[A-Z_]+)')) {
    Assert-True ($match.Groups[1].Value -in $labels) "Missing safety target: $($match.Groups[1].Value)"
}

function Invoke-BatchTest($Path, $InputText) {
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $env:ComSpec
    $info.Arguments = '/d /c ""' + $Path + '""'
    $info.UseShellExecute = $false
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $process = [Diagnostics.Process]::Start($info)
    $stderr = $process.StandardError.ReadToEndAsync()
    $captured = [Text.StringBuilder]::new()
    if ($InputText.StartsWith('6') -or $InputText.StartsWith('4')) {
        $first = $InputText.Substring(0,1)
        $middle = if ($first -eq '6') { 'Select a tool number, or 0/Enter to return.' } else { 'Select tool:' }
        foreach ($step in @(@('Select an option:',$first),@($middle,'0'),@('Select an option:','0'))) {
            $tail = [Text.StringBuilder]::new()
            while ($tail.ToString().IndexOf($step[0],[StringComparison]::Ordinal) -lt 0) {
                $buffer = New-Object char[] 1
                $read = $process.StandardOutput.ReadAsync($buffer,0,1)
                if (-not $read.Wait(30000) -or $read.Result -eq 0) { $process.Kill(); throw "Batch prompt not reached: $($step[0]); $tail" }
                $null = $tail.Append($buffer[0]); $null = $captured.Append($buffer[0])
            }
            if ($step[0] -eq 'Select a tool number, or 0/Enter to return.') { $process.StandardInput.WriteLine($step[1]) }
            else { $process.StandardInput.Write($step[1]) }
            $process.StandardInput.Flush()
        }
    } else { $process.StandardInput.Write($InputText) }
    $process.StandardInput.Close()
    $stdout = $process.StandardOutput.ReadToEndAsync()
    if (-not $process.WaitForExit(30000)) { $process.Kill(); throw 'Batch menu test timed out' }
    $null = $captured.Append($stdout.Result)
    Assert-True ($process.ExitCode -eq 0) "Batch test failed: $($stderr.Result) $captured"
    return $captured.ToString()
}

$batchPath = Join-Path $PSScriptRoot 'CTRLKirk Gaming Optimizer.bat'
$toolsMenu = Invoke-BatchTest $batchPath "6`r`n0`r`n0`r`n"
Assert-True ($toolsMenu -match 'RECOMMENDED TOOLS') 'Tools menu did not open'
$ramMenu = Invoke-BatchTest $batchPath "4`r`n0`r`n0`r`n"
Assert-True ($ramMenu -match 'RAM & MEMORY TOOLS') 'RAM menu did not open'
$fixtureDirectory = New-FriendlyRunDirectory ([IO.Path]::GetTempPath()) 'CTRLKirk Batch Test'
$helper = [regex]::Match($batch,'(?ms)^:BUILD_RAM_SCRIPT\r?\n(.*?)\r?\ngoto :eof').Groups[1].Value
Assert-True ($helper -notmatch 'powershell|reg add|taskkill') 'Helper-generation fixture contains executable system operations'
$fixture = Join-Path $fixtureDirectory 'BuildHelper.bat'
@('@echo off','setlocal enabledelayedexpansion',('set "CKTMP=' + $fixtureDirectory + '"'),$helper,'exit /b 0') | Set-Content -LiteralPath $fixture -Encoding ASCII
$null = Invoke-BatchTest $fixture ''
$tokens = $null; $parseErrors = $null
$null = [Management.Automation.Language.Parser]::ParseFile((Join-Path $fixtureDirectory 'ck_ram_v2.ps1'),[ref]$tokens,[ref]$parseErrors)
Assert-True (@($parseErrors).Count -eq 0) 'Generated RAM helper does not parse'
$script:Testing = $true
$power = $script:Catalog | Where-Object Id -EQ 'power-performance'
$originalPower = [pscustomobject]@{ Exists=$true; Kind='PowerScheme'; Value='12345678-1234-1234-1234-123456789abc' }
$script:Store[$power.Id] = $originalPower
$script:Journal = [pscustomobject]@{ Version=1; Computer='Test'; User='Test'; Entries=[System.Collections.Generic.List[object]]::new() }
Invoke-Setting $power
Restore-Journal $script:Journal
Assert-True (Test-SameState (Get-ValueState $power) $originalPower) 'Power plan original GUID not restored'
$rejected = $false
try { $null = Get-Plan @('power-balanced','power-performance') } catch { $rejected = $true }
Assert-True $rejected 'Conflicting power plan choices accepted'
$script:Testing = $false

$profile = Join-Path $fixtureDirectory '.devin\profiles\test.clixml'
Save-Preferences @('edge-startup') $profile
$loadedProfile = [string[]](Import-Clixml -LiteralPath $profile)
Assert-True ($loadedProfile.Length -eq 1 -and $loadedProfile[0] -eq 'edge-startup') 'Profile IDs did not round trip'
Save-Preferences @() $profile
$loadedProfile = [string[]](Import-Clixml -LiteralPath $profile)
Assert-True ($loadedProfile.Length -eq 0) 'Empty profile did not clear selections'
$cleanupRoot = Join-Path $fixtureDirectory 'SyntheticTemp'
New-Item -ItemType Directory -Path $cleanupRoot | Out-Null
$oldFile = Join-Path $cleanupRoot 'old.tmp'
$keepFile = Join-Path $cleanupRoot 'keep.tmp'
[IO.File]::WriteAllText($oldFile,'old test data')
[IO.File]::WriteAllText($keepFile,'new test data')
[IO.File]::SetLastWriteTimeUtc($oldFile,[datetime]::UtcNow.AddDays(-10))
[IO.File]::SetLastAccessTimeUtc($oldFile,[datetime]::UtcNow.AddDays(-10))
$candidates = @(Get-CleanupCandidates $cleanupRoot ([datetime]::UtcNow.AddDays(-7)))
Assert-True ($candidates.Count -eq 1) 'Cleanup age filter did not preserve recent file'
$escape = [pscustomobject]@{ Root=$cleanupRoot; Path=(Join-Path $fixtureDirectory 'outside.tmp'); Bytes=1; ModifiedTicks=0; AccessTicks=0 }
Assert-True (-not (Test-CleanupCandidate $escape)) 'Cleanup accepted a path outside its root'
$changedFile = Join-Path $cleanupRoot 'changed.tmp'
[IO.File]::WriteAllText($changedFile,'original')
[IO.File]::SetLastWriteTimeUtc($changedFile,[datetime]::UtcNow.AddDays(-10))
[IO.File]::SetLastAccessTimeUtc($changedFile,[datetime]::UtcNow.AddDays(-10))
$changedCandidate = @(Get-CleanupCandidates $cleanupRoot ([datetime]::UtcNow.AddDays(-7)) | Where-Object Path -EQ $changedFile)[0]
[IO.File]::WriteAllText($changedFile,'changed after preview')
Assert-True (-not (Test-CleanupCandidate $changedCandidate)) 'Changed temp file remained eligible'
$blocked = $false
try { $null = Get-CleanupCandidates $env:USERPROFILE ([datetime]::UtcNow.AddDays(-7)) } catch { $blocked = $true }
Assert-True $blocked 'Cleanup accepted a personal-folder root'
Remove-CleanupPlan @($candidates[0],$changedCandidate)
Assert-True (-not (Test-Path -LiteralPath $oldFile) -and (Test-Path -LiteralPath $keepFile) -and (Test-Path -LiteralPath $changedFile)) 'Cleanup did not preserve recent/changed files'
$rejected = $false
try { Invoke-NativeLogged $env:ComSpec @('/d','/c','exit 7') 'Synthetic failure' } catch { $rejected = $true }
Assert-True $rejected 'Native failure was reported as success'
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File (Join-Path $PSScriptRoot 'MalwareScanner\Scanner.ps1') -SelfTest
if ($LASTEXITCODE -ne 0) { throw 'Scanner self-test process failed' }
$fixedDate = [datetime]::new(2026,10,25,11,20,0)
Assert-True ((Get-FriendlyDate $fixedDate) -eq 'Oct 25th 2026') 'Friendly date format changed'
foreach ($pair in @(@(1,'st'),@(2,'nd'),@(3,'rd'),@(11,'th'),@(12,'th'),@(13,'th'),@(21,'st'),@(22,'nd'),@(23,'rd'))) {
    Assert-True ((Get-FriendlyDate ([datetime]::new(2026,10,$pair[0]))) -eq "Oct $($pair[0])$($pair[1]) 2026") 'Ordinal suffix is wrong'
}
$readableRoot = Join-Path $fixtureDirectory 'Logs\Safety Runs'
$firstRun = New-FriendlyRunDirectory $readableRoot 'Safety Run' $fixedDate
$secondRun = New-FriendlyRunDirectory $readableRoot 'Safety Run' $fixedDate
Assert-True ((Split-Path $firstRun -Leaf) -eq 'Oct 25th 2026 Safety Run 11.20am') 'Readable run name is incorrect'
Assert-True ((Split-Path $secondRun -Leaf) -eq 'Oct 25th 2026 Safety Run 11.20am (2)') 'Run naming collision overwrote a directory'
$legacyRoot = Join-Path $fixtureDirectory 'SafetyRuns'
$legacyRun = New-Item -ItemType Directory -Path (Join-Path $legacyRoot '20261025_110156_881_4addbc1d') -Force
$script:Journal | Export-Clixml -LiteralPath (Join-Path $firstRun 'Snapshot.clixml')
$script:Journal | Export-Clixml -LiteralPath (Join-Path $legacyRun.FullName 'Snapshot.clixml')
Assert-True (@(Get-SnapshotRuns @($readableRoot,$legacyRoot)).Count -eq 2) 'Legacy or readable snapshots disappeared from discovery'

$namedRoot = Join-Path $fixtureDirectory '.devin\profiles\named'
foreach ($badName in @('../escape','CON','NUL','name:bad','folder\name','')) {
    $blocked = $false
    try { $null = Get-PreferencePath $namedRoot $badName } catch { $blocked = $true }
    Assert-True $blocked "Unsafe preference name accepted: $badName"
}
$script:PromptAnswers = [System.Collections.Generic.Queue[string]]::new()
function Read-Host { param($Prompt) $script:PromptAnswers.Dequeue() }
try {
    $script:PromptAnswers.Enqueue('Gaming Laptop')
    Assert-True (Save-NamedPreferences @('edge-startup') $namedRoot) 'Named preference was not saved'
    $script:PromptAnswers.Enqueue('1'); $script:PromptAnswers.Enqueue('1')
    $source = Get-PreferenceSource $namedRoot
    Assert-True ($source.Action -eq 'Load' -and (Split-Path $source.Path -Leaf) -eq 'Gaming Laptop.clixml') 'Named preference load selection failed'
    $script:PromptAnswers.Enqueue('2')
    Assert-True ((Get-PreferenceSource $namedRoot).Action -eq 'New') 'New preference choice failed'
    $script:PromptAnswers.Enqueue('3')
    Assert-True ((Get-PreferenceSource $namedRoot).Action -eq 'Manual') 'Manual preference choice failed'
    $script:PromptAnswers.Enqueue('0')
    Assert-True ((Get-PreferenceSource $namedRoot).Action -eq 'Cancel') 'Preference cancellation failed'
    $script:PromptAnswers.Enqueue('Gaming Laptop'); $script:PromptAnswers.Enqueue('')
    Assert-True (-not (Save-NamedPreferences @() $namedRoot)) 'Existing preference was overwritten without consent'
    $savedIds = [string[]](Import-Clixml -LiteralPath (Get-PreferencePath $namedRoot 'Gaming Laptop'))
    Assert-True ($savedIds.Length -eq 1 -and $savedIds[0] -eq 'edge-startup') 'Refused overwrite still changed the profile'
} finally { Remove-Item Function:\Read-Host }
$testApp = Join-Path $fixtureDirectory 'App Under Test'
New-Item -ItemType Directory -Path $testApp | Out-Null
foreach ($file in @('OptimizerSafety.ps1','OptimizerFeatures.ps1','OptimizerPaths.ps1')) { Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination $testApp }
function Invoke-PreferenceFlow($FlowMode, $Answers) {
    if ('APPLY' -cin $Answers -or 'RESTORE' -cin $Answers) { throw 'Integration test must not authorize system changes' }
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $info.Arguments = '-NoProfile -File "' + (Join-Path $testApp 'OptimizerSafety.ps1') + '" -Mode ' + $FlowMode
    $info.UseShellExecute = $false
    $info.RedirectStandardInput = $true; $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
    $process = [Diagnostics.Process]::Start($info)
    $outTask = $process.StandardOutput.ReadToEndAsync(); $errTask = $process.StandardError.ReadToEndAsync()
    foreach ($answer in $Answers) { $process.StandardInput.WriteLine($answer) }
    $process.StandardInput.Close()
    if (-not $process.WaitForExit(30000)) { $process.Kill(); throw 'Named preference flow timed out' }
    Assert-True ($process.ExitCode -eq 0 -and [string]::IsNullOrEmpty($errTask.Result)) "Preference flow failed: $($errTask.Result) $($outTask.Result)"
    return $outTask.Result
}
$flow = Invoke-PreferenceFlow 'Preferences' (@('2','Y') + (@('N') * ($nonPowerCount - 1)) + @('SAVE','Month Later'))
Assert-True ($flow -match 'Named preference saved; no system changes') 'Create named preference flow failed'
$flow = Invoke-PreferenceFlow 'Standard' @('1','1','')
Assert-True ($flow -match '\[Loaded\]' -and $flow -match 'PLAN: 1 selected' -and $flow -notmatch 'Every option defaults') 'Load did not skip the questionnaire and preserve the saved selection'
Assert-True ($flow -match 'Preview complete; no system changes') 'Loading applied a preference without confirmation'
$flow = Invoke-PreferenceFlow 'Standard' (@('3') + (@('N') * $nonPowerCount))
Assert-True ($flow -match 'PLAN: 0 selected') 'Manual front-door flow failed'
foreach ($setting in $script:Catalog) { Assert-True (Test-SameState (Get-ValueState $setting) $before[$setting.Id]) "Profile flow changed a real setting: $($setting.Id)" }
$legacyValidated = 0
foreach ($run in @(Get-SnapshotRuns @((Join-Path $PSScriptRoot 'SafetyRuns')))) {
    $legacyJournal = Import-Clixml -LiteralPath (Join-Path $run.FullName 'Snapshot.clixml')
    if ($legacyJournal.Computer -eq $env:COMPUTERNAME -and $legacyJournal.User -eq [Security.Principal.WindowsIdentity]::GetCurrent().User.Value) {
        Assert-Journal $legacyJournal
        $legacyValidated++
    }
}
Write-Host "Validated $legacyValidated existing same-account legacy snapshots without modifying them."
Write-Host 'PASS: existing safety tests, named preference creation/load/manual integration, name validation, overwrite refusal, readable ordinal names, collision handling and old/new snapshot discovery. No real optimization, repair, antivirus scan, RAM cleanup or install ran.'
