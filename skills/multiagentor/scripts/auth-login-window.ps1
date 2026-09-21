[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CliPath,
    [Parameter(Mandatory)][string]$SessionDirectory,
    [switch]$Probe
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$host.UI.RawUI.WindowTitle = 'MultiAgentor OAuth login'
$ready = Join-Path $SessionDirectory 'ready'
$result = Join-Path $SessionDirectory 'result.json'
New-Item -ItemType Directory -Force -Path $SessionDirectory | Out-Null
Set-Content -LiteralPath $ready -Value 'ready' -Encoding ascii

if ($Probe) {
    Write-Host 'MultiAgentor OAuth window probe is ready.' -ForegroundColor Green
    Start-Sleep -Seconds 2
    [Environment]::Exit(0)
}

$authenticated = $false
$message = $null
try {
    $help = (& $CliPath --help 2>&1 | Out-String)
    if ($help -notmatch '(?m)^\s*auth oauth(?:\s|$)') {
        throw 'This CLI version does not support auth oauth. Update multiagentor-scenario-cli from npm.'
    }

    Write-Host 'Opening the MultiAgentor authorization page in your default browser...' -ForegroundColor Cyan
    Write-Host 'Complete sign-in and authorization in the browser. This window will wait for the result.'
    & $CliPath auth oauth
    if ($LASTEXITCODE -ne 0) { throw 'CLI OAuth command failed or authorization expired.' }

    $statusText = (& $CliPath auth status 2>&1 | Out-String).Trim()
    try { $authenticated = [bool](($statusText | ConvertFrom-Json).authenticated) } catch { $authenticated = $statusText -match '"authenticated"\s*:\s*true' }
    if (-not $authenticated) { throw 'Login command returned, but auth status did not report authenticated: true.' }
    $message = 'OAuth authentication completed successfully.'
    Write-Host $message -ForegroundColor Green
} catch {
    $message = $_.Exception.Message
    Write-Host "OAuth login failed: $message" -ForegroundColor Red
} finally {
    @{ authenticated = $authenticated; message = $message } | ConvertTo-Json -Compress | Set-Content -LiteralPath $result -Encoding utf8
}

Read-Host 'Press Enter to close this window'
[Environment]::Exit($(if ($authenticated) { 0 } else { 1 }))
