[CmdletBinding()]
param(
    [string]$CliRepo,
    [string]$CliPath,
    [switch]$CheckRemote
)

$ErrorActionPreference = 'Stop'
$skillRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function Try-CommandPath([string]$Name) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Source }
    return $null
}

function Try-Capture([scriptblock]$Action) {
    try { return (& $Action 2>$null | Out-String).Trim() }
    catch { return $null }
}

$nodePath = Try-CommandPath 'node'
$nodeVersion = if ($nodePath) { Try-Capture { & $nodePath '--version' } } else { $null }
$nvmPath = Try-CommandPath 'nvm'
$nvmHome = if ($env:NVM_HOME) { $env:NVM_HOME } elseif ($nvmPath) { Split-Path -Parent $nvmPath } else { $null }
$nvmVersions = @()
if ($nvmHome -and (Test-Path -LiteralPath $nvmHome)) {
    $nvmVersions = @(Get-ChildItem -LiteralPath $nvmHome -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^v\d+\.\d+\.\d+$' } |
        Select-Object -ExpandProperty Name)
}

$resolvedCli = $CliPath
if (-not $resolvedCli -and $env:MULTIAGENTOR_CLI_PATH) { $resolvedCli = $env:MULTIAGENTOR_CLI_PATH }
if (-not $resolvedCli) { $resolvedCli = Try-CommandPath 'multiagentor' }
if (-not $resolvedCli -and $CliRepo) {
    $candidate = Join-Path $CliRepo 'dist\bin\multiagentor.js'
    if (Test-Path -LiteralPath $candidate) { $resolvedCli = $candidate }
}

$cliVersion = $null
$cliHelpAvailable = $false
if ($resolvedCli -and (Test-Path -LiteralPath $resolvedCli)) {
    if ([IO.Path]::GetExtension($resolvedCli) -eq '.js') {
        if ($nodePath) {
            $cliVersion = Try-Capture { & $nodePath $resolvedCli '--version' }
            $cliHelpAvailable = [bool](Try-Capture { & $nodePath $resolvedCli '--help' })
        }
    } else {
        $cliVersion = Try-Capture { & $resolvedCli '--version' }
        $cliHelpAvailable = [bool](Try-Capture { & $resolvedCli '--help' })
    }
}

$packageVersion = $null
$nodeEngine = $null
$packageManager = $null
$repoHead = $null
$remoteHead = $null
$repoRemote = $null
if ($CliRepo) {
    $repo = (Resolve-Path -LiteralPath $CliRepo).Path
    $packageFile = Join-Path $repo 'package.json'
    if (Test-Path -LiteralPath $packageFile) {
        $package = Get-Content -Raw -LiteralPath $packageFile | ConvertFrom-Json
        $packageVersion = $package.version
        $nodeEngine = $package.engines.node
        $packageManager = $package.packageManager
    }
    $git = Try-CommandPath 'git'
    if ($git -and (Test-Path -LiteralPath (Join-Path $repo '.git'))) {
        $repoHead = Try-Capture { & $git -C $repo 'rev-parse' 'HEAD' }
        $repoRemote = Try-Capture { & $git -C $repo 'remote' 'get-url' 'origin' }
        if ($CheckRemote -and $repoRemote) {
            $line = Try-Capture { & $git 'ls-remote' $repoRemote 'HEAD' }
            if ($line) { $remoteHead = ($line -split '\s+')[0] }
        }
    }
}

$skillVersion = $null
$skillFile = Join-Path $skillRoot 'SKILL.md'
if (Test-Path -LiteralPath $skillFile) {
    $skillText = Get-Content -Raw -LiteralPath $skillFile
    $versionMatch = [regex]::Match($skillText, '(?m)^\s{2}version:\s*["'']?([^"''\r\n]+)')
    if ($versionMatch.Success) { $skillVersion = $versionMatch.Groups[1].Value.Trim() }
}
$skillRepoHead = $null
$skillRepoRemote = $null
$skillRemoteHead = $null
$skillDirty = $null
$gitForSkill = Try-CommandPath 'git'
if ($gitForSkill) {
    $skillTop = Try-Capture { & $gitForSkill -C $skillRoot 'rev-parse' '--show-toplevel' }
    if ($skillTop) {
        $skillRepoHead = Try-Capture { & $gitForSkill -C $skillTop 'rev-parse' 'HEAD' }
        if ($skillRepoHead -notmatch '^[0-9a-f]{40}$') { $skillRepoHead = $null }
        $skillRepoRemote = Try-Capture { & $gitForSkill -C $skillTop 'remote' 'get-url' 'origin' }
        if (-not $skillRepoRemote) { $skillRepoRemote = $null }
        $skillDirtyText = Try-Capture { & $gitForSkill -C $skillTop 'status' '--porcelain' }
        $skillDirty = [bool]$skillDirtyText
        if ($CheckRemote -and $skillRepoRemote) {
            $line = Try-Capture { & $gitForSkill 'ls-remote' $skillRepoRemote 'HEAD' }
            if ($line) { $skillRemoteHead = ($line -split '\s+')[0] }
        }
    }
}

[ordered]@{
    skillVersion = $skillVersion
    skillRoot = $skillRoot
    skillRepoHead = $skillRepoHead
    skillRepoRemote = $skillRepoRemote
    skillRemoteHead = $skillRemoteHead
    skillDirty = $skillDirty
    os = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    nodePath = $nodePath
    nodeVersion = $nodeVersion
    nvmPath = $nvmPath
    nvmVersions = $nvmVersions
    cliPath = $resolvedCli
    cliVersion = $cliVersion
    cliHelpAvailable = $cliHelpAvailable
    cliRepo = $CliRepo
    packageVersion = $packageVersion
    nodeEngine = $nodeEngine
    packageManager = $packageManager
    repoHead = $repoHead
    repoRemote = $repoRemote
    remoteHead = $remoteHead
    dataDir = $env:MULTIAGENTOR_DATA_DIR
    apiUrl = $env:MULTIAGENTOR_API_URL
    browserExecutable = $env:MULTIAGENTOR_BROWSER_EXECUTABLE
} | ConvertTo-Json -Depth 4
