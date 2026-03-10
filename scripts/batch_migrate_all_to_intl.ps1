# Batch Migration Script - Convert All Remaining Screens to intl System
# Created: February 9, 2026
# Purpose: Migrate all unmigrated screens from custom I18n to professional intl

param(
    [switch]$DryRun = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Batch intl Migration Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN MODE] - Nenhuma alteracao sera feita" -ForegroundColor Yellow
    Write-Host ""
}

$migrationScript = ".\scripts\migrate_to_intl.ps1"
if (-not (Test-Path $migrationScript)) {
    Write-Host "ERRO: Script de migracao nao encontrado em $migrationScript" -ForegroundColor Red
    exit 1
}

$migratedScreens = @(
    "lib/screens/auth/login_screen.dart",
    "lib/screens/auth/register_screen.dart",
    "lib/screens/utility/settings_screen.dart",
    "lib/screens/maintenance/manutencao_preventiva_detalhes_screen.dart",
    "lib/screens/maintenance/manutencao_preventiva_lista_screen.dart"
)

$allScreens = Get-ChildItem -Path "lib/screens" -Filter "*.dart" -Recurse -Force |
    Where-Object { $_.Name -notlike "*.bak" -and $_.Name -notlike "*.intl_backup" } |
    ForEach-Object { $_.FullName }

$screensToMigrate = @()
foreach ($screen in $allScreens) {
    $normalized = $screen.Replace('\', '/')
    $relativePath = ($normalized -replace '^.*?(lib/screens/)', 'lib/screens/')
    if ($migratedScreens -notcontains $relativePath) {
        $screensToMigrate += $screen
    }
}

$totalScreens = $screensToMigrate.Count

Write-Host "Total de screens encontradas: $($allScreens.Count)" -ForegroundColor White
Write-Host "Ja migradas: $($migratedScreens.Count)" -ForegroundColor Green
Write-Host "Pendentes de migracao: $totalScreens" -ForegroundColor Yellow
Write-Host ""

if ($totalScreens -eq 0) {
    Write-Host "Todas as screens ja foram migradas." -ForegroundColor Green
    exit 0
}

Write-Host "Screens que serao migradas:" -ForegroundColor Cyan
Write-Host "-----------------------------" -ForegroundColor Cyan
$screensToMigrate | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
Write-Host ""

if ($DryRun) {
    Write-Host "Modo DRY RUN ativo - execute novamente sem -DryRun para aplicar" -ForegroundColor Yellow
    exit 0
}

Write-Host "Deseja continuar com a migracao de $totalScreens screens? (S/N): " -ForegroundColor Yellow -NoNewline
$confirm = Read-Host
if ($confirm -ne 'S' -and $confirm -ne 's') {
    Write-Host "Migracao cancelada pelo usuario." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Iniciando migracao..." -ForegroundColor Green
Write-Host ""

$successCount = 0
$failureCount = 0
$failedScreens = @()

$current = 0
foreach ($screen in $screensToMigrate) {
    $current++
    $percentage = [math]::Round(($current / $totalScreens) * 100)

    Write-Host "[$current/$totalScreens - $percentage%] Migrando: $screen" -ForegroundColor Cyan

    try {
        & powershell -ExecutionPolicy Bypass -File $migrationScript -FilePath $screen | Out-Null

        $backupFile = "$screen.intl_backup"
        if (Test-Path $backupFile) {
            Write-Host "  OK - Backup criado" -ForegroundColor Green
        } else {
            Write-Host "  Aviso - Nenhum backup criado (arquivo pode nao ter strings I18n)" -ForegroundColor Yellow
        }
        $successCount++
    }
    catch {
        Write-Host "  ERRO: $($_.Exception.Message)" -ForegroundColor Red
        $failureCount++
        $failedScreens += $screen
    }

    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Resumo da Migracao" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total processadas: $totalScreens" -ForegroundColor White
Write-Host "Sucessos: $successCount" -ForegroundColor Green
Write-Host "Falhas: $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($failureCount -gt 0) {
    Write-Host "Screens com falha:" -ForegroundColor Red
    $failedScreens | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    Write-Host ""
}

Write-Host "Proximos passos:" -ForegroundColor Cyan
Write-Host "- flutter analyze" -ForegroundColor Gray
Write-Host "- flutter run -d windows" -ForegroundColor Gray
Write-Host "- Testar troca de idioma em Configuracoes" -ForegroundColor Gray

Write-Host ""
Write-Host "Migracao concluida." -ForegroundColor Cyan
