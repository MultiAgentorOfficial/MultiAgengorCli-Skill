[CmdletBinding()]
param(
    [string]$Repository = 'https://gitlab.kuajingvs.com/com-bifang-workspace/multiagengorcli.git',
    [string]$Ref = 'master',
    [string]$InstallRoot,
    [string]$SourceDirectory,
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

function Write-Result([hashtable]$Values) { $Values | ConvertTo-Json -Compress -Depth 5 }
function Download([string]$Uri, [string]$OutFile) {
    Invoke-WebRequest -UseBasicParsing -Headers @{ 'User-Agent' = 'multiagentor-skill-bootstrap' } -Uri $Uri -OutFile $OutFile
}
function Read-Package([string]$Root) {
    $file = Join-Path $Root 'package.json'
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "CLI package.json not found under $Root" }
    return Get-Content -Raw -LiteralPath $file | ConvertFrom-Json
}

if ($CheckOnly) {
    $existingLauncher = Join-Path $InstallRoot 'multiagentor.cmd'
    Write-Result @{
        mode = 'check-only'; platform = 'win32-x64'; installRoot = $InstallRoot
        installed = (Test-Path -LiteralPath $existingLauncher -PathType Leaf)
        invocation = if (Test-Path -LiteralPath $existingLauncher) { $existingLauncher } else { $null }
        repository = $Repository; ref = $Ref
    }
    exit 0
}

New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
$work = Join-Path $InstallRoot ('.bootstrap-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
try {
    $sourceRoot = $null
    $sourceCommit = $null
    if ($SourceDirectory) {
        $sourceRoot = (Resolve-Path -LiteralPath $SourceDirectory).Path
    } else {
        $sourceRoot = Join-Path $InstallRoot 'source'
        $git = Get-Command git -ErrorAction SilentlyContinue
        if ($git) {
            if (Test-Path -LiteralPath (Join-Path $sourceRoot '.git')) {
                $dirty = & $git.Source -C $sourceRoot status --porcelain
                if ($LASTEXITCODE -ne 0 -or $dirty) { throw "Portable CLI source checkout is dirty or unreadable: $sourceRoot" }
                & $git.Source -C $sourceRoot fetch --depth 1 origin $Ref
                if ($LASTEXITCODE -ne 0) { throw 'Failed to fetch the CLI repository.' }
                & $git.Source -C $sourceRoot checkout --detach FETCH_HEAD
                if ($LASTEXITCODE -ne 0) { throw 'Failed to select the fetched CLI revision.' }
            } elseif (Test-Path -LiteralPath $sourceRoot) {
                $stagedSource = Join-Path $work 'source-git'
                & $git.Source clone --depth 1 --branch $Ref $Repository $stagedSource
                if ($LASTEXITCODE -ne 0) { throw 'Failed to clone the CLI repository.' }
                if (-not (Test-Path -LiteralPath (Join-Path $stagedSource 'package.json') -PathType Leaf)) { throw 'Cloned CLI source does not contain package.json.' }
                $rollbackSource = Join-Path $InstallRoot ('.source-rollback-' + [guid]::NewGuid().ToString('N'))
                Move-Item -LiteralPath $sourceRoot -Destination $rollbackSource
                try {
                    Move-Item -LiteralPath $stagedSource -Destination $sourceRoot
                    Remove-Item -LiteralPath $rollbackSource -Recurse -Force
                } catch {
                    if (Test-Path -LiteralPath $sourceRoot) { Remove-Item -LiteralPath $sourceRoot -Recurse -Force }
                    Move-Item -LiteralPath $rollbackSource -Destination $sourceRoot
                    throw
                }
            } else {
                & $git.Source clone --depth 1 --branch $Ref $Repository $sourceRoot
                if ($LASTEXITCODE -ne 0) { throw 'Failed to clone the CLI repository.' }
            }
            $sourceCommit = (& $git.Source -C $sourceRoot rev-parse HEAD).Trim()
        } else {
            $archiveBase = $Repository.TrimEnd('/') -replace '\.git$', ''
            $archive = Join-Path $work 'source.zip'
            Download "$archiveBase/-/archive/$Ref/multiagengorcli-$Ref.zip" $archive
            $extract = Join-Path $work 'source-extract'
            Expand-Archive -LiteralPath $archive -DestinationPath $extract
            $extractedRoot = Get-ChildItem -LiteralPath $extract -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'package.json') } | Select-Object -First 1
            if (-not $extractedRoot) { throw 'Downloaded CLI archive does not contain package.json.' }
            $rollbackSource = $null
            if (Test-Path -LiteralPath $sourceRoot) {
                $rollbackSource = Join-Path $InstallRoot ('.source-rollback-' + [guid]::NewGuid().ToString('N'))
                Move-Item -LiteralPath $sourceRoot -Destination $rollbackSource
            }
            try {
                Move-Item -LiteralPath $extractedRoot.FullName -Destination $sourceRoot
                if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot 'package.json') -PathType Leaf)) { throw 'Installed CLI archive lacks package.json.' }
                if ($rollbackSource) { Remove-Item -LiteralPath $rollbackSource -Recurse -Force }
            } catch {
                if (Test-Path -LiteralPath $sourceRoot) { Remove-Item -LiteralPath $sourceRoot -Recurse -Force }
                if ($rollbackSource -and (Test-Path -LiteralPath $rollbackSource)) { Move-Item -LiteralPath $rollbackSource -Destination $sourceRoot }
                throw
            }
        }
    }

    if (-not $sourceCommit) {
        $gitForSource = Get-Command git -ErrorAction SilentlyContinue
        if ($gitForSource -and (Test-Path -LiteralPath (Join-Path $sourceRoot '.git'))) {
            $candidateCommit = (& $gitForSource.Source -C $sourceRoot rev-parse HEAD 2>$null | Select-Object -First 1)
            if ($candidateCommit -match '^[0-9a-f]{40}$') { $sourceCommit = $candidateCommit }
        }
    }

    $package = Read-Package $sourceRoot
    $engine = [string]$package.engines.node
    if ($engine -notmatch '>=\s*(\d+)') { throw "Unsupported Node engine expression for portable bootstrap: $engine" }
    $nodeMajor = [int]$Matches[1]
    $packageManager = [string]$package.packageManager
    if ($packageManager -notmatch '^pnpm@(\d+\.\d+\.\d+)$') { throw "Unsupported packageManager: $packageManager" }
    $pnpmVersion = $Matches[1]

    $index = Invoke-RestMethod -UseBasicParsing -Headers @{ 'User-Agent' = 'multiagentor-skill-bootstrap' } -Uri 'https://nodejs.org/dist/index.json'
    $release = $index | Where-Object { $_.lts -and ([int](($_.version -replace '^v','').Split('.')[0])) -eq $nodeMajor -and $_.files -contains 'win-x64-zip' } | Select-Object -First 1
    if (-not $release) { throw "No Node.js LTS win-x64 ZIP found for major $nodeMajor." }
    $nodeVersion = [string]$release.version
    $nodeArchiveName = "node-$nodeVersion-win-x64.zip"
    $nodeRoot = Join-Path $InstallRoot "runtime\$nodeVersion"
    $nodeExe = Join-Path $nodeRoot 'node.exe'
    if (-not (Test-Path -LiteralPath $nodeExe -PathType Leaf)) {
        $archive = Join-Path $work $nodeArchiveName
        $checksums = Join-Path $work 'SHASUMS256.txt'
        Download "https://nodejs.org/dist/$nodeVersion/$nodeArchiveName" $archive
        Download "https://nodejs.org/dist/$nodeVersion/SHASUMS256.txt" $checksums
        $expectedLine = Get-Content -LiteralPath $checksums | Where-Object { $_ -match "\s+$([regex]::Escape($nodeArchiveName))$" } | Select-Object -First 1
        if (-not $expectedLine) { throw 'Node.js checksum entry was not found.' }
        $expected = ($expectedLine -split '\s+')[0].ToLowerInvariant()
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $archive).Hash.ToLowerInvariant()
        if ($actual -ne $expected) { throw 'Node.js archive checksum mismatch.' }
        $extract = Join-Path $work 'node-extract'
        Expand-Archive -LiteralPath $archive -DestinationPath $extract
        $expanded = Get-ChildItem -LiteralPath $extract -Directory | Select-Object -First 1
        New-Item -ItemType Directory -Force -Path (Split-Path $nodeRoot -Parent) | Out-Null
        Move-Item -LiteralPath $expanded.FullName -Destination $nodeRoot
    }

    $oldPath = $env:Path
    $env:Path = "$nodeRoot;$oldPath"
    try {
        $activeNode = (& $nodeExe --version).Trim()
        if (-not $activeNode.StartsWith("v$nodeMajor.")) { throw "Selected Node runtime is incompatible: $activeNode for $engine" }
        $toolsRoot = Join-Path $InstallRoot 'tools'
        $npm = Join-Path $nodeRoot 'npm.cmd'
        & $npm install --prefix $toolsRoot --no-save --no-package-lock "pnpm@$pnpmVersion"
        if ($LASTEXITCODE -ne 0) { throw 'Failed to install the required pnpm version.' }
        $pnpm = Join-Path $toolsRoot 'node_modules\pnpm\bin\pnpm.cjs'
        & $nodeExe $pnpm --dir $sourceRoot install --frozen-lockfile
        if ($LASTEXITCODE -ne 0) { throw 'CLI dependency installation failed.' }
        & $nodeExe $pnpm --dir $sourceRoot build
        if ($LASTEXITCODE -ne 0) { throw 'CLI build failed.' }
    } finally { $env:Path = $oldPath }

    $entry = Join-Path $sourceRoot 'dist\bin\multiagentor.js'
    if (-not (Test-Path -LiteralPath $entry -PathType Leaf)) { throw 'Built CLI entrypoint is missing.' }
    $launcher = Join-Path $InstallRoot 'multiagentor.cmd'
    @("@echo off", "`"$nodeExe`" `"$entry`" %*") | Set-Content -LiteralPath $launcher -Encoding ascii
    $version = (& $nodeExe $entry --version).Trim()
    & $nodeExe $entry --help | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Built CLI help verification failed.' }
    Write-Result @{
        mode = 'installed'; platform = 'win32-x64'; invocation = $launcher
        cliVersion = $version; nodeVersion = $nodeVersion; pnpmVersion = $pnpmVersion
        nodeEngine = $engine; source = $sourceRoot; sourceCommit = $sourceCommit
        repository = $Repository; ref = $Ref; installRoot = $InstallRoot
    }
} finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
