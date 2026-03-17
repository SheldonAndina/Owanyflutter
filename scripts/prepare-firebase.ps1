<#
Prepare Firebase service account secret for local production-like runs.

Usage (from repo root - PowerShell):
    .\Scripts\prepare-firebase.ps1 -SourcePath "C:\path\to\firebase.json"

What this script does:
- Copies the Firebase JSON into ./secrets/firebase-service-account.json
- Ensures /secrets is in .gitignore
- Persists the env var Firebase__ServiceAccountPath using setx (per-user)
  (A new terminal is required for setx to be visible globally.)
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

try {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
    if (-not (Test-Path $scriptDir)) { $scriptDir = Get-Location }
    Set-Location $scriptDir

    if (-not (Test-Path $SourcePath)) {
        Write-Err "Source file not found: $SourcePath"
        exit 1
    }

    $secretsDir = Join-Path (Get-Location) 'secrets'
    if (-not (Test-Path $secretsDir)) {
        New-Item -ItemType Directory -Path $secretsDir | Out-Null
        Write-Info "Created secrets directory: $secretsDir"
    }

    $dest = Join-Path $secretsDir 'firebase-service-account.json'
    Copy-Item -Path $SourcePath -Destination $dest -Force
    Write-Info "Copied Firebase JSON to: $dest"

    $gitignorePath = Join-Path (Get-Location) '.gitignore'
    $ignoreEntry = '/secrets'
    $needsAppend = $true
    if (Test-Path $gitignorePath) {
        $existing = Get-Content $gitignorePath -ErrorAction SilentlyContinue
        if ($existing -contains $ignoreEntry) { $needsAppend = $false }
    }

    if ($needsAppend) {
        Add-Content -Path $gitignorePath -Value $ignoreEntry
        Write-Info "Added '$ignoreEntry' to .gitignore"
    } else {
        Write-Info "'.gitignore' already contains '$ignoreEntry'"
    }

    $resolved = (Resolve-Path $dest).Path
    Write-Info "Persisting env var Firebase__ServiceAccountPath via setx"
    setx Firebase__ServiceAccountPath "$resolved" | Out-Null

    Write-Info "Done. Open a new terminal for setx changes to take effect globally."
} catch {
    Write-Err "Unhandled error: $_"
    exit 1
}
