[CmdletBinding()]
param(
    [string]$PackageName = 'multiagentor-scenario-cli',
    [string]$Registry = 'https://registry.npmjs.org',
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
$Registry = $Registry.TrimEnd('/')
$launcher = Join-Path $InstallRoot 'multiagentor.cmd'

function Get-CliVersion([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    try { $value = (& $Path --version 2>$null | Select-Object -First 1); $text = ([string]$value).Trim(); if ($text) { return $text } } catch { }
    return $null
}
function Emit([hashtable]$Values) { $Values | ConvertTo-Json -Compress -Depth 5 }

$document = Invoke-RestMethod -UseBasicParsing -Headers @{ 'User-Agent' = 'multiagentor-skill-updater' } -Uri "$Registry/$([Uri]::EscapeDataString($PackageName))"
$latest = [string]$document.'dist-tags'.latest
if (-not $latest -or -not $document.versions.$latest) { throw "npm metadata has no latest release for $PackageName." }
$engine = [string]$document.versions.$latest.engines.node
$integrity = [string]$document.versions.$latest.dist.integrity
$current = Get-CliVersion $launcher
$needsUpdate = -not $current -or ([version]$latest -gt [version]$current)
if (-not $needsUpdate) {
    & $launcher --help | Out-Null
    if ($LASTEXITCODE -ne 0) { $needsUpdate = $true }
}

if ($CheckOnly -or -not $needsUpdate) {
    Emit @{ mode = if ($CheckOnly) { 'check-only' } else { 'current' }; updateAvailable = $needsUpdate; updated = $false; invocation = if (Test-Path -LiteralPath $launcher) { $launcher } else { $null }; cliVersion = $current; latestVersion = $latest; nodeEngine = $engine; packageName = $PackageName; registry = $Registry; integrity = $integrity }
    exit 0
}

$bootstrap = Join-Path $PSScriptRoot 'bootstrap-portable-cli.ps1'
$arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $bootstrap, '-PackageName', $PackageName, '-Registry', $Registry, '-InstallRoot', $InstallRoot)
$output = & powershell.exe @arguments
if ($LASTEXITCODE -ne 0) { throw 'npm CLI installation or update failed.' }
$jsonLine = $output | Where-Object { ([string]$_).TrimStart().StartsWith('{') } | Select-Object -Last 1
if (-not $jsonLine) { throw 'CLI bootstrap did not return its JSON result.' }
$installed = ([string]$jsonLine | ConvertFrom-Json)
Emit @{ mode = 'updated'; updateAvailable = $true; updated = $true; previousVersion = $current; cliVersion = $installed.cliVersion; latestVersion = $latest; invocation = $installed.invocation; nodeVersion = $installed.nodeVersion; npmVersion = $installed.npmVersion; nodeEngine = $installed.nodeEngine; packageName = $PackageName; registry = $Registry; integrity = $installed.integrity }
