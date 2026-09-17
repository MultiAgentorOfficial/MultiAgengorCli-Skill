[CmdletBinding()]
param(
    [string]$CliPath,
    [string]$PackageName = 'multiagentor-scenario-cli',
    [string]$Registry = 'https://registry.npmjs.org',
    [switch]$CheckRemote
)

$ErrorActionPreference = 'Stop'
$skillRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
function Command-Path([string]$Name) { $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1; if ($command) { $command.Source } }
function Capture([scriptblock]$Action) { try { (& $Action 2>$null | Out-String).Trim() } catch { $null } }

$nodePath = Command-Path 'node'
$nodeVersion = if ($nodePath) { Capture { & $nodePath --version } } else { $null }
$npmPath = Command-Path 'npm'
$npmVersion = if ($npmPath) { Capture { & $npmPath --version } } else { $null }
$nvmPath = Command-Path 'nvm'
$resolvedCli = $CliPath
if (-not $resolvedCli -and $env:MULTIAGENTOR_CLI_PATH) { $resolvedCli = $env:MULTIAGENTOR_CLI_PATH }
if (-not $resolvedCli) { $resolvedCli = Command-Path 'multiagentor' }
$cliVersion = if ($resolvedCli) { Capture { & $resolvedCli --version } } else { $null }
$cliHelp = if ($resolvedCli) { [bool](Capture { & $resolvedCli --help }) } else { $false }

$latest = $null; $nodeEngine = $null; $integrity = $null
if ($CheckRemote) {
    $document = Invoke-RestMethod -UseBasicParsing -Headers @{ 'User-Agent' = 'multiagentor-skill-environment-check' } -Uri "$($Registry.TrimEnd('/'))/$([Uri]::EscapeDataString($PackageName))"
    $latest = [string]$document.'dist-tags'.latest
    if ($latest -and $document.versions.$latest) { $nodeEngine = [string]$document.versions.$latest.engines.node; $integrity = [string]$document.versions.$latest.dist.integrity }
}

$skillText = Get-Content -Raw -LiteralPath (Join-Path $skillRoot 'SKILL.md')
$match = [regex]::Match($skillText, '(?m)^\s{2}version:\s*["'']?([^"''\r\n]+)')
[ordered]@{
    skillVersion = if ($match.Success) { $match.Groups[1].Value.Trim() } else { $null }
    skillRoot = $skillRoot
    os = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    nodePath = $nodePath
    nodeVersion = $nodeVersion
    npmPath = $npmPath
    npmVersion = $npmVersion
    nvmPath = $nvmPath
    cliPath = if ($resolvedCli) { [string]$resolvedCli } else { $null }
    cliVersion = $cliVersion
    cliHelpAvailable = $cliHelp
    packageName = $PackageName
    registry = $Registry.TrimEnd('/')
    latestVersion = $latest
    nodeEngine = $nodeEngine
    integrity = $integrity
    dataDir = $env:MULTIAGENTOR_DATA_DIR
    apiUrl = $env:MULTIAGENTOR_API_URL
    browserExecutable = $env:MULTIAGENTOR_BROWSER_EXECUTABLE
} | ConvertTo-Json -Depth 4
