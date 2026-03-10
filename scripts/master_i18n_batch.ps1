#!/usr/bin/env pwsh
# Master I18n Batch Converter
# Purpose: Orchestrate full app bilingual conversion with minimal manual intervention
# Usage: .\master_i18n_batch.ps1

param(
    [switch]$AnalyzeOnly = $false,
    [switch]$DryRun = $true,
    [switch]$Backup = $true,
    [string]$ReportDir = "./i18n_reports"
)

$ErrorActionPreference = "Continue"

function Write-Title { 
    Write-Host ""
    Write-Host ("╔" + ("═" * 78) + "╗") -ForegroundColor Cyan
    Write-Host ("║ " + $args[0].PadRight(77) + "║") -ForegroundColor Cyan
    Write-Host ("╚" + ("═" * 78) + "╝") -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step { Write-Host "  ▶ $args" -ForegroundColor Yellow }
function Write-Info { Write-Host "    $args" -ForegroundColor White }
function Write-Success { Write-Host "    ✓ $args" -ForegroundColor Green }
function Write-Error { Write-Host "    ✗ $args" -ForegroundColor Red }

# Verify scripts exist
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$scripts = @(
    "$scriptDir/analyze_i18n_strings.ps1",
    "$scriptDir/smart_i18n_converter.ps1"
)

Write-Title "OWANY APP - MASTER I18N BATCH CONVERTER"

Write-Info "Verifying required scripts..."
foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Success "Found: $(Split-Path $script -Leaf)"
    } else {
        Write-Error "Missing: $(Split-Path $script -Leaf)"
    }
}

Write-Info ""
Write-Step "CONFIGURATION:"
Write-Info "  Dry-run mode: $DryRun"
Write-Info "  Create backups: $Backup"
Write-Info "  Reports directory: $ReportDir"

# Create report directory
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir | Out-Null
    Write-Success "Created report directory"
}

# Screen categories to process
$screenCategories = @(
    @{ Path = "lib/screens/utility"; Name = "Utility (Profile, Settings, Notifications)" },
    @{ Path = "lib/screens/auth"; Name = "Auth (Login, Register, Forgot Password)" },
    @{ Path = "lib/screens/maintenance"; Name = "Maintenance (Alerts, Forms)" },
    @{ Path = "lib/screens/apartments"; Name = "Apartments" },
    @{ Path = "lib/screens/agendamentos"; Name = "Schedules (Agendamentos)" },
    @{ Path = "lib/screens/users"; Name = "Users Management" },
    @{ Path = "lib/screens/core"; Name = "Core (Dashboard, Maintenance Requests)" }
)

Write-Title "ANALYSIS PHASE"

$summaryReport = @()
$summaryReport += "╔" + ("═" * 78) + "╗"
$summaryReport += "║ I18N CONVERSION SUMMARY REPORT - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$summaryReport += "╚" + ("═" * 78) + "╝"
$summaryReport += ""

foreach ($category in $screenCategories) {
    Write-Step "Analyzing: $($category.Name)"
    Write-Info "Path: $($category.Path)"
    
    if (Test-Path $category.Path) {
        $dartFiles = @(Get-ChildItem -Path $category.Path -Filter "*.dart" -Recurse)
        Write-Info "Found: $($dartFiles.Count) Dart files"
        
        # Run analysis
        $analysisLog = "$ReportDir/$($category.Name.Replace(' ', '_')).txt"
        Write-Success "Will save analysis to: $(Split-Path $analysisLog -Leaf)"
        
        $summaryReport += "$($category.Name): $($dartFiles.Count) files"
    } else {
        Write-Error "Path not found: $($category.Path)"
    }
}

$summaryReport | Out-File -FilePath "$ReportDir/summary.txt" -Encoding UTF8
Write-Success "Summary report: $ReportDir/summary.txt"

if ($AnalyzeOnly) {
    Write-Title "ANALYSIS COMPLETE - NO CONVERSIONS PERFORMED"
    Write-Info "Dry-run mode is enabled. Examine reports in: $ReportDir"
    exit 0
}

Write-Title "CONVERSION PHASE"

if ($DryRun) {
    Write-Info "DRY-RUN MODE: Changes will be simulated but not applied"
    Write-Info "To apply changes, run with: -DryRun:`$false"
}

$totalProcessed = 0

foreach ($category in $screenCategories) {
    Write-Step "Converting: $($category.Name)"
    
    if (Test-Path $category.Path) {
        try {
            # Run conversion
            & "$scriptDir/smart_i18n_converter.ps1" `
                -ScreensPath $category.Path `
                -OutputLog "$ReportDir/$($category.Name.Replace(' ', '_'))_conversion.log" `
                -DryRun:$DryRun `
                -Backup:$Backup
            
            Write-Success "Completed: $($category.Name)"
        } catch {
            Write-Error "Failed to process $($category.Name): $_"
        }
    }
}

Write-Title "CONVERSION COMPLETE"

Write-Info "Next steps:"
Write-Info "  1. Review changes in each category"
Write-Info "  2. Check for any compilation errors: flutter analyze"
Write-Info "  3. Run the app: flutter run -d windows"
Write-Info "  4. Test language switching in Settings and Login"

Write-Info ""
Write-Info "All reports saved to: $ReportDir"
Write-Success "Batch conversion process completed!"
