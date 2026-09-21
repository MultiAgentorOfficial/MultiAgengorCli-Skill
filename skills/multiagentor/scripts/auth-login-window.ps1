[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CliPath,
    [Parameter(Mandatory)][string]$SessionDirectory,
    [switch]$Probe
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$host.UI.RawUI.WindowTitle = 'MultiAgentor secure login'
$ready = Join-Path $SessionDirectory 'ready'
$result = Join-Path $SessionDirectory 'result.json'
New-Item -ItemType Directory -Force -Path $SessionDirectory | Out-Null
Set-Content -LiteralPath $ready -Value 'ready' -Encoding ascii

if ($Probe) {
    Write-Host 'MultiAgentor login window probe is ready.' -ForegroundColor Green
    Start-Sleep -Seconds 2
    [Environment]::Exit(0)
}

$authenticated = $false
$message = $null
try {
    $help = (& $CliPath auth login --help 2>&1 | Out-String)
    if ($help -notmatch '(?m)(^|\s)--password-stdin(\s|$)') {
        throw 'This CLI version does not support auth login --password-stdin. Update the npm package before secure login. Password arguments are disabled by this Skill.'
    }

    $email = Read-Host 'MultiAgentor email'
    if (-not $email) { throw 'Email is required.' }
    $secure = Read-Host 'MultiAgentor password' -AsSecureString
    $pointer = [IntPtr]::Zero
    $plain = $null
    try {
        $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
        $plain | & $CliPath auth login --email $email --password-stdin
        if ($LASTEXITCODE -ne 0) { throw 'CLI login command failed.' }
    } finally {
        if ($pointer -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
        $plain = $null
        $secure = $null
    }

    $statusText = (& $CliPath auth status 2>&1 | Out-String).Trim()
    try { $authenticated = [bool](($statusText | ConvertFrom-Json).authenticated) } catch { $authenticated = $statusText -match '"authenticated"\s*:\s*true' }
    if (-not $authenticated) { throw 'Login command returned, but auth status did not report authenticated: true.' }
    $message = 'Authenticated successfully.'
    Write-Host $message -ForegroundColor Green
} catch {
    $message = $_.Exception.Message
    Write-Host "Login failed: $message" -ForegroundColor Red
} finally {
    @{ authenticated = $authenticated; message = $message } | ConvertTo-Json -Compress | Set-Content -LiteralPath $result -Encoding utf8
}

Read-Host 'Press Enter to close this window'
[Environment]::Exit($(if ($authenticated) { 0 } else { 1 }))
