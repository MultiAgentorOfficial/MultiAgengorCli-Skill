[CmdletBinding()]
param(
    [string]$Repository = 'MultiAgentorOfficial/MultiAgengorCli-Skill',
    [string]$Ref = 'main',
    [switch]$CheckOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Read-SkillIdentity([string]$Path) {
    $text = Get-Content -Raw -LiteralPath $Path
    $name = [regex]::Match($text, '(?m)^name:\s*([a-z0-9-]+)\s*$')
    $version = [regex]::Match($text, '(?m)^\s{2}version:\s*["'']?([^"''\r\n]+)')
    if (-not $name.Success -or $name.Groups[1].Value -ne 'multiagentor' -or -not $version.Success) { throw "Invalid MultiAgentor SKILL.md: $Path" }
    $value = $version.Groups[1].Value.Trim()
    if ($value -notmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$') { throw "Invalid Skill SemVer: $value" }
    return @{ Name = 'multiagentor'; Version = [version]$value; TextVersion = $value }
}
function Test-Integrity([string]$Root) {
    $required = @(
        'SKILL.md', 'agents\openai.yaml', 'references\installation.md',
        'references\dynamic-discovery.md', 'references\execution-workflow.md', 'references\authentication.md',
        'references\supervised-execution.md', 'references\troubleshooting.md',
        'scripts\update-skill.ps1', 'scripts\update-skill.sh',
        'scripts\update-cli.ps1', 'scripts\update-cli.sh',
        'scripts\start-auth-login.ps1', 'scripts\start-auth-login.sh',
        'scripts\auth-login-window.ps1', 'scripts\auth-login-window.sh',
        'scripts\bootstrap-portable-cli.ps1', 'scripts\bootstrap-portable-cli.sh',
        'scripts\check-environment.ps1', 'scripts\check-environment.sh'
    )
    foreach ($relative in $required) { if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { return $false } }
    return $true
}
function Result([string]$Current, [string]$Latest, [bool]$Updated, [bool]$Integrity, [string]$Mode) {
    @{ currentVersion = $Current; latestVersion = $Latest; updated = $Updated; integrityOk = $Integrity; mode = $Mode; restartRequired = $Updated } |
        ConvertTo-Json -Compress
}

$skillRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$localFile = Join-Path $skillRoot 'SKILL.md'
$current = Read-SkillIdentity $localFile
$integrity = Test-Integrity $skillRoot
$encodedRef = [Uri]::EscapeDataString($Ref)
$cacheKey = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$headers = @{ 'User-Agent' = 'multiagentor-skill-updater'; 'Cache-Control' = 'no-cache'; 'Accept' = 'application/vnd.github+json' }
$commit = Invoke-RestMethod -UseBasicParsing -Headers $headers -Uri "https://api.github.com/repos/$Repository/commits/${encodedRef}?cache=$cacheKey"
$remoteSha = ([string]$commit.sha).Trim()
if ($remoteSha -notmatch '^[0-9a-f]{40}$') { throw 'GitHub returned an invalid Skill repository commit.' }
$remoteUrl = "https://raw.githubusercontent.com/$Repository/$remoteSha/skills/multiagentor/SKILL.md"
$remoteText = Invoke-RestMethod -UseBasicParsing -Headers $headers -Uri $remoteUrl
$remoteTemp = Join-Path ([IO.Path]::GetTempPath()) ("multiagentor-skill-" + [guid]::NewGuid().ToString('N') + '.md')
[IO.File]::WriteAllText($remoteTemp, [string]$remoteText, [Text.UTF8Encoding]::new($false))
try { $latest = Read-SkillIdentity $remoteTemp } finally { Remove-Item -LiteralPath $remoteTemp -Force -ErrorAction SilentlyContinue }

$needsReplace = $latest.Version -gt $current.Version -or -not $integrity
if (-not $needsReplace) { Result $current.TextVersion $latest.TextVersion $false $true 'current'; exit 0 }
if ($CheckOnly) { Result $current.TextVersion $latest.TextVersion $false $integrity 'available-or-repair'; exit 0 }

$parent = Split-Path $skillRoot -Parent
$id = [guid]::NewGuid().ToString('N')
$work = Join-Path $parent ".multiagentor-update-$id"
$staged = Join-Path $parent ".multiagentor-staged-$id"
$rollback = Join-Path $parent ".multiagentor-rollback-$id"
New-Item -ItemType Directory -Path $work | Out-Null
$replaced = $false
try {
    $archive = Join-Path $work 'repository.zip'
    Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri "https://codeload.github.com/$Repository/zip/$remoteSha" -OutFile $archive
    $extract = Join-Path $work 'extract'
    Expand-Archive -LiteralPath $archive -DestinationPath $extract
    $source = Get-ChildItem -LiteralPath $extract -Directory | ForEach-Object { Join-Path $_.FullName 'skills\multiagentor' } | Where-Object { Test-Path -LiteralPath (Join-Path $_ 'SKILL.md') } | Select-Object -First 1
    if (-not $source) { throw 'Official archive does not contain skills/multiagentor.' }
    $stagedIdentity = Read-SkillIdentity (Join-Path $source 'SKILL.md')
    if ($stagedIdentity.Version -ne $latest.Version -or -not (Test-Integrity $source)) { throw 'Staged Skill failed identity, version, or integrity validation.' }
    Copy-Item -LiteralPath $source -Destination $staged -Recurse
    Move-Item -LiteralPath $skillRoot -Destination $rollback
    try {
        Move-Item -LiteralPath $staged -Destination $skillRoot
        $installed = Read-SkillIdentity (Join-Path $skillRoot 'SKILL.md')
        if ($installed.Version -ne $latest.Version -or -not (Test-Integrity $skillRoot)) { throw 'Installed Skill failed validation.' }
        $replaced = $true
    } catch {
        if (Test-Path -LiteralPath $skillRoot) { Remove-Item -LiteralPath $skillRoot -Recurse -Force }
        Move-Item -LiteralPath $rollback -Destination $skillRoot
        throw
    }
    Remove-Item -LiteralPath $rollback -Recurse -Force
    Result $current.TextVersion $latest.TextVersion $true $true 'archive-replace'
} finally {
    if (-not $replaced -and (Test-Path -LiteralPath $staged)) { Remove-Item -LiteralPath $staged -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
