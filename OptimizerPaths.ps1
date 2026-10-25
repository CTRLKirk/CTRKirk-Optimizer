[CmdletBinding()]
param([switch]$InitializeLauncher)

function Get-FriendlyDate([datetime]$Date = (Get-Date)) {
    $day = $Date.Day
    $suffix = if ($day % 100 -in @(11,12,13)) { 'th' } else { switch ($day % 10) { 1 { 'st' } 2 { 'nd' } 3 { 'rd' } default { 'th' } } }
    '{0} {1}{2} {3}' -f $Date.ToString('MMM',[Globalization.CultureInfo]::InvariantCulture),$day,$suffix,$Date.Year
}

function New-FriendlyRunDirectory($Root, $Label, [datetime]$Date = (Get-Date)) {
    if (-not (Test-Path -LiteralPath $Root)) { New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null }
    $name = '{0} {1} {2}' -f (Get-FriendlyDate $Date),$Label,$Date.ToString('h.mmtt',[Globalization.CultureInfo]::InvariantCulture).ToLowerInvariant()
    for ($i=1; $i -le 10000; $i++) {
        $leaf = if ($i -eq 1) { $name } else { "$name ($i)" }
        $path = Join-Path $Root $leaf
        try { return (New-Item -ItemType Directory -Path $path -ErrorAction Stop).FullName }
        catch { if (-not (Test-Path -LiteralPath $path)) { throw } }
    }
    throw 'Unable to allocate a unique readable run folder.'
}

function Get-SnapshotRuns($Roots) {
    foreach ($root in $Roots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        Get-ChildItem -LiteralPath $root -Directory -ErrorAction Stop | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'Snapshot.clixml') }
    }
}

if ($InitializeLauncher) {
    $ErrorActionPreference = 'Stop'
    $sessions = Join-Path $PSScriptRoot 'Logs\Sessions'
    if (-not (Test-Path -LiteralPath $sessions)) { New-Item -ItemType Directory -Path $sessions -Force | Out-Null }
    $log = Join-Path $sessions ('Optimizer Log ' + (Get-FriendlyDate) + '.log')
    Add-Content -LiteralPath $log -Value ("`r`n--- Session started " + (Get-Date).ToString('yyyy-MM-dd h:mm:ss tt') + ' ---') -Encoding UTF8
    $temporary = New-FriendlyRunDirectory ([IO.Path]::GetTempPath()) 'CTRLKirk Memory Tools'
    Write-Output "LOG|$log"
    Write-Output "TEMP|$temporary"
}
