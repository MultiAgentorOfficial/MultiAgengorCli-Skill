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

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Use bootstrap-portable-cli.sh on macOS.' }
if (-not [Environment]::Is64BitOperatingSystem) { throw 'MultiAgentor browser execution requires Windows x64.' }
if (-not $InstallRoot) {
    $base = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $env:USERPROFILE 'AppData\Local' }
    $InstallRoot = Join-Path $base 'multiagentor-scenario-cli\portable'
}
$InstallRoot = [IO.Path]::GetFullPath($InstallRoot)
$Registry = $Registry.TrimEnd('/')
$launcher = Join-Path $InstallRoot 'multiagentor.cmd'

function Emit([hashtable]$Values) { $Values | ConvertTo-Json -Compress -Depth 6 }
function Download([string]$Uri, [string]$OutFile) { Invoke-WebRequest -UseBasicParsing -Headers @{ 'User-Agent' = 'multiagentor-skill-bootstrap' } -Uri $Uri -OutFile $OutFile }
function Get-Metadata {
    $cacheKey = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $headers = @{ 'User-Agent' = 'multiagentor-skill-bootstrap'; 'Cache-Control' = 'no-cache, no-store'; 'Pragma' = 'no-cache' }
    $document = Invoke-RestMethod -UseBasicParsing -Headers $headers -Uri "$Registry/$([Uri]::EscapeDataString($PackageName))?cache=$cacheKey"
    $latest = [string]$document.'dist-tags'.latest
    $release = if ($latest) { $document.versions.$latest } else { $null }
    if (-not $release) { throw "npm metadata has no latest release for $PackageName." }
    $engine = [string]$release.engines.node
    if ($engine -notmatch '>=\s*(\d+)') { throw "Unsupported Node engine expression: $engine" }
    @{ Version = $latest; Engine = $engine; NodeMajor = [int]$Matches[1]; Integrity = [string]$release.dist.integrity }
}

if ($CheckOnly) {
    Emit @{ mode = 'check-only'; platform = 'win32-x64'; installed = (Test-Path -LiteralPath $launcher -PathType Leaf); invocation = if (Test-Path -LiteralPath $launcher) { $launcher } else { $null }; packageName = $PackageName; registry = $Registry; installRoot = $InstallRoot }
    exit 0
}

$metadata = Get-Metadata
New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
$work = Join-Path $InstallRoot ('.bootstrap-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
try {
    $index = Invoke-RestMethod -UseBasicParsing -Headers @{ 'User-Agent' = 'multiagentor-skill-bootstrap' } -Uri 'https://nodejs.org/dist/index.json'
    $release = $index | Where-Object { $_.lts -and ([int](($_.version -replace '^v','').Split('.')[0])) -eq $metadata.NodeMajor -and $_.files -contains 'win-x64-zip' } | Select-Object -First 1
    if (-not $release) { throw "No Node.js LTS win-x64 ZIP found for major $($metadata.NodeMajor)." }
    $nodeVersion = [string]$release.version
    $archiveName = "node-$nodeVersion-win-x64.zip"
    $nodeRoot = Join-Path $InstallRoot "runtime\$nodeVersion"
    $nodeExe = Join-Path $nodeRoot 'node.exe'
    if (-not (Test-Path -LiteralPath $nodeExe -PathType Leaf)) {
        $archive = Join-Path $work $archiveName
        $checksums = Join-Path $work 'SHASUMS256.txt'
        Download "https://nodejs.org/dist/$nodeVersion/$archiveName" $archive
        Download "https://nodejs.org/dist/$nodeVersion/SHASUMS256.txt" $checksums
        $line = Get-Content -LiteralPath $checksums | Where-Object { $_ -match "\s+$([regex]::Escape($archiveName))$" } | Select-Object -First 1
        if (-not $line) { throw 'Node.js checksum entry was not found.' }
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $archive).Hash.ToLowerInvariant() -ne (($line -split '\s+')[0].ToLowerInvariant())) { throw 'Node.js archive checksum mismatch.' }
        $extract = Join-Path $work 'node-extract'
        Expand-Archive -LiteralPath $archive -DestinationPath $extract
        $expanded = Get-ChildItem -LiteralPath $extract -Directory | Select-Object -First 1
        New-Item -ItemType Directory -Force -Path (Split-Path $nodeRoot -Parent) | Out-Null
        Move-Item -LiteralPath $expanded.FullName -Destination $nodeRoot
    }

    $stage = Join-Path $work 'package'
    New-Item -ItemType Directory -Path $stage | Out-Null
    $npm = Join-Path $nodeRoot 'npm.cmd'
    $oldPath = $env:Path
    $env:Path = "$nodeRoot;$oldPath"
    try {
        & $npm install --global --prefix $stage "$PackageName@$($metadata.Version)" --registry $Registry --no-audit --no-fund
        if ($LASTEXITCODE -ne 0) { throw 'npm CLI installation failed.' }
    } finally { $env:Path = $oldPath }

    $packageRoot = Join-Path $stage "node_modules\$PackageName"
    $packageFile = Join-Path $packageRoot 'package.json'
    if (-not (Test-Path -LiteralPath $packageFile -PathType Leaf)) { throw 'Installed npm package is missing package.json.' }
    $package = Get-Content -Raw -LiteralPath $packageFile | ConvertFrom-Json
    $binRelative = if ($package.bin -is [string]) { [string]$package.bin } elseif ($package.bin.multiagentor) { [string]$package.bin.multiagentor } else { [string]($package.bin.PSObject.Properties | Select-Object -First 1).Value }
    $entry = Join-Path $packageRoot $binRelative
    if (-not (Test-Path -LiteralPath $entry -PathType Leaf)) { throw 'Installed npm package is missing its CLI entrypoint.' }
    $version = (& $nodeExe $entry --version).Trim()
    & $nodeExe $entry --help | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Installed CLI help verification failed.' }

    $target = Join-Path $InstallRoot 'package'
    $rollback = $null
    if (Test-Path -LiteralPath $target) { $rollback = Join-Path $InstallRoot ('.package-rollback-' + [guid]::NewGuid().ToString('N')); Move-Item -LiteralPath $target -Destination $rollback }
    try {
        Move-Item -LiteralPath $stage -Destination $target
        $stableEntry = Join-Path $target "node_modules\$PackageName\$binRelative"
        @('@echo off', "`"$nodeExe`" `"$stableEntry`" %*") | Set-Content -LiteralPath $launcher -Encoding ascii
        & $launcher --help | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Stable CLI launcher verification failed.' }
        if ($rollback) { Remove-Item -LiteralPath $rollback -Recurse -Force }
    } catch {
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
        if ($rollback -and (Test-Path -LiteralPath $rollback)) { Move-Item -LiteralPath $rollback -Destination $target }
        throw
    }

    Emit @{ mode = 'installed'; platform = 'win32-x64'; invocation = $launcher; cliVersion = $version; nodeVersion = $nodeVersion; npmVersion = (& $npm --version).Trim(); nodeEngine = $metadata.Engine; packageName = $PackageName; registry = $Registry; integrity = $metadata.Integrity; installRoot = $InstallRoot }
} finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
