#!/usr/bin/env pwsh
# Smart I18n Converter with Import Management (Fixed Version)
# Purpose: Convert screens to i18n with automatic import handling
# Usage: .\smart_i18n_converter_fixed.ps1 -ScreensPath "lib/screens/utility" -DryRun $true

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
    $msg = "[OK] $args"
    Add-Content -Path $OutputLog -Value $msg -Encoding UTF8
    Write-Host $msg -ForegroundColor Green
}

function Warn {
    $msg = "[!!] $args"
    Add-Content -Path $OutputLog -Value $msg -Encoding UTF8
    Write-Host $msg -ForegroundColor Yellow
}

# Clear log
"" | Set-Content -Path $OutputLog -Encoding UTF8

Log "Starting Smart I18n Converter"
Log "Screens path: $ScreensPath"
Log "Dry-run mode: $DryRun"

# Define replacements in arrays to avoid escaping issues
$replacementPairs = @(
    # Profile
    @{ Pattern = '"Meu Perfil"'; Replace = 'I18n.t.text(${apostrophe}profile_title${apostrophe})' },
    @{ Pattern = '"Nome Completo"'; Replace = 'I18n.t.text(${apostrophe}profile_name${apostrophe})' },
    @{ Pattern = '"Telefone"'; Replace = 'I18n.t.text(${apostrophe}register_phone${apostrophe})' },
    
    # Settings
    @{ Pattern = '"Configurações"'; Replace = 'I18n.t.text(${apostrophe}settings_title${apostrophe})' },
    @{ Pattern = '"Segurança"'; Replace = 'I18n.t.text(${apostrophe}settings_security${apostrophe})' },
    @{ Pattern = '"Aparência"'; Replace = 'I18n.t.text(${apostrophe}settings_appearance${apostrophe})' },
    
    # Common
    @{ Pattern = '"Salvar"'; Replace = 'I18n.t.text(${apostrophe}action_save${apostrophe})' },
    @{ Pattern = '"Excluir"'; Replace = 'I18n.t.text(${apostrophe}action_delete${apostrophe})' },
    @{ Pattern = '"Editar"'; Replace = 'I18n.t.text(${apostrophe}action_edit${apostrophe})' },
    @{ Pattern = '"Voltar"'; Replace = 'I18n.t.text(${apostrophe}action_back${apostrophe})' },
    @{ Pattern = '"Cancelar"'; Replace = 'I18n.t.text(${apostrophe}common_cancel${apostrophe})' },
)

function Add-I18nImport {
    param([string]$FilePath)
    
    $content = Get-Content -Path $FilePath -Raw
    
    if ($content -match "import.*idioma") {
        Log "I18n import already exists in $(Split-Path $FilePath -Leaf)"
        return $content
    }
    
    $lines = $content -split "`n"
    $lastImportIndex = -1
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^import ") {
            $lastImportIndex = $i
        }
    }
    
    if ($lastImportIndex -ge 0) {
        $lines[$lastImportIndex] = $lines[$lastImportIndex] + "`nimport '../../i18n/idioma.dart';"
        Log "Added i18n import to $(Split-Path $FilePath -Leaf)"
        return $lines -join "`n"
    }
    
    return $content
}

# Process files
$dartFiles = @(Get-ChildItem -Path $ScreensPath -Filter "*.dart" -Recurse)

Log "Found $($dartFiles.Count) Dart files"
$processed = 0
$modifiedCount = 0
$apostrophe = "'"

foreach ($file in $dartFiles) {
    $fileName = Split-Path $file -Leaf
    Log "Processing: $fileName"
    
    $content = Get-Content -Path $file.FullName -Raw
    $originalContent = $content
    $modified = $false
    
    # Add import
    $content = Add-I18nImport -FilePath $file.FullName
    if ($content -ne $originalContent) {
        $modified = $true
    }
    
    # Apply replacements
    foreach ($pair in $replacementPairs) {
        $pattern = $pair.Pattern
        $replacement = $ExecutionContext.ExpandString($pair.Replace)
        
        if ($content -match [regex]::Escape($pattern)) {
            $matchCount = ([regex]::Matches($content, [regex]::Escape($pattern))).Count
            Log "  Found $matchCount: $pattern"
            $content = $content -replace [regex]::Escape($pattern), $replacement
            $modified = $true
        }
    }
    
    # Write changes
    if ($modified) {
        if ($DryRun) {
            Warn "Would modify: $fileName (dry-run)"
        } else {
            if ($Backup) {
                Copy-Item -Path $file.FullName -Destination "$($file.FullName).bak" -Force
                Log "Backup created"
            }
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8
            Success "Modified: $fileName"
            $modifiedCount++
        }
        $processed++
    } else {
        Log "No changes needed: $fileName"
    }
}

Log ""
Log "=========================================="
Success "Processed: $processed files"
if ($DryRun) {
    Warn "DRY-RUN MODE: No files were modified"
} else {
    Success "Actually modified: $modifiedCount files"
}
Log "Log saved to: $OutputLog"
