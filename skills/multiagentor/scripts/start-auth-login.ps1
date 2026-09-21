[CmdletBinding()]
param(
    [string]$CliPath,
    [ValidateRange(5,60)][int]$ReadyTimeoutSeconds = 15,
    [switch]$Probe
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $CliPath -and $env:MULTIAGENTOR_CLI_PATH) { $CliPath = $env:MULTIAGENTOR_CLI_PATH }
if (-not $CliPath) { $command = Get-Command multiagentor -ErrorAction SilentlyContinue | Select-Object -First 1; if ($command) { $CliPath = $command.Source } }
if (-not $CliPath) {
    $managed = Join-Path $env:LOCALAPPDATA 'multiagentor-scenario-cli\portable\multiagentor.cmd'
    if (Test-Path -LiteralPath $managed -PathType Leaf) { $CliPath = $managed }
}
if (-not $CliPath -or -not (Test-Path -LiteralPath $CliPath -PathType Leaf)) { throw 'A usable MultiAgentor CLI launcher was not found.' }
$CliPath = [IO.Path]::GetFullPath($CliPath)

$base = Join-Path $env:LOCALAPPDATA 'MultiAgentorAuth'
$session = Join-Path $base ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $session | Out-Null
$worker = Join-Path $PSScriptRoot 'auth-login-window.ps1'
$ready = Join-Path $session 'ready'
$fallback = Join-Path $session 'open-login.cmd'
$escapedWorker = $worker.Replace("'", "''")
$escapedCli = $CliPath.Replace("'", "''")
$escapedSession = $session.Replace("'", "''")
$probeText = if ($Probe) { ' -Probe' } else { '' }
$commandText = "& '$escapedWorker' -CliPath '$escapedCli' -SessionDirectory '$escapedSession'$probeText"
$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($commandText))
@('@echo off', 'powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -EncodedCommand ' + $encoded) | Set-Content -LiteralPath $fallback -Encoding ascii

$process = $null
try {
    $process = Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-EncodedCommand',$encoded) -WindowStyle Normal -WorkingDirectory $session -PassThru
} catch {
    @{ started = $false; ready = $false; error = $_.Exception.Message; fallbackScript = $fallback; sessionDirectory = $session } | ConvertTo-Json -Compress
    exit 1
}

$deadline = [DateTime]::UtcNow.AddSeconds($ReadyTimeoutSeconds)
while ([DateTime]::UtcNow -lt $deadline -and -not (Test-Path -LiteralPath $ready -PathType Leaf) -and -not $process.HasExited) { Start-Sleep -Milliseconds 250; $process.Refresh() }
$isReady = Test-Path -LiteralPath $ready -PathType Leaf
if (-not $isReady) {
    try { Start-Process -FilePath 'explorer.exe' -ArgumentList ('/select,"{0}"' -f $fallback) | Out-Null } catch { }
}
@{ started = $true; ready = $isReady; processId = $process.Id; readyMarker = $ready; resultFile = (Join-Path $session 'result.json'); fallbackScript = $fallback; sessionDirectory = $session; probe = [bool]$Probe } | ConvertTo-Json -Compress
if (-not $isReady) { exit 1 }
