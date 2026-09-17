[CmdletBinding()]
param(
    [string]$Repository = 'https://gitlab.kuajingvs.com/com-bifang-workspace/multiagengorcli.git',
    [string]$Ref = 'master',
    [string]$InstallRoot,
    [switch]$CheckOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (-not $InstallRoot) {
    $base = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $env:USERPROFILE 'AppData\Local' }
    $InstallRoot = Join-Path $base 'multiagentor-scenario-cli\portable'
}
$InstallRoot = [IO.Path]::GetFullPath($InstallRoot)
$launcher = Join-Path $InstallRoot 'multiagentor.cmd'
$sourceRoot = Join-Path $InstallRoot 'source'
$git = Get-Command git -ErrorAction SilentlyContinue

function Get-CliVersion([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    try {
        $global:LASTEXITCODE = 0
        $value = (& $Path --version 2>$null | Select-Object -First 1)
        $text = ([string]$value).Trim()
        if ($text) { return $text }
    } catch { }
    return $null
}
function Emit([hashtable]$Values) { $Values | ConvertTo-Json -Compress -Depth 6 }

$previousVersion = Get-CliVersion $launcher
$localCommit = $null
$remoteCommit = $null
$sourceMode = 'missing'

if ($git -and (Test-Path -LiteralPath (Join-Path $sourceRoot '.git') -PathType Container)) {
    $sourceMode = 'git'
    $localCommit = ([string](& $git.Source -C $sourceRoot rev-parse HEAD 2>$null | Select-Object -First 1)).Trim()
    if ($localCommit -notmatch '^[0-9a-f]{40}$') { throw "Cannot read managed CLI source commit: $sourceRoot" }
    $remoteLine = (& $git.Source ls-remote $Repository "refs/heads/$Ref" 2>$null | Select-Object -First 1)
    if (-not $remoteLine) { throw 'Cannot query the official CLI repository HEAD.' }
    $remoteCommit = (([string]$remoteLine -split '\s+')[0]).Trim()
    if ($remoteCommit -notmatch '^[0-9a-f]{40}$') { throw 'The official CLI repository returned an invalid commit.' }
} elseif (Test-Path -LiteralPath (Join-Path $sourceRoot 'package.json') -PathType Leaf) {
    $sourceMode = 'archive'
}

$needsUpdate = -not $previousVersion -or $sourceMode -ne 'git' -or $localCommit -ne $remoteCommit
if (-not $needsUpdate) {
    $global:LASTEXITCODE = 0
    & $launcher --help | Out-Null
    if ($LASTEXITCODE -ne 0) { $needsUpdate = $true }
}

if ($CheckOnly -or -not $needsUpdate) {
    Emit @{
        mode = if ($CheckOnly) { 'check-only' } else { 'current' }
        updateAvailable = $needsUpdate
        updated = $false
        invocation = if (Test-Path -LiteralPath $launcher) { $launcher } else { $null }
        cliVersion = $previousVersion
        localCommit = $localCommit
        remoteCommit = $remoteCommit
        sourceMode = $sourceMode
        repository = $Repository
        ref = $Ref
    }
    exit 0
}

$bootstrap = Join-Path $PSScriptRoot 'bootstrap-portable-cli.ps1'
$arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $bootstrap, '-Repository', $Repository, '-Ref', $Ref, '-InstallRoot', $InstallRoot)
$global:LASTEXITCODE = 0
$output = & powershell.exe @arguments
if ($LASTEXITCODE -ne 0) { throw 'CLI bootstrap/update failed.' }
$jsonLine = $output | Where-Object { ([string]$_).TrimStart().StartsWith('{') } | Select-Object -Last 1
if (-not $jsonLine) { throw 'CLI bootstrap/update did not return its JSON result.' }
$installed = ([string]$jsonLine | ConvertFrom-Json)
Emit @{
    mode = 'updated'
    updateAvailable = $true
    updated = $true
    previousVersion = $previousVersion
    cliVersion = $installed.cliVersion
    invocation = $installed.invocation
    localCommit = $localCommit
    remoteCommit = if ($installed.sourceCommit) { $installed.sourceCommit } else { $remoteCommit }
    sourceMode = if ($installed.sourceCommit) { 'git' } else { 'archive' }
    nodeVersion = $installed.nodeVersion
    pnpmVersion = $installed.pnpmVersion
    repository = $Repository
    ref = $Ref
}
