#!/usr/bin/env pwsh
# Smart I18n Converter with Import Management
# Purpose: Convert screens to i18n with automatic import handling
# Usage: .\smart_i18n_converter.ps1 -ScreensPath "lib/screens/utility" -OutputLog "conversion.log"

param(
    [Parameter(Mandatory=$true)]
    [string]$ScreensPath,
    
    [string]$OutputLog = "conversion.log",
    [switch]$DryRun = $true,
    [switch]$Backup = $true
)

function Log { 
    $msg = "[$(Get-Date -Format 'HH:mm:ss')] $args"
    Add-Content -Path $OutputLog -Value $msg -Encoding UTF8
    Write-Host $msg -ForegroundColor Cyan
}

function Success {
    $msg = "[✓] $args"
    Add-Content -Path $OutputLog -Value $msg -Encoding UTF8
    Write-Host $msg -ForegroundColor Green
}

function Warn {
    $msg = "[⚠] $args"
    Add-Content -Path $OutputLog -Value $msg -Encoding UTF8
    Write-Host $msg -ForegroundColor Yellow
}

# Clear log
"" | Set-Content -Path $OutputLog -Encoding UTF8

Log "Starting Smart I18n Converter"
Log "Screens path: $ScreensPath"
Log "Dry-run mode: $DryRun"

# Extended replacements with categories
$commonReplacements = @{
    # === PROFILE SCREEN ===
    'label: ''Nome Completo''' = 'label: I18n.t.text(''profile_name'')'
    'label: ''Telefone''' = 'label: I18n.t.text(''profile_phone'')'
    'label: ''Email''' = 'label: I18n.t.text(''profile_email'')'
    'Text(''Meu Perfil''' = 'Text(I18n.t.text(''profile_title'''
    'Text(''Editar Perfil''' = 'Text(I18n.t.text(''profile_edit'''
    
    # === SETTINGS SCREEN ===
    'Text(''Configurações''' = 'Text(I18n.t.text(''settings_title'''
    'Text(''Segurança''' = 'Text(I18n.t.text(''settings_security'''
    'Text(''Notificações''' = 'Text(I18n.t.text(''settings_notifications'''
    'Text(''Aparência''' = 'Text(I18n.t.text(''settings_appearance'''
    'Text(''Sobre''' = 'Text(I18n.t.text(''settings_about'''
    
    # === NOTIFICATIONS ===
    'Text(''Notificações''' = 'Text(I18n.t.text(''notifications_title'''
    'Text(''Nenhuma notificação''' = 'Text(I18n.t.text(''notifications_empty'''
    
    # === APARTMENTS ===
    'Text(''Apartamentos''' = 'Text(I18n.t.text(''apartments_list_title'''
    'Text(''Disponível''' = 'Text(I18n.t.text(''apartments_list_available'''
    'Text(''Ocupado''' = 'Text(I18n.t.text(''apartments_list_occupied'''
    'Text(''Manutenção''' = 'Text(I18n.t.text(''maintenance_list_in_progress'''
    
    # === BUTTONS & ACTIONS ===
    'Text(''Salvar''' = 'Text(I18n.t.text(''action_save'''
    'Text(''Excluir''' = 'Text(I18n.t.text(''action_delete'''
    'Text(''Editar''' = 'Text(I18n.t.text(''action_edit'''
    'Text(''Criar''' = 'Text(I18n.t.text(''action_create'''
    'Text(''Voltar''' = 'Text(I18n.t.text(''action_back'''
    'Text(''Cancelar''' = 'Text(I18n.t.text(''common_cancel'''
    
    # === MESSAGES ===
    'snackBar(''Salvo com sucesso''' = 'snackBar(I18n.t.text(''success_saved'''
    'snackBar(''Excluído com sucesso''' = 'snackBar(I18n.t.text(''success_deleted'''
    'snackBar(''Ocorreu um erro''' = 'snackBar(I18n.t.text(''error_generic'''
}

function Add-I18nImport {
    param([string]$FilePath)
    
    $content = Get-Content -Path $FilePath -Raw
    
    # Check if i18n import already exists
    if ($content -match "import.*idioma") {
        Log "I18n import already exists in $(Split-Path $FilePath -Leaf)"
        return $content
    }
    
    # Find the last import statement
    $lines = $content -split "`n"
    $lastImportIndex = -1
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^import ") {
            $lastImportIndex = $i
        }
    }
    
    if ($lastImportIndex -ge 0) {
        # Insert after last import
        $lines[$lastImportIndex] = $lines[$lastImportIndex] + "`nimport '../../i18n/idioma.dart';"
        Log "Added i18n import to $(Split-Path $FilePath -Leaf)"
        return $lines -join "`n"
    }
    
    return $content
}

# Process files
$dartFiles = Get-ChildItem -Path $ScreensPath -Filter "*.dart" -Recurse

Log "Found $($dartFiles.Count) Dart files"
$processed = 0
$skipped = 0

foreach ($file in $dartFiles) {
    Log "Processing: $($file.Name)"
    
    $content = Get-Content -Path $file.FullName -Raw
    $originalContent = $content
    $modified = $false
    
    # Add import
    $content = Add-I18nImport -FilePath $file.FullName
    if ($content -ne $originalContent) {
        $modified = $true
    }
    
    # Apply replacements
    foreach ($pattern in $commonReplacements.Keys) {
        $replacement = $commonReplacements[$pattern]
        $escapePattern = [regex]::Escape($pattern)
        
        if ($content -match $escapePattern) {
            $count = ([regex]::Matches($content, $escapePattern)).Count
            Log "  Replacing ($count) occurrence(s): $pattern → $replacement"
            $content = $content -replace $escapePattern, $replacement
            $modified = $true
        }
    }
    
    # Write changes
    if ($modified -and -not $DryRun) {
        # Backup
        if ($Backup) {
            Copy-Item -Path $file.FullName -Destination "$($file.FullName).bak" -Force
        }
        
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        Success "Modified: $($file.Name)"
        $processed++
    } elseif ($modified) {
        Warn "Would modify: $($file.Name) (dry-run mode)"
        $processed++
    } else {
        Log "No changes needed: $($file.Name)"
        $skipped++
    }
}

Log ""
Log "========== CONVERSION COMPLETE =========="
Success "Processed: $processed files"
Warn "Skipped: $skipped files"
if ($DryRun) {
    Warn "DRY-RUN MODE: No files were actually modified"
    Log "Run with -DryRun:`$false to apply changes"
}
Log "Log saved to: $OutputLog"
