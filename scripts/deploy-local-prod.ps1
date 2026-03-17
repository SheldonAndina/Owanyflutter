<#
Deploy helper: prepare firebase secret, apply EF migrations and run the API.

Usage (from repo root - PowerShell):
    .\Scripts\deploy-local-prod.ps1 -SourcePath "C:\path\to\wwwroot\your-firebase.json"

What this script does:
- Calls ./Scripts/prepare-firebase.ps1 to copy the Firebase JSON into ./secrets and set a per-user env var
- Exports the same env var into the current session so the following commands see it immediately
- Ensures `dotnet-ef` tool is installed (attempts to install if missing)
- Runs `dotnet ef database update`
- Runs `dotnet run`

Notes:
- This script must be executed on your machine; the assistant cannot run it for you.
- Open a new terminal/IDE after running prepare-firebase if you rely on the persisted setx env var.
#>

param(
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

    if (-not $SourcePath) {
        # try to find a firebase json in wwwroot automatically
        $candidates = Get-ChildItem -Path "./wwwroot" -Filter "*.json" -File -ErrorAction SilentlyContinue
        if ($candidates -and $candidates.Count -gt 0) {
            # prefer files that contain 'firebase' or 'owany'
            $found = $candidates | Where-Object { $_.Name -match 'firebase|owany' } | Select-Object -First 1
            if (-not $found) { $found = $candidates | Select-Object -First 1 }
            $SourcePath = $found.FullName
            Write-Info "Auto-detected SourcePath: $SourcePath"
        } else {
            Write-Err "No JSON found in ./wwwroot and no -SourcePath provided. Provide the Firebase JSON path."
            exit 1
        }
    }

    if (-not (Test-Path $SourcePath)) { Write-Err "Source file not found: $SourcePath"; exit 1 }

    Write-Info "Calling prepare-firebase.ps1 with SourcePath: $SourcePath"
    & "./Scripts/prepare-firebase.ps1" -SourcePath $SourcePath

    # Ensure current session has the env var (prepare-firebase used setx for persistence)
    $dest = Join-Path (Join-Path (Get-Location) 'secrets') 'firebase-service-account.json'
    if (Test-Path $dest) {
        $resolved = (Resolve-Path $dest).Path
        Write-Info "Setting session env var Firebase__ServiceAccountPath = $resolved"
        $env:Firebase__ServiceAccountPath = $resolved
    } else {
        Write-Warn "Expected secrets file not found at $dest. Make sure prepare-firebase copied the file."
    }

    # Ensure dotnet-ef is available
    $efAvailable = $false
    try {
        dotnet ef --version | Out-Null
        $efAvailable = $true
    } catch {
        $efAvailable = $false
    }

    if (-not $efAvailable) {
        Write-Info "dotnet-ef not found. Attempting to install global tool 'dotnet-ef'..."
        try {
            dotnet tool install --global dotnet-ef | Out-Null
            Write-Info "dotnet-ef installed. You might need to open a new shell for PATH to include the tool location."
        } catch {
            Write-Warn "Failed to install dotnet-ef automatically. Install it manually: `dotnet tool install --global dotnet-ef` and re-run this script."
        }
    }

    Write-Info "Applying EF migrations: dotnet ef database update"
    dotnet ef database update

    Write-Info "Starting the API: dotnet run"
    dotnet run

} catch {
    Write-Err "Unhandled error: $_"
    exit 1
}
