#!/usr/bin/env pwsh
# Migrate from custom I18n to intl AppLocalizations
# Usage: .\migrate_to_intl.ps1 -FilePath "lib/screens/auth/login_screen.dart"

param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

Write-Host "Migrando: $FilePath" -ForegroundColor Cyan

if (!(Test-Path $FilePath)) {
    Write-Host "Erro: Arquivo não encontrado!" -ForegroundColor Red
    exit 1
}

# Backup
$backupPath = "$FilePath.intl_backup"
Copy-Item $FilePath $backupPath -Force
Write-Host "Backup criado: $backupPath" -ForegroundColor Green

# Read content
$content = Get-Content $FilePath -Raw

# 1. Replace import
$content = $content -replace "import '../../i18n/idioma\.dart';", "import '../../generated_l10n/app_localizations.dart';"

# 2. Replace I18n.t.text('key') with AppLocalizations.of(context)!.key
# Common patterns we need to handle

# Pattern: I18n.t.text('login_welcome')
$content = $content -replace "I18n\.t\.text\('([a-zA-Z_]+)'\)", 'AppLocalizations.of(context)!.$1'

# Pattern: t.text('login_welcome') where t = I18n.t
$content = $content -replace "t\.text\('([a-zA-Z_]+)'\)", 'AppLocalizations.of(context)!.$1'

# 3. Remove "final t = I18n.t;" lines
$content = $content -replace "final t = I18n\.t;\s*\n", ""

# 4. Replace Idioma enum references
$content = $content -replace "Idioma\.pt", "'pt'"
$content = $content -replace "Idioma\.en", "'en'"
$content = $content -replace "languageProvider\.idioma", "languageProvider.idiomaCode"

# Write back
Set-Content $FilePath -Value $content -Encoding UTF8

Write-Host "Migração completa!" -ForegroundColor Green
Write-Host "Verifique o arquivo e teste a compilação." -ForegroundColor Yellow
