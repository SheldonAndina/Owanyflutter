#!/usr/bin/env pwsh
# Simple I18n Converter - Working Version
# Purpose: Apply i18n conversions to Flutter screens
# Usage: .\simple_i18n_converter.ps1 -ScreensPath "lib/screens/utility" -DryRun $true

param(
    [Parameter(Mandatory=$true)]
    [string]$ScreensPath,
    [bool]$DryRun = $true,
    [bool]$Backup = $true,
    [string]$LogFile = "i18n_conversion.log"
)

# Cleanup log
"=== I18n Conversion Log ===" | Set-Content $LogFile

function Log { 
    $msg = "[$(Get-Date -Format 'HH:mm:ss')] $args"
    Add-Content $LogFile $msg
    Write-Host $msg -ForegroundColor Cyan
}

function LogSuccess {
    $msg = "[OK] $args"  
    Add-Content $LogFile $msg
    Write-Host $msg -ForegroundColor Green
}

function LogWarn {
    $msg = "[!!] $args"
    Add-Content $LogFile $msg
    Write-Host $msg -ForegroundColor Yellow
}

Log "Starting I18n Converter"
Log "Screens: $ScreensPath"
Log "Dry-run: $DryRun"

# Simple replacement list
$replacements = @{
    '"Meu Perfil"'           = 'I18n.t.text("profile_title")'
    '"Editar Perfil"'        = 'I18n.t.text("profile_edit")'
    '"Configurações"'        = 'I18n.t.text("settings_title")'
    '"Segurança"'            = 'I18n.t.text("settings_security")'
    '"Aparência"'            = 'I18n.t.text("settings_appearance")'
    '"Notificações"'         = 'I18n.t.text("notifications_title")'
    '"Nenhuma notificação"'  = 'I18n.t.text("notifications_empty")'
    '"Apartamentos"'         = 'I18n.t.text("apartments_list_title")'
    '"Disponível"'           = 'I18n.t.text("apartments_list_available")'
    '"Ocupado"'              = 'I18n.t.text("apartments_list_occupied")'
    '"Manutenção"'           = 'I18n.t.text("maintenance_list_in_progress")'
    '"Salvar"'               = 'I18n.t.text("action_save")'
    '"Excluir"'              = 'I18n.t.text("action_delete")'
    '"Editar"'               = 'I18n.t.text("action_edit")'
    '"Voltar"'               = 'I18n.t.text("action_back")'
    '"Cancelar"'             = 'I18n.t.text("common_cancel")'
}

$dartFiles = @(Get-ChildItem -Path $ScreensPath -Filter "*.dart" -Recurse -ErrorAction SilentlyContinue)

if ($dartFiles.Count -eq 0) {
    LogWarn "No Dart files found in: $ScreensPath"
    exit 1
}

Log "Found $($dartFiles.Count) Dart files"

$filesProcessed = 0
$filesModified = 0
$replacementCount = 0

foreach ($file in $dartFiles) {
    $fileName = $file.Name
    Log "Processing: $fileName"
    
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $fileModified = $false
    
    # Add import if missing
    if ($content -notmatch "import.*idioma") {
        $lines = $content -split "`n"
        $lastImport = -1
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^import ") {
                $lastImport = $i
            }
        }
        
        if ($lastImport -ge 0) {
            $lines[$lastImport] += "`nimport '../../i18n/idioma.dart';"
            $content = $lines -join "`n"
            Log "  > Added i18n import"
            $fileModified = $true
        }
    }
    
    # Apply replacements
    foreach ($pattern in $replacements.Keys) {
        $replacement = $replacements[$pattern]
        
        if ($content -match [regex]::Escape($pattern)) {
            $matches = [regex]::Matches($content, [regex]::Escape($pattern))
            $count = $matches.Count
            
            Log "  > Replace ($count): $pattern"
            
            $content = $content -replace [regex]::Escape($pattern), $replacement
            $fileModified = $true
            $replacementCount += $count
        }
    }
    
    # Save if modified
    if ($fileModified) {
        if ($DryRun) {
            LogWarn "Would modify: $fileName"
        } else {
            if ($Backup) {
                Copy-Item $file.FullName "$($file.FullName).bak" -Force
            }
            Set-Content $file.FullName -Value $content -Encoding UTF8
            LogSuccess "Modified: $fileName"
            $filesModified++
        }
    }
    
    $filesProcessed++
}

Log ""
Log "====== COMPLETE ======"
LogSuccess "Files processed: $filesProcessed"
if ($DryRun) {
    LogWarn "DRY-RUN: No files actually modified"
} else {
    LogSuccess "Files modified: $filesModified"
    LogSuccess "Total replacements: $replacementCount"
}
Log "Log file: $LogFile"
